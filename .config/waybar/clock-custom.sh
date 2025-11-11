#!/bin/bash

# Get the date without padding
DATE_TEXT=$(date '+%a %-d %H:%M:%S')

# Get current day for highlighting
CURRENT_DAY=$(date '+%-d')
YEAR_MONTH=$(date '+%Y %B')

# Get calendar with week numbers and Monday as first day
CAL_OUTPUT=$(cal -mw)

# Process calendar line by line for better formatting
CAL_LINES=()
while IFS= read -r line; do
    # Check if it's the header line (contains Mo Tu We...)
    if [[ "$line" == *"Mo Tu We"* ]]; then
        # Make header bold
        line="<b>$line</b>"
    else
        # First, highlight week numbers (at the beginning of lines) in green
        line=$(echo "$line" | sed "s/^\([0-9]\{2\}\)/<span color='#a3be8c' weight='bold'>\1<\/span>/")

        # Check if this line contains the current day (for week highlighting)
        CONTAINS_CURRENT_DAY=false
        if [ "$CURRENT_DAY" -le 9 ]; then
            # Single digit - check with space
            if [[ "$line" =~ (^|[^0-9])$CURRENT_DAY([^0-9]|$) ]]; then
                CONTAINS_CURRENT_DAY=true
            fi
        else
            # Double digit
            if [[ "$line" == *"$CURRENT_DAY"* ]]; then
                CONTAINS_CURRENT_DAY=true
            fi
        fi

        if [ "$CONTAINS_CURRENT_DAY" = true ]; then
            # Apply week highlighting but preserve week number
            # Extract week number if present
            if [[ "$line" =~ ^(\<span[^\>]*\>[0-9]{2}\</span\>)(.*)$ ]]; then
                WEEK_NUM="${BASH_REMATCH[1]}"
                REST="${BASH_REMATCH[2]}"
                # Apply background to the rest of the line (not the week number)
                line="$WEEK_NUM<span background='#3b4252'>$REST</span>"
            else
                # No week number, highlight entire line
                line="<span background='#3b4252'>$line</span>"
            fi

            # Then highlight the current day specifically with brighter color
            if [ "$CURRENT_DAY" -le 9 ]; then
                line=$(echo "$line" | sed "s/\([^0-9]\)$CURRENT_DAY\([^0-9]\)/\1<span background='#88c0d0' foreground='#2e3440' weight='bold'>$CURRENT_DAY<\/span>\2/g")
            else
                line=$(echo "$line" | sed "s/\b$CURRENT_DAY\b/<span background='#88c0d0' foreground='#2e3440' weight='bold'>$CURRENT_DAY<\/span>/g")
            fi
        fi
    fi

    CAL_LINES+=("$line")
done <<< "$CAL_OUTPUT"

# Join lines with escaped newlines for JSON
CALENDAR=""
for line in "${CAL_LINES[@]}"; do
    if [ -z "$CALENDAR" ]; then
        CALENDAR="$line"
    else
        CALENDAR="$CALENDAR\\n$line"
    fi
done

# Create tooltip with formatted calendar (larger sizes)
TOOLTIP="<span size='xx-large' weight='bold'>$YEAR_MONTH</span>\\n\\n<tt><span size='large'>$CALENDAR</span></tt>"

# Output JSON with both text and tooltip
printf '{"text":"%s","tooltip":"%s"}\n' "$DATE_TEXT" "$TOOLTIP"
