# Portfolio brutalist redesign — design spec

**Date:** 2026-05-06
**Status:** Approved (verbal, three sections), pending written review
**Target:** `https://drogon4231.github.io/harshithkantamneni.github.io/`
**Repo:** Astro 5.4.2 project at `/tmp/harshithkantamneni.github.io`

---

## Context

The current site (Fraunces serif + warm beige `#F7F3EB` + terracotta `#B8593A`) reads as
the second wave of AI-portfolio cargo cult: warm-beige-and-serif as a reaction to the
indigo-Tailwind first wave. User feedback after the first review:

1. Looks Claude-like
2. Visual hierarchy clutter — important points don't catch the eye
3. Mobile not friendly

## Positioning thesis

**Brutalist editorial × research lab.** The site is a publication, not a portfolio
deck. It documents the operating methodology of autonomous AI labs — long-form prose
is the primary surface, not stat cards. The visual system creates drama through type
scale and confident hierarchy, not decoration. One distinctive interaction. Stark color.
Mobile-first.

Three explicit anti-patterns to avoid:

1. **AI-portfolio v1**: Tailwind indigo, Inter, three-icon-grid, gradient hero
2. **AI-portfolio v2**: warm beige + Fraunces + terracotta + uniform cards (current site)
3. **Brutalism-cosplay**: Times-New-Roman-and-shouting; harshness without hierarchy

The cure is brutalist editorial in service of legibility — heavy type for emphasis,
generous reading measure, hairline rules over boxes, marginalia for context.

## Approved decisions

### Color (Option A: Concrete brutalism)

```
--paper:        #E8E5DF   /* cool grey paper, warmer than #FFF, cooler than current beige */
--ink:          #111111   /* near-black, not pure */
--ink-low:      #555555   /* mono labels, secondary text — 6.0:1 on paper */
--accent:       #FF5722   /* industrial orange — large text, accents, marks ONLY */
--accent-deep:  #C8401B   /* darker orange for inline body links — 5.4:1 on paper */
--accent-soft:  rgba(255, 87, 34, 0.12)  /* highlight backgrounds, marks */
--rule:         #111111   /* hairline rules, full opacity */
```

Dark mode flips `--paper` ↔ `--ink`; `--accent` unchanged (4.7:1 on `#111`).

**Color usage rules (WCAG AA bounds):**

