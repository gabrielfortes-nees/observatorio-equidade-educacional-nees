import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Base path:
//   - em dev (`npm run dev`): "/"
//   - em build de produção (GitHub Pages): definido pela env BUILD_BASE,
//     normalmente "/observatorio-equidade-educacional-nees/medio/".
//   Isso será fechado na Etapa B junto com o workflow de deploy.
export default defineConfig({
  plugins: [react()],
  base: process.env.BUILD_BASE ?? '/',
  server: { port: 5173 },
});
