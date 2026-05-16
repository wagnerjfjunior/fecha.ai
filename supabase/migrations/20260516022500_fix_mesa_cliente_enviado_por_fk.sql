-- FECH.AI — Mesa Cliente
-- Correção: estoque_arquivos.enviado_por referencia public.corretores.id, não auth.users.id.
--
-- Contexto do erro observado na preview:
--   409 /rest/v1/rpc/importar_mesa_cliente_parser_resultado
--   violates foreign key constraint estoque_arquivos_enviado_por_fkey
--
-- Causa:
--   A RPC gravava auth.uid() em estoque_arquivos.enviado_por.
--   Porém a coluna enviado_por possui FK para public.corretores.id.
--
-- Decisão arquitetural:
--   - Manter auth.uid() como identidade de sessão.
--   - Resolver c.id a partir de corretores.user_id = auth.uid().
--   - Gravar corretores.id em estoque_arquivos.enviado_por.
--   - Para root/admin_global sem linha em corretores, permitir enviado_por null, pois a coluna é nullable.
--   - Preservar isolamento por empresa e RPC security definer.

create or replace function public.importar_mesa_cliente_parser_resultado(
  p_empresa_id uuid,
  p_empreendimento_nome text,
  p_incorporadora text default null,
  p_bairro text default null,
  p_cidade text default null,
  p_nome_arquivo text default null,
  p_parser_nome text default 'native_first',
  p_unidades jsonb default '[]'::jsonb
)
returns table(
  empreendimento_id uuid,
  arquivo_id uuid,
  snapshot_id uuid,
  unidades_importadas integer,
  status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_user_empresa_id uuid;
  v_corretor_id uuid;
  v_can_import boolean := false;
  v_empreendimento_id uuid;
  v_arquivo_id uuid;
  v_snapshot_id uuid;
  v_item jsonb;
  v_count integer := 0;
  v_unidade text;
  v_valor numeric;
  v_status text;
begin
  if v_uid is null then
    raise exception 'Usuário não autenticado';
  end if;

  if p_empresa_id is null then
    raise exception 'empresa_id obrigatório';
  end if;

  if nullif(trim(coalesce(p_empreendimento_nome, '')), '') is null then
    raise exception 'empreendimento_nome obrigatório';
  end if;

  if p_unidades is null or jsonb_typeof(p_unidades) <> 'array' then
    raise exception 'unidades deve ser um array JSON';
  end if;

  if jsonb_array_length(p_unidades) = 0 then
    raise exception 'nenhuma unidade enviada pelo parser';
  end if;

  select c.id,
         c.empresa_id,
         coalesce(c.is_gestor, false)
         or coalesce(c.is_admin_local, false)
         or c.role in ('gestor','admin','admin_local','admin_global')
    into v_corretor_id, v_user_empresa_id, v_can_import
  from public.corretores c
  where c.user_id = v_uid
    and coalesce(c.ativo, true) = true
  limit 1;

  if not public.is_root() and v_user_empresa_id is distinct from p_empresa_id then
    raise exception 'Acesso negado à empresa informada';
  end if;

  if not public.is_root() and coalesce(v_can_import, false) = false then
    raise exception 'Apenas gestor ou administrador pode importar tabela comercial';
  end if;

  select e.id
    into v_empreendimento_id
  from public.empreendimentos e
  where e.empresa_id = p_empresa_id
    and lower(trim(e.nome)) = lower(trim(p_empreendimento_nome))
  order by e.created_at desc
  limit 1;

  if v_empreendimento_id is null then
    insert into public.empreendimentos (
      empresa_id,
      nome,
      incorporadora,
      bairro,
      cidade,
      status
    ) values (
      p_empresa_id,
      trim(p_empreendimento_nome),
      nullif(trim(coalesce(p_incorporadora, '')), ''),
      nullif(trim(coalesce(p_bairro, '')), ''),
      nullif(trim(coalesce(p_cidade, '')), ''),
      'ativo'
    ) returning id into v_empreendimento_id;
  else
    update public.empreendimentos e
       set incorporadora = coalesce(nullif(trim(coalesce(p_incorporadora, '')), ''), e.incorporadora),
           bairro = coalesce(nullif(trim(coalesce(p_bairro, '')), ''), e.bairro),
           cidade = coalesce(nullif(trim(coalesce(p_cidade, '')), ''), e.cidade),
           status = 'ativo',
           updated_at = now()
     where e.id = v_empreendimento_id;
  end if;

  insert into public.estoque_arquivos (
    empresa_id,
    empreendimento_id,
    enviado_por,
    nome_arquivo,
    tipo_arquivo,
    status_processamento,
    confianca_extracao,
    data_referencia,
    processado_em,
    observacoes
  ) values (
    p_empresa_id,
    v_empreendimento_id,
    v_corretor_id,
    coalesce(nullif(trim(p_nome_arquivo), ''), concat('Importação parser ', to_char(now(), 'YYYY-MM-DD HH24:MI:SS'))),
    'tabela_trabalho',
    'processado',
    'media',
    now(),
    now(),
    concat('Importado via Mesa Cliente parser: ', coalesce(nullif(trim(p_parser_nome), ''), 'native_first'), '. auth_user_id=', v_uid::text)
  ) returning id into v_arquivo_id;

  update public.estoque_snapshots s
     set ativo = false,
         updated_at = now()
   where s.empresa_id = p_empresa_id
     and s.empreendimento_id = v_empreendimento_id
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
    p_empresa_id,
    v_empreendimento_id,
    v_arquivo_id,
    coalesce(nullif(trim(p_parser_nome), ''), 'native_first'),
    now(),
    now(),
    'processado',
    'media',
    true,
    false,
    'Snapshot criado a partir do resultado do parser. Disponibilidade ainda não validada pelo espelho de vendas.'
  ) returning id into v_snapshot_id;

  for v_item in select * from jsonb_array_elements(p_unidades)
  loop
    v_unidade := nullif(trim(coalesce(v_item->>'unidade', v_item->>'apto', v_item->>'apartamento', '')), '');
    v_valor := nullif(regexp_replace(replace(coalesce(v_item->>'valor_tabela', v_item->>'valor_total', v_item->>'preco', ''), ',', '.'), '[^0-9.-]', '', 'g'), '')::numeric;
    v_status := lower(nullif(trim(coalesce(v_item->>'status_comercial', v_item->>'status', 'disponivel')), ''));

    if v_unidade is null then
      raise exception 'Unidade sem identificador no payload do parser: %', v_item::text;
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
      p_empresa_id,
      v_empreendimento_id,
      nullif(trim(coalesce(v_item->>'torre', '')), ''),
      v_unidade,
      nullif(trim(coalesce(v_item->>'final', '')), ''),
      nullif(regexp_replace(coalesce(v_item->>'andar', ''), '[^0-9-]', '', 'g'), '')::integer,
      nullif(regexp_replace(replace(coalesce(v_item->>'metragem', v_item->>'area', v_item->>'area_m2', ''), ',', '.'), '[^0-9.-]', '', 'g'), '')::numeric,
      nullif(regexp_replace(coalesce(v_item->>'dormitorios', v_item->>'dorms', ''), '[^0-9-]', '', 'g'), '')::integer,
      nullif(regexp_replace(coalesce(v_item->>'suites', ''), '[^0-9-]', '', 'g'), '')::integer,
      nullif(regexp_replace(coalesce(v_item->>'vagas_quantidade', v_item->>'vagas', ''), '[^0-9-]', '', 'g'), '')::integer,
      v_valor,
      case
        when v_status in ('vendida','reservada','bloqueada','proposta','indisponivel','disponivel') then v_status::unidade_status_comercial
        else 'disponivel'::unidade_status_comercial
      end,
      nullif(trim(coalesce(v_item->>'planta_tipo', v_item->>'planta', '')), ''),
      concat(
        'Importado pelo parser. Disponibilidade ainda não validada pelo espelho de vendas. Payload: ',
        left(v_item::text, 2500)
      ),
      coalesce(nullif(trim(coalesce(v_item->>'confianca_linha', '')), '')::snapshot_confianca_tipo, 'media'),
      now()
    );

    v_count := v_count + 1;
  end loop;

  return query select v_empreendimento_id, v_arquivo_id, v_snapshot_id, v_count, 'ok'::text;
