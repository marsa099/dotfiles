# Herdr workspace prompts and agent-sidebar emphasis

These settings are applied in the local `~/.config/herdr/config.toml`, which is not
tracked in this repository. Merge into existing tables rather than duplicating them:

```toml
[ui]
prompt_new_workspace_name = true

[ui.sidebar.agents]
rows = [
  ["state_icon", "machine", { token = "tab", fg = "#abb2bf", bold = true, dim = false }],
  [{ token = "workspace", fg = "#5c6370", bold = false, dim = true }],
]
```

The first row shows the state icon, machine (when applicable), and bright/bold tab
name. The second row shows only the dimmed space name; the agent type is hidden.
The prominent label is Herdr's tab name, not the Pi session name. Our
`herdr-new-pi-tab` helper gives both the same name at creation. The colors match the
current One Dark palette; revisit the hex colors if changing themes.

Reload with `herdr server reload-config`; no process restart is needed.
New interactive workspaces now prompt for a name (default shortcut with our prefix:
Ctrl+Space, Shift+N). Explicit CLI/API workspace creation is separate from the UI prompt.