| Where | Color | Contrast |
|---|---|---|
| Body text on paper | `--ink` (#111) on `--paper` | 16.0:1 ✓ |
| Mono labels, secondary | `--ink-low` (#555) on `--paper` | 6.0:1 ✓ |
| Inline body link | `--accent-deep` (#C8401B) on `--paper` | 5.4:1 ✓ |
| Hero, h2, section markers | `--ink` on `--paper` | 16.0:1 ✓ |
| Accent at scale (>18pt or >14pt bold) | `--accent` on `--paper` | 3.4:1 ✓ for large |
| Accent rules, borders, marks (non-text) | `--accent` | n/a |
| Newsletter button text on accent | `--ink` (#111) on `--accent` | 4.7:1 ✓ |

`--accent` (#FF5722) is **never used for body-sized text on light paper** — fails AA
at small sizes. For inline body links on light paper use `--accent-deep` (#C8401B),
which passes AA at 5.4:1.

In **dark mode**, `--accent` (#FF5722) on `--ink` (#111) measures 4.7:1 — passes AA
for body text. Use a `--link` token that flips: `--accent-deep` in light mode,
`--accent` in dark mode. CSS:

```css
:root[data-theme="light"] { --link: var(--accent-deep); }
:root[data-theme="dark"]  { --link: var(--accent); }
```

### Typography

| Role | Font | Source | Approx size |
|---|---|---|---|
| Display | Bricolage Grotesque (variable, 200–800, opsz axis) | Google Fonts variable woff2, self-hosted | ~80KB |
| Body | Newsreader (variable, 200–800, opsz axis) | Google Fonts variable woff2, self-hosted | ~100KB |
| Mono | JetBrains Mono (variable, 100–800) | Google Fonts variable woff2, self-hosted | ~50KB |

**Sourcing:** download variable woff2 directly from Google Fonts (`fonts.google.com`
→ "Get font" → variable woff2). Place under `public/fonts/`. Reference via
`@font-face` in `tokens.css`.

**Subsetting strategy:** apply `unicode-range: U+0000-00FF;` (Latin-1) to all three
families. Drops Cyrillic/Greek/Vietnamese subsets, brings combined payload to
~150KB target. Use `font-display: swap` on all faces.

Drop the three Google Fonts CSS imports (Fraunces, JetBrains Mono, General Sans)
in `Default.astro` in favor of self-hosted `@font-face` declarations in `tokens.css`.

### Type scale

```
hero          clamp(3rem, 14vw, 14rem)    Bricolage 700, leading 0.9, tracking -0.02em
h2            clamp(2rem, 6vw, 5rem)      Bricolage 700, leading 1, tracking -0.01em
h3            clamp(1.25rem, 2vw, 1.75rem)  Bricolage 600
lede          clamp(1.25rem, 2vw, 1.75rem)  Newsreader 400, leading 1.4, max 42ch
body          1.0625rem                    Newsreader 400, leading 1.55, max 58ch
mono-label    11–12px                      JetBrains Mono uppercase, tracking +0.2em
pull-quote    clamp(1.5rem, 3vw, 2.5rem)  Bricolage 600, leading 1.15
```

### Hierarchy moves

1. **Extreme scale range.** Hero up to 14rem on desktop, body 1.0625rem. The scale
   jump is the visual signal — no decorative chrome.
2. **Section markers** replace the current `<span class="index-number">` + `<h2>`
   pattern. Format: `001 / THESIS` in JetBrains Mono uppercase, 12px, tracking
   +0.2em, with a hairline rule extending to right edge of viewport.

   **Semantic structure:** the marker is decoration. The `<h2>` carries the heading
   semantic. Use:
   ```html
   <header class="section-head">
     <p class="section-marker" aria-hidden="true">001 / THESIS</p>
     <h2>Thesis</h2>
   </header>
   ```
   Screen readers skip the marker, follow `<h2>`. Visual readers see both.
3. **Drop cap** on first paragraph of long-form posts (reports, multi-paragraph
   notes). 4 lines tall, Bricolage 600.

   **Implementation:** primary path uses CSS `initial-letter: 4` (modern Safari).
   Fallback for browsers without support uses `::first-letter` with `float: left`
   plus computed `font-size` and `line-height` to match. Both paths in `style.css`,
   selected via `@supports`.
4. **Pull quotes hang in the margin** (cols 9–12 on desktop). On mobile, full-width
   with 4px orange left rule.
5. **All-caps mono labels** — "ACTIVE 2026", "MADISON, WI", "REPORTS" — used as
   inline metadata, not as headings.

### Layout: asymmetric 12-column grid

```
col:  1   2   3   4   5   6   7   8   9   10  11  12
      ├───┤                                            ← marginalia (1–2)
              ├───────────────────────┤                ← body without quote (3–8)
              ├───────────────────────┤                ← body with quote (3–8)
                                          ├───────────┤ ← pull-quote (9–12)
              ├───────────────────────────────┤         ← body extends (3–10) when no quote
      ├───────────────────────────────────────────────┤ ← full-bleed: section markers, hero, rules (1–12)
```

**Allocations:**

- Marginalia (mono dates, footnotes, metadata): cols 1–2
- Body prose default: cols 3–8, ~58ch (tight, brutalist measure)
- Body prose extended (no marginalia, no quote on this row): cols 3–10
- Pull quotes: cols 9–12 (sits beside body; never overlaps)
- Hero, h2 + section marker, hairline rules: cols 1–12 (full bleed)

**Tablet (60em–80em):** marginalia merges into body (becomes inline above prose).
Pull quote stays in cols 9–12. Body cols 1–8.

**Mobile (<60em):** single column. Marginalia inlined. Pull quotes full-width with
4px orange left rule.

### Hero pattern (replaces current `.hero`)

```
001 / THESIS                                     ← mono marker, top
                                                  
I design and run                                 ← Bricolage 700,
autonomous AI labs.                                clamp(3rem, 14vw, 14rem)
                                                   intentional line breaks
                                                   
ACTIVE 2026 · MADISON, WI · 2 LABS              ← mono strip below
```

Drop parallax layers (`.hero-parallax-layer-1/2`). Drop `.lede` paragraph from hero
(moves into next section as opening prose, or omitted for index page).

### No uniform cards

| Was | Becomes |
|---|---|
| `.card` grid for labs | Numbered list: `01 — HIVE / Product Lab` + 2-line description + mono metadata row. Hairline rule between entries. |
| `.card` grid for contact channels | Two-column table: mono left (channel + handle), serif right (when/why). |
| `.card` for newsletter form | Inline form with thick orange button (`background: var(--accent)`), no surrounding box. |
| `.card` for "what I respond to" lists | Plain numbered list, large type. |

The `.card` class can be deleted from `style.css`.

### Component extraction

Repeating patterns get extracted as Astro components. Without this, 13 pages each
hand-roll the hero pattern and section markers — guaranteed drift over time.

New components in `src/components/`:

| Component | Purpose | Props |
|---|---|---|
| `Hero.astro` | Mono marker + display headline + mono meta strip | `marker`, `meta` (array); slot for headline |
| `SectionHead.astro` | Mono marker + h2 + hairline rule | `marker`, `title`, `level` (default 2) |
| `MetaStrip.astro` | Mono dot-separated metadata row | `items` (array) |
| `NumberedList.astro` | Numbered list with hairline rules between entries | slots for entries |
| `PullQuote.astro` | Pull quote with margin behavior | slot |

Existing components stay (`Header.astro`, `Footer.astro`) but get restyled to match
the new system. New components avoid the temptation to over-engineer — each is
under 30 lines, slot-driven, no internal state.

### Page-by-page deltas

**Index (`src/pages/index.astro`)**
- Hero pattern (single statement, mono metadata strip)
- `001 / LABS` numbered lab list
- `002 / WRITING` writing list (already brutalist, tighten spacing)
- `003 / SUBSCRIBE` inline newsletter form

**Labs index (`src/pages/labs/index.astro`)**
- Hero pattern
- Numbered list of labs (no cards)

**Lab detail (`src/pages/labs/hive.astro`, `autonomous-research.astro`)**
- Hero pattern with lab name + 1-line purpose
- Narrative prose with section markers (`001 / WHAT IT DOES`, `002 / OPERATING MODEL`, etc.)
- Pull quotes hang in margin
- Mono metadata strip (status, started, agent count)

**Reports index (`src/pages/reports/index.astro`)**
- Hero pattern
- Writing list (already correct shape, tighten type)

**Report detail (`src/pages/reports/recursive-verification-surface-collapse.astro`)**
- Mono metadata above title (date, length, status)
- Title in Bricolage at hero scale
- Drop cap on first paragraph
- Pull quotes hanging in right margin
- Section markers between major sections

**Notes index + detail** — same pattern as reports, smaller hero scale

**About (`src/pages/about.astro`)**
- Single prose column with marginalia in left margin
- Mono labels for sections

**Now (`src/pages/now.astro`)**
- Timeline: dates in mono left column, content in serif right column
- Most recent at top

**Contact (`src/pages/contact.astro`)**
- Two-column table replaces card stack
- Mono left (channel name + handle), serif right (purpose + response criteria)
- Inline subscribe form below

### Interaction (one distinctive move)

1. **Hero variable-font tween**: cursor proximity drives Bricolage `wght` axis
   from 500 → 700 on hero text. Subtle, alive, type-anchored.
   - Distance threshold: tween only kicks in when cursor within 240px of hero
     bounding box; outside that range, weight stays at 500
   - Throttled via `requestAnimationFrame`, single listener on `pointermove`
   - Disabled entirely under `prefers-reduced-motion: reduce`
   - Disabled on touch devices (`pointer: coarse`) — no hover, no tween
2. **Section markers**: `position: sticky; top: 0;` so each marker fixes at viewport
   top while its section is in view, releases on next section.
   - **Primary path**: scroll-driven CSS animation using `animation-timeline: view()`
     adjusts marker opacity / underline emphasis as section enters/exits
   - **Fallback path** (Firefox, older browsers): plain `position: sticky` without
     scroll-driven enhancement. Markers still anchor at viewport top, just without
     the animated transition. Wrap enhancement in `@supports (animation-timeline: view())`.
   - Pure CSS, no JS

**Dropped**:
- Lab card tilt (no cards)
- Hero parallax layers (decoration, reads as AI-portfolio)
- Scroll reveal opacity fades (paint immediately)

`motion.js` shrinks to a single interaction (~1.5KB) — the hero weight tween.
Theme toggle stays inline.

### Mobile (mobile-first)

**Breakpoints**: `40em` (phone+), `60em` (tablet), `80em` (desktop).
Fluid type via `clamp()` between them — no fixed media-query type jumps.

**Mobile-specific moves**:
- Hero clamp `clamp(3rem, 14vw, 14rem)` already produces correct mobile sizing
  via its 3rem floor (≈ 48px on phone, fills the viewport stack with the mono
  marker and metadata strip). No separate mobile clamp needed.
- Asymmetric grid → single column
- Pull quotes → full-width, 4px orange left rule, flush left
- Marginalia → inline mono metadata above prose
- Touch targets ≥48px on nav, buttons, form fields, mobile menu items, theme
  toggle (see Accessibility section for full rules; body prose links not bound)
- Mobile menu: full-bleed overlay (current `<details>` element kept, restyled).
  Links at `clamp(2rem, 8vw, 3.5rem)` Bricolage 700.
- Section markers stay sticky at top on mobile — they orient you as you scroll

### Accessibility

**Focus states (keyboard nav).**

```css
:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 3px;
  border-radius: 0;  /* no rounded focus rings */
}
```

Applied via single `:focus-visible` rule — no per-element overrides. Outline always
visible on keyboard focus, hidden on mouse click.

**Touch targets (interactive elements).**

≥48px applies to: nav links, buttons, form inputs, mobile menu items, theme toggle.
Body prose links keep their natural inline size — long-form text doesn't enforce
48px line-height. Non-prose lists (lab list, contact channel rows) get `padding`
to reach 48px clickable area without forcing visual height.

**Screen readers.**

- Section markers: `aria-hidden="true"` (decorative)
- Numbered list prefixes (`01 — `, `02 — `): `aria-hidden="true"` on the prefix span,
  the lab name itself is the readable content
- Mono metadata strip: regular `<p>` content, screen-reader accessible
- Mobile menu `<details>`: native disclosure semantics, no ARIA additions
- Theme toggle: `<button>` with `aria-label="Toggle dark mode"` (text content alone
  — `LIGHT` / `DARK` — is ambiguous without context)

**Motion preferences.**

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Plus the `motion.js` cursor tween checks `matchMedia('(prefers-reduced-motion: reduce)').matches`
before attaching listeners.

### Theme toggle

- Light/dark stays
- Dark mode: flips paper ↔ ink, accent unchanged
- Toggle button: mono uppercase `LIGHT` / `DARK` text — no sun/moon icon

### Spacing + layout tokens

```
--space-1:   0.25rem    /*  4px */
--space-2:   0.5rem     /*  8px */
--space-3:   1rem       /* 16px */
--space-4:   1.5rem     /* 24px */
--space-5:   2.5rem     /* 40px */
--space-6:   4rem       /* 64px */
--space-7:   6rem       /* 96px */
--space-8:   10rem      /* 160px — between major page sections */

--rule-thin:    1px
--rule-medium:  2px
--rule-thick:   4px

--measure-tight:    58ch  /* default body */
--measure-loose:    72ch  /* extended body */
--measure-narrow:   42ch  /* lede, hero subheads */
```

Drop the existing token names that don't match (e.g. `--content-width`,
`--container-narrow`) — replace with the measure tokens above.

### Performance budget

- Variable fonts, self-hosted woff2, subset to Latin-1, total ≤180KB
- No client-side framework
- `motion.js` ≤2KB minified
- Astro static output unchanged
- Lighthouse mobile score targets: Performance ≥90, Accessibility ≥95, Best
  Practices ≥95, SEO ≥95

## Out of scope

- New pages or new content (this is a layout/visual redesign of existing pages)
- Lab repo (`autonomous-lab-systems`) changes — separate concern
- Newsletter content — Buttondown integration unchanged
- RSS feed — content unchanged, item links unchanged
- Domain or hosting — GitHub Pages stays, base path stays
- JSON-LD, OG meta, sitemap — unchanged

## Files to touch

**New:**

- `src/components/Hero.astro`
- `src/components/SectionHead.astro`
- `src/components/MetaStrip.astro`
- `src/components/NumberedList.astro`
- `src/components/PullQuote.astro`
- `public/fonts/` — Bricolage Grotesque, Newsreader, JetBrains Mono variable woff2

**Rewrite:**

- `src/styles/tokens.css` — color, type, scale, spacing tokens; `@font-face` block
- `src/styles/style.css` — component styles, grid, section markers, drop cap

**Modify:**

- `src/layouts/Default.astro` — drop Google Fonts CSS imports
- `src/components/Header.astro` — restyle, mobile menu treatment
- `src/components/Footer.astro` — restyle (mono labels, hairline rule)
- `public/motion.js` — shrink to single interaction (cursor weight tween)
- All 13 `src/pages/**/*.astro` — apply new components, drop hand-rolled markup

## Out-of-scope files (untouched)

- `astro.config.mjs`
- `src/pages/rss.xml.js`
- `.github/workflows/deploy.yml`
- `package.json` (no new deps)

## Risk / open questions

- **Variable font subsetting**: hitting ≤180KB with Latin-1 subset is feasible but
  tight. If actual payload exceeds budget, drop one variable axis (e.g. opsz on
  Newsreader) before dropping the variable file altogether.
- **Section marker scroll-driven animation**: `animation-timeline: view()` needs
  `@supports` fallback. Spec covers this — fallback is plain `position: sticky`
  without animation. Verify in Firefox build.
- **Pull quotes in margin**: relies on grid + line-up with paragraph rows. On
  viewport widths between 60em and 80em, quote stays in cols 9–12 alongside body
  in cols 1–8 (marginalia merged). Verify visual rhythm doesn't break.
- **Drop cap**: `initial-letter` has limited support outside Safari. Spec covers
  `::first-letter` fallback. Test both paths.
- **Hero variable-font tween perf**: every `pointermove` event recalculating
  `font-variation-settings` could thrash on weak devices. rAF throttling + 240px
  distance threshold should keep it bounded; verify with throttled CPU in DevTools.
- **Lab list maintainability**: labs index is still a hand-coded list. Adding a
  new lab requires editing the page. Out of scope for this redesign — flag for
  future content-collection migration if the list grows past 4–5 entries.

## Acceptance

The redesign is acceptable when all of:

1. Three open-incognito visits to the live site read as: brutalist editorial,
   research-lab serious, not generic AI portfolio
2. Hero on phone fills viewport without horizontal scroll, type renders before
   FCP (no flash of unstyled text from font swap)
3. WCAG AA contrast verified across all colored text combinations (orange never
   used for body-sized text)
4. Touch targets pass 48px audit on nav, buttons, forms, mobile menu
5. Keyboard nav: every interactive element shows `:focus-visible` orange outline
6. Screen reader pass: section markers skipped, headings flow correctly, mobile
   menu announced as disclosure
7. Visual hierarchy is legible at a glance — what's important is obviously important
8. No cards, no parallax, no fade-ins, no italic headings
9. Drop cap renders correctly in both Safari (initial-letter path) and
   Chrome/Firefox (first-letter fallback)
10. Section markers fix-on-scroll in Chrome (scroll-driven path) and remain
    static-but-functional in Firefox (fallback path)
11. Lighthouse mobile: Performance ≥90, Accessibility ≥95
12. `prefers-reduced-motion` honored — no cursor tween, no scroll-driven animation
13. All 13 pages use extracted components (Hero, SectionHead, MetaStrip, etc.) —
    no hand-rolled hero patterns remaining in `.astro` files
