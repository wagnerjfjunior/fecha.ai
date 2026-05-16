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
  return n.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
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

function parseObsKV(observacoes = '') {
  const out = {};
  String(observacoes || '').split('|').forEach(part => {
    const [k, ...rest] = part.split('=');
    const key = String(k || '').trim();
    if (!key) return;
    out[key] = rest.join('=').trim();
  });
  return out;
}

function parsePayloadFromObservacoes(observacoes = '') {
  const text = String(observacoes || '');
  const marker = 'Payload:';
  const idx = text.indexOf(marker);
  if (idx < 0) return null;
  const payloadText = text.slice(idx + marker.length).trim();
  if (!payloadText.startsWith('{')) return null;
  try {
    return JSON.parse(payloadText);
  } catch {
    return null;
  }
}

function buildFluxoFromParser(unidade = {}) {
  const payload = parsePayloadFromObservacoes(unidade.observacoes) || {};
  const raw = payload.raw || payload;
  const meta = parseObsKV(payload.observacoes || unidade.observacoes || '');

  const sinal = toNumber(raw.sinal_1 ?? payload.sinal_1);
  const complemento = toNumber(raw.a4_each ?? payload.a4_each);
  const mensalEach = toNumber(raw.mensal_each ?? payload.mensal_each);
  const interEach = toNumber(raw.inter_each ?? payload.inter_each);
  const chavesEach = toNumber(raw.chaves_each ?? payload.chaves_each);

  const atoQtd = Number.parseInt(meta.ato_qtd || '1', 10) || 1;
  const compQtd = Number.parseInt(meta.comp_qtd || '0', 10) || 0;
  const mensalQtd = Number.parseInt(raw.mensal_qtd || payload.mensal_qtd || meta.mensal_qtd || '0', 10) || 0;
  const interQtd = Number.parseInt(raw.inter_qtd || payload.inter_qtd || meta.inter_qtd || '0', 10) || 0;
  const unicaQtd = Number.parseInt(meta.unica_qtd || '0', 10) || 0;
  const interTipo = String(raw.inter_tipo || payload.inter_tipo || '').toLowerCase();

  const fluxo = { e: [], c: [], m: [], a: [], u: [] };

  if (sinal > 0) {
    if (atoQtd <= 1) {
      fluxo.e.push({ id: 'ato', label: 'Ato', date: '', value: sinal, meta: 'tabela parser', source: 'parser' });
    } else {
      fluxo.e.push({ id: 'ato', label: 'Ato', qty: atoQtd, value: sinal, dateStart: '', meta: 'tabela parser', isGroup: true, source: 'parser' });
    }
  }

  if (complemento > 0 && compQtd > 0) {
    const labels = ['+30 dias', '+60 dias', '+90 dias', '+120 dias', '+150 dias', '+180 dias'];
    for (let i = 0; i < compQtd; i += 1) {
      fluxo.c.push({
        id: `c${i + 1}`,
        label: labels[i] || `Compl. ${i + 1}`,
        date: '',
        value: complemento,
        meta: 'tabela parser',
        source: 'parser',
      });
    }
  }

  if (mensalEach > 0 && mensalQtd > 0) {
    fluxo.m.push({
      id: 'm1',
      label: 'Mensais',
      qty: mensalQtd,
      value: mensalEach,
      dateStart: meta.mensal_inicio || '',
      meta: 'tabela parser',
      isGroup: true,
      source: 'parser',
    });
  }

  if (interEach > 0 && interQtd > 0) {
    const per = interTipo.includes('semestral') ? 'semestral' : 'anual';
    fluxo.a.push({
      id: 'a1',
      label: per === 'semestral' ? 'Semestrais' : 'Anuais',
      qty: interQtd,
      value: interEach,
      dateStart: meta.anual_inicio || '',
      meta: per === 'semestral' ? 'semestral · parser' : 'anual · parser',
      isGroup: true,
      per,
      source: 'parser',
    });
  }

  if (chavesEach > 0 && unicaQtd > 0) {
    if (unicaQtd <= 1) {
      fluxo.u.push({ id: 'u1', label: 'Parcela única', date: meta.unica || '', value: chavesEach, meta: 'tabela parser', source: 'parser' });
    } else {
      fluxo.u.push({ id: 'u1', label: 'Chaves', qty: unicaQtd, value: chavesEach, dateStart: meta.unica || '', meta: 'tabela parser', isGroup: true, source: 'parser' });
    }
  }

  const hasAny = Object.values(fluxo).some(arr => arr.length > 0);
  return hasAny ? fluxo : null;
}

