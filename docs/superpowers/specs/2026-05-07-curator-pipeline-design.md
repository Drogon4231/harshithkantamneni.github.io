# Lab-to-Portfolio Curator Pipeline — Design Spec

**Date:** 2026-05-07
**Status:** Approved (architecture, model selection, gating, RAM strategy)
**Target:** `~/Desktop/website/` (Astro 5.4.2, GitHub Pages)
**Sources:** `~/Desktop/Fun/lab/` (HIVE), `~/Desktop/AGI/` (Autonomous Research Lab)

---

## Goal

Build a daily-cron curator that turns ratified lab artifacts into published reports/notes on the portfolio site, with quality gates strong enough to defend against the documented failure modes (Hit Piece runaway, same-family judge bias, voice drift, hallucinated facts). Operator-in-the-loop only at the merge step. Zero per-token cost (Claude Code via Max subscription, MLX-served Qwen judges locally, no third-party services).

## Non-goals

- Real-time publish (24-hour latency floor is a feature, not a bug — gives the operator time to veto)
- Cross-lab direct messaging (labs read each other's public RSS, no internal pipe)
- Web dashboard / Slack / fancy UI (logs are enough)
- Auto-discovery of publish-worthy artifacts (lab-side ratification is the gate)

## Constraints

- Hardware: M3 Pro 18GB unified memory shared with both labs running 24/7
- Anthropic budget: $0 (Max subscription only, no API tokens)
- All curator inference: local MLX serving Qwen 2.5 family
- All drafting: `claude --print` (cloud-side compute, near-zero local RAM)
- Site host: GitHub Pages, deploys from `main` push
- Curator runs on operator's Mac via launchd (not GitHub Actions — auth/Claude Code/Ollama are local)

## Architecture

```
┌────────────────────┐  ┌────────────────────┐
│ HIVE close hook    │  │ AGI close hook     │
│  appends manifest  │  │  appends manifest  │
└─────────┬──────────┘  └─────────┬──────────┘
          │                       │
          ▼                       ▼
   publish_candidates/<id>.json (per-lab, git-tracked)
          │                       │
          └───────────┬───────────┘
                      │
                      ▼
       ┌──────────────────────────────────────────┐
       │  Curator (~/Desktop/website/tools/       │
       │           curator/run.sh)                │
       │  Daily 04:00 launchd                     │
       │                                          │
       │  1. RAM precondition (>=12GB free)       │
       │  2. Scan manifests for new candidates    │
       │  3. Per candidate:                       │
       │     a. Risk classifier (Qwen 3B / MLX)   │
       │     b. Draft (claude --print, Opus)      │
       │     c. PoLL panel (3x MLX models)        │
       │     d. Validators (deterministic)        │
       │     e. Provenance frontmatter            │
       │     f. OG image (Pillow)                 │
       │     g. Branch + commit                   │
       │     h. PR or auto-merge per tier         │
       └──────────────────────────────────────────┘
                      │
                      ▼
              main → GH Pages auto-deploy
```

## Layer 1 — Lab-side manifest contract

Each lab gets `publish_candidates/<id>.json` with this schema:

```json
{
  "id": "hive-c108-byte-identical",
  "lab": "hive",
  "type": "note",
  "status": "ready",
  "title": "Twelve cycles of byte-identical builds",
  "summary": "What it takes for an autonomous lab to produce reproducible binaries across cycles, and why it matters for verification.",
  "source_artifacts": [
    "lab/knowledge/findings/c108-byte-identical.md",
    "lab/state/build_history.tsv"
  ],
  "ratified_at": "C108",
  "ratified_date": "2026-05-04",
  "tags": ["verification", "build-discipline"],
  "voice_fit_target": 6.5,
  "novelty_target": 6.0,
  "risk_tier": null,
  "curator_state": "pending"
}
```

**Append-only.** Once a JSON file exists, the curator picks it up. The lab never deletes or modifies entries (those are the audit trail).

The append happens inside the lab's existing closeout protocol:
- HIVE: knowledge-manager agent writes when a finding/heuristic transitions to STABILIZED or a paper is archived
- AGI: program-close hook writes when `closure_memo.md` lands

`curator_state` lifecycle:
- `pending` → curator hasn't seen it yet
- `processing` → curator picked it up
- `published` → in main, deployed
- `held` → failed a gate (judge, validator, risk); curator won't re-try without manual reset
- `superseded` → newer candidate replaces this one

## Layer 2 — Curator pipeline

**Triggers:** daily 04:00 local time via launchd. RAM precondition: defer to next day if <12GB free.

**Per-candidate pipeline** (in `process.sh`):

| Step | Tool | Purpose | Failure mode |
|---|---|---|---|
| 1. Read source | `cat` + git | load source artifacts named in manifest | fail if any missing |
| 2. Classify risk | MLX Qwen 2.5 3B | assign Tier 1/2/3 | unclassifiable → Tier 1 (default to safest) |
| 3. Draft | `claude --print --model opus` | adapt source to public Astro page | fail if claude exits nonzero |
| 4. Voice judge | MLX Qwen 2.5 Coder 14B | score voice_fit 0-10 vs voice.md anchor | <6.5 → held |
| 5. Factcheck judge | MLX Qwen 2.5 7B | verify all numbers/names/quotes appear in source | any hallucination → held |
| 6. Novelty judge | MLX Qwen 2.5 7B (same model, different prompt) | check vs already-published pieces | duplicate → superseded |
| 7. Validate | bash + grep + npm | em-dash, forbidden terms, base path, [VERIFY] markers, `npm run build` | any fail → held |
| 8. Provenance | bash | inject frontmatter metadata | n/a |
| 9. OG image | python + Pillow | generate per-piece word card | fall back to default og |
| 10. Branch + commit | git | branch `draft/<id>`, commit changes | fail loudly |
| 11. Gate by tier | gh CLI | PR or auto-merge | tier-1 PR; tier-2 PR + auto-merge if all judges pass; tier-3 commit + 24h veto |

## Risk tiers

**Tier 1 — Always PR, human merges:**
- Touches real names (other than the operator's)
- Novel external claims (data not from public papers)
- External links to specific orgs/people
- Security topics
- Anything that quotes a paper or person

**Tier 2 — PR opens, auto-merges if all three judges pass:**
- Standard methodology pieces
- Lab-internal observations with no external surface
- Cycle observations with concrete numbers but no external claims

**Tier 3 — Direct commit to draft branch, auto-merges after 24h veto window:**
- Lab status updates (cycle counts, build state)
- Internal-only experiments with no novel claims
- /now timeline updates

The risk classifier is a Qwen 3B Q4 call with a fixed prompt. When in doubt, it defaults Tier 1. False-Tier-1 (over-gating) is acceptable; false-Tier-3 (under-gating) is not.

## PoLL panel (judges)

Three independent MLX-served judges, each different prompt + temperature:

| Judge | Model | Score | Threshold |
|---|---|---|---|
| Voice fit | Qwen 2.5 Coder 14B Q4 | 0-10 | ≥6.5 (calibrated against real prose; Task 1) |
| Factcheck | Qwen 2.5 7B Q4 | pass/fail per claim | 0 hallucinations |
| Novelty | Qwen 2.5 7B Q4 (same load, different prompt) | 0-10 | ≥6.0 |

Different model variants give the diversity that addresses the same-family bias documented in arxiv 2502.01534. All Claude → Qwen evaluation is cross-family by definition.

**Loading strategy:** sequential. Voice judge loads, runs, unloads. Factcheck judge loads, runs, novelty judge reuses (same model, same context window allows). Peak RAM ~6GB during 14B load, ~4GB during 7B load.

## Validators (deterministic)

Run after judges pass:

```bash
# em-dash check
[ "$(grep -c '—' "$DRAFT")" = "0" ] || hold "em-dash present"

# forbidden phrases
grep -if forbidden_phrases.txt "$DRAFT" && hold "forbidden phrase"

# base path
grep -E 'href="(/[^h])' "$DRAFT" | grep -v "/harshithkantamneni.github.io/" && hold "bad href"

# verify markers
grep -c "\[VERIFY\]" "$DRAFT" | grep -q "^0$" || hold "[VERIFY] markers remain"

# build
(cd .. && npm run build) || hold "build failed"
```

`forbidden_phrases.txt` includes: specializing in, leverage (as verb), passionate about, cutting-edge, state-of-the-art, seamlessly, META-altitude (per-lab jargon), POST-CXX (cycle references unsuitable for public).

## Provenance frontmatter

Every published `.astro` carries a comment block with origin metadata:

```astro
{/*
  provenance:
    lab: hive
    cycle_id: C108
    source_artifacts:
      - lab/knowledge/findings/c108-byte-identical.md
    drafted_by: claude-opus-4-7 via claude-cli
    judged_by:
      voice: mlx-qwen2.5-coder-14b-instruct-4bit (8.2/10)
      factcheck: mlx-qwen2.5-7b-instruct-4bit (pass)
      novelty: mlx-qwen2.5-7b-instruct-4bit (7.1/10)
    risk_tier: 2
    curator_run: 2026-05-08T04:00:00-05:00
    cost_local_seconds: 92
*/}
```

## Voice anchor docs

`tools/curator/voice/hive.md` and `voice/agi.md` — each contains:

1. Two anchor pieces from that lab's published prose (HIVE: byte-identical-builds, llm-judge-bias; AGI: cross-lab-diagnosis if it survives the manifest backfill)
2. Annotations on what's load-bearing in each (the concrete number, the structural claim, the wry-but-not-cute tone)
3. Forbidden terms specific to that lab's internal jargon

The drafting prompt prepends voice.md before the source artifact.

## /now status surface (separate from publication pipeline)

Each lab writes `lab_status.json` at every cycle close:

```json
{
  "lab": "hive",
  "cycle": 132,
  "current_focus": "alpha gate prep",
  "last_build_status": "pass",
  "last_artifact": "knowledge/findings/c131-arch-port-complete.md",
  "updated_at": "2026-05-08T03:42:11Z"
}
```

Astro fetches both at build time. /now renders a small live block above the existing timeline.

## Failure modes defended against

| Failure | Cited source | Defense |
|---|---|---|
| Voice drift | inferred from harness pattern | voice.md anchor + judge floor |
| Hallucinated facts | AutoResearchClaw, harness §verification | numbers/names verbatim from source; factcheck judge |
| Premature publication | inferred | lab-side ratification gates the manifest |
| Cross-lab content bleed | MAST 36.9% inter-agent misalignment | curator scoped to one lab per invocation |
| Same-family judge bias | arxiv 2502.01534 | PoLL panel of Qwen variants (cross-family from Claude) |
| Bag-of-Agents amplification | DeepMind scaling agent systems | curator IS the centralized orchestrator |
| Hit Piece runaway | Shamblog 2025 | PR gate for Tier 1, 24h veto for Tier 3 |
| Resource exhaustion / hang | inferred | RAM precondition; sequential model loading; defer if labs busy |
| Internal jargon leakage | inferred | forbidden-term lint with explicit list |
| Reproducibility / origin loss | AutoRecLab provenance pattern | provenance frontmatter on every published piece |

## Cost

Per artifact:
- Drafting: $0 (Claude Max sub)
- Risk classifier: $0 (local MLX, ~5s, ~2GB peak)
- Voice judge: $0 (local MLX, ~30s, ~6GB peak)
- Factcheck + novelty: $0 (local MLX, ~25s, ~4GB peak)
- Validation, OG, git: $0
- **Total cost: $0 marginal**

Time per artifact: ~2 minutes wall clock. Daily run with 0-3 candidates: ~6 minutes worst case.

## Out of scope

- Per-piece OG image generation (default OG works fine for now; can add later)
- Slack/email notifications
- Web dashboard for curator status
- Curator self-review (no recursion)
- Auto-tagging artifacts as ready (lab-side ratification is the only signal)
- Multi-machine deployment (operator's Mac is the only host)

## Acceptance

The curator is acceptable when:

1. Daily run with no new candidates exits in <5 seconds with `no new candidates` in log
2. Run with one Tier-2 candidate produces a working PR with all gates passed and judges' scores logged
3. Run with one Tier-1 candidate produces a PR but does not auto-merge
4. Run with one Tier-3 candidate commits to a draft branch; separate veto-window cron auto-merges 24h later
5. A synthetic AI-slop draft (via deliberately bad prompt) is held by at least the voice judge or the validator
6. A draft with hallucinated facts (e.g., a number not in the source) is held by the factcheck judge
7. RAM precondition correctly defers when <12GB free
8. End-to-end run on the existing `cross-lab-diagnosis` source produces a draft within 95% character match of the live published version (allowing for minor adaptation differences)
