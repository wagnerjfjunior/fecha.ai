-- FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8
-- 16D — Escopo/RLS/cross-tenant da RPC pme_registrar_message_usage com ROLLBACK
--
-- Objetivo:
--   Validar isolamento operacional por empresa da RPC:
--     public.pme_registrar_message_usage(uuid, jsonb)
--
-- Escopo validado:
--   1. owner/corretor da empresa do lead registra uso positivo;
--   2. outro corretor da mesma empresa também é autorizado pela regra atual pme_can_consume_empresa;
--   3. corretor de outra empresa é bloqueado ao tentar usar lead de empresa alheia;
--   4. template de outra empresa é bloqueado mesmo com lead válido da empresa atual;
--   5. lead inexistente é bloqueado;
--   6. tentativas cross-tenant não geram mutação indevida;
--   7. RLS permanece ativo nas tabelas PME envolvidas.
--
-- Segurança do teste:
--   - fixture transacional mínima;
--   - sem IDs hardcoded;
--   - sem DDL persistente;
--   - sem alteração permanente;
--   - encerra obrigatoriamente com ROLLBACK.

begin;

select set_config('app.pme16d.results', '[]', true);
select set_config('app.pme16d.empresa_a', '', true);
select set_config('app.pme16d.owner_user', '', true);
select set_config('app.pme16d.owner_corretor', '', true);
select set_config('app.pme16d.outro_mesma_empresa_user', '', true);
select set_config('app.pme16d.outro_mesma_empresa_corretor', '', true);
select set_config('app.pme16d.empresa_b', '', true);
select set_config('app.pme16d.cross_user', '', true);
select set_config('app.pme16d.cross_corretor', '', true);
select set_config('app.pme16d.lead_a', '', true);
select set_config('app.pme16d.template_a', '', true);
select set_config('app.pme16d.template_b', '', true);
select set_config('app.pme16d.usage_count_before', '0', true);
select set_config('request.jwt.claim.sub', '', true);

create or replace function pg_temp.pme16d_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.pme16d.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.pme16d.results',
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
-- 00. Seleção de atores reais: empresa A com 2 corretores + empresa B
-- =========================================================

with empresa_a as materialized (
  select c.empresa_id
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and c.empresa_id is not null
    and coalesce(c.role, '') = 'corretor'
    and (
      select count(*)
      from public.corretores cx
      where cx.empresa_id = c.empresa_id
        and cx.user_id is not null
        and coalesce(cx.ativo, true) = true
        and coalesce(cx.role, '') = 'corretor'
    ) >= 2
  group by c.empresa_id
  order by count(*) desc, c.empresa_id
  limit 1
), owner_a as materialized (
  select c.user_id, c.id as corretor_id, c.empresa_id
  from public.corretores c
  join empresa_a ea on ea.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and coalesce(c.role, '') = 'corretor'
  order by c.created_at desc nulls last, c.id
  limit 1
), outro_a as materialized (
  select c.user_id, c.id as corretor_id, c.empresa_id
  from public.corretores c
  join empresa_a ea on ea.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and coalesce(c.role, '') = 'corretor'
    and c.id <> (select corretor_id from owner_a)
  order by c.created_at desc nulls last, c.id
  limit 1
), cross_b as materialized (
  select c.user_id, c.id as corretor_id, c.empresa_id
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and c.empresa_id is not null
    and c.empresa_id <> (select empresa_id from empresa_a)
    and (
      select count(*)
      from public.corretores c2
      where c2.user_id = c.user_id
        and coalesce(c2.ativo, true) = true
    ) = 1
  order by
    case
      when coalesce(c.role, '') = 'corretor' then 1
      when coalesce(c.role, '') = 'admin_local' then 2
      when coalesce(c.role, '') = 'gestor' then 3
      else 4
    end,
    c.created_at desc nulls last,
    c.id
  limit 1
)
select
  set_config('app.pme16d.empresa_a', (select empresa_id::text from empresa_a), true),
  set_config('app.pme16d.owner_user', (select user_id::text from owner_a), true),
  set_config('app.pme16d.owner_corretor', (select corretor_id::text from owner_a), true),
  set_config('app.pme16d.outro_mesma_empresa_user', (select user_id::text from outro_a), true),
  set_config('app.pme16d.outro_mesma_empresa_corretor', (select corretor_id::text from outro_a), true),
  set_config('app.pme16d.empresa_b', (select empresa_id::text from cross_b), true),
  set_config('app.pme16d.cross_user', (select user_id::text from cross_b), true),
  set_config('app.pme16d.cross_corretor', (select corretor_id::text from cross_b), true);

