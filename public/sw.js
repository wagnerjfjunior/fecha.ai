// FECH.AI Service Worker v2
// Build: 1777216430065
const CACHE_NAME = 'fech-ai-shell-v2-1777216430065';

// Apenas assets estáticos do shell — nunca dados da API
const SHELL_URLS = ['/', '/index.html', '/manifest.json'];

// URLs que NUNCA devem ser cacheadas
function shouldSkip(url) {
  const u = new URL(url);
  // Toda requisição para o Supabase
  if (u.hostname.includes('supabase.co')) return true;
  // Endpoints de API por path
  if (u.pathname.includes('/rest/v1')) return true;
  if (u.pathname.includes('/rpc/'))    return true;
  if (u.pathname.includes('/auth/v1')) return true;
  if (u.pathname.includes('/storage/v1')) return true;
  // Outros serviços externos
  if (u.hostname !== self.location.hostname) return true;
  return false;
}

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME)
      .then(c => c.addAll(SHELL_URLS))
      .catch(err => console.warn('[SW] shell cache parcial:', err))
  );
  // Forçar ativação imediata sem esperar tabs fecharem
  self.skipWaiting();
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(k => k !== CACHE_NAME)
          .map(k => { console.log('[SW] removendo cache antigo:', k); return caches.delete(k); })
      )
    )
  );
  // Assumir controle de todas as tabs abertas imediatamente
  self.clients.claim();
});

self.addEventListener('fetch', e => {
  const req = e.request;

  // Ignorar tudo que não seja GET
  if (req.method !== 'GET') return;

  // Ignorar APIs e serviços externos
  if (shouldSkip(req.url)) return;

  e.respondWith(
    fetch(req)
      .then(res => {
        // Cachear apenas respostas 200 de assets estáticos do próprio domínio
        if (res.ok && res.status === 200) {
          const url = new URL(req.url);
          const ext = url.pathname.split('.').pop().toLowerCase();
          const staticExts = ['js','css','html','png','jpg','jpeg','svg','ico','woff','woff2','ttf'];
          if (staticExts.includes(ext) || url.pathname === '/' || url.pathname === '/index.html') {
            const clone = res.clone();
            caches.open(CACHE_NAME).then(c => c.put(req, clone));
          }
        }
        return res;
      })
      .catch(() =>
        // Offline: servir do cache ou fallback para index.html (SPA)
        caches.match(req).then(cached => cached || caches.match('/index.html'))
      )
  );
});
