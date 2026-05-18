-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4C
-- 09B Validação rollback — Negativos da agenda financeira cliente-safe.
--
-- Objetivo:
--   Validar que a RPC public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)
--   bloqueia cenários indevidos e não vaza campos internos em payloads hostis.
--
-- Protocolo Mestre:
--   - sem frontend;
--   - sem parser;
--   - sem Worker/Make/n8n;
--   - sem DML em operações financeiras;
--   - fixture apenas transacional;
--   - BEGIN + ROLLBACK;
--   - sem deduzir colunas inexistentes;
--   - cliente-safe não pode expor campos sensíveis.
--
-- Este teste usa função auxiliar em pg_temp somente para capturar exceções por cenário.
-- A função é temporária/transacional e não altera o schema público.

begin;

-- 01. Contagens iniciais.
select
  set_config('mc09b.agendas_before', (select count(*)::text from public.mesa_cliente_agendas_financeiras), true) as agendas_before,
  set_config('mc09b.parcelas_before', (select count(*)::text from public.mesa_cliente_fluxo_parcelas), true) as parcelas_before,
  set_config('mc09b.operacoes_before', (select count(*)::text from public.mesa_cliente_fluxo_operacoes), true) as operacoes_before;

-- 02. Helper transacional para capturar erro sem abortar o teste inteiro.
create or replace function pg_temp.mc09b_try_cliente_safe(p_simulacao_id uuid)
returns jsonb
language plpgsql
as $$
declare
  v_result jsonb;
begin
  begin
    v_result := public.mesa_cliente_obter_agenda_financeira_cliente_safe(p_simulacao_id);

    return jsonb_build_object(
      'erro_capturado', false,
      'sqlstate', null,
      'message', null,
      'result', v_result
    );
  exception when others then
    return jsonb_build_object(
      'erro_capturado', true,
      'sqlstate', sqlstate,
      'message', sqlerrm,
      'result', null
    );
  end;
end;
$$;

-- 03. Cenário sem auth: limpa claims antes de qualquer candidato.
select
  set_config('request.jwt.claim.sub', '', true) as jwt_sub_vazio,
  set_config('request.jwt.claim.role', 'authenticated', true) as jwt_role,
  set_config('mc09b.sem_auth_result', pg_temp.mc09b_try_cliente_safe(gen_random_uuid())::text, true) as sem_auth_result;

-- 04. Candidato principal real, preferindo usuário não-root quando existir.
with candidate as (
  select
    c.user_id,
    c.empresa_id,
    c.id as corretor_id,
    coalesce(c.role, '') as role,
    coalesce(c.ativo, true) as ativo,
    coalesce(c.is_gestor, false) as is_gestor,
    coalesce(c.is_admin_local, false) as is_admin_local,
    e.id as empreendimento_id,
    to_jsonb(e)->>'nome' as empreendimento_nome
  from public.corretores c
  join lateral (
    select e1.*
    from public.empreendimentos e1
    where e1.empresa_id = c.empresa_id
    order by e1.created_at asc nulls last, e1.id
    limit 1
  ) e on true
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
  order by
    case when coalesce(c.role, '') = 'admin_global' then 1 else 0 end,
    c.created_at asc nulls last,
    c.id
  limit 1
)
select
  set_config('mc09b.main_has_candidate', 'true', true) as main_has_candidate,
  set_config('request.jwt.claim.sub', c.user_id::text, true) as jwt_sub,
  set_config('request.jwt.claim.role', 'authenticated', true) as jwt_role,
  set_config('mc09b.user_id', c.user_id::text, true) as user_id,
  set_config('mc09b.empresa_id', c.empresa_id::text, true) as empresa_id,
  set_config('mc09b.corretor_id', c.corretor_id::text, true) as corretor_id,
  set_config('mc09b.role', c.role, true) as role,
  set_config('mc09b.ativo', c.ativo::text, true) as ativo,
  set_config('mc09b.is_gestor', c.is_gestor::text, true) as is_gestor,
  set_config('mc09b.is_admin_local', c.is_admin_local::text, true) as is_admin_local,
  set_config('mc09b.empreendimento_id', c.empreendimento_id::text, true) as empreendimento_id,
  set_config('mc09b.empreendimento_nome', coalesce(c.empreendimento_nome, ''), true) as empreendimento_nome,
  set_config('mc09b.sim_sem_agenda_id', gen_random_uuid()::text, true) as sim_sem_agenda_id,
  set_config('mc09b.sim_substituida_id', gen_random_uuid()::text, true) as sim_substituida_id,
  set_config('mc09b.agenda_substituida_id', gen_random_uuid()::text, true) as agenda_substituida_id,
  set_config('mc09b.sim_dirty_id', gen_random_uuid()::text, true) as sim_dirty_id,
  set_config('mc09b.agenda_dirty_id', gen_random_uuid()::text, true) as agenda_dirty_id
