#!/bin/bash
# Clean up permission notification state after tool use completes
STATE_DIR="/tmp/claude-permissions"
if [ -n "$TMUX_PANE" ]; then
    ID="${TMUX_PANE#%}"
else
    ID="d$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' | grep -oP 'pts/\K\d+')"
    [ "$ID" = "d" ] && exit 0
fi
NID="$STATE_DIR/notif-id-${ID}"
[ -f "$NID" ] && dunstify -C "$(cat "$NID")" 2>/dev/null
rm -f "$STATE_DIR/$ID" "$STATE_DIR/tool-info-${ID}.json" "$NID"
