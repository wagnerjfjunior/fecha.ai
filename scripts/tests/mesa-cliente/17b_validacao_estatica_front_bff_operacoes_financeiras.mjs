#!/usr/bin/env node

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { execSync } from 'node:child_process';

const ROOT = process.cwd();

const PATHS = Object.freeze({
  adapter: 'src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js',
  hooks: 'src/components/MesaCliente/hooks/useMesaData.js',
  doc8b: 'docs/mesa-cliente/fase-8b-adapter-front-operacoes-financeiras.md',
});

const EXPECTED_RPC_NAMES = [
  'mesa_cliente_listar_operacoes_financeiras_admin',
  'mesa_cliente_obter_operacao_financeira_admin',
  'mesa_cliente_resumir_operacao_financeira_admin',
  'mesa_cliente_obter_resumo_operacao_cliente_safe',
  'mesa_cliente_aplicar_operacao_financeira_admin',
];

const EXPECTED_HOOKS = [
  'useOperacoesFinanceirasAdmin',
  'useOperacaoFinanceiraAdmin',
  'useResumoOperacaoFinanceiraAdmin',
  'useResumoOperacaoClienteSafe',
  'useAplicarOperacaoFinanceiraAdmin',
];

const EXPECTED_AUTHORITY_KEYS = [
  'empresa_id',
  'tenant_id',
  'simulacao_id',
  'agenda_id',
  'empreendimento_id',
  'politica_id',
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
  'visivel_cliente',
  'checksum_operacao',
  'metadata',
  'created_at',
  'updated_at',
  'criado_por',
];

const FORBIDDEN_FRONT_SECRET_PATTERNS = [
  /service[_-]?role/i,
  /SUPABASE_SERVICE_ROLE/i,
  /serviceRole/i,
];

const FORBIDDEN_ANON_KEY_PATTERNS = [
  /anon[_-]?key/i,
  /VITE_SUPABASE_ANON_KEY/i,
  /eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}/,
];

const FORBIDDEN_ENGINE_PATH_PREFIXES = [
  'supabase/migrations/',
  'supabase/tests/',
  'workers/',
  'worker/',
  'cloudflare/',
  'make/',
  'n8n/',
];

const ALLOWED_PHASE_8B_PATHS = new Set([
  PATHS.adapter,
  PATHS.hooks,
  PATHS.doc8b,
  'docs/mesa-cliente/fase-8a-preflight-integracao-front-bff-operacoes-financeiras.md',
  'scripts/tests/mesa-cliente/17b_validacao_estatica_front_bff_operacoes_financeiras.mjs',
]);

function fullPath(relativePath) {
  return path.join(ROOT, relativePath);
}

function exists(relativePath) {
  return fs.existsSync(fullPath(relativePath));
}

function read(relativePath) {
  return fs.readFileSync(fullPath(relativePath), 'utf8');
}

function listFilesRecursive(relativeDir) {
  const base = fullPath(relativeDir);
  if (!fs.existsSync(base)) return [];

  const out = [];
  const stack = [base];
  const ignored = new Set(['node_modules', '.git', 'dist', 'build', '.next', 'coverage']);

  while (stack.length) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true });

    for (const entry of entries) {
      if (ignored.has(entry.name)) continue;
      const entryPath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(entryPath);
        continue;
      }
      if (entry.isFile()) {
        out.push(path.relative(ROOT, entryPath).split(path.sep).join('/'));
      }
    }
  }

  return out;
}

function getChangedFiles() {
  const commands = [
    'git diff --name-only origin/main...HEAD',
    'git diff --name-only main...HEAD',
  ];

  for (const command of commands) {
    try {
      const result = execSync(command, { cwd: ROOT, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] })
        .split('\n')
        .map((item) => item.trim())
        .filter(Boolean);

      if (result.length > 0) {
        return { ok: true, command, files: result };
      }
    } catch {
      // fallback para o próximo comando
    }
  }

  return { ok: false, command: null, files: [] };
}

