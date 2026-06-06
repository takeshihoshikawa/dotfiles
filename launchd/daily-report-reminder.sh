#!/usr/bin/env bash
set -e

# Skip catch-up runs fired on wake after the Mac slept past the schedule.
now=$(date +%H%M)
if [ "$now" -ge 1633 ] && [ "$now" -le 1730 ]; then
  osascript -e 'display notification "Write your daily report (/daily-report)" with title "Daily Report"'
fi
