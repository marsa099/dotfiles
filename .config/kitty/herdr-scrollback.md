# Herdr scrollback, styled like Kitty

The native `edit_scrollback` action writes unwrapped plain text and opens the normal
editor. This replacement reads the **original pane's wrapped ANSI history**, including
the current screen, into a standalone Neovim terminal pager. It opens at the bottom.
No command is sent to the original shell or agent; running sessions are untouched.

## Enable

Merge these entries into `~/.config/herdr/config.toml` (do not duplicate `[keys]`):

```toml
[keys]
edit_scrollback = []

[[keys.command]]
key = ["prefix+e", "ctrl+shift+e"]
command = "$HOME/.scripts/herdr-scrollback"
type = "popup"
width = "100%"
height = "100%"
description = "Kitty-style color scrollback"
```

Run `herdr server reload-config`. No server restart is required. With the existing
prefix, press **Ctrl+Space, e**, or use **Ctrl+Shift+E** directly in a dedicated
Herdr Kitty window. Press **q** or **Escape** to return.

- `j` / `k`, Page Up / Page Down: move through the snapshot.
- `/text`, `n` / `N`: search.
- `v` / `V`, then `y`: select and copy to the clipboard without closing.
- `gg` / `G`: oldest / newest output; `zh` / `zl`: horizontal movement.

The clipboard follows `ksb-minimal.lua`: trim surrounding whitespace and copy
characterwise, so pasting a command does not submit it automatically.

## Fidelity and limits

Colors, Unicode, box drawing, blank lines within the capture, and the TUI's current
prompt/footer are preserved. Kitty's generated `theme.conf` supplies the 16-color
palette. The pager hides editor bars, uses relative numbers, and does not load the
normal editor's plugins. The snapshot is static; it is not a live mirror.

Herdr's popup border and surrounding sidebar/tab bar remain. The line-number gutter
and popup border use columns; very wide rows may need horizontal scrolling rather
than being rewrapped. Kitty graphics/images and Kitty's shell-command navigation are
not reproduced. Herdr can only provide the history it still retains (up to 100,000
rows are requested); a pager cannot reconstruct overwritten alternate-screen rows.
The temporary capture is private (0600) and removed when the pager exits; an abrupt
kill or machine crash can leave the file behind, like other temporary files.

## Tests

```sh
python3 .scripts/tests/test-herdr-scrollback.py
```

Tests exercise ANSI decoding, Unicode, preserved long rows, retained footer, bottom
positioning, minimal window options, original-pane targeting, private temporary
files, failure cleanup, and rejecting use outside Herdr.

## Undo

Remove the custom command table and remove `edit_scrollback = []`, then run
`herdr server reload-config`. The native editor binding becomes available again.
