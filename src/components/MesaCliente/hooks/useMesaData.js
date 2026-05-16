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
  salvarMesaClienteEnriquecimento,
} from '../../../features/mesaCliente/api/mesaClienteApi';

export const MESA_KEYS = {
  root: ['mesa'],
  empreendimentos: (empresaId) => ['mesa', 'empreendimentos', empresaId],
  config: (empresaId) => ['mesa', 'config', empresaId],
  historico: (empresaId, filtros = {}) => ['mesa', 'historico', empresaId, filtros],
  unidades: (empreendimentoId) => ['mesa', 'unidades', empreendimentoId],
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
