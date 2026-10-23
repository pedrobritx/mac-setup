"""Loopback-only companion for the static site and the existing Bash installer."""

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import mimetypes
import os
from pathlib import Path
import platform
import secrets
import signal
import subprocess
import tempfile
import threading
from urllib.parse import unquote, urlsplit
import uuid
import webbrowser

from .catalog import ROOT, build_catalog
from .plan import PlanError, compile_selection, load_plan, validate_plan

MODULES = ["xcode", "brew", "directories", "apps", "mas", "ssh", "git", "terminal",
           "node", "python", "swift", "vscode", "macos", "security", "verification"]
TERMINAL = {"complete", "needs_attention", "failed", "interrupted"}


class Application:
    """One local session, one active installation, append-only installer evidence."""

    def __init__(self, state_dir, dry_run=False, initial_plan=None):
        self.catalog = build_catalog()
        self.state_dir = Path(state_dir)
        self.dry_run = dry_run
        self.initial_plan = initial_plan
        self.token = secrets.token_urlsafe(32)
        self.lock = threading.Lock()
        self.run = None
        self.process = None

    def start(self, body):
        if not isinstance(body, dict) or set(body) - {"plan", "confirm", "identity"}:
            raise PlanError("Invalid installation request.")
        if body.get("confirm") is not True:
            raise PlanError("Review and explicitly confirm your setup first.")
        plan = body.get("plan")
        items = validate_plan(plan, self.catalog)
        identity = body.get("identity", {"name": "", "email": ""})
        if not isinstance(identity, dict) or set(identity) != {"name", "email"}:
            raise PlanError("Invalid Git identity.")
        for value in identity.values():
            if not isinstance(value, str) or len(value) > 200 or any(ord(c) < 32 for c in value):
                raise PlanError("Git identity must be plain text under 200 characters.")
        if bool(identity["name"].strip()) != bool(identity["email"].strip()):
            raise PlanError("Provide both a Git name and email, or leave both empty.")
        if not self.dry_run:
            if platform.system() != "Darwin" or os.geteuid() == 0:
                raise PlanError("Installation requires macOS and a regular user account.")
            for item in items:
                if item.get("architectures") and platform.machine() not in item["architectures"]:
                    raise PlanError(f"{item['name']} requires Apple Silicon. Deselect it and review again.")
        with self.lock:
            if self.run and self.run["status"] not in TERMINAL:
                raise PlanError("An installation is already running. Follow its progress.")
            run_id = uuid.uuid4().hex
            directory = self.state_dir / run_id
            directory.mkdir(parents=True, mode=0o700)
            (directory / "reports").mkdir(mode=0o700)
            compile_selection(plan, self.catalog, directory / "selection.txt")
            (directory / "plan.json").write_text(json.dumps(plan, indent=2) + "\n")
            self.run = {"id": run_id, "status": "starting", "directory": directory,
                        "items": items, "error": "", "exitCode": None}
            threading.Thread(target=self._execute, args=(self.run, identity), daemon=True).start()
        return {"id": run_id}

    def _execute(self, run, identity):
        directory = run["directory"]
        try:
            if not self.dry_run:
                run["status"] = "authorising"
                print("\nSetup confirmed in the browser. Approve sudo here if requested.", flush=True)
                if subprocess.run(["sudo", "-v"], check=False).returncode:
                    raise OSError("Administrator authorisation was cancelled in Terminal. Nothing was installed.")
            env = {k: v for k, v in os.environ.items() if not k.startswith("MAC_SETUP_")}
            env.update({"MAC_SETUP_ROOT": str(ROOT), "MAC_SETUP_STATE_DIR": str(directory), "MAC_SETUP_RUN_ID": run["id"],
                   "MAC_SETUP_EVENT_FILE": str(directory / "events.tsv"),
                   "MAC_SETUP_REPORT_RAW": str(directory / "reports" / (run["id"] + ".tsv")),
                   "MAC_SETUP_GIT_NAME": identity["name"].strip(), "MAC_SETUP_GIT_EMAIL": identity["email"].strip(),
                   "MAC_SETUP_GITHUB_USER": "", "MAC_SETUP_GIT_SSH_SIGNING": "0"})
            # Never accept a caller-supplied active Brewfile or inherited mode.
            env["MAC_SETUP_BREWFILE"] = str(ROOT / "Brewfile")
            env["MAC_SETUP_BRITX"] = "0"
            env["DRY_RUN"] = "1" if self.dry_run else "0"
            env["MAC_SETUP_TEST"] = "1" if self.dry_run else "0"
            followups = [i for i in run["items"] if i["type"] in {"manual", "web", "mcp"}]
            with Path(env["MAC_SETUP_REPORT_RAW"]).open("w") as report:
                for item in followups:
                    detail = f"{item['url']}|{item['description']}|Open the official guide and complete setup with your own account."
                    report.write(f"MANUAL\tconnections\t{item['name']}\t{detail}\n")
            args = ["bash", str(ROOT / "install.sh"), "--selection", str(directory / "selection.txt"), "--yes"]
            if self.dry_run:
                args.append("--dry-run")
            with (directory / "output.log").open("w") as output:
                run["status"] = "running"
                self.process = subprocess.Popen(args, cwd=ROOT, env=env, stdin=subprocess.DEVNULL,
                                                stdout=output, stderr=subprocess.STDOUT)
                code = self.process.wait()
            run["exitCode"] = code
            run["status"] = "complete" if code == 0 else "needs_attention"
        except OSError as error:
            run["status"] = "failed"
            run["error"] = str(error)

    def snapshot(self):
        """Project real module events and reports; dry runs remain labelled previews."""
        with self.lock:
            run = self.run
            if not run:
                return {"status": "idle", "dryRun": self.dry_run}
            directory = run["directory"]
            planned = {"xcode", "brew", "apps", "mas", "verification"}
            for item in run["items"]:
                if item["type"] == "step":
                    planned.add(item["token"])
                elif item["type"] == "pref" and item["token"].split(":")[0] in {"macos", "security"}:
                    planned.add(item["token"].split(":")[0])
            states = {module: "pending" for module in MODULES if module in planned}
            events = directory / "events.tsv"
            if events.exists():
                for line in events.read_text(errors="replace").splitlines():
                    fields = line.split("\t")
                    if len(fields) != 3 or fields[1] not in states:
                        continue
                    phase, module, code = fields
                    states[module] = "running" if phase == "start" else ("complete" if code == "0" else "needs_attention")
            records = []
            report = directory / "reports" / (run["id"] + ".tsv")
            if report.exists():
                for line in report.read_text(errors="replace").splitlines():
                    fields = line.split("\t", 3)
                    if len(fields) == 4:
                        status, module, item, detail = fields
                        records.append({"status": status, "module": module, "item": item, "detail": detail})
                        state_module = "verification" if module == "verify" else module
                        if status == "FAIL" and state_module in states:
                            states[state_module] = "needs_attention"
            finished = run["status"] in TERMINAL
            if finished:
                states = {m: ("skipped" if s == "pending" else s) for m, s in states.items()}
            output = directory / "output.log"
            log = ""
            if output.exists():
                with output.open("rb") as stream:
                    stream.seek(max(0, output.stat().st_size - 16000))
                    log = stream.read().decode("utf-8", errors="replace")
            return {"id": run["id"], "status": run["status"], "dryRun": self.dry_run,
                    "modules": [{"id": m, "status": s} for m, s in states.items()],
                    "records": records, "log": log, "error": run["error"], "exitCode": run["exitCode"],
                    "reports": [key for key, name in {"install": "install-report.md", "manual": "manual-actions.md"}.items()
                                if (directory / "reports" / name).is_file()]}


