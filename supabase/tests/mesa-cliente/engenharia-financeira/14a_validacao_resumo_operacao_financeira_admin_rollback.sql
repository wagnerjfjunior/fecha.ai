-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 6
-- 14A — Validação positiva da RPC administrativa de resumo de operação financeira.
--
-- RPC validada:
--   public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
--
-- Princípios do teste:
--   - não hardcodar tenant/empresa/usuário/perfil;
--   - derivar admin/gestor/coordenador ativo a partir do banco;
--   - criar fixture financeira transacional;
--   - usar RPCs anteriores como fonte de verdade para gerar massa válida;
--   - validar retorno administrativo da Fase 6;
--   - validar que a RPC 6 é read-only;
--   - encerrar tudo com ROLLBACK.
--
-- Dependências funcionais:
--   - Fase 4B: mesa_cliente_persistir_agenda_financeira_admin
--   - Fase 5B: mesa_cliente_registrar_operacao_financeira_admin
--   - Fase 6:  mesa_cliente_resumir_operacao_financeira_admin

begin;

select set_config('app.mc14a.results', '[]', true);
select set_config('app.mc14a.user_id', '', true);
select set_config('app.mc14a.simulacao_id', '', true);
select set_config('app.mc14a.empresa_id', '', true);
select set_config('app.mc14a.empreendimento_id', '', true);
select set_config('app.mc14a.politica_id', '', true);
select set_config('app.mc14a.agenda_id', '', true);
select set_config('app.mc14a.parcela_id', '', true);
select set_config('app.mc14a.operacao_id', '', true);
select set_config('app.mc14a.payload_4b', 'null', true);
select set_config('app.mc14a.payload_5b', 'null', true);
select set_config('app.mc14a.payload_6_admin', 'null', true);
select set_config('app.mc14a.count_operacoes_antes_rpc6', '0', true);
select set_config('app.mc14a.count_operacoes_depois_rpc6', '0', true);
select set_config('app.mc14a.count_parcelas_antes_rpc6', '0', true);
select set_config('app.mc14a.count_parcelas_depois_rpc6', '0', true);
select set_config('request.jwt.claim.sub', '', true);

-- Datas dinâmicas da fixture. Sem ano fixo/mágico.
select set_config('app.mc14a.data_referencia', current_date::text, true);
select set_config('app.mc14a.data_ato', (current_date + interval '730 days')::date::text, true);
select set_config('app.mc14a.mes_mensais', to_char((current_date + interval '760 days')::date, 'MM/YYYY'), true);
select set_config('app.mc14a.mes_intermediarias', to_char((current_date + interval '820 days')::date, 'MM/YYYY'), true);
select set_config('app.mc14a.politica_mes_referencia', date_trunc('month', current_date + interval '21 years')::date::text, true);
select set_config('app.mc14a.politica_vigencia_inicio', (current_date - interval '1 year')::date::text, true);
select set_config('app.mc14a.politica_vigencia_fim', (current_date + interval '21 years')::date::text, true);

create or replace function pg_temp.mc14a_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.mc14a.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc14a.results',
    (v_atual || jsonb_build_array(jsonb_build_object(
      'bloco', p_bloco,
      'status', p_status,
      'detalhe', coalesce(p_detalhe, '{}'::jsonb)
    )))::text,
    true
  );
end;
$$;

create or replace function pg_temp.mc14a_norm_grupo(p_grupo text)
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

