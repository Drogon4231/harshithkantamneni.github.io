# HIVE — Voice Anchor

The curator reads this before every HIVE-source draft. The drafting prompt prepends this entire file as the voice reference.

---

## Anchor 1 — `byte-identical-builds`

> HIVE just produced its twelfth consecutive cycle where the cross-platform build (Android arm64, armeabi-v7a, x86, x86_64, plus iOS Mach-O) hashed identically to the cycle before it. Five surfaces, twelve cycles, byte-for-byte the same binary content.
>
> That sounds like nothing happened. It actually means something specific: across roughly two weeks of cycles, no specialist agent introduced an undeclared change to the build output. Source edits that touched the relevant files either didn't make it into the binary (correctly), got reverted (correctly), or didn't exist (the binary is a stable base case). Every change that should have been visible would have shown up as a hash mismatch.
>
> It took three things to get here. First, an R11 invariant that names exactly which surfaces must hash-match the previous cycle: per-architecture `.so` files for Android, the Mach-O for iOS, and the symbol-name set within them. Second, a build-history TSV row appended at every cycle close, which means the chain is grep-recoverable across hundreds of cycles. Third, a golden symbol parity check that requires both `hive_core_zeroize` and `hive_core_hkdf_sha256` to appear at the same address as the prior cycle's binary, which catches the case where the symbol set is intact but its layout shifted underneath.
>
> Why this matters for verification: it gives the external verdict (CI on a public commit) something concrete to bind against.
>
> The point of byte-identical builds is not the bytes. It is the structural fact that drift in the build is now legible to an outside observer. Without that, the build-pass streak is just another self-reported number.

**What's load-bearing here:**

- **Lead with a specific, quantifiable fact.** "Twelfth consecutive cycle." Not "many cycles." Not "consistently."
- **Defamiliarize the obvious.** "That sounds like nothing happened. It actually means something specific." This pattern shows up across HIVE prose: state the apparent triviality, then specify what it actually means.
- **Concrete enumeration.** "Three things." Not "several." Then list the three with technical specifics.
- **Reframe at the end.** "The point isn't the bytes." Closing with the structural claim that resolves what the piece was actually about.
- **No grandeur.** Never says "rigorous methodology" or "robust verification." Just describes what was done.

---

## Anchor 2 — `tier-per-task`

> Common pattern in multi-agent setups: assign each role a fixed model tier. The architect gets opus, the implementer gets sonnet, the formatter gets haiku. Cleaner config, simpler routing, easier to reason about.
>
> The problem is that real roles don't do one tier of work. Applied researcher reading five papers and synthesizing a verdict is opus-tier judgment work. The same applied researcher pulling three citation strings out of a known paper is haiku-tier mechanical extraction. If the role is pinned to one tier, you either burn opus on the mechanical task or send haiku at the judgment task. Both are bad.
>
> The fix is to tier the dispatch, not the role. Same agent, different model per call, decided by what the task is rather than who is doing it.
>
> What it costs: a dispatcher has to make a real decision per call. Either a person picks the model, which adds friction to every dispatch, or a script picks based on task signals (keywords, length, output schema, escalation history), which adds infrastructure but stays cheap to run.
>
> What it buys: usually 2-5x cost reduction at matched quality, because most of what specialists do is bounded and doesn't need the top tier.

**What's load-bearing here:**

- **State the common pattern, then attack it.** "Common pattern: X. The problem is Y." Sets up a contrast.
- **Concrete examples on both sides.** "Applied researcher reading five papers" vs. "pulling three citation strings." Specific verbs and numbers.
- **What it costs / what it buys.** Symmetric framing. Honest about tradeoffs.
- **No filler hedge words.** No "in many cases," no "generally speaking." Direct claims.
- **Slightly wry pragmatism.** "Both are bad." Two-word punch line.

---

## Voice characteristics (synthesized)

| Trait | What it looks like |
|---|---|
| Declarative | Statements, not "I think" or "it could be argued." |
| Specific | "Twelfth cycle," "5 sign-offs," "1,688 tests." Never "several," "many." |
| Short sentences mixed with longer | "Both are bad." Then a longer paragraph unpacking why. |
| Defamiliarizing setup | "That sounds like nothing happened." |
| Counter-establishment edge | Names the common-but-wrong pattern, then dismantles it. |
| Pragmatic, not idealistic | "What it costs / what it buys." Honest tradeoffs. |
| Wry but not cute | Dry punchlines. Not jokes. |
| Counter-cargo-cult | If most AI portfolios would write a phrase, HIVE prose avoids it. |

---

## On-voice phrases (use freely)

- "It actually means something specific."
- "The point isn't X. It's Y."
- "What it costs / what it buys."
- "That sounds like nothing happened."
- "Both are bad."
- "Trust the loops; intervene only when they fail."
- Phrases that lead with a number or named technical artifact.
- Phrases that punctuate a paragraph with a short sentence that lands hard.

## Off-voice phrases (avoid; flag if seen)

- "Cutting-edge," "state-of-the-art," "next-generation"
- "Specializing in," "passionate about," "deeply experienced"
- "Leverage" as a verb
- "Seamlessly," "robustly," "scalably"
- "Paradigm shift," "innovative approach," "revolutionary"
- "We are excited to announce"
- Em-dashes (—) anywhere
- Hedging filler: "in many cases," "generally speaking," "broadly," "tends to"
- Marketing nouns: "synergy," "best-in-class," "proven track record"
- AI-adjacent buzz: "AI-powered," "intelligent automation," "next-gen agents"
- Lab-internal jargon left unexplained: "META-altitude," "POST-C103," "FINDING-CXX-NN"
- Closure-framing for things that aren't closed: "we have completed," "we have solved"

---

## Test cases

If a draft is judged against this anchor:

**HIGH score (~8/10) drafts:**
- Lead with a specific weird fact
- Have at least one defamiliarizing setup
- End with a structural reframe
- No cargo cult phrases

**MID score (~6/10) drafts:**
- Generally on-voice but introduce some narrative or first-person flourish that goes beyond declarative
- Contain one minor hedge or generalization

**LOW score (≤4/10) drafts:**
- Use cargo cult language
- Generic abstractions without numbers
- Marketing tone
- Closure-framing for unfinished work
