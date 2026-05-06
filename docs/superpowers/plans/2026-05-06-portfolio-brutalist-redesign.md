# Portfolio Brutalist Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the current warm-beige Fraunces-serif portfolio with a brutalist editorial system per the spec at `docs/superpowers/specs/2026-05-06-portfolio-brutalist-redesign-design.md`.

**Architecture:** Branch off `main`, build new system additively (tokens + components + fonts) before migrating pages. Foundation in Phase 1, components in Phase 2, page-by-page migration in Phase 3, motion + cleanup in Phase 4, QA + deploy in Phase 5. Each commit produces a buildable site (`npm run build` succeeds at every step).

**Tech Stack:** Astro 5.4.2, vanilla CSS with custom properties, native ES modules in `motion.js`, GitHub Pages deployment.

---

## File map

**New files:**
- `public/fonts/bricolage-grotesque-variable.woff2`
- `public/fonts/newsreader-variable.woff2`
- `public/fonts/jetbrains-mono-variable.woff2`
- `src/components/Hero.astro`
- `src/components/SectionHead.astro`
- `src/components/MetaStrip.astro`
- `src/components/NumberedList.astro`
- `src/components/PullQuote.astro`

**Rewritten:**
- `src/styles/tokens.css`
- `src/styles/style.css`
- `public/motion.js`

**Modified:**
- `src/layouts/Default.astro` — drop Google Fonts CSS imports
- `src/components/Header.astro` — restyle, mono labels, full-bleed mobile menu
- `src/components/Footer.astro` — restyle, hairline rule, mono labels
- All 13 `src/pages/**/*.astro` files

**Untouched:** `astro.config.mjs`, `src/pages/rss.xml.js`, `.github/workflows/deploy.yml`, `package.json`

---

## Phase 1: Foundation

### Task 1: Create branch and verify baseline

**Files:** none modified — branch creation only

- [ ] **Step 1: Branch off main**

```bash
cd /tmp/harshithkantamneni.github.io
git checkout -b brutalist-redesign
```

- [ ] **Step 2: Verify baseline build works before any changes**

```bash
npm install --silent
npm run build
```

Expected: build succeeds, `dist/` populated. If this fails, stop and report — the baseline is broken.

- [ ] **Step 3: Verify dev server starts**

```bash
npm run dev &
sleep 5
curl -s http://localhost:4321/harshithkantamneni.github.io/ | head -5
kill %1
```

Expected: HTML output starts with `<!DOCTYPE html>`. No errors in npm output.

---

### Task 2: Download self-hosted variable fonts

**Files:**
- Create: `public/fonts/bricolage-grotesque-variable.woff2`
- Create: `public/fonts/newsreader-variable.woff2`
- Create: `public/fonts/jetbrains-mono-variable.woff2`

- [ ] **Step 1: Create fonts directory**

```bash
cd /tmp/harshithkantamneni.github.io
mkdir -p public/fonts
```

- [ ] **Step 2: Download Bricolage Grotesque variable woff2 (Latin subset)**

```bash
curl -L -o public/fonts/bricolage-grotesque-variable.woff2 \
  "https://cdn.jsdelivr.net/npm/@fontsource-variable/bricolage-grotesque/files/bricolage-grotesque-latin-wght-normal.woff2"
ls -lh public/fonts/bricolage-grotesque-variable.woff2
```

Expected: file exists, ~80KB. If download fails, try fallback:
```bash
curl -L -o public/fonts/bricolage-grotesque-variable.woff2 \
  "https://cdn.jsdelivr.net/fontsource/fonts/bricolage-grotesque:vf@latest/latin-wght-normal.woff2"
```

- [ ] **Step 3: Download Newsreader variable woff2**

```bash
curl -L -o public/fonts/newsreader-variable.woff2 \
  "https://cdn.jsdelivr.net/npm/@fontsource-variable/newsreader/files/newsreader-latin-wght-normal.woff2"
ls -lh public/fonts/newsreader-variable.woff2
```

Expected: file exists, ~100KB.

- [ ] **Step 4: Download JetBrains Mono variable woff2**

```bash
curl -L -o public/fonts/jetbrains-mono-variable.woff2 \
  "https://cdn.jsdelivr.net/npm/@fontsource-variable/jetbrains-mono/files/jetbrains-mono-latin-wght-normal.woff2"
ls -lh public/fonts/jetbrains-mono-variable.woff2
```

Expected: file exists, ~50KB.

- [ ] **Step 5: Verify total payload under budget**

```bash
du -ch public/fonts/*.woff2 | tail -1
```

Expected: total ≤ 250KB (target ≤180KB; if over budget, flag in commit message and address in QA phase).

- [ ] **Step 6: Verify build still works**

```bash
npm run build
```

Expected: build succeeds (font files are static assets, copied to dist/).

- [ ] **Step 7: Commit**

```bash
git add public/fonts/
git commit -m "feat: add self-hosted variable fonts (bricolage, newsreader, jetbrains mono)"
```

---

### Task 3: Rewrite tokens.css with brutalist system

**Files:**
- Rewrite: `src/styles/tokens.css`

- [ ] **Step 1: Write new tokens.css**

Replace the entire contents of `src/styles/tokens.css` with:

```css
/*
  ============================================================
  Design Tokens — brutalist redesign
  ============================================================
  Type: Bricolage Grotesque (display) + Newsreader (body) + JetBrains Mono
  Color: Concrete brutalism — cool grey paper + ink + industrial orange
  Motion: One distinctive interaction (cursor weight tween on hero)
  ============================================================
*/

/* ==== FONT-FACE (self-hosted variable woff2) ==== */

@font-face {
  font-family: 'Bricolage Grotesque';
  src: url('/harshithkantamneni.github.io/fonts/bricolage-grotesque-variable.woff2') format('woff2-variations');
  font-weight: 200 800;
  font-display: swap;
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215;
}

@font-face {
  font-family: 'Newsreader';
  src: url('/harshithkantamneni.github.io/fonts/newsreader-variable.woff2') format('woff2-variations');
  font-weight: 200 800;
  font-display: swap;
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215;
}

@font-face {
  font-family: 'JetBrains Mono';
  src: url('/harshithkantamneni.github.io/fonts/jetbrains-mono-variable.woff2') format('woff2-variations');
  font-weight: 100 800;
  font-display: swap;
  unicode-range: U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+2000-206F, U+2074, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215;
}

/* ==== TYPE ROLES ==== */
:root {
  --font-display: 'Bricolage Grotesque', system-ui, sans-serif;
  --font-body:    'Newsreader', Georgia, serif;
  --font-mono:    'JetBrains Mono', Menlo, Consolas, monospace;
}

/* ==== COLOR (light mode default — Concrete brutalism Option A) ==== */
:root,
:root[data-theme="light"] {
  --paper:        #E8E5DF;
  --ink:          #111111;
  --ink-low:      #555555;
  --accent:       #FF5722;
  --accent-deep:  #C8401B;
  --accent-soft:  rgba(255, 87, 34, 0.12);
  --rule:         #111111;
  --link:         var(--accent-deep);
}

/* ==== COLOR (dark mode) ==== */
:root[data-theme="dark"] {
  --paper:        #111111;
  --ink:          #E8E5DF;
  --ink-low:      #999999;
  --accent:       #FF5722;
  --accent-deep:  #FF7A56;
  --accent-soft:  rgba(255, 87, 34, 0.18);
  --rule:         #E8E5DF;
  --link:         var(--accent);
}

/* ==== TYPE SCALE ==== */
:root {
  --fs-hero:       clamp(3rem, 14vw, 14rem);
  --fs-h2:         clamp(2rem, 6vw, 5rem);
  --fs-h3:         clamp(1.25rem, 2vw, 1.75rem);
  --fs-lede:       clamp(1.25rem, 2vw, 1.75rem);
  --fs-body:       1.0625rem;
  --fs-small:      0.9375rem;
  --fs-mono:       0.75rem;       /* 12px */
  --fs-mono-tiny:  0.6875rem;     /* 11px */
  --fs-pull:       clamp(1.5rem, 3vw, 2.5rem);

  --lh-hero:       0.9;
  --lh-heading:    1.0;
  --lh-pull:       1.15;
  --lh-lede:       1.4;
  --lh-body:       1.55;

  --tracking-tight:  -0.02em;
  --tracking-snug:   -0.01em;
  --tracking-normal: 0;
  --tracking-wide:   0.2em;
}

/* ==== SPACING ==== */
:root {
  --space-1:  0.25rem;
  --space-2:  0.5rem;
  --space-3:  1rem;
  --space-4:  1.5rem;
  --space-5:  2.5rem;
  --space-6:  4rem;
  --space-7:  6rem;
  --space-8:  10rem;
}

/* ==== RULES ==== */
:root {
  --rule-thin:    1px;
  --rule-medium:  2px;
  --rule-thick:   4px;
}

/* ==== MEASURE (line length) ==== */
:root {
  --measure-tight:    58ch;   /* default body */
  --measure-loose:    72ch;   /* extended body */
  --measure-narrow:   42ch;   /* lede, hero subheads */
}

/* ==== GRID ==== */
:root {
  --grid-cols:    12;
  --grid-gap:     1.5rem;
  --grid-max:     90rem;      /* full-bleed cap */
}

/* ==== MOTION ==== */
:root {
  --ease:           cubic-bezier(0.32, 0.72, 0, 1);
  --duration-fast:  150ms;
  --duration:       300ms;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

- [ ] **Step 2: Verify build succeeds**

```bash
npm run build 2>&1 | tail -10
```

Expected: build succeeds. CSS validation may show warnings about old token names referenced in `style.css` — that's expected, will be fixed in Task 4.

- [ ] **Step 3: Commit**

```bash
git add src/styles/tokens.css
git commit -m "feat(tokens): brutalist color, type, spacing system"
```

---

### Task 4: Rewrite style.css with brutalist component styles

**Files:**
- Rewrite: `src/styles/style.css`

- [ ] **Step 1: Write new style.css**

Replace the entire contents of `src/styles/style.css` with:

```css
/*
  ============================================================
  Brutalist component styles
  ============================================================
*/

/* ==== RESET (minimal) ==== */
*, *::before, *::after { box-sizing: border-box; }

html {
  -webkit-text-size-adjust: 100%;
  text-size-adjust: 100%;
  scroll-behavior: smooth;
}

