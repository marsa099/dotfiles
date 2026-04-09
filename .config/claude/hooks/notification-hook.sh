#!/bin/bash

# Claude Code Notification Hook
# For permission prompts: shows rich dunst notification with keybinding hints
# For other notifications: shows simple dunst notification
# Saves per-instance state for multi-instance keybinding response
#
# Supports both tmux and direct terminal (non-tmux) instances.
# Requires: jq, dunstify, niri. Optional: tmux, wtype

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

echo "$(ts) [notification] type=$TYPE title=$TITLE message=$MESSAGE" >> "$LOG"

# Compute instance ID: tmux pane number or "d<PTS>" for direct terminals
compute_instance_id() {
    if [ -n "$TMUX_PANE" ]; then
        echo "${TMUX_PANE#%}"
    else
        local pts_num
        pts_num=$(ps -o tty= -p $$ 2>/dev/null | tr -d ' ' | grep -oP 'pts/\K\d+')
        [ -n "$pts_num" ] && echo "d${pts_num}"
    fi
}

# Extract tool details saved by PermissionRequest hook, fallback to transcript
get_tool_info() {
    local instance_id="$1"
    local info_file="$STATE_DIR/tool-info-${instance_id}.json"
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

# Find niri window ID for the current process's terminal
find_terminal_window() {
    local windows
    windows=$(niri msg windows 2>/dev/null)
    local pid=$$
    while [ "$pid" != "1" ] && [ -n "$pid" ] && [ "$pid" != "0" ]; do
        local wid
        wid=$(echo "$windows" | awk -v p="$pid" '
            /^Window ID/ { id = $3; sub(/:$/, "", id) }
            /PID:/ && $2 == p { print id; exit }
        ')
        if [ -n "$wid" ]; then
            echo "$wid"
            return 0
        fi
        pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
    done
    return 1
}

if [ "$TYPE" = "permission_prompt" ]; then
    INSTANCE_ID=$(compute_instance_id)
    if [ -z "$INSTANCE_ID" ]; then
        echo "$(ts) [notification] error: cannot determine instance ID" >> "$LOG"
        exit 0
    fi

    # Determine instance type and label
    if [ -n "$TMUX_PANE" ]; then
        INSTANCE_TYPE="tmux"
        PANE="$TMUX_PANE"
        SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)
        WINDOW_IDX=$(tmux display-message -t "$PANE" -p '#{window_index}' 2>/dev/null)
        LABEL="${SESSION:-claude}:${WINDOW_IDX}"
    else
        INSTANCE_TYPE="direct"
        PANE=""
        SESSION=""
        CWD_NAME=$(basename "$PWD" 2>/dev/null)
        LABEL="${CWD_NAME:-direct}"
        TERMINAL_WID=$(find_terminal_window)
    fi

    # Detect prompt type: Yes/No vs Allow/Always Allow/Deny
    PROMPT_TYPE="permission"
    if echo "$MESSAGE" | grep -qi "Do you want to proceed"; then
        PROMPT_TYPE="yesno"
    fi

    # Save per-instance state file
    {
        printf 'instance_type=%s\n' "$INSTANCE_TYPE"
        printf 'label=%s\n' "$LABEL"
        printf 'prompt_type=%s\n' "$PROMPT_TYPE"
        [ "$INSTANCE_TYPE" = "tmux" ] && printf 'pane=%s\nsession=%s\n' "$PANE" "$SESSION"
        [ "$INSTANCE_TYPE" = "direct" ] && printf 'window_id=%s\n' "$TERMINAL_WID"
    } > "$STATE_DIR/$INSTANCE_ID"
    echo "$(ts) [notification] saved state: id=$INSTANCE_ID type=$INSTANCE_TYPE prompt_type=$PROMPT_TYPE" >> "$LOG"

    # Extract tool details
    TOOL_JSON=$(get_tool_info "$INSTANCE_ID")
    TOOL_NAME=$(echo "$TOOL_JSON" | jq -r '.name // empty' 2>/dev/null)
    TOOL_CMD=$(echo "$TOOL_JSON" | jq -r '.command // empty' 2>/dev/null)
    TOOL_FILE=$(echo "$TOOL_JSON" | jq -r '.file_path // empty' 2>/dev/null)
    TOOL_DESC=$(echo "$TOOL_JSON" | jq -r '.description // empty' 2>/dev/null)
    TOOL_PATTERN=$(echo "$TOOL_JSON" | jq -r '.pattern // empty' 2>/dev/null)
    TOOL_PROMPT=$(echo "$TOOL_JSON" | jq -r '.prompt // empty' 2>/dev/null)
    TOOL_SUBTYPE=$(echo "$TOOL_JSON" | jq -r '.subagent_type // empty' 2>/dev/null)

    # Escape backslashes so dunst doesn't interpret sequences like \0 as null
    TOOL_CMD="${TOOL_CMD//\\/\\\\}"
    TOOL_FILE="${TOOL_FILE//\\/\\\\}"
    TOOL_DESC="${TOOL_DESC//\\/\\\\}"
    TOOL_PATTERN="${TOOL_PATTERN//\\/\\\\}"
    TOOL_PROMPT="${TOOL_PROMPT//\\/\\\\}"

    # Truncate long commands - notification is for context, full cmd is in terminal
    if [ -n "$TOOL_CMD" ] && [ ${#TOOL_CMD} -gt 200 ]; then
        TOOL_CMD="${TOOL_CMD:0:200}..."
    fi

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

    echo "$(ts) [notification] permission: id=$INSTANCE_ID tool=$TOOL_NAME cmd=\"$TOOL_CMD\" file=\"$TOOL_FILE\" desc=\"$TOOL_DESC\"" >> "$LOG"

    # Check if the user is looking at this instance
    PANE_VISIBLE=false
    if [ "$INSTANCE_TYPE" = "tmux" ] && [ -n "$PANE" ]; then
        CLIENT_ACTIVE_PANE=$(tmux list-clients -F '#{pane_id}' 2>/dev/null | head -1)
        [ "$CLIENT_ACTIVE_PANE" = "$PANE" ] && PANE_VISIBLE=true
        echo "$(ts) [notification] our_pane=$PANE client_active=$CLIENT_ACTIVE_PANE visible=$PANE_VISIBLE" >> "$LOG"
    else
        # Non-tmux: terminal shows only this instance
        PANE_VISIBLE=true
    fi

    if is_terminal_focused && [ "$PANE_VISIBLE" = true ]; then
        echo "$(ts) [notification] skipped: terminal is focused" >> "$LOG"
    else
        REPLACE_ID_FILE="$STATE_DIR/notif-id-${INSTANCE_ID}"
        REPLACE_ARGS=()
        [ -f "$REPLACE_ID_FILE" ] && REPLACE_ARGS=(-r "$(cat "$REPLACE_ID_FILE")")
        NOTIF_ID=$(dunstify "Claude - $LABEL" "$BODY" \
            "${REPLACE_ARGS[@]}" \
            -u critical -I "$ICON" -t 0 -p)
        echo "$NOTIF_ID" > "$REPLACE_ID_FILE"
    fi
else
    dunstify "$TITLE" "$MESSAGE" \
        -u normal -I "$ICON"
    echo "$(ts) [notification] dunst sent: $TITLE - $MESSAGE" >> "$LOG"
fi
