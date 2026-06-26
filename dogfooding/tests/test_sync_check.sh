#!/usr/bin/env bash
# Auto-checked dogfooding cases: does the skill notice when the Fireworks docs
# change? Runs scripts/sync_check.py offline against a local llms.txt fixture
# (via FW_LLMS_TXT / FW_BASELINE env overrides).
source "$(dirname "$0")/lib.sh"
echo "Docs sync — does the skill notice when Fireworks docs change?"

TMP="$(mktemp -d)"
fixture="$TMP/llms.txt"
baseline="$TMP/baseline.txt"

mk_fixture() { : > "$fixture"; for u in "$@"; do echo "[x](https://docs.fireworks.ai/$u)" >> "$fixture"; done; }
runsc() { FW_LLMS_TXT="file://$fixture" FW_BASELINE="$baseline" python3 "$SYNC_CHECK" "$@" 2>&1; }

# Seed baseline from a fixture with two fine-tuning pages (+ one unrelated).
mk_fixture "fine-tuning/intro.md" "fine-tuning/choose.md" "guides/other.md"
runsc --update >/dev/null

# Nothing changed → quiet, success.
out="$(runsc)"; code=$?
assert_eq "$code" "0" "stays quiet when nothing changed"
assert_contains "$out" "In sync" "...and says it's in sync"

# A new fine-tuning page appears → flagged.
mk_fixture "fine-tuning/intro.md" "fine-tuning/choose.md" "fine-tuning/newpage.md"
out="$(runsc)"; code=$?
assert_eq "$code" "1" "flags a newly added page"
assert_contains "$out" "newpage.md" "...and names it"

# A page is removed → flagged.
mk_fixture "fine-tuning/intro.md"
out="$(runsc)"; code=$?
assert_eq "$code" "1" "flags a removed page"
assert_contains "$out" "choose.md" "...and names it"

# The docs format changes (no pages found) → fails loudly, doesn't pass silently.
mk_fixture "guides/only.md"
out="$(runsc)"; code=$?
assert_eq "$code" "2" "fails loudly if the docs format changes"

rm -rf "$TMP"
finish
