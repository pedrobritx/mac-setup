"""Boundary, transport and real dry-run integration tests; never install software."""
import copy
import http.client
import json
import os
from pathlib import Path
import subprocess
import tempfile
import threading
import time
import unittest
from unittest.mock import patch

from web.catalog import ROOT, build_catalog
from web.plan import PlanError, validate_plan, compile_selection
from web.server import Application, make_server, TERMINAL

CATALOG = build_catalog()

def plan(*extra):
    return {'schema': 1, 'catalogVersion': CATALOG['version'], 'profile': 'essentials',
            'selected': ['step:xcode', 'step:brew', *extra]}

class PlanTests(unittest.TestCase):
    def test_minimal_plan_is_valid(self):
        self.assertEqual({i['id'] for i in validate_plan(plan(), CATALOG)}, {'step:xcode', 'step:brew'})

    def test_untrusted_shapes_are_rejected(self):
        for invalid in [None, [], {}, {**plan(), 'command': 'rm -rf /'}, {**plan(), 'selected': [None]},
                        {**plan(), 'selected': ['step:brew']}, {**plan(), 'profile': 'other'},
                        {**plan(), 'schema': True}, {**plan(), 'catalogVersion': 'old'}, {**plan(), 'profile': []},
                        plan('step:brew'), plan('cask:does-not-exist'), plan('step:python')]:
            with self.subTest(value=invalid), self.assertRaises(PlanError):
                validate_plan(invalid, CATALOG)

    def test_shell_fragments_are_never_compiled(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'selection'
            with self.assertRaises(PlanError):
                compile_selection(plan('$(touch /tmp/mac-setup-injected)'), CATALOG, output)
            self.assertFalse(output.exists())

    def test_followups_do_not_become_executable_selection_keys(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'selection'
            items = compile_selection(plan('mcp:figma', 'manual:vmware', 'web:google-docs'), CATALOG, output)
            self.assertEqual(len(items), 5)
            self.assertEqual(set(output.read_text().splitlines()), {'step:xcode', 'step:brew'})

    def test_shipped_catalogue_matches_current_installer(self):
        self.assertEqual(json.loads((ROOT / 'docs/assets/catalog.json').read_text()), CATALOG)

class TransportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory()
        cls.app = Application(cls.temp.name, dry_run=True)
        cls.server = make_server(cls.app)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown(); cls.server.server_close(); cls.thread.join(); cls.temp.cleanup()

    def request(self, method='GET', path='/api/session', data=None, headers=None):
        connection = http.client.HTTPConnection('127.0.0.1', self.server.server_port, timeout=10)
        connection.request(method, path, body=json.dumps(data) if data is not None else None, headers=headers or {})
        response = connection.getresponse(); content = response.read(); status = response.status
        connection.close(); return status, content

    def auth(self, **extra):
        return {'Authorization': 'Bearer ' + self.app.token, **extra}

    def test_private_state_requires_session_token(self):
        for path in ['/api/session', '/api/state', '/api/reports/install']:
            self.assertEqual(self.request(path=path)[0], 401)

    def test_same_origin_authenticated_session_is_available(self):
        status, content = self.request(headers=self.auth())
        self.assertEqual(status, 200); self.assertTrue(json.loads(content)['dryRun'])

    def test_foreign_origins_and_rebound_hosts_are_rejected(self):
        self.assertEqual(self.request(headers=self.auth(Origin='https://evil.example'))[0], 403)
        self.assertEqual(self.request(headers=self.auth(Host='evil.example'))[0], 403)
        self.assertEqual(self.request(headers=self.auth(**{'Sec-Fetch-Site': 'cross-site'}))[0], 403)

    def test_source_files_and_path_traversal_are_not_served(self):
        for path in ['/install.sh', '/config/settings.sh', '/assets/../../config/settings.sh', '/assets/%2e%2e/%2e%2e/config/settings.sh']:
            self.assertEqual(self.request(path=path)[0], 404)

    def test_safety_page_and_bundled_icons_are_public_but_repository_files_are_not(self):
        status, content = self.request(path='/safety.html')
        self.assertEqual(status, 200)
        self.assertIn(b'Safety &amp; privacy', content)
        self.assertNotIn(self.app.token.encode(), content)
        self.assertEqual(self.request(path='/assets/icons/mac-figma.png')[0], 200)
        for path in ['/LICENSE', '/README.md', '/safety.html/../README.md']:
            self.assertEqual(self.request(path=path)[0], 404)

    def test_public_catalogue_has_no_account_or_session_details(self):
        status, content = self.request(path='/assets/catalog.json')
        self.assertEqual(status, 200)
        self.assertNotIn(self.app.token.encode(), content)
        self.assertNotIn(b'pedrohbrito@', content)

    def test_mutations_require_json_and_explicit_confirmation(self):
        with patch.object(self.app, '_execute') as execute:
            self.assertEqual(self.request('POST', '/api/runs', {'plan': plan(), 'confirm': True}, self.auth())[0], 415)
            self.assertEqual(self.request('POST', '/api/runs', {'plan': plan(), 'confirm': False}, self.auth(**{'Content-Type': 'application/json'}))[0], 400)
            execute.assert_not_called()

    def test_identity_cannot_inject_control_characters(self):
        with self.assertRaises(PlanError):
            self.app.start({'plan': plan(), 'confirm': True, 'identity': {'name': 'Name\ncommand', 'email': 'x@example.com'}})

    def test_simultaneous_installations_are_rejected(self):
        self.app.run = {'status': 'running'}
        try:
            with self.assertRaises(PlanError): self.app.start({'plan': plan(), 'confirm': True})
        finally: self.app.run = None

class InstallerTests(unittest.TestCase):
    def test_optional_framework_reuses_existing_checkout_and_manages_reversible_links(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory) / 'home'; home.mkdir()
            (home / '.zshrc').write_text('original config\n')
            checkout = home / '.oh-my-zsh'; checkout.mkdir()
            (checkout / 'oh-my-zsh.sh').write_text('# existing framework\n')
            (checkout / 'personal-plugin').write_text('preserve me\n')
            active = Path(directory) / 'Brewfile'; active.write_text('# no optional packages\n')
            state = Path(directory) / 'state'
            env = {**os.environ, 'HOME': str(home), 'SHELL': '/bin/zsh', 'MAC_SETUP_TEST': '1',
                   'DRY_RUN': '0', 'MAC_SETUP_STATE_DIR': str(state), 'MAC_SETUP_RUN_ID': 'terminal-test',
                   'MAC_SETUP_BREWFILE': str(active), 'MAC_SETUP_PREF_OHMYZSH': '1'}
            for _ in range(2):
                result = subprocess.run(['bash', 'scripts/terminal.sh'], cwd=ROOT, env=env,
                                        capture_output=True, text=True, timeout=20)
                self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
                self.assertNotIn('git clone', result.stdout)
            self.assertEqual((checkout / 'personal-plugin').read_text(), 'preserve me\n')
            framework = home / '.config/mac-setup/shell.zsh'
            self.assertTrue(framework.is_symlink())
            self.assertIn('MAC_SETUP_USE_OH_MY_ZSH=1', framework.read_text())
            self.assertEqual((state / 'backups/terminal-test/.zshrc').read_text(), 'original config\n')
            self.assertIn(str(framework), (state / 'manifest/symlinks.tsv').read_text())

    def test_exact_selection_runs_real_installer_without_changing_the_home(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory) / 'home'; home.mkdir()
            binaries = Path(directory) / 'bin'; binaries.mkdir()
            brew = binaries / 'brew'
            brew.write_text('#!/bin/sh\nif [ "$1" = "--version" ]; then echo "Homebrew test fixture"; else exit 1; fi\n')
            brew.chmod(0o755)
            sentinel = home / '.zshrc'; sentinel.write_text('original shell config\n')
            environment = {'HOME': str(home), 'PATH': str(binaries) + ':/usr/bin:/bin:/usr/sbin:/sbin', 'SHELL': '/bin/zsh'}
            with patch.dict(os.environ, environment):
                app = Application(Path(directory) / 'state', dry_run=True)
                app.start({'plan': plan('brew:git', 'mcp:figma'), 'confirm': True})
                deadline = time.monotonic() + 40
                while app.run['status'] not in TERMINAL and time.monotonic() < deadline:
                    time.sleep(.05)
                snapshot = app.snapshot()
            self.assertIn(snapshot['status'], TERMINAL, 'dry run did not finish')
            self.assertEqual(snapshot['exitCode'], 0, snapshot['log'])
            self.assertEqual(sentinel.read_text(), 'original shell config\n')
            self.assertFalse((home / '.ssh').exists())
            active = next(app.run['directory'].glob('active-brewfile-*')).read_text()
            self.assertIn('brew "git"', active)
            self.assertFalse(any(line.startswith(('cask "', 'mas "', 'tap "')) for line in active.splitlines()))
            self.assertNotIn('brew upgrade', snapshot['log'])
            self.assertNotIn('zsh-autosuggestions', (app.run['directory'] / 'reports/verification-report.md').read_text())
            self.assertEqual({m['id'] for m in snapshot['modules']}, {'xcode', 'brew', 'apps', 'mas', 'verification'})
            self.assertTrue(any(r['status'] == 'MANUAL' and r['item'] == 'Figma MCP' for r in snapshot['records']))
            self.assertFalse(any(r['item'] == 'VMware Fusion' for r in snapshot['records']))
            self.assertIn('install', snapshot['reports'])

    def test_bash_rejects_unknown_keys_without_evaluating_them(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'selection'; sentinel = Path(directory) / 'executed'
            path.write_text('$(touch ' + str(sentinel) + ')\n')
            env = {**os.environ, 'HOME': directory, 'MAC_SETUP_TEST': '1', 'MAC_SETUP_STATE_DIR': directory + '/state'}
            result = subprocess.run(['bash', 'install.sh', '--selection', str(path), '--dry-run', '--yes'],
                                    cwd=ROOT, env=env, capture_output=True, text=True, timeout=20)
            self.assertEqual(result.returncode, 2)
            self.assertFalse(sentinel.exists())
            self.assertFalse(list(Path(directory).glob('state/active-brewfile-*')))

if __name__ == '__main__': unittest.main()
