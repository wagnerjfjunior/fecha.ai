-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 6
-- 14D — Validação de escopo, perfil e tenant da RPC cliente-safe.
--
-- RPC validada:
--   public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
--
-- Objetivo:
--   Provar que a RPC cliente-safe respeita escopo de corretor, perfil administrativo
--   e isolamento tenant em operação marcada como visível ao cliente.
--
-- Cenários validados:
--   1. Corretor dono da simulação acessa operação cliente-safe liberada.
--   2. Outro corretor do mesmo tenant, não dono da simulação, é bloqueado.
--   3. Admin/gestor/coordenador do mesmo tenant acessa.
--   4. Admin/gestor/coordenador de outro tenant é bloqueado por cross_tenant_denied,
--      exceto admin_global, quando existir, pois admin_global possui escopo global por contrato.
--   5. Todas as tentativas permanecem read-only.
--
-- Princípios:
--   - não hardcodar tenant/empresa/usuário/perfil;
--   - escolher massa real disponível no banco;
--   - criar fixture transacional;
--   - usar 4B + 5B para gerar massa financeira válida;
--   - liberar visivel_cliente=true somente dentro da fixture transacional;
--   - encerrar com ROLLBACK.

begin;

select set_config('app.mc14d.results', '[]', true);
select set_config('request.jwt.claim.sub', '', true);

