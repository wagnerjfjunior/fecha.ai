-- FECH.AI — MesaCliente
-- Fase 7 — Aplicacao de operacao financeira
-- Teste 15E — Regressao final da aplicacao de operacao financeira admin
--
-- Objetivo:
--   Validar o fluxo completo em fixture transacional:
--     4B -> 5B -> 5C -> release fixture -> 6 admin/cliente-safe -> 7 aplicar -> 6 pos-aplicacao
--
-- Escopo validado:
--   - criacao de agenda/parcela pela 4B
--   - registro da operacao pela 5B
--   - confirmacao da operacao pela 5C
--   - release transacional para cliente-safe antes da aplicacao
--   - resumo administrativo pre-aplicacao
--   - resumo cliente-safe pre-aplicacao sem vazamento
--   - aplicacao financeira pela RPC da Fase 7
--   - mutacao controlada em parcela/agenda/operacao
--   - resumo administrativo pos-aplicacao read-only
--   - cliente-safe pos-aplicacao bloqueado por release gate ou retornando payload seguro
--
-- Garantias do teste:
--   - Fixture transacional
--   - DML somente dentro de BEGIN + ROLLBACK
--   - Nenhuma fixture deve permanecer no banco
--   - Nao altera motor financeiro fora da transacao

begin;

select set_config('app.mc15e.results', '[]', true);
select set_config('request.jwt.claim.sub', '', true);

