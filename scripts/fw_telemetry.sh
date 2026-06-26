#!/usr/bin/env bash
# fw_telemetry.sh — append one fireworks-training-skill usage event to a LOCAL
# JSONL file. Local-only: nothing is ever transmitted. A backend collector can
# be added later (see TELEMETRY.md) — events.jsonl is the durable interface.
#
# Mirrors gstack's logging pattern, trimmed to the dogfooding essentials:
# no network, no consent tiers, no device id, no free-text fields.
#
# Data flow:
#   SKILL.md preamble  ──▶ writes .pending-<session>   (crash marker)
#   SKILL.md epilogue  ──▶ fw_telemetry.sh             (append event)
#
# Usage:
#   fw_telemetry.sh --outcome success --duration 142 \
#     --reference choose-method --session-id "$SID"
#   fw_telemetry.sh --event-type question --question-id route-method \
#     --followed-recommendation true --session-id "$SID"
#
# Opt-out: export FW_TELEMETRY=off  OR  touch ~/.fireworks-skill/telemetry-off
#
# Env overrides (testing):
#   FW_STATE_DIR  — override ~/.fireworks-skill state directory
#   FW_SKILL_DIR  — override auto-detected skill root (where VERSION lives)
#
# NEVER exits non-zero — telemetry must not break the user's task.
set -uo pipefail

FW_SKILL_DIR="${FW_SKILL_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
STATE_DIR="${FW_STATE_DIR:-$HOME/.fireworks-skill}"
ANALYTICS_DIR="$STATE_DIR/analytics"
JSONL_FILE="$ANALYTICS_DIR/events.jsonl"
VERSION_FILE="$FW_SKILL_DIR/VERSION"

# ─── Defaults / flags ────────────────────────────────────────
EVENT_TYPE="skill_run"
OUTCOME="unknown"
DURATION=""
REFERENCE=""
ERROR_CLASS=""
SESSION_ID=""
QUESTION_ID=""
FOLLOWED_REC=""

while [ $# -gt 0 ]; do
  case "$1" in
    --event-type)              EVENT_TYPE="$2"; shift 2 ;;
    --outcome)                 OUTCOME="$2"; shift 2 ;;
    --duration)                DURATION="$2"; shift 2 ;;
    --reference)               REFERENCE="$2"; shift 2 ;;
    --error-class)             ERROR_CLASS="$2"; shift 2 ;;
    --session-id)              SESSION_ID="$2"; shift 2 ;;
    --question-id)             QUESTION_ID="$2"; shift 2 ;;
    --followed-recommendation) FOLLOWED_REC="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# ─── Opt-out ─────────────────────────────────────────────────
# Default ON (local-only). Honor either the env var or the opt-out file.
if [ "${FW_TELEMETRY:-on}" = "off" ] || [ -f "$STATE_DIR/telemetry-off" ]; then
  [ -n "$SESSION_ID" ] && rm -f "$ANALYTICS_DIR/.pending-$SESSION_ID" 2>/dev/null || true
  exit 0
fi

mkdir -p "$ANALYTICS_DIR" 2>/dev/null || true

# ─── Finalize orphaned pending markers (crash detector) ──────
# A run that died never reached its epilogue, so its .pending marker survives.
# Any marker that is NOT our current session = a previous crashed run → emit it
# as outcome:unknown so crashes are still captured.
for PFILE in "$ANALYTICS_DIR"/.pending-*; do
  [ -f "$PFILE" ] || continue
  PBASE="$(basename "$PFILE")"; PSID="${PBASE#.pending-}"
  [ "$PSID" = "$SESSION_ID" ] && continue
  PDATA="$(cat "$PFILE" 2>/dev/null || true)"
  rm -f "$PFILE" 2>/dev/null || true
  [ -z "$PDATA" ] && continue
  P_TS="$(echo "$PDATA" | grep -o '"ts":"[^"]*"' | head -1 | awk -F'"' '{print $4}')"
  P_REF="$(echo "$PDATA" | grep -o '"reference":"[^"]*"' | head -1 | awk -F'"' '{print $4}')"
  P_VER="$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo unknown)"
  P_OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  printf '{"v":1,"ts":"%s","event_type":"skill_run","skill":"fireworks-training","skill_version":"%s","os":"%s","session_id":"%s","reference_used":"%s","outcome":"unknown","error_class":null,"duration_s":null,"question_id":null,"followed_recommendation":null}\n' \
    "$P_TS" "$P_VER" "$P_OS" "$PSID" "${P_REF:-none}" >> "$JSONL_FILE" 2>/dev/null || true
done

# Clear our own marker — we're about to log the real event.
[ -n "$SESSION_ID" ] && rm -f "$ANALYTICS_DIR/.pending-$SESSION_ID" 2>/dev/null || true

# ─── Metadata ────────────────────────────────────────────────
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo "")"
VERSION="$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo unknown)"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"

# ─── Sanitize (enum-ish values only; never free text) ────────
safe() { printf '%s' "$1" | tr -d '"\\\n\r\t' | head -c 60; }
OUTCOME="$(safe "$OUTCOME")"; REFERENCE="$(safe "$REFERENCE")"
ERROR_CLASS="$(safe "$ERROR_CLASS")"; SESSION_ID="$(safe "$SESSION_ID")"
EVENT_TYPE="$(safe "$EVENT_TYPE")"; QUESTION_ID="$(safe "$QUESTION_ID")"

DUR_FIELD="null"
case "$DURATION" in
  ''|*[!0-9]*) ;;                       # non-numeric → null
  *) [ "$DURATION" -le 86400 ] && DUR_FIELD="$DURATION" ;;
esac
ERR_FIELD="null";  [ -n "$ERROR_CLASS" ] && ERR_FIELD="\"$ERROR_CLASS\""
REF_FIELD="\"${REFERENCE:-none}\""
QID_FIELD="null"; [ -n "$QUESTION_ID" ] && QID_FIELD="\"$QUESTION_ID\""
FOL_FIELD="null"; case "$FOLLOWED_REC" in true) FOL_FIELD=true ;; false) FOL_FIELD=false ;; esac

# ─── Append one line (local only) ────────────────────────────
printf '{"v":1,"ts":"%s","event_type":"%s","skill":"fireworks-training","skill_version":"%s","os":"%s","session_id":"%s","reference_used":%s,"outcome":"%s","error_class":%s,"duration_s":%s,"question_id":%s,"followed_recommendation":%s}\n' \
  "$TS" "$EVENT_TYPE" "$VERSION" "$OS" "$SESSION_ID" \
  "$REF_FIELD" "$OUTCOME" "$ERR_FIELD" "$DUR_FIELD" \
  "$QID_FIELD" "$FOL_FIELD" >> "$JSONL_FILE" 2>/dev/null || true

exit 0
