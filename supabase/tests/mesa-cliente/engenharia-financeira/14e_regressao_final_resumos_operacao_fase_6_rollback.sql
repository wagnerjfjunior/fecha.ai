-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 6
-- 14E — Regressão final dos resumos read-only de operação financeira.
--
-- RPCs validadas:
--   public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
--   public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
--
-- Objetivo:
--   Fechar a Fase 6 validando contrato de catálogo, execução positiva das duas RPCs,
--   ausência de vazamento cliente-safe e garantia read-only.
--
-- Escopo:
--   - SECURITY DEFINER.
--   - STABLE.
--   - search_path fixado em public, pg_temp.
--   - EXECUTE liberado para authenticated.
--   - EXECUTE negado para anon/public.
--   - Comentários presentes no catálogo.
--   - Fixture transacional via 4B + 5B.
--   - Operação visível ao cliente somente dentro do rollback.
--   - Payload admin conforme contrato real da migration.
--   - Payload cliente-safe sem campos sensíveis.
--   - Sem DML financeiro nas RPCs da Fase 6.
--
-- Observação técnica importante:
--   O payload admin não possui parcelas_impactadas no topo.
--   O contrato admin canônico possui:
--     ids, operacao, resumo_financeiro_admin, simulacao, flags_integridade.
--   O payload cliente-safe possui parcelas_impactadas por ser visão comercial simplificada.
--
-- Este teste deve encerrar sempre com ROLLBACK.

begin;

select set_config('app.mc14e.results', '[]', true);
select set_config('request.jwt.claim.sub', '', true);
select set_config('app.mc14e.user_id', '', true);
select set_config('app.mc14e.simulacao_id', '', true);
select set_config('app.mc14e.politica_id', '', true);
select set_config('app.mc14e.agenda_id', '', true);
select set_config('app.mc14e.parcela_id', '', true);
select set_config('app.mc14e.operacao_id', '', true);
select set_config('app.mc14e.payload_4b', 'null', true);
select set_config('app.mc14e.payload_5b', 'null', true);
select set_config('app.mc14e.payload_admin', 'null', true);
select set_config('app.mc14e.payload_cliente', 'null', true);
select set_config('app.mc14e.operacoes_antes', '0', true);
select set_config('app.mc14e.operacoes_depois', '0', true);
select set_config('app.mc14e.parcelas_antes', '0', true);
select set_config('app.mc14e.parcelas_depois', '0', true);

create or replace function pg_temp.mc14e_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.mc14e.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc14e.results',
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

create or replace function pg_temp.mc14e_norm_grupo(p_grupo text)
returns text
language sql
immutable
as $$
  select case
    when lower(coalesce(p_grupo, '')) in ('financiamento', 'financiamento_bancario', 'financiamento bancário') then 'financiamento'
    when lower(coalesce(p_grupo, '')) in ('chaves', 'chave') then 'chaves'
    when lower(coalesce(p_grupo, '')) in ('anual', 'anuais', 'intermediaria', 'intermediarias', 'intermediária', 'intermediárias') then 'anuais'
    when lower(coalesce(p_grupo, '')) in ('mensal', 'mensais') then 'mensais'
    else lower(coalesce(p_grupo, ''))
  end;
$$;

-- -----------------------------------------------------------------------------
-- 00 — Contrato de catálogo das RPCs da Fase 6
-- -----------------------------------------------------------------------------
with meta as (
  select
    p.proname,
    p.prosecdef,
    p.provolatile,
    p.proconfig,
    p.proacl::text as proacl,
    has_function_privilege('authenticated', p.oid, 'EXECUTE') as authenticated_execute,
    has_function_privilege('anon', p.oid, 'EXECUTE') as anon_execute,
    obj_description(p.oid, 'pg_proc') as comentario
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.proname in (
      'mesa_cliente_resumir_operacao_financeira_admin',
      'mesa_cliente_obter_resumo_operacao_cliente_safe'
    )
)
select pg_temp.mc14e_add_result(
  '00_contrato_rpc_catalogo',
  case
    when count(*) = 2
     and bool_and(prosecdef)
     and bool_and(provolatile = 's')
     and bool_and(proconfig::text[] @> array['search_path=public, pg_temp'])
     and bool_and(authenticated_execute)
     and bool_and(not anon_execute)
     and bool_and(coalesce(comentario, '') <> '')
     and bool_and(coalesce(proacl, '') !~ '(^|,)=[^,]*X')
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'funcoes', jsonb_agg(
      jsonb_build_object(
        'proname', proname,
        'security_definer', prosecdef,
        'volatility', provolatile,
        'search_path', proconfig,
        'authenticated_execute', authenticated_execute,
        'anon_execute', anon_execute,
        'proacl', proacl,
        'comentario_presente', coalesce(comentario, '') <> ''
      )
      order by proname
    )
  )
)
from meta;