from candidate c;

-- 05. Fixture: simulação sem agenda ativa.
insert into public.mesa_simulacoes (
  id,
  empresa_id,
  corretor_id,
  empreendimento_id,
  cliente_nome,
  valor_total,
  entrada,
  financiamento,
  valor_final,
  status,
  created_at,
  updated_at
)
select
  current_setting('mc09b.sim_sem_agenda_id', true)::uuid,
  current_setting('mc09b.empresa_id', true)::uuid,
  current_setting('mc09b.corretor_id', true)::uuid,
  current_setting('mc09b.empreendimento_id', true)::uuid,
  'Fixture 09B - Sem Agenda Ativa',
  1000000,
  100000,
  900000,
  1000000,
  'rascunho',
  now(),
  now()
where coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true';

-- 06. Fixture: simulação com agenda substituída apenas.
insert into public.mesa_simulacoes (
  id,
  empresa_id,
  corretor_id,
  empreendimento_id,
  cliente_nome,
  valor_total,
  entrada,
  financiamento,
  valor_final,
  status,
  created_at,
  updated_at
)
select
  current_setting('mc09b.sim_substituida_id', true)::uuid,
  current_setting('mc09b.empresa_id', true)::uuid,
  current_setting('mc09b.corretor_id', true)::uuid,
  current_setting('mc09b.empreendimento_id', true)::uuid,
  'Fixture 09B - Agenda Substituida',
  1000000,
  100000,
  900000,
  1000000,
  'rascunho',
  now(),
  now()
where coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true';

insert into public.mesa_cliente_agendas_financeiras (
  id,
  empresa_id,
  simulacao_id,
  empreendimento_id,
  versao,
  status,
  origem,
  checksum,
  payload_origem,
  totais,
  metadata,
  criado_por,
  substituida_em,
  substituida_por,
  created_at,
  updated_at
)
select
  current_setting('mc09b.agenda_substituida_id', true)::uuid,
  current_setting('mc09b.empresa_id', true)::uuid,
  current_setting('mc09b.sim_substituida_id', true)::uuid,
  current_setting('mc09b.empreendimento_id', true)::uuid,
  1,
  'substituida',
  'fixture_09b_agenda_substituida',
  md5(current_setting('mc09b.sim_substituida_id', true) || ':substituida'),
  jsonb_build_object('payload_origem', 'nao_deve_sair'),
  jsonb_build_object('qtd_parcelas', 0, 'valor_total', 0),
  jsonb_build_object('metadata', 'nao_deve_sair'),
  current_setting('mc09b.user_id', true)::uuid,
  now(),
  current_setting('mc09b.user_id', true)::uuid,
  now(),
  now()
where coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true';

-- 07. Fixture: payload sujo com agenda ativa para validar filtro cliente-safe.
insert into public.mesa_simulacoes (
  id,
  empresa_id,
  corretor_id,
  empreendimento_id,
  cliente_nome,
  valor_total,
  entrada,
  financiamento,
  valor_final,
  status,
  created_at,
  updated_at
)
select
  current_setting('mc09b.sim_dirty_id', true)::uuid,
  current_setting('mc09b.empresa_id', true)::uuid,
  current_setting('mc09b.corretor_id', true)::uuid,
  current_setting('mc09b.empreendimento_id', true)::uuid,
  'Fixture 09B - Payload Sujo',
  1000000,
  100000,
  900000,
  1000000,
  'rascunho',
  now(),
  now()
where coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true';

insert into public.mesa_cliente_agendas_financeiras (
  id,
  empresa_id,
  simulacao_id,
  empreendimento_id,
  versao,
  status,
  origem,
  checksum,
  payload_origem,
  totais,
  metadata,
  criado_por,
  created_at,
  updated_at
)
select
  current_setting('mc09b.agenda_dirty_id', true)::uuid,
  current_setting('mc09b.empresa_id', true)::uuid,
  current_setting('mc09b.sim_dirty_id', true)::uuid,
  current_setting('mc09b.empreendimento_id', true)::uuid,
  1,
  'ativa',
  'fixture_09b_payload_sujo',
  md5(current_setting('mc09b.sim_dirty_id', true) || ':dirty'),
  jsonb_build_object(
    'checksum', 'nao_deve_sair',
    'metadata', 'nao_deve_sair',
    'payload_origem', 'nao_deve_sair',
    'criado_por', current_setting('mc09b.user_id', true),
    'vpl_aplicado_pct', 9.99,
    'premio_corretor_pct', 1.23,
    'politica_id', gen_random_uuid()::text,
    'taxa_ano_pct', 12.34,
    'desconto_calculado', 999,
    'acrescimo_calculado', 888,
    'economia_liquida', 777
  ),
  jsonb_build_object('qtd_parcelas', 2, 'valor_total', 1000),
  jsonb_build_object(
    'metadata', 'nao_deve_sair',
    'status_premio', 'interno',
    'confirmado_por', current_setting('mc09b.user_id', true),
    'cancelado_por', current_setting('mc09b.user_id', true)
  ),
  current_setting('mc09b.user_id', true)::uuid,
  now(),
  now()
where coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true';

insert into public.mesa_cliente_fluxo_parcelas (
  empresa_id,
  simulacao_id,
  empreendimento_id,
  grupo,
  descricao,
  valor_original,
  valor_atual,
  data_original,
  data_atual,
  origem_data,
  regra_data,
  ordem,
  eh_periodicidade_simbolica,
  pode_receber_vpl,
  pode_receber_antecipacao,
  pode_receber_postergacao,
  metadata,
  criado_por,
  atualizado_por,
  agenda_id,
  created_at,
  updated_at
)
select
  current_setting('mc09b.empresa_id', true)::uuid,
  current_setting('mc09b.sim_dirty_id', true)::uuid,
  current_setting('mc09b.empreendimento_id', true)::uuid,
  pf.grupo,
  pf.descricao,
  pf.valor,
  pf.valor,
  pf.data_ref,
  pf.data_ref,
  'tabela_comercial_mes'::public.mesa_financeira_origem_data,
  'fixture_09b',
  pf.ordem,
  pf.eh_periodicidade_simbolica,
  pf.pode_receber_vpl,
  pf.pode_receber_antecipacao,
  pf.pode_receber_postergacao,
  jsonb_build_object(
    'metadata', 'nao_deve_sair',
    'pode_receber_vpl', pf.pode_receber_vpl,
    'vpl_aplicado_pct', 9.99,
    'premio_corretor_pct', 1.23,
    'taxa_ano_pct', 12.34,
    'desconto_calculado', 999,
    'acrescimo_calculado', 888,
    'economia_liquida', 777,
    'label', pf.metadata_label
  ),
  current_setting('mc09b.user_id', true)::uuid,
  current_setting('mc09b.user_id', true)::uuid,
  current_setting('mc09b.agenda_dirty_id', true)::uuid,
  now(),
  now()
from (values
  (1, 'entrada'::text, 'Entrada hostil'::text, 1000::numeric, date '2099-05-31', false, true, true, true, 'metadata_parcela_entrada'::text),
  (2, 'periodicidade'::text, 'Periodicidade hostil'::text, 0::numeric, date '2099-06-30', true, false, false, false, 'metadata_parcela_periodicidade'::text)
) as pf(
  ordem,
  grupo,
  descricao,
  valor,
  data_ref,
  eh_periodicidade_simbolica,
  pode_receber_vpl,
  pode_receber_antecipacao,
  pode_receber_postergacao,
  metadata_label
)
where coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true';

