-- FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8
-- 16E — Regressão final da v0.2.8 com ROLLBACK
--
-- Objetivo:
--   Consolidar, em um único teste final, as garantias já validadas em 16A–16D para:
--     public.pme_registrar_message_usage(uuid, jsonb)
--
-- Escopo validado:
--   1. contrato/catálogo da RPC;
--   2. RLS/hardening mínimo das tabelas PME;
--   3. fixture operacional com empresa/usuário/corretor/lead/template;
--   4. execução positiva append-only;
--   5. bloqueios negativos essenciais;
--   6. bloqueio cross-tenant essencial;
--   7. cardinalidade final sem mutação indevida;
--   8. readiness para PR/merge.
--
-- Segurança do teste:
--   - fixture transacional;
--   - sem IDs hardcoded;
--   - sem DDL persistente;
--   - DML apenas dentro da transação;
--   - encerra obrigatoriamente com ROLLBACK.

begin;

select set_config('app.pme16e.results', '[]', true);
select set_config('app.pme16e.empresa_a', '', true);
select set_config('app.pme16e.owner_user', '', true);
select set_config('app.pme16e.owner_corretor', '', true);
select set_config('app.pme16e.empresa_b', '', true);
select set_config('app.pme16e.cross_user', '', true);
select set_config('app.pme16e.cross_corretor', '', true);
select set_config('app.pme16e.lead_a', '', true);
select set_config('app.pme16e.template_a', '', true);
select set_config('app.pme16e.template_b', '', true);
select set_config('app.pme16e.usage_count_before', '0', true);
select set_config('app.pme16e.usage_id_positive', '', true);
select set_config('request.jwt.claim.sub', '', true);

create or replace function pg_temp.pme16e_add_result(
  p_bloco text,
  p_status text,
  p_detalhe jsonb default '{}'::jsonb
)
returns void
language plpgsql
as $$
declare
  v_atual jsonb;
