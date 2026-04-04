#!/bin/bash

# Claude Code Notification Hook
# For permission prompts: shows fuzzel popup with action choices
# For other notifications: shows dunst notification
#
# Requires: jq, dunstify, fuzzel, niri, wtype

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }

INPUT=$(cat)
TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs attention"')

echo "$(ts) [notification] type=$TYPE" >> "$LOG"

# Find niri window ID by walking process tree to terminal PID
find_niri_window_id() {
    local window_pids
    window_pids=$(niri msg windows 2>/dev/null) || return 1

    local pid=$$
    while [ "$pid" != "1" ] && [ -n "$pid" ]; do
        local wid
        wid=$(echo "$window_pids" | awk -v p="$pid" '
            /^Window ID/ { id = $3; sub(/:$/, "", id) }
            /PID:/ && $2 == p { print id; exit }
        ')
        if [ -n "$wid" ]; then
            echo "$wid"
            return 0
        fi
        pid=$(awk '{print $4}' /proc/$pid/stat 2>/dev/null)
    done
    return 1
}

WINDOW_ID=""
[ -z "$TMUX" ] && WINDOW_ID=$(find_niri_window_id)

if [ "$TYPE" = "permission_prompt" ] && [ -n "$WINDOW_ID" ]; then
    CHOICE=$(printf "1. Allow\n2. Always Allow\n3. Deny" | fuzzel --dmenu \
        --prompt "$MESSAGE: " \
        --width 50 --lines 3)

    KEY=""
    case "$CHOICE" in
        "1. Allow")        KEY="1" ;;
        "2. Always Allow") KEY="2" ;;
        "3. Deny")         KEY="3" ;;
    esac

    echo "$(ts) [notification] choice=\"$CHOICE\" key=$KEY wid=$WINDOW_ID" >> "$LOG"

    if [ -n "$KEY" ]; then
        setsid bash -c "
            niri msg action focus-window --id $WINDOW_ID
            wtype -k $KEY
        " </dev/null &
        disown
    fi
else
    dunstify "$TITLE" "$MESSAGE" \
        --stack-tag claude-prompt \
        -u normal -i robot
    echo "$(ts) [notification] dunst sent: $TITLE - $MESSAGE" >> "$LOG"
fi
