/**
 * useMesaData.js
 * Camada definitiva de dados da Mesa Cliente.
 *
 * Padrão FECH.AI:
 * - recebe o client único `sb` criado no App.jsx;
 * - recebe o token da sessão autenticada;
 * - chama apenas RPCs tenant-safe;
 * - não importa/cria cliente Supabase paralelo;
 * - TanStack Query fica somente como cache/estado de rede do front.
 */

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export const MESA_KEYS = {
  empreendimentos: (empresaId) => ['mesa', 'empreendimentos', empresaId],
  config: (empresaId) => ['mesa', 'config', empresaId],
  historico: (empresaId, filtros = {}) => ['mesa', 'historico', empresaId, filtros],
  unidades: (empreendimentoId) => ['mesa', 'unidades', empreendimentoId],
};

function assertMesaClient({ sb, token }) {
  if (!sb || typeof sb.rpc !== 'function') {
    throw new Error('Client RPC do FECH.AI não disponível para a Mesa Cliente.');
  }
  if (!token) {
    throw new Error('Sessão autenticada ausente para a Mesa Cliente.');
  }
}

async function callMesaRpc({ sb, token, fn, args = {} }) {
  assertMesaClient({ sb, token });

  try {
    return await sb.rpc(fn, args, token);
  } catch (error) {
    const msg = error?.message || `Erro ao executar ${fn}`;
    throw new Error(msg);
  }
}

function normalizeError(error) {
  return error ? (error.message || String(error)) : null;
}

function withCompat(result) {
  return {
    ...result,
    isLoading: result.isLoading || result.isPending || result.fetchStatus === 'fetching',
    reload: result.refetch,
    error: normalizeError(result.error),
  };
}

function withMutationCompat(result) {
  return {
    ...result,
    isLoading: result.isPending,
    error: normalizeError(result.error),
  };
}

export function useEmpreendimentosMesa({ sb, token, empresaId }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.empreendimentos(empresaId),
    queryFn: async () => callMesaRpc({
      sb,
      token,
      fn: 'get_empreendimentos_mesa',
      args: { p_empresa_id: empresaId },
    }),
    enabled: Boolean(sb && token && empresaId),
    staleTime: 2 * 60 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useEmpresaMesaConfig({ sb, token, empresaId }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.config(empresaId),
    queryFn: async () => callMesaRpc({
      sb,
      token,
      fn: 'get_empresa_mesa_config',
      args: { p_empresa_id: empresaId },
    }),
    enabled: Boolean(sb && token && empresaId),
    staleTime: 10 * 60 * 1000,
    refetchOnWindowFocus: false,
  }));
}

export function useHistoricoMesas({ sb, token, empresaId, filtros = {}, corretorId = null }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.historico(empresaId, { ...filtros, corretorId }),
    queryFn: async () => callMesaRpc({
      sb,
      token,
      fn: 'get_historico_mesas',
      args: {
        p_empresa_id: empresaId,
        p_corretor_id: corretorId ?? null,
        p_emp_id: filtros.empId ?? null,
        p_status: filtros.status ?? null,
        p_busca: filtros.busca || null,
        p_limit: 50,
        p_offset: 0,
      },
    }),
    enabled: Boolean(sb && token && empresaId),
    staleTime: 30 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useUnidadesMesa({ sb, token, empreendimentoId }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.unidades(empreendimentoId),
    queryFn: async () => callMesaRpc({
      sb,
      token,
      fn: 'get_unidades_mesa',
      args: { p_empreendimento_id: empreendimentoId },
    }),
    enabled: Boolean(sb && token && empreendimentoId),
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
  }));
}

export function useRegistrarUpload({ sb, token }) {
  const queryClient = useQueryClient();

  return withMutationCompat(useMutation({
    mutationFn: async ({ empresaId, empreendimentoId, tipoArquivo, nomeArquivo, storagePath, observacoes }) => callMesaRpc({
      sb,
      token,
      fn: 'registrar_upload_arquivo_mesa',
      args: {
        p_empresa_id: empresaId,
        p_empreendimento_id: empreendimentoId,
        p_tipo_arquivo: tipoArquivo,
        p_nome_arquivo: nomeArquivo,
        p_storage_path: storagePath ?? null,
        p_observacoes: observacoes ?? null,
      },
    }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.empreendimentos(variables.empresaId) });
    },
  }));
}

export function useCriarMesaSimulacao({ sb, token }) {
  const queryClient = useQueryClient();

  return withMutationCompat(useMutation({
    mutationFn: async ({ empresaId, empreendimentoId, unidadeId, leadId, clienteNome, valorTotal, metaObraPct, tabelaProvisoria, fluxoJson }) => callMesaRpc({
      sb,
      token,
      fn: 'criar_mesa_simulacao',
      args: {
        p_empresa_id: empresaId,
        p_empreendimento_id: empreendimentoId,
        p_unidade_id: unidadeId ?? null,
        p_lead_id: leadId ?? null,
        p_cliente_nome: clienteNome ?? null,
        p_valor_total: valorTotal,
        p_meta_obra_pct: metaObraPct ?? 30,
        p_tabela_provisoria: tabelaProvisoria ?? false,
        p_fluxo_json: fluxoJson,
      },
    }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['mesa', 'historico', variables.empresaId] });
    },
  }));
}

export function useAprovarRejeitarMesa({ sb, token }) {
  const queryClient = useQueryClient();

  return withMutationCompat(useMutation({
    mutationFn: async ({ simulacaoId, acao, justificativa, empresaId }) => {
      const data = await callMesaRpc({
        sb,
        token,
        fn: 'aprovar_rejeitar_mesa',
        args: {
          p_simulacao_id: simulacaoId,
          p_acao: acao,
          p_justificativa: justificativa ?? null,
        },
      });
      return { data, empresaId };
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['mesa', 'historico', variables.empresaId] });
    },
  }));
}

export function useImportarMesaClienteParserResultado({ sb, token }) {
  const queryClient = useQueryClient();

  return withMutationCompat(useMutation({
    mutationFn: async ({ empresaId, empreendimentoNome, incorporadora, bairro, cidade, nomeArquivo, parserNome, unidades }) => callMesaRpc({
      sb,
      token,
      fn: 'importar_mesa_cliente_parser_resultado',
      args: {
        p_empresa_id: empresaId,
        p_empreendimento_nome: empreendimentoNome,
        p_incorporadora: incorporadora || null,
        p_bairro: bairro || null,
        p_cidade: cidade || null,
        p_nome_arquivo: nomeArquivo || 'parser-json-manual.json',
        p_parser_nome: parserNome || 'manual_json_preview',
        p_parser_json: { unidades },
      },
    }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.empreendimentos(variables.empresaId) });
      queryClient.invalidateQueries({ queryKey: ['mesa'] });
    },
  }));
}
