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

## Install the launchd jobs

```bash
# Daily curator at 04:00
cp ~/Desktop/website/tools/curator/launchd/com.harshith.website-curator.plist \
   ~/Library/LaunchAgents/

# Validate plist syntax
plutil -lint ~/Library/LaunchAgents/com.harshith.website-curator.plist

# Load (modern launchctl)
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.harshith.website-curator.plist

# Verify loaded
launchctl list | grep harshith
```

> Note: the 24h Tier-3 veto window was retired 2026-05-13. The dashboard
> review gate (`cli.sh ui`) is now the human checkpoint — Tier 3
> publishes identically to Tier 2 (PR + auto-merge) once you click
> 'approve & publish' in the review modal. No separate veto-check
> launchd job is needed.

## Manual run (testing)

```bash
cd ~/Desktop/website
bash tools/curator/run.sh                   # full daily run
bash tools/curator/run.sh --skip-ram-check  # skip RAM gate (testing)
DRY_RUN=1 bash tools/curator/run.sh         # log commands without pushing
CURATOR_DEBUG=1 bash tools/curator/run.sh   # extra log detail
```

## Where logs land

- `tools/curator/log/YYYY-MM-DD.log` — per-day curator runs
- `tools/curator/log/launchd.{stdout,stderr}.log` — launchd-captured stdout/err

Logs are gitignored (`*.log` in `tools/curator/log/.gitignore`).

## Uninstall

```bash
launchctl bootout gui/$(id -u)/com.harshith.website-curator
rm ~/Library/LaunchAgents/com.harshith.website-curator.plist
```

## How it triggers

The Mac must be on at 04:00 local time for the daily run to fire. If the Mac is asleep at the trigger time, launchd queues the job and runs it on next wake (per macOS launchd behavior).

## What happens when there's nothing to publish

The labs append manifest entries to `~/Desktop/Fun/lab/publish_candidates/` (HIVE) or `~/Desktop/AGI/data/publish_candidates/` (AGI) when artifacts ratify. Most days, no new entries appear. Curator scans both dirs, finds no `pending` entries, logs `no new candidates → exit clean`, and exits in seconds. This is the expected default outcome.

## When it goes wrong

- **RAM tight (labs busy)**: curator logs `RAM tight; deferring this run` and exits 0. Next day's cron picks up.
- **Drafting fails (Claude CLI auth issue)**: logs error, marks candidate `held`, moves to next.
- **Judges hold the draft**: marks candidate `held` with reason; the operator inspects `tools/curator/log/<date>.log` to see why and either fixes the lab-side artifact or manually overrides `curator_state` back to `pending`.
- **Validators hold**: same pattern.
- **Publish fails (network, gh auth)**: logs error, marks held.

In all cases, the manifest entry is the audit trail. The operator can re-trigger by setting `curator_state` back to `pending` and running `bash tools/curator/run.sh` manually.
