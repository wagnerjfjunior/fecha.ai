-- MesaCliente Engenharia Financeira — 07B validações negativas da agenda financeira
-- Fase 4A: gerar_mesa_cliente_agenda_parcelas
--
-- Teste com BEGIN + ROLLBACK.
-- Não deixa dados permanentes.

begin;

create temp table if not exists tmp_mc_07b_result (
  bloco text,
  status text,
  detalhe jsonb
) on commit drop;

truncate table tmp_mc_07b_result;

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
), sim_cross as materialized (
  select s.id simulacao_id, s.empresa_id, s.empreendimento_id
  from public.mesa_simulacoes s
  join ac on ac.empresa_id is distinct from s.empresa_id
  where s.empresa_id is not null
    and s.empreendimento_id is not null
  order by s.updated_at desc nulls last, s.created_at desc nulls last, s.id
  limit 1
), seed as (
  select ac.*, sim.simulacao_id, sim.empreendimento_id, sim_cross.simulacao_id cross_simulacao_id
  from ac left join sim on true left join sim_cross on true
)
select
  set_config('request.jwt.claim.sub', coalesce(user_id::text,'00000000-0000-0000-0000-000000000000'), true),
  set_config('app.mc.user_id', coalesce(user_id::text,''), true),
  set_config('app.mc.corretor_id', coalesce(corretor_id::text,''), true),
  set_config('app.mc.empresa_id', coalesce(empresa_id::text,''), true),
  set_config('app.mc.role', coalesce(role::text,''), true),
  set_config('app.mc.ativo', coalesce(ativo::text,'false'), true),
  set_config('app.mc.simulacao_id', coalesce(simulacao_id::text,''), true),
  set_config('app.mc.cross_simulacao_id', coalesce(cross_simulacao_id::text,''), true),
  set_config('app.mc.qtd_ctx', case when user_id is null then '0' else '1' end, true)
from seed;

set local role authenticated;

do $$
declare
  v_sim uuid := nullif(current_setting('app.mc.simulacao_id', true),'')::uuid;
  v_cross uuid := nullif(current_setting('app.mc.cross_simulacao_id', true),'')::uuid;
  v_ok_payload jsonb := jsonb_build_object(
    'parcelas', jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Ato','valor',50000,'data_oficial','2026-02-10','ordem',1)
    )
  );
  v_payload jsonb;
