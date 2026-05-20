-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 6
-- Migration: resumos read-only de operação financeira.
--
-- Contrato canônico:
--   docs/mesa-cliente/fase-6-contrato-resumos-operacao-financeira.md
--
-- Preflight técnico:
--   supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql
--   docs/mesa-cliente/fase-6-preflight-14-execucao.md
--
-- Objetivo:
--   1. Criar uma RPC administrativa para resumo financeiro interno.
--   2. Criar uma RPC cliente-safe separada fisicamente.
--   3. Manter leitura pura/read-only.
--   4. Não alterar motor financeiro.
--   5. Não recalcular operação.
--   6. Não alterar agenda.
--   7. Não alterar parcelas.
--   8. Não alterar operação.
--   9. Não confirmar operação.
--   10. Não cancelar operação.
--
-- Decisão arquitetural:
--   RPC admin e RPC cliente-safe são separadas.
--   A versão cliente-safe não usa parâmetro "visao" para alternar exposição.
--   Isso reduz o risco de vazamento por CASE mal fechado.
--
-- Segurança:
--   - SECURITY DEFINER.
--   - search_path fixado em public, pg_temp.
--   - auth.uid() obrigatório.
--   - corretor ativo obrigatório.
--   - tenant validado no banco.
--   - frontend não envia autoridade soberana.
--   - anon e public sem execute.
--   - authenticated com execute controlado por validações internas.
--
-- Campos internos que não devem aparecer no cliente-safe:
--   - empresa_id / tenant_id.
--   - politica_id.
--   - taxa_ano_pct.
--   - vpl_aplicado_pct.
--   - premio_corretor_pct.
--   - status_premio.
--   - checksum_operacao.
--   - metadata.
--   - confirmado_por / cancelado_por.
--   - payload bruto.


-- -----------------------------------------------------------------------------
-- RPC 1/2 — visão administrativa
-- -----------------------------------------------------------------------------
-- Esta RPC é destinada a perfis administrativos/gestão.
-- Ela pode expor dados internos necessários para auditoria financeira.
-- Ela continua sendo read-only e não executa DML financeiro.
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_resumir_operacao_financeira_admin(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  -- Identidade autenticada.
  v_auth_uid uuid := auth.uid();

  -- Entidade operacional vinculada ao usuário autenticado.
  v_corretor public.corretores%rowtype;

  -- Registro financeiro central da Fase 6.
  v_operacao public.mesa_cliente_fluxo_operacoes%rowtype;

  -- Simulação vinculada à operação.
  v_simulacao public.mesa_simulacoes%rowtype;

  -- Controle de parâmetros não permitidos.
  v_bad_key text;

  -- Controle de perfil administrativo.
  v_admin boolean := false;

  -- Payload opcional, nunca soberano.
  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);

  -- Chaves que o frontend não pode enviar como autoridade.
  v_forbidden text[] := array[
    'empresa_id',
    'tenant_id',
    'simulacao_id',
    'agenda_id',
    'corretor_id',
    'user_id',
    'auth_uid',
    'role',
    'perfil',
    'is_admin',
    'is_gestor',
    'is_admin_local',
    'criado_por',
    'confirmado_por',
    'cancelado_por',
    'politica_id',
    'empreendimento_id',
    'status_operacao',
    'tipo_operacao',
    'valor_movido',
    'valor_base',
    'taxa_ano_pct',
    'vpl_aplicado_pct',
    'desconto_calculado',
    'acrescimo_calculado',
    'economia_liquida',
    'premio_corretor_pct',
    'status_premio',
    'visivel_cliente',
    'checksum_operacao',
    'metadata',
    'cliente_safe',
    'visao'
  ];
