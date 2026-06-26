#!/usr/bin/env bash
# Tier 7 — doc-drift detection. Runs scripts/sync_check.py offline against a
# local llms.txt fixture (via FW_LLMS_TXT / FW_BASELINE env overrides).
source "$(dirname "$0")/lib.sh"
echo "Tier 7 — sync_check.py (doc drift)"

TMP="$(mktemp -d)"
fixture="$TMP/llms.txt"
baseline="$TMP/baseline.txt"

mk_fixture() { : > "$fixture"; for u in "$@"; do echo "[x](https://docs.fireworks.ai/$u)" >> "$fixture"; done; }
runsc() { FW_LLMS_TXT="file://$fixture" FW_BASELINE="$baseline" python3 "$SYNC_CHECK" "$@" 2>&1; }

# Seed baseline from a fixture with two in-scope pages (+ one out-of-scope).
mk_fixture "fine-tuning/intro.md" "fine-tuning/choose.md" "guides/other.md"
runsc --update >/dev/null

# F3 — in sync → exit 0
out="$(runsc)"; code=$?
assert_eq "$code" "0" "F3 in-sync exits 0"
assert_contains "$out" "In sync" "F3 reports in sync"

# F1 — a new in-scope page → exit 1 and lists it
mk_fixture "fine-tuning/intro.md" "fine-tuning/choose.md" "fine-tuning/newpage.md"
out="$(runsc)"; code=$?
assert_eq "$code" "1" "F1 added page exits 1"
assert_contains "$out" "newpage.md" "F1 lists the new page"

# F2 — a removed page → exit 1 and lists it
mk_fixture "fine-tuning/intro.md"
out="$(runsc)"; code=$?
assert_eq "$code" "1" "F2 removed page exits 1"
assert_contains "$out" "choose.md" "F2 lists the removed page"

# F4 — no in-scope pages (llms.txt format changed) → exit 2, not a silent pass
mk_fixture "guides/only.md"
out="$(runsc)"; code=$?
assert_eq "$code" "2" "F4 no in-scope pages exits 2 (fails loud)"

rm -rf "$TMP"
finish
