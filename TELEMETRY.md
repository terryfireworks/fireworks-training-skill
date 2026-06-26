# Telemetry — design & privacy

Adapted from [gstack](https://github.com/garrytan/gstack)'s pattern, trimmed to the
dogfooding essentials.

## Problem

The skill runs on machines we don't control (Claude Code, Cursor, Codex) and we
never see the transcripts. So we have no visibility into what actually trips
people up building on Fireworks training — which references they need, where they
get stuck, where the skill's routing is ambiguous. Without a signal, every
improvement to the skill is a guess.

## Outcomes

A concrete, anonymous readout of where people succeed vs. stall, which drives:
- **A better skill** — fix the references people fail on, tighten ambiguous routing.
- **A product signal** — the error classes people hit (quota, auth, dataset
  format, deploy, numerics) are a real-world map of the training product's rough
  edges.

Goal: get that signal **without ever seeing their code, and without standing up
any backend yet.**

**Local-only.** Every install writes an anonymous usage log to
`~/.fireworks-skill/analytics/events.jsonl`. Nothing is transmitted anywhere. A
backend collector can be added later (see "Future" below); until then, data is
collected manually with the report script.

**Inlined in SKILL.md.** The `skills` CLI (`npx skills add`) installs **only
`SKILL.md`** — supporting files are not copied. So the logging logic lives
directly in the SKILL.md preamble/epilogue as self-contained bash (no external
script, no VERSION file). `scripts/fw_telemetry_report.sh` is a *maintainer* tool
run from the repo to inspect collected data; it isn't shipped or needed at runtime.

## How it flows

```
SKILL.md preamble  ──▶ .pending-<session> marker        (crash detector)
SKILL.md epilogue  ──▶ inline bash: append 1 JSON line
                              ▼
                   ~/.fireworks-skill/analytics/events.jsonl   (local, durable)
                              ▼
                   scripts/fw_telemetry_report.sh        (maintainer, from repo)
```

- **Non-blocking.** The skill only appends one line. Telemetry can never break a
  user's task (`set -uo pipefail`, every line `|| true`, always `exit 0`).
- **Crash detector.** Preamble drops `.pending-<session>`; epilogue deletes it on
  clean finish. A run that dies leaves its marker, and the *next* run reports that
  earlier run as `outcome:unknown` — so crashes are still captured.

## Consent

On by default, **local-only**, and disclosed in the preamble. Opt out anytime:

```bash
touch ~/.fireworks-skill/telemetry-off     # or: export FW_TELEMETRY=off
```

## What's collected — and never collected

Collected (per event): `event_type`, `skill_version`, `os`, `session_id`,
`reference_used`, `outcome`, `error_class` (a short enum, not a message),
`duration_s`, `question_id`, `followed_recommendation`.

Never: prompts, code, file paths, dataset contents, API keys, error messages, or
any device/user identifier. The client has **no free-text fields**, so there's
nothing to redact or leak.

## The signals

| Signal | Field | Tells us |
|--------|-------|----------|
| Usage | `reference_used` | which docs people actually need |
| Blockers | `outcome` + `error_class` | where people get stuck on Fireworks training |
| Friction | `question_id` + `followed_recommendation` | where the skill's routing is ambiguous |

## Future: adding a collector

`events.jsonl` is the stable interface. When engineering sets up a backend, the
only new piece is a sync that POSTs unsent lines to an endpoint (gstack's
`telemetry-sync` is a ~60-line reference: rate-limited, cursor-tracked, advances
only on success).

**Before any data leaves the machine, switch consent from opt-out to opt-in** —
local logging and transmitted logging warrant different defaults.