begin
  -- 01: anon sem EXECUTE direto.
  insert into tmp_mc_07b_result(bloco,status,detalhe)
  select '01_anon_sem_execute',
    case when has_function_privilege('anon', 'public.gerar_mesa_cliente_agenda_parcelas(uuid,date,jsonb,jsonb)', 'EXECUTE') is false then 'PASS' else 'FAIL' end,
    jsonb_build_object('anon_execute', has_function_privilege('anon', 'public.gerar_mesa_cliente_agenda_parcelas(uuid,date,jsonb,jsonb)', 'EXECUTE'));

  -- 02: sem auth.uid().
  begin
    perform set_config('request.jwt.claim.sub', '', true);
    perform public.gerar_mesa_cliente_agenda_parcelas(v_sim, date '2026-01-31', v_ok_payload, '{}'::jsonb);
    insert into tmp_mc_07b_result values ('02_sem_auth_bloqueado','FAIL',jsonb_build_object('erro','rpc executou sem auth'));
  exception when others then
    insert into tmp_mc_07b_result values ('02_sem_auth_bloqueado','PASS',jsonb_build_object('sqlstate',sqlstate,'message',sqlerrm));
  end;

  perform set_config('request.jwt.claim.sub', current_setting('app.mc.user_id', true), true);

  -- 03: simulação inexistente.
  begin
    perform public.gerar_mesa_cliente_agenda_parcelas('00000000-0000-0000-0000-000000000000'::uuid, date '2026-01-31', v_ok_payload, '{}'::jsonb);
    insert into tmp_mc_07b_result values ('03_simulacao_inexistente_bloqueada','FAIL',jsonb_build_object('erro','rpc executou com simulação inexistente'));
  exception when others then
    insert into tmp_mc_07b_result values ('03_simulacao_inexistente_bloqueada','PASS',jsonb_build_object('sqlstate',sqlstate,'message',sqlerrm));
  end;

  -- 04: cross-tenant, se houver simulação de outra empresa.
  if v_cross is not null then
    begin
      perform public.gerar_mesa_cliente_agenda_parcelas(v_cross, date '2026-01-31', v_ok_payload, '{}'::jsonb);
      insert into tmp_mc_07b_result values ('04_cross_tenant_bloqueado','FAIL',jsonb_build_object('cross_simulacao_id',v_cross,'erro','rpc executou cross-tenant'));
    exception when others then
      insert into tmp_mc_07b_result values ('04_cross_tenant_bloqueado','PASS',jsonb_build_object('cross_simulacao_id',v_cross,'sqlstate',sqlstate,'message',sqlerrm));
    end;
  else
    insert into tmp_mc_07b_result values ('04_cross_tenant_bloqueado','SKIP',jsonb_build_object('motivo','sem simulação de outra empresa disponível para teste'));
  end if;

  -- 05: payload nulo.
  begin
    perform public.gerar_mesa_cliente_agenda_parcelas(v_sim, date '2026-01-31', null::jsonb, '{}'::jsonb);
    insert into tmp_mc_07b_result values ('05_payload_nulo_bloqueado','FAIL',jsonb_build_object('erro','rpc executou com payload nulo'));
  exception when others then
    insert into tmp_mc_07b_result values ('05_payload_nulo_bloqueado','PASS',jsonb_build_object('sqlstate',sqlstate,'message',sqlerrm));
  end;

  -- 06: payload malformado.
  begin
    perform public.gerar_mesa_cliente_agenda_parcelas(v_sim, date '2026-01-31', jsonb_build_object('foo','bar'), '{}'::jsonb);
    insert into tmp_mc_07b_result values ('06_payload_malformado_bloqueado','FAIL',jsonb_build_object('erro','rpc executou com payload malformado'));
  exception when others then
    insert into tmp_mc_07b_result values ('06_payload_malformado_bloqueado','PASS',jsonb_build_object('sqlstate',sqlstate,'message',sqlerrm));
  end;

  -- 07: valor negativo.
  begin
    perform public.gerar_mesa_cliente_agenda_parcelas(
      v_sim, date '2026-01-31',
      jsonb_build_object('parcelas',jsonb_build_array(jsonb_build_object('grupo','mensais','descricao','Negativa','valor',-1,'mes_ano','2026-03','ordem',1))),
      '{}'::jsonb
    );
    insert into tmp_mc_07b_result values ('07_valor_negativo_bloqueado','FAIL',jsonb_build_object('erro','rpc executou com valor negativo'));
  exception when others then
    insert into tmp_mc_07b_result values ('07_valor_negativo_bloqueado','PASS',jsonb_build_object('sqlstate',sqlstate,'message',sqlerrm));
  end;

  -- 08: grupo desconhecido.
  begin
    perform public.gerar_mesa_cliente_agenda_parcelas(
      v_sim, date '2026-01-31',
      jsonb_build_object('parcelas',jsonb_build_array(jsonb_build_object('grupo','banana_split','descricao','Grupo inválido','valor',100,'mes_ano','2026-03','ordem',1))),
      '{}'::jsonb
    );
    insert into tmp_mc_07b_result values ('08_grupo_desconhecido_bloqueado','FAIL',jsonb_build_object('erro','rpc executou com grupo desconhecido'));
  exception when others then
    insert into tmp_mc_07b_result values ('08_grupo_desconhecido_bloqueado','PASS',jsonb_build_object('sqlstate',sqlstate,'message',sqlerrm));
  end;

  -- 09: empresa_id no payload deve ser ignorado, não usado como fonte de verdade.
  begin
    v_payload := public.gerar_mesa_cliente_agenda_parcelas(
      v_sim, date '2026-01-31',
      jsonb_build_object('parcelas',jsonb_build_array(jsonb_build_object('grupo','entrada','descricao','Ato com empresa fake','valor',100,'data_oficial','2026-02-10','empresa_id','00000000-0000-0000-0000-000000000000','ordem',1))),
      '{}'::jsonb
    );

    insert into tmp_mc_07b_result values (
      '09_empresa_id_payload_ignorado',
      case when v_payload is not null and (v_payload->>'ok')::boolean is true and v_payload->>'empresa_id' <> '00000000-0000-0000-0000-000000000000' then 'PASS' else 'FAIL' end,
      jsonb_build_object('empresa_id_retorno',v_payload->>'empresa_id')
    );
  exception when others then
    insert into tmp_mc_07b_result values ('09_empresa_id_payload_ignorado','FAIL',jsonb_build_object('sqlstate',sqlstate,'message',sqlerrm));
  end;

  -- 10: periodicidade simbólica negociável deve ser bloqueada.
  begin
    perform public.gerar_mesa_cliente_agenda_parcelas(
      v_sim, date '2026-01-31',
      jsonb_build_object('parcelas',jsonb_build_array(jsonb_build_object('grupo','periodicidade','descricao','28 mensais fraudada','valor',0,'eh_periodicidade_simbolica',true,'pode_receber_vpl',true,'ordem',1))),
      '{}'::jsonb
    );
    insert into tmp_mc_07b_result values ('10_periodicidade_negociavel_bloqueada','FAIL',jsonb_build_object('erro','rpc aceitou periodicidade negociável'));
  exception when others then
    insert into tmp_mc_07b_result values ('10_periodicidade_negociavel_bloqueada','PASS',jsonb_build_object('sqlstate',sqlstate,'message',sqlerrm));
  end;
end $$;

select bloco, status, detalhe
from tmp_mc_07b_result
union all
select '11_rollback_notice','INFO',jsonb_build_object('mensagem','Todos os efeitos da validação negativa serão desfeitos pelo ROLLBACK.')
order by bloco;

rollback;
