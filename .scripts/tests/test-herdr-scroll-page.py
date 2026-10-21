#!/usr/bin/env python3
import json
import runpy
from pathlib import Path
import unittest
from unittest.mock import patch, Mock

module = runpy.run_path(str(Path(__file__).resolve().parents[1] / 'herdr-scroll-page'))


class PageTests(unittest.TestCase):
    def test_server_command_without_pane_environment(self):
        namespace = module['main'].__globals__
        response = {'pane': {'scroll': {'viewport_rows': 44, 'offset_from_bottom': 0,
                                       'max_offset_from_bottom': 100}}}
        request = Mock(side_effect=[response, {}])
        with patch.dict(namespace['os'].environ,
                        {'HERDR_ACTIVE_PANE_ID': 'w1:p2', 'HERDR_SOCKET_PATH': '/tmp/test.sock'},
                        clear=True), patch.object(namespace['sys'], 'argv', ['scroll', 'up']), \
             patch.dict(namespace, {'request': request}):
            module['main']()
        request.assert_called_with('/tmp/test.sock', 'pane.scroll',
                                   {'pane_id': 'w1:p2', 'offset_from_bottom': 22})

    def test_pi_shortcuts_scroll_transcript(self):
        namespace = module['main'].__globals__
        response = {'pane': {'agent': 'pi', 'scroll': {
            'viewport_rows': 53, 'offset_from_bottom': 0,
            'max_offset_from_bottom': 0}}}
        for direction, key in [('up', 'ctrl+shift+u'), ('down', 'ctrl+shift+d')]:
            with self.subTest(direction=direction):
                request = Mock(side_effect=[response, {}])
                with patch.dict(namespace['os'].environ, {
                    'HERDR_ACTIVE_PANE_ID': 'w1:p2',
                    'HERDR_PANE_ID': 'w1:p9',
                    'HERDR_SOCKET_PATH': '/tmp/test.sock',
                }, clear=True), patch.object(namespace['sys'], 'argv', ['scroll', direction]), \
                     patch.dict(namespace, {'request': request}):
                    module['main']()
                self.assertEqual(request.call_count, 2)
                request.assert_called_with('/tmp/test.sock', 'pane.send_keys',
                                           {'pane_id': 'w1:p2', 'keys': [key]})

    def test_pi_bindings_match_forwarded_keys(self):
        root = Path(__file__).resolve().parents[2]
        bindings = json.loads((root / '.pi/agent/keybindings.json').read_text())
        self.assertEqual(bindings['tui.altScreen.halfPageUp'], 'ctrl+shift+u')
        self.assertEqual(bindings['tui.altScreen.halfPageDown'], 'ctrl+shift+d')

    def test_pi_navigation_errors_are_not_silenced(self):
        namespace = module['main'].__globals__
        request = Mock(side_effect=[{'pane': {'agent': 'pi'}}, RuntimeError('rejected')])
        with patch.dict(namespace['os'].environ, {
            'HERDR_ACTIVE_PANE_ID': 'w1:p2', 'HERDR_SOCKET_PATH': '/tmp/test.sock',
        }, clear=True), patch.object(namespace['sys'], 'argv', ['scroll', 'up']), \
             patch.dict(namespace, {'request': request}):
            with self.assertRaisesRegex(RuntimeError, 'rejected'):
                module['main']()

    def test_page_directions_and_bounds(self):
        offset = module['page_offset']
        scroll = {'viewport_rows': 44, 'offset_from_bottom': 50, 'max_offset_from_bottom': 100}
        self.assertEqual(offset(scroll, 1), 72)
        self.assertEqual(offset(scroll, -1), 28)
        scroll['viewport_rows'] = 45
        self.assertEqual(offset(scroll, 1), 72)
        scroll['offset_from_bottom'] = 90
        self.assertEqual(offset(scroll, 1), 100)
        scroll['offset_from_bottom'] = 0
        self.assertEqual(offset(scroll, -1), 0)
        scroll['viewport_rows'] = 1
        self.assertEqual(offset(scroll, 1), 1)


if __name__ == '__main__':
    unittest.main()
