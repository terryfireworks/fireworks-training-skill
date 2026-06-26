#!/usr/bin/env bash
# Tier 8 — telemetry regression. Runs the ACTUAL inline prolog/epilog extracted
# from SKILL.md against an isolated HOME, mirroring how the agent runs them
# (separate shells, same $PPID).
source "$(dirname "$0")/lib.sh"
echo "Tier 8 — telemetry (inline SKILL.md hooks)"

TESTHOME="$(mktemp -d)"
export HOME="$TESTHOME"            # ~ now resolves under the temp dir
D="$TESTHOME/.fireworks-skill/analytics"

PROLOG="$(extract_bash "$SKILL_MD" 'Telemetry preamble' 1)"
EPILOG="$(extract_bash "$SKILL_MD" 'Telemetry epilogue' 1)"
FRICTION="$(extract_bash "$SKILL_MD" 'Telemetry epilogue' 2)"

[ -n "$PROLOG" ] && ok "extracted prolog block" || no "extracted prolog block"
assert_contains "$EPILOG" 'events.jsonl' "extracted epilog block"
assert_contains "$FRICTION" 'event_type":"question' "extracted friction block"

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

# T1 — success run logs reference + outcome, exactly one event (no spurious crash)
reset; prolog; epilog choose-method success ""
assert_contains "$(events)" '"reference_used":"choose-method"' "T1 logs reference_used"
assert_contains "$(events)" '"outcome":"success"'             "T1 logs outcome=success"
assert_eq "$(events | grep -c '^{')" "1"                       "T1 exactly one event (prolog marker cleared)"

# T2 — error run logs the error class
reset; prolog; epilog deploy-and-troubleshoot error quota
assert_contains "$(events)" '"error_class":"quota"' "T2 logs error_class=quota"

# T3 — friction event logs the decision + whether the recommendation was taken
# (prolog runs first in a real task, creating the analytics dir the friction
# event appends to)
reset; prolog; friction route-method false
assert_contains "$(events)" '"question_id":"route-method"'       "T3 logs question_id"
assert_contains "$(events)" '"followed_recommendation":false'    "T3 logs followed_recommendation"

# T4 — crash detector: an orphan marker from another session → outcome:unknown
reset; mkdir -p "$D"
echo '{"ts":"2026-01-01T00:00:00Z"}' > "$D/.pending-OLDPID"
echo 1700000000 > "$D/.start-OLDPID"
prolog; epilog getting-started success ""
assert_contains "$(events)" '"session_id":"OLDPID"' "T4 orphan run finalized"
assert_contains "$(events)" '"outcome":"unknown"'   "T4 ...as outcome=unknown"
[ ! -f "$D/.pending-OLDPID" ] && ok "T4 orphan marker cleaned" || no "T4 orphan marker cleaned"

# T5 — opt-out writes nothing
reset
FW_TELEMETRY=off bash -c "$PROLOG"
FW_TELEMETRY=off bash -c "REF=\"choose-method\"; OUTCOME=\"success\"; ERR=\"\"
$EBODY"
[ ! -f "$D/events.jsonl" ] && ok "T5 opt-out writes no events" || no "T5 opt-out writes no events"

# T6 — every emitted line is valid JSON
reset; prolog; epilog choose-method success ""; friction q1 true
valid=1
while IFS= read -r l; do
  [ -z "$l" ] && continue
  printf '%s' "$l" | python3 -c 'import sys,json; json.loads(sys.stdin.read())' 2>/dev/null || valid=0
done < "$D/events.jsonl"
[ "$valid" = 1 ] && ok "T6 all events are valid JSON" || no "T6 all events are valid JSON"

rm -rf "$TESTHOME"
finish
