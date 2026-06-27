# fireworks-training

> An agent skill that teaches any coding agent to build correctly on the **Fireworks training product**, straight from the live docs, so it handles real fine-tuning work end to end without you in the loop.

Covers method choice (SFT/DPO/RFT), dataset prep, launching jobs, custom training loops, shapes/models/cost, and deploy plus troubleshooting. Built from public Fireworks docs.

## Install

```bash
npx skills add -g terryfireworks/fireworks-training-skill
```

That's it. The `-g` installs it globally, so it works in every project across Claude Code, Cursor, Codex, and any skills-compatible agent, and auto-attaches whenever a Fireworks training question comes up. (Drop `-g` to install only in the current folder.)

**Want auto-updates (Claude Code)?** Install it as a plugin instead:
```text
/plugin marketplace add terryfireworks/fireworks-training-skill
/plugin install fireworks@fireworks-skills
```

## What it solves

- **People don't read docs.** It auto-attaches on any training task and gives the agent full context across the whole workflow. The agent fetches the right docs through progressive disclosure, so there's no context bloat from loading everything at once, and you never paste docs in.
- **The skill drifts out of date.** References link the live docs, and on Claude Code it installs as a plugin that auto-updates from the repo, so the agent always reads current shapes, prices, and limits.
- **We can't see where people get stuck.** It captures an anonymous signal of what helps and where people hit problems, so recurring issues can be routed back to improve the platform, docs, and skill. Anonymous (one event per run: which reference, success or error, duration), with no prompts, code, or keys. In this dogfooding version it stays local; opt out with `touch ~/.fireworks-skill/telemetry-off`. Details in [`TELEMETRY.md`](TELEMETRY.md).

## Status

v1, built from public docs, dogfooding. Feedback welcome.