begin
  v_atual := coalesce(nullif(current_setting('app.pme16e.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.pme16e.results',
    (
      v_atual || jsonb_build_array(
        jsonb_build_object(
          'bloco', p_bloco,
          'status', p_status,
          'detalhe', coalesce(p_detalhe, '{}'::jsonb)
        )
      )
    )::text,
    true
  );
end;
$$;

-- =========================================================
-- 00. Contrato/catálogo da RPC principal
-- =========================================================

with fn as materialized (
  select
    p.oid,
    p.proname,
    oidvectortypes(p.proargtypes) as args,
    p.prosecdef as security_definer,
    p.provolatile as volatility,
    coalesce(p.proconfig, '{}'::text[]) as proconfig,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
    has_function_privilege('service_role', p.oid, 'EXECUTE') as service_role_execute,
    obj_description(p.oid, 'pg_proc') is not null as comentario_presente
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname = 'pme_registrar_message_usage'
    and oidvectortypes(p.proargtypes) = 'uuid, jsonb'
)
select pg_temp.pme16e_add_result(
  '00_contrato_rpc_catalogo',
  case
    when count(*) = 1
     and bool_and(security_definer)
     and bool_and(proconfig @> array['search_path=public, pg_temp'])
     and bool_and(not anon_execute)
     and bool_and(authenticated_execute)
     and bool_and(service_role_execute)
     and bool_and(comentario_presente)
    then 'PASS'
    else 'FAIL'
  end,
  coalesce(jsonb_agg(jsonb_build_object(
    'proname', proname,
    'args', args,
    'security_definer', security_definer,
    'volatility', volatility,
    'search_path', proconfig,
    'anon_execute', anon_execute,
    'authenticated_execute', authenticated_execute,
    'service_role_execute', service_role_execute,
    'comentario_presente', comentario_presente
  )), '[]'::jsonb)
)
from fn;

-- =========================================================
-- 01. RLS/hardening mínimo das tabelas PME
-- =========================================================

with tabelas as materialized (
  select
    c.relname,
    c.relrowsecurity as rls_ativo
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in ('pme_message_templates', 'pme_message_usage')
), colunas_obrigatorias as materialized (
  select *
  from (values
    ('pme_message_usage','id'),
    ('pme_message_usage','empresa_id'),
    ('pme_message_usage','lead_id'),
    ('pme_message_usage','corretor_id'),
    ('pme_message_usage','template_id'),
    ('pme_message_usage','channel'),
    ('pme_message_usage','lead_type'),
    ('pme_message_usage','phase'),
    ('pme_message_usage','selection_mode'),
    ('pme_message_usage','status'),
    ('pme_message_usage','metadata'),
    ('pme_message_usage','created_at'),
    ('pme_message_templates','id'),
    ('pme_message_templates','empresa_id'),
    ('pme_message_templates','channel'),
    ('pme_message_templates','lead_type'),
    ('pme_message_templates','phase'),
    ('pme_message_templates','is_active')
  ) as v(table_name, column_name)
), colunas_status as materialized (
  select
    co.table_name,
    co.column_name,
    exists (
      select 1
      from information_schema.columns ic
      where ic.table_schema = 'public'
        and ic.table_name = co.table_name
        and ic.column_name = co.column_name
    ) as existe
  from colunas_obrigatorias co
), politicas_mutacionais_usage as materialized (
  select count(*) as qtd
  from pg_policies pp
  where pp.schemaname = 'public'
    and pp.tablename = 'pme_message_usage'
    and pp.cmd in ('UPDATE', 'DELETE')
)
select pg_temp.pme16e_add_result(
  '01_rls_schema_hardening_pme',
  case
    when (select count(*) from tabelas) = 2
     and (select bool_and(rls_ativo) from tabelas)
     and (select bool_and(existe) from colunas_status)
     and (select qtd from politicas_mutacionais_usage) = 0
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'tabelas', coalesce((select jsonb_agg(jsonb_build_object('relname', relname, 'rls_ativo', rls_ativo) order by relname) from tabelas), '[]'::jsonb),
    'colunas', coalesce((select jsonb_agg(jsonb_build_object('table_name', table_name, 'column_name', column_name, 'existe', existe) order by table_name, column_name) from colunas_status), '[]'::jsonb),
    'politicas_update_delete_usage', (select qtd from politicas_mutacionais_usage)
  )
);

-- =========================================================
-- 02. Seleção de atores e fixture operacional
-- =========================================================

with owner_a as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and c.empresa_id is not null
    and (
      select count(*)
      from public.corretores c2
      where c2.user_id = c.user_id
        and coalesce(c2.ativo, true) = true
    ) = 1
  order by
    case
      when coalesce(c.role, '') = 'corretor' then 1
      when coalesce(c.role, '') = 'gestor' then 2
      when coalesce(c.role, '') = 'admin_local' then 3
      else 4
    end,
    c.created_at desc nulls last,
    c.id
  limit 1
), cross_b as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and c.empresa_id is not null
    and c.empresa_id <> (select empresa_id from owner_a)
    and (
      select count(*)
      from public.corretores c2
      where c2.user_id = c.user_id
        and coalesce(c2.ativo, true) = true
    ) = 1
  order by
    case
      when coalesce(c.role, '') = 'corretor' then 1
      when coalesce(c.role, '') = 'gestor' then 2
      when coalesce(c.role, '') = 'admin_local' then 3
      else 4
    end,
    c.created_at desc nulls last,
    c.id
  limit 1
)
select
  set_config('app.pme16e.empresa_a', (select empresa_id::text from owner_a), true),
  set_config('app.pme16e.owner_user', (select user_id::text from owner_a), true),
  set_config('app.pme16e.owner_corretor', (select corretor_id::text from owner_a), true),
  set_config('app.pme16e.empresa_b', (select empresa_id::text from cross_b), true),
  set_config('app.pme16e.cross_user', (select user_id::text from cross_b), true),
  set_config('app.pme16e.cross_corretor', (select corretor_id::text from cross_b), true);

select set_config('request.jwt.claim.sub', current_setting('app.pme16e.owner_user', true), true);

