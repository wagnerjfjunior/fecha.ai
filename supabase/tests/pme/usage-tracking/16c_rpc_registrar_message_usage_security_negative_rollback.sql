-- FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8
-- 16C — Segurança negativa da RPC pme_registrar_message_usage com ROLLBACK
--
-- Objetivo:
--   Validar bloqueios de segurança da RPC:
--     public.pme_registrar_message_usage(uuid, jsonb)
--
-- Escopo validado:
--   1. bloqueio sem autenticação;
--   2. bloqueio de autoridade soberana enviada pelo frontend;
--   3. bloqueio de payload não objeto;
--   4. bloqueio de referência ausente;
--   5. bloqueio de channel inválido;
--   6. bloqueio de lead_type inválido;
--   7. bloqueio de status inválido;
--   8. ausência de mutação indevida em public.pme_message_usage.
--
-- Segurança do teste:
--   - fixture transacional mínima;
--   - sem IDs hardcoded;
--   - sem DDL persistente;
--   - sem alteração permanente;
--   - encerra obrigatoriamente com ROLLBACK.

begin;

select set_config('app.pme16c.results', '[]', true);
select set_config('app.pme16c.user_id', '', true);
select set_config('app.pme16c.corretor_id', '', true);
select set_config('app.pme16c.empresa_id', '', true);
select set_config('app.pme16c.lead_id', '', true);
select set_config('app.pme16c.template_id', '', true);
select set_config('app.pme16c.usage_count_before', '0', true);
select set_config('request.jwt.claim.sub', '', true);

create or replace function pg_temp.pme16c_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.pme16c.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.pme16c.results',
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
-- 00. Fixture autenticada mínima: usuário, lead e template válidos
-- =========================================================

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
    c.is_gestor,
    c.is_admin_local
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
      when c.role = 'corretor' then 1
      when c.role = 'gestor' then 2
      when c.role = 'admin_local' then 3
      when c.role = 'admin_global' then 4
      else 5
    end,
    c.created_at desc nulls last,
    c.id
  limit 1
)
select
  set_config('app.pme16c.user_id', user_id::text, true),
  set_config('app.pme16c.corretor_id', corretor_id::text, true),
  set_config('app.pme16c.empresa_id', empresa_id::text, true)
from candidato;

select set_config('request.jwt.claim.sub', current_setting('app.pme16c.user_id', true), true);

with lead_fixture as materialized (
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
    current_setting('app.pme16c.empresa_id', true)::uuid,
    current_setting('app.pme16c.corretor_id', true)::uuid,
    'Teste rollback 16C PME Usage Tracking',
    'teste.16c.pme@example.invalid',
    '11999999998',
    '11999999998',
    '+5511999999998',
    'distribuido',
    'lista',
    'fixture_16c_pme',
    'Fixture transacional 16C. Deve sumir no ROLLBACK.'
  )
  returning id, empresa_id, corretor_id
), template_fixture as materialized (
  insert into public.pme_message_templates (
    empresa_id,
    channel,
    lead_type,
    phase,
    tone,
    title,
    objective,
    body,
    variables,
    weight,
    is_active,
    is_seed,
    seed_key,
    created_by,
    updated_by
  ) values (
    current_setting('app.pme16c.empresa_id', true)::uuid,
    'whatsapp',
    'lista_fria',
    'primeira_mensagem',
    'consultivo',
    'Template rollback 16C PME',
    'Validar bloqueios negativos da RPC PME em fixture transacional.',
    'Olá, {{nome}}. Template válido para testes negativos de segurança.',
    '["nome"]'::jsonb,
    1,
    true,
    false,
    'fixture_16c_' || replace(gen_random_uuid()::text, '-', ''),
    current_setting('app.pme16c.corretor_id', true)::uuid,
    current_setting('app.pme16c.corretor_id', true)::uuid
  )
  returning id, empresa_id
)
select
  set_config('app.pme16c.lead_id', lf.id::text, true),
  set_config('app.pme16c.template_id', tf.id::text, true)
from lead_fixture lf
cross join template_fixture tf;