-- 08. Executa cenários negativos/autorizados do candidato principal.
select
  set_config('mc09b.sim_inexistente_result', pg_temp.mc09b_try_cliente_safe(gen_random_uuid())::text, true) as sim_inexistente_result,
  set_config('mc09b.sem_agenda_result', pg_temp.mc09b_try_cliente_safe(current_setting('mc09b.sim_sem_agenda_id', true)::uuid)::text, true) as sem_agenda_result,
  set_config('mc09b.substituida_result', pg_temp.mc09b_try_cliente_safe(current_setting('mc09b.sim_substituida_id', true)::uuid)::text, true) as substituida_result,
  set_config('mc09b.dirty_result', pg_temp.mc09b_try_cliente_safe(current_setting('mc09b.sim_dirty_id', true)::uuid)::text, true) as dirty_result
where coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true';

-- 09. Candidato cross-tenant: usuário não-root de uma empresa tentando ler simulação de outra empresa.
with cross_candidate as (
  select
    c.user_id as requester_user_id,
    c.empresa_id as requester_empresa_id,
    c.id as requester_corretor_id,
    coalesce(c.role, '') as requester_role,
    e_other.empresa_id as target_empresa_id,
    e_other.id as target_empreendimento_id,
    to_jsonb(e_other)->>'nome' as target_empreendimento_nome,
    c_target.id as target_corretor_id
  from public.corretores c
  join lateral (
    select e1.*
    from public.empreendimentos e1
    where e1.empresa_id is distinct from c.empresa_id
    order by e1.created_at asc nulls last, e1.id
    limit 1
  ) e_other on true
  join lateral (
    select c2.*
    from public.corretores c2
    where c2.empresa_id = e_other.empresa_id
    order by c2.created_at asc nulls last, c2.id
    limit 1
  ) c_target on true
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and coalesce(c.role, '') <> 'admin_global'
  order by c.created_at asc nulls last, c.id
  limit 1
)
select
  set_config('mc09b.cross_has_candidate', 'true', true) as cross_has_candidate,
  set_config('mc09b.cross_user_id', cc.requester_user_id::text, true) as cross_user_id,
  set_config('mc09b.cross_requester_empresa_id', cc.requester_empresa_id::text, true) as cross_requester_empresa_id,
  set_config('mc09b.cross_requester_role', cc.requester_role, true) as cross_requester_role,
  set_config('mc09b.cross_target_empresa_id', cc.target_empresa_id::text, true) as cross_target_empresa_id,
  set_config('mc09b.cross_target_corretor_id', cc.target_corretor_id::text, true) as cross_target_corretor_id,
  set_config('mc09b.cross_target_empreendimento_id', cc.target_empreendimento_id::text, true) as cross_target_empreendimento_id,
  set_config('mc09b.cross_target_empreendimento_nome', coalesce(cc.target_empreendimento_nome, ''), true) as cross_target_empreendimento_nome,
  set_config('mc09b.cross_simulacao_id', gen_random_uuid()::text, true) as cross_simulacao_id
from cross_candidate cc;

insert into public.mesa_simulacoes (
  id,
  empresa_id,
  corretor_id,
  empreendimento_id,
  cliente_nome,
  valor_total,
  entrada,
  financiamento,
  valor_final,
  status,
  created_at,
  updated_at
)
select
  current_setting('mc09b.cross_simulacao_id', true)::uuid,
  current_setting('mc09b.cross_target_empresa_id', true)::uuid,
  current_setting('mc09b.cross_target_corretor_id', true)::uuid,
  current_setting('mc09b.cross_target_empreendimento_id', true)::uuid,
  'Fixture 09B - Cross Tenant',
  1000000,
  100000,
  900000,
  1000000,
  'rascunho',
  now(),
  now()
where coalesce(current_setting('mc09b.cross_has_candidate', true), 'false') = 'true';

