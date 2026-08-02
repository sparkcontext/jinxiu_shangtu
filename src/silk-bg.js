import * as THREE from 'three';

/**
 * 《錦繡商途》絲綢背景 — 可重用的 Three.js 動態背景模組
 *
 * 用法:
 *   import { startSilkBackground } from './silk-bg.js';
 *   const silk = startSilkBackground(document.getElementById('silk-bg'));
 *   silk.setTheme('day'); // 切換白天金絲緞
 *   silk.stop();          // 停止渲染並釋放資源
 *
 * 選項:
 *   interactive   滑鼠視差與布料互動(預設 true)
 *   particleCount 金色塵光粒子數量(預設 700)
 *   theme         'night'(夜晚燈籠紅,預設)或 'day'(白天金絲緞)
 */

/** 日夜兩種氛圍的配色 */
export const SILK_THEMES = {
  night: {
    background: 0x140808,
    colorA: 0x5c1220, // 深緋(波谷)
    colorB: 0xa32c3d, // 緋紅(波峰)
    colorC: 0xd4a24e, // 金線光澤
    particleA: 0xd4a14f,
    particleB: 0xffe099,
  },
  day: {
    background: 0xf3e8d2, // 宣紙暖白
    colorA: 0xc99e5a, // 金緞陰影
    colorB: 0xefd49b, // 金絲緞面
    colorC: 0xfff7de, // 日光緞光
    particleA: 0xb98a3e,
    particleB: 0xffedc0,
  },
};

const THEME_FADE_SECONDS = 1.0;

