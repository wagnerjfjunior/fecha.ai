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
  const [saved, setSaved] = useState(null); // uuid da simulação salva

  if (!empreendimento) {
    return (
      <div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-3">
        <span className="text-5xl">📋</span>
        <p className="text-[14px] font-medium text-[var(--color-text-secondary)]">
          Nenhum empreendimento selecionado
        </p>
        <p className="text-[12px] text-[var(--color-text-tertiary)]">
          Vá para Empreendimentos, escolha um com tabela ativa e clique em "Abrir Mesa"
        </p>
        <button
          onClick={onIrParaEmps}
          className="mt-2 px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]"
        >
          Ir para Empreendimentos
        </button>
      </div>
    );
  }

  if (configLoading) {
    return (
      <div className="flex items-center justify-center py-12 text-[var(--color-text-tertiary)] text-[13px]">
        Carregando configurações…
      </div>
    );
  }

  if (saved) {
    return (
      <div className="flex flex-col items-center justify-center h-full py-16 px-4 text-center gap-4">
        <span className="text-5xl">✅</span>
        <p className="text-[16px] font-semibold text-[var(--color-text-primary)]">
          Proposta salva!
        </p>
        <p className="text-[12px] text-[var(--color-text-tertiary)]">
          ID: <span className="font-mono">{saved.slice(0, 8)}…</span>
          {saved.precisaAprovacao && ' · Enviada para aprovação do gestor'}
        </p>
        <div className="flex gap-2 mt-2">
          <button
            onClick={() => setSaved(null)}
            className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]"
          >
            Nova Mesa
          </button>
          <button
            onClick={onVoltar}
            className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]"
          >
            Ver Empreendimentos
          </button>
        </div>
      </div>
    );
  }

  const handleSalvar = async ({ clienteNome, valorTotal, metaObraPct, tabelaProvisoria, metaEspecial, fluxoJson }) => {
    const precisaAprovacao = metaEspecial || (metaObraPct < (config.meta_obra_pct ?? 30));

    const id = await criarSimulacao({
      empresaId,
      empreendimentoId: empreendimento.id,
      unidadeId:        null,
      leadId:           null,
      clienteNome:      clienteNome || null,
      valorTotal,
      metaObraPct,
      tabelaProvisoria: empreendimento.tabela_tipo === 'trabalho',
      fluxoJson,
    });

    setSaved({ id, precisaAprovacao });
  };

  return (
    <div className="p-3">
      <FluxoBuilder
        empreendimento={empreendimento}
        precoTotal={empreendimento.valor_tabela ?? 850000}
        empresaConfig={config}
        tabelaProvisoria={empreendimento.tabela_tipo === 'trabalho'}
        onSalvar={handleSalvar}
        onVoltar={onVoltar}
      />
    </div>
  );
}
