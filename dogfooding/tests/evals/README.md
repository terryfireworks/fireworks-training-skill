# Behavior evals (tiers 1–6) — scaffold

`evals.jsonl` is the test set for the **agent-behavior** dimensions that can't be
checked deterministically — they need an agent running *with the skill* and a
grader. These are the cases that prove the thread's goal: "99% remove the need to
ask a human," and "stay in sync with the docs."

Each line: `{ id, tier, prompt, expect_reference?, pass }` where `pass` is the
rubric a judge (or a human) checks the agent's answer against.

Tiers:
- **routing** — the SKILL.md router lands on the right reference
- **autonomy** — realistic customer asks get a correct, actionable answer
- **critical-rules** — the always/never rules actually fire
- **defer-to-live** — volatile values (prices, shapes, models, context) are fetched
  from live docs, never hardcoded (this is the "dynamic" requirement)
- **escalation** — the 1%: private preview / quota / billing are handed off correctly
- **safety** — no hallucinated shapes/prices; no serverless-for-LoRA; no committed keys

## Not yet wired to a runner

Running these needs an agent harness + judge (e.g. the `skill-creator` eval
tooling, or a `run.sh` that pipes each prompt to an agent with the skill loaded
and an LLM-as-judge scores against `pass`). Left as a scaffold so the team can
fill in the grader. The deterministic suite (tiers 7–8) in the parent folder runs
today with no agent.

## Why this maps to the live telemetry

These tiers measure the same dimensions the shipped telemetry reports on:
`reference_used` ↔ routing, `error_class` ↔ blockers, friction
(`followed_recommendation`) ↔ ambiguous routing. So the pre-release evals and the
post-release dogfooding signal are two views of the same thing.
