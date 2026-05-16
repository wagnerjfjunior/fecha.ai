/**
 * TabFluxo.jsx
 * Aba de montagem do fluxo de pagamento.
 * Preview: seleciona uma unidade real extraída do parser antes de abrir o FluxoBuilder.
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
  if (sinal > 0) fluxo.e.push(atoQtd <= 1 ? { id: 'ato', label: 'Ato', date: '', value: sinal, meta: 'tabela parser', source: 'parser' } : { id: 'ato', label: 'Ato', qty: atoQtd, value: sinal, dateStart: '', meta: 'tabela parser', isGroup: true, source: 'parser' });
  if (complemento > 0 && compQtd > 0) {
    const labels = ['+30 dias', '+60 dias', '+90 dias', '+120 dias', '+150 dias', '+180 dias'];
    for (let i = 0; i < compQtd; i += 1) fluxo.c.push({ id: `c${i + 1}`, label: labels[i] || `Compl. ${i + 1}`, date: '', value: complemento, meta: 'tabela parser', source: 'parser' });
  }
  if (mensalEach > 0 && mensalQtd > 0) fluxo.m.push({ id: 'm1', label: 'Mensais', qty: mensalQtd, value: mensalEach, dateStart: meta.mensal_inicio || '', meta: 'tabela parser', isGroup: true, source: 'parser' });
  if (interEach > 0 && interQtd > 0) {
    const per = interTipo.includes('semestral') ? 'semestral' : 'anual';
    fluxo.a.push({ id: 'a1', label: per === 'semestral' ? 'Semestrais' : 'Anuais', qty: interQtd, value: interEach, dateStart: meta.anual_inicio || '', meta: per === 'semestral' ? 'semestral · parser' : 'anual · parser', isGroup: true, per, source: 'parser' });
  }
  if (chavesEach > 0 && unicaQtd > 0) fluxo.u.push(unicaQtd <= 1 ? { id: 'u1', label: 'Parcela única', date: meta.unica || '', value: chavesEach, meta: 'tabela parser', source: 'parser' } : { id: 'u1', label: 'Chaves', qty: unicaQtd, value: chavesEach, dateStart: meta.unica || '', meta: 'tabela parser', isGroup: true, source: 'parser' });
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
    <div className={`rounded-xl px-3 py-2 ${colors}`}>
      <p className="text-[10px] font-semibold uppercase tracking-wide opacity-80">{label}</p>
      <p className="text-[12px] font-bold">{unit ? `Un. ${unit.unidade} · ${moneyBR(unit.valor_tabela)}` : '—'}</p>
      {unit?.final && <p className="text-[10px] opacity-75">Final {unit.final}</p>}
    </div>
  );
}

function UnidadeCard({ unidade: unidadeInput, onSelect, condoMin, condoMax, finalMin, finalMax }) {
  const unidade = enrichUnit(unidadeInput);
  const resumo = fluxoResumo(unidade);
  if (!unidade.id && !unidade.unidade) return null;
  const badges = [];
  if (unidade.id === condoMin?.id) badges.push('💚 menor do condomínio');
  if (unidade.id === condoMax?.id) badges.push('👑 maior do condomínio');
  if (unidade.id === finalMin?.id) badges.push('⬇️ menor da prumada');
  if (unidade.id === finalMax?.id) badges.push('⬆️ maior da prumada');
  const basics = formatUnitBasics(unidade);
  const ref = unidade.face || '';

  return (
    <button onClick={() => onSelect(unidade)} className="w-full text-left rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] hover:border-[var(--color-border-secondary)] p-3 transition-all">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="text-[15px] font-semibold text-[var(--color-text-primary)]">Unidade {unidade.unidade || '—'}</p>
          <p className="text-[12px] text-[var(--color-text-secondary)] mt-0.5">
            Final {unidade.final || '—'} · {numberBR(unidade.metragem, ' m²')}
          </p>
          {basics && <p className="text-[12px] text-[var(--color-text-primary)] mt-1">{basics}</p>}
          <p className="text-[12px] text-[#0F6E56] mt-1">
            {unidade.orientacao_calc.label}{ref ? ` · ${ref}` : ''}
          </p>
          {unidade.vista && <p className="text-[11px] text-[var(--color-text-tertiary)] mt-1">{unidade.vista}</p>}
          {unidade.torre && <p className="text-[10px] text-[var(--color-text-tertiary)] mt-1">Torre {unidade.torre}{unidade.andar !== null && unidade.andar !== undefined ? ` · ${unidade.andar}º andar` : ''}</p>}
        </div>
        <div className="text-right flex-none"><p className="text-[14px] font-bold text-[#0F6E56]">{moneyBR(unidade.valor_tabela)}</p><p className="text-[10px] text-[var(--color-text-tertiary)]">tabela parser</p></div>
      </div>
      {badges.length > 0 && <div className="flex flex-wrap gap-1 mt-2">{badges.map(b => <span key={b} className="rounded-full bg-[#E1F5EE] text-[#0F6E56] px-2 py-1 text-[10px] font-semibold">{b}</span>)}</div>}
      {resumo && <div className="mt-3 rounded-xl bg-[#E1F5EE] text-[#0F6E56] px-3 py-2 text-[11px] leading-relaxed">Fluxo parser: {resumo}</div>}
      <div className="mt-3 rounded-xl bg-[#FAEEDA] text-[#412402] px-3 py-2 text-[11px] leading-relaxed">⚠️ {unidade.aviso || 'Disponibilidade ainda não validada pelo espelho de vendas.'}</div>
    </button>
  );
}

function EnriquecimentoModal({ empreendimento, finais, unidades, onClose, onSave, saving, error }) {
  const [finalSelecionado, setFinalSelecionado] = useState(finais[0] || '');
  const unidadesDoFinal = useMemo(() => unidades.filter(u => u.final === finalSelecionado), [unidades, finalSelecionado]);
  const exemplo = unidadesDoFinal[0] || {};
  const [form, setForm] = useState({ dormitorios: '', suites: '', vagasQuantidade: '', orientacaoSolar: '', face: '', vista: '', observacoes: '' });

  useEffect(() => {
    const base = unidades.find(u => u.final === finalSelecionado) || {};
    setForm({
      dormitorios: base.dormitorios_calc ?? base.dormitorios ?? '',
      suites: base.suites ?? '',
      vagasQuantidade: base.vagas_quantidade ?? '',
      orientacaoSolar: base.orientacao_solar || base.orientacao_calc?.value || '',
      face: base.face || '',
      vista: base.vista || '',
      observacoes: '',
    });
  }, [finalSelecionado, unidades]);

  const setField = (field, value) => setForm(prev => ({ ...prev, [field]: value }));

  const handleSave = async () => {
    if (!finalSelecionado) return;
    await onSave({
      empreendimentoId: empreendimento.id,
      final: finalSelecionado,
      dormitorios: toIntOrNull(form.dormitorios),
      suites: toIntOrNull(form.suites),
      vagasQuantidade: toIntOrNull(form.vagasQuantidade),
      orientacaoSolar: form.orientacaoSolar || null,
      face: form.face || null,
      vista: form.vista || null,
      observacoes: form.observacoes || null,
    });
  };

  return (
    <div className="fixed inset-0 z-[9999] bg-black/40 flex items-end sm:items-center justify-center p-3" onClick={onClose}>
      <div className="w-full max-w-[760px] max-h-[88vh] overflow-y-auto rounded-3xl bg-[var(--color-background-primary)] shadow-2xl border border-[var(--color-border-tertiary)]" onClick={e => e.stopPropagation()}>
        <div className="sticky top-0 bg-[var(--color-background-primary)] border-b border-[var(--color-border-tertiary)] p-4 flex items-start justify-between gap-3 rounded-t-3xl">
          <div>
            <p className="text-[16px] font-bold text-[var(--color-text-primary)]">Completar dados das unidades</p>
            <p className="text-[12px] text-[var(--color-text-tertiary)]">{empreendimento.nome} · dados por final/prumada</p>
          </div>
          <button onClick={onClose} className="w-8 h-8 rounded-full bg-[var(--color-background-secondary)] text-[18px] leading-none">×</button>
        </div>

        <div className="p-4 grid gap-4">
          <div className="rounded-2xl bg-[#E6F1FB] text-[#042C53] px-3 py-3 text-[12px] leading-relaxed">
            Escolha o final e preencha somente o que souber. O card da unidade vai ocultar campos vazios automaticamente.
          </div>

          <div>
            <p className="text-[11px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)] mb-2">Finais encontrados</p>
            <div className="flex flex-wrap gap-2">
              {finais.map(f => (
                <button
                  key={f}
                  onClick={() => setFinalSelecionado(f)}
                  className={`px-3 py-2 rounded-xl text-[12px] font-semibold border ${finalSelecionado === f ? 'bg-[#0F6E56] border-[#0F6E56] text-white' : 'bg-[var(--color-background-secondary)] border-[var(--color-border-tertiary)] text-[var(--color-text-secondary)]'}`}
                >
                  Final {f}
                </button>
              ))}
            </div>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-1 gap-3">
            <div className="rounded-2xl border border-[var(--color-border-tertiary)] p-3">
              <p className="text-[11px] text-[var(--color-text-tertiary)]">Prévia do card</p>
              <p className="text-[15px] font-semibold mt-2">Unidade {exemplo.unidade || '—'}</p>
              <p className="text-[12px] text-[var(--color-text-secondary)]">Final {finalSelecionado || '—'} · {numberBR(exemplo.metragem, ' m²')}</p>
              <p className="text-[12px] mt-1">
                {[form.dormitorios && `${form.dormitorios} dorms`, form.suites && `${form.suites} suíte${Number(form.suites) > 1 ? 's' : ''}`, form.vagasQuantidade && `${form.vagasQuantidade} vaga${Number(form.vagasQuantidade) > 1 ? 's' : ''}`].filter(Boolean).join(' · ') || 'Tipologia não informada'}
              </p>
              <p className="text-[12px] text-[#0F6E56] mt-1">{solLabel(form.orientacaoSolar).label}{form.face ? ` · ${form.face}` : ''}</p>
              {form.vista && <p className="text-[11px] text-[var(--color-text-tertiary)] mt-1">{form.vista}</p>}
              <p className="text-[10px] text-[var(--color-text-tertiary)] mt-3">Afeta {unidadesDoFinal.length} unidade(s) deste final.</p>
            </div>

            <div className="grid gap-3">
              <div className="grid grid-cols-3 gap-2">
                <label className="grid gap-1 text-[11px] text-[var(--color-text-tertiary)]">Dorms<input value={form.dormitorios} onChange={e => setField('dormitorios', e.target.value)} type="number" min="0" max="10" className="rounded-xl border px-3 py-2 text-[13px] bg-transparent text-[var(--color-text-primary)]" /></label>
                <label className="grid gap-1 text-[11px] text-[var(--color-text-tertiary)]">Suítes<input value={form.suites} onChange={e => setField('suites', e.target.value)} type="number" min="0" max="10" className="rounded-xl border px-3 py-2 text-[13px] bg-transparent text-[var(--color-text-primary)]" /></label>
                <label className="grid gap-1 text-[11px] text-[var(--color-text-tertiary)]">Vagas<input value={form.vagasQuantidade} onChange={e => setField('vagasQuantidade', e.target.value)} type="number" min="0" max="10" className="rounded-xl border px-3 py-2 text-[13px] bg-transparent text-[var(--color-text-primary)]" /></label>
              </div>
              <label className="grid gap-1 text-[11px] text-[var(--color-text-tertiary)]">Sol / orientação
                <select value={form.orientacaoSolar} onChange={e => setField('orientacaoSolar', e.target.value)} className="rounded-xl border px-3 py-2 text-[13px] bg-transparent text-[var(--color-text-primary)]">
                  <option value="">Não informado</option>
                  <option value="manha">🌅 Sol da manhã</option>
                  <option value="tarde">🌇 Sol da tarde</option>
                  <option value="norte">☀️ Face norte</option>
                  <option value="sul">🌤️ Face sul</option>
                  <option value="misto">🌅🌇 Dupla face</option>
                </select>
              </label>
              <label className="grid gap-1 text-[11px] text-[var(--color-text-tertiary)]">Referência da face<input value={form.face} onChange={e => setField('face', e.target.value)} placeholder="Rua Fortunato Ferraz, City Lapa…" className="rounded-xl border px-3 py-2 text-[13px] bg-transparent text-[var(--color-text-primary)]" /></label>
              <label className="grid gap-1 text-[11px] text-[var(--color-text-tertiary)]">Vista / observação comercial<input value={form.vista} onChange={e => setField('vista', e.target.value)} placeholder="Vista livre, frente para Nova Vivere…" className="rounded-xl border px-3 py-2 text-[13px] bg-transparent text-[var(--color-text-primary)]" /></label>
              <label className="grid gap-1 text-[11px] text-[var(--color-text-tertiary)]">Observação interna<input value={form.observacoes} onChange={e => setField('observacoes', e.target.value)} placeholder="Ex.: validado na maquete" className="rounded-xl border px-3 py-2 text-[13px] bg-transparent text-[var(--color-text-primary)]" /></label>
            </div>
          </div>

          {error && <div className="rounded-xl bg-[#FDEAEA] text-[#4B1528] px-3 py-2 text-[12px]">{error}</div>}

          <div className="flex gap-2 justify-end sticky bottom-0 bg-[var(--color-background-primary)] py-3 border-t border-[var(--color-border-tertiary)]">
            <button onClick={onClose} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Cancelar</button>
            <button onClick={handleSave} disabled={saving || !finalSelecionado} className="px-4 py-2 rounded-xl bg-[#0F6E56] text-white text-[13px] font-semibold disabled:opacity-50">{saving ? 'Salvando…' : `Salvar final ${finalSelecionado}`}</button>
          </div>
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
  const [showEnriquecimento, setShowEnriquecimento] = useState(false);

  const unidades = useMemo(() => Array.isArray(unidadesRaw) ? unidadesRaw.filter(u => u && typeof u === 'object').map(enrichUnit) : [], [unidadesRaw]);
  const sortedByPrice = useMemo(() => [...unidades].filter(u => u.valor_num > 0).sort((a,b) => a.valor_num - b.valor_num), [unidades]);
  const condoMin = sortedByPrice[0] || null;
  const condoMax = sortedByPrice[sortedByPrice.length - 1] || null;
  const finais = useMemo(() => [...new Set(unidades.map(u => u.final).filter(Boolean))].sort((a, b) => String(a).localeCompare(String(b), 'pt-BR', { numeric: true })), [unidades]);
  const dorms = useMemo(() => [...new Set(unidades.map(u => u.dormitorios_calc).filter(Boolean))].sort((a,b)=>a-b), [unidades]);
  const sols = useMemo(() => [...new Map(unidades.map(u => [u.orientacao_calc.value, u.orientacao_calc]).filter(([v]) => v)).values()], [unidades]);

  const unidadesFiltradas = useMemo(() => {
    const term = busca.trim().toLowerCase();
    return unidades.filter(u => {
      const matchBusca = !term || [u.unidade, u.torre, u.final, u.andar, u.metragem, u.valor_tabela, u.face, u.vista].some(v => String(v ?? '').toLowerCase().includes(term));
      return matchBusca && (!filtroFinal || u.final === filtroFinal) && (!filtroDorm || String(u.dormitorios_calc) === filtroDorm) && (!filtroSol || u.orientacao_calc.value === filtroSol);
    });
  }, [busca, filtroFinal, filtroDorm, filtroSol, unidades]);

  const byFinal = useMemo(() => {
    const map = new Map();
    for (const final of finais) {
      const arr = unidades.filter(u => u.final === final && u.valor_num > 0).sort((a,b) => a.valor_num - b.valor_num);
      map.set(final, { min: arr[0] || null, max: arr[arr.length - 1] || null });
    }
    return map;
  }, [finais, unidades]);

  const selectedFinalStats = filtroFinal ? byFinal.get(filtroFinal) : null;
  const fluxoParser = useMemo(() => (unidadeSelecionada ? buildFluxoFromParser(unidadeSelecionada) : null), [unidadeSelecionada]);

  const handleSalvarEnriquecimento = async (payload) => {
    await salvarEnriquecimento(payload);
    await reloadUnidades?.();
  };

  if (!empreendimento) return <div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-3"><span className="text-5xl">📋</span><p className="text-[14px] font-medium text-[var(--color-text-secondary)]">Nenhum empreendimento selecionado</p><button onClick={onIrParaEmps} className="mt-2 px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Ir para Empreendimentos</button></div>;
  if (configLoading || unidadesLoading) return <div className="flex items-center justify-center py-12 text-[var(--color-text-tertiary)] text-[13px]">Carregando dados da mesa…</div>;
  if (configError || unidadesError) return <div className="p-4 text-center"><div className="text-4xl mb-3">⚠️</div><p className="text-[14px] font-semibold mb-1">Não foi possível carregar a mesa</p><p className="text-[12px] mb-4">{configError || unidadesError}</p><button onClick={reloadUnidades} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Tentar novamente</button></div>;
  if (saved) return <div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-4"><span className="text-5xl">✅</span><p className="text-[16px] font-semibold">Proposta salva!</p><button onClick={() => { setSaved(null); setUnidadeSelecionada(null); }} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Nova Mesa</button></div>;

  const handleSalvar = async ({ clienteNome, valorTotal, metaObraPct, tabelaProvisoria, metaEspecial, fluxoJson }) => {
    if (!unidadeSelecionada?.id) throw new Error('Selecione uma unidade antes de salvar a mesa.');
    const precisaAprovacao = metaEspecial || (metaObraPct < (config.meta_obra_pct ?? 30));
    const id = await criarSimulacao({ empresaId, empreendimentoId: empreendimento.id, unidadeId: unidadeSelecionada.id, leadId: null, clienteNome: clienteNome || null, valorTotal, metaObraPct, tabelaProvisoria: empreendimento.tabela_tipo === 'trabalho' || tabelaProvisoria, fluxoJson });
    setSaved({ id, precisaAprovacao });
  };

  if (!unidadeSelecionada) return (
    <div className="p-3">
      <div className="flex items-center gap-2 mb-3">
        <button onClick={onVoltar} className="px-3 py-1.5 rounded-xl bg-[var(--color-background-secondary)] text-[12px]">← Voltar</button>
        <div className="min-w-0 flex-1"><p className="text-[15px] font-semibold truncate">{empreendimento.nome}</p><p className="text-[11px] text-[var(--color-text-tertiary)]">Escolha a unidade extraída pelo parser para montar a mesa.</p></div>
        {isGestor && unidades.length > 0 && <button onClick={() => setShowEnriquecimento(true)} className="px-3 py-1.5 rounded-xl bg-[#0F6E56] text-white text-[12px] font-semibold">✨ Completar dados</button>}
      </div>
      <div className="grid grid-cols-2 gap-2 mb-3"><StatCard label="Menor condomínio" unit={condoMin} tone="cheap"/><StatCard label="Maior condomínio" unit={condoMax} tone="expensive"/><StatCard label={filtroFinal ? `Menor final ${filtroFinal}` : 'Menor prumada'} unit={selectedFinalStats?.min || null} tone="cheap"/><StatCard label={filtroFinal ? `Maior final ${filtroFinal}` : 'Maior prumada'} unit={selectedFinalStats?.max || null} tone="expensive"/></div>
      <div className="rounded-2xl border border-[#EF9F27] bg-[#FAEEDA] text-[#412402] p-3 text-[12px] leading-relaxed mb-3">Nesta etapa o espelho de vendas ainda não filtra unidades vendidas. A tela exibe todas as unidades identificadas na tabela comercial.</div>
      <input value={busca} onChange={e => setBusca(e.target.value)} placeholder="Buscar por unidade, torre, andar, metragem, valor, face ou vista…" className="w-full rounded-xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] px-3 py-2 text-[13px] mb-2 outline-none" />
      <div className="grid grid-cols-3 gap-2 mb-3">
        <select value={filtroFinal} onChange={e => setFiltroFinal(e.target.value)} className="rounded-xl border px-2 py-2 text-[12px] bg-transparent"><option value="">Todos finais</option>{finais.map(f => <option key={f} value={f}>Final {f}</option>)}</select>
        <select value={filtroDorm} onChange={e => setFiltroDorm(e.target.value)} className="rounded-xl border px-2 py-2 text-[12px] bg-transparent"><option value="">Todos dorms</option>{dorms.map(d => <option key={d} value={d}>{d} dorms</option>)}</select>
        <select value={filtroSol} onChange={e => setFiltroSol(e.target.value)} className="rounded-xl border px-2 py-2 text-[12px] bg-transparent"><option value="">Todos sóis</option>{sols.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}</select>
      </div>
      {unidades.length === 0 && <div className="text-center py-12 border border-dashed rounded-2xl"><div className="text-4xl mb-3">📭</div><p className="text-[14px] font-semibold">Nenhuma unidade importada</p></div>}
      {unidades.length > 0 && unidadesFiltradas.length === 0 && <div className="text-center py-8 text-[13px] text-[var(--color-text-tertiary)]">Nenhuma unidade encontrada para os filtros.</div>}
      <div className="grid gap-3">{unidadesFiltradas.map(u => { const stats = byFinal.get(u.final) || {}; return <UnidadeCard key={u.id || u.unidade} unidade={u} onSelect={setUnidadeSelecionada} condoMin={condoMin} condoMax={condoMax} finalMin={stats.min} finalMax={stats.max}/>; })}</div>
      {showEnriquecimento && <EnriquecimentoModal empreendimento={empreendimento} finais={finais} unidades={unidades} onClose={() => setShowEnriquecimento(false)} onSave={handleSalvarEnriquecimento} saving={savingEnriquecimento} error={enrichmentError} />}
    </div>
  );

  return (
    <div className="p-3">
      <div className="rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-secondary)] p-3 mb-3 flex items-start justify-between gap-3"><div><p className="text-[12px] text-[var(--color-text-tertiary)]">Unidade selecionada</p><p className="text-[14px] font-semibold">{empreendimento.nome} · Unidade {unidadeSelecionada.unidade}</p><p className="text-[11px] text-[var(--color-text-tertiary)]">{moneyBR(unidadeSelecionada.valor_tabela)} · {numberBR(unidadeSelecionada.metragem, ' m²')} · {unidadeSelecionada.orientacao_calc?.label}</p>{fluxoParser && <p className="text-[11px] text-[#0F6E56] mt-1">Fluxo iniciado com os valores reais extraídos da tabela.</p>}</div><button onClick={() => setUnidadeSelecionada(null)} className="px-3 py-1.5 rounded-xl bg-[var(--color-background-primary)] text-[12px]">Trocar</button></div>
      {saveError && <div className="bg-[#FDEAEA] text-[#4B1528] rounded-xl px-3 py-2 text-[12px] mb-3">{saveError}</div>}{saving && <div className="bg-[#E1F5EE] text-[#0F6E56] rounded-xl px-3 py-2 text-[12px] mb-3">Salvando proposta…</div>}
      <FluxoBuilder empreendimento={empreendimento} unidade={unidadeSelecionada} precoTotal={Number(unidadeSelecionada.valor_tabela)} empresaConfig={config} tabelaProvisoria={empreendimento.tabela_tipo === 'trabalho'} initialFluxo={fluxoParser} fluxoOrigem={fluxoParser ? 'parser' : 'padrao'} onSalvar={handleSalvar} onVoltar={() => setUnidadeSelecionada(null)} />
    </div>
  );
}
