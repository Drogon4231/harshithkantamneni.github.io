import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// Site is served at https://drogon4231.github.io/harshithkantamneni.github.io/
// because the GitHub username (Drogon4231) does not match the repo name.
// All internal links must be prefixed with the base path.
export default defineConfig({
  site: 'https://drogon4231.github.io',
  base: '/harshithkantamneni.github.io',
  integrations: [sitemap()],
  build: {
    format: 'directory',
  },
  trailingSlash: 'ignore',
});
