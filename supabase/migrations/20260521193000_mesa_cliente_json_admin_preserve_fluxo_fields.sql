-- Mesa Cliente — JSON admin preserva campos financeiros do parser
-- Fase 8 / Chateau Jardin
--
-- Objetivo:
--   Corrigir a importação JSON administrativa para não perder campos financeiros
--   usados pela Mesa Cliente: sinal, complementos, mensais, intermediárias,
--   parcela única/chaves, financiamento principal e financiamento corrigido
--   informativo pela Tabela Price.
--
-- Segurança preservada:
--   - Continua exigindo auth.uid().
--   - Continua exigindo admin/root via usuario_pode_importar_mesa_json_admin().
--   - Continua ignorando empresa_id vindo do arquivo.
--   - Continua sanitizando/allowlistando os campos antes da RPC base.
--   - Continua sem service_role no frontend.
--
-- Regra de negócio Chateau Jardin:
--   - financiamento = Principal Financ. (set/29)
--   - financiamento_price_11_2029 = valor informativo com 1% a.m. Tabela Price
--   - meta_obra_pct = 45 quando informado pelo payload

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
  v_fluxo_payload jsonb;
  v_observacoes text;
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

    v_fluxo_payload := jsonb_strip_nulls(jsonb_build_object(
      'sinal_1', nullif(left(regexp_replace(replace(coalesce(v_item->>'sinal_1', v_item->>'ato', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'a4_each', nullif(left(regexp_replace(replace(coalesce(v_item->>'a4_each', v_item->>'complemento_each', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'mensal_each', nullif(left(regexp_replace(replace(coalesce(v_item->>'mensal_each', v_item->>'mensais_each', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'inter_each', nullif(left(regexp_replace(replace(coalesce(v_item->>'inter_each', v_item->>'intermediaria_each', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'chaves_each', nullif(left(regexp_replace(replace(coalesce(v_item->>'chaves_each', v_item->>'unica_each', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'financiamento', nullif(left(regexp_replace(replace(coalesce(v_item->>'financiamento', v_item->>'principal_financ_set_29', v_item->>'principal_financ_original_set_29', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'principal_financ_set_29', nullif(left(regexp_replace(replace(coalesce(v_item->>'principal_financ_set_29', v_item->>'principal_financ_original_set_29', v_item->>'financiamento', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'financiamento_price_11_2029', nullif(left(regexp_replace(replace(coalesce(v_item->>'financiamento_price_11_2029', v_item->>'financ_corrigido_original_11_2029', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'meta_obra_pct', nullif(left(regexp_replace(replace(coalesce(v_item->>'meta_obra_pct', ''), ',', '.'), '[^0-9.-]', '', 'g'), 10), ''),
      'valor_total', nullif(left(regexp_replace(replace(coalesce(v_item->>'valor_total', v_item->>'valor_tabela', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
      'mensal_qtd', nullif(left(regexp_replace(coalesce(v_item->>'mensal_qtd', ''), '[^0-9-]', '', 'g'), 6), ''),
      'inter_qtd', nullif(left(regexp_replace(coalesce(v_item->>'inter_qtd', ''), '[^0-9-]', '', 'g'), 6), ''),
      'comp_qtd', nullif(left(regexp_replace(coalesce(v_item->>'comp_qtd', ''), '[^0-9-]', '', 'g'), 6), ''),
      'ato_qtd', nullif(left(regexp_replace(coalesce(v_item->>'ato_qtd', ''), '[^0-9-]', '', 'g'), 6), ''),
      'unica_qtd', nullif(left(regexp_replace(coalesce(v_item->>'unica_qtd', ''), '[^0-9-]', '', 'g'), 6), ''),
      'financiamento_observacao', nullif(left(regexp_replace(coalesce(v_item->>'financiamento_observacao', ''), '[<>]', '', 'g'), 300), '')
    ));

    v_observacoes := nullif(left(regexp_replace(coalesce(v_item->>'observacoes', v_item->>'obs', ''), '[<>]', '', 'g'), 1200), '');

    if v_fluxo_payload <> '{}'::jsonb then
      v_observacoes := concat_ws(
        ' | ',
        v_observacoes,
        'Payload: ' || v_fluxo_payload::text
      );
    end if;

    v_unidades_sanitizadas := v_unidades_sanitizadas || jsonb_build_array(
      jsonb_strip_nulls(
        jsonb_build_object(
          'torre', nullif(left(regexp_replace(coalesce(v_item->>'torre', ''), '[<>]', '', 'g'), 120), ''),
          'unidade', nullif(left(regexp_replace(coalesce(v_item->>'unidade', v_item->>'apto', v_item->>'apartamento', ''), '[^0-9A-Za-z._/-]', '', 'g'), 30), ''),
          'final', nullif(left(regexp_replace(coalesce(v_item->>'final', v_item->>'prumada', ''), '[^0-9A-Za-z._/-]', '', 'g'), 20), ''),
          'andar', nullif(left(regexp_replace(coalesce(v_item->>'andar', v_item->>'pavimento', ''), '[^0-9-]', '', 'g'), 6), ''),
          'metragem', nullif(left(regexp_replace(replace(coalesce(v_item->>'metragem', v_item->>'area', v_item->>'area_m2', ''), ',', '.'), '[^0-9.-]', '', 'g'), 20), ''),
          'dormitorios', nullif(left(regexp_replace(coalesce(v_item->>'dormitorios', v_item->>'dorms', ''), '[^0-9-]', '', 'g'), 6), ''),
          'suites', nullif(left(regexp_replace(coalesce(v_item->>'suites', ''), '[^0-9-]', '', 'g'), 6), ''),
          'vagas_quantidade', nullif(left(regexp_replace(coalesce(v_item->>'vagas_quantidade', v_item->>'vagas', ''), '[^0-9-]', '', 'g'), 6), ''),
          'valor_tabela', nullif(left(regexp_replace(replace(coalesce(v_item->>'valor_tabela', v_item->>'valor_total', v_item->>'preco', ''), ',', '.'), '[^0-9.-]', '', 'g'), 30), ''),
          'status_comercial', lower(nullif(left(regexp_replace(coalesce(v_item->>'status_comercial', v_item->>'status', 'disponivel'), '[^0-9A-Za-z_ -]', '', 'g'), 30), '')),
          'planta_tipo', nullif(left(regexp_replace(coalesce(v_item->>'planta_tipo', v_item->>'planta', v_item->>'tipologia', ''), '[<>]', '', 'g'), 80), ''),
          'observacoes', v_observacoes,
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
