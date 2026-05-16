/**
 * TabFluxo.jsx
 * Aba de montagem do fluxo de pagamento.
 * Preview: seleciona uma unidade real importada antes de abrir o FluxoBuilder.
 * Enriquecimento manual: não altera parser e não possui regras hardcoded por empreendimento.
 */

import { useEffect, useMemo, useState } from 'react';
import FluxoBuilder from './FluxoBuilder';
import {
  useEmpresaMesaConfig,
  useCriarMesaSimulacao,
  useUnidadesMesa,
  useSalvarMesaClienteEnriquecimento,
} from './hooks/useMesaData';

function moneyBR(value) {
  const n = Number(value || 0);
  return n.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL', minimumFractionDigits: 0, maximumFractionDigits: 0 });
}

function numberBR(value, suffix = '') {
  if (value === null || value === undefined || value === '') return '—';
  return `${Number(value).toLocaleString('pt-BR', { maximumFractionDigits: 2 })}${suffix}`;
}

function toNumber(value) {
  if (value === null || value === undefined || value === '') return 0;
  const raw = String(value).trim();
  if (!raw) return 0;
  let s = raw;
  const hasComma = s.includes(',');
  const hasDot = s.includes('.');
  if (hasComma && hasDot) {
    if (s.lastIndexOf(',') > s.lastIndexOf('.')) s = s.replace(/\./g, '').replace(',', '.');
    else s = s.replace(/,/g, '');
  } else if (hasComma) {
    s = s.replace(/\./g, '').replace(',', '.');
  }
  s = s.replace(/[^0-9.-]/g, '');
  const n = Number.parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}

function safeObj(value) {
  return value && typeof value === 'object' && !Array.isArray(value) ? value : {};
}

function toIntOrNull(value) {
  if (value === null || value === undefined || value === '') return null;
  const n = Number.parseInt(String(value), 10);
  return Number.isFinite(n) ? n : null;
}

function parseObsKV(observacoes = '') {
  const out = {};
  const text = typeof observacoes === 'string' ? observacoes : String(observacoes ?? '');
  text.split('|').forEach(part => {
    const [k, ...rest] = String(part || '').split('=');
    const key = String(k || '').trim();
    if (!key) return;
    out[key] = rest.join('=').trim();
  });
  return out;
}

function parsePayloadFromObservacoes(observacoes = '') {
  const text = typeof observacoes === 'string' ? observacoes : String(observacoes ?? '');
  const marker = 'Payload:';
  const idx = text.indexOf(marker);
  if (idx < 0) return null;
  const payloadText = text.slice(idx + marker.length).trim();
  if (!payloadText.startsWith('{')) return null;
  try { return safeObj(JSON.parse(payloadText)); } catch { return null; }
}

function getPayloadRaw(unidadeInput = {}) {
  const unidade = safeObj(unidadeInput);
  const payload = safeObj(parsePayloadFromObservacoes(unidade.observacoes));
  return { unidade, payload, raw: safeObj(payload.raw || payload), meta: parseObsKV(payload.observacoes || unidade.observacoes || '') };
}

function inferDormitorios(unidadeInput = {}) {
  const { unidade, raw } = getPayloadRaw(unidadeInput);
  const direct = toNumber(unidade.dormitorios ?? raw.dormitorios ?? raw.dorms ?? raw.quartos);
  if (direct > 0) return Math.trunc(direct);
  const text = `${unidade.planta_tipo || ''} ${unidade.observacoes || ''} ${raw.tipologia || ''} ${raw.planta || ''}`.toLowerCase();
  const match = text.match(/(\d+)\s*(dorm|dormit[oó]rio|quarto|su[ií]te)/i);
  return match ? Number(match[1]) : null;
}

function solLabel(value) {
  const v = String(value || '').toLowerCase();
  if (v === 'manha' || v === 'nascente' || v === 'leste') return { value: v || 'manha', label: '🌅 Sol da manhã' };
  if (v === 'tarde' || v === 'poente' || v === 'oeste') return { value: v || 'tarde', label: '🌇 Sol da tarde' };
  if (v === 'norte') return { value: v, label: '☀️ Face norte' };
  if (v === 'sul') return { value: v, label: '🌤️ Face sul' };
  if (v === 'misto') return { value: v, label: '🌅🌇 Dupla face' };
  return { value: '', label: '🧭 Sol não informado' };
}

