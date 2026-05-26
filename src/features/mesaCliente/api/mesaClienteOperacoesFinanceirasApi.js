import { callMesaRpc } from './mesaClienteApi';

const RPCS = Object.freeze({
  listarOperacoesAdmin: 'mesa_cliente_listar_operacoes_financeiras_admin',
  obterOperacaoAdmin: 'mesa_cliente_obter_operacao_financeira_admin',
  resumirOperacaoAdmin: 'mesa_cliente_resumir_operacao_financeira_admin',
  obterResumoClienteSafe: 'mesa_cliente_obter_resumo_operacao_cliente_safe',
  aplicarOperacaoAdmin: 'mesa_cliente_aplicar_operacao_financeira_admin',
});

const STATUS_OPERACAO_CANONICOS = new Set([
  'simulada',
  'confirmada',
  'aplicada',
  'cancelada',
  'bloqueada',
]);

const STATUS_OPERACAO_FILTRO_5D = new Set([
  'simulada',
  'confirmada',
  'cancelada',
  'bloqueada',
]);

const TIPOS_OPERACAO = new Set([
  'antecipacao',
  'postergacao',
  'vpl',
]);

const ORDER_BY_LISTAGEM = new Set([
  'created_at',
  'updated_at',
  'status_operacao',
  'tipo_operacao',
]);

const ORDER_DIR_LISTAGEM = new Set(['asc', 'desc']);

const FRONTEND_AUTHORITY_KEYS = new Set([
  'empresa_id',
  'tenant_id',
  'simulacao_id',
  'agenda_id',
  'empreendimento_id',
  'politica_id',
  'parcela_origem_id',
  'parcela_destino_id',
  'corretor_id',
  'user_id',
  'auth_uid',
  'role',
  'perfil',
  'is_admin',
  'is_gestor',
  'is_admin_local',
  'tipo_operacao',
  'valor_base',
  'valor_movido',
  'taxa_ano_pct',
  'vpl_aplicado_pct',
  'desconto_calculado',
  'acrescimo_calculado',
  'economia_liquida',
  'premio_corretor_pct',
  'status_premio',
  'status_operacao',
  'confirmado',
  'confirmado_por',
  'confirmado_em',
  'cancelado_por',
  'cancelado_em',
  'motivo_cancelamento',
  'visivel_cliente',
  'checksum_operacao',
  'metadata',
  'created_at',
  'updated_at',
  'criado_por',
]);

function parseJsonIfNeeded(value) {
  if (typeof value !== 'string') return value;

  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

function assertUuidLike(value, fieldName) {
  if (!value || typeof value !== 'string') {
    throw new Error(`${fieldName} é obrigatório.`);
  }
}

function clampInteger(value, fallback, min, max) {
  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed)) return fallback;
  return Math.min(Math.max(parsed, min), max);
}

function normalizeDateFilter(value) {
  if (!value) return null;
  if (value instanceof Date && !Number.isNaN(value.valueOf())) {
    return value.toISOString().slice(0, 10);
  }
  if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return value;
  }
  return null;
}