with lead_a as materialized (
  insert into public.leads (
    empresa_id,
    corretor_id,
    nome,
    email,
    telefone_origem_1,
    telefone_escolhido,
    telefone_e164,
    status,
    origem_tipo,
    fornecedor,
    observacao_corretor
  ) values (
    current_setting('app.pme16e.empresa_a', true)::uuid,
    current_setting('app.pme16e.owner_corretor', true)::uuid,
    'Teste rollback 16E PME Usage Tracking Regressao Final',
    'teste.16e.pme@example.invalid',
    '11999999996',
    '11999999996',
    '+5511999999996',
    'distribuido',
    'lista',
    'fixture_16e_pme',
    'Fixture transacional 16E. Deve sumir no ROLLBACK.'
  )
  returning id
), template_a as materialized (
  insert into public.pme_message_templates (
    empresa_id, channel, lead_type, phase, tone, title, objective, body,
    variables, weight, is_active, is_seed, seed_key, created_by, updated_by
  ) values (
    current_setting('app.pme16e.empresa_a', true)::uuid,
    'whatsapp', 'lista_fria', 'primeira_mensagem', 'consultivo',
    'Template rollback 16E empresa A',
    'Validar regressao final positiva da RPC PME.',
    'Olá, {{nome}}. Template válido para regressão final PME.',
    '["nome"]'::jsonb, 1, true, false,
    'fixture_16e_a_' || replace(gen_random_uuid()::text, '-', ''),
    current_setting('app.pme16e.owner_corretor', true)::uuid,
    current_setting('app.pme16e.owner_corretor', true)::uuid
  )
  returning id
), template_b as materialized (
  insert into public.pme_message_templates (
    empresa_id, channel, lead_type, phase, tone, title, objective, body,
    variables, weight, is_active, is_seed, seed_key, created_by, updated_by
  ) values (
    current_setting('app.pme16e.empresa_b', true)::uuid,
    'whatsapp', 'lista_fria', 'primeira_mensagem', 'consultivo',
    'Template rollback 16E empresa B',
    'Validar regressao final cross-tenant da RPC PME.',
    'Olá, {{nome}}. Template empresa B para bloqueio cross-tenant.',
    '["nome"]'::jsonb, 1, true, false,
    'fixture_16e_b_' || replace(gen_random_uuid()::text, '-', ''),
    current_setting('app.pme16e.cross_corretor', true)::uuid,
    current_setting('app.pme16e.cross_corretor', true)::uuid
  )
  returning id
)
select
  set_config('app.pme16e.lead_a', (select id::text from lead_a), true),
  set_config('app.pme16e.template_a', (select id::text from template_a), true),
  set_config('app.pme16e.template_b', (select id::text from template_b), true);

select set_config(
  'app.pme16e.usage_count_before',
  (
    select count(*)::text
    from public.pme_message_usage u
    where u.lead_id = current_setting('app.pme16e.lead_a', true)::uuid
  ),
  true
);

select pg_temp.pme16e_add_result(
  '02_setup_fixture_regressao',
  case
    when nullif(current_setting('app.pme16e.empresa_a', true), '') is not null
     and nullif(current_setting('app.pme16e.owner_user', true), '') is not null
     and nullif(current_setting('app.pme16e.owner_corretor', true), '') is not null
     and nullif(current_setting('app.pme16e.empresa_b', true), '') is not null
     and nullif(current_setting('app.pme16e.cross_user', true), '') is not null
     and nullif(current_setting('app.pme16e.cross_corretor', true), '') is not null
     and nullif(current_setting('app.pme16e.lead_a', true), '') is not null
     and nullif(current_setting('app.pme16e.template_a', true), '') is not null
     and nullif(current_setting('app.pme16e.template_b', true), '') is not null
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'empresa_a', nullif(current_setting('app.pme16e.empresa_a', true), ''),
    'owner_user', nullif(current_setting('app.pme16e.owner_user', true), ''),
    'owner_corretor', nullif(current_setting('app.pme16e.owner_corretor', true), ''),
    'empresa_b', nullif(current_setting('app.pme16e.empresa_b', true), ''),
    'cross_user', nullif(current_setting('app.pme16e.cross_user', true), ''),
    'cross_corretor', nullif(current_setting('app.pme16e.cross_corretor', true), ''),
    'lead_a', nullif(current_setting('app.pme16e.lead_a', true), ''),
    'template_a', nullif(current_setting('app.pme16e.template_a', true), ''),
    'template_b', nullif(current_setting('app.pme16e.template_b', true), ''),
    'usage_count_before', current_setting('app.pme16e.usage_count_before', true)::int
  )
);