select set_config(
  'app.pme16c.usage_count_before',
  (
    select count(*)::text
    from public.pme_message_usage u
    where u.lead_id = current_setting('app.pme16c.lead_id', true)::uuid
  ),
  true
);

select pg_temp.pme16c_add_result(
  '00_setup_fixture_negativa',
  case
    when nullif(current_setting('app.pme16c.user_id', true), '') is not null
     and nullif(current_setting('app.pme16c.corretor_id', true), '') is not null
     and nullif(current_setting('app.pme16c.empresa_id', true), '') is not null
     and nullif(current_setting('app.pme16c.lead_id', true), '') is not null
     and nullif(current_setting('app.pme16c.template_id', true), '') is not null
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'user_id', nullif(current_setting('app.pme16c.user_id', true), ''),
    'empresa_id', nullif(current_setting('app.pme16c.empresa_id', true), ''),
    'corretor_id', nullif(current_setting('app.pme16c.corretor_id', true), ''),
    'lead_id', nullif(current_setting('app.pme16c.lead_id', true), ''),
    'template_id', nullif(current_setting('app.pme16c.template_id', true), ''),
    'usage_count_before', current_setting('app.pme16c.usage_count_before', true)::int
  )
);

-- =========================================================
-- 01. Bloqueio sem autenticação
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  perform set_config('request.jwt.claim.sub', '', true);

  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16c.lead_id', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16c.template_id', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );

    perform pg_temp.pme16c_add_result(
      '01_bloqueio_sem_auth',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_executou_sem_auth')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16c_add_result(
      '01_bloqueio_sem_auth',
      case when v_message = 'auth_required' and v_state = '28000' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;

  perform set_config('request.jwt.claim.sub', current_setting('app.pme16c.user_id', true), true);
end;
$$;

-- =========================================================
-- 02. Bloqueio de autoridade soberana enviada pelo frontend
-- =========================================================

do $$
declare
  v_key text;
  v_message text;
  v_state text;
  v_pass_count int := 0;
  v_fail_count int := 0;
  v_details jsonb := '[]'::jsonb;
  v_payload jsonb;
begin
  foreach v_key in array array['empresa_id','tenant_id','corretor_id','user_id','created_by','updated_by']
  loop
    v_payload := jsonb_build_object(
      'template_id', current_setting('app.pme16c.template_id', true),
      'channel', 'whatsapp',
      'lead_type', 'lista_fria',
      'phase', 'primeira_mensagem',
      'status', 'copied'
    ) || jsonb_build_object(v_key, gen_random_uuid()::text);

    begin
      perform public.pme_registrar_message_usage(
        current_setting('app.pme16c.lead_id', true)::uuid,
        v_payload
      );

      v_fail_count := v_fail_count + 1;
      v_details := v_details || jsonb_build_array(jsonb_build_object(
        'key', v_key,
        'status', 'FAIL',
        'message', 'rpc_aceitou_autoridade_frontend',
        'sqlstate', null
      ));
    exception when others then
      get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

      if v_message = 'frontend_authority_forbidden' and v_state = '42501' then
        v_pass_count := v_pass_count + 1;
        v_details := v_details || jsonb_build_array(jsonb_build_object(
          'key', v_key,
          'status', 'PASS',
          'message', v_message,
          'sqlstate', v_state
        ));
      else
        v_fail_count := v_fail_count + 1;
        v_details := v_details || jsonb_build_array(jsonb_build_object(
          'key', v_key,
          'status', 'FAIL',
          'message', v_message,
          'sqlstate', v_state
        ));
      end if;
    end;
  end loop;

  perform pg_temp.pme16c_add_result(
    '02_bloqueio_parametros_soberanos_frontend',
    case when v_fail_count = 0 and v_pass_count = 6 then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'pass_count', v_pass_count,
      'fail_count', v_fail_count,
      'detalhes', v_details
    )
  );
end;
$$;

