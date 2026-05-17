-- MesaCliente Engenharia Financeira — testes de hardening
-- Branch alvo: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Validar a migration:
--   supabase/migrations/20260517162000_mesa_cliente_engenharia_financeira_hardening.sql
--
-- Escopo validado:
--   1. RLS habilitada nas 4 tabelas financeiras.
--   2. Policies canônicas existentes e policies legadas removidas.
--   3. Escrita direta por authenticated bloqueada.
--   4. Leitura por tenant funcionando.
--   5. Integridade empresa/empreendimento/simulação/política/parcela validada no banco.
--   6. Periodicidade simbólica não entra como parcela negociável.
--   7. Prêmio interno nunca fica visível ao cliente.
--
-- Segurança operacional:
--   - Este arquivo usa BEGIN/ROLLBACK.
--   - Os dados de teste são temporários na transação.
--   - Não altera parser, motor financeiro atual, Worker, Make ou front.

begin;

-- -----------------------------------------------------------------------------
-- Helpers locais de teste
-- -----------------------------------------------------------------------------

create or replace function pg_temp.assert_true(
  p_condition boolean,
  p_message text
)
returns void
language plpgsql
as $$
begin
  if coalesce(p_condition, false) is not true then
    raise exception 'ASSERT FAIL: %', p_message;
  end if;
end;
$$;

create or replace function pg_temp.expect_error(
  p_sql text,
  p_context text
)
returns void
language plpgsql
security invoker
as $$
declare
  v_error_ok boolean := false;
begin
  begin
    execute p_sql;
  exception when others then
    v_error_ok := true;
  end;

  if not v_error_ok then
    raise exception 'ASSERT FAIL: erro esperado não ocorreu em [%]. SQL: %', p_context, p_sql;
  end if;
end;
$$;

create or replace function pg_temp.create_test_auth_user(
  p_user_id uuid,
  p_email text
)
returns void
language plpgsql
as $$
declare
  v_cols text[] := array[quote_ident('id')];
  v_vals text[] := array['$1'];
  v_known_cols text[] := array['id'];
  v_missing text[];
