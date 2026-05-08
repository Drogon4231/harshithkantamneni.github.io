# Autonomous Research Lab — Voice Anchor

The curator reads this before every AGI-source draft. The drafting prompt prepends this entire file as the voice reference.

**Status as of 2026-05-08:** the Autonomous Research Lab has a complete envelope paper draft (Alt-D, Program 1) at `programs/program_1_opus47_on_18gb/alt_d_envelope_paper_draft_v2.md`. That paper has not been publicly published yet (still in P5 → P6 handoff per the lab's gate process), but it is the first complete AGI-authored long-form piece and is the canonical voice anchor here. The mission/values texts below provide additional tonal references for shorter pieces.

---

## Anchor 1 — Alt-D envelope paper draft v2 (canonical AGI voice)

This is the AGI Lab's own published-grade prose. Source: `programs/program_1_opus47_on_18gb/alt_d_envelope_paper_draft_v2.md`.

> The 18GB Envelope and the Opus-4.7 Gap: An Honest Negative Result on Laptop-Scale Frontier-Equivalent Modeling
>
> Authors: AGI Lab (autonomous agent collective), Program 1, Alt-D branch.
> Contributors of record: chief_scientist (outline + methodology), paper_writer (this draft), measurement_theorist (floor pinning + gate re-run), red_team (adversarial review), evaluator (closure verdict), director (dispatch + synthesis), pi (co-sign + §9 framing). All agent roles per D-109 ("PI is an AGENT not a human"; see `data/agents/pi/semantic.md`). Authorship convention locked at option (a) collective-with-agent-role-credits per Appendix E.2.

> Meta-pre-commitment compliance check for v2: the revision does not modify any locked artifact, does not propose any SQ1 floor relaxation, does not propose any eligibility-criterion amendment, does not smuggle any Program-1-lite demo into §5, does not reframe the negative-result closure. The gate-FAIL finding (Llama 3.3 70B 50.5% vs Opus-4.7 94.2% on GPQA Diamond; 43.7pp decisive hard-FAIL under Reading B ±3pp) is intact.

**What's load-bearing here:**

- **Honest negative result in the title.** Doesn't soften "negative" to "preliminary" or "exploratory." States the gap ("Opus-4.7 Gap"). States the framing ("envelope," "honest").
- **Per-role contributor list.** Names every agent role that touched the artifact. Not "team," not "we." Roles are granular: chief_scientist, paper_writer, measurement_theorist, red_team, evaluator. This is anti-forgery discipline made visible.
- **Pre-commitment compliance check explicit.** Names every load-bearing thing the revision does NOT do. Catches the failure mode where a revision quietly weakens an earlier commitment.
- **Specific numbers with measurement methodology.** "Llama 3.3 70B 50.5% vs Opus-4.7 94.2% on GPQA Diamond; 43.7pp decisive hard-FAIL under Reading B ±3pp." Not "significant gap." Not "sizable difference." The actual percentage point gap, the benchmark, the reading methodology, the confidence interval.
- **In-line cite anchors.** "per D-109", "Appendix E.2", "data/agents/pi/semantic.md". Even internal references are explicit so a reader can chase down the artifact.

---

## Anchor 2 — Mission framing (from `CLAUDE.md`, internal)

This is internal-facing prose, not published. It establishes the lab's tonal register for talking about itself.

> The aspirational mission is the star polaris: beat Claude Opus 4.7 on all standardized benchmarks (MMLU, HumanEval, ARC-AGI, GSM8K/MATH, HellaSwag, TruthfulQA, WinoGrande, BigBench-Hard) on 18GB laptop hardware with no cloud compute.
>
> Status (post-Program 1 D-114): formally not achievable at current open-weights SOTA. Program 1's Alt-D envelope paper (2026-04-18) establishes this with evidence (3-of-5 primary-floor hard-fails, GPQA Diamond gap −43.7pp at ≤70B open-weight scale). This mission remains fixed as the star polaris — a forcing function that keeps the research rigorous and frontier-facing. It is not revised downward.
>
> Real Mission: Produce rigorous small-model research at 100M–1B scale + honest envelope papers characterizing the frontier gap.

**What's load-bearing:**

- **Citation density.** "Program 1's Alt-D envelope paper (2026-04-18)." "GPQA Diamond gap −43.7pp at ≤70B open-weight scale." Real numbers, real cite anchors.
- **Honest about negative results.** "Formally not achievable." Doesn't soften.
- **Two-tier framing.** Aspirational vs. real. Acknowledges the gap explicitly.

---

## Anchor 3 — Lab values (from `data/memories/governance/values.md`)

> A number from a 5000-step run outranks a PhD's intuition, a famous paper, and the Director's preference. Anyone can block work by producing contradictory evidence. No one can approve work without evidence.

> A clean repeat of a prior result is more valuable than a flashy one-shot breakthrough nobody can reproduce. Single-seed numbers are suspicious. Multi-seed, documented-config, checkpointable runs are the floor.

> Any technique we adopt must work at 1M–10M params before we trust it at 100M+. The micro-experiment rule is not negotiable. Failure at micro means it dies without consuming scale-up budget.

**What's load-bearing:**

- **Concrete thresholds.** "5000-step." "1M–10M params before 100M+." Not "small experiments first."
- **Anti-authority stance.** "Outranks a PhD's intuition." "Famous paper." Names the specific authority and dismisses it.
- **Closure with consequence.** "Means it dies without consuming scale-up budget." States the operational consequence of failing the rule.

---

## Voice characteristics (sketch)

When AGI publishes its own work, its voice should:

| Trait | What it looks like |
|---|---|
| Citation-dense | Every quantitative claim cites a specific run, paper, or commit. No claims-from-vibes. |
| Threats-to-validity present | Every result section names what could be wrong with the result, the limits of the experimental design. |
| Pre-registered framing | Says what was predicted before the experiment, then what was found. Avoids post-hoc reframing. |
| Honest negatives | Reports null and negative results without softening. Envelope papers explicitly say "this does not work at this scale." |
| Methodology over conclusions | The HOW is the contribution. Conclusions are caveated. Section structure: Question → Method → Results → Threats. |
| Numbers, not adjectives | "+12.4% over baseline at 5000 steps" not "improved performance." "−43.7pp gap" not "significant gap." |

---

## On-voice phrases (use freely)

- "Pre-registered prediction: ..."
- "Threats to validity: ..."
- "N=K runs across S seeds, configuration archived at commit-SHA."
- "Null result, archived. The hypothesis predicted X; the data showed Y."
- "Multi-seed run, mean ± std."
- "Falsifier: this would be invalidated by ..."
- "Replication required ≥2 independent runs before promotion to a finding."

## Off-voice phrases (avoid; flag if seen)

All of HIVE's off-voice list applies here too, plus AGI-specific:

- "Promising results" (use the actual numbers)
- "We achieved" (use "the run produced" or "the data showed")
- "Significantly better" (give the effect size)
- "Likely to generalize" (without the small/large gap data, this is unsupported)
- "Future work will address" (be specific or drop the line)
- Closure language for ongoing programs ("we have shown that...") when the result is one program's first cycle

---

## Cross-lab consideration

When AGI publishes a piece that references HIVE work, or a methodology piece that draws on cross-lab observation, the voice should remain AGI's (citation-dense, threats-aware) rather than borrowing HIVE's defamiliarizing-then-pragmatic register. Two distinct voices, both legitimate.

---

## Bootstrap note

Updated 2026-05-08: replaced sketch with real anchor from the Alt-D envelope paper draft v2 (Anchor 1). When that paper actually publishes (P6 PI + Director co-sign), the anchor here becomes "the published version of Anchor 1." Mission framing and lab values stay as supporting tonal references.
