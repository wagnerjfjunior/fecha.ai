-- MesaCliente Engenharia Financeira — 06B validação funcional da RPC de simulação administrativa
-- Cria política/faixas temporárias, simula operações e desfaz tudo com ROLLBACK.

begin;

with ac as materialized (
  select c.user_id, c.id corretor_id, c.empresa_id, c.role, coalesce(c.ativo,true) ativo
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo,true)=true
    and (c.role in ('admin_global','admin_local','gestor') or coalesce(c.is_admin_local,false) or coalesce(c.is_gestor,false))
  order by case c.role when 'admin_global' then 1 when 'admin_local' then 2 when 'gestor' then 3 else 4 end,
           c.created_at nulls last, c.id
  limit 1
), emp as materialized (
  select e.id empreendimento_id, e.empresa_id, e.nome empreendimento_nome
  from public.empreendimentos e join ac on ac.empresa_id=e.empresa_id
  order by e.created_at nulls last, e.id
  limit 1
), conf as materialized (
  select count(*) qtd
  from public.mesa_cliente_politicas_financeiras p join emp on emp.empreendimento_id=p.empreendimento_id
  where p.empresa_id=emp.empresa_id and p.mes_referencia=date '2099-03-01'
), seed as (
  select ac.*, emp.empreendimento_id, emp.empreendimento_nome, coalesce(conf.qtd,0) qtd_conflitos
  from ac left join emp on true left join conf on true
)
select
  set_config('request.jwt.claim.sub', coalesce(user_id::text,'00000000-0000-0000-0000-000000000000'), true),
  set_config('app.mc.user_id', coalesce(user_id::text,''), true),
  set_config('app.mc.corretor_id', coalesce(corretor_id::text,''), true),
  set_config('app.mc.empresa_id', coalesce(empresa_id::text,''), true),
  set_config('app.mc.role', coalesce(role::text,''), true),
  set_config('app.mc.ativo', coalesce(ativo::text,'false'), true),
  set_config('app.mc.qtd_ctx', case when user_id is null then '0' else '1' end, true),
  set_config('app.mc.empreendimento_id', coalesce(empreendimento_id::text,''), true),
  set_config('app.mc.empreendimento_nome', coalesce(empreendimento_nome::text,''), true),
  set_config('app.mc.qtd_conflitos', coalesce(qtd_conflitos::text,'0'), true)
from seed;

select set_config('request.jwt.claim.sub', coalesce(nullif(current_setting('request.jwt.claim.sub',true),''),'00000000-0000-0000-0000-000000000000'), true);
select set_config('app.mc.user_id', coalesce(current_setting('app.mc.user_id',true),''), true);
select set_config('app.mc.corretor_id', coalesce(current_setting('app.mc.corretor_id',true),''), true);
select set_config('app.mc.empresa_id', coalesce(current_setting('app.mc.empresa_id',true),''), true);
select set_config('app.mc.role', coalesce(current_setting('app.mc.role',true),''), true);
select set_config('app.mc.ativo', coalesce(nullif(current_setting('app.mc.ativo',true),''),'false'), true);
select set_config('app.mc.qtd_ctx', coalesce(nullif(current_setting('app.mc.qtd_ctx',true),''),'0'), true);
select set_config('app.mc.empreendimento_id', coalesce(current_setting('app.mc.empreendimento_id',true),''), true);
select set_config('app.mc.empreendimento_nome', coalesce(current_setting('app.mc.empreendimento_nome',true),''), true);
select set_config('app.mc.qtd_conflitos', coalesce(nullif(current_setting('app.mc.qtd_conflitos',true),''),'0'), true);

set local role authenticated;