-- =========================================================
-- 03. Bloqueio de payload não objeto
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16c.lead_id', true)::uuid,
      '[]'::jsonb
    );

    perform pg_temp.pme16c_add_result(
      '03_bloqueio_payload_nao_objeto',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_aceitou_payload_array')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16c_add_result(
      '03_bloqueio_payload_nao_objeto',
      case when v_message = 'p_payload_must_be_object' and v_state = '22023' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;
end;
$$;

-- =========================================================
-- 04. Bloqueio de referência ausente
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16c.lead_id', true)::uuid,
      jsonb_build_object(
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );

    perform pg_temp.pme16c_add_result(
      '04_bloqueio_referencia_ausente',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_aceitou_usage_sem_referencia')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16c_add_result(
      '04_bloqueio_referencia_ausente',
      case when v_message = 'usage_reference_required' and v_state = '22023' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;
end;
$$;

-- =========================================================
-- 05. Bloqueio de channel inválido
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16c.lead_id', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16c.template_id', true),
        'channel', 'sms',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );

    perform pg_temp.pme16c_add_result(
      '05_bloqueio_channel_invalido',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_aceitou_channel_invalido')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16c_add_result(
      '05_bloqueio_channel_invalido',
      case when v_message = 'invalid_channel' and v_state = '22023' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;
end;
$$;

-- =========================================================
-- 06. Bloqueio de lead_type inválido
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16c.lead_id', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16c.template_id', true),
        'channel', 'whatsapp',
        'lead_type', 'lead_misterioso',
        'phase', 'primeira_mensagem',
        'status', 'copied'
      )
    );

    perform pg_temp.pme16c_add_result(
      '06_bloqueio_lead_type_invalido',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_aceitou_lead_type_invalido')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16c_add_result(
      '06_bloqueio_lead_type_invalido',
      case when v_message = 'invalid_lead_type' and v_state = '22023' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;
end;
$$;

-- =========================================================
-- 07. Bloqueio de status inválido
-- =========================================================

do $$
declare
  v_message text;
  v_state text;
begin
  begin
    perform public.pme_registrar_message_usage(
      current_setting('app.pme16c.lead_id', true)::uuid,
      jsonb_build_object(
        'template_id', current_setting('app.pme16c.template_id', true),
        'channel', 'whatsapp',
        'lead_type', 'lista_fria',
        'phase', 'primeira_mensagem',
        'status', 'enviado_pelo_robo_sem_permissao'
      )
    );

    perform pg_temp.pme16c_add_result(
      '07_bloqueio_status_invalido',
      'FAIL',
      jsonb_build_object('motivo', 'rpc_aceitou_status_invalido')
    );
  exception when others then
    get stacked diagnostics v_message = message_text, v_state = returned_sqlstate;

    perform pg_temp.pme16c_add_result(
      '07_bloqueio_status_invalido',
      case when v_message = 'invalid_status' and v_state = '22023' then 'PASS' else 'FAIL' end,
      jsonb_build_object('message', v_message, 'sqlstate', v_state)
    );
  end;
end;
$$;

-- =========================================================
-- 08. Ausência de mutação indevida em pme_message_usage
-- =========================================================

select pg_temp.pme16c_add_result(
  '08_sem_mutacao_usage_tentativas_negativas',
  case
    when (
      select count(*)
      from public.pme_message_usage u
      where u.lead_id = current_setting('app.pme16c.lead_id', true)::uuid
    ) = current_setting('app.pme16c.usage_count_before', true)::int
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'usage_count_before', current_setting('app.pme16c.usage_count_before', true)::int,
    'usage_count_after', (
      select count(*)
      from public.pme_message_usage u
      where u.lead_id = current_setting('app.pme16c.lead_id', true)::uuid
    ),
    'lead_id', current_setting('app.pme16c.lead_id', true)
  )
);

-- =========================================================
-- 99. Saída única e rollback
-- =========================================================

select pg_temp.pme16c_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
    'teste', '16C',
    'ddl_persistente', false,
    'dml_fixture', true,
    'rollback', true,
    'mensagem', 'Teste 16C encerra com ROLLBACK. Fixture e tentativas negativas não devem permanecer no banco.',
    'validacao', 'seguranca negativa da RPC pme_registrar_message_usage'
  )
);

select jsonb_pretty(current_setting('app.pme16c.results', true)::jsonb) as resultado_16c;

rollback;
