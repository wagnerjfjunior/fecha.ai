#!/usr/bin/env node

/**
 * FECH.AI — MesaCliente
 * 17C — Validação Estática do OperacoesFinanceirasPanel
 *
 * Objetivo:
 * - validar o contrato visual da Fase 8C antes/depois da implementação do painel;
 * - garantir uso dos hooks aprovados na Fase 8B;
 * - bloquear chamada direta de RPC financeira no componente;
 * - preservar motor financeiro, parser, Worker, Make e n8n no escopo do gate estático. Migrations/RPCs de fases posteriores ficam sob validação própria.
 *
 * Este teste é estático: não acessa banco, não executa RPC, não faz DDL e não faz DML.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { execSync } from 'node:child_process';

const ROOT = process.cwd();

const PANEL_PATH = 'src/components/MesaCliente/OperacoesFinanceirasPanel.jsx';
const CONTRACT_PATH = 'docs/mesa-cliente/fase-8c-contrato-operacoes-financeiras-panel.md';
const HOOKS_PATH = 'src/components/MesaCliente/hooks/useMesaData.js';
const ADAPTER_PATH = 'src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js';

const FORBIDDEN_ENGINE_PATH_PATTERNS = [
  /^workers?\//i,
  /^worker\//i,
  /^make\//i,
  /^n8n\//i,
  /parser/i,
];

const REQUIRED_HOOKS = [
  'useOperacoesFinanceirasAdmin',
  'useOperacaoFinanceiraAdmin',
  'useResumoOperacaoFinanceiraAdmin',
  'useResumoOperacaoClienteSafe',
  'useAplicarOperacaoFinanceiraAdmin',
];

const REQUIRED_HELPERS = [
  'canAplicarOperacaoFinanceira',
];

const REQUIRED_UI_TOKENS = [
  'loading',
  'Nenhuma operação financeira encontrada',
  'erro',
  'Aplicar operação financeira',
  'Você está prestes a aplicar esta operação financeira',
];

const FORBIDDEN_RPC_DIRECT_PATTERNS = [
  /\.rpc\s*\(/,
  /callMesaRpc\s*\(/,
  /mesa_cliente_listar_operacoes_financeiras_admin/,
  /mesa_cliente_obter_operacao_financeira_admin/,
  /mesa_cliente_resumir_operacao_financeira_admin/,
  /mesa_cliente_obter_resumo_operacao_cliente_safe/,
  /mesa_cliente_aplicar_operacao_financeira_admin/,
];

const FORBIDDEN_FRONT_AUTHORITY_KEYS = [
  'tenant_id',
  'empresa_id',
  'role',
  'perfil',
  'status_operacao',
  'valor_movido',
  'taxa_ano_pct',
  'vpl_aplicado_pct',
  'confirmado',
  'visivel_cliente',
  'metadata',
];

const CLIENT_SAFE_FORBIDDEN_TERMS = [
  'vpl_interno',
  'premio_corretor_pct',
  'comissao',
  'score_politica',
  'regra_aprovacao_interna',
  'auditoria_bruta',
  'metadata_bruta',
];

function readFileIfExists(relativePath) {
  const absolutePath = path.join(ROOT, relativePath);
  if (!fs.existsSync(absolutePath)) return null;
  return fs.readFileSync(absolutePath, 'utf8');
}

function exists(relativePath) {
  return fs.existsSync(path.join(ROOT, relativePath));
}

function result(bloco, status, detalhe = {}) {
  return { bloco, status, detalhe };
}

function hasAny(content, tokens) {
  return tokens.filter((token) => !content.includes(token));
}

function regexMatches(content, patterns) {
  return patterns
    .filter((pattern) => pattern.test(content))
    .map((pattern) => String(pattern));
}

function runGit(command) {
  return execSync(command, {
    cwd: ROOT,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  }).trim();
}

function getChangedFilesFromGit() {
  const attempts = [];

  try {
    runGit('git rev-parse --is-inside-work-tree');
  } catch (error) {
    return {
      files: [],
      range: null,
      attempts,
      warning: `not_a_git_worktree: ${error.message}`,
    };
  }

  try {
    runGit('git fetch --quiet origin main');
    attempts.push({ command: 'git fetch --quiet origin main', ok: true });
  } catch (error) {
    attempts.push({ command: 'git fetch --quiet origin main', ok: false, error: error.message });
  }

  const candidateRanges = [
    'origin/main...HEAD',
    'main...HEAD',
    'HEAD~1...HEAD',
  ];

  for (const range of candidateRanges) {
    try {
      const output = runGit(`git diff --name-only ${range}`);
      const files = output.split('\n').map((line) => line.trim()).filter(Boolean);
      attempts.push({ range, ok: true, count: files.length });

      if (files.length > 0 || range === candidateRanges.at(-1)) {
        return {
          files,
          range,
          attempts,
          warning: files.length === 0 ? 'diff_empty_after_all_ranges' : null,
        };
      }
    } catch (error) {
      attempts.push({ range, ok: false, error: error.message });
    }
  }

  return {
    files: [],
    range: null,
    attempts,
    warning: 'unable_to_resolve_git_diff_range',
  };
}

const resultados = [];

const panel = readFileIfExists(PANEL_PATH);
const contract = readFileIfExists(CONTRACT_PATH);
const hooks = readFileIfExists(HOOKS_PATH);
const adapter = readFileIfExists(ADAPTER_PATH);

resultados.push(result('00_arquivos_base_8c',
  exists(CONTRACT_PATH) && exists(HOOKS_PATH) && exists(ADAPTER_PATH) ? 'PASS' : 'FAIL',
  {
    contract_exists: exists(CONTRACT_PATH),
    hooks_exists: exists(HOOKS_PATH),
    adapter_exists: exists(ADAPTER_PATH),
    panel_exists: exists(PANEL_PATH),
    observacao: exists(PANEL_PATH)
      ? 'Painel encontrado.'
      : 'Painel ainda não encontrado. Esperado antes da implementação; deve virar PASS após criar a UI 8C.',
  }));

if (!contract) {
  resultados.push(result('01_contrato_8c', 'FAIL', { missing: CONTRACT_PATH }));
} else {
  const missingContractTokens = hasAny(contract, [
    'OperacoesFinanceirasPanel.jsx',
    'useOperacoesFinanceirasAdmin',
    'useAplicarOperacaoFinanceiraAdmin',
    'canAplicarOperacaoFinanceira',
    'Não autoriza alteração do motor financeiro',
    'AGUARDANDO APROVAÇÃO DO USUÁRIO PARA INICIAR CÓDIGO DA 8C',
  ]);
  resultados.push(result('01_contrato_8c', missingContractTokens.length === 0 ? 'PASS' : 'FAIL', {
    missing_tokens: missingContractTokens,
  }));
}

if (!hooks) {
  resultados.push(result('02_hooks_8b_disponiveis', 'FAIL', { missing: HOOKS_PATH }));
} else {
  const missingHooks = hasAny(hooks, REQUIRED_HOOKS);
  resultados.push(result('02_hooks_8b_disponiveis', missingHooks.length === 0 ? 'PASS' : 'FAIL', {
    missing_hooks: missingHooks,
  }));
}

if (!adapter) {
  resultados.push(result('03_adapter_8b_disponivel', 'FAIL', { missing: ADAPTER_PATH }));
} else {
  const missingHelpers = hasAny(adapter, [...REQUIRED_HELPERS, 'sanitizeParametrosAplicacaoFinanceira']);
  resultados.push(result('03_adapter_8b_disponivel', missingHelpers.length === 0 ? 'PASS' : 'FAIL', {
    missing_helpers: missingHelpers,
  }));
}

if (!panel) {
  resultados.push(result('04_panel_existe', 'FAIL', {
    expected_file: PANEL_PATH,
    motivo: 'O componente visual da Fase 8C ainda não foi criado.',
  }));
} else {
  resultados.push(result('04_panel_existe', 'PASS', { file: PANEL_PATH }));

  const missingPanelHooks = REQUIRED_HOOKS.filter((hookName) => !panel.includes(hookName));
  resultados.push(result('05_panel_usa_hooks_aprovados', missingPanelHooks.length === 0 ? 'PASS' : 'FAIL', {
    missing_hooks_in_panel: missingPanelHooks,
  }));

  const missingGating = REQUIRED_HELPERS.filter((helperName) => !panel.includes(helperName));
  resultados.push(result('06_gating_aplicacao', missingGating.length === 0 ? 'PASS' : 'FAIL', {
    missing_helpers_in_panel: missingGating,
  }));

  const directRpcMatches = regexMatches(panel, FORBIDDEN_RPC_DIRECT_PATTERNS);
  resultados.push(result('07_sem_rpc_direta_no_panel', directRpcMatches.length === 0 ? 'PASS' : 'FAIL', {
    matches: directRpcMatches,
  }));

  const missingUiTokens = hasAny(panel, REQUIRED_UI_TOKENS);
  resultados.push(result('08_estados_ui_minimos', missingUiTokens.length === 0 ? 'PASS' : 'FAIL', {
    missing_tokens: missingUiTokens,
  }));

  const frontendAuthorityMatches = FORBIDDEN_FRONT_AUTHORITY_KEYS.filter((key) => {
    const propPattern = new RegExp(`\\b${key}\\s*=`, 'i');
    return propPattern.test(panel);
  });
  resultados.push(result('09_sem_props_soberanas', frontendAuthorityMatches.length === 0 ? 'PASS' : 'FAIL', {
    matches: frontendAuthorityMatches,
  }));

  const clientSafeForbiddenMatches = CLIENT_SAFE_FORBIDDEN_TERMS.filter((term) => panel.includes(term));
  resultados.push(result('10_cliente_safe_sem_termos_sensiveis', clientSafeForbiddenMatches.length === 0 ? 'PASS' : 'FAIL', {
    matches: clientSafeForbiddenMatches,
  }));
}

const changedFilesInfo = getChangedFilesFromGit();
const changedFiles = changedFilesInfo.files;
const forbiddenEngineFiles = changedFiles.filter((file) => FORBIDDEN_ENGINE_PATH_PATTERNS.some((pattern) => pattern.test(file)));
resultados.push(result('11_motor_preservado', forbiddenEngineFiles.length === 0 ? 'PASS' : 'FAIL', {
  changed_files: changedFiles,
  diff_range: changedFilesInfo.range,
  diff_warning: changedFilesInfo.warning,
  diff_attempts: changedFilesInfo.attempts,
  forbidden_engine_files: forbiddenEngineFiles,
  ddl: false,
  dml: false,
  banco_alterado: false,
}));

const failCount = resultados.filter((item) => item.status === 'FAIL').length;
const panelExists = exists(PANEL_PATH);

resultados.push(result('99_readiness_8c_ui', failCount === 0 ? 'PASS' : 'FAIL', {
  fail_count: failCount,
  panel_exists: panelExists,
  contrato_8c_existe: exists(CONTRACT_PATH),
  motor_financeiro_preservado: forbiddenEngineFiles.length === 0,
  observacao: failCount === 0
    ? 'Painel 8C atende aos gates estáticos mínimos.'
    : 'Ainda há pendências estáticas antes de considerar a UI 8C pronta.',
}));

const output = JSON.stringify(resultados, null, 2);
console.log(output);

const artifactDir = path.join(ROOT, 'artifacts', 'mesa-cliente');
fs.mkdirSync(artifactDir, { recursive: true });
fs.writeFileSync(path.join(artifactDir, '17c_resultado.json'), `${output}\n`, 'utf8');

process.exit(failCount === 0 ? 0 : 1);
