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
# $PPID (the agent process) is stable across separate tool calls, so the
# epilogue can match this run; a plain shell var would not survive.
date +%s > ~/.fireworks-skill/analytics/.start-"$PPID" 2>/dev/null || true
echo '{"ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > ~/.fireworks-skill/analytics/.pending-"$PPID" 2>/dev/null || true
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

At the end of the task, append one local event. **Edit the three variables on the first line**: `REF` = the main `references/*.md` you used (or `none`); `OUTCOME` = `success`/`error`/`abort`; `ERR` = a short error class on failure only (`quota`/`auth`/`dataset_format`/`deploy`/`numerics`/`other`), else empty. Self-contained — skip silently on a non-bash host:

```bash
REF="none"; OUTCOME="success"; ERR=""   # ← edit these three
D=~/.fireworks-skill/analytics; SID="$PPID"
if [ "${FW_TELEMETRY:-on}" != off ] && [ ! -f ~/.fireworks-skill/telemetry-off ]; then
  mkdir -p "$D"; TS=$(date -u +%Y-%m-%dT%H:%M:%SZ); OS=$(uname -s|tr 'A-Z' 'a-z'); VER=0.1.0
  T0=$(cat "$D/.start-$SID" 2>/dev/null); case "$T0" in ''|*[!0-9]*) T0=$(date +%s);; esac
  # finalize any crashed prior runs (markers from other sessions → outcome:unknown)
  for f in "$D"/.pending-*; do
    [ -f "$f" ] || continue; sid=$(basename "$f"); sid=${sid#.pending-}
    [ "$sid" = "$SID" ] && continue
    pts=$(grep -o '"ts":"[^"]*"' "$f" 2>/dev/null|head -1|cut -d'"' -f4)
    printf '{"v":1,"ts":"%s","event_type":"skill_run","skill":"fireworks-training","skill_version":"%s","os":"%s","session_id":"%s","reference_used":"none","outcome":"unknown","error_class":null,"duration_s":null,"question_id":null,"followed_recommendation":null}\n' "$pts" "$VER" "$OS" "$sid" >> "$D/events.jsonl" 2>/dev/null
    rm -f "$f" "$D/.start-$sid" 2>/dev/null
  done
  rm -f "$D/.pending-$SID" "$D/.start-$SID" 2>/dev/null
  ejson=null; [ -n "$ERR" ] && ejson="\"$ERR\""
  printf '{"v":1,"ts":"%s","event_type":"skill_run","skill":"fireworks-training","skill_version":"%s","os":"%s","session_id":"%s","reference_used":"%s","outcome":"%s","error_class":%s,"duration_s":%s,"question_id":null,"followed_recommendation":null}\n' \
    "$TS" "$VER" "$OS" "$SID" "$REF" "$OUTCOME" "$ejson" "$(( $(date +%s) - T0 ))" >> "$D/events.jsonl" 2>/dev/null
fi
```

If you had to stop and ask the user a routing decision, also append a friction event (`QID` = a stable id for the question; `FOLLOWED` = `true`/`false` for whether they took your recommendation):

```bash
QID="route-method"; FOLLOWED=true   # ← edit these two
[ "${FW_TELEMETRY:-on}" != off ] && [ ! -f ~/.fireworks-skill/telemetry-off ] && \
printf '{"v":1,"ts":"%s","event_type":"question","skill":"fireworks-training","os":"%s","session_id":"%s","reference_used":"none","outcome":"unknown","error_class":null,"duration_s":null,"question_id":"%s","followed_recommendation":%s}\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(uname -s|tr 'A-Z' 'a-z')" "$PPID" "$QID" "$FOLLOWED" \
  >> ~/.fireworks-skill/analytics/events.jsonl 2>/dev/null || true
```

Data is local-only. Maintainers: view it with `dogfooding/report.sh` from the repo. See `TELEMETRY.md`.
