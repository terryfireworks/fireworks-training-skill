# fireworks-training

> An agent skill that teaches any coding agent to build correctly on the **Fireworks training product** — straight from the live docs, so it handles real fine-tuning work end-to-end **without needing to ask a human**.

Built from public Fireworks docs. Covers method choice (SFT/DPO/RFT), dataset prep, launching jobs via `firectl`, custom training loops (Training API), picking shapes/models, cost, and deploying + troubleshooting.

## What you get

- **Works in your agent harness, with full context.** Drop it into Claude Code, Cursor, Codex, or any skills-compatible agent. It auto-attaches the moment a training task comes up and routes to exactly the right depth — broad enough to cover the whole workflow, specific enough to write correct code. The agent gets the context it needs without you pasting docs.
- **Always up to date & synced.** References are *link-first* — they point at the live `.md` docs, so the agent reads current values (shapes, prices, context limits), never a stale snapshot. A drift check flags when Fireworks adds or removes fine-tuning pages, and the plugin **auto-updates from this repo**, so everyone stays on the latest guidance.
- **Self-improving.** It captures an anonymous signal of what helps and where people get stuck — which docs they need, what errors they hit, where the skill had to stop and ask. Today that stays **local on each machine**; it's built to roll up to Fireworks (opt-in) so the docs *and* the skill keep improving from real usage. See [Telemetry](#telemetry).

## Install

Pick one — the skill auto-attaches by its `description` whenever a Fireworks training task comes up.

**A) Claude Code plugin — stays current automatically (recommended)**
```text
/plugin marketplace add terryfireworks/fireworks-training-skill
/plugin install fireworks@fireworks-skills
```
Then enable auto-update once: `/plugin` → **Marketplaces** → **Auto-update** on `fireworks-skills`. New commits are pulled at startup after that. (Self-hosted marketplaces are opt-in per user; an org can force it via `managed-settings.json`.)

**B) Cross-agent (Cursor, Codex, …) — one line, manual updates**
```bash
npx skills add terryfireworks/fireworks-training-skill   # update: npx skills update -y
```

<details>
<summary>C) Dogfooding / contributing — live edits, no reinstall</summary>

```bash
git clone https://github.com/terryfireworks/fireworks-training-skill.git ~/Desktop/fireworks-training-skill
ln -s ~/Desktop/fireworks-training-skill/skills/fireworks-training ~/.claude/skills/fireworks-training
```
Edits to `SKILL.md` take effect immediately. Dogfooding tooling (report + tests) lives in [`dogfooding/`](dogfooding/).
</details>

## How it works (progressive disclosure)

- **`SKILL.md`** — always-loaded router: auto-attaches, routes each task to the right reference, carries the critical "always/never" rules. Small context footprint.
- **`references/`** — loaded only when the router points there: `getting-started`, `choose-method`, `training-api`, `models-shapes-and-cost`, `deploy-and-troubleshoot`.
- Anything not covered → the agent is pointed at the full machine-readable doc index (`docs.fireworks.ai/llms.txt`).

## Staying current

References link the live docs, so content is always fresh. `scripts/sync_check.py` diffs `docs.fireworks.ai/llms.txt` against a committed baseline and flags new/removed fine-tuning pages in CI, so the skill never silently drifts.

## Telemetry

Local-only, anonymous, on by default. Two tiny bash hooks in `SKILL.md` append one event per run to `~/.fireworks-skill/analytics/events.jsonl` — **which reference was used, success/error + error class, duration, and any stop-and-ask** (including whether the agent's recommendation was taken). It captures **no prompts, code, file paths, or keys** — there are no free-text fields to leak.

Today **nothing is transmitted**; the data is the signal behind "self-improving" above, and `events.jsonl` is the stable interface for a future opt-in collector that rolls it up to Fireworks. Opt out anytime: `touch ~/.fireworks-skill/telemetry-off` or `export FW_TELEMETRY=off`. Full design + privacy in [`TELEMETRY.md`](TELEMETRY.md); dogfooding + tests in [`dogfooding/`](dogfooding/).

## Status

v1, built from public docs — dogfooding. Feedback welcome.
