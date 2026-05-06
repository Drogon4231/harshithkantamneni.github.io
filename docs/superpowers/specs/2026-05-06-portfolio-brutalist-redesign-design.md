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

This redesign breaks the mold by going brutalist editorial × research-lab — drama
through type scale, not chrome; one distinctive interaction, not three; mobile-first
fluid scaling.

## Approved decisions

### Color (Option A: Concrete brutalism)

```
--paper:        #E8E5DF   /* cool grey paper, warmer than #FFF, cooler than current beige */
--ink:          #111111   /* near-black, not pure */
--ink-low:      #555555   /* mono labels, secondary text */
--accent:       #FF5722   /* industrial orange — loud enough to be a real signal */
--accent-soft:  rgba(255, 87, 34, 0.12)  /* highlight backgrounds, marks */
--rule:         #111111   /* hairline rules, full opacity */
```

Dark mode flips `--paper` ↔ `--ink`; `--accent` unchanged.

### Typography

| Role | Font | Source |
|---|---|---|
| Display | Bricolage Grotesque (variable, 200–800, optical-size axis) | self-hosted woff2 |
| Body | Newsreader (variable, 200–800, optical-size axis) | self-hosted woff2 |
| Mono | JetBrains Mono (kept) | self-hosted woff2 |

Total font payload target: ≤180KB woff2. Drop the three Google Fonts CSS imports
in `Default.astro` in favor of a single self-hosted `@font-face` set with
`font-display: swap`.

### Type scale

```
hero          clamp(3rem, 14vw, 14rem)    Bricolage 700, leading 0.9, tracking tight
h2            clamp(2rem, 6vw, 5rem)      Bricolage 700, leading 1
h3            clamp(1.25rem, 2vw, 1.75rem)  Bricolage 600
lede          clamp(1.25rem, 2vw, 1.75rem)  Newsreader 400, leading 1.4
body          1.0625rem                    Newsreader 400, leading 1.55, max 65ch
mono-label    11–12px                      JetBrains Mono uppercase, tracking +0.2em
pull-quote    clamp(1.5rem, 3vw, 2.5rem)  Bricolage 600
```

### Hierarchy moves

1. **Extreme scale range.** Hero up to 14rem on desktop, body 1.0625rem. The scale
   jump is the visual signal — no decorative chrome.
2. **Section markers** replace the current `<span class="index-number">` + `<h2>`
   pattern. Format: `001 / THESIS` in JetBrains Mono uppercase, 12px, tracking
   +0.2em, with a hairline rule extending to right edge of viewport.
3. **Drop cap** on first paragraph of long-form posts (reports, multi-paragraph
   notes). 4 lines tall, Bricolage 600.
4. **Pull quotes hang in the margin** (cols 9–12 on desktop). On mobile, full-width
   with 4px orange left rule.
5. **All-caps mono labels** — "ACTIVE 2026", "MADISON, WI", "REPORTS" — used as
   inline metadata, not as headings.

### Layout: asymmetric 12-column grid

```
| 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
  marginalia    main measure (3–9)             pull-quotes
```

- Body prose: cols 3–9, ~65ch
- Pull quotes: cols 9–12, breaking right
- Marginalia (mono dates, footnotes, metadata): cols 1–2
- Mobile: collapses to single column. Marginalia becomes inline mono metadata
  above prose blocks. Pull quotes go full-width with thick left rule.

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
   from 500 → 700 on hero text. Subtle, alive, type-anchored. Disabled under
   `prefers-reduced-motion`.
2. **Section markers**: `position: sticky` + scroll-driven animation. Markers fix
   at viewport top while their section is in view, release on next section. Pure
   CSS, no JS.

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
- Touch targets ≥48px (exceeds 44px floor) on nav, buttons, form fields
- Mobile menu: full-bleed overlay (current `<details>` element kept, restyled).
  Links at `clamp(2rem, 8vw, 3.5rem)` Bricolage 700.
- Section markers stay sticky at top on mobile — they orient you as you scroll

### Theme toggle

- Light/dark stays
- Dark mode: flips paper ↔ ink, accent unchanged
- Toggle button: mono uppercase `LIGHT` / `DARK` text — no sun/moon icon

### Performance budget

- Variable fonts, self-hosted woff2, total ≤180KB
- No client-side framework
- `motion.js` ≤2KB minified
- Astro static output unchanged

## Out of scope

- New pages or new content (this is a layout/visual redesign of existing pages)
- Lab repo (`autonomous-lab-systems`) changes — separate concern
- Newsletter content — Buttondown integration unchanged
- RSS feed — content unchanged, item links unchanged
- Domain or hosting — GitHub Pages stays, base path stays
- JSON-LD, OG meta, sitemap — unchanged

## Files to touch

- `src/styles/tokens.css` — full rewrite (color, type, scale tokens)
- `src/styles/style.css` — full rewrite (component styles)
- `src/layouts/Default.astro` — font loading change (drop Google Fonts, add self-hosted)
- `src/components/Header.astro` — restyle, mobile menu treatment
- `src/components/Footer.astro` — restyle (mono labels, hairline rule)
- `public/motion.js` — shrink to single interaction
- All 13 `src/pages/**/*.astro` — apply new hero pattern, section markers, no cards
- `public/fonts/` — new directory, add Bricolage Grotesque + Newsreader woff2

## Out-of-scope files (untouched)

- `astro.config.mjs`
- `src/pages/rss.xml.js`
- `.github/workflows/deploy.yml`
- `package.json` (no new deps)

## Risk / open questions

- **Self-hosted variable fonts**: need to source Bricolage Grotesque variable woff2
  (Google Fonts download or fontsource). Newsreader available on fontsource.
- **Section marker scroll-driven CSS animation**: needs `@supports` fallback for
  browsers without scroll-driven animation support — falls back to non-sticky markers.
- **Pull quotes in margin**: relies on `position` + grid. On viewport widths between
  60em and 80em, may need to clamp quote to within main column rather than break
  out, to avoid overflow.
- **Drop cap**: CSS `initial-letter` has limited support. Use a manual fallback with
  `::first-letter` styling.

## Acceptance

The redesign is acceptable when:

1. Three open-incognito visits to the live site read as: brutalist editorial,
   research-lab serious, not generic AI portfolio
2. Hero on phone fills viewport without horizontal scroll
3. All touch targets pass 48px audit
4. Visual hierarchy is legible at a glance — what's important is obviously important
5. No cards, no parallax, no fade-ins
6. Lighthouse mobile score ≥90 across performance/accessibility
