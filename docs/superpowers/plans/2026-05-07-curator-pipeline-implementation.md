# Curator Pipeline — Implementation Plan

**Spec:** `docs/superpowers/specs/2026-05-07-curator-pipeline-design.md`
**Approach:** task-by-task with explicit verification after each. Quality is the metric, not speed.

---

## Sequencing principle

Each task produces something independently testable. After each task: verify it works in isolation before moving to the next. If a task fails its verification, stop and fix; do not stack on top of broken foundations.

---

## Task 1 — MLX setup + model verification

**Files:** `tools/curator/setup.md` (notes), no scripts yet

**Steps:**
1. `pip3 install --break-system-packages mlx-lm`
2. Verify each MLX-served model loads and runs:
   - `mlx-community/Qwen2.5-3B-Instruct-4bit`
   - `mlx-community/Qwen2.5-Coder-14B-Instruct-4bit`
   - `mlx-community/Qwen2.5-7B-Instruct-4bit`
3. Measure peak RAM during a sample inference of each
4. Document the exact CLI invocation pattern

**Verification:**
- All three models respond to a sample prompt
- Peak RAM measured matches expectation (3B≈2GB, 14B≈6GB, 7B≈4GB)
- First run downloads weights; second run loads from cache in <5s

**Done when:** `tools/curator/setup.md` documents the working CLI patterns and measured RAM.

---

## Task 2 — Manifest contract + backfill

**Files:**
- `tools/curator/schema/publish_candidate.schema.json`
- Backfill 6 candidates: one per existing published piece

**Steps:**
1. Write JSON Schema for `publish_candidate.schema.json`
2. For each currently-published piece, write a backfill manifest entry to a new `tools/curator/backfill/` directory with `curator_state: published` (so curator skips them but the format is exercised)
3. Validate all 6 backfilled entries against the schema using `python3 -c "import jsonschema; ..."`

**Verification:**
- Schema validates all 6 backfilled entries
- Each backfill entry includes the right `lab`, `type`, `source_artifacts`, `ratified_at`

**Done when:** schema + 6 backfilled JSON files exist and pass validation.

---

## Task 3 — Voice anchors + forbidden terms

**Files:**
- `tools/curator/voice/hive.md`
- `tools/curator/voice/agi.md`
- `tools/curator/forbidden_phrases.txt`

**Steps:**
1. Write `voice/hive.md`: two anchor pieces (byte-identical-builds, llm-judge-bias), annotations on what's load-bearing
2. Write `voice/agi.md`: cross-lab-diagnosis as the anchor, plus a sketch of expected AGI lab voice
3. Write `forbidden_phrases.txt`: cargo-cult phrases + lab-internal jargon

**Verification:**
- Anchor pieces are full prose (not summaries)
- Annotations are 1-2 sentences each, concrete
- Forbidden list includes: specializing in, leverage as verb, passionate, cutting-edge, state-of-the-art, seamlessly, META-altitude, POST-CXX patterns

**Done when:** all three files exist with substantive content.

---

## Task 4 — Curator scaffold

**Files:**
- `tools/curator/run.sh` (orchestrator entry point)
- `tools/curator/lib/log.sh` (logging functions)
- `tools/curator/lib/ram_check.sh` (RAM precondition)
- `tools/curator/log/.gitkeep` (log directory)

**Steps:**
1. Write `run.sh` with placeholder calls for each pipeline stage (each stage echoes its name and exits 0)
2. Write logging helpers: `log_info`, `log_warn`, `log_error`, all writing to `log/$(date +%F).log`
3. Write RAM precondition: returns nonzero if <12GB free
4. Add `tools/curator/log/.gitignore` to ignore `*.log`

**Verification:**
- `bash run.sh` exits 0 with stages echoing
- Log file `log/$(date +%F).log` is created with the run timestamp
- RAM check returns correct values (test with `vm_stat`)

**Done when:** scaffold runs end-to-end and logs.

---

## Task 5 — Risk classifier

**Files:**
- `tools/curator/prompts/classify_risk.txt`
- `tools/curator/lib/classify.sh`

