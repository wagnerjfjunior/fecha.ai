-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4B
-- 08B — Validação de idempotência da persistência da agenda financeira com rollback.
--
-- Objetivo:
--   Chamar duas vezes a RPC:
--     public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)
--   com exatamente a mesma simulação e o mesmo payload.
--
-- Critérios:
--   - Primeira chamada cria 1 agenda ativa e 6 parcelas.
--   - Segunda chamada retorna idempotente=true.
--   - Segunda chamada não cria nova agenda.
--   - Segunda chamada não duplica parcelas.
--   - Checksum e agenda_id permanecem iguais.
--   - Não cria operação financeira.
--   - Termina com ROLLBACK.

begin;

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
    coalesce(c.ativo, true) as ativo,
    coalesce(c.is_admin_local, false) as is_admin_local,
    coalesce(c.is_gestor, false) as is_gestor,
    e.id as empreendimento_id,
    e.nome as empreendimento_nome
  from public.corretores c
  join public.empreendimentos e
    on e.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'root', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case
      when c.role = 'admin_global' then 1
      when c.role = 'root' then 2
      when c.role = 'admin_local' then 3
      when c.role = 'gestor' then 4
      when c.role = 'coordenador' then 5
      when coalesce(c.is_admin_local, false) then 6
      when coalesce(c.is_gestor, false) then 7
      else 8
    end,
    c.created_at desc nulls last,
    c.id,
    e.nome
  limit 1
),
fixture as materialized (
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
    'Teste rollback 08B idempotencia agenda',
    29500.50,
    10000.50,
    0,
    29500.50,
    jsonb_build_object(
      'origem', 'teste_08b_idempotencia_agenda_rollback',
      'fixture_transacional', true
    ),
    'Fixture transacional do teste 08B. Deve sumir no ROLLBACK.'
  from candidato
  returning id as simulacao_id, empresa_id, corretor_id, empreendimento_id
),
setup as (
  select
    set_config('request.jwt.claim.sub', coalesce(c.user_id::text, '00000000-0000-0000-0000-000000000000'), true),
    set_config('app.mc08b.user_id', coalesce(c.user_id::text, ''), true),
    set_config('app.mc08b.corretor_id', coalesce(c.corretor_id::text, ''), true),
    set_config('app.mc08b.empresa_id', coalesce(f.empresa_id::text, ''), true),
    set_config('app.mc08b.role', coalesce(c.role::text, ''), true),
    set_config('app.mc08b.ativo', coalesce(c.ativo::text, 'false'), true),
    set_config('app.mc08b.is_admin_local', coalesce(c.is_admin_local::text, 'false'), true),
    set_config('app.mc08b.is_gestor', coalesce(c.is_gestor::text, 'false'), true),
    set_config('app.mc08b.simulacao_id', coalesce(f.simulacao_id::text, ''), true),
    set_config('app.mc08b.empreendimento_id', coalesce(f.empreendimento_id::text, ''), true),
    set_config('app.mc08b.empreendimento_nome', coalesce(c.empreendimento_nome::text, ''), true),
    set_config('app.mc08b.qtd_ctx', case when f.simulacao_id is null then '0' else '1' end, true)
  from candidato c
  join fixture f on true
)
select * from setup;

with ctx as (
  select
    nullif(current_setting('app.mc08b.simulacao_id', true), '')::uuid as simulacao_id
)
select
  set_config('app.mc08b.agendas_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_agendas_financeiras a
    join ctx on ctx.simulacao_id = a.simulacao_id
  ), '0'), true),
  set_config('app.mc08b.parcelas_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_fluxo_parcelas p
    join ctx on ctx.simulacao_id = p.simulacao_id
  ), '0'), true),
  set_config('app.mc08b.operacoes_before', coalesce((
    select count(*)::text
    from public.mesa_cliente_fluxo_operacoes o
    join ctx on ctx.simulacao_id = o.simulacao_id
  ), '0'), true)
from ctx;

set local role authenticated;

