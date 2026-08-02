// 端到端重現使用者流程:開場頁 → 點「進入遊戲」→ 等待遊戲載入 → 檢查最終畫面
// 使用本機安裝的 Chrome(headless),目標為 Vercel 線上版本。
import { chromium } from 'playwright-core';

const CHROME = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const BASE = process.env.TARGET || 'https://jinxiu-shangtu.vercel.app';
const LOAD_TIMEOUT_MS = 240000;

const consoleLogs = [];
const pageErrors = [];

const browser = await chromium.launch({
  executablePath: CHROME,
  headless: true,
  args: ['--window-size=1440,900'],
});
const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
page.on('console', (msg) => consoleLogs.push(`[${msg.type()}] ${msg.text()}`));
page.on('pageerror', (err) => pageErrors.push(String(err)));

console.log('1) 開啟開場頁:', BASE);
await page.goto(BASE + '/', { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(4000);
await page.screenshot({ path: 'e2e_1_opening.png' });
console.log('   開場頁截圖完成');

console.log('2) 點擊「進入遊戲」');
await page.click('#enter-btn');
await page.waitForURL('**/web_export/index.html**', { timeout: 15000 });
console.log('   已跳轉:', page.url());
await page.waitForTimeout(3000);
await page.screenshot({ path: 'e2e_2_loading.png' });

console.log('3) 等待遊戲載入完成(#status 消失),最長', LOAD_TIMEOUT_MS / 1000, '秒');
let loaded = true;
try {
  await page.waitForSelector('#status', { state: 'detached', timeout: LOAD_TIMEOUT_MS });
} catch {
  loaded = false;
}
const pct = await page.evaluate(() => document.getElementById('ls-percent')?.textContent || '(overlay gone)');
console.log('   載入結果:', loaded ? '完成' : '逾時', '| 進度:', pct);

await page.waitForTimeout(5000);
await page.screenshot({ path: 'e2e_3_final.png' });

const state = await page.evaluate(() => {
  const c = document.getElementById('canvas');
  const silk = document.getElementById('silk-bg');
  return {
    canvasExists: !!c,
    canvasSize: c ? `${c.width}x${c.height}` : null,
    canvasStyle: c ? `${c.style.width}x${c.style.height}` : null,
    silkExists: !!silk,
    statusExists: !!document.getElementById('status'),
    crossOriginIsolated: window.crossOriginIsolated,
  };
});
console.log('4) 最終狀態:', JSON.stringify(state));

console.log('--- console(錯誤與警告) ---');
for (const l of consoleLogs.filter((x) => x.startsWith('[error') || x.startsWith('[warn'))) console.log(l);
console.log('--- page errors ---');
for (const e of pageErrors) console.log(e);
console.log('--- console 最後 8 則 ---');
for (const l of consoleLogs.slice(-8)) console.log(l);

await browser.close();
console.log('完成');