begin
  -- ---------------------------------------------------------------------------
  -- Gate 01 — autenticação obrigatória
  -- ---------------------------------------------------------------------------
  if v_auth_uid is null then
    raise exception using
      errcode = '28000',
      message = 'auth_required';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 02 — operação obrigatória
  -- ---------------------------------------------------------------------------
  if p_operacao_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_operacao_id_required';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 03 — parâmetros opcionais devem ser objeto JSON
  -- ---------------------------------------------------------------------------
  if jsonb_typeof(v_params) <> 'object' then
    raise exception using
      errcode = '22023',
      message = 'p_parametros_must_be_object';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 04 — frontend não pode enviar autoridade soberana
  -- ---------------------------------------------------------------------------
  select k
    into v_bad_key
  from jsonb_object_keys(v_params) as t(k)
  where k = any(v_forbidden)
  limit 1;

  if v_bad_key is not null then
    raise exception using
      errcode = '42501',
      message = 'frontend_authority_forbidden:' || v_bad_key;
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 05 — localizar corretor ativo pelo auth.uid()
  -- ---------------------------------------------------------------------------
  select c.*
    into v_corretor
  from public.corretores c
  where c.user_id = v_auth_uid
    and coalesce(c.ativo, true) = true
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
  limit 1;

  if not found then
    raise exception using
      errcode = '28000',
      message = 'active_corretor_not_found';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 06 — perfil administrativo/gestão obrigatório
  -- ---------------------------------------------------------------------------
  v_admin :=
    coalesce(v_corretor.role, '') in (
      'admin_global',
      'admin_local',
      'gestor',
      'coordenador'
    )
    or coalesce(v_corretor.is_admin_local, false)
    or coalesce(v_corretor.is_gestor, false);

  if not v_admin then
    raise exception using
      errcode = '42501',
      message = 'admin_profile_required';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 07 — localizar operação financeira
  -- ---------------------------------------------------------------------------
  select o.*
    into v_operacao
  from public.mesa_cliente_fluxo_operacoes o
  where o.id = p_operacao_id
  limit 1;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'operacao_not_found';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 08 — proteção cross-tenant
  -- ---------------------------------------------------------------------------
  if coalesce(v_corretor.role, '') <> 'admin_global'
     and v_corretor.empresa_id is distinct from v_operacao.empresa_id then
    raise exception using
      errcode = '42501',
      message = 'cross_tenant_denied';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 09 — simulação vinculada e consistente com o tenant
  -- ---------------------------------------------------------------------------
  select s.*
    into v_simulacao
  from public.mesa_simulacoes s
  where s.id = v_operacao.simulacao_id
    and s.empresa_id = v_operacao.empresa_id
  limit 1;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'simulacao_not_found';
  end if;

  -- ---------------------------------------------------------------------------
  -- Retorno administrativo
  -- ---------------------------------------------------------------------------
  return jsonb_build_object(
    'ok',
    true,

    'fase',
    '6_RESUMOS_OPERACAO_FINANCEIRA',

    'visao',
    'administrativa',

    'cliente_safe',
    false,

    'readonly',
    true,

    'dml_financeiro',
    false,

    'altera_agenda',
    false,

    'altera_parcelas',
    false,

    'altera_operacao',
    false,

    'recalcula_operacao',
    false,

    'ids',
    jsonb_strip_nulls(
      jsonb_build_object(
        'operacao_id',
        v_operacao.id,

        'simulacao_id',
        v_operacao.simulacao_id,

        'agenda_id',
        v_operacao.agenda_id,

        'empresa_id',
        v_operacao.empresa_id,

        'empreendimento_id',
        v_operacao.empreendimento_id,

        'politica_id',
        v_operacao.politica_id
      )
    ),

    'operacao',
    jsonb_strip_nulls(
      jsonb_build_object(
        'tipo_operacao',
        v_operacao.tipo_operacao::text,

        'status_operacao',
        v_operacao.status_operacao,

        'confirmado',
        v_operacao.confirmado,

        'confirmado_por',
        v_operacao.confirmado_por,

        'confirmado_em',
        v_operacao.confirmado_em,

        'cancelado_por',
        v_operacao.cancelado_por,

        'cancelado_em',
        v_operacao.cancelado_em,

        'motivo_cancelamento',
        v_operacao.motivo_cancelamento,

        'visivel_cliente',
        v_operacao.visivel_cliente,

        'checksum_operacao',
        v_operacao.checksum_operacao,

        'grupo_origem',
        v_operacao.grupo_origem,

        'grupo_destino',
        v_operacao.grupo_destino,

        'parcela_origem_id',
        v_operacao.parcela_origem_id,

        'parcela_destino_id',
        v_operacao.parcela_destino_id,

        'created_at',
        v_operacao.created_at,

        'updated_at',
        v_operacao.updated_at
      )
    ),

    'resumo_financeiro_admin',
    jsonb_build_object(
      'valor_movido',
      v_operacao.valor_movido,

      'valor_base',
      v_operacao.valor_base,

      'data_origem',
      v_operacao.data_origem,

      'data_destino',
      v_operacao.data_destino,

      'taxa_ano_pct',
      v_operacao.taxa_ano_pct,

      'vpl_aplicado_pct',
      v_operacao.vpl_aplicado_pct,

      'desconto_calculado',
      v_operacao.desconto_calculado,

      'acrescimo_calculado',
      v_operacao.acrescimo_calculado,

      'economia_liquida',
      v_operacao.economia_liquida,

      'dias_calculo',
      v_operacao.dias_calculo,

      'premio_corretor_pct',
      v_operacao.premio_corretor_pct,

      'status_premio',
      v_operacao.status_premio
    ),

    'simulacao',
    jsonb_strip_nulls(
      jsonb_build_object(
        'cliente_nome',
        v_simulacao.cliente_nome,

        'status',
        v_simulacao.status::text,

        'corretor_id',
        v_simulacao.corretor_id,

        'valor_total',
        v_simulacao.valor_total,

        'entrada',
        v_simulacao.entrada,

        'financiamento',
        v_simulacao.financiamento,

        'valor_final',
        v_simulacao.valor_final,

        'oficial',
        v_simulacao.oficial
      )
    ),

    'flags_integridade',
    jsonb_build_object(
      'tenant_consistente',
      v_simulacao.empresa_id = v_operacao.empresa_id,

      'visivel_cliente',
      coalesce(v_operacao.visivel_cliente, false),

      'tem_metadata',
      coalesce(v_operacao.metadata, '{}'::jsonb) <> '{}'::jsonb
    )
  );
