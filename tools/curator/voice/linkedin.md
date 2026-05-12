# LinkedIn — Voice Anchor

**Note:** synthesized starting point. The operator should review what this produces on the first 2-3 teasers, then either tune this file directly or replace it with 2-3 real LinkedIn posts (theirs or writers they admire) that better match the voice they want.

The LinkedIn register is NOT the same as the brutalist editorial voice on the site. It's tighter, more personal, more obviously human. But it still avoids cargo-cult marketing language — same forbidden phrases apply.

---

## Shape

LinkedIn rewards a specific cadence:

```
Hook (1 line, often counterintuitive or specific fact)
[blank line]
Context (2-3 lines, why the hook matters)
[blank line]
Insight (3-5 lines, the actual point)
[blank line]
Optional: bulleted takeaways (3-4 bullets)
[blank line]
CTA (1-2 lines, link + invitation)
```

Total length: 150-300 words. LinkedIn truncates posts at ~210 chars in feed; the first two lines are the entire pitch. Lead with the strongest fact.

## Anchor 1 — "Lab passed its own tests" example

> Twelve cycles in a row, my autonomous lab produced byte-identical builds across five platforms.
>
> Sounds like nothing happened. It actually means something specific: no specialist agent introduced an undeclared change to the build during those two weeks.
>
> The discipline is what makes verification meaningful at all. Without byte-identical reproducibility, every "build still passing" claim is just another self-reported number from inside the trust boundary.
>
> The point isn't the bytes. It's that drift in the build is now legible to an outside observer.
>
> Full write-up on what it took to get there: [URL]

**What's load-bearing:**
- **First line is the specific fact.** "Twelve cycles in a row" not "consistently for weeks."
- **Defamiliarize fast.** "Sounds like nothing happened. It actually means..."
- **Pragmatic close.** Names what the discipline buys you, not how clever the team is.
- **CTA is a link, not a hashtag spray.** No `#multiagentsystems #autonomousAI #futureofAI`.

## Anchor 2 — "Found something surprising" example

> ICLR 2026 paper says LLM judges systematically prefer outputs from their own model family.
>
> I run a multi-agent review gate with 4 separate Claude opus instances. The intuition was role diversity (architect / red team / researcher / CPO) would catch bias. Empirically: when proposals get split votes, the dissent is on framing, not substance.
>
> The fix has to be structural. At least one judge in any review board needs to be cross-family. Currently testing Qwen-2.5 via local Ollama as that voice.
>
> The general principle: same-family is a different problem from sample-size. Adding more Claude instances doesn't give you cross-family diversity. It gives you the same review board with more chairs.
>
> [URL]

**What's load-bearing:**
- **Hook is a citation + a finding.** Specific paper, specific claim.
- **First-person credibility.** "I run a multi-agent review gate" not "Many teams use multi-agent reviews."
- **Honest about what the experiment showed.** Including the framing of "intuition was X. Empirically Y."
- **Closing principle is the real takeaway.** Not the project's name, not buzzwords.

## On-voice phrases (LinkedIn specifically)

- "Sounds like X. Actually means Y."
- "Empirically:"
- "The point isn't X. It's Y."
- "The fix has to be structural."
- Concrete numbers in the first sentence.
- Direct first-person ("I", "we") without humblebrag.
- One specific named system/paper/concept per post.

## Off-voice phrases (avoid; flag if seen)

All HIVE/AGI off-voice phrases apply here, plus LinkedIn-specific:

- "Excited to share my latest" / "Excited to announce"
- "Honored to" / "Humbled by"
- Hashtag spam at the end
- "Game-changing", "groundbreaking", "revolutionary"
- "What are your thoughts? Comment below!" (forced engagement bait)
- "Thread 🧵 1/12" (LinkedIn doesn't do Twitter threads)
- "DM me if you want to chat" (too aggressive)
- Anything that smells like a personal brand pitch

## CTA conventions

End with one of:

- `Read the full report: <URL>`
- `Full piece + discussion in the comments: <URL>`
- `More + the methodology: <URL>`

If the post is a follow-up to an earlier post, the CTA can reference it:
- `Builds on last week's post on X: <URL>`

Avoid:
- "Click the link in my bio" (LinkedIn doesn't use bio links)
- "Like + share if this resonates" (engagement bait)
- "DM me" (too forward)

## Length target

200-300 words. Under 150 reads thin; over 350 hits the "see more" fold (LinkedIn collapses long posts). Empirically the 200-300 range performs best for technical posts.
