begin;

-- -----------------------------------------------------------------------------
-- FECH.AI / MesaCliente — Fase 20D.5
-- Fluxo financeiro canônico em shadow mode
-- -----------------------------------------------------------------------------
-- Objetivo:
--   Corrigir a origem canônica do fluxo financeiro sem quebrar o legado.
--
-- Estratégia:
--   1. Criar tabela paralela public.mesa_fluxo_pagamentos_canonico.
--   2. Manter public.mesa_fluxo_pagamentos como legado/compatibilidade.
--   3. Atualizar public.criar_mesa_simulacao para gravar também o fluxo canônico.
--   4. Corrigir semanticamente no canônico:
--      - u => parcela_unica_obra, não quitacao;
--      - f => financiamento_saldo;
--      - p => periodicidade_obra;
--      - financiamento residual = valor_total - fluxo de obra, quando f não vier no payload.
--
-- Não faz:
--   - backfill de propostas antigas;
--   - alteração de parser, Worker, Make/n8n ou frontend;
--   - reprocessamento de tabela;
--   - alteração destrutiva da tabela legada;
--   - aplicação de operações financeiras avançadas.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 1. Preflight defensivo
-- -----------------------------------------------------------------------------

do $$
begin
  if to_regclass('public.mesa_simulacoes') is null then
    raise exception 'Tabela public.mesa_simulacoes não encontrada. 20D.5 abortada.';
  end if;

  if to_regclass('public.mesa_fluxo_pagamentos') is null then
    raise exception 'Tabela public.mesa_fluxo_pagamentos não encontrada. 20D.5 abortada.';
  end if;

  if to_regclass('public.unidades_estoque') is null then
    raise exception 'Tabela public.unidades_estoque não encontrada. 20D.5 abortada.';
  end if;

  if to_regclass('public.empreendimentos') is null then
    raise exception 'Tabela public.empreendimentos não encontrada. 20D.5 abortada.';
  end if;

  if to_regclass('public.corretores') is null then
    raise exception 'Tabela public.corretores não encontrada. 20D.5 abortada.';
  end if;

  if to_regclass('public.audit_logs') is null then
    raise exception 'Tabela public.audit_logs não encontrada. 20D.5 abortada.';
  end if;

  if to_regtype('public.mesa_fluxo_tipo') is null then
    raise exception 'Enum public.mesa_fluxo_tipo não encontrado. 20D.5 abortada.';
  end if;

  if to_regprocedure('public.is_root()') is null then
    raise exception 'Função public.is_root() não encontrada. 20D.5 abortada.';
  end if;

  if to_regprocedure('public.validar_mesa_cliente_desconto(uuid,numeric,numeric)') is null then
    raise exception 'Função public.validar_mesa_cliente_desconto(uuid,numeric,numeric) não encontrada. 20D.5 abortada.';
  end if;
end $$;

-- -----------------------------------------------------------------------------
-- 2. Helper read-only para extrair chave=valor de unidades_estoque.observacoes
-- -----------------------------------------------------------------------------

create or replace function public.mesa_cliente_extract_obs_kv(
  p_observacoes text,
  p_key text
)
returns text
language plpgsql
immutable
set search_path = public
as $$
declare
  v_part text;
  v_pos integer;
  v_k text;
  v_v text;
begin
  if p_key is null or btrim(p_key) = '' then
    return null;
  end if;

  foreach v_part in array regexp_split_to_array(coalesce(p_observacoes, ''), '\|') loop
    v_pos := position('=' in v_part);

    if v_pos > 0 then
      v_k := btrim(substring(v_part from 1 for v_pos - 1));
      v_v := btrim(substring(v_part from v_pos + 1));

      if lower(v_k) = lower(btrim(p_key)) then
        return nullif(v_v, '');
      end if;
    end if;
  end loop;

  return null;
end;
$$;

comment on function public.mesa_cliente_extract_obs_kv(text, text) is
  'MesaCliente 20D.5: helper imutável para extrair chave=valor de unidades_estoque.observacoes. Usado apenas como fonte auxiliar/fallback, nunca como payload soberano do frontend.';

