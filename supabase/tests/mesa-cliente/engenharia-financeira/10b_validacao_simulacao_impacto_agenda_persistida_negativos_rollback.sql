-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5A.1
-- 10B — Validações negativas da RPC agenda-first de simulação de impacto.
--
-- Objetivo:
--   Validar bloqueios principais da RPC 5A.1:
--     - anon sem execute;
--     - sem auth;
--     - simulação inexistente;
--     - empresa_id no payload;
--     - valor negativo;
--     - modo inválido;
--     - agenda inexistente.
--
-- Nota técnica:
--   Este teste troca role para authenticated para simular execução real via Supabase.
--   Não usa temp table para armazenar resultados, porque temp table + SET LOCAL ROLE
--   pode gerar erro de permissão ou resolução de schema no SQL Editor.
--   Os resultados são acumulados em uma variável transacional via set_config(...).

begin;

select set_config('app.mc10b.results', '[]', true);
select set_config('app.mc10b.simulacao_id', '', true);
select set_config('app.mc10b.empresa_id', '', true);

-- 01: anon não pode executar a RPC.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc10b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  if has_function_privilege('anon', 'public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)'::regprocedure, 'EXECUTE') then
    v_item := jsonb_build_object('bloco', '01_grant_anon_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('anon_can_execute', true));
  else
    v_item := jsonb_build_object('bloco', '01_grant_anon_bloqueado', 'status', 'PASS', 'detalhe', jsonb_build_object('anon_can_execute', false));
  end if;

  perform set_config('app.mc10b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 02: chamada sem auth deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc10b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform set_config('request.jwt.claim.sub', '', true);
  perform public.mesa_cliente_simular_impacto_agenda_persistida_admin(gen_random_uuid(), current_date, 'melhor_aplicacao', jsonb_build_object('valor_disponivel', 1000));
  v_item := jsonb_build_object('bloco', '02_sem_auth_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'chamada sem auth não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '02_sem_auth_bloqueado', 'status', case when sqlstate = '28000' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc10b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- Seleciona usuário administrativo real para os testes com authenticated.
with candidato as materialized (
  select c.user_id
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'admin_local', 'gestor')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by case when c.role = 'admin_global' then 1 when c.role = 'admin_local' then 2 when c.role = 'gestor' then 3 else 4 end,
           c.created_at desc nulls last,
           c.id
  limit 1
)
select set_config('request.jwt.claim.sub', user_id::text, true)
from candidato;

set local role authenticated;

-- 03: simulação inexistente deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc10b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  perform public.mesa_cliente_simular_impacto_agenda_persistida_admin(gen_random_uuid(), current_date, 'melhor_aplicacao', jsonb_build_object('valor_disponivel', 1000));
  v_item := jsonb_build_object('bloco', '03_simulacao_inexistente_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'simulação inexistente não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '03_simulacao_inexistente_bloqueada', 'status', case when sqlstate = 'P0002' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc10b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- Fixture mínima sem agenda para testar bloqueio de agenda inexistente e validações de payload.
reset role;

with candidato as materialized (
  select c.user_id, c.id as corretor_id, c.empresa_id, e.id as empreendimento_id
  from public.corretores c
  join public.empreendimentos e on e.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'admin_local', 'gestor')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by case when c.role = 'admin_global' then 1 when c.role = 'admin_local' then 2 when c.role = 'gestor' then 3 else 4 end,
           c.created_at desc nulls last,
           c.id
  limit 1
),
s as materialized (
  insert into public.mesa_simulacoes (
    empresa_id,
    corretor_id,
    empreendimento_id,
    cliente_nome,
    valor_total,
    entrada,
    financiamento,
    valor_final,
    snapshot_payload,
    observacoes
  )
  select empresa_id, corretor_id, empreendimento_id, 'Teste rollback 10B negativos', 10000, 1000, 0, 10000, jsonb_build_object('origem','teste_10b'), 'Fixture 10B sem agenda ativa.'
  from candidato
  returning id, empresa_id, empreendimento_id
),
setup as (
  select
    set_config('app.mc10b.simulacao_id', s.id::text, true),
    set_config('app.mc10b.empresa_id', s.empresa_id::text, true),
    set_config('request.jwt.claim.sub', c.user_id::text, true)
  from candidato c
  join s on true
)
select count(*) from setup;

set local role authenticated;

-- 04: empresa_id no payload deve bloquear antes de qualquer leitura de agenda.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc10b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
  v_sim uuid := current_setting('app.mc10b.simulacao_id', true)::uuid;
begin
  perform public.mesa_cliente_simular_impacto_agenda_persistida_admin(v_sim, current_date, 'melhor_aplicacao', jsonb_build_object('empresa_id', gen_random_uuid(), 'valor_disponivel', 1000));
  v_item := jsonb_build_object('bloco', '04_empresa_id_payload_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'empresa_id no payload não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '04_empresa_id_payload_bloqueado', 'status', case when sqlstate = '42501' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc10b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 05: valor negativo deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc10b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
  v_sim uuid := current_setting('app.mc10b.simulacao_id', true)::uuid;
begin
  perform public.mesa_cliente_simular_impacto_agenda_persistida_admin(v_sim, current_date, 'melhor_aplicacao', jsonb_build_object('valor_disponivel', -100));
  v_item := jsonb_build_object('bloco', '05_valor_negativo_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'valor negativo não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '05_valor_negativo_bloqueado', 'status', case when sqlstate = '22023' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc10b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 06: modo inválido deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc10b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
  v_sim uuid := current_setting('app.mc10b.simulacao_id', true)::uuid;
begin
  perform public.mesa_cliente_simular_impacto_agenda_persistida_admin(v_sim, current_date, 'modo_invalido', jsonb_build_object('valor_disponivel', 1000));
  v_item := jsonb_build_object('bloco', '06_modo_invalido_bloqueado', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'modo inválido não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '06_modo_invalido_bloqueado', 'status', case when sqlstate = '22023' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc10b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

-- 07: simulação válida sem agenda ativa deve bloquear.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc10b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
  v_sim uuid := current_setting('app.mc10b.simulacao_id', true)::uuid;
begin
  perform public.mesa_cliente_simular_impacto_agenda_persistida_admin(v_sim, current_date, 'melhor_aplicacao', jsonb_build_object('valor_disponivel', 1000));
  v_item := jsonb_build_object('bloco', '07_agenda_inexistente_bloqueada', 'status', 'FAIL', 'detalhe', jsonb_build_object('erro', 'agenda inexistente não bloqueou'));
exception when others then
  v_item := jsonb_build_object('bloco', '07_agenda_inexistente_bloqueada', 'status', case when sqlstate = 'P0002' then 'PASS' else 'FAIL' end, 'detalhe', jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm));
  perform set_config('app.mc10b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

reset role;

-- 99: aviso de rollback.
do $$
declare
  v_results jsonb := coalesce(nullif(current_setting('app.mc10b.results', true), '')::jsonb, '[]'::jsonb);
  v_item jsonb;
begin
  v_item := jsonb_build_object('bloco', '99_rollback_notice', 'status', 'INFO', 'detalhe', jsonb_build_object('mensagem', 'Teste 10B encerra com ROLLBACK. Nada deve permanecer no banco.'));
  perform set_config('app.mc10b.results', (v_results || jsonb_build_array(v_item))::text, true);
end $$;

select
  item->>'bloco' as bloco,
  item->>'status' as status,
  item->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc10b.results', true)::jsonb) with ordinality as r(item, ord)
order by ord;

rollback;
