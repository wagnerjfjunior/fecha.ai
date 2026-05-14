/**
 * TabHistorico.jsx
 * Histórico de simulações/propostas da Mesa Cliente.
 * Gestor vê todas. Corretor vê só as suas.
 * Gestor pode aprovar/rejeitar inline.
 */

import { useState } from 'react';
import { useHistoricoMesas, useAprovarRejeitarMesa } from './hooks/useMesaData';

const STATUS_CFG = {
  rascunho:  { label: 'Rascunho', cor: '#9CA3AF', bg: 'bg-[var(--color-background-secondary)]', text: 'text-[var(--color-text-tertiary)]' },
  pendente:  { label: 'Pend. aprovação', cor: '#EF9F27', bg: 'bg-[#FAEEDA]', text: 'text-[#412402]' },
  aprovada:  { label: 'Aprovada', cor: '#1D9E75', bg: 'bg-[#E1F5EE]', text: 'text-[#04342C]' },
  enviada:   { label: 'Enviada', cor: '#185FA5', bg: 'bg-[#E6F1FB]', text: 'text-[#042C53]' },
  rejeitada: { label: 'Rejeitada', cor: '#E24B4A', bg: 'bg-[#FDEAEA]', text: 'text-[#4B1528]' },
  oficial:   { label: 'Oficial', cor: '#534AB7', bg: 'bg-[#EEEDFE]', text: 'text-[#26215C]' },
};
const fmtBRL = (n) => 'R$ ' + Math.round(n || 0).toLocaleString('pt-BR');
const fmtData = (iso) => iso ? new Date(iso).toLocaleDateString('pt-BR', { day: '2-digit', month: 'short', year: 'numeric' }) : '—';
function HistCard({ item, isGestor, empresaId, onRefetch }) {
  const [showAprov, setShowAprov] = useState(false);
  const [justificativa, setJustificativa] = useState('');
  const { mutateAsync: aprovarRejeitar, isPending } = useAprovarRejeitarMesa();
  const st = STATUS_CFG[item.status] ?? STATUS_CFG.rascunho;
  const podeAprovar = isGestor && item.status === 'pendente';
  const handleAcao = async (acao) => { await aprovarRejeitar({ simulacaoId: item.id, acao, justificativa, empresaId }); setShowAprov(false); setJustificativa(''); onRefetch?.(); };
  return (<div className="bg-[var(--color-background-primary)] border border-[var(--color-border-tertiary)] rounded-2xl overflow-hidden mb-2 hover:border-[var(--color-border-secondary)] transition-colors"><div className="flex items-start gap-3 p-3"><div className="w-1 self-stretch rounded-full flex-shrink-0 min-h-[44px]" style={{ background: st.cor }} /><div className="flex-1 min-w-0"><div className="text-[13px] font-semibold">{item.cliente_nome || '(sem nome)'}</div><div className="text-[12px] text-[var(--color-text-secondary)] mt-0.5">{item.empreendimento}</div><div className="text-[14px] font-semibold tabular-nums">{fmtBRL(item.valor_total)}</div><span className={`text-[11px] font-medium px-2 py-0.5 rounded mt-1 inline-block ${st.bg} ${st.text}`}>{st.label}</span>{isGestor && item.status === 'pendente' && !showAprov && <button onClick={() => setShowAprov(true)} className="mt-2 text-[11px] px-3 py-1.5 rounded-xl bg-[#FAEEDA] text-[#412402] font-medium">Aprovar ou rejeitar →</button>}</div></div></div>);
}
export default function TabHistorico({ empresaId, corretorId, isGestor }) {
  const [busca, setBusca] = useState('');
  const [stFiltro, setSt] = useState('');
  const filtros = { busca: busca || null, status: stFiltro || null };
  const { data: historico = [], isLoading, isError, refetch } = useHistoricoMesas(empresaId, filtros, corretorId);
  return (<div className="p-3"><div className="flex gap-2 mb-3 flex-wrap"><input type="text" placeholder="Buscar por cliente, unidade…'" value={busca} onChange={e => setBusca(e.target.value)} className="flex-1 min-w-[160px] text-[13px] px-3 py-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] outline-none" /><select value={stFiltro} onChange={e => setSt(e.target.value)} className="text-[13px] px-3 py-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] outline-none"><option value="">Todos os status</option><option value="rascunho">Rascunho</option><option value="pendente">Pend. aprovação</option><option value="aprovada">Aprovada</option><option value="enviada">Enviada</option><option value="rejeitada">Rejeitada</option><option value="oficial">Oficial</option></select></div><div id="hist-list">{historico.map(item => <HistCard key={item.id} item={item} isGestor={isGestor} empresaId={empresaId} onRefetch={refetch} />)}</div></div>);
}
