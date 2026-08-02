import { startSilkBackground } from './silk-bg.js';

/**
 * 瀏覽器全域入口 — vite lib 模式打包成 IIFE 後,
 * 任何純 HTML 頁面都能這樣使用:
 *
 *   <canvas id="silk-bg"></canvas>
 *   <script src="silk-bg.js"></script>
 *   <script>
 *     const silk = JinxiuSilk.start(document.getElementById('silk-bg'));
 *     silk.stop(); // 需要時停止
 *   </script>
 */

window.JinxiuSilk = { start: startSilkBackground };
