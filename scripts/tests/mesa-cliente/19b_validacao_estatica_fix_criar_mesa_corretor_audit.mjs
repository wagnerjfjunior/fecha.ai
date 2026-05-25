#!/usr/bin/env node

/**
 * FECH.AI — MesaCliente
 * 19B — Validação estática do fix corretor_id + audit_logs da RPC criar_mesa_simulacao
 *
 * Não acessa banco, não executa RPC e não faz DML.
 */

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

const ROOT = process.cwd();
const MIGRATION_PATH = 'supabase/migrations/20260525152000_mesa_cliente_fase_8h_fix_criar_mesa_corretor_audit.sql';
const CONTRACT_PATH = 'docs/mesa-cliente/fase-8h-contrato-fix-rpc-criar-mesa-corretor-audit.md';

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

resultados.push(result('00_arquivos_base_19b', exists(MIGRATION_PATH) && exists(CONTRACT_PATH) ? 'PASS' : 'FAIL', {
  migration_exists: exists(MIGRATION_PATH),
  contract_exists: exists(CONTRACT_PATH),
}));

if (!contract) {
  resultados.push(result('01_contrato_8h', 'FAIL', { missing: CONTRACT_PATH }));
} else {
  const required = [
    'APROVADO PARA IMPLEMENTAÇÃO CONTROLADA',
    'Resolver `v_corretor_id` a partir de `public.corretores.id`',
    'audit_logs',
  ];
  const missing = required.filter((token) => !contract.includes(token));
  resultados.push(result('01_contrato_8h', missing.length === 0 ? 'PASS' : 'FAIL', { missing_tokens: missing }));
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

  const noAuthAssignedToCorretor = !/v_corretor_id\s*:=\s*v_auth_uid\s*;/i.test(functionBody);
  resultados.push(result('05_nao_atribui_auth_uid_como_corretor', noAuthAssignedToCorretor ? 'PASS' : 'FAIL', { noAuthAssignedToCorretor }));

  const resolvesCorretorReal = /select\s+c\.id\s*,\s*c\.empresa_id\s+into\s+v_corretor_id\s*,\s*v_user_empresa_id\s+from\s+public\.corretores\s+c/i.test(functionBody)
    && /c\.user_id\s*=\s*v_auth_uid/i.test(functionBody)
    && /coalesce\(c\.ativo,\s*true\)\s*=\s*true/i.test(functionBody);
  resultados.push(result('06_resolve_corretor_real', resolvesCorretorReal ? 'PASS' : 'FAIL', { resolvesCorretorReal }));

  const validatesCorretorNotNull = /if\s+v_corretor_id\s+is\s+null\s+then/i.test(functionBody)
    && /Usuário sem corretor ativo vinculado/.test(functionBody);
  resultados.push(result('07_valida_corretor_ativo', validatesCorretorNotNull ? 'PASS' : 'FAIL', { validatesCorretorNotNull }));

  const tenantCheck = /if\s+not\s+v_is_root\s+and\s+v_user_empresa_id\s+is\s+distinct\s+from\s+p_empresa_id\s+then/i.test(functionBody);
  resultados.push(result('08_tenant_check_preservado', tenantCheck ? 'PASS' : 'FAIL', { tenantCheck }));

  const statusEnumOk = functionBody.includes("'em_analise'::public.mesa_simulacao_status")
    && functionBody.includes("'rascunho'::public.mesa_simulacao_status")
    && !functionBody.includes('aguardando_aprovacao');
  resultados.push(result('09_status_enum_8g_preservado', statusEnumOk ? 'PASS' : 'FAIL', { statusEnumOk }));

  const noOldAuditCols = !/\busuario_id\b/i.test(functionBody)
    && !/\btabela_afetada\b/i.test(functionBody)
    && !/\bregistro_id\b/i.test(functionBody)
    && !/\bdetalhes\b/i.test(functionBody);
  resultados.push(result('10_sem_schema_antigo_audit', noOldAuditCols ? 'PASS' : 'FAIL', { noOldAuditCols }));

  const auditInsertReal = /insert\s+into\s+public\.audit_logs\s*\([\s\S]*empresa_id[\s\S]*action[\s\S]*actor_id[\s\S]*payload[\s\S]*ator_user_id[\s\S]*ator_corretor_id[\s\S]*acao[\s\S]*entidade[\s\S]*entidade_id[\s\S]*depois[\s\S]*\)/i.test(functionBody);
  resultados.push(result('11_audit_logs_schema_real', auditInsertReal ? 'PASS' : 'FAIL', { auditInsertReal }));

  const auditUsesAuthAndCorretor = /actor_id[\s\S]*v_auth_uid/i.test(functionBody)
    && /ator_user_id[\s\S]*v_auth_uid/i.test(functionBody)
    && /ator_corretor_id[\s\S]*v_corretor_id/i.test(functionBody);
  resultados.push(result('12_audit_separa_user_e_corretor', auditUsesAuthAndCorretor ? 'PASS' : 'FAIL', { auditUsesAuthAndCorretor }));

  const noStructureChanges = !/alter\s+table\s+public\./i.test(functionBody)
    && !/create\s+table\s+public\./i.test(functionBody)
    && !/drop\s+table\s+public\./i.test(functionBody)
    && !/alter\s+type\s+public\./i.test(functionBody)
    && !/create\s+policy\s+/i.test(functionBody)
    && !/drop\s+policy\s+/i.test(functionBody)
    && !/grant\s+/i.test(functionBody)
    && !/revoke\s+/i.test(functionBody);
  resultados.push(result('13_sem_alteracao_estrutural', noStructureChanges ? 'PASS' : 'FAIL', { noStructureChanges }));
}

const failCount = resultados.filter((item) => item.status === 'FAIL').length;
resultados.push(result('99_readiness_19b_fix_corretor_audit', failCount === 0 ? 'PASS' : 'FAIL', {
  fail_count: failCount,
  migration_exists: exists(MIGRATION_PATH),
}));

const output = JSON.stringify(resultados, null, 2);
console.log(output);

const artifactDir = path.join(ROOT, 'artifacts', 'mesa-cliente');
fs.mkdirSync(artifactDir, { recursive: true });
fs.writeFileSync(path.join(artifactDir, '19b_resultado.json'), `${output}\n`, 'utf8');

process.exit(failCount === 0 ? 0 : 1);
