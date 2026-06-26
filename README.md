# fireworks-training

An agent skill that teaches a coding agent (Claude Code, Cursor, Codex, …) to build correctly on the **Fireworks training product** — choosing a method, preparing data, launching jobs, custom training loops, picking shapes/models, cost, and deploying + troubleshooting — **without needing to ask a human**. Built from public Fireworks docs.

## Install

```bash
npx skills add terryfireworks/fireworks-training-skill
```

Installs into every skills-compatible agent (Claude Code, Cursor, +others). Update later with `npx skills update -y`. Manual: copy `SKILL.md` + `references/` into `~/.claude/skills/fireworks-training/` (or `.cursor/skills/`, or append `SKILL.md` to `AGENTS.md`).

## How it works (progressive disclosure)

- **`SKILL.md`** — always-loaded router: auto-attaches via its `description`, routes each task to the right reference, and carries the critical "always/never" rules. Small context footprint.
- **`references/`** — loaded only when the router points there: `getting-started`, `choose-method`, `training-api`, `models-shapes-and-cost`, `deploy-and-troubleshoot`.
- For anything not covered, the skill points the agent at the full machine-readable doc index (`docs.fireworks.ai/llms.txt`).

So the agent reads the description at startup, loads `SKILL.md` when a training task matches, then triages into exactly the doc it needs.

## Staying current

References are **link-first** (they link the live `.md` docs, so the agent reads current content). `scripts/sync_check.py` diffs `docs.fireworks.ai/llms.txt` against a committed baseline and flags new/removed fine-tuning pages, so the skill doesn't silently drift.

## Usage telemetry (local-only)

**The problem.** This skill runs on machines we don't control (Claude Code, Cursor, Codex). We can't read transcripts, so we're blind to what actually trips people up building on Fireworks training — which docs they need, where they get stuck, where the skill's routing is unclear. Without a signal, the skill improves on guesswork.

**What it does.** Each run appends one anonymous line to `~/.fireworks-skill/analytics/events.jsonl`. The logic is inlined in `SKILL.md` so it works on any install (the skills CLI ships only `SKILL.md`). It is **local-only — nothing is transmitted** — and captures no prompts, code, file paths, or keys (no free-text fields at all).

- **Three signals** — *usage* (`reference_used`: which docs people need), *blockers* (`outcome` + `error_class`: where they get stuck — quota, auth, dataset format…), *friction* (`question_id` + `followed_recommendation`: where the skill had to stop and ask, and whether its recommendation was right).
- **Crash detector** — a run that dies is still recorded (a pending marker is finalized as `unknown` on the next run), so failures aren't invisible.
- **On by default, easy opt-out** — `touch ~/.fireworks-skill/telemetry-off` or `FW_TELEMETRY=off`.
- **View it** — `scripts/fw_telemetry_report.sh` summarizes the local log.

**Outcomes.** A concrete readout of where people succeed vs. stall on Fireworks training — which feeds two things: (1) tightening the skill itself (better routing, fixing the references people fail on), and (2) a real-world signal of the product's rough edges. During dogfooding it's local-only; a backend collector can be added later (`events.jsonl` is the stable interface). See [`TELEMETRY.md`](TELEMETRY.md) for the full design and privacy model.

## Status

v1, built from public docs — dogfooding. Feedback welcome.
