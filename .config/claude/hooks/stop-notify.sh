#!/bin/bash

# Claude Code Stop Hook
# Triggers when Claude finishes responding and waits for input

LOG="$HOME/.cache/claude/hooks.log"
ICON="$HOME/.config/claude/icons/claude-code.svg"
STATE_DIR="/tmp/claude-permissions"
PANE_NUM="${TMUX_PANE#%}"

echo "$(date '+%Y-%m-%dT%H:%M:%S.%3N') [stop] Claude finished" >> "$LOG"

# Clean up any pending permission state for this pane
if [ -n "$PANE_NUM" ]; then
    [ -f "$STATE_DIR/notif-id-${PANE_NUM}" ] && dunstify -C "$(cat "$STATE_DIR/notif-id-${PANE_NUM}")" 2>/dev/null
    rm -f "$STATE_DIR/$PANE_NUM" "$STATE_DIR/tool-info-${PANE_NUM}.json" "$STATE_DIR/notif-id-${PANE_NUM}"
fi

if [ -n "$TMUX" ]; then
    printf '\033]2;Claude: Waiting for input ⌨\033\\'
    printf '\a'
fi

STOP_ID=$(dunstify "Claude Code" "Ready for input" \
    --stack-tag "claude-stop-$PANE_NUM" \
    -u normal -I "$ICON" -p)
echo "$STOP_ID" > "$STATE_DIR/stop-notif-id-${PANE_NUM}"
