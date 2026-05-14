-- FECH.AI — Mesa Cliente
-- Preview: exibir unidades extraídas pelo parser da tabela comercial
--
-- Esta migration cria RPCs tenant-safe para:
-- 1) importar unidades extraídas pelo parser para estoque_snapshots/unidades_estoque;
-- 2) listar todas as unidades extraídas para uso na tela Mesa Cliente.
--
-- Importante:
-- - Não usa service_role no frontend.
-- - Não abre INSERT direto em unidades_estoque.
-- - Não usa empresa_id vindo do frontend como fonte de verdade.
-- - Não aplica espelho de vendas nesta fase.
-- - Todas as unidades importadas são exibidas com disponibilidade_validada = false.

begin;

-- -----------------------------------------------------------------------------
-- RPC: get_unidades_mesa
-- -----------------------------------------------------------------------------
-- Retorna todas as unidades do snapshot ativo/mais recente do empreendimento.
-- A disponibilidade NÃO é validada pelo espelho nesta etapa.
-- Segurança:
-- - Usuário autenticado obrigatório.
-- - Empreendimento deve pertencer ao tenant do usuário, exceto root.
-- - Retorno limitado ao tenant validado.

create or replace function public.get_unidades_mesa(
  p_empreendimento_id uuid
)
returns table (
  id uuid,
  empreendimento_id uuid,
  snapshot_id uuid,
  unidade text,
  torre text,
  andar integer,
  final text,
  metragem numeric,
  dormitorios integer,
  suites integer,
  vagas_quantidade integer,
  valor_tabela numeric,
  status_comercial text,
  disponibilidade_validada boolean,
  aviso text,
  observacoes text,
  confianca_linha text,
  atualizado_em timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_empresa_id uuid;
  v_emp_empresa_id uuid;
  v_snapshot_id uuid;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if p_empreendimento_id is null then
    raise exception 'EMPREENDIMENTO_REQUIRED' using errcode = '22023';
  end if;

  v_empresa_id := public.my_empresa_id();

  select e.empresa_id
    into v_emp_empresa_id
  from public.empreendimentos e
  where e.id = p_empreendimento_id;

  if v_emp_empresa_id is null then
    raise exception 'EMPREENDIMENTO_NOT_FOUND' using errcode = 'P0002';
  end if;

  if not public.is_root() and v_emp_empresa_id is distinct from v_empresa_id then
    raise exception 'TENANT_FORBIDDEN' using errcode = '42501';
  end if;

  select s.id
    into v_snapshot_id
  from public.estoque_snapshots s
  where s.empreendimento_id = p_empreendimento_id
    and s.empresa_id = v_emp_empresa_id
    and s.ativo = true
    and s.status_processamento in ('processado', 'validado')
  order by s.data_referencia desc nulls last,
           s.data_processamento desc nulls last,
           s.created_at desc
  limit 1;

  if v_snapshot_id is null then
    return;
  end if;

  return query
  select
    u.id,
    u.empreendimento_id,
    u.snapshot_id,
    u.unidade,
    u.torre,
    u.andar,
    u.final,
    u.metragem,
    u.dormitorios,
    u.suites,
    u.vagas_quantidade,
    u.valor_tabela,
    u.status_comercial::text,
    false as disponibilidade_validada,
    'Disponibilidade ainda não validada pelo espelho de vendas'::text as aviso,
    u.observacoes,
    u.confianca_linha::text,
    u.updated_at as atualizado_em
  from public.unidades_estoque u
  where u.snapshot_id = v_snapshot_id
    and u.empresa_id = v_emp_empresa_id
    and u.empreendimento_id = p_empreendimento_id
  order by
    u.torre nulls last,
    u.andar nulls last,
    u.unidade;
end;
$$;

revoke all on function public.get_unidades_mesa(uuid) from public;
grant execute on function public.get_unidades_mesa(uuid) to authenticated;

comment on function public.get_unidades_mesa(uuid) is
'Mesa Cliente: lista unidades extraídas da tabela comercial para o empreendimento do tenant autenticado. Não valida espelho de vendas nesta etapa.';

-- -----------------------------------------------------------------------------
-- RPC: importar_unidades_mesa_parser
-- -----------------------------------------------------------------------------
-- Recebe unidades canônicas do parser e cria um novo snapshot ativo.
-- Segurança:
-- - Usuário autenticado obrigatório.
-- - Importação restrita a gestor/admin/root.
-- - Empreendimento deve pertencer ao tenant do usuário, exceto root.
-- - Arquivo, quando informado, deve pertencer ao mesmo tenant/empreendimento.
-- - Não aceita unidade sem identificador ou sem valor_tabela positivo.

create or replace function public.importar_unidades_mesa_parser(
  p_empreendimento_id uuid,
  p_arquivo_id uuid default null,
  p_parser_nome text default null,
  p_unidades jsonb default '[]'::jsonb
)
returns table (
  snapshot_id uuid,
  quantidade_importada integer,
  status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_empresa_id uuid;
  v_emp_empresa_id uuid;
  v_corretor_id uuid;
  v_is_importador boolean := false;
  v_snapshot_id uuid;
  v_item jsonb;
  v_count integer := 0;
  v_valor numeric;
  v_unidade text;
  v_arquivo_ok boolean := false;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  if p_empreendimento_id is null then
    raise exception 'EMPREENDIMENTO_REQUIRED' using errcode = '22023';
  end if;

  if p_unidades is null or jsonb_typeof(p_unidades) <> 'array' then
    raise exception 'UNIDADES_ARRAY_REQUIRED' using errcode = '22023';
  end if;

  if jsonb_array_length(p_unidades) = 0 then
    raise exception 'UNIDADES_EMPTY' using errcode = '22023';
  end if;

  v_empresa_id := public.my_empresa_id();

  select c.id,
         coalesce(c.is_gestor, false)
         or coalesce(c.is_admin_local, false)
         or c.role in ('gestor', 'admin', 'admin_local', 'admin_global')
    into v_corretor_id, v_is_importador
  from public.corretores c
  where c.user_id = v_uid
    and c.ativo = true
  limit 1;

  if not public.is_root() and coalesce(v_is_importador, false) = false then
    raise exception 'IMPORT_FORBIDDEN' using errcode = '42501';
  end if;

  select e.empresa_id
    into v_emp_empresa_id
  from public.empreendimentos e
  where e.id = p_empreendimento_id;

  if v_emp_empresa_id is null then
    raise exception 'EMPREENDIMENTO_NOT_FOUND' using errcode = 'P0002';
  end if;

  if not public.is_root() and v_emp_empresa_id is distinct from v_empresa_id then
    raise exception 'TENANT_FORBIDDEN' using errcode = '42501';
  end if;

  if p_arquivo_id is not null then
    select exists (
      select 1
      from public.estoque_arquivos a
      where a.id = p_arquivo_id
        and a.empresa_id = v_emp_empresa_id
        and a.empreendimento_id = p_empreendimento_id
    ) into v_arquivo_ok;

    if not v_arquivo_ok then
      raise exception 'ARQUIVO_FORBIDDEN_OR_NOT_FOUND' using errcode = '42501';
    end if;
  end if;

  -- Inativa snapshots anteriores do empreendimento/empresa.
  update public.estoque_snapshots s
     set ativo = false,
         updated_at = now()
   where s.empresa_id = v_emp_empresa_id
     and s.empreendimento_id = p_empreendimento_id
     and s.ativo = true;

  insert into public.estoque_snapshots (
    empresa_id,
    empreendimento_id,
    arquivo_origem_id,
    fonte,
    data_referencia,
    data_processamento,
    status_processamento,
    confianca_extracao,
    ativo,
    validado,
    observacoes
  ) values (
    v_emp_empresa_id,
    p_empreendimento_id,
    p_arquivo_id,
    'parser_native_first',
    now(),
    now(),
    'processado',
    'media',
    true,
    false,
    concat(
      'Importação Mesa Cliente via parser',
      case when nullif(trim(coalesce(p_parser_nome, '')), '') is not null
        then concat(': ', trim(p_parser_nome))
        else ''
      end,
      '. Disponibilidade ainda não validada pelo espelho de vendas.'
    )
  ) returning id into v_snapshot_id;

  for v_item in select * from jsonb_array_elements(p_unidades)
  loop
    v_unidade := nullif(trim(coalesce(v_item->>'unidade', '')), '');
    v_valor := nullif(regexp_replace(coalesce(v_item->>'valor_tabela', ''), '[^0-9,.-]', '', 'g'), '')::numeric;

    if v_unidade is null then
      raise exception 'UNIDADE_INVALIDA: unidade obrigatoria' using errcode = '22023';
    end if;

    if v_valor is null or v_valor <= 0 then
      raise exception 'UNIDADE_INVALIDA: valor_tabela obrigatorio para unidade %', v_unidade using errcode = '22023';
    end if;

    insert into public.unidades_estoque (
      snapshot_id,
      empresa_id,
      empreendimento_id,
      torre,
      unidade,
      final,
      andar,
      metragem,
      dormitorios,
      suites,
      vagas_quantidade,
      valor_tabela,
      status_comercial,
      planta_tipo,
      observacoes,
      confianca_linha,
      extraido_em
    ) values (
      v_snapshot_id,
      v_emp_empresa_id,
      p_empreendimento_id,
      nullif(trim(coalesce(v_item->>'torre', '')), ''),
      v_unidade,
      nullif(trim(coalesce(v_item->>'final', '')), ''),
      nullif(regexp_replace(coalesce(v_item->>'andar', ''), '[^0-9-]', '', 'g'), '')::integer,
      nullif(regexp_replace(coalesce(v_item->>'metragem', ''), '[^0-9,.-]', '', 'g'), '')::numeric,
      nullif(regexp_replace(coalesce(v_item->>'dormitorios', ''), '[^0-9-]', '', 'g'), '')::integer,
      nullif(regexp_replace(coalesce(v_item->>'suites', ''), '[^0-9-]', '', 'g'), '')::integer,
      nullif(regexp_replace(coalesce(v_item->>'vagas_quantidade', ''), '[^0-9-]', '', 'g'), '')::integer,
      v_valor,
      'disponivel',
      nullif(trim(coalesce(v_item->>'planta_tipo', '')), ''),
      concat(
        'Disponibilidade ainda não validada pelo espelho de vendas.',
        case when v_item ? 'fluxo_original'
          then concat(' Fluxo original parser: ', left((v_item->'fluxo_original')::text, 3000))
          else ''
        end
      ),
      coalesce(nullif(trim(coalesce(v_item->>'confianca_linha', '')), '')::snapshot_confianca_tipo, 'media'),
      now()
    );

    v_count := v_count + 1;
  end loop;

  if p_arquivo_id is not null then
    update public.estoque_arquivos a
       set status_processamento = 'processado',
           confianca_extracao = 'media',
           processado_em = now(),
           observacoes = concat(
             coalesce(a.observacoes, ''),
             case when coalesce(a.observacoes, '') = '' then '' else E'\n' end,
             'Importado para Mesa Cliente via ', coalesce(nullif(trim(p_parser_nome), ''), 'parser_native_first'),
             '. Unidades: ', v_count::text,
             '. Disponibilidade ainda não validada pelo espelho de vendas.'
           ),
           updated_at = now()
     where a.id = p_arquivo_id
       and a.empresa_id = v_emp_empresa_id
       and a.empreendimento_id = p_empreendimento_id;
  end if;

  return query select v_snapshot_id, v_count, 'ok'::text;
end;
$$;

revoke all on function public.importar_unidades_mesa_parser(uuid, uuid, text, jsonb) from public;
grant execute on function public.importar_unidades_mesa_parser(uuid, uuid, text, jsonb) to authenticated;

comment on function public.importar_unidades_mesa_parser(uuid, uuid, text, jsonb) is
'Mesa Cliente: importa unidades extraídas pelo parser para snapshot ativo tenant-safe. Restrito a gestor/admin/root. Não valida espelho de vendas nesta etapa.';

commit;
