#!/usr/bin/env bash
# Auto-checked dogfooding cases: does the skill correctly record what happens?
# Runs the ACTUAL inline prolog/epilog extracted from SKILL.md against an
# isolated HOME, mirroring how the agent runs them (separate shells, same $PPID).
source "$(dirname "$0")/lib.sh"
echo "Telemetry — does the skill record what happens?"

TESTHOME="$(mktemp -d)"
export HOME="$TESTHOME"            # ~ now resolves under the temp dir
D="$TESTHOME/.fireworks-skill/analytics"

PROLOG="$(extract_bash "$SKILL_MD" 'Telemetry preamble' 1)"
EPILOG="$(extract_bash "$SKILL_MD" 'Telemetry epilogue' 1)"
FRICTION="$(extract_bash "$SKILL_MD" 'Telemetry epilogue' 2)"

[ -n "$PROLOG" ] && ok "found the prolog in SKILL.md" || no "found the prolog in SKILL.md"
assert_contains "$EPILOG" 'events.jsonl' "found the epilog in SKILL.md"
assert_contains "$FRICTION" 'event_type":"question' "found the friction logger in SKILL.md"

# The epilog/friction first line sets the agent-edited vars; drop it and inject
# test values so we exercise the rest of the shipped logic verbatim.
EBODY="$(printf '%s\n' "$EPILOG"   | tail -n +2)"
FBODY="$(printf '%s\n' "$FRICTION" | tail -n +2)"

prolog()   { bash -c "$PROLOG"; }
epilog()   { bash -c "REF=\"$1\"; OUTCOME=\"$2\"; ERR=\"$3\"
$EBODY"; }
friction() { bash -c "QID=\"$1\"; FOLLOWED=$2
$FBODY"; }
events()   { cat "$D/events.jsonl" 2>/dev/null; }
reset()    { rm -rf "$TESTHOME/.fireworks-skill"; }

# A normal run is recorded (which reference, and that it succeeded), once.
reset; prolog; epilog choose-method success ""
assert_contains "$(events)" '"reference_used":"choose-method"' "records which reference was used"
assert_contains "$(events)" '"outcome":"success"'             "records the run as a success"
assert_eq "$(events | grep -c '^{')" "1"                       "a clean run produces exactly one record (no phantom crash)"

# A failure is recorded with its error type.
reset; prolog; epilog deploy-and-troubleshoot error quota
assert_contains "$(events)" '"error_class":"quota"' "records a failure with its error type (quota)"

# A stop-and-ask is recorded, including whether the suggestion was taken.
reset; prolog; friction route-method false
assert_contains "$(events)" '"question_id":"route-method"'    "records when the agent had to stop and ask"
assert_contains "$(events)" '"followed_recommendation":false' "records whether the suggestion was taken"

# A run that crashes (no epilog) is still recorded — by the next run.
reset; mkdir -p "$D"
echo '{"ts":"2026-01-01T00:00:00Z"}' > "$D/.pending-OLDRUN"
echo 1700000000 > "$D/.start-OLDRUN"
prolog; epilog getting-started success ""
assert_contains "$(events)" '"session_id":"OLDRUN"' "a crashed run still gets recorded later"
assert_contains "$(events)" '"outcome":"unknown"'   "...marked as unknown"
[ ! -f "$D/.pending-OLDRUN" ] && ok "...and its leftover marker is cleaned up" || no "...and its leftover marker is cleaned up"

# Opting out records nothing.
reset
FW_TELEMETRY=off bash -c "$PROLOG"
FW_TELEMETRY=off bash -c "REF=\"choose-method\"; OUTCOME=\"success\"; ERR=\"\"
$EBODY"
[ ! -f "$D/events.jsonl" ] && ok "opting out records nothing" || no "opting out records nothing"

# Every record is valid JSON.
reset; prolog; epilog choose-method success ""; friction q1 true
valid=1
while IFS= read -r l; do
  [ -z "$l" ] && continue
  printf '%s' "$l" | python3 -c 'import sys,json; json.loads(sys.stdin.read())' 2>/dev/null || valid=0
done < "$D/events.jsonl"
[ "$valid" = 1 ] && ok "every record is valid JSON" || no "every record is valid JSON"

rm -rf "$TESTHOME"
finish
