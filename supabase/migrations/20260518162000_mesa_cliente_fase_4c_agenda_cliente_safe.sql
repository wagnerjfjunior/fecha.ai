-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4C
-- RPC cliente-safe para leitura da agenda financeira persistida.
--
-- Protocolo Mestre FECH.AI / MesaCliente:
--   Primeiro contrato. Depois validação. Depois dry-run. Depois persistência.
--
-- Escopo desta migration:
--   - Criar somente RPC read-only cliente-safe.
--   - Ler agenda ativa persistida pela Fase 4B.
--   - Retornar JSON seguro para consumo cliente-safe/BFF.
--
-- Fora de escopo:
--   - Não cria agenda.
--   - Não recria parcelas.
--   - Não registra operação financeira.
--   - Não confirma/cancela operação.
--   - Não altera frontend, parser, Worker, Make ou n8n.
--
-- Segurança:
--   - Não aceita empresa_id do frontend como autoridade.
--   - Resolve tenant/empresa pelo banco.
--   - Exige auth.uid().
--   - Exige usuário/corretor ativo.
--   - Valida simulação, empreendimento e agenda ativa.
--   - Bloqueia anon.
--   - Não expõe checksum, metadata bruta, payload_origem, VPL, prêmio,
--     comissão, política, taxas internas ou campos de auditoria.

