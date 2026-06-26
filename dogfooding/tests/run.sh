#!/usr/bin/env bash
# Deterministic test suite (tiers 7–8) for the fireworks-training skill.
# No agent / network required. CI-friendly: exits non-zero on any failure.
cd "$(dirname "$0")"
fail=0
for t in test_sync_check.sh test_telemetry.sh; do
  echo "════ $t ════"
  bash "$t" || fail=1
  echo
done
if [ "$fail" -eq 0 ]; then echo "✓ ALL DETERMINISTIC TESTS PASSED"; else echo "✗ SOME TESTS FAILED"; fi
exit "$fail"
