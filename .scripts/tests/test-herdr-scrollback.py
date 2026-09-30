#!/usr/bin/env python3
"""Run with python3 .scripts/tests/test-herdr-scrollback.py (requires nvim)."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
PAGER = ROOT / '.scripts/herdr-scrollback'
CONFIG = ROOT / '.config/kitty/herdr-scrollback.lua'


class ScrollbackTests(unittest.TestCase):
    def test_ansi_unicode_wrapping_footer_and_minimal_ui(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            capture = folder / 'capture.ansi'
            result = folder / 'result.json'
            expected = ['Orange heading', 'X' * 180, '─' * 100,
                        '👋 🧠 input prompt', '⚡ fast (inactive) ● ADHD ON']
            capture.write_text('\x1b[38;2;255;87;13mOrange heading\x1b[0m\n' +
                               '\n'.join(expected[1:]) + '\n')
            # Also test completed-terminal rendering with history longer than the viewport.
            for prefix in ('', ''.join(f'history {i}\n' for i in range(150))):
                capture.write_text(prefix + '\x1b[38;2;255;87;13mOrange heading\x1b[0m\n' +
                                   '\n'.join(expected[1:]) + '\n')
                check = folder / 'check.lua'
                check.write_text('''
vim.defer_fn(function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- The first inspection enables hlstate; redraw once after enabling it.
  vim.api.nvim__inspect_cell(1, 0, 0)
  vim.cmd('redraw!')
  local orange = false
  for row = 0, vim.o.lines - 2 do
    for col = 0, math.min(30, vim.o.columns - 1) do
      local cell = vim.api.nvim__inspect_cell(1, row, col)
      if cell[2] and cell[2].foreground == 0xff570d then orange = true end
    end
  end
  local result = {
    orange = orange,
    extmarks = vim.api.nvim_buf_get_extmarks(0, -1, 0, -1, { details = true }),
    ready = vim.g.herdr_scrollback_ready or false,
    lines = lines, cursor = vim.api.nvim_win_get_cursor(0),
    laststatus = vim.o.laststatus, showtabline = vim.o.showtabline,
    cmdheight = vim.o.cmdheight, number = vim.wo.number,
    relativenumber = vim.wo.relativenumber, wrap = vim.wo.wrap,
    modifiable = vim.bo.modifiable, modified = vim.bo.modified,
    q = vim.fn.maparg('q', 'n'),
  }
  vim.fn.writefile({vim.json.encode(result)}, vim.env.TEST_RESULT)
  vim.cmd('qa!')
end, 700)
''')
                env = dict(os.environ, HERDR_SCROLLBACK_FILE=str(capture), TEST_RESULT=str(result))
                subprocess.run(['nvim', '--headless', '--noplugin', '-n', '-i', 'NONE',
                                '-u', str(CONFIG), '+luafile ' + str(check)],
                               env=env, check=True, timeout=10, capture_output=True)
                data = json.loads(result.read_text())
                self.assertTrue(data['ready'])
                self.assertTrue(data['orange'], 'ANSI RGB must survive terminal rendering')
                self.assertFalse(data['extmarks'], 'No process-exit banner should remain')
                self.assertEqual(data['lines'][-5:], expected)
                self.assertEqual(len(data['lines']), 155 if prefix else 5)
                self.assertEqual(data['cursor'], [len(data['lines']), 0])
                for key in ('laststatus', 'showtabline', 'cmdheight'):
                    self.assertEqual(data[key], 0)
                for key in ('number', 'relativenumber'):
                    self.assertTrue(data[key])
                for key in ('wrap', 'modifiable', 'modified'):
                    self.assertFalse(data[key])
                self.assertIn('qa!', data['q'])

    def test_launcher_targets_original_pane_and_cleans_private_capture(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            mock_herdr = folder / 'herdr'
            mock_herdr.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
Path(os.environ['TEST_ARGS']).write_text(json.dumps(sys.argv[1:]))
if os.environ.get('FAIL_CAPTURE'): sys.exit(1)
print('\\x1b[31mhello\\x1b[0m')
''')
            mock_nvim = folder / 'nvim'
            mock_nvim.write_text('''#!/usr/bin/env python3
import json, os
from pathlib import Path
p = Path(os.environ['HERDR_SCROLLBACK_FILE'])
Path(os.environ['TEST_CAPTURE']).write_text(json.dumps({
    'path': str(p), 'mode': p.stat().st_mode & 0o777, 'text': p.read_text()}))
''')
            for mock in (mock_herdr, mock_nvim):
                mock.chmod(0o755)
            env = dict(os.environ, PATH=str(folder) + ':' + os.environ['PATH'],
                       HERDR_ENV='1', HERDR_ACTIVE_PANE_ID='w1:p2', HERDR_PANE_ID='w1:p99',
                       TEST_ARGS=str(folder / 'args'), TEST_CAPTURE=str(folder / 'capture'),
                       TMPDIR=str(folder))
            subprocess.run([str(PAGER)], env=env, check=True)
            self.assertEqual(json.loads((folder / 'args').read_text()),
                             ['pane', 'read', 'w1:p2', '--source', 'recent', '--lines', '100000',
                              '--format', 'ansi', '--raw'])
            data = json.loads((folder / 'capture').read_text())
            self.assertEqual(data['mode'], 0o600)
            self.assertIn('\x1b[31m', data['text'])
            self.assertFalse(Path(data['path']).exists())
            (folder / 'capture').unlink()
            failed = subprocess.run([str(PAGER)], env=dict(env, FAIL_CAPTURE='1'))
            self.assertNotEqual(failed.returncode, 0)
            self.assertFalse((folder / 'capture').exists())
            self.assertEqual(list(folder.glob('herdr-pager.*')), [])

    def test_rejects_use_outside_herdr(self):
        env = dict(os.environ, HERDR_ENV='0')
        result = subprocess.run([str(PAGER)], env=env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('inside Herdr', result.stderr)


if __name__ == '__main__':
    unittest.main()
