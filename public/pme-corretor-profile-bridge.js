/*
 * FECH.AI — PME Corretor Profile Bridge
 * Version: 0.1.1
 * Scope: frontend-only bridge for PME template variables.
 * Safety: read-only; no automatic sending; no Supabase/RPC/RLS/Auth/DB changes.
 */
(function () {
  'use strict';

  const PROFILE_KEY = 'fechai_pme_corretor_profile';
  const LEGACY_KEYS = {
    nome: ['fechai_corretor_nome', 'fechai_pme_corretor_nome'],
    telefone: ['fechai_corretor_telefone', 'fechai_pme_corretor_telefone'],
    whatsapp: ['fechai_corretor_whatsapp', 'fechai_pme_link_whatsapp_corretor'],
    empresa: ['fechai_corretor_empresa', 'fechai_pme_corretor_empresa']
  };

  function safeGet(key, fallback) {
    try {
      const value = window.localStorage.getItem(key);
      return value == null || value === '' ? fallback : value;
    } catch (_) {
      return fallback;
    }
  }

  function safeSet(key, value) {
    try {
      if (value == null || value === '') return;
      window.localStorage.setItem(key, String(value));
    } catch (_) {}
  }

  function clean(value) {
    return String(value || '').trim();
  }

  function onlyDigits(value) {
    return String(value || '').replace(/\D/g, '');
  }

  function normalizePhone(value) {
    let digits = onlyDigits(value);
    if (!digits) return '';
    if (digits.length === 10 || digits.length === 11) digits = '55' + digits;
    return digits;
  }

  function formatPhone(value) {
    const digits = onlyDigits(value);
    if (!digits) return '';
    const br = digits.startsWith('55') ? digits.slice(2) : digits;
    if (br.length === 11) return `(${br.slice(0, 2)}) ${br.slice(2, 7)}-${br.slice(7)}`;
    if (br.length === 10) return `(${br.slice(0, 2)}) ${br.slice(2, 6)}-${br.slice(6)}`;
    return value;
  }

  function firstNonEmpty(obj, keys) {
    for (const key of keys) {
      const value = clean(obj && obj[key]);
      if (value) return value;
    }
    return '';
  }

  function pickProfile(raw) {
    const source = raw || {};
    const nome = firstNonEmpty(source, ['apelido', 'nome', 'name']);
    const telefoneRaw = firstNonEmpty(source, ['telefone_prof']);
    const empresa = firstNonEmpty(source, ['empresa']);
    const telefone = formatPhone(telefoneRaw);
    const normalizedPhone = normalizePhone(telefoneRaw);
    const whatsapp = normalizedPhone ? `https://wa.me/${normalizedPhone}` : '';

    return {
      nome,
      telefone,
      whatsapp,
      empresa,
      source: 'corretores'
    };
  }

  function publish(profile) {
    const p = pickProfile(profile);
    if (!p.nome && !p.telefone && !p.whatsapp && !p.empresa) return null;

    window.FECHAI_PME_CORRETOR_PROFILE = p;
    safeSet(PROFILE_KEY, JSON.stringify(p));

    safeSet(LEGACY_KEYS.nome[0], p.nome);
    safeSet(LEGACY_KEYS.nome[1], p.nome);
    safeSet(LEGACY_KEYS.telefone[0], p.telefone);
    safeSet(LEGACY_KEYS.telefone[1], p.telefone);
    safeSet(LEGACY_KEYS.whatsapp[0], p.whatsapp);
    safeSet(LEGACY_KEYS.whatsapp[1], p.whatsapp);
    safeSet(LEGACY_KEYS.empresa[0], p.empresa);
    safeSet(LEGACY_KEYS.empresa[1], p.empresa);

    window.dispatchEvent(new CustomEvent('fechai:pme-corretor-profile-ready', { detail: p }));
    return p;
  }

  function readSession() {
    try {
      return JSON.parse(window.localStorage.getItem('fechai_session') || 'null');
    } catch (_) {
      return null;
    }
  }

  async function fetchProfile() {
    const session = readSession();
    const userId = session && session.user && session.user.id;
    const token = session && session.access_token;
    const supabaseUrl = window.FECHAI_SUPABASE_URL;
    const anonKey = window.FECHAI_SUPABASE_ANON_KEY;

    if (!userId || !token || !supabaseUrl || !anonKey) return null;

    // Query intencionalmente mínima: somente colunas já usadas pela própria tela do corretor.
    // Evita quebrar o preview quando uma coluna opcional ainda não existe no schema.
    const columns = ['nome', 'apelido', 'telefone_prof', 'empresa'].join(',');
    const url = `${supabaseUrl}/rest/v1/corretores?user_id=eq.${encodeURIComponent(userId)}&select=${encodeURIComponent(columns)}&limit=1`;

    const response = await fetch(url, {
      headers: {
        apikey: anonKey,
        Authorization: `Bearer ${token}`,
        Accept: 'application/json'
      }
    });

    if (!response.ok) return null;
    const rows = await response.json();
    return Array.isArray(rows) && rows.length ? rows[0] : null;
  }

  function hydrateFromStorage() {
    try {
      const stored = JSON.parse(safeGet(PROFILE_KEY, 'null'));
      if (stored) publish(stored);
    } catch (_) {}
  }

  async function hydrate() {
    hydrateFromStorage();

    try {
      const profile = await fetchProfile();
      if (profile) publish(profile);
    } catch (_) {
      // Ponte não bloqueia o uso do discador. Em caso de erro, o módulo legado segue com fallback.
    }
  }

  window.FECHAI_PME_PROFILE_BRIDGE = {
    hydrate,
    publish,
    pickProfile
  };

  hydrate();
  window.addEventListener('storage', hydrate);
  window.addEventListener('focus', hydrate);
})();
