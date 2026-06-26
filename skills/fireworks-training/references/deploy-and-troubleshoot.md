# Deploy your fine-tuned model + troubleshooting

*Source of truth: [Deploying fine-tuned models](https://docs.fireworks.ai/fine-tuning/deploying-loras.md) · [numerics alignment](https://docs.fireworks.ai/fine-tuning/rl-rollout-integration.md) — defer to the live docs for current behavior.*

Take a trained adapter live, smoke-test it, tear it down to stop spend, keep numerics aligned, and recover from common failures.

## Deploy after training (LoRA → on-demand only)

A fine-tuned LoRA **cannot run on serverless** — it needs an **on-demand (dedicated) deployment**. Two methods:

| | **Live merge** | **Multi-LoRA** |
|---|---|---|
| How | LoRA merged into base at deploy → one model | Base + addons; adapters loaded per request |
| # LoRAs | One per deployment | Many per deployment |
| Perf | Matches base | Slightly higher TTFT; lower max throughput |
| Best for | Single model in prod | Experiments / many variants |

**One adapter → live merge** (simplest):
```bash
firectl deployment create "accounts/<ACCOUNT_ID>/models/<FINE_TUNED_MODEL_ID>"
```
**Multi-LoRA:**
```bash
firectl deployment create "accounts/fireworks/models/<BASE_MODEL_ID>" --enable-addons
firectl load-lora <FINE_TUNED_MODEL_ID> --deployment <DEPLOYMENT_ID>
# route per request: model="<model_name>#<deployment_name>"
```
> **Addon gotcha:** `--enable-addons` works only on **BF16** shapes (FP8/FP4 reject addons). Use a BF16 shape or live merge.

Docs: [Deploying fine-tuned models](https://docs.fireworks.ai/fine-tuning/deploying-loras), [On-demand deployments](https://docs.fireworks.ai/guides/ondemand-deployments).

## Smoke-test

- **Playground:** open the deployment in the [dashboard](https://app.fireworks.ai), send prompts.
- **API:** `POST https://api.fireworks.ai/inference/v1/chat/completions` with the model string above. A base-only response usually means the adapter wasn't promoted/loaded.

## CLEAN UP — stop the spend

On-demand bills by **GPU-second while replicas are active, even with no traffic**:
```bash
firectl deployment list
firectl deployment delete <DEPLOYMENT_ID>
```
Lighter: `scale_to_zero` (min/max replicas = 0). Defaults: scale to zero after ~1h idle; min-0 deployments auto-deleted after 7 days idle. A scaled-to-zero deployment returns **`503 DEPLOYMENT_SCALING_UP`** on the first request — add retry/backoff.

## Numerics alignment (why outputs drift)

Training and inference are different code paths; mismatched numerics cause logprob/output drift (and in RL, wasted rollouts):
- **Match precision/quantization** (FP8 / BF16 / FP4) between trainer checkpoints and the deployment shape.
- **Measure logprob divergence** on the same tokens.
- **MoE → Router Replay (R3):** divergence often comes from the router picking different top-K experts; pass `include_routing_matrix: true` + `logprobs: true`. Docs: [Numerics alignment](https://docs.fireworks.ai/fine-tuning/rl-rollout-integration#numerics-alignment), [MoE Router Replay](https://docs.fireworks.ai/guides/rollout-inference#moe-router-replay).

## Common failures + recovery

- **Insufficient GPU quota:** quota is a **ceiling on concurrent GPUs**, not a billing state. Raise it ([account quotas](https://docs.fireworks.ai/guides/quotas_usage/account-quotas)) or pick a smaller model.
- **Account suspended / "spending limit reached":** **billing-side**, distinct from quota — budget cap hit (even with credits), no payment method, or risk review. Fix in [Billing](https://fireworks.ai/billing). ([why suspended with credits](https://docs.fireworks.ai/faq-new/billing-pricing/why-might-my-account-be-suspended-even-with-remaining-credits))
- **412 precondition / shape unavailable:** the requested shape isn't enabled on your account — pick a listed shape or contact support.
- **Adapter not promoted / base behavior:** confirm the job finished + model exists; for multi-LoRA confirm `load-lora` succeeded and you route with `model#deployment`.
- **429 on an on-demand deployment:** capacity saturation, **not** quota — back off or scale replicas.

## Critical rules

- **LoRA = on-demand only** (serverless won't serve fine-tuned LoRAs).
- **One adapter → live merge; many → multi-LoRA on a BF16 shape.**
- **Always tear down / `scale_to_zero` when done** — on-demand bills by GPU-second even when idle.
- **Align numerics before trusting outputs** (precision + logprob divergence + R3 for MoE).
- **Before assuming a Fireworks bug, check quota (a GPU ceiling) and billing (suspension = billing-side)** — different controls.
