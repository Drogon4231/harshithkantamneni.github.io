# Curator — Operating Manual

Operator interface for the daily curator pipeline. Pair this with `STATUS.md` (implementation status) and the spec at `docs/superpowers/specs/2026-05-07-curator-pipeline-design.md`.

---

## Daily glance

```
bash tools/curator/cli.sh status
```

One-pager. Shows: launchd job state, queue counts, channel drafts pending, today's run summary.

Other verbs:

| Command | Purpose |
|---|---|
| `cli.sh status` | The dashboard |
| `cli.sh queue` | Table of all non-published candidates |
| `cli.sh held` | Held candidates + reasons + retry hint |
| `cli.sh retry <id>` | Reset held → pending |
| `cli.sh tail` | Tail today's log |
| `cli.sh runs [N]` | Summary of last N runs (default 10) |
| `cli.sh audit` | Scan all pages for future dates, [VERIFY] markers, TODO/FIXME (add `--check-style` for forbidden-phrase scan) |
| `cli.sh ui` | Launch the browser dashboard at http://127.0.0.1:8088/ — review modal with preview/source/diff/real-preview tabs, editable channel drafts, comment-as-prompt + Claude revise, revision history, live log streaming, keyboard shortcuts |
| `cli.sh help` | Print help |

Convenient alias (one-time):
```
echo "alias cur='bash ~/Desktop/website/tools/curator/cli.sh'" >> ~/.zshrc
```
Then: `cur status`, `cur retry foo`, etc.

---

## When something's wrong

| Symptom | Action |
|---|---|
| `status` shows `held N`  | `cli.sh held` to see reasons. Fix root cause (edit voice anchor, fix MLX, etc.), then `cli.sh retry <id>`. |
| `status` shows `processing N` (>0) but no run is happening | A previous run crashed mid-pipeline. Manually edit the manifest's `curator_state` back to `pending` and re-run. |
| `status` shows launchd jobs `NOT LOADED` | `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.harshith.website-curator.plist` |
| Want to kill a draft before it publishes | Open the review modal in `cli.sh ui` → `reject` button. The pipeline pauses at `awaiting_review`; nothing publishes until you click `approve & publish`. |
| `runs` shows `FAIL` for recent run | `cli.sh tail` to see the last entries, or grep the day's log file. |
| Curator runs but nothing publishes | The labs aren't writing manifests to `publish_candidates/`. See the lab-side append protocol spec. |

---

## Where to edit what

| Goal | File |
|---|---|
| Voice anchor for HIVE lab content | `tools/curator/voice/hive.md` |
| Voice anchor for AGI lab content | `tools/curator/voice/agi.md` |
| Voice anchor for LinkedIn teasers | `tools/curator/voice/linkedin.md` |
| Add/remove a forbidden cargo-cult phrase | `tools/curator/forbidden_phrases.txt` |
| Drafting prompt (the main one) | `tools/curator/prompts/draft.txt` |
| Risk classifier prompt | `tools/curator/prompts/classify_risk.txt` |
| Voice judge prompt | `tools/curator/prompts/judge_voice.txt` |
| Factcheck logic (deterministic, not a prompt) | `tools/curator/lib/judge.sh` (look for `judge_factcheck`) |
| Novelty judge prompt | `tools/curator/prompts/judge_novelty.txt` |
| LinkedIn teaser prompt | `tools/curator/prompts/channel_linkedin.txt` |
| Validators (em-dash, forbidden, base path, [VERIFY], build) | `tools/curator/lib/validate.sh` |
| Voice score threshold (currently 6.5) | `tools/curator/lib/judge.sh` (`VOICE_THRESHOLD` env var or default at line 27) |
| Per-tier publish behavior | `tools/curator/lib/publish.sh` |
| Manifest schema (adding a new field) | `tools/curator/schema/publish_candidate.schema.json` |
| Daily run time | `~/Library/LaunchAgents/com.harshith.website-curator.plist` (then reload, see below) |
| HN username, site base URL | env vars `HN_USERNAME`, `SITE_BASE_URL` (or defaults inline) |

After editing a prompt, voice anchor, or forbidden list: no restart needed. The next curator run picks it up.

After editing a plist:
```
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.harshith.website-curator.plist
cp tools/curator/launchd/com.harshith.website-curator.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.harshith.website-curator.plist
```

---

## Anatomy of a manifest

A candidate is a JSON file at `~/Desktop/Fun/lab/publish_candidates/<id>.json` (HIVE) or `~/Desktop/AGI/data/publish_candidates/<id>.json` (AGI).

