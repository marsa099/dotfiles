#!/bin/bash

# Claude Code Notification Hook
# For permission prompts: shows rich dunst notification with keybinding hints
# For other notifications: shows simple dunst notification
# Saves tmux pane target for global keybinding response
#
# Requires: jq, dunstify, tmux, niri

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_FILE="/tmp/claude-permission-pane"
ICON="$HOME/.config/claude/icons/claude-code.svg"

INPUT=$(cat)
TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs attention"')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

echo "$(ts) [notification] type=$TYPE" >> "$LOG"

# Extract tool use details from the transcript
get_tool_info() {
    [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || return
    tac "$TRANSCRIPT" | grep -m1 '"tool_use"' | jq -r '
        .message.content[] | select(.type == "tool_use") |
        {
            name: .name,
            command: (.input.command // null),
            file_path: (.input.file_path // null),
            description: (.input.description // null),
            pattern: (.input.pattern // null)
        } | to_entries | map(select(.value != null)) | from_entries
    ' 2>/dev/null
}

# Check if Claude Code's terminal window (ghostty) is focused in niri
# Walks from the tmux client PID up to find the ghostty window
is_terminal_focused() {
    local focused_wid
    focused_wid=$(niri msg focused-window 2>/dev/null | awk '/^Window ID/ {print $3; exit}' | tr -d ':')
    [ -z "$focused_wid" ] && return 1

    # Find the starting PID: tmux client if in tmux, otherwise our own PID
    local start_pid=$$
    [ -n "$TMUX" ] && start_pid=$(tmux display-message -p '#{client_pid}' 2>/dev/null)
    [ -z "$start_pid" ] && return 1

    local windows
    windows=$(niri msg windows 2>/dev/null)

    local pid=$start_pid
    while [ "$pid" != "1" ] && [ -n "$pid" ] && [ "$pid" != "0" ]; do
        local wid
        wid=$(echo "$windows" | awk -v p="$pid" '
            /^Window ID/ { id = $3; sub(/:$/, "", id) }
            /PID:/ && $2 == p { print id; exit }
        ')
        if [ -n "$wid" ]; then
            [ "$wid" = "$focused_wid" ] && return 0
            return 1
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
    return 1
}

if [ "$TYPE" = "permission_prompt" ]; then
    # Save tmux pane for keybinding scripts
    # Use $TMUX_PANE (env var = subprocess's actual pane) not display-message (= client's viewed pane)
    if [ -n "$TMUX" ]; then
        PANE="$TMUX_PANE"
        echo "$PANE" > "$STATE_FILE"
        echo "$(ts) [notification] saved pane=$PANE" >> "$LOG"
    fi

    # Extract tool details
    TOOL_JSON=$(get_tool_info)
    TOOL_NAME=$(echo "$TOOL_JSON" | jq -r '.name // empty' 2>/dev/null)
    TOOL_CMD=$(echo "$TOOL_JSON" | jq -r '.command // empty' 2>/dev/null)
    TOOL_FILE=$(echo "$TOOL_JSON" | jq -r '.file_path // empty' 2>/dev/null)
    TOOL_DESC=$(echo "$TOOL_JSON" | jq -r '.description // empty' 2>/dev/null)
    TOOL_PATTERN=$(echo "$TOOL_JSON" | jq -r '.pattern // empty' 2>/dev/null)

    # Build notification body
    BODY="<b>${TOOL_NAME:-Tool}</b>"
    [ -n "$TOOL_CMD" ] && BODY="$BODY\n$TOOL_CMD"
    [ -n "$TOOL_FILE" ] && BODY="$BODY\n$TOOL_FILE"
    [ -n "$TOOL_PATTERN" ] && BODY="$BODY\nPattern: $TOOL_PATTERN"
    [ -n "$TOOL_DESC" ] && BODY="$BODY\n<i>$TOOL_DESC</i>"
    BODY="$BODY\n\nAllow <b>(Ctrl+Super+Y)</b>\nAlways Allow <b>(Ctrl+Super+A)</b>\nDeny <b>(Ctrl+Super+N)</b>"

    echo "$(ts) [notification] permission: tool=$TOOL_NAME cmd=\"$TOOL_CMD\" file=\"$TOOL_FILE\"" >> "$LOG"

    # Check if our pane is the one the user is currently looking at
    PANE_VISIBLE=false
    if [ -n "$TMUX" ] && [ -n "$PANE" ]; then
        CLIENT_ACTIVE_PANE=$(tmux list-clients -F '#{pane_id}' 2>/dev/null | head -1)
        [ "$CLIENT_ACTIVE_PANE" = "$PANE" ] && PANE_VISIBLE=true
        echo "$(ts) [notification] our_pane=$PANE client_active=$CLIENT_ACTIVE_PANE visible=$PANE_VISIBLE" >> "$LOG"
    fi

    if is_terminal_focused && [ "$PANE_VISIBLE" = true ]; then
        echo "$(ts) [notification] skipped: terminal is focused" >> "$LOG"
    else
        dunstify "Claude Code - Permission" "$BODY" \
            --stack-tag claude-prompt \
            -u critical -I "$ICON" -t 0
    fi
else
    dunstify "$TITLE" "$MESSAGE" \
        --stack-tag claude-prompt \
        -u normal -I "$ICON"
    echo "$(ts) [notification] dunst sent: $TITLE - $MESSAGE" >> "$LOG"
fi
