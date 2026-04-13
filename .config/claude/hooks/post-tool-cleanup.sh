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
if [ -f "$NID" ]; then
    nid_val=$(cat "$NID")
    [ -n "$nid_val" ] && dunstify -C "$nid_val" 2>/dev/null
fi
rm -f "$STATE_DIR/$ID" "$STATE_DIR/tool-info-${ID}.json" "$NID"
# Clean up .last-navigate if it points to this instance or no pending remain
NAV="$STATE_DIR/.last-navigate"
if [ -f "$NAV" ]; then
    nav_val=$(cat "$NAV")
    if [ "$nav_val" = "$ID" ] || [ -z "$(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '*-*' ! -name '*.json' 2>/dev/null)" ]; then
        rm -f "$NAV"
    fi
fi
