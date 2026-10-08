"""Run with python3 .scripts/tests/test_teams_launcher.py."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

LAUNCHER = Path(__file__).resolve().parents[1] / "teams-launcher"


class TeamsLauncherTests(unittest.TestCase):
    def run_launcher(self, scenario, args=(), stock=False):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            if stock:
                flag = root / "teams-launcher/use-stock"
                flag.parent.mkdir()
                flag.touch()
            bus = root / "busctl"
            bus.write_text('''#!/usr/bin/env python3
import json, os, sys
args = sys.argv[1:]
with open(os.environ['CALL_LOG'], 'a') as log:
    log.write(json.dumps(['busctl'] + args) + '\\n')
scenario = os.environ['SCENARIO']
if scenario == 'unavailable':
    sys.exit(1)
if args[-1] == 'RegisteredStatusNotifierItems':
    items = [] if scenario == 'absent' else [':1.40/Other', ':1.999/StatusNotifierItem']
    print(json.dumps({'type': 'as', 'data': items}))
elif args[-1] == 'Id':
    name = 'other-app' if ':1.40' in args else 'teams-for-linux_status_icon_1'
    print(json.dumps({'type': 's', 'data': name}))
elif 'Activate' in args:
    sys.exit(1 if scenario == 'disappeared' else 0)
else:
    sys.exit(2)
''')
            bus.chmod(0o755)
            for name in ('teams-for-linux', 'teams-for-linux-stock'):
                stub = root / name
                stub.write_text('''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['CALL_LOG'], 'a') as log:
    log.write(json.dumps([os.path.basename(sys.argv[0])] + sys.argv[1:]) + '\\n')
''')
                stub.chmod(0o755)
            log = root / 'calls'
            env = dict(os.environ, PATH=f'{root}:{os.environ["PATH"]}',
                       XDG_CONFIG_HOME=str(root), SCENARIO=scenario, CALL_LOG=str(log))
            subprocess.run(['bash', str(LAUNCHER), *args], env=env, check=True)
            return [json.loads(line) for line in log.read_text().splitlines()]

    def test_activate_discovered_owner_only(self):
        calls = self.run_launcher('running')
        activation = [c for c in calls if 'Activate' in c]
        self.assertEqual(len(activation), 1)
        self.assertIn(':1.999', activation[0])
        self.assertFalse(any(c[0].startswith('teams-for-linux') for c in calls))

    def test_cold_start_and_failures_fall_back(self):
        for scenario in ('absent', 'unavailable', 'disappeared'):
            with self.subTest(scenario=scenario):
                self.assertEqual(self.run_launcher(scenario)[-1], ['teams-for-linux'])

    def test_stock_selection_on_cold_start(self):
        self.assertEqual(self.run_launcher('absent', stock=True)[-1],
                         ['teams-for-linux-stock'])

    def test_arguments_bypass_tray_and_are_preserved(self):
        args = ['msteams://example/a b', '--example']
        self.assertEqual(self.run_launcher('running', args), [['teams-for-linux', *args]])

    def test_stock_arguments_are_preserved(self):
        self.assertEqual(self.run_launcher('running', ['--version'], stock=True),
                         [['teams-for-linux-stock', '--version']])


if __name__ == '__main__':
    unittest.main()
