// Gin Aromatics Lab — Service Worker
// Versão do cache: mude para forçar atualização
const CACHE_VERSION = 'gin-lab-v2';
const STATIC_CACHE = CACHE_VERSION + '-static';
const DYNAMIC_CACHE = CACHE_VERSION + '-dynamic';

// Recursos que DEVEM estar em cache para funcionar offline
const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json',
  './icons/icon-192.png',
  './icons/icon-512.png',
];

// CDN resources to cache on first fetch
const CDN_CACHE_PATTERNS = [
  'unpkg.com/react@18',
  'unpkg.com/react-dom@18',
  'unpkg.com/@babel/standalone',
  'unpkg.com/jspdf',
  'unpkg.com/qrcode',
  'fonts.googleapis.com',
  'fonts.gstatic.com',
];

// ── Install: pré-cacheia recursos locais ──────────────────────────────────────
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then((cache) => {
      console.log('[SW] Pre-caching static assets');
      return cache.addAll(PRECACHE_URLS);
    }).then(() => self.skipWaiting())
  );
});

// ── Activate: limpa caches antigos ───────────────────────────────────────────
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) =>
      Promise.all(
        cacheNames
          .filter(name => name.startsWith('gin-lab-') && name !== STATIC_CACHE && name !== DYNAMIC_CACHE)
          .map(name => {
            console.log('[SW] Deleting old cache:', name);
            return caches.delete(name);
          })
      )
    ).then(() => self.clients.claim())
  );
});

// ── Fetch: estratégia Cache-First para estáticos, Network-First para resto ───
self.addEventListener('fetch', (event) => {
  const url = event.request.url;

  // Skip non-GET and chrome-extension
  if (event.request.method !== 'GET') return;
  if (url.startsWith('chrome-extension://')) return;

  const isCDN = CDN_CACHE_PATTERNS.some(p => url.includes(p));
  const isLocal = url.includes(self.location.origin) || url.startsWith('./');

  if (isCDN || isLocal) {
    // Cache-First: serve do cache, faz fetch em background se online
    event.respondWith(
      caches.match(event.request).then((cached) => {
        if (cached) {
          // Revalidate in background if online
          if (navigator.onLine) {
            fetch(event.request).then((response) => {
              if (response && response.status === 200) {
                caches.open(DYNAMIC_CACHE).then(cache => cache.put(event.request, response));
              }
            }).catch(() => {});
          }
          return cached;
        }
        // Not in cache — fetch and store
        return fetch(event.request).then((response) => {
          if (!response || response.status !== 200) return response;
          const cloned = response.clone();
          caches.open(DYNAMIC_CACHE).then(cache => cache.put(event.request, cloned));
          return response;
        }).catch(() => {
          // Offline fallback
          return caches.match('./index.html');
        });
      })
    );
  }
});

// ── Background sync: notifica quando voltar online ───────────────────────────
self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') self.skipWaiting();
});
