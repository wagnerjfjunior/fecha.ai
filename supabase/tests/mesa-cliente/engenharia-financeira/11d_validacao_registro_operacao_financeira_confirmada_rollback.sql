-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 5B
-- 11D — Validação de operação financeira confirmada e conflito na RPC 5B.
--
-- Pré-requisito:
--   Migration 5B aplicada:
--   supabase/migrations/20260519123000_mesa_cliente_fase_5b_registro_operacao_financeira.sql
--
-- Objetivo:
--   Criar fixture transacional, persistir agenda via 4B, registrar operação via 5B,
--   marcar a operação como confirmada dentro da transação e validar:
--     - mesma chamada canônica reaproveita a operação confirmada por checksum;
--     - chamada conflitante para a mesma parcela é bloqueada com SQLSTATE 55000;
--     - operação confirmada é preservada;
--     - não duplica operação financeira;
--     - agenda e parcelas não são mutadas;
--     - rollback final.
--
-- Observação:
--   Este teste não implementa a Fase 5C. A confirmação aqui é fixture transacional
--   controlada para validar o bloqueio de conflito da RPC 5B.
--   Não usa temp table. Usa set_config(...) transacional para evitar fragilidade com SET LOCAL ROLE.

begin;

select set_config('app.mc11d.user_id', '', true);
select set_config('app.mc11d.simulacao_id', '', true);
select set_config('app.mc11d.empresa_id', '', true);
select set_config('app.mc11d.empreendimento_id', '', true);
select set_config('app.mc11d.politica_id', '', true);
select set_config('app.mc11d.agenda_id', '', true);
select set_config('app.mc11d.parcela_id', '', true);
select set_config('app.mc11d.payload_4b', 'null', true);
select set_config('app.mc11d.payload_5b_criacao', 'null', true);
select set_config('app.mc11d.payload_confirmacao_fixture', 'null', true);
select set_config('app.mc11d.payload_5b_mesmo_checksum', 'null', true);
select set_config('app.mc11d.payload_5b_conflito', 'null', true);
select set_config('app.mc11d.snapshot_before', 'null', true);
select set_config('app.mc11d.snapshot_after_criacao', 'null', true);
select set_config('app.mc11d.snapshot_after_confirmacao', 'null', true);
select set_config('app.mc11d.snapshot_after_mesmo_checksum', 'null', true);
select set_config('app.mc11d.snapshot_after_conflito', 'null', true);
select set_config('request.jwt.claim.sub', '', true);

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
    e.id as empreendimento_id,
    e.nome as empreendimento_nome
  from public.corretores c
  join public.empreendimentos e on e.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'admin_local', 'gestor')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case when c.role = 'admin_global' then 1 when c.role = 'admin_local' then 2 when c.role = 'gestor' then 3 else 4 end,
    c.created_at desc nulls last,
    c.id
  limit 1
),
simulacao as materialized (
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
  select
    empresa_id,
    corretor_id,
    empreendimento_id,
    'Teste rollback 11D operação confirmada e conflito registro 5B',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object('origem', 'teste_11d_5b_rollback', 'fixture_transacional', true),
    'Fixture transacional 11D. Deve sumir no ROLLBACK.'
  from candidato
  returning id, empresa_id, corretor_id, empreendimento_id
),
politica as materialized (
  insert into public.mesa_cliente_politicas_financeiras (
    empresa_id,
    empreendimento_id,
    mes_referencia,
    vigencia_inicio,
    vigencia_fim,
    vpl_max_pct,
    taxa_antecipacao_ano_pct,
    taxa_postergacao_ano_pct,
    metodo_calculo,
    base_tempo,
    permite_vpl_financiamento,
    permite_vpl_chaves,
    permite_vpl_anuais,
    permite_vpl_mensais,
    permite_antecipacao_financiamento,
    permite_antecipacao_chaves,
    permite_antecipacao_anuais,
    permite_antecipacao_mensais,
    permite_postergacao_financiamento,
    permite_postergacao_chaves,
    permite_postergacao_anuais,
    permite_postergacao_mensais,
    ativo,
    observacoes
  )
  select
    empresa_id,
    empreendimento_id,
    date '2099-05-01',
    date '2099-01-01',
    date '2099-12-31',
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture 11D para validação de operação confirmada e conflito da RPC 5B.'
  from simulacao
  on conflict (empresa_id, empreendimento_id, mes_referencia)
  do update set
    vigencia_inicio = excluded.vigencia_inicio,
    vigencia_fim = excluded.vigencia_fim,
    vpl_max_pct = excluded.vpl_max_pct,
    taxa_antecipacao_ano_pct = excluded.taxa_antecipacao_ano_pct,
    taxa_postergacao_ano_pct = excluded.taxa_postergacao_ano_pct,
    metodo_calculo = excluded.metodo_calculo,
    base_tempo = excluded.base_tempo,
    permite_vpl_financiamento = excluded.permite_vpl_financiamento,
    permite_vpl_chaves = excluded.permite_vpl_chaves,
    permite_vpl_anuais = excluded.permite_vpl_anuais,
    permite_vpl_mensais = excluded.permite_vpl_mensais,
    permite_antecipacao_financiamento = excluded.permite_antecipacao_financiamento,
    permite_antecipacao_chaves = excluded.permite_antecipacao_chaves,
    permite_antecipacao_anuais = excluded.permite_antecipacao_anuais,
    permite_antecipacao_mensais = excluded.permite_antecipacao_mensais,
    permite_postergacao_financiamento = excluded.permite_postergacao_financiamento,
    permite_postergacao_chaves = excluded.permite_postergacao_chaves,
    permite_postergacao_anuais = excluded.permite_postergacao_anuais,
    permite_postergacao_mensais = excluded.permite_postergacao_mensais,
    ativo = excluded.ativo,
    observacoes = excluded.observacoes,
    updated_at = now()
  returning id, empresa_id, empreendimento_id
),
faixas as materialized (
  insert into public.mesa_cliente_politica_premio_faixas (
    empresa_id,
    politica_id,
    vpl_de_pct,
    vpl_ate_pct,
    premio_corretor_pct,
    status,
    descricao,
    ordem,
    ativo
  )
  select p.empresa_id, p.id, v.vpl_de_pct, v.vpl_ate_pct, v.premio_corretor_pct, v.status, v.descricao, v.ordem, true
  from politica p
  cross join (
    values
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 11D — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 11D — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 11D — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc11d.user_id', c.user_id::text, true),
    set_config('app.mc11d.simulacao_id', s.id::text, true),
    set_config('app.mc11d.empresa_id', s.empresa_id::text, true),
    set_config('app.mc11d.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc11d.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select
  '00_setup_fixture_11d' as bloco,
  case when count(*) = 1 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'simulacao_id', current_setting('app.mc11d.simulacao_id', true),
    'politica_id', current_setting('app.mc11d.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  ) as detalhe
from setup;

set local role authenticated;

with ctx as (
  select
    current_setting('app.mc11d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11d.empresa_id', true)::uuid as empresa_id,
    current_setting('app.mc11d.empreendimento_id', true)::uuid as empreendimento_id
),
chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    ctx.simulacao_id,
    date '2099-05-31',
    jsonb_build_array(
      jsonb_build_object('grupo','entrada','descricao','Sinal ato','valor','10000,50','data','2099-05-31'),
      jsonb_build_object('grupo','mensais','descricao','Mensais','valor','2500.00','quantidade',3,'mes_ano','06/2099'),
      jsonb_build_object('grupo','intermediarias','descricao','Intermediária anual','valor','12000','mes_ano','2099-12'),
      jsonb_build_object('grupo','periodicidade','descricao','Periodicidade simbólica','valor',0,'mes_ano','07/2099')
    ),
    jsonb_build_object('empresa_id', ctx.empresa_id, 'empreendimento_id', ctx.empreendimento_id, 'origem', 'teste_11d')
  ) as payload
  from ctx
)
select set_config('app.mc11d.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with ctx as (
  select current_setting('app.mc11d.simulacao_id', true)::uuid as simulacao_id
),
agenda as (
  select a.id, a.checksum, a.totais, a.updated_at
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  where a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcela as (
  select fp.id
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual > 0
    and fp.data_atual > date '2099-05-31'
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
  order by fp.valor_atual desc, fp.data_atual desc, fp.id
  limit 1
),
snapshot_before as (
  select jsonb_build_object(
    'agenda_id', (select id from agenda),
    'agenda_checksum', (select checksum from agenda),
    'agenda_tots', (select totais from agenda),
    'agenda_updated_at', (select updated_at from agenda),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp join agenda a on a.id = fp.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o join ctx on ctx.simulacao_id = o.simulacao_id)
  ) as payload
),
setups as (
  select
    set_config('app.mc11d.agenda_id', (select id::text from agenda), true),
    set_config('app.mc11d.parcela_id', (select id::text from parcela), true),
    set_config('app.mc11d.snapshot_before', (select payload::text from snapshot_before), true)
)
select
  '00b_agenda_parcela_fixture_11d' as bloco,
  case
    when current_setting('app.mc11d.agenda_id', true) <> ''
     and current_setting('app.mc11d.parcela_id', true) <> ''
    then 'PASS' else 'FAIL'
  end as status,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc11d.agenda_id', true),
    'parcela_id', current_setting('app.mc11d.parcela_id', true),
    'before', current_setting('app.mc11d.snapshot_before', true)::jsonb
  ) as detalhe
from setups;

set local role authenticated;

with chamada_5b_criacao as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11d.simulacao_id', true)::uuid,
    current_setting('app.mc11d.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11d.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    5000.00,
    jsonb_build_object('origem_teste', '11d', 'observacao', 'operacao confirmada e conflito rollback')
  ) as payload
)
select set_config('app.mc11d.payload_5b_criacao', coalesce((select payload::text from chamada_5b_criacao), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc11d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11d.agenda_id', true)::uuid as agenda_id
),
snapshot_after_criacao as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select a.checksum from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_tots', (select a.totais from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_updated_at', (select a.updated_at from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'status_operacao', o.status_operacao, 'confirmado', o.confirmado, 'checksum_operacao', o.checksum_operacao) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc11d.snapshot_after_criacao', coalesce((select payload::text from snapshot_after_criacao), 'null'), true);

with op_confirmada as materialized (
  update public.mesa_cliente_fluxo_operacoes o
     set status_operacao = 'confirmada',
         confirmado = true,
         confirmado_por = current_setting('app.mc11d.user_id', true)::uuid,
         confirmado_em = now(),
         visivel_cliente = false,
         metadata = coalesce(o.metadata, '{}'::jsonb) || jsonb_build_object(
           'fixture_11d_confirmada', true,
           'observacao', 'Confirmação transacional apenas para validar conflito da 5B.'
         ),
         updated_at = now()
   where o.id = (current_setting('app.mc11d.payload_5b_criacao', true)::jsonb->'operacao'->>'id')::uuid
   returning o.*
),
payload_confirmacao as (
  select jsonb_build_object(
    'operacao_id', id,
    'checksum_operacao', checksum_operacao,
    'status_operacao', status_operacao,
    'confirmado', confirmado,
    'confirmado_por', confirmado_por,
    'confirmado_em', confirmado_em,
    'visivel_cliente', visivel_cliente
  ) as payload
  from op_confirmada
)
select set_config('app.mc11d.payload_confirmacao_fixture', coalesce((select payload::text from payload_confirmacao), 'null'), true);

with ctx as (
  select
    current_setting('app.mc11d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11d.agenda_id', true)::uuid as agenda_id
),
snapshot_after_confirmacao as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select a.checksum from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_tots', (select a.totais from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_updated_at', (select a.updated_at from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'status_operacao', o.status_operacao, 'confirmado', o.confirmado, 'checksum_operacao', o.checksum_operacao) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc11d.snapshot_after_confirmacao', coalesce((select payload::text from snapshot_after_confirmacao), 'null'), true);

set local role authenticated;

with chamada_5b_mesmo_checksum as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc11d.simulacao_id', true)::uuid,
    current_setting('app.mc11d.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc11d.parcela_id', true)::uuid,
    date '2099-05-31',
    null,
    5000.00,
    jsonb_build_object('origem_teste', '11d', 'observacao', 'operacao confirmada e conflito rollback')
  ) as payload
)
select set_config('app.mc11d.payload_5b_mesmo_checksum', coalesce((select payload::text from chamada_5b_mesmo_checksum), 'null'), true);