export function startSilkBackground(canvas, options = {}) {
  const opts = {
    interactive: true,
    particleCount: 700,
    theme: 'night',
    ...options,
  };

  // ---------- 主題顏色(即時值,切換時會漸變) ----------
  const makeThemeColors = (name) => {
    const t = SILK_THEMES[name] || SILK_THEMES.night;
    return {
      background: new THREE.Color(t.background),
      colorA: new THREE.Color(t.colorA),
      colorB: new THREE.Color(t.colorB),
      colorC: new THREE.Color(t.colorC),
      particleA: new THREE.Color(t.particleA),
      particleB: new THREE.Color(t.particleB),
    };
  };

  const live = makeThemeColors(opts.theme);
  let themeName = SILK_THEMES[opts.theme] ? opts.theme : 'night';
  let themeFrom = null; // 漸變起點
  let themeTo = null;   // 漸變終點
  let themeT = 1;       // 0~1,1 表示無漸變進行中

  // ---------- 渲染器 ----------
  const renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false });
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.setSize(window.innerWidth, window.innerHeight);

  const scene = new THREE.Scene();
  scene.background = live.background;
  scene.fog = new THREE.FogExp2(0x140808, 0.055);
  scene.fog.color = live.background;

  const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 100);
  camera.position.set(0, 0.4, 7.5);

  // ---------- 流動絲綢 ----------
  const silkUniforms = {
    uTime: { value: 0 },
    uMouse: { value: new THREE.Vector2(0, 0) },
    uColorA: { value: live.colorA },
    uColorB: { value: live.colorB },
    uColorC: { value: live.colorC },
  };

  const silkMaterial = new THREE.ShaderMaterial({
    uniforms: silkUniforms,
    side: THREE.DoubleSide,
    transparent: true,
    vertexShader: /* glsl */ `
      uniform float uTime;
      uniform vec2 uMouse;
      varying vec2 vUv;
      varying float vWave;
      varying vec3 vNormal;

      // 疊加數層正弦波,模擬絲綢隨風起伏
      float wave(vec2 p, float t) {
        float w = 0.0;
        w += sin(p.x * 1.6 + t * 0.9) * 0.45;
        w += sin(p.y * 2.3 - t * 0.7) * 0.30;
        w += sin((p.x + p.y) * 3.1 + t * 1.3) * 0.18;
        w += sin(length(p) * 2.2 - t * 0.8) * 0.22;
        return w;
      }

      void main() {
        vUv = uv;
        vec3 pos = position;
        vec2 p = position.xy;
        float t = uTime;

        float w = wave(p + uMouse * 0.6, t);
        pos.z += w * 0.85;

        // 邊緣固定、中央飄動(布的四角像被釘住)
        float pin = smoothstep(0.0, 0.35, uv.x) * smoothstep(1.0, 0.65, uv.x)
                  * smoothstep(0.0, 0.35, uv.y) * smoothstep(1.0, 0.65, uv.y);
        pos.z *= mix(0.25, 1.0, pin);

        // 以數值微分估算法線,讓光澤隨波浪流動
        float e = 0.08;
        float wx = wave(p + vec2(e, 0.0) + uMouse * 0.6, t);
        float wy = wave(p + vec2(0.0, e) + uMouse * 0.6, t);
        vNormal = normalize(vec3(-(wx - w) / e, -(wy - w) / e, 1.0));

        vWave = w;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(pos, 1.0);
      }
    `,
    fragmentShader: /* glsl */ `
      uniform vec3 uColorA;
      uniform vec3 uColorB;
      uniform vec3 uColorC;
      varying vec2 vUv;
      varying float vWave;
      varying vec3 vNormal;

      void main() {
        // 依波峰波谷在深緋與緋紅之間漸變
        float m = smoothstep(-0.9, 0.9, vWave);
        vec3 col = mix(uColorA, uColorB, m);

        // 金線光澤:法線朝向視線時泛起金色絲光
        float sheen = pow(max(dot(normalize(vNormal), vec3(0.0, 0.0, 1.0)), 0.0), 3.0);
        col = mix(col, uColorC, sheen * 0.55);

        // 斜向織紋(細密經緯線)
        float weave = sin((vUv.x + vUv.y) * 220.0) * 0.5 + 0.5;
        col += (weave - 0.5) * 0.045;

        // 邊緣壓暗融入背景
        float edge = smoothstep(0.0, 0.18, vUv.x) * smoothstep(1.0, 0.82, vUv.x)
                   * smoothstep(0.0, 0.18, vUv.y) * smoothstep(1.0, 0.82, vUv.y);
        float alpha = mix(0.35, 1.0, edge);

        gl_FragColor = vec4(col, alpha * 0.96);
      }
    `,
  });

  const silk = new THREE.Mesh(new THREE.PlaneGeometry(14, 9, 160, 110), silkMaterial);
  silk.position.set(0, 0.2, -1.5);
  silk.rotation.x = -0.12;
  scene.add(silk);

  // ---------- 第二層絲綢(遠景,更暗) ----------
  const silkFarMaterial = silkMaterial.clone();
  silkFarMaterial.uniforms = silkUniforms; // 共用時間、滑鼠與主題色
  const silkFar = new THREE.Mesh(new THREE.PlaneGeometry(20, 12, 90, 60), silkFarMaterial);
  silkFar.position.set(-2.5, 1.6, -5.5);
  silkFar.rotation.set(0.15, 0.25, 0.1);
  scene.add(silkFar);

  // ---------- 金色塵光粒子 ----------
  const count = opts.particleCount;
  const pGeo = new THREE.BufferGeometry();
  const positions = new Float32Array(count * 3);
  const speeds = new Float32Array(count);
  const sizes = new Float32Array(count);

  for (let i = 0; i < count; i++) {
    positions[i * 3] = (Math.random() - 0.5) * 16;      // x
    positions[i * 3 + 1] = (Math.random() - 0.5) * 10;  // y
    positions[i * 3 + 2] = (Math.random() - 0.5) * 6;   // z
    speeds[i] = 0.15 + Math.random() * 0.5;
    sizes[i] = 0.5 + Math.random() * 1.6;
  }
  pGeo.setAttribute('position', new THREE.BufferAttribute(positions, 3));
  pGeo.setAttribute('aSpeed', new THREE.BufferAttribute(speeds, 1));
  pGeo.setAttribute('aSize', new THREE.BufferAttribute(sizes, 1));

  const pUniforms = {
    uTime: { value: 0 },
    uColorA: { value: live.particleA },
    uColorB: { value: live.particleB },
  };
  const pMat = new THREE.ShaderMaterial({
    uniforms: pUniforms,
    transparent: true,
    depthWrite: false,
    blending: THREE.AdditiveBlending,
    vertexShader: /* glsl */ `
      uniform float uTime;
      attribute float aSpeed;
      attribute float aSize;
      varying float vFade;

      void main() {
        vec3 pos = position;
        // 緩緩上升,超過頂部後循環回底部
        pos.y = mod(pos.y + uTime * aSpeed + 5.0, 10.0) - 5.0;
        // 輕微左右搖曳
        pos.x += sin(uTime * aSpeed + position.z * 3.0) * 0.25;

        vFade = smoothstep(-5.0, -3.0, pos.y) * smoothstep(5.0, 3.0, pos.y);

        vec4 mv = modelViewMatrix * vec4(pos, 1.0);
        gl_PointSize = aSize * (28.0 / -mv.z);
        gl_Position = projectionMatrix * mv;
      }
    `,
    fragmentShader: /* glsl */ `
      uniform vec3 uColorA;
      uniform vec3 uColorB;
      varying float vFade;
      void main() {
        float d = length(gl_PointCoord - 0.5);
        float glow = smoothstep(0.5, 0.0, d);
        glow *= glow;
        vec3 col = mix(uColorA, uColorB, glow);
        gl_FragColor = vec4(col, glow * vFade * 0.85);
      }
    `,
  });
  scene.add(new THREE.Points(pGeo, pMat));

  // ---------- 滑鼠視差 ----------
  const mouse = new THREE.Vector2(0, 0);
  const mouseTarget = new THREE.Vector2(0, 0);
  const onPointerMove = (e) => {
    mouseTarget.x = (e.clientX / window.innerWidth) * 2 - 1;
    mouseTarget.y = -(e.clientY / window.innerHeight) * 2 + 1;
  };
  if (opts.interactive) window.addEventListener('pointermove', onPointerMove);

  // ---------- 尺寸自適應 ----------
  const onResize = () => {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  };
  window.addEventListener('resize', onResize);

  // ---------- 主題漸變 ----------
  const THEME_KEYS = ['background', 'colorA', 'colorB', 'colorC', 'particleA', 'particleB'];
  const easeInOut = (x) => x * x * (3 - 2 * x);

  function stepTheme(dt) {
    if (themeT >= 1 || !themeFrom || !themeTo) return;
    themeT = Math.min(1, themeT + dt / THEME_FADE_SECONDS);
    const k = easeInOut(themeT);
    for (const key of THEME_KEYS) {
      live[key].copy(themeFrom[key]).lerp(themeTo[key], k);
    }
  }

  // ---------- 動畫迴圈 ----------
  const clock = new THREE.Clock();
  let cameraPush = 0;
  let running = true;
  let rafId = 0;

  function tick() {
    if (!running) return;
    const dt = clock.getDelta();
    const t = clock.elapsedTime;
    stepTheme(dt);

    silkUniforms.uTime.value = t;
    pUniforms.uTime.value = t;

    mouse.lerp(mouseTarget, 0.04);
    silkUniforms.uMouse.value.copy(mouse);

    camera.position.x = mouse.x * 0.55;
    camera.position.y = 0.4 + mouse.y * 0.35;
    // cameraPush: 0 = 正常觀賞位,1 = 推進到絲綢前(轉場)
    camera.position.z = 7.5 + (2.2 - 7.5) * cameraPush;
    camera.lookAt(0, 0.1, -1.5);

    renderer.render(scene, camera);
    rafId = requestAnimationFrame(tick);
  }
  tick();

  // ---------- 對外控制 ----------
  return {
    scene,
    camera,
    renderer,
    /** 目前主題名稱('night' | 'day') */
    getTheme() {
      return themeName;
    },
    /** 切換氛圍:'night' 夜晚燈籠紅 / 'day' 白天金絲緞,顏色自動漸變 */
    setTheme(name, instant = false) {
      if (!SILK_THEMES[name]) return;
      themeName = name;
      themeFrom = {};
      for (const key of THEME_KEYS) themeFrom[key] = live[key].clone();
      themeTo = makeThemeColors(name);
      themeT = instant ? 1 : 0;
      if (instant) {
        for (const key of THEME_KEYS) live[key].copy(themeTo[key]);
      }
    },
    /** 鏡頭向絲綢推進(轉場用),p 為 0~1 */
    setCameraPush(p) {
      cameraPush = Math.min(1, Math.max(0, p));
    },
    /** 停止渲染並釋放 WebGL 資源 */
    stop() {
      running = false;
      cancelAnimationFrame(rafId);
      window.removeEventListener('resize', onResize);
      if (opts.interactive) window.removeEventListener('pointermove', onPointerMove);
      pGeo.dispose();
      pMat.dispose();
      silk.geometry.dispose();
      silkMaterial.dispose();
      silkFar.geometry.dispose();
      silkFarMaterial.dispose();
      renderer.dispose();
    },
  };
}
