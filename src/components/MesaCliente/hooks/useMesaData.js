/**
 * useMesaData.js
 * Hooks de dados da Mesa Cliente usando o cliente RPC real do FECH.AI.
 *
 * Decisão desta preview:
 * - Não criar supabaseClient paralelo.
 * - Não depender de @tanstack/react-query enquanto o pacote não estiver instalado.
 * - Usar sb.rpc + token recebidos do App principal.
 * - Manter isolamento real no banco via RPCs tenant-safe.
 */

import { useCallback, useEffect, useMemo, useState } from 'react';

const EMPTY_ARRAY = Object.freeze([]);
const EMPTY_OBJECT = Object.freeze({});

function normalizeError(error, fallback = 'Erro ao carregar dados da Mesa Cliente') {
  if (!error) return fallback;
  if (typeof error === 'string') return error;
  return error.message || error.error || fallback;
}

async function callRpc(sb, token, name, args = {}) {
  if (!sb || !token) throw new Error('Sessão não inicializada');
  const data = await sb.rpc(name, args, token);
  if (data?.error) throw new Error(data.error);
  return data;
}

function useRpcQuery({ sb, token, name, args, enabled = true, defaultData, deps = [] }) {
  const [data, setData] = useState(defaultData);
  const [isLoading, setIsLoading] = useState(Boolean(enabled));
  const [error, setError] = useState(null);
  const [refreshTick, setRefreshTick] = useState(0);

  const reload = useCallback(() => {
    setRefreshTick(v => v + 1);
  }, []);

  useEffect(() => {
    let alive = true;

    if (!enabled || !sb || !token) {
      setIsLoading(false);
      return () => { alive = false; };
    }

    setIsLoading(true);
    setError(null);

    callRpc(sb, token, name, args)
      .then(result => {
        if (!alive) return;
        setData(result ?? defaultData);
      })
      .catch(err => {
        if (!alive) return;
        setError(normalizeError(err));
        setData(defaultData);
      })
      .finally(() => {
        if (alive) setIsLoading(false);
      });

    return () => { alive = false; };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sb, token, name, enabled, refreshTick, ...deps]);

  return { data, isLoading, error, reload };
}

export function useEmpreendimentosMesa({ sb, token, empresaId }) {
  const args = useMemo(() => ({ p_empresa_id: empresaId }), [empresaId]);
  return useRpcQuery({
    sb,
    token,
    name: 'get_empreendimentos_mesa',
    args,
    enabled: Boolean(empresaId),
    defaultData: EMPTY_ARRAY,
    deps: [empresaId],
  });
}

export function useEmpresaMesaConfig({ sb, token, empresaId }) {
  const args = useMemo(() => ({ p_empresa_id: empresaId }), [empresaId]);
  return useRpcQuery({
    sb,
    token,
    name: 'get_empresa_mesa_config',
    args,
    enabled: Boolean(empresaId),
    defaultData: EMPTY_OBJECT,
    deps: [empresaId],
  });
}

export function useUnidadesMesa({ sb, token, empreendimentoId }) {
  const args = useMemo(() => ({ p_empreendimento_id: empreendimentoId }), [empreendimentoId]);
  return useRpcQuery({
    sb,
    token,
    name: 'get_unidades_mesa',
    args,
    enabled: Boolean(empreendimentoId),
    defaultData: EMPTY_ARRAY,
    deps: [empreendimentoId],
  });
}

export function useHistoricoMesas({ sb, token, empresaId, filtros = {}, corretorId = null }) {
  const args = useMemo(() => ({
    p_empresa_id: empresaId,
    p_corretor_id: corretorId ?? null,
    p_emp_id: filtros.empId ?? null,
    p_status: filtros.status ?? null,
    p_busca: filtros.busca || null,
    p_limit: 50,
    p_offset: 0,
  }), [empresaId, corretorId, filtros.empId, filtros.status, filtros.busca]);

  return useRpcQuery({
    sb,
    token,
    name: 'get_historico_mesas',
    args,
    enabled: Boolean(empresaId),
    defaultData: EMPTY_ARRAY,
    deps: [empresaId, corretorId, filtros.empId, filtros.status, filtros.busca],
  });
}

