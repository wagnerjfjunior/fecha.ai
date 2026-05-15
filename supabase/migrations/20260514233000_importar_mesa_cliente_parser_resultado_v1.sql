-- Mesa Cliente — Importação segura do resultado do parser
--
-- Objetivo:
--   Receber o JSON canônico do parser e popular:
--   - empreendimentos
--   - estoque_arquivos
--   - estoque_snapshots
--   - unidades_estoque
--
-- Segurança:
--   - Exige auth.uid().
--   - Valida empresa do usuário em corretores.
--   - Apenas gestor/admin/root pode importar.
--   - Não expõe escrita direta nas tabelas.
--   - Não usa service_role no frontend.
--   - Não depende da tabela inexistente perfis.

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

  select c.empresa_id,
         coalesce(c.is_gestor, false)
         or coalesce(c.is_admin_local, false)
         or c.role in ('gestor','admin','admin_local','admin_global')
    into v_user_empresa_id, v_can_import
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
    v_uid,
    coalesce(nullif(trim(p_nome_arquivo), ''), concat('Importação parser ', to_char(now(), 'YYYY-MM-DD HH24:MI:SS'))),
    'tabela_trabalho',
    'processado',
    'media',
    now(),
    now(),
    concat('Importado via Mesa Cliente parser: ', coalesce(nullif(trim(p_parser_nome), ''), 'native_first'))
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