function inferOrientacao(unidadeInput = {}) {
  const { unidade, raw } = getPayloadRaw(unidadeInput);
  const direct = unidade.orientacao_solar || unidade.orientacao || unidade.sol || raw.orientacao_solar || raw.orientacao || raw.sol;
  if (direct) return solLabel(direct);
  const text = `${unidade.face || ''} ${unidade.vista || ''} ${unidade.observacoes || ''} ${raw.face || ''}`.toLowerCase();
  if (/nascente|manh[aã]|leste|fortunato/.test(text)) return { value: 'manha', label: '🌅 Sol da manhã' };
  if (/poente|tarde|oeste|city\s*lapa/.test(text)) return { value: 'tarde', label: '🌇 Sol da tarde' };
  if (/norte/.test(text)) return { value: 'norte', label: '☀️ Face norte' };
  if (/sul/.test(text)) return { value: 'sul', label: '🌤️ Face sul' };
  return { value: '', label: '🧭 Sol não informado' };
}

function enrichUnit(u) {
  const unidade = safeObj(u);
  return {
    ...unidade,
    dormitorios_calc: inferDormitorios(unidade),
    orientacao_calc: inferOrientacao(unidade),
    valor_num: Number(unidade.valor_tabela || 0),
  };
}

function buildFluxoFromParser(unidadeInput = {}) {
  const { unidade, payload, raw, meta } = getPayloadRaw(unidadeInput);
  if (!unidade.id && !unidade.observacoes) return null;
  const sinal = toNumber(raw.sinal_1 ?? payload.sinal_1);
  const complemento = toNumber(raw.a4_each ?? payload.a4_each);
  const mensalEach = toNumber(raw.mensal_each ?? payload.mensal_each);
  const interEach = toNumber(raw.inter_each ?? payload.inter_each);
  const chavesEach = toNumber(raw.chaves_each ?? payload.chaves_each);
  const atoQtd = Number.parseInt(meta.ato_qtd || '1', 10) || 1;
  const compQtd = Number.parseInt(meta.comp_qtd || '0', 10) || 0;
  const mensalQtd = Number.parseInt(raw.mensal_qtd || payload.mensal_qtd || meta.mensal_qtd || '0', 10) || 0;
  const interQtd = Number.parseInt(raw.inter_qtd || payload.inter_qtd || meta.inter_qtd || '0', 10) || 0;
  const unicaQtd = Number.parseInt(meta.unica_qtd || raw.unica_qtd || payload.unica_qtd || '0', 10) || 0;
  const interTipo = String(raw.inter_tipo || payload.inter_tipo || '').toLowerCase();
  const fluxo = { e: [], c: [], m: [], a: [], u: [] };
  if (sinal > 0) fluxo.e.push(atoQtd <= 1 ? { id: 'ato', label: 'Ato', date: '', value: sinal, meta: 'valor da tabela', source: 'parser' } : { id: 'ato', label: 'Ato', qty: atoQtd, value: sinal, dateStart: '', meta: 'valor da tabela', isGroup: true, source: 'parser' });
  if (complemento > 0 && compQtd > 0) {
    const labels = ['+30 dias', '+60 dias', '+90 dias', '+120 dias', '+150 dias', '+180 dias'];
    for (let i = 0; i < compQtd; i += 1) fluxo.c.push({ id: `c${i + 1}`, label: labels[i] || `Compl. ${i + 1}`, date: '', value: complemento, meta: 'valor da tabela', source: 'parser' });
  }
  if (mensalEach > 0 && mensalQtd > 0) fluxo.m.push({ id: 'm1', label: 'Mensais', qty: mensalQtd, value: mensalEach, dateStart: meta.mensal_inicio || '', meta: 'valor da tabela', isGroup: true, source: 'parser' });
  if (interEach > 0 && interQtd > 0) {
    const per = interTipo.includes('semestral') ? 'semestral' : 'anual';
    fluxo.a.push({ id: 'a1', label: per === 'semestral' ? 'Semestrais' : 'Anuais', qty: interQtd, value: interEach, dateStart: meta.anual_inicio || '', meta: per === 'semestral' ? 'semestral · tabela' : 'anual · tabela', isGroup: true, per, source: 'parser' });
  }
  if (chavesEach > 0 && unicaQtd > 0) fluxo.u.push(unicaQtd <= 1 ? { id: 'u1', label: 'Parcela única', date: meta.unica || '', value: chavesEach, meta: 'valor da tabela', source: 'parser' } : { id: 'u1', label: 'Chaves', qty: unicaQtd, value: chavesEach, dateStart: meta.unica || '', meta: 'valor da tabela', isGroup: true, source: 'parser' });
  return Object.values(fluxo).some(arr => arr.length > 0) ? fluxo : null;
}

