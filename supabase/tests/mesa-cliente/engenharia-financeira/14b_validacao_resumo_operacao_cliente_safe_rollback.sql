-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 6
-- 14B — Validação positiva da RPC cliente-safe de resumo de operação financeira.
--
-- RPC validada:
--   public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
--
-- Princípios do teste:
--   - não hardcodar tenant/empresa/usuário/perfil;
--   - derivar admin/gestor/coordenador ativo a partir do banco;
--   - criar fixture financeira transacional;
--   - usar RPCs anteriores como fonte de verdade para gerar massa válida;
--   - confirmar operação pela RPC da Fase 5C;
--   - liberar visivel_cliente=true apenas dentro da fixture transacional;
--   - validar payload comercial mínimo;
--   - validar ausência de vazamento de campos e termos internos sensíveis;
--   - validar que a RPC 6 é read-only;
--   - encerrar tudo com ROLLBACK.
--
-- Observação crítica:
--   A Fase 6 não define o mecanismo real de publicação/liberação cliente-safe.
--   Neste teste, visivel_cliente=true é aplicado diretamente na fixture transacional
--   exclusivamente para permitir o teste positivo da RPC cliente-safe.
--   Isso não altera o contrato funcional da Fase 6.
--
-- Dependências funcionais:
--   - Fase 4B: mesa_cliente_persistir_agenda_financeira_admin
--   - Fase 5B: mesa_cliente_registrar_operacao_financeira_admin
--   - Fase 5C: mesa_cliente_atualizar_status_operacao_financeira_admin
--   - Fase 6:  mesa_cliente_obter_resumo_operacao_cliente_safe

begin;

select set_config('app.mc14b.results', '[]', true);
select set_config('app.mc14b.user_id', '', true);
select set_config('app.mc14b.simulacao_id', '', true);
select set_config('app.mc14b.empresa_id', '', true);
select set_config('app.mc14b.empreendimento_id', '', true);
select set_config('app.mc14b.politica_id', '', true);
select set_config('app.mc14b.agenda_id', '', true);
select set_config('app.mc14b.parcela_id', '', true);
select set_config('app.mc14b.operacao_id', '', true);
select set_config('app.mc14b.payload_4b', 'null', true);
select set_config('app.mc14b.payload_5b', 'null', true);
select set_config('app.mc14b.payload_5c', 'null', true);
select set_config('app.mc14b.payload_6_cliente', 'null', true);
select set_config('app.mc14b.count_operacoes_antes_rpc6', '0', true);
select set_config('app.mc14b.count_operacoes_depois_rpc6', '0', true);
select set_config('app.mc14b.count_parcelas_antes_rpc6', '0', true);
select set_config('app.mc14b.count_parcelas_depois_rpc6', '0', true);
select set_config('request.jwt.claim.sub', '', true);

-- Datas dinâmicas da fixture. Sem ano fixo/mágico.
select set_config('app.mc14b.data_referencia', current_date::text, true);
select set_config('app.mc14b.data_ato', (current_date + interval '730 days')::date::text, true);
select set_config('app.mc14b.mes_mensais', to_char((current_date + interval '760 days')::date, 'MM/YYYY'), true);
select set_config('app.mc14b.mes_intermediarias', to_char((current_date + interval '820 days')::date, 'MM/YYYY'), true);
select set_config('app.mc14b.politica_mes_referencia', date_trunc('month', current_date + interval '22 years')::date::text, true);
select set_config('app.mc14b.politica_vigencia_inicio', (current_date - interval '1 year')::date::text, true);
select set_config('app.mc14b.politica_vigencia_fim', (current_date + interval '22 years')::date::text, true);

create or replace function pg_temp.mc14b_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.mc14b.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc14b.results',
    (v_atual || jsonb_build_array(jsonb_build_object(
      'bloco', p_bloco,
      'status', p_status,
      'detalhe', coalesce(p_detalhe, '{}'::jsonb)
    )))::text,
    true
  );
end;
$$;

