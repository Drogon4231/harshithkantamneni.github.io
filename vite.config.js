// vite.config.js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vite.dev/config/
export default defineConfig({
  // 👇 MUST match the repo name exactly
  base: '/harshithkantamneni.github.io/',
  plugins: [react()],
});
