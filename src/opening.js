import { startSilkBackground, SILK_THEMES } from './silk-bg.js';

/**
 * 《錦繡商途》3D 開場畫面
 * 絲綢背景由 silk-bg.js 提供;此檔負責日夜氛圍切換、進場、按鈕與轉場。
 *
 * 主題優先順序:?theme= URL 參數 > localStorage 記憶 > 預設夜。
 * 選擇會寫入 localStorage,並在進入遊戲時帶到載入頁。
 */

const THEME_KEY = 'jinxiu-theme';

function readStoredTheme() {
  try {
    const t = localStorage.getItem(THEME_KEY);
    return SILK_THEMES[t] ? t : null;
  } catch {
    return null;
  }
}

// ---------- 初始主題 ----------
const params = new URLSearchParams(window.location.search);
const paramTheme = SILK_THEMES[params.get('theme')] ? params.get('theme') : null;
const initialTheme = paramTheme || readStoredTheme() || 'night';

const silk = startSilkBackground(document.getElementById('scene'), {
  interactive: true,
  theme: initialTheme,
});

// ---------- 日夜切換 ----------
const btnDay = document.getElementById('theme-day');
const btnNight = document.getElementById('theme-night');

function applyTheme(name, instant = false) {
  silk.setTheme(name, instant);
  document.documentElement.dataset.theme = name;
  btnDay.classList.toggle('active', name === 'day');
  btnNight.classList.toggle('active', name === 'night');
  try { localStorage.setItem(THEME_KEY, name); } catch { /* 隱私模式等情況忽略 */ }
}

btnDay.addEventListener('click', () => applyTheme('day'));
btnNight.addEventListener('click', () => applyTheme('night'));
applyTheme(initialTheme, true); // 立即套用初始主題,不做漸變

// ---------- 進場與轉場 ----------
const overlay = document.getElementById('overlay');
const fade = document.getElementById('fade');

requestAnimationFrame(() => overlay.classList.add('show'));

let leaving = false;
document.getElementById('enter-btn').addEventListener('click', () => {
  if (leaving) return;
  leaving = true;
  overlay.classList.add('leaving');
  fade.classList.add('on');

  // 鏡頭緩緩推進絲綢
  let push = 0;
  const pushTimer = setInterval(() => {
    push += 0.02;
    silk.setCameraPush(push);
    if (push >= 1) clearInterval(pushTimer);
  }, 16);

  // 把目前氛圍帶進遊戲載入頁
  const gameUrl = `/web_export/index.html?theme=${silk.getTheme()}`;
  setTimeout(() => { window.location.href = gameUrl; }, 1100);
});
