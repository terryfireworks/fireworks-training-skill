# Dogfooding

Everything for running the internal dogfood of the fireworks-training skill:
how people install it, how their feedback reaches you, and the tests that keep it
honest.

## For dogfooders — install & give feedback

**Install** (pick one; the skill auto-attaches on any Fireworks training question):

- Claude Code (auto-updates as fixes land):
  ```
  claude plugin marketplace add terryfireworks/fireworks-training-skill
  claude plugin install fireworks@fireworks-skills
  ```
  Then `/plugin` → Marketplaces → enable Auto-update for `fireworks-skills`.
- Other agents (Cursor/Codex): `npx skills add terryfireworks/fireworks-training-skill`

**Send feedback** (telemetry is local-only — no auto-collection). After using it,
run this and send the file it drops on your Desktop:

```bash
cp ~/.fireworks-skill/analytics/events.jsonl ~/Desktop/fw-feedback-$(whoami)-$(date +%Y%m%d).jsonl 2>/dev/null \
  && echo "Saved to your Desktop — send me that file" || echo "No feedback yet — use the skill first"
```

Anonymous enum-ish fields only (no prompts/code/keys). See [`../TELEMETRY.md`](../TELEMETRY.md).

## For the maintainer — review feedback

Drop everyone's files in one folder and aggregate:

```bash
dogfooding/report.sh ~/Desktop/dogfood-feedback/   # a folder of collected *.jsonl
dogfooding/report.sh                               # or just this machine's log
```

Shows outcomes, which references people needed, blockers (error classes), and
interaction friction.

## Tests

Two layers (see [`tests/`](tests/)):

- **Deterministic (tiers 7–8)** — run today, no agent/network:
  ```bash
  dogfooding/tests/run.sh
  ```
  - `test_sync_check.sh` — doc-drift detection (added/removed pages, format change)
  - `test_telemetry.sh` — the inline prolog/epilog: events, crash detector, opt-out, valid JSON
- **Behavior evals (tiers 1–6)** — [`tests/evals/`](tests/evals/): routing, autonomy,
  critical-rules, defer-to-live, escalation, safety. Test set is written; needs an
  agent + judge harness to run (scaffold).

What each tier proves, mapped to the goals: routing/autonomy = "99% no human";
defer-to-live + `sync_check` = "stay in sync with the docs"; escalation = the 1%
boundary; telemetry = the dogfooding signal stays trustworthy.
