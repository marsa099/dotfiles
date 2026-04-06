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
    [ -f "$STATE_DIR/$PANE_NUM" ] && dunstify "" --stack-tag "claude-perm-$PANE_NUM" -t 1 2>/dev/null
    rm -f "$STATE_DIR/$PANE_NUM" "$STATE_DIR/tool-info-${PANE_NUM}.json"
fi

if [ -n "$TMUX" ]; then
    printf '\033]2;Claude: Waiting for input ⌨\033\\'
    printf '\a'
fi

dunstify "Claude Code" "Ready for input" \
    --stack-tag "claude-stop-$PANE_NUM" \
    -u normal -I "$ICON"
