# Training API (custom training loops)

*Source of truth: [Training API intro](https://docs.fireworks.ai/fine-tuning/training-api/introduction.md) · [cookbook](https://github.com/fw-ai/cookbook) — defer to the live docs/repo for current SDK + recipes.*

Write your **own** Python training loop; Fireworks runs forward/backward on distributed GPUs. The SDK is **Tinker-compatible**, so Tinker code ports over with minimal changes. Low-level path — for standard runs prefer the managed UI.

Docs: https://docs.fireworks.ai/fine-tuning/training-api/introduction · Cookbook (start here): https://github.com/fw-ai/cookbook

> Status: private preview — request access at https://fireworks.ai/contact-training

## API vs managed UI

Use the **managed UI** for standard SFT/DPO (data + hyperparameters, no code). Reach for the **Training API** when you need: custom **loss/reward**, **RL with rollouts** (inference-in-the-loop), access to forward-pass internals (e.g. MoE routing for R3), or multi-turn/agentic trajectories.

## Default workflow: fork a cookbook recipe

Don't write a loop from scratch — fork a recipe in the `training/` tree of `fw-ai/cookbook`:
- `training/recipes/` — loop scripts (e.g. `async_rl_loop`)
- `training/examples/` — worked RL / SFT / DPO / ORPO
- `training/utils/` — config, data loading, losses, metrics

Recipes cover SFT, DPO/ORPO, and RL (GRPO, DAPO, GSPO, CISPO).

## Core SDK primitives

- `forward_backward` — built-in losses by id (e.g. `"cross_entropy"`), no extra forward pass.
- `forward_backward_custom(datums, loss_fn)` — your Python loss; returns per-token logprobs with gradients. **Loss runs locally; forward/backward run on remote GPUs.**
- `forward` — forward-only (e.g. reference-model logprobs).
- `optim_step(...)` — optimizer update after gradient accumulation.
- `save_weights_for_sampler()` + `create_sampling_client()` — export a checkpoint + stand up a sampler (weight sync for eval/rollouts).

Loss docs: https://docs.fireworks.ai/fine-tuning/training-api/loss-functions

```python
def loss_fn(data, logprobs_list):   # logprobs_list: per-token, requires_grad
    # return (scalar differentiable loss, {metrics for logging})
    ...
```

## RL: async loop + rollouts

RL recipe: https://docs.fireworks.ai/fine-tuning/training-api/cookbook/rl

`training.recipes.async_rl_loop.main` runs rollout sampling + training as concurrent tasks (superset of synchronous on-policy GRPO). You write `rollout.py` (samples a trajectory, computes the **reward**, returns a `RolloutSample`) and `train.py` (`Config` + `main`). `RolloutSample` = parallel per-token `tokens` / `logprobs` / `loss_mask` + a scalar `reward`; multi-turn flattens into the same shape. Key knobs: `policy_loss` (`grpo`/`dapo`/`gspo`/`cispo`/…), `max_head_offpolicy_versions` (0 = strict on-policy), `completions_per_prompt`.

## Numerics alignment & MoE Router Replay (R3)

Trainer↔inference divergence silently wrecks RL. Required reading: https://docs.fireworks.ai/fine-tuning/rl-rollout-integration#numerics-alignment
- Match **precision/quantization** between trainer checkpoints and the deployment shape.
- Measure **logprob divergence** between trainer forward and rollout inference on the same tokens.
- **MoE → Router Replay (R3):** align the top-K experts the router picks. Inference returns them via `include_routing_matrix: true` + `logprobs: true`; feed them back through `loss_fn_inputs`. https://docs.fireworks.ai/guides/rollout-inference#moe-router-replay

## Critical rules

- **Start from a cookbook recipe**, not a blank loop.
- **Align numerics** before trusting any RL signal; turn on **R3** for MoE.
- **For RL, use a dedicated rollout deployment** (sized for sampling), not your prod endpoint.
- Use `forward_backward_custom` only for a genuinely custom objective; otherwise the built-in path is cheaper.
- Loss must be differentiable w.r.t. `logprobs_list`; the metrics dict is logging-only.
