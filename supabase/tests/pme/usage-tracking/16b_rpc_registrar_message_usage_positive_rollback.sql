-- FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8
-- 16B — RPC positiva de registro append-only de uso PME com ROLLBACK
--
-- Objetivo:
--   Validar funcionalmente a RPC:
--     public.pme_registrar_message_usage(uuid, jsonb)
--
-- Escopo validado:
--   1. contexto autenticado elegível via request.jwt.claim.sub;
--   2. lead válido de empresa existente;
--   3. template PME válido na mesma empresa;
--   4. empresa_id derivado do banco, nunca do frontend;
--   5. corretor_id derivado do contexto autenticado via public.my_corretor_id();
--   6. inserção controlada em public.pme_message_usage;
--   7. retorno ok=true / append_only=true / dml=true;
--   8. payload persistido dentro da transação;
--   9. encerramento com ROLLBACK.
--
-- Segurança do teste:
--   - fixture transacional mínima;
--   - não depende de IDs hardcoded;
--   - não executa DDL;
--   - não altera dados permanentes;
--   - encerra obrigatoriamente com ROLLBACK.

begin;

select set_config('app.pme16b.results', '[]', true);
select set_config('app.pme16b.user_id', '', true);
select set_config('app.pme16b.corretor_id', '', true);
select set_config('app.pme16b.empresa_id', '', true);
select set_config('app.pme16b.lead_id', '', true);
select set_config('app.pme16b.template_id', '', true);
select set_config('app.pme16b.usage_id', '', true);
select set_config('app.pme16b.rpc_payload', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

create or replace function pg_temp.pme16b_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.pme16b.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.pme16b.results',
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
-- 00. Seleção de usuário operacional elegível
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
  set_config('app.pme16b.user_id', user_id::text, true),
  set_config('app.pme16b.corretor_id', corretor_id::text, true),
  set_config('app.pme16b.empresa_id', empresa_id::text, true)
from candidato;

select pg_temp.pme16b_add_result(
  '00_contexto_auth_fixture',
  case
    when nullif(current_setting('app.pme16b.user_id', true), '') is not null
     and nullif(current_setting('app.pme16b.corretor_id', true), '') is not null
     and nullif(current_setting('app.pme16b.empresa_id', true), '') is not null
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'user_id', nullif(current_setting('app.pme16b.user_id', true), ''),
    'corretor_id', nullif(current_setting('app.pme16b.corretor_id', true), ''),
    'empresa_id', nullif(current_setting('app.pme16b.empresa_id', true), '')
  )
);

-- Simula usuário autenticado da fixture.
select set_config('request.jwt.claim.sub', current_setting('app.pme16b.user_id', true), true);

-- =========================================================
-- 01. Fixture de lead e template PME
-- =========================================================

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
    current_setting('app.pme16b.empresa_id', true)::uuid,
    current_setting('app.pme16b.corretor_id', true)::uuid,
    'Teste rollback 16B PME Usage Tracking',
    'teste.16b.pme@example.invalid',
    '11999999999',
    '11999999999',
    '+5511999999999',
    'em_atendimento',
    'lista',
    'fixture_16b_pme',
    'Fixture transacional 16B. Deve sumir no ROLLBACK.'
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
    current_setting('app.pme16b.empresa_id', true)::uuid,
    'whatsapp',
    'lista_fria',
    'primeira_mensagem',
    'consultivo',
    'Template rollback 16B PME',
    'Validar uso positivo da RPC PME em fixture transacional.',
    'Olá, {{nome}}. Vi seu interesse e posso te ajudar com as melhores opções disponíveis.',
    '["nome"]'::jsonb,
    1,
    true,
    false,
    'fixture_16b_' || replace(gen_random_uuid()::text, '-', ''),
    current_setting('app.pme16b.corretor_id', true)::uuid,
    current_setting('app.pme16b.corretor_id', true)::uuid
  )
  returning id, empresa_id
)
select
  set_config('app.pme16b.lead_id', lf.id::text, true),
  set_config('app.pme16b.template_id', tf.id::text, true)
from lead_fixture lf
cross join template_fixture tf;

select pg_temp.pme16b_add_result(
  '01_fixture_lead_template',
  case
    when nullif(current_setting('app.pme16b.lead_id', true), '') is not null
     and nullif(current_setting('app.pme16b.template_id', true), '') is not null
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'lead_id', nullif(current_setting('app.pme16b.lead_id', true), ''),
    'template_id', nullif(current_setting('app.pme16b.template_id', true), ''),
    'empresa_id', current_setting('app.pme16b.empresa_id', true),
    'corretor_id', current_setting('app.pme16b.corretor_id', true)
  )
);

-- =========================================================
-- 02. Execução positiva da RPC
-- =========================================================