end;
$$;


-- -----------------------------------------------------------------------------
-- RPC 2/2 — visão cliente-safe
-- -----------------------------------------------------------------------------
-- Esta RPC é destinada à exposição comercial controlada.
-- Ela não expõe regra financeira interna.
-- Ela exige visivel_cliente=true.
-- Ela valida tenant e escopo.
-- Ela não executa DML financeiro.
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_obter_resumo_operacao_cliente_safe(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  -- Identidade autenticada.
  v_auth_uid uuid := auth.uid();

  -- Entidade operacional vinculada ao usuário autenticado.
  v_corretor public.corretores%rowtype;

  -- Operação financeira original.
  v_operacao public.mesa_cliente_fluxo_operacoes%rowtype;

  -- Simulação vinculada.
  v_simulacao public.mesa_simulacoes%rowtype;

  -- Parcela de origem, quando houver.
  v_origem public.mesa_cliente_fluxo_parcelas%rowtype;

  -- Parcela de destino, quando houver.
  v_destino public.mesa_cliente_fluxo_parcelas%rowtype;

  -- Parâmetro proibido detectado.
  v_bad_key text;

  -- Perfil administrativo/gestão.
  v_admin boolean := false;

  -- Status traduzido para linguagem comercial.
  v_status_comercial text;

  -- Payload opcional, nunca soberano.
  v_params jsonb := coalesce(p_parametros, '{}'::jsonb);

  -- Lista de chaves soberanas proibidas.
  v_forbidden text[] := array[
    'empresa_id',
    'tenant_id',
    'simulacao_id',
    'agenda_id',
    'corretor_id',
    'user_id',
    'auth_uid',
    'role',
    'perfil',
    'is_admin',
    'is_gestor',
    'is_admin_local',
    'criado_por',
    'confirmado_por',
    'cancelado_por',
    'politica_id',
    'empreendimento_id',
    'status_operacao',
    'tipo_operacao',
    'valor_movido',
    'valor_base',
    'taxa_ano_pct',
    'vpl_aplicado_pct',
    'desconto_calculado',
    'acrescimo_calculado',
    'economia_liquida',
    'premio_corretor_pct',
    'status_premio',
    'visivel_cliente',
    'checksum_operacao',
    'metadata',
    'cliente_safe',
    'visao'
  ];
begin
  -- ---------------------------------------------------------------------------
  -- Gate 01 — autenticação obrigatória
  -- ---------------------------------------------------------------------------
  if v_auth_uid is null then
    raise exception using
      errcode = '28000',
      message = 'auth_required';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 02 — operação obrigatória
  -- ---------------------------------------------------------------------------
  if p_operacao_id is null then
    raise exception using
      errcode = '22023',
      message = 'p_operacao_id_required';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 03 — parâmetros opcionais devem ser objeto JSON
  -- ---------------------------------------------------------------------------
  if jsonb_typeof(v_params) <> 'object' then
    raise exception using
      errcode = '22023',
      message = 'p_parametros_must_be_object';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 04 — frontend não pode enviar autoridade soberana
  -- ---------------------------------------------------------------------------
  select k
    into v_bad_key
  from jsonb_object_keys(v_params) as t(k)
  where k = any(v_forbidden)
  limit 1;

  if v_bad_key is not null then
    raise exception using
      errcode = '42501',
      message = 'frontend_authority_forbidden:' || v_bad_key;
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 05 — localizar corretor ativo pelo auth.uid()
  -- ---------------------------------------------------------------------------
  select c.*
    into v_corretor
  from public.corretores c
  where c.user_id = v_auth_uid
    and coalesce(c.ativo, true) = true
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
  limit 1;

  if not found then
    raise exception using
      errcode = '28000',
      message = 'active_corretor_not_found';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 06 — identificar perfil administrativo ou escopo de corretor
  -- ---------------------------------------------------------------------------
  v_admin :=
    coalesce(v_corretor.role, '') in (
      'admin_global',
      'admin_local',
      'gestor',
      'coordenador'
    )
    or coalesce(v_corretor.is_admin_local, false)
    or coalesce(v_corretor.is_gestor, false);

  -- ---------------------------------------------------------------------------
  -- Gate 07 — localizar operação financeira
  -- ---------------------------------------------------------------------------
  select o.*
    into v_operacao
  from public.mesa_cliente_fluxo_operacoes o
  where o.id = p_operacao_id
  limit 1;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'operacao_not_found';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 08 — proteção cross-tenant
  -- ---------------------------------------------------------------------------
  if coalesce(v_corretor.role, '') <> 'admin_global'
     and v_corretor.empresa_id is distinct from v_operacao.empresa_id then
    raise exception using
      errcode = '42501',
      message = 'cross_tenant_denied';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 09 — localizar simulação vinculada
  -- ---------------------------------------------------------------------------
  select s.*
    into v_simulacao
  from public.mesa_simulacoes s
  where s.id = v_operacao.simulacao_id
    and s.empresa_id = v_operacao.empresa_id
  limit 1;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'simulacao_not_found';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 10 — corretor comum só acessa operação vinculada à sua simulação
  -- ---------------------------------------------------------------------------
  if not v_admin
     and v_simulacao.corretor_id is distinct from v_corretor.id then
    raise exception using
      errcode = '42501',
      message = 'corretor_scope_denied';
  end if;

  -- ---------------------------------------------------------------------------
  -- Gate 11 — cliente-safe só libera operação marcada como visível
  -- ---------------------------------------------------------------------------
  if coalesce(v_operacao.visivel_cliente, false) is false then
    raise exception using
      errcode = '42501',
      message = 'cliente_safe_not_released';
  end if;

  -- ---------------------------------------------------------------------------
  -- Leitura auxiliar: parcela origem
  -- ---------------------------------------------------------------------------
  if v_operacao.parcela_origem_id is not null then
    select p.*
      into v_origem
    from public.mesa_cliente_fluxo_parcelas p
    where p.id = v_operacao.parcela_origem_id
      and p.simulacao_id = v_operacao.simulacao_id
      and p.empresa_id = v_operacao.empresa_id
    limit 1;
  end if;

  -- ---------------------------------------------------------------------------
  -- Leitura auxiliar: parcela destino
  -- ---------------------------------------------------------------------------
  if v_operacao.parcela_destino_id is not null then
    select p.*
      into v_destino
    from public.mesa_cliente_fluxo_parcelas p
    where p.id = v_operacao.parcela_destino_id
      and p.simulacao_id = v_operacao.simulacao_id
      and p.empresa_id = v_operacao.empresa_id
    limit 1;
  end if;

  -- ---------------------------------------------------------------------------
  -- Tradução de status interno para status comercial
  -- ---------------------------------------------------------------------------
  v_status_comercial := case
    when v_operacao.status_operacao = 'confirmada'
         and coalesce(v_operacao.confirmado, false)
      then 'condicao_confirmada'

    when v_operacao.status_operacao = 'cancelada'
      then 'condicao_cancelada'

    else 'condicao_em_analise'
  end;

  -- ---------------------------------------------------------------------------
  -- Retorno cliente-safe
  -- ---------------------------------------------------------------------------
  return jsonb_build_object(
    'ok',
    true,

    'fase',
    '6_RESUMOS_OPERACAO_FINANCEIRA',

    'visao',
    'cliente_safe',

    'cliente_safe',
    true,

    'readonly',
    true,

    'dml_financeiro',
    false,

    'altera_agenda',
    false,

    'altera_parcelas',
    false,

    'altera_operacao',
    false,

    'recalcula_operacao',
    false,

    'status_comercial',
    v_status_comercial,

    'resumo_condicao',
    jsonb_strip_nulls(
      jsonb_build_object(
        'tipo_operacao',
        v_operacao.tipo_operacao::text,

        'status',
        v_status_comercial,

        'valor_negociado',
        v_operacao.valor_movido,

        'valor_referencia',
        v_operacao.valor_base,

        'data_original',
        v_operacao.data_origem,

        'nova_data',
        v_operacao.data_destino,

        'desconto_comercial',
        nullif(v_operacao.desconto_calculado, 0),

        'acrescimo_comercial',
        nullif(v_operacao.acrescimo_calculado, 0)
      )
    ),

    'cliente',
    jsonb_strip_nulls(
      jsonb_build_object(
        'nome',
        v_simulacao.cliente_nome
      )
    ),

    'parcelas_impactadas',
    jsonb_build_object(
      'origem',
      case
        when v_operacao.parcela_origem_id is null then null
        else jsonb_strip_nulls(
          jsonb_build_object(
            'grupo',
            v_origem.grupo,

            'descricao',
            v_origem.descricao,

            'ordem',
            v_origem.ordem,

            'valor_original',
            v_origem.valor_original,

            'valor_atual',
            v_origem.valor_atual,

            'data_original',
            v_origem.data_original,

            'data_atual',
            v_origem.data_atual
          )
        )
      end,

      'destino',
      case
        when v_operacao.parcela_destino_id is null then null
        else jsonb_strip_nulls(
          jsonb_build_object(
            'grupo',
            v_destino.grupo,

            'descricao',
            v_destino.descricao,

            'ordem',
            v_destino.ordem,

            'valor_original',
            v_destino.valor_original,

            'valor_atual',
            v_destino.valor_atual,

            'data_original',
            v_destino.data_original,

            'data_atual',
            v_destino.data_atual
          )
        )
      end
    ),

    'avisos',
    jsonb_build_array(
      'cliente_safe_sem_taxa_vpl_premio_politica_checksum_metadata_payload_bruto',
      'condicao_sujeita_a_validacao_comercial_conforme_status'
    )
  );
end;
$$;


-- -----------------------------------------------------------------------------
-- Permissões — RPC administrativa
-- -----------------------------------------------------------------------------

revoke all on function public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
from public;

revoke all on function public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
from anon;

grant execute on function public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
to authenticated;

comment on function public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
is 'FECH.AI MesaCliente Fase 6: resumo administrativo read-only de operacao financeira, tenant-safe, sem DML financeiro.';


-- -----------------------------------------------------------------------------
-- Permissões — RPC cliente-safe
-- -----------------------------------------------------------------------------

revoke all on function public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
from public;

revoke all on function public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
from anon;

grant execute on function public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
to authenticated;

comment on function public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
is 'FECH.AI MesaCliente Fase 6: resumo cliente-safe read-only, separado da visao admin, sem VPL/taxa/premio/politica/checksum/metadata.';
