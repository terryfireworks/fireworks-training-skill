#!/usr/bin/env bash
# Auto-checked dogfooding cases for the fireworks-training skill.
# No agent / network needed. CI-friendly: exits non-zero on any failure.
cd "$(dirname "$0")"
fail=0
for t in test_sync_check.sh test_telemetry.sh; do
  echo "──────────────────────────────────────────"
  bash "$t" || fail=1
  echo
done
if [ "$fail" -eq 0 ]; then echo "✓ all automatic dogfooding cases passed"; else echo "✗ some cases failed"; fi
exit "$fail"
