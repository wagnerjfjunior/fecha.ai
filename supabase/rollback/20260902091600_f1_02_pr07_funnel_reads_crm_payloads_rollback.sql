-- FECH.AI — F1-02 / PR-07 rollback
-- Restores the exact pre-PR-07 function definitions/grants and removes only
-- PR-07-owned idempotency control metadata.
-- This rollback reopens the PR-07 security defects and does NOT preserve Security Go.
-- Existing leads, lists, logs, funnel history, lots and stages are preserved.

BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '120s';

SELECT pg_catalog.pg_advisory_xact_lock(20260902091600);

DO $preflight$
BEGIN
  IF pg_catalog.to_regclass('public.importar_leads_batch_idempotency') IS NULL THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback preflight failed: idempotency table absent';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.logs'::pg_catalog.regclass
      AND c.conname = 'logs_sessao_id_unique'
      AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'UNIQUE (sessao_id)'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback preflight failed: logs_sessao_id_unique drift';
  END IF;
END
$preflight$;

-- Exact pre-PR-07 pg_get_functiondef() snapshots follow.
CREATE OR REPLACE FUNCTION public.listar_funil_estagios()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN (
    SELECT jsonb_agg(
      jsonb_build_object('id', id, 'nome', nome, 'icone', icone, 'cor', cor, 'ordem', ordem)
      ORDER BY ordem ASC
    )
    FROM funil_estagios
  );
END;
$function$

;
CREATE OR REPLACE FUNCTION public.importar_leads_batch(p_lista_id uuid, p_leads jsonb, p_sessao_id text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_empresa_id  uuid;
  v_user_email  text;
  v_inserted    int := 0;
  v_invalidos   int := 0;
  v_skipped     int := 0;
  v_lead        jsonb;
BEGIN
  -- Rejeitar chamadas não autenticadas explicitamente
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('error', 'Autenticação obrigatória');
  END IF;

  -- Resolver empresa pelo corretor autenticado
  SELECT c.empresa_id INTO v_empresa_id
  FROM public.corretores c
  WHERE c.user_id = auth.uid()
    AND coalesce(c.ativo, true) = true
  LIMIT 1;

  IF v_empresa_id IS NULL THEN
    RETURN jsonb_build_object('error', 'Empresa não encontrada');
  END IF;

  -- Email para log
  SELECT email INTO v_user_email
  FROM auth.users WHERE id = auth.uid();

  -- Verificar que a lista pertence à empresa
  IF NOT EXISTS (
    SELECT 1 FROM public.listas li
    WHERE li.id = p_lista_id AND li.empresa_id = v_empresa_id
  ) THEN
    RETURN jsonb_build_object('error', 'Lista não encontrada ou sem permissão');
  END IF;

  -- Deduplicação de sessão
  IF p_sessao_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM public.logs
      WHERE acao = 'import_batch'
        AND detalhes->>'sessao_id' = p_sessao_id
    ) THEN
      RETURN jsonb_build_object(
        'validos', 0, 'invalidos', 0, 'duplicados', 0, 'sessao_duplicada', true
      );
    END IF;

    INSERT INTO public.logs (acao, usuario_email, empresa_id, detalhes)
    VALUES (
      'import_batch', v_user_email, v_empresa_id,
      jsonb_build_object('sessao_id', p_sessao_id, 'lista_id', p_lista_id)
    );
  END IF;

  -- Processar leads
  FOR v_lead IN SELECT * FROM jsonb_array_elements(p_leads)
  LOOP
    DECLARE
      v_e164 text := trim(v_lead->>'telefone_e164');
    BEGIN
      IF v_e164 IS NULL OR v_e164 = '' THEN
        v_invalidos := v_invalidos + 1;
        CONTINUE;
      END IF;

      IF EXISTS (
        SELECT 1 FROM public.leads l
        WHERE l.empresa_id = v_empresa_id AND l.telefone_e164 = v_e164
      ) THEN
        v_skipped := v_skipped + 1;
        CONTINUE;
      END IF;

      INSERT INTO public.leads (
        empresa_id, lista_id,
        nome, email, endereco, zona,
        telefone_origem_1, telefone_origem_2,
        telefone_escolhido, telefone_e164,
        tipo_telefone, pais_telefone,
        ligar, whatsapp, fornecedor, status
      ) VALUES (
        v_empresa_id, p_lista_id,
        v_lead->>'nome', v_lead->>'email', v_lead->>'endereco',
        NULLIF(trim(v_lead->>'zona'), ''),
        v_lead->>'telefone_origem_1', v_lead->>'telefone_origem_2',
        v_lead->>'telefone_escolhido', v_e164,
        v_lead->>'tipo_telefone', v_lead->>'pais_telefone',
        v_lead->>'ligar', v_lead->>'whatsapp', v_lead->>'fornecedor',
        'disponivel'
      );

      v_inserted := v_inserted + 1;
    END;
  END LOOP;

  UPDATE public.listas SET
    leads_validos   = leads_validos   + v_inserted,
    leads_invalidos = leads_invalidos + v_invalidos
  WHERE id = p_lista_id;

  RETURN jsonb_build_object(
    'validos', v_inserted, 'invalidos', v_invalidos, 'duplicados', v_skipped
  );