create or replace function pg_temp.mc14d_add_result(
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
  v_atual := coalesce(nullif(current_setting('app.mc14d.results', true), '')::jsonb, '[]'::jsonb);

  perform set_config(
    'app.mc14d.results',
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

create or replace function pg_temp.mc14d_norm_grupo(p_grupo text)
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

with base_empresa as materialized (
  select c.empresa_id
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
  group by c.empresa_id
  having count(*) filter (
    where not (
      coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  ) >= 2
  and count(*) filter (
    where coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
       or coalesce(c.is_admin_local, false)
       or coalesce(c.is_gestor, false)
  ) >= 1
  order by count(*) desc, c.empresa_id
  limit 1
),
owner_corretor as materialized (
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
outro_corretor_mesmo_tenant as materialized (
  select c.*
  from public.corretores c
  join base_empresa b on b.empresa_id = c.empresa_id
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and c.id <> (select id from owner_corretor)
    and not (
      coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by c.created_at desc nulls last, c.id
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
admin_outro_tenant as materialized (
  select c.*
  from public.corretores c
  where c.user_id is not null
    and coalesce(c.ativo, true) = true
    and c.empresa_id <> (select empresa_id from base_empresa)
    and (
      coalesce(c.role, '') in ('admin_global', 'admin_local', 'gestor', 'coordenador')
      or coalesce(c.is_admin_local, false)
      or coalesce(c.is_gestor, false)
    )
  order by
    case when c.role = 'admin_global' then 9 else 1 end,
    c.created_at desc nulls last,
    c.id
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
    o.id,
    e.empreendimento_id,
    'Teste rollback 14D escopo tenant cliente-safe fase 6',
    97000.00,
    25000.00,
    0,
    97000.00,
    jsonb_build_object('origem_teste', '14d_fase_6_rollback', 'fixture_transacional', true),
    'Fixture transacional 14D. Deve sumir no ROLLBACK.'
  from empreendimento_base e
  join owner_corretor o on true
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
    date_trunc('month', current_date + interval '24 years')::date,
    (current_date - interval '1 year')::date,
    (current_date + interval '24 years')::date,
    6.00,
    12.00,
    12.00,
    'composto'::public.mesa_financeira_metodo_calculo,
    'dias_365'::public.mesa_financeira_base_tempo,
    true,true,true,true,true,true,true,true,true,true,true,true,
    true,
    'Fixture transacional 14D para escopo tenant cliente-safe fase 6.'
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
setup as (
  select
    set_config('app.mc14d.owner_user', (select user_id::text from owner_corretor), true),
    set_config('app.mc14d.outro_user', coalesce((select user_id::text from outro_corretor_mesmo_tenant), ''), true),
    set_config('app.mc14d.admin_user', coalesce((select user_id::text from admin_mesmo_tenant), ''), true),
    set_config('app.mc14d.admin_outro_user', coalesce((select user_id::text from admin_outro_tenant), ''), true),
    set_config('app.mc14d.admin_outro_role', coalesce((select role from admin_outro_tenant), ''), true),
    set_config('app.mc14d.simulacao_id', (select id::text from simulacao), true),
    set_config('app.mc14d.empresa_id', (select empresa_id::text from empreendimento_base), true)
)
select pg_temp.mc14d_add_result(
  '00_setup_escopo_fixture',
  case
    when current_setting('app.mc14d.owner_user', true) <> ''
     and current_setting('app.mc14d.outro_user', true) <> ''
     and current_setting('app.mc14d.admin_user', true) <> ''
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'empresa_id', current_setting('app.mc14d.empresa_id', true),
    'owner_user', current_setting('app.mc14d.owner_user', true),
    'outro_mesmo_tenant_user', current_setting('app.mc14d.outro_user', true),
    'admin_mesmo_tenant_user', current_setting('app.mc14d.admin_user', true),
    'admin_outro_tenant_user', current_setting('app.mc14d.admin_outro_user', true),
    'admin_outro_role', current_setting('app.mc14d.admin_outro_role', true)
  )
)
from setup;

-- Fixture financeira criada com perfil admin/gestão do mesmo tenant.
select set_config('request.jwt.claim.sub', current_setting('app.mc14d.admin_user', true), true);
set local role authenticated;

select set_config(
  'app.mc14d.payload_4b',
  public.mesa_cliente_persistir_agenda_financeira_admin(
    current_setting('app.mc14d.simulacao_id', true)::uuid,
    (current_date + interval '730 days')::date,
    jsonb_build_array(
      jsonb_build_object(
        'grupo', 'mensais',
        'descricao', 'Mensais 14D',
        'valor', '3000.00',
        'quantidade', 6,
        'mes_ano', to_char((current_date + interval '760 days')::date, 'MM/YYYY')
      ),
      jsonb_build_object(
        'grupo', 'intermediarias',
        'descricao', 'Intermediaria 14D',
        'valor', '10000.00',
        'quantidade', 2,
        'mes_ano', to_char((current_date + interval '820 days')::date, 'MM/YYYY')
      )
    ),
    jsonb_build_object('origem_teste', '14d')
  )::text,
  true
);

reset role;

with agenda as (
  select a.id
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = current_setting('app.mc14d.simulacao_id', true)::uuid
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
    and coalesce(p.pode_receber_antecipacao, false) = true
    and pg_temp.mc14d_norm_grupo(p.grupo::text) in ('financiamento', 'chaves', 'anuais', 'mensais')
  order by p.data_atual asc, p.valor_atual desc, p.id asc
  limit 1
)
select
  set_config('app.mc14d.agenda_id', (select id::text from agenda), true),
  set_config('app.mc14d.parcela_id', (select id::text from parcela), true);

set local role authenticated;

select set_config(
  'app.mc14d.payload_5b',
  public.mesa_cliente_registrar_operacao_financeira_admin(
    current_setting('app.mc14d.simulacao_id', true)::uuid,
    current_setting('app.mc14d.agenda_id', true)::uuid,
    'antecipacao',
    current_setting('app.mc14d.parcela_id', true)::uuid,
    current_date,
    null,
    null,
    jsonb_build_object('origem_teste', '14d')
  )::text,
  true
);

reset role;

select set_config(
  'app.mc14d.operacao_id',
  current_setting('app.mc14d.payload_5b', true)::jsonb->'operacao'->>'id',
  true
);

-- Liberação cliente-safe apenas para a fixture transacional.
update public.mesa_cliente_fluxo_operacoes
set visivel_cliente = true,
    updated_at = now()
where id = current_setting('app.mc14d.operacao_id', true)::uuid;

select pg_temp.mc14d_add_result(
  '01_operacao_visivel_fixture',
  case
    when current_setting('app.mc14d.payload_4b', true)::jsonb->>'ok' = 'true'
     and current_setting('app.mc14d.payload_5b', true)::jsonb->>'ok' = 'true'
     and exists (
       select 1
       from public.mesa_cliente_fluxo_operacoes o
       where o.id = current_setting('app.mc14d.operacao_id', true)::uuid
         and coalesce(o.visivel_cliente, false) = true
     )
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacao_id', current_setting('app.mc14d.operacao_id', true),
    'payload_4b_ok', current_setting('app.mc14d.payload_4b', true)::jsonb->>'ok',
    'payload_5b_ok', current_setting('app.mc14d.payload_5b', true)::jsonb->>'ok'
  )
);

select set_config(
  'app.mc14d.operacoes_antes',
  (select count(*)::text from public.mesa_cliente_fluxo_operacoes where simulacao_id = current_setting('app.mc14d.simulacao_id', true)::uuid),
  true
);

select set_config(
  'app.mc14d.parcelas_antes',
  (select count(*)::text from public.mesa_cliente_fluxo_parcelas where simulacao_id = current_setting('app.mc14d.simulacao_id', true)::uuid),
  true
);

-- Cenário 1: corretor dono acessa.
select set_config('request.jwt.claim.sub', current_setting('app.mc14d.owner_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_obter_resumo_operacao_cliente_safe(
      current_setting('app.mc14d.operacao_id', true)::uuid,
      jsonb_build_object('origem_teste', '14d_owner')
    );

    perform pg_temp.mc14d_add_result(
      '02_owner_corretor_acessa_cliente_safe',
      case when v_payload->>'ok' = 'true' and v_payload->>'visao' = 'cliente_safe' then 'PASS' else 'FAIL' end,
      jsonb_build_object('ok', v_payload->>'ok', 'visao', v_payload->>'visao')
    );
  exception when others then
    perform pg_temp.mc14d_add_result(
      '02_owner_corretor_acessa_cliente_safe',
      'FAIL',
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- Cenário 2: outro corretor do mesmo tenant, não dono, deve ser bloqueado.
select set_config('request.jwt.claim.sub', current_setting('app.mc14d.outro_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_obter_resumo_operacao_cliente_safe(
      current_setting('app.mc14d.operacao_id', true)::uuid,
      jsonb_build_object('origem_teste', '14d_outro_mesmo_tenant')
    );

    perform pg_temp.mc14d_add_result(
      '03_outro_corretor_mesmo_tenant_bloqueado',
      'FAIL',
      jsonb_build_object('motivo', 'outro_corretor_acessou', 'payload', v_payload)
    );
  exception when others then
    perform pg_temp.mc14d_add_result(
      '03_outro_corretor_mesmo_tenant_bloqueado',
      case when sqlstate = '42501' and sqlerrm = 'corretor_scope_denied' then 'PASS' else 'FAIL' end,
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- Cenário 3: admin/gestor/coordenador do mesmo tenant acessa.
select set_config('request.jwt.claim.sub', current_setting('app.mc14d.admin_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
begin
  begin
    v_payload := public.mesa_cliente_obter_resumo_operacao_cliente_safe(
      current_setting('app.mc14d.operacao_id', true)::uuid,
      jsonb_build_object('origem_teste', '14d_admin_mesmo_tenant')
    );

    perform pg_temp.mc14d_add_result(
      '04_admin_mesmo_tenant_acessa',
      case when v_payload->>'ok' = 'true' then 'PASS' else 'FAIL' end,
      jsonb_build_object('ok', v_payload->>'ok', 'visao', v_payload->>'visao')
    );
  exception when others then
    perform pg_temp.mc14d_add_result(
      '04_admin_mesmo_tenant_acessa',
      'FAIL',
      jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
    );
  end;
end $$;

reset role;

-- Cenário 4: admin de outro tenant bloqueado, exceto admin_global por contrato.
select set_config('request.jwt.claim.sub', current_setting('app.mc14d.admin_outro_user', true), true);
set local role authenticated;

do $$
declare
  v_payload jsonb;
  v_role_outro text := current_setting('app.mc14d.admin_outro_role', true);
begin
  if current_setting('app.mc14d.admin_outro_user', true) = '' then
    perform pg_temp.mc14d_add_result(
      '05_admin_outro_tenant_bloqueado_ou_global',
      'SKIP',
      jsonb_build_object('motivo', 'sem_admin_outro_tenant_disponivel')
    );
  elsif v_role_outro = 'admin_global' then
    begin
      v_payload := public.mesa_cliente_obter_resumo_operacao_cliente_safe(
        current_setting('app.mc14d.operacao_id', true)::uuid,
        jsonb_build_object('origem_teste', '14d_admin_global')
      );

      perform pg_temp.mc14d_add_result(
        '05_admin_outro_tenant_bloqueado_ou_global',
        case when v_payload->>'ok' = 'true' then 'PASS' else 'FAIL' end,
        jsonb_build_object('observacao', 'admin_global_tem_escopo_global_por_contrato', 'ok', v_payload->>'ok')
      );
    exception when others then
      perform pg_temp.mc14d_add_result(
        '05_admin_outro_tenant_bloqueado_ou_global',
        'FAIL',
        jsonb_build_object('esperado', 'admin_global_acessa', 'sqlstate', sqlstate, 'message', sqlerrm)
      );
    end;
  else
    begin
      v_payload := public.mesa_cliente_obter_resumo_operacao_cliente_safe(
        current_setting('app.mc14d.operacao_id', true)::uuid,
        jsonb_build_object('origem_teste', '14d_admin_outro_tenant')
      );

      perform pg_temp.mc14d_add_result(
        '05_admin_outro_tenant_bloqueado_ou_global',
        'FAIL',
        jsonb_build_object('motivo', 'admin_outro_tenant_acessou', 'payload', v_payload)
      );
    exception when others then
      perform pg_temp.mc14d_add_result(
        '05_admin_outro_tenant_bloqueado_ou_global',
        case when sqlstate = '42501' and sqlerrm = 'cross_tenant_denied' then 'PASS' else 'FAIL' end,
        jsonb_build_object('sqlstate', sqlstate, 'message', sqlerrm)
      );
    end;
  end if;
end $$;

reset role;

select set_config(
  'app.mc14d.operacoes_depois',
  (select count(*)::text from public.mesa_cliente_fluxo_operacoes where simulacao_id = current_setting('app.mc14d.simulacao_id', true)::uuid),
  true
);

select set_config(
  'app.mc14d.parcelas_depois',
  (select count(*)::text from public.mesa_cliente_fluxo_parcelas where simulacao_id = current_setting('app.mc14d.simulacao_id', true)::uuid),
  true
);

select pg_temp.mc14d_add_result(
  '06_readonly_escopo_sem_mutacao',
  case
    when current_setting('app.mc14d.operacoes_antes', true) = current_setting('app.mc14d.operacoes_depois', true)
     and current_setting('app.mc14d.parcelas_antes', true) = current_setting('app.mc14d.parcelas_depois', true)
    then 'PASS' else 'FAIL'
  end,
  jsonb_build_object(
    'operacoes_antes', current_setting('app.mc14d.operacoes_antes', true),
    'operacoes_depois', current_setting('app.mc14d.operacoes_depois', true),
    'parcelas_antes', current_setting('app.mc14d.parcelas_antes', true),
    'parcelas_depois', current_setting('app.mc14d.parcelas_depois', true)
  )
);

select pg_temp.mc14d_add_result(
  '99_rollback_notice',
  'INFO',
  jsonb_build_object(
    'fase', '6_RESUMOS_OPERACAO_FINANCEIRA',
    'mensagem', 'Teste 14D encerra com ROLLBACK. Fixture de escopo/tenant nao deve permanecer.'
  )
);

select
  r.elem->>'bloco' as bloco,
  r.elem->>'status' as status,
  r.elem->'detalhe' as detalhe
from jsonb_array_elements(current_setting('app.mc14d.results', true)::jsonb) with ordinality as r(elem, ord)
order by r.ord;

rollback;
