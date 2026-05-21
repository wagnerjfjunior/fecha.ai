-- =====================================================================
-- MesaCliente / Engenharia Financeira
-- Fase 7 — Aplicação de Operação Financeira
-- Teste 15C — Segurança negativa da RPC de aplicação admin
--
-- Objetivo:
--   Validar que public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
--   respeita auth, escopo multi-tenant, perfil administrativo, bloqueio de
--   parâmetros soberanos vindos do frontend, status aplicáveis e idempotência.
--
-- Escopo:
--   - Cria fixture transacional 4B/5B/5C.
--   - Usa 4 parcelas distintas para evitar colisão/idempotência da 5B.
--   - Não deve deixar dados persistidos: encerra com ROLLBACK.
--
-- Observação técnica:
--   A operação cancelada é preparada por DML direto dentro da fixture
--   transacional porque a 5C vigente bloqueia cancelamento de operação
--   confirmada. O objetivo aqui não é testar cancelamento da 5C, mas sim
--   provar que a Fase 7 não aplica operação em status cancelada.
-- =====================================================================

begin;

select set_config('app.mc15c.results', '[]', true);
select set_config('request.jwt.claim.sub', '', true);
select set_config('app.mc15c.admin_user', '', true);
select set_config('app.mc15c.corretor_user', '', true);
select set_config('app.mc15c.admin_outro_user', '', true);
select set_config('app.mc15c.simulacao_id', '', true);
select set_config('app.mc15c.agenda_id', '', true);
select set_config('app.mc15c.parcela_confirmada_id', '', true);
select set_config('app.mc15c.parcela_simulada_id', '', true);
select set_config('app.mc15c.parcela_cancelada_id', '', true);
select set_config('app.mc15c.parcela_idempotencia_id', '', true);
select set_config('app.mc15c.operacao_confirmada_id', '', true);
select set_config('app.mc15c.operacao_simulada_id', '', true);
select set_config('app.mc15c.operacao_cancelada_id', '', true);
select set_config('app.mc15c.operacao_idempotencia_id', '', true);
select set_config('app.mc15c.payload_4b', 'null', true);
select set_config('app.mc15c.payload_aplicacao_1', 'null', true);
select set_config('app.mc15c.valor_confirmada_antes', '0', true);
select set_config('app.mc15c.valor_confirmada_depois', '0', true);
select set_config('app.mc15c.status_confirmada_antes', '', true);
select set_config('app.mc15c.status_confirmada_depois', '', true);
select set_config('app.mc15c.operacoes_antes_negativos', '0', true);
select set_config('app.mc15c.operacoes_depois_negativos', '0', true);
select set_config('app.mc15c.parcelas_antes_negativos', '0', true);
select set_config('app.mc15c.parcelas_depois_negativos', '0', true);
select set_config('app.mc15c.valor_pos_primeira_aplicacao', '0', true);
select set_config('app.mc15c.valor_pos_segunda_tentativa', '0', true);
select set_config('app.mc15c.data_ato', (current_date + interval '730 days')::date::text, true);
select set_config('app.mc15c.mes_1', to_char((current_date + interval '760 days')::date, 'MM/YYYY'), true);
select set_config('app.mc15c.mes_2', to_char((current_date + interval '790 days')::date, 'MM/YYYY'), true);
select set_config('app.mc15c.mes_3', to_char((current_date + interval '820 days')::date, 'MM/YYYY'), true);
select set_config('app.mc15c.mes_4', to_char((current_date + interval '850 days')::date, 'MM/YYYY'), true);
select set_config('app.mc15c.politica_mes_referencia', date_trunc('month', current_date + interval '27 years')::date::text, true);
select set_config('app.mc15c.politica_vigencia_inicio', (current_date - interval '1 year')::date::text, true);
select set_config('app.mc15c.politica_vigencia_fim', (current_date + interval '27 years')::date::text, true);