with ctx as materialized (
  select
    nullif(current_setting('app.mc.empresa_id',true),'')::uuid empresa_id,
    nullif(current_setting('app.mc.empreendimento_id',true),'')::uuid empreendimento_id,
    nullif(current_setting('app.mc.empreendimento_nome',true),'') empreendimento_nome,
    nullif(current_setting('app.mc.role',true),'') role,
    coalesce(nullif(current_setting('app.mc.ativo',true),'')::boolean,false) ativo,
    coalesce(nullif(current_setting('app.mc.qtd_ctx',true),'')::int,0) qtd_ctx,
    coalesce(nullif(current_setting('app.mc.qtd_conflitos',true),'')::int,0) qtd_conflitos
), perm as materialized (
  select *,
    case when empresa_id is not null then public.mesa_cliente_can_admin_empresa(empresa_id) else false end can_admin_empresa,
    case when empresa_id is not null then public.mesa_cliente_can_access_empresa(empresa_id) else false end can_access_empresa
  from ctx
), pol as materialized (
  select case when qtd_ctx=1 and ativo and can_admin_empresa and empreendimento_id is not null and qtd_conflitos=0
    then public.mesa_cliente_upsert_politica_financeira(
      empresa_id, empreendimento_id, date '2099-03-15', date '2099-03-01', date '2099-03-31',
      20, 12, 12, 'composto', 'dias_365',
      false, true, true, true,
      false, true, true, true,
      false, true, true, true,
      true, 'TESTE 06B rollback'
    ) else null::jsonb end payload
  from perm
), pc as materialized (
  select
    (payload->'politica'->>'id')::uuid politica_id,
    (payload->'politica'->>'empresa_id')::uuid empresa_id,
    (payload->'politica'->>'empreendimento_id')::uuid empreendimento_id,
    (payload->'politica'->>'mes_referencia')::date mes_referencia
  from pol where payload is not null
), faixas as materialized (
  select case when politica_id is not null then public.mesa_cliente_upsert_faixas_premio(
    empresa_id, politica_id,
    jsonb_build_array(
      jsonb_build_object('vpl_de_pct',0,'vpl_ate_pct',11,'premio_corretor_pct',2,'status','premio_cheio','descricao','Teste 06B cheio','ordem',1,'ativo',true),
      jsonb_build_object('vpl_de_pct',11.000001,'vpl_ate_pct',20,'premio_corretor_pct',1,'status','premio_parcial','descricao','Teste 06B parcial','ordem',2,'ativo',true)
    )
  ) else null::jsonb end payload
  from pc
), sim as materialized (
  select public.mesa_cliente_simular_impacto_financeiro_admin(
    pc.empresa_id, pc.empreendimento_id, date '2099-03-01',
    jsonb_build_array(
      jsonb_build_object('tipo_operacao','antecipacao','grupo','chaves','valor',100000,'data_original','2100-03-01','data_nova','2099-03-01','descricao','antecipacao chaves'),
      jsonb_build_object('tipo_operacao','postergacao','grupo','mensais','valor',50000,'data_original','2099-03-01','data_nova','2100-03-01','descricao','postergacao mensais'),
      jsonb_build_object('tipo_operacao','vpl','grupo','intermediarias','valor',80000,'data_original','2100-03-01','descricao','vpl intermediaria'),
      jsonb_build_object('tipo_operacao','antecipacao','grupo','mensais','valor',12345,'data_original','2100-03-01','data_nova','2099-03-01','descricao','periodicidade simbolica','eh_periodicidade_simbolica',true)
    ),
    pc.politica_id
  ) payload
  from pc cross join faixas
), p as materialized (
  select
    payload,
    (payload->>'ok')::boolean ok,
    payload->>'visao' visao,
    (payload->>'cliente_safe')::boolean cliente_safe,
    (payload->'totais'->>'qtd_operacoes_validas')::int qtd_validas,
    (payload->'totais'->>'qtd_operacoes_rejeitadas')::int qtd_rejeitadas,
    (payload->'totais'->>'valor_original_total')::numeric valor_original_total,
    (payload->'totais'->>'valor_calculado_total')::numeric valor_calculado_total,
    (payload->'totais'->>'desconto_total')::numeric desconto_total,
    (payload->'totais'->>'acrescimo_total')::numeric acrescimo_total,
    (payload->'totais'->>'economia_liquida_total')::numeric economia_total,
    (payload->'totais'->>'maior_impacto_pct')::numeric maior_impacto_pct,
    (payload->'totais'->>'premio_corretor_pct_mais_restritivo')::numeric premio_restritivo,
    jsonb_array_length(coalesce(payload->'operacoes','[]'::jsonb)) qtd_ops_array,
    jsonb_array_length(coalesce(payload->'rejeicoes','[]'::jsonb)) qtd_rej_array
  from sim
)
select '01_admin_candidate' bloco,
  case when qtd_ctx=1 and ativo and can_admin_empresa and can_access_empresa then 'PASS' else 'FAIL' end status,
  jsonb_build_object('role',role,'ativo',ativo,'empresa_id',empresa_id,'can_admin_empresa',can_admin_empresa,'can_access_empresa',can_access_empresa) detalhe