class Handler(BaseHTTPRequestHandler):
    """Serve only public assets and authenticated local APIs; reject cross-site traffic."""

    server_version = "mac-setup"

    def log_message(self, *_args):
        # Access logs must not retain session credentials or plan/identity data.
        pass

    def respond(self, status, body, content_type="application/json; charset=utf-8", download=None):
        if not isinstance(body, bytes):
            body = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        self.send_header("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'")
        if download:
            self.send_header("Content-Disposition", f'attachment; filename="{download}"')
        self.end_headers()
        self.wfile.write(body)

    def allowed(self, authenticate=False):
        host = f"127.0.0.1:{self.server.server_port}"
        if self.headers.get("Host") != host:
            self.respond(403, {"error": "Invalid local host."})
            return False
        if self.headers.get("Origin") not in (None, "http://" + host) or self.headers.get("Sec-Fetch-Site") == "cross-site":
            self.respond(403, {"error": "Only this local setup page can access the companion."})
            return False
        if authenticate:
            auth = self.headers.get("Authorization", "")
            if not secrets.compare_digest(auth.encode(), ("Bearer " + self.server.app.token).encode()):
                self.respond(401, {"error": "Open the private setup link printed in Terminal."})
                return False
        return True

    def do_GET(self):
        path = urlsplit(self.path).path
        if not self.allowed(authenticate=path.startswith("/api/")):
            return
        app = self.server.app
        if path == "/health":
            self.respond(200, {"status": "ready"})
        elif path == "/api/session":
            self.respond(200, {"dryRun": app.dry_run, "platform": platform.system(),
                               "architecture": platform.machine(), "plan": app.initial_plan,
                               "catalogVersion": app.catalog["version"]})
        elif path == "/api/state":
            self.respond(200, app.snapshot())
        elif path.startswith("/api/reports/"):
            names = {"install": "reports/install-report.md", "manual": "reports/manual-actions.md",
                     "verification": "reports/verification-report.md", "log": "output.log"}
            key = path.rsplit("/", 1)[-1]
            if not app.run or key not in names:
                self.respond(404, {"error": "Report not found."})
                return
            report = app.run["directory"] / names[key]
            if not report.is_file():
                self.respond(404, {"error": "This report is not available yet."})
                return
            self.respond(200, report.read_bytes(), "text/plain; charset=utf-8", report.name)
        elif path == "/assets/catalog.json":
            self.respond(200, app.catalog)
        else:
            root = ROOT / "docs"
            file = (root / ("index.html" if path == "/" else unquote(path).lstrip("/"))).resolve()
            if root.resolve() not in file.parents or not file.is_file() or (file not in (root / "index.html", root / "safety.html") and not path.startswith("/assets/")):
                self.respond(404, {"error": "Page not found."})
                return
            self.respond(200, file.read_bytes(), mimetypes.guess_type(str(file))[0] or "application/octet-stream")

    def do_POST(self):
        if not self.allowed(authenticate=True):
            return
        if self.path != "/api/runs":
            self.respond(404, {"error": "Unknown action."})
            return
        if self.headers.get("Content-Type", "").split(";", 1)[0] != "application/json":
            self.respond(415, {"error": "Send a JSON setup plan."})
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 65536:
                raise PlanError("Invalid request size.")
            body = json.loads(self.rfile.read(length))
            result = self.server.app.start(body)
        except (PlanError, ValueError, UnicodeError) as error:
            self.respond(400, {"error": str(error)})
            return
        self.respond(202, result)


