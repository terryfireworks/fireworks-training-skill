#!/usr/bin/env python3
"""Sync check for the fireworks-training skill.

Keeps the skill in sync with the live docs. Fetches docs.fireworks.ai/llms.txt,
extracts the set of fine-tuning / training doc pages, and compares it against a
committed baseline (known_pages.txt). Drift (added/removed pages) means the docs
changed and the skill may need updating — the check exits non-zero so CI flags it.

Usage:
  python sync_check.py            # report drift vs baseline; exit 1 if any
  python sync_check.py --update   # rewrite the baseline to current docs

Read-only against the network (no API key). The skill deliberately references a
*subset* of pages and links the live `.md` for specifics, so this checks for
*new/removed* pages to review — not 1:1 coverage.
"""
import os
import sys
import re
import urllib.request
from pathlib import Path

# Env overrides exist for testing (point at a local fixture / temp baseline).
LLMS_TXT = os.environ.get("FW_LLMS_TXT", "https://docs.fireworks.ai/llms.txt")
# Pages whose path matches these are "in scope" for the training skill.
IN_SCOPE = ("/fine-tuning/", "/fine-tuning.")
_bl = os.environ.get("FW_BASELINE")
BASELINE = Path(_bl) if _bl else Path(__file__).with_name("known_pages.txt")


def fetch_scope_pages() -> set[str]:
    with urllib.request.urlopen(LLMS_TXT, timeout=30) as r:
        text = r.read().decode("utf-8", "replace")
    # llms.txt lists pages as [Title](https://docs.fireworks.ai/path.md)
    urls = re.findall(r"\((https://docs\.fireworks\.ai/[^)]+\.md)\)", text)
    return {u for u in urls if any(s in u for s in IN_SCOPE)}


def read_baseline() -> set[str]:
    if not BASELINE.exists():
        return set()
    return {ln.strip() for ln in BASELINE.read_text().splitlines() if ln.strip() and not ln.startswith("#")}


def main() -> int:
    update = "--update" in sys.argv
    current = fetch_scope_pages()
    if not current:
        print("ERROR: no in-scope pages found in llms.txt (format changed?)", file=sys.stderr)
        return 2

    if update:
        BASELINE.write_text(
            "# Fine-tuning doc pages known to the fireworks-training skill.\n"
            "# Regenerate: python sync_check.py --update  (then review the skill + commit)\n"
            + "\n".join(sorted(current)) + "\n"
        )
        print(f"Baseline updated: {len(current)} pages -> {BASELINE.name}")
        return 0

    baseline = read_baseline()
    if not baseline:
        print("No baseline yet. Seed it with: python sync_check.py --update", file=sys.stderr)
        return 2

    added = sorted(current - baseline)
    removed = sorted(baseline - current)
    print(f"Live fine-tuning pages: {len(current)} | baseline: {len(baseline)}")
    if added:
        print(f"\nNEW pages since last sync ({len(added)}) — review whether the skill should cover them:")
        for u in added:
            print(f"  + {u}")
    if removed:
        print(f"\nREMOVED pages ({len(removed)}) — the skill may link a dead page:")
        for u in removed:
            print(f"  - {u}")
    if added or removed:
        print("\nDrift detected. Update the skill if needed, then re-baseline: python sync_check.py --update")
        return 1
    print("\nIn sync — no new or removed fine-tuning pages.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
