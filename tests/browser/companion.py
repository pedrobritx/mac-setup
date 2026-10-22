"""Isolated test-only companion. The fixed token is never used by the launcher."""
import os
from pathlib import Path
import sys
import tempfile
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from web.server import Application, make_server

with tempfile.TemporaryDirectory(prefix='mac-setup-browser-test-') as directory:
    home = Path(directory) / 'home'
    home.mkdir()
    os.environ.update({'HOME': str(home), 'PATH': '/usr/bin:/bin:/usr/sbin:/sbin', 'SHELL': '/bin/zsh'})
    app = Application(Path(directory) / 'state', dry_run=True)
    app.token = 'browser-test-session-only'
    server = make_server(app, 3420)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