create or replace function pg_temp.mc14b_norm_grupo(p_grupo text)
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
    'Teste rollback 14B cliente-safe fase 6',
    88000.00,
    22000.00,
    0,
    88000.00,
    jsonb_build_object('origem_teste', '14b_fase_6_rollback', 'fixture_transacional', true),
    'Fixture transacional 14B. Deve sumir no ROLLBACK.'
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
    current_setting('app.mc14b.politica_mes_referencia', true)::date,
    current_setting('app.mc14b.politica_vigencia_inicio', true)::date,
    current_setting('app.mc14b.politica_vigencia_fim', true)::date,
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture transacional 14B para resumo cliente-safe fase 6.'
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
      (0.00::numeric, 2.00::numeric, 100.00::numeric, 'premio_cheio'::text, 'Faixa fixture 14B — prêmio cheio', 1),
      (2.01::numeric, 4.00::numeric, 70.00::numeric, 'premio_parcial'::text, 'Faixa fixture 14B — prêmio parcial', 2),
      (4.01::numeric, 6.00::numeric, 0.00::numeric, 'sem_premio'::text, 'Faixa fixture 14B — sem prêmio', 3)
  ) as v(vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, descricao, ordem)
  returning id
),
setup as (
  select
    set_config('request.jwt.claim.sub', c.user_id::text, true),
    set_config('app.mc14b.user_id', c.user_id::text, true),
    set_config('app.mc14b.simulacao_id', s.id::text, true),
    set_config('app.mc14b.empresa_id', s.empresa_id::text, true),
    set_config('app.mc14b.empreendimento_id', s.empreendimento_id::text, true),
    set_config('app.mc14b.politica_id', p.id::text, true)
  from candidato c
  join simulacao s on true
  join politica p on true
)
select pg_temp.mc14b_add_result(
  '00_setup_admin_fixture',
  case when count(*) = 1 then 'PASS' else 'FAIL' end,
  jsonb_build_object(
    'user_id', current_setting('app.mc14b.user_id', true),
    'simulacao_id', current_setting('app.mc14b.simulacao_id', true),
    'politica_id', current_setting('app.mc14b.politica_id', true),
    'qtd_faixas', (select count(*) from faixas)
  )
)
from setup;

set local role authenticated;

with chamada_4b as materialized (
  select public.mesa_cliente_persistir_agenda_financeira_admin(
    current_setting('app.mc14b.simulacao_id', true)::uuid,
    current_setting('app.mc14b.data_ato', true)::date,
    jsonb_build_array(
      jsonb_build_object(
        'grupo','mensais',
        'descricao','Mensais 14B',
        'valor','3000.00',
        'quantidade',6,
        'mes_ano', current_setting('app.mc14b.mes_mensais', true)
      ),
      jsonb_build_object(
        'grupo','intermediarias',
        'descricao','Intermediária 14B',
        'valor','10000.00',
        'quantidade',2,
        'mes_ano', current_setting('app.mc14b.mes_intermediarias', true)
      )
    ),
    jsonb_build_object('origem_teste', '14b')
  ) as payload
)
select set_config('app.mc14b.payload_4b', coalesce((select payload::text from chamada_4b), 'null'), true);

reset role;

with agenda as (
  select a.*
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = current_setting('app.mc14b.simulacao_id', true)::uuid
    and a.status = 'ativa'
  order by a.created_at desc nulls last, a.id desc
  limit 1
),
parcela as (
  select fp.*
  from public.mesa_cliente_fluxo_parcelas fp
  join agenda a on a.id = fp.agenda_id
  where fp.valor_atual > 0
    and fp.data_atual > current_setting('app.mc14b.data_referencia', true)::date
    and coalesce(fp.eh_periodicidade_simbolica, false) = false
    and coalesce(fp.pode_receber_antecipacao, false) = true
    and pg_temp.mc14b_norm_grupo(fp.grupo::text) in ('financiamento','chaves','anuais','mensais')
  order by fp.data_atual asc, fp.valor_atual desc, fp.id asc
  limit 1
),
setup as (
  select
    set_config('app.mc14b.agenda_id', (select id::text from agenda), true),
    set_config('app.mc14b.parcela_id', (select id::text from parcela), true)
)
select pg_temp.mc14b_add_result(
  '01_agenda_parcela_fixture',
  case
    when current_setting('app.mc14b.agenda_id', true) <> ''
     and current_setting('app.mc14b.parcela_id', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'agenda_id', current_setting('app.mc14b.agenda_id', true),
    'parcela_id', current_setting('app.mc14b.parcela_id', true),
    'payload_4b_ok', current_setting('app.mc14b.payload_4b', true)::jsonb->>'ok'
  )
)
from setup;