reset role;

with ctx as (
  select
    current_setting('app.mc11d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11d.agenda_id', true)::uuid as agenda_id
),
snapshot_after_mesmo_checksum as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select a.checksum from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_tots', (select a.totais from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_updated_at', (select a.updated_at from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'status_operacao', o.status_operacao, 'confirmado', o.confirmado, 'checksum_operacao', o.checksum_operacao) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc11d.snapshot_after_mesmo_checksum', coalesce((select payload::text from snapshot_after_mesmo_checksum), 'null'), true);

set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_registrar_operacao_financeira_admin(
      current_setting('app.mc11d.simulacao_id', true)::uuid,
      current_setting('app.mc11d.agenda_id', true)::uuid,
      'antecipacao',
      current_setting('app.mc11d.parcela_id', true)::uuid,
      date '2099-05-31',
      null,
      4000.00,
      jsonb_build_object('origem_teste', '11d', 'observacao', 'conflito esperado contra operação confirmada')
    );

    perform set_config(
      'app.mc11d.payload_5b_conflito',
      jsonb_build_object('capturou_erro', false, 'payload', v_payload)::text,
      true
    );
  exception when others then
    perform set_config(
      'app.mc11d.payload_5b_conflito',
      jsonb_build_object('capturou_erro', true, 'sqlstate', sqlstate, 'message', sqlerrm)::text,
      true
    );
  end;
