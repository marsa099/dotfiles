#!/usr/bin/env bash
# dsqrd/slqs media viewer: open images and gifs in imv (floating via niri),
# fall back to xdg-open for video/audio/non-image URLs.
#
# Pointed at by SLK_MEDIA_VIEWER (set in ~/.config/nixos/configuration.nix),
# which the dsqrd/slqs launchers honour over their own bundled
# media-viewer.sh. This is the pre-6fa4907 upstream script, kept because the
# one daphen ships now does no window sizing at all — see the dsqrd section of
# ~/.claude/CLAUDE.md.
#
# Args (custom_media_hint=True):
#   $1 = file path or URL. The native chat client may pass SEVERAL newline-
#        separated paths here (all photos from one message) — they open together
#        in imv so you can arrow between them. endcord passes a single path/URL.
#   $2 = media type — one of: img, gif, video, audio, URL, YT
set -e

file=$1
type=${2:-img}

# Split $file into an array on newlines: one element for the usual single
# path/URL, several when the chat client opens a whole message's photos.
mapfile -t files <<< "$file"

# Log what we're called with so we can see what the client actually passes for
# a given message (giphy gifv vs Discord CDN gif vs YouTube etc.).
# Never let a bad log path abort viewing under `set -e`.
log=${XDG_CACHE_HOME:-$HOME/.cache}/dsqrd-media-viewer.log
printf '%s  type=%s  n=%s  file=%s\n' "$(date -Iseconds)" "$type" "${#files[@]}" "${files[0]}" >> "$log" || true

# Match imv's bg to the active theme so it doesn't cut a pitch-black hole
# through the floating window. imv's -b takes a 6-digit hex without `#`.
# colors.json lives in the themes-generator checkout, not ~/.config/themes
# (which the old upstream script assumed and which does not exist here).
mode=$(cat "$HOME/.config/theme_mode" 2>/dev/null || echo dark)
for colors in "$HOME/repos/themes-generator/colors.json" "$HOME/.config/themes/colors.json"; do
    [ -r "$colors" ] || continue
    bg=$(jq -r ".themes.${mode}.background.primary // empty" "$colors" 2>/dev/null | tr -d '#')
    [ -n "$bg" ] && break
done
bg=${bg:-181818}

# Compute initial window dimensions as a fraction of the focused
# output's logical size. imv respects -W/-H at launch so niri sees the
# desired size in the initial configure — no post-launch resize jump.
# mpv has similar flags via --geometry=WxH.
read -r screen_w screen_h out_scale <<<"$(
    niri msg --json focused-output 2>/dev/null \
        | jq -r '
            (.logical | "\(.width) \(.height) \(.scale // 1)")
            // (.modes[] | select(.is_current) | "\(.width) \(.height) 1")
            // "1920 1080 1"
        ' 2>/dev/null
)"
# Size knob 1: max fraction of the output a media window may take.
win_w=$(( screen_w * 90 / 100 ))
win_h=$(( screen_h * 90 / 100 ))

# Size knob 2: how far an image SMALLER than the cap may be blown up to fill
# the window, in percent of its native size. 100 = never upscale (images
# opened at native size and so looked small even with a big cap); 250 = up to
# 2.5x. imv 5's default scaling mode is `full`, i.e. it scales the image both
# up and down to fit the window, so the window size we ask for here is what
# actually decides apparent size. Raise for bigger, lower if upscaled
# screenshots look too soft.
max_upscale_pct=250