-- Autentica como usuário da empresa de origem e tenta ler simulação da empresa alvo.
select
  set_config('request.jwt.claim.sub', current_setting('mc09b.cross_user_id', true), true) as jwt_cross_sub,
  set_config('request.jwt.claim.role', 'authenticated', true) as jwt_cross_role,
  set_config('mc09b.cross_tenant_result', pg_temp.mc09b_try_cliente_safe(current_setting('mc09b.cross_simulacao_id', true)::uuid)::text, true) as cross_tenant_result
where coalesce(current_setting('mc09b.cross_has_candidate', true), 'false') = 'true';

-- 10. Restaura auth do candidato principal para as leituras finais.
select
  set_config('request.jwt.claim.sub', current_setting('mc09b.user_id', true), true) as jwt_main_sub,
  set_config('request.jwt.claim.role', 'authenticated', true) as jwt_main_role
where coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true';

-- 11. Resultset único.
with
ctx as (
  select
    coalesce(current_setting('mc09b.main_has_candidate', true), 'false') = 'true' as main_has_candidate,
    coalesce(current_setting('mc09b.cross_has_candidate', true), 'false') = 'true' as cross_has_candidate,
    current_setting('mc09b.user_id', true)::uuid as user_id,
    current_setting('mc09b.empresa_id', true)::uuid as empresa_id,
    current_setting('mc09b.corretor_id', true)::uuid as corretor_id,
    current_setting('mc09b.role', true) as role,
    current_setting('mc09b.ativo', true)::boolean as ativo,
    current_setting('mc09b.is_gestor', true)::boolean as is_gestor,
    current_setting('mc09b.is_admin_local', true)::boolean as is_admin_local,
    current_setting('mc09b.empreendimento_id', true)::uuid as empreendimento_id,
    current_setting('mc09b.empreendimento_nome', true) as empreendimento_nome,
    current_setting('mc09b.sim_sem_agenda_id', true)::uuid as sim_sem_agenda_id,
    current_setting('mc09b.sim_substituida_id', true)::uuid as sim_substituida_id,
    current_setting('mc09b.agenda_substituida_id', true)::uuid as agenda_substituida_id,
    current_setting('mc09b.sim_dirty_id', true)::uuid as sim_dirty_id,
    current_setting('mc09b.agenda_dirty_id', true)::uuid as agenda_dirty_id,
    current_setting('mc09b.agendas_before', true)::bigint as agendas_before,
    current_setting('mc09b.parcelas_before', true)::bigint as parcelas_before,
    current_setting('mc09b.operacoes_before', true)::bigint as operacoes_before
),
scenario_results as (
  select
    current_setting('mc09b.sem_auth_result', true)::jsonb as sem_auth_result,
    current_setting('mc09b.sim_inexistente_result', true)::jsonb as sim_inexistente_result,
    current_setting('mc09b.sem_agenda_result', true)::jsonb as sem_agenda_result,
    current_setting('mc09b.substituida_result', true)::jsonb as substituida_result,
    current_setting('mc09b.dirty_result', true)::jsonb as dirty_result,
    case
      when coalesce(current_setting('mc09b.cross_has_candidate', true), 'false') = 'true'
      then current_setting('mc09b.cross_tenant_result', true)::jsonb
      else null::jsonb
    end as cross_tenant_result
),
forbidden_keys as (
  select array[
    'checksum',
    'metadata',
    'payload_origem',
    'criado_por',
    'atualizado_por',
    'confirmado_por',
    'cancelado_por',
    'pode_receber_vpl',
    'vpl_aplicado_pct',
    'premio_corretor_pct',
    'status_premio',
    'politica_id',
    'taxa_ano_pct',
    'desconto_calculado',
    'acrescimo_calculado',
    'economia_liquida'
  ]::text[] as keys
),
sensitive_found_dirty as (
  select coalesce(jsonb_agg(k.key order by k.key), '[]'::jsonb) as keys_found
  from scenario_results sr
  cross join forbidden_keys fk
  cross join lateral unnest(fk.keys) as k(key)
  where sr.dirty_result->'result' is not null
    and (sr.dirty_result->'result')::text like '%"' || k.key || '"%'
),
after_counts as (
  select
    (select count(*) from public.mesa_cliente_agendas_financeiras)::bigint as agendas_after,
    (select count(*) from public.mesa_cliente_fluxo_parcelas)::bigint as parcelas_after,
    (select count(*) from public.mesa_cliente_fluxo_operacoes)::bigint as operacoes_after
),
resultados as (
  select
    '01_fixture_transacional_contexto'::text as bloco,
    case
      when (select main_has_candidate from ctx)
       and exists (select 1 from public.mesa_simulacoes s where s.id = (select sim_sem_agenda_id from ctx))
       and exists (select 1 from public.mesa_simulacoes s where s.id = (select sim_substituida_id from ctx))
       and exists (select 1 from public.mesa_simulacoes s where s.id = (select sim_dirty_id from ctx))
       and exists (select 1 from public.mesa_cliente_agendas_financeiras a where a.id = (select agenda_substituida_id from ctx) and a.status = 'substituida')
       and exists (select 1 from public.mesa_cliente_agendas_financeiras a where a.id = (select agenda_dirty_id from ctx) and a.status = 'ativa')
       and (select count(*) from public.mesa_cliente_fluxo_parcelas p where p.agenda_id = (select agenda_dirty_id from ctx)) = 2
      then 'PASS' else 'FAIL'
    end::text as status,
    jsonb_build_object(
      'user_id', (select user_id from ctx),
      'empresa_id', (select empresa_id from ctx),
      'corretor_id', (select corretor_id from ctx),
      'role', (select role from ctx),
      'ativo', (select ativo from ctx),
      'is_gestor', (select is_gestor from ctx),
      'is_admin_local', (select is_admin_local from ctx),
      'empreendimento_id', (select empreendimento_id from ctx),
      'empreendimento_nome', (select empreendimento_nome from ctx),
      'sim_sem_agenda_id', (select sim_sem_agenda_id from ctx),
      'sim_substituida_id', (select sim_substituida_id from ctx),
      'sim_dirty_id', (select sim_dirty_id from ctx),
      'agenda_dirty_id', (select agenda_dirty_id from ctx),
      'qtd_parcelas_dirty_fixture', (select count(*) from public.mesa_cliente_fluxo_parcelas p where p.agenda_id = (select agenda_dirty_id from ctx))
    ) as detalhe

  union all

  select
    '02_grants_rpc_anon_bloqueado_authenticated_liberado',
    case
      when not has_function_privilege('anon', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
       and has_function_privilege('authenticated', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'anon_can_execute', has_function_privilege('anon', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE'),
      'authenticated_can_execute', has_function_privilege('authenticated', 'public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)', 'EXECUTE')
    )

  union all

  select
    '03_sem_auth_bloqueado',
    case when (select (sem_auth_result->>'erro_capturado')::boolean from scenario_results) = true
      then 'PASS' else 'FAIL' end,
    (select sem_auth_result - 'result' from scenario_results)

  union all

  select
    '04_simulacao_inexistente_bloqueada',
    case when (select (sim_inexistente_result->>'erro_capturado')::boolean from scenario_results) = true
      then 'PASS' else 'FAIL' end,
    (select sim_inexistente_result - 'result' from scenario_results)

  union all

  select
    '05_simulacao_sem_agenda_ativa_bloqueada',
    case when (select (sem_agenda_result->>'erro_capturado')::boolean from scenario_results) = true
      then 'PASS' else 'FAIL' end,
    (select sem_agenda_result - 'result' from scenario_results)

  union all

  select
    '06_agenda_substituida_nao_retornada',
    case when (select (substituida_result->>'erro_capturado')::boolean from scenario_results) = true
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'erro', (select substituida_result - 'result' from scenario_results),
      'agenda_substituida_id', (select agenda_substituida_id from ctx),
      'status_agenda_fixture', (
        select a.status
        from public.mesa_cliente_agendas_financeiras a
        where a.id = (select agenda_substituida_id from ctx)
      )
    )

  union all

  select
    '07_cross_tenant_bloqueado',
    case
      when not (select cross_has_candidate from ctx) then 'INFO'
      when (select (cross_tenant_result->>'erro_capturado')::boolean from scenario_results) = true then 'PASS'
      else 'FAIL'
    end,
    jsonb_build_object(
      'cross_has_candidate', (select cross_has_candidate from ctx),
      'requester_user_id', current_setting('mc09b.cross_user_id', true),
      'requester_empresa_id', current_setting('mc09b.cross_requester_empresa_id', true),
      'requester_role', current_setting('mc09b.cross_requester_role', true),
      'target_empresa_id', current_setting('mc09b.cross_target_empresa_id', true),
      'target_empreendimento_id', current_setting('mc09b.cross_target_empreendimento_id', true),
      'target_empreendimento_nome', current_setting('mc09b.cross_target_empreendimento_nome', true),
      'cross_result', (select cross_tenant_result - 'result' from scenario_results)
    )

  union all

  select
    '08_payload_sujo_cliente_safe_sem_vazamento',
    case
      when (select (dirty_result->>'erro_capturado')::boolean from scenario_results) = false
       and (select dirty_result #>> '{result,ok}' from scenario_results) = 'true'
       and (select dirty_result #>> '{result,cliente_safe}' from scenario_results) = 'true'
       and jsonb_array_length((select keys_found from sensitive_found_dirty)) = 0
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'erro_capturado', (select dirty_result->>'erro_capturado' from scenario_results),
      'ok', (select dirty_result #>> '{result,ok}' from scenario_results),
      'fase', (select dirty_result #>> '{result,fase}' from scenario_results),
      'cliente_safe', (select dirty_result #>> '{result,cliente_safe}' from scenario_results),
      'visao', (select dirty_result #>> '{result,visao}' from scenario_results),
      'sensitive_keys_found', (select keys_found from sensitive_found_dirty),
      'forbidden_keys_checked', to_jsonb((select keys from forbidden_keys))
    )

  union all

  select
    '09_periodicidade_cliente_safe_continua_bloqueada',
    case
      when exists (
        select 1
        from scenario_results sr
        cross join lateral jsonb_array_elements(coalesce(sr.dirty_result #> '{result,parcelas}', '[]'::jsonb)) p
        where p->>'grupo' = 'periodicidade'
          and p->>'negociavel' = 'false'
          and p->'motivos_bloqueio' ? 'periodicidade_simbolica_nao_negociavel'
      )
      then 'PASS' else 'FAIL'
    end,
    jsonb_build_object(
      'periodicidade', (
        select p
        from scenario_results sr
        cross join lateral jsonb_array_elements(coalesce(sr.dirty_result #> '{result,parcelas}', '[]'::jsonb)) p
        where p->>'grupo' = 'periodicidade'
        limit 1
      )
    )

  union all

  select
    '10_read_only_sem_dml_adicional_agendas',
    case
      when (select cross_has_candidate from ctx)
        then case when (select agendas_after from after_counts) = (select agendas_before from ctx) + 2 then 'PASS' else 'FAIL' end
      else case when (select agendas_after from after_counts) = (select agendas_before from ctx) + 2 then 'PASS' else 'FAIL' end
    end,
    jsonb_build_object(
      'agendas_before', (select agendas_before from ctx),
      'agendas_after', (select agendas_after from after_counts),
      'esperado_delta', 2,
      'observacao', 'Apenas as agendas fixture transacionais: uma substituida e uma ativa suja.'
    )

  union all

  select
    '11_read_only_sem_dml_adicional_parcelas',
    case when (select parcelas_after from after_counts) = (select parcelas_before from ctx) + 2
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'parcelas_before', (select parcelas_before from ctx),
      'parcelas_after', (select parcelas_after from after_counts),
      'esperado_delta', 2,
      'observacao', 'Apenas as 2 parcelas fixture transacionais do payload sujo.'
    )

  union all

  select
    '12_zero_dml_operacoes',
    case when (select operacoes_after from after_counts) = (select operacoes_before from ctx)
      then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'operacoes_before', (select operacoes_before from ctx),
      'operacoes_after', (select operacoes_after from after_counts)
    )

  union all

  select
    '13_rollback_notice',
    'INFO',
    jsonb_build_object(
      'mensagem', 'Fixtures negativas foram criadas apenas dentro da transação. Tudo será encerrado com ROLLBACK.'
    )
)
select
  bloco,
  status,
  detalhe
from resultados
order by bloco;

rollback;