revoke all on function public.mesa_cliente_extract_obs_kv(text, text) from public;
revoke all on function public.mesa_cliente_extract_obs_kv(text, text) from anon;
grant execute on function public.mesa_cliente_extract_obs_kv(text, text) to authenticated;

-- -----------------------------------------------------------------------------
-- 3. Tabela canônica shadow
-- -----------------------------------------------------------------------------

create table if not exists public.mesa_fluxo_pagamentos_canonico (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null,
  simulacao_id uuid not null references public.mesa_simulacoes(id) on delete cascade,
  fluxo_pagamento_id uuid null references public.mesa_fluxo_pagamentos(id) on delete set null,

  origem_registro text not null default 'criar_mesa_simulacao_20d5_shadow',
  grupo_original text null,
  grupo_canonico text not null,
  natureza_financeira text not null,
  descricao text not null,
  ordem integer not null,

  valor_unitario numeric not null default 0,
  quantidade integer not null default 1,
  valor_total numeric not null default 0,
  periodicidade text null,

  data_prevista date null,
  origem_data text null,
  fonte_tipo text not null default 'classificacao_explicita_pipeline',
  fonte_valor text not null default 'payload_fluxo_ou_resumo_simulacao',

  entra_agenda boolean not null default true,
  entra_motor_financeiro boolean not null default true,
  valor_simbolico boolean not null default false,

  created_by_user_id uuid null,
  created_by_corretor_id uuid null,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint mesa_fluxo_canonico_grupo_check check (
    grupo_canonico in (
      'entrada_ato',
      'entrada_complemento',
      'mensal_obra',
      'intermediaria_obra',
      'parcela_unica_obra',
      'financiamento_saldo',
      'quitacao_real',
      'periodicidade_obra',
      'observacao_operacional'
    )
  ),
  constraint mesa_fluxo_canonico_quantidade_check check (quantidade between 1 and 240),
  constraint mesa_fluxo_canonico_valor_unitario_check check (valor_unitario >= 0),
  constraint mesa_fluxo_canonico_valor_total_check check (valor_total >= 0),
  constraint mesa_fluxo_canonico_ordem_check check (ordem >= 0)
);

comment on table public.mesa_fluxo_pagamentos_canonico is
  'MesaCliente 20D.5: fluxo financeiro canônico em shadow mode. Corrige semântica de parcela única/chaves, financiamento/saldo e periodicidade sem quebrar mesa_fluxo_pagamentos legado.';

comment on column public.mesa_fluxo_pagamentos_canonico.grupo_canonico is
  'Grupo financeiro canônico. Não pode ser derivado por quantidade; deve vir de classificação explícita da tabela/pipeline.';

comment on column public.mesa_fluxo_pagamentos_canonico.valor_total is
  'Total da obrigação financeira do grupo/linha. Quantidade define repetição, não natureza.';

comment on column public.mesa_fluxo_pagamentos_canonico.valor_simbolico is
  'Usado para periodicidade/final simbólica de obra. Não deve classificar tipo por valor; apenas marca natureza operacional já classificada.';

create index if not exists idx_mesa_fluxo_canonico_empresa_simulacao
  on public.mesa_fluxo_pagamentos_canonico (empresa_id, simulacao_id);

create index if not exists idx_mesa_fluxo_canonico_simulacao_ordem
  on public.mesa_fluxo_pagamentos_canonico (simulacao_id, ordem);

create index if not exists idx_mesa_fluxo_canonico_grupo
  on public.mesa_fluxo_pagamentos_canonico (grupo_canonico);

create unique index if not exists ux_mesa_fluxo_canonico_sim_origem_ordem
  on public.mesa_fluxo_pagamentos_canonico (simulacao_id, origem_registro, ordem);

alter table public.mesa_fluxo_pagamentos_canonico enable row level security;

