import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  getEmpreendimentosMesa,
  getEmpresaMesaConfig,
  getHistoricoMesas,
  getUnidadesMesa,
  registrarUploadArquivoMesa,
  criarMesaSimulacao,
  aprovarRejeitarMesa,
  importarMesaClienteParserResultado,
  usuarioPodeImportarMesaJsonAdmin,
  importarMesaClienteJsonAdmin,
  importarMesaClienteDisponibilidadeOficial,
  salvarMesaClienteEnriquecimento,
  obterSimulacaoFluxoHistorico,
} from '../../../features/mesaCliente/api/mesaClienteApi';
import {
  aplicarOperacaoFinanceiraAdmin,
  mapMesaClienteOperacaoFinanceiraError,
  obterOperacaoFinanceiraAdmin,
  obterResumoOperacaoClienteSafe,
  resumirOperacaoFinanceiraAdmin,
  listarOperacoesFinanceirasAdmin,
} from '../../../features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi';

export const MESA_KEYS = {
  root: ['mesa'],
  empreendimentos: (empresaId) => ['mesa', 'empreendimentos', empresaId],
  config: (empresaId) => ['mesa', 'config', empresaId],
  historico: (empresaId, filtros = {}) => ['mesa', 'historico', empresaId, filtros],
  unidades: (empreendimentoId) => ['mesa', 'unidades', empreendimentoId],
  fluxoHistorico: (simulacaoId) => ['mesa', 'fluxo-historico', simulacaoId],
  jsonAdminPermission: (empresaId) => ['mesa', 'json-admin-permission', empresaId],
  operacoesFinanceiras: (simulacaoId, agendaId = null, filtros = {}) => [
    'mesa',
    'operacoes-financeiras',
    simulacaoId,
    agendaId,
    filtros,
  ],
  operacaoFinanceira: (operacaoId) => ['mesa', 'operacao-financeira', operacaoId],
  resumoOperacaoFinanceiraAdmin: (operacaoId) => ['mesa', 'resumo-operacao-financeira-admin', operacaoId],
  resumoOperacaoClienteSafe: (operacaoId) => ['mesa', 'resumo-operacao-cliente-safe', operacaoId],
};

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

function withFinanceMutationCompat(result) {
  return {
    ...withMutationCompat(result),
    mappedError: result.error ? mapMesaClienteOperacaoFinanceiraError(result.error) : null,
  };
}

export function useEmpreendimentosMesa({ sb, token, empresaId }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.empreendimentos(empresaId),
    queryFn: () => getEmpreendimentosMesa({ sb, token, empresaId }),
    enabled: Boolean(sb && token && empresaId),
    staleTime: 2 * 60 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useEmpresaMesaConfig({ sb, token, empresaId }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.config(empresaId),
    queryFn: () => getEmpresaMesaConfig({ sb, token, empresaId }),
    enabled: Boolean(sb && token && empresaId),
    staleTime: 10 * 60 * 1000,
    refetchOnWindowFocus: false,
  }));
}

export function useMesaJsonAdminPermission({ sb, token, empresaId }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.jsonAdminPermission(empresaId),
    queryFn: () => usuarioPodeImportarMesaJsonAdmin({ sb, token, empresaId }),
    enabled: Boolean(sb && token && empresaId),
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useHistoricoMesas({ sb, token, empresaId, filtros = {}, corretorId = null }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.historico(empresaId, { ...filtros, corretorId }),
    queryFn: () => getHistoricoMesas({ sb, token, empresaId, filtros, corretorId }),
    enabled: Boolean(sb && token && empresaId),
    staleTime: 30 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useUnidadesMesa({ sb, token, empreendimentoId }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.unidades(empreendimentoId),
    queryFn: () => getUnidadesMesa({ sb, token, empreendimentoId }),
    enabled: Boolean(sb && token && empreendimentoId),
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
  }));
}

export function useSimulacaoFluxoHistorico({ sb, token, simulacaoId, parametros = {} }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.fluxoHistorico(simulacaoId),
    queryFn: () => obterSimulacaoFluxoHistorico({ sb, token, simulacaoId, parametros }),
    enabled: Boolean(sb && token && simulacaoId),
    staleTime: 15 * 1000,
    refetchOnWindowFocus: false,
  }));
}

