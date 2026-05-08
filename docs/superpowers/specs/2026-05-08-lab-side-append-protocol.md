# Lab-Side Append Protocol

**Date:** 2026-05-08
**Audience:** HIVE knowledge-manager agent + AGI program-close hook (operator implements one-time on each lab)
**Companion to:** `docs/superpowers/specs/2026-05-07-curator-pipeline-design.md`

---

## What this spec defines

When an artifact ratifies inside a lab and crosses the publication threshold, the lab appends a single JSON file to `publish_candidates/` matching `tools/curator/schema/publish_candidate.schema.json` on the website repo. The curator daily-cron picks it up.

This spec is the **append discipline**: what triggers an append, what the entry must contain, and the invariants that hold across appends.

## Where the file goes

| Lab | Path |
|---|---|
| HIVE | `~/Desktop/Fun/lab/publish_candidates/<id>.json` |
| AGI | `~/Desktop/AGI/data/publish_candidates/<id>.json` |

Curator scans both paths daily. Per-lab scoping is intentional (avoids cross-lab content bleed; MAST taxonomy 36.9% inter-agent misalignment).

## When to append

### HIVE triggers

The HIVE knowledge-manager agent appends a manifest entry on any of these transitions:

1. **A heuristic transitions to STABILIZED** with the four-exhibit floor met and the multi-cycle hold satisfied (per HIVE's lifecycle: PROVISIONALLY-VERIFIED → ACCEPTED → STABILIZED → CLOSED). Only if the heuristic has cross-cycle generality (not implementation-specific).
2. **A finding transitions to RATIFIED** in `archives/findings/c<N>/` and the finding's content is generalizable beyond a single cycle's situation.
3. **A paper draft is archived** under `paper_archived_v<N>_<date>/` with a closure memo present.
4. **A long-form post-mortem or methodology piece** is filed under a dedicated archive directory with PI co-sign in the directive log.

### AGI triggers

The AGI program-close hook appends on:

1. **A program closure memo lands** at `programs/<program>/closure_memo.md` with PI + Director co-sign.
2. **A phase publication file** lands at `programs/<program>/phase<N>_publication.md` with the lab's gate progression complete (p4_evaluator_report → p5_evaluator_report → p5_red_team_report all passing).
3. **A methodology paper or envelope paper** transitions from DRAFT to RATIFIED inside the program directory.

## What the entry contains

Required fields (validated by the curator's schema):

- `id` — slug derived from the artifact (URL-safe, used as page filename)
- `lab` — `"hive"` or `"agi"`
- `type` — `"report"` (long-form, ~2,500-4,000 words) or `"note"` (short-form, ~500-1,500 words)
- `status` — `"ready"` (or `"draft"` if the lab wants to test the curator without triggering publication)
- `title` — public-facing title
- `summary` — 1-2 sentences for writing list, RSS, social cards
- `source_artifacts` — array of paths relative to the lab root (the curator reads these when adapting)
- `ratified_at` — cycle ID, named anchor (e.g. `closure_memo_2026-04-18`), or ISO date
- `curator_state` — always `"pending"` on first append

Optional fields (curator may set or override):

- `ratified_date` — ISO date (helps with date-based sorting)
- `tags` — topic tags, lowercase, hyphenated
- `voice_fit_target` — defaults to 6.5 if absent (see Task 1 calibration)
- `novelty_target` — defaults to 6.0 if absent
- `risk_tier` — let the classifier set this; lab leaves null

## Invariants

1. **Append-only.** Once written, an entry is never modified or deleted by the lab. The curator owns subsequent state transitions. The lab can append a NEW entry that supersedes a prior one (status `"superseded"` on the prior id, new entry with new id).

2. **Idempotent.** If the same artifact is ratified twice (e.g., re-ratified after a revision), the lab uses a different `id` (e.g., suffix `-v2`). The curator never overwrites.

3. **Source paths must resolve.** Every path in `source_artifacts` must be readable when the curator scans (relative to the lab root). The curator fails the candidate (state `"held"`, reason `"source_artifacts not found"`) if any path fails to resolve.

4. **One JSON file per candidate.** No JSONL aggregate. Each artifact gets its own file. This makes git diffs clean and lets the operator inspect/delete a single candidate easily.

5. **Filename matches `id`.** The file at `publish_candidates/<id>.json` MUST contain `"id": "<id>"`. Curator validates this.

6. **No secrets in the manifest.** The lab MUST NOT include API keys, paths to private data, or anything that would be embarrassing if the manifest got pushed publicly. Source artifacts can reference files with secrets, but the entry's metadata stays clean.

## Example: HIVE knowledge-manager pseudocode

```python
def on_heuristic_stabilized(heuristic_id, heuristic_node):
    if not heuristic_node.is_publishable():  # cross-cycle generality, no internal-implementation coupling
        return

    candidate_id = slugify(heuristic_node.public_title)
    out = Path(LAB_ROOT) / "publish_candidates" / f"{candidate_id}.json"
    if out.exists():
        return  # idempotent — never overwrite

    payload = {
        "id": candidate_id,
        "lab": "hive",
        "type": "note",
        "status": "ready",
        "title": heuristic_node.public_title,
        "summary": heuristic_node.public_summary,
        "source_artifacts": heuristic_node.source_paths_relative,
        "ratified_at": heuristic_node.cycle_anchor,
        "ratified_date": heuristic_node.ratified_date_iso,
        "tags": heuristic_node.tags,
        "curator_state": "pending"
    }
    validate_against_schema(payload)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2))
    log("appended manifest entry", candidate_id)
```

## Example: AGI program-close hook pseudocode

```python
def on_program_closure_memo(program_dir):
    closure_memo = program_dir / "closure_memo.md"
    if not closure_memo.exists():
        return

    metadata = parse_closure_memo_frontmatter(closure_memo)
    if metadata.get("publish_to_portfolio") != True:
        return  # opt-in flag in the closure memo frontmatter

    candidate_id = slugify(metadata["public_title"])
    out = Path(LAB_ROOT) / "data" / "publish_candidates" / f"{candidate_id}.json"
    if out.exists():
        return

    payload = {
        "id": candidate_id,
        "lab": "agi",
        "type": metadata.get("type", "report"),
        "status": "ready",
        "title": metadata["public_title"],
        "summary": metadata["public_summary"],
        "source_artifacts": metadata["public_source_artifacts"],
        "ratified_at": f"closure_memo_{metadata['date']}",
        "ratified_date": metadata["date"],
        "tags": metadata.get("tags", []),
        "curator_state": "pending"
    }
    validate_against_schema(payload)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(payload, indent=2))
```

## Lab-side validation before commit

Before each append, the lab agent should:

1. Read `tools/curator/schema/publish_candidate.schema.json` from the website repo (cached locally is fine; refresh weekly)
2. Validate the proposed JSON against the schema
3. Verify each source path in `source_artifacts` resolves
4. Refuse to write the file if validation fails; surface a clear error to the lab's own log

This pushes errors to the lab side rather than letting them accumulate in held curator candidates.

## What this spec does NOT cover

- The curator's processing pipeline (covered in main spec)
- The website's publication pages (out of scope; curator owns)
- Lab-side opt-out mechanisms (e.g., "don't publish this even though it stabilized") — the lab's own ratification discipline already filters; the manifest only sees publication-eligible artifacts
- Cross-lab observation pieces (where one lab observes another and writes a piece about it) — these are written by the operator in the relevant lab's normal flow and tagged with the appropriate `lab:` value; cross-lab is just data, not a separate workflow

## Implementation status

- [x] Spec written
- [ ] HIVE knowledge-manager agent implements (lab-side work; not blocking curator pipeline)
- [ ] AGI program-close hook implements (lab-side work; not blocking curator pipeline)

The curator pipeline tests against backfilled manifest entries (see `tools/curator/backfill/`) until the labs implement append. This is the right sequencing: prove the curator works, then have the labs feed it.
