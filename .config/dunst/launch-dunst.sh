#!/usr/bin/env bash
#
# Launch dunst with dynamic offset that matches Hyprland gaps_out value
#
# This script queries the current Hyprland gaps_out configuration and uses
# it to set the dunst notification offset via command-line override. This
# ensures notifications are positioned consistently with window borders.
#
# The offset is applied via CLI (-offset flag) which overrides the static
# value in dunstrc, allowing dynamic adjustment without modifying the config.

# Get current Hyprland gaps_out value
GAPS_OUT=$(hyprctl getoption general:gaps_out -j | jq -r '.int')

# Launch dunst with dynamic offset matching gaps_out
# The CLI override takes precedence over dunstrc settings
exec dunst -offset "${GAPS_OUT},${GAPS_OUT}"