select pg_temp.pme16d_add_result(
  '00_setup_atores_escopo',
  case
    when nullif(current_setting('app.pme16d.empresa_a', true), '') is not null
     and nullif(current_setting('app.pme16d.owner_user', true), '') is not null
     and nullif(current_setting('app.pme16d.owner_corretor', true), '') is not null
     and nullif(current_setting('app.pme16d.outro_mesma_empresa_user', true), '') is not null
     and nullif(current_setting('app.pme16d.outro_mesma_empresa_corretor', true), '') is not null
     and nullif(current_setting('app.pme16d.empresa_b', true), '') is not null
     and nullif(current_setting('app.pme16d.cross_user', true), '') is not null
     and nullif(current_setting('app.pme16d.cross_corretor', true), '') is not null
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'empresa_a', nullif(current_setting('app.pme16d.empresa_a', true), ''),
    'owner_user', nullif(current_setting('app.pme16d.owner_user', true), ''),
    'owner_corretor', nullif(current_setting('app.pme16d.owner_corretor', true), ''),
    'outro_mesma_empresa_user', nullif(current_setting('app.pme16d.outro_mesma_empresa_user', true), ''),
    'outro_mesma_empresa_corretor', nullif(current_setting('app.pme16d.outro_mesma_empresa_corretor', true), ''),
    'empresa_b', nullif(current_setting('app.pme16d.empresa_b', true), ''),
    'cross_user', nullif(current_setting('app.pme16d.cross_user', true), ''),
    'cross_corretor', nullif(current_setting('app.pme16d.cross_corretor', true), '')
  )
);

-- =========================================================
-- 01. Fixture: lead/template empresa A + template empresa B
-- =========================================================

select set_config('request.jwt.claim.sub', current_setting('app.pme16d.owner_user', true), true);

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
    current_setting('app.pme16d.empresa_a', true)::uuid,
    current_setting('app.pme16d.owner_corretor', true)::uuid,
    'Teste rollback 16D PME Usage Tracking Empresa A',
    'teste.16d.empresa.a@example.invalid',
    '11999999997',
    '11999999997',
    '+5511999999997',
    'distribuido',
    'lista',
    'fixture_16d_pme',
    'Fixture transacional 16D empresa A. Deve sumir no ROLLBACK.'
  )
  returning id
), template_a as materialized (
  insert into public.pme_message_templates (
    empresa_id, channel, lead_type, phase, tone, title, objective, body,
    variables, weight, is_active, is_seed, seed_key, created_by, updated_by
  ) values (
    current_setting('app.pme16d.empresa_a', true)::uuid,
    'whatsapp', 'lista_fria', 'primeira_mensagem', 'consultivo',
    'Template rollback 16D empresa A',
    'Validar escopo positivo empresa A.',
    'Olá, {{nome}}. Template válido empresa A.',
    '["nome"]'::jsonb, 1, true, false,
    'fixture_16d_a_' || replace(gen_random_uuid()::text, '-', ''),
    current_setting('app.pme16d.owner_corretor', true)::uuid,
    current_setting('app.pme16d.owner_corretor', true)::uuid
  )
  returning id
), template_b as materialized (
  insert into public.pme_message_templates (
    empresa_id, channel, lead_type, phase, tone, title, objective, body,
    variables, weight, is_active, is_seed, seed_key, created_by, updated_by
  ) values (
    current_setting('app.pme16d.empresa_b', true)::uuid,
    'whatsapp', 'lista_fria', 'primeira_mensagem', 'consultivo',
    'Template rollback 16D empresa B',
    'Validar bloqueio cross-tenant por template.',
    'Olá, {{nome}}. Template válido empresa B, mas não para lead da empresa A.',
    '["nome"]'::jsonb, 1, true, false,
    'fixture_16d_b_' || replace(gen_random_uuid()::text, '-', ''),
    current_setting('app.pme16d.cross_corretor', true)::uuid,
    current_setting('app.pme16d.cross_corretor', true)::uuid
  )
  returning id
)
select
  set_config('app.pme16d.lead_a', (select id::text from lead_a), true),
  set_config('app.pme16d.template_a', (select id::text from template_a), true),
  set_config('app.pme16d.template_b', (select id::text from template_b), true);

