#!/usr/bin/env python3
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
                                   {'pane_id': 'w1:p2', 'offset_from_bottom': 42})

    def test_page_directions_and_bounds(self):
        offset = module['page_offset']
        scroll = {'viewport_rows': 44, 'offset_from_bottom': 50, 'max_offset_from_bottom': 100}
        self.assertEqual(offset(scroll, 1), 92)
        self.assertEqual(offset(scroll, -1), 8)
        scroll['offset_from_bottom'] = 90
        self.assertEqual(offset(scroll, 1), 100)
        scroll['offset_from_bottom'] = 0
        self.assertEqual(offset(scroll, -1), 0)
        scroll['viewport_rows'] = 1
        self.assertEqual(offset(scroll, 1), 1)


if __name__ == '__main__':
    unittest.main()
