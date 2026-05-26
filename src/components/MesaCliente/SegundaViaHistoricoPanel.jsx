import { useMemo } from 'react';
import { useSimulacaoFluxoHistorico } from './hooks/useMesaData';

const GROUPS = [
  { id: 'e', label: 'Entrada', tone: 'bg-[#EEEDFE] text-[#26215C] border-[#CECBF6]' },
  { id: 'c', label: 'Complementos', tone: 'bg-[#FBEAF0] text-[#4B1528] border-[#F4C0D1]' },
  { id: 'm', label: 'Mensais', tone: 'bg-[#E6F1FB] text-[#042C53] border-[#B5D4F4]' },
  { id: 'a', label: 'Intermediárias / reforços', tone: 'bg-[#E1F5EE] text-[#04342C] border-[#9FE1CB]' },
  { id: 'u', label: 'Chaves / parcela única', tone: 'bg-[#FEF9EA] text-[#78350F] border-[#FDE68A]' },
  { id: 'f', label: 'Financiamento', tone: 'bg-[#FEF0EB] text-[#4A1B0C] border-[#F7C8B8]' },
];

function fmtBRL(value) {
  const n = Number(value || 0);
  return n.toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  });
}

function fmtDate(value) {
  const text = String(value || '').trim();
  if (!text) return '—';

  const iso = text.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (iso) return `${iso[3]}/${iso[2]}/${iso[1]}`;

  return text;
}

function normalizarGrupo(item = {}) {
  const grupo = String(item.grupo || '').trim().toLowerCase();
  if (grupo) return grupo;

  const tipo = String(item.tipo || '').trim().toLowerCase();
  if (tipo === 'entrada') return 'e';
  if (tipo === 'curto_prazo') return 'c';
  if (tipo === 'periodica') return 'm';
  if (tipo === 'intermediaria') return 'a';
  if (tipo === 'quitacao') return 'u';
  if (tipo === 'financiamento') return 'f';

  return 'outros';
}

function normalizarFluxo(fluxoRaw) {
  const arr = Array.isArray(fluxoRaw) ? fluxoRaw : [];

  return arr
    .filter((item) => item && typeof item === 'object')
    .map((item, index) => {
      const quantidade = Number(item.quantidade ?? item.qty ?? 1) || 1;
      const valor = Number(item.valor ?? item.value ?? 0) || 0;
      const total = Number(item.total ?? valor * quantidade) || 0;

      return {
        ...item,
        ordem: Number(item.ordem ?? index + 1),
        grupo: normalizarGrupo(item),
        label: item.label || item.descricao || item.tipo || `Parcela ${index + 1}`,
        quantidade,
        valor,
        total,
        data: item.data_prevista || item.date || item.data || '',
      };
    })
    .sort((a, b) => a.ordem - b.ordem);
}