end $$;

reset role;

with ctx as (
  select
    current_setting('app.mc11d.simulacao_id', true)::uuid as simulacao_id,
    current_setting('app.mc11d.agenda_id', true)::uuid as agenda_id
),
snapshot_after_conflito as (
  select jsonb_build_object(
    'agenda_id', ctx.agenda_id,
    'agenda_checksum', (select a.checksum from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_tots', (select a.totais from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'agenda_updated_at', (select a.updated_at from public.mesa_cliente_agendas_financeiras a where a.id = ctx.agenda_id),
    'parcelas', (select count(*) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'valor_total_parcelas', (select coalesce(sum(fp.valor_atual), 0) from public.mesa_cliente_fluxo_parcelas fp where fp.agenda_id = ctx.agenda_id),
    'operacoes', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id),
    'operacoes_confirmadas', (select count(*) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id and o.status_operacao = 'confirmada'),
    'operacoes_lista', (select coalesce(jsonb_agg(jsonb_build_object('id', o.id, 'status_operacao', o.status_operacao, 'confirmado', o.confirmado, 'checksum_operacao', o.checksum_operacao, 'valor_movido', o.valor_movido) order by o.created_at, o.id), '[]'::jsonb) from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id and o.agenda_id = ctx.agenda_id)
  ) as payload
  from ctx
)
select set_config('app.mc11d.snapshot_after_conflito', coalesce((select payload::text from snapshot_after_conflito), 'null'), true);

with dados as (
  select
    current_setting('app.mc11d.snapshot_before', true)::jsonb as b,
    current_setting('app.mc11d.snapshot_after_criacao', true)::jsonb as c,
    current_setting('app.mc11d.snapshot_after_confirmacao', true)::jsonb as f,
    current_setting('app.mc11d.snapshot_after_mesmo_checksum', true)::jsonb as s,
    current_setting('app.mc11d.snapshot_after_conflito', true)::jsonb as a,
    current_setting('app.mc11d.payload_5b_criacao', true)::jsonb as p_criacao,
    current_setting('app.mc11d.payload_confirmacao_fixture', true)::jsonb as p_confirmacao,
    current_setting('app.mc11d.payload_5b_mesmo_checksum', true)::jsonb as p_mesmo,
    current_setting('app.mc11d.payload_5b_conflito', true)::jsonb as p_conflito
)
select
  bloco,
  status,
  detalhe
from (
  select
    '01_operacao_confirmada_fixture' as bloco,
    case
      when p_criacao->>'ok' = 'true'
       and p_criacao->>'idempotente' = 'false'
       and p_criacao->'operacao'->>'status_operacao' = 'simulada'
       and p_confirmacao->>'status_operacao' = 'confirmada'
       and p_confirmacao->>'confirmado' = 'true'
       and p_confirmacao->>'operacao_id' = p_criacao->'operacao'->>'id'
       and p_confirmacao->>'checksum_operacao' = p_criacao->'operacao'->>'checksum_operacao'
       and (c->>'operacoes')::integer = 1
       and (f->>'operacoes')::integer = 1
       and (f->>'operacoes_confirmadas')::integer = 1
    then 'PASS' else 'FAIL' end as status,
    jsonb_build_object(
      'criacao', p_criacao->'operacao',
      'confirmacao_fixture', p_confirmacao,
      'snapshot_after_criacao', c,
      'snapshot_after_confirmacao', f
    ) as detalhe
  from dados

  union all

  select
    '02_mesmo_checksum_reaproveitou_confirmada',
    case
      when p_mesmo->>'ok' = 'true'
       and p_mesmo->>'idempotente' = 'true'
       and p_mesmo->'operacao'->>'id' = p_criacao->'operacao'->>'id'
       and p_mesmo->'operacao'->>'checksum_operacao' = p_criacao->'operacao'->>'checksum_operacao'
       and p_mesmo->'operacao'->>'status_operacao' = 'confirmada'
       and p_mesmo->'operacao'->>'confirmado' = 'true'
       and (s->>'operacoes')::integer = 1
       and (s->>'operacoes_confirmadas')::integer = 1
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'idempotente_mesmo_checksum', p_mesmo->>'idempotente',
      'operacao_id_criacao', p_criacao->'operacao'->>'id',
      'operacao_id_reaproveitada', p_mesmo->'operacao'->>'id',
      'checksum_criacao', p_criacao->'operacao'->>'checksum_operacao',
      'checksum_reaproveitado', p_mesmo->'operacao'->>'checksum_operacao',
      'status_reaproveitado', p_mesmo->'operacao'->>'status_operacao',
      'confirmado_reaproveitado', p_mesmo->'operacao'->>'confirmado',
      'snapshot_after_mesmo_checksum', s
    )
  from dados

  union all

  select
    '03_conflito_confirmada_bloqueado',
    case
      when p_conflito->>'capturou_erro' = 'true'
       and p_conflito->>'sqlstate' = '55000'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'resultado_conflito', p_conflito,
      'expected_sqlstate', '55000',
      'expected_message', 'Operação financeira bloqueada: já existe operação confirmada conflitante para esta parcela/simulação.'
    )
  from dados

  union all

  select
    '04_operacao_confirmada_preservada_sem_duplicidade',
    case
      when (a->>'operacoes')::integer = 1
       and (a->>'operacoes_confirmadas')::integer = 1
       and a->'operacoes_lista'->0->>'id' = p_criacao->'operacao'->>'id'
       and a->'operacoes_lista'->0->>'status_operacao' = 'confirmada'
       and a->'operacoes_lista'->0->>'confirmado' = 'true'
       and a->'operacoes_lista'->0->>'checksum_operacao' = p_criacao->'operacao'->>'checksum_operacao'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'snapshot_after_conflito', a,
      'operacao_id_original', p_criacao->'operacao'->>'id',
      'checksum_original', p_criacao->'operacao'->>'checksum_operacao'
    )
  from dados

  union all

  select
    '05_agenda_parcelas_nao_mutadas',
    case
      when b->>'agenda_id' = a->>'agenda_id'
       and b->>'agenda_checksum' = a->>'agenda_checksum'
       and b->'agenda_tots' = a->'agenda_tots'
       and b->>'parcelas' = a->>'parcelas'
       and b->>'valor_total_parcelas' = a->>'valor_total_parcelas'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'agenda_id_before', b->>'agenda_id',
      'agenda_id_after', a->>'agenda_id',
      'checksum_before', b->>'agenda_checksum',
      'checksum_after', a->>'agenda_checksum',
      'totais_iguais', b->'agenda_tots' = a->'agenda_tots',
      'parcelas_before', b->>'parcelas',
      'parcelas_after', a->>'parcelas',
      'valor_total_parcelas_before', b->>'valor_total_parcelas',
      'valor_total_parcelas_after', a->>'valor_total_parcelas'
    )
  from dados

  union all

  select
    '06_flags_contrato_5b_preservadas_no_reaproveitamento',
    case
      when p_mesmo->>'cliente_safe' = 'false'
       and p_mesmo->>'persistencia' = 'true'
       and p_mesmo->>'dml_financeiro' = 'true'
       and p_mesmo->>'escopo_dml' = 'operacao_financeira'
       and p_mesmo->>'altera_agenda' = 'false'
       and p_mesmo->>'altera_parcelas' = 'false'
    then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'cliente_safe', p_mesmo->>'cliente_safe',
      'persistencia', p_mesmo->>'persistencia',
      'dml_financeiro', p_mesmo->>'dml_financeiro',
      'escopo_dml', p_mesmo->>'escopo_dml',
      'altera_agenda', p_mesmo->>'altera_agenda',
      'altera_parcelas', p_mesmo->>'altera_parcelas'
    )
  from dados

  union all

  select
    '99_rollback_notice',
    'INFO',
    jsonb_build_object('mensagem', 'Teste 11D encerra com ROLLBACK. Nada deve permanecer no banco.')
) r
order by bloco;

rollback;