export function useRegistrarUpload({ sb, token, onSuccess } = {}) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const mutateAsync = useCallback(async ({
    empresaId,
    empreendimentoId,
    tipoArquivo,
    nomeArquivo,
    storagePath,
    observacoes,
  }) => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await callRpc(sb, token, 'registrar_upload_arquivo_mesa', {
        p_empresa_id: empresaId,
        p_empreendimento_id: empreendimentoId,
        p_tipo_arquivo: tipoArquivo,
        p_nome_arquivo: nomeArquivo,
        p_storage_path: storagePath ?? null,
        p_observacoes: observacoes ?? null,
      });
      onSuccess?.(data, { empresaId, empreendimentoId });
      return data;
    } catch (err) {
      const msg = normalizeError(err, 'Erro ao registrar upload');
      setError(msg);
      throw new Error(msg);
    } finally {
      setIsLoading(false);
    }
  }, [sb, token, onSuccess]);

  return { mutateAsync, isLoading, error };
}

export function useImportarUnidadesMesaParser({ sb, token, onSuccess } = {}) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const mutateAsync = useCallback(async ({ empreendimentoId, arquivoId = null, parserNome, unidades }) => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await callRpc(sb, token, 'importar_unidades_mesa_parser', {
        p_empreendimento_id: empreendimentoId,
        p_arquivo_id: arquivoId,
        p_parser_nome: parserNome ?? null,
        p_unidades: unidades ?? [],
      });
      onSuccess?.(data, { empreendimentoId });
      return data;
    } catch (err) {
      const msg = normalizeError(err, 'Erro ao importar unidades do parser');
      setError(msg);
      throw new Error(msg);
    } finally {
      setIsLoading(false);
    }
  }, [sb, token, onSuccess]);

  return { mutateAsync, isLoading, error };
}

export function useCriarMesaSimulacao({ sb, token, onSuccess } = {}) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const mutateAsync = useCallback(async ({
    empresaId,
    empreendimentoId,
    unidadeId,
    leadId,
    clienteNome,
    valorTotal,
    metaObraPct,
    tabelaProvisoria,
    fluxoJson,
  }) => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await callRpc(sb, token, 'criar_mesa_simulacao', {
        p_empresa_id: empresaId,
        p_empreendimento_id: empreendimentoId,
        p_unidade_id: unidadeId ?? null,
        p_lead_id: leadId ?? null,
        p_cliente_nome: clienteNome ?? null,
        p_valor_total: valorTotal,
        p_meta_obra_pct: metaObraPct ?? 30,
        p_tabela_provisoria: tabelaProvisoria ?? false,
        p_fluxo_json: fluxoJson ?? [],
      });
      onSuccess?.(data, { empresaId, empreendimentoId, unidadeId });
      return data;
    } catch (err) {
      const msg = normalizeError(err, 'Erro ao criar simulação');
      setError(msg);
      throw new Error(msg);
    } finally {
      setIsLoading(false);
    }
  }, [sb, token, onSuccess]);

  return { mutateAsync, isLoading, error };
}

export function useAprovarRejeitarMesa({ sb, token, onSuccess } = {}) {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);

  const mutateAsync = useCallback(async ({ simulacaoId, acao, justificativa, empresaId }) => {
    setIsLoading(true);
    setError(null);
    try {
      const data = await callRpc(sb, token, 'aprovar_rejeitar_mesa', {
        p_simulacao_id: simulacaoId,
        p_acao: acao,
        p_justificativa: justificativa ?? null,
      });
      onSuccess?.(data, { empresaId, simulacaoId });
      return data;
    } catch (err) {
      const msg = normalizeError(err, 'Erro ao aprovar/rejeitar mesa');
      setError(msg);
      throw new Error(msg);
    } finally {
      setIsLoading(false);
    }
  }, [sb, token, onSuccess]);

  return { mutateAsync, isLoading, error };
}
