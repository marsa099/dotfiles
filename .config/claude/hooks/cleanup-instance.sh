#!/bin/bash
# Shared cleanup logic: close notification for an instance and promote the next
# pending one if any remain. Called by post-tool-cleanup.sh and the watcher.
# Usage: cleanup-instance.sh <instance-id>
STATE_DIR="/tmp/claude-permissions"
LOG="$HOME/.cache/claude/hooks.log"
ts() { date '+%Y-%m-%dT%H:%M:%S.%3N'; }
ICON="$HOME/.config/claude/icons/claude-code.png"

ID="$1"
[ -z "$ID" ] && exit 0

# Close this instance's notification
NID="$STATE_DIR/notif-id-${ID}"
if [ -f "$NID" ]; then
    nid_val=$(cat "$NID")
    [ -n "$nid_val" ] && dunstify -C "$nid_val" 2>/dev/null
fi
rm -f "$STATE_DIR/$ID" "$STATE_DIR/tool-info-${ID}.json" "$NID"

NAV="$STATE_DIR/.last-navigate"
nav_val=""
[ -f "$NAV" ] && nav_val=$(cat "$NAV")
REMAINING=$(find "$STATE_DIR" -maxdepth 1 -type f ! -name '.*' ! -name '*-*' ! -name '*.json' 2>/dev/null)

if [ -z "$REMAINING" ]; then
    rm -f "$NAV"
    echo "$(ts) [cleanup] instance=$ID no more pending" >> "$LOG"
    exit 0
fi

# Promote next pending instance
_esc() { local s="${1//&/&amp;}"; s="${s//</&lt;}"; s="${s//>/&gt;}"; echo "$s"; }

build_body() {
    local id="$1"
    local info="$STATE_DIR/tool-info-${id}.json"
    local tn="" tc="" tf="" td="" tp="" tpt="" ts=""
    if [ -f "$info" ]; then
        tn=$(jq -r '.tool_name // empty' "$info" 2>/dev/null)
        tc=$(jq -r '.tool_input.command // empty' "$info" 2>/dev/null)
        tf=$(jq -r '.tool_input.file_path // empty' "$info" 2>/dev/null)
        td=$(jq -r '.tool_input.description // empty' "$info" 2>/dev/null)
        tp=$(jq -r '.tool_input.pattern // empty' "$info" 2>/dev/null)
        tpt=$(jq -r '.tool_input.prompt // empty' "$info" 2>/dev/null)
        ts=$(jq -r '.tool_input.subagent_type // empty' "$info" 2>/dev/null)
    fi
    tc=$(_esc "$tc"); tf=$(_esc "$tf"); td=$(_esc "$td")
    tp=$(_esc "$tp"); tpt=$(_esc "$tpt")
    [ -n "$tc" ] && [ ${#tc} -gt 200 ] && tc="${tc:0:200}..."
    local b
    if [ -n "$ts" ]; then b="<b>${tn:-Tool}</b> (${ts})"; else b="<b>${tn:-Tool}</b>"; fi
    [ -n "$tc" ] && b="$b\n<tt>$tc</tt>"
    [ -n "$tf" ] && b="$b\n$tf"
    [ -n "$tp" ] && b="$b\nPattern: $tp"
    [ -n "$td" ] && b="$b\n<i>$td</i>"
    if [ -n "$tpt" ]; then
        local trunc="${tpt:0:200}"
        [ ${#tpt} -gt 200 ] && trunc="${trunc}..."
        b="$b\n${trunc}"
    fi
    echo "$b"
}

TARGET_ID=""
if [ -n "$nav_val" ] && [ "$nav_val" != "$ID" ] && [ -f "$STATE_DIR/$nav_val" ]; then
    TARGET_ID="$nav_val"
else
    TARGET_ID=$(basename "$(echo "$REMAINING" | head -1)")
fi
echo "$TARGET_ID" > "$NAV"

TARGET_LABEL=$(grep '^label=' "$STATE_DIR/$TARGET_ID" 2>/dev/null | cut -d= -f2)
[ -z "$TARGET_LABEL" ] && TARGET_LABEL="claude:?"

BODY=$(build_body "$TARGET_ID")
BODY="$BODY\n\nAllow <b>(Ctrl+Super+Y)</b>\nAlways Allow <b>(Ctrl+Super+A)</b>\nDeny <b>(Ctrl+Super+N)</b>\nNext <b>(Ctrl+Super+P)</b>\nGo to <b>(Ctrl+Super+O)</b>"

total=$(echo "$REMAINING" | wc -l)
extra=$((total - 1))
[ "$extra" -gt 0 ] && BODY="$BODY\n\n<i>+${extra} more pending</i>"

REPLACE_ID_FILE="$STATE_DIR/notif-id-${TARGET_ID}"
REPLACE_ARGS=()
if [ -f "$REPLACE_ID_FILE" ]; then
    old_id=$(cat "$REPLACE_ID_FILE")
    [ -n "$old_id" ] && REPLACE_ARGS=(-r "$old_id")
fi

NOTIF_ID=$(dunstify "> Claude - $TARGET_LABEL" "$BODY" \
    "${REPLACE_ARGS[@]}" \
    -I "$ICON" -u critical -t 0 -p 2>>"$LOG")
[ -n "$NOTIF_ID" ] && echo "$NOTIF_ID" > "$REPLACE_ID_FILE"
echo "$(ts) [cleanup] instance=$ID promoted=$TARGET_ID notif=$NOTIF_ID remaining=$total" >> "$LOG"
