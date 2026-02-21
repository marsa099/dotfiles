#!/usr/bin/env python3
"""rentalscanner — check car availability across providers.

Usage:
  python3 rentalscanner.py <from> <to>

  Times can be:
    14          -> today at 14:00
    14:30       -> today at 14:30
    tomorrow 9  -> tomorrow at 09:00
    mon 10      -> next monday at 10:00
    2026-02-22 15:00

Examples:
  python3 rentalscanner.py 14 18          # today 14:00-18:00
  python3 rentalscanner.py 14:30 17       # today 14:30-17:00
  python3 rentalscanner.py 'tomorrow 9' 'tomorrow 17'
  python3 rentalscanner.py 'mån 8' 'mån 16'
"""

import json
import re
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from providers.kinto import get_availability as kinto_availability

CONFIG_PATH = Path(__file__).parent / "config.json"
CET = timezone(timedelta(hours=1))

PROVIDER_FUNCS = {
    "kinto": kinto_availability,
}

WEEKDAYS_SV = {
    "mån": 0, "mon": 0,
    "tis": 1, "tue": 1,
    "ons": 2, "wed": 2,
    "tor": 3, "thu": 3,
    "fre": 4, "fri": 4,
    "lör": 5, "sat": 5,
    "sön": 6, "sun": 6,
}


def parse_time(s):
    """Parse a flexible time string into a datetime with CET timezone."""
    s = s.strip()
    now = datetime.now(CET)
    today = now.replace(hour=0, minute=0, second=0, microsecond=0)

    # Full ISO datetime
    if re.match(r"\d{4}-\d{2}-\d{2}", s):
        dt = datetime.fromisoformat(s)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=CET)
        return dt

    # Split into optional day part and time part
    parts = s.rsplit(" ", 1)
    if len(parts) == 2:
        day_part, time_part = parts[0].lower(), parts[1]
    else:
        day_part, time_part = None, parts[0]

    # Parse time
    if ":" in time_part:
        hour, minute = map(int, time_part.split(":"))
    else:
        hour, minute = int(time_part), 0

    # Parse day
    if day_part is None:
        base = today
    elif day_part in ("tomorrow", "imorgon"):
        base = today + timedelta(days=1)
    elif day_part in WEEKDAYS_SV:
        target_wd = WEEKDAYS_SV[day_part]
        current_wd = today.weekday()
        days_ahead = (target_wd - current_wd) % 7
        if days_ahead == 0:
            days_ahead = 7
        base = today + timedelta(days=days_ahead)
    else:
        raise ValueError(f"Kan inte tolka dag: '{day_part}'")

    return base.replace(hour=hour, minute=minute)


def load_config():
    with open(CONFIG_PATH) as f:
        return json.load(f)


def format_duration(td):
    total_min = int(td.total_seconds() // 60)
    hours, minutes = divmod(total_min, 60)
    if hours > 0:
        return f"{hours}h {minutes}min"
    return f"{minutes}min"


def format_time(dt):
    return dt.strftime("%a %H:%M").replace(
        "Mon", "mån").replace("Tue", "tis").replace(
        "Wed", "ons").replace("Thu", "tor").replace(
        "Fri", "fre").replace("Sat", "lör").replace("Sun", "sön")


def main():
    if len(sys.argv) < 3:
        print("Användning: python3 rentalscanner.py <från> <till>")
        print("Exempel:    python3 rentalscanner.py 14 18")
        print("            python3 rentalscanner.py 'tomorrow 9' 'tomorrow 17'")
        print("            python3 rentalscanner.py 'mån 8' 'mån 16'")
        sys.exit(1)

    start = parse_time(sys.argv[1])
    end = parse_time(sys.argv[2])

    # If end landed before start (e.g. "fre 8" to "sön 18" when today is
    # saturday), push end forward by a week so the range makes sense.
    while end <= start:
        end += timedelta(days=7)

    config = load_config()

    print(f"Söker lediga bilar: {format_time(start)} -> {format_time(end)}")
    print("=" * 60)

    for provider_name, provider_config in config["providers"].items():
        func = PROVIDER_FUNCS.get(provider_name)
        if not func:
            print(f"\nOkänd provider: {provider_name}")
            continue

        STATION_ORDER = [
            "Ola Hanssonsgatan 1",
            "Kristinebergs Strand 31",
            "Rålambsvägen 66",
        ]
        stations = func(provider_config, start.isoformat(), end.isoformat())
        stations.sort(key=lambda s: next((i for i, name in enumerate(STATION_ORDER) if name in s["station"]), 999))
        for station in stations:
            has_overlap = False
            lines = []
            for vehicle in station["vehicles"]:
                if "error" in vehicle:
                    lines.append(f"  {vehicle['name']}: Fel - {vehicle['error']}")
                    continue
                # Only show slots that overlap with requested window
                matching = []
                for slot in vehicle["free_slots"]:
                    slot_start, slot_end = slot[0], slot[1]
                    slot_price = slot[2] if len(slot) > 2 else None
                    overlap_start = max(slot_start, start)
                    overlap_end = min(slot_end, end)
                    if overlap_start < overlap_end:
                        matching.append((overlap_start, overlap_end, slot_price))
                if matching:
                    has_overlap = True
                    covers_full = (len(matching) == 1 and
                                   matching[0][0] <= start and
                                   matching[0][1] >= end)
                    if covers_full:
                        price_str = f" — {matching[0][2]} kr" if matching[0][2] else ""
                        lines.append(f"  {vehicle['name']}: LEDIG hela perioden{price_str}")
                    else:
                        lines.append(f"  {vehicle['name']}:")
                        for s, e, price in matching:
                            duration = format_duration(e - s)
                            price_str = f" — {price} kr" if price else ""
                            lines.append(f"    {format_time(s)} - "
                                         f"{format_time(e)} ({duration}){price_str}")
                else:
                    lines.append(f"  {vehicle['name']}: Upptagen")

            if has_overlap:
                print(f"\n[{provider_name}] {station['station']}")
                print("-" * 40)
                for line in lines:
                    print(line)


if __name__ == "__main__":
    main()
