#!/usr/bin/env bash
# fw_telemetry_report.sh — summarize collected telemetry events.
#
# Usage:
#   fw_telemetry_report.sh                 # this machine's log (~/.fireworks-skill/...)
#   fw_telemetry_report.sh <file.jsonl>    # one dogfooder's exported file
#   fw_telemetry_report.sh <dir/>          # a folder of collected *.jsonl files (aggregate)
set -uo pipefail
STATE_DIR="${FW_STATE_DIR:-$HOME/.fireworks-skill}"
INPUT="${1:-$STATE_DIR/analytics/events.jsonl}"

TMP=""; cleanup() { [ -n "$TMP" ] && rm -f "$TMP"; }; trap cleanup EXIT
SOURCE_DESC=""

if [ -d "$INPUT" ]; then
  TMP="$(mktemp)"; n=0
  for f in "$INPUT"/*.jsonl; do [ -f "$f" ] || continue; cat "$f" >> "$TMP"; n=$((n+1)); done
  JSONL="$TMP"; SOURCE_DESC="$n file(s) in $INPUT"
elif [ -f "$INPUT" ]; then
  JSONL="$INPUT"; SOURCE_DESC="$INPUT"
else
  echo "No events found at: $INPUT"
  echo "Run the skill first, or pass a .jsonl file / a folder of collected files."
  exit 0
fi

TOTAL="$(grep -c '^{' "$JSONL" 2>/dev/null || echo 0)"
echo "fireworks-training-skill — telemetry report"
echo "source: $SOURCE_DESC   events: $TOTAL"
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
