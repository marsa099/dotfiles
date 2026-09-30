# Named Herdr tabs

Merge into `~/.config/herdr/config.toml` (merge existing tables, do not duplicate them):

```toml
[terminal]
new_cwd = "follow"

[ui]
prompt_new_tab_name = true

[keys]
new_tab = "prefix+c"

[[keys.command]]
key = "prefix+shift+c"
command = "$HOME/.scripts/herdr-new-pi-tab"
type = "popup"
width = "60%"
height = 9
description = "Named Pi tab in current directory"
```

Run `herdr server reload-config` without restarting any sessions.

- **Ctrl+Space, c:** native name prompt, named shell tab following the current pane cwd.
- **Ctrl+Space, Shift+C:** name prompt, same cwd and workspace, named tab running
  `pi --name <name>`. The Pi session name is exactly the tab name, including spaces.
- **Escape** in the Pi-tab prompt cancels without creating anything. Blank input does
  not create a tab. Ctrl+U clears the name.

The helper reads the original pane ID passed by Herdr, not the popup's own pane.
It snapshots the source pane's foreground cwd before prompting, falling back to its
reported cwd only if no foreground cwd is available. A missing directory is an error,
not a silent fallback to home. The name is passed as a CLI argument and shell-quoted
for Pi, never evaluated as shell code.

Pi is launched as an ordinary interactive program: normal authentication and project
trust prompts are retained. Sending its launch command does not guarantee Pi has
finished startup. A launch error leaves the newly created tab intact and reports its
ID; it does not close existing work or retry commands into another pane.

Tests: `python3 .scripts/tests/test-herdr-new-pi-tab.py`.