create or replace function public.mesa_cliente_obter_agenda_financeira_cliente_safe(
  p_simulacao_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;

  v_corretor_id uuid;
  v_corretor_empresa_id uuid;
  v_corretor_ativo boolean;
  v_role text;
  v_is_gestor boolean;
  v_is_admin_local boolean;
  v_is_global boolean;

  v_sim_empresa_id uuid;
  v_sim_corretor_id uuid;
  v_sim_empreendimento_id uuid;
  v_sim_unidade_estoque_id uuid;
  v_sim_cliente_nome text;
  v_sim_status text;

  v_agenda_id uuid;
  v_agenda_empresa_id uuid;
  v_agenda_empreendimento_id uuid;
  v_agenda_unidade_estoque_id uuid;
  v_agenda_status text;
  v_agenda_created_at timestamptz;
  v_agenda_updated_at timestamptz;

  v_empreendimento_nome text;

  v_parcelas jsonb;
  v_qtd_parcelas integer;
  v_valor_total numeric;
begin
  if p_simulacao_id is null then
    raise exception 'p_simulacao_id é obrigatório'
      using errcode = '22023';
  end if;

  perform public.mesa_cliente_assert_auth();
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception 'Usuário não autenticado'
      using errcode = '42501';
  end if;

  select
    c.id,
    c.empresa_id,
    coalesce(c.ativo, true),
    coalesce(c.role, ''),
    coalesce(c.is_gestor, false),
    coalesce(c.is_admin_local, false)
  into
    v_corretor_id,
    v_corretor_empresa_id,
    v_corretor_ativo,
    v_role,
    v_is_gestor,
    v_is_admin_local
  from public.corretores c
  where c.user_id = v_auth_uid
    and coalesce(c.ativo, true) = true
  limit 1;

  if v_corretor_id is null or not coalesce(v_corretor_ativo, false) then
    raise exception 'Usuário ativo não encontrado para o MesaCliente'
      using errcode = '42501';
  end if;

  v_is_global := coalesce(public.is_root(), false) or v_role = 'admin_global';

  select
    s.empresa_id,
    s.corretor_id,
    s.empreendimento_id,
    s.unidade_estoque_id,
    s.cliente_nome,
    s.status::text
  into
    v_sim_empresa_id,
    v_sim_corretor_id,
    v_sim_empreendimento_id,
    v_sim_unidade_estoque_id,
    v_sim_cliente_nome,
    v_sim_status
  from public.mesa_simulacoes s
  where s.id = p_simulacao_id;

  if v_sim_empresa_id is null then
    raise exception 'Simulação não encontrada'
      using errcode = 'P0002';
  end if;

  if v_sim_empreendimento_id is null then
    raise exception 'Simulação sem empreendimento vinculado'
      using errcode = '22023';
  end if;

  if not v_is_global and v_corretor_empresa_id is distinct from v_sim_empresa_id then
    raise exception 'Acesso negado à simulação de outra empresa'
      using errcode = '42501';
  end if;

  if not v_is_global
     and not coalesce(v_is_admin_local, false)
     and not coalesce(v_is_gestor, false)
     and v_role not in ('admin_local', 'gestor', 'coordenador')
     and v_sim_corretor_id is distinct from v_corretor_id then
    raise exception 'Perfil sem permissão para acessar a agenda financeira da simulação'
      using errcode = '42501';
  end if;

  select
    a.id,
    a.empresa_id,
    a.empreendimento_id,
    a.unidade_estoque_id,
    a.status,
    a.created_at,
    a.updated_at
  into
    v_agenda_id,
    v_agenda_empresa_id,
    v_agenda_empreendimento_id,
    v_agenda_unidade_estoque_id,
    v_agenda_status,
    v_agenda_created_at,
    v_agenda_updated_at
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = p_simulacao_id
    and a.status = 'ativa'
  order by a.created_at desc, a.id desc
  limit 1;

  if v_agenda_id is null then
    raise exception 'Agenda financeira ativa não encontrada para a simulação'
      using errcode = 'P0002';
  end if;

  if v_agenda_empresa_id is distinct from v_sim_empresa_id then
    raise exception 'Agenda financeira diverge da empresa da simulação'
      using errcode = '42501';
  end if;

  if v_agenda_empreendimento_id is distinct from v_sim_empreendimento_id then
    raise exception 'Agenda financeira diverge do empreendimento da simulação'
      using errcode = '42501';
  end if;

  select to_jsonb(e)->>'nome'
    into v_empreendimento_nome
  from public.empreendimentos e
  where e.id = v_sim_empreendimento_id
    and e.empresa_id = v_sim_empresa_id
  limit 1;

  if v_empreendimento_nome is null then
    raise exception 'Empreendimento da simulação não encontrado ou divergente da empresa'
      using errcode = 'P0002';
  end if;

  with parcelas_base as (
    select
      p.id as parcela_id,
      p.grupo,
      p.descricao,
      p.ordem,
      p.valor_atual,
      p.data_atual,
      p.data_original,
      p.origem_data::text as origem_data,
      p.regra_data,
      p.eh_periodicidade_simbolica,
      (
        p.eh_periodicidade_simbolica is false
        and (
          coalesce(p.pode_receber_antecipacao, false)
          or coalesce(p.pode_receber_postergacao, false)
        )
      ) as negociavel,
      row_number() over (
        partition by p.grupo, p.descricao
        order by p.ordem, p.data_atual nulls last, p.id
      )::integer as parcela_numero,
      count(*) over (
        partition by p.grupo, p.descricao
      )::integer as parcelas_total_item
    from public.mesa_cliente_fluxo_parcelas p
    where p.agenda_id = v_agenda_id
      and p.simulacao_id = p_simulacao_id
      and p.empresa_id = v_sim_empresa_id
      and p.empreendimento_id = v_sim_empreendimento_id
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_strip_nulls(
          jsonb_build_object(
            'id', parcela_id,
            'grupo', grupo,
            'descricao', descricao,
            'ordem', ordem,
            'parcela_numero', parcela_numero,
            'parcelas_total_item', parcelas_total_item,
            'valor', valor_atual,
            'data_vencimento', data_atual,
            'data_original', data_original,
            'origem_data', origem_data,
            'regra_data', regra_data,
            'negociavel', negociavel,
            'eh_periodicidade_simbolica', eh_periodicidade_simbolica,
            'motivos_bloqueio', case
              when eh_periodicidade_simbolica then jsonb_build_array('periodicidade_simbolica_nao_negociavel')
              when not negociavel then jsonb_build_array('parcela_nao_negociavel')
              else '[]'::jsonb
            end
          )
        )
        order by ordem, data_atual nulls last, parcela_id
      ),
      '[]'::jsonb
    ),
    count(*)::integer,
    coalesce(sum(valor_atual), 0)::numeric
  into
    v_parcelas,
    v_qtd_parcelas,
    v_valor_total
  from parcelas_base;

  return jsonb_build_object(
    'ok', true,
    'fase', '4C_CLIENTE_SAFE',
    'visao', 'cliente_safe',
    'cliente_safe', true,
    'persistencia', false,
    'dml_financeiro', false,
    'simulacao', jsonb_strip_nulls(jsonb_build_object(
      'id', p_simulacao_id,
      'status', v_sim_status,
      'cliente_nome', v_sim_cliente_nome
    )),
    'empreendimento', jsonb_strip_nulls(jsonb_build_object(
      'id', v_sim_empreendimento_id,
      'nome', v_empreendimento_nome
    )),
    'agenda', jsonb_build_object(
      'id', v_agenda_id,
      'status', v_agenda_status,
      'created_at', v_agenda_created_at,
      'updated_at', v_agenda_updated_at
    ),
    'totais', jsonb_build_object(
      'qtd_parcelas', v_qtd_parcelas,
      'valor_total', v_valor_total
    ),
    'parcelas', v_parcelas
  );
end;
$$;

revoke all on function public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid) from public;
revoke all on function public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid) from anon;
grant execute on function public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid) to authenticated;

comment on function public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)
is 'Fase 4C MesaCliente: retorna agenda financeira cliente-safe, read-only, sem expor checksum, metadata, VPL, prêmio, comissão, política ou auditoria.';
