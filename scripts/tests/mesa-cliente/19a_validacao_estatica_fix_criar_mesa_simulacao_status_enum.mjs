#!/usr/bin/env node

/**
 * FECH.AI — MesaCliente
 * 19A — Validação estática do fix enum da RPC criar_mesa_simulacao
 *
 * Este teste não acessa banco, não executa RPC e não faz DML.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { execSync } from 'node:child_process';

const ROOT = process.cwd();
const MIGRATION_PATH = 'supabase/migrations/20260525143000_mesa_cliente_fase_8g_fix_criar_mesa_simulacao_status_enum.sql';
const CONTRACT_PATH = 'docs/mesa-cliente/fase-8g-contrato-fix-rpc-criar-mesa-simulacao-status-enum.md';

const FORBIDDEN_PATH_PATTERNS = [
  /^src\//,
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

  const hasInvalidStatus = migration.includes('aguardando_aprovacao');
  resultados.push(result('05_sem_status_invalido', !hasInvalidStatus ? 'PASS' : 'FAIL', { hasInvalidStatus }));

  const hasEmAnaliseCast = migration.includes("'em_analise'::public.mesa_simulacao_status");
  resultados.push(result('06_em_analise_cast_enum', hasEmAnaliseCast ? 'PASS' : 'FAIL', { hasEmAnaliseCast }));

  const hasRascunhoCast = migration.includes("'rascunho'::public.mesa_simulacao_status");
  resultados.push(result('07_rascunho_cast_enum', hasRascunhoCast ? 'PASS' : 'FAIL', { hasRascunhoCast }));

  const altersEnum = /alter\s+type\s+public\.mesa_simulacao_status\s+add\s+value/i.test(migration)
    || /create\s+type\s+public\.mesa_simulacao_status/i.test(migration);
  resultados.push(result('08_nao_altera_enum', !altersEnum ? 'PASS' : 'FAIL', { altersEnum }));

  const altersTable = /alter\s+table\s+public\./i.test(migration) || /create\s+table\s+public\./i.test(migration) || /drop\s+table\s+public\./i.test(migration);
  resultados.push(result('09_nao_altera_tabelas', !altersTable ? 'PASS' : 'FAIL', { altersTable }));

  const grantsAnon = /grant\s+execute[^;]+to\s+anon/i.test(migration);
  resultados.push(result('10_nao_concede_anon', !grantsAnon ? 'PASS' : 'FAIL', { grantsAnon }));

  const destructiveDml = /\b(update|delete)\s+public\./i.test(migration) || /\binsert\s+into\s+public\.(?!mesa_simulacoes|mesa_fluxo_pagamentos|audit_logs)/i.test(migration);
  resultados.push(result('11_sem_dml_corretivo_fora_da_funcao', !destructiveDml ? 'PASS' : 'FAIL', { destructiveDml }));
}

const changedFilesInfo = getChangedFilesFromGit();
const changedFiles = changedFilesInfo.files;
const forbiddenFiles = changedFiles.filter((file) => FORBIDDEN_PATH_PATTERNS.some((pattern) => pattern.test(file)));

resultados.push(result('12_escopo_preservado', forbiddenFiles.length === 0 ? 'PASS' : 'FAIL', {
  changed_files: changedFiles,
  diff_range: changedFilesInfo.range,
  diff_warning: changedFilesInfo.warning,
  forbidden_files: forbiddenFiles,
  frontend_alterado: forbiddenFiles.some((file) => file.startsWith('src/')),
  worker_make_n8n_parser_alterado: forbiddenFiles.some((file) => !file.startsWith('src/')),
}));

const failCount = resultados.filter((item) => item.status === 'FAIL').length;
resultados.push(result('99_readiness_19a_fix_status_enum', failCount === 0 ? 'PASS' : 'FAIL', {
  fail_count: failCount,
  migration_exists: exists(MIGRATION_PATH),
  status_invalido_removido: migration ? !migration.includes('aguardando_aprovacao') : false,
  enum_casts_presentes: migration ? migration.includes("'em_analise'::public.mesa_simulacao_status") && migration.includes("'rascunho'::public.mesa_simulacao_status") : false,
}));

const output = JSON.stringify(resultados, null, 2);
console.log(output);

const artifactDir = path.join(ROOT, 'artifacts', 'mesa-cliente');
fs.mkdirSync(artifactDir, { recursive: true });
fs.writeFileSync(path.join(artifactDir, '19a_resultado.json'), `${output}\n`, 'utf8');

process.exit(failCount === 0 ? 0 : 1);
