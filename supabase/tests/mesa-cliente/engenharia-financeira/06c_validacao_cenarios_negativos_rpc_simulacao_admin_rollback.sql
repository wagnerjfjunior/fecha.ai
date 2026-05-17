-- MesaCliente Engenharia Financeira — 06C cenários negativos da RPC de simulação administrativa
-- Seguro para produção única: cria política/faixas temporárias e desfaz tudo com ROLLBACK.

begin;

create or replace function pg_temp.capture_error(p_sql text)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_sqlstate text;
  v_message text;
begin
  begin
    execute p_sql;
    return jsonb_build_object('erro_capturado', false, 'sqlstate', null, 'message', null);
  exception when others then
    get stacked diagnostics v_sqlstate = returned_sqlstate, v_message = message_text;
    return jsonb_build_object('erro_capturado', true, 'sqlstate', v_sqlstate, 'message', v_message);
  end;
end;
$$;

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
  where p.empresa_id=emp.empresa_id and p.mes_referencia=date '2099-04-01'
), seed as (
  select ac.*, emp.empreendimento_id, emp.empreendimento_nome, coalesce(conf.qtd,0) qtd_conflitos
  from ac left join emp on true left join conf on true
)
select
  set_config('request.jwt.claim.sub', coalesce(user_id::text,'00000000-0000-0000-0000-000000000000'), true),
  set_config('app.mc06c.empresa_id', coalesce(empresa_id::text,''), true),
  set_config('app.mc06c.empreendimento_id', coalesce(empreendimento_id::text,''), true),
  set_config('app.mc06c.empreendimento_nome', coalesce(empreendimento_nome::text,''), true),
  set_config('app.mc06c.role', coalesce(role::text,''), true),
  set_config('app.mc06c.ativo', coalesce(ativo::text,'false'), true),
  set_config('app.mc06c.qtd_ctx', case when user_id is null then '0' else '1' end, true),
  set_config('app.mc06c.qtd_conflitos', coalesce(qtd_conflitos::text,'0'), true)
from seed;

select set_config('request.jwt.claim.sub', coalesce(nullif(current_setting('request.jwt.claim.sub',true),''),'00000000-0000-0000-0000-000000000000'), true);
select set_config('app.mc06c.empresa_id', coalesce(current_setting('app.mc06c.empresa_id',true),''), true);
select set_config('app.mc06c.empreendimento_id', coalesce(current_setting('app.mc06c.empreendimento_id',true),''), true);
select set_config('app.mc06c.empreendimento_nome', coalesce(current_setting('app.mc06c.empreendimento_nome',true),''), true);
select set_config('app.mc06c.role', coalesce(current_setting('app.mc06c.role',true),''), true);
select set_config('app.mc06c.ativo', coalesce(nullif(current_setting('app.mc06c.ativo',true),''),'false'), true);
select set_config('app.mc06c.qtd_ctx', coalesce(nullif(current_setting('app.mc06c.qtd_ctx',true),''),'0'), true);
select set_config('app.mc06c.qtd_conflitos', coalesce(nullif(current_setting('app.mc06c.qtd_conflitos',true),''),'0'), true);

set local role authenticated;