function fluxoResumo(unidadeInput = {}) {
  const { unidade, payload, raw, meta } = getPayloadRaw(unidadeInput);
  if (!unidade.id && !unidade.observacoes) return '';
  const parts = [];
  const sinal = toNumber(raw.sinal_1 ?? payload.sinal_1);
  const complemento = toNumber(raw.a4_each ?? payload.a4_each);
  const mensalEach = toNumber(raw.mensal_each ?? payload.mensal_each);
  const interEach = toNumber(raw.inter_each ?? payload.inter_each);
  const chavesEach = toNumber(raw.chaves_each ?? payload.chaves_each);
  const financiamento = toNumber(raw.financiamento ?? payload.financiamento);
  const compQtd = Number.parseInt(meta.comp_qtd || '0', 10) || 0;
  const mensalQtd = Number.parseInt(raw.mensal_qtd || payload.mensal_qtd || meta.mensal_qtd || '0', 10) || 0;
  const interQtd = Number.parseInt(raw.inter_qtd || payload.inter_qtd || meta.inter_qtd || '0', 10) || 0;
  const unicaQtd = Number.parseInt(meta.unica_qtd || raw.unica_qtd || payload.unica_qtd || '0', 10) || 0;
  if (sinal > 0) parts.push(`Ato ${moneyBR(sinal)}`);
  if (complemento > 0 && compQtd > 0) parts.push(`${compQtd} compl. de ${moneyBR(complemento)}`);
  if (mensalEach > 0 && mensalQtd > 0) parts.push(`${mensalQtd} mensais de ${moneyBR(mensalEach)}`);
  if (interEach > 0 && interQtd > 0) parts.push(`${interQtd} interm. de ${moneyBR(interEach)}`);
  if (chavesEach > 0 && unicaQtd > 0) parts.push(`${unicaQtd} chaves de ${moneyBR(chavesEach)}`);
  if (financiamento > 0) parts.push(`Fin. ${moneyBR(financiamento)}`);
  return parts.join(' · ');
}

function formatUnitBasics(unidade) {
  const parts = [];
  const dorms = unidade.dormitorios_calc ?? unidade.dormitorios;
  if (dorms) parts.push(`${dorms} dorms`);
  if (unidade.suites) parts.push(`${unidade.suites} suíte${Number(unidade.suites) > 1 ? 's' : ''}`);
  if (unidade.vagas_quantidade) parts.push(`${unidade.vagas_quantidade} vaga${Number(unidade.vagas_quantidade) > 1 ? 's' : ''}`);
  return parts.join(' · ');
}

function StatCard({ label, unit, tone = 'neutral' }) {
  const colors = tone === 'cheap' ? 'bg-[#E1F5EE] text-[#0F6E56]' : tone === 'expensive' ? 'bg-[#FEF0EB] text-[#7C3B20]' : 'bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)]';
  return (
    <div className={`rounded-2xl px-4 py-3 ${colors}`}>
      <p className="text-[12px] font-bold uppercase tracking-wide opacity-80">{label}</p>
      <p className="text-[16px] font-bold mt-1">{unit ? `Un. ${unit.unidade} · ${moneyBR(unit.valor_tabela)}` : '—'}</p>
      {unit?.final && <p className="text-[12px] opacity-75">Final {unit.final}</p>}
    </div>
  );
}

function UnidadeCard({ unidade: unidadeInput, onSelect, condoMin, condoMax, finalMin, finalMax }) {
  const unidade = enrichUnit(unidadeInput);
  const resumo = fluxoResumo(unidade);
  if (!unidade.id && !unidade.unidade) return null;
  const badges = [];
  if (unidade.id === condoMin?.id) badges.push('💚 menor valor');
  if (unidade.id === condoMax?.id) badges.push('👑 maior valor');
  if (unidade.id === finalMin?.id) badges.push('⬇️ menor da prumada');
  if (unidade.id === finalMax?.id) badges.push('⬆️ maior da prumada');
  const basics = formatUnitBasics(unidade);
  const ref = unidade.face || '';
  return (
    <button onClick={() => onSelect(unidade)} className="w-full text-left rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] hover:border-[#0F6E56] hover:shadow-md p-4 transition-all">
      <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
        <div className="min-w-0 flex-1">
          <p className="text-[20px] sm:text-[19px] font-bold text-[var(--color-text-primary)] leading-tight">Unidade {unidade.unidade || '—'}</p>
          <p className="text-[15px] text-[var(--color-text-secondary)] mt-1 leading-relaxed">Final {unidade.final || '—'} · {numberBR(unidade.metragem, ' m²')}</p>
          {basics && <p className="text-[15px] text-[var(--color-text-primary)] mt-2 leading-relaxed">{basics}</p>}
          <p className="text-[15px] text-[#0F6E56] mt-2 font-medium leading-relaxed">{unidade.orientacao_calc.label}{ref ? ` · ${ref}` : ''}</p>
          {unidade.vista && <p className="text-[13px] text-[var(--color-text-tertiary)] mt-1 leading-relaxed">{unidade.vista}</p>}
          {unidade.torre && <p className="text-[12px] text-[var(--color-text-tertiary)] mt-1">Torre {unidade.torre}{unidade.andar !== null && unidade.andar !== undefined ? ` · ${unidade.andar}º andar` : ''}</p>}
        </div>
        <div className="text-left sm:text-right flex-none border-t sm:border-t-0 border-[var(--color-border-tertiary)] pt-3 sm:pt-0">
          <p className="text-[20px] sm:text-[18px] font-bold text-[#0F6E56] leading-tight">{moneyBR(unidade.valor_tabela)}</p>
          <p className="text-[12px] text-[var(--color-text-tertiary)] mt-0.5">Valor de Tabela</p>
        </div>
      </div>
      {badges.length > 0 && <div className="flex flex-wrap gap-1.5 mt-3">{badges.map(b => <span key={b} className="rounded-full bg-[#E1F5EE] text-[#0F6E56] px-2.5 py-1 text-[12px] font-semibold">{b}</span>)}</div>}
      {resumo && <div className="mt-3 rounded-xl bg-[#E1F5EE] text-[#0F6E56] px-3 py-2 text-[13px] leading-relaxed">Fluxo sugerido: {resumo}</div>}
      <div className="mt-3 rounded-xl bg-[#FAEEDA] text-[#412402] px-3 py-2 text-[12px] leading-relaxed">⚠️ {unidade.aviso || 'Disponibilidade ainda não validada pelo espelho de vendas.'}</div>
    </button>
  );
}