EXCEPTION
  WHEN others THEN
    RETURN jsonb_build_object('error', 'Erro interno: ' || SQLERRM);
END;
$function$

;
CREATE OR REPLACE FUNCTION public.registrar_feedback(p_lead_id uuid, p_feedback text, p_observacao text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_corretor_id         uuid;
  v_empresa_id          uuid;
  v_lote_id             uuid;
  v_count_fb            int;
  v_lote_fechado        boolean := false;
  v_tem_phone           boolean;
  v_tem_email           boolean;
  v_tentativas_caiu     int;
  v_novo_estagio        uuid;
  v_obs_auto            text;
  v_tecnico_pendente    boolean := false;
  v_acao_sugerida       text    := null;
  v_em_conversa_id      uuid;
  v_visita_ag_id        uuid;
  v_perdido_sem_id      uuid;
  v_perdido_com_id      uuid;
  v_feedback_tipo       public.lead_feedback_tipo;
  v_status_comercial    public.lead_status_comercial;
  v_iniciado_em         timestamptz;
  v_tempo               integer;
begin
  select c.id, c.empresa_id
  into v_corretor_id, v_empresa_id
  from public.corretores c
  where c.user_id = auth.uid()
  limit 1;

  if v_corretor_id is null then
    return jsonb_build_object('error', 'Corretor não encontrado');
  end if;

  select l.lote_id,
         l.tentativas_caiu,
         l.atendimento_iniciado_em,
         (l.telefone_e164 is not null and l.telefone_e164 <> '') as tem_phone,
         (l.email is not null and trim(l.email) <> '') as tem_email
  into v_lote_id, v_tentativas_caiu, v_iniciado_em, v_tem_phone, v_tem_email
  from public.leads l
  where l.id = p_lead_id
    and l.corretor_id = v_corretor_id
    and l.empresa_id = v_empresa_id
  limit 1;

  if v_lote_id is null then
    return jsonb_build_object('error', 'Lead não encontrado ou sem permissão');
  end if;

  if v_iniciado_em is not null then
    v_tempo := extract(epoch from (now() - v_iniciado_em))::int;
  else
    v_tempo := null;
  end if;

  select fe.id into v_em_conversa_id
  from public.funil_estagios fe
  where fe.codigo_estagio = 'em_conversa'
    and fe.empresa_id = v_empresa_id
  limit 1;

  select fe.id into v_visita_ag_id
  from public.funil_estagios fe
  where fe.codigo_estagio = 'visita_agendada'
    and fe.empresa_id = v_empresa_id
  limit 1;

  select fe.id into v_perdido_sem_id
  from public.funil_estagios fe
  where fe.codigo_estagio = 'perdido_sem_contato'
    and fe.empresa_id = v_empresa_id
  limit 1;

  select fe.id into v_perdido_com_id
  from public.funil_estagios fe
  where fe.codigo_estagio = 'perdido_com_contato'
    and fe.empresa_id = v_empresa_id
  limit 1;

  begin
    v_feedback_tipo := p_feedback::public.lead_feedback_tipo;
  exception when invalid_text_representation then
    v_feedback_tipo := null;
  end;

  v_status_comercial :=
    case
      when p_feedback in ('agendado_visita','enviado_informacoes','retornar_depois','em_conversa')
        then 'contato_efetivo'::public.lead_status_comercial
      when p_feedback in ('sem_interesse','lead_ja_atendido')
        then 'perdido_com_contato'::public.lead_status_comercial
      when p_feedback in ('nao_responde','nao_responde_email','numero_errado',
                          'caixa_postal','nao_toca','chamada_caiu','whatsapp_invalido')
        then 'perdido_sem_contato'::public.lead_status_comercial
      when p_feedback = 'invalido' then 'invalido'::public.lead_status_comercial
      else 'sem_status'::public.lead_status_comercial
    end;

  if p_feedback = 'chamada_caiu' then
    v_tentativas_caiu := coalesce(v_tentativas_caiu, 0) + 1;

    if v_tentativas_caiu < 3 then
      v_tecnico_pendente := true;
      v_acao_sugerida := 'ligar';

      update public.leads set
        feedback = 'chamada_caiu',
        observacao_corretor = p_observacao,
        data_feedback = now(),
        atendimento_finalizado_em = now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = now(),
        tentativas_caiu = v_tentativas_caiu,
        tecnico_pendente = true,
        ultima_falha_tecnica = 'chamada_caiu',
        ultima_falha_em = now(),
        acao_sugerida = 'ligar',
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      where id = p_lead_id
        and corretor_id = v_corretor_id
        and empresa_id = v_empresa_id;
    else
      v_tecnico_pendente := false;
      v_novo_estagio := v_perdido_sem_id;
      v_obs_auto := 'Auto: 3 tentativas técnicas esgotadas → Perdido sem contato';

      update public.leads set
        feedback = 'chamada_caiu',
        observacao_corretor = p_observacao,
        data_feedback = now(),
        atendimento_finalizado_em = now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = now(),
        tentativas_caiu = v_tentativas_caiu,
        tecnico_pendente = false,
        ultima_falha_tecnica = 'chamada_caiu',
        ultima_falha_em = now(),
        acao_sugerida = null,
        funil_estagio_id = v_perdido_sem_id,
        funil_atualizado_em = now(),
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      where id = p_lead_id
        and corretor_id = v_corretor_id
        and empresa_id = v_empresa_id;

      insert into public.funil_movimentacoes(lead_id, corretor_id, estagio_id, observacao, empresa_id, origem_evento, motivo)
      values(p_lead_id, v_corretor_id, v_perdido_sem_id, v_obs_auto, v_empresa_id, 'feedback'::public.funil_origem_evento, p_feedback);
    end if;

  elsif p_feedback = 'whatsapp_invalido' then
    if v_tem_phone then
      v_tecnico_pendente := true;
      v_acao_sugerida := 'ligar';

      update public.leads set
        feedback = 'whatsapp_invalido',
        observacao_corretor = p_observacao,
        data_feedback = now(),
        atendimento_finalizado_em = now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = now(),
        tecnico_pendente = true,
        ultima_falha_tecnica = 'whatsapp_invalido',
        ultima_falha_em = now(),
        acao_sugerida = 'ligar',
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      where id = p_lead_id
        and corretor_id = v_corretor_id
        and empresa_id = v_empresa_id;
    elsif v_tem_email then
      v_tecnico_pendente := false;
      v_acao_sugerida := 'email';
      v_novo_estagio := v_perdido_sem_id;
      v_obs_auto := 'Auto: WhatsApp inválido, sem telefone → Mensagens por e-mail';

      update public.leads set
        feedback = 'whatsapp_invalido',
        observacao_corretor = p_observacao,
        data_feedback = now(),
        atendimento_finalizado_em = now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = now(),
        tecnico_pendente = false,
        ultima_falha_tecnica = 'whatsapp_invalido',
        ultima_falha_em = now(),
        acao_sugerida = 'email',
        funil_estagio_id = v_perdido_sem_id,
        funil_atualizado_em = now(),
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      where id = p_lead_id
        and corretor_id = v_corretor_id
        and empresa_id = v_empresa_id;

      insert into public.funil_movimentacoes(lead_id, corretor_id, estagio_id, observacao, empresa_id, origem_evento, motivo)
      values(p_lead_id, v_corretor_id, v_perdido_sem_id, v_obs_auto, v_empresa_id, 'feedback'::public.funil_origem_evento, p_feedback);
    else
      v_tecnico_pendente := false;
      v_novo_estagio := v_perdido_sem_id;
      v_obs_auto := 'Auto: WhatsApp inválido, sem canal alternativo → Perdido sem contato';

      update public.leads set
        feedback = 'whatsapp_invalido',
        observacao_corretor = p_observacao,
        data_feedback = now(),
        atendimento_finalizado_em = now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = now(),
        tecnico_pendente = false,
        ultima_falha_tecnica = 'whatsapp_invalido',
        ultima_falha_em = now(),
        acao_sugerida = null,
        funil_estagio_id = v_perdido_sem_id,
        funil_atualizado_em = now(),
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      where id = p_lead_id
        and corretor_id = v_corretor_id
        and empresa_id = v_empresa_id;

      insert into public.funil_movimentacoes(lead_id, corretor_id, estagio_id, observacao, empresa_id, origem_evento, motivo)
      values(p_lead_id, v_corretor_id, v_perdido_sem_id, v_obs_auto, v_empresa_id, 'feedback'::public.funil_origem_evento, p_feedback);
    end if;

  else
    v_tecnico_pendente := false;

    update public.leads set
      feedback = p_feedback,
      observacao_corretor = p_observacao,
      data_feedback = now(),
      atendimento_finalizado_em = now(),
      tempo_tratativa_segundos = v_tempo,
      updated_at = now(),
      tecnico_pendente = false,
      acao_sugerida = null,
      feedback_tipo = v_feedback_tipo,
      status_operacional = 'em_trabalho'::public.lead_status_operacional,
      status_comercial = v_status_comercial
    where id = p_lead_id
      and corretor_id = v_corretor_id
      and empresa_id = v_empresa_id;

    v_novo_estagio := null;
    v_obs_auto := '';

    case p_feedback
      when 'enviado_informacoes','em_conversa' then v_novo_estagio := v_em_conversa_id; v_obs_auto := 'Auto: Em conversa';
      when 'nao_toca' then v_novo_estagio := v_em_conversa_id; v_obs_auto := 'Auto: Respondeu e-mail → Em conversa';
      when 'retornar_depois' then v_novo_estagio := v_em_conversa_id; v_obs_auto := 'Auto: Retornar depois → Em conversa';
      when 'agendado_visita' then v_novo_estagio := v_visita_ag_id; v_obs_auto := 'Auto: Visita agendada';
      when 'lead_ja_atendido','sem_interesse' then v_novo_estagio := v_perdido_com_id; v_obs_auto := 'Auto: Perdido com contato';
      when 'numero_errado','nao_responde','caixa_postal','nao_responde_email' then v_novo_estagio := v_perdido_sem_id; v_obs_auto := 'Auto: Perdido sem contato';
      else v_novo_estagio := null;
    end case;

    if v_novo_estagio is not null then
      update public.leads set
        funil_estagio_id = v_novo_estagio,
        funil_atualizado_em = now()
      where id = p_lead_id
        and corretor_id = v_corretor_id
        and empresa_id = v_empresa_id;

      insert into public.funil_movimentacoes(lead_id, corretor_id, estagio_id, observacao, empresa_id, origem_evento, motivo)
      values(p_lead_id, v_corretor_id, v_novo_estagio, v_obs_auto, v_empresa_id, 'feedback'::public.funil_origem_evento, p_feedback);
    end if;
  end if;

  select count(*) into v_count_fb
  from public.leads l
  where l.lote_id = v_lote_id
    and l.corretor_id = v_corretor_id
    and l.empresa_id = v_empresa_id
    and l.feedback is not null
    and l.feedback <> ''
    and (l.tecnico_pendente = false or l.tecnico_pendente is null);

  update public.lotes set quantidade_feedback = v_count_fb
  where id = v_lote_id
    and corretor_id = v_corretor_id
    and empresa_id = v_empresa_id;

  if v_count_fb >= 25 then
    update public.lotes set
      status = 'finalizado',
      status_v2 = 'concluido'::public.lote_status,
      data_fechamento = now(),
      closed_at = now()
    where id = v_lote_id
      and corretor_id = v_corretor_id
      and empresa_id = v_empresa_id
      and status = 'aberto';

    update public.leads set
      status = 'finalizado',
      status_operacional = 'finalizado'::public.lead_status_operacional
    where lote_id = v_lote_id
      and corretor_id = v_corretor_id
      and empresa_id = v_empresa_id;

    v_lote_fechado := true;

    insert into public.logs(acao, usuario_email, detalhes, empresa_id)
    values(
      'lote_fechado',
      current_setting('request.jwt.claims', true)::jsonb->>'email',
      jsonb_build_object('lote_id', v_lote_id, 'corretor_id', v_corretor_id, 'empresa_id', v_empresa_id),
      v_empresa_id
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'lote_fechado', v_lote_fechado,
    'tecnico_pendente', v_tecnico_pendente,
    'acao_sugerida', v_acao_sugerida,
    'tentativas_caiu', v_tentativas_caiu,
    'tempo_tratativa_segundos', v_tempo
  );
end;
$function$

;

-- Restore exact pre-PR-07 client-visible grants.
REVOKE ALL PRIVILEGES
ON FUNCTION public.listar_funil_estagios()
FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL PRIVILEGES
ON FUNCTION public.importar_leads_batch(uuid, jsonb, text)
FROM PUBLIC, anon, authenticated, service_role;

REVOKE ALL PRIVILEGES
ON FUNCTION public.registrar_feedback(uuid, text, text)
FROM PUBLIC, anon, authenticated, service_role;

GRANT EXECUTE
ON FUNCTION public.listar_funil_estagios()
TO authenticated, service_role;

GRANT EXECUTE
ON FUNCTION public.importar_leads_batch(uuid, jsonb, text)
TO authenticated, service_role;

GRANT EXECUTE
ON FUNCTION public.registrar_feedback(uuid, text, text)
TO authenticated, service_role;

-- This removes only PR-07 control metadata. It intentionally loses replay history.
DROP TABLE public.importar_leads_batch_idempotency;

DO $postflight$
BEGIN
  IF pg_catalog.to_regclass('public.importar_leads_batch_idempotency') IS NOT NULL THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback postflight failed: idempotency table still exists';
  END IF;

  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.listar_funil_estagios()'::pg_catalog.regprocedure))
       IS DISTINCT FROM '8ca0d3dd61fbe00c20f591dbe3dae6f8' THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback postflight failed: listar_funil_estagios not restored';
  END IF;

  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure))
       IS DISTINCT FROM '8f8f2c8b8593a54068783c7ddd4a84ee' THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback postflight failed: importar_leads_batch not restored';
  END IF;

  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure))
       IS DISTINCT FROM '3a6282c898199abc6c497a8cdfb5d16f' THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback postflight failed: registrar_feedback not restored';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_proc p
    WHERE p.oid IN (
      'public.listar_funil_estagios()'::pg_catalog.regprocedure,
      'public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure,
      'public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure
    )
      AND (
        pg_catalog.pg_get_userbyid(p.proowner) IS DISTINCT FROM 'postgres'
        OR p.prosecdef IS DISTINCT FROM true
        OR p.proconfig IS DISTINCT FROM ARRAY['search_path=public']::text[]
      )
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback postflight failed: pre-PR-07 metadata not restored';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM (
      VALUES
        ('public.listar_funil_estagios()'),
        ('public.importar_leads_batch(uuid,jsonb,text)'),
        ('public.registrar_feedback(uuid,text,text)')
    ) AS f(signature)
    WHERE pg_catalog.has_function_privilege('anon', f.signature, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('authenticated', f.signature, 'EXECUTE')
       OR NOT pg_catalog.has_function_privilege('service_role', f.signature, 'EXECUTE')
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback postflight failed: pre-PR-07 grants not restored';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_proc p
    CROSS JOIN LATERAL pg_catalog.aclexplode(
      coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))
    ) e
    WHERE p.oid IN (
      'public.listar_funil_estagios()'::pg_catalog.regprocedure,
      'public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure,
      'public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure
    )
      AND e.grantee = 0
      AND e.privilege_type = 'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback postflight failed: PUBLIC EXECUTE exists';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.logs'::pg_catalog.regclass
      AND c.conname = 'logs_sessao_id_unique'
      AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'UNIQUE (sessao_id)'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 rollback postflight failed: logs_sessao_id_unique changed';
  END IF;
END
$postflight$;

COMMIT;
