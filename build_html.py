#!/usr/bin/env python3
"""
Gin Aromatics Lab — HTML builder
Reads aroma_neural_net.jsx and produces index.html with correct repo URLs
"""
import sys, os

REPO_USER = "RodrigoVassoler"
REPO_NAME = "GINSMITH"
REPO_RAW  = f"https://raw.githubusercontent.com/{REPO_USER}/{REPO_NAME}/main"
PAGES_URL = f"https://{REPO_USER}.github.io/{REPO_NAME}"

JSX_PATH  = os.path.join(os.path.dirname(__file__), "aroma_neural_net.jsx")

with open(JSX_PATH, "r", encoding="utf-8") as f:
    jsx = f.read()

app_code = jsx \
    .replace('import { useState, useMemo, useEffect, useCallback } from "react";\n', '') \
    .replace('export default function App(){', 'function App(){')
app_code = 'const { useState, useMemo, useEffect, useCallback } = React;\n' + app_code
app_code = app_code.replace(
    'const GITHUB_RAW_URL = "";',
    f'const GITHUB_RAW_URL = "{REPO_RAW}/botanicals.json";'
)

HTML = f'''<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
  <meta name="theme-color" content="#060c06">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="Gin Lab">
  <meta name="description" content="Gin Aromatics Lab — perfil aromático de botânicos para gin e coquetéis">
  <title>Gin Aromatics Lab</title>
  <link rel="manifest" href="manifest.json">
  <link rel="apple-touch-icon" href="icons/icon-192.png">
  <style>
    * {{ margin:0; padding:0; box-sizing:border-box; }}
    html, body, #root {{ height:100%; }}
    body {{ background:#060c06; color:#e0f0e0; overflow-x:hidden; }}
    #install-banner {{
      display:none; position:fixed; bottom:0; left:0; right:0; z-index:9999;
      background:linear-gradient(135deg,#0d2208,#091609);
      border-top:1px solid #2a5a1a; padding:12px 20px;
      align-items:center; gap:12px;
      font-family:'DM Mono',monospace; font-size:12px; color:#a0da60;
    }}
    #install-banner.visible {{ display:flex; }}
    #install-banner button {{
      background:linear-gradient(135deg,#1c4a0c,#12300a);
      border:1px solid #3a7a1a; color:#a0da60; padding:7px 18px;
      border-radius:7px; cursor:pointer;
      font-family:'DM Mono',monospace; font-size:11px; letter-spacing:0.5px;
    }}
    #install-close {{ margin-left:auto; background:transparent; border:none; color:#305030; font-size:18px; cursor:pointer; }}
    #offline-bar {{
      display:none; position:fixed; top:0; left:0; right:0; z-index:9998;
      background:#3a1a0a; border-bottom:1px solid #7a3a1a;
      padding:6px; text-align:center;
      font-family:'DM Mono',monospace; font-size:10px; color:#d07040; letter-spacing:1px;
    }}
  </style>
</head>
<body>
  <div id="offline-bar">⚡ MODO OFFLINE — dados locais</div>
  <div id="root"></div>

  <div id="install-banner">
    <span>🌿</span>
    <div>
      <div style="font-weight:500">Instalar Gin Aromatics Lab</div>
      <div style="font-size:10px;color:#5a9a3a;margin-top:2px">Funciona offline · acesso direto da tela inicial</div>
    </div>
    <button id="install-btn">⬇ Instalar</button>
    <button id="install-close">✕</button>
  </div>

  <!-- Core deps via CDN -->
  <script crossorigin src="https://unpkg.com/react@18/umd/react.production.min.js"></script>
  <script crossorigin src="https://unpkg.com/react-dom@18/umd/react-dom.production.min.js"></script>
  <script src="https://unpkg.com/@babel/standalone/babel.min.js"></script>
  <!-- PDF export -->
  <script src="https://unpkg.com/jspdf@2.5.1/dist/jspdf.umd.min.js"></script>

  <script>
    // ── Service Worker ──────────────────────────────────────────────────────
    if ('serviceWorker' in navigator) {{
      window.addEventListener('load', () => {{
        navigator.serviceWorker.register('sw.js')
          .then(r => console.log('[SW] registered:', r.scope))
          .catch(e => console.warn('[SW] error:', e));
      }});
    }}

    // ── Offline indicator ───────────────────────────────────────────────────
    function updateOnlineStatus() {{
      document.getElementById('offline-bar').style.display = navigator.onLine ? 'none' : 'block';
    }}
    window.addEventListener('online',  updateOnlineStatus);
    window.addEventListener('offline', updateOnlineStatus);
    updateOnlineStatus();

    // ── PWA Install prompt ──────────────────────────────────────────────────
    let deferredPrompt;
    const banner = document.getElementById('install-banner');
    window.addEventListener('beforeinstallprompt', (e) => {{
      e.preventDefault();
      deferredPrompt = e;
      banner.classList.add('visible');
    }});
    document.getElementById('install-btn').addEventListener('click', async () => {{
      if (!deferredPrompt) return;
      deferredPrompt.prompt();
      await deferredPrompt.userChoice;
      deferredPrompt = null;
      banner.classList.remove('visible');
    }});
    document.getElementById('install-close').addEventListener('click', () => banner.classList.remove('visible'));
    window.addEventListener('appinstalled', () => {{ banner.classList.remove('visible'); deferredPrompt = null; }});

    // ── Storage API (localStorage + in-memory fallback) ─────────────────────
    window.storage = {{
      _store: {{}},
      async get(key) {{
        try {{
          const raw = localStorage.getItem('ginlab_' + key);
          if (raw === null) throw new Error('not found');
          return {{ key, value: raw }};
        }} catch(e) {{
          if (this._store[key] !== undefined) return {{ key, value: this._store[key] }};
          throw e;
        }}
      }},
      async set(key, value) {{
        this._store[key] = value;
        try {{ localStorage.setItem('ginlab_' + key, value); }} catch(e) {{}}
        return {{ key, value }};
      }},
      async delete(key) {{
        delete this._store[key];
        try {{ localStorage.removeItem('ginlab_' + key); }} catch(e) {{}}
        return {{ key, deleted: true }};
      }},
      async list(prefix) {{
        const keys = Object.keys(localStorage)
          .filter(k => k.startsWith('ginlab_' + (prefix || '')))
          .map(k => k.replace('ginlab_', ''));
        return {{ keys }};
      }}
    }};
  </script>

  <!-- App (JSX transpiled by Babel in browser — no build step needed) -->
  <script type="text/babel" data-presets="react">
{app_code}

    const root = ReactDOM.createRoot(document.getElementById('root'));
    root.render(React.createElement(App));
  </script>
</body>
</html>'''

out_path = os.path.join(os.path.dirname(__file__), "index.html")
with open(out_path, "w", encoding="utf-8") as f:
    f.write(HTML)

kb = len(HTML.encode()) / 1024
print(f"✓ index.html gerado: {kb:.0f} KB")
print(f"  Repo: {REPO_RAW}")
print(f"  Pages: {PAGES_URL}")