```json
{
  "id": "byte-identical-builds",
  "type": "report",
  "title": "...",
  "summary": "...",
  "source_path": "~/Desktop/Fun/lab/.../report.md",
  "channels": ["website", "hackernews", "linkedin"],
  "curator_state": "pending",
  "risk_tier": 1,
  "held_reason": "...",
  "scores": { "voice": 7.8, "factcheck": "pass", "novelty": 6.5 },
  "published_at": "2026-05-12T..."
}
```

**State machine:**
```
pending → processing → awaiting_review → (published | held)
held → pending (via cli.sh retry or dashboard retry button)
```

The pipeline now PAUSES at `awaiting_review` instead of auto-publishing. The
operator approves (→ publish) or rejects (→ held) via the dashboard. The
staged draft sits at `tools/curator/pending_drafts/<id>.astro` and is
editable inline through the dashboard's review modal before approval.

---

## Dashboard review modal — what's where

Launch: `bash tools/curator/cli.sh ui` → opens http://127.0.0.1:8088/

Click any card in the "Awaiting your review" section → modal opens.

**Tabs above the preview pane:**
- **visual preview** — server-rendered approximation (Astro components stripped, basic typography). Fast, always available.
- **real preview** — actual Astro page in an iframe. Requires `npm run dev` running in another terminal (`cd ~/Desktop/website && npm run dev`). If dev server isn't up, the tab shows a banner with the startup command.
- **astro source** — full editable .astro source. Edit, then "save source edits" button to persist.
- **diff vs prev** — unified diff between the pre-revise and post-revise versions (appears only after first revise).

**Right column:**
- Judge scores (voice / factcheck / novelty) with thresholds color-coded
- Linked channel drafts — first one auto-expands. HN and LinkedIn paste-ready text rendered as editable textareas with "save channel" buttons. Approve picks up your edits.
- Revision history — every Claude revision logged with timestamp + your prompt + a "restore this version" button (deep undo across all rounds).
- Comments / revision instructions textarea — what you type here is sent to Claude as the revision prompt when you click "apply".

**Bottom actions:**
- `↶ undo last revise` — one-step swap to .prev (appears only when .prev exists)
- `reject…` — two-click: first click reveals a reason textarea; second click submits (state → held)
- `approve & publish` — runs the tier-aware publish flow with live log streaming

**Keyboard shortcuts (modal-scoped):**
- `Esc` → close (warns on unsaved edits / aborts active stream)
- `⌘+S` (or `Ctrl+S`) → save (source if source tab is active, else notes)
- `⌘+Enter` (or `Ctrl+Enter`) → apply notes (Claude revises)

**Live log panel** (info-bordered, opens during approve/revise):
- Streams stdout + stderr from approve.sh / revise.sh via SSE line-by-line
- Color codes: ERROR/FAILED red, WARN amber, PASS/published/complete green
- Stays open after the action so you can review what happened

**Operator-safe edits:**
- `channels` — which channels to fire (re-runs won't re-fire already-done channels by default; see Stage 8 in `run.sh`)
- `curator_state` — force-reset (e.g., `published → pending` to re-run)
- `held_reason` — clear when retrying

**Don't manually edit:**
- `scores` — comes from judges
- `published_at` — set on publish
- `vetoed_at` — set on legacy veto (no longer produced; kept for old manifests)

---

## Trigger a run manually

```
bash tools/curator/run.sh
```

Useful flags:
- `--skip-ram-check` — bypass the 12 GB free RAM precondition
- `DRY_RUN=1` (env var) — log what would happen, don't push or run channel adapters
- `CURATOR_DEBUG=1` (env var) — extra logging

---

## Channel drafts

Curator does not auto-post to HN or LinkedIn. It writes paste-ready files:

- `tools/curator/channel_drafts/hackernews/<id>.txt` — title, URL, timing notes
- `tools/curator/channel_drafts/linkedin/<id>.txt` — 200-300 word teaser body, metadata header

Operator pastes manually when timing is right (see notes inside each file). HN's submission UI is at `https://news.ycombinator.com/submit`. LinkedIn's compose box is wherever LinkedIn currently puts it.

After pasting, the operator can delete the draft file to clear the "pending operator paste" count in `cli.sh status`.

---

## Files Claude (this assistant) is allowed to touch

Everything under `tools/curator/`. If you want Claude to also edit the labs (HIVE knowledge-manager, AGI program-close hook) to start writing manifests, ask explicitly — those live in separate working directories.