with rpc as materialized (
  select public.pme_registrar_message_usage(
    current_setting('app.pme16b.lead_id', true)::uuid,
    jsonb_build_object(
      'template_id', current_setting('app.pme16b.template_id', true),
      'channel', 'whatsapp',
      'lead_type', 'lista_fria',
      'phase', 'primeira_mensagem',
      'selection_mode', 'suggested',
      'status', 'copied',
      'rendered_body', 'Olá, Teste rollback 16B. Posso te ajudar com as melhores opções disponíveis.',
      'feedback_key', 'teste_16b_positive',
      'metadata', jsonb_build_object(
        'origem', 'teste_16b_pme_usage_tracking',
        'fixture_transacional', true,
        'frontend_sem_autoridade_soberana', true
      )
    )
  ) as payload
)
select
  set_config('app.pme16b.rpc_payload', payload::text, true),
  set_config('app.pme16b.usage_id', payload->>'usage_id', true)
from rpc;

select pg_temp.pme16b_add_result(
  '02_rpc_registrar_usage_basico',
  case
    when (current_setting('app.pme16b.rpc_payload', true)::jsonb ->> 'ok')::boolean = true
     and (current_setting('app.pme16b.rpc_payload', true)::jsonb ->> 'append_only')::boolean = true
     and (current_setting('app.pme16b.rpc_payload', true)::jsonb ->> 'dml')::boolean = true
     and current_setting('app.pme16b.rpc_payload', true)::jsonb ->> 'fase' = 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC'
    then 'PASS'
    else 'FAIL'
  end,
  current_setting('app.pme16b.rpc_payload', true)::jsonb
);

-- =========================================================
-- 03. Validação de soberania: empresa_id/corretor_id derivados do banco
-- =========================================================

select pg_temp.pme16b_add_result(
  '03_soberania_empresa_corretor_derivados',
  case
    when (current_setting('app.pme16b.rpc_payload', true)::jsonb ->> 'empresa_id')::uuid = current_setting('app.pme16b.empresa_id', true)::uuid
     and (current_setting('app.pme16b.rpc_payload', true)::jsonb ->> 'corretor_id')::uuid = current_setting('app.pme16b.corretor_id', true)::uuid
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'empresa_id_esperado', current_setting('app.pme16b.empresa_id', true),
    'empresa_id_rpc', current_setting('app.pme16b.rpc_payload', true)::jsonb ->> 'empresa_id',
    'corretor_id_esperado', current_setting('app.pme16b.corretor_id', true),
    'corretor_id_rpc', current_setting('app.pme16b.rpc_payload', true)::jsonb ->> 'corretor_id'
  )
);

-- =========================================================
-- 04. Validação da linha append-only criada dentro da transação
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
  where u.id = current_setting('app.pme16b.usage_id', true)::uuid
)
select pg_temp.pme16b_add_result(
  '04_usage_persistido_na_transacao',
  case
    when count(*) = 1
     and bool_and(empresa_id = current_setting('app.pme16b.empresa_id', true)::uuid)
     and bool_and(lead_id = current_setting('app.pme16b.lead_id', true)::uuid)
     and bool_and(corretor_id = current_setting('app.pme16b.corretor_id', true)::uuid)
     and bool_and(template_id = current_setting('app.pme16b.template_id', true)::uuid)
     and bool_and(channel = 'whatsapp')
     and bool_and(lead_type = 'lista_fria')
     and bool_and(phase = 'primeira_mensagem')
     and bool_and(selection_mode = 'suggested')
     and bool_and(status = 'copied')
     and bool_and(feedback_key = 'teste_16b_positive')
     and bool_and(metadata->>'fixture_transacional' = 'true')
    then 'PASS'
    else 'FAIL'
  end,
  coalesce(
    jsonb_agg(jsonb_build_object(
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
    )),
    '[]'::jsonb
  )
)
from usage_row;

-- =========================================================
-- 05. Validação de cardinalidade: 1 uso para a fixture
-- =========================================================

select pg_temp.pme16b_add_result(
  '05_cardinalidade_usage_fixture',
  case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'usage_count_fixture', count(*),
    'lead_id', current_setting('app.pme16b.lead_id', true),
    'template_id', current_setting('app.pme16b.template_id', true)
  )
)
from public.pme_message_usage u
where u.lead_id = current_setting('app.pme16b.lead_id', true)::uuid
  and u.template_id = current_setting('app.pme16b.template_id', true)::uuid;

-- =========================================================
-- 99. Saída única e rollback
-- =========================================================

select pg_temp.pme16b_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
    'teste', '16B',
    'ddl', false,
    'dml_fixture', true,
    'rollback', true,
    'mensagem', 'Teste 16B encerra com ROLLBACK. Lead, template e uso PME não devem permanecer no banco.',
    'validacao', 'RPC positiva pme_registrar_message_usage com append-only transacional'
  )
);

select jsonb_pretty(current_setting('app.pme16b.results', true)::jsonb) as resultado_16b;

rollback;
