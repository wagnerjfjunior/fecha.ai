function assertRpcClient({ sb, token }) {
  if (!sb || typeof sb.rpc !== 'function') {
    throw new Error('Client RPC do FECH.AI não disponível para a Mesa Cliente.');
  }

  if (!token) {
    throw new Error('Sessão autenticada ausente para a Mesa Cliente.');
  }
}

function normalizeRpcError(error, fallback) {
  if (!error) return new Error(fallback || 'Erro inesperado na Mesa Cliente.');
  if (error instanceof Error) return error;
  return new Error(error.message || error.error_description || error.details || fallback || String(error));
}

export async function callMesaRpc({ sb, token, fn, args = {} }) {
  assertRpcClient({ sb, token });

  try {
    return await sb.rpc(fn, args, token);
  } catch (error) {
    throw normalizeRpcError(error, `Erro ao executar ${fn}`);
  }
}

export function getEmpreendimentosMesa({ sb, token, empresaId }) {
  return callMesaRpc({
    sb,
    token,
    fn: 'get_empreendimentos_mesa',
    args: { p_empresa_id: empresaId },
  });
}

export function getEmpresaMesaConfig({ sb, token, empresaId }) {
  return callMesaRpc({
    sb,
    token,
    fn: 'get_empresa_mesa_config',
    args: { p_empresa_id: empresaId },
  });
}

export function getHistoricoMesas({ sb, token, empresaId, filtros = {}, corretorId = null }) {
  return callMesaRpc({
    sb,
    token,
    fn: 'get_historico_mesas',
    args: {
      p_empresa_id: empresaId,
      p_corretor_id: corretorId ?? null,
      p_emp_id: filtros.empId ?? null,
      p_status: filtros.status ?? null,
      p_busca: filtros.busca || null,
      p_limit: filtros.limit ?? 50,
      p_offset: filtros.offset ?? 0,
    },
  });
}

export function getUnidadesMesa({ sb, token, empreendimentoId }) {
  return callMesaRpc({
    sb,
    token,
    fn: 'get_unidades_mesa',
    args: { p_empreendimento_id: empreendimentoId },
  });
}

export function registrarUploadArquivoMesa({
  sb,
  token,
  empresaId,
  empreendimentoId,
  tipoArquivo,
  nomeArquivo,
  storagePath = null,
  observacoes = null,
}) {
  return callMesaRpc({
    sb,
    token,
    fn: 'registrar_upload_arquivo_mesa',
    args: {
      p_empresa_id: empresaId,
      p_empreendimento_id: empreendimentoId,
      p_tipo_arquivo: tipoArquivo,
      p_nome_arquivo: nomeArquivo,
      p_storage_path: storagePath,
      p_observacoes: observacoes,
    },
  });
}

export function criarMesaSimulacao({
  sb,
  token,
  empresaId,
  empreendimentoId,
  unidadeId = null,
  leadId = null,
  clienteNome = null,
  valorTotal,
  metaObraPct = 30,
  tabelaProvisoria = false,
  fluxoJson,
}) {
  return callMesaRpc({
    sb,
    token,
    fn: 'criar_mesa_simulacao',
    args: {
      p_empresa_id: empresaId,
      p_empreendimento_id: empreendimentoId,
      p_unidade_id: unidadeId,
      p_lead_id: leadId,
      p_cliente_nome: clienteNome,
      p_valor_total: valorTotal,
      p_meta_obra_pct: metaObraPct,
      p_tabela_provisoria: tabelaProvisoria,
      p_fluxo_json: fluxoJson,
    },
  });
}

export function aprovarRejeitarMesa({ sb, token, simulacaoId, acao, justificativa = null }) {
  return callMesaRpc({
    sb,
    token,
    fn: 'aprovar_rejeitar_mesa',
    args: {
      p_simulacao_id: simulacaoId,
      p_acao: acao,
      p_justificativa: justificativa,
    },
  });
}

export function importarMesaClienteParserResultado({
  sb,
  token,
  empresaId,
  empreendimentoNome,
  incorporadora = null,
  bairro = null,
  cidade = null,
  nomeArquivo = 'parser-json-manual.json',
  parserNome = 'manual_json_preview',
  unidades,
}) {
  return callMesaRpc({
    sb,
    token,
    fn: 'importar_mesa_cliente_parser_resultado',
    args: {
      p_empresa_id: empresaId,
      p_empreendimento_nome: empreendimentoNome,
      p_incorporadora: incorporadora,
      p_bairro: bairro,
      p_cidade: cidade,
      p_nome_arquivo: nomeArquivo,
      p_parser_nome: parserNome,
      p_parser_json: { unidades },
    },
  });
}