# Open file(s) in imv as a floating window via niri (window-rule app-id="imv").
# setsid + disown so the script returns immediately and endcord stays
# interactive in the background while you view. Multiple files → arrow keys
# page between them.
view_in_imv() {
    # Size the window to the first image's aspect ratio, scaled to fill the
    # win_w/win_h cap as far as max_upscale_pct allows (identify reports
    # physical px, niri windows are logical — divide by scale). A fixed-size
    # window would leave a small image swimming in a void; native size left
    # every screenshot opening at a fraction of the screen.
    local w=$win_w h=$win_h dims
    dims=$(identify -format '%w %h' "$1[0]" 2>/dev/null | head -n1)
    if [ -n "$dims" ]; then
        read -r iw ih <<< "$dims"
        read -r w h < <(awk -v iw="$iw" -v ih="$ih" -v s="${out_scale:-1}" \
                            -v mw="$win_w" -v mh="$win_h" -v up="$max_upscale_pct" '
            BEGIN { w = iw / s; h = ih / s
                # Largest factor that still fits inside the cap, then clamp
                # the blow-up (f < 1 means shrink, which is never clamped).
                f = mw / w; if (mh / h < f) f = mh / h
                if (f > up / 100) f = up / 100
                w = w * f; h = h * f
                printf "%d %d\n", (w < 200 ? 200 : w), (h < 150 ? 150 : h) }')
    fi
    setsid -f imv -b "$bg" -W "$w" -H "$h" "$@" >/dev/null 2>&1
    # With scaling_mode=shrink imv keeps the layout it computed for the
    # REQUESTED size; when the compositor's real configure differs, small
    # images land off-center (full-scaling used to re-center on rescale).
    # Nudge a center once the window has settled.
    (
        # the imv binary is a launcher; the real process is imv-wayland.
        # Rapid-fire: the first centers land inside niri's open animation,
        # so the misplaced first layout is never actually seen; the late
        # ones cover slow decodes.
        for delay in 0.05 0.05 0.05 0.1 0.15 0.3 0.6; do
            sleep "$delay"
            pid=$(pgrep -n -x imv-wayland || pgrep -n -x imv)
            [ -n "$pid" ] && imv-msg "$pid" center
        done
    ) >/dev/null 2>&1 &
}

view_in_mpv() {
    setsid -f mpv --loop --no-terminal --geometry="${win_w}x${win_h}" "$@" >/dev/null 2>&1
}

# Mixed images + videos in one playlist. Each item HOLDS until you step with
# h / l: images via image-display-duration, videos via loop-file (else a short
# video plays once and auto-advances off itself before you can watch it).
view_in_mpv_mix() {
    # h/l = prev/next item (vim-style; mpv's default < / > is non-obvious).
    conf="${XDG_RUNTIME_DIR:-/tmp}/slqs-mpv-mix.conf"
    printf 'h playlist-prev\nl playlist-next\n' > "$conf"
    setsid -f mpv --no-terminal --loop-file=inf --image-display-duration=inf \
        --input-conf="$conf" --geometry="${win_w}x${win_h}" "$@" >/dev/null 2>&1
}

case "$type" in
    img|gif)
        view_in_imv "${files[@]}"
        ;;
    mix)
        view_in_mpv_mix "${files[@]}"
        ;;
    URL)
        # Endcord categorizes any https:// path as URL — including direct
        # links to gif/png from Discord embeds (giphy, tenor, etc.). HEAD
        # the URL to inspect Content-Type; if it's image/*, download and
        # view in imv. Anything else (HTML pages, videos, redirects to
        # non-image content) falls back to the default browser.
        #
        # gifv URLs sometimes need .gifv → .gif rewrite to actually serve
        # gif content; try the rewrite first, fall through if it 404s.
        try_url=${file%.gifv}
        [ "$try_url" = "$file" ] || try_url="${try_url}.gif"

        ctype=$(curl -fsIL --max-time 10 -o /dev/null -w '%{content_type}' "$try_url" 2>/dev/null || true)
        printf '  HEAD %s -> %s\n' "$try_url" "$ctype" >> "$log"

        case "$ctype" in
            image/*|video/*)
                tmp=$(mktemp --tmpdir endcord-media.XXXXXX) || exit 1
                if curl -fsSL --max-time 10 -o "$tmp" "$try_url"; then
                    case "$ctype" in
                        image/*) view_in_imv "$tmp" ;;
                        video/*) view_in_mpv "$tmp" ;;
                    esac
                else
                    rm -f "$tmp"
                    xdg-open "$file"
                fi
                ;;
            *)
                xdg-open "$file"
                ;;
        esac
        ;;
    video)
        # niri floats it via the same app-id rule as imv.
        view_in_mpv "${files[@]}"
        ;;
    audio)
        # voice notes: play ONCE (a looping voice note is noise); force a small
        # window so there's something visible to replay (space) or close (q).
        setsid -f mpv --no-terminal --force-window=immediate --keep-open=yes \
            --loop-file=no --geometry="${win_w}x120" "${files[@]}" >/dev/null 2>&1
        ;;
    *)
        # YT or anything else — hand off to system default.
        xdg-open "$file"
        ;;
esac
