-- MesaCliente Engenharia Financeira — 07A validação positiva da agenda financeira
-- Fase 4A: gerar_mesa_cliente_agenda_parcelas
--
-- Teste com BEGIN + ROLLBACK.
-- Não deixa dados permanentes.

begin;

create temp table if not exists tmp_mc_07a_result (
  payload jsonb
) on commit drop;

truncate table tmp_mc_07a_result;

with ac as materialized (
  select c.user_id, c.id corretor_id, c.empresa_id, c.role, coalesce(c.ativo,true) ativo
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo,true)=true
    and (c.role in ('admin_global','admin_local','gestor') or coalesce(c.is_admin_local,false) or coalesce(c.is_gestor,false))
  order by case c.role when 'admin_global' then 1 when 'admin_local' then 2 when 'gestor' then 3 else 4 end,
           c.created_at nulls last, c.id
  limit 1
), sim as materialized (
  select s.id simulacao_id, s.empresa_id, s.empreendimento_id
  from public.mesa_simulacoes s
  join ac on ac.empresa_id = s.empresa_id
  where s.empresa_id is not null
    and s.empreendimento_id is not null
  order by s.updated_at desc nulls last, s.created_at desc nulls last, s.id
  limit 1
), seed as (
  select ac.*, sim.simulacao_id, sim.empreendimento_id
  from ac left join sim on true
)
select
  set_config('request.jwt.claim.sub', coalesce(user_id::text,'00000000-0000-0000-0000-000000000000'), true),
  set_config('app.mc.user_id', coalesce(user_id::text,''), true),
  set_config('app.mc.corretor_id', coalesce(corretor_id::text,''), true),
  set_config('app.mc.empresa_id', coalesce(empresa_id::text,''), true),
  set_config('app.mc.role', coalesce(role::text,''), true),
  set_config('app.mc.ativo', coalesce(ativo::text,'false'), true),
  set_config('app.mc.simulacao_id', coalesce(simulacao_id::text,''), true),
  set_config('app.mc.empreendimento_id', coalesce(empreendimento_id::text,''), true),
  set_config('app.mc.qtd_ctx', case when user_id is null then '0' else '1' end, true)
from seed;

set local role authenticated;

do $$
declare
  v_simulacao_id uuid := nullif(current_setting('app.mc.simulacao_id', true),'')::uuid;
  v_payload jsonb;
begin
  if v_simulacao_id is not null then
    v_payload := public.gerar_mesa_cliente_agenda_parcelas(
      v_simulacao_id,
      date '2026-01-31',
      jsonb_build_object(
        'parcelas', jsonb_build_array(
          jsonb_build_object('grupo','entrada','descricao','Ato oficial','valor',50000,'data_oficial','2026-02-10','ordem',1),
          jsonb_build_object('grupo','mensais','descricao','Mensal março usa dia do ato','valor',3000,'mes_ano','2026-03','ordem',2),
          jsonb_build_object('grupo','mensais','descricao','Mensal fevereiro ajusta último dia','valor',3000,'mes_ano','2026-02','ordem',3),
          jsonb_build_object('grupo','chaves','descricao','Chaves 60 dias','valor',100000,'ordem',4),
          jsonb_build_object('grupo','chaves','descricao','Chaves 30 dias','valor',50000,'cabecalho_dias_antes_financiamento',30,'data_financiamento','2028-09-30','ordem',5),
          jsonb_build_object('grupo','periodicidade','descricao','28 mensais','valor',0,'eh_periodicidade_simbolica',true,'ordem',6)
        ),
        'regras_cabecalho', jsonb_build_object(
          'chaves_dias_antes_financiamento',60,
          'data_financiamento','2028-09-30'
        )
      ),
      jsonb_build_object('origem','teste_07a')
    );

    -- Segunda chamada valida idempotência: deve recriar a mesma quantidade, não duplicar.
    v_payload := public.gerar_mesa_cliente_agenda_parcelas(
      v_simulacao_id,
      date '2026-01-31',
      jsonb_build_object(
        'parcelas', jsonb_build_array(
          jsonb_build_object('grupo','entrada','descricao','Ato oficial','valor',50000,'data_oficial','2026-02-10','ordem',1),
          jsonb_build_object('grupo','mensais','descricao','Mensal março usa dia do ato','valor',3000,'mes_ano','2026-03','ordem',2),
          jsonb_build_object('grupo','mensais','descricao','Mensal fevereiro ajusta último dia','valor',3000,'mes_ano','2026-02','ordem',3),
          jsonb_build_object('grupo','chaves','descricao','Chaves 60 dias','valor',100000,'ordem',4),
          jsonb_build_object('grupo','chaves','descricao','Chaves 30 dias','valor',50000,'cabecalho_dias_antes_financiamento',30,'data_financiamento','2028-09-30','ordem',5),
          jsonb_build_object('grupo','periodicidade','descricao','28 mensais','valor',0,'eh_periodicidade_simbolica',true,'ordem',6)
        ),
        'regras_cabecalho', jsonb_build_object(
          'chaves_dias_antes_financiamento',60,
          'data_financiamento','2028-09-30'
        )
      ),
      jsonb_build_object('origem','teste_07a')
    );

    insert into tmp_mc_07a_result(payload) values (v_payload);
  end if;