**Steps:**
1. Write `classify_risk.txt`: prompt that takes a candidate JSON + source content, returns `Tier 1`, `Tier 2`, or `Tier 3` per the spec rules
2. Write `classify.sh`: invokes MLX Qwen 3B with the prompt, parses output to a tier number
3. Test on all 6 backfilled candidates: classifier should agree with our retroactive tier assignment (operator labels them; classifier predicts; compare)

**Verification:**
- Classifier returns one of three tier values
- Agreement rate ≥83% (5 of 6) with operator labels
- Defaults to Tier 1 on ambiguous output

**Done when:** classifier passes on backfill set.

---

## Task 6 — Drafting via Claude CLI

**Files:**
- `tools/curator/prompts/draft.txt`
- `tools/curator/lib/draft.sh`

**Steps:**
1. Write `draft.txt`: drafting instructions, voice anchor injection, source artifact reference, output format (Astro page with proper component imports)
2. Write `draft.sh`: builds the prompt (voice + forbidden + source), pipes to `claude --print --model opus --effort max`, captures stdout to a draft file
3. Test on the cross-lab-diagnosis source: regenerate and compare to live published version. Score similarity.

**Verification:**
- Draft output is valid Astro syntax
- Draft contains expected components (Hero, MetaStrip, SectionHead, etc.)
- Character similarity vs live version ≥85% (allowing for minor wording variation)
- No em-dashes in draft

**Done when:** drafting produces an Astro page that builds and matches the live version closely.

---

## Task 7 — PoLL judges

**Files:**
- `tools/curator/prompts/judge_voice.txt`
- `tools/curator/prompts/judge_factcheck.txt`
- `tools/curator/prompts/judge_novelty.txt`
- `tools/curator/lib/judge.sh`

**Steps:**
1. Voice judge prompt: takes draft + voice anchor, returns 0-10 score with rationale
2. Factcheck judge prompt: takes draft + source, returns pass/fail per claim with list of any claims not found in source
3. Novelty judge prompt: takes draft + already-published pieces summary, returns 0-10 (10 = entirely new) with rationale
4. `judge.sh`: orchestrates the three judges sequentially, parses scores, decides hold/proceed
5. Test on one regenerated draft: should pass all judges (since it came from a real published piece)
6. Test on a synthetic AI-slop draft: at least voice judge should fail
7. Test on a draft with hallucinated number (manually inject "1,800 tests" where source says "1,688"): factcheck judge should fail

**Verification:**
- All three judges return parseable scores
- Real piece passes all judges
- AI-slop fails voice judge
- Hallucinated draft fails factcheck judge

**Done when:** judges correctly classify all three test cases.

---

## Task 8 — Validators

**Files:**
- `tools/curator/lib/validate.sh`

**Steps:**
1. Write validator that runs all checks in order:
   - em-dash count
   - forbidden phrase grep
   - base path href check
   - `[VERIFY]` marker check
   - `npm run build` from website root
2. Each check writes a clear pass/fail line to log
3. Test: violate each check in turn (synthetic draft with em-dash, then with forbidden phrase, then with missing base path); validator catches each

**Verification:**
- Each individual check correctly fails on a synthetic violation
- All checks pass on a clean draft
- Build check runs and produces success/failure correctly

**Done when:** validator catches all 5 synthetic violations and passes a clean draft.

---

## Task 9 — Branch + commit + PR/merge logic

**Files:**
- `tools/curator/lib/publish.sh`
- `tools/curator/templates/pr_body.md`

**Steps:**
1. Write `publish.sh`: takes a draft + tier + scores, creates `draft/<id>` branch, commits the new files (page + writing list updates + RSS update + provenance), pushes, creates PR
2. Tier 1: `gh pr create` (no auto-merge)
3. Tier 2: `gh pr create --label auto-merge`; the auto-merge condition is "all judges passed + validators clean"
4. Tier 3: commits to `draft/<id>` branch, does NOT open PR; separate cron at `tools/curator/veto_check.sh` reviews 24h-old draft branches and merges if no veto
5. Test in dry-run mode (no actual push): verify branch + commit + PR command would be correct

