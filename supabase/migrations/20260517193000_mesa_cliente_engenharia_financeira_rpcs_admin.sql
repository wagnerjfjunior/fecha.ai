-- MesaCliente Engenharia Financeira — RPCs administrativas soberanas
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Criar RPCs administrativas para consulta/cadastro de políticas financeiras
--   e faixas de prêmio, sem expor regras internas ao cliente e sem permitir
--   escrita direta pelo front.
--
-- Escopo:
--   - Helpers de autorização multitenant.
--   - mesa_cliente_listar_politicas_financeiras
--   - mesa_cliente_obter_politica_financeira
--   - mesa_cliente_upsert_politica_financeira
--   - mesa_cliente_upsert_faixas_premio
--
-- Fora do escopo desta migration:
--   - Cálculo de VPL.
--   - Antecipação/postergacão composta.
--   - Parser, motor financeiro atual, Worker, Make, front.

begin;

-- -----------------------------------------------------------------------------
-- 1. Helpers soberanos de autorização
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_current_corretor_context()
returns table (
  user_id uuid,
  corretor_id uuid,
  empresa_id uuid,
  role text,
  is_admin_local boolean,
  is_gestor boolean,
  ativo boolean
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.user_id,
    c.id as corretor_id,
    c.empresa_id,
    c.role,
    coalesce(c.is_admin_local, false) as is_admin_local,
    coalesce(c.is_gestor, false) as is_gestor,
    coalesce(c.ativo, true) as ativo
  from public.corretores c
  where c.user_id = auth.uid()
  limit 1
$$;

comment on function public.mesa_cliente_current_corretor_context() is
'MesaCliente Engenharia Financeira: retorna contexto autenticado do corretor atual para validação multitenant.';

create or replace function public.mesa_cliente_assert_auth()
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid;
begin
  v_uid := auth.uid();

  if v_uid is null then
    raise exception 'Usuário não autenticado'
      using errcode = '28000';
  end if;

  return v_uid;
end;
$$;

comment on function public.mesa_cliente_assert_auth() is
'MesaCliente Engenharia Financeira: exige auth.uid() válido para RPCs soberanas.';

create or replace function public.mesa_cliente_can_access_empresa(
  p_empresa_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_ok boolean;
begin
  v_uid := public.mesa_cliente_assert_auth();

  if p_empresa_id is null then
    return false;
  end if;

  if public.is_root() then
    return true;
  end if;

  select exists (
    select 1
    from public.corretores c
    where c.user_id = v_uid
      and c.empresa_id = p_empresa_id
      and coalesce(c.ativo, true) = true
  ) into v_ok;

  return coalesce(v_ok, false);
end;
$$;

comment on function public.mesa_cliente_can_access_empresa(uuid) is
'MesaCliente Engenharia Financeira: valida acesso de leitura por empresa/tenant.';

create or replace function public.mesa_cliente_can_admin_empresa(
  p_empresa_id uuid
)
returns boolean
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_ok boolean;
begin
  v_uid := public.mesa_cliente_assert_auth();

  if p_empresa_id is null then
    return false;
  end if;

  if public.is_root() then
    return true;
  end if;

  select exists (
    select 1
    from public.corretores c
    where c.user_id = v_uid
      and c.empresa_id = p_empresa_id
      and coalesce(c.ativo, true) = true
      and (
        c.role in ('admin_global', 'admin_local', 'gestor')
        or coalesce(c.is_admin_local, false) = true
        or coalesce(c.is_gestor, false) = true
      )
  ) into v_ok;

  return coalesce(v_ok, false);
end;
$$;

comment on function public.mesa_cliente_can_admin_empresa(uuid) is
'MesaCliente Engenharia Financeira: valida permissão administrativa por empresa/tenant para políticas financeiras.';

create or replace function public.mesa_cliente_assert_empreendimento_empresa(
  p_empresa_id uuid,
  p_empreendimento_id uuid
)
returns void
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_exists boolean;
begin
  if p_empresa_id is null or p_empreendimento_id is null then
    raise exception 'empresa_id e empreendimento_id são obrigatórios'
      using errcode = '22023';
  end if;

  select exists (
    select 1
    from public.empreendimentos e
    where e.id = p_empreendimento_id
      and e.empresa_id = p_empresa_id
  ) into v_exists;

  if not coalesce(v_exists, false) then
    raise exception 'Empreendimento não pertence à empresa informada'
      using errcode = '42501';
  end if;
end;
$$;

comment on function public.mesa_cliente_assert_empreendimento_empresa(uuid, uuid) is
'MesaCliente Engenharia Financeira: garante vínculo empreendimento/empresa antes de RPC administrativa.';

-- -----------------------------------------------------------------------------
-- 2. RPC: listar políticas financeiras
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_listar_politicas_financeiras(
  p_empresa_id uuid,
  p_empreendimento_id uuid default null,
  p_ativas_only boolean default true,
  p_limit integer default 100,
  p_offset integer default 0
)
returns table (
  id uuid,
  empresa_id uuid,
  empreendimento_id uuid,
  empreendimento_nome text,
  mes_referencia date,
  vigencia_inicio date,
  vigencia_fim date,
  vpl_max_pct numeric,
  taxa_antecipacao_ano_pct numeric,
  taxa_postergacao_ano_pct numeric,
  metodo_calculo text,
  base_tempo text,
  ativo boolean,
  observacoes text,
  created_at timestamptz,
  updated_at timestamptz,
  qtd_faixas_premio bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  perform public.mesa_cliente_assert_auth();

  if not public.mesa_cliente_can_admin_empresa(p_empresa_id) then
    raise exception 'Sem permissão para listar políticas financeiras desta empresa'
      using errcode = '42501';
  end if;

  if p_empreendimento_id is not null then
    perform public.mesa_cliente_assert_empreendimento_empresa(p_empresa_id, p_empreendimento_id);
  end if;

  return query
  select
    p.id,
    p.empresa_id,
    p.empreendimento_id,
    e.nome as empreendimento_nome,
    p.mes_referencia,
    p.vigencia_inicio,
    p.vigencia_fim,
    p.vpl_max_pct,
    p.taxa_antecipacao_ano_pct,
    p.taxa_postergacao_ano_pct,
    p.metodo_calculo::text,
    p.base_tempo::text,
    p.ativo,
    p.observacoes,
    p.created_at,
    p.updated_at,
    count(f.id) filter (where f.ativo is true) as qtd_faixas_premio
  from public.mesa_cliente_politicas_financeiras p
  join public.empreendimentos e on e.id = p.empreendimento_id
  left join public.mesa_cliente_politica_premio_faixas f on f.politica_id = p.id
  where p.empresa_id = p_empresa_id
    and (p_empreendimento_id is null or p.empreendimento_id = p_empreendimento_id)
    and (p_ativas_only is false or p.ativo is true)
  group by p.id, e.nome
  order by p.mes_referencia desc, p.vigencia_inicio desc, p.created_at desc
  limit greatest(1, least(coalesce(p_limit, 100), 500))
  offset greatest(0, coalesce(p_offset, 0));
end;
$$;

comment on function public.mesa_cliente_listar_politicas_financeiras(uuid, uuid, boolean, integer, integer) is
'MesaCliente Engenharia Financeira: lista políticas financeiras internas para admin/gestor do tenant. Não destinada ao cliente.';

-- -----------------------------------------------------------------------------
-- 3. RPC: obter política financeira completa
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_obter_politica_financeira(
  p_politica_id uuid,
  p_empresa_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_politica record;
  v_empresa_id uuid;
  v_result jsonb;
begin
  perform public.mesa_cliente_assert_auth();

  if p_politica_id is null then
    raise exception 'politica_id é obrigatório'
      using errcode = '22023';
  end if;

  select p.*
    into v_politica
  from public.mesa_cliente_politicas_financeiras p
  where p.id = p_politica_id;

  if v_politica.id is null then
    raise exception 'Política financeira não encontrada'
      using errcode = 'P0002';
  end if;

  v_empresa_id := coalesce(p_empresa_id, v_politica.empresa_id);

  if v_empresa_id <> v_politica.empresa_id then
    raise exception 'empresa_id diverge da política financeira'
      using errcode = '42501';
  end if;

  if not public.mesa_cliente_can_admin_empresa(v_empresa_id) then
    raise exception 'Sem permissão para obter política financeira desta empresa'
      using errcode = '42501';
  end if;

  select jsonb_build_object(
    'politica', jsonb_build_object(
      'id', p.id,
      'empresa_id', p.empresa_id,
      'empreendimento_id', p.empreendimento_id,
      'empreendimento_nome', e.nome,
      'mes_referencia', p.mes_referencia,
      'vigencia_inicio', p.vigencia_inicio,
      'vigencia_fim', p.vigencia_fim,
      'vpl_max_pct', p.vpl_max_pct,
      'taxa_antecipacao_ano_pct', p.taxa_antecipacao_ano_pct,
      'taxa_postergacao_ano_pct', p.taxa_postergacao_ano_pct,
      'metodo_calculo', p.metodo_calculo::text,
      'base_tempo', p.base_tempo::text,
      'permite_vpl_financiamento', p.permite_vpl_financiamento,
      'permite_vpl_chaves', p.permite_vpl_chaves,
      'permite_vpl_anuais', p.permite_vpl_anuais,
      'permite_vpl_mensais', p.permite_vpl_mensais,
      'permite_antecipacao_financiamento', p.permite_antecipacao_financiamento,
      'permite_antecipacao_chaves', p.permite_antecipacao_chaves,
      'permite_antecipacao_anuais', p.permite_antecipacao_anuais,
      'permite_antecipacao_mensais', p.permite_antecipacao_mensais,
      'permite_postergacao_financiamento', p.permite_postergacao_financiamento,
      'permite_postergacao_chaves', p.permite_postergacao_chaves,
      'permite_postergacao_anuais', p.permite_postergacao_anuais,
      'permite_postergacao_mensais', p.permite_postergacao_mensais,
      'ativo', p.ativo,
      'observacoes', p.observacoes,
      'created_at', p.created_at,
      'updated_at', p.updated_at
    ),
    'faixas_premio', coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', f.id,
          'empresa_id', f.empresa_id,
          'politica_id', f.politica_id,
          'vpl_de_pct', f.vpl_de_pct,
          'vpl_ate_pct', f.vpl_ate_pct,
          'premio_corretor_pct', f.premio_corretor_pct,
          'status', f.status,
          'descricao', f.descricao,
          'ordem', f.ordem,
          'ativo', f.ativo,
          'created_at', f.created_at,
          'updated_at', f.updated_at
        ) order by f.ordem, f.vpl_de_pct, f.vpl_ate_pct
      ) filter (where f.id is not null),
      '[]'::jsonb
    )
  ) into v_result
  from public.mesa_cliente_politicas_financeiras p
  join public.empreendimentos e on e.id = p.empreendimento_id
  left join public.mesa_cliente_politica_premio_faixas f on f.politica_id = p.id
  where p.id = p_politica_id
  group by p.id, e.nome;

  return v_result;
end;
$$;

comment on function public.mesa_cliente_obter_politica_financeira(uuid, uuid) is
'MesaCliente Engenharia Financeira: obtém política completa com faixas internas para admin/gestor. Cliente não deve consumir esta RPC.';

-- -----------------------------------------------------------------------------
-- 4. RPC: upsert política financeira
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_upsert_politica_financeira(
  p_empresa_id uuid,
  p_empreendimento_id uuid,
  p_mes_referencia date,
  p_vigencia_inicio date,
  p_vigencia_fim date,
  p_vpl_max_pct numeric,
  p_taxa_antecipacao_ano_pct numeric,
  p_taxa_postergacao_ano_pct numeric,
  p_metodo_calculo text default 'composto',
  p_base_tempo text default 'dias_365',
  p_permite_vpl_financiamento boolean default false,
  p_permite_vpl_chaves boolean default true,
  p_permite_vpl_anuais boolean default true,
  p_permite_vpl_mensais boolean default true,
  p_permite_antecipacao_financiamento boolean default false,
  p_permite_antecipacao_chaves boolean default true,
  p_permite_antecipacao_anuais boolean default true,
  p_permite_antecipacao_mensais boolean default true,
  p_permite_postergacao_financiamento boolean default false,
  p_permite_postergacao_chaves boolean default true,
  p_permite_postergacao_anuais boolean default true,
  p_permite_postergacao_mensais boolean default true,
  p_ativo boolean default true,
  p_observacoes text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_mes_referencia date;
  v_id uuid;
begin
  v_uid := public.mesa_cliente_assert_auth();

  if not public.mesa_cliente_can_admin_empresa(p_empresa_id) then
    raise exception 'Sem permissão para salvar política financeira desta empresa'
      using errcode = '42501';
  end if;

  perform public.mesa_cliente_assert_empreendimento_empresa(p_empresa_id, p_empreendimento_id);

  if p_mes_referencia is null then
    raise exception 'mes_referencia é obrigatório'
      using errcode = '22023';
  end if;

  v_mes_referencia := date_trunc('month', p_mes_referencia)::date;

  if p_vigencia_inicio is null or p_vigencia_fim is null or p_vigencia_fim < p_vigencia_inicio then
    raise exception 'Vigência inválida'
      using errcode = '22023';
  end if;

  if coalesce(p_vpl_max_pct, -1) < 0 or coalesce(p_vpl_max_pct, 101) > 100 then
    raise exception 'vpl_max_pct deve estar entre 0 e 100'
      using errcode = '22023';
  end if;

  if coalesce(p_taxa_antecipacao_ano_pct, -1) < 0 or coalesce(p_taxa_antecipacao_ano_pct, 101) > 100 then
    raise exception 'taxa_antecipacao_ano_pct deve estar entre 0 e 100'
      using errcode = '22023';
  end if;

  if coalesce(p_taxa_postergacao_ano_pct, -1) < 0 or coalesce(p_taxa_postergacao_ano_pct, 101) > 100 then
    raise exception 'taxa_postergacao_ano_pct deve estar entre 0 e 100'
      using errcode = '22023';
  end if;

  if coalesce(p_metodo_calculo, 'composto') <> 'composto' then
    raise exception 'Somente método composto está liberado nesta fase'
      using errcode = '22023';
  end if;

  if coalesce(p_base_tempo, 'dias_365') <> 'dias_365' then
    raise exception 'Somente base_tempo dias_365 está liberada nesta fase'
      using errcode = '22023';
  end if;

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
    observacoes,
    criado_por,
    atualizado_por
  ) values (
    p_empresa_id,
    p_empreendimento_id,
    v_mes_referencia,
    p_vigencia_inicio,
    p_vigencia_fim,
    p_vpl_max_pct,
    p_taxa_antecipacao_ano_pct,
    p_taxa_postergacao_ano_pct,
    p_metodo_calculo::public.mesa_financeira_metodo_calculo,
    p_base_tempo::public.mesa_financeira_base_tempo,
    coalesce(p_permite_vpl_financiamento, false),
    coalesce(p_permite_vpl_chaves, true),
    coalesce(p_permite_vpl_anuais, true),
    coalesce(p_permite_vpl_mensais, true),
    coalesce(p_permite_antecipacao_financiamento, false),
    coalesce(p_permite_antecipacao_chaves, true),
    coalesce(p_permite_antecipacao_anuais, true),
    coalesce(p_permite_antecipacao_mensais, true),
    coalesce(p_permite_postergacao_financiamento, false),
    coalesce(p_permite_postergacao_chaves, true),
    coalesce(p_permite_postergacao_anuais, true),
    coalesce(p_permite_postergacao_mensais, true),
    coalesce(p_ativo, true),
    p_observacoes,
    v_uid,
    v_uid
  )
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
    atualizado_por = v_uid,
    updated_at = now()
  returning id into v_id;

  return public.mesa_cliente_obter_politica_financeira(v_id, p_empresa_id);
end;
$$;

comment on function public.mesa_cliente_upsert_politica_financeira(uuid, uuid, date, date, date, numeric, numeric, numeric, text, text, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, text) is
'MesaCliente Engenharia Financeira: cria/atualiza política financeira por empresa, empreendimento e mês. Escrita exclusiva via RPC soberana.';

-- -----------------------------------------------------------------------------
-- 5. RPC: substituir faixas de prêmio de uma política
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_upsert_faixas_premio(
  p_empresa_id uuid,
  p_politica_id uuid,
  p_faixas jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public
as $$
declare
  v_uid uuid;
  v_politica record;
  v_item jsonb;
  v_ordem integer := 0;
  v_de numeric;
  v_ate numeric;
  v_premio numeric;
  v_status text;
  v_descricao text;
begin
  v_uid := public.mesa_cliente_assert_auth();

  if p_empresa_id is null or p_politica_id is null then
    raise exception 'empresa_id e politica_id são obrigatórios'
      using errcode = '22023';
  end if;

  if not public.mesa_cliente_can_admin_empresa(p_empresa_id) then
    raise exception 'Sem permissão para salvar faixas de prêmio desta empresa'
      using errcode = '42501';
  end if;

  select *
    into v_politica
  from public.mesa_cliente_politicas_financeiras p
  where p.id = p_politica_id
    and p.empresa_id = p_empresa_id;

  if v_politica.id is null then
    raise exception 'Política financeira não encontrada para esta empresa'
      using errcode = 'P0002';
  end if;

  if p_faixas is null or jsonb_typeof(p_faixas) <> 'array' then
    raise exception 'faixas deve ser um array JSON'
      using errcode = '22023';
  end if;

  if jsonb_array_length(p_faixas) > 20 then
    raise exception 'Limite máximo de 20 faixas de prêmio por política'
      using errcode = '22023';
  end if;

  delete from public.mesa_cliente_politica_premio_faixas
  where empresa_id = p_empresa_id
    and politica_id = p_politica_id;

  for v_item in select value from jsonb_array_elements(p_faixas)
  loop
    v_ordem := v_ordem + 1;
    v_de := nullif(v_item->>'vpl_de_pct', '')::numeric;
    v_ate := nullif(v_item->>'vpl_ate_pct', '')::numeric;
    v_premio := nullif(v_item->>'premio_corretor_pct', '')::numeric;
    v_status := coalesce(nullif(v_item->>'status', ''), 'ativo');
    v_descricao := nullif(v_item->>'descricao', '');

    if v_de is null or v_ate is null or v_premio is null then
      raise exception 'Faixa % inválida: vpl_de_pct, vpl_ate_pct e premio_corretor_pct são obrigatórios', v_ordem
        using errcode = '22023';
    end if;

    if v_de < 0 or v_ate < v_de or v_ate > 100 or v_premio < 0 or v_premio > 100 then
      raise exception 'Faixa % inválida: percentuais fora do intervalo permitido', v_ordem
        using errcode = '22023';
    end if;

    if v_ate > v_politica.vpl_max_pct then
      raise exception 'Faixa % excede vpl_max_pct da política', v_ordem
        using errcode = '22023';
    end if;

    if v_status not in ('premio_cheio', 'premio_parcial', 'sem_premio', 'ativo', 'inativo') then
      raise exception 'Faixa % possui status inválido', v_ordem
        using errcode = '22023';
    end if;

    insert into public.mesa_cliente_politica_premio_faixas (
      empresa_id,
      politica_id,
      vpl_de_pct,
      vpl_ate_pct,
      premio_corretor_pct,
      status,
      descricao,
      ordem,
      ativo,
      criado_por,
      atualizado_por
    ) values (
      p_empresa_id,
      p_politica_id,
      v_de,
      v_ate,
      v_premio,
      v_status,
      v_descricao,
      coalesce(nullif(v_item->>'ordem', '')::integer, v_ordem),
      coalesce(nullif(v_item->>'ativo', '')::boolean, true),
      v_uid,
      v_uid
    );
  end loop;

  return public.mesa_cliente_obter_politica_financeira(p_politica_id, p_empresa_id);
end;
$$;

comment on function public.mesa_cliente_upsert_faixas_premio(uuid, uuid, jsonb) is
'MesaCliente Engenharia Financeira: substitui faixas internas de prêmio de uma política. Cliente não deve consumir esta RPC.';

-- -----------------------------------------------------------------------------
-- 6. Grants das RPCs
-- -----------------------------------------------------------------------------

revoke all on function public.mesa_cliente_current_corretor_context() from public;
revoke all on function public.mesa_cliente_assert_auth() from public;
revoke all on function public.mesa_cliente_can_access_empresa(uuid) from public;
revoke all on function public.mesa_cliente_can_admin_empresa(uuid) from public;
revoke all on function public.mesa_cliente_assert_empreendimento_empresa(uuid, uuid) from public;
revoke all on function public.mesa_cliente_listar_politicas_financeiras(uuid, uuid, boolean, integer, integer) from public;
revoke all on function public.mesa_cliente_obter_politica_financeira(uuid, uuid) from public;
revoke all on function public.mesa_cliente_upsert_politica_financeira(uuid, uuid, date, date, date, numeric, numeric, numeric, text, text, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, text) from public;
revoke all on function public.mesa_cliente_upsert_faixas_premio(uuid, uuid, jsonb) from public;

grant execute on function public.mesa_cliente_listar_politicas_financeiras(uuid, uuid, boolean, integer, integer) to authenticated;
grant execute on function public.mesa_cliente_obter_politica_financeira(uuid, uuid) to authenticated;
grant execute on function public.mesa_cliente_upsert_politica_financeira(uuid, uuid, date, date, date, numeric, numeric, numeric, text, text, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, boolean, text) to authenticated;
grant execute on function public.mesa_cliente_upsert_faixas_premio(uuid, uuid, jsonb) to authenticated;

grant execute on function public.mesa_cliente_current_corretor_context() to authenticated;
grant execute on function public.mesa_cliente_can_access_empresa(uuid) to authenticated;
grant execute on function public.mesa_cliente_can_admin_empresa(uuid) to authenticated;

commit;
