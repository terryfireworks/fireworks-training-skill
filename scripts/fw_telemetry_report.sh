#!/usr/bin/env bash
# fw_telemetry_report.sh — summarize locally-collected events.
# Makes the pipeline useful end-to-end on your own machine with zero backend.
# Reads ~/.fireworks-skill/analytics/events.jsonl.
set -uo pipefail
STATE_DIR="${FW_STATE_DIR:-$HOME/.fireworks-skill}"
JSONL="$STATE_DIR/analytics/events.jsonl"

if [ ! -f "$JSONL" ]; then
  echo "No events yet ($JSONL). Run the skill a few times first."
  exit 0
fi

TOTAL="$(grep -c '^{' "$JSONL" 2>/dev/null || echo 0)"

echo "fireworks-training-skill — local telemetry"
echo "events: $TOTAL   file: $JSONL"
echo

field() { grep -o "\"$1\":\"[^\"]*\"" | awk -F'"' '{print $4}'; }
count() { sort | uniq -c | sort -rn; }

echo "Outcomes:";        grep '"event_type":"skill_run"' "$JSONL" | field outcome | count | sed 's/^/  /'
echo
echo "References used:";  grep '"event_type":"skill_run"' "$JSONL" | field reference_used | count | sed 's/^/  /'
echo
ERRORS="$(grep '"outcome":"error"' "$JSONL" | grep -o '"error_class":"[^"]*"' | awk -F'"' '{print $4}' | count)"
if [ -n "$ERRORS" ]; then echo "Error classes (blockers):"; echo "$ERRORS" | sed 's/^/  /'; echo; fi
FRIC="$(grep '"event_type":"question"' "$JSONL")"
if [ -n "$FRIC" ]; then
  OVERRIDES="$(echo "$FRIC" | grep -c '"followed_recommendation":false' || echo 0)"
  ASKED="$(echo "$FRIC" | grep -c '^{' || echo 0)"
  echo "Interaction friction: $ASKED questions asked, $OVERRIDES overrode the recommended default"
fi
