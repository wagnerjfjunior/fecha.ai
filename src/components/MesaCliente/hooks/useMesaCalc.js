/**
 * useMesaCalc.js
 * Hook puro de cálculo da Mesa Cliente.
 * Sem dependências externas. Totalmente testável.
 * Princípio: "Cérebro no Banco, Braço no Front" — este hook só
 * faz cálculos de UX; a validação oficial é feita pelo RPC criar_mesa_simulacao.
 */

import { useState, useCallback, useMemo, useEffect } from 'react';

// ─── Formatação ────────────────────────────────────────────────
export const fmtBRL = (n) =>
  'R$ ' + Math.round(n || 0).toLocaleString('pt-BR');

export const fmtBRLShort = (n) => fmtBRL(n);

function normalizeInitialFluxo(initialFluxo, precoTotal) {
  if (!initialFluxo || typeof initialFluxo !== 'object') return defaultFluxo(precoTotal);
  const normalized = {
    e: Array.isArray(initialFluxo.e) ? initialFluxo.e : [],
    c: Array.isArray(initialFluxo.c) ? initialFluxo.c : [],
    m: Array.isArray(initialFluxo.m) ? initialFluxo.m : [],
    a: Array.isArray(initialFluxo.a) ? initialFluxo.a : [],
    u: Array.isArray(initialFluxo.u) ? initialFluxo.u : [],
  };

  if (!normalized.e.length && !normalized.c.length && !normalized.m.length && !normalized.a.length && !normalized.u.length) {
    return defaultFluxo(precoTotal);
  }

  return normalized;
}

// ─── Estado padrão ─────────────────────────────────────────────
export function defaultFluxo(precoTotal = 850000) {
  return {
    e: [{ id: 'ato', label: 'Ato', date: '', value: Math.round(precoTotal * 0.1), meta: 'assinatura' }],
    c: [
      { id: 'c1', label: '+30 dias', date: '', value: Math.round(precoTotal * 0.03), meta: '' },
      { id: 'c2', label: '+60 dias', date: '', value: Math.round(precoTotal * 0.03), meta: '' },
      { id: 'c3', label: '+90 dias', date: '', value: Math.round(precoTotal * 0.03), meta: '' },
    ],
    m: [{ id: 'm1', label: 'Mensais', qty: 36, value: Math.round((precoTotal * 0.04) / 36), dateStart: '', meta: 'durante a obra', isGroup: true }],
    a: [{ id: 'a1', label: 'Anuais', qty: 3, value: Math.round(precoTotal * 0.03), dateStart: '', meta: 'dez · 13º', isGroup: true, per: 'anual' }],
    u: [],
  };
}

// ─── Cálculos ──────────────────────────────────────────────────
export function calcGroupTotal(items) {
  return (items || []).reduce((s, t) => s + (t.isGroup ? (t.value || 0) * (t.qty || 0) : (t.value || 0)), 0);
}

export function calcTotais(state, precoTotal) {
  const vE = calcGroupTotal(state.e);
  const vC = calcGroupTotal(state.c);
  const vM = calcGroupTotal(state.m);
  const vA = calcGroupTotal(state.a);
  const vU = calcGroupTotal(state.u);

  // obra = parcelas regulares do fluxo antes do financiamento.
  // pagamentoFluxo = tudo que não entra no financiamento, incluindo parcela única/chaves.
  const obra = vE + vC + vM + vA;
  const pagamentoFluxo = obra + vU;
  const fin = Math.max(0, precoTotal - pagamentoFluxo);
  const obraPct = precoTotal > 0 ? (obra / precoTotal) * 100 : 0;
  const pagamentoPct = precoTotal > 0 ? (pagamentoFluxo / precoTotal) * 100 : 0;
  const finPct = precoTotal > 0 ? (fin / precoTotal) * 100 : 0;

  return { vE, vC, vM, vA, vU, obra, pagamentoFluxo, fin, obraPct, pagamentoPct, finPct };
}

export function calcBarStatus(pagamentoPct, metaPct) {
  if (pagamentoPct >= metaPct) return 'ok';
  if (pagamentoPct >= metaPct - 5) return 'yellow';
  return 'red';
}

// ─── Serialização para o RPC ───────────────────────────────────
export function serializarFluxo(state) {
  const items = [];
  const add = (grupo, tiles) =>
    tiles.forEach((t) =>
      items.push({
        grupo,
        id: t.id,
        label: t.label,
        valor: t.value || 0,
        qty: t.qty || 1,
        total: t.isGroup ? (t.value || 0) * (t.qty || 1) : (t.value || 0),
        date: t.date || t.dateStart || null,
        periodicidade: t.per || null,
        isGroup: t.isGroup || false,
        source: t.source || null,
      })
    );
  add('e', state.e);
  add('c', state.c);
  add('m', state.m);
  add('a', state.a);
  add('u', state.u);
  return items;
}

