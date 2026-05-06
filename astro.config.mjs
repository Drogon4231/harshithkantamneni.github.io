import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://harshithkantamneni.github.io',
  integrations: [sitemap()],
  build: {
    format: 'directory',
  },
  trailingSlash: 'ignore',
});
