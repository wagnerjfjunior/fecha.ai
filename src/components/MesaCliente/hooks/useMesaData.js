/**
 * useMesaData.js
 * Hooks TanStack Query para dados do Supabase da Mesa Cliente.
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '../../lib/supabaseClient';

export const MESA_KEYS = {
  empreendimentos: (id) => ['mesa', 'empreendimentos', id],
  config: (id) => ['mesa', 'config', id],
  historico: (id, f) => ['mesa', 'historico', id, f],
};

export function useEmpreendimentosMesa(empresaId) {
  return useQuery({
    queryKey: MESA_KEYS.empreendimentos(empresaId),
    queryFn: async () => {
      const { data, error } = await supabase.rpc('get_empreendimentos_mesa', { p_empresa_id: empresaId });
      if (error) throw error; return data ?? [];
    },
    enabled: !!empresaId, staleTime: 2*160*1000, refetchOnWindowFocus: true,
  });
}

export function useEmpresaMesaConfig(empresaId) {
  return useQuery({
    queryKey: MESA_KEYS.config(empresaId),
    queryFn: async () => {
      const { data, error } = await supabase.rpc('get_empresa_mesa_config', { p_empresa_id: empresaId });
      if (error) throw error; return data ?? {};
    },
    enabled: !!empresaId, staleTime: 10*60*1000, refetchOnWindowFocus: false,
  });
}

export function useHistoricoMesas(empresaId, filtros={}, corretorId=null) {
  return useQuery({
    queryKey: MESA_KEYS.historico(empresaId, {...filtros,corretorId}),
    queryFn: async () => {
      const { data, error } = await supabase.rpc('get_historico_mesas', {
        p_empresa_id: empresaId, p_corretor_id: corretorId??null,
        p_emp_id: filtros.empId??null, p_status: filtros.status??null,
        p_busca: filtros.busca||null, p_limit: 50, p_offset: 0,
      });
      if (error) throw error; return data ?? [];
    },
    enabled: !!empresaId, staleTime: 30*1000, refetchOnWindowFocus: true,
  });
}

export function useRegistrarUpload() {
  const qc=useQueryClient();
  return useMutation({
    mutationFn: async ({ empresaId, empreendimentoId, tipoArquivo, nomeArquivo, storagePath, observacoes }) => {
      const { data, error } = await supabase.rpc('registrar_upload_arquivo_mesa', {
        p_empresa_id: empresaId, p_empreendimento_id: empreendimentoId,
        p_tipo_arquivo: tipoArquivo, p_nome_arquivo: nomeArquivo,
        p_storage_path: storagePath??null, p_observacoes: observacoees??null,
      });
      if (error) throw error; return data;
    },
    onSuccess: (_d,v) => qc.invalidateQueries({queryKey:MESA_KEYS.empreendimentos(v.empresaId)}),
  });
}

export function useCriarMesaSimulacao() {
  const qc=useQueryClient();
  return useMutation({
    mutationFn: async ({ empresaId, empreendimentoId, unidadeId, leadId, clienteNome, valorTotal, metaObraPct, tabelaProvisoria, fluxoJson }) => {
      const { data, error } = await supabase.rpc('criar_mesa_simulacao', {
        p_empresa_id: empresaId, p_empreendimento_id: empreendimentoId,
        p_unidade_id: unidadeId??null, p_lead_id: leadId??null,
        p_cliente_nome: clienteNome??null, p_valor_total: valorTotal,
        p_meta_obra_pct: metaObraPct??30, p_tabela_provisoria: tabelaProvisoria??false,
        p_fluxo_json: JSON.stringify(fluxoJson),
      });
      if (error) throw error; return data;
    },
    onSuccess: (_d,v) => qc.invalidateQueries({queryKey:MESA_KEYS.historico(v.empresaId,{})}),
  });
}

export function useAprovarRejeitarMesa() {
  const qc=useQueryClient();
  return useMutation({
    mutationFn: async ({ simulacaoId, acao, justificativa, empresaId }) => {
      const { data, error } = await supabase.rpc('aprovar_rejeitar_mesa', {
        p_simulacao_id: simulacaoId, p_acao: acao, p_justificativa: justificativa??null,
      });
      if (error) throw error; return data;
    },
    onSuccess: (_d,v) => qc.invalidateQueries({queryKey:MESA_KEYS.historico(v.empresaId,{})}),
  });
}
