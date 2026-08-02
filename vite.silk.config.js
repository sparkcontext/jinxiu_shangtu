import { defineConfig } from 'vite';

// 將絲綢背景打包成單一 IIFE JS,直接輸出到 Godot web 版目錄,
// 讓 web_export/index.html 可以用 <script src="silk-bg.js"> 載入。
export default defineConfig({
  build: {
    outDir: 'web_export',
    emptyOutDir: false, // 重要:web_export 內是 Godot 遊戲檔案,不可清空
    lib: {
      entry: 'src/silk-bg-global.js',
      name: 'JinxiuSilk',
      formats: ['iife'],
      fileName: () => 'silk-bg.js',
    },
  },
});
