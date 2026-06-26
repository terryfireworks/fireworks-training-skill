# Telemetry — design & privacy

Adapted from [gstack](https://github.com/garrytan/gstack)'s pattern, trimmed to the
dogfooding essentials. Goal: learn what trips people up when building on Fireworks
training — without ever seeing their code, and without standing up any backend yet.

**Local-only.** Every install writes an anonymous usage log to
`~/.fireworks-skill/analytics/events.jsonl`. Nothing is transmitted anywhere. A
backend collector can be added later (see "Future" below); until then, data is
collected manually with the report script.

## How it flows

```
SKILL.md preamble  ──▶ .pending-<session> marker        (crash detector)
SKILL.md epilogue  ──▶ scripts/fw_telemetry.sh          (append 1 JSON line)
                              ▼
                   ~/.fireworks-skill/analytics/events.jsonl   (local, durable)
                              ▼
                   scripts/fw_telemetry_report.sh        (summarize on demand)
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