-- -----------------------------------------------------------------------------
-- 01 — Fixture base admin + política + faixas
-- -----------------------------------------------------------------------------
with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    e.id as empreendimento_id
  from public.corretores c
  join public.empreendimentos e on e.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and (
      c.role in ('admin_global', 'admin_local', 'gestor', 'coordenador')
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
    'Teste rollback 14E regressao final fase 6',
    99000.00,
    26000.00,
    0,
    99000.00,
    jsonb_build_object('origem_teste', '14e_fase_6_rollback', 'fixture_transacional', true),
    'Fixture transacional 14E. Deve sumir no ROLLBACK.'
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
    date_trunc('month', current_date + interval '25 years')::date,
    (current_date - interval '1 year')::date,
    (current_date + interval '25 years')::date,
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture transacional 14E para regressao final fase 6.'
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
    true
  from politica p
  cross join (
    values
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 14E — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 14E — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 14E — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc14e.user_id', c.user_id::text, true),
    set_config('app.mc14e.simulacao_id', s.id::text, true),
    set_config('app.mc14e.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select pg_temp.mc14e_add_result(
  '01_setup_fixture_final',
  case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'user_id', current_setting('app.mc14e.user_id', true),
    'simulacao_id', current_setting('app.mc14e.simulacao_id', true),
    'politica_id', current_setting('app.mc14e.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  )
)
from setup;

-- -----------------------------------------------------------------------------
-- 02 — Criar agenda 4B, operação 5B e liberar visibilidade dentro da transação
-- -----------------------------------------------------------------------------
set local role authenticated;

select set_config(
  'app.mc14e.payload_4b',
  public.mesa_cliente_persistir_agenda_financeira_admin(
    current_setting('app.mc14e.simulacao_id', true)::uuid,
    (current_date + interval '730 days')::date,
    jsonb_build_array(
      jsonb_build_object(
        'grupo', 'mensais',
        'descricao', 'Mensais 14E',
        'valor', '3000.00',
        'quantidade', 6,
        'mes_ano', to_char((current_date + interval '760 days')::date, 'MM/YYYY')
      ),
      jsonb_build_object(
        'grupo', 'intermediarias',
        'descricao', 'Intermediaria 14E',
        'valor', '10000.00',
        'quantidade', 2,
        'mes_ano', to_char((current_date + interval '820 days')::date, 'MM/YYYY')
      )
    ),
    jsonb_build_object('origem_teste', '14e')
  )::text,
  true
);

reset role;

with agenda as (
  select a.id
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = current_setting('app.mc14e.simulacao_id', true)::uuid
    and a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcela as (
  select p.id
  from public.mesa_cliente_fluxo_parcelas p
  join agenda a on a.id = p.agenda_id
  where p.valor_atual > 0
    and p.data_atual > current_date
    and coalesce(p.eh_periodicidade_simbolica, false) = false
    and coalesce(p.pode_receber_antecipacao, false) = true
    and pg_temp.mc14e_norm_grupo(p.grupo::text) in ('financiamento', 'chaves', 'anuais', 'mensais')
  order by p.data_atual asc, p.valor_atual desc, p.id asc
  limit 1
)
select
  set_config('app.mc14e.agenda_id', (select id::text from agenda), true),
  set_config('app.mc14e.parcela_id', (select id::text from parcela), true);

set local role authenticated;

select set_config(
  'app.mc14e.payload_5b',
  public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc14e.simulacao_id', true)::uuid,
    current_setting('app.mc14e.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc14e.parcela_id', true)::uuid,
    current_date,
    null,
    null,
    jsonb_build_object('origem_teste', '14e')
  )::text,
  true
);

reset role;

select set_config(
  'app.mc14e.operacao_id',
  current_setting('app.mc14e.payload_5b', true)::jsonb->'operacao'->>'id',
  true
);

update public.mesa_cliente_fluxo_operacoes
set visivel_cliente = true,
    updated_at = now()
where id = current_setting('app.mc14e.operacao_id', true)::uuid;

select pg_temp.mc14e_add_result(
  '02_operacao_base_final',
  case
    when current_setting('app.mc14e.payload_4b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14e.payload_5b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14e.operacao_id', true) <> ''
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes o
       where o.id = current_setting('app.mc14e.operacao_id', true)::uuid
         and coalesce(o.visivel_cliente, false) = true
     )
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc14e.agenda_id', true),
    'parcela_id', current_setting('app.mc14e.parcela_id', true),
    'operacao_id', current_setting('app.mc14e.operacao_id', true),
    'payload_4b_ok', current_setting('app.mc14e.payload_4b', true)::jsonb->>'ok',
    'payload_5b_ok', current_setting('app.mc14e.payload_5b', true)::jsonb->>'ok'
  )
);

select set_config(
  'app.mc14e.operacoes_antes',
  (select count(*)::text from public.mesa_cliente_fluxo_operacoes where simulacao_id = current_setting('app.mc14e.simulacao_id', true)::uuid),
  true
);

select set_config(
  'app.mc14e.parcelas_antes',
  (select count(*)::text from public.mesa_cliente_fluxo_parcelas where simulacao_id = current_setting('app.mc14e.simulacao_id', true)::uuid),
  true
);

-- -----------------------------------------------------------------------------
-- 03/04 — Execução positiva das duas RPCs
-- -----------------------------------------------------------------------------
set local role authenticated;

select set_config(
  'app.mc14e.payload_admin',
  public.mesa_cliente_resumir_operacao_financeira_admin(
    current_setting('app.mc14e.operacao_id', true)::uuid,
    jsonb_build_object('origem_teste', '14e_admin')
  )::text,
  true
);

select set_config(
  'app.mc14e.payload_cliente',
  public.mesa_cliente_obter_resumo_operacao_cliente_safe(
    current_setting('app.mc14e.operacao_id', true)::uuid,
    jsonb_build_object('origem_teste', '14e_cliente_safe')
  )::text,
  true
);

reset role;

select pg_temp.mc14e_add_result(
  '03_regressao_rpc_admin',
  case
    when current_setting('app.mc14e.payload_admin', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14e.payload_admin', true)::jsonb->>'fase' = '6_RESUMOS_OPERACAO_FINANCEIRA'
     and current_setting('app.mc14e.payload_admin', true)::jsonb->>'visao' = 'administrativa'
     and current_setting('app.mc14e.payload_admin', true)::jsonb->>'readonly' = 'true'
     and current_setting('app.mc14e.payload_admin', true)::jsonb ? 'ids'
     and current_setting('app.mc14e.payload_admin', true)::jsonb ? 'operacao'
     and current_setting('app.mc14e.payload_admin', true)::jsonb ? 'resumo_financeiro_admin'
     and current_setting('app.mc14e.payload_admin', true)::jsonb ? 'simulacao'
     and current_setting('app.mc14e.payload_admin', true)::jsonb ? 'flags_integridade'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'ok', current_setting('app.mc14e.payload_admin', true)::jsonb->>'ok',
    'fase', current_setting('app.mc14e.payload_admin', true)::jsonb->>'fase',
    'visao', current_setting('app.mc14e.payload_admin', true)::jsonb->>'visao',
    'readonly', current_setting('app.mc14e.payload_admin', true)::jsonb->>'readonly',
    'top_level_keys', (
      select jsonb_agg(k order by k)
      from jsonb_object_keys(current_setting('app.mc14e.payload_admin', true)::jsonb) as t(k)
    )
  )
);

select pg_temp.mc14e_add_result(
  '04_regressao_rpc_cliente_safe',
  case
    when current_setting('app.mc14e.payload_cliente', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14e.payload_cliente', true)::jsonb->>'fase' = '6_RESUMOS_OPERACAO_FINANCEIRA'
     and current_setting('app.mc14e.payload_cliente', true)::jsonb->>'visao' = 'cliente_safe'
     and current_setting('app.mc14e.payload_cliente', true)::jsonb->>'cliente_safe' = 'true'
     and current_setting('app.mc14e.payload_cliente', true)::jsonb->>'readonly' = 'true'
     and current_setting('app.mc14e.payload_cliente', true)::jsonb ? 'resumo_condicao'
     and current_setting('app.mc14e.payload_cliente', true)::jsonb ? 'status_comercial'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'ok', current_setting('app.mc14e.payload_cliente', true)::jsonb->>'ok',
    'fase', current_setting('app.mc14e.payload_cliente', true)::jsonb->>'fase',
    'visao', current_setting('app.mc14e.payload_cliente', true)::jsonb->>'visao',
    'cliente_safe', current_setting('app.mc14e.payload_cliente', true)::jsonb->>'cliente_safe',
    'status_comercial', current_setting('app.mc14e.payload_cliente', true)::jsonb->>'status_comercial'
  )
);

-- -----------------------------------------------------------------------------
-- 05 — Cliente-safe sem vazamento sensível
-- -----------------------------------------------------------------------------
select pg_temp.mc14e_add_result(
  '05_regressao_sem_vazamento_cliente_safe',
  case
    when not (
      current_setting('app.mc14e.payload_cliente', true)::jsonb ?| array[
        'empresa_id',
        'tenant_id',
        'politica_id',
        'checksum_operacao',
        'metadata',
        'resumo_financeiro_admin',
        'taxa_ano_pct',
        'vpl_aplicado_pct',
        'premio_corretor_pct',
        'status_premio',
        'confirmado_por',
        'cancelado_por'
      ]
    )
    and current_setting('app.mc14e.payload_cliente', true) !~* '(empresa_id|tenant_id|politica_id|checksum_operacao|metadata|resumo_financeiro_admin|taxa_ano_pct|vpl_aplicado_pct|premio_corretor_pct|status_premio|confirmado_por|cancelado_por|vpl|taxa|prêmio|premio|comissao|comissão)'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'top_level_keys_cliente', (
      select jsonb_agg(k order by k)
      from jsonb_object_keys(current_setting('app.mc14e.payload_cliente', true)::jsonb) as t(k)
    ),
    'avisos_cliente', current_setting('app.mc14e.payload_cliente', true)::jsonb->'avisos'
  )
);