-- =========================================================
-- 03. Execução positiva append-only
-- =========================================================

do $$
declare
  v_payload jsonb;
begin
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16e.owner_user', true), true);

  v_payload := public.pme_registrar_message_usage(
    current_setting('app.pme16e.lead_a', true)::uuid,
    jsonb_build_object(
      'template_id', current_setting('app.pme16e.template_a', true),
      'channel', 'whatsapp',
      'lead_type', 'lista_fria',
      'phase', 'primeira_mensagem',
      'selection_mode', 'suggested',
      'status', 'copied',
      'rendered_body', 'Olá, Teste rollback 16E. Regressão final positiva.',
      'feedback_key', 'teste_16e_positive',
      'metadata', jsonb_build_object(
        'origem', 'teste_16e_regressao_final',
        'fixture_transacional', true
      )
    )
  );

  perform set_config('app.pme16e.usage_id_positive', v_payload->>'usage_id', true);

  perform pg_temp.pme16e_add_result(
    '03_execucao_positiva_append_only',
    case
      when (v_payload->>'ok')::boolean = true
       and (v_payload->>'append_only')::boolean = true
       and (v_payload->>'dml')::boolean = true
       and (v_payload->>'fase') = 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC'
       and (v_payload->>'empresa_id')::uuid = current_setting('app.pme16e.empresa_a', true)::uuid
       and (v_payload->>'corretor_id')::uuid = current_setting('app.pme16e.owner_corretor', true)::uuid
      then 'PASS'
      else 'FAIL'
    end,
    v_payload
  );
exception when others then
  perform pg_temp.pme16e_add_result(
    '03_execucao_positiva_append_only',
    'FAIL',
    jsonb_build_object('message', sqlerrm, 'sqlstate', sqlstate)
  );
end;
$$;

-- =========================================================
-- 04. Persistência transacional da linha positiva
-- =========================================================

with usage_row as materialized (
  select
    u.id,
    u.empresa_id,
    u.lead_id,
    u.corretor_id,
    u.template_id,
    u.channel,
    u.lead_type,
    u.phase,
    u.selection_mode,
    u.status,
    u.feedback_key,
    u.metadata,
    u.created_at
  from public.pme_message_usage u
  where u.id = nullif(current_setting('app.pme16e.usage_id_positive', true), '')::uuid
)
select pg_temp.pme16e_add_result(
  '04_linha_usage_positiva_persistida_na_transacao',
  case
    when count(*) = 1
     and bool_and(empresa_id = current_setting('app.pme16e.empresa_a', true)::uuid)
     and bool_and(lead_id = current_setting('app.pme16e.lead_a', true)::uuid)
     and bool_and(corretor_id = current_setting('app.pme16e.owner_corretor', true)::uuid)
     and bool_and(template_id = current_setting('app.pme16e.template_a', true)::uuid)
     and bool_and(channel = 'whatsapp')
     and bool_and(lead_type = 'lista_fria')
     and bool_and(phase = 'primeira_mensagem')
     and bool_and(selection_mode = 'suggested')
     and bool_and(status = 'copied')
     and bool_and(feedback_key = 'teste_16e_positive')
     and bool_and(metadata->>'fixture_transacional' = 'true')
    then 'PASS'
    else 'FAIL'
  end,
  coalesce(jsonb_agg(jsonb_build_object(
    'usage_id', id,
    'empresa_id', empresa_id,
    'lead_id', lead_id,
    'corretor_id', corretor_id,
    'template_id', template_id,
    'channel', channel,
    'lead_type', lead_type,
    'phase', phase,
    'selection_mode', selection_mode,
    'status', status,
    'feedback_key', feedback_key,
    'metadata', metadata,
    'created_at_presente', created_at is not null
  )), '[]'::jsonb)
)
from usage_row;