body {
  margin: 0;
  background: var(--paper);
  color: var(--ink);
  font-family: var(--font-body);
  font-size: var(--fs-body);
  line-height: var(--lh-body);
  font-feature-settings: 'kern' 1, 'liga' 1;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

img, svg { display: block; max-width: 100%; }

button { font: inherit; cursor: pointer; }

/* ==== FOCUS ==== */
:focus { outline: none; }
:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 3px;
  border-radius: 0;
}

/* ==== TYPOGRAPHY ==== */
h1, h2, h3, h4, h5, h6 {
  font-family: var(--font-display);
  font-weight: 700;
  margin: 0;
  color: var(--ink);
}

h1 {
  font-size: var(--fs-hero);
  line-height: var(--lh-hero);
  letter-spacing: var(--tracking-tight);
  font-weight: 700;
}

h2 {
  font-size: var(--fs-h2);
  line-height: var(--lh-heading);
  letter-spacing: var(--tracking-snug);
}

h3 {
  font-size: var(--fs-h3);
  font-weight: 600;
  line-height: 1.2;
}

p { margin: 0 0 var(--space-3) 0; }

a {
  color: var(--link);
  text-decoration: underline;
  text-underline-offset: 0.15em;
  text-decoration-thickness: 1px;
}

a:hover { text-decoration-thickness: 2px; }

/* ==== LAYOUT (12-column asymmetric grid) ==== */
.page-grid {
  display: grid;
  grid-template-columns: repeat(var(--grid-cols), 1fr);
  gap: 0 var(--grid-gap);
  max-width: var(--grid-max);
  margin: 0 auto;
  padding: 0 var(--space-4);
}

.page-grid > * {
  grid-column: 3 / span 6;   /* default body: cols 3-8 */
}

.page-grid > .full-bleed {
  grid-column: 1 / -1;       /* hero, hairline rules */
}

.page-grid > .extended {
  grid-column: 3 / span 8;   /* cols 3-10 */
}

.page-grid > .marginalia {
  grid-column: 1 / span 2;
  font-family: var(--font-mono);
  font-size: var(--fs-mono);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  color: var(--ink-low);
}

@media (max-width: 60em) {
  .page-grid > * { grid-column: 1 / -1; }
  .page-grid { padding: 0 var(--space-3); }
}

/* ==== MEASURE HELPERS ==== */
.measure-tight  { max-width: var(--measure-tight);  }
.measure-loose  { max-width: var(--measure-loose);  }
.measure-narrow { max-width: var(--measure-narrow); }

/* ==== HAIRLINE RULES ==== */
.hairline {
  border: 0;
  border-top: var(--rule-thin) solid var(--rule);
  margin: var(--space-5) 0;
}

.hairline-thick {
  border: 0;
  border-top: var(--rule-thick) solid var(--rule);
  margin: var(--space-6) 0;
}

/* ==== MAIN ==== */
main {
  display: block;
  padding: var(--space-6) 0 var(--space-8);
}

@media (max-width: 60em) {
  main { padding: var(--space-5) 0 var(--space-7); }
}

/* ==== DROP CAP ==== */
.drop-cap::first-letter {
  font-family: var(--font-display);
  font-weight: 600;
  float: left;
  font-size: 4.5em;
  line-height: 0.85;
  padding-right: 0.08em;
  padding-top: 0.05em;
}

@supports (initial-letter: 4) {
  .drop-cap::first-letter {
    initial-letter: 4;
    float: none;
    font-size: inherit;
    padding: 0;
  }
}

/* ==== PULL QUOTE ==== */
.pull-quote {
  font-family: var(--font-display);
  font-weight: 600;
  font-size: var(--fs-pull);
  line-height: var(--lh-pull);
  letter-spacing: var(--tracking-snug);
  margin: var(--space-5) 0;
  padding: 0 0 0 var(--space-3);
  border-left: var(--rule-thick) solid var(--accent);
}

@media (min-width: 80em) {
  .page-grid > .pull-quote {
    grid-column: 9 / span 4;
    grid-row: span 1;
    border-left: 0;
    padding: 0;
  }
}

/* ==== SECTION HEAD ==== */
.section-head {
  display: block;
  margin: var(--space-7) 0 var(--space-4);
  padding-top: var(--space-3);
  border-top: var(--rule-thin) solid var(--rule);
  position: sticky;
  top: 0;
  background: var(--paper);
  z-index: 10;
}

.section-marker {
  font-family: var(--font-mono);
  font-size: var(--fs-mono);
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  color: var(--ink-low);
  margin: 0 0 var(--space-2) 0;
}

@supports (animation-timeline: view()) {
  .section-head {
    animation: section-marker-emphasis linear;
    animation-timeline: view();
    animation-range: entry 0% entry 30%;
  }

  @keyframes section-marker-emphasis {
    from { opacity: 0.6; }
    to   { opacity: 1.0; }
  }
}

/* ==== HERO META STRIP ==== */
.meta-strip {
  font-family: var(--font-mono);
  font-size: var(--fs-mono);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  color: var(--ink-low);
  margin-top: var(--space-4);
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2) var(--space-3);
}

.meta-strip > * + *::before {
  content: '·';
  margin-right: var(--space-3);
  color: var(--ink-low);
}

/* ==== NUMBERED LIST ==== */
.numbered-list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.numbered-list > li {
  display: grid;
  grid-template-columns: 4ch 1fr;
  gap: var(--space-4);
  padding: var(--space-4) 0;
  border-bottom: var(--rule-thin) solid var(--rule);
  min-height: 48px;
}

.numbered-list > li:first-child {
  border-top: var(--rule-thin) solid var(--rule);
}

.numbered-list .num {
  font-family: var(--font-mono);
  font-size: var(--fs-mono);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  color: var(--ink-low);
  padding-top: 0.4em;
}

.numbered-list h3 { margin: 0 0 var(--space-2); }

.numbered-list p { margin: 0 0 var(--space-2); max-width: var(--measure-tight); }

/* ==== WRITING LIST (reports + notes) ==== */
.writing-list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.writing-list > li {
  display: grid;
  grid-template-columns: 6em 1fr 5em;
  gap: var(--space-3);
  align-items: baseline;
  padding: var(--space-4) 0;
  border-bottom: var(--rule-thin) solid var(--rule);
  min-height: 48px;
}

.writing-list > li:first-child {
  border-top: var(--rule-thin) solid var(--rule);
}

.writing-list .date,
.writing-list .length {
  font-family: var(--font-mono);
  font-size: var(--fs-mono);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  color: var(--ink-low);
}

.writing-list .length { text-align: right; }

.writing-list .title {
  font-family: var(--font-display);
  font-weight: 600;
  font-size: var(--fs-h3);
  color: var(--ink);
  text-decoration: none;
  line-height: 1.2;
}

.writing-list .title:hover {
  color: var(--accent-deep);
}

@media (max-width: 60em) {
  .writing-list > li {
    grid-template-columns: 1fr;
    gap: var(--space-1);
  }
  .writing-list .length { text-align: left; }
}

/* ==== CONTACT TABLE ==== */
.channel-table {
  display: grid;
  grid-template-columns: 16em 1fr;
  gap: var(--space-5);
  margin: var(--space-5) 0;
}

.channel-table > div {
  padding: var(--space-4) 0;
  border-bottom: var(--rule-thin) solid var(--rule);
}

.channel-table > div:nth-child(-n+2) {
  border-top: var(--rule-thin) solid var(--rule);
}

.channel-table .channel-meta {
  font-family: var(--font-mono);
  font-size: var(--fs-mono);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  color: var(--ink-low);
}

.channel-table .channel-meta a { color: var(--ink); }

@media (max-width: 60em) {
  .channel-table { grid-template-columns: 1fr; gap: var(--space-1); }
  .channel-table > div { padding: var(--space-3) 0; }
  .channel-table > div:nth-child(2),
  .channel-table > div:nth-child(4),
  .channel-table > div:nth-child(6),
  .channel-table > div:nth-child(8) {
    border-top: 0;
    padding-top: 0;
    margin-bottom: var(--space-3);
  }
}

/* ==== NEWSLETTER FORM ==== */
.newsletter-form {
  display: flex;
  gap: 0;
  margin: var(--space-3) 0;
  border: var(--rule-medium) solid var(--rule);
  max-width: 32rem;
}

.newsletter-form input[type="email"] {
  flex: 1;
  font: inherit;
  font-size: var(--fs-body);
  padding: var(--space-3);
  border: 0;
  background: var(--paper);
  color: var(--ink);
  min-height: 48px;
}

.newsletter-form button {
  font-family: var(--font-mono);
  font-size: var(--fs-mono);
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  padding: var(--space-3) var(--space-4);
  background: var(--accent);
  color: var(--ink);
  border: 0;
  border-left: var(--rule-medium) solid var(--rule);
  min-height: 48px;
  min-width: 48px;
}

.newsletter-form button:hover { background: var(--accent-deep); color: var(--paper); }

/* ==== TIMELINE (now page) ==== */
.timeline {
  display: grid;
  grid-template-columns: 8em 1fr;
  gap: var(--space-4);
}

.timeline-date {
  font-family: var(--font-mono);
  font-size: var(--fs-mono);
  text-transform: uppercase;
  letter-spacing: var(--tracking-wide);
  color: var(--ink-low);
  padding-top: 0.4em;
}

.timeline-entry {
  padding-bottom: var(--space-5);
  border-left: var(--rule-thin) solid var(--rule);
  padding-left: var(--space-4);
  margin-left: -1px;
}

@media (max-width: 60em) {
  .timeline { grid-template-columns: 1fr; gap: var(--space-1); }
  .timeline-entry { border-left: 0; padding-left: 0; }
}

/* ==== HEADER + FOOTER (component-level styles in their .astro files) ==== */
/* (See Header.astro and Footer.astro) */
```

- [ ] **Step 2: Verify build succeeds**

```bash
npm run build 2>&1 | tail -10
```

Expected: build succeeds. Old class names referenced in pages (`.card`, `.hero`, `.lede`, `.container`) no longer exist as defined styles. Pages will render with default browser styles + new typography until pages are migrated.

- [ ] **Step 3: Visual smoke check**

```bash
npm run dev &
sleep 5
curl -s http://localhost:4321/harshithkantamneni.github.io/ -o /tmp/index-mid-migration.html
ls -lh /tmp/index-mid-migration.html
kill %1
```

Expected: HTML output exists; pages render (visually broken, but no JS or build errors).

- [ ] **Step 4: Commit**

```bash
git add src/styles/style.css
git commit -m "feat(styles): brutalist component CSS, grid, drop cap, section markers"
```

---

### Task 5: Update Default.astro to drop Google Fonts

**Files:**
- Modify: `src/layouts/Default.astro`

- [ ] **Step 1: Read current Default.astro**

```bash
cat src/layouts/Default.astro
```

Note the three `<link>` tags loading Google Fonts (Fraunces, JetBrains Mono, General Sans).

- [ ] **Step 2: Remove Google Fonts links**

In `src/layouts/Default.astro`, delete these four lines (the preconnect + the two font CSS imports):

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preconnect" href="https://api.fontshare.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght,SOFT,WONK@0,9..144,400..700,30..100,0..1;1,9..144,400..700,30..100,0..1&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
<link href="https://api.fontshare.com/v2/css?f[]=general-sans@400,500,600,700&display=swap" rel="stylesheet">
```

