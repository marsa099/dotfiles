"""Run with python3 .scripts/tests/test_tmqs_launcher.py."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

LAUNCHER = Path(__file__).resolve().parents[2] / '.config/niri/scripts/launch-teams-client'


class TmqsLauncherTests(unittest.TestCase):
    def run_launcher(self, ipc_ok):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            log = root / 'calls'
            source = LAUNCHER.read_text()
            # Production PATH selects installed binaries; tests isolate them.
            source = '\n'.join(line for line in source.splitlines()
                               if not line.startswith('export PATH='))
            script = root / 'launcher'
            script.write_text(source)
            stubs = {
                'qs': 'echo "qs $*" >> "$CALL_LOG"; if [ "$1" = ipc ]; then exit "$IPC_STATUS"; fi',
                'niri': 'echo niri >> "$CALL_LOG"; echo "[]"',
                'pgrep': 'echo pgrep >> "$CALL_LOG"; exit 1',
                'setsid': 'echo daemon >> "$CALL_LOG"',
            }
            for name, body in stubs.items():
                stub = root / name
                stub.write_text('#!/usr/bin/env bash\n' + body + '\n')
                stub.chmod(0o755)
            env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                       HOME=str(root), CALL_LOG=str(log), IPC_STATUS='0' if ipc_ok else '1')
            subprocess.run(['bash', str(script)], env=env, check=True)
            calls = log.read_text().splitlines()
            return calls, str(root / 'repos/tmqs/ui')

    def test_warm_reopen_skips_cleanup_and_new_ui(self):
        calls, path = self.run_launcher(True)
        self.assertEqual(calls, [f'qs ipc -p {path} call window openWindow'])

    def test_unavailable_ipc_falls_back_to_normal_startup(self):
        calls, path = self.run_launcher(False)
        self.assertEqual(calls[0], f'qs ipc -p {path} call window openWindow')
        self.assertIn('niri', calls)
        self.assertIn(f'qs -p {path}', calls)


if __name__ == '__main__':
    unittest.main()