end $$;

with ctx as materialized (
  select
    nullif(current_setting('app.mc.user_id',true),'')::uuid user_id,
    nullif(current_setting('app.mc.empresa_id',true),'')::uuid empresa_id,
    nullif(current_setting('app.mc.simulacao_id',true),'')::uuid simulacao_id,
    coalesce(nullif(current_setting('app.mc.qtd_ctx',true),'')::int,0) qtd_ctx
), p as materialized (
  select payload from tmp_mc_07a_result limit 1
), parcelas as materialized (
  select value p from p, jsonb_array_elements(coalesce(payload->'parcelas','[]'::jsonb))
)
select '01_auth_context' bloco,
  case when ctx.qtd_ctx=1 and ctx.user_id is not null and ctx.empresa_id is not null then 'PASS' else 'FAIL' end status,
  jsonb_build_object('user_id',ctx.user_id,'empresa_id',ctx.empresa_id) detalhe
from ctx
union all
select '02_simulacao_existente',
  case when ctx.simulacao_id is not null then 'PASS' else 'FAIL' end,
  jsonb_build_object('simulacao_id',ctx.simulacao_id)
from ctx
union all
select '03_rpc_agenda_executou',
  case when p.payload is not null and (p.payload->>'ok')::boolean is true and (p.payload->>'qtd_parcelas_criadas')::int = 6 then 'PASS' else 'FAIL' end,
  coalesce(p.payload, '{}'::jsonb)
from p
union all
select '04_data_oficial_prevaleceu',
  case when exists (select 1 from parcelas where p->>'descricao'='Ato oficial' and p->>'data_atual'='2026-02-10' and p->>'origem_data'='tabela_oficial') then 'PASS' else 'FAIL' end,
  jsonb_build_object('esperado','2026-02-10')
union all
select '05_mes_ano_usou_dia_ato',
  case when exists (select 1 from parcelas where p->>'descricao'='Mensal março usa dia do ato' and p->>'data_atual'='2026-03-31' and p->>'regra_data'='usar_dia_do_ato') then 'PASS' else 'FAIL' end,
  jsonb_build_object('esperado','2026-03-31')
union all
select '06_mes_sem_dia_usou_ultimo_dia',
  case when exists (select 1 from parcelas where p->>'descricao'='Mensal fevereiro ajusta último dia' and p->>'data_atual'='2026-02-28' and p->>'regra_data'='ultimo_dia_valido_mes') then 'PASS' else 'FAIL' end,
  jsonb_build_object('esperado','2026-02-28')
union all
select '07_chaves_cabecalho_30_60_dias',
  case when exists (select 1 from parcelas where p->>'descricao'='Chaves 60 dias' and p->>'data_atual'='2028-08-01' and p->>'regra_data'='cabecalho_60_dias')
         and exists (select 1 from parcelas where p->>'descricao'='Chaves 30 dias' and p->>'data_atual'='2028-08-31' and p->>'regra_data'='cabecalho_30_dias')
       then 'PASS' else 'FAIL' end,
  jsonb_build_object('financiamento','2028-09-30','chaves_60','2028-08-01','chaves_30','2028-08-31')
union all
select '08_periodicidade_simbolica_bloqueada',
  case when exists (select 1 from parcelas where p->>'descricao'='28 mensais' and (p->>'eh_periodicidade_simbolica')::boolean is true and (p->>'pode_receber_vpl')::boolean is false) then 'PASS' else 'FAIL' end,
  jsonb_build_object('esperado','informativa_nao_negociavel')
union all
select '09_flags_negociacao_corretas',
  case when exists (select 1 from parcelas where p->>'descricao'='Mensal março usa dia do ato' and (p->>'pode_receber_vpl')::boolean is true and (p->>'pode_receber_antecipacao')::boolean is true and (p->>'pode_receber_postergacao')::boolean is true)
         and exists (select 1 from parcelas where p->>'descricao'='Ato oficial' and (p->>'pode_receber_vpl')::boolean is false)
       then 'PASS' else 'FAIL' end,
  jsonb_build_object('mensais','negociavel','entrada','bloqueada')
union all
select '10_idempotencia',
  case when p.payload is not null and (p.payload->>'qtd_parcelas_criadas')::int = 6 then 'PASS' else 'FAIL' end,
  jsonb_build_object('qtd_final',coalesce((p.payload->>'qtd_parcelas_criadas')::int,0),'esperado',6)
from p
union all
select '11_payload_cliente_safe',
  case when p.payload::text not ilike '%premio%' and p.payload::text not ilike '%comissao%' and p.payload::text not ilike '%taxa_interna%' and p.payload::text not ilike '%politica%' then 'PASS' else 'FAIL' end,
  jsonb_build_object('cliente_safe',p.payload->>'cliente_safe','campos_sensiveis','ausentes')
from p
union all
select '12_rollback_notice','INFO',jsonb_build_object('mensagem','Agenda gerada/recriada será desfeita pelo ROLLBACK.');

rollback;
