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

## Status

v1, built from public docs — dogfooding. Feedback welcome.