function statusFrom(condition) {
  return condition ? 'PASS' : 'FAIL';
}

function block(bloco, condition, detalhe) {
  return {
    bloco,
    status: statusFrom(condition),
    detalhe,
  };
}

function info(bloco, detalhe) {
  return {
    bloco,
    status: 'INFO',
    detalhe,
  };
}

function containsEvery(content, tokens) {
  return tokens.map((token) => ({ token, presente: content.includes(token) }));
}

function hasAnyPattern(content, patterns) {
  return patterns.some((pattern) => pattern.test(content));
}

function inspectFilesForPatterns(files, patterns) {
  const matches = [];

  for (const file of files) {
    let content = '';
    try {
      content = read(file);
    } catch {
      continue;
    }

    for (const pattern of patterns) {
      if (pattern.test(content)) {
        matches.push({ file, pattern: pattern.toString() });
      }
    }
  }

  return matches;
}

const resultados = [];

const requiredFiles = Object.entries(PATHS).map(([key, relativePath]) => ({
  key,
  path: relativePath,
  existe: exists(relativePath),
}));

resultados.push(block(
  '00_arquivos_fase_8b',
  requiredFiles.every((item) => item.existe),
  requiredFiles,
));

const adapter = exists(PATHS.adapter) ? read(PATHS.adapter) : '';
const hooks = exists(PATHS.hooks) ? read(PATHS.hooks) : '';
const doc8b = exists(PATHS.doc8b) ? read(PATHS.doc8b) : '';

const rpcChecks = containsEvery(adapter, EXPECTED_RPC_NAMES);
resultados.push(block(
  '01_rpc_names_contrato',
  rpcChecks.every((item) => item.presente),
  rpcChecks,
));

const hookChecks = containsEvery(hooks, EXPECTED_HOOKS);
resultados.push(block(
  '02_hooks_expostos',
  hookChecks.every((item) => item.presente),
  hookChecks,
));

const authorityChecks = containsEvery(adapter, EXPECTED_AUTHORITY_KEYS);
resultados.push(block(
  '03_bloqueio_authority_frontend',
  adapter.includes('FRONTEND_AUTHORITY_KEYS')
    && adapter.includes('sanitizeParametrosAplicacaoFinanceira')
    && authorityChecks.every((item) => item.presente),
  {
    set_presente: adapter.includes('FRONTEND_AUTHORITY_KEYS'),
    sanitizer_presente: adapter.includes('sanitizeParametrosAplicacaoFinanceira'),
    authority_keys: authorityChecks,
  },
));

const payloadAplicacaoChecks = {
  usa_sanitizer_na_rpc: adapter.includes('p_parametros: sanitizeParametrosAplicacaoFinanceira(parametros)'),
  nao_envia_parametros_cru: !adapter.includes('p_parametros: parametros'),
  origem_front_presente: adapter.includes("origem_front: 'mesa_cliente_fase_8'"),
  correlation_id_presente: adapter.includes('correlation_id'),
  metadata_front_presente: adapter.includes('metadata_front'),
};

resultados.push(block(
  '04_payload_aplicacao_sanitizado',
  Object.values(payloadAplicacaoChecks).every(Boolean),
  payloadAplicacaoChecks,
));

const srcFiles = listFilesRecursive('src')
  .filter((file) => /\.(js|jsx|ts|tsx|mjs|cjs)$/.test(file));
const serviceRoleMatches = inspectFilesForPatterns(srcFiles, FORBIDDEN_FRONT_SECRET_PATTERNS);
resultados.push(block(
  '05_sem_service_role_front',
  serviceRoleMatches.length === 0,
  {
    arquivos_varridos: srcFiles.length,
    matches: serviceRoleMatches,
  },
));

