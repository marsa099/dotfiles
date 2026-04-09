#!/bin/bash

# Claude Code Stop Hook
# Triggers when Claude finishes responding and waits for input

LOG="$HOME/.cache/claude/hooks.log"
ICON="$HOME/.config/claude/icons/claude-code.svg"
STATE_DIR="/tmp/claude-permissions"

if [ -n "$TMUX_PANE" ]; then
    INSTANCE_ID="${TMUX_PANE#%}"
else
    INSTANCE_ID="d$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' | grep -oP 'pts/\K\d+')"
    [ "$INSTANCE_ID" = "d" ] && INSTANCE_ID=""
fi

echo "$(date '+%Y-%m-%dT%H:%M:%S.%3N') [stop] Claude finished" >> "$LOG"

# Clean up any pending permission state for this instance
if [ -n "$INSTANCE_ID" ]; then
    [ -f "$STATE_DIR/notif-id-${INSTANCE_ID}" ] && dunstify -C "$(cat "$STATE_DIR/notif-id-${INSTANCE_ID}")" 2>/dev/null
    rm -f "$STATE_DIR/$INSTANCE_ID" "$STATE_DIR/tool-info-${INSTANCE_ID}.json" "$STATE_DIR/notif-id-${INSTANCE_ID}"
fi

if [ -n "$TMUX" ]; then
    printf '\033]2;Claude: Waiting for input \xe2\x8c\xa8\033\\'
    printf '\a'
fi

STOP_ID=$(dunstify "Claude Code" "Ready for input" \
    --stack-tag "claude-stop-${INSTANCE_ID}" \
    -u normal -I "$ICON" -p)
[ -n "$INSTANCE_ID" ] && echo "$STOP_ID" > "$STATE_DIR/stop-notif-id-${INSTANCE_ID}"
