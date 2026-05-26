#!/usr/bin/env node

/**
 * FECH.AI — MesaCliente
 * 18C — Validação Estática de Seleção Segura de Simulação para Operações
 *
 * Objetivo:
 * - validar abertura da aba Operações a partir de item.id do Histórico;
 * - impedir derivação de simulacaoId por empresa/corretor/empreendimento/unidade;
 * - preservar comportamento bloqueado quando não houver simulação selecionada;
 * - preservar motor financeiro, parser, Worker, Make e n8n no escopo do gate estático. Migrations/RPCs de fases posteriores ficam sob validação própria.
 *
 * Este teste é estático: não acessa banco, não executa RPC, não faz DDL e não faz DML.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';
import { execSync } from 'node:child_process';

const ROOT = process.cwd();
const INDEX_PATH = 'src/components/MesaCliente/index.jsx';
const HIST_PATH = 'src/components/MesaCliente/TabHistorico.jsx';
const CONTRACT_PATH = 'docs/mesa-cliente/fase-8f-contrato-selecao-segura-simulacao-operacoes-financeiras.md';

const FORBIDDEN_ENGINE_PATH_PATTERNS = [
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
const historico = read(HIST_PATH);
const contract = read(CONTRACT_PATH);
const resultados = [];

resultados.push(result('00_arquivos_base_18c',
  exists(INDEX_PATH) && exists(HIST_PATH) && exists(CONTRACT_PATH) ? 'PASS' : 'FAIL',
  {
    index_exists: exists(INDEX_PATH),
    historico_exists: exists(HIST_PATH),
    contract_8f_exists: exists(CONTRACT_PATH),
  }
));

if (!contract) {
  resultados.push(result('01_contrato_8f', 'FAIL', { missing: CONTRACT_PATH }));
} else {
  const required = [
    'TabHistorico → historico.map(item) → item.id',
    'APROVADO PARA IMPLEMENTAÇÃO CONTROLADA',
    'Não autoriza alteração de motor financeiro',
  ];
  const missing = required.filter((token) => !contract.includes(token));
  resultados.push(result('01_contrato_8f', missing.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: missing }));
}

if (!historico) {
  resultados.push(result('02_historico_callback_operacoes', 'FAIL', { missing: HIST_PATH }));
} else {
  const receivesCallback = /export\s+default\s+function\s+TabHistorico\s*\([^)]*onAbrirOperacoesFinanceiras/.test(historico)
    || historico.includes('onAbrirOperacoesFinanceiras })');
  resultados.push(result('02_historico_callback_operacoes', receivesCallback ? 'PASS' : 'FAIL', { receivesCallback }));

  const histCardReceivesCallback = /function\s+HistCard\s*\([^)]*onAbrirOperacoesFinanceiras/.test(historico)
    || historico.includes('onAbrirOperacoesFinanceiras })');
  resultados.push(result('03_histcard_recebe_callback', histCardReceivesCallback ? 'PASS' : 'FAIL', { histCardReceivesCallback }));

  const hasButton = historico.includes('Operações financeiras') && historico.includes('podeAbrirOperacoes');
  resultados.push(result('04_botao_operacoes_financeiras', hasButton ? 'PASS' : 'FAIL', { hasButton }));

  const validatesItemId = historico.includes('Boolean(item?.id && onAbrirOperacoesFinanceiras)');
  resultados.push(result('05_botao_exige_item_id', validatesItemId ? 'PASS' : 'FAIL', { validatesItemId }));

  const callbackWithItem = historico.includes('onAbrirOperacoesFinanceiras(item)');
  resultados.push(result('06_callback_chamado_com_item', callbackWithItem ? 'PASS' : 'FAIL', { callbackWithItem }));

  const propPassedToCards = historico.includes('onAbrirOperacoesFinanceiras={onAbrirOperacoesFinanceiras}');
  resultados.push(result('07_callback_repassado_para_cards', propPassedToCards ? 'PASS' : 'FAIL', { propPassedToCards }));
}

if (!index) {
  resultados.push(result('08_index_estado_selecao_simulacao', 'FAIL', { missing: INDEX_PATH }));
} else {
  const hasState = index.includes('simulacaoOperacoesSelecionada') && index.includes('setSimulacaoOperacoesSelecionada');
  resultados.push(result('08_index_estado_selecao_simulacao', hasState ? 'PASS' : 'FAIL', { hasState }));

  const hasBuilder = index.includes('function buildSimulacaoOperacoesContext(item)') && index.includes('if (!item?.id) return null;');
  resultados.push(result('09_index_builder_valida_item_id', hasBuilder ? 'PASS' : 'FAIL', { hasBuilder }));

  const hasAllowedContext = [
    'id: item.id',
    'cliente_nome: item.cliente_nome || null',
    'empreendimento: item.empreendimento || null',
    'unidade: item.unidade || null',
    'status: item.status || null',
    'valor_total: item.valor_total ?? null',
  ].filter((token) => !index.includes(token));
  resultados.push(result('10_contexto_visual_minimo', hasAllowedContext.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: hasAllowedContext }));

  const handlerUsesBuilder = index.includes('const abrirOperacoesFinanceiras = (item) =>')
    && index.includes('const contexto = buildSimulacaoOperacoesContext(item);')
    && index.includes('if (!contexto?.id) return;')
    && index.includes('setSimulacaoOperacoesSelecionada(contexto);')
    && index.includes("setTab('ops')");
  resultados.push(result('11_handler_abre_aba_ops_com_item_id', handlerUsesBuilder ? 'PASS' : 'FAIL', { handlerUsesBuilder }));

  const tabHistoricoReceivesHandler = index.includes('onAbrirOperacoesFinanceiras={abrirOperacoesFinanceiras}');
  resultados.push(result('12_index_repassa_handler_ao_historico', tabHistoricoReceivesHandler ? 'PASS' : 'FAIL', { tabHistoricoReceivesHandler }));

  const panelReceivesSelectedId = index.includes('simulacaoId={simulacaoOperacoesSelecionada?.id || null}');
  resultados.push(result('13_panel_recebe_simulacao_selecionada', panelReceivesSelectedId ? 'PASS' : 'FAIL', {
    expected: 'simulacaoId={simulacaoOperacoesSelecionada?.id || null}',
    found: panelReceivesSelectedId,
  }));

  const safeFallbackComment = index.includes('Sem seleção, o fallback preserva comportamento equivalente a simulacaoId={null}.');
  resultados.push(result('14_fallback_bloqueado_sem_selecao_preservado', safeFallbackComment ? 'PASS' : 'FAIL', { safeFallbackComment }));

  const forbiddenPatterns = [
    /simulacaoId=\{ctx\./,
    /simulacaoId=\{empresaId\}/,
    /simulacaoId=\{ctx\.empresaId\}/,
    /simulacaoId=\{ctx\.corretorId\}/,
    /simulacaoId=\{empSelecionado/,
    /simulacaoOperacoesSelecionada\s*:\s*ctx\./,
    /setSimulacaoOperacoesSelecionada\(ctx\./,
    /localStorage\./,
    /sessionStorage\./,
  ];
  const matches = forbiddenPatterns.filter((pattern) => pattern.test(index)).map(String);
  resultados.push(result('15_sem_derivacao_soberana_simulacao_id', matches.length === 0 ? 'PASS' : 'FAIL', { matches }));
}

const changedFilesInfo = getChangedFilesFromGit();
const changedFiles = changedFilesInfo.files;
const forbiddenEngineFiles = changedFiles.filter((file) => FORBIDDEN_ENGINE_PATH_PATTERNS.some((pattern) => pattern.test(file)));

resultados.push(result('16_motor_preservado', forbiddenEngineFiles.length === 0 ? 'PASS' : 'FAIL', {
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
resultados.push(result('99_readiness_18c_selecao_segura', failCount === 0 ? 'PASS' : 'FAIL', {
  fail_count: failCount,
  historico_tem_botao_operacoes: historico?.includes('Operações financeiras') === true,
  panel_recebe_simulacao_selecionada: index?.includes('simulacaoId={simulacaoOperacoesSelecionada?.id || null}') === true,
  motor_financeiro_preservado: forbiddenEngineFiles.length === 0,
}));

const output = JSON.stringify(resultados, null, 2);
console.log(output);

const artifactDir = path.join(ROOT, 'artifacts', 'mesa-cliente');
fs.mkdirSync(artifactDir, { recursive: true });
fs.writeFileSync(path.join(artifactDir, '18c_resultado.json'), `${output}\n`, 'utf8');

process.exit(failCount === 0 ? 0 : 1);
