"""Collect native dry-run evidence; never authorize a real installation."""

import argparse
import json
import os
from pathlib import Path
import platform
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]


def collect(output):
    """Record only checks actually executed, including refusals and failures."""
    evidence = {
        "platform": platform.system(),
        "machine": platform.machine(),
        "macOS": platform.mac_ver()[0],
        "python": platform.python_version(),
        "mode": "dry-run",
        "realInstallationPerformed": False,
        "status": "not_run",
        "syntaxChecks": [],
        "checks": [],
    }
    code = 0
    try:
        if evidence["platform"] != "Darwin":
            evidence["reason"] = "Native macOS is required for this evidence."
            return 2
        evidence["sourceCommit"] = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
        ).strip()
        evidence["worktreeDirty"] = bool(subprocess.check_output(
            ["git", "status", "--porcelain"], cwd=ROOT, text=True
        ).strip())
        evidence["systemBash"] = subprocess.check_output(
            ["/bin/bash", "--version"], text=True
        ).splitlines()[0]
        evidence["status"] = "running"
        scripts = subprocess.check_output(
            ["git", "ls-files", "*.sh"], cwd=ROOT, text=True
        ).splitlines()
        for script in scripts:
            result = subprocess.run(
                ["/bin/bash", "-n", script], cwd=ROOT, timeout=60, check=False
            )
            evidence["syntaxChecks"].append({
                "path": script, "exitCode": result.returncode,
            })
            result.check_returncode()
        with tempfile.TemporaryDirectory(prefix="mac-setup-native-qa-") as home:
            # Do not inherit installer overrides from a developer's shell.
            env = {
                key: value for key, value in os.environ.items()
                if not key.startswith("MAC_SETUP_")
            }
            env.update({
                "HOME": home,
                "DRY_RUN": "1",
                "MAC_SETUP_TEST": "1",
                "MAC_SETUP_ROOT": str(ROOT),
                "MAC_SETUP_STATE_DIR": str(Path(home) / "state"),
            })
            for args in (
                ["--help"], ["--list"], ["--dry-run", "--yes"],
                ["--dry-run", "--britx"],
            ):
                result = subprocess.run(
                    ["/bin/bash", "./install.sh", *args],
                    cwd=ROOT, env=env, timeout=60, check=False,
                )
                evidence["checks"].append({
                    "args": args, "exitCode": result.returncode,
                })
                result.check_returncode()
        evidence["status"] = "passed"
    except (OSError, subprocess.SubprocessError) as error:
        evidence["status"] = "failed"
        evidence["error"] = str(error)
        code = 1
    finally:
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_text(json.dumps(evidence, indent=2) + "\n")
        print(f"Native acceptance evidence: {evidence['status']} — {output}")
        summary = {
            key: evidence[key] for key in (
                "platform", "machine", "macOS", "status",
                "realInstallationPerformed",
            )
        }
        summary["syntaxCheckCount"] = len(evidence["syntaxChecks"])
        summary["smokeCheckCount"] = len(evidence["checks"])
        for key in ("sourceCommit", "error", "reason"):
            if key in evidence:
                summary[key] = evidence[key]
        print(json.dumps(summary, sort_keys=True))
    return code


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output", type=Path,
        default=ROOT / "test-results/native-macos/summary.json",
    )
    raise SystemExit(collect(parser.parse_args().output))