// ─── Hook principal ────────────────────────────────────────────
let _counter = 100;
const nextId = () => 'n' + (++_counter);

export function useMesaCalc({ precoTotal = 850000, metaPct = 30, metaEspecial = null, initialFluxo = null, resetKey = '' } = {}) {
  const [state, setState] = useState(() => normalizeInitialFluxo(initialFluxo, precoTotal));
  const [selected, setSelected] = useState(null); // { g, id }

  useEffect(() => {
    setState(normalizeInitialFluxo(initialFluxo, precoTotal));
    setSelected(null);
  }, [precoTotal, resetKey]);

  const metaAtual = metaEspecial !== null ? metaEspecial : metaPct;
  const pagamentoTarget = (precoTotal * metaAtual) / 100;

  const totais = useMemo(() => calcTotais(state, precoTotal), [state, precoTotal]);
  const barStatus = useMemo(() => calcBarStatus(totais.pagamentoPct, metaAtual), [totais.pagamentoPct, metaAtual]);

  const surplus = totais.pagamentoFluxo >= pagamentoTarget ? totais.pagamentoFluxo - pagamentoTarget : 0;
  const deficit = totais.pagamentoFluxo < pagamentoTarget ? pagamentoTarget - totais.pagamentoFluxo : 0;

  const selectTile = useCallback((g, id) => {
    setSelected((prev) => (prev?.g === g && prev?.id === id ? null : { g, id }));
  }, []);

  const closeEditor = useCallback(() => setSelected(null), []);

  const updateField = useCallback((g, id, field, value) => {
    setState((prev) => {
      const group = prev[g].map((t) => {
        if (t.id !== id) return t;
        if (field === 'qty') return { ...t, qty: parseInt(value) || 0 };
        if (field === 'value') return { ...t, value: parseFloat(value) || 0 };
        return { ...t, [field]: value };
      });
      return { ...prev, [g]: group };
    });
  }, []);

  const updatePeriodicidade = useCallback((g, id, per) => {
    setState((prev) => ({
      ...prev,
      [g]: prev[g].map((t) =>
        t.id !== id ? t : {
          ...t,
          per,
          label: per === 'semestral' ? 'Semestrais' : 'Anuais',
          meta: per === 'semestral' ? 'semestral' : 'dez · 13º',
        }
      ),
    }));
  }, []);

  const removeTile = useCallback((g, id) => {
    setState((prev) => ({ ...prev, [g]: prev[g].filter((t) => t.id !== id) }));
    setSelected((prev) => (prev?.g === g && prev?.id === id ? null : prev));
  }, []);

  const addTile = useCallback((g) => {
    const id = nextId();
    setState((prev) => {
      let newTile;
      if (g === 'c') {
        const n = prev.c.length + 1;
        const dias = [30, 60, 90, 120, 150, 180][n - 1] || n * 30;
        newTile = { id, label: `+${dias} dias`, date: '', value: Math.round(precoTotal * 0.03), meta: '' };
      } else if (g === 'm') {
        newTile = { id, label: 'Mensais', qty: 36, value: Math.round((precoTotal * 0.04) / 36), dateStart: '', meta: 'durante a obra', isGroup: true };
      } else if (g === 'a') {
        newTile = { id, label: 'Anuais', qty: 3, value: Math.round(precoTotal * 0.03), dateStart: '', meta: 'dez · 13º', isGroup: true, per: 'anual' };
      } else if (g === 'u') {
        newTile = { id, label: 'Parcela única', date: '', value: 0, meta: 'chaves / antes do financiamento' };
      } else {
        newTile = { id, label: 'Parcela', date: '', value: 0, meta: '' };
      }
      return { ...prev, [g]: [...prev[g], newTile] };
    });
    setSelected({ g, id });
  }, [precoTotal]);

  const reset = useCallback(() => {
    setState(normalizeInitialFluxo(initialFluxo, precoTotal));
    setSelected(null);
  }, [precoTotal, initialFluxo]);

  return {
    state,
    selected,
    totais,
    barStatus,
    surplus,
    deficit,
    obraTarget: pagamentoTarget,
    pagamentoTarget,
    metaAtual,
    // actions
    selectTile,
    closeEditor,
    updateField,
    updatePeriodicidade,
    removeTile,
    addTile,
    reset,
    serializarFluxo: () => serializarFluxo(state),
  };
}
