# fireworks-training

An agent skill that teaches a coding agent (Claude Code, Cursor, Codex, …) to build correctly on the **Fireworks training product** — choosing a method, preparing data, launching jobs, custom training loops, picking shapes/models, cost, and deploying + troubleshooting — **without needing to ask a human**. Built from public Fireworks docs.

## Install

Pick one. The skill auto-attaches (by its `description`) whenever a Fireworks training task comes up.

**A) Claude Code plugin — stays current automatically (recommended)**

```text
/plugin marketplace add terryfireworks/fireworks-training-skill
/plugin install fireworks@fireworks-skills
```

Then turn on auto-update once: `/plugin` → **Marketplaces** → enable **Auto-update** for `fireworks-skills`. After that, new commits are pulled at startup — no manual updates. (Auto-update is opt-in for self-hosted marketplaces; an org can force it via `managed-settings.json`.)

**B) Cross-agent (Cursor, Codex, …) — one-line, manual updates**

```bash
npx skills add terryfireworks/fireworks-training-skill
```

Update with `npx skills update -y` (no auto-update in the `skills` CLI). Ships `SKILL.md` + `references/`.

<details>
<summary>C) Dogfooding / contributing — live edits, no reinstall</summary>

```bash
git clone https://github.com/terryfireworks/fireworks-training-skill.git ~/Desktop/fireworks-training-skill
ln -s ~/Desktop/fireworks-training-skill/skills/fireworks-training ~/.claude/skills/fireworks-training
```

Edits to `SKILL.md` take effect immediately. The maintainer report tool lives at `scripts/fw_telemetry_report.sh` in the repo.
</details>

## How it works (progressive disclosure)

- **`SKILL.md`** — always-loaded router: auto-attaches via its `description`, routes each task to the right reference, and carries the critical "always/never" rules. Small context footprint.
- **`references/`** — loaded only when the router points there: `getting-started`, `choose-method`, `training-api`, `models-shapes-and-cost`, `deploy-and-troubleshoot`.
- For anything not covered, the skill points the agent at the full machine-readable doc index (`docs.fireworks.ai/llms.txt`).

So the agent reads the description at startup, loads `SKILL.md` when a training task matches, then triages into exactly the doc it needs.

## Staying current

References are **link-first** (they link the live `.md` docs, so the agent reads current content). `scripts/sync_check.py` diffs `docs.fireworks.ai/llms.txt` against a committed baseline and flags new/removed fine-tuning pages, so the skill doesn't silently drift.

## Usage telemetry (local-only)

**Why.** This skill runs on machines we don't control and we never see the transcripts — so without a signal we're blind to what trips people up building on Fireworks training. This adds that signal, while keeping all data **on the user's machine**.

**How — two hooks the agent runs around each task.** Both are plain bash embedded directly in `SKILL.md` (the skills CLI installs only `SKILL.md`, so nothing external is required). Both are best-effort: on a non-bash host they're skipped silently and never affect the task.

- **Prolog** (runs first) — stamps the start: writes a start-time file and an "in-flight" marker, both keyed by `$PPID` (the agent process, which is stable across the separate tool calls a run makes). The marker is what lets us detect a run that later dies.
- **Epilog** (runs last) — closes the run: works out the duration, appends **one** event line (which reference was used, success/error, error class, how long), clears this run's marker, and finalizes any *other* leftover marker as a crashed run (`outcome: unknown`).

**Where the data lives right now.** Everything is local — **nothing is transmitted anywhere.**

```
~/.fireworks-skill/analytics/
├── events.jsonl        ← the log (one JSON object per run)
├── .start-<pid>        ← transient: run start time (removed by the epilog)
└── .pending-<pid>      ← transient: in-flight marker for crash detection
```

Each event captures **no prompts, code, file paths, or keys** — only enum-ish fields (there are no free-text fields to leak). Three signals come out of it:

- **Usage** — `reference_used`: which docs people actually need.
- **Blockers** — `outcome` + `error_class` (quota, auth, dataset_format, deploy, numerics): where people get stuck.
- **Friction** — `question_id` + `followed_recommendation`: where the skill had to stop and ask, and whether its recommendation was right.

**Controls.** On by default (local-only). Opt out anytime: `touch ~/.fireworks-skill/telemetry-off` or `export FW_TELEMETRY=off`. View the log with `scripts/fw_telemetry_report.sh` (from the repo).

**Sending feedback (dogfooders).** Since the log is local-only, there's no auto-collection yet. To share your usage data, run this one-liner and send the file it saves to your Desktop:

```bash
cp ~/.fireworks-skill/analytics/events.jsonl ~/Desktop/fw-feedback-$(whoami)-$(date +%Y%m%d).jsonl 2>/dev/null \
  && echo "Saved to your Desktop — send me that file" || echo "No feedback yet — use the skill first"
```

It contains only anonymous enum-ish fields (no prompts/code/keys) — same data described above.

**Reviewing collected feedback (maintainer).** Drop everyone's files in one folder and report across all of them:

```bash
scripts/fw_telemetry_report.sh ~/Desktop/dogfood-feedback/   # a folder of collected *.jsonl files
```

**Outcomes & what's next.** A concrete readout of where people succeed vs. stall — which feeds (1) a better skill (fix the references/routing people fail on) and (2) a real-world map of the training product's rough edges. During dogfooding it stays local; `events.jsonl` is the stable interface, so a collector can be added later without touching the skill. Before any data leaves a machine, the default flips from opt-out to opt-in. Full design + privacy: [`TELEMETRY.md`](TELEMETRY.md).

## Status

v1, built from public docs — dogfooding. Feedback welcome.
