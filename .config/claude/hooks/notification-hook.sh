#!/bin/bash

# Claude Code Notification Hook
# For permission prompts: shows rich dunst notification with keybinding hints
# For other notifications: shows simple dunst notification
# Saves tmux pane target for global keybinding response
#
# Requires: jq, dunstify, tmux

LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
STATE_FILE="/tmp/claude-permission-pane"

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

if [ "$TYPE" = "permission_prompt" ]; then
    # Save tmux pane for keybinding scripts
    if [ -n "$TMUX" ]; then
        PANE=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
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

    if [ -n "$TOOL_CMD" ]; then
        BODY="$BODY\n$TOOL_CMD"
    fi
    if [ -n "$TOOL_FILE" ]; then
        BODY="$BODY\n$TOOL_FILE"
    fi
    if [ -n "$TOOL_PATTERN" ]; then
        BODY="$BODY\nPattern: $TOOL_PATTERN"
    fi
    if [ -n "$TOOL_DESC" ]; then
        BODY="$BODY\n<i>$TOOL_DESC</i>"
    fi

    BODY="$BODY\n\n<b>[Ctrl+Super+Y]</b> Allow  <b>[Ctrl+Super+A]</b> Always  <b>[Ctrl+Super+N]</b> Deny"

    ICON="$HOME/.config/claude/icons/claude-code.svg"
    dunstify "Claude Code - Permission" "$BODY" \
        --stack-tag claude-prompt \
        -u critical -I "$ICON" -t 0

    echo "$(ts) [notification] permission: tool=$TOOL_NAME cmd=\"$TOOL_CMD\" file=\"$TOOL_FILE\"" >> "$LOG"
else
    ICON="$HOME/.config/claude/icons/claude-code.svg"
    dunstify "$TITLE" "$MESSAGE" \
        --stack-tag claude-prompt \
        -u normal -I "$ICON"
    echo "$(ts) [notification] dunst sent: $TITLE - $MESSAGE" >> "$LOG"
fi