begin
  -- Insere usuário de teste em auth.users de forma defensiva, considerando
  -- variações de schema entre versões do Supabase Auth.

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'instance_id'
  ) then
    v_cols := array_append(v_cols, quote_ident('instance_id'));
    v_vals := array_append(v_vals, '''00000000-0000-0000-0000-000000000000''::uuid');
    v_known_cols := array_append(v_known_cols, 'instance_id');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'aud'
  ) then
    v_cols := array_append(v_cols, quote_ident('aud'));
    v_vals := array_append(v_vals, '''authenticated''');
    v_known_cols := array_append(v_known_cols, 'aud');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'role'
  ) then
    v_cols := array_append(v_cols, quote_ident('role'));
    v_vals := array_append(v_vals, '''authenticated''');
    v_known_cols := array_append(v_known_cols, 'role');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'email'
  ) then
    v_cols := array_append(v_cols, quote_ident('email'));
    v_vals := array_append(v_vals, '$2');
    v_known_cols := array_append(v_known_cols, 'email');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'encrypted_password'
  ) then
    v_cols := array_append(v_cols, quote_ident('encrypted_password'));
    v_vals := array_append(v_vals, '''mesa-cliente-test-password-not-used''');
    v_known_cols := array_append(v_known_cols, 'encrypted_password');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'email_confirmed_at'
  ) then
    v_cols := array_append(v_cols, quote_ident('email_confirmed_at'));
    v_vals := array_append(v_vals, 'now()');
    v_known_cols := array_append(v_known_cols, 'email_confirmed_at');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'created_at'
  ) then
    v_cols := array_append(v_cols, quote_ident('created_at'));
    v_vals := array_append(v_vals, 'now()');
    v_known_cols := array_append(v_known_cols, 'created_at');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'updated_at'
  ) then
    v_cols := array_append(v_cols, quote_ident('updated_at'));
    v_vals := array_append(v_vals, 'now()');
    v_known_cols := array_append(v_known_cols, 'updated_at');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'raw_app_meta_data'
  ) then
    v_cols := array_append(v_cols, quote_ident('raw_app_meta_data'));
    v_vals := array_append(v_vals, '''{"provider":"email","providers":["email"]}''::jsonb');
    v_known_cols := array_append(v_known_cols, 'raw_app_meta_data');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'raw_user_meta_data'
  ) then
    v_cols := array_append(v_cols, quote_ident('raw_user_meta_data'));
    v_vals := array_append(v_vals, '''{}''::jsonb');
    v_known_cols := array_append(v_known_cols, 'raw_user_meta_data');
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'auth' and table_name = 'users' and column_name = 'is_anonymous'
  ) then
    v_cols := array_append(v_cols, quote_ident('is_anonymous'));
    v_vals := array_append(v_vals, 'false');
    v_known_cols := array_append(v_known_cols, 'is_anonymous');
  end if;

  select array_agg(column_name order by ordinal_position)
    into v_missing
  from information_schema.columns
  where table_schema = 'auth'
    and table_name = 'users'
    and is_nullable = 'NO'
    and column_default is null
    and not (column_name = any(v_known_cols));

  if v_missing is not null then
    raise exception 'auth.users possui colunas obrigatórias não mapeadas no teste: %', v_missing;
  end if;

  execute format(
    'insert into auth.users (%s) values (%s) on conflict (id) do nothing',
    array_to_string(v_cols, ', '),
    array_to_string(v_vals, ', ')
  ) using p_user_id, p_email;
end;
$$;

-- -----------------------------------------------------------------------------
-- Auditoria estrutural sem dados
-- -----------------------------------------------------------------------------

do $$
declare
  v_count int;
begin
  -- RLS habilitada.
  select count(*) into v_count
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in (
      'mesa_cliente_politicas_financeiras',
      'mesa_cliente_politica_premio_faixas',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
    and c.relrowsecurity is true;

  perform pg_temp.assert_true(v_count = 4, 'RLS deve estar habilitada nas 4 tabelas financeiras');

  -- Policies canônicas presentes.
  select count(*) into v_count
  from pg_policies
  where schemaname = 'public'
    and policyname in (
      'mcpf_select_tenant',
      'mcpf_no_direct_insert',
      'mcpf_no_direct_update',
      'mcpf_no_direct_delete',
      'mcppf_select_tenant',
      'mcppf_no_direct_insert',
      'mcppf_no_direct_update',
      'mcppf_no_direct_delete',
      'mcfp_select_tenant',
      'mcfp_no_direct_insert',
      'mcfp_no_direct_update',
      'mcfp_no_direct_delete',
      'mcfo_select_tenant',
      'mcfo_no_direct_insert',
      'mcfo_no_direct_update',
      'mcfo_no_direct_delete'
    );

  perform pg_temp.assert_true(v_count = 16, 'As 16 policies canônicas devem existir');

  -- Policies legadas/duplicadas removidas.
  select count(*) into v_count
  from pg_policies
  where schemaname = 'public'
    and policyname in (
      'mesa_politicas_financeiras_select_tenant',
      'mesa_politicas_financeiras_no_direct_insert',
      'mesa_politicas_financeiras_no_direct_update',
      'mesa_politicas_financeiras_no_direct_delete',
      'mesa_premio_faixas_select_tenant',
      'mesa_premio_faixas_no_direct_insert',
      'mesa_premio_faixas_no_direct_update',
      'mesa_premio_faixas_no_direct_delete',
      'mesa_fluxo_parcelas_select_tenant',
      'mesa_fluxo_parcelas_no_direct_insert',
      'mesa_fluxo_parcelas_no_direct_update',
      'mesa_fluxo_parcelas_no_direct_delete',
      'mesa_fluxo_operacoes_select_tenant',
      'mesa_fluxo_operacoes_no_direct_insert',
      'mesa_fluxo_operacoes_no_direct_update',
      'mesa_fluxo_operacoes_no_direct_delete'
    );

  perform pg_temp.assert_true(v_count = 0, 'Policies legadas/duplicadas devem ter sido removidas');

  -- Trigger de integridade presente nas 4 tabelas.
  select count(*) into v_count
  from pg_trigger t
  join pg_class c on c.oid = t.tgrelid
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relname in (
      'mesa_cliente_politicas_financeiras',
      'mesa_cliente_politica_premio_faixas',
      'mesa_cliente_fluxo_parcelas',
      'mesa_cliente_fluxo_operacoes'
    )
    and t.tgname in (
      'trg_mcpf_assert_integridade',
      'trg_mcppf_assert_integridade',
      'trg_mcfp_assert_integridade',
      'trg_mcfo_assert_integridade'
    )
    and not t.tgisinternal;

  perform pg_temp.assert_true(v_count = 4, 'Triggers de integridade devem existir nas 4 tabelas');
end $$;

-- -----------------------------------------------------------------------------
-- Testes comportamentais com dados transacionais
-- -----------------------------------------------------------------------------

do $$
declare
  v_plan_id uuid := gen_random_uuid();

  v_user_a uuid := gen_random_uuid();
  v_user_b uuid := gen_random_uuid();

  v_empresa_a uuid := gen_random_uuid();
  v_empresa_b uuid := gen_random_uuid();

  v_corretor_a uuid := gen_random_uuid();
  v_corretor_b uuid := gen_random_uuid();

  v_empreendimento_a uuid := gen_random_uuid();
  v_empreendimento_b uuid := gen_random_uuid();

  v_simulacao_a uuid := gen_random_uuid();
  v_simulacao_b uuid := gen_random_uuid();

  v_politica_a uuid := gen_random_uuid();
  v_politica_b uuid := gen_random_uuid();

  v_parcela_a uuid := gen_random_uuid();
  v_parcela_b uuid := gen_random_uuid();

  v_operacao_a uuid := gen_random_uuid();

  v_count int;
  v_bool boolean;
begin
  -- Usuários de teste para RLS.
  perform pg_temp.create_test_auth_user(v_user_a, 'mesa-cliente-user-a-' || v_user_a::text || '@example.test');
  perform pg_temp.create_test_auth_user(v_user_b, 'mesa-cliente-user-b-' || v_user_b::text || '@example.test');

  -- Plano/empresas/empreendimentos isolados.
  insert into public.planos (
    id, nome, slug, max_corretores, max_times, max_leads_mes, preco_mensal, features, ativo
  ) values (
    v_plan_id,
    'Plano Teste MesaCliente Engenharia Financeira',
    'plano-teste-mesa-financeira-' || left(v_plan_id::text, 8),
    100,
    10,
    100000,
    0,
    '{}'::jsonb,
    true
  );

  insert into public.empresas (id, nome, slug, plano_id, ativa)
  values
    (v_empresa_a, 'Empresa Teste A Engenharia Financeira', 'empresa-teste-a-' || left(v_empresa_a::text, 8), v_plan_id, true),
    (v_empresa_b, 'Empresa Teste B Engenharia Financeira', 'empresa-teste-b-' || left(v_empresa_b::text, 8), v_plan_id, true);

  insert into public.empreendimentos (id, empresa_id, nome, incorporadora, bairro, cidade)
  values
    (v_empreendimento_a, v_empresa_a, 'Empreendimento Teste A', 'Incorporadora A', 'Bairro A', 'São Paulo'),
    (v_empreendimento_b, v_empresa_b, 'Empreendimento Teste B', 'Incorporadora B', 'Bairro B', 'São Paulo');

  insert into public.corretores (id, user_id, nome, email, empresa_id, ativo, role)
  values
    (v_corretor_a, v_user_a, 'Corretor Teste A', 'corretor-a-' || v_user_a::text || '@example.test', v_empresa_a, true, 'gestor'),
    (v_corretor_b, v_user_b, 'Corretor Teste B', 'corretor-b-' || v_user_b::text || '@example.test', v_empresa_b, true, 'gestor');

  insert into public.mesa_simulacoes (
    id, empresa_id, corretor_id, empreendimento_id, cliente_nome, valor_total, entrada, financiamento, valor_final
  ) values
    (v_simulacao_a, v_empresa_a, v_corretor_a, v_empreendimento_a, 'Cliente Teste A', 1000000, 100000, 700000, 1000000),
    (v_simulacao_b, v_empresa_b, v_corretor_b, v_empreendimento_b, 'Cliente Teste B', 2000000, 200000, 1400000, 2000000);

  -- Inserts válidos como dono/migration runner: devem passar.
  insert into public.mesa_cliente_politicas_financeiras (
    id,
    empresa_id,
    empreendimento_id,
    mes_referencia,
    vigencia_inicio,
    vigencia_fim,
    vpl_max_pct,
    taxa_antecipacao_ano_pct,
    taxa_postergacao_ano_pct,
    observacoes
  ) values
    (v_politica_a, v_empresa_a, v_empreendimento_a, date '2026-05-01', date '2026-05-01', date '2026-05-31', 6, 12, 12, 'Política A teste'),
    (v_politica_b, v_empresa_b, v_empreendimento_b, date '2026-05-01', date '2026-05-01', date '2026-05-31', 6, 12, 12, 'Política B teste');

  insert into public.mesa_cliente_politica_premio_faixas (
    empresa_id,
    politica_id,
    vpl_de_pct,
    vpl_ate_pct,
    premio_corretor_pct,
    status,
    descricao,
    ordem
  ) values (
    v_empresa_a,
    v_politica_a,
    0,
    3,
    2,
    'premio_cheio',
    'Faixa teste A',
    1
  );

  -- Periodicidade simbólica: mesmo que alguém tente marcar flags negociáveis,
  -- o banco deve forçar tudo para false.
  insert into public.mesa_cliente_fluxo_parcelas (
    id,
    empresa_id,
    simulacao_id,
    empreendimento_id,
    grupo,
    descricao,
    valor_original,
    valor_atual,
    data_original,
    data_atual,
    origem_data,
    ordem,
    eh_periodicidade_simbolica,
    pode_receber_vpl,
    pode_receber_antecipacao,
    pode_receber_postergacao
  ) values (
    v_parcela_a,
    v_empresa_a,
    v_simulacao_a,
    v_empreendimento_a,
    'periodicidade',
    'Periodicidade simbólica teste',
    0,
    0,
    date '2026-05-17',
    date '2026-05-17',
    'manual',
    1,
    true,
    true,
    true,
    true
  );

  select
    pode_receber_vpl or pode_receber_antecipacao or pode_receber_postergacao
  into v_bool
  from public.mesa_cliente_fluxo_parcelas
  where id = v_parcela_a;

  perform pg_temp.assert_true(v_bool is false, 'Periodicidade simbólica deve ter flags negociáveis forçadas para false');

  insert into public.mesa_cliente_fluxo_parcelas (
    id,
    empresa_id,
    simulacao_id,
    empreendimento_id,
    grupo,
    descricao,
    valor_original,
    valor_atual,
    data_original,
    data_atual,
    origem_data,
    ordem,
    pode_receber_vpl,
    pode_receber_antecipacao,
    pode_receber_postergacao
  ) values (
    v_parcela_b,
    v_empresa_b,
    v_simulacao_b,
    v_empreendimento_b,
    'mensal',
    'Parcela mensal teste B',
    10000,
    10000,
    date '2026-06-17',
    date '2026-06-17',
    'manual',
    1,
    true,
    true,
    true
  );

  -- Prêmio interno: se vier premio_corretor_pct, visivel_cliente precisa virar false.
  insert into public.mesa_cliente_fluxo_operacoes (
    id,
    empresa_id,
    simulacao_id,
    empreendimento_id,
    politica_id,
    tipo_operacao,
    grupo_origem,
    grupo_destino,
    parcela_origem_id,
    valor_movido,
    data_origem,
    data_destino,
    taxa_ano_pct,
    vpl_aplicado_pct,
    desconto_calculado,
    acrescimo_calculado,
    economia_liquida,
    premio_corretor_pct,
    visivel_cliente,
    valor_base,
    dias_calculo
  ) values (
    v_operacao_a,
    v_empresa_a,
    v_simulacao_a,
    v_empreendimento_a,
    v_politica_a,
    'vpl',
    'periodicidade',
    'entrada',
    v_parcela_a,
    10000,
    date '2026-06-17',
    date '2026-05-17',
    12,
    3,
    300,
    0,
    300,
    2,
    true,
    10000,
    31
  );

  select visivel_cliente
    into v_bool
  from public.mesa_cliente_fluxo_operacoes
  where id = v_operacao_a;

  perform pg_temp.assert_true(v_bool is false, 'Operação com prêmio interno nunca deve ficar visível ao cliente');

  -- Integridade negativa: política com empreendimento de outra empresa deve falhar.
  perform pg_temp.expect_error(format($sql$
    insert into public.mesa_cliente_politicas_financeiras (
      empresa_id, empreendimento_id, mes_referencia, vigencia_inicio, vigencia_fim,
      vpl_max_pct, taxa_antecipacao_ano_pct, taxa_postergacao_ano_pct
    ) values (
      %L::uuid, %L::uuid, date '2026-06-01', date '2026-06-01', date '2026-06-30', 6, 12, 12
    )
  $sql$, v_empresa_a, v_empreendimento_b), 'política com empreendimento de outra empresa');

  -- Integridade negativa: faixa de prêmio com política de outra empresa deve falhar.
  perform pg_temp.expect_error(format($sql$
    insert into public.mesa_cliente_politica_premio_faixas (
      empresa_id, politica_id, vpl_de_pct, vpl_ate_pct, premio_corretor_pct, status, ordem
    ) values (
      %L::uuid, %L::uuid, 0, 3, 2, 'premio_cheio', 1
    )
  $sql$, v_empresa_b, v_politica_a), 'faixa de prêmio com política de outra empresa');

  -- Integridade negativa: parcela com simulação de outra empresa deve falhar.
  perform pg_temp.expect_error(format($sql$
    insert into public.mesa_cliente_fluxo_parcelas (
      empresa_id, simulacao_id, empreendimento_id, grupo, descricao,
      valor_original, valor_atual, data_original, data_atual, origem_data, ordem
    ) values (
      %L::uuid, %L::uuid, %L::uuid, 'mensal', 'Parcela inválida',
      10000, 10000, date '2026-06-17', date '2026-06-17', 'manual', 1
    )
  $sql$, v_empresa_a, v_simulacao_b, v_empreendimento_a), 'parcela com simulação de outra empresa');

  -- Integridade negativa: operação com parcela de outra simulação/empresa deve falhar.
  perform pg_temp.expect_error(format($sql$
    insert into public.mesa_cliente_fluxo_operacoes (
      empresa_id, simulacao_id, empreendimento_id, politica_id, tipo_operacao,
      grupo_origem, grupo_destino, parcela_origem_id, valor_movido,
      data_origem, data_destino, taxa_ano_pct, vpl_aplicado_pct,
      desconto_calculado, acrescimo_calculado, economia_liquida, valor_base, dias_calculo
    ) values (
      %L::uuid, %L::uuid, %L::uuid, %L::uuid, 'vpl',
      'mensal', 'entrada', %L::uuid, 10000,
      date '2026-06-17', date '2026-05-17', 12, 3,
      300, 0, 300, 10000, 31
    )
  $sql$, v_empresa_a, v_simulacao_a, v_empreendimento_a, v_politica_a, v_parcela_b), 'operação com parcela de outro tenant/simulação');

  -- ---------------------------------------------------------------------------
  -- RLS: leitura por tenant e escrita direta bloqueada como authenticated.
  -- ---------------------------------------------------------------------------

  perform set_config('request.jwt.claim.sub', v_user_a::text, true);

  begin
    execute 'set local role authenticated';

    execute format(
      'select count(*) from public.mesa_cliente_politicas_financeiras where id = %L::uuid',
      v_politica_a
    ) into v_count;

    perform pg_temp.assert_true(v_count = 1, 'Usuário A deve ler política da própria empresa');

    execute format(
      'select count(*) from public.mesa_cliente_politicas_financeiras where id = %L::uuid',
      v_politica_b
    ) into v_count;

    perform pg_temp.assert_true(v_count = 0, 'Usuário A não deve ler política de outra empresa');

    perform pg_temp.expect_error(format($sql$
      insert into public.mesa_cliente_politicas_financeiras (
        empresa_id, empreendimento_id, mes_referencia, vigencia_inicio, vigencia_fim,
        vpl_max_pct, taxa_antecipacao_ano_pct, taxa_postergacao_ano_pct
      ) values (
        %L::uuid, %L::uuid, date '2026-08-01', date '2026-08-01', date '2026-08-31', 6, 12, 12
      )
    $sql$, v_empresa_a, v_empreendimento_a), 'authenticated não pode inserir política diretamente');

    perform pg_temp.expect_error(format($sql$
      update public.mesa_cliente_politicas_financeiras
         set observacoes = 'update direto indevido'
       where id = %L::uuid
    $sql$, v_politica_a), 'authenticated não pode atualizar política diretamente');

    perform pg_temp.expect_error(format($sql$
      delete from public.mesa_cliente_politicas_financeiras
       where id = %L::uuid
    $sql$, v_politica_a), 'authenticated não pode apagar política diretamente');

    execute 'reset role';
  exception when others then
    execute 'reset role';
    raise;
  end;
end $$;

-- Resultado esperado:
--   Se tudo estiver correto, o script chega até aqui sem exception.
--   O ROLLBACK abaixo remove todos os dados transitórios de teste.

rollback;