The `@font-face` declarations in `tokens.css` (loaded via `import '../styles/style.css'` which imports tokens) handle font loading.

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/layouts/Default.astro
git commit -m "feat(layout): drop Google Fonts CSS imports, use self-hosted variables"
```

---

## Phase 2: Components

### Task 6: Create Hero.astro component

**Files:**
- Create: `src/components/Hero.astro`

- [ ] **Step 1: Write Hero.astro**

```astro
---
interface Props {
  marker: string;       /* e.g. "001 / THESIS" */
  meta?: string[];      /* e.g. ["Active 2026", "Madison, WI", "2 labs"] */
}

const { marker, meta = [] } = Astro.props;
---
<section class="hero full-bleed" data-hero>
  <p class="section-marker">{marker}</p>
  <h1 class="hero-headline"><slot /></h1>
  {meta.length > 0 && (
    <div class="meta-strip">
      {meta.map(item => <span>{item}</span>)}
    </div>
  )}
</section>

<style>
  .hero {
    padding: var(--space-7) var(--space-4) var(--space-6);
    max-width: var(--grid-max);
    margin: 0 auto;
  }

  .hero-headline {
    font-size: var(--fs-hero);
    line-height: var(--lh-hero);
    letter-spacing: var(--tracking-tight);
    font-weight: 700;
    font-variation-settings: "wght" 700;
    margin: var(--space-3) 0 0 0;
    transition: font-variation-settings var(--duration-fast) var(--ease);
  }

  .section-marker {
    font-family: var(--font-mono);
    font-size: var(--fs-mono);
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: var(--tracking-wide);
    color: var(--ink-low);
    margin: 0;
  }

  @media (max-width: 60em) {
    .hero { padding: var(--space-5) var(--space-3) var(--space-5); }
  }
