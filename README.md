# 錦繡商途 (Jinxiu Shangtu)

A Godot 4 visual novel game set in the world of Qing Dynasty commerce.

## 🌐 Play Online

https://jinxiu-shangtu.vercel.app/

## 📦 Web Export

The `web_export/` folder contains the Godot 4 HTML5 build. It is deployed automatically to Vercel via GitHub integration.

### Vercel Config

`vercel.json` sets required COOP/COEP headers for Godot 4's SharedArrayBuffer / threading support:

```json
{
  "outputDirectory": "web_export",
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "Cross-Origin-Opener-Policy", "value": "same-origin" },
        { "key": "Cross-Origin-Embedder-Policy", "value": "require-corp" }
      ]
    }
  ]
}
```

## ⚡ Optimization Notes

| File | Size | Notes |
|------|------|-------|
| `index.wasm` | ~42 MB | Godot 4 web runtime — unavoidable |
| `index.pck` | ~22 MB | Game data — ** dominated by NotoSansSC fonts (22 MB)** |
| `index.js` | ~360 KB | Engine loader |

**Font optimization opportunity:**
`assets/fonts/NotoSansSC-Regular.ttf` and `NotoSansSC-Bold.ttf` are 11 MB each. 
To reduce `.pck` size significantly, subset the fonts to only the characters used in the game 
(e.g. with [fonttools/pyftsubset](https://github.com/fonttools/fonttools) or [Glyphhanger](https://github.com/filamentgroup/glyphhanger)) 
before importing into Godot.

## 🛠️ Local Preview

```bash
cd web_export
node serve.js --port 7100
```

The custom server adds required `Cross-Origin-Opener-Policy` and `Cross-Origin-Embedder-Policy` headers.
