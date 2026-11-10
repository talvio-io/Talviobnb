/* TALV IO service worker — installability + offline shell.
   Conservative by design: navigations are network-first (the live mint page
   is never trapped behind a stale cache), only the app shell is precached. */
const CACHE = 'talvio-v2';
const CORE = ['/', '/index.html', '/manifest.webmanifest', '/logo-mark.png', '/icon-192.png', '/icon-512.png'];

self.addEventListener('install', (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(CORE)).then(() => self.skipWaiting()));
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys()
      .then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (e) => {
  if (e.request.method !== 'GET') return;
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request)
        .then((r) => {
          const cp = r.clone();
          caches.open(CACHE).then((c) => c.put('/index.html', cp));
          return r;
        })
        .catch(() => caches.match('/index.html'))
    );
    return;
  }
  const url = new URL(e.request.url);
  if (url.origin === location.origin && CORE.includes(url.pathname)) {
    e.respondWith(caches.match(e.request).then((hit) => hit || fetch(e.request)));
  }
});