create or replace function pg_temp.mc15e_add_result(
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
  v_atual := coalesce(
    nullif(current_setting('app.mc15e.results', true), '')::jsonb,
    '[]'::jsonb
  );

  perform set_config(
    'app.mc15e.results',
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

create or replace function pg_temp.mc15e_norm_grupo(p_grupo text)
returns text
language sql
immutable
as $$
  select case
    when lower(coalesce(p_grupo, '')) in (
      'financiamento',
      'financiamento_bancario',
      'financiamento bancário'
    ) then 'financiamento'
    when lower(coalesce(p_grupo, '')) in ('chaves', 'chave') then 'chaves'
    when lower(coalesce(p_grupo, '')) in (
      'anual',
      'anuais',
      'intermediaria',
      'intermediarias',
      'intermediária',
      'intermediárias'
    ) then 'anuais'
    when lower(coalesce(p_grupo, '')) in ('mensal', 'mensais') then 'mensais'
    else lower(coalesce(p_grupo, ''))
  end;
$$;

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    e.id as empreendimento_id
  from public.corretores c
  join public.empreendimentos e
    on e.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true)
    and (
      coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case
      when c.role = 'admin_global' then 1
      when c.role = 'admin_local' then 2
      when c.role = 'gestor' then 3
      when c.role = 'coordenador' then 4
      else 5
    end,
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
    'Teste rollback 15E regressao final fase 7 corrigido',
    96000,
    26000,
    0,
    96000,
    jsonb_build_object(
      'origem_teste', '15e_fase_7_rollback_corrigido',
      'fixture_transacional', true
    ),
    'Fixture transacional 15E corrigida. Deve sumir no ROLLBACK.'
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
    date_trunc('month', current_date + interval '29 years')::date,
    (current_date - interval '1 year')::date,
    (current_date + interval '29 years')::date,
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    'Fixture transacional 15E corrigida.'
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
    ativo = true,
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
  select
    p.empresa_id,
    p.id,
    v.vpl_de_pct,
    v.vpl_ate_pct,
    v.premio_corretor_pct,
    v.status,
    v.descricao,
    v.ordem,
    v.ativo
  from politica p
  cross join (
    values
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 15E — prêmio cheio', 1, true),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 15E — prêmio parcial', 2, true),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 15E — sem prêmio', 3, true)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem, ativo)
  returning id
),
setup as (
  select
    set_config('app.mc15e.user_id', c.user_id::text, true),
    set_config('app.mc15e.simulacao_id', s.id::text, true),
    set_config('app.mc15e.empresa_id', s.empresa_id::text, true),
    set_config('app.mc15e.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc15e.politica_id', p.id::text, true),
    set_config('request.jwt.claim.sub', c.user_id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select pg_temp.mc15e_add_result(
  '00_setup_admin_fixture',
  case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'user_id', current_setting('app.mc15e.user_id', true),
    'simulacao_id', current_setting('app.mc15e.simulacao_id', true),
    'politica_id', current_setting('app.mc15e.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  )
)
from setup;

set local role authenticated;

select set_config(
  'app.mc15e.payload_4b',
  public.mesa_cliente_persistir_agenda_financeira_admin(
    current_setting('app.mc15e.simulacao_id', true)::uuid,
    (current_date + interval '730 days')::date,
    jsonb_build_array(
      jsonb_build_object(
        'grupo', 'mensais',
        'descricao', 'Mensais 15E',
        'valor', '3000.00',
        'quantidade', 6,
        'mes_ano', to_char((current_date + interval '760 days')::date, 'MM/YYYY')
      ),
      jsonb_build_object(
        'grupo', 'intermediarias',
        'descricao', 'Intermediária 15E',
        'valor', '10000.00',
        'quantidade', 2,
        'mes_ano', to_char((current_date + interval '820 days')::date, 'MM/YYYY')
      )
    ),
    jsonb_build_object('origem_teste', '15e_corrigido')
  )::text,
  true
);

reset role;

with agenda as (
  select id
  from public.mesa_cliente_agendas_financeiras
  where simulacao_id = current_setting('app.mc15e.simulacao_id', true)::uuid
    and status = 'ativa'
  order by created_at desc nulls last, id desc
  limit 1
),
parcela as (
  select
    p.id,
    p.valor_atual,
    p.data_atual
  from public.mesa_cliente_fluxo_parcelas p
  join agenda a
    on a.id = p.agenda_id
  where p.valor_atual > 0
    and p.data_atual > current_date
    and coalesce(p.eh_periodicidade_simbolica, false) = false
    and coalesce(p.pode_receber_antecipacao, false) = true
    and pg_temp.mc15e_norm_grupo(p.grupo::text) in ('financiamento', 'chaves', 'anuais', 'mensais')
  order by p.data_atual asc, p.valor_atual desc, p.id asc
  limit 1
)
select
  set_config('app.mc15e.agenda_id', (select id::text from agenda), true),
  set_config('app.mc15e.parcela_id', (select id::text from parcela), true),
  set_config('app.mc15e.valor_parcela_antes', (select valor_atual::text from parcela), true),
  set_config('app.mc15e.data_parcela_antes', (select data_atual::text from parcela), true);

select pg_temp.mc15e_add_result(
  '01_agenda_parcela_4b_fixture',
  case
    when current_setting('app.mc15e.payload_4b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc15e.agenda_id', true) <> ''
     and current_setting('app.mc15e.parcela_id', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'payload_4b_ok', current_setting('app.mc15e.payload_4b', true)::jsonb->>'ok',
    'agenda_id', current_setting('app.mc15e.agenda_id', true),
    'parcela_id', current_setting('app.mc15e.parcela_id', true),
    'valor_parcela_antes', current_setting('app.mc15e.valor_parcela_antes', true),
    'data_parcela_antes', current_setting('app.mc15e.data_parcela_antes', true)
  )
);

select set_config('request.jwt.claim.sub', current_setting('app.mc15e.user_id', true), true);
set local role authenticated;

select set_config(
  'app.mc15e.payload_5b',
  public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc15e.simulacao_id', true)::uuid,
    current_setting('app.mc15e.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc15e.parcela_id', true)::uuid,
    current_date,
    null,
    null,
    jsonb_build_object('origem_teste', '15e_5b')
  )::text,
  true
);

select set_config(
  'app.mc15e.operacao_id',
  current_setting('app.mc15e.payload_5b', true)::jsonb->'operacao'->>'id',
  true
);

select set_config(
  'app.mc15e.valor_movido',
  coalesce(
    current_setting('app.mc15e.payload_5b', true)::jsonb->'operacao'->>'valor_movido',
    '0'
  ),
  true
);

select set_config(
  'app.mc15e.payload_5c',
  public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    current_setting('app.mc15e.operacao_id', true)::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '15e_5c')
  )::text,
  true
);

reset role;

-- Release transacional necessario para validar o resumo cliente-safe pre-aplicacao.
-- A propria RPC da Fase 7 deve voltar visivel_cliente=false apos aplicar.
update public.mesa_cliente_fluxo_operacoes
set
  visivel_cliente = true,
  metadata = coalesce(metadata, '{}'::jsonb)
    || jsonb_build_object('fixture_15e_release_cliente_safe', true),
  updated_at = now()
where id = current_setting('app.mc15e.operacao_id', true)::uuid;

select pg_temp.mc15e_add_result(
  '02_operacao_5b_5c_confirmada_liberada',
  case
    when current_setting('app.mc15e.payload_5b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc15e.payload_5c', true)::jsonb->>'ok' = 'true'
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes
       where id = current_setting('app.mc15e.operacao_id', true)::uuid
         and status_operacao = 'confirmada'
         and coalesce(confirmado, false) = true
         and visivel_cliente = true
     )
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacao_id', current_setting('app.mc15e.operacao_id', true),
    'payload_5b_ok', current_setting('app.mc15e.payload_5b', true)::jsonb->>'ok',
    'payload_5c_ok', current_setting('app.mc15e.payload_5c', true)::jsonb->>'ok',
    'status_operacao', (select status_operacao from public.mesa_cliente_fluxo_operacoes where id = current_setting('app.mc15e.operacao_id', true)::uuid),
    'confirmado', (select confirmado from public.mesa_cliente_fluxo_operacoes where id = current_setting('app.mc15e.operacao_id', true)::uuid),
    'visivel_cliente', (select visivel_cliente from public.mesa_cliente_fluxo_operacoes where id = current_setting('app.mc15e.operacao_id', true)::uuid),
    'valor_movido', current_setting('app.mc15e.valor_movido', true)
  )
);