def make_server(app, port=0):
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    server.daemon_threads = True
    server.app = app
    return server


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="preview commands; never install or apply preferences")
    parser.add_argument("--no-browser", action="store_true")
    parser.add_argument("--port", type=int, default=0)
    parser.add_argument("--plan", type=Path, help="open an exported browser plan")
    parser.add_argument("--state-dir", type=Path)
    args = parser.parse_args()
    if not args.dry_run and (platform.system() != "Darwin" or os.geteuid() == 0):
        parser.exit(1, "Run as a regular macOS user, or use --dry-run to preview.\n")
    os.umask(0o077)
    state = args.state_dir or (Path(tempfile.mkdtemp(prefix="mac-setup-preview-")) if args.dry_run else Path.home() / ".local/state/mac-setup/web")
    app = Application(state, args.dry_run)
    if args.plan:
        try:
            app.initial_plan = load_plan(args.plan, app.catalog)
        except (OSError, PlanError) as error:
            parser.exit(2, f"{error}\n")
    try:
        server = make_server(app, args.port)
    except OSError as error:
        parser.exit(1, f"Could not open the local companion: {error}\n")
    url = f"http://127.0.0.1:{server.server_port}/#session={app.token}"
    print(f"{'DRY RUN — commands only' if args.dry_run else 'LOCAL SETUP — review before installing'}\n{url}\nKeep Terminal open. Press Control-C to stop the companion.", flush=True)
    if not args.no_browser:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        if app.process and app.process.poll() is None:
            app.process.send_signal(signal.SIGINT)
            if app.run:
                app.run["status"] = "interrupted"
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
