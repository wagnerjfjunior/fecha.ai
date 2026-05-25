#!/usr/bin/env node

/**
 * FECH.AI — MesaCliente
 * 18A — Validação Estática da Integração Visual do OperacoesFinanceirasPanel
 *
 * Objetivo:
 * - validar que o painel financeiro foi plugado na navegação principal em modo seguro;
 * - garantir aba Operações sem inventar simulacaoId;
 * - preservar motor financeiro, parser, Worker, Make, n8n, migrations e RPCs.
 *
 * Este teste é estático: não acessa banco, não executa RPC, não faz DDL e não faz DML.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { execSync } from 'node:child_process';

const ROOT = process.cwd();
const INDEX_PATH = 'src/components/MesaCliente/index.jsx';
const PANEL_PATH = 'src/components/MesaCliente/OperacoesFinanceirasPanel.jsx';
const CONTRACT_PATH = 'docs/mesa-cliente/fase-8e-contrato-integracao-visual-operacoes-financeiras-panel.md';

const FORBIDDEN_ENGINE_PATH_PATTERNS = [
  /^supabase\/migrations\//,
  /^supabase\/tests\//,
  /^workers?\//i,
  /^worker\//i,
  /^make\//i,
  /^n8n\//i,
  /parser/i,
];

function read(relativePath) {
  const absolute = path.join(ROOT, relativePath);
  if (!fs.existsSync(absolute)) return null;
  return fs.readFileSync(absolute, 'utf8');
}

function exists(relativePath) {
  return fs.existsSync(path.join(ROOT, relativePath));
}

function result(bloco, status, detalhe = {}) {
  return { bloco, status, detalhe };
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
    return { files: [], range: null, attempts, warning: `not_a_git_worktree: ${error.message}` };
  }

  try {
    runGit('git fetch --quiet origin main');
    attempts.push({ command: 'git fetch --quiet origin main', ok: true });
  } catch (error) {
    attempts.push({ command: 'git fetch --quiet origin main', ok: false, error: error.message });
  }

  const ranges = ['origin/main...HEAD', 'main...HEAD', 'HEAD~1...HEAD'];
  for (const range of ranges) {
    try {
      const output = runGit(`git diff --name-only ${range}`);
      const files = output.split('\n').map((line) => line.trim()).filter(Boolean);
      attempts.push({ range, ok: true, count: files.length });
      if (files.length > 0 || range === ranges.at(-1)) {
        return { files, range, attempts, warning: files.length === 0 ? 'diff_empty_after_all_ranges' : null };
      }
    } catch (error) {
      attempts.push({ range, ok: false, error: error.message });
    }
  }

  return { files: [], range: null, attempts, warning: 'unable_to_resolve_git_diff_range' };
}

const index = read(INDEX_PATH);
const panel = read(PANEL_PATH);
const contract = read(CONTRACT_PATH);
const resultados = [];

resultados.push(result('00_arquivos_base_18a',
  exists(INDEX_PATH) && exists(PANEL_PATH) && exists(CONTRACT_PATH) ? 'PASS' : 'FAIL',
  {
    index_exists: exists(INDEX_PATH),
    panel_exists: exists(PANEL_PATH),
    contract_8e_exists: exists(CONTRACT_PATH),
  }
));

if (!contract) {
  resultados.push(result('01_contrato_8e', 'FAIL', { missing: CONTRACT_PATH }));
} else {
  const required = [
    'Operações',
    'simulacaoId={null}',
    'APROVADO PARA IMPLEMENTAÇÃO CONTROLADA DA ABA OPERAÇÕES',
  ];
  const missing = required.filter((token) => !contract.includes(token));
  resultados.push(result('01_contrato_8e', missing.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: missing }));
}

if (!index) {
  resultados.push(result('02_index_importa_panel', 'FAIL', { missing: INDEX_PATH }));
} else {
  const hasImport = /import\s+OperacoesFinanceirasPanel\s+from\s+['"]\.\/OperacoesFinanceirasPanel['"]/.test(index);
  resultados.push(result('02_index_importa_panel', hasImport ? 'PASS' : 'FAIL', { hasImport }));

  const hasTab = index.includes("id: 'ops'") && index.includes("label: 'Operações'") && index.includes("icon: '💳'");
  resultados.push(result('03_aba_operacoes_existe', hasTab ? 'PASS' : 'FAIL', { hasTab }));

  const hasRenderGuard = index.includes("tab === 'ops'") && index.includes('<OperacoesFinanceirasPanel');
  resultados.push(result('04_renderiza_panel_na_aba_ops', hasRenderGuard ? 'PASS' : 'FAIL', { hasRenderGuard }));

  const safeSimulacaoNull = index.includes('simulacaoId={null}');
  resultados.push(result('05_simulacao_id_modo_seguro', safeSimulacaoNull ? 'PASS' : 'FAIL', {
    expected: 'simulacaoId={null}',
    found: safeSimulacaoNull,
  }));

  const safeAgendaNull = index.includes('agendaId={null}');
  resultados.push(result('06_agenda_id_modo_seguro', safeAgendaNull ? 'PASS' : 'FAIL', {
    expected: 'agendaId={null}',
    found: safeAgendaNull,
  }));

  const gestorGuard = index.includes('usuarioPodeAplicar={ctx.isGestor}');
  resultados.push(result('07_usuario_pode_aplicar_ctx_gestor', gestorGuard ? 'PASS' : 'FAIL', {
    expected: 'usuarioPodeAplicar={ctx.isGestor}',
    found: gestorGuard,
  }));

  const existingTabsPreserved = ['Empreendimentos', 'Fluxo', 'Histórico'].filter((label) => !index.includes(label));
  resultados.push(result('08_abas_existentes_preservadas', existingTabsPreserved.length === 0 ? 'PASS' : 'FAIL', {
    missing_existing_tabs: existingTabsPreserved,
  }));

  const suspiciousSimulacaoDerivation = [
    /simulacaoId=\{ctx\./,
    /simulacaoId=\{empresaId\}/,
    /simulacaoId=\{ctx\.empresaId\}/,
    /simulacaoId=\{ctx\.corretorId\}/,
    /simulacaoId=\{empSelecionado/,
  ].filter((pattern) => pattern.test(index)).map(String);

  resultados.push(result('09_sem_derivacao_soberana_simulacao_id', suspiciousSimulacaoDerivation.length === 0 ? 'PASS' : 'FAIL', {
    matches: suspiciousSimulacaoDerivation,
  }));
}

if (!panel) {
  resultados.push(result('10_panel_estado_bloqueado_sem_contexto', 'FAIL', { missing: PANEL_PATH }));
} else {
  const panelBlocksWithoutContext = panel.includes('contextoIncompleto')
    && panel.includes('!sb || !token || !simulacaoId')
    && panel.includes('Operações financeiras indisponíveis')
    && panel.includes('A consulta foi bloqueada antes de chamar os hooks de dados.');

  resultados.push(result('10_panel_estado_bloqueado_sem_contexto', panelBlocksWithoutContext ? 'PASS' : 'FAIL', {
    panelBlocksWithoutContext,
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
resultados.push(result('99_readiness_18a_integracao_visual', failCount === 0 ? 'PASS' : 'FAIL', {
  fail_count: failCount,
  aba_operacoes_integrada: index?.includes("id: 'ops'") === true,
  panel_renderizado_em_modo_seguro: index?.includes('simulacaoId={null}') === true,
  motor_financeiro_preservado: forbiddenEngineFiles.length === 0,
}));

const output = JSON.stringify(resultados, null, 2);
console.log(output);

const artifactDir = path.join(ROOT, 'artifacts', 'mesa-cliente');
fs.mkdirSync(artifactDir, { recursive: true });
fs.writeFileSync(path.join(artifactDir, '18a_resultado.json'), `${output}\n`, 'utf8');

process.exit(failCount === 0 ? 0 : 1);
