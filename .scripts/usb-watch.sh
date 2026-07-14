#!/usr/bin/env bash
# Logs USB device and USB-C (typec) add/remove events with wall-clock timestamps.
# Purpose: correlate keyboard (3-1) disconnects with typec partner events.
#   usb remove WITHOUT typec remove  -> keyboard reset itself (firmware/device side)
#   usb remove WITH typec partner remove -> physical connection lost (cable/port side)
LOG="${1:-$HOME/usb-watch.log}"
echo "$(date '+%F %T') usb-watch started" >> "$LOG"
udevadm monitor --udev --subsystem-match=usb/usb_device --subsystem-match=typec |
while read -r line; do
  case "$line" in
    *" add "*|*" remove "*)
      printf '%s %s\n' "$(date '+%F %T')" "$line" >> "$LOG"
      ;;
  esac
done
