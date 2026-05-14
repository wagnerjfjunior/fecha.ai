/**
 * TabFluxo.jsx
 * Aba de montagem do fluxo de pagamento.
 * Conecta FluxoBuilder com os dados reais do Supabase.
 */

import { useState } from 'react';
import FluxoBuilder from './FluxoBuilder';
import { useEmpresaMesaConfig, useCriarMesaSimulacao } from './hooks/useMesaData';

export default function TabFluxo({
  empresaId,
  corretorId,
  isGestor,
  empreendimento,
  onVoltar,
  onIrParaEmps,
}) {
  const { data: config = {}, isLoading: configLoading } = useEmpresaMesaConfig(empresaId);
  const { mutateAsync: criarSimulacao } = useCriarMesaSimulacao();
  const [saved, setSaved] = useState(null);

  if (!empreendimento) return (<div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-3"><span className="text-5xl">📋</span><p className="text-[14px] font-medium text-[var(--color-text-secondary)]">Nenhum empreendimento selecionado</p><button onClick={onIrParaEmps} className="mt-2 px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">Ir para Empreendimentos</button></div>);
  if (configLoading) return (<div className="flex items-center justify-center py-12 text-[var(--color-text-tertiary)] text-[13px]">Carregando configurações…</div>);

  const handleSalvar = async ({ clienteNome, valorTotal, metaObraPct, metaEspecial, fluxoJson }) => {
    const precisaAprovacao = metaEspecial || (metaObraPct < (config.meta_obra_pct ?? 30));
    const id = await criarSimulacao({ empresaId, empreendimentoId: empreendimento.id, unidadeId: null, leadId: null, clienteNome: clienteNome || null, valorTotal, metaObraPct, tabelaProvisoria: empreendimento.tabela_tipo === 'trabalho', fluxoJson });
    setSaved({ id, precisaAprovacao });
  };

  return (<div className="p-3"><FluxoBuilder empreendimento={empreendimento} precoTotal={empreendimento.valor_tabela ?? 850000} empresaConfig={config} tabelaProvisoria={empreendimento.tabela_tipo === 'trabalho'} onSalvar={handleSalvar} onVoltar={onVoltar} /></div>
  );
}
