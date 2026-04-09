#!/bin/bash
# Save tool info from PermissionRequest for the notification hook to read
# Per-instance file to support multiple Claude instances
mkdir -p /tmp/claude-permissions
if [ -n "$TMUX_PANE" ]; then
    INSTANCE_ID="${TMUX_PANE#%}"
else
    INSTANCE_ID="d$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' | grep -oP 'pts/\K\d+')"
    [ "$INSTANCE_ID" = "d" ] && exit 0
fi
cat | jq -c '{tool_name: .tool_name, tool_input: .tool_input}' > "/tmp/claude-permissions/tool-info-${INSTANCE_ID}.json" 2>/dev/null
