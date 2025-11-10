#!/bin/bash

# Get the date without padding
DATE_TEXT=$(date '+%a %-d %H:%M:%S')

# Get calendar with current day highlighted
CALENDAR=$(cal -mw | sed ':a;N;$!ba;s/\n/\\n/g')
YEAR_MONTH=$(date '+%Y %B')

# Create tooltip with year/month header and calendar
TOOLTIP="<big>$YEAR_MONTH</big>\\n<tt><small>$CALENDAR</small></tt>"

# Output JSON with both text and tooltip
printf '{"text":"%s","tooltip":"%s"}\n' "$DATE_TEXT" "$TOOLTIP"
