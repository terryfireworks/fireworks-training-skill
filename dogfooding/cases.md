# Dogfooding cases

What we check the skill against, in plain English. Two kinds:

- **Automatic** — verify the plumbing; run `dogfooding/tests/run.sh` (no agent, no network).
- **By hand** — try these on the skill and confirm it does the right thing. (Also stored
  machine-readably in `dogfooding/tests/behavior-cases.jsonl` for a future auto-judge.)

These trace back to the goal: the skill should answer customers' training questions
**without needing a human**, and **stay in sync with the live docs**.

## Automatic cases

**Does it record what happens?** (telemetry)
- A normal run is recorded — which reference was used, that it succeeded — exactly once.
- A failure is recorded with its error type (quota, auth, …).
- A stop-and-ask is recorded, including whether the agent's suggestion was taken.
- A run that crashes is still recorded (caught by the next run).
- Opting out records nothing.
- Every record is valid JSON.

**Does it notice when the Fireworks docs change?** (doc sync)
- Quiet when nothing changed.
- Flags (and names) a newly added fine-tuning page.
- Flags (and names) a removed page.
- Fails loudly if the docs format changes (doesn't pass silently).

## By-hand cases

**Opens the right guide**
- "Install firectl and run my first fine-tune" → getting-started
- "SFT, DPO, or RFT for my data?" → choose-method
- "Custom RL loss with rollouts" → training-api
- "Which shape/GPU, and what will it cost?" → models-shapes-and-cost
- "My deployed model returns base behavior" → deploy-and-troubleshoot
- "Fine-tune Llama on 2k transcripts and launch it" → choose-method, then getting-started
- "Fine-tune an embedding model?" (not covered) → falls back to live docs / says out of scope; no guessing

**Answers it without a human**
- 2,000 labeled transcripts, match our tone → SFT (not DPO), LoRA defaults
- 300 prompts + a grader, no gold answers → RFT, ~200–500 prompts, free under 16B
- Only A-better-than-B pairs → DPO, one-turn only
- "How do I deploy the LoRA?" → on-demand only, live-merge vs multi-LoRA, tear down
- "Bill is higher than expected" → per-token vs per-GPU-hour; scale to zero / delete idle

**Follows the always/never rules**
- "What settings to start with?" → SFT + LoRA + defaults, change one thing at a time
- "Done testing my deployment" → tear it down / scale to zero
- "How should automation authenticate?" → scoped/service-account key, never admin, never commit
- "Upload a CSV for SFT?" → no, needs JSONL `messages`; validate before upload
- "Noisy RL reward on an MoE model" → align numerics + Router Replay (R3) first

**Stays current (no made-up numbers)**
- "Exact price to SFT Llama-70B?" → looks it up live, doesn't quote a hardcoded number
- "Max context for Qwen3.5?" → live shapes/context table
- "Which base models can I fine-tune?" → live tunable-models registry
- "Shape ID for model X?" → live catalog, full path

**Knows when to get a human (the ~1%)**
- "Custom Training API loop" → it's private preview, point to request access
- "Insufficient GPU quota" → quota is a ceiling; raise it / smaller model; not a bug
- "Suspended despite credits" → billing-side, distinct from quota
- A genuinely undocumented ask → admits it, points to live docs/support, doesn't fabricate

**Doesn't give bad advice**
- "Serve my fine-tuned LoRA on serverless?" → no, on-demand only
- "Is this a Fireworks bug?" → check quota vs billing before assuming a bug
