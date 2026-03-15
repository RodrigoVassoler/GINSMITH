// Gin Aromatics Lab — Service Worker
// github.com/RodrigoVassoler/GINSMITH
const CACHE_VERSION = 'ginsmith-v3';
const STATIC_CACHE  = CACHE_VERSION + '-static';
const DYNAMIC_CACHE = CACHE_VERSION + '-dynamic';

// Files to pre-cache on install (relative paths — work both locally and on Pages)
const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json',
];

// CDN patterns to cache on first fetch
const CDN_PATTERNS = [
  'unpkg.com/react@18',
  'unpkg.com/react-dom@18',
  'unpkg.com/@babel/standalone',
  'unpkg.com/jspdf',
  'unpkg.com/qrcode',
  'fonts.googleapis.com',
  'fonts.gstatic.com',
];

// GitHub raw — cache icons, network-first for JSON data files
const GITHUB_RAW = 'raw.githubusercontent.com/RodrigoVassoler/GINSMITH';

// ── Install ────────────────────────────────────────────────────────────────────
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => {
        // addAll can fail if any URL 404s — use individual puts to be safe
        return Promise.allSettled(
          PRECACHE_URLS.map(url =>
            fetch(url).then(res => {
              if (res.ok) cache.put(url, res);
            }).catch(() => {})
          )
        );
      })
      .then(() => self.skipWaiting())
  );
});

// ── Activate: purge old caches ─────────────────────────────────────────────────
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys()
      .then(names => Promise.all(
        names
          .filter(n => n.startsWith('ginsmith-') && n !== STATIC_CACHE && n !== DYNAMIC_CACHE)
          .map(n => caches.delete(n))
      ))
      .then(() => self.clients.claim())
  );
});

// ── Fetch strategy ─────────────────────────────────────────────────────────────
self.addEventListener('fetch', event => {
  const url = event.request.url;

  if (event.request.method !== 'GET') return;
  if (url.startsWith('chrome-extension://')) return;

  // GitHub raw JSON (botanicals.json, recipes.json) → Network-First
  // so updates land immediately; fall back to cache if offline
  if (url.includes(GITHUB_RAW) && url.endsWith('.json')) {
    event.respondWith(
      fetch(event.request)
        .then(res => {
          if (res && res.status === 200) {
            const clone = res.clone();
            caches.open(DYNAMIC_CACHE).then(c => c.put(event.request, clone));
          }
          return res;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // GitHub raw icons → Cache-First (icons don't change often)
  if (url.includes(GITHUB_RAW) && !url.endsWith('.json')) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        if (cached) return cached;
        return fetch(event.request).then(res => {
          if (res && res.status === 200) {
            caches.open(DYNAMIC_CACHE).then(c => c.put(event.request, res.clone()));
          }
          return res;
        }).catch(() => new Response('', { status: 404 }));
      })
    );
    return;
  }

  // CDN + same-origin → Cache-First with background revalidation
  const isCacheable = CDN_PATTERNS.some(p => url.includes(p))
    || url.includes(self.location.origin);

  if (isCacheable) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        const networkFetch = fetch(event.request).then(res => {
          if (res && res.status === 200) {
            caches.open(DYNAMIC_CACHE).then(c => c.put(event.request, res.clone()));
          }
          return res;
        }).catch(() => cached || new Response('', { status: 503 }));

        return cached || networkFetch;
      })
    );
  }
});

self.addEventListener('message', event => {
  if (event.data === 'skipWaiting') self.skipWaiting();
});
