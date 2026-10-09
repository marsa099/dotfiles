"""Run with python3 .scripts/tests/test_dsqrd_launcher.py."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

LAUNCHER = Path(__file__).resolve().parents[2] / '.config/niri/scripts/launch-discord-client'


class DiscordLauncherTests(unittest.TestCase):
    def run_launcher(self, ipc_ok, installed='/nix/store/current-dsqrd'):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            log = root / 'calls'
            script = root / 'launcher'
            script.write_text('\n'.join(line for line in LAUNCHER.read_text().splitlines()
                                        if not line.startswith('export PATH=')))
            stubs = {
                'dsqrd': 'exit 0',
                'readlink': 'echo "$INSTALLED/bin/dsqrd"',
                'qs': 'echo "qs $*" >> "$CALL_LOG"; exit "$IPC_STATUS"',
                'niri': 'echo niri >> "$CALL_LOG"; echo "[]"',
                'pgrep': 'exit 1',
                'dsqrd-client': 'echo dsqrd-client >> "$CALL_LOG"',
            }
            for name, body in stubs.items():
                stub = root / name
                stub.write_text('#!/usr/bin/env bash\n' + body + '\n')
                stub.chmod(0o755)
            env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                       HOME=str(root), CALL_LOG=str(log), INSTALLED=installed,
                       IPC_STATUS='0' if ipc_ok else '1')
            subprocess.run(['bash', str(script)], env=env, check=True)
            return log.read_text().splitlines()

    def test_warm_reopen_skips_cleanup_and_new_client(self):
        self.assertEqual(self.run_launcher(True),
                         ['qs ipc -p /nix/store/current-dsqrd/share/dsqrd/ui call window openWindow'])

    def test_unavailable_ipc_runs_cleanup_and_packaged_client(self):
        calls = self.run_launcher(False)
        self.assertIn('niri', calls)
        self.assertEqual(calls[-1], 'dsqrd-client')

    def test_installed_package_selects_exact_ui_after_upgrade(self):
        self.assertEqual(self.run_launcher(True, '/nix/store/new-dsqrd'),
                         ['qs ipc -p /nix/store/new-dsqrd/share/dsqrd/ui call window openWindow'])


if __name__ == '__main__':
    unittest.main()
