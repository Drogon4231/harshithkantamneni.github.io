# Curator Pipeline — Implementation Status

**Plan:** `docs/superpowers/plans/2026-05-07-curator-pipeline-implementation.md`
**Spec:** `docs/superpowers/specs/2026-05-07-curator-pipeline-design.md`
**Lab-side append protocol:** `docs/superpowers/specs/2026-05-08-lab-side-append-protocol.md`

---

## All 12 tasks complete + multi-channel extension

| # | Task | Commit | Quality verification |
|---|---|---|---|
| 1 | MLX setup + 3 models verified | `296a87a`, `cf749b3` | Substantive tests on each model: 3B classifies correctly, 7B catches number mismatch, 14B Coder scores AI-slop 2/10 vs real prose 7/10. Voice threshold calibrated 7.5 → 6.5. |
| 2 | Manifest contract + 6 backfills | `b1b6064` | 6/6 schema-valid; 10/10 source paths resolve; 6/6 published_urls return 200. |
| 3 | Voice anchors + forbidden list | `a5eb4dd` | 12/12 AI-slop catches in synthetic test; 2 expected matches on existing site (intentional META-altitude in user's voice). |
| 4 | Orchestrator scaffold | `7b52dac` | Bug caught: hardcoded 4KB page size on M-series (16KB). Fixed by reading vm_stat header. RAM measure 5GB matched Python cross-check 5.38GB. |
| 5 | Risk classifier (MLX 3B) | `d12d8e7` | 6/6 exact agreement on backfill set. Two infra bugs caught: stale CURATOR_DIR env (fixed: always resolve from BASH_SOURCE), tee polluting stdout (fixed: log to stderr+file only). |
| 6 | Drafting via Claude --print | `c9bfa6f` | First pass consolidated 11→5 sections (substance loss). Prompt iterated to enforce structure. Result: 5/5 prescriptions enumerated, 7/7 critical numbers preserved, build passes. |
| 7 | PoLL judges | `228655c` | Spec deviation: replaced LLM factcheck with deterministic numeric (7B over-flagged 19/19 valid claims). Voice/novelty work correctly. AI-slop test: voice 2/10. Hallucinated draft: factcheck catches `187`. |
| 8 | Validators | `86fbfa6` | All 5 catch synthetic violations; clean draft passes all. Bug caught: `grep -c \|\| echo 0` produced "0\n0". Fixed with `wc -l`. |
| 9 | Branch + PR/auto-merge per tier | `50bbe50` | All 3 tier paths produce correct git ops (DRY_RUN). Veto check handles empty/missing-branch cases. Bash 3.2 compatibility (replaced mapfile). |
| 10 | Provenance frontmatter | `c65e5af` | Block injects, build passes, idempotent (re-injecting replaces; cost field updates). Bug caught: bash heredoc f-string scope mismatch. Fixed with env vars. |
| 11 | run.sh wired + launchd + E2E | `e362a52` | Full E2E pipeline ran on synthetic candidate in 183s. All 7 stages logged correctly. plutil-lint passes both plists. |
| 12 | /now status surface | `4cbbf87` | Renders gracefully without files; renders both lab blocks with files. Schema validates. Per-lab independence (only present-file lab renders). |
| X1 | HN + LinkedIn channel adapters | `873fdb1` | HN: deterministic suggester (no LLM). Title-trim logic verified on 95-char title (cuts at colon, lands 38 chars). LinkedIn: 261-word teaser on cross-lab-diagnosis, 0 em-dashes, on-voice (hook is specific %). forbidden_check false-positive fixed (blank-line regex bug). |

Medium dropped: API key issuance stopped. HN + LinkedIn are higher-leverage for this audience anyway.

---

## Real bugs caught and fixed during quality verification

Quality gates after each task surfaced 8 real bugs that smoke tests would have missed:

1. **Hardcoded 4KB page size** (T4) — M-series Macs use 16KB pages. Fixed by reading vm_stat header.
2. **Stale CURATOR_DIR env** (T5) — `:= ` default-assignment inherited stale values. Fixed: unconditional resolve from BASH_SOURCE.
3. **`tee` polluting stdout** (T5) — log lines bled into function returns captured via $(...). Fixed: write to stderr + file only.
4. **Drafting consolidation** (T6) — first pass merged 11 sections into 5 (lost "PI notes" and "runner flag" prescriptions). Prompt iterated.
5. **Date format drift** (T6) — ISO instead of human-readable. Prompt updated.
6. **LLM factcheck over-flag** (T7) — 7B model marked 19/19 valid claims as unverified. Replaced with deterministic numeric check.
7. **`grep -c \|\| echo 0`** producing "0\n0" (T8) — broke integer comparison. Fixed with `wc -l`.
8. **Bash heredoc f-string scope** (T10) — bash vars not visible in Python f-string. Fixed by passing via env vars.

---

## Pipeline shape (what runs daily at 04:00)

```
operator manually runs `bash tools/curator/run.sh`
   ↓
run.sh
   ↓ Stage 0: ram_check (defer if <12GB free)
   ↓ Stage 1: scan ~/Desktop/Fun/lab/publish_candidates/ + ~/Desktop/AGI/data/publish_candidates/
   ↓
   for each pending candidate:
     ↓ Stage 2: classify_candidate (MLX Qwen 3B, ~5s)
     ↓ Stage 3: draft_candidate (claude --print --model opus, ~30-60s)
     ↓ Stage 4: judge_draft (sequential MLX, ~60s)
         - voice (Qwen Coder 14B)
         - factcheck (deterministic numeric)
         - novelty (Qwen 7B)
     ↓ Stage 5: inject_provenance
     ↓ Stage 6: validate_draft (em-dash, forbidden, [VERIFY], base path, npm build)
     ↓ Stage 7: publish_draft
         - Tier 1 → PR opens, human merges
         - Tier 2 → PR + gh pr merge --auto --squash
         - Tier 3 → PR + auto-merge (same as Tier 2; the dashboard review gate is the human checkpoint)
     ↓ Stage 8: channel adapters (per candidate's channels[] field)
         - hackernews → deterministic suggester, writes paste-ready file
         - linkedin   → single narrow claude --print, writes paste-ready draft
         - failures non-blocking (website already published)
   ↓ each stage updates manifest entry's curator_state
```

The pipeline runs manually (operator-triggered). The earlier daily-cron + 24h-veto-window design was retired 2026-05-13 in favor of the dashboard review gate.

Channel adapters never auto-post. HN is hostile to automation; LinkedIn's
API blocks third-party posting. Both write paste-ready drafts to
`channel_drafts/{hackernews,linkedin}/<id>.txt` for the operator to send
when timing is right.

---

## What's NOT done (out of scope for this implementation)

- **Lab-side `publish_candidates/` writers** — the actual code in HIVE's knowledge-manager and AGI's program-close hook that appends manifest entries. Spec at `docs/superpowers/specs/2026-05-08-lab-side-append-protocol.md`. Implementing requires editing each lab's agent files; should be done lab-side, not curator-side.
- **`lab_status.json` writers** — same story. Spec defined; lab-side implementation pending.

The curator pipeline is functionally complete and ready to receive manifest entries when the labs start writing them. Until then, the curator runs daily, finds nothing, exits clean (verified).

---

## Operating cost

Per Task 1 + Task 7 measurements:
- Drafting (claude --print): $0 (Max subscription)
- Risk classifier (MLX 3B): $0 (local, ~5s)
- Voice judge (MLX 14B Coder): $0 (local, ~30s)
- Factcheck (deterministic): $0 (no model)
- Novelty (MLX 7B): $0 (local, ~15s)
- Validation: $0 (deterministic)
- OG image: $0 (local Pillow)
- GitHub Actions: not used; runs locally
- **Total marginal cost: $0**

Per-piece wall clock: ~2-3 minutes. Daily run with 0 candidates: <5 seconds.