select set_config(
  'app.pme16d.usage_count_before',
  (
    select count(*)::text
    from public.pme_message_usage u
    where u.lead_id = current_setting('app.pme16d.lead_a', true)::uuid
  ),
  true
);

select pg_temp.pme16d_add_result(
  '01_fixture_cross_tenant',
  case
    when nullif(current_setting('app.pme16d.lead_a', true), '') is not null
     and nullif(current_setting('app.pme16d.template_a', true), '') is not null
     and nullif(current_setting('app.pme16d.template_b', true), '') is not null
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'lead_a', current_setting('app.pme16d.lead_a', true),
    'template_a', current_setting('app.pme16d.template_a', true),
    'template_b', current_setting('app.pme16d.template_b', true),
    'empresa_a', current_setting('app.pme16d.empresa_a', true),
    'empresa_b', current_setting('app.pme16d.empresa_b', true),
    'usage_count_before', current_setting('app.pme16d.usage_count_before', true)::int
  )
);

-- =========================================================
-- 02. Owner da empresa A registra uso positivo
-- =========================================================

do $$
declare
  v_payload jsonb;
begin
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16d.owner_user', true), true);

  v_payload := public.pme_registrar_message_usage(
    current_setting('app.pme16d.lead_a', true)::uuid,
    jsonb_build_object(
      'template_id', current_setting('app.pme16d.template_a', true),
      'channel', 'whatsapp',
      'lead_type', 'lista_fria',
      'phase', 'primeira_mensagem',
      'selection_mode', 'suggested',
      'status', 'copied',
      'feedback_key', 'teste_16d_owner_positive',
      'metadata', jsonb_build_object('origem', 'teste_16d_owner_positive')
    )
  );

  perform pg_temp.pme16d_add_result(
    '02_owner_mesma_empresa_registra',
    case
      when (v_payload->>'ok')::boolean = true
       and (v_payload->>'empresa_id')::uuid = current_setting('app.pme16d.empresa_a', true)::uuid
       and (v_payload->>'corretor_id')::uuid = current_setting('app.pme16d.owner_corretor', true)::uuid
      then 'PASS'
      else 'FAIL'
    end,
    v_payload
  );
exception when others then
  perform pg_temp.pme16d_add_result(
    '02_owner_mesma_empresa_registra',
    'FAIL',
    jsonb_build_object('message', sqlerrm, 'sqlstate', sqlstate)
  );
end;
$$;

-- =========================================================
-- 03. Outro corretor da mesma empresa registra uso positivo
--     Regra validada: escopo atual é empresa, não ownership exclusivo do lead.
-- =========================================================

do $$
declare
  v_payload jsonb;
begin
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16d.outro_mesma_empresa_user', true), true);

  v_payload := public.pme_registrar_message_usage(
    current_setting('app.pme16d.lead_a', true)::uuid,
    jsonb_build_object(
      'template_id', current_setting('app.pme16d.template_a', true),
      'channel', 'whatsapp',
      'lead_type', 'lista_fria',
      'phase', 'primeira_mensagem',
      'selection_mode', 'manual',
      'status', 'copied',
      'feedback_key', 'teste_16d_mesma_empresa_positive',
      'metadata', jsonb_build_object('origem', 'teste_16d_mesma_empresa_positive')
    )
  );

  perform pg_temp.pme16d_add_result(
    '03_outro_corretor_mesma_empresa_registra',
    case
      when (v_payload->>'ok')::boolean = true
       and (v_payload->>'empresa_id')::uuid = current_setting('app.pme16d.empresa_a', true)::uuid
       and (v_payload->>'corretor_id')::uuid = current_setting('app.pme16d.outro_mesma_empresa_corretor', true)::uuid
      then 'PASS'
      else 'FAIL'
    end,
    v_payload || jsonb_build_object(
      'interpretacao', 'escopo_atual_por_empresa_nao_por_owner_exclusivo_do_lead'
    )
  );
