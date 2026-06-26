# fireworks-training

> An agent skill that teaches any coding agent to build correctly on the **Fireworks training product**, straight from the live docs, so it handles real fine-tuning work end to end without you in the loop.

Covers method choice (SFT/DPO/RFT), dataset prep, launching jobs, custom training loops, shapes/models/cost, and deploy plus troubleshooting. Built from public Fireworks docs.

## Install

```bash
npx skills add terryfireworks/fireworks-training-skill
```

That's it. It works in Claude Code, Cursor, Codex, and any skills-compatible agent, and auto-attaches whenever a Fireworks training question comes up.

**Want auto-updates (Claude Code)?** Install it as a plugin instead:
```text
/plugin marketplace add terryfireworks/fireworks-training-skill
/plugin install fireworks@fireworks-skills
```

## Key features

- **No copy-pasting docs.** Via progressive disclosure the agent retrieves the right docs itself. It loads a small router, opens only the reference a task needs, and fetches live pages from `docs.fireworks.ai`. You never hunt for or paste documentation.
- **Always up to date.** References link the live docs, so the agent reads current shapes, prices, and limits rather than a stale snapshot, and the plugin auto-updates from this repo.
- **Self-improving.** Captures an anonymous, local-only signal of what helps and where people get stuck, designed to roll up to Fireworks (opt-in) so the docs and skill keep improving.
- **Runs anywhere.** One skill, every agent harness, no setup beyond install.

## Telemetry

Local-only and anonymous. One event per run (which reference, success or error, duration), with no prompts, code, or keys. Nothing is transmitted today. Opt out with `touch ~/.fireworks-skill/telemetry-off`. Details in [`TELEMETRY.md`](TELEMETRY.md); dogfooding and tests in [`dogfooding/`](dogfooding/).

## Status

v1, built from public docs, dogfooding. Feedback welcome.