with ctx as materialized (
  select
    nullif(current_setting('app.mc08b.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc08b.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc08b.simulacao_id', true), '')::uuid as simulacao_id,
    coalesce(nullif(current_setting('app.mc08b.qtd_ctx', true), '')::integer, 0) as qtd_ctx
),
input as materialized (
  select
    ctx.*,
    date '2099-05-31' as data_ato,
    jsonb_build_array(
      jsonb_build_object(
        'grupo', 'entrada',
        'descricao', 'Sinal ato',
        'valor', '10000,50',
        'data', '2099-05-31'
      ),
      jsonb_build_object(
        'grupo', 'mensais',
        'descricao', 'Mensais',
        'valor', '2500.00',
        'quantidade', 3,
        'mes_ano', '06/2099'
      ),
      jsonb_build_object(
        'grupo', 'intermediarias',
        'descricao', 'Intermediária anual',
        'valor', '12000',
        'mes_ano', '2099-12'
      ),
      jsonb_build_object(
        'grupo', 'periodicidade',
        'descricao', 'Periodicidade simbólica',
        'valor', 0,
        'mes_ano', '07/2099'
      )
    ) as fluxo_json,
    jsonb_build_object(
      'empresa_id', ctx.empresa_id,
      'empreendimento_id', ctx.empreendimento_id,
      'origem', 'teste_08b_idempotencia_agenda'
    ) as payload_tabela
  from ctx
),
primeira_chamada as materialized (
  select
    case
      when qtd_ctx = 1 and simulacao_id is not null then
        public.mesa_cliente_persistir_agenda_financeira_admin(
          simulacao_id,
          data_ato,
          fluxo_json,
          payload_tabela
        )
      else null::jsonb
    end as payload1
  from input
),
segunda_chamada as materialized (
  select
    case
      when i.qtd_ctx = 1 and i.simulacao_id is not null then
        public.mesa_cliente_persistir_agenda_financeira_admin(
          i.simulacao_id,
          i.data_ato,
          i.fluxo_json,
          i.payload_tabela
        )
      else null::jsonb
    end as payload2
  from input i
  cross join primeira_chamada p1
)
select
  set_config('app.mc08b.payload1', coalesce((select payload1::text from primeira_chamada), 'null'), true),
  set_config('app.mc08b.payload2', coalesce((select payload2::text from segunda_chamada), 'null'), true);

reset role;

