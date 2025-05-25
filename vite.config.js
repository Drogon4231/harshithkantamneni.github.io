import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // 👇 tells Vite every asset lives one folder deep on Pages
  base: '/harshithkantamneni.github.io/',
});
