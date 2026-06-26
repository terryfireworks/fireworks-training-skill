# Choosing a fine-tuning method + preparing data

*Source of truth: [Fine-tuning intro](https://docs.fireworks.ai/fine-tuning/finetuning-intro.md) — defer to the live docs for current dataset schemas + method support.*

Pick the method that matches the *signal you have*, not the one that sounds most advanced. Start simple (SFT); escalate only when your data demands it. Source: https://docs.fireworks.ai/fine-tuning/finetuning-intro

## Decision tree

```
Do you have labeled ground-truth outputs?
├─ Yes, >1000 examples ............................ SFT
├─ Yes, 100–1000 + reasoning helps ................ RFT
├─ Yes, 100–1000 + no reasoning needed ............ SFT
├─ Only "A is better than B" preference pairs ..... DPO
└─ No labels, but outputs are verifiable/scorable . RFT
```

| Method | You provide | Best for |
|--------|-------------|----------|
| **SFT** | Labeled `messages` (the ideal output) | Classification, extraction, style/format, tool-call shaping. The default. |
| **DPO** | preferred vs non-preferred responses | Aligning tone/quality when you can rank two answers but can't write the one true answer. |
| **RFT** | Prompts + an evaluator/reward (0.0–1.0) | Verifiable tasks (math, code, agents) with few labels. |

## SFT format

JSONL, one object per line; OpenAI-style `messages`. **Min 3, max 3M** (aim for 1000+ for quality). Optional per-message `weight` (0 skips from loss).

```jsonl
{"messages":[{"role":"system","content":"You are a helpful assistant."},{"role":"user","content":"Capital of France?"},{"role":"assistant","content":"Paris."}]}
```

Docs: https://docs.fireworks.ai/fine-tuning/fine-tuning-models · [weighted training](https://docs.fireworks.ai/fine-tuning/weighted-training)

## DPO format

Preference pairs, **one-turn only** (preferred/non-preferred must be the last assistant turn). Two accepted shapes:

```jsonl
{"input":{"messages":[{"role":"user","content":"What is Einstein famous for?"}]},"preferred_output":[{"role":"assistant","content":"His theory of relativity, E=mc²."}],"non_preferred_output":[{"role":"assistant","content":"He was a scientist."}]}
```
(Training API also accepts `chosen`/`rejected`.) Docs: https://docs.fireworks.ai/fine-tuning/dpo-fine-tuning

## RFT — reinforcement fine-tuning

Provide three things (not labeled outputs): a **dataset** of prompts; an **evaluator** that scores an output 0.0→1.0 (the reward), registered via `pytest` or a remote service; and the **agent** being trained. Start with **200–500 diverse prompts**. Docs: https://docs.fireworks.ai/fine-tuning/how-rft-works · [evaluators](https://docs.fireworks.ai/fine-tuning/evaluators)

## LoRA vs full-parameter

**Pick LoRA first** — small adapter, cheaper/faster, fewer GPUs, deployable on the base model. **LoRA rank** default 8 (range 4–32); raise for complex reasoning, keep low for style/format. Go **full-parameter** only when LoRA plateaus and you have GPU budget. Docs: https://docs.fireworks.ai/fine-tuning/parameter-tuning

## RL loss methods (RFT)

- **GRPO** (default) — group-relative, symmetric clip `[0.8,1.2]`, small KL penalty. Conservative baseline; start here.
- **DAPO** — asymmetric clip `[0.8,1.28]`, no KL; more aggressive/faster.
- **GSPO-token** — sequence-level IS, tight clipping; stability + long-form, may need more steps.

## Critical rules

- **Default to SFT.** DPO only with preference pairs; RFT only with a reward/verifiable task.
- **Validate dataset format before uploading** — JSONL, one object/line, right schema, roles in order. Min 3, max 3M.
- **DPO is one-turn only.**
- **Start LoRA + defaults** (rank 8, 1 epoch, LR ~1e-4); change one thing at a time, watch the curves.
- **Iterate cheap first** — validate evaluator/data on a small model before scaling.