with ctx as materialized (
  select
    nullif(current_setting('app.mc08b.user_id', true), '')::uuid as user_id,
    nullif(current_setting('app.mc08b.corretor_id', true), '')::uuid as corretor_id,
    nullif(current_setting('app.mc08b.empresa_id', true), '')::uuid as empresa_id,
    nullif(current_setting('app.mc08b.empreendimento_id', true), '')::uuid as empreendimento_id,
    nullif(current_setting('app.mc08b.simulacao_id', true), '')::uuid as simulacao_id,
    nullif(current_setting('app.mc08b.role', true), '') as role,
    coalesce(nullif(current_setting('app.mc08b.ativo', true), '')::boolean, false) as ativo,
    coalesce(nullif(current_setting('app.mc08b.is_admin_local', true), '')::boolean, false) as is_admin_local,
    coalesce(nullif(current_setting('app.mc08b.is_gestor', true), '')::boolean, false) as is_gestor,
    nullif(current_setting('app.mc08b.empreendimento_nome', true), '') as empreendimento_nome,
    coalesce(nullif(current_setting('app.mc08b.qtd_ctx', true), '')::integer, 0) as qtd_ctx,
    coalesce(nullif(current_setting('app.mc08b.agendas_before', true), '')::bigint, 0) as agendas_before,
    coalesce(nullif(current_setting('app.mc08b.parcelas_before', true), '')::bigint, 0) as parcelas_before,
    coalesce(nullif(current_setting('app.mc08b.operacoes_before', true), '')::bigint, 0) as operacoes_before,
    coalesce(nullif(current_setting('app.mc08b.payload1', true), '')::jsonb, 'null'::jsonb) as payload1,
    coalesce(nullif(current_setting('app.mc08b.payload2', true), '')::jsonb, 'null'::jsonb) as payload2
),
after_counts as materialized (
  select
    ctx.simulacao_id,
    (select count(*)::bigint from public.mesa_cliente_agendas_financeiras a where a.simulacao_id = ctx.simulacao_id) as agendas_after,
    (select count(*)::bigint from public.mesa_cliente_fluxo_parcelas p where p.simulacao_id = ctx.simulacao_id) as parcelas_after,
    (select count(*)::bigint from public.mesa_cliente_fluxo_operacoes o where o.simulacao_id = ctx.simulacao_id) as operacoes_after
  from ctx
),
db_agenda as materialized (
  select
    a.id as agenda_id,
    a.simulacao_id,
    a.empresa_id,
    a.empreendimento_id,
    a.status,
    coalesce((a.totais->>'qtd_parcelas')::integer, 0) as qtd_parcelas,
    coalesce((a.totais->>'valor_total')::numeric, 0) as valor_total_agenda,
    a.checksum,
    a.versao
  from public.mesa_cliente_agendas_financeiras a
  join ctx on ctx.simulacao_id = a.simulacao_id
  order by a.created_at desc
  limit 1
),
db_parcelas as materialized (
  select
    count(*)::integer as qtd_parcelas_db,
    coalesce(sum(p.valor_atual), 0)::numeric as valor_total_parcelas_db,
    count(distinct p.agenda_id)::integer as qtd_agendas_nas_parcelas,
    count(*) filter (where p.agenda_id is not null)::integer as qtd_com_agenda_id
  from public.mesa_cliente_fluxo_parcelas p
  join ctx on ctx.simulacao_id = p.simulacao_id
),
p as materialized (
  select
    c.*,
    ac.agendas_after,
    ac.parcelas_after,
    ac.operacoes_after,
    (c.payload1->>'ok')::boolean as ok1,
    c.payload1->>'fase' as fase1,
    (c.payload1->>'idempotente')::boolean as idempotente1,
    nullif(c.payload1->>'agenda_id', '')::uuid as agenda_id_payload1,
    c.payload1->>'checksum' as checksum_payload1,
    (c.payload1->>'qtd_parcelas_persistidas')::integer as qtd_parcelas_payload1,
    (c.payload2->>'ok')::boolean as ok2,
    c.payload2->>'fase' as fase2,
    (c.payload2->>'idempotente')::boolean as idempotente2,
    nullif(c.payload2->>'agenda_id', '')::uuid as agenda_id_payload2,
    c.payload2->>'checksum' as checksum_payload2,
    (c.payload2->>'qtd_parcelas_persistidas')::integer as qtd_parcelas_payload2,
    (c.payload2->>'cliente_safe')::boolean as cliente_safe2,
    c.payload2->>'visao' as visao2,
    da.agenda_id as agenda_id_db,
    da.status as agenda_status_db,
    da.qtd_parcelas as qtd_parcelas_agenda_db,
    da.valor_total_agenda as valor_total_agenda_db,
    da.checksum as checksum_db,
    da.versao as versao_db,
    dp.qtd_parcelas_db,
    dp.valor_total_parcelas_db,
    dp.qtd_agendas_nas_parcelas,
    dp.qtd_com_agenda_id
  from ctx c
  cross join after_counts ac
  left join db_agenda da on true
  cross join db_parcelas dp
)
select
  '01_fixture_transacional_contexto' as bloco,
  case
    when qtd_ctx = 1
      and user_id is not null
      and empresa_id is not null
      and empreendimento_id is not null
      and simulacao_id is not null
    then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'user_id', user_id,
    'corretor_id', corretor_id,
    'empresa_id', empresa_id,
    'empreendimento_id', empreendimento_id,
    'empreendimento_nome', empreendimento_nome,
    'simulacao_id_fixture', simulacao_id,
    'role', role,
    'ativo', ativo,
    'is_admin_local', is_admin_local,
    'is_gestor', is_gestor
  ) as detalhe
