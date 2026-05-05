# Laptop speakers silent after docking external monitor

**Machine:** ThinkPad X1 Carbon Gen 11 (21HM006GMX), NixOS, PipeWire + WirePlumber.

## Symptom
After plugging into the external monitor (PNP KUY 32"), no sound comes out
of the laptop speakers. `wpctl status` shows the default sink is the
monitor's HDMI output, which has no real speakers.

## Root cause
Two things, in order of importance:

1. **Device profile is wrong.** WirePlumber auto-selected the profile
   `HiFi (HDMI1, HDMI2, HDMI3, Headphones, Mic1, Mic2)` — which does NOT
   include a Speaker output at all. Even if the default sink is correct,
   the laptop speakers are physically unreachable in this profile.
   The correct profile is `HiFi (HDMI1, HDMI2, HDMI3, Mic1, Mic2, Speaker)`.
2. WirePlumber's auto-switch policy picks newly-plugged HDMI sinks as
   default, even when the monitor has no usable speakers.

## Fix (one shot)
```bash
# 1. Find the on-board ALSA device id (the cAVS one, NOT the webcam)
wpctl status            # look under Audio → Devices

# 2. Switch profile to the one that exposes Speaker
wpctl set-profile <dev-id> 2

# 3. Engage the Speaker route on that device (and persist the choice)
pw-cli s <dev-id> Route '{ index: 3, device: 3, save: true }'

# 4. Make Speaker the default sink (find sink id under Audio → Sinks)
wpctl set-default <speaker-sink-id>
```

## How to inspect what's wrong
```bash
wpctl status                                # see sinks, devices, default (*)
pw-metadata -n default                      # active vs configured default sink
pw-dump <device-id> | less                  # full route + profile JSON
```
Key things to check in `pw-dump`:
- `Profile` (active) — must be the one listing `Speaker`
- `EnumRoute` — find the `[Out] Speaker` entry, note its `index` and `devices`
- `Route` (active) — should include `[Out] Speaker` after the fix

## Why `wpctl set-default <headphones>` looked broken earlier
On this machine the "Headphones" sink corresponds to the analog jack route
which was `available: no` (nothing plugged in). Setting it as default
appeared to do nothing because the route wasn't usable. Switching the
device profile to expose Speaker is the actual fix.

## Useful tools
- `wpctl` (wireplumber) — high-level: sinks, sources, default, profile
- `pw-cli` / `pw-metadata` / `pw-dump` (pipewire) — low-level routes/metadata
- `pavucontrol` — GUI mixer (added to configuration.nix)

## Streaming audio into Teams (browser, no "include computer sound" toggle)
Teams in the browser on Linux has no built-in system-audio capture. Route
audio in via the monitor source instead:
1. Start the call. Start Spotify (or whatever) playing.
2. Open `pavucontrol` → **Recording** tab.
3. Find the Teams/Chromium mic stream → change source dropdown to
   **"Monitor of <speaker sink>"**.
4. Mute the real mic in Teams so room noise doesn't layer on top.
