# Direct Herdr shortcuts

Merge into the existing `[keys]` table in `~/.config/herdr/config.toml`:

```toml
previous_workspace = "ctrl+shift+h"
next_workspace = "ctrl+shift+l"
previous_agent = ["prefix+shift+a", "ctrl+shift+j"]
next_agent = ["prefix+a", "ctrl+shift+k"]
```

The scrollback custom command uses `key = ["prefix+e", "ctrl+shift+e"]`.
The former direct Ctrl+Shift+S/A bindings are no longer assigned to Herdr.

Kitty's config forwards H/L/J/K/E only when its initial window command contains
an executable named `herdr` (either `herdr` or an absolute path ending `/herdr`).
This matches the Niri launchers: `kitty --class=herdr -e herdr`.
Normal Kitty windows retain their scrolling, layout, URL hints, and Kitty scrollback
bindings; primary-selection paste (S) and opacity controls (A) are restored too.
This conditional does not detect Herdr subsequently launched inside a normal shell
window: use the dedicated Herdr launcher for these overrides.

Ctrl+Shift+E normally invokes Kitty URL hints. Its “No matches found” screen means
no URLs were found, not a Herdr/Neovim failure. In a dedicated Herdr window the key
now reaches Herdr and opens the ANSI scrollback pager instead.

Reload Herdr with `herdr server reload-config` and reload the relevant Kitty window
configuration. No pane processes need restarting.