from p

union all

select
  '02_primeira_chamada_criou_agenda',
  case
    when ok1 is true
      and fase1 = '4B_PERSISTENCIA_AGENDA'
      and idempotente1 is false
      and agenda_id_payload1 is not null
      and checksum_payload1 is not null
      and qtd_parcelas_payload1 = 6
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'ok1', ok1,
    'fase1', fase1,
    'idempotente1', idempotente1,
    'agenda_id_payload1', agenda_id_payload1,
    'checksum_payload1', checksum_payload1,
    'qtd_parcelas_payload1', qtd_parcelas_payload1
  )
from p

union all

select
  '03_segunda_chamada_idempotente',
  case
    when ok2 is true
      and fase2 = '4B_PERSISTENCIA_AGENDA'
      and idempotente2 is true
      and agenda_id_payload2 = agenda_id_payload1
      and checksum_payload2 = checksum_payload1
      and qtd_parcelas_payload2 = 6
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'ok2', ok2,
    'fase2', fase2,
    'idempotente2', idempotente2,
    'agenda_id_payload2', agenda_id_payload2,
    'checksum_payload2', checksum_payload2,
    'qtd_parcelas_payload2', qtd_parcelas_payload2,
    'agenda_id_payload1', agenda_id_payload1,
    'checksum_payload1', checksum_payload1
  )
from p

union all

select
  '04_nao_duplicou_agenda',
  case
    when agendas_before = 0
      and agendas_after = 1
      and agenda_id_db = agenda_id_payload1
      and agenda_id_db = agenda_id_payload2
      and agenda_status_db = 'ativa'
      and versao_db = 1
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'agendas_before', agendas_before,
    'agendas_after', agendas_after,
    'agenda_id_db', agenda_id_db,
    'agenda_status_db', agenda_status_db,
    'versao_db', versao_db,
    'agenda_id_payload1', agenda_id_payload1,
    'agenda_id_payload2', agenda_id_payload2
  )
from p

union all

select
  '05_nao_duplicou_parcelas',
  case
    when parcelas_before = 0
      and parcelas_after = 6
      and qtd_parcelas_db = 6
      and qtd_com_agenda_id = 6
      and qtd_agendas_nas_parcelas = 1
      and qtd_parcelas_agenda_db = 6
      and valor_total_parcelas_db = 29500.50
      and valor_total_agenda_db = 29500.50
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'parcelas_before', parcelas_before,
    'parcelas_after', parcelas_after,
    'qtd_parcelas_db', qtd_parcelas_db,
    'qtd_com_agenda_id', qtd_com_agenda_id,
    'qtd_agendas_nas_parcelas', qtd_agendas_nas_parcelas,
    'qtd_parcelas_agenda_db', qtd_parcelas_agenda_db,
    'valor_total_parcelas_db', valor_total_parcelas_db,
    'valor_total_agenda_db', valor_total_agenda_db
  )
from p

union all

select
  '06_checksum_consistente',
  case
    when checksum_db = checksum_payload1
      and checksum_db = checksum_payload2
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'checksum_db', checksum_db,
    'checksum_payload1', checksum_payload1,
    'checksum_payload2', checksum_payload2
  )
from p

union all

select
  '07_payload_admin_nao_cliente_safe',
  case
    when visao2 = 'administrativa'
      and cliente_safe2 is false
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'visao2', visao2,
    'cliente_safe2', cliente_safe2
  )
from p

union all

select
  '08_zero_dml_operacoes',
  case
    when operacoes_before = operacoes_after
      and operacoes_after = 0
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'operacoes_before', operacoes_before,
    'operacoes_after', operacoes_after
  )
from p

union all

select
  '09_rollback_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Agenda, parcelas e fixture foram criadas apenas dentro da transação. Tudo será encerrado com ROLLBACK.'
  )
from p;

rollback;
