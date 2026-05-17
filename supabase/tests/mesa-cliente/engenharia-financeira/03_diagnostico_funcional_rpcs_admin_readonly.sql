-- MesaCliente Engenharia Financeira — 03 Diagnóstico funcional read-only das RPCs administrativas
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Validar funcionalmente, sem escrita, se as RPCs administrativas conseguem:
--   - reconhecer um usuário admin/gestor existente;
--   - retornar contexto autenticado;
--   - listar políticas financeiras do tenant;
--   - obter a primeira política encontrada, se existir.
--
-- Segurança em produção única:
--   - Não cria dados.
--   - Não atualiza dados.
--   - Não apaga dados.
--   - Não altera schema.
--   - Usa apenas SELECT, SET LOCAL ROLE e set_config local de sessão.
--   - Finaliza com ROLLBACK.
--
-- Observação:
--   O SQL Editor roda como postgres. Para simular o comportamento real da API,
--   este script escolhe um corretor ativo com perfil administrativo já existente,
--   injeta o auth.uid() na sessão via request.jwt.claim.sub e muda LOCALMENTE
--   o role para authenticated.
--
-- Resultado esperado:
--   - 01_admin_candidate: PASS
--   - 02_auth_context_rpc: PASS
--   - 03_admin_permission_helper: PASS
--   - 04_listar_politicas_rpc: PASS
--   - 05_obter_primeira_politica_rpc: PASS ou SKIP caso ainda não exista política

begin;

-- -----------------------------------------------------------------------------
-- 1. Escolher um usuário administrativo real, sem alterar dados
-- -----------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  coalesce((
    select c.user_id::text
    from public.corretores c
    where c.user_id is not null
      and coalesce(c.ativo, true) = true
      and (
        c.role in ('admin_global', 'admin_local', 'gestor')
        or coalesce(c.is_admin_local, false) = true
        or coalesce(c.is_gestor, false) = true
      )
    order by
      case c.role
        when 'admin_global' then 1
        when 'admin_local' then 2
        when 'gestor' then 3
        else 4
      end,
      c.created_at nulls last,
      c.id
    limit 1
  ), '00000000-0000-0000-0000-000000000000'),
  true
) as simulated_auth_uid;

-- A partir daqui, testar como authenticated.
set local role authenticated;

with ctx as materialized (
  select *
  from public.mesa_cliente_current_corretor_context()
), candidate_status as (
  select
    count(*) as qtd_ctx,
    max(user_id) as user_id,
    max(corretor_id) as corretor_id,
    max(empresa_id) as empresa_id,
    max(role) as role,
    bool_or(coalesce(is_admin_local, false)) as is_admin_local,
    bool_or(coalesce(is_gestor, false)) as is_gestor,
    bool_or(coalesce(ativo, false)) as ativo
  from ctx
), admin_permission as (
  select
    cs.*,
    case
      when cs.empresa_id is not null then public.mesa_cliente_can_admin_empresa(cs.empresa_id)
      else false
    end as can_admin_empresa,
    case
      when cs.empresa_id is not null then public.mesa_cliente_can_access_empresa(cs.empresa_id)
      else false
    end as can_access_empresa
  from candidate_status cs
), listar_politicas as materialized (
  select l.*
  from ctx
  cross join lateral public.mesa_cliente_listar_politicas_financeiras(
    ctx.empresa_id,
    null,
    false,
    10,
    0
  ) l
), listar_status as (
  select
    count(*) as qtd_politicas_retornadas,
    min(id) as primeira_politica_id,
    min(empresa_id) as primeira_empresa_id,
    jsonb_agg(
      jsonb_build_object(
        'id', id,
        'empresa_id', empresa_id,
        'empreendimento_id', empreendimento_id,
        'empreendimento_nome', empreendimento_nome,
        'mes_referencia', mes_referencia,
        'vigencia_inicio', vigencia_inicio,
        'vigencia_fim', vigencia_fim,
        'ativo', ativo,
        'qtd_faixas_premio', qtd_faixas_premio
      )
      order by mes_referencia desc, vigencia_inicio desc
    ) filter (where id is not null) as sample_politicas
  from listar_politicas
), primeira_politica as (
  select
    id,
    empresa_id
  from listar_politicas
  order by mes_referencia desc, vigencia_inicio desc, created_at desc
  limit 1
), obter_primeira as materialized (
  select public.mesa_cliente_obter_politica_financeira(pp.id, pp.empresa_id) as payload
  from primeira_politica pp
), obter_status as (
  select
    count(*) as qtd_payloads,
    max(payload) as payload
  from obter_primeira
)
select
  '01_admin_candidate' as bloco,
  case
    when ap.qtd_ctx = 1 and ap.ativo is true then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'mensagem', case
      when ap.qtd_ctx = 1 then 'Usuário administrativo encontrado e simulado na sessão.'
      else 'Nenhum usuário administrativo ativo foi encontrado em corretores.'
    end,
    'user_id', ap.user_id,
    'corretor_id', ap.corretor_id,
    'empresa_id', ap.empresa_id,
    'role', ap.role,
    'is_admin_local', ap.is_admin_local,
    'is_gestor', ap.is_gestor,
    'ativo', ap.ativo
  ) as detalhe
from admin_permission ap

union all

select
  '02_auth_context_rpc' as bloco,
  case
    when ap.qtd_ctx = 1 and ap.user_id is not null and ap.empresa_id is not null then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'mensagem', 'Valida execução de mesa_cliente_current_corretor_context() como authenticated.',
    'qtd_contextos', ap.qtd_ctx,
    'user_id', ap.user_id,
    'empresa_id', ap.empresa_id,
    'role', ap.role
  ) as detalhe
from admin_permission ap

union all

select
  '03_admin_permission_helper' as bloco,
  case
    when ap.can_admin_empresa is true and ap.can_access_empresa is true then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'mensagem', 'Valida helpers mesa_cliente_can_admin_empresa() e mesa_cliente_can_access_empresa().',
    'empresa_id', ap.empresa_id,
    'can_admin_empresa', ap.can_admin_empresa,
    'can_access_empresa', ap.can_access_empresa
  ) as detalhe
from admin_permission ap

union all

select
  '04_listar_politicas_rpc' as bloco,
  case
    when ap.qtd_ctx = 1 and ap.can_admin_empresa is true then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'mensagem', 'Valida chamada da RPC mesa_cliente_listar_politicas_financeiras(). Zero políticas não é erro; significa apenas que não há política cadastrada ainda.',
    'qtd_politicas_retornadas', coalesce(ls.qtd_politicas_retornadas, 0),
    'sample_politicas', coalesce(ls.sample_politicas, '[]'::jsonb)
  ) as detalhe
from admin_permission ap
cross join listar_status ls

union all

select
  '05_obter_primeira_politica_rpc' as bloco,
  case
    when coalesce(ls.qtd_politicas_retornadas, 0) = 0 then 'SKIP'
    when os.qtd_payloads = 1 and os.payload is not null then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'mensagem', case
      when coalesce(ls.qtd_politicas_retornadas, 0) = 0 then 'Nenhuma política existente para testar obter; isso é esperado se ainda não houver cadastro administrativo.'
      else 'Valida chamada da RPC mesa_cliente_obter_politica_financeira() com a primeira política retornada pela listagem.'
    end,
    'qtd_politicas_retornadas', coalesce(ls.qtd_politicas_retornadas, 0),
    'payload_obter_politica', os.payload
  ) as detalhe
from listar_status ls
cross join obter_status os;

rollback;
