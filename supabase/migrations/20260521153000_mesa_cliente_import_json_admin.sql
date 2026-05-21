-- Mesa Cliente — Importação JSON administrativa segura
--
-- Objetivo:
--   Permitir importação de payload JSON canônico somente por admin/root,
--   reaproveitando a RPC oficial de importação de resultado do parser.
--
-- Segurança:
--   - Exige auth.uid().
--   - Valida empresa do usuário em corretores.
--   - Permite somente admin/admin_local/admin_global/root.
--   - Não permite gestor comum importar JSON administrativo.
--   - Não aceita empresa_id vindo do arquivo/payload.
--   - Sanitiza/allowlista os campos das unidades antes de chamar a RPC base.
--   - Remove payload bruto/raw e campos extras para reduzir risco de dado malicioso persistido.

create or replace function public.usuario_pode_importar_mesa_json_admin(
  p_empresa_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_user_empresa_id uuid;
  v_is_admin boolean := false;
begin
  if v_uid is null or p_empresa_id is null then
    return false;
  end if;

  if public.is_root() then
    return true;
  end if;

  select c.empresa_id,
         coalesce(c.is_admin_local, false)
         or c.role in ('admin','admin_local','admin_global')
    into v_user_empresa_id, v_is_admin
  from public.corretores c
  where c.user_id = v_uid
    and coalesce(c.ativo, true) = true
  limit 1;

  return v_user_empresa_id is not distinct from p_empresa_id
     and coalesce(v_is_admin, false) = true;
end;
$$;

revoke all on function public.usuario_pode_importar_mesa_json_admin(uuid) from public;
grant execute on function public.usuario_pode_importar_mesa_json_admin(uuid) to authenticated;

create or replace function public.importar_mesa_cliente_json_admin(
  p_empresa_id uuid,
  p_empreendimento_nome text,
  p_incorporadora text default null,
  p_bairro text default null,
  p_cidade text default null,
  p_nome_arquivo text default null,
  p_parser_nome text default 'manual_json_admin_import',
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
  v_item jsonb;
  v_unidades_sanitizadas jsonb := '[]'::jsonb;
  v_parser_nome text;
  v_count integer;
begin
  if auth.uid() is null then
    raise exception 'Usuário não autenticado';
  end if;

  if p_empresa_id is null then
    raise exception 'empresa_id obrigatório';
  end if;

  if public.usuario_pode_importar_mesa_json_admin(p_empresa_id) is distinct from true then
    raise exception 'Apenas administrador pode importar JSON administrativo da Mesa Cliente';
  end if;

  if nullif(trim(coalesce(p_empreendimento_nome, '')), '') is null then
    raise exception 'empreendimento_nome obrigatório';
  end if;

  if p_unidades is null or jsonb_typeof(p_unidades) <> 'array' then
    raise exception 'unidades deve ser um array JSON';
  end if;

  v_count := jsonb_array_length(p_unidades);

  if v_count = 0 then
    raise exception 'nenhuma unidade enviada no JSON administrativo';
  end if;

  if v_count > 500 then
    raise exception 'JSON administrativo excede o limite de 500 unidades por importação';
  end if;

  for v_item in select * from jsonb_array_elements(p_unidades)
  loop
    if jsonb_typeof(v_item) <> 'object' then
      raise exception 'Todas as unidades do JSON administrativo devem ser objetos';
    end if;

    v_unidades_sanitizadas := v_unidades_sanitizadas || jsonb_build_array(
      jsonb_strip_nulls(
        jsonb_build_object(
          'torre', nullif(left(regexp_replace(coalesce(v_item->>'torre', ''), '[<>]', '', 'g'), 120), ''),
          'unidade', nullif(left(regexp_replace(coalesce(v_item->>'unidade', v_item->>'apto', v_item->>'apartamento', ''), '[^0-9A-Za-z._/-]', '', 'g'), 30), ''),
          'final', nullif(left(regexp_replace(coalesce(v_item->>'final', ''), '[^0-9A-Za-z._/-]', '', 'g'), 20), ''),
          'andar', nullif(left(regexp_replace(coalesce(v_item->>'andar', v_item->>'pavimento', ''), '[^0-9-]', '', 'g'), 6), ''),
          'metragem', nullif(left(regexp_replace(replace(coalesce(v_item->>'metragem', v_item->>'area', v_item->>'area_m2', ''), ',', '.'), '[^0-9.-]', '', 'g'), 20), ''),
          'dormitorios', nullif(left(regexp_replace(coalesce(v_item->>'dormitorios', v_item->>'dorms', ''), '[^0-9-]', '', 'g'), 6), ''),
          'suites', nullif(left(regexp_replace(coalesce(v_item->>'suites', ''), '[^0-9-]', '', 'g'), 6), ''),
          'vagas_quantidade', nullif(left(regexp_replace(coalesce(v_item->>'vagas_quantidade', v_item->>'vagas', ''), '[^0-9-]', '', 'g'), 6), ''),
          'valor_tabela', nullif(left(regexp_replace(replace(coalesce(v_item->>'valor_tabela', v_item->>'valor_total', v_item->>'preco', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
          'status_comercial', lower(nullif(left(regexp_replace(coalesce(v_item->>'status_comercial', v_item->>'status', 'disponivel'), '[^0-9A-Za-z_ -]', '', 'g'), 30), '')),
          'planta_tipo', nullif(left(regexp_replace(coalesce(v_item->>'planta_tipo', v_item->>'planta', v_item->>'tipologia', ''), '[<>]', '', 'g'), 80), ''),
          'observacoes', nullif(left(regexp_replace(coalesce(v_item->>'observacoes', v_item->>'obs', ''), '[<>]', '', 'g'), 500), ''),
          'confianca_linha', lower(nullif(left(regexp_replace(coalesce(v_item->>'confianca_linha', v_item->>'confianca', 'alta'), '[^0-9A-Za-z_ -]', '', 'g'), 30), ''))
        )
      )
    );
  end loop;

  v_parser_nome := concat(
    'admin_json:',
    left(coalesce(nullif(trim(p_parser_nome), ''), 'manual_json_admin_import'), 120)
  );

  return query
  select *
  from public.importar_mesa_cliente_parser_resultado(
    p_empresa_id,
    p_empreendimento_nome,
    p_incorporadora,
    p_bairro,
    p_cidade,
    coalesce(nullif(trim(p_nome_arquivo), ''), 'payload-json-admin.json'),
    v_parser_nome,
    v_unidades_sanitizadas
  );
end;
$$;

revoke all on function public.importar_mesa_cliente_json_admin(uuid, text, text, text, text, text, text, jsonb) from public;
grant execute on function public.importar_mesa_cliente_json_admin(uuid, text, text, text, text, text, text, jsonb) to authenticated;
