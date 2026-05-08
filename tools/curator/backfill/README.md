# Backfill — historical manifest entries

Six manifest entries representing the six pieces already published on the site as of 2026-05-07. They exist to:

1. Demonstrate the schema in real shape (not just synthetic test data)
2. Anchor the curator's "already published" reference set (used by the novelty judge in Task 7 to detect duplication)
3. Validate that the schema captures every field a published piece needs

**Curator behavior:** entries with `curator_state: published` are skipped on every curator run. They never re-process. They exist as a reference, not a queue.

## Files

| File | Lab | Type | Title |
|---|---|---|---|
| `recursive-verification-surface-collapse.json` | hive | report | Recursive Verification-Surface Collapse |
| `cross-lab-diagnosis.json` | hive | report | Cross-Lab Diagnosis |
| `byte-identical-builds.json` | hive | note | Twelve cycles of byte-identical builds |
| `tier-per-task.json` | hive | note | Tier dispatchers per task, not per role |
| `llm-judge-bias.json` | hive | note | Same-family LLM judge bias is real |
| `six-cycles-after-the-directive.json` | hive | note | Six cycles after the verification-depth directive |

## Validation

```bash
python3 -c "
import json, jsonschema, os
schema = json.load(open('../schema/publish_candidate.schema.json'))
for f in os.listdir('.'):
    if f.endswith('.json'):
        jsonschema.validate(json.load(open(f)), schema)
        print(f'{f}: VALID')
"
```

All 6 files validate as of 2026-05-07.

## Cross-lab source convention

`cross-lab-diagnosis.json` is authored from HIVE's perspective but its source file lives in the AGI lab tree. The schema supports two shapes for `source_artifacts`:

- **Plain string** (`"path/to/file"`): resolves against the entry's own `lab:` root
- **Typed object** (`{"lab": "agi", "path": "..."}`): cross-lab; resolves against the named lab's root

`cross-lab-diagnosis.json` uses the typed-object form. All other backfill entries use plain strings.

This was refactored from the original `../../AGI/...` relative-path notation on 2026-05-08 (deferral item 2 closed).

## All HIVE, no AGI

All 6 currently-published pieces are sourced from HIVE work. AGI Lab hasn't published yet. When AGI ratifies its first envelope paper or program closure for public consumption, that'll be the first `lab: "agi"` entry.

## Anchor convention (`path#anchor`)

Some `source_artifacts` use `path#section-anchor` notation (e.g. `knowledge/heuristics.md#H-C61-01`). The anchor is informational — the curator will read the whole file and the anchor helps the LLM locate the relevant section. The path part (before `#`) is what gets opened.
