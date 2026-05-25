/**
 * TabHistorico.jsx
 * Histórico de simulações/propostas da Mesa Cliente.
 * Gestor vê todas. Corretor vê só as suas.
 * Gestor pode aprovar/rejeitar inline via RPC segura.
 */

import { useMemo, useState } from 'react';
import { useHistoricoMesas, useAprovarRejeitarMesa } from './hooks/useMesaData';

const STATUS_CFG = {
  rascunho:  { label: 'Rascunho',        cor: '#9CA3AF', bg: 'bg-[var(--color-background-secondary)]', text: 'text-[var(--color-text-tertiary)]' },
  pendente:  { label: 'Pend. aprovação', cor: '#EF9F27', bg: 'bg-[#FAEEDA]', text: 'text-[#412402]' },
  aprovada:  { label: 'Aprovada',        cor: '#1D9E75', bg: 'bg-[#E1F5EE]', text: 'text-[#04342C]' },
  enviada:   { label: 'Enviada',         cor: '#185FA5', bg: 'bg-[#E6F1FB]', text: 'text-[#042C53]' },
  rejeitada: { label: 'Rejeitada',       cor: '#E24B4A', bg: 'bg-[#FDEAEA]', text: 'text-[#4B1528]' },
  oficial:   { label: 'Oficial',         cor: '#534AB7', bg: 'bg-[#EEEDFE]', text: 'text-[#26215C]' },
};

const fmtBRL = (n) => 'R$ ' + Math.round(n || 0).toLocaleString('pt-BR');
const fmtData = (iso) => iso ? new Date(iso).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' }) : '—';

function HistCard({ item, isGestor, empresaId, sb, token, onRefetch, onAbrirOperacoesFinanceiras }) {
  const [showAprov, setShowAprov] = useState(false);
  const [justificativa, setJustificativa] = useState('');
  const { mutateAsync: aprovarRejeitar, isLoading, error } = useAprovarRejeitarMesa({ sb, token });

  const st = STATUS_CFG[item.status] ?? STATUS_CFG.rascunho;
  const podeAprovar = isGestor && item.status === 'pendente';
  const podeAbrirOperacoes = Boolean(item?.id && onAbrirOperacoesFinanceiras);

  const handleAcao = async (acao) => {
    await aprovarRejeitar({ simulacaoId: item.id, acao, justificativa, empresaId });
    setShowAprov(false);
    setJustificativa('');
    onRefetch?.();
  };

  return (
    <div className="bg-[var(--color-background-primary)] border border-[var(--color-border-tertiary)] rounded-2xl overflow-hidden mb-2 hover:border-[var(--color-border-secondary)] transition-colors">
      <div className="flex items-start gap-3 p-3">
        <div className="w-1 self-stretch rounded-full flex-shrink-0 min-h-[44px]" style={{ background: st.cor }} />

        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <div>
              <div className="text-[13px] font-semibold text-[var(--color-text-primary)] leading-tight">{item.cliente_nome || '(sem nome)'}</div>
              <div className="text-[12px] text-[var(--color-text-secondary)] mt-0.5">{item.empreendimento} {item.unidade ? `· ${item.unidade}` : ''}</div>
              <div className="flex gap-3 mt-1.5 flex-wrap">
                <span className="text-[11px] text-[var(--color-text-tertiary)]">👤 {item.corretor_nome || '—'}</span>
                <span className="text-[11px] text-[var(--color-text-tertiary)]">📅 {fmtData(item.atualizado_em)}</span>
                {item.tabela_provisoria && <span className="text-[10px] bg-[#FAEEDA] text-[#412402] px-1.5 py-0.5 rounded">tabela provisória</span>}
              </div>
            </div>
            <div className="text-right flex-shrink-0">
              <div className="text-[14px] font-semibold tabular-nums">{fmtBRL(item.valor_total)}</div>
              <span className={`text-[11px] font-medium px-2 py-0.5 rounded mt-1 inline-block ${st.bg} ${st.text}`}>{st.label}</span>
            </div>
          </div>

          <div className="mt-2 flex flex-wrap gap-2">
            {podeAbrirOperacoes && (
              <button
                type="button"
                onClick={() => onAbrirOperacoesFinanceiras(item)}
                className="text-[11px] px-3 py-1.5 rounded-xl bg-[#E6F1FB] text-[#042C53] font-medium"
              >
                Operações financeiras
              </button>
            )}

            {podeAprovar && !showAprov && (
              <button onClick={() => setShowAprov(true)} className="text-[11px] px-3 py-1.5 rounded-xl bg-[#FAEEDA] text-[#412402] font-medium">Aprovar ou rejeitar →</button>
            )}
          </div>
        </div>
      </div>

      {showAprov && (
        <div className="px-3 pb-3 border-t border-[var(--color-border-tertiary)]">
          <p className="text-[12px] font-medium text-[var(--color-text-primary)] mt-2 mb-2">Justificativa (opcional)</p>
          <textarea rows={2} value={justificativa} onChange={e => setJustificativa(e.target.value)} placeholder="Motivo da aprovação ou rejeição…" className="w-full text-[12px] p-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-secondary)] resize-none outline-none" />
          {error && <p className="text-[11px] text-[#993556] mt-2">{error}</p>}
          <div className="flex gap-2 mt-2">
            <button onClick={() => setShowAprov(false)} className="flex-1 py-1.5 rounded-xl text-[12px] bg-[var(--color-background-secondary)]">Cancelar</button>
            <button onClick={() => handleAcao('rejeitar')} disabled={isLoading} className="flex-1 py-1.5 rounded-xl text-[12px] bg-[#FDEAEA] text-[#993556] font-medium">Rejeitar</button>
            <button onClick={() => handleAcao('aprovar')} disabled={isLoading} className="flex-1 py-1.5 rounded-xl text-[12px] bg-[#E1F5EE] text-[#0F6E56] font-medium">{isLoading ? '…' : 'Aprovar'}</button>
          </div>
        </div>
      )}
    </div>
  );
}

