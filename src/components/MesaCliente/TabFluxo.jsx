/**
 * TabFluxo.jsx
 * Aba de montagem do fluxo de pagamento.
 * Preview: seleciona uma unidade real extraída do parser antes de abrir o FluxoBuilder.
 */

import { useMemo, useState } from 'react';
import FluxoBuilder from './FluxoBuilder';
import { useEmpresaMesaConfig, useCriarMesaSimulacao, useUnidadesMesa } from './hooks/useMesaData';

function moneyBR(value) {
  const n = Number(value || 0);
  return n.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL', maximumFractionDigits: 0 });
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

function inferOrientacao(unidadeInput = {}) {
  const { unidade, raw } = getPayloadRaw(unidadeInput);
  const text = `${unidade.orientacao || ''} ${unidade.face || ''} ${unidade.sol || ''} ${unidade.observacoes || ''} ${raw.orientacao || ''} ${raw.face || ''} ${raw.sol || ''}`.toLowerCase();
  if (/nascente|manh[aã]|leste/.test(text)) return { value: 'nascente', label: '🌅 Nascente' };
  if (/poente|tarde|oeste/.test(text)) return { value: 'poente', label: '🌇 Poente' };
  if (/norte/.test(text)) return { value: 'norte', label: '☀️ Norte' };
  if (/sul/.test(text)) return { value: 'sul', label: '🌤️ Sul' };
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

  return (
    <button onClick={() => onSelect(unidade)} className="w-full text-left rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] hover:border-[var(--color-border-secondary)] p-3 transition-all">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-[15px] font-semibold text-[var(--color-text-primary)]">Unidade {unidade.unidade || '—'}</p>
          <p className="text-[11px] text-[var(--color-text-tertiary)] mt-0.5">
            {unidade.torre ? `Torre ${unidade.torre}` : 'Torre não informada'}{unidade.andar !== null && unidade.andar !== undefined ? ` · ${unidade.andar}º andar` : ''}{unidade.final ? ` · Final ${unidade.final}` : ''}
          </p>
        </div>
        <div className="text-right"><p className="text-[14px] font-bold text-[#0F6E56]">{moneyBR(unidade.valor_tabela)}</p><p className="text-[10px] text-[var(--color-text-tertiary)]">tabela parser</p></div>
      </div>
      {badges.length > 0 && <div className="flex flex-wrap gap-1 mt-2">{badges.map(b => <span key={b} className="rounded-full bg-[#E1F5EE] text-[#0F6E56] px-2 py-1 text-[10px] font-semibold">{b}</span>)}</div>}
      <div className="grid grid-cols-4 gap-2 mt-3">
        <div className="rounded-xl bg-[var(--color-background-secondary)] px-2 py-1.5"><p className="text-[10px] text-[var(--color-text-tertiary)]">Área</p><p className="text-[12px] font-semibold">{numberBR(unidade.metragem, ' m²')}</p></div>
        <div className="rounded-xl bg-[var(--color-background-secondary)] px-2 py-1.5"><p className="text-[10px] text-[var(--color-text-tertiary)]">Dorms</p><p className="text-[12px] font-semibold">{unidade.dormitorios_calc ?? '—'}</p></div>
        <div className="rounded-xl bg-[var(--color-background-secondary)] px-2 py-1.5"><p className="text-[10px] text-[var(--color-text-tertiary)]">Vagas</p><p className="text-[12px] font-semibold">{unidade.vagas_quantidade ?? '—'}</p></div>
        <div className="rounded-xl bg-[var(--color-background-secondary)] px-2 py-1.5"><p className="text-[10px] text-[var(--color-text-tertiary)]">Sol</p><p className="text-[12px] font-semibold">{unidade.orientacao_calc.label}</p></div>
      </div>
      {resumo && <div className="mt-3 rounded-xl bg-[#E1F5EE] text-[#0F6E56] px-3 py-2 text-[11px] leading-relaxed">Fluxo parser: {resumo}</div>}
      <div className="mt-3 rounded-xl bg-[#FAEEDA] text-[#412402] px-3 py-2 text-[11px] leading-relaxed">⚠️ {unidade.aviso || 'Disponibilidade ainda não validada pelo espelho de vendas.'}</div>
    </button>
  );
}

export default function TabFluxo({ sb, token, empresaId, corretorId, empreendimento, onVoltar, onIrParaEmps }) {
  const { data: config = {}, isLoading: configLoading, error: configError } = useEmpresaMesaConfig({ sb, token, empresaId });
  const { data: unidadesRaw = [], isLoading: unidadesLoading, error: unidadesError, reload: reloadUnidades } = useUnidadesMesa({ sb, token, empreendimentoId: empreendimento?.id });
  const { mutateAsync: criarSimulacao, isLoading: saving, error: saveError } = useCriarMesaSimulacao({ sb, token });
  const [saved, setSaved] = useState(null);
  const [unidadeSelecionada, setUnidadeSelecionada] = useState(null);
  const [busca, setBusca] = useState('');
  const [filtroFinal, setFiltroFinal] = useState('');
  const [filtroDorm, setFiltroDorm] = useState('');
  const [filtroSol, setFiltroSol] = useState('');

  const unidades = useMemo(() => Array.isArray(unidadesRaw) ? unidadesRaw.filter(u => u && typeof u === 'object').map(enrichUnit) : [], [unidadesRaw]);
  const sortedByPrice = useMemo(() => [...unidades].filter(u => u.valor_num > 0).sort((a,b) => a.valor_num - b.valor_num), [unidades]);
  const condoMin = sortedByPrice[0] || null;
  const condoMax = sortedByPrice[sortedByPrice.length - 1] || null;
  const finais = useMemo(() => [...new Set(unidades.map(u => u.final).filter(Boolean))].sort(), [unidades]);
  const dorms = useMemo(() => [...new Set(unidades.map(u => u.dormitorios_calc).filter(Boolean))].sort((a,b)=>a-b), [unidades]);
  const sols = useMemo(() => [...new Map(unidades.map(u => [u.orientacao_calc.value, u.orientacao_calc]).filter(([v]) => v)).values()], [unidades]);

  const unidadesFiltradas = useMemo(() => {
    const term = busca.trim().toLowerCase();
    return unidades.filter(u => {
      const matchBusca = !term || [u.unidade, u.torre, u.final, u.andar, u.metragem, u.valor_tabela].some(v => String(v ?? '').toLowerCase().includes(term));
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
      <div className="flex items-center gap-2 mb-3"><button onClick={onVoltar} className="px-3 py-1.5 rounded-xl bg-[var(--color-background-secondary)] text-[12px]">← Voltar</button><div className="min-w-0"><p className="text-[15px] font-semibold truncate">{empreendimento.nome}</p><p className="text-[11px] text-[var(--color-text-tertiary)]">Escolha a unidade extraída pelo parser para montar a mesa.</p></div></div>
      <div className="grid grid-cols-2 gap-2 mb-3"><StatCard label="Menor condomínio" unit={condoMin} tone="cheap"/><StatCard label="Maior condomínio" unit={condoMax} tone="expensive"/><StatCard label={filtroFinal ? `Menor final ${filtroFinal}` : 'Menor prumada'} unit={selectedFinalStats?.min || null} tone="cheap"/><StatCard label={filtroFinal ? `Maior final ${filtroFinal}` : 'Maior prumada'} unit={selectedFinalStats?.max || null} tone="expensive"/></div>
      <div className="rounded-2xl border border-[#EF9F27] bg-[#FAEEDA] text-[#412402] p-3 text-[12px] leading-relaxed mb-3">Nesta etapa o espelho de vendas ainda não filtra unidades vendidas. A tela exibe todas as unidades identificadas na tabela comercial.</div>
      <input value={busca} onChange={e => setBusca(e.target.value)} placeholder="Buscar por unidade, torre, andar, metragem ou valor…" className="w-full rounded-xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] px-3 py-2 text-[13px] mb-2 outline-none" />
      <div className="grid grid-cols-3 gap-2 mb-3">
        <select value={filtroFinal} onChange={e => setFiltroFinal(e.target.value)} className="rounded-xl border px-2 py-2 text-[12px] bg-transparent"><option value="">Todos finais</option>{finais.map(f => <option key={f} value={f}>Final {f}</option>)}</select>
        <select value={filtroDorm} onChange={e => setFiltroDorm(e.target.value)} className="rounded-xl border px-2 py-2 text-[12px] bg-transparent"><option value="">Todos dorms</option>{dorms.map(d => <option key={d} value={d}>{d} dorms</option>)}</select>
        <select value={filtroSol} onChange={e => setFiltroSol(e.target.value)} className="rounded-xl border px-2 py-2 text-[12px] bg-transparent"><option value="">Todos sóis</option>{sols.map(s => <option key={s.value} value={s.value}>{s.label}</option>)}</select>
      </div>
      {unidades.length === 0 && <div className="text-center py-12 border border-dashed rounded-2xl"><div className="text-4xl mb-3">📭</div><p className="text-[14px] font-semibold">Nenhuma unidade importada</p></div>}
      {unidades.length > 0 && unidadesFiltradas.length === 0 && <div className="text-center py-8 text-[13px] text-[var(--color-text-tertiary)]">Nenhuma unidade encontrada para os filtros.</div>}
      <div className="grid gap-3">{unidadesFiltradas.map(u => { const stats = byFinal.get(u.final) || {}; return <UnidadeCard key={u.id || u.unidade} unidade={u} onSelect={setUnidadeSelecionada} condoMin={condoMin} condoMax={condoMax} finalMin={stats.min} finalMax={stats.max}/>; })}</div>
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