select set_config('request.jwt.claim.sub', current_setting('app.mc15e.user_id', true), true);
set local role authenticated;

select set_config(
  'app.mc15e.payload_6_admin_antes',
  public.mesa_cliente_resumir_operacao_financeira_admin(
    current_setting('app.mc15e.operacao_id', true)::uuid,
    jsonb_build_object('origem_teste', '15e_admin_antes')
  )::text,
  true
);

select set_config(
  'app.mc15e.payload_6_cliente_antes',
  public.mesa_cliente_obter_resumo_operacao_cliente_safe(
    current_setting('app.mc15e.operacao_id', true)::uuid,
    jsonb_build_object('origem_teste', '15e_cliente_antes')
  )::text,
  true
);

reset role;

select pg_temp.mc15e_add_result(
  '03_resumos_fase_6_pre_aplicacao',
  case
    when current_setting('app.mc15e.payload_6_admin_antes', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc15e.payload_6_admin_antes', true)::jsonb->>'visao' = 'administrativa'
     and current_setting('app.mc15e.payload_6_admin_antes', true)::jsonb->>'readonly' = 'true'
     and current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb->>'visao' = 'cliente_safe'
     and current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb->>'cliente_safe' = 'true'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'admin_ok', current_setting('app.mc15e.payload_6_admin_antes', true)::jsonb->>'ok',
    'admin_visao', current_setting('app.mc15e.payload_6_admin_antes', true)::jsonb->>'visao',
    'admin_readonly', current_setting('app.mc15e.payload_6_admin_antes', true)::jsonb->>'readonly',
    'cliente_ok', current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb->>'ok',
    'cliente_visao', current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb->>'visao',
    'cliente_safe', current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb->>'cliente_safe',
    'cliente_status_comercial', current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb->>'status_comercial'
  )
);

