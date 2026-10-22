#!/usr/bin/env bash
# Test the focus helper without contacting the running compositor.
set -euo pipefail
helper=$(realpath "$(dirname "$0")/niri-spawn-or-focus")
test_dir=$(mktemp -d /tmp/spotifast-niri-focus-test.XXXXXXXX)
trap 'rm -rf -- "$test_dir"' EXIT
mkdir -p "$test_dir/bin"
export ACTION_LOG="$test_dir/actions"
cat > "$test_dir/bin/niri" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$*" == 'msg -j windows' ]]; then
    printf '%s\n' "$WINDOWS_JSON"
else
    printf '%s\n' "$*" >> "$ACTION_LOG"
fi
STUB
chmod +x "$test_dir/bin/niri"
export PATH="$test_dir/bin:$PATH"

check_case() {
    local name=$1 windows=$2 app_ids=$3 expected=$4
    : > "$ACTION_LOG"
    WINDOWS_JSON="$windows" XDG_STATE_HOME="$test_dir/state/$name" \
        bash "$helper" "$app_ids" spotifast-lab
    test "$(<"$ACTION_LOG")" = "$expected"
    printf 'PASS: %s\n' "$name"
}

check_case legacy '[{"id":2,"app_id":"fastpotify-lab","is_focused":false}]' \
    spotifast-lab,fastpotify-lab 'msg action focus-window --id 2'
check_case renamed '[{"id":9,"app_id":"spotifast-lab","is_focused":false}]' \
    spotifast-lab,fastpotify-lab 'msg action focus-window --id 9'
check_case cycle '[{"id":9,"app_id":"spotifast-lab","is_focused":false},{"id":2,"app_id":"fastpotify-lab","is_focused":true}]' \
    spotifast-lab,fastpotify-lab 'msg action focus-window --id 9'
check_case launch '[{"id":1,"app_id":"other","is_focused":true}]' \
    spotifast-lab,fastpotify-lab 'msg action spawn -- spotifast-lab'
check_case single '[{"id":5,"app_id":"foot","is_focused":false}]' \
    foot 'msg action focus-window --id 5'
