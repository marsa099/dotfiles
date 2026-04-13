#!/bin/bash

# Claude Code Permission Go-To (multi-instance)
# Called by niri keybinding to focus the currently selected Claude instance
# Uses the selection from permission-navigate.sh, or most recent if none selected
#
# Usage: permission-goto.sh

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_DIR="/tmp/claude-permissions"
ICON="$HOME/.config/claude/icons/claude-code.png"
LAST_NAV_FILE="$STATE_DIR/.last-navigate"

# Use navigated selection if available, otherwise most recent
TARGET=""
if [ -f "$LAST_NAV_FILE" ]; then
    NAV_TARGET=$(cat "$LAST_NAV_FILE")
    [ -f "$STATE_DIR/$NAV_TARGET" ] && TARGET="$NAV_TARGET"
fi
if [ -z "$TARGET" ]; then
    TARGET=$(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '*-*' -printf '%T@ %f\n' 2>/dev/null | sort -n | head -1 | awk '{print $2}')
fi

if [ -z "$TARGET" ]; then
    dunstify "Claude Code" "No pending permissions" \
        --stack-tag claude-nav -I "$ICON" -u low -t 3000
    echo "$(ts) [goto] no pending permissions" >> "$LOG"
    exit 0
fi

STATE_FILE="$STATE_DIR/$TARGET"
INSTANCE_TYPE=$(grep '^instance_type=' "$STATE_FILE" 2>/dev/null | cut -d= -f2)

if [ "$INSTANCE_TYPE" = "tmux" ]; then
    PANE=$(grep '^pane=' "$STATE_FILE" 2>/dev/null | cut -d= -f2)
    if [ -z "$PANE" ]; then
        echo "$(ts) [goto] error: empty pane in state file $TARGET" >> "$LOG"
        exit 1
    fi
    # Focus the ghostty terminal window in niri
    GHOSTTY_WID=$(niri msg windows 2>/dev/null | awk '
        /^Window ID/ { id = $3; sub(/:$/, "", id) }
        /App ID:.*com\.mitchellh\.ghostty/ { print id; exit }
    ')
    [ -n "$GHOSTTY_WID" ] && niri msg action focus-window --id "$GHOSTTY_WID"
    # Switch tmux to the target pane
    tmux select-pane -t "$PANE" 2>/dev/null
    tmux select-window -t "$PANE" 2>/dev/null
    echo "$(ts) [goto] focused pane=$PANE target=$TARGET [tmux]" >> "$LOG"
else
    WINDOW_ID=$(grep '^window_id=' "$STATE_FILE" 2>/dev/null | cut -d= -f2)
    if [ -z "$WINDOW_ID" ]; then
        echo "$(ts) [goto] error: no window_id in state file $TARGET" >> "$LOG"
        exit 1
    fi
    niri msg action focus-window --id "$WINDOW_ID" 2>/dev/null
    echo "$(ts) [goto] focused window=$WINDOW_ID target=$TARGET [direct]" >> "$LOG"
fi