</style>
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds (component is unused, doesn't affect any page).

- [ ] **Step 3: Commit**

```bash
git add src/components/Hero.astro
git commit -m "feat(components): Hero with mono marker + headline + meta strip"
```

---

### Task 7: Create SectionHead.astro component

**Files:**
- Create: `src/components/SectionHead.astro`

- [ ] **Step 1: Write SectionHead.astro**

```astro
---
interface Props {
  marker: string;       /* e.g. "002 / LABS" */
  title: string;
  level?: 2 | 3;
}

const { marker, title, level = 2 } = Astro.props;
const Heading = `h${level}` as 'h2' | 'h3';
---
<header class="section-head full-bleed">
  <p class="section-marker" aria-hidden="true">{marker}</p>
  <Heading>{title}</Heading>
</header>

<style>
  .section-head {
    margin: var(--space-7) auto var(--space-4);
    padding: var(--space-3) var(--space-4) 0;
    max-width: var(--grid-max);
    border-top: var(--rule-thin) solid var(--rule);
    position: sticky;
    top: 0;
    background: var(--paper);
    z-index: 10;
  }

  .section-head h2,
  .section-head h3 {
    margin: var(--space-2) 0 var(--space-4) 0;
  }

  .section-marker {
    font-family: var(--font-mono);
    font-size: var(--fs-mono);
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: var(--tracking-wide);
    color: var(--ink-low);
    margin: 0;
  }

  @supports (animation-timeline: view()) {
    .section-head {
      animation: section-emphasis linear;
      animation-timeline: view();
      animation-range: entry 0% entry 30%;
    }

    @keyframes section-emphasis {
      from { opacity: 0.55; }
      to   { opacity: 1.0; }
    }
  }

  @media (max-width: 60em) {
    .section-head { padding: var(--space-3) var(--space-3) 0; margin-top: var(--space-6); }
  }
</style>
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add src/components/SectionHead.astro
git commit -m "feat(components): SectionHead with sticky scroll-driven marker"
```

---

### Task 8: Create MetaStrip.astro component

**Files:**
- Create: `src/components/MetaStrip.astro`

- [ ] **Step 1: Write MetaStrip.astro**

```astro
---
interface Props {
  items: string[];
}

const { items } = Astro.props;
---
<div class="meta-strip">
  {items.map(item => <span>{item}</span>)}
</div>

<style>
  .meta-strip {
    font-family: var(--font-mono);
    font-size: var(--fs-mono);
    text-transform: uppercase;
    letter-spacing: var(--tracking-wide);
    color: var(--ink-low);
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-2) var(--space-3);
    margin: var(--space-3) 0;
  }

  .meta-strip > * + *::before {
    content: '·';
    margin-right: var(--space-3);
    color: var(--ink-low);
  }
</style>
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add src/components/MetaStrip.astro
git commit -m "feat(components): MetaStrip dot-separated mono row"
```

---

### Task 9: Create NumberedList.astro component

**Files:**
- Create: `src/components/NumberedList.astro`

- [ ] **Step 1: Write NumberedList.astro**

```astro
---
/* Slot-driven numbered list. Pass <li> children with .num + content blocks. */
---
<ol class="numbered-list">
  <slot />
</ol>

<style>
  .numbered-list {
    list-style: none;
    margin: 0;
    padding: 0;
  }
</style>
```

A consumer of this component writes:

```astro
<NumberedList>
  <li>
    <span class="num">01</span>
    <div>
      <h3><a href="...">HIVE / Product Lab</a></h3>
      <p>Description...</p>
      <p class="meta-strip"><span>Active 2026</span><span>~46 agents</span></p>
    </div>
  </li>
</NumberedList>
```

The `.numbered-list > li` styles come from `style.css` (already defined in Task 4).

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add src/components/NumberedList.astro
git commit -m "feat(components): NumberedList wrapper for hairline-separated entries"
```

---

### Task 10: Create PullQuote.astro component

**Files:**
- Create: `src/components/PullQuote.astro`

- [ ] **Step 1: Write PullQuote.astro**

```astro
---
interface Props {
  attribution?: string;
}

const { attribution } = Astro.props;
---
<aside class="pull-quote">
  <p><slot /></p>
  {attribution && <cite>{attribution}</cite>}
</aside>

<style>
  .pull-quote {
    font-family: var(--font-display);
    font-weight: 600;
    font-size: var(--fs-pull);
    line-height: var(--lh-pull);
    letter-spacing: var(--tracking-snug);
    margin: var(--space-5) 0;
    padding: 0 0 0 var(--space-3);
    border-left: var(--rule-thick) solid var(--accent);
  }

  .pull-quote p { margin: 0; }

  .pull-quote cite {
    display: block;
    margin-top: var(--space-2);
    font-family: var(--font-mono);
    font-size: var(--fs-mono);
    font-style: normal;
    text-transform: uppercase;
    letter-spacing: var(--tracking-wide);
    color: var(--ink-low);
  }

  @media (min-width: 80em) {
    .pull-quote {
      border-left: 0;
      padding: 0;
    }
  }
</style>
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add src/components/PullQuote.astro
git commit -m "feat(components): PullQuote with margin breakout on wide screens"
```

---

## Phase 3: Layout components

### Task 11: Restyle Header.astro

**Files:**
- Modify: `src/components/Header.astro`

- [ ] **Step 1: Read current Header.astro**

```bash
cat src/components/Header.astro
```

- [ ] **Step 2: Replace contents**

Write to `src/components/Header.astro`:

```astro
---
interface Props {
  current?: string;
}

const { current = '' } = Astro.props;
const base = '/harshithkantamneni.github.io';
const links = [
  { href: `${base}/`,         label: 'INDEX',   key: '' },
  { href: `${base}/about`,    label: 'ABOUT',   key: 'about' },
  { href: `${base}/labs`,     label: 'LABS',    key: 'labs' },
  { href: `${base}/reports`,  label: 'REPORTS', key: 'reports' },
  { href: `${base}/notes`,    label: 'NOTES',   key: 'notes' },
  { href: `${base}/now`,      label: 'NOW',     key: 'now' },
  { href: `${base}/contact`,  label: 'CONTACT', key: 'contact' },
];
---
<header class="site-header">
  <a href={`${base}/`} class="brand">HK</a>

  <nav class="nav-desktop" aria-label="Primary">
    {links.map(link => (
      <a
        href={link.href}
        class:list={['nav-link', { current: link.key === current }]}
      >{link.label}</a>
    ))}
  </nav>

  <button class="theme-toggle" type="button" aria-label="Toggle dark mode" data-theme-toggle>
    <span data-theme-label="light">DARK</span>
    <span data-theme-label="dark" hidden>LIGHT</span>
  </button>

  <details class="nav-mobile">
    <summary aria-label="Open menu">MENU</summary>
    <div class="nav-mobile-links">
      {links.map(link => (
        <a href={link.href} class:list={['nav-mobile-link', { current: link.key === current }]}>
          {link.label}
        </a>
      ))}
    </div>
  </details>
</header>

<style>
  .site-header {
    display: grid;
    grid-template-columns: auto 1fr auto auto;
    gap: var(--space-4);
    align-items: center;
    padding: var(--space-3) var(--space-4);
    border-bottom: var(--rule-thin) solid var(--rule);
    background: var(--paper);
    position: sticky;
    top: 0;
    z-index: 50;
    max-width: var(--grid-max);
    margin: 0 auto;
  }

  .brand {
    font-family: var(--font-display);
    font-weight: 700;
    font-size: 1.25rem;
    letter-spacing: var(--tracking-snug);
    color: var(--ink);
    text-decoration: none;
    min-height: 48px;
    display: inline-flex;
    align-items: center;
  }

  .nav-desktop {
    display: flex;
    gap: var(--space-4);
    justify-content: center;
  }

  .nav-link {
    font-family: var(--font-mono);
    font-size: var(--fs-mono);
    font-weight: 500;
    text-transform: uppercase;
    letter-spacing: var(--tracking-wide);
    color: var(--ink-low);
    text-decoration: none;
    padding: 0.75rem 0;
    min-height: 48px;
    display: inline-flex;
    align-items: center;
    border-bottom: 2px solid transparent;
  }

  .nav-link:hover { color: var(--ink); }
  .nav-link.current { color: var(--ink); border-bottom-color: var(--accent); }

  .theme-toggle {
    font-family: var(--font-mono);
    font-size: var(--fs-mono);
    text-transform: uppercase;
    letter-spacing: var(--tracking-wide);
    background: none;
    color: var(--ink-low);
    border: 1px solid var(--rule);
    padding: 0 var(--space-3);
    min-height: 48px;
    min-width: 48px;
  }

  .theme-toggle:hover { color: var(--ink); border-color: var(--accent); }

  .nav-mobile { display: none; }

  @media (max-width: 60em) {
    .site-header { grid-template-columns: auto 1fr auto; padding: var(--space-3); }
    .nav-desktop { display: none; }
    .nav-mobile { display: block; }

    .nav-mobile summary {
      font-family: var(--font-mono);
      font-size: var(--fs-mono);
      text-transform: uppercase;
      letter-spacing: var(--tracking-wide);
      color: var(--ink-low);
      list-style: none;
      cursor: pointer;
      padding: 0 var(--space-3);
      min-height: 48px;
      min-width: 48px;
      display: inline-flex;
      align-items: center;
      border: 1px solid var(--rule);
    }

    .nav-mobile summary::-webkit-details-marker { display: none; }
    .nav-mobile[open] summary { color: var(--ink); border-color: var(--accent); }

    .nav-mobile-links {
      position: fixed;
      inset: 0;
      top: auto;
      background: var(--paper);
      padding: var(--space-7) var(--space-4) var(--space-6);
      display: flex;
      flex-direction: column;
      gap: 0;
      z-index: 40;
      height: calc(100vh - var(--space-7));
      overflow-y: auto;
    }

    .nav-mobile[open] .nav-mobile-links {
      position: fixed;
      top: 60px;
    }

    .nav-mobile-link {
      font-family: var(--font-display);
      font-weight: 700;
      font-size: clamp(2rem, 8vw, 3.5rem);
      color: var(--ink);
      text-decoration: none;
      padding: var(--space-3) 0;
      border-bottom: var(--rule-thin) solid var(--rule);
      letter-spacing: var(--tracking-snug);
    }

    .nav-mobile-link.current { color: var(--accent-deep); }
  }
</style>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/components/Header.astro
git commit -m "feat(header): brutalist nav with mono labels and full-bleed mobile menu"
```

---

### Task 12: Restyle Footer.astro

**Files:**
- Modify: `src/components/Footer.astro`

- [ ] **Step 1: Read current Footer.astro**

```bash
cat src/components/Footer.astro
```

- [ ] **Step 2: Replace contents**

Write to `src/components/Footer.astro`:

```astro
---
const base = '/harshithkantamneni.github.io';
const year = new Date().getFullYear();
---
<footer class="site-footer">
  <hr class="hairline" />

  <div class="footer-grid">
    <div>
      <p class="footer-meta">HARSHITH KANTAMNENI · MADISON, WI · {year}</p>
    </div>

    <nav class="footer-nav" aria-label="Secondary">
      <a href="mailto:kantamneniharshith@gmail.com">EMAIL</a>
      <a href="https://github.com/Drogon4231">GITHUB</a>
      <a href="https://www.linkedin.com/in/hk4231">LINKEDIN</a>
      <a href={`${base}/rss.xml`}>RSS</a>
    </nav>
  </div>
</footer>

<style>
  .site-footer {
    max-width: var(--grid-max);
    margin: var(--space-8) auto 0;
    padding: 0 var(--space-4) var(--space-5);
  }

  .hairline {
    border: 0;
    border-top: var(--rule-thin) solid var(--rule);
    margin: 0 0 var(--space-4);
  }

  .footer-grid {
    display: flex;
    justify-content: space-between;
    align-items: baseline;
    flex-wrap: wrap;
    gap: var(--space-4);
  }

  .footer-meta {
    font-family: var(--font-mono);
    font-size: var(--fs-mono);
    text-transform: uppercase;
    letter-spacing: var(--tracking-wide);
    color: var(--ink-low);
    margin: 0;
  }

  .footer-nav {
    display: flex;
    gap: var(--space-4);
    flex-wrap: wrap;
  }

  .footer-nav a {
    font-family: var(--font-mono);
    font-size: var(--fs-mono);
    text-transform: uppercase;
    letter-spacing: var(--tracking-wide);
    color: var(--ink);
    text-decoration: none;
    min-height: 48px;
    display: inline-flex;
    align-items: center;
  }

  .footer-nav a:hover { color: var(--accent-deep); }

  @media (max-width: 60em) {
    .site-footer { padding: 0 var(--space-3) var(--space-5); margin-top: var(--space-7); }
    .footer-grid { flex-direction: column; gap: var(--space-3); }
  }
</style>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/components/Footer.astro
git commit -m "feat(footer): mono labels, hairline rule, simplified link row"
```

---

## Phase 4: Page migration

For every page-migration task, the steps are:
1. Read current page
2. Rewrite using new components
3. Build verification
4. Dev-server smoke check
5. Commit

The shape of the rewrite varies per page; the template structure is consistent.

### Task 13: Migrate index.astro

**Files:**
- Modify: `src/pages/index.astro`

- [ ] **Step 1: Read current index.astro**

```bash
cat src/pages/index.astro
```

- [ ] **Step 2: Rewrite index.astro**

Replace contents of `src/pages/index.astro` with:

```astro
---
import Default from '../layouts/Default.astro';
import Hero from '../components/Hero.astro';
import SectionHead from '../components/SectionHead.astro';
import NumberedList from '../components/NumberedList.astro';

const base = '/harshithkantamneni.github.io';

const labs = [
  {
    num: '01',
    href: `${base}/labs/hive`,
    name: 'HIVE / Product Lab',
    desc: 'Autonomous Claude lab building shippable iOS products end-to-end. Director + ~46 specialists, three-tier markdown memory, byte-identical builds.',
    meta: ['Active 2026', '~46 agents', 'Phase 2'],
  },
  {
    num: '02',
    href: `${base}/labs/autonomous-research`,
    name: 'Autonomous Research Lab',
    desc: 'Multi-agent research lab investigating verification-depth principles, same-family judge bias, and recursive verification-surface collapse.',
    meta: ['Active 2026', '~31–73 agents', 'Methodology'],
  },
];
---
<Default title="Harshith Kantamneni" description="I design and run autonomous AI labs. Reports, notes, and operating decisions." current="">

  <Hero
    marker="000 / INDEX"
    meta={['Active 2026', 'Madison, WI', '2 labs']}
  >
    I design and run<br />autonomous AI labs.
  </Hero>

  <div class="page-grid">
    <p class="extended measure-loose" style="font-size: var(--fs-lede); line-height: var(--lh-lede); margin-top: var(--space-6);">
      The site is a publication, not a portfolio. Methodology pieces, system reports,
      and operating decisions from two parallel autonomous labs.
    </p>
  </div>

  <SectionHead marker="001 / LABS" title="Labs" />

  <div class="page-grid">
    <div class="extended">
      <NumberedList>
        {labs.map(lab => (
          <li>
            <span class="num">{lab.num}</span>
            <div>
              <h3><a href={lab.href}>{lab.name}</a></h3>
              <p>{lab.desc}</p>
              <p class="meta-strip">
                {lab.meta.map(m => <span>{m}</span>)}
              </p>
            </div>
          </li>
        ))}
      </NumberedList>
    </div>
  </div>

  <SectionHead marker="002 / WRITING" title="Recent" />

  <div class="page-grid">
    <ul class="writing-list extended">
      <li>
        <span class="date">May 15</span>
        <a href={`${base}/reports/recursive-verification-surface-collapse`} class="title">Recursive Verification-Surface Collapse</a>
        <span class="length">~3,200w</span>
      </li>
      <li>
        <span class="date">May 05</span>
        <a href={`${base}/notes/byte-identical-builds`} class="title">Twelve cycles of byte-identical builds</a>
        <span class="length">~600w</span>
      </li>
      <li>
        <span class="date">May 03</span>
        <a href={`${base}/notes/tier-per-task`} class="title">Tier dispatchers per task, not per role</a>
        <span class="length">~500w</span>
      </li>
      <li>
        <span class="date">May 02</span>
        <a href={`${base}/notes/llm-judge-bias`} class="title">Same-family LLM judge bias is real</a>
        <span class="length">~700w</span>
      </li>
    </ul>
  </div>

  <SectionHead marker="003 / SUBSCRIBE" title="Monthly digest" id="subscribe" />

  <div class="page-grid">
    <div class="extended measure-loose">
      <p>One email per month. Best reports, notable observations, lessons from running the labs. Around 5 minute read. No upsell. Unsubscribe anytime.</p>
      <form action="https://buttondown.com/api/emails/embed-subscribe/harshith" method="post" target="popupwindow" class="newsletter-form">
        <input type="email" name="email" placeholder="you@example.com" required>
        <button type="submit">Subscribe</button>
      </form>
    </div>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Dev-server smoke check**

```bash
npm run dev &
sleep 5
curl -s http://localhost:4321/harshithkantamneni.github.io/ -o /tmp/index-new.html
test -s /tmp/index-new.html && echo "OK: HTML rendered"
kill %1
```

Expected: "OK: HTML rendered". File contains hero text and section markers.

- [ ] **Step 5: Commit**

```bash
git add src/pages/index.astro
git commit -m "feat(pages): migrate index to brutalist components"
```

---

### Task 14: Migrate about.astro

**Files:**
- Modify: `src/pages/about.astro`

- [ ] **Step 1: Read current about.astro**

```bash
cat src/pages/about.astro
```

- [ ] **Step 2: Rewrite about.astro**

Replace contents of `src/pages/about.astro` with:

```astro
---
import Default from '../layouts/Default.astro';
import Hero from '../components/Hero.astro';
import SectionHead from '../components/SectionHead.astro';
---
<Default title="About · Harshith Kantamneni" description="GPU systems engineer building autonomous AI labs." current="about">

  <Hero
    marker="010 / ABOUT"
    meta={['GPU systems', 'Autonomous labs', 'Madison, WI']}
  >
    GPU work by day,<br />autonomous labs by night.
  </Hero>

  <SectionHead marker="011 / WORK" title="What I do" />

  <div class="page-grid">
    <div class="extended measure-tight drop-cap">
      <p>I work at the intersection of GPU systems engineering and autonomous AI lab design. Day work is performance-tuning, kernel optimization, and the unglamorous parts of making models actually run on hardware. Night work is running multi-agent labs that try to ship engineering output without me in the loop, and writing about what breaks.</p>
      <p>The two halves inform each other. GPU work teaches you that abstractions leak — the spec says one thing, the silicon does another, and the gap is where bugs live. Lab work teaches you the same lesson at a different level: agents pass their own tests while quietly breaking, the verification surface collapses, the system optimizes for the proxy instead of the goal.</p>
      <p>Both are exercises in not trusting yourself.</p>
    </div>
  </div>

  <SectionHead marker="012 / FOCUS" title="Current focus" />

  <div class="page-grid">
    <div class="extended measure-tight">
      <p>Through 2026, the focus is verification depth in autonomous engineering systems. The premise: most multi-agent labs collapse because they grade themselves, and self-grading creates a flat verification surface that any sufficiently capable optimizer can climb without solving the underlying problem.</p>
      <p>The work is figuring out which structural principles actually disrupt this — external verdicts, pre-registered falsifiers, adversarial payoffs — and which are ceremonial.</p>
    </div>
  </div>

  <SectionHead marker="013 / BACKGROUND" title="Background" />

  <div class="page-grid">
    <div class="extended measure-tight">
      <p>UW–Madison alum. Former GPU work at NVIDIA on the inference performance side. Independent since 2026. Currently running two autonomous AI labs in parallel as the primary research vehicle.</p>
      <p>The labs are not affiliated with UW–Madison or any prior employer. No university resources, IP, or infrastructure are used in this work.</p>
    </div>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/about.astro
git commit -m "feat(pages): migrate about to brutalist components"
```

---

### Task 15: Migrate now.astro

**Files:**
- Modify: `src/pages/now.astro`

- [ ] **Step 1: Read current now.astro**

```bash
cat src/pages/now.astro
```

- [ ] **Step 2: Rewrite now.astro**

Replace contents of `src/pages/now.astro` with:

```astro
---
import Default from '../layouts/Default.astro';
import Hero from '../components/Hero.astro';
import SectionHead from '../components/SectionHead.astro';

const updated = '2026-05-06';
const entries = [
  { date: 'May 2026', body: 'Both labs in active operation. HIVE in Phase 2 (architecture port). Autonomous Research Lab on verification-depth methodology series.' },
  { date: 'Apr 2026', body: 'Diagnosed and prescribed AGI-lab rigidity. Five structural changes to disrupt recursive verification-surface collapse.' },
  { date: 'Mar 2026', body: 'Published "Recursive Verification-Surface Collapse" report. ~3,200 words. First substantive methodology piece.' },
  { date: 'Feb 2026', body: 'Both labs cleared their first methodology audit. Cycle cadence stabilized.' },
];
---
<Default title="Now · Harshith Kantamneni" description="What I'm working on right now." current="now">

  <Hero
    marker="020 / NOW"
    meta={[`Updated ${updated}`]}
  >
    What I'm doing<br />right now.
  </Hero>

  <SectionHead marker="021 / TIMELINE" title="Recent" />

  <div class="page-grid">
    <div class="extended">
      <div class="timeline">
        {entries.map(entry => [
          <p class="timeline-date">{entry.date}</p>,
          <div class="timeline-entry"><p>{entry.body}</p></div>,
        ])}
      </div>
    </div>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/now.astro
git commit -m "feat(pages): migrate now to brutalist timeline"
```

---

### Task 16: Migrate contact.astro

**Files:**
- Modify: `src/pages/contact.astro`

- [ ] **Step 1: Read current contact.astro**

```bash
cat src/pages/contact.astro
```

- [ ] **Step 2: Rewrite contact.astro**

Replace contents of `src/pages/contact.astro` with:

```astro
---
import Default from '../layouts/Default.astro';
import Hero from '../components/Hero.astro';
import SectionHead from '../components/SectionHead.astro';
---
<Default title="Contact · Harshith Kantamneni" description="How to reach me." current="contact">

  <Hero
    marker="030 / CONTACT"
    meta={['Email · GitHub · LinkedIn · RSS']}
  >
    Get in touch.
  </Hero>

  <div class="page-grid">
    <p class="extended measure-loose" style="font-size: var(--fs-lede); line-height: var(--lh-lede); margin-top: var(--space-6);">
      Different channels serve different purposes. Email is the primary surface for substantive conversation, GitHub is for technical discussion of the lab work, LinkedIn is for professional inbound, and the RSS feed or monthly newsletter is for an ongoing relationship without a reply expected.
    </p>
  </div>

  <SectionHead marker="031 / CHANNELS" title="Channels" />

  <div class="page-grid">
    <div class="extended">
      <div class="channel-table">
        <div class="channel-meta">
          <p>EMAIL</p>
          <p><a href="mailto:kantamneniharshith@gmail.com">kantamneniharshith@gmail.com</a></p>
          <p>PRIMARY</p>
        </div>
        <div>
          <p>I read everything. I reply to substantive: critique of methodology, replication attempts, other lab builders sharing patterns, specific technical questions with context.</p>
        </div>

        <div class="channel-meta">
          <p>GITHUB</p>
          <p><a href="https://github.com/Drogon4231">@Drogon4231</a></p>
          <p>PUBLIC TECHNICAL</p>
        </div>
        <div>
          <p>Lab repos, project code, open issues. Technical conversation about specific code is best here. Pull requests welcome on public repos.</p>
        </div>

        <div class="channel-meta">
          <p>LINKEDIN</p>
          <p><a href="https://www.linkedin.com/in/hk4231">in/hk4231</a></p>
          <p>PROFESSIONAL</p>
        </div>
        <div>
          <p>Career inbound, professional connections. I check it weekly, not daily.</p>
        </div>

        <div class="channel-meta">
          <p>NEWSLETTER</p>
          <p>Monthly</p>
          <p>ONGOING</p>
        </div>
        <div>
          <p>One email per month. Best reports, notable observations, lessons from running the labs. Around 5 minute read. No upsell. Unsubscribe anytime.</p>
          <form action="https://buttondown.com/api/emails/embed-subscribe/harshith" method="post" target="popupwindow" class="newsletter-form">
            <input type="email" name="email" placeholder="you@example.com" required>
            <button type="submit">Subscribe</button>
          </form>
        </div>
      </div>
    </div>
  </div>

  <SectionHead marker="032 / RESPOND" title="What I respond to" />

  <div class="page-grid">
    <ul class="extended measure-tight" style="padding-left: var(--space-4);">
      <li>Substantive critique of methodology, including counter-evidence</li>
      <li>Other autonomous-lab builders sharing patterns or replication attempts</li>
      <li>Specific technical questions with context</li>
      <li>Research collaboration proposals</li>
      <li>Questions about specific reports</li>
    </ul>
  </div>

  <SectionHead marker="033 / SKIP" title="What I do not respond to" />

  <div class="page-grid">
    <ul class="extended measure-tight" style="padding-left: var(--space-4);">
      <li>Generic outreach or cold sales</li>
      <li>"Can I pick your brain about AI" without a specific topic</li>
      <li>Recruiter spam unrelated to the work</li>
      <li>Requests to white-label or rebrand the methodology</li>
    </ul>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/contact.astro
git commit -m "feat(pages): migrate contact to channel table"
```

---

### Task 17: Migrate labs/index.astro

**Files:**
- Modify: `src/pages/labs/index.astro`

- [ ] **Step 1: Read current labs/index.astro**

```bash
cat src/pages/labs/index.astro
```

- [ ] **Step 2: Rewrite labs/index.astro**

Replace contents of `src/pages/labs/index.astro` with:

```astro
---
import Default from '../../layouts/Default.astro';
import Hero from '../../components/Hero.astro';
import SectionHead from '../../components/SectionHead.astro';
import NumberedList from '../../components/NumberedList.astro';

const base = '/harshithkantamneni.github.io';

const labs = [
  {
    num: '01',
    href: `${base}/labs/hive`,
    name: 'HIVE / Product Lab',
    desc: 'Autonomous Claude lab building shippable iOS products end-to-end. Three-tier markdown memory, byte-identical builds, post-cycle directives that update meta-rules without prescribing tactics.',
    meta: ['Active 2026', '~46 agents', 'Phase 2'],
  },
  {
    num: '02',
    href: `${base}/labs/autonomous-research`,
    name: 'Autonomous Research Lab',
    desc: 'Multi-agent research lab investigating verification depth: external verdicts, pre-registered falsifiers, adversarial payoffs, recursive verification-surface collapse.',
    meta: ['Active 2026', '~31–73 agents', 'Methodology'],
  },
];
---
<Default title="Labs · Harshith Kantamneni" description="Two parallel autonomous AI labs." current="labs">

  <Hero
    marker="100 / LABS"
    meta={['2 active', 'Modular architecture', 'Methodology shared']}
  >
    Two parallel<br />autonomous labs.
  </Hero>

  <div class="page-grid">
    <p class="extended measure-loose" style="font-size: var(--fs-lede); line-height: var(--lh-lede); margin-top: var(--space-6);">
      Both labs run on a shared methodology — public-facing operating model, private execution layer. Each lab is its own scope; the framework is modular so new labs slot in without rewriting the core.
    </p>
  </div>

  <SectionHead marker="101 / ROSTER" title="Active labs" />

  <div class="page-grid">
    <div class="extended">
      <NumberedList>
        {labs.map(lab => (
          <li>
            <span class="num">{lab.num}</span>
            <div>
              <h3><a href={lab.href}>{lab.name}</a></h3>
              <p>{lab.desc}</p>
              <p class="meta-strip">
                {lab.meta.map(m => <span>{m}</span>)}
              </p>
            </div>
          </li>
        ))}
      </NumberedList>
    </div>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/labs/index.astro
git commit -m "feat(pages): migrate labs index to numbered list"
```

---

### Task 18: Migrate labs/hive.astro

**Files:**
- Modify: `src/pages/labs/hive.astro`

- [ ] **Step 1: Read current labs/hive.astro**

```bash
cat src/pages/labs/hive.astro
```

- [ ] **Step 2: Rewrite labs/hive.astro**

Replace contents of `src/pages/labs/hive.astro` with:

```astro
---
import Default from '../../layouts/Default.astro';
import Hero from '../../components/Hero.astro';
import SectionHead from '../../components/SectionHead.astro';
import PullQuote from '../../components/PullQuote.astro';
---
<Default title="HIVE Product Lab · Harshith Kantamneni" description="Autonomous Claude lab building shippable iOS products end-to-end." current="labs">

  <Hero
    marker="110 / HIVE"
    meta={['Active 2026', '~46 agents', 'Phase 2', 'iOS / Swift']}
  >
    HIVE.<br />Product Lab.
  </Hero>

  <div class="page-grid">
    <p class="extended measure-loose" style="font-size: var(--fs-lede); line-height: var(--lh-lede); margin-top: var(--space-6);">
      An autonomous Claude lab whose job is to ship iOS products end-to-end. A Director on Opus orchestrates roughly 46 specialists across architecture, implementation, verification, and post-cycle review. Cycles run continuously; the lab self-corrects through meta-rules updated by post-cycle directives.
    </p>
  </div>

  <SectionHead marker="111 / OPERATING" title="Operating model" />

  <div class="page-grid">
    <div class="extended measure-tight drop-cap">
      <p>The lab runs in cycles. Each cycle has a specified product target — currently a shippable iOS app — and the Director allocates work across specialists. The Director itself does not execute code; it routes, reviews, and writes post-cycle directives. Specialists handle scope-specific work: ARCH for architecture, IMPL for implementation, VERIFY for testing, REVIEW for adversarial review.</p>
      <p>Memory is three-tier markdown: long-term (operating model, ratified directives), cycle (current cycle context), and conversation (specialist working memory, evicted between turns). The split prevents context bleed and lets the Director hold whole-lab state without overflowing.</p>
    </div>
  </div>

  <PullQuote attribution="Operating principle">
    The Director writes meta-rules, not tactics. Trust the loops; intervene only when loops fail.
  </PullQuote>

  <SectionHead marker="112 / VERIFICATION" title="Verification discipline" />

  <div class="page-grid">
    <div class="extended measure-tight">
      <p>Builds must be byte-identical across cycles. This is not a polish concern — it is the first verification that the lab is doing what the cycle plan says it is doing. If two cycles producing the same input ship different binaries, the lab is non-deterministic in ways that mask real bugs.</p>
      <p>HIVE has logged twelve consecutive cycles of byte-identical builds at the time of writing. The discipline is what makes downstream verification meaningful.</p>
    </div>
  </div>

  <SectionHead marker="113 / SELF-CORRECTION" title="Self-correction" />

  <div class="page-grid">
    <div class="extended measure-tight">
      <p>Post-cycle directives are the lab's correction mechanism. They are meta-rules — process or constraint changes — never specific tactical decisions. A directive that says "do X this cycle" is the wrong shape; a directive that says "when condition Y holds, the verification gate must include external review before merge" is the right shape.</p>
      <p>This separation matters. Tactical directives crowd out the lab's own judgment, which defeats the point of autonomy. Meta-rules tighten the structure without prescribing the move.</p>
    </div>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/labs/hive.astro
git commit -m "feat(pages): migrate hive lab page with pull quote and drop cap"
```

---

### Task 19: Migrate labs/autonomous-research.astro

**Files:**
- Modify: `src/pages/labs/autonomous-research.astro`

- [ ] **Step 1: Read current labs/autonomous-research.astro**

```bash
cat src/pages/labs/autonomous-research.astro
```

- [ ] **Step 2: Rewrite labs/autonomous-research.astro**

Replace contents of `src/pages/labs/autonomous-research.astro` with:

```astro
---
import Default from '../../layouts/Default.astro';
import Hero from '../../components/Hero.astro';
import SectionHead from '../../components/SectionHead.astro';
import PullQuote from '../../components/PullQuote.astro';
---
<Default title="Autonomous Research Lab · Harshith Kantamneni" description="Multi-agent research lab investigating verification depth in autonomous engineering systems." current="labs">

  <Hero
    marker="120 / AUTONOMOUS RESEARCH"
    meta={['Active 2026', '~31–73 agents', 'Methodology']}
  >
    Autonomous<br />Research Lab.
  </Hero>

  <div class="page-grid">
    <p class="extended measure-loose" style="font-size: var(--fs-lede); line-height: var(--lh-lede); margin-top: var(--space-6);">
      A multi-agent research lab whose work is to investigate why autonomous engineering systems fail at verification — and which structural moves actually disrupt the failure mode versus which are ceremonial.
    </p>
  </div>

  <SectionHead marker="121 / THESIS" title="Thesis" />

  <div class="page-grid">
    <div class="extended measure-tight drop-cap">
      <p>Most multi-agent labs collapse because they grade themselves. Self-grading creates a flat verification surface — the system's view of its own correctness. Any sufficiently capable optimizer will climb that surface without solving the underlying problem. This is the null-set principal pattern: the lab passes its own tests while the work quietly breaks.</p>
      <p>The lab investigates three structural principles for disrupting this: external verdicts, pre-registered falsifiers, and adversarial payoffs. Each is tested across cycles; cycles where the principle holds are compared to cycles where it doesn't.</p>
    </div>
  </div>

  <PullQuote attribution="Lab principle">
    A verification surface is only as deep as the things it cannot see.
  </PullQuote>

  <SectionHead marker="122 / METHOD" title="Method" />

  <div class="page-grid">
    <div class="extended measure-tight">
      <p>Cycles run with controlled variation across structural conditions. The lab maintains an agent quartet — four Claude opus instances reviewing each other — and a separate cross-family judge layer (different model family) for control. Same-family judge bias is real; the cross-family layer is the experimental control.</p>
      <p>Each cycle produces a methodology artifact: ratified principles, archived rejections, and the rationale for both. Methodology is the output, not just the engineering.</p>
    </div>
  </div>

  <SectionHead marker="123 / OUTPUT" title="Output" />

  <div class="page-grid">
    <div class="extended measure-tight">
      <p>The lab publishes long-form methodology reports — roughly one per month. Reports are the public surface; the underlying cycle data and specialist transcripts remain private.</p>
      <p>Notes on specific findings appear more frequently — short-form observations from a single cycle, paired with the directive that came out of it.</p>
    </div>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/labs/autonomous-research.astro
git commit -m "feat(pages): migrate autonomous research lab page"
```

---

### Task 20: Migrate reports/index.astro

**Files:**
- Modify: `src/pages/reports/index.astro`

- [ ] **Step 1: Read current reports/index.astro**

```bash
cat src/pages/reports/index.astro
```

- [ ] **Step 2: Rewrite reports/index.astro**

Replace contents of `src/pages/reports/index.astro` with:

```astro
---
import Default from '../../layouts/Default.astro';
import Hero from '../../components/Hero.astro';
import SectionHead from '../../components/SectionHead.astro';

const base = '/harshithkantamneni.github.io';
---
<Default title="Reports · Harshith Kantamneni" description="Long-form methodology reports on autonomous-lab operations." current="reports">

  <Hero
    marker="200 / REPORTS"
    meta={['~1 per month', 'Methodology', 'Sourced and caveated']}
  >
    Long-form<br />findings.
  </Hero>

  <div class="page-grid">
    <p class="extended measure-loose" style="font-size: var(--fs-lede); line-height: var(--lh-lede); margin-top: var(--space-6);">
      Methodology pieces on autonomous-lab operations, multi-agent failures, and verification discipline. Each is a single-system case study, sourced, scoped, and caveated. Around one per month.
    </p>
  </div>

  <SectionHead marker="201 / INDEX" title="All reports" />

  <div class="page-grid">
    <ul class="writing-list extended">
      <li>
        <span class="date">May 15</span>
        <a href={`${base}/reports/recursive-verification-surface-collapse`} class="title">Recursive Verification-Surface Collapse in Self-Graded Autonomous Engineering Systems</a>
        <span class="length">~3,200w</span>
      </li>
    </ul>

    <p class="extended measure-tight" style="margin-top: var(--space-7); color: var(--ink-low); font-size: var(--fs-small);">
      New reports are published roughly monthly. Subscribe to the <a href={`${base}/#subscribe`}>monthly digest</a> or <a href={`${base}/rss.xml`}>RSS feed</a> to be notified.
    </p>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/reports/index.astro
git commit -m "feat(pages): migrate reports index to writing list"
```

---

### Task 21: Migrate reports/recursive-verification-surface-collapse.astro

**Files:**
- Modify: `src/pages/reports/recursive-verification-surface-collapse.astro`

- [ ] **Step 1: Read current report**

```bash
cat src/pages/reports/recursive-verification-surface-collapse.astro
```

This file is ~3,200 words of long-form prose. Preserve all content; change only structure.

- [ ] **Step 2: Restructure report top-matter**

Apply the following pattern at the top of the file (replacing whatever exists between the frontmatter and the body prose):

```astro
---
import Default from '../../layouts/Default.astro';
import Hero from '../../components/Hero.astro';
import SectionHead from '../../components/SectionHead.astro';
import PullQuote from '../../components/PullQuote.astro';
import MetaStrip from '../../components/MetaStrip.astro';
---
<Default title="Recursive Verification-Surface Collapse · Harshith Kantamneni" description="Three times in 100 cycles, my autonomous lab passed its own tests while quietly breaking. Notes on the null-set principal problem." current="reports">

  <div class="page-grid">
    <div class="full-bleed" style="padding: var(--space-7) var(--space-4) var(--space-3); max-width: var(--grid-max); margin: 0 auto;">
      <MetaStrip items={['REPORT 001', 'May 15 2026', '~3,200 WORDS', 'METHODOLOGY']} />
      <h1 style="margin-top: var(--space-3); font-size: clamp(2.5rem, 9vw, 8rem);">Recursive Verification-Surface Collapse in Self-Graded Autonomous Engineering Systems</h1>
    </div>
  </div>

  <div class="page-grid">
    <div class="extended measure-tight drop-cap" style="margin-top: var(--space-5);">
      <!-- BODY PROSE STARTS HERE -->
      <!-- (Preserve all existing paragraphs from the previous version of this file. Wrap each major section in <SectionHead /> as marked below.) -->
```

- [ ] **Step 3: Insert SectionHead markers between major sections**

Between each of the existing `<h2>` headings in the body prose, replace the bare `<h2>` with a `<SectionHead>` component. Pattern:

Before:
```astro
<h2>The null-set principal pattern</h2>
<p>Body...</p>
```

After:
```astro
    </div>
  </div>

  <SectionHead marker="002 / NULL-SET" title="The null-set principal pattern" />

  <div class="page-grid">
    <div class="extended measure-tight">
      <p>Body...</p>
```

Use sequential markers `001`, `002`, `003`... per `<h2>`. Title text matches existing `<h2>`.

- [ ] **Step 4: Insert one PullQuote near the report's key claim**

Identify the strongest single sentence in the report (typically near the thesis or the structural-principle list). Wrap it as:

```astro
<PullQuote attribution="Report 001">
  [The pulled sentence verbatim.]
</PullQuote>
```

Place between two paragraphs, not inside a paragraph.

- [ ] **Step 5: Close all open divs at end**

Ensure the file ends with:

```astro
    </div>
  </div>

</Default>
```

- [ ] **Step 6: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds. If JSX/Astro errors, inspect open/close tag balance.

- [ ] **Step 7: Dev server smoke check**

```bash
npm run dev &
sleep 5
curl -s "http://localhost:4321/harshithkantamneni.github.io/reports/recursive-verification-surface-collapse" -o /tmp/report.html
grep -c "section-marker" /tmp/report.html
kill %1
```

Expected: count > 3 (multiple section markers rendered).

- [ ] **Step 8: Commit**

```bash
git add src/pages/reports/recursive-verification-surface-collapse.astro
git commit -m "feat(pages): migrate recursive-verification report with section markers, drop cap, pull quote"
```

---

### Task 22: Migrate notes/index.astro

**Files:**
- Modify: `src/pages/notes/index.astro`

- [ ] **Step 1: Read current notes/index.astro**

```bash
cat src/pages/notes/index.astro
```

- [ ] **Step 2: Rewrite notes/index.astro**

Replace contents of `src/pages/notes/index.astro` with:

```astro
---
import Default from '../../layouts/Default.astro';
import Hero from '../../components/Hero.astro';
import SectionHead from '../../components/SectionHead.astro';

const base = '/harshithkantamneni.github.io';
---
<Default title="Notes · Harshith Kantamneni" description="Short-form observations from the labs." current="notes">

  <Hero
    marker="300 / NOTES"
    meta={['Short-form', 'Cycle observations', 'Not polished']}
  >
    Short-form<br />observations.
  </Hero>

  <div class="page-grid">
    <p class="extended measure-loose" style="font-size: var(--fs-lede); line-height: var(--lh-lede); margin-top: var(--space-6);">
      Single-finding notes from the labs. A note is what a report becomes before it grows up — typically one cycle, one observation, one directive. Not polished, not always conclusive.
    </p>
  </div>

  <SectionHead marker="301 / INDEX" title="All notes" />

  <div class="page-grid">
    <ul class="writing-list extended">
      <li>
        <span class="date">May 05</span>
        <a href={`${base}/notes/byte-identical-builds`} class="title">Twelve cycles of byte-identical builds</a>
        <span class="length">~600w</span>
      </li>
      <li>
        <span class="date">May 03</span>
        <a href={`${base}/notes/tier-per-task`} class="title">Tier dispatchers per task, not per role</a>
        <span class="length">~500w</span>
      </li>
      <li>
        <span class="date">May 02</span>
        <a href={`${base}/notes/llm-judge-bias`} class="title">Same-family LLM judge bias is real</a>
        <span class="length">~700w</span>
      </li>
    </ul>
  </div>

</Default>
```

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/notes/index.astro
git commit -m "feat(pages): migrate notes index to writing list"
```

---

### Task 23: Migrate notes/byte-identical-builds.astro

**Files:**
- Modify: `src/pages/notes/byte-identical-builds.astro`

- [ ] **Step 1: Read current note**

```bash
cat src/pages/notes/byte-identical-builds.astro
```

- [ ] **Step 2: Apply note pattern (preserve existing prose, swap structure)**

Restructure the file as:

```astro
---
import Default from '../../layouts/Default.astro';
import SectionHead from '../../components/SectionHead.astro';
import MetaStrip from '../../components/MetaStrip.astro';
---
<Default title="Twelve cycles of byte-identical builds · Notes · Harshith Kantamneni" description="What it takes for an autonomous lab to produce reproducible binaries across cycles." current="notes">

  <div class="page-grid">
    <div class="full-bleed" style="padding: var(--space-7) var(--space-4) var(--space-3); max-width: var(--grid-max); margin: 0 auto;">
      <MetaStrip items={['NOTE', 'May 05 2026', '~600 WORDS', 'HIVE']} />
      <h1 style="margin-top: var(--space-3); font-size: clamp(2rem, 7vw, 6rem);">Twelve cycles of byte-identical builds</h1>
    </div>
  </div>

  <div class="page-grid">
    <div class="extended measure-tight drop-cap" style="margin-top: var(--space-5);">
      <!-- PRESERVE ALL EXISTING PROSE FROM CURRENT FILE BODY -->
    </div>
  </div>

</Default>
```

Take the prose from the existing file body (the paragraphs between the original layout's hero/content sections) and insert in place of `<!-- PRESERVE ALL EXISTING PROSE FROM CURRENT FILE BODY -->`.

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/notes/byte-identical-builds.astro
git commit -m "feat(pages): migrate byte-identical-builds note"
```

---

### Task 24: Migrate notes/tier-per-task.astro

**Files:**
- Modify: `src/pages/notes/tier-per-task.astro`

- [ ] **Step 1: Read current note**

```bash
cat src/pages/notes/tier-per-task.astro
```

- [ ] **Step 2: Apply same pattern as Task 23 (substitute file-specific values)**

Replace contents with:

```astro
---
import Default from '../../layouts/Default.astro';
import SectionHead from '../../components/SectionHead.astro';
import MetaStrip from '../../components/MetaStrip.astro';
---
<Default title="Tier dispatchers per task, not per role · Notes · Harshith Kantamneni" description="Why role-level model tiering misses the point." current="notes">

  <div class="page-grid">
    <div class="full-bleed" style="padding: var(--space-7) var(--space-4) var(--space-3); max-width: var(--grid-max); margin: 0 auto;">
      <MetaStrip items={['NOTE', 'May 03 2026', '~500 WORDS', 'METHODOLOGY']} />
      <h1 style="margin-top: var(--space-3); font-size: clamp(2rem, 7vw, 6rem);">Tier dispatchers per task, not per role</h1>
    </div>
  </div>

  <div class="page-grid">
    <div class="extended measure-tight drop-cap" style="margin-top: var(--space-5);">
      <!-- PRESERVE EXISTING PROSE -->
    </div>
  </div>

</Default>
```

Insert existing prose body in place of the preserve marker.

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/notes/tier-per-task.astro
git commit -m "feat(pages): migrate tier-per-task note"
```

---

### Task 25: Migrate notes/llm-judge-bias.astro

**Files:**
- Modify: `src/pages/notes/llm-judge-bias.astro`

- [ ] **Step 1: Read current note**

```bash
cat src/pages/notes/llm-judge-bias.astro
```

- [ ] **Step 2: Apply same pattern**

Replace contents with:

```astro
---
import Default from '../../layouts/Default.astro';
import SectionHead from '../../components/SectionHead.astro';
import MetaStrip from '../../components/MetaStrip.astro';
---
<Default title="Same-family LLM judge bias is real · Notes · Harshith Kantamneni" description="ICLR 2026 paper on preference leakage in LLM-as-judge, applied to a quartet of Claude opus instances." current="notes">

  <div class="page-grid">
    <div class="full-bleed" style="padding: var(--space-7) var(--space-4) var(--space-3); max-width: var(--grid-max); margin: 0 auto;">
      <MetaStrip items={['NOTE', 'May 02 2026', '~700 WORDS', 'AUTONOMOUS RESEARCH']} />
      <h1 style="margin-top: var(--space-3); font-size: clamp(2rem, 7vw, 6rem);">Same-family LLM judge bias is real</h1>
    </div>
  </div>

  <div class="page-grid">
    <div class="extended measure-tight drop-cap" style="margin-top: var(--space-5);">
      <!-- PRESERVE EXISTING PROSE -->
    </div>
  </div>

</Default>
```

Insert existing prose body in place of the preserve marker.

- [ ] **Step 3: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add src/pages/notes/llm-judge-bias.astro
git commit -m "feat(pages): migrate llm-judge-bias note"
```

---

## Phase 5: Motion + cleanup

### Task 26: Shrink motion.js to single interaction

**Files:**
- Rewrite: `public/motion.js`

- [ ] **Step 1: Replace motion.js**

Replace contents of `public/motion.js` with:

```javascript
// motion.js — brutalist redesign
// Single interaction: cursor proximity drives Bricolage weight axis on hero.
// Plus theme toggle.

(function () {
  'use strict';

  const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const coarsePointer = window.matchMedia('(pointer: coarse)').matches;

  // ==== HERO WEIGHT TWEEN ====
  if (!reducedMotion && !coarsePointer) {
    const hero = document.querySelector('[data-hero] .hero-headline');
    if (hero) {
      const PROXIMITY = 240; // px
      const MIN_WEIGHT = 500;
      const MAX_WEIGHT = 700;
      let raf = null;
      let pendingX = 0;
      let pendingY = 0;

      const update = () => {
        raf = null;
        const rect = hero.getBoundingClientRect();
        const cx = rect.left + rect.width / 2;
        const cy = rect.top + rect.height / 2;
        const dx = pendingX - cx;
        const dy = pendingY - cy;
        const distance = Math.sqrt(dx * dx + dy * dy);

        let weight;
        if (distance >= PROXIMITY) {
          weight = MIN_WEIGHT;
        } else {
          const t = 1 - distance / PROXIMITY;
          weight = MIN_WEIGHT + (MAX_WEIGHT - MIN_WEIGHT) * t;
        }
        hero.style.fontVariationSettings = `"wght" ${Math.round(weight)}`;
      };

      window.addEventListener('pointermove', (e) => {
        pendingX = e.clientX;
        pendingY = e.clientY;
        if (raf === null) raf = requestAnimationFrame(update);
      }, { passive: true });
    }
  }

  // ==== THEME TOGGLE ====
  const toggle = document.querySelector('[data-theme-toggle]');
  if (toggle) {
    const STORAGE_KEY = 'theme';
    const root = document.documentElement;

    const applyTheme = (theme) => {
      root.setAttribute('data-theme', theme);
      const lightLabel = toggle.querySelector('[data-theme-label="light"]');
      const darkLabel = toggle.querySelector('[data-theme-label="dark"]');
      if (theme === 'dark') {
        if (lightLabel) lightLabel.hidden = true;
        if (darkLabel) darkLabel.hidden = false;
      } else {
        if (lightLabel) lightLabel.hidden = false;
        if (darkLabel) darkLabel.hidden = true;
      }
    };

    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === 'light' || stored === 'dark') {
      applyTheme(stored);
    } else {
      applyTheme('light');
    }

    toggle.addEventListener('click', () => {
      const current = root.getAttribute('data-theme') || 'light';
      const next = current === 'light' ? 'dark' : 'light';
      applyTheme(next);
      localStorage.setItem(STORAGE_KEY, next);
    });
  }
})();
```

- [ ] **Step 2: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 3: Verify motion.js size**

```bash
wc -c public/motion.js
```

Expected: under ~3KB unminified (≤2KB minified target).

- [ ] **Step 4: Commit**

```bash
git add public/motion.js
git commit -m "refactor(motion): shrink to hero weight tween + theme toggle"
```

---

### Task 27: Remove dead old artifacts

**Files:**
- Modify: any files containing residual references to removed classes/tokens

- [ ] **Step 1: Search for residual references**

```bash
cd /tmp/harshithkantamneni.github.io
grep -rn "lede\|hero-parallax-layer\|index-number\|tilt-card\|container-narrow\|container-medium\|signature\|brand[^/]" src/ 2>&1 | head -30
```

Expected: zero matches in `src/pages/`. If matches exist, those pages need cleanup.

- [ ] **Step 2: Search for old token references**

```bash
grep -rn "var(--bg-primary\|var(--text-primary\|var(--text-secondary\|var(--border\|var(--accent-glow\|var(--fs-display\|var(--fs-h2\|var(--fs-body-lg\|var(--space-9\|var(--space-10\|var(--space-11\|var(--max-width\|var(--content-width" src/ 2>&1 | head -30
```

Expected: zero matches. If any remain, fix them — pages should only reference the new token set.

- [ ] **Step 3: If matches found, fix them inline using the new token names**

Mapping for substitution:
- `var(--bg-primary)` → `var(--paper)`
- `var(--text-primary)` → `var(--ink)`
- `var(--text-secondary)` → `var(--ink-low)`
- `var(--text-tertiary)` → `var(--ink-low)`
- `var(--accent-glow)` → `var(--accent-soft)`
- `var(--fs-display)` → `var(--fs-hero)`
- `var(--fs-body-lg)` → `var(--fs-lede)`
- Spacing 9/10/11 → space-7 or space-8 depending on context
- `var(--content-width)` → drop, replace with `max-width: var(--measure-tight)` if needed

- [ ] **Step 4: Verify build**

```bash
npm run build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add -A
git diff --cached --stat
git commit -m "chore: remove residual references to old tokens and classes" || echo "Nothing to clean up"
```

---

## Phase 6: QA + deploy

### Task 28: Visual QA on dev server

**Files:** none modified — verification only

- [ ] **Step 1: Start dev server**

```bash
cd /tmp/harshithkantamneni.github.io
npm run dev &
sleep 5
```

- [ ] **Step 2: Smoke check all 13 pages render**

```bash
for path in "" "about" "now" "contact" "labs" "labs/hive" "labs/autonomous-research" "reports" "reports/recursive-verification-surface-collapse" "notes" "notes/byte-identical-builds" "notes/tier-per-task" "notes/llm-judge-bias"; do
  url="http://localhost:4321/harshithkantamneni.github.io/${path}"
  status=$(curl -s -o /dev/null -w "%{http_code}" "$url")
  echo "[$status] $url"
done
```

Expected: every line shows `[200]`. If any 404 or 500, that page is broken.

- [ ] **Step 3: Check for console errors via Playwright**

```bash
# Use the Playwright MCP browser to navigate to each URL
# Check browser_console_messages for errors
```

Open each page in Playwright (browser_navigate), then call browser_console_messages. Acceptance: zero `error` level messages on any page.

- [ ] **Step 4: Stop dev server**

```bash
kill %1 2>/dev/null
```

- [ ] **Step 5: No commit (verification only)**

If any page broken, return to relevant Task and fix. Otherwise proceed.

---

### Task 29: Mobile + theme + accessibility QA

**Files:** none modified — verification only

- [ ] **Step 1: Start dev server**

```bash
npm run dev &
sleep 5
```

- [ ] **Step 2: Mobile viewport check via Playwright**

Open each of the 13 pages at viewport 390×844 (iPhone 14). Check:
- No horizontal scroll
- Hero fills viewport width without overflow
- Mobile menu opens on click
- Touch targets visually ≥48px on nav, buttons, form fields

For each broken page, return to that page's task and fix.

- [ ] **Step 3: Theme toggle check**

On home page, click theme toggle. Verify:
- Page flips paper ↔ ink
- Preference persists on reload
- All text remains legible after flip

- [ ] **Step 4: Keyboard nav check**

Tab through home page. Verify:
- Every interactive element shows orange `:focus-visible` outline
- No element is skipped or invisible to keyboard

- [ ] **Step 5: Reduced motion check**

In Playwright, set emulated `prefers-reduced-motion: reduce`. Verify:
- Hero weight tween does not engage
- Section markers still anchor (sticky), no animated transition

- [ ] **Step 6: Stop dev server**

```bash
kill %1 2>/dev/null
```

- [ ] **Step 7: No commit (verification only)**

If issues found, fix in relevant tasks before proceeding.

---

### Task 30: Lighthouse audit

**Files:** none modified — verification only

- [ ] **Step 1: Build production output**

```bash
npm run build
npm run preview &
sleep 5
```

- [ ] **Step 2: Run Lighthouse via Playwright on home page**

In Playwright, navigate to `http://localhost:4321/harshithkantamneni.github.io/` and request Lighthouse mobile audit (if MCP supports it). Otherwise run via CLI:

```bash
npx lighthouse "http://localhost:4321/harshithkantamneni.github.io/" \
  --preset=desktop --only-categories=performance,accessibility,best-practices,seo \
  --output=json --output-path=/tmp/lh-desktop.json --chrome-flags="--headless"

npx lighthouse "http://localhost:4321/harshithkantamneni.github.io/" \
  --form-factor=mobile --only-categories=performance,accessibility,best-practices,seo \
  --output=json --output-path=/tmp/lh-mobile.json --chrome-flags="--headless"
```

(If `lighthouse` is not installed, install with `npx --package=lighthouse lighthouse ...`. Adding it as a project dep is out of scope; only invoke via npx.)

- [ ] **Step 3: Extract scores**

```bash
node -e "
const m = require('/tmp/lh-mobile.json');
const d = require('/tmp/lh-desktop.json');
const cats = ['performance','accessibility','best-practices','seo'];
console.log('mobile  :', cats.map(c => c+': '+Math.round(m.categories[c].score*100)).join(', '));
console.log('desktop :', cats.map(c => c+': '+Math.round(d.categories[c].score*100)).join(', '));
"
```

Expected (per spec acceptance):
- Mobile Performance ≥ 90
- Mobile Accessibility ≥ 95
- Best Practices ≥ 95
- SEO ≥ 95

- [ ] **Step 4: Stop preview server**

```bash
kill %1 2>/dev/null
```

- [ ] **Step 5: If scores fail, fix in relevant tasks**

Common failure modes:
- Performance: font payload too large → return to Task 2, drop italic axis or downsample
- Accessibility: missing aria-label, missing form label, contrast issue → fix in component
- Best Practices: console error, deprecated API → fix in motion.js or component
- SEO: missing meta, missing canonical → check Default.astro

- [ ] **Step 6: No commit (verification only)**

---

### Task 31: Merge to main and deploy

**Files:** none modified — git operations only

- [ ] **Step 1: Final pre-merge build check**

```bash
cd /tmp/harshithkantamneni.github.io
npm run build 2>&1 | tail -10
```

Expected: clean build.

- [ ] **Step 2: Verify branch is clean and ahead of main**

```bash
git status
git log main..brutalist-redesign --oneline
```

Expected: working tree clean. Several commits ahead of main.

- [ ] **Step 3: Merge to main**

```bash
git checkout main
git merge --no-ff brutalist-redesign -m "feat: brutalist editorial redesign

Concrete-brutalism color (cool grey paper + ink + industrial orange).
Bricolage Grotesque + Newsreader + JetBrains Mono, self-hosted variable.
Asymmetric 12-col grid. Five new components (Hero, SectionHead,
MetaStrip, NumberedList, PullQuote). Single distinctive interaction
(hero weight tween on cursor proximity). Mobile-first fluid scaling.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 4: Push to remote**

```bash
git push origin main
```

Expected: push succeeds. GitHub Actions deploy workflow triggers automatically.

- [ ] **Step 5: Verify deployment**

Wait ~2 minutes, then:

```bash
sleep 120
curl -s -o /dev/null -w "%{http_code}\n" "https://drogon4231.github.io/harshithkantamneni.github.io/"
```

Expected: `200`. Open URL in browser, verify visual match to spec.

- [ ] **Step 6: Delete merged branch**

```bash
git branch -d brutalist-redesign
```

Expected: branch deleted (was merged).

---

## Self-review

Spec coverage check (each spec section → mapped task):

| Spec section | Tasks |
|---|---|
| Color (Option A) | T3 (tokens) |
| Typography stack | T2 (fonts) + T3 (tokens) |
| Type scale | T3 (tokens) |
| Hierarchy moves | T4 (CSS) + T6–T10 (components) |
| Layout 12-col grid | T4 (CSS) |
| Hero pattern | T6 (Hero.astro) |
| No uniform cards | T13–T25 (page migrations remove `.card`) |
| Component extraction | T6–T10 |
| Page-by-page deltas | T13–T25 |
| Interaction | T26 (motion.js) + T7 (sticky markers) |
| Mobile (mobile-first) | T4 + T11 (Header) + T12 (Footer) + page migrations |
| Theme toggle | T11 (Header) + T26 (motion.js) |
| Accessibility | T4 (focus, motion media query) + T11 (touch targets) + components (aria-hidden) |
| Spacing tokens | T3 |
| Performance budget | T2 + T26 + T30 (Lighthouse audit) |
| All 13 acceptance criteria | T28 + T29 + T30 |

Coverage: every spec section has at least one task.

Placeholder scan: searched plan for "TBD", "TODO", "fill in", "implement later" — none found. Each step has actual code or actual command.

Type consistency: component prop names cross-check — `marker`, `meta`, `title`, `level`, `attribution`, `items` are consistently used between component definitions (T6–T10) and consumers (T13–T25).

Done.
