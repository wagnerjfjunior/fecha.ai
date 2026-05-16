-- FECH.AI — Mesa Cliente
-- Hardening da RPC de disponibilidade oficial
--
-- Princípios DevSecOps aplicados:
--   - Sem tenant hardcoded.
--   - Sem corretor/auditoria falsificada.
--   - Sem confiar em empresa_id vindo do frontend.
--   - Tenant sempre resolvido pelo banco a partir do empreendimento e do usuário autenticado.
--   - Usuário comum precisa existir em corretores.
--   - Root/admin_global sem registro em corretores não é mascarado como outro corretor.
--   - Campos de auditoria FK para corretores.id ficam NULL quando não houver corretor local válido.
--   - auth.uid() técnico fica registrado em observações.
--   - RPC SECURITY DEFINER com search_path fixo.
--   - Execute liberado somente para authenticated.

begin;

create or replace function public.importar_mesa_cliente_disponibilidade_oficial(
  p_empreendimento_id uuid,
  p_nome_arquivo text default null,
  p_parser_nome text default 'native_first',
  p_unidades jsonb default '[]'::jsonb
)
returns table(
  empreendimento_id uuid,
  arquivo_id uuid,
  snapshot_id uuid,
  disponiveis_oficial integer,
  unidades_marcadas_disponiveis integer,
  unidades_marcadas_indisponiveis integer,
  status text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_corretor_id uuid;
  v_user_empresa_id uuid;
  v_emp_empresa_id uuid;
  v_user_role text;
  v_can_import boolean := false;
  v_is_root boolean := false;
  v_snapshot_id uuid;
  v_arquivo_id uuid;
  v_disponiveis integer := 0;
  v_marcadas_disponiveis integer := 0;
  v_marcadas_indisponiveis integer := 0;
  v_nome_arquivo text;
  v_parser_nome text;
  v_audit_actor text;
begin
  if v_uid is null then
    raise exception 'AUTH_REQUIRED' using errcode = '28000';
  end if;

  v_is_root := coalesce(public.is_root(), false);

  if p_empreendimento_id is null then
    raise exception 'EMPREENDIMENTO_REQUIRED' using errcode = '22023';
  end if;

  if p_unidades is null or jsonb_typeof(p_unidades) <> 'array' then
    raise exception 'UNIDADES_ARRAY_REQUIRED' using errcode = '22023';
  end if;

  if jsonb_array_length(p_unidades) = 0 then
    raise exception 'UNIDADES_EMPTY' using errcode = '22023';
  end if;

  v_nome_arquivo := left(coalesce(nullif(trim(p_nome_arquivo), ''), concat('Disponibilidade oficial ', to_char(now(), 'YYYY-MM-DD HH24:MI:SS'))), 255);
  v_parser_nome := left(coalesce(nullif(trim(p_parser_nome), ''), 'native_first'), 120);

  select e.empresa_id
    into v_emp_empresa_id
  from public.empreendimentos e
  where e.id = p_empreendimento_id
    and e.status = 'ativo'
  limit 1;

  if v_emp_empresa_id is null then
    raise exception 'EMPREENDIMENTO_NOT_FOUND' using errcode = 'P0002';
  end if;

  select c.id,
         c.empresa_id,
         c.role,
         coalesce(c.is_gestor, false)
         or coalesce(c.is_admin_local, false)
         or c.role in ('gestor','admin','admin_local','admin_global')
    into v_corretor_id, v_user_empresa_id, v_user_role, v_can_import
  from public.corretores c
  where c.user_id = v_uid
    and coalesce(c.ativo, true) = true
  order by c.created_at desc nulls last
  limit 1;

  if not v_is_root and v_corretor_id is null then
    raise exception 'CORRETOR_NOT_FOUND' using errcode = '42501';
  end if;

  if not v_is_root and v_user_empresa_id is distinct from v_emp_empresa_id then
    raise exception 'TENANT_FORBIDDEN' using errcode = '42501';
  end if;

  if not v_is_root and coalesce(v_can_import, false) = false then
    raise exception 'IMPORT_FORBIDDEN' using errcode = '42501';
  end if;

  if v_is_root and v_corretor_id is not null and v_user_empresa_id is not null and v_user_empresa_id is distinct from v_emp_empresa_id then
    -- Root autenticado em outro contexto de empresa não deve gerar FK de corretor de tenant diferente.
    v_corretor_id := null;
  end if;

  v_audit_actor := case
    when v_is_root then concat('root_auth_uid=', v_uid::text)
    when v_corretor_id is not null then concat('corretor_id=', v_corretor_id::text, '; auth_uid=', v_uid::text, '; role=', coalesce(v_user_role, ''))
    else concat('auth_uid=', v_uid::text)
  end;

  select s.id
    into v_snapshot_id
  from public.estoque_snapshots s
  where s.empresa_id = v_emp_empresa_id
    and s.empreendimento_id = p_empreendimento_id
    and s.ativo = true
    and s.status_processamento in ('processado','validado')
  order by s.data_referencia desc nulls last,
           s.data_processamento desc nulls last,
           s.created_at desc
  limit 1;

  if v_snapshot_id is null then
    raise exception 'SNAPSHOT_COMERCIAL_NOT_FOUND' using errcode = 'P0002';
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
    v_emp_empresa_id,
    p_empreendimento_id,
    v_corretor_id,
    v_nome_arquivo,
    'espelho',
    'processado',
    'media',
    now(),
    now(),
    concat('Disponibilidade importada pela tabela oficial. Parser: ', v_parser_nome, '. Actor: ', v_audit_actor)
  ) returning id into v_arquivo_id;

  create temporary table tmp_mesa_disponiveis(
    unidade text primary key
  ) on commit drop;

  insert into tmp_mesa_disponiveis(unidade)
  select distinct nullif(trim(coalesce(x.item->>'unidade', x.item->>'apto', x.item->>'apartamento', '')), '')
  from jsonb_array_elements(p_unidades) as x(item)
  where nullif(trim(coalesce(x.item->>'unidade', x.item->>'apto', x.item->>'apartamento', '')), '') is not null;

  select count(*) into v_disponiveis from tmp_mesa_disponiveis;

  if v_disponiveis = 0 then
    raise exception 'UNIDADES_EMPTY_AFTER_NORMALIZATION' using errcode = '22023';
  end if;

  update public.unidades_estoque u
     set status_comercial = 'disponivel'::public.unidade_status_comercial,
         observacoes = concat_ws(' | ', nullif(u.observacoes, ''), 'Confirmada como disponível pela tabela oficial em ' || to_char(now(), 'DD/MM/YYYY HH24:MI')),
         updated_at = now()
   where u.snapshot_id = v_snapshot_id
     and u.empresa_id = v_emp_empresa_id
     and u.empreendimento_id = p_empreendimento_id
     and exists (select 1 from tmp_mesa_disponiveis d where d.unidade = u.unidade);

  get diagnostics v_marcadas_disponiveis = row_count;

  update public.unidades_estoque u
     set status_comercial = 'indisponivel'::public.unidade_status_comercial,
         observacoes = concat_ws(' | ', nullif(u.observacoes, ''), 'Não consta na tabela oficial de disponibilidade em ' || to_char(now(), 'DD/MM/YYYY HH24:MI')),
         updated_at = now()
   where u.snapshot_id = v_snapshot_id
     and u.empresa_id = v_emp_empresa_id
     and u.empreendimento_id = p_empreendimento_id
     and not exists (select 1 from tmp_mesa_disponiveis d where d.unidade = u.unidade);

  get diagnostics v_marcadas_indisponiveis = row_count;

  update public.estoque_snapshots s
     set validado = true,
         validado_por = v_corretor_id,
         validado_em = now(),
         status_processamento = 'validado',
         observacoes = concat_ws(' | ', nullif(s.observacoes, ''), 'Disponibilidade oficial aplicada pelo arquivo ' || v_nome_arquivo || '. Actor: ' || v_audit_actor),
         updated_at = now()
   where s.id = v_snapshot_id
     and s.empresa_id = v_emp_empresa_id
     and s.empreendimento_id = p_empreendimento_id;

  return query
  select
    p_empreendimento_id,
    v_arquivo_id,
    v_snapshot_id,
    v_disponiveis,
    v_marcadas_disponiveis,
    v_marcadas_indisponiveis,
    'ok'::text;
end;
$$;

revoke all on function public.importar_mesa_cliente_disponibilidade_oficial(uuid, text, text, jsonb) from public;
grant execute on function public.importar_mesa_cliente_disponibilidade_oficial(uuid, text, text, jsonb) to authenticated;

comment on function public.importar_mesa_cliente_disponibilidade_oficial(uuid, text, text, jsonb) is
'Mesa Cliente: aplica disponibilidade oficial da tabela Tegra sobre snapshot comercial ativo. Hardened multi-tenant: tenant resolvido no banco, sem auditoria falsificada e sem dados hardcoded.';

commit;