select pg_temp.mc15e_add_result(
  '04_cliente_safe_pre_aplicacao_sem_vazamento',
  case
    when current_setting('app.mc15e.payload_6_cliente_antes', true) !~* '(taxa_ano_pct|vpl_aplicado_pct|premio_corretor_pct|economia_liquida|politica_id|metadata|resumo_financeiro_admin|flags_integridade|simulacao)'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'top_level_keys_cliente', (
      select jsonb_agg(key order by key)
      from jsonb_object_keys(current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb) as key
    ),
    'avisos_cliente', current_setting('app.mc15e.payload_6_cliente_antes', true)::jsonb->'avisos'
  )
);

select set_config(
  'app.mc15e.operacoes_antes_apply',
  (
    select count(*)::text
    from public.mesa_cliente_fluxo_operacoes
    where simulacao_id = current_setting('app.mc15e.simulacao_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15e.parcelas_antes_apply',
  (
    select count(*)::text
    from public.mesa_cliente_fluxo_parcelas
    where simulacao_id = current_setting('app.mc15e.simulacao_id', true)::uuid
  ),
  true
);

select set_config('request.jwt.claim.sub', current_setting('app.mc15e.user_id', true), true);
set local role authenticated;

select set_config(
  'app.mc15e.payload_7',
  public.mesa_cliente_aplicar_operacao_financeira_admin(
    current_setting('app.mc15e.operacao_id', true)::uuid,
    jsonb_build_object('origem_teste', '15e_apply')
  )::text,
  true
);

reset role;

select set_config(
  'app.mc15e.operacoes_depois_apply',
  (
    select count(*)::text
    from public.mesa_cliente_fluxo_operacoes
    where simulacao_id = current_setting('app.mc15e.simulacao_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15e.parcelas_depois_apply',
  (
    select count(*)::text
    from public.mesa_cliente_fluxo_parcelas
    where simulacao_id = current_setting('app.mc15e.simulacao_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15e.valor_parcela_depois',
  (
    select valor_atual::text
    from public.mesa_cliente_fluxo_parcelas
    where id = current_setting('app.mc15e.parcela_id', true)::uuid
  ),
  true
);

select set_config(
  'app.mc15e.data_parcela_depois',
  (
    select data_atual::text
    from public.mesa_cliente_fluxo_parcelas
    where id = current_setting('app.mc15e.parcela_id', true)::uuid
  ),
  true
);

select pg_temp.mc15e_add_result(
  '05_rpc_7_aplicacao_final',
  case
    when current_setting('app.mc15e.payload_7', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc15e.payload_7', true)::jsonb->>'fase' = '7_APLICACAO_OPERACAO_FINANCEIRA'
     and current_setting('app.mc15e.payload_7', true)::jsonb->>'visao' = 'administrativa'
     and current_setting('app.mc15e.payload_7', true)::jsonb->>'readonly' = 'false'
     and current_setting('app.mc15e.payload_7', true)::jsonb->>'dml_financeiro' = 'true'
     and current_setting('app.mc15e.payload_7', true)::jsonb->>'status_operacao_anterior' = 'confirmada'
     and current_setting('app.mc15e.payload_7', true)::jsonb->>'status_operacao_final' = 'aplicada'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'ok', current_setting('app.mc15e.payload_7', true)::jsonb->>'ok',
    'fase', current_setting('app.mc15e.payload_7', true)::jsonb->>'fase',
    'visao', current_setting('app.mc15e.payload_7', true)::jsonb->>'visao',
    'readonly', current_setting('app.mc15e.payload_7', true)::jsonb->>'readonly',
    'dml_financeiro', current_setting('app.mc15e.payload_7', true)::jsonb->>'dml_financeiro',
    'status_operacao_anterior', current_setting('app.mc15e.payload_7', true)::jsonb->>'status_operacao_anterior',
    'status_operacao_final', current_setting('app.mc15e.payload_7', true)::jsonb->>'status_operacao_final'
  )
);

select pg_temp.mc15e_add_result(
  '06_mutacao_financeira_controlada',
  case
    when exists (
      select 1
      from public.mesa_cliente_fluxo_operacoes
      where id = current_setting('app.mc15e.operacao_id', true)::uuid
        and status_operacao = 'aplicada'
        and coalesce(confirmado, false) = true
        and coalesce(visivel_cliente, true) = false
        and metadata ? 'fase_7_aplicacao'
    )
    and round(current_setting('app.mc15e.valor_parcela_depois', true)::numeric, 2)
      = round(
          current_setting('app.mc15e.valor_parcela_antes', true)::numeric
          - current_setting('app.mc15e.valor_movido', true)::numeric,
          2
        )
    and current_setting('app.mc15e.data_parcela_depois', true) = current_setting('app.mc15e.data_parcela_antes', true)
    and current_setting('app.mc15e.operacoes_antes_apply', true) = current_setting('app.mc15e.operacoes_depois_apply', true)
    and current_setting('app.mc15e.parcelas_antes_apply', true) = current_setting('app.mc15e.parcelas_depois_apply', true)
    and exists (
      select 1
      from public.mesa_cliente_agendas_financeiras
      where id = current_setting('app.mc15e.agenda_id', true)::uuid
        and metadata ? 'fase_7_ultima_aplicacao'
        and totais ? 'fase_7_ultima_delta_valor'
        and totais ? 'fase_7_ultima_operacao_id'
    )
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacao_id', current_setting('app.mc15e.operacao_id', true),
    'status_operacao', (select status_operacao from public.mesa_cliente_fluxo_operacoes where id = current_setting('app.mc15e.operacao_id', true)::uuid),
    'confirmado', (select confirmado from public.mesa_cliente_fluxo_operacoes where id = current_setting('app.mc15e.operacao_id', true)::uuid),
    'visivel_cliente', (select visivel_cliente from public.mesa_cliente_fluxo_operacoes where id = current_setting('app.mc15e.operacao_id', true)::uuid),
    'valor_parcela_antes', current_setting('app.mc15e.valor_parcela_antes', true),
    'valor_movido', current_setting('app.mc15e.valor_movido', true),
    'valor_parcela_depois', current_setting('app.mc15e.valor_parcela_depois', true),
    'data_antes', current_setting('app.mc15e.data_parcela_antes', true),
    'data_depois', current_setting('app.mc15e.data_parcela_depois', true),
    'operacoes_antes', current_setting('app.mc15e.operacoes_antes_apply', true),
    'operacoes_depois', current_setting('app.mc15e.operacoes_depois_apply', true),
    'parcelas_antes', current_setting('app.mc15e.parcelas_antes_apply', true),
    'parcelas_depois', current_setting('app.mc15e.parcelas_depois_apply', true),
    'agenda_metadata_fase_7', (
      select metadata ? 'fase_7_ultima_aplicacao'
      from public.mesa_cliente_agendas_financeiras
      where id = current_setting('app.mc15e.agenda_id', true)::uuid
    ),
    'agenda_delta', (
      select totais->>'fase_7_ultima_delta_valor'
      from public.mesa_cliente_agendas_financeiras
      where id = current_setting('app.mc15e.agenda_id', true)::uuid
    )
  )
);

select set_config('request.jwt.claim.sub', current_setting('app.mc15e.user_id', true), true);
set local role authenticated;

select set_config(
  'app.mc15e.payload_6_admin_depois',
  public.mesa_cliente_resumir_operacao_financeira_admin(
    current_setting('app.mc15e.operacao_id', true)::uuid,
    jsonb_build_object('origem_teste', '15e_admin_depois')
  )::text,
  true
);

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_obter_resumo_operacao_cliente_safe(
      current_setting('app.mc15e.operacao_id', true)::uuid,
      jsonb_build_object('origem_teste', '15e_cliente_depois')
    );

    perform set_config('app.mc15e.payload_6_cliente_depois', v_payload::text, true);
    perform set_config('app.mc15e.cliente_depois_status', 'RETURNED', true);
  exception when others then
    perform set_config('app.mc15e.payload_6_cliente_depois', 'null', true);
    perform set_config('app.mc15e.cliente_depois_status', sqlstate, true);
    perform set_config('app.mc15e.cliente_depois_message', sqlerrm, true);
  end;
end;
$$;

reset role;

select pg_temp.mc15e_add_result(
  '07_resumo_admin_pos_aplicacao',
  case
    when current_setting('app.mc15e.payload_6_admin_depois', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc15e.payload_6_admin_depois', true)::jsonb->>'visao' = 'administrativa'
     and current_setting('app.mc15e.payload_6_admin_depois', true)::jsonb->>'readonly' = 'true'
     and current_setting('app.mc15e.payload_6_admin_depois', true)::jsonb->>'dml_financeiro' = 'false'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'admin_ok', current_setting('app.mc15e.payload_6_admin_depois', true)::jsonb->>'ok',
    'admin_visao', current_setting('app.mc15e.payload_6_admin_depois', true)::jsonb->>'visao',
    'admin_readonly', current_setting('app.mc15e.payload_6_admin_depois', true)::jsonb->>'readonly',
    'admin_dml_financeiro', current_setting('app.mc15e.payload_6_admin_depois', true)::jsonb->>'dml_financeiro',
    'status_operacao_tabela', (
      select status_operacao
      from public.mesa_cliente_fluxo_operacoes
      where id = current_setting('app.mc15e.operacao_id', true)::uuid
    )
  )
);

select pg_temp.mc15e_add_result(
  '08_cliente_safe_pos_aplicacao_gate_ou_sem_vazamento',
  case
    when current_setting('app.mc15e.cliente_depois_status', true) = '42501'
     and current_setting('app.mc15e.cliente_depois_message', true) = 'cliente_safe_not_released'
    then 'PASS'
    when current_setting('app.mc15e.cliente_depois_status', true) = 'RETURNED'
     and current_setting('app.mc15e.payload_6_cliente_depois', true)::jsonb->>'cliente_safe' = 'true'
     and current_setting('app.mc15e.payload_6_cliente_depois', true) !~* '(taxa_ano_pct|vpl_aplicado_pct|premio_corretor_pct|economia_liquida|politica_id|metadata|resumo_financeiro_admin|flags_integridade|simulacao)'
    then 'PASS'
    else 'FAIL'
  end,
  jsonb_build_object(
    'cliente_depois_status', current_setting('app.mc15e.cliente_depois_status', true),
    'cliente_depois_message', current_setting('app.mc15e.cliente_depois_message', true),
    'interpretacao', 'apos aplicacao, cliente-safe pode bloquear por release gate ou retornar payload safe sem vazamento'
  )
);

select pg_temp.mc15e_add_result(
  '09_readiness_fechamento_fase_7',
  case
    when not exists (
      select 1
      from jsonb_array_elements(current_setting('app.mc15e.results', true)::jsonb) as r
      where r->>'status' = 'FAIL'
    )
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
    'validacoes', jsonb_build_array(
      '4B',
      '5B',
      '5C',
      '6_admin_pre',
      '6_cliente_safe_pre',
      '7_apply',
      '6_admin_post',
      'cliente_safe_gate_ou_safe_post'
    ),
    'rollback', true
  )
);

select pg_temp.mc15e_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', '7_APLICACAO_OPERACAO_FINANCEIRA',
    'mensagem', 'Teste 15E encerra com ROLLBACK. Fluxo completo executado apenas em fixture transacional.',
    'validacao', 'regressao final Fase 7: 4B -> 5B -> 5C -> release fixture -> 6 -> 7 -> 6 pos-aplicacao'
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc15e.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
