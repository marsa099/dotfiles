#!/usr/bin/env python3
import importlib.machinery
import importlib.util
from pathlib import Path
import shlex
import tempfile
import unittest
from unittest.mock import patch, Mock

PATH = Path(__file__).resolve().parents[1] / 'herdr-new-pi-tab'
loader = importlib.machinery.SourceFileLoader('new_pi_tab', str(PATH))
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class NewPiTabTests(unittest.TestCase):
    def test_name_cwd_and_safe_command(self):
        with tempfile.TemporaryDirectory() as cwd:
            source = {'foreground_cwd': cwd, 'cwd': '/', 'workspace_id': 'w4'}
            name = "Fix auth's bug; $(touch /tmp/never-run-this)"
            created = {'root_pane': {'pane_id': 'w4:p8'}, 'tab': {'tab_id': 'w4:t3'}}
            with patch.object(module, 'herdr', side_effect=[created, {}, {}]) as api:
                module.create_pi_tab(source, name)
            calls = [call.args for call in api.call_args_list]
            self.assertEqual(calls[0], ('tab', 'create', '--workspace', 'w4',
                                       '--cwd', cwd, '--label', name, '--no-focus'))
            self.assertEqual(calls[1][:3], ('pane', 'run', 'w4:p8'))
            self.assertEqual(shlex.split(calls[1][3]), ['pi', '--name', name])
            self.assertEqual(calls[2], ('tab', 'focus', 'w4:t3'))

    def test_missing_cwd_does_not_create_tab(self):
        with patch.object(module, 'herdr') as api:
            with self.assertRaisesRegex(RuntimeError, 'nothing created'):
                module.create_pi_tab({'workspace_id': 'w1'}, 'name')
            api.assert_not_called()

    def test_cancel_does_not_create_tab(self):
        with patch.dict(module.os.environ, {'HERDR_ENV': '1', 'HERDR_ACTIVE_PANE_ID': 'w1:p4'}), \
             patch.object(module, 'herdr', return_value={'pane': {'cwd': '/'}}) as api, \
             patch.object(module.curses, 'wrapper', return_value=None):
            module.main()
            api.assert_called_once_with('pane', 'get', 'w1:p4')

    def test_start_failure_keeps_new_tab_and_reports_id(self):
        created = {'root_pane': {'pane_id': 'w1:p2'}, 'tab': {'tab_id': 'w1:t2'}}
        with patch.object(module, 'herdr', side_effect=[created, RuntimeError('not ready')]) as api:
            with self.assertRaisesRegex(RuntimeError, 'Tab w1:t2 was created'):
                module.create_pi_tab({'cwd': '/', 'workspace_id': 'w1'}, 'test')
            self.assertEqual(api.call_count, 2)

    def test_successful_mutation_without_json(self):
        result = Mock(returncode=0, stdout='', stderr='')
        with patch.object(module.subprocess, 'run', return_value=result):
            self.assertEqual(module.herdr('pane', 'run', 'w1:p2', 'pi'), {})

    def test_prompt_blank_editing_and_escape(self):
        screen = Mock()
        screen.getmaxyx.return_value = (7, 70)
        screen.get_wch.side_effect = ['\n', 'a', 'x', '\x7f', 'b', '\n']
        with patch.object(module.curses, 'curs_set'):
            self.assertEqual(module.prompt_name(screen), 'ab')
            screen.get_wch.side_effect = ['\x1b']
            self.assertIsNone(module.prompt_name(screen))

    def test_rejects_outside_herdr(self):
        with patch.dict(module.os.environ, {'HERDR_ENV': '0'}), patch.object(module, 'herdr') as api:
            with self.assertRaisesRegex(RuntimeError, 'inside Herdr'):
                module.main()
            api.assert_not_called()


if __name__ == '__main__':
    unittest.main()