function gerarCorrelationId() {
  const randomUuid = globalThis.crypto?.randomUUID?.();
  if (randomUuid) return randomUuid;

  return `mesa-front-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

function sanitizeMetadata(metadata) {
  if (!metadata || typeof metadata !== 'object' || Array.isArray(metadata)) {
    return undefined;
  }

  const sanitized = {};
  Object.entries(metadata).forEach(([key, value]) => {
    if (FRONTEND_AUTHORITY_KEYS.has(key)) return;
    if (value === undefined) return;
    sanitized[key] = value;
  });

  return Object.keys(sanitized).length > 0 ? sanitized : undefined;
}

function sanitizeParametrosLeitura(parametros = {}) {
  if (!parametros || typeof parametros !== 'object' || Array.isArray(parametros)) return {};

  const sanitized = {};
  Object.entries(parametros).forEach(([key, value]) => {
    if (FRONTEND_AUTHORITY_KEYS.has(key)) return;
    if (value === undefined) return;
    sanitized[key] = value;
  });

  return sanitized;
}

export function sanitizeParametrosAplicacaoFinanceira(parametros = {}) {
  const safeInput = parametros && typeof parametros === 'object' && !Array.isArray(parametros)
    ? parametros
    : {};

  const sanitized = {
    origem_front: 'mesa_cliente_fase_8',
    correlation_id: safeInput.correlation_id || gerarCorrelationId(),
  };

  if (typeof safeInput.motivo === 'string' && safeInput.motivo.trim()) {
    sanitized.motivo = safeInput.motivo.trim().slice(0, 500);
  }

  if (typeof safeInput.observacao === 'string' && safeInput.observacao.trim()) {
    sanitized.observacao = safeInput.observacao.trim().slice(0, 1000);
  }

  const metadata = sanitizeMetadata(safeInput.metadata);
  if (metadata) {
    sanitized.metadata_front = metadata;
  }

  return sanitized;
}

export function normalizeFiltrosOperacoesFinanceiras(filtros = {}) {
  const safeInput = filtros && typeof filtros === 'object' && !Array.isArray(filtros)
    ? filtros
    : {};

  const normalized = {
    limit: clampInteger(safeInput.limit ?? safeInput.pageSize, 50, 1, 200),
    offset: clampInteger(safeInput.offset, 0, 0, Number.MAX_SAFE_INTEGER),
    order_by: ORDER_BY_LISTAGEM.has(safeInput.order_by) ? safeInput.order_by : 'created_at',
    order_dir: ORDER_DIR_LISTAGEM.has(String(safeInput.order_dir || '').toLowerCase())
      ? String(safeInput.order_dir).toLowerCase()
      : 'desc',
  };

  if (safeInput.page && !safeInput.offset) {
    const page = clampInteger(safeInput.page, 1, 1, Number.MAX_SAFE_INTEGER);
    normalized.offset = (page - 1) * normalized.limit;
  }

  const status = typeof safeInput.status_operacao === 'string'
    ? safeInput.status_operacao.toLowerCase().trim()
    : null;

  const clientSideStatusOperacao = status === 'aplicada' ? 'aplicada' : null;
  if (status && STATUS_OPERACAO_CANONICOS.has(status) && STATUS_OPERACAO_FILTRO_5D.has(status)) {
    normalized.status_operacao = status;
  }

  const tipo = typeof safeInput.tipo_operacao === 'string'
    ? safeInput.tipo_operacao.toLowerCase().trim()
    : null;
  if (tipo && TIPOS_OPERACAO.has(tipo)) {
    normalized.tipo_operacao = tipo;
  }

  if (typeof safeInput.visivel_cliente === 'boolean') {
    normalized.visivel_cliente = safeInput.visivel_cliente;
  }

  const dataDe = normalizeDateFilter(safeInput.data_de);
  const dataAte = normalizeDateFilter(safeInput.data_ate);
  if (dataDe) normalized.data_de = dataDe;
  if (dataAte) normalized.data_ate = dataAte;

  return {
    filtrosRpc: normalized,
    clientSideStatusOperacao,
  };
}

function normalizeListagemOperacoesFinanceiras(payload, clientSideStatusOperacao = null) {
  const data = parseJsonIfNeeded(payload);
  if (Array.isArray(data)) {
    return clientSideStatusOperacao
      ? data.filter((item) => item?.status_operacao === clientSideStatusOperacao)
      : data;
  }

  if (!data || typeof data !== 'object') return data;

  const operacoes = Array.isArray(data.operacoes) ? data.operacoes : [];
  const operacoesFiltradas = clientSideStatusOperacao
    ? operacoes.filter((item) => item?.status_operacao === clientSideStatusOperacao)
    : operacoes;

  return {
    ...data,
    operacoes: operacoesFiltradas,
    total_cliente: clientSideStatusOperacao ? operacoesFiltradas.length : data.total,
    filtro_status_cliente_side: clientSideStatusOperacao,
  };
}

export function mapMesaClienteOperacaoFinanceiraError(error) {
  const rawMessage = error?.message || error?.details || error?.hint || String(error || '');
  const message = rawMessage.toLowerCase();

  if (message.includes('auth') || message.includes('sessão') || message.includes('autenticado')) {
    return {
      code: 'AUTH_REQUIRED',
      severity: 'error',
      message: 'Sessão expirada ou ausente. Entre novamente para continuar.',
      rawMessage,
    };
  }

  if (message.includes('tenant') || message.includes('empresa') || message.includes('scope') || message.includes('escopo')) {
    return {
      code: 'SCOPE_DENIED',
      severity: 'error',
      message: 'Esta operação não pertence ao seu escopo de acesso.',
      rawMessage,
    };
  }

  if (message.includes('perfil sem permissão') || message.includes('acesso negado') || message.includes('42501')) {
    return {
      code: 'PERMISSION_DENIED',
      severity: 'error',
      message: 'Seu perfil não tem permissão para executar esta ação.',
      rawMessage,
    };
  }

  if (message.includes('status') && message.includes('confirmada')) {
    return {
      code: 'INVALID_STATUS_TO_APPLY',
      severity: 'warning',
      message: 'A operação precisa estar confirmada antes de ser aplicada.',
      rawMessage,
    };
  }

  if (message.includes('frontend') || message.includes('autoridade') || message.includes('authority')) {
    return {
      code: 'FRONTEND_AUTHORITY_FORBIDDEN',
      severity: 'error',
      message: 'Parâmetro não permitido no frontend. A autoridade financeira é definida pelo banco.',
      rawMessage,
    };
  }

  if (message.includes('not found') || message.includes('não encontrada') || message.includes('nao encontrada')) {
    return {
      code: 'NOT_FOUND',
      severity: 'warning',
      message: 'Operação financeira não encontrada.',
      rawMessage,
    };
  }

  return {
    code: 'MESA_CLIENTE_FINANCIAL_OPERATION_ERROR',
    severity: 'error',
    message: 'Não foi possível processar a operação financeira agora.',
    rawMessage,
  };
}

export function canAplicarOperacaoFinanceira({ operacao, resumoAdmin = null, usuarioPodeAplicar = true } = {}) {
  const status = operacao?.status_operacao || resumoAdmin?.operacao?.status_operacao || resumoAdmin?.status_operacao;
  const confirmado = operacao?.confirmado ?? resumoAdmin?.operacao?.confirmado ?? false;
  const readonly = resumoAdmin?.readonly;

  if (!usuarioPodeAplicar) {
    return { allowed: false, reason: 'perfil_sem_permissao' };
  }

  if (status === 'aplicada') {
    return { allowed: false, reason: 'operacao_ja_aplicada' };
  }

  if (status !== 'confirmada' || confirmado !== true) {
    return { allowed: false, reason: 'operacao_precisa_estar_confirmada' };
  }

  if (readonly === false) {
    return { allowed: false, reason: 'resumo_admin_invalido' };
  }

  return { allowed: true, reason: null };
}

export async function listarOperacoesFinanceirasAdmin({ sb, token, simulacaoId, agendaId = null, filtros = {} }) {
  assertUuidLike(simulacaoId, 'simulacaoId');
  const { filtrosRpc, clientSideStatusOperacao } = normalizeFiltrosOperacoesFinanceiras(filtros);

  const payload = await callMesaRpc({
    sb,
    token,
    fn: RPCS.listarOperacoesAdmin,
    args: {
      p_simulacao_id: simulacaoId,
      p_agenda_id: agendaId ?? null,
      p_filtros: filtrosRpc,
    },
  });

  return normalizeListagemOperacoesFinanceiras(payload, clientSideStatusOperacao);
}

export function obterOperacaoFinanceiraAdmin({ sb, token, operacaoId, parametros = {} }) {
  assertUuidLike(operacaoId, 'operacaoId');

  return callMesaRpc({
    sb,
    token,
    fn: RPCS.obterOperacaoAdmin,
    args: {
      p_operacao_id: operacaoId,
      p_parametros: sanitizeParametrosLeitura(parametros),
    },
  });
}

export function resumirOperacaoFinanceiraAdmin({ sb, token, operacaoId, parametros = {} }) {
  assertUuidLike(operacaoId, 'operacaoId');

  return callMesaRpc({
    sb,
    token,
    fn: RPCS.resumirOperacaoAdmin,
    args: {
      p_operacao_id: operacaoId,
      p_parametros: sanitizeParametrosLeitura(parametros),
    },
  });
}

export function obterResumoOperacaoClienteSafe({ sb, token, operacaoId, parametros = {} }) {
  assertUuidLike(operacaoId, 'operacaoId');

  return callMesaRpc({
    sb,
    token,
    fn: RPCS.obterResumoClienteSafe,
    args: {
      p_operacao_id: operacaoId,
      p_parametros: sanitizeParametrosLeitura(parametros),
    },
  });
}

export function aplicarOperacaoFinanceiraAdmin({ sb, token, operacaoId, parametros = {} }) {
  assertUuidLike(operacaoId, 'operacaoId');

  return callMesaRpc({
    sb,
    token,
    fn: RPCS.aplicarOperacaoAdmin,
    args: {
      p_operacao_id: operacaoId,
      p_parametros: sanitizeParametrosAplicacaoFinanceira(parametros),
    },
  });
}
