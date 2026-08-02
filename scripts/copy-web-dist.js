// 將 Godot web 版(含 silk-bg.js)複製進 dist/,
// 讓 dist/ 成為完整可部署目錄:/ 是 3D 開場,/web_export/ 是遊戲本體。
import { cpSync } from 'node:fs';

cpSync('web_export', 'dist/web_export', { recursive: true });
console.log('Copied web_export -> dist/web_export');