function EnriquecimentoModal({ empreendimento, finais, unidades, onClose, onSave, saving, error }) {
  const [finaisSelecionados, setFinaisSelecionados] = useState(finais[0] ? [finais[0]] : []);
  const [form, setForm] = useState({ dormitorios: '', suites: '', vagasQuantidade: '', orientacaoSolar: '', face: '', vista: '', observacoes: '' });
  const unidadesAfetadas = useMemo(() => unidades.filter(u => finaisSelecionados.includes(u.final)), [unidades, finaisSelecionados]);
  const exemplo = unidadesAfetadas[0] || {};
  const metragemResumo = useMemo(() => [...new Set(unidadesAfetadas.map(u => numberBR(u.metragem, ' m²')).filter(Boolean))].slice(0, 6), [unidadesAfetadas]);

  useEffect(() => {
    if (finaisSelecionados.length !== 1) return;
    const base = unidades.find(u => u.final === finaisSelecionados[0]) || {};
    setForm({ dormitorios: base.dormitorios_calc ?? base.dormitorios ?? '', suites: base.suites ?? '', vagasQuantidade: base.vagas_quantidade ?? '', orientacaoSolar: base.orientacao_solar || base.orientacao_calc?.value || '', face: base.face || '', vista: base.vista || '', observacoes: '' });
  }, [finaisSelecionados, unidades]);

  const setField = (field, value) => setForm(prev => ({ ...prev, [field]: value }));
  const toggleFinal = (final) => setFinaisSelecionados(prev => prev.includes(final) ? prev.filter(f => f !== final) : [...prev, final]);
  const selecionarTodos = () => setFinaisSelecionados(finais);
  const limparSelecao = () => setFinaisSelecionados([]);
  const selecionarPorMetragem = (metragem) => { const finaisMetragem = [...new Set(unidades.filter(u => Number(u.metragem) === Number(metragem)).map(u => u.final).filter(Boolean))]; setFinaisSelecionados(finaisMetragem); };
  const metragens = useMemo(() => [...new Set(unidades.map(u => u.metragem).filter(v => v !== null && v !== undefined))].sort((a, b) => Number(a) - Number(b)), [unidades]);
  const inputClass = "rounded-xl border border-slate-300 px-3 py-2 text-[14px] bg-white text-slate-900 outline-none focus:border-[#0F6E56]";
  const labelClass = "grid gap-1 text-[12px] text-slate-600";

  const handleSave = async () => {
    if (finaisSelecionados.length === 0) return;
    await onSave({ empreendimentoId: empreendimento.id, finais: finaisSelecionados, dormitorios: toIntOrNull(form.dormitorios), suites: toIntOrNull(form.suites), vagasQuantidade: toIntOrNull(form.vagasQuantidade), orientacaoSolar: form.orientacaoSolar || null, face: form.face || null, vista: form.vista || null, observacoes: form.observacoes || null });
  };

  return (
    <div className="fixed inset-0 z-[9999] bg-black/55 backdrop-blur-[2px] flex items-end sm:items-center justify-center p-3" onClick={onClose}>
      <div className="w-full max-w-[860px] max-h-[88vh] overflow-y-auto rounded-3xl bg-white text-slate-900 shadow-2xl border border-slate-200" onClick={e => e.stopPropagation()}>
        <div className="sticky top-0 bg-white border-b border-slate-200 p-4 flex items-start justify-between gap-3 rounded-t-3xl"><div><p className="text-[16px] font-bold text-slate-900">Completar dados em lote</p><p className="text-[12px] text-slate-500">{empreendimento.nome} · selecione finais/prumadas e salve uma vez</p></div><button onClick={onClose} className="w-8 h-8 rounded-full bg-slate-100 text-slate-700 text-[18px] leading-none">×</button></div>
        <div className="p-4 grid gap-4 bg-white">
          <div className="rounded-2xl bg-[#E6F1FB] text-[#042C53] px-3 py-3 text-[12px] leading-relaxed">Nenhuma informação de empreendimento está hardcoded. O sistema usa somente os finais e metragens extraídos da tabela importada; o gestor agrupa visualmente e aplica a regra comercial em lote.</div>
          <div className="grid gap-2"><div className="flex items-center justify-between gap-2"><p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">Selecione os finais do mesmo grupo</p><div className="flex gap-2"><button type="button" onClick={selecionarTodos} className="px-3 py-1.5 rounded-xl bg-slate-100 text-slate-700 text-[11px] font-semibold">Todos</button><button type="button" onClick={limparSelecao} className="px-3 py-1.5 rounded-xl bg-slate-100 text-slate-700 text-[11px] font-semibold">Limpar</button></div></div><div className="flex flex-wrap gap-2">{finais.map(f => <button key={f} type="button" onClick={() => toggleFinal(f)} className={`px-3 py-2 rounded-xl text-[12px] font-semibold border ${finaisSelecionados.includes(f) ? 'bg-[#0F6E56] border-[#0F6E56] text-white' : 'bg-slate-100 border-slate-200 text-slate-700'}`}>Final {f}</button>)}</div></div>
          {metragens.length > 0 && <div className="grid gap-2"><p className="text-[11px] font-semibold uppercase tracking-wide text-slate-500">Atalho por metragem extraída</p><div className="flex flex-wrap gap-2">{metragens.map(m => <button key={String(m)} type="button" onClick={() => selecionarPorMetragem(m)} className="px-3 py-2 rounded-xl text-[12px] font-semibold border bg-slate-50 border-slate-200 text-slate-700">{numberBR(m, ' m²')}</button>)}</div></div>}
          <div className="grid grid-cols-2 sm:grid-cols-1 gap-3"><div className="rounded-2xl border border-slate-200 bg-white p-3"><p className="text-[11px] text-slate-500">Prévia do grupo</p><p className="text-[15px] font-semibold mt-2 text-slate-900">{finaisSelecionados.length || 0} final(is) selecionado(s)</p><p className="text-[12px] text-slate-600">{finaisSelecionados.length ? `Finais ${finaisSelecionados.join(', ')}` : 'Nenhum final selecionado'}</p><p className="text-[12px] text-slate-600 mt-1">{metragemResumo.length ? `Metragens: ${metragemResumo.join(', ')}` : 'Metragem não identificada'}</p><p className="text-[12px] mt-2 text-slate-900">{[form.dormitorios && `${form.dormitorios} dorms`, form.suites && `${form.suites} suíte${Number(form.suites) > 1 ? 's' : ''}`, form.vagasQuantidade && `${form.vagasQuantidade} vaga${Number(form.vagasQuantidade) > 1 ? 's' : ''}`].filter(Boolean).join(' · ') || 'Tipologia não informada'}</p><p className="text-[12px] text-[#0F6E56] mt-1">{solLabel(form.orientacaoSolar).label}{form.face ? ` · ${form.face}` : ''}</p>{form.vista && <p className="text-[11px] text-slate-500 mt-1">{form.vista}</p>}<p className="text-[10px] text-slate-500 mt-3">Afeta {unidadesAfetadas.length} unidade(s) da tabela importada.</p>{exemplo.unidade && <p className="text-[10px] text-slate-500 mt-1">Exemplo: unidade {exemplo.unidade}, final {exemplo.final}</p>}</div><div className="grid gap-3"><div className="grid grid-cols-3 gap-2"><label className={labelClass}>Dorms<input value={form.dormitorios} onChange={e => setField('dormitorios', e.target.value)} type="number" min="0" max="10" className={inputClass} /></label><label className={labelClass}>Suítes<input value={form.suites} onChange={e => setField('suites', e.target.value)} type="number" min="0" max="10" className={inputClass} /></label><label className={labelClass}>Vagas<input value={form.vagasQuantidade} onChange={e => setField('vagasQuantidade', e.target.value)} type="number" min="0" max="10" className={inputClass} /></label></div><label className={labelClass}>Sol / orientação<select value={form.orientacaoSolar} onChange={e => setField('orientacaoSolar', e.target.value)} className={inputClass}><option value="">Não informado</option><option value="manha">🌅 Sol da manhã</option><option value="tarde">🌇 Sol da tarde</option><option value="norte">☀️ Face norte</option><option value="sul">🌤️ Face sul</option><option value="misto">🌅🌇 Dupla face</option></select></label><label className={labelClass}>Referência da face<input value={form.face} onChange={e => setField('face', e.target.value)} placeholder="Rua, bairro, praça, city, área interna…" className={inputClass} /></label><label className={labelClass}>Vista / observação comercial<input value={form.vista} onChange={e => setField('vista', e.target.value)} placeholder="Vista livre, frente para torre X, vista interna…" className={inputClass} /></label><label className={labelClass}>Observação interna<input value={form.observacoes} onChange={e => setField('observacoes', e.target.value)} placeholder="Ex.: validado na implantação/maquete" className={inputClass} /></label></div></div>
          {error && <div className="rounded-xl bg-[#FDEAEA] text-[#4B1528] px-3 py-2 text-[12px]">{error}</div>}
          <div className="flex gap-2 justify-end sticky bottom-0 bg-white py-3 border-t border-slate-200"><button onClick={onClose} className="px-4 py-2 rounded-xl bg-slate-100 text-slate-700 text-[13px]">Cancelar</button><button onClick={handleSave} disabled={saving || finaisSelecionados.length === 0} className="px-4 py-2 rounded-xl bg-[#0F6E56] text-white text-[13px] font-semibold disabled:opacity-50">{saving ? 'Salvando…' : `Salvar grupo (${finaisSelecionados.length} finais)`}</button></div>
        </div>
      </div>
    </div>
  );
}

