#!/usr/bin/env python3
"""Validate compiled Kitty maps, not opts.map (which is consumed by load_config)."""
import os
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[2]
code = r'''
import os, re
from kitty.config import load_config
from kitty.options.utils import parse_shortcut
errors = []
o = load_config(os.environ['TEST_KITTY_CONFIG'], accumulate_bad_lines=errors)
assert not errors, errors
maps = o.keyboard_modes[''].keymap
for letter in 'hljkeud':
    definitions = maps[parse_shortcut('ctrl+shift+' + letter)]
    conditional = definitions[-1]
    assert conditional.definition == 'send_key ctrl+shift+' + letter
    query = conditional.options.when_focus_on
    assert query == 'cmdline:^herdr$ or cmdline:/herdr$'
    # Exercise Kitty's expression parser too: unquoted regex parentheses are
    # interpreted as query grouping, even though config parsing accepts them.
    from kitty.search_query_parser import search
    def match(location, pattern, candidates):
        assert location == 'cmdline'
        return {item for item in candidates if re.search(pattern, item)}
    candidates = {'herdr', '/run/current-system/sw/bin/herdr', '/bin/bash', 'herdr-helper'}
    assert search(query, ('cmdline',), candidates, match) == {'herdr', '/run/current-system/sw/bin/herdr'}
    assert any(not d.options.when_focus_on and d.definition for d in definitions[:-1])
assert any(d.definition == 'open_url_with_hints' for d in maps[parse_shortcut('ctrl+shift+e')])
assert any(d.definition.startswith('kitty_scrollback_nvim') for d in maps[parse_shortcut('ctrl+shift+h')])
assert any(d.definition == 'paste_from_selection' for d in maps[parse_shortcut('ctrl+shift+s')])
assert any(d.definition.startswith('set_background_opacity') for d in maps[parse_shortcut('ctrl+shift+a')])
assert any(d.definition == 'scroll_page_up' for d in maps[parse_shortcut('ctrl+shift+u')])
assert any(d.definition == 'scroll_page_down' for d in maps[parse_shortcut('ctrl+shift+d')])
print('PASS: seven conditional forwards; ordinary Kitty mappings retained; S/A/U/D fallbacks kept')
'''
subprocess.run(['kitty', '+runpy', code], check=True,
               env=dict(os.environ, TEST_KITTY_CONFIG=str(root / '.config/kitty/kitty.conf')))
