-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 4B
-- Persistência segura da agenda financeira gerada pela Fase 4A JSON-first.
--
-- Protocolo Mestre FECH.AI / MesaCliente v1.2
-- Regra: primeiro contrato, depois validação, depois dry-run, depois persistência.
--
-- Escopo desta migration:
-- - Criar cabeçalho versionado de agenda financeira.
-- - Vincular parcelas persistidas a agenda_id.
-- - Criar RPC admin para persistir agenda usando a RPC 4A JSON-first como fonte.
-- - Aplicar lock transacional, idempotência por checksum e auditoria mínima.
-- - Bloquear recriação/substituição quando existir operação confirmada.
--
-- Fora de escopo:
-- - Não cria operação financeira.
-- - Não confirma/cancela operação.
-- - Não cria cliente-safe.
-- - Não mexe em frontend, parser, Worker, Make/n8n.
-- - Não usa empresa_id do frontend como autoridade.

create table if not exists public.mesa_cliente_agendas_financeiras (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id) on delete cascade,
  simulacao_id uuid not null references public.mesa_simulacoes(id) on delete cascade,
  empreendimento_id uuid not null references public.empreendimentos(id) on delete cascade,
  unidade_estoque_id uuid null references public.unidades_estoque(id) on delete set null,
  versao integer not null,
  status text not null default 'ativa',
  origem text not null default '4b_persistencia_agenda_financeira',
  checksum text not null,
  payload_origem jsonb not null default '{}'::jsonb,
  totais jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  criado_por uuid null default auth.uid(),
  substituida_em timestamptz null,
  substituida_por uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint mesa_cliente_agendas_financeiras_status_check
    check (status in ('ativa', 'substituida', 'bloqueada')),
  constraint mesa_cliente_agendas_financeiras_versao_check
    check (versao > 0),
  constraint mesa_cliente_agendas_financeiras_checksum_check
    check (length(checksum) > 0),
  constraint mesa_cliente_agendas_financeiras_empresa_simulacao_versao_key
    unique (empresa_id, simulacao_id, versao),
  constraint mesa_cliente_agendas_financeiras_empresa_simulacao_checksum_key
    unique (empresa_id, simulacao_id, checksum)
);

alter table public.mesa_cliente_agendas_financeiras enable row level security;
alter table public.mesa_cliente_agendas_financeiras force row level security;

create unique index if not exists idx_mcaf_uma_ativa_por_simulacao
  on public.mesa_cliente_agendas_financeiras (empresa_id, simulacao_id)
  where status = 'ativa';

create index if not exists idx_mcaf_tenant_status
  on public.mesa_cliente_agendas_financeiras (empresa_id, empreendimento_id, status, created_at desc);

create index if not exists idx_mcaf_simulacao_status
  on public.mesa_cliente_agendas_financeiras (simulacao_id, status, created_at desc);

drop policy if exists mesa_cliente_agendas_financeiras_select on public.mesa_cliente_agendas_financeiras;
create policy mesa_cliente_agendas_financeiras_select
  on public.mesa_cliente_agendas_financeiras
  for select
  to authenticated
  using (public.is_root() or empresa_id = public.my_empresa_id());

revoke all on table public.mesa_cliente_agendas_financeiras from public;
revoke all on table public.mesa_cliente_agendas_financeiras from anon;
revoke insert, update, delete on table public.mesa_cliente_agendas_financeiras from authenticated;
grant select on table public.mesa_cliente_agendas_financeiras to authenticated;

alter table public.mesa_cliente_fluxo_parcelas
  add column if not exists agenda_id uuid null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'mesa_cliente_fluxo_parcelas_agenda_id_fkey'
      and conrelid = 'public.mesa_cliente_fluxo_parcelas'::regclass
  ) then
    alter table public.mesa_cliente_fluxo_parcelas
      add constraint mesa_cliente_fluxo_parcelas_agenda_id_fkey
      foreign key (agenda_id)
      references public.mesa_cliente_agendas_financeiras(id)
      on delete restrict;
  end if;
end $$;

create index if not exists idx_mcfp_agenda_id
  on public.mesa_cliente_fluxo_parcelas (agenda_id, ordem);

create index if not exists idx_mcfp_agenda_tenant
  on public.mesa_cliente_fluxo_parcelas (empresa_id, simulacao_id, agenda_id);

comment on table public.mesa_cliente_agendas_financeiras is
  'Cabeçalho versionado da agenda financeira persistida. Criado na Fase 4B após validação JSON-first da Fase 4A.';