export default function TabFluxo({ sb, token, empresaId, corretorId, isGestor = false, empreendimento, onVoltar, onIrParaEmps }) {
  const { data: config = {}, isLoading: configLoading, error: configError } = useEmpresaMesaConfig({ sb, token, empresaId });
  const { data: unidadesRaw = [], isLoading: unidadesLoading, error: unidadesError, reload: reloadUnidades } = useUnidadesMesa({ sb, token, empreendimentoId: empreendimento?.id });
  const { mutateAsync: criarSimulacao, isLoading: saving, error: saveError } = useCriarMesaSimulacao({ sb, token });
  const { mutateAsync: salvarEnriquecimento, isLoading: savingEnriquecimento, error: enrichmentError } = useSalvarMesaClienteEnriquecimento({ sb, token });
  const [saved, setSaved] = useState(null);
  const [unidadeSelecionada, setUnidadeSelecionada] = useState(null);
  const [busca, setBusca] = useState('');
  const [filtroFinal, setFiltroFinal] = useState('');
  const [filtroDorm, setFiltroDorm] = useState('');
  const [filtroSol, setFiltroSol] = useState('');
  const [valorMin, setValorMin] = useState('');
  const [valorMax, setValorMax] = useState('');
  const [ordenacao, setOrdenacao] = useState('menor_valor');
  const [showEnriquecimento, setShowEnriquecimento] = useState(false);

  const unidades = useMemo(() => Array.isArray(unidadesRaw) ? unidadesRaw.filter(u => u && typeof u === 'object').map(enrichUnit) : [], [unidadesRaw]);
  const sortedByPrice = useMemo(() => [...unidades].filter(u => u.valor_num > 0).sort((a,b) => a.valor_num - b.valor_num), [unidades]);
  const condoMin = sortedByPrice[0] || null;
  const condoMax = sortedByPrice[sortedByPrice.length - 1] || null;
  const finais = useMemo(() => [...new Set(unidades.map(u => u.final).filter(Boolean))].sort((a, b) => String(a).localeCompare(String(b), 'pt-BR', { numeric: true })), [unidades]);
  const dorms = useMemo(() => [...new Set(unidades.map(u => u.dormitorios_calc).filter(Boolean))].sort((a,b)=>a-b), [unidades]);
  const sols = useMemo(() => [...new Map(unidades.map(u => [u.orientacao_calc.value, u.orientacao_calc]).filter(([v]) => v)).values()], [unidades]);
  const byFinal = useMemo(() => { const map = new Map(); for (const final of finais) { const arr = unidades.filter(u => u.final === final && u.valor_num > 0).sort((a,b) => a.valor_num - b.valor_num); map.set(final, { min: arr[0] || null, max: arr[arr.length - 1] || null }); } return map; }, [finais, unidades]);

  const unidadesFiltradas = useMemo(() => {
    const term = busca.trim().toLowerCase();
    const min = toNumber(valorMin);
    const max = toNumber(valorMax);
    let arr = unidades.filter(u => {
      const matchBusca = !term || [u.unidade, u.torre, u.final, u.andar, u.metragem, u.valor_tabela, u.face, u.vista].some(v => String(v ?? '').toLowerCase().includes(term));
      const matchValor = (!min || u.valor_num >= min) && (!max || u.valor_num <= max);
      return matchBusca && matchValor && (!filtroFinal || u.final === filtroFinal) && (!filtroDorm || String(u.dormitorios_calc) === filtroDorm) && (!filtroSol || u.orientacao_calc.value === filtroSol);
    });
    if (ordenacao === 'menor_prumada') arr = arr.filter(u => u.id === byFinal.get(u.final)?.min?.id).sort((a,b) => a.valor_num - b.valor_num);
    else if (ordenacao === 'maior_prumada') arr = arr.filter(u => u.id === byFinal.get(u.final)?.max?.id).sort((a,b) => b.valor_num - a.valor_num);
    else if (ordenacao === 'maior_valor') arr = arr.sort((a,b) => b.valor_num - a.valor_num);
    else arr = arr.sort((a,b) => a.valor_num - b.valor_num);
    return arr;
  }, [busca, filtroFinal, filtroDorm, filtroSol, valorMin, valorMax, ordenacao, unidades, byFinal]);

  const fluxoParser = useMemo(() => (unidadeSelecionada ? buildFluxoFromParser(unidadeSelecionada) : null), [unidadeSelecionada]);
  const handleSalvarEnriquecimento = async (payload) => { const finaisPayload = Array.isArray(payload.finais) && payload.finais.length > 0 ? payload.finais : [payload.final].filter(Boolean); for (const final of finaisPayload) await salvarEnriquecimento({ ...payload, final, finais: undefined }); await reloadUnidades?.(); };

  if (!empreendimento) return <div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-3"><span className="text-5xl">📋</span><p className="text-[15px] font-medium text-[var(--color-text-secondary)]">Nenhum empreendimento selecionado</p><button onClick={onIrParaEmps} className="mt-2 px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[14px]">Ir para Empreendimentos</button></div>;
  if (configLoading || unidadesLoading) return <div className="flex items-center justify-center py-12 text-[var(--color-text-tertiary)] text-[14px]">Carregando dados da mesa…</div>;
  if (configError || unidadesError) return <div className="p-4 text-center"><div className="text-4xl mb-3">⚠️</div><p className="text-[15px] font-semibold mb-1">Não foi possível carregar a mesa</p><p className="text-[13px] mb-4">{configError || unidadesError}</p><button onClick={reloadUnidades} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[14px]">Tentar novamente</button></div>;
  if (saved) return <div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-4"><span className="text-5xl">✅</span><p className="text-[18px] font-semibold">Proposta salva!</p><button onClick={() => { setSaved(null); setUnidadeSelecionada(null); }} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[14px]">Nova Mesa</button></div>;

  const handleSalvar = async ({ clienteNome, valorTotal, metaObraPct, tabelaProvisoria, metaEspecial, fluxoJson }) => {
    if (!unidadeSelecionada?.id) throw new Error('Selecione uma unidade antes de salvar a mesa.');
    const precisaAprovacao = metaEspecial || (metaObraPct < (config.meta_obra_pct ?? 30));
    const id = await criarSimulacao({ empresaId, empreendimentoId: empreendimento.id, unidadeId: unidadeSelecionada.id, leadId: null, clienteNome: clienteNome || null, valorTotal, metaObraPct, tabelaProvisoria: empreendimento.tabela_tipo === 'trabalho' || tabelaProvisoria, fluxoJson });
    setSaved({ id, precisaAprovacao });
  };

  if (!unidadeSelecionada) return (
    <div className="p-4">
      <div className="flex items-center gap-3 mb-4">
        <button onClick={onVoltar} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[14px]">← Voltar</button>
        <div className="min-w-0 flex-1"><p className="text-[18px] font-bold truncate">{empreendimento.nome}</p><p className="text-[14px] text-[var(--color-text-tertiary)]">Escolha uma unidade da tabela importada para montar a proposta com o cliente.</p></div>
        {isGestor && unidades.length > 0 && <button onClick={() => setShowEnriquecimento(true)} className="px-4 py-2 rounded-xl bg-[#0F6E56] text-white text-[14px] font-bold">✨ Completar dados</button>}
      </div>
      <div className="grid grid-cols-2 sm:grid-cols-1 gap-3 mb-3"><StatCard label="Menor valor" unit={condoMin} tone="cheap"/><StatCard label="Maior valor" unit={condoMax} tone="expensive"/></div>
      <div className="rounded-2xl border border-[#EF9F27] bg-[#FAEEDA] text-[#412402] p-4 text-[14px] leading-relaxed mb-4">Nesta etapa o espelho de vendas ainda não filtra unidades vendidas. A tela exibe todas as unidades identificadas na tabela comercial.</div>
      <div className="grid gap-3 mb-4">
        <input value={busca} onChange={e => setBusca(e.target.value)} placeholder="Buscar por unidade, torre, andar, metragem, valor, face ou vista…" className="w-full rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] px-4 py-3 text-[16px] outline-none" />
        <div className="grid grid-cols-4 md:grid-cols-2 sm:grid-cols-1 gap-3">
          <select value={ordenacao} onChange={e => setOrdenacao(e.target.value)} className="rounded-2xl border px-3 py-3 text-[15px] bg-[var(--color-background-primary)]"><option value="menor_valor">Menor valor</option><option value="maior_valor">Maior valor</option><option value="menor_prumada">Menor por prumada</option><option value="maior_prumada">Maior por prumada</option></select>
          <select value={filtroFinal} onChange={e => setFiltroFinal(e.target.value)} className="rounded-2xl border px-3 py-3 text-[15px] bg-[var(--color-background-primary)]"><option value="">Todos finais</option>{finais.map(f => <option key={f} value={f}>Final {f}</option>)}</select>
          <select value={filtroDorm} onChange={e => setFiltroDorm(e.target.value)} className="rounded-2xl border px-3 py-3 text-[15px] bg-[var(--color-background-primary)]"><option value="">Todos dorms</option>{dorms.map(d => <option key={d} value={d}>{d} dorms</option>)}</select>
          <select value={filtroSol} onChange={e => setFiltroSol(e.target.value)} className="rounded-2xl border px-3 py-3 text-[15px] bg-[var(--color-background-primary)]"><option value="">Todos sóis</option>{sols.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}</select>
        </div>
        <div className="grid grid-cols-2 sm:grid-cols-1 gap-3"><input value={valorMin} onChange={e => setValorMin(e.target.value)} placeholder="Valor mínimo" inputMode="numeric" className="rounded-2xl border px-4 py-3 text-[15px] bg-[var(--color-background-primary)]"/><input value={valorMax} onChange={e => setValorMax(e.target.value)} placeholder="Valor máximo" inputMode="numeric" className="rounded-2xl border px-4 py-3 text-[15px] bg-[var(--color-background-primary)]"/></div>
      </div>
      {unidades.length === 0 && <div className="text-center py-12 border border-dashed rounded-2xl"><div className="text-4xl mb-3">📭</div><p className="text-[15px] font-semibold">Nenhuma unidade importada</p></div>}
      {unidades.length > 0 && unidadesFiltradas.length === 0 && <div className="text-center py-8 text-[14px] text-[var(--color-text-tertiary)]">Nenhuma unidade encontrada para os filtros.</div>}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-3">{unidadesFiltradas.map(u => { const stats = byFinal.get(u.final) || {}; return <UnidadeCard key={u.id || u.unidade} unidade={u} onSelect={setUnidadeSelecionada} condoMin={condoMin} condoMax={condoMax} finalMin={stats.min} finalMax={stats.max}/>; })}</div>
      {showEnriquecimento && <EnriquecimentoModal empreendimento={empreendimento} finais={finais} unidades={unidades} onClose={() => setShowEnriquecimento(false)} onSave={handleSalvarEnriquecimento} saving={savingEnriquecimento} error={enrichmentError} />}
    </div>
  );

  return (
    <div className="p-3">
      <div className="rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-secondary)] p-3 mb-3 flex items-start justify-between gap-3"><div><p className="text-[12px] text-[var(--color-text-tertiary)]">Unidade selecionada</p><p className="text-[14px] font-semibold">{empreendimento.nome} · Unidade {unidadeSelecionada.unidade}</p><p className="text-[11px] text-[var(--color-text-tertiary)]">{moneyBR(unidadeSelecionada.valor_tabela)} · {numberBR(unidadeSelecionada.metragem, ' m²')} · {unidadeSelecionada.orientacao_calc?.label}</p>{fluxoParser && <p className="text-[11px] text-[#0F6E56] mt-1">Fluxo iniciado com os valores reais da tabela.</p>}</div><button onClick={() => setUnidadeSelecionada(null)} className="px-3 py-1.5 rounded-xl bg-[var(--color-background-primary)] text-[12px]">Trocar</button></div>
      {saveError && <div className="bg-[#FDEAEA] text-[#4B1528] rounded-xl px-3 py-2 text-[12px] mb-3">{saveError}</div>}{saving && <div className="bg-[#E1F5EE] text-[#0F6E56] rounded-xl px-3 py-2 text-[12px] mb-3">Salvando proposta…</div>}
      <FluxoBuilder empreendimento={empreendimento} unidade={unidadeSelecionada} precoTotal={Number(unidadeSelecionada.valor_tabela)} empresaConfig={config} tabelaProvisoria={empreendimento.tabela_tipo === 'trabalho'} initialFluxo={fluxoParser} fluxoOrigem={fluxoParser ? 'parser' : 'padrao'} onSalvar={handleSalvar} onVoltar={() => setUnidadeSelecionada(null)} />
    </div>
  );
}
