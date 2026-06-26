---
name: fireworks-training
description: >-
  Build on the Fireworks fine-tuning / training product: choosing a method (SFT/DPO/RFT),
  preparing datasets, launching jobs via firectl or the managed UI, writing custom training
  loops with the Training API (Tinker-compatible cookbook recipes, RL/GRPO, distillation),
  picking training shapes + models + context/LoRA rank, cost (GPU-hour vs per-token), and
  deploying + troubleshooting fine-tuned models. Use when building, modifying, reviewing, or
  debugging any Fireworks training/fine-tuning work — SFT, DPO, RFT/RL, dataset prep, training
  shapes, deploying a fine-tuned model, or fixing a failed training job.
---

Fireworks lets you fine-tune open models and serve them on one platform. **Managed fine-tuning (SFT/DPO/RFT) is GA**; the **Training API (custom Python loops) is private preview** — request access at https://fireworks.ai/contact-training . Always use the latest model + the correct training shape from the live catalog, and prefer a **scoped/service-account API key** over a personal admin key.

## Telemetry preamble (run first, best-effort)

This skill keeps a **local-only** usage log (in `~/.fireworks-skill/`) to help improve it — anonymous, never transmitted, no prompts/code/keys. Opt out anytime with `touch ~/.fireworks-skill/telemetry-off`. Run this once at the start of a task; if anything isn't available (non-bash host, script missing), skip silently and continue:

```bash
mkdir -p ~/.fireworks-skill/analytics
FW_SID="$$-$(date +%s)"; FW_T0=$(date +%s)
echo '{"ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","reference":""}' > ~/.fireworks-skill/analytics/.pending-"$FW_SID" 2>/dev/null || true
```

## Before you build

Install + auth: `firectl` + `firectl signin` → `references/getting-started.md`.

**If the Fireworks training MCP is available, call `training_planner` first** (describe the task → it returns the recommended method + shape + recipe, from live data). Otherwise use the routing table below.

The references **link the live `.md` docs**; for any specific value (training shapes, models, context limits, prices, API params) **defer to the linked doc** — the references are durable guidance, not a snapshot to trust over the docs.

## Routing — read the matching reference before answering or writing code

| Task | Reference |
|---|---|
| Set up, install `firectl`, first job, quota | `references/getting-started.md` |
| Pick SFT vs DPO vs RFT; dataset format; LoRA vs full-param | `references/choose-method.md` |
| Custom training loop, cookbook recipes, RL/GRPO, custom loss/reward, numerics | `references/training-api.md` |
| Pick a training shape / model; context length; GPU class; what it costs | `references/models-shapes-and-cost.md` |
| Deploy a fine-tuned model; tear down; fix a failed job / quota / suspension | `references/deploy-and-troubleshoot.md` |

**Not covered above?** The full machine-readable doc index is at <https://docs.fireworks.ai/llms.txt> — find the relevant page and fetch its `.md` version (every page has one). The routing table covers the common paths; `llms.txt` + the live docs are the complete, always-current source.

## Critical rules

- **Start with SFT + LoRA + defaults** unless you have preference pairs (DPO) or a reward/verifiable task (RFT). Change one thing at a time; watch loss/reward curves.
- **Validate dataset format before uploading** — JSONL, one object per line, correct schema per method.
- **Let the platform map GPU → model** via the training shape; use the model's full context. Check the live catalog — don't hardcode shapes/models.
- **Fine-tuned LoRA deploys on-demand only** (live-merge or multi-LoRA), never serverless. **Tear down the deployment when done** — on-demand bills by GPU-second even when idle.
- **Align numerics** (precision + logprob divergence; Router Replay/R3 for MoE) before trusting RL signal.
- **Before assuming a Fireworks bug, check quota (a GPU ceiling) and billing (suspension/spending-limit is billing-side)** — different controls.
- SFT/DPO bill **per training token**; full-param/RFT trainers + deployments bill **per GPU-hour**. Saturate the GPU.

## Docs

Latest + machine-readable: https://docs.fireworks.ai/fine-tuning/finetuning-intro.md · prefer the `.md` URL form of any doc page. Training shapes catalog + pricing are generated live — link them, don't memorize.

## Telemetry epilogue (run last, best-effort)

At the end of the task, log one event. Set `OUTCOME` to `success`/`error`/`abort`, `REF` to the main `references/*.md` you used (or `none`), and `ERR` to a short error class only on failure (`quota`/`auth`/`dataset_format`/`deploy`/`numerics`/`other`). Skip silently if unavailable:

```bash
S="$HOME/.claude/skills/fireworks-training/scripts"; [ -d "$S" ] || S="$(pwd)/scripts"
[ -x "$S/fw_telemetry.sh" ] && "$S/fw_telemetry.sh" \
  --outcome "OUTCOME" --reference "REF" --error-class "ERR" \
  --duration "$(( $(date +%s) - ${FW_T0:-$(date +%s)} ))" --session-id "${FW_SID:-none}" 2>/dev/null || true
```

If you had to stop and ask the user a routing decision, also log the friction (use a stable `question_id`, and whether they took your recommended option):

```bash
[ -x "$S/fw_telemetry.sh" ] && "$S/fw_telemetry.sh" --event-type question \
  --question-id "QID" --followed-recommendation "true|false" --session-id "${FW_SID:-none}" 2>/dev/null || true
```

Data stays on the machine; run `scripts/fw_telemetry_report.sh` to view it. See `TELEMETRY.md` for the design and privacy model.