with candidato as materialized (
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
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
    'Teste rollback 14A resumo admin fase 6',
    78000.00,
    18000.00,
    0,
    78000.00,
    jsonb_build_object('origem_teste', '14a_fase_6_rollback', 'fixture_transacional', true),
    'Fixture transacional 14A. Deve sumir no ROLLBACK.'
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
    current_setting('app.mc14a.politica_mes_referencia', true)::date,
    current_setting('app.mc14a.politica_vigencia_inicio', true)::date,
    current_setting('app.mc14a.politica_vigencia_fim', true)::date,
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture transacional 14A para resumo admin fase 6.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 14A — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 14A — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 14A — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc14a.user_id', c.user_id::text, true),
    set_config('app.mc14a.simulacao_id', s.id::text, true),
    set_config('app.mc14a.empresa_id', s.empresa_id::text, true),
    set_config('app.mc14a.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc14a.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select pg_temp.mc14a_add_result(
  '00_setup_admin_fixture',
  case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'user_id', current_setting('app.mc14a.user_id', true),
    'simulacao_id', current_setting('app.mc14a.simulacao_id', true),
    'politica_id', current_setting('app.mc14a.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  )
)
from setup;

set local role authenticated;

with chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    current_setting('app.mc14a.simulacao_id', true)::uuid,
    current_setting('app.mc14a.data_ato', true)::date,
    jsonb_build_array(
      jsonb_build_object(
        'grupo','mensais',
        'descricao','Mensais 14A',
        'valor','3000.00',
        'quantidade',6,
        'mes_ano', current_setting('app.mc14a.mes_mensais', true)
      ),
      jsonb_build_object(
        'grupo','intermediarias',
        'descricao','Intermediária 14A',
        'valor','10000.00',
        'quantidade',2,
        'mes_ano', current_setting('app.mc14a.mes_intermediarias', true)
      )
    ),
    jsonb_build_object('origem_teste', '14a')
  ) as payload
)
select set_config('app.mc14a.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = current_setting('app.mc14a.simulacao_id', true)::uuid
    and a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcela as (
  select fp.*
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual > 0
    and fp.data_atual > current_setting('app.mc14a.data_referencia', true)::date
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
    and pg_temp.mc14a_norm_grupo(fp.grupo::text) in ('financiamento','chaves','anuais','mensais')
  order by fp.data_atual asc, fp.valor_atual desc, fp.id asc
  limit 1
),
setup as (
  select
    set_config('app.mc14a.agenda_id', (select id::text from agenda), true),
    set_config('app.mc14a.parcela_id', (select id::text from parcela), true)
)
select pg_temp.mc14a_add_result(
  '01_agenda_parcela_fixture',
  case
    when current_setting('app.mc14a.agenda_id', true) <> ''
     and current_setting('app.mc14a.parcela_id', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc14a.agenda_id', true),
    'parcela_id', current_setting('app.mc14a.parcela_id', true),
    'payload_4b_ok', current_setting('app.mc14a.payload_4b', true)::jsonb->>'ok'
  )
)
from setup;

set local role authenticated;

with chamada_5b as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc14a.simulacao_id', true)::uuid,
    current_setting('app.mc14a.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc14a.parcela_id', true)::uuid,
    current_setting('app.mc14a.data_referencia', true)::date,
    null,
    null,
    jsonb_build_object('origem_teste', '14a', 'operacao', 'antecipacao_admin_resumo')
  ) as payload
)
select
  set_config('app.mc14a.payload_5b', coalesce((select payload::text from chamada_5b), 'null'), true),
  set_config('app.mc14a.operacao_id', coalesce((select payload->'operacao'->>'id' from chamada_5b), ''), true);

reset role;

select pg_temp.mc14a_add_result(
  '02_operacao_5b_fixture',
  case
    when current_setting('app.mc14a.payload_5b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14a.operacao_id', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacao_id', current_setting('app.mc14a.operacao_id', true),
    'payload_5b_ok', current_setting('app.mc14a.payload_5b', true)::jsonb->>'ok',
    'tipo_operacao', current_setting('app.mc14a.payload_5b', true)::jsonb->'operacao'->>'tipo_operacao'
  )
);

select set_config(
  'app.mc14a.count_operacoes_antes_rpc6',
  (select count(*)::text from public.mesa_cliente_fluxo_operacoes where simulacao_id = current_setting('app.mc14a.simulacao_id', true)::uuid),
  true
);

select set_config(
  'app.mc14a.count_parcelas_antes_rpc6',
  (select count(*)::text from public.mesa_cliente_fluxo_parcelas where simulacao_id = current_setting('app.mc14a.simulacao_id', true)::uuid),
  true
);

