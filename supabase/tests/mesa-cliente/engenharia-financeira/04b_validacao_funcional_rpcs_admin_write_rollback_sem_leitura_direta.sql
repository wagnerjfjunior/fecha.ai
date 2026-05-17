-- MesaCliente Engenharia Financeira — 04B Validação funcional RPCs admin com ROLLBACK
-- Versão compatível com produção única: após SET LOCAL ROLE authenticated,
-- não lê tabelas base diretamente. IDs necessários são coletados antes.

begin;

with admin_candidate as materialized (
  select c.user_id, c.id as corretor_id, c.empresa_id, c.role, coalesce(c.ativo, true) as ativo
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'admin_local', 'gestor')
      or coalesce(c.is_admin_local, false) = true
      or coalesce(c.is_gestor, false) = true
    )
  order by case c.role when 'admin_global' then 1 when 'admin_local' then 2 when 'gestor' then 3 else 4 end,
           c.created_at nulls last,
           c.id
  limit 1
), empreendimento_candidate as materialized (
  select e.id as empreendimento_id, e.empresa_id, e.nome as empreendimento_nome
  from public.empreendimentos e
  join admin_candidate ac on ac.empresa_id = e.empresa_id
  order by e.created_at nulls last, e.id
  limit 1
), conflito_mes_teste as materialized (
  select count(*) as qtd_conflitos
  from public.mesa_cliente_politicas_financeiras p
  join empreendimento_candidate ec on ec.empreendimento_id = p.empreendimento_id
  where p.empresa_id = ec.empresa_id
    and p.mes_referencia = date '2099-01-01'
), seed as (
  select ac.*, ec.empreendimento_id, ec.empreendimento_nome, coalesce(cmt.qtd_conflitos, 0) as qtd_conflitos
  from admin_candidate ac
  left join empreendimento_candidate ec on true
  left join conflito_mes_teste cmt on true
)
select
  set_config('request.jwt.claim.sub', coalesce(seed.user_id::text, '00000000-0000-0000-0000-000000000000'), true),
  set_config('app.mc_test.user_id', coalesce(seed.user_id::text, ''), true),
  set_config('app.mc_test.corretor_id', coalesce(seed.corretor_id::text, ''), true),
  set_config('app.mc_test.empresa_id', coalesce(seed.empresa_id::text, ''), true),
  set_config('app.mc_test.role', coalesce(seed.role::text, ''), true),
  set_config('app.mc_test.ativo', coalesce(seed.ativo::text, 'false'), true),
  set_config('app.mc_test.qtd_ctx', case when seed.user_id is not null then '1' else '0' end, true),
  set_config('app.mc_test.empreendimento_id', coalesce(seed.empreendimento_id::text, ''), true),
  set_config('app.mc_test.empreendimento_nome', coalesce(seed.empreendimento_nome::text, ''), true),
  set_config('app.mc_test.qtd_conflitos', coalesce(seed.qtd_conflitos::text, '0'), true)
from seed;

select set_config('request.jwt.claim.sub', coalesce(nullif(current_setting('request.jwt.claim.sub', true), ''), '00000000-0000-0000-0000-000000000000'), true);
select set_config('app.mc_test.user_id', coalesce(current_setting('app.mc_test.user_id', true), ''), true);
select set_config('app.mc_test.corretor_id', coalesce(current_setting('app.mc_test.corretor_id', true), ''), true);
select set_config('app.mc_test.empresa_id', coalesce(current_setting('app.mc_test.empresa_id', true), ''), true);
select set_config('app.mc_test.role', coalesce(current_setting('app.mc_test.role', true), ''), true);
select set_config('app.mc_test.ativo', coalesce(nullif(current_setting('app.mc_test.ativo', true), ''), 'false'), true);
select set_config('app.mc_test.qtd_ctx', coalesce(nullif(current_setting('app.mc_test.qtd_ctx', true), ''), '0'), true);
select set_config('app.mc_test.empreendimento_id', coalesce(current_setting('app.mc_test.empreendimento_id', true), ''), true);
select set_config('app.mc_test.empreendimento_nome', coalesce(current_setting('app.mc_test.empreendimento_nome', true), ''), true);
select set_config('app.mc_test.qtd_conflitos', coalesce(nullif(current_setting('app.mc_test.qtd_conflitos', true), ''), '0'), true);

set local role authenticated;

