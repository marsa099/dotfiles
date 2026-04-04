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
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

echo "$(ts) [notification] type=$TYPE" >> "$LOG"

# Extract the actual tool use details from the transcript
get_tool_detail() {
    [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || return
    tac "$TRANSCRIPT" | grep -m1 '"tool_use"' | jq -r '
        .message.content[] | select(.type == "tool_use") |
        if .name == "Bash" then "Bash: \(.input.command)"
        elif .name == "Edit" then "Edit: \(.input.file_path)"
        elif .name == "Write" then "Write: \(.input.file_path)"
        elif .name == "Read" then "Read: \(.input.file_path)"
        else .name
        end
    ' 2>/dev/null | tail -1
}

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
    TOOL_DETAIL=$(get_tool_detail)
    DETAIL="${TOOL_DETAIL:-$MESSAGE}"
    TOOL_NAME="${DETAIL%%: *}"
    TOOL_CMD="${DETAIL#*: }"

    # Word-wrap long commands into multiple header lines
    WRAPPED=$(echo "$TOOL_CMD" | fold -s -w 60)
    HEADER_LINES=$(echo "$WRAPPED" | wc -l)
    TOTAL_LINES=$((HEADER_LINES + 4)) # header + separator + 3 options

    ITEMS=$(printf "── %s ──\n%s\n1. Allow\n2. Always Allow\n3. Deny" "$TOOL_NAME" "$WRAPPED")
    LONGEST=$(echo "$ITEMS" | awk '{l=length; if(l>m) m=l} END{print m+4}')
    CHOICE=$(echo "$ITEMS" | fuzzel --dmenu \
        --prompt "Permission: " \
        --width "$LONGEST" --lines "$TOTAL_LINES")

    KEY=""
    case "$CHOICE" in
        "1. Allow")        KEY="1" ;;
        "2. Always Allow") KEY="2" ;;
        "3. Deny")         KEY="3" ;;
    esac

    echo "$(ts) [notification] choice=\"$CHOICE\" key=$KEY wid=$WINDOW_ID tool=\"$TOOL_DETAIL\"" >> "$LOG"

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