function fluxoResumo(unidade = {}) {
  const payload = parsePayloadFromObservacoes(unidade.observacoes) || {};
  const raw = payload.raw || payload;
  const meta = parseObsKV(payload.observacoes || unidade.observacoes || '');
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
  const unicaQtd = Number.parseInt(meta.unica_qtd || '0', 10) || 0;

  if (sinal > 0) parts.push(`Ato ${moneyBR(sinal)}`);
  if (complemento > 0 && compQtd > 0) parts.push(`${compQtd} compl. de ${moneyBR(complemento)}`);
  if (mensalEach > 0 && mensalQtd > 0) parts.push(`${mensalQtd} mensais de ${moneyBR(mensalEach)}`);
  if (interEach > 0 && interQtd > 0) parts.push(`${interQtd} interm. de ${moneyBR(interEach)}`);
  if (chavesEach > 0 && unicaQtd > 0) parts.push(`${unicaQtd} chaves de ${moneyBR(chavesEach)}`);
  if (financiamento > 0) parts.push(`Fin. ${moneyBR(financiamento)}`);
  return parts.join(' · ');
}

function UnidadeCard({ unidade, selected, onSelect }) {
  const resumo = fluxoResumo(unidade);

  return (
    <button
      onClick={() => onSelect(unidade)}
      className={`w-full text-left rounded-2xl border p-3 transition-all ${
        selected ? 'border-[#2563eb] bg-[#eff6ff]' : 'border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] hover:border-[var(--color-border-secondary)]'
      }`}
    >
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-[15px] font-semibold text-[var(--color-text-primary)]">
            Unidade {unidade.unidade || '—'}
          </p>
          <p className="text-[11px] text-[var(--color-text-tertiary)] mt-0.5">
            {unidade.torre ? `Torre ${unidade.torre}` : 'Torre não informada'}
            {unidade.andar !== null && unidade.andar !== undefined ? ` · ${unidade.andar}º andar` : ''}
            {unidade.final ? ` · Final ${unidade.final}` : ''}
          </p>
        </div>
        <div className="text-right">
          <p className="text-[14px] font-bold text-[#0F6E56]">{moneyBR(unidade.valor_tabela)}</p>
          <p className="text-[10px] text-[var(--color-text-tertiary)]">tabela parser</p>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-2 mt-3">
        <div className="rounded-xl bg-[var(--color-background-secondary)] px-2 py-1.5">
          <p className="text-[10px] text-[var(--color-text-tertiary)]">Área</p>
          <p className="text-[12px] font-semibold">{numberBR(unidade.metragem, ' m²')}</p>
        </div>
        <div className="rounded-xl bg-[var(--color-background-secondary)] px-2 py-1.5">
          <p className="text-[10px] text-[var(--color-text-tertiary)]">Dorms</p>
          <p className="text-[12px] font-semibold">{unidade.dormitorios ?? '—'}</p>
        </div>
        <div className="rounded-xl bg-[var(--color-background-secondary)] px-2 py-1.5">
          <p className="text-[10px] text-[var(--color-text-tertiary)]">Vagas</p>
          <p className="text-[12px] font-semibold">{unidade.vagas_quantidade ?? '—'}</p>
        </div>
      </div>

      {resumo && (
        <div className="mt-3 rounded-xl bg-[#E1F5EE] text-[#0F6E56] px-3 py-2 text-[11px] leading-relaxed">
          Fluxo parser: {resumo}
        </div>
      )}

      <div className="mt-3 rounded-xl bg-[#FAEEDA] text-[#412402] px-3 py-2 text-[11px] leading-relaxed">
        ⚠️ {unidade.aviso || 'Disponibilidade ainda não validada pelo espelho de vendas.'}
      </div>
    </button>
  );
}