-- =========================================================
-- 05. Segurança negativa essencial
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
  v_details jsonb := '[]'::jsonb;
  v_pass int := 0;
  v_fail int := 0;
begin
  -- 05A: sem auth
  perform set_config('request.jwt.claim.sub', '', true);
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16e.lead_a', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16e.template_a', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );
    v_fail := v_fail + 1;
    v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'sem_auth', 'status', 'FAIL', 'message', 'rpc_executou_sem_auth'));
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;
    if v_message = 'auth_required' and v_state = '28000' then
      v_pass := v_pass + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'sem_auth', 'status', 'PASS', 'message', v_message, 'sqlstate', v_state));
    else
      v_fail := v_fail + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'sem_auth', 'status', 'FAIL', 'message', v_message, 'sqlstate', v_state));
    end if;
  end;

  -- 05B: soberania frontend
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16e.owner_user', true), true);
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16e.lead_a', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16e.template_a', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied',
        'empresa_id', gen_random_uuid()::text
      )
    );
    v_fail := v_fail + 1;
    v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'empresa_id_frontend', 'status', 'FAIL', 'message', 'rpc_aceitou_autoridade_frontend'));
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;
    if v_message = 'frontend_authority_forbidden' and v_state = '42501' then
      v_pass := v_pass + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'empresa_id_frontend', 'status', 'PASS', 'message', v_message, 'sqlstate', v_state));
    else
      v_fail := v_fail + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'empresa_id_frontend', 'status', 'FAIL', 'message', v_message, 'sqlstate', v_state));
    end if;
  end;

  -- 05C: payload não objeto
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16e.lead_a', true)::uuid,
      '[]'::jsonb
    );
    v_fail := v_fail + 1;
    v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'payload_nao_objeto', 'status', 'FAIL', 'message', 'rpc_aceitou_payload_array'));
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;
    if v_message = 'p_payload_must_be_object' and v_state = '22023' then
      v_pass := v_pass + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'payload_nao_objeto', 'status', 'PASS', 'message', v_message, 'sqlstate', v_state));
    else
      v_fail := v_fail + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'payload_nao_objeto', 'status', 'FAIL', 'message', v_message, 'sqlstate', v_state));
    end if;
  end;

  -- 05D: status inválido
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16e.lead_a', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16e.template_a', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'enviado_sem_permissao'
      )
    );
    v_fail := v_fail + 1;
    v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'status_invalido', 'status', 'FAIL', 'message', 'rpc_aceitou_status_invalido'));
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;
    if v_message = 'invalid_status' and v_state = '22023' then
      v_pass := v_pass + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'status_invalido', 'status', 'PASS', 'message', v_message, 'sqlstate', v_state));
    else
      v_fail := v_fail + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'status_invalido', 'status', 'FAIL', 'message', v_message, 'sqlstate', v_state));
    end if;
  end;

  perform pg_temp.pme16e_add_result(
    '05_seguranca_negativa_essencial',
    case when v_pass = 4 and v_fail = 0 then 'PASS' else 'FAIL' end,
    jsonb_build_object('pass_count', v_pass, 'fail_count', v_fail, 'detalhes', v_details)
  );
end;
$$;

-- =========================================================
-- 06. Escopo cross-tenant essencial
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
  v_details jsonb := '[]'::jsonb;
  v_pass int := 0;
  v_fail int := 0;
