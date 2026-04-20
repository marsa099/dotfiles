#!/bin/bash
# Clean up permission notification state after tool use completes.
STATE_DIR="/tmp/claude-permissions"
if [ -n "$TMUX_PANE" ]; then
    ID="${TMUX_PANE#%}"
else
    ID="d$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' | grep -oP 'pts/\K\d+')"
    [ "$ID" = "d" ] && exit 0
fi
# Only clean up if this instance has pending state
[ -f "$STATE_DIR/$ID" ] || exit 0
bash ~/.config/claude/hooks/cleanup-instance.sh "$ID"