exception when others then
  perform pg_temp.pme16d_add_result(
    '03_outro_corretor_mesma_empresa_registra',
    'FAIL',
    jsonb_build_object('message', sqlerrm, 'sqlstate', sqlstate)
  );
end;
$$;

-- =========================================================
-- 04. Usuário de outra empresa bloqueado no lead da empresa A
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16d.cross_user', true), true);

  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16d.lead_a', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16d.template_a', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );

    perform pg_temp.pme16d_add_result(
      '04_cross_tenant_user_bloqueado',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_aceitou_usuario_de_outra_empresa')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16d_add_result(
      '04_cross_tenant_user_bloqueado',
      case when v_message = 'pme_scope_denied' and v_state = '42501' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;
end;
$$;

-- =========================================================
-- 05. Template de outra empresa bloqueado com lead válido da empresa A
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16d.owner_user', true), true);

  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16d.lead_a', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16d.template_b', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );

    perform pg_temp.pme16d_add_result(
      '05_template_cross_tenant_bloqueado',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_aceitou_template_de_outra_empresa')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16d_add_result(
      '05_template_cross_tenant_bloqueado',
      case when v_message = 'template_scope_denied_or_not_found' and v_state = '42501' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;
end;
$$;

-- =========================================================
-- 06. Lead inexistente bloqueado
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  perform set_config('request.jwt.claim.sub', current_setting('app.pme16d.owner_user', true), true);

  begin
    perform public.pme_registrar_message_usage(
      gen_random_uuid(),
      jsonb_build_object(
        'template_id', current_setting('app.pme16d.template_a', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );

    perform pg_temp.pme16d_add_result(
      '06_lead_inexistente_bloqueado',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_aceitou_lead_inexistente')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16d_add_result(
      '06_lead_inexistente_bloqueado',
      case when v_message = 'lead_not_found' and v_state = 'P0002' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;
end;
$$;

-- =========================================================
-- 07. RLS ativo nas tabelas PME envolvidas
-- =========================================================

select pg_temp.pme16d_add_result(
  '07_rls_tabelas_pme_ativo',
  case
    when bool_and(c.relrowsecurity) then 'PASS'
    else 'FAIL'
  end,
  coalesce(jsonb_agg(jsonb_build_object(
    'relname', c.relname,
    'rls_ativo', c.relrowsecurity
  ) order by c.relname), '[]'::jsonb)
)
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('pme_message_usage', 'pme_message_templates');

-- =========================================================
-- 08. Cardinalidade: só os 2 positivos devem existir na transação
-- =========================================================

select pg_temp.pme16d_add_result(
  '08_cardinalidade_sem_mutacao_cross_tenant',
  case
    when (
      select count(*)
      from public.pme_message_usage u
      where u.lead_id = current_setting('app.pme16d.lead_a', true)::uuid
    ) = current_setting('app.pme16d.usage_count_before', true)::int + 2
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'usage_count_before', current_setting('app.pme16d.usage_count_before', true)::int,
    'usage_count_after', (
      select count(*)
      from public.pme_message_usage u
      where u.lead_id = current_setting('app.pme16d.lead_a', true)::uuid
    ),
    'positivos_esperados', 2,
    'negativos_bloqueados_esperados', 3,
    'lead_a', current_setting('app.pme16d.lead_a', true)
  )
);

-- =========================================================
-- 99. Saída única e rollback
-- =========================================================

select pg_temp.pme16d_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
    'teste', '16D',
    'ddl_persistente', false,
    'dml_fixture', true,
    'rollback', true,
    'mensagem', 'Teste 16D encerra com ROLLBACK. Fixtures e usos PME da transação não devem permanecer no banco.',
    'validacao', 'escopo/RLS/cross-tenant da RPC pme_registrar_message_usage'
  )
);

select jsonb_pretty(current_setting('app.pme16d.results', true)::jsonb) as resultado_16d;

rollback;
