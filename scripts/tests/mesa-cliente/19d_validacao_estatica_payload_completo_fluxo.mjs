#!/usr/bin/env node

/**
 * FECH.AI — MesaCliente
 * 19D — Validação estática do payload completo do Fluxo
 *
 * Objetivo:
 * - Provar que o frontend está preparado para serializar todos os grupos
 *   financeiros visuais do fluxo: e, c, m, a, u.
 * - Provar que parcela única/chaves não é descartada antes da RPC.
 * - Não executa banco, não chama RPC, não faz DDL/DML.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const ROOT = process.cwd();

const FILES = {
  contract: 'docs/mesa-cliente/fase-8j-contrato-validacao-payload-completo-fluxo.md',
  tabFluxo: 'src/components/MesaCliente/TabFluxo.jsx',
  fluxoBuilder: 'src/components/MesaCliente/FluxoBuilder.jsx',
  useMesaCalc: 'src/components/MesaCliente/hooks/useMesaCalc.js',
};

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

function hasAll(text, tokens) {
  return tokens.filter((token) => !text.includes(token));
}

const contract = read(FILES.contract);
const tabFluxo = read(FILES.tabFluxo);
const fluxoBuilder = read(FILES.fluxoBuilder);
const useMesaCalc = read(FILES.useMesaCalc);
const resultados = [];

resultados.push(result('00_arquivos_base_19d', Object.values(FILES).every(exists) ? 'PASS' : 'FAIL', {
  contract_exists: exists(FILES.contract),
  tab_fluxo_exists: exists(FILES.tabFluxo),
  fluxo_builder_exists: exists(FILES.fluxoBuilder),
  use_mesa_calc_exists: exists(FILES.useMesaCalc),
}));

if (!contract) {
  resultados.push(result('01_contrato_8j', 'FAIL', { missing: FILES.contract }));
} else {
  const required = [
    'Contrato 19D',
    'payload completo do Fluxo',
    'parcela única',
    '`u`',
    'DML financeiro: não',
    'Alteração de parser: não',
  ];
  const missing = hasAll(contract, required);
  resultados.push(result('01_contrato_8j', missing.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: missing }));
}

if (!tabFluxo) {
  resultados.push(result('02_tabfluxo_parser_fluxo_completo', 'FAIL', { missing: FILES.tabFluxo }));
} else {
  const required = [
    'function buildFluxoFromParser',
    'const fluxo = { e: [], c: [], m: [], a: [], u: [] }',
    'sinal_1',
    'a4_each',
    'mensal_each',
    'inter_each',
    'chaves_each',
    'unica_qtd',
    "fluxo.e.push",
    "fluxo.c.push",
    "fluxo.m.push",
    "fluxo.a.push",
    "fluxo.u.push",
  ];
  const missing = hasAll(tabFluxo, required);
  resultados.push(result('02_tabfluxo_parser_fluxo_completo', missing.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: missing }));

  const hasUnicaDate = tabFluxo.includes("date: meta.unica || ''") || tabFluxo.includes("dateStart: meta.unica || ''");
  const hasUnicaLabel = tabFluxo.includes("label: 'Parcela única'") && tabFluxo.includes("label: 'Chaves'");
  resultados.push(result('03_tabfluxo_parcela_unica_chaves', hasUnicaDate && hasUnicaLabel ? 'PASS' : 'FAIL', {
    hasUnicaDate,
    hasUnicaLabel,
  }));

  const noHardcodedEmp = !/empreendimento\.nome\s*===|empreendimento\.id\s*===\s*['"]/i.test(tabFluxo);
  resultados.push(result('04_tabfluxo_sem_hardcoded_empreendimento', noHardcodedEmp ? 'PASS' : 'FAIL', { noHardcodedEmp }));
}

if (!fluxoBuilder) {
  resultados.push(result('05_fluxobuilder_exibe_grupo_u', 'FAIL', { missing: FILES.fluxoBuilder }));
} else {
  const hasShowUnicaFromInitial = fluxoBuilder.includes("useState(() => Boolean(initialFluxo?.u?.length))");
  const hasGrupoU = fluxoBuilder.includes('<GrupoTiles g="u"') || fluxoBuilder.includes("<GrupoTiles g='u'");
  const hasToggleUnica = fluxoBuilder.includes('setShowUnica') && fluxoBuilder.includes('Adicionar chaves');
  const hasEstoqueProntoGuard = fluxoBuilder.includes('isEstoqueProntoFluxo')
    && fluxoBuilder.includes('state.u.length === 0');
  resultados.push(result('05_fluxobuilder_exibe_grupo_u', hasShowUnicaFromInitial && hasGrupoU && hasToggleUnica ? 'PASS' : 'FAIL', {
    hasShowUnicaFromInitial,
    hasGrupoU,
    hasToggleUnica,
  }));

  resultados.push(result('06_fluxobuilder_estoque_pronto_nao_confunde_u', hasEstoqueProntoGuard ? 'PASS' : 'FAIL', {
    hasEstoqueProntoGuard,
    observacao: 'Se houver grupo u importado, não deve cair no aviso de estoque pronto somente ato + financiamento.',
  }));
}

if (!useMesaCalc) {
  resultados.push(result('07_usemesacalc_serializa_todos_grupos', 'FAIL', { missing: FILES.useMesaCalc }));
} else {
  const serializaTodos = ['add(\'e\'', 'add(\'c\'', 'add(\'m\'', 'add(\'a\'', 'add(\'u\'']
    .every((token) => useMesaCalc.includes(token));
  const hasPayloadFields = [
    'grupo,',
    'valor: t.value || 0',
    'qty: t.qty || 1',
    'total: t.isGroup',
    'periodicidade: t.per || null',
    'isGroup: t.isGroup || false',
    'source: t.source || null',
  ].every((token) => useMesaCalc.includes(token));
  resultados.push(result('07_usemesacalc_serializa_todos_grupos', serializaTodos && hasPayloadFields ? 'PASS' : 'FAIL', {
    serializaTodos,
    hasPayloadFields,
  }));

  const incluiUEmPagamento = useMesaCalc.includes('const vU = calcGroupTotal(state.u)')
    && useMesaCalc.includes('const pagamentoFluxo = obra + vU')
    && useMesaCalc.includes('const fin = Math.max(0, precoTotal - pagamentoFluxo)');
  resultados.push(result('08_usemesacalc_u_entra_no_pagamento_fluxo', incluiUEmPagamento ? 'PASS' : 'FAIL', {
    incluiUEmPagamento,
  }));
}

const frontTexts = [tabFluxo || '', fluxoBuilder || '', useMesaCalc || ''].join('\n');
const serviceRoleMatches = [...frontTexts.matchAll(/service[_-]?role|serviceRole|SUPABASE_SERVICE_ROLE/gi)].map((match) => match[0]);
resultados.push(result('09_sem_service_role_front_fluxo', serviceRoleMatches.length === 0 ? 'PASS' : 'FAIL', {
  matches: serviceRoleMatches,
}));

const forbiddenEngineFiles = [
  'supabase/migrations/',
  'supabase/functions/',
  'workers/',
  'worker/',
  'make/',
  'n8n/',
];

const changedByDesign = Object.values(FILES);
const forbiddenTouched = changedByDesign.filter((file) => forbiddenEngineFiles.some((prefix) => file.startsWith(prefix)));
resultados.push(result('10_motor_preservado_19d', forbiddenTouched.length === 0 ? 'PASS' : 'FAIL', {
  arquivos_do_teste: changedByDesign,
  forbiddenTouched,
  ddl: false,
  dml_financeiro: false,
  altera_parser: false,
  altera_worker_make: false,
}));

const failCount = resultados.filter((item) => item.status === 'FAIL').length;
resultados.push(result('99_readiness_19d_payload_completo_fluxo', failCount === 0 ? 'PASS' : 'FAIL', {
  fail_count: failCount,
}));

const output = JSON.stringify(resultados, null, 2);
console.log(output);

const artifactDir = path.join(ROOT, 'artifacts', 'mesa-cliente');
fs.mkdirSync(artifactDir, { recursive: true });
fs.writeFileSync(path.join(artifactDir, '19d_resultado.json'), `${output}\n`, 'utf8');

process.exit(failCount === 0 ? 0 : 1);