export function useOperacoesFinanceirasAdmin({ sb, token, simulacaoId, agendaId = null, filtros = {} }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.operacoesFinanceiras(simulacaoId, agendaId, filtros),
    queryFn: () => listarOperacoesFinanceirasAdmin({ sb, token, simulacaoId, agendaId, filtros }),
    enabled: Boolean(sb && token && simulacaoId),
    staleTime: 15 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useOperacaoFinanceiraAdmin({ sb, token, operacaoId, parametros = {} }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.operacaoFinanceira(operacaoId),
    queryFn: () => obterOperacaoFinanceiraAdmin({ sb, token, operacaoId, parametros }),
    enabled: Boolean(sb && token && operacaoId),
    staleTime: 15 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useResumoOperacaoFinanceiraAdmin({ sb, token, operacaoId, parametros = {} }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.resumoOperacaoFinanceiraAdmin(operacaoId),
    queryFn: () => resumirOperacaoFinanceiraAdmin({ sb, token, operacaoId, parametros }),
    enabled: Boolean(sb && token && operacaoId),
    staleTime: 15 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useResumoOperacaoClienteSafe({ sb, token, operacaoId, parametros = {} }) {
  return withCompat(useQuery({
    queryKey: MESA_KEYS.resumoOperacaoClienteSafe(operacaoId),
    queryFn: () => obterResumoOperacaoClienteSafe({ sb, token, operacaoId, parametros }),
    enabled: Boolean(sb && token && operacaoId),
    staleTime: 15 * 1000,
    refetchOnWindowFocus: true,
  }));
}

export function useRegistrarUpload({ sb, token }) {
  const queryClient = useQueryClient();
  return withMutationCompat(useMutation({
    mutationFn: (variables) => registrarUploadArquivoMesa({ sb, token, ...variables }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.empreendimentos(variables.empresaId) });
    },
  }));
}

export function useCriarMesaSimulacao({ sb, token }) {
  const queryClient = useQueryClient();
  return withMutationCompat(useMutation({
    mutationFn: (variables) => criarMesaSimulacao({ sb, token, ...variables }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['mesa', 'historico', variables.empresaId] });
    },
  }));
}

export function useAprovarRejeitarMesa({ sb, token }) {
  const queryClient = useQueryClient();
  return withMutationCompat(useMutation({
    mutationFn: async (variables) => {
      const data = await aprovarRejeitarMesa({ sb, token, ...variables });
      return { data, empresaId: variables.empresaId };
    },
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['mesa', 'historico', variables.empresaId] });
    },
  }));
}

export function useAplicarOperacaoFinanceiraAdmin({ sb, token }) {
  const queryClient = useQueryClient();

  return withFinanceMutationCompat(useMutation({
    mutationFn: (variables) => aplicarOperacaoFinanceiraAdmin({ sb, token, ...variables }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: ['mesa', 'operacoes-financeiras'] });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.operacaoFinanceira(variables.operacaoId) });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.resumoOperacaoFinanceiraAdmin(variables.operacaoId) });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.resumoOperacaoClienteSafe(variables.operacaoId) });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.root });
    },
  }));
}

export function useImportarMesaClienteParserResultado({ sb, token }) {
  const queryClient = useQueryClient();
  return withMutationCompat(useMutation({
    mutationFn: (variables) => importarMesaClienteParserResultado({ sb, token, ...variables }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.empreendimentos(variables.empresaId) });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.root });
    },
  }));
}

export function useImportarMesaClienteJsonAdmin({ sb, token }) {
  const queryClient = useQueryClient();
  return withMutationCompat(useMutation({
    mutationFn: (variables) => importarMesaClienteJsonAdmin({ sb, token, ...variables }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.empreendimentos(variables.empresaId) });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.root });
    },
  }));
}

export function useImportarMesaClienteDisponibilidadeOficial({ sb, token }) {
  const queryClient = useQueryClient();
  return withMutationCompat(useMutation({
    mutationFn: (variables) => importarMesaClienteDisponibilidadeOficial({ sb, token, ...variables }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.empreendimentos(variables.empresaId) });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.unidades(variables.empreendimentoId) });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.root });
    },
  }));
}

export function useSalvarMesaClienteEnriquecimento({ sb, token }) {
  const queryClient = useQueryClient();
  return withMutationCompat(useMutation({
    mutationFn: (variables) => salvarMesaClienteEnriquecimento({ sb, token, ...variables }),
    onSuccess: (_data, variables) => {
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.unidades(variables.empreendimentoId) });
      queryClient.invalidateQueries({ queryKey: MESA_KEYS.root });
    },
  }));
}
