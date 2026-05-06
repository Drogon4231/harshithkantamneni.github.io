# harshithkantamneni.github.io

Personal site for Harshith Kantamneni. Built with [Astro](https://astro.build).

Live at [harshithkantamneni.github.io](https://harshithkantamneni.github.io).

## Local development

```bash
npm install
npm run dev      # http://localhost:4321
npm run build    # outputs ./dist
npm run preview  # preview build locally
```

## Structure

```
src/
├── layouts/Default.astro    shared layout (header + footer + meta)
├── components/              header, footer
├── pages/                   one .astro file per route
│   ├── index.astro          home
│   ├── about.astro
│   ├── now.astro
│   ├── contact.astro
│   ├── labs/                lab modules (each lab = one file)
│   ├── reports/             long-form reports
│   ├── notes/               short observations
│   └── rss.xml.js           RSS feed
└── styles/                  CSS tokens + components

public/                      static assets (PDFs, favicon, motion.js)
```

## Deploy

Pushed to `main` → GitHub Actions builds and deploys to GitHub Pages automatically.
