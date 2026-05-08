# Curator — MLX Setup & Verification

**Date verified:** 2026-05-07
**Host:** M3 Pro 18GB unified memory
**Status:** Task 1 of implementation plan complete

---

## Install

```bash
pip3 install --break-system-packages mlx-lm
```

Verifies:

```bash
python3 -c "from mlx_lm import load, generate; print('mlx_lm OK')"
which mlx_lm.generate
```

Result: installed successfully. CLI available at `/opt/homebrew/bin/mlx_lm.generate`.

---

## Models pulled and verified

All three pulled from `mlx-community/` on Hugging Face. Auto-cached at `~/.cache/huggingface/hub/`.

| Model | Disk size (Q4) | Peak RAM | Generation throughput | First-load time | Cached-load time |
|---|---|---|---|---|---|
| `mlx-community/Qwen2.5-3B-Instruct-4bit` | ~2 GB | **1.86 GB** | 140 tok/s | ~26s download | ~5s |
| `mlx-community/Qwen2.5-7B-Instruct-4bit` | ~5 GB | **4.43 GB** | 61 tok/s | ~52s download | ~8s |
| `mlx-community/Qwen2.5-Coder-14B-Instruct-4bit` | ~9 GB | **8.44 GB** | 33 tok/s | ~110s download | ~15s |

All three respond correctly to a smoke-test prompt. Memory peaks match pre-task estimates within 1 GB.

---

## CLI invocation pattern

Single-shot generate:

```bash
mlx_lm.generate \
  --model mlx-community/Qwen2.5-Coder-14B-Instruct-4bit \
  --prompt "$PROMPT_TEXT" \
  --max-tokens 1024
```

For longer prompts, pipe via stdin or `--prompt-file`:

```bash
mlx_lm.generate \
  --model mlx-community/Qwen2.5-7B-Instruct-4bit \
  --prompt-file /path/to/prompt.txt \
  --max-tokens 2048 \
  --temp 0.3
```

Common flags we'll use:
- `--max-tokens N` — output cap
- `--temp F` — sampling temperature (0.3 for judging, 0.0 for classification)
- `--top-p F` — nucleus sampling threshold (default 1.0 is fine)
- `--seed N` — for reproducibility in eval mode

---

## Sequential loading discipline

MLX does NOT auto-unload models between calls. Each `mlx_lm.generate` invocation loads, runs, exits — clean. Memory is freed at process exit.

Implication: invoke as a separate subprocess per stage. Don't try to use the Python API to keep models resident across pipeline stages — that would stack RAM usage.

The curator's per-stage pattern:

```bash
# stage 1: classify with 3B (peak 1.86 GB)
TIER=$(mlx_lm.generate --model 3B-Instruct-4bit --prompt "$CLASSIFY_PROMPT" --max-tokens 8)

# stage 2: voice judge with 14B (peak 8.44 GB) — independent process
VOICE_SCORE=$(mlx_lm.generate --model Coder-14B-Instruct-4bit --prompt "$VOICE_PROMPT" --max-tokens 256)

# stage 3: factcheck with 7B (peak 4.43 GB) — independent process
FACT_RESULT=$(mlx_lm.generate --model 7B-Instruct-4bit --prompt "$FACT_PROMPT" --max-tokens 512)
```

Sequential, never overlapping. Peak RAM at any moment ≤ 8.44 GB (during 14B stage).

---

## RAM safety margin

| Scenario | Free RAM needed | Curator peak | Verdict |
|---|---|---|---|
| Both labs idle (~2-3 GB lab-side) | ~10 GB free | ~8.44 GB | Safe |
| AGI lab training (~13-15 GB lab-side) | ~3-5 GB free | ~8.44 GB | **Defer — RAM precondition catches** |
| HIVE running, AGI idle | ~10-12 GB free | ~8.44 GB | Safe |

Curator's `lib/ram_check.sh` (Task 4) gates on free RAM ≥ 12 GB before launching to keep margin for OS + IO buffers.

---

## Disk footprint

Models cached at `~/.cache/huggingface/hub/models--mlx-community--*`. Total ~16 GB committed.

```bash
du -sh ~/.cache/huggingface/hub/models--mlx-community--*
```

To remove a model and free disk: `rm -rf ~/.cache/huggingface/hub/models--mlx-community--<name>`.

---

## Acceptance — Task 1

Per the implementation plan:

- [x] `mlx-lm` installs cleanly
- [x] All three models load and respond
- [x] Peak RAM measured matches expectation (3B≈2GB ✓, 7B≈4-5GB ✓, 14B≈8-9GB ✓)
- [x] First run downloads weights; second run loads from cache in ≤15s
- [x] CLI invocation pattern documented

**Task 1 complete.** Ready for Task 2 (manifest contract + backfill).