function GrupoFluxo({ grupo, itens }) {
  if (!itens.length) return null;

  const totalGrupo = itens.reduce((acc, item) => acc + Number(item.total || 0), 0);

  return (
    <section className={`rounded-2xl border p-4 ${grupo.tone}`}>
      <div className="flex items-start justify-between gap-3 mb-3">
        <div>
          <p className="text-[13px] font-bold uppercase tracking-wide">{grupo.label}</p>
          <p className="text-[12px] opacity-75 mt-0.5">Leitura histórica read-only</p>
        </div>
        <p className="text-[15px] font-bold tabular-nums">{fmtBRL(totalGrupo)}</p>
      </div>

      <div className="grid gap-2">
        {itens.map((item) => (
          <div key={`${item.id || item.ordem}-${item.label}`} className="rounded-xl bg-white/70 border border-white/80 px-3 py-2">
            <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-1">
              <div>
                <p className="text-[13px] font-semibold">{item.label}</p>
                <p className="text-[11px] opacity-75 mt-0.5">
                  {item.quantidade > 1 ? `${item.quantidade}x de ${fmtBRL(item.valor)}` : fmtBRL(item.valor)}
                  {item.periodicidade ? ` · ${item.periodicidade}` : ''}
                  {item.data ? ` · ${fmtDate(item.data)}` : ''}
                </p>
              </div>
              <p className="text-[13px] font-bold tabular-nums">{fmtBRL(item.total)}</p>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}

export default function SegundaViaHistoricoPanel({
  sb,
  token,
  simulacaoId,
  context = null,
  onVoltar,
  onAbrirOperacoesFinanceiras,
}) {
  const { data, isLoading, error, reload } = useSimulacaoFluxoHistorico({
    sb,
    token,
    simulacaoId,
    parametros: { origem_front: 'segunda_via_historico' },
  });

  const simulacao = data?.simulacao || context || {};
  const fluxo = useMemo(() => normalizarFluxo(data?.fluxo), [data]);
  const totalFluxo = fluxo.reduce((acc, item) => acc + Number(item.total || 0), 0);

  if (!simulacaoId) {
    return (
      <div className="p-4 text-center py-12">
        <div className="text-4xl mb-3">📄</div>
        <p className="text-[15px] font-semibold text-[var(--color-text-primary)]">Nenhuma proposta selecionada</p>
        <p className="text-[12px] text-[var(--color-text-tertiary)] mt-1">Volte ao histórico e selecione uma proposta para emitir a 2ª via.</p>
        {onVoltar && <button onClick={onVoltar} className="mt-4 px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Voltar ao histórico</button>}
      </div>
    );
  }

  if (isLoading) {
    return <div className="p-4 text-center py-12 text-[13px] text-[var(--color-text-tertiary)]">Carregando 2ª via da proposta…</div>;
  }

  if (error) {
    return (
      <div className="p-4 text-center py-10">
        <div className="text-4xl mb-3">🔒</div>
        <p className="text-[15px] font-semibold text-[var(--color-text-primary)]">Não foi possível abrir a 2ª via</p>
        <p className="text-[13px] text-[var(--color-text-danger)] mt-2">{error}</p>
        <div className="flex flex-wrap gap-2 justify-center mt-4">
          {onVoltar && <button onClick={onVoltar} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Voltar ao histórico</button>}
          <button onClick={reload} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Tentar novamente</button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-3 space-y-3 max-w-[980px] mx-auto">
      <div className="rounded-2xl border border-[var(--color-border-tertiary)] bg-[var(--color-background-secondary)] p-4">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-[12px] font-semibold uppercase tracking-wide text-[var(--color-text-tertiary)]">2ª via da proposta</p>
            <p className="text-[20px] font-bold text-[var(--color-text-primary)] mt-1">{simulacao.cliente_nome || '(sem nome)'}</p>
            <p className="text-[13px] text-[var(--color-text-secondary)] mt-1">
              {context?.empreendimento || simulacao.empreendimento || 'Empreendimento não informado'}
              {(context?.unidade || simulacao.unidade) ? ` · Unidade ${context?.unidade || simulacao.unidade}` : ''}
            </p>
            <div className="flex flex-wrap gap-2 mt-3">
              <span className="rounded-full bg-[var(--color-background-primary)] px-2 py-0.5 text-[11px] text-[var(--color-text-secondary)]">Status: {simulacao.status || '—'}</span>
              <span className="rounded-full bg-[var(--color-background-primary)] px-2 py-0.5 text-[11px] text-[var(--color-text-secondary)]">Valor da proposta: {fmtBRL(simulacao.valor_total ?? context?.valor_total)}</span>
              <span className="rounded-full bg-[var(--color-background-primary)] px-2 py-0.5 text-[11px] text-[var(--color-text-secondary)]">Total do fluxo: {fmtBRL(totalFluxo)}</span>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            {onVoltar && <button type="button" onClick={onVoltar} className="rounded-xl bg-[var(--color-background-primary)] px-3 py-2 text-[12px] font-semibold text-[var(--color-text-primary)]">← Histórico</button>}
            {onAbrirOperacoesFinanceiras && (
              <button type="button" onClick={() => onAbrirOperacoesFinanceiras(simulacao)} className="rounded-xl bg-[#E6F1FB] px-3 py-2 text-[12px] font-semibold text-[#042C53]">Operações financeiras</button>
            )}
          </div>
        </div>
      </div>

      {data?.readonly === true && (
        <div className="rounded-2xl bg-[#FAEEDA] text-[#412402] px-4 py-3 text-[13px] leading-relaxed">
          Esta 2ª via é uma leitura histórica read-only. A proposta original não é editada por esta tela.
        </div>
      )}

      {fluxo.length === 0 && (
        <div className="rounded-2xl border border-dashed border-[var(--color-border-tertiary)] p-8 text-center">
          <div className="text-4xl mb-3">📭</div>
          <p className="text-[14px] font-semibold text-[var(--color-text-primary)]">Fluxo histórico não encontrado</p>
          <p className="text-[12px] text-[var(--color-text-tertiary)] mt-1">A simulação existe, mas não retornou parcelas para exibição.</p>
        </div>
      )}

      {GROUPS.map((grupo) => (
        <GrupoFluxo key={grupo.id} grupo={grupo} itens={fluxo.filter((item) => item.grupo === grupo.id)} />
      ))}

      {fluxo.some((item) => !GROUPS.some((grupo) => grupo.id === item.grupo)) && (
        <GrupoFluxo grupo={{ id: 'outros', label: 'Outros lançamentos', tone: 'bg-[var(--color-background-secondary)] text-[var(--color-text-primary)] border-[var(--color-border-tertiary)]' }} itens={fluxo.filter((item) => !GROUPS.some((grupo) => grupo.id === item.grupo))} />
      )}
    </div>
  );
}
