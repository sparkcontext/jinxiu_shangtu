import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    host: true,
    headers: {
      // Required by the Godot 4 web export (SharedArrayBuffer) in web_export/
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    },
  },
  preview: {
    host: true,
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    },
  },
  build: {
    outDir: 'dist',
  },
});