set local role authenticated;

with chamada_5b as materialized (
  select public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc14b.simulacao_id', true)::uuid,
    current_setting('app.mc14b.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc14b.parcela_id', true)::uuid,
    current_setting('app.mc14b.data_referencia', true)::date,
    null,
    null,
    jsonb_build_object('origem_teste', '14b', 'operacao', 'antecipacao_cliente_safe_resumo')
  ) as payload
)
select
  set_config('app.mc14b.payload_5b', coalesce((select payload::text from chamada_5b), 'null'), true),
  set_config('app.mc14b.operacao_id', coalesce((select payload->'operacao'->>'id' from chamada_5b), ''), true);

with chamada_5c as materialized (
  select public.mesa_cliente_atualizar_status_operacao_financeira_admin(
    current_setting('app.mc14b.operacao_id', true)::uuid,
    'confirmar',
    null,
    jsonb_build_object('origem_teste', '14b_confirmar')
  ) as payload
)
select set_config('app.mc14b.payload_5c', coalesce((select payload::text from chamada_5c), 'null'), true);

reset role;

-- Liberação cliente-safe apenas para fixture transacional.
-- Publicação real está fora do escopo da Fase 6.
update public.mesa_cliente_fluxo_operacoes
set visivel_cliente = true,
    metadata = coalesce(metadata, '{}'::jsonb)
      || jsonb_build_object(
        'fixture_14b',
        jsonb_build_object(
          'visivel_cliente_forcado_em_fixture', true,
          'motivo', 'teste positivo cliente-safe fase 6; publicacao real fora do escopo da fase 6'
        )
      ),
    updated_at = now()
where id = current_setting('app.mc14b.operacao_id', true)::uuid;

select pg_temp.mc14b_add_result(
  '02_operacao_confirmada_liberada_fixture',
  case
    when current_setting('app.mc14b.payload_5b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14b.payload_5c', true)::jsonb->>'ok' = 'true'
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes o
       where o.id = current_setting('app.mc14b.operacao_id', true)::uuid
         and o.status_operacao = 'confirmada'
         and coalesce(o.confirmado,false) = true
         and coalesce(o.visivel_cliente,false) = true
     )
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacao_id', current_setting('app.mc14b.operacao_id', true),
    'payload_5b_ok', current_setting('app.mc14b.payload_5b', true)::jsonb->>'ok',
    'payload_5c_ok', current_setting('app.mc14b.payload_5c', true)::jsonb->>'ok',
    'visivel_cliente', (
      select o.visivel_cliente
      from public.mesa_cliente_fluxo_operacoes o
      where o.id = current_setting('app.mc14b.operacao_id', true)::uuid
    )
  )
);

select set_config(
  'app.mc14b.count_operacoes_antes_rpc6',
  (select count(*)::text from public.mesa_cliente_fluxo_operacoes where simulacao_id = current_setting('app.mc14b.simulacao_id', true)::uuid),
  true
);

select set_config(
  'app.mc14b.count_parcelas_antes_rpc6',
  (select count(*)::text from public.mesa_cliente_fluxo_parcelas where simulacao_id = current_setting('app.mc14b.simulacao_id', true)::uuid),
  true
);

set local role authenticated;

select set_config(
  'app.mc14b.payload_6_cliente',
  public.mesa_cliente_obter_resumo_operacao_cliente_safe(
    current_setting('app.mc14b.operacao_id', true)::uuid,
    jsonb_build_object('origem_teste', '14b')
  )::text,
  true
);

reset role;