begin
  -- 06A: usuário de outra empresa tentando usar lead da empresa A
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16e.cross_user', true), true);
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16e.lead_a', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16e.template_a', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );
    v_fail := v_fail + 1;
    v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'cross_user_lead_a', 'status', 'FAIL', 'message', 'rpc_aceitou_cross_tenant_user'));
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;
    if v_message = 'pme_scope_denied' and v_state = '42501' then
      v_pass := v_pass + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'cross_user_lead_a', 'status', 'PASS', 'message', v_message, 'sqlstate', v_state));
    else
      v_fail := v_fail + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'cross_user_lead_a', 'status', 'FAIL', 'message', v_message, 'sqlstate', v_state));
    end if;
  end;

  -- 06B: template da empresa B em lead da empresa A
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16e.owner_user', true), true);
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16e.lead_a', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16e.template_b', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );
    v_fail := v_fail + 1;
    v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'template_b_lead_a', 'status', 'FAIL', 'message', 'rpc_aceitou_template_cross_tenant'));
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;
    if v_message = 'template_scope_denied_or_not_found' and v_state = '42501' then
      v_pass := v_pass + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'template_b_lead_a', 'status', 'PASS', 'message', v_message, 'sqlstate', v_state));
    else
      v_fail := v_fail + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object('cenario', 'template_b_lead_a', 'status', 'FAIL', 'message', v_message, 'sqlstate', v_state));
    end if;
  end;

  perform pg_temp.pme16e_add_result(
    '06_escopo_cross_tenant_essencial',
    case when v_pass = 2 and v_fail = 0 then 'PASS' else 'FAIL' end,
    jsonb_build_object('pass_count', v_pass, 'fail_count', v_fail, 'detalhes', v_details)
  );
end;
$$;

-- =========================================================
-- 07. Cardinalidade final: somente 1 positivo deve existir na transação
-- =========================================================

select pg_temp.pme16e_add_result(
  '07_cardinalidade_final_sem_mutacao_indevida',
  case
    when (
      select count(*)
      from public.pme_message_usage u
      where u.lead_id = current_setting('app.pme16e.lead_a', true)::uuid
    ) = current_setting('app.pme16e.usage_count_before', true)::int + 1
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'usage_count_before', current_setting('app.pme16e.usage_count_before', true)::int,
    'usage_count_after', (
      select count(*)
      from public.pme_message_usage u
      where u.lead_id = current_setting('app.pme16e.lead_a', true)::uuid
    ),
    'positivos_esperados', 1,
    'negativos_essenciais_bloqueados_esperados', 6,
    'usage_id_positive', nullif(current_setting('app.pme16e.usage_id_positive', true), ''),
    'lead_a', current_setting('app.pme16e.lead_a', true)
  )
);

-- =========================================================
-- 08. Readiness para PR/merge
-- =========================================================

with falhas as materialized (
  select
    count(*) as fail_count,
    coalesce(jsonb_agg(elem) filter (where elem->>'status' = 'FAIL'), '[]'::jsonb) as detalhes_falhas
  from jsonb_array_elements(current_setting('app.pme16e.results', true)::jsonb) elem
  where elem->>'status' = 'FAIL'
)
select pg_temp.pme16e_add_result(
  '08_readiness_pr_merge',
  case when (select fail_count from falhas) = 0 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
    'fail_count', (select fail_count from falhas),
    'falhas', (select detalhes_falhas from falhas),
    'readiness_pr_merge', (select fail_count from falhas) = 0,
    'cobertura_consolidada', jsonb_build_array(
      'contrato_rpc_catalogo',
      'rls_schema_hardening',
      'execucao_positiva_append_only',
      'persistencia_transacional',
      'seguranca_negativa_essencial',
      'escopo_cross_tenant_essencial',
      'cardinalidade_sem_mutacao_indevida',
      'rollback'
    )
  )
);

-- =========================================================
-- 99. Saída única e rollback
-- =========================================================

select pg_temp.pme16e_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
    'teste', '16E',
    'ddl_persistente', false,
    'dml_fixture', true,
    'rollback', true,
    'mensagem', 'Teste 16E encerra com ROLLBACK. Fixture e usos PME da regressao final nao devem permanecer no banco.',
    'validacao', 'regressao final v0.2.8 PME Usage Tracking DB/RLS/RPC'
  )
);

select jsonb_pretty(current_setting('app.pme16e.results', true)::jsonb) as resultado_16e;

rollback;
