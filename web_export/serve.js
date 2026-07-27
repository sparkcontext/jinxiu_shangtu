// 《錦繡商途》Web 版本機預覽伺服器
// Godot 4 Web 匯出需要 COOP/COEP 標頭才能啟用 SharedArrayBuffer
const http = require("http");
const fs = require("fs");
const path = require("path");

// 解析 --port / --host(支援 `--port 7100`、`--port=7100`、PORT 環境變數)
function arg(name, fallback) {
  const i = process.argv.indexOf("--" + name);
  if (i !== -1 && process.argv[i + 1]) return process.argv[i + 1];
  const eq = process.argv.find((a) => a.startsWith("--" + name + "="));
  if (eq) return eq.split("=")[1];
  return fallback;
}
const PORT = Number(arg("port", process.env.PORT || 7100));
const HOST = arg("host", process.env.HOST || "127.0.0.1");

const MIME = {
  ".html": "text/html; charset=utf-8",
  ".js": "application/javascript",
  ".wasm": "application/wasm",
  ".pck": "application/octet-stream",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".json": "application/json",
  ".css": "text/css",
};

http
  .createServer((req, res) => {
    let file = decodeURIComponent(req.url.split("?")[0]);
    if (file === "/") file = "/index.html";
    const full = path.join(__dirname, file);
    if (!full.startsWith(__dirname) || !fs.existsSync(full) || fs.statSync(full).isDirectory()) {
      res.writeHead(404);
      res.end("Not found");
      return;
    }
    res.writeHead(200, {
      "Content-Type": MIME[path.extname(full).toLowerCase()] || "application/octet-stream",
      "Cross-Origin-Opener-Policy": "same-origin",
      "Cross-Origin-Embedder-Policy": "require-corp",
      "Cache-Control": "no-cache",
    });
    fs.createReadStream(full).pipe(res);
  })
  .listen(PORT, HOST, () => {
    console.log(`錦繡商途 Web 版 → http://${HOST}:${PORT}/`);
  });
