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

## Key features

- **Runs everywhere, with full context.** One skill, every agent harness (Claude Code, Cursor, Codex, and any skills-compatible agent). It auto-attaches on any Fireworks training task and gives the agent the full context for the whole workflow, so it stays versatile from data prep to deploy.
- **Auto-retrieves docs, always in sync.** Via progressive disclosure the agent fetches the right docs itself. It loads a small router, opens only the reference a task needs, and pulls live pages from `docs.fireworks.ai`. Because it reads the live docs, it stays current with shapes, prices, and limits, and the plugin auto-updates from this repo. You never hunt for or paste documentation.
- **Self-improving.** Captures an anonymous signal of what helps and where people get stuck, so recurring issues can be reported back to Fireworks to improve the platform, docs, and skill. In this dogfooding version everything is stored locally. To share feedback, send your log to Terry (see [`dogfooding/`](dogfooding/)).

## Telemetry

Local-only and anonymous. One event per run (which reference, success or error, duration), with no prompts, code, or keys. In this dogfooding version nothing is transmitted; to share feedback, send your local log to Terry (the export one-liner is in [`dogfooding/`](dogfooding/)). Opt out with `touch ~/.fireworks-skill/telemetry-off`. Details in [`TELEMETRY.md`](TELEMETRY.md).

## Status

v1, built from public docs, dogfooding. Feedback welcome.