with pode_executar as materialized (
  select
    nullif(current_setting('app.mc_test.user_id', true), '')::uuid as user_id,
    nullif(current_setting('app.mc_test.corretor_id', true), '')::uuid as corretor_id,
    nullif(current_setting('app.mc_test.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc_test.role', true), '')::text as role,
    coalesce(nullif(current_setting('app.mc_test.ativo', true), '')::boolean, false) as ativo,
    coalesce(nullif(current_setting('app.mc_test.qtd_ctx', true), '')::integer, 0) as qtd_ctx,
    nullif(current_setting('app.mc_test.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc_test.empreendimento_nome', true), '')::text as empreendimento_nome,
    coalesce(nullif(current_setting('app.mc_test.qtd_conflitos', true), '')::integer, 0) as qtd_conflitos,
    case when nullif(current_setting('app.mc_test.empresa_id', true), '') is not null
      then public.mesa_cliente_can_admin_empresa(nullif(current_setting('app.mc_test.empresa_id', true), '')::uuid)
      else false end as can_admin_empresa
), upsert_politica as materialized (
  select case when pe.qtd_ctx = 1 and pe.ativo and pe.can_admin_empresa and pe.empreendimento_id is not null and pe.qtd_conflitos = 0
    then public.mesa_cliente_upsert_politica_financeira(
      pe.empresa_id, pe.empreendimento_id, date '2099-01-15', date '2099-01-01', date '2099-01-31',
      6.00, 12.00, 12.00, 'composto', 'dias_365',
      false, true, true, true, false, true, true, true, false, true, true, true, true,
      'TESTE TRANSACIONAL FECH.AI — rollback automático'
    ) else null::jsonb end as payload
  from pode_executar pe
), politica_criada as materialized (
  select
    (payload->'politica'->>'id')::uuid as politica_id,
    (payload->'politica'->>'empresa_id')::uuid as empresa_id,
    (payload->'politica'->>'empreendimento_id')::uuid as empreendimento_id,
    (payload->'politica'->>'mes_referencia')::date as mes_referencia,
    payload as payload_politica
  from upsert_politica
  where payload is not null
), upsert_faixas as materialized (
  select case when pc.politica_id is not null then public.mesa_cliente_upsert_faixas_premio(
    pc.empresa_id,
    pc.politica_id,
    jsonb_build_array(
      jsonb_build_object('vpl_de_pct', 0, 'vpl_ate_pct', 3, 'premio_corretor_pct', 2, 'status', 'premio_cheio', 'descricao', 'Teste rollback: prêmio cheio até 3%', 'ordem', 1, 'ativo', true),
      jsonb_build_object('vpl_de_pct', 3.01, 'vpl_ate_pct', 6, 'premio_corretor_pct', 1, 'status', 'premio_parcial', 'descricao', 'Teste rollback: prêmio parcial até limite da política', 'ordem', 2, 'ativo', true)
    )
  ) else null::jsonb end as payload
  from politica_criada pc
), listar_politica_criada as materialized (
  select l.*
  from politica_criada pc
  cross join lateral public.mesa_cliente_listar_politicas_financeiras(pc.empresa_id, pc.empreendimento_id, false, 50, 0) l
  where l.id = pc.politica_id
), obter_politica_final as materialized (
  select public.mesa_cliente_obter_politica_financeira(pc.politica_id, pc.empresa_id) as payload
  from politica_criada pc
)
select '01_admin_candidate' as bloco,
  case when pe.qtd_ctx = 1 and pe.ativo and pe.can_admin_empresa then 'PASS' else 'FAIL' end as status,
  jsonb_build_object('user_id', pe.user_id, 'corretor_id', pe.corretor_id, 'empresa_id', pe.empresa_id, 'role', pe.role, 'ativo', pe.ativo, 'can_admin_empresa', pe.can_admin_empresa) as detalhe
from pode_executar pe
union all
select '02_empreendimento_candidate', case when pe.empreendimento_id is not null then 'PASS' else 'FAIL' end,
  jsonb_build_object('empresa_id', pe.empresa_id, 'empreendimento_id', pe.empreendimento_id, 'empreendimento_nome', pe.empreendimento_nome)
from pode_executar pe
union all
select '03_no_policy_conflict_for_test_month', case when pe.qtd_conflitos = 0 then 'PASS' else 'FAIL' end,
  jsonb_build_object('mes_teste', '2099-01-01', 'qtd_conflitos', pe.qtd_conflitos)
from pode_executar pe
union all
select '04_upsert_politica_rpc', case when pc.politica_id is not null and pc.mes_referencia = date '2099-01-01' then 'PASS' else 'FAIL' end,
  jsonb_build_object('politica_id', pc.politica_id, 'empresa_id', pc.empresa_id, 'empreendimento_id', pc.empreendimento_id, 'mes_referencia', pc.mes_referencia)
from politica_criada pc
union all
select '05_upsert_faixas_rpc', case when jsonb_array_length(coalesce(uf.payload->'faixas_premio', '[]'::jsonb)) = 2 then 'PASS' else 'FAIL' end,
  jsonb_build_object('qtd_faixas', jsonb_array_length(coalesce(uf.payload->'faixas_premio', '[]'::jsonb)))
from upsert_faixas uf
union all
select '06_listar_politica_criada', case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object('qtd_registros_listados', count(*))
from listar_politica_criada
union all
select '07_obter_politica_com_faixas', case when jsonb_array_length(coalesce(opf.payload->'faixas_premio', '[]'::jsonb)) = 2 then 'PASS' else 'FAIL' end,
  jsonb_build_object('qtd_faixas', jsonb_array_length(coalesce(opf.payload->'faixas_premio', '[]'::jsonb)))
from obter_politica_final opf
union all
select '08_rollback_notice', 'INFO', jsonb_build_object('mensagem', 'Tudo que foi criado será desfeito pelo ROLLBACK.', 'mes_teste', '2099-01-01');

rollback;
