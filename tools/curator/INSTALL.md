# Curator Installation

One-time setup for the curator pipeline on the operator's Mac.

## Prerequisites (one-time)

```bash
# Python 3 + jsonschema + pypdf (for occasional analysis)
pip3 install --break-system-packages mlx-lm jsonschema

# MLX models (~16GB total disk; first run downloads automatically)
mlx_lm.generate --model mlx-community/Qwen2.5-3B-Instruct-4bit --prompt "ok" --max-tokens 1
mlx_lm.generate --model mlx-community/Qwen2.5-7B-Instruct-4bit --prompt "ok" --max-tokens 1
mlx_lm.generate --model mlx-community/Qwen2.5-Coder-14B-Instruct-4bit --prompt "ok" --max-tokens 1

# Claude Code CLI (already installed if you run the labs)
claude --version

# GitHub CLI (gh) — for PR creation
gh auth status  # confirm authenticated
```

## Running the pipeline

The curator runs manually. There is no daily cron; the operator triggers a pass when a lab has new candidates worth processing.

```bash
cd ~/Desktop/website
bash tools/curator/run.sh                   # full pass (classify → draft → judge → validate → stage for review)
bash tools/curator/run.sh --skip-ram-check  # skip the 12GB-free RAM precondition
DRY_RUN=1 bash tools/curator/run.sh         # log commands without pushing
CURATOR_DEBUG=1 bash tools/curator/run.sh   # extra log detail
```

After staging completes, drafts wait in `pending_drafts/` for operator review via the dashboard:

```bash
bash tools/curator/cli.sh ui                # opens http://127.0.0.1:8088/
```

> **Why manual, not cron:** an earlier version of the curator ran via a daily launchd job at 04:00. macOS Sequoia's TCC (Privacy & Security) blocks launchd-spawned bash from reading `~/Desktop` regardless of granted Full Disk Access. Since the review-gate refactor makes the operator the trigger anyway (every draft waits at `awaiting_review` for approval in the dashboard), automatic firing wasn't doing real work. The launchd job was retired 2026-05-13.

## Where logs land

- `tools/curator/log/YYYY-MM-DD.log` — per-day curator runs (one file per calendar day)

Logs are gitignored.

## What happens when there's nothing to publish

The labs append manifest entries to `~/Desktop/Fun/lab/publish_candidates/` (HIVE) or `~/Desktop/AGI/data/publish_candidates/` (AGI) when artifacts ratify. Most days, no new entries appear. `run.sh` scans both dirs, finds no `pending` entries, logs `no new candidates → exit clean`, and exits in seconds. This is the expected default outcome.

## When it goes wrong

- **RAM tight (labs busy)**: curator logs `RAM tight; deferring this run` and exits 0. Re-run later.
- **Drafting fails (Claude CLI auth issue)**: logs error, marks candidate `held`, moves to next.
- **Judges hold the draft**: marks candidate `held` with reason; inspect `tools/curator/log/<date>.log` to see why and either fix the lab-side artifact or run `cli.sh retry <id>` to re-queue.
- **Validators hold**: same pattern.
- **Publish fails (network, gh auth)**: logs error, marks held.

In all cases, the manifest entry is the audit trail. Re-trigger by `cli.sh retry <id>` (or manually editing `curator_state` back to `pending`) and re-running `bash tools/curator/run.sh`.