select set_config(
  'app.mc14b.count_operacoes_depois_rpc6',
  (select count(*)::text from public.mesa_cliente_fluxo_operacoes where simulacao_id = current_setting('app.mc14b.simulacao_id', true)::uuid),
  true
);

select set_config(
  'app.mc14b.count_parcelas_depois_rpc6',
  (select count(*)::text from public.mesa_cliente_fluxo_parcelas where simulacao_id = current_setting('app.mc14b.simulacao_id', true)::uuid),
  true
);

select pg_temp.mc14b_add_result(
  '03_rpc_cliente_safe_basico',
  case
    when current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'fase' = '6_RESUMOS_OPERACAO_FINANCEIRA'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'visao' = 'cliente_safe'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'cliente_safe' = 'true'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'readonly' = 'true'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'fase', current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'fase',
    'visao', current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'visao',
    'cliente_safe', current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'cliente_safe',
    'readonly', current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'readonly'
  )
);

select pg_temp.mc14b_add_result(
  '04_payload_comercial_minimo',
  case
    when current_setting('app.mc14b.payload_6_cliente', true)::jsonb ? 'status_comercial'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb ? 'resumo_condicao'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb ? 'cliente'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb ? 'parcelas_impactadas'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb ? 'avisos'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'status_comercial', current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'status_comercial',
    'resumo_keys', (
      select jsonb_agg(k order by k)
      from jsonb_object_keys(current_setting('app.mc14b.payload_6_cliente', true)::jsonb->'resumo_condicao') as t(k)
    ),
    'cliente', current_setting('app.mc14b.payload_6_cliente', true)::jsonb->'cliente'
  )
);

select pg_temp.mc14b_add_result(
  '05_sem_vazamento_campos_sensiveis_top_level',
  case
    when not (
      current_setting('app.mc14b.payload_6_cliente', true)::jsonb ?| array[
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
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'top_level_keys', (
      select jsonb_agg(k order by k)
      from jsonb_object_keys(current_setting('app.mc14b.payload_6_cliente', true)::jsonb) as t(k)
    )
  )
);

select pg_temp.mc14b_add_result(
  '06_sem_vazamento_campos_sensiveis_textual',
  case
    when current_setting('app.mc14b.payload_6_cliente', true) !~* '(empresa_id|tenant_id|politica_id|checksum_operacao|metadata|resumo_financeiro_admin|taxa_ano_pct|vpl_aplicado_pct|premio_corretor_pct|status_premio|confirmado_por|cancelado_por|vpl|taxa|prêmio|premio|comissao|comissão)'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'avisos', current_setting('app.mc14b.payload_6_cliente', true)::jsonb->'avisos'
  )
);

select pg_temp.mc14b_add_result(
  '07_readonly_sem_mutacao_rpc6',
  case
    when current_setting('app.mc14b.count_operacoes_antes_rpc6', true) = current_setting('app.mc14b.count_operacoes_depois_rpc6', true)
     and current_setting('app.mc14b.count_parcelas_antes_rpc6', true) = current_setting('app.mc14b.count_parcelas_depois_rpc6', true)
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'dml_financeiro' = 'false'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'altera_agenda' = 'false'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'altera_parcelas' = 'false'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'altera_operacao' = 'false'
     and current_setting('app.mc14b.payload_6_cliente', true)::jsonb->>'recalcula_operacao' = 'false'
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacoes_antes', current_setting('app.mc14b.count_operacoes_antes_rpc6', true),
    'operacoes_depois', current_setting('app.mc14b.count_operacoes_depois_rpc6', true),
    'parcelas_antes', current_setting('app.mc14b.count_parcelas_antes_rpc6', true),
    'parcelas_depois', current_setting('app.mc14b.count_parcelas_depois_rpc6', true)
  )
);

select pg_temp.mc14b_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'mensagem', 'Teste 14B encerra com ROLLBACK. A liberacao visivel_cliente=true e apenas fixture transacional, pois publicacao real esta fora do escopo da Fase 6.',
    'fase', '6_RESUMOS_OPERACAO_FINANCEIRA',
    'validacao', 'resumo cliente-safe positivo com operacao previamente liberada em fixture'
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc14b.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