end;
$$;

revoke all on function public.importar_mesa_cliente_parser_resultado(uuid, text, text, text, text, text, text, jsonb) from public;
grant execute on function public.importar_mesa_cliente_parser_resultado(uuid, text, text, text, text, text, text, jsonb) to authenticated;

create or replace function public.registrar_upload_arquivo_mesa(
  p_empresa_id uuid,
  p_empreendimento_id uuid,
  p_tipo_arquivo text,
  p_nome_arquivo text,
  p_storage_path text default null,
  p_observacoes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_usuario_id uuid := auth.uid();
  v_corretor_id uuid;
  v_usuario_nome text;
  v_user_empresa_id uuid;
  v_emp_empresa_id uuid;
begin
  if v_usuario_id is null then
    raise exception 'Usuário não autenticado';
  end if;

  select c.id, c.nome, c.empresa_id
    into v_corretor_id, v_usuario_nome, v_user_empresa_id
  from public.corretores c
  where c.user_id = v_usuario_id
    and coalesce(c.ativo, true) = true
  limit 1;

  select e.empresa_id
    into v_emp_empresa_id
  from public.empreendimentos e
  where e.id = p_empreendimento_id
    and e.status = 'ativo'
  limit 1;

  if v_emp_empresa_id is null then
    raise exception 'Empreendimento não encontrado ou inativo';
  end if;

  if not public.is_root() and (v_user_empresa_id is distinct from p_empresa_id or v_emp_empresa_id is distinct from p_empresa_id) then
    raise exception 'Acesso negado à empresa/empreendimento informado';
  end if;

  insert into public.estoque_arquivos (
    empresa_id,
    empreendimento_id,
    enviado_por,
    nome_arquivo,
    tipo_arquivo,
    storage_path,
    status_processamento,
    data_referencia,
    observacoes
  ) values (
    p_empresa_id,
    p_empreendimento_id,
    v_corretor_id,
    p_nome_arquivo,
    p_tipo_arquivo,
    p_storage_path,
    'pendente',
    now(),
    concat(coalesce(p_observacoes, ''), case when coalesce(p_observacoes, '') = '' then '' else E'\n' end, 'auth_user_id=', v_usuario_id::text)
  ) returning id into v_id;

  return v_id;
end;
$$;

revoke all on function public.registrar_upload_arquivo_mesa(uuid, uuid, text, text, text, text) from public;
grant execute on function public.registrar_upload_arquivo_mesa(uuid, uuid, text, text, text, text) to authenticated;

create or replace function public.get_empreendimentos_mesa(p_empresa_id uuid)
returns table(
  id uuid,
  nome text,
  incorporadora text,
  bairro text,
  cidade text,
  tabela_status text,
  tabela_data timestamptz,
  tabela_tipo text,
  tabela_enviado_por text,
  tabela_dias_atras integer,
  espelho_status text,
  espelho_data timestamptz,
  espelho_enviado_por text,
  espelho_dias_atras integer,
  pode_abrir_mesa boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_empresa_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  select c.empresa_id
    into v_user_empresa_id
  from public.corretores c
  where c.user_id = auth.uid()
    and coalesce(c.ativo, true) = true
  limit 1;

  if not public.is_root() and v_user_empresa_id is distinct from p_empresa_id then
    raise exception 'Acesso negado à empresa informada';
  end if;

  return query
  with tabelas as (
    select distinct on (ea.empreendimento_id)
      ea.empreendimento_id,
      ea.data_referencia,
      ea.tipo_arquivo,
      c.nome as enviado_por_nome,
      extract(day from now() - ea.data_referencia)::int as dias_atras
    from public.estoque_arquivos ea
    left join public.corretores c on c.id = ea.enviado_por
    where ea.empresa_id = p_empresa_id
      and ea.tipo_arquivo in ('tabela_trabalho','tabela_oficial')
      and ea.status_processamento = 'processado'
    order by ea.empreendimento_id, ea.data_referencia desc nulls last, ea.created_at desc
  ),
  espelhos as (
    select distinct on (ea.empreendimento_id)
      ea.empreendimento_id,
      ea.data_referencia,
      c.nome as enviado_por_nome,
      extract(day from now() - ea.data_referencia)::int as dias_atras
    from public.estoque_arquivos ea
    left join public.corretores c on c.id = ea.enviado_por
    where ea.empresa_id = p_empresa_id
      and ea.tipo_arquivo = 'espelho'
      and ea.status_processamento = 'processado'
    order by ea.empreendimento_id, ea.data_referencia desc nulls last, ea.created_at desc
  )
  select
    e.id,
    e.nome,
    e.incorporadora,
    e.bairro,
    e.cidade,
    case when t.dias_atras is null then 'red' when t.dias_atras > 45 then 'red' when t.dias_atras > 35 then 'yellow' else 'ok' end as tabela_status,
    t.data_referencia as tabela_data,
    case t.tipo_arquivo when 'tabela_oficial' then 'oficial' when 'tabela_trabalho' then 'trabalho' else null end as tabela_tipo,
    t.enviado_por_nome as tabela_enviado_por,
    t.dias_atras as tabela_dias_atras,
    case when es.dias_atras is null then 'red' when es.dias_atras > 2 then 'red' when es.dias_atras = 1 then 'yellow' else 'ok' end as espelho_status,
    es.data_referencia as espelho_data,
    es.enviado_por_nome as espelho_enviado_por,
    es.dias_atras as espelho_dias_atras,
    (t.dias_atras is not null and t.dias_atras <= 45) as pode_abrir_mesa
  from public.empreendimentos e
  inner join tabelas t on t.empreendimento_id = e.id
  left join espelhos es on es.empreendimento_id = e.id
  where e.empresa_id = p_empresa_id
    and e.status = 'ativo'
  order by e.nome;
end;
$$;

revoke all on function public.get_empreendimentos_mesa(uuid) from public;
grant execute on function public.get_empreendimentos_mesa(uuid) to authenticated;