-- -----------------------------------------------------------------------------
-- 06 — Read-only efetivo das duas RPCs
-- -----------------------------------------------------------------------------
select set_config(
  'app.mc14e.operacoes_depois',
  (select count(*)::text from public.mesa_cliente_fluxo_operacoes where simulacao_id = current_setting('app.mc14e.simulacao_id', true)::uuid),
  true
);

select set_config(
  'app.mc14e.parcelas_depois',
  (select count(*)::text from public.mesa_cliente_fluxo_parcelas where simulacao_id = current_setting('app.mc14e.simulacao_id', true)::uuid),
  true
);

select pg_temp.mc14e_add_result(
  '06_readonly_regressao_duas_rpcs',
  case
    when current_setting('app.mc14e.operacoes_antes', true) = current_setting('app.mc14e.operacoes_depois', true)
     and current_setting('app.mc14e.parcelas_antes', true) = current_setting('app.mc14e.parcelas_depois', true)
     and current_setting('app.mc14e.payload_admin', true)::jsonb->>'dml_financeiro' = 'false'
     and current_setting('app.mc14e.payload_cliente', true)::jsonb->>'dml_financeiro' = 'false'
     and current_setting('app.mc14e.payload_admin', true)::jsonb->>'altera_agenda' = 'false'
     and current_setting('app.mc14e.payload_cliente', true)::jsonb->>'altera_agenda' = 'false'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacoes_antes', current_setting('app.mc14e.operacoes_antes', true),
    'operacoes_depois', current_setting('app.mc14e.operacoes_depois', true),
    'parcelas_antes', current_setting('app.mc14e.parcelas_antes', true),
    'parcelas_depois', current_setting('app.mc14e.parcelas_depois', true),
    'admin_dml_financeiro', current_setting('app.mc14e.payload_admin', true)::jsonb->>'dml_financeiro',
    'cliente_dml_financeiro', current_setting('app.mc14e.payload_cliente', true)::jsonb->>'dml_financeiro'
  )
);

select pg_temp.mc14e_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', '6_RESUMOS_OPERACAO_FINANCEIRA',
    'mensagem', 'Teste 14E encerra com ROLLBACK. Regressao final da Fase 6 nao deve deixar fixture no banco.',
    'validacao', 'contrato catalogo + execucao admin + execucao cliente-safe + ausencia de vazamento + read-only'
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc14e.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