set local role authenticated;

select set_config(
  'app.mc14a.payload_6_admin',
  public.mesa_cliente_resumir_operacao_financeira_admin(
    current_setting('app.mc14a.operacao_id', true)::uuid,
    jsonb_build_object('origem_teste', '14a')
  )::text,
  true
);

reset role;

select set_config(
  'app.mc14a.count_operacoes_depois_rpc6',
  (select count(*)::text from public.mesa_cliente_fluxo_operacoes where simulacao_id = current_setting('app.mc14a.simulacao_id', true)::uuid),
  true
);

select set_config(
  'app.mc14a.count_parcelas_depois_rpc6',
  (select count(*)::text from public.mesa_cliente_fluxo_parcelas where simulacao_id = current_setting('app.mc14a.simulacao_id', true)::uuid),
  true
);

select pg_temp.mc14a_add_result(
  '03_rpc_admin_basico',
  case
    when current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'fase' = '6_RESUMOS_OPERACAO_FINANCEIRA'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'visao' = 'administrativa'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'cliente_safe' = 'false'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'readonly' = 'true'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'fase', current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'fase',
    'visao', current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'visao',
    'readonly', current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'readonly'
  )
);

select pg_temp.mc14a_add_result(
  '04_identidade_e_tenant',
  case
    when current_setting('app.mc14a.payload_6_admin', true)::jsonb->'ids'->>'operacao_id' = current_setting('app.mc14a.operacao_id', true)
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'ids'->>'simulacao_id' = current_setting('app.mc14a.simulacao_id', true)
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'ids'->>'agenda_id' = current_setting('app.mc14a.agenda_id', true)
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'ids'->>'empresa_id' = current_setting('app.mc14a.empresa_id', true)
    then 'PASS' else 'FAIL'
  end,
  current_setting('app.mc14a.payload_6_admin', true)::jsonb->'ids'
);

select pg_temp.mc14a_add_result(
  '05_campos_financeiros_admin_presentes',
  case
    when current_setting('app.mc14a.payload_6_admin', true)::jsonb ? 'resumo_financeiro_admin'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'resumo_financeiro_admin' ? 'valor_movido'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'resumo_financeiro_admin' ? 'valor_base'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'resumo_financeiro_admin' ? 'taxa_ano_pct'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'resumo_financeiro_admin' ? 'vpl_aplicado_pct'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'resumo_financeiro_admin' ? 'premio_corretor_pct'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->'resumo_financeiro_admin' ? 'status_premio'
    then 'PASS' else 'FAIL'
  end,
  current_setting('app.mc14a.payload_6_admin', true)::jsonb->'resumo_financeiro_admin'
);

select pg_temp.mc14a_add_result(
  '06_readonly_sem_mutacao_rpc6',
  case
    when current_setting('app.mc14a.count_operacoes_antes_rpc6', true) = current_setting('app.mc14a.count_operacoes_depois_rpc6', true)
     and current_setting('app.mc14a.count_parcelas_antes_rpc6', true) = current_setting('app.mc14a.count_parcelas_depois_rpc6', true)
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'dml_financeiro' = 'false'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'altera_agenda' = 'false'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'altera_parcelas' = 'false'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'altera_operacao' = 'false'
     and current_setting('app.mc14a.payload_6_admin', true)::jsonb->>'recalcula_operacao' = 'false'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacoes_antes', current_setting('app.mc14a.count_operacoes_antes_rpc6', true),
    'operacoes_depois', current_setting('app.mc14a.count_operacoes_depois_rpc6', true),
    'parcelas_antes', current_setting('app.mc14a.count_parcelas_antes_rpc6', true),
    'parcelas_depois', current_setting('app.mc14a.count_parcelas_depois_rpc6', true)
  )
);

select pg_temp.mc14a_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Teste 14A encerra com ROLLBACK. A fixture 4B/5B/6 não deve permanecer no banco.',
    'fase', '6_RESUMOS_OPERACAO_FINANCEIRA',
    'validacao', 'resumo administrativo positivo com fixture transacional'
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc14a.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