**Verification:**
- Tier 1 dry-run: PR command, no auto-merge
- Tier 2 dry-run: PR command with auto-merge label
- Tier 3 dry-run: branch creation, no PR
- veto_check dry-run: identifies a 24h-old branch and would merge it

**Done when:** all four tier paths produce correct git operations.

---

## Task 10 — Provenance frontmatter

**Files:**
- `tools/curator/lib/provenance.sh`

**Steps:**
1. Write helper that injects the provenance comment block into a draft
2. Includes lab, cycle_id, source_artifacts, drafted_by, judged_by (with scores), risk_tier, curator_run timestamp, cost_local_seconds
3. Test: run on a draft, verify the comment block appears at top, verify subsequent `npm run build` still passes (Astro accepts JSX comments)

**Verification:**
- Provenance block injects cleanly
- Build still succeeds

**Done when:** provenance injection works and build remains green.

---

## Task 11 — launchd unit + RAM precondition + end-to-end

**Files:**
- `~/Library/LaunchAgents/com.harshith.website-curator.plist`
- `~/Library/LaunchAgents/com.harshith.website-veto-check.plist`
- `tools/curator/INSTALL.md`

**Steps:**
1. Write the launchd plist for daily 04:00 trigger
2. Write the second plist for hourly veto-check (so a 24h-old draft picks up within ~1 hour of crossing the threshold)
3. Write INSTALL.md with `launchctl load ...` instructions
4. End-to-end test: drop a synthetic candidate into one lab's `publish_candidates/` dir, run `tools/curator/run.sh` manually, verify the full pipeline executes and produces correct output for the candidate's tier

**Verification:**
- E2E run on synthetic candidate produces expected branch + commit + PR/draft state
- launchd plist parses correctly with `plutil -lint`
- INSTALL.md is followable without questions

**Done when:** full pipeline works end-to-end on a synthetic candidate, launchd is loadable.

---

## Task 12 — /now status surface (separate flow)

**Files:**
- Lab side: spec for `lab_status.json` writer (HIVE + AGI add this to their cycle close)
- Site side: `src/pages/now.astro` updated to fetch both `lab_status.json` files at build time

**Steps:**
1. Write the lab-side `lab_status.json` schema spec (lab, cycle, current_focus, last_build_status, last_artifact, updated_at)
2. Update `now.astro` to fetch from `~/Desktop/Fun/lab/state/lab_status.json` and `~/Desktop/AGI/data/lab_status.json` at build time (Astro `fs.readFileSync` in frontmatter)
3. Render a small "current state" block above the existing timeline
4. Lab-side: add the writer to each lab's closeout (out of scope for this implementation; spec only)

**Verification:**
- /now page renders both lab statuses if the JSON files exist
- /now page falls back gracefully if either file is missing

**Done when:** /now page reads from JSON files and renders correctly with mock data.

---

## Self-review checklist

After all tasks complete, verify:

- [ ] All 8 acceptance criteria from the design spec are met (run end-to-end tests for each)
- [ ] No forbidden phrases anywhere in the code or prompts
- [ ] Forbidden terms list captures the actual terms found in lab dirs
- [ ] Voice anchors actually contain published prose, not summaries
- [ ] PoLL panel is genuinely diverse (different model variants, different prompts)
- [ ] Risk classifier defaults to Tier 1 on ambiguity
- [ ] RAM precondition value (12GB) is calibrated against actual measured peaks
- [ ] launchd unit is loadable and survives reboot
- [ ] Veto-check cron runs at sensible interval (1h, not 24h, so the threshold is hit promptly)

---

## Stopping conditions

If any of the following occurs during implementation, stop and escalate to the operator:

- An MLX model fails to load or download (model availability change)
- A judge consistently scores correctly-good drafts as bad (calibration off; would block legitimate publication)
- The Claude CLI invocation pattern changes (`claude --print --model opus` deprecation)
- Build infrastructure changes (Astro upgrade, GitHub Pages auth change)
- RAM measurements during testing show >18GB peaks (planning broken)