export default function TabHistorico({ sb, token, empresaId, corretorId, isGestor, onAbrirOperacoesFinanceiras }) {
  const [busca, setBusca] = useState('');
  const [stFiltro, setSt] = useState('');

  const filtros = useMemo(() => ({
    busca: busca || null,
    empId: null,
    status: stFiltro || null,
  }), [busca, stFiltro]);

  const { data: historico = [], isLoading, error, reload } = useHistoricoMesas({
    sb,
    token,
    empresaId,
    filtros,
    corretorId,
  });

  return (
    <div className="p-3">
      <div className="flex gap-2 mb-3 flex-wrap">
        <input type="text" placeholder="Buscar por cliente, unidade…" value={busca} onChange={e => setBusca(e.target.value)} className="flex-1 min-w-[160px] text-[13px] px-3 py-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] outline-none" />
        <select value={stFiltro} onChange={e => setSt(e.target.value)} className="text-[13px] px-3 py-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] outline-none">
          <option value="">Todos os status</option>
          <option value="rascunho">Rascunho</option>
          <option value="pendente">Pend. aprovação</option>
          <option value="aprovada">Aprovada</option>
          <option value="enviada">Enviada</option>
          <option value="rejeitada">Rejeitada</option>
          <option value="oficial">Oficial</option>
        </select>
      </div>

      <p className="text-[11px] text-[var(--color-text-tertiary)] mb-2 uppercase tracking-wide font-medium">
        Propostas · {historico.length} registros
        {isGestor && <span className="ml-2 text-[var(--color-text-info)]">visão gestor</span>}
      </p>

      {isLoading && <div className="text-center py-10 text-[var(--color-text-tertiary)] text-[13px]">Carregando histórico…</div>}

      {error && (
        <div className="text-center py-8">
          <p className="text-[var(--color-text-danger)] text-[13px] mb-3">{error}</p>
          <button onClick={reload} className="text-[12px] px-4 py-2 rounded-xl bg-[var(--color-background-secondary)]">Tentar novamente</button>
        </div>
      )}

      {!isLoading && !error && historico.length === 0 && (
        <div className="text-center py-12">
          <div className="text-4xl mb-3">📂</div>
          <p className="text-[14px] font-medium text-[var(--color-text-secondary)]">Nenhuma proposta encontrada</p>
          <p className="text-[12px] text-[var(--color-text-tertiary)] mt-1">{busca || stFiltro ? 'Tente outros filtros' : 'As propostas salvas na Mesa aparecem aqui'}</p>
        </div>
      )}

      {historico.map(item => (
        <HistCard
          key={item.id}
          item={item}
          isGestor={isGestor}
          empresaId={empresaId}
          sb={sb}
          token={token}
          onRefetch={reload}
          onAbrirOperacoesFinanceiras={onAbrirOperacoesFinanceiras}
        />
      ))}
    </div>
  );
}