from perm
union all
select '02_empreendimento_candidate', case when empreendimento_id is not null then 'PASS' else 'FAIL' end,
  jsonb_build_object('empresa_id',empresa_id,'empreendimento_id',empreendimento_id,'empreendimento_nome',empreendimento_nome)
from perm
union all
select '03_no_policy_conflict_for_test_month', case when qtd_conflitos=0 then 'PASS' else 'FAIL' end,
  jsonb_build_object('mes_teste','2099-03-01','qtd_conflitos',qtd_conflitos)
from perm
union all
select '04_upsert_politica_rpc', case when politica_id is not null and mes_referencia=date '2099-03-01' then 'PASS' else 'FAIL' end,
  jsonb_build_object('politica_id',politica_id,'empresa_id',empresa_id,'empreendimento_id',empreendimento_id,'mes_referencia',mes_referencia)
from pc
union all
select '05_upsert_faixas_rpc', case when jsonb_array_length(coalesce(payload->'faixas_premio','[]'::jsonb))=2 then 'PASS' else 'FAIL' end,
  jsonb_build_object('qtd_faixas',jsonb_array_length(coalesce(payload->'faixas_premio','[]'::jsonb)))
from faixas
union all
select '06_simulacao_rpc_executou', case when payload is not null then 'PASS' else 'FAIL' end,
  jsonb_build_object('payload_existe',payload is not null,'ok',ok)
from p
union all
select '07_payload_admin_nao_cliente_safe', case when visao='administrativa' and cliente_safe=false then 'PASS' else 'FAIL' end,
  jsonb_build_object('visao',visao,'cliente_safe',cliente_safe)
from p
union all
select '08_operacoes_validas_e_rejeicoes', case when ok=false and qtd_validas=3 and qtd_rejeitadas=1 and qtd_ops_array=3 and qtd_rej_array=1 then 'PASS' else 'FAIL' end,
  jsonb_build_object('ok',ok,'qtd_validas',qtd_validas,'qtd_rejeitadas',qtd_rejeitadas,'qtd_operacoes_array',qtd_ops_array,'qtd_rejeicoes_array',qtd_rej_array)
from p
union all
select '09_calculos_compostos_bateram', case when valor_original_total=230000 and valor_calculado_total=216714.28 and desconto_total=19285.72 and acrescimo_total=6000 and economia_total=19285.72 and maior_impacto_pct=12 then 'PASS' else 'FAIL' end,
  jsonb_build_object('valor_original_total',valor_original_total,'valor_calculado_total',valor_calculado_total,'desconto_total',desconto_total,'acrescimo_total',acrescimo_total,'economia_total',economia_total,'maior_impacto_pct',maior_impacto_pct)
from p
union all
select '10_politica_e_premio_aplicados', case when premio_restritivo=1 then 'PASS' else 'FAIL' end,
  jsonb_build_object('premio_corretor_pct_mais_restritivo',premio_restritivo,'motivo','Impacto máximo de 12% entra na faixa parcial 11.000001-20')
from p
union all
select '11_rollback_notice','INFO',jsonb_build_object('mensagem','Política e faixas temporárias serão desfeitas pelo ROLLBACK.','mes_teste','2099-03-01');

rollback;