revoke all on table public.mesa_fluxo_pagamentos_canonico from public;
revoke all on table public.mesa_fluxo_pagamentos_canonico from anon;
revoke all on table public.mesa_fluxo_pagamentos_canonico from authenticated;
grant select, insert, update, delete on table public.mesa_fluxo_pagamentos_canonico to service_role;

-- -----------------------------------------------------------------------------
-- 4. Atualização da origem: criar_mesa_simulacao grava legado + canônico shadow
-- -----------------------------------------------------------------------------

create or replace function public.criar_mesa_simulacao(
  p_empresa_id uuid,
  p_empreendimento_id uuid,
  p_unidade_id uuid default null::uuid,
  p_lead_id uuid default null::uuid,
  p_cliente_nome text default null::text,
  p_valor_total numeric default 0,
  p_meta_obra_pct integer default 30,
  p_tabela_provisoria boolean default false,
  p_fluxo_json jsonb default '[]'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_id uuid;
  v_auth_uid uuid;
  v_corretor_id uuid;
  v_user_empresa_id uuid;
  v_target_empresa_id uuid;
  v_item jsonb;
  v_ordem int := 0;
  v_obra_total numeric := 0;
  v_fin_total numeric := 0;
  v_fin_json_total numeric := 0;
  v_fin_explicit_count integer := 0;
  v_tipo_fluxo mesa_fluxo_tipo;
  v_valor_tabela numeric := 0;
  v_unidade_observacoes text;
  v_desconto_valor numeric := 0;
  v_desconto_validacao jsonb := '{}'::jsonb;
  v_audit_payload jsonb := '{}'::jsonb;
  v_is_root boolean := false;
  v_item_grupo text;
  v_item_label text;
  v_item_valor numeric;
  v_item_qty integer;
  v_item_total numeric;
  v_item_data date;
  v_item_periodicidade text;
  v_fluxo_pagamento_id uuid;
  v_grupo_canonico text;
  v_natureza_financeira text;
  v_entra_agenda boolean;
  v_entra_motor_financeiro boolean;
  v_valor_simbolico boolean;
  v_fonte_tipo text;
  v_origem_data text;
  v_financiamento_data_txt text;
  v_financiamento_data date;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception 'Usuário não autenticado';
  end if;

  if p_empresa_id is null then
    raise exception 'Empresa obrigatória para criar mesa';
  end if;

  if p_empreendimento_id is null then
    raise exception 'Empreendimento obrigatório para criar mesa';
  end if;

  if p_valor_total is null or p_valor_total <= 0 then
    raise exception 'Valor total inválido para criar mesa';
  end if;

  if p_fluxo_json is null or jsonb_typeof(p_fluxo_json) <> 'array' then
    raise exception 'Fluxo de pagamento inválido';
  end if;

  v_is_root := coalesce(public.is_root(), false);

  select c.id, c.empresa_id
    into v_corretor_id, v_user_empresa_id
  from public.corretores c
  where c.user_id = v_auth_uid
    and coalesce(c.ativo, true) = true
  limit 1;

  select e.empresa_id
    into v_target_empresa_id
  from public.empreendimentos e
  where e.id = p_empreendimento_id
    and e.status = 'ativo'
  limit 1;

  if v_target_empresa_id is null then
    raise exception 'Empreendimento não encontrado ou inativo';
  end if;

  if v_target_empresa_id is distinct from p_empresa_id then
    raise exception 'Empresa informada não pertence ao empreendimento';
  end if;

  if v_corretor_id is null then
    raise exception 'Usuário sem corretor ativo vinculado';
  end if;

  if not v_is_root and v_user_empresa_id is distinct from p_empresa_id then
    raise exception 'Acesso negado para criar mesa nesta empresa';
  end if;

  if p_unidade_id is not null then
    select ue.valor_tabela,
           ue.observacoes
      into v_valor_tabela,
           v_unidade_observacoes
    from public.unidades_estoque ue
    where ue.id = p_unidade_id
      and ue.empresa_id = p_empresa_id
      and ue.empreendimento_id = p_empreendimento_id
    limit 1;

    if v_valor_tabela is null then
      raise exception 'Unidade não encontrada para a empresa/empreendimento informado';
    end if;

    v_desconto_valor := greatest(0, v_valor_tabela - p_valor_total);
    v_desconto_validacao := public.validar_mesa_cliente_desconto(
      p_empreendimento_id,
      v_valor_tabela,
      v_desconto_valor
    );

    if coalesce((v_desconto_validacao->>'bloqueado')::boolean, false) then
      raise exception 'Desconto proibido pela política comercial configurada. Reduza o desconto ou solicite aprovação gerencial.';
    end if;
  end if;

  v_financiamento_data_txt := coalesce(
    public.mesa_cliente_extract_obs_kv(v_unidade_observacoes, 'financiamento_data'),
    public.mesa_cliente_extract_obs_kv(v_unidade_observacoes, 'financiamento_price_data')
  );

  if v_financiamento_data_txt ~ '^\d{4}-\d{2}-\d{2}$' then
    v_financiamento_data := v_financiamento_data_txt::date;
  else
    v_financiamento_data := null;
  end if;

  for v_item in select * from jsonb_array_elements(p_fluxo_json) loop
    v_item_grupo := coalesce(v_item->>'grupo', '');
    v_item_total := coalesce(nullif(v_item->>'total', '')::numeric, 0);

    if v_item_grupo in ('e','c','m','a','u') then
      v_obra_total := v_obra_total + v_item_total;
    elsif v_item_grupo = 'f' then
      v_fin_json_total := v_fin_json_total + v_item_total;
      v_fin_explicit_count := v_fin_explicit_count + 1;
    elsif v_item_grupo = 'p' then
      -- Periodicidade/Final(is) é controle de prazo de obra e não compõe obra_total.
      null;
    else
      raise exception 'Grupo de fluxo não reconhecido para persistência canônica. grupo=%', v_item_grupo;
    end if;
  end loop;

  if v_fin_json_total > 0 then
    v_fin_total := v_fin_json_total;
  else
    v_fin_total := greatest(0, p_valor_total - v_obra_total);
  end if;

  insert into public.mesa_simulacoes (
    empresa_id,
    corretor_id,
    lead_id,
    empreendimento_id,
    unidade_estoque_id,
    cliente_nome,
    status,
    valor_total,
    entrada,
    financiamento,
    snapshot_payload
  ) values (
    p_empresa_id,
    v_corretor_id,
    p_lead_id,
    p_empreendimento_id,
    p_unidade_id,
    p_cliente_nome,
    case
      when coalesce((v_desconto_validacao->>'requer_aprovacao')::boolean, false)
        then 'em_analise'::public.mesa_simulacao_status
      else 'rascunho'::public.mesa_simulacao_status
    end,
    p_valor_total,
    v_obra_total,
    v_fin_total,
    jsonb_build_object(
      'meta_obra_pct', p_meta_obra_pct,
      'tabela_provisoria', p_tabela_provisoria,
      'criado_por', v_corretor_id,
      'criado_por_user_id', v_auth_uid,
      'valor_tabela', nullif(v_valor_tabela, 0),
      'valor_negociado', p_valor_total,
      'desconto_valor', v_desconto_valor,
      'desconto_validacao', v_desconto_validacao,
      'fluxo_canonico_shadow', true,
      'fluxo_canonico_versao', '20D.5',
      'financiamento_calculado_residual', v_fin_explicit_count = 0 and v_fin_total > 0
    )
  ) returning id into v_id;

  for v_item in select * from jsonb_array_elements(p_fluxo_json) loop
    v_item_grupo := coalesce(v_item->>'grupo', '');
    v_item_label := coalesce(nullif(v_item->>'label', ''), v_item_grupo);
    v_item_valor := coalesce(nullif(v_item->>'valor', '')::numeric, 0);
    v_item_qty := coalesce(nullif(v_item->>'qty', '')::int, 1);
    v_item_total := coalesce(nullif(v_item->>'total', '')::numeric, v_item_valor * v_item_qty);
    v_item_data := nullif(v_item->>'date', '')::date;
    v_item_periodicidade := nullif(v_item->>'periodicidade', '');

    if v_item_grupo not in ('e','c','m','a','u','f','p') then
      raise exception 'Grupo de fluxo não reconhecido para gravação. grupo=%', v_item_grupo;
    end if;

    v_tipo_fluxo := case v_item_grupo
      when 'e' then 'entrada'::mesa_fluxo_tipo
      when 'c' then 'curto_prazo'::mesa_fluxo_tipo
      when 'm' then 'periodica'::mesa_fluxo_tipo
      when 'a' then 'intermediaria'::mesa_fluxo_tipo
      when 'u' then 'quitacao'::mesa_fluxo_tipo -- legado/compatibilidade; canônico corrige para parcela_unica_obra.
      when 'f' then 'financiamento'::mesa_fluxo_tipo
      when 'p' then 'observacao'::mesa_fluxo_tipo
    end;

    insert into public.mesa_fluxo_pagamentos (
      empresa_id,
      simulacao_id,
      tipo,
      descricao,
      valor,
      quantidade,
      periodicidade,
      data_prevista,
      ordem
    ) values (
      p_empresa_id,
      v_id,
      v_tipo_fluxo,
      v_item_label,
      v_item_valor,
      v_item_qty,
      v_item_periodicidade,
      v_item_data,
      v_ordem
    ) returning id into v_fluxo_pagamento_id;

    v_grupo_canonico := case v_item_grupo
      when 'e' then 'entrada_ato'
      when 'c' then 'entrada_complemento'
      when 'm' then 'mensal_obra'
      when 'a' then 'intermediaria_obra'
      when 'u' then 'parcela_unica_obra'
      when 'f' then 'financiamento_saldo'
      when 'p' then 'periodicidade_obra'
    end;

    v_natureza_financeira := case v_item_grupo
      when 'e' then 'entrada_obra'
      when 'c' then 'complemento_entrada_obra'
      when 'm' then 'mensal_obra'
      when 'a' then 'intermediaria_obra'
      when 'u' then 'parcela_unica_chaves_obra'
      when 'f' then 'saldo_devedor_financiamento'
      when 'p' then 'controle_periodo_obra'
    end;

    v_entra_agenda := case when v_item_grupo = 'p' then false else true end;
    v_entra_motor_financeiro := case when v_item_grupo = 'p' then false else true end;
    v_valor_simbolico := case when v_item_grupo = 'p' then true else false end;
    v_fonte_tipo := 'grupo_frontend_' || v_item_grupo || '_classificacao_pipeline';
    v_origem_data := case when v_item_data is not null then 'payload_fluxo_json' else null end;

    insert into public.mesa_fluxo_pagamentos_canonico (
      empresa_id,
      simulacao_id,
      fluxo_pagamento_id,
      origem_registro,
      grupo_original,
      grupo_canonico,
      natureza_financeira,
      descricao,
      ordem,
      valor_unitario,
      quantidade,
      valor_total,
      periodicidade,
      data_prevista,
      origem_data,
      fonte_tipo,
      fonte_valor,
      entra_agenda,
      entra_motor_financeiro,
      valor_simbolico,
      created_by_user_id,
      created_by_corretor_id,
      metadata
    ) values (
      p_empresa_id,
      v_id,
      v_fluxo_pagamento_id,
      'criar_mesa_simulacao_20d5_shadow',
      v_item_grupo,
      v_grupo_canonico,
      v_natureza_financeira,
      v_item_label,
      v_ordem,
      v_item_valor,
      v_item_qty,
      v_item_total,
      v_item_periodicidade,
      v_item_data,
      v_origem_data,
      v_fonte_tipo,
      'payload_fluxo_json',
      v_entra_agenda,
      v_entra_motor_financeiro,
      v_valor_simbolico,
      v_auth_uid,
      v_corretor_id,
      jsonb_build_object(
        'source', v_item->>'source',
        'is_group', coalesce((v_item->>'isGroup')::boolean, false),
        'observacao', case
          when v_item_grupo = 'u' then 'parcela_unica_obra_nao_quitacao'
          when v_item_grupo = 'p' then 'periodicidade_final_simbolica_controle_obra'
          else null
        end
      )
    );

    v_ordem := v_ordem + 1;
  end loop;

  if v_fin_total > 0 and v_fin_explicit_count = 0 then
    insert into public.mesa_fluxo_pagamentos_canonico (
      empresa_id,
      simulacao_id,
      fluxo_pagamento_id,
      origem_registro,
      grupo_original,
      grupo_canonico,
      natureza_financeira,
      descricao,
      ordem,
      valor_unitario,
      quantidade,
      valor_total,
      periodicidade,
      data_prevista,
      origem_data,
      fonte_tipo,
      fonte_valor,
      entra_agenda,
      entra_motor_financeiro,
      valor_simbolico,
      created_by_user_id,
      created_by_corretor_id,
      metadata
    ) values (
      p_empresa_id,
      v_id,
      null,
      'criar_mesa_simulacao_20d5_shadow',
      'f_residual',
      'financiamento_saldo',
      'saldo_devedor_financiamento',
      'Financiamento / saldo devedor',
      v_ordem,
      v_fin_total,
      1,
      v_fin_total,
      null,
      v_financiamento_data,
      case when v_financiamento_data is not null then 'unidades_estoque.observacoes.financiamento_data' else 'ausente_na_origem' end,
      'residual_valor_total_menos_fluxo_obra',
      'mesa_simulacoes.valor_total_menos_obra_total',
      true,
      true,
      false,
      v_auth_uid,
      v_corretor_id,
      jsonb_build_object(
        'gerado_por', 'residual_valor_total_menos_fluxo_obra',
        'valor_total_simulacao', p_valor_total,
        'obra_total', v_obra_total,
        'financiamento_total', v_fin_total,
        'financiamento_data_txt', v_financiamento_data_txt
      )
    );
  end if;

  v_audit_payload := jsonb_build_object(
    'cliente_nome', p_cliente_nome,
    'valor_total', p_valor_total,
    'valor_tabela', nullif(v_valor_tabela, 0),
    'desconto_valor', v_desconto_valor,
    'desconto_validacao', v_desconto_validacao,
    'tabela_provisoria', p_tabela_provisoria,
    'num_parcelas', jsonb_array_length(p_fluxo_json),
    'simulacao_id', v_id,
    'corretor_id', v_corretor_id,
    'auth_uid', v_auth_uid,
    'fluxo_canonico_shadow', true,
    'fluxo_canonico_versao', '20D.5',
    'entrada_total', v_obra_total,
    'financiamento_total', v_fin_total,
    'financiamento_calculado_residual', v_fin_explicit_count = 0 and v_fin_total > 0
  );

  insert into public.audit_logs (
    empresa_id,
    action,
    actor_id,
    payload,
    ator_user_id,
    ator_corretor_id,
    acao,
    entidade,
    entidade_id,
    depois
  ) values (
    p_empresa_id,
    'criar_mesa_simulacao',
    v_auth_uid,
    v_audit_payload,
    v_auth_uid,
    v_corretor_id,
    'criar_mesa_simulacao',
    'mesa_simulacoes',
    v_id,
    v_audit_payload
  );

  return v_id;
end;
$function$;

comment on function public.criar_mesa_simulacao(uuid, uuid, uuid, uuid, text, numeric, integer, boolean, jsonb) is
  'MesaCliente 20D.5: cria simulação mantendo mesa_fluxo_pagamentos legado e gravando mesa_fluxo_pagamentos_canonico em shadow mode. Parcela única/chaves não é quitação; financiamento residual é item canônico; periodicidade/final é controle de obra.';

commit;