create or replace function pg_temp.mc15c_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.mc15c.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc15c.results',
    (
      v_atual
      || jsonb_build_array(
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

-- ---------------------------------------------------------------------
-- 00 — Setup da fixture de segurança
-- ---------------------------------------------------------------------
with base_empresa as materialized (
  select c.empresa_id
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
  group by c.empresa_id
  having count(*) filter (
    where coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
       or coalesce(c.is_admin_local, false)
       or coalesce(c.is_gestor, false)
  ) >= 1
  and count(*) filter (
    where not (
      coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  ) >= 1
  order by count(*) desc, c.empresa_id
  limit 1
),
admin_mesmo_tenant as materialized (
  select c.*
  from public.corretores c
  join base_empresa b on b.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case
      when c.role = 'admin_global' then 9
      when c.role = 'admin_local' then 1
      when c.role = 'gestor' then 2
      when c.role = 'coordenador' then 3
      else 4
    end,
    c.created_at desc nulls last,
    c.id
  limit 1
),
corretor_comum as materialized (
  select c.*
  from public.corretores c
  join base_empresa b on b.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and not (
      coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by c.created_at desc nulls last, c.id
  limit 1
),
admin_outro_tenant as materialized (
  select c.*
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and c.empresa_id <> (select empresa_id from base_empresa)
    and coalesce(c.role, '') <> 'admin_global'
    and (
      coalesce(c.role, '') in ('admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by c.created_at desc nulls last, c.id
  limit 1
),
empreendimento_base as materialized (
  select e.id as empreendimento_id, b.empresa_id
  from base_empresa b
  join public.empreendimentos e on e.empresa_id = b.empresa_id
  order by e.created_at desc nulls last, e.id
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
    e.empresa_id,
    c.id,
    e.empreendimento_id,
    'Teste rollback 15C seguranca negativa fase 7 v3',
    125000.00,
    35000.00,
    0,
    125000.00,
    jsonb_build_object(
      'origem_teste', '15c_fase_7_rollback_v3',
      'fixture_transacional', true
    ),
    'Fixture transacional 15C v3. Deve sumir no ROLLBACK.'
  from empreendimento_base e
  join corretor_comum c on true
  returning *
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
    e.empresa_id,
    e.empreendimento_id,
    current_setting('app.mc15c.politica_mes_referencia', true)::date,
    current_setting('app.mc15c.politica_vigencia_inicio', true)::date,
    current_setting('app.mc15c.politica_vigencia_fim', true)::date,
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true, true, true, true,
    true, true, true, true,
    true, true, true, true,
    true,
    'Fixture transacional 15C v3 para seguranca negativa fase 7.'
  from empreendimento_base e
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
    ativo = true,
    observacoes = excluded.observacoes,
    updated_at = now()
  returning *
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
  select
    p.empresa_id,
    p.id,
    v.vpl_de_pct,
    v.vpl_ate_pct,
    v.premio_corretor_pct,
    v.status,
    v.descricao,
    v.ordem,
    true
  from politica p
  cross join (
    values
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 15C v3 — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 15C v3 — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 15C v3 — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('app.mc15c.admin_user', (select user_id::text from admin_mesmo_tenant), true),
    set_config('app.mc15c.corretor_user', (select user_id::text from corretor_comum), true),
    set_config('app.mc15c.admin_outro_user', coalesce((select user_id::text from admin_outro_tenant), ''), true),
    set_config('app.mc15c.simulacao_id', (select id::text from simulacao), true)
)
select pg_temp.mc15c_add_result(
  '00_setup_seguranca_fixture',
  case
    when current_setting('app.mc15c.admin_user', true) <> ''
     and current_setting('app.mc15c.corretor_user', true) <> ''
     and current_setting('app.mc15c.simulacao_id', true) <> ''
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'admin_user', current_setting('app.mc15c.admin_user', true),
    'corretor_comum_user', current_setting('app.mc15c.corretor_user', true),
    'admin_outro_tenant_user', current_setting('app.mc15c.admin_outro_user', true),
    'simulacao_id', current_setting('app.mc15c.simulacao_id', true),
    'qtd_faixas', (select count(*) from faixas)
  )
)
from setup;

-- ---------------------------------------------------------------------
-- 01 — Agenda e 4 parcelas distintas
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_user', true), true);
set local role authenticated;

select set_config(
  'app.mc15c.payload_4b',
  public.mesa_cliente_persistir_agenda_financeira_admin(
    current_setting('app.mc15c.simulacao_id', true)::uuid,
    current_setting('app.mc15c.data_ato', true)::date,
    jsonb_build_array(
      jsonb_build_object(
        'grupo', 'mensais',
        'descricao', 'Mensais 15C confirmada',
        'valor', '3000.00',
        'quantidade', 1,
        'mes_ano', current_setting('app.mc15c.mes_1', true)
      ),
      jsonb_build_object(
        'grupo', 'mensais',
        'descricao', 'Mensais 15C simulada',
        'valor', '3100.00',
        'quantidade', 1,
        'mes_ano', current_setting('app.mc15c.mes_2', true)
      ),
      jsonb_build_object(
        'grupo', 'intermediarias',
        'descricao', 'Intermediária 15C cancelada',
        'valor', '10000.00',
        'quantidade', 1,
        'mes_ano', current_setting('app.mc15c.mes_3', true)
      ),
      jsonb_build_object(
        'grupo', 'intermediarias',
        'descricao', 'Intermediária 15C idempotencia',
        'valor', '11000.00',
        'quantidade', 1,
        'mes_ano', current_setting('app.mc15c.mes_4', true)
      )
    ),
    jsonb_build_object('origem_teste', '15c_v3')
  )::text,
  true
);

reset role;

with agenda as (
  select a.id
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = current_setting('app.mc15c.simulacao_id', true)::uuid
    and a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcelas as (
  select
    p.id,
    p.valor_atual,
    row_number() over (order by p.data_atual asc, p.valor_atual asc, p.id asc) as rn
  from public.mesa_cliente_fluxo_parcelas p
  join agenda a on a.id = p.agenda_id
  where p.valor_atual > 0
    and p.data_atual > current_date
    and coalesce(p.eh_periodicidade_simbolica, false) = false
    and coalesce(p.pode_receber_antecipacao, false) = true
)
select
  set_config('app.mc15c.agenda_id', (select id::text from agenda), true),
  set_config('app.mc15c.parcela_confirmada_id', (select id::text from parcelas where rn = 1), true),
  set_config('app.mc15c.parcela_simulada_id', (select id::text from parcelas where rn = 2), true),
  set_config('app.mc15c.parcela_cancelada_id', (select id::text from parcelas where rn = 3), true),
  set_config('app.mc15c.parcela_idempotencia_id', (select id::text from parcelas where rn = 4), true),
  set_config('app.mc15c.valor_confirmada_antes', (select valor_atual::text from parcelas where rn = 1), true);

select pg_temp.mc15c_add_result(
  '01_agenda_parcelas_distintas_fixture',
  case
    when current_setting('app.mc15c.payload_4b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc15c.parcela_confirmada_id', true) <> ''
     and current_setting('app.mc15c.parcela_simulada_id', true) <> ''
     and current_setting('app.mc15c.parcela_cancelada_id', true) <> ''
     and current_setting('app.mc15c.parcela_idempotencia_id', true) <> ''
     and current_setting('app.mc15c.parcela_confirmada_id', true) <> current_setting('app.mc15c.parcela_simulada_id', true)
     and current_setting('app.mc15c.parcela_simulada_id', true) <> current_setting('app.mc15c.parcela_cancelada_id', true)
     and current_setting('app.mc15c.parcela_cancelada_id', true) <> current_setting('app.mc15c.parcela_idempotencia_id', true)
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'payload_4b_ok', current_setting('app.mc15c.payload_4b', true)::jsonb->>'ok',
    'agenda_id', current_setting('app.mc15c.agenda_id', true),
    'parcela_confirmada_id', current_setting('app.mc15c.parcela_confirmada_id', true),
    'parcela_simulada_id', current_setting('app.mc15c.parcela_simulada_id', true),
    'parcela_cancelada_id', current_setting('app.mc15c.parcela_cancelada_id', true),
    'parcela_idempotencia_id', current_setting('app.mc15c.parcela_idempotencia_id', true),
    'valor_confirmada_antes', current_setting('app.mc15c.valor_confirmada_antes', true)
  )
);

-- ---------------------------------------------------------------------
-- 02 — Operações distintas nos estados necessários
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_user', true), true);
set local role authenticated;

select set_config(
  'app.mc15c.operacao_confirmada_id',
  (
    public.mesa_cliente_registrar_operacao_financeira_admin(
      current_setting('app.mc15c.simulacao_id', true)::uuid,
      current_setting('app.mc15c.agenda_id', true)::uuid,
      'antecipacao',
      current_setting('app.mc15c.parcela_confirmada_id', true)::uuid,
      current_date,
      null,
      null,
      jsonb_build_object('origem_teste', '15c_confirmada_v3')
    )::jsonb->'operacao'->>'id'
  ),
  true
);

select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
  current_setting('app.mc15c.operacao_confirmada_id', true)::uuid,
  'confirmar',
  null,
  jsonb_build_object('origem_teste', '15c_confirmar_v3')
);

select set_config(
  'app.mc15c.operacao_simulada_id',
  (
    public.mesa_cliente_registrar_operacao_financeira_admin(
      current_setting('app.mc15c.simulacao_id', true)::uuid,
      current_setting('app.mc15c.agenda_id', true)::uuid,
      'antecipacao',
      current_setting('app.mc15c.parcela_simulada_id', true)::uuid,
      current_date,
      null,
      null,
      jsonb_build_object('origem_teste', '15c_simulada_v3')
    )::jsonb->'operacao'->>'id'
  ),
  true
);

select set_config(
  'app.mc15c.operacao_cancelada_id',
  (
    public.mesa_cliente_registrar_operacao_financeira_admin(
      current_setting('app.mc15c.simulacao_id', true)::uuid,
      current_setting('app.mc15c.agenda_id', true)::uuid,
      'antecipacao',
      current_setting('app.mc15c.parcela_cancelada_id', true)::uuid,
      current_date,
      null,
      null,
      jsonb_build_object('origem_teste', '15c_cancelada_v3')
    )::jsonb->'operacao'->>'id'
  ),
  true
);

select set_config(
  'app.mc15c.operacao_idempotencia_id',
  (
    public.mesa_cliente_registrar_operacao_financeira_admin(
      current_setting('app.mc15c.simulacao_id', true)::uuid,
      current_setting('app.mc15c.agenda_id', true)::uuid,
      'antecipacao',
      current_setting('app.mc15c.parcela_idempotencia_id', true)::uuid,
      current_date,
      null,
      null,
      jsonb_build_object('origem_teste', '15c_idempotencia_v3')
    )::jsonb->'operacao'->>'id'
  ),
  true
);

select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
  current_setting('app.mc15c.operacao_idempotencia_id', true)::uuid,
  'confirmar',
  null,
  jsonb_build_object('origem_teste', '15c_idempotencia_confirmar_v3')
);

reset role;

-- Preparação controlada da operação cancelada somente para cenário negativo.
update public.mesa_cliente_fluxo_operacoes
set
  status_operacao = 'cancelada',
  confirmado = false,
  cancelado_por = current_setting('app.mc15c.admin_user', true)::uuid,
  cancelado_em = now(),
  motivo_cancelamento = 'fixture transacional 15C v3 — cancelada direta para teste negativo fase 7',
  updated_at = now()
where id = current_setting('app.mc15c.operacao_cancelada_id', true)::uuid;

select set_config(
  'app.mc15c.status_confirmada_antes',
  (
    select status_operacao
    from public.mesa_cliente_fluxo_operacoes
    where id = current_setting('app.mc15c.operacao_confirmada_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15c.operacoes_antes_negativos',
  (
    select count(*)::text
    from public.mesa_cliente_fluxo_operacoes
    where simulacao_id = current_setting('app.mc15c.simulacao_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15c.parcelas_antes_negativos',
  (
    select count(*)::text
    from public.mesa_cliente_fluxo_parcelas
    where simulacao_id = current_setting('app.mc15c.simulacao_id', true)::uuid
  ),
  true
);

select pg_temp.mc15c_add_result(
  '02_operacoes_fixture_estados_distintos',
  case
    when current_setting('app.mc15c.operacao_confirmada_id', true) <> current_setting('app.mc15c.operacao_simulada_id', true)
     and current_setting('app.mc15c.operacao_simulada_id', true) <> current_setting('app.mc15c.operacao_cancelada_id', true)
     and current_setting('app.mc15c.operacao_cancelada_id', true) <> current_setting('app.mc15c.operacao_idempotencia_id', true)
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes
       where id = current_setting('app.mc15c.operacao_confirmada_id', true)::uuid
         and status_operacao = 'confirmada'
     )
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes
       where id = current_setting('app.mc15c.operacao_simulada_id', true)::uuid
         and status_operacao = 'simulada'
     )
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes
       where id = current_setting('app.mc15c.operacao_cancelada_id', true)::uuid
         and status_operacao = 'cancelada'
     )
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes
       where id = current_setting('app.mc15c.operacao_idempotencia_id', true)::uuid
         and status_operacao = 'confirmada'
     )
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'operacao_confirmada_id', current_setting('app.mc15c.operacao_confirmada_id', true),
    'operacao_simulada_id', current_setting('app.mc15c.operacao_simulada_id', true),
    'operacao_cancelada_id', current_setting('app.mc15c.operacao_cancelada_id', true),
    'operacao_idempotencia_id', current_setting('app.mc15c.operacao_idempotencia_id', true),
    'status_confirmada', (
      select status_operacao
      from public.mesa_cliente_fluxo_operacoes
      where id = current_setting('app.mc15c.operacao_confirmada_id', true)::uuid
    ),
    'status_simulada', (
      select status_operacao
      from public.mesa_cliente_fluxo_operacoes
      where id = current_setting('app.mc15c.operacao_simulada_id', true)::uuid
    ),
    'status_cancelada', (
      select status_operacao
      from public.mesa_cliente_fluxo_operacoes
      where id = current_setting('app.mc15c.operacao_cancelada_id', true)::uuid
    ),
    'status_idempotencia', (
      select status_operacao
      from public.mesa_cliente_fluxo_operacoes
      where id = current_setting('app.mc15c.operacao_idempotencia_id', true)::uuid
    )
  )
);

-- ---------------------------------------------------------------------
-- 03 — Bloqueio sem auth
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', '', true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_aplicar_operacao_financeira_admin(
      current_setting('app.mc15c.operacao_confirmada_id', true)::uuid,
      jsonb_build_object('origem_teste', '15c_sem_auth_v3')
    );

    perform pg_temp.mc15c_add_result(
      '03_bloqueio_sem_auth',
      'FAIL',
      jsonb_build_object('motivo', 'sem_auth_aplicou', 'payload', v_payload)
    );
  exception when others then
    perform pg_temp.mc15c_add_result(
      '03_bloqueio_sem_auth',
      case when sqlstate = '28000' and sqlerrm = 'auth_required' then 'PASS' else 'FAIL' end,
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- ---------------------------------------------------------------------
-- 04 — Bloqueio de corretor comum
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.corretor_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_aplicar_operacao_financeira_admin(
      current_setting('app.mc15c.operacao_confirmada_id', true)::uuid,
      jsonb_build_object('origem_teste', '15c_corretor_comum_v3')
    );

    perform pg_temp.mc15c_add_result(
      '04_bloqueio_corretor_comum',
      'FAIL',
      jsonb_build_object('motivo', 'corretor_comum_aplicou', 'payload', v_payload)
    );
  exception when others then
    perform pg_temp.mc15c_add_result(
      '04_bloqueio_corretor_comum',
      case when sqlstate = '42501' and sqlerrm = 'profile_not_allowed' then 'PASS' else 'FAIL' end,
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- ---------------------------------------------------------------------
-- 05 — Bloqueio cross-tenant
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_outro_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  if current_setting('app.mc15c.admin_outro_user', true) = '' then
    perform pg_temp.mc15c_add_result(
      '05_bloqueio_cross_tenant',
      'SKIP',
      jsonb_build_object('motivo', 'sem_admin_outro_tenant_nao_global_disponivel')
    );
  else
    begin
      v_payload := public.mesa_cliente_aplicar_operacao_financeira_admin(
        current_setting('app.mc15c.operacao_confirmada_id', true)::uuid,
        jsonb_build_object('origem_teste', '15c_cross_tenant_v3')
      );

      perform pg_temp.mc15c_add_result(
        '05_bloqueio_cross_tenant',
        'FAIL',
        jsonb_build_object('motivo', 'cross_tenant_aplicou', 'payload', v_payload)
      );
    exception when others then
      perform pg_temp.mc15c_add_result(
        '05_bloqueio_cross_tenant',
        case when sqlstate = '42501' and sqlerrm = 'cross_tenant_denied' then 'PASS' else 'FAIL' end,
        jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
      );
    end;
  end if;
end $$;

reset role;

-- ---------------------------------------------------------------------
-- 06 — Bloqueio de parâmetros soberanos vindos do frontend
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_user', true), true);
set local role authenticated;

do $$
declare
  v_key text;
  v_payload jsonb;
  v_pass int := 0;
  v_fail int := 0;
  v_details jsonb := '[]'::jsonb;
begin
  foreach v_key in array array[
    'empresa_id',
    'tenant_id',
    'status_operacao',
    'valor_movido',
    'metadata',
    'visao',
    'cliente_safe'
  ] loop
    begin
      v_payload := public.mesa_cliente_aplicar_operacao_financeira_admin(
        current_setting('app.mc15c.operacao_confirmada_id', true)::uuid,
        jsonb_build_object(v_key, 'tentativa_frontend_soberano')
      );

      v_fail := v_fail + 1;
      v_details := v_details || jsonb_build_array(
        jsonb_build_object(
          'key', v_key,
          'status', 'FAIL',
          'motivo', 'parametro_soberano_aceito',
          'payload', v_payload
        )
      );
    exception when others then
      if sqlstate = '42501' and sqlerrm = 'frontend_authority_forbidden:' || v_key then
        v_pass := v_pass + 1;
        v_details := v_details || jsonb_build_array(
          jsonb_build_object(
            'key', v_key,
            'status', 'PASS',
            'sqlstate', sqlstate,
            'message', sqlerrm
          )
        );
      else
        v_fail := v_fail + 1;
        v_details := v_details || jsonb_build_array(
          jsonb_build_object(
            'key', v_key,
            'status', 'FAIL',
            'sqlstate', sqlstate,
            'message', sqlerrm
          )
        );
      end if;
    end;
  end loop;

  perform pg_temp.mc15c_add_result(
    '06_bloqueio_parametros_soberanos',
    case when v_fail = 0 and v_pass = 7 then 'PASS' else 'FAIL' end,
    jsonb_build_object(
      'pass_count', v_pass,
      'fail_count', v_fail,
      'detalhes', v_details
    )
  );
end $$;

reset role;

-- ---------------------------------------------------------------------
-- 07 — Bloqueio de p_parametros não objeto
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_aplicar_operacao_financeira_admin(
      current_setting('app.mc15c.operacao_confirmada_id', true)::uuid,
      '[]'::jsonb
    );

    perform pg_temp.mc15c_add_result(
      '07_bloqueio_parametros_nao_objeto',
      'FAIL',
      jsonb_build_object('motivo', 'parametros_array_aceitos', 'payload', v_payload)
    );
  exception when others then
    perform pg_temp.mc15c_add_result(
      '07_bloqueio_parametros_nao_objeto',
      case when sqlstate = '22023' and sqlerrm = 'p_parametros_must_be_object' then 'PASS' else 'FAIL' end,
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- ---------------------------------------------------------------------
-- 08 — Operação simulada não pode ser aplicada
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_aplicar_operacao_financeira_admin(
      current_setting('app.mc15c.operacao_simulada_id', true)::uuid,
      jsonb_build_object('origem_teste', '15c_operacao_simulada_v3')
    );

    perform pg_temp.mc15c_add_result(
      '08_bloqueio_operacao_nao_confirmada',
      'FAIL',
      jsonb_build_object('motivo', 'operacao_simulada_aplicada', 'payload', v_payload)
    );
  exception when others then
    perform pg_temp.mc15c_add_result(
      '08_bloqueio_operacao_nao_confirmada',
      case when sqlstate = '55000' and sqlerrm = 'operacao_not_applicable_status' then 'PASS' else 'FAIL' end,
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- ---------------------------------------------------------------------
-- 09 — Operação cancelada não pode ser aplicada
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_aplicar_operacao_financeira_admin(
      current_setting('app.mc15c.operacao_cancelada_id', true)::uuid,
      jsonb_build_object('origem_teste', '15c_operacao_cancelada_v3')
    );

    perform pg_temp.mc15c_add_result(
      '09_bloqueio_operacao_cancelada',
      'FAIL',
      jsonb_build_object('motivo', 'operacao_cancelada_aplicada', 'payload', v_payload)
    );
  exception when others then
    perform pg_temp.mc15c_add_result(
      '09_bloqueio_operacao_cancelada',
      case when sqlstate = '55000' and sqlerrm = 'operacao_cancelada' then 'PASS' else 'FAIL' end,
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- ---------------------------------------------------------------------
-- 10 — Tentativas negativas não podem gerar mutação
-- ---------------------------------------------------------------------
select set_config(
  'app.mc15c.valor_confirmada_depois',
  (
    select valor_atual::text
    from public.mesa_cliente_fluxo_parcelas
    where id = current_setting('app.mc15c.parcela_confirmada_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15c.status_confirmada_depois',
  (
    select status_operacao
    from public.mesa_cliente_fluxo_operacoes
    where id = current_setting('app.mc15c.operacao_confirmada_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15c.operacoes_depois_negativos',
  (
    select count(*)::text
    from public.mesa_cliente_fluxo_operacoes
    where simulacao_id = current_setting('app.mc15c.simulacao_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15c.parcelas_depois_negativos',
  (
    select count(*)::text
    from public.mesa_cliente_fluxo_parcelas
    where simulacao_id = current_setting('app.mc15c.simulacao_id', true)::uuid
  ),
  true
);

select pg_temp.mc15c_add_result(
  '10_tentativas_negativas_sem_mutacao',
  case
    when current_setting('app.mc15c.valor_confirmada_antes', true)::numeric = current_setting('app.mc15c.valor_confirmada_depois', true)::numeric
     and current_setting('app.mc15c.status_confirmada_antes', true) = current_setting('app.mc15c.status_confirmada_depois', true)
     and current_setting('app.mc15c.operacoes_antes_negativos', true) = current_setting('app.mc15c.operacoes_depois_negativos', true)
     and current_setting('app.mc15c.parcelas_antes_negativos', true) = current_setting('app.mc15c.parcelas_depois_negativos', true)
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'valor_confirmada_antes', current_setting('app.mc15c.valor_confirmada_antes', true),
    'valor_confirmada_depois', current_setting('app.mc15c.valor_confirmada_depois', true),
    'status_confirmada_antes', current_setting('app.mc15c.status_confirmada_antes', true),
    'status_confirmada_depois', current_setting('app.mc15c.status_confirmada_depois', true),
    'operacoes_antes', current_setting('app.mc15c.operacoes_antes_negativos', true),
    'operacoes_depois', current_setting('app.mc15c.operacoes_depois_negativos', true),
    'parcelas_antes', current_setting('app.mc15c.parcelas_antes_negativos', true),
    'parcelas_depois', current_setting('app.mc15c.parcelas_depois_negativos', true)
  )
);

-- ---------------------------------------------------------------------
-- 11 — Idempotência: segunda aplicação deve ser bloqueada
-- ---------------------------------------------------------------------
select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_user', true), true);
set local role authenticated;

select set_config(
  'app.mc15c.payload_aplicacao_1',
  public.mesa_cliente_aplicar_operacao_financeira_admin(
    current_setting('app.mc15c.operacao_idempotencia_id', true)::uuid,
    jsonb_build_object('origem_teste', '15c_primeira_aplicacao_v3')
  )::text,
  true
);

reset role;

select set_config(
  'app.mc15c.valor_pos_primeira_aplicacao',
  (
    select valor_atual::text
    from public.mesa_cliente_fluxo_parcelas
    where id = current_setting('app.mc15c.parcela_idempotencia_id', true)::uuid
  ),
  true
);

select set_config('request.jwt.claim.sub', current_setting('app.mc15c.admin_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_aplicar_operacao_financeira_admin(
      current_setting('app.mc15c.operacao_idempotencia_id', true)::uuid,
      jsonb_build_object('origem_teste', '15c_segunda_aplicacao_v3')
    );

    perform pg_temp.mc15c_add_result(
      '11_bloqueio_operacao_ja_aplicada',
      'FAIL',
      jsonb_build_object('motivo', 'operacao_reaplicada', 'payload', v_payload)
    );
  exception when others then
    perform pg_temp.mc15c_add_result(
      '11_bloqueio_operacao_ja_aplicada',
      case when sqlstate = '55000' and sqlerrm = 'operacao_already_applied' then 'PASS' else 'FAIL' end,
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- ---------------------------------------------------------------------
-- 12 — Idempotência: segunda tentativa não gera segunda mutação
-- ---------------------------------------------------------------------
select set_config(
  'app.mc15c.valor_pos_segunda_tentativa',
  (
    select valor_atual::text
    from public.mesa_cliente_fluxo_parcelas
    where id = current_setting('app.mc15c.parcela_idempotencia_id', true)::uuid
  ),
  true
);

select pg_temp.mc15c_add_result(
  '12_idempotencia_sem_segunda_mutacao',
  case
    when current_setting('app.mc15c.payload_aplicacao_1', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc15c.payload_aplicacao_1', true)::jsonb->>'status_operacao_final' = 'aplicada'
     and current_setting('app.mc15c.valor_pos_primeira_aplicacao', true)::numeric = current_setting('app.mc15c.valor_pos_segunda_tentativa', true)::numeric
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes
       where id = current_setting('app.mc15c.operacao_idempotencia_id', true)::uuid
         and status_operacao = 'aplicada'
         and metadata ? 'fase_7_aplicacao'
     )
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'operacao_idempotencia_id', current_setting('app.mc15c.operacao_idempotencia_id', true),
    'primeira_aplicacao_ok', current_setting('app.mc15c.payload_aplicacao_1', true)::jsonb->>'ok',
    'status_final_primeira_aplicacao', current_setting('app.mc15c.payload_aplicacao_1', true)::jsonb->>'status_operacao_final',
    'valor_pos_primeira_aplicacao', current_setting('app.mc15c.valor_pos_primeira_aplicacao', true),
    'valor_pos_segunda_tentativa', current_setting('app.mc15c.valor_pos_segunda_tentativa', true)
  )
);

-- ---------------------------------------------------------------------
-- 99 — Aviso operacional
-- ---------------------------------------------------------------------
select pg_temp.mc15c_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
    'mensagem', 'Teste 15C encerra com ROLLBACK. Todas as fixtures e a aplicacao usada para idempotencia devem sumir do banco.',
    'validacao', 'seguranca negativa da RPC de aplicacao financeira admin'
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc15c.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
