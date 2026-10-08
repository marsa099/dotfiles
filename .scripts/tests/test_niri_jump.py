"""Run with python3 .scripts/tests/test_niri_jump.py."""
import json
import os
from pathlib import Path
import runpy
import re
import socket
import threading
from unittest.mock import patch
import subprocess
import tempfile
import unittest
import uuid

HELPER = Path(__file__).resolve().parents[2] / '.config/niri/scripts/niri-jump-or-exec'
choose = runpy.run_path(str(HELPER))['choose_window']


class NiriJumpTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.tracker = self.root / 'tracker'
        self.cycle = self.root / 'cycle'
        self.windows = [
            {'id': 1, 'title': "Team's client", 'app_id': 'chat',
             'focus_timestamp': {'secs': 1, 'nanos': 0}},
            {'id': 2, 'title': "Team's client", 'app_id': 'chat',
             'focus_timestamp': {'secs': 2, 'nanos': 0}},
            {'id': 3, 'title': None, 'app_id': None, 'is_focused': True},
        ]

    def select(self, pattern='chat'):
        return choose(self.windows, pattern, self.tracker, self.cycle)

    def test_matching_and_recency(self):
        self.assertEqual(self.select(), 2)
        self.assertEqual(self.select("title:^TEAM'S CLIENT$"), 2)
        self.assertEqual(self.select('regex:^cha'), 2)
        self.assertIsNone(self.select('missing'))

    def test_focused_window_cycles_and_wraps(self):
        self.windows[2]['is_focused'] = False
        self.windows[1]['is_focused'] = True
        self.assertEqual(self.select(), 1)
        self.windows[1]['is_focused'] = False
        self.windows[0]['is_focused'] = True
        self.assertEqual(self.select(), 2)

    def test_state_priority_and_stale_fallback(self):
        self.tracker.write_text('1')
        self.cycle.write_text('2')
        self.assertEqual(self.select(), 1)
        self.tracker.write_text('999')
        self.cycle.write_text('1')
        self.assertEqual(self.select(), 1)
        self.cycle.write_text('999')
        self.assertEqual(self.select(), 2)

    def test_one_window_cycles_to_itself_and_missing_timestamp(self):
        self.windows = [{'id': 1, 'app_id': 'chat', 'is_focused': True}]
        self.assertEqual(self.select(), 1)

    def test_invalid_regex_is_rejected(self):
        with self.assertRaises(re.error):
            self.select('regex:[')

    def run_helper(self, windows, command):
        app = 'test-niri-jump-' + uuid.uuid4().hex
        cycle = Path('/tmp/niri-cycle-' + app)
        self.addCleanup(lambda: cycle.unlink(missing_ok=True))
        log = self.root / 'calls'
        niri = self.root / 'niri'
        niri.write_text('''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['LOG'], 'a') as f:
    f.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[-1] == 'windows':
    print(os.environ['WINDOWS'])
''')
        niri.chmod(0o755)
        env = dict(os.environ, PATH=f'{self.root}:{os.environ["PATH"]}',
                   LOG=str(log), WINDOWS=json.dumps(windows(app)))
        env.pop('NIRI_SOCKET', None)
        result = subprocess.run(['python3', str(HELPER), app, command], env=env,
                                capture_output=True, text=True)
        return result, [json.loads(x) for x in log.read_text().splitlines()], cycle

    def test_direct_socket_query(self):
        address = str(self.root / 'niri.sock')
        requests = []
        with socket.socket(socket.AF_UNIX) as server:
            server.bind(address)
            server.listen(1)
            server.settimeout(3)

            def respond():
                with server.accept()[0] as connection:
                    requests.append(connection.recv(4096))
                    connection.sendall((json.dumps({'Ok': {'Windows': self.windows}})
                                        + '\n').encode())

            worker = threading.Thread(target=respond)
            worker.start()
            try:
                with patch.dict(os.environ, NIRI_SOCKET=address):
                    actual = runpy.run_path(str(HELPER))['get_windows']()
                self.assertEqual(actual, self.windows)
            finally:
                worker.join(timeout=3)
            self.assertEqual(requests, [b'"Windows"\n'])

    def test_focus_queries_once_and_updates_cycle(self):
        result, calls, cycle = self.run_helper(
            lambda app: [{'id': 42, 'app_id': app}], 'unused')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [['msg', '--json', 'windows'],
                                 ['msg', 'action', 'focus-window', '--id', '42']])
        self.assertEqual(cycle.read_text().strip(), '42')

    def test_launch_queries_once_and_preserves_quoted_arguments(self):
        output = self.root / 'launched'
        command = f"python3 -c \"from pathlib import Path; Path('{output}').write_text('launched')\""
        result, calls, cycle = self.run_helper(lambda app: [], command)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [['msg', '--json', 'windows']])
        self.assertEqual(output.read_text(), 'launched')
        self.assertFalse(cycle.exists())


if __name__ == '__main__':
    unittest.main()