comment on column public.mesa_cliente_fluxo_parcelas.agenda_id is
  'Vínculo da parcela financeira com o cabeçalho versionado da agenda financeira persistida.';

create or replace function public.mesa_cliente_persistir_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_corretor record;
  v_simulacao record;
  v_empreendimento record;
  v_resultado_4a jsonb;
  v_payload_4a jsonb;
  v_agenda jsonb;
  v_totais jsonb;
  v_checksum text;
  v_agenda_id uuid;
  v_agenda_existente_id uuid;
  v_agenda_existente_checksum text;
  v_nova_versao integer;
  v_qtd_parcelas integer;
  v_valor_total numeric;
  v_tem_operacao_confirmada boolean;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception 'Usuário não autenticado'
      using errcode = '28000';
  end if;

  select c.*
    into v_corretor
  from public.corretores c
  where c.user_id = v_auth_uid
    and coalesce(c.ativo, false) is true
  limit 1;

  if v_corretor.id is null then
    raise exception 'Corretor não encontrado ou inativo'
      using errcode = '42501';
  end if;

  select s.*
    into v_simulacao
  from public.mesa_simulacoes s
  where s.id = p_simulacao_id;

  if v_simulacao.id is null then
    raise exception 'Simulação não encontrada'
      using errcode = 'P0002';
  end if;

  if v_simulacao.empresa_id is null then
    raise exception 'Simulação sem empresa vinculada'
      using errcode = '23502';
  end if;

  if v_simulacao.empreendimento_id is null then
    raise exception 'Simulação sem empreendimento vinculado'
      using errcode = '23502';
  end if;

  select e.*
    into v_empreendimento
  from public.empreendimentos e
  where e.id = v_simulacao.empreendimento_id;

  if v_empreendimento.id is null then
    raise exception 'Empreendimento não encontrado'
      using errcode = 'P0002';
  end if;

  if v_empreendimento.empresa_id is distinct from v_simulacao.empresa_id then
    raise exception 'Empreendimento diverge da empresa da simulação'
      using errcode = '42501';
  end if;

  if coalesce(v_corretor.role::text, '') not in ('admin_global', 'root')
     and v_corretor.empresa_id is distinct from v_simulacao.empresa_id then
    raise exception 'Usuário não pertence à empresa da simulação'
      using errcode = '42501';
  end if;

  if coalesce(v_corretor.role::text, '') not in ('admin_global', 'root', 'admin_local', 'gestor', 'coordenador')
     and v_simulacao.corretor_id is distinct from v_corretor.id then
    raise exception 'Usuário sem perfil para persistir agenda desta simulação'
      using errcode = '42501';
  end if;

  if p_payload_tabela ? 'empresa_id'
     and nullif(p_payload_tabela->>'empresa_id', '')::uuid is distinct from v_simulacao.empresa_id then
    raise exception 'empresa_id do payload_tabela diverge da simulação e não é autoridade'
      using errcode = '42501';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('mesa_cliente_agenda_financeira:' || p_simulacao_id::text, 0));

  select exists (
    select 1
    from public.mesa_cliente_fluxo_operacoes o
    where o.simulacao_id = p_simulacao_id
      and (coalesce(o.confirmado, false) is true or o.status_operacao = 'confirmada')
  ) into v_tem_operacao_confirmada;

  v_resultado_4a := public.mesa_cliente_gerar_agenda_financeira_admin(
    p_simulacao_id,
    p_data_ato,
    p_fluxo_json,
    p_payload_tabela
  );

  if coalesce((v_resultado_4a->>'ok')::boolean, false) is not true then
    raise exception 'RPC 4A não retornou ok=true'
      using errcode = '22023';
  end if;

  v_payload_4a := coalesce(v_resultado_4a->'payload', v_resultado_4a);
  v_agenda := coalesce(v_payload_4a->'agenda', v_resultado_4a->'agenda');

  if v_agenda is null or jsonb_typeof(v_agenda) <> 'array' or jsonb_array_length(v_agenda) = 0 then
    raise exception 'Agenda 4A vazia ou inválida'
      using errcode = '22023';
  end if;

  v_valor_total := (
    select coalesce(sum(coalesce((item->>'valor_atual')::numeric, (item->>'valor_original')::numeric, (item->>'valor')::numeric, 0)), 0)
    from jsonb_array_elements(v_agenda) as t(item)
  );

  v_totais := jsonb_build_object(
    'qtd_parcelas', jsonb_array_length(v_agenda),
    'valor_total', v_valor_total,
    'fase_origem', '4A_JSON_FIRST'
  );

  v_checksum := md5(jsonb_build_object(
    'simulacao_id', p_simulacao_id,
    'data_ato', p_data_ato,
    'agenda', v_agenda,
    'totais', v_totais
  )::text);

  select a.id, a.checksum
    into v_agenda_existente_id, v_agenda_existente_checksum
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = p_simulacao_id
    and a.status = 'ativa'
  order by a.versao desc
  limit 1;

  if v_agenda_existente_id is not null and v_agenda_existente_checksum = v_checksum then
    select count(*)
      into v_qtd_parcelas
    from public.mesa_cliente_fluxo_parcelas p
    where p.agenda_id = v_agenda_existente_id;

    return jsonb_build_object(
      'ok', true,
      'fase', '4B_PERSISTENCIA_AGENDA',
      'persistencia', true,
      'dml_financeiro', false,
      'idempotente', true,
      'cliente_safe', false,
      'visao', 'administrativa',
      'agenda_id', v_agenda_existente_id,
      'simulacao_id', p_simulacao_id,
      'qtd_parcelas_persistidas', v_qtd_parcelas,
      'checksum', v_checksum,
      'mensagem', 'Agenda ativa já existia com o mesmo checksum; nenhuma nova parcela foi criada.'
    );
  end if;

  if v_agenda_existente_id is not null and v_tem_operacao_confirmada is true then
    raise exception 'Agenda não pode ser substituída: existe operação financeira confirmada para a simulação'
      using errcode = '55000';
  end if;

  select coalesce(max(a.versao), 0) + 1
    into v_nova_versao
  from public.mesa_cliente_agendas_financeiras a
  where a.simulacao_id = p_simulacao_id;

  if v_agenda_existente_id is not null then
    update public.mesa_cliente_agendas_financeiras
       set status = 'substituida',
           substituida_em = now(),
           substituida_por = v_auth_uid,
           updated_at = now(),
           metadata = metadata || jsonb_build_object('substituida_por_nova_versao', v_nova_versao)
     where id = v_agenda_existente_id
       and status = 'ativa';
  end if;

  insert into public.mesa_cliente_agendas_financeiras (
    empresa_id,
    simulacao_id,
    empreendimento_id,
    unidade_estoque_id,
    versao,
    status,
    checksum,
    payload_origem,
    totais,
    metadata,
    criado_por
  ) values (
    v_simulacao.empresa_id,
    v_simulacao.id,
    v_simulacao.empreendimento_id,
    v_simulacao.unidade_estoque_id,
    v_nova_versao,
    'ativa',
    v_checksum,
    jsonb_build_object(
      'data_ato', p_data_ato,
      'payload_tabela_sem_autoridade', coalesce(p_payload_tabela, '{}'::jsonb),
      'resultado_4a', v_resultado_4a
    ),
    v_totais,
    jsonb_build_object(
      'fonte', 'mesa_cliente_persistir_agenda_financeira_admin',
      'contrato', '4B_persistencia_segura_pos_4A_json_first',
      'protocolo', 'protocolo-mestre-fechai-mesacliente-v1.2'
    ),
    v_auth_uid
  )
  returning id into v_agenda_id;

  insert into public.mesa_cliente_fluxo_parcelas (
    agenda_id,
    empresa_id,
    simulacao_id,
    empreendimento_id,
    unidade_estoque_id,
    grupo,
    descricao,
    valor_original,
    valor_atual,
    data_original,
    data_atual,
    origem_data,
    regra_data,
    ordem,
    eh_periodicidade_simbolica,
    pode_receber_vpl,
    pode_receber_antecipacao,
    pode_receber_postergacao,
    metadata
  )
  select
    v_agenda_id,
    v_simulacao.empresa_id,
    v_simulacao.id,
    v_simulacao.empreendimento_id,
    v_simulacao.unidade_estoque_id,
    case
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('ato') then 'ato'
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('entrada') then 'entrada'
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('complemento', 'complementos', '30_60_90') then 'complemento'
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('mensal', 'mensais') then 'mensal'
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('anual', 'anuais', 'intermediaria', 'intermediarias', 'intermediária', 'intermediárias') then 'anual'
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('chaves', 'chave') then 'chaves'
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('unica', 'única', 'parcela_unica', 'parcela_única') then 'unica'
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('financiamento') then 'financiamento'
      when lower(coalesce(x.item->>'grupo', 'outros')) in ('periodicidade') then 'periodicidade'
      else 'outros'
    end,
    coalesce(nullif(x.item->>'descricao', ''), 'Parcela financeira'),
    coalesce((nullif(x.item->>'valor_original', ''))::numeric, (nullif(x.item->>'valor', ''))::numeric, 0),
    coalesce((nullif(x.item->>'valor_atual', ''))::numeric, (nullif(x.item->>'valor', ''))::numeric, (nullif(x.item->>'valor_original', ''))::numeric, 0),
    coalesce((nullif(x.item->>'data_original', ''))::date, (nullif(x.item->>'data_vencimento', ''))::date, (nullif(x.item->>'data_atual', ''))::date),
    coalesce((nullif(x.item->>'data_atual', ''))::date, (nullif(x.item->>'data_vencimento', ''))::date, (nullif(x.item->>'data_original', ''))::date),
    case coalesce(nullif(x.item->>'origem_data', ''), 'estimada')
      when 'data_oficial' then 'tabela_oficial'
      when 'tabela_oficial' then 'tabela_oficial'
      when 'tabela_comercial_data' then 'tabela_comercial_data'
      when 'tabela_comercial_mes' then 'tabela_comercial_mes'
      when 'cabecalho_regra' then 'cabecalho_regra'
      when 'calculada_ato' then 'calculada_ato'
      when 'offset_data_ato' then 'calculada_ato'
      when 'fallback_data_ato' then 'estimada'
      when 'estimada' then 'estimada'
      when 'manual' then 'manual'
      else 'estimada'
    end::public.mesa_financeira_origem_data,
    coalesce(nullif(x.item->>'regra_data', ''), nullif(x.item->>'origem_regra', '')),
    coalesce((nullif(x.item->>'ordem', ''))::integer, x.idx::integer),
    coalesce((nullif(x.item->>'eh_periodicidade_simbolica', ''))::boolean, lower(coalesce(x.item->>'grupo', '')) = 'periodicidade'),
    case
      when coalesce((nullif(x.item->>'eh_periodicidade_simbolica', ''))::boolean, lower(coalesce(x.item->>'grupo', '')) = 'periodicidade') then false
      else coalesce((nullif(x.item->>'pode_receber_vpl', ''))::boolean, (nullif(x.item->>'elegivel_vpl', ''))::boolean, true)
    end,
    case
      when coalesce((nullif(x.item->>'eh_periodicidade_simbolica', ''))::boolean, lower(coalesce(x.item->>'grupo', '')) = 'periodicidade') then false
      else coalesce((nullif(x.item->>'pode_receber_antecipacao', ''))::boolean, true)
    end,
    case
      when coalesce((nullif(x.item->>'eh_periodicidade_simbolica', ''))::boolean, lower(coalesce(x.item->>'grupo', '')) = 'periodicidade') then false
      else coalesce((nullif(x.item->>'pode_receber_postergacao', ''))::boolean, true)
    end,
    jsonb_build_object(
      'fonte', '4B_persistencia_de_agenda_gerada_pela_4A',
      'item_origem_index', coalesce((nullif(x.item->>'item_origem_index', ''))::integer, x.idx::integer),
      'parcela_numero', coalesce((nullif(x.item->>'parcela_numero', ''))::integer, 1),
      'parcelas_total_item', coalesce((nullif(x.item->>'parcelas_total_item', ''))::integer, 1),
      'item_4a', x.item
    )
  from jsonb_array_elements(v_agenda) with ordinality as x(item, idx);

  get diagnostics v_qtd_parcelas = row_count;

  return jsonb_build_object(
    'ok', true,
    'fase', '4B_PERSISTENCIA_AGENDA',
    'persistencia', true,
    'dml_financeiro', true,
    'idempotente', false,
    'cliente_safe', false,
    'visao', 'administrativa',
    'agenda_id', v_agenda_id,
    'simulacao_id', p_simulacao_id,
    'versao', v_nova_versao,
    'qtd_parcelas_persistidas', v_qtd_parcelas,
    'valor_total_agenda', v_valor_total,
    'checksum', v_checksum,
    'agenda_anterior_substituida', v_agenda_existente_id is not null
  );
end;
$$;

revoke all on function public.mesa_cliente_persistir_agenda_financeira_admin(uuid, date, jsonb, jsonb) from public;
revoke all on function public.mesa_cliente_persistir_agenda_financeira_admin(uuid, date, jsonb, jsonb) from anon;
grant execute on function public.mesa_cliente_persistir_agenda_financeira_admin(uuid, date, jsonb, jsonb) to authenticated;

comment on function public.mesa_cliente_persistir_agenda_financeira_admin(uuid, date, jsonb, jsonb) is
  'Fase 4B: persiste agenda financeira administrativa a partir da RPC 4A JSON-first, com lock, idempotência, versionamento e bloqueio contra operação confirmada.';