const phase8bFiles = [PATHS.adapter, PATHS.hooks].filter(exists);
const anonKeyMatchesPhase8b = inspectFilesForPatterns(phase8bFiles, FORBIDDEN_ANON_KEY_PATTERNS);
resultados.push(block(
  '06_sem_anon_key_nova_fase_8b',
  anonKeyMatchesPhase8b.length === 0,
  {
    criterio: 'valida que a Fase 8B não introduziu anon_key/JWT hardcoded nos arquivos novos/alterados do adapter e hooks',
    arquivos_varridos: phase8bFiles,
    matches: anonKeyMatchesPhase8b,
  },
));

const statusAplicadaChecks = {
  status_canonico_aplicada: adapter.includes("'aplicada'") && adapter.includes('STATUS_OPERACAO_CANONICOS'),
  filtro_5d_separado: adapter.includes('STATUS_OPERACAO_FILTRO_5D'),
  aplicada_client_side: adapter.includes("status === 'aplicada'") && adapter.includes('clientSideStatusOperacao'),
  filtro_local_presente: adapter.includes('filter((item) => item?.status_operacao === clientSideStatusOperacao)'),
};

resultados.push(block(
  '07_status_aplicada_compat_5d',
  Object.values(statusAplicadaChecks).every(Boolean),
  statusAplicadaChecks,
));

const cacheChecks = {
  mutation_presente: hooks.includes('useAplicarOperacaoFinanceiraAdmin'),
  invalida_operacoes_financeiras: hooks.includes("['mesa', 'operacoes-financeiras']"),
  invalida_operacao: hooks.includes('MESA_KEYS.operacaoFinanceira(variables.operacaoId)'),
  invalida_resumo_admin: hooks.includes('MESA_KEYS.resumoOperacaoFinanceiraAdmin(variables.operacaoId)'),
  invalida_resumo_cliente_safe: hooks.includes('MESA_KEYS.resumoOperacaoClienteSafe(variables.operacaoId)'),
  invalida_root: hooks.includes('MESA_KEYS.root'),
};

resultados.push(block(
  '08_cache_invalidation_aplicacao',
  Object.values(cacheChecks).every(Boolean),
  cacheChecks,
));

const changed = getChangedFiles();
const forbiddenChangedFiles = changed.files.filter((file) => FORBIDDEN_ENGINE_PATH_PREFIXES.some((prefix) => file.startsWith(prefix)));
const unexpectedChangedFiles = changed.files.filter((file) => !ALLOWED_PHASE_8B_PATHS.has(file));

resultados.push({
  bloco: '09_motor_preservado',
  status: changed.ok && forbiddenChangedFiles.length === 0 ? 'PASS' : 'FAIL',
  detalhe: {
    diff_disponivel: changed.ok,
    comando: changed.command,
    changed_files: changed.files,
    forbidden_engine_files: forbiddenChangedFiles,
    unexpected_changed_files: unexpectedChangedFiles,
    observacao: 'unexpected_changed_files é informativo; o bloqueio real deste teste é alteração em migrations/tests/worker/make/n8n.',
  },
});

const docChecks = {
  doc_8b_existe: Boolean(doc8b),
  cita_17b: doc8b.includes('17B'),
  cita_sem_engine: doc8b.includes('Sem alteração de engine') || doc8b.includes('Não foram alterados'),
  cita_hooks: EXPECTED_HOOKS.every((hook) => doc8b.includes(hook)),
};

resultados.push(block(
  '10_documentacao_8b_alinhada',
  Object.values(docChecks).every(Boolean),
  docChecks,
));

const failCount = resultados.filter((item) => item.status === 'FAIL').length;

resultados.push({
  bloco: '99_readiness_8c',
  status: failCount === 0 ? 'PASS' : 'FAIL',
  detalhe: {
    fase: '8B_ADAPTER_FRONT_BFF_OPERACOES_FINANCEIRAS',
    proxima_fase: '8C_OPERACOES_FINANCEIRAS_PANEL_UI',
    fail_count: failCount,
    ddl: false,
    dml: false,
    banco_alterado: false,
    motor_financeiro_preservado: failCount === 0,
  },
});

console.log(JSON.stringify(resultados, null, 2));

if (failCount > 0) {
  process.exitCode = 1;
}
