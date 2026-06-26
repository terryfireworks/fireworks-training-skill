#!/usr/bin/env bash
# Shared helpers for the deterministic test suite (tiers 7–8).
set -uo pipefail

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$LIB_DIR/../.." && pwd)"
SKILL_MD="$REPO/skills/fireworks-training/SKILL.md"
SYNC_CHECK="$REPO/scripts/sync_check.py"

_PASS=0; _FAIL=0
ok() { _PASS=$((_PASS+1)); printf '  \033[32m✓\033[0m %s\n' "$1"; }
no() { _FAIL=$((_FAIL+1)); printf '  \033[31m✗\033[0m %s\n' "$1"; }

assert_contains() { # haystack needle desc
  case "$1" in *"$2"*) ok "$3" ;; *) no "$3  (missing: $2)" ;; esac
}
assert_eq() { # actual expected desc
  if [ "$1" = "$2" ]; then ok "$3"; else no "$3  (got '$1', want '$2')"; fi
}
finish() { echo; echo "  $_PASS passed, $_FAIL failed"; [ "$_FAIL" -eq 0 ]; }

# extract_bash <file> <heading-substring> <occurrence>
# Prints the body of the Nth ```bash block that appears after the heading line.
# Lets the telemetry tests run the EXACT code shipped in SKILL.md.
extract_bash() {
  awk -v h="$2" -v want="${3:-1}" '
    !found && index($0,h) { found=1; next }
    found && /^```bash/    { n++; if (n==want) cap=1; next }
    found && /^```/        { if (cap) exit; next }
    cap                    { print }
  ' "$1"
}