export default function TabFluxo({
  sb,
  token,
  empresaId,
  corretorId,
  empreendimento,
  onVoltar,
  onIrParaEmps,
}) {
  const { data: config = {}, isLoading: configLoading, error: configError } = useEmpresaMesaConfig({ sb, token, empresaId });
  const { data: unidades = [], isLoading: unidadesLoading, error: unidadesError, reload: reloadUnidades } = useUnidadesMesa({
    sb,
    token,
    empreendimentoId: empreendimento?.id,
  });
  const { mutateAsync: criarSimulacao, isLoading: saving, error: saveError } = useCriarMesaSimulacao({ sb, token });

  const [saved, setSaved] = useState(null);
  const [unidadeSelecionada, setUnidadeSelecionada] = useState(null);
  const [busca, setBusca] = useState('');

  const unidadesFiltradas = useMemo(() => {
    const term = busca.trim().toLowerCase();
    if (!term) return unidades;
    return unidades.filter(u => [u.unidade, u.torre, u.final, u.andar, u.metragem, u.valor_tabela]
      .some(v => String(v ?? '').toLowerCase().includes(term)));
  }, [busca, unidades]);

  const fluxoParser = useMemo(() => buildFluxoFromParser(unidadeSelecionada), [unidadeSelecionada]);

  if (!empreendimento) {
    return (
      <div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-3">
        <span className="text-5xl">📋</span>
        <p className="text-[14px] font-medium text-[var(--color-text-secondary)]">Nenhum empreendimento selecionado</p>
        <p className="text-[12px] text-[var(--color-text-tertiary)]">Vá para Empreendimentos, escolha um com tabela ativa e clique em "Abrir Mesa"</p>
        <button onClick={onIrParaEmps} className="mt-2 px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Ir para Empreendimentos</button>
      </div>
    );
  }

  if (configLoading || unidadesLoading) {
    return <div className="flex items-center justify-center py-12 text-[var(--color-text-tertiary)] text-[13px]">Carregando dados da mesa…</div>;
  }

  if (configError || unidadesError) {
    return (
      <div className="p-4 text-center">
        <div className="text-4xl mb-3">⚠️</div>
        <p className="text-[14px] font-semibold text-[var(--color-text-primary)] mb-1">Não foi possível carregar a mesa</p>
        <p className="text-[12px] text-[var(--color-text-secondary)] mb-4">{configError || unidadesError}</p>
        <div className="flex gap-2 justify-center">
          <button onClick={reloadUnidades} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Tentar novamente</button>
          <button onClick={onVoltar} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Voltar</button>
        </div>
      </div>
    );
  }

  if (saved) {
    return (
      <div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-4">
        <span className="text-5xl">✅</span>
        <p className="text-[16px] font-semibold text-[var(--color-text-primary)]">Proposta salva!</p>
        <p className="text-[12px] text-[var(--color-text-tertiary)]">
          ID: <span className="font-mono">{String(saved.id || saved).slice(0, 8)}…</span>
          {saved.precisaAprovacao && ' · Enviada para aprovação do gestor'}
        </p>
        <div className="flex gap-2 mt-2">
          <button onClick={() => { setSaved(null); setUnidadeSelecionada(null); }} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Nova Mesa</button>
          <button onClick={onVoltar} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Ver Empreendimentos</button>
        </div>
      </div>
    );
  }

  const handleSalvar = async ({ clienteNome, valorTotal, metaObraPct, tabelaProvisoria, metaEspecial, fluxoJson }) => {
    if (!unidadeSelecionada?.id) throw new Error('Selecione uma unidade antes de salvar a mesa.');
    const precisaAprovacao = metaEspecial || (metaObraPct < (config.meta_obra_pct ?? 30));

    const id = await criarSimulacao({
      empresaId,
      empreendimentoId: empreendimento.id,
      unidadeId: unidadeSelecionada.id,
      leadId: null,
      clienteNome: clienteNome || null,
      valorTotal,
      metaObraPct,
      tabelaProvisoria: empreendimento.tabela_tipo === 'trabalho' || tabelaProvisoria,
      fluxoJson,
    });

    setSaved({ id, precisaAprovacao });
  };

  if (!unidadeSelecionada) {
    return (
      <div className="p-3">
        <div className="flex items-center gap-2 mb-3">
          <button onClick={onVoltar} className="px-3 py-1.5 rounded-xl bg-[var(--color-background-secondary)] text-[12px]">← Voltar</button>
          <div className="min-w-0">
            <p className="text-[15px] font-semibold text-[var(--color-text-primary)] truncate">{empreendimento.nome}</p>
            <p className="text-[11px] text-[var(--color-text-tertiary)]">Escolha a unidade extraída pelo parser para montar a mesa.</p>
          </div>
        </div>

        <div className="rounded-2xl border border-[#EF9F27] bg-[#FAEEDA] text-[#412402] p-3 text-[12px] leading-relaxed mb-3">
          Nesta etapa o espelho de vendas ainda não filtra unidades vendidas. A tela exibe todas as unidades identificadas na tabela comercial. Parece simples, mas evita aquele clássico “cadê a unidade?” no plantão.
        </div>

        <input
          value={busca}
          onChange={e => setBusca(e.target.value)}
          placeholder="Buscar por unidade, torre, andar, metragem ou valor…"
          className="w-full rounded-xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-primary)] px-3 py-2 text-[13px] mb-3 outline-none"
        />

        {unidades.length === 0 && (
          <div className="text-center py-12 border border-dashed border-[var(--color-border-tertiary)] rounded-2xl">
            <div className="text-4xl mb-3">📭</div>
            <p className="text-[14px] font-semibold text-[var(--color-text-secondary)]">Nenhuma unidade importada</p>
            <p className="text-[12px] text-[var(--color-text-tertiary)] mt-1 max-w-[360px] mx-auto">
              O empreendimento tem tabela registrada, mas ainda não há unidades salvas em unidades_estoque para o snapshot ativo.
            </p>
          </div>
        )}

        {unidades.length > 0 && unidadesFiltradas.length === 0 && (
          <div className="text-center py-8 text-[13px] text-[var(--color-text-tertiary)]">Nenhuma unidade encontrada para a busca.</div>
        )}

        <div className="grid gap-3">
          {unidadesFiltradas.map(u => (
            <UnidadeCard key={u.id} unidade={u} selected={false} onSelect={setUnidadeSelecionada} />
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="p-3">
      <div className="rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-secondary)] p-3 mb-3 flex items-start justify-between gap-3">
        <div>
          <p className="text-[12px] text-[var(--color-text-tertiary)]">Unidade selecionada</p>
          <p className="text-[14px] font-semibold text-[var(--color-text-primary)]">
            {empreendimento.nome} · Unidade {unidadeSelecionada.unidade}
          </p>
          <p className="text-[11px] text-[var(--color-text-tertiary)]">
            {moneyBR(unidadeSelecionada.valor_tabela)} · {numberBR(unidadeSelecionada.metragem, ' m²')} · disponibilidade não validada pelo espelho
          </p>
          {fluxoParser && (
            <p className="text-[11px] text-[#0F6E56] mt-1">
              Fluxo iniciado com os valores reais extraídos da tabela.
            </p>
          )}
        </div>
        <button onClick={() => setUnidadeSelecionada(null)} className="px-3 py-1.5 rounded-xl bg-[var(--color-background-primary)] text-[12px]">Trocar</button>
      </div>

      {saveError && <div className="bg-[#FDEAEA] text-[#4B1528] rounded-xl px-3 py-2 text-[12px] mb-3">{saveError}</div>}
      {saving && <div className="bg-[#E1F5EE] text-[#0F6E56] rounded-xl px-3 py-2 text-[12px] mb-3">Salvando proposta…</div>}

      <FluxoBuilder
        empreendimento={empreendimento}
        unidade={unidadeSelecionada}
        precoTotal={Number(unidadeSelecionada.valor_tabela)}
        empresaConfig={config}
        tabelaProvisoria={empreendimento.tabela_tipo === 'trabalho'}
        initialFluxo={fluxoParser}
        fluxoOrigem={fluxoParser ? 'parser' : 'padrao'}
        onSalvar={handleSalvar}
        onVoltar={() => setUnidadeSelecionada(null)}
      />
    </div>
  );
}
