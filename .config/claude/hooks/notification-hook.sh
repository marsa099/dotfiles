#!/bin/bash

# Claude Code Notification Hook
# For permission prompts: shows rich dunst notification with keybinding hints
# For other notifications: shows simple dunst notification
# Saves per-instance state for multi-instance keybinding response
#
# Requires: jq, dunstify, tmux, niri

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_DIR="/tmp/claude-permissions"
ICON="$HOME/.config/claude/icons/claude-code.svg"

mkdir -p "$STATE_DIR"

INPUT=$(cat)
TYPE=$(echo "$INPUT" | jq -r '.notification_type // empty')
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Needs attention"')
TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty')

echo "$(ts) [notification] type=$TYPE" >> "$LOG"

# Extract tool details saved by PermissionRequest hook, fallback to transcript
get_tool_info() {
    local pane_num="${TMUX_PANE#%}"
    local info_file="/tmp/claude-permissions/tool-info-${pane_num}.json"
    if [ -f "$info_file" ]; then
        local tool_name
        tool_name=$(jq -r '.tool_name // empty' "$info_file" 2>/dev/null)
        if [ -n "$tool_name" ]; then
            jq --arg name "$tool_name" '{
                name: $name,
                command: (.tool_input.command // null),
                file_path: (.tool_input.file_path // null),
                description: (.tool_input.description // null),
                pattern: (.tool_input.pattern // null),
                prompt: (.tool_input.prompt // null),
                subagent_type: (.tool_input.subagent_type // null)
            } | to_entries | map(select(.value != null)) | from_entries' "$info_file" 2>/dev/null
            return
        fi
    fi
    # Fallback: parse transcript
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
    PANE="$TMUX_PANE"
    PANE_NUM="${TMUX_PANE#%}"
    SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
    WINDOW_NAME=$(tmux display-message -t "$PANE" -p '#{window_name}' 2>/dev/null)
    WINDOW_IDX=$(tmux display-message -t "$PANE" -p '#{window_index}' 2>/dev/null)
    LABEL="${SESSION:-claude}:${WINDOW_IDX}"

    # Detect prompt type: Yes/No vs Allow/Always Allow/Deny
    PROMPT_TYPE="permission"
    if echo "$MESSAGE" | grep -qi "Do you want to proceed"; then
        PROMPT_TYPE="yesno"
    fi

    # Save per-instance state file
    if [ -n "$TMUX" ] && [ -n "$PANE_NUM" ]; then
        printf 'pane=%s\nsession=%s\nlabel=%s\nprompt_type=%s\n' "$PANE" "$SESSION" "$LABEL" "$PROMPT_TYPE" > "$STATE_DIR/$PANE_NUM"
        echo "$(ts) [notification] saved state: pane=$PANE session=$SESSION prompt_type=$PROMPT_TYPE" >> "$LOG"
    fi

    # Extract tool details
    TOOL_JSON=$(get_tool_info)
    TOOL_NAME=$(echo "$TOOL_JSON" | jq -r '.name // empty' 2>/dev/null)
    TOOL_CMD=$(echo "$TOOL_JSON" | jq -r '.command // empty' 2>/dev/null)
    TOOL_FILE=$(echo "$TOOL_JSON" | jq -r '.file_path // empty' 2>/dev/null)
    TOOL_DESC=$(echo "$TOOL_JSON" | jq -r '.description // empty' 2>/dev/null)
    TOOL_PATTERN=$(echo "$TOOL_JSON" | jq -r '.pattern // empty' 2>/dev/null)
    TOOL_PROMPT=$(echo "$TOOL_JSON" | jq -r '.prompt // empty' 2>/dev/null)
    TOOL_SUBTYPE=$(echo "$TOOL_JSON" | jq -r '.subagent_type // empty' 2>/dev/null)

    # Build notification body
    if [ -n "$TOOL_SUBTYPE" ]; then
        BODY="<b>${TOOL_NAME:-Tool}</b> (${TOOL_SUBTYPE})"
    else
        BODY="<b>${TOOL_NAME:-Tool}</b>"
    fi
    [ -n "$TOOL_CMD" ] && BODY="$BODY\n<tt>$TOOL_CMD</tt>"
    [ -n "$TOOL_FILE" ] && BODY="$BODY\n$TOOL_FILE"
    [ -n "$TOOL_PATTERN" ] && BODY="$BODY\nPattern: $TOOL_PATTERN"
    [ -n "$TOOL_DESC" ] && BODY="$BODY\n<i>$TOOL_DESC</i>"
    if [ -n "$TOOL_PROMPT" ]; then
        truncated="${TOOL_PROMPT:0:200}"
        [ ${#TOOL_PROMPT} -gt 200 ] && truncated="${truncated}..."
        BODY="$BODY\n${truncated}"
    fi

    if [ "$PROMPT_TYPE" = "yesno" ]; then
        BODY="$BODY\n\nYes <b>(Ctrl+Super+Y)</b>\nNo <b>(Ctrl+Super+N)</b>\nGo to <b>(Ctrl+Super+P)</b>"
    else
        BODY="$BODY\n\nAllow <b>(Ctrl+Super+Y)</b>\nAlways Allow <b>(Ctrl+Super+A)</b>\nDeny <b>(Ctrl+Super+N)</b>\nGo to <b>(Ctrl+Super+P)</b>"
    fi

    echo "$(ts) [notification] permission: tool=$TOOL_NAME cmd=\"$TOOL_CMD\" file=\"$TOOL_FILE\" desc=\"$TOOL_DESC\" pending=$PENDING" >> "$LOG"

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
        NOTIF_ID=$(dunstify "Claude - $LABEL" "$BODY" \
            --stack-tag "claude-perm-$PANE_NUM" \
            -u critical -I "$ICON" -t 0 -p)
        echo "$NOTIF_ID" > "$STATE_DIR/notif-id-${PANE_NUM}"
    fi
else
    dunstify "$TITLE" "$MESSAGE" \
        --stack-tag "claude-stop-${TMUX_PANE#%}" \
        -u normal -I "$ICON"
    echo "$(ts) [notification] dunst sent: $TITLE - $MESSAGE" >> "$LOG"
fi