with ctx as materialized (
  select
    nullif(current_setting('app.mc06c.empresa_id',true),'')::uuid empresa_id,
    nullif(current_setting('app.mc06c.empreendimento_id',true),'')::uuid empreendimento_id,
    nullif(current_setting('app.mc06c.empreendimento_nome',true),'') empreendimento_nome,
    nullif(current_setting('app.mc06c.role',true),'') role,
    coalesce(nullif(current_setting('app.mc06c.ativo',true),'')::boolean,false) ativo,
    coalesce(nullif(current_setting('app.mc06c.qtd_ctx',true),'')::int,0) qtd_ctx,
    coalesce(nullif(current_setting('app.mc06c.qtd_conflitos',true),'')::int,0) qtd_conflitos
), perm as materialized (
  select *,
    case when empresa_id is not null then public.mesa_cliente_can_admin_empresa(empresa_id) else false end can_admin_empresa,
    case when empresa_id is not null then public.mesa_cliente_can_access_empresa(empresa_id) else false end can_access_empresa
  from ctx
), pol as materialized (
  select case when qtd_ctx=1 and ativo and can_admin_empresa and empreendimento_id is not null and qtd_conflitos=0
    then public.mesa_cliente_upsert_politica_financeira(
      empresa_id, empreendimento_id, date '2099-04-15', date '2099-04-01', date '2099-04-30',
      6, 12, 12, 'composto', 'dias_365',
      false, true, true, true,
      false, true, true, true,
      false, true, true, true,
      true, 'TESTE 06C rollback'
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
      jsonb_build_object('vpl_de_pct',0,'vpl_ate_pct',3,'premio_corretor_pct',2,'status','premio_cheio','descricao','Teste 06C cheio','ordem',1,'ativo',true),
      jsonb_build_object('vpl_de_pct',3.000001,'vpl_ate_pct',6,'premio_corretor_pct',1,'status','premio_parcial','descricao','Teste 06C parcial','ordem',2,'ativo',true)
    )
  ) else null::jsonb end payload
  from pc
), sims as materialized (
  select
    pc.*,
    public.mesa_cliente_simular_impacto_financeiro_admin(
      pc.empresa_id, pc.empreendimento_id, date '2099-04-01',
      jsonb_build_array(jsonb_build_object('tipo_operacao','vpl','grupo','financiamento','valor',100000,'data_original','2100-04-01')),
      pc.politica_id
    ) grupo_bloqueado,
    public.mesa_cliente_simular_impacto_financeiro_admin(
      pc.empresa_id, pc.empreendimento_id, date '2099-04-01',
      jsonb_build_array(jsonb_build_object('tipo_operacao','antecipacao','grupo','chaves','valor',100000,'data_original','2100-04-01','data_nova','2099-04-01')),
      pc.politica_id
    ) impacto_excedido,
    public.mesa_cliente_simular_impacto_financeiro_admin(
      pc.empresa_id, pc.empreendimento_id, date '2099-04-01',
      jsonb_build_array(jsonb_build_object('tipo_operacao','antecipacao','grupo','mensais','valor',10000,'data_original','2100-04-01','data_nova','2099-04-01','eh_periodicidade_simbolica',true)),
      pc.politica_id
    ) periodicidade,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_simular_impacto_financeiro_admin(%L::uuid,%L::uuid,date '2099-04-01',%L::jsonb,%L::uuid)$q$,
      pc.empresa_id,
      pc.empreendimento_id,
      '[{"tipo_operacao":"op_invalida","grupo":"mensais","valor":100,"data_original":"2100-04-01","data_nova":"2099-04-01"}]',
      pc.politica_id
    )) tipo_invalido,
    pg_temp.capture_error(format(
      $q$select public.mesa_cliente_simular_impacto_financeiro_admin(%L::uuid,%L::uuid,date '2098-01-01',%L::jsonb,null::uuid)$q$,
      pc.empresa_id,
      pc.empreendimento_id,
      '[{"tipo_operacao":"vpl","grupo":"mensais","valor":100,"data_original":"2099-01-01"}]'
    )) politica_inexistente
  from pc cross join faixas
), anon_test as materialized (
  select pg_temp.capture_error(format(
    $q$set local role anon; select public.mesa_cliente_simular_impacto_financeiro_admin(%L::uuid,%L::uuid,date '2099-04-01',%L::jsonb,%L::uuid); reset role$q$,
    empresa_id,
    empreendimento_id,
    '[{"tipo_operacao":"vpl","grupo":"mensais","valor":100,"data_original":"2100-04-01"}]',
    politica_id
  )) anon_result
  from pc
)
select '01_admin_candidate' bloco,
  case when qtd_ctx=1 and ativo and can_admin_empresa and can_access_empresa then 'PASS' else 'FAIL' end status,
  jsonb_build_object('role',role,'ativo',ativo,'empresa_id',empresa_id,'can_admin_empresa',can_admin_empresa,'can_access_empresa',can_access_empresa) detalhe
from perm
union all
select '02_politica_temporaria_criada', case when politica_id is not null and mes_referencia=date '2099-04-01' then 'PASS' else 'FAIL' end,
  jsonb_build_object('politica_id',politica_id,'empresa_id',empresa_id,'empreendimento_id',empreendimento_id,'mes_referencia',mes_referencia)
from pc
union all
select '03_grupo_bloqueado_rejeitado', case when (grupo_bloqueado->>'ok')::boolean=false and (grupo_bloqueado->'totais'->>'qtd_operacoes_rejeitadas')::int=1 then 'PASS' else 'FAIL' end,
  jsonb_build_object('ok',grupo_bloqueado->>'ok','rejeicoes',grupo_bloqueado->'rejeicoes')
from sims
union all
select '04_impacto_acima_limite_rejeitado', case when (impacto_excedido->>'ok')::boolean=false and (impacto_excedido->'totais'->>'qtd_operacoes_rejeitadas')::int=1 then 'PASS' else 'FAIL' end,
  jsonb_build_object('ok',impacto_excedido->>'ok','rejeicoes',impacto_excedido->'rejeicoes')
from sims
union all
select '05_periodicidade_simbolica_rejeitada', case when (periodicidade->>'ok')::boolean=false and (periodicidade->'totais'->>'qtd_operacoes_rejeitadas')::int=1 then 'PASS' else 'FAIL' end,
  jsonb_build_object('ok',periodicidade->>'ok','rejeicoes',periodicidade->'rejeicoes')
from sims
union all
select '06_tipo_operacao_invalido_bloqueado', case when (tipo_invalido->>'erro_capturado')::boolean=true and tipo_invalido->>'sqlstate'='22023' then 'PASS' else 'FAIL' end,
  tipo_invalido
from sims
union all
select '07_politica_inexistente_bloqueada', case when (politica_inexistente->>'erro_capturado')::boolean=true and politica_inexistente->>'sqlstate'='P0002' then 'PASS' else 'FAIL' end,
  politica_inexistente
from sims
union all
select '08_anon_sem_execute', case when (anon_result->>'erro_capturado')::boolean=true then 'PASS' else 'FAIL' end,
  anon_result
from anon_test
union all
select '09_payloads_nao_cliente_safe', case when (grupo_bloqueado->>'cliente_safe')::boolean=false and (impacto_excedido->>'cliente_safe')::boolean=false and (periodicidade->>'cliente_safe')::boolean=false then 'PASS' else 'FAIL' end,
  jsonb_build_object('grupo_cliente_safe',grupo_bloqueado->>'cliente_safe','impacto_cliente_safe',impacto_excedido->>'cliente_safe','periodicidade_cliente_safe',periodicidade->>'cliente_safe')
from sims
union all
select '10_rollback_notice','INFO',jsonb_build_object('mensagem','Política/faixas temporárias e função pg_temp serão desfeitas pelo ROLLBACK.','mes_teste','2099-04-01');

rollback;
