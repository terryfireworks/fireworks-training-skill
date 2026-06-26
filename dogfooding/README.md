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

## Cases

All the cases we check the skill against — in plain English — are in
[`cases.md`](cases.md). Two kinds:

- **Automatic** — verify the plumbing (telemetry + doc-sync). Run today, no agent:
  ```bash
  dogfooding/tests/run.sh
  ```
- **By hand** — try them on the skill and confirm it answers right (opens the right
  guide, solves without a human, stays current, knows when to escalate). Also stored
  machine-readably in [`tests/behavior-cases.jsonl`](tests/behavior-cases.jsonl) for a
  future auto-judge.
