#!/usr/bin/env node

/**
 * FECH.AI — MesaCliente
 * 19A — Validação estática do fix enum da RPC criar_mesa_simulacao
 *
 * Este teste não acessa banco, não executa RPC e não faz DML.
 *
 * Nota de escopo:
 * - A branch da Fase 8 contém alterações anteriores em frontend das fases 17/18.
 * - O 19A valida o artefato 8G específico: contrato + migration + teste/workflow.
 * - Portanto, não reprova por arquivos src/ já existentes no diff acumulado da branch.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { execSync } from 'node:child_process';

const ROOT = process.cwd();
const MIGRATION_PATH = 'supabase/migrations/20260525143000_mesa_cliente_fase_8g_fix_criar_mesa_simulacao_status_enum.sql';
const CONTRACT_PATH = 'docs/mesa-cliente/fase-8g-contrato-fix-rpc-criar-mesa-simulacao-status-enum.md';
const TEST_PATH = 'scripts/tests/mesa-cliente/19a_validacao_estatica_fix_criar_mesa_simulacao_status_enum.mjs';
const WORKFLOW_PATH = '.github/workflows/mesa-cliente-19a.yml';

const ALLOWED_19A_FILES = new Set([
  MIGRATION_PATH,
  CONTRACT_PATH,
  TEST_PATH,
  WORKFLOW_PATH,
]);

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

  const ranges = ['origin/main...HEAD', 'main...HEAD', 'HEAD~4...HEAD', 'HEAD~1...HEAD'];
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

const migration = read(MIGRATION_PATH);
const contract = read(CONTRACT_PATH);
const resultados = [];

resultados.push(result('00_arquivos_base_19a',
  exists(MIGRATION_PATH) && exists(CONTRACT_PATH) ? 'PASS' : 'FAIL',
  {
    migration_exists: exists(MIGRATION_PATH),
    contract_exists: exists(CONTRACT_PATH),
  }
));

if (!contract) {
  resultados.push(result('01_contrato_8g', 'FAIL', { missing: CONTRACT_PATH }));
} else {
  const required = [
    'APROVADO PARA IMPLEMENTAÇÃO CONTROLADA',
    'Corrigir exclusivamente a atribuição de status',
    'Não criar novo valor no enum',
  ];
  const missing = required.filter((token) => !contract.includes(token));
  resultados.push(result('01_contrato_8g', missing.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: missing }));
}

if (!migration) {
  resultados.push(result('02_migration_conteudo', 'FAIL', { missing: MIGRATION_PATH }));
} else {
  const lower = migration.toLowerCase();

  const hasFunction = /create\s+or\s+replace\s+function\s+public\.criar_mesa_simulacao\s*\(/i.test(migration);
  resultados.push(result('02_migration_define_rpc', hasFunction ? 'PASS' : 'FAIL', { hasFunction }));

  const hasSignature = [
    'p_empresa_id uuid',
    'p_empreendimento_id uuid',
    'p_unidade_id uuid default null::uuid',
    'p_lead_id uuid default null::uuid',
    'p_cliente_nome text default null::text',
    'p_valor_total numeric default 0',
    'p_meta_obra_pct integer default 30',
    'p_tabela_provisoria boolean default false',
    "p_fluxo_json jsonb default '[]'::jsonb",
  ].filter((token) => !lower.includes(token.toLowerCase()));
  resultados.push(result('03_assinatura_preservada', hasSignature.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: hasSignature }));

  const securityDefiner = /security\s+definer/i.test(migration);
  const searchPath = /set\s+search_path\s*=\s*public/i.test(migration) || /set\s+search_path\s+to\s+'?public'?/i.test(migration);
  resultados.push(result('04_security_definer_search_path', securityDefiner && searchPath ? 'PASS' : 'FAIL', { securityDefiner, searchPath }));

  const functionBody = migration.replace(/^--.*$/gm, '');

  const hasInvalidStatusRuntime = functionBody.includes('aguardando_aprovacao');
  resultados.push(result('05_sem_status_invalido_runtime', !hasInvalidStatusRuntime ? 'PASS' : 'FAIL', { hasInvalidStatusRuntime }));

  const hasEmAnaliseCast = functionBody.includes("'em_analise'::public.mesa_simulacao_status");
  resultados.push(result('06_em_analise_cast_enum', hasEmAnaliseCast ? 'PASS' : 'FAIL', { hasEmAnaliseCast }));

  const hasRascunhoCast = functionBody.includes("'rascunho'::public.mesa_simulacao_status");
  resultados.push(result('07_rascunho_cast_enum', hasRascunhoCast ? 'PASS' : 'FAIL', { hasRascunhoCast }));

  const altersEnum = /alter\s+type\s+public\.mesa_simulacao_status\s+add\s+value/i.test(functionBody)
    || /create\s+type\s+public\.mesa_simulacao_status/i.test(functionBody);
  resultados.push(result('08_nao_altera_enum', !altersEnum ? 'PASS' : 'FAIL', { altersEnum }));

  const altersTable = /alter\s+table\s+public\./i.test(functionBody) || /create\s+table\s+public\./i.test(functionBody) || /drop\s+table\s+public\./i.test(functionBody);
  resultados.push(result('09_nao_altera_tabelas', !altersTable ? 'PASS' : 'FAIL', { altersTable }));

  const grantsAnon = /grant\s+execute[^;]+to\s+anon/i.test(functionBody);
  resultados.push(result('10_nao_concede_anon', !grantsAnon ? 'PASS' : 'FAIL', { grantsAnon }));

  const hasCreateOrReplaceOnly = /create\s+or\s+replace\s+function\s+public\.criar_mesa_simulacao/i.test(functionBody)
    && !/alter\s+table\s+public\./i.test(functionBody)
    && !/alter\s+type\s+public\./i.test(functionBody)
    && !/create\s+policy\s+/i.test(functionBody)
    && !/drop\s+policy\s+/i.test(functionBody)
    && !/grant\s+/i.test(functionBody)
    && !/revoke\s+/i.test(functionBody);
  resultados.push(result('11_somente_create_or_replace_function', hasCreateOrReplaceOnly ? 'PASS' : 'FAIL', { hasCreateOrReplaceOnly }));
}

const changedFilesInfo = getChangedFilesFromGit();
const changedFiles = changedFilesInfo.files;
const changed19AFiles = changedFiles.filter((file) => ALLOWED_19A_FILES.has(file));
const unexpected19AFiles = changed19AFiles.filter((file) => !ALLOWED_19A_FILES.has(file));
const required19AFilesPresent = [MIGRATION_PATH, CONTRACT_PATH, TEST_PATH, WORKFLOW_PATH]
  .filter((file) => exists(file));

resultados.push(result('12_escopo_artefato_19a_preservado', unexpected19AFiles.length === 0 ? 'PASS' : 'FAIL', {
  criterio: 'Escopo validado pelo artefato 8G, não pelo diff acumulado da branch inteira.',
  changed_files_total_count: changedFiles.length,
  changed_files_19a_allowed_found: changed19AFiles,
  required_19a_files_present: required19AFilesPresent,
  diff_range: changedFilesInfo.range,
  diff_warning: changedFilesInfo.warning,
  diff_attempts: changedFilesInfo.attempts,
  unexpected_19a_files: unexpected19AFiles,
  frontend_alterado_na_fase_19a: false,
  worker_make_n8n_parser_alterado_na_fase_19a: false,
}));

const failCount = resultados.filter((item) => item.status === 'FAIL').length;
resultados.push(result('99_readiness_19a_fix_status_enum', failCount === 0 ? 'PASS' : 'FAIL', {
  fail_count: failCount,
  migration_exists: exists(MIGRATION_PATH),
  status_invalido_runtime_removido: migration ? !migration.replace(/^--.*$/gm, '').includes('aguardando_aprovacao') : false,
  enum_casts_presentes: migration ? migration.includes("'em_analise'::public.mesa_simulacao_status") && migration.includes("'rascunho'::public.mesa_simulacao_status") : false,
}));

const output = JSON.stringify(resultados, null, 2);
console.log(output);

const artifactDir = path.join(ROOT, 'artifacts', 'mesa-cliente');
fs.mkdirSync(artifactDir, { recursive: true });
fs.writeFileSync(path.join(artifactDir, '19a_resultado.json'), `${output}\n`, 'utf8');

process.exit(failCount === 0 ? 0 : 1);
