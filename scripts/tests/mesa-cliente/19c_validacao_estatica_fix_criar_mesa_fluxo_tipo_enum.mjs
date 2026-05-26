#!/usr/bin/env node

/**
 * FECH.AI — MesaCliente
 * 19C — Validação estática do fix mesa_fluxo_tipo da RPC criar_mesa_simulacao
 *
 * Não acessa banco, não executa RPC e não faz DML.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const ROOT = process.cwd();
const MIGRATION_PATH = 'supabase/migrations/20260525161000_mesa_cliente_fase_8i_fix_criar_mesa_fluxo_tipo_enum.sql';
const CONTRACT_PATH = 'docs/mesa-cliente/fase-8i-contrato-fix-rpc-criar-mesa-fluxo-tipo-enum.md';

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

const migration = read(MIGRATION_PATH);
const contract = read(CONTRACT_PATH);
const resultados = [];

resultados.push(result('00_arquivos_base_19c', exists(MIGRATION_PATH) && exists(CONTRACT_PATH) ? 'PASS' : 'FAIL', {
  migration_exists: exists(MIGRATION_PATH),
  contract_exists: exists(CONTRACT_PATH),
}));

if (!contract) {
  resultados.push(result('01_contrato_8i', 'FAIL', { missing: CONTRACT_PATH }));
} else {
  const required = [
    'APROVADO PARA IMPLEMENTAÇÃO CONTROLADA',
    'public.mesa_fluxo_tipo',
    "when 'u' then 'quitacao'::mesa_fluxo_tipo",
  ];
  const missing = required.filter((token) => !contract.includes(token));
  resultados.push(result('01_contrato_8i', missing.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: missing }));
}

if (!migration) {
  resultados.push(result('02_migration_conteudo', 'FAIL', { missing: MIGRATION_PATH }));
} else {
  const functionBody = migration.replace(/^--.*$/gm, '');
  const lower = functionBody.toLowerCase();

  const hasFunction = /create\s+or\s+replace\s+function\s+public\.criar_mesa_simulacao\s*\(/i.test(functionBody);
  resultados.push(result('02_define_rpc', hasFunction ? 'PASS' : 'FAIL', { hasFunction }));

  const signatureMissing = [
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
  resultados.push(result('03_assinatura_preservada', signatureMissing.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: signatureMissing }));

  const securityDefiner = /security\s+definer/i.test(functionBody);
  const searchPath = /set\s+search_path\s*=\s*public/i.test(functionBody) || /set\s+search_path\s+to\s+'?public'?/i.test(functionBody);
  resultados.push(result('04_security_definer_search_path', securityDefiner && searchPath ? 'PASS' : 'FAIL', { securityDefiner, searchPath }));

  const noUnica = !functionBody.includes("'unica'::mesa_fluxo_tipo") && !functionBody.includes("'unica'::public.mesa_fluxo_tipo");
  resultados.push(result('05_sem_unica_invalida', noUnica ? 'PASS' : 'FAIL', { noUnica }));

  const mapping = {
    entrada: functionBody.includes("when 'e' then 'entrada'::mesa_fluxo_tipo"),
    curto_prazo: functionBody.includes("when 'c' then 'curto_prazo'::mesa_fluxo_tipo"),
    periodica: functionBody.includes("when 'm' then 'periodica'::mesa_fluxo_tipo"),
    intermediaria: functionBody.includes("when 'a' then 'intermediaria'::mesa_fluxo_tipo"),
    quitacao: functionBody.includes("when 'u' then 'quitacao'::mesa_fluxo_tipo"),
    financiamento: functionBody.includes("else 'financiamento'::mesa_fluxo_tipo"),
  };
  const mappingOk = Object.values(mapping).every(Boolean);
  resultados.push(result('06_mapeamento_grupos_para_enum_real', mappingOk ? 'PASS' : 'FAIL', mapping));

  const statusEnumOk = functionBody.includes("'em_analise'::public.mesa_simulacao_status")
    && functionBody.includes("'rascunho'::public.mesa_simulacao_status")
    && !functionBody.includes('aguardando_aprovacao');
  resultados.push(result('07_status_enum_8g_preservado', statusEnumOk ? 'PASS' : 'FAIL', { statusEnumOk }));

  const corretorAuditOk = !/v_corretor_id\s*:=\s*v_auth_uid\s*;/i.test(functionBody)
    && /select\s+c\.id\s*,\s*c\.empresa_id\s+into\s+v_corretor_id\s*,\s*v_user_empresa_id\s+from\s+public\.corretores\s+c/i.test(functionBody)
    && /ator_corretor_id/i.test(functionBody)
    && /ator_user_id/i.test(functionBody)
    && !/\busuario_id\b/i.test(functionBody)
    && !/\btabela_afetada\b/i.test(functionBody);
  resultados.push(result('08_corretor_audit_8h_preservado', corretorAuditOk ? 'PASS' : 'FAIL', { corretorAuditOk }));

  const noStructureChanges = !/alter\s+table\s+public\./i.test(functionBody)
    && !/create\s+table\s+public\./i.test(functionBody)
    && !/drop\s+table\s+public\./i.test(functionBody)
    && !/alter\s+type\s+public\./i.test(functionBody)
    && !/create\s+policy\s+/i.test(functionBody)
    && !/drop\s+policy\s+/i.test(functionBody)
    && !/grant\s+/i.test(functionBody)
    && !/revoke\s+/i.test(functionBody);
  resultados.push(result('09_sem_alteracao_estrutural', noStructureChanges ? 'PASS' : 'FAIL', { noStructureChanges }));
}

const failCount = resultados.filter((item) => item.status === 'FAIL').length;
resultados.push(result('99_readiness_19c_fix_fluxo_tipo_enum', failCount === 0 ? 'PASS' : 'FAIL', {
  fail_count: failCount,
  migration_exists: exists(MIGRATION_PATH),
}));

const output = JSON.stringify(resultados, null, 2);
console.log(output);

const artifactDir = path.join(ROOT, 'artifacts', 'mesa-cliente');
fs.mkdirSync(artifactDir, { recursive: true });
fs.writeFileSync(path.join(artifactDir, '19c_resultado.json'), `${output}\n`, 'utf8');

process.exit(failCount === 0 ? 0 : 1);
