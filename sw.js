// Gin Aromatics Lab — Service Worker v3
// github.com/RodrigoVassoler/GINSMITH
const CACHE_VERSION = 'ginsmith-v3';
const STATIC_CACHE  = CACHE_VERSION + '-static';
const DYNAMIC_CACHE = CACHE_VERSION + '-dynamic';

const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png',
];

const CDN_PATTERNS = [
  'unpkg.com/react@18',
  'unpkg.com/react-dom@18',
  'unpkg.com/@babel/standalone',
  'unpkg.com/jspdf',
  'unpkg.com/qrcode',
  'fonts.googleapis.com',
  'fonts.gstatic.com',
];

// ── Install ──────────────────────────────────────────────────────────────────
self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then(cache => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// ── Activate: purge old caches ────────────────────────────────────────────────
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

// ── Fetch: Cache-First for CDN + local, Network-First for GitHub raw ──────────
self.addEventListener('fetch', event => {
  const url = event.request.url;
  if (event.request.method !== 'GET') return;
  if (url.startsWith('chrome-extension://')) return;

  // GitHub raw (botanicals.json, recipes.json) — Network-First so updates land immediately
  if (url.includes('raw.githubusercontent.com')) {
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

  const isCacheable = CDN_PATTERNS.some(p => url.includes(p))
    || url.includes(self.location.origin);

  if (isCacheable) {
    event.respondWith(
      caches.match(event.request).then(cached => {
        if (cached) {
          // Revalidate in background
          if (navigator.onLine) {
            fetch(event.request).then(res => {
              if (res && res.status === 200)
                caches.open(DYNAMIC_CACHE).then(c => c.put(event.request, res));
            }).catch(() => {});
          }
          return cached;
        }
        return fetch(event.request).then(res => {
          if (!res || res.status !== 200) return res;
          const clone = res.clone();
          caches.open(DYNAMIC_CACHE).then(c => c.put(event.request, clone));
          return res;
        }).catch(() => caches.match('./index.html'));
      })
    );
  }
});

self.addEventListener('message', event => {
  if (event.data === 'skipWaiting') self.skipWaiting();
});
