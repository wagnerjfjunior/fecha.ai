-- FECH.AI — F1-02 / PR-07
-- Tenant-safe funnel reads + CRM payload integrity.
-- Scope: listar_funil_estagios(), importar_leads_batch(uuid,jsonb,text),
-- registrar_feedback(uuid,text,text), and PR-07-owned import idempotency metadata.
-- No App.jsx change. No data repair. Runtime-negative PASS is NOT established.
-- SECURITY_GO remains DENIED.

BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL statement_timeout = '120s';

SELECT pg_catalog.pg_advisory_xact_lock(20260902091600);

DO $preflight$
DECLARE
  v_enum text;
  v_public_exec boolean;
BEGIN
  IF pg_catalog.to_regclass('public.importar_leads_batch_idempotency') IS NOT NULL THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: idempotency table already exists';
  END IF;

  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.listar_funil_estagios()'::pg_catalog.regprocedure))
       IS DISTINCT FROM '8ca0d3dd61fbe00c20f591dbe3dae6f8' THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: listar_funil_estagios drift';
  END IF;

  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure))
       IS DISTINCT FROM '8f8f2c8b8593a54068783c7ddd4a84ee' THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: importar_leads_batch drift';
  END IF;

  IF pg_catalog.md5(pg_catalog.pg_get_functiondef('public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure))
       IS DISTINCT FROM '3a6282c898199abc6c497a8cdfb5d16f' THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: registrar_feedback drift';
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
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: function owner/definer/search_path drift';
  END IF;

  FOR v_public_exec IN
    SELECT EXISTS (
      SELECT 1
      FROM pg_catalog.aclexplode(coalesce(p.proacl, pg_catalog.acldefault('f', p.proowner))) e
      WHERE e.grantee = 0
        AND e.privilege_type = 'EXECUTE'
    )
    FROM pg_catalog.pg_proc p
    WHERE p.oid IN (
      'public.listar_funil_estagios()'::pg_catalog.regprocedure,
      'public.importar_leads_batch(uuid,jsonb,text)'::pg_catalog.regprocedure,
      'public.registrar_feedback(uuid,text,text)'::pg_catalog.regprocedure
    )
  LOOP
    IF v_public_exec THEN
      RAISE EXCEPTION 'F1-02/PR-07 preflight failed: PUBLIC EXECUTE drift';
    END IF;
  END LOOP;

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
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: function ACL drift';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.corretores'::pg_catalog.regclass
      AND c.contype = 'u'
      AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'UNIQUE (user_id)'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: corretores.user_id uniqueness absent';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.listas'::pg_catalog.regclass
      AND c.contype = 'u'
      AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'UNIQUE (id, empresa_id)'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: listas(id,empresa_id) candidate key absent';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.logs'::pg_catalog.regclass
      AND c.conname = 'logs_sessao_id_unique'
      AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'UNIQUE (sessao_id)'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: logs_sessao_id_unique drift';
  END IF;

  IF pg_catalog.to_regprocedure('extensions.digest(text,text)') IS NULL THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: extensions.digest(text,text) unavailable';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_attribute a
    WHERE a.attrelid = 'public.funil_estagios'::pg_catalog.regclass
      AND a.attname = 'empresa_id'
      AND a.attnotnull = true
      AND a.attisdropped = false
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: funil_estagios.empresa_id must remain NOT NULL';
  END IF;

  IF EXISTS (SELECT 1 FROM public.funil_estagios fe WHERE fe.empresa_id IS NULL) THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: unexpected global funnel stage rows';
  END IF;

  SELECT pg_catalog.string_agg(e.enumlabel, ',' ORDER BY e.enumsortorder)
  INTO v_enum
  FROM pg_catalog.pg_type t
  JOIN pg_catalog.pg_enum e ON e.enumtypid = t.oid
  JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = 'public'
    AND t.typname = 'lead_feedback_tipo';

  IF v_enum IS DISTINCT FROM
    'agendado_visita,enviado_informacoes,em_conversa,retornar_depois,sem_interesse,lead_ja_atendido,nao_responde,nao_responde_email,numero_errado,caixa_postal,chamada_caiu,whatsapp_invalido,invalido,nao_toca' THEN
    RAISE EXCEPTION 'F1-02/PR-07 preflight failed: lead_feedback_tipo drift';
  END IF;
END
$preflight$;

CREATE TABLE public.importar_leads_batch_idempotency (
  empresa_id uuid NOT NULL,
  sessao_id text NOT NULL,
  lista_id uuid NOT NULL,
  request_fingerprint text NOT NULL,
  resultado jsonb NULL,
  created_at timestamptz NOT NULL DEFAULT pg_catalog.now(),
  completed_at timestamptz NULL,

  CONSTRAINT importar_leads_batch_idempotency_pkey
    PRIMARY KEY (empresa_id, sessao_id),

  CONSTRAINT importar_leads_batch_idempotency_session_check
    CHECK (
      pg_catalog.char_length(sessao_id) BETWEEN 1 AND 128
      AND sessao_id = pg_catalog.btrim(sessao_id)
    ),

  CONSTRAINT importar_leads_batch_idempotency_fingerprint_check
    CHECK (
      pg_catalog.char_length(request_fingerprint) = 64
      AND request_fingerprint ~ '^[0-9a-f]{64}$'
    ),

  CONSTRAINT importar_leads_batch_idempotency_completion_check
    CHECK (
      (resultado IS NULL AND completed_at IS NULL)
      OR
      (resultado IS NOT NULL AND completed_at IS NOT NULL)
    ),

  CONSTRAINT importar_leads_batch_idempotency_lista_empresa_fkey
    FOREIGN KEY (lista_id, empresa_id)
    REFERENCES public.listas (id, empresa_id)
    ON DELETE CASCADE
);

ALTER TABLE public.importar_leads_batch_idempotency OWNER TO postgres;
ALTER TABLE public.importar_leads_batch_idempotency ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.importar_leads_batch_idempotency FORCE ROW LEVEL SECURITY;

REVOKE ALL PRIVILEGES
ON TABLE public.importar_leads_batch_idempotency
FROM PUBLIC, anon, authenticated, service_role;

-- No client policies are intentionally created.
-- The SECURITY DEFINER import RPC is the application command boundary.

CREATE OR REPLACE FUNCTION public.listar_funil_estagios()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_empresa_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  IF public.is_root() THEN
    RETURN '[]'::jsonb;
  END IF;

  SELECT c.empresa_id
  INTO v_empresa_id
  FROM public.corretores c
  WHERE c.user_id = auth.uid()
    AND coalesce(c.ativo, true) = true
    AND c.empresa_id IS NOT NULL;

  IF v_empresa_id IS NULL THEN
    RETURN '[]'::jsonb;
  END IF;

  RETURN coalesce(
    (
      SELECT pg_catalog.jsonb_agg(
        pg_catalog.jsonb_build_object(
          'id', fe.id,
          'nome', fe.nome,
          'icone', fe.icone,
          'cor', fe.cor,
          'ordem', fe.ordem
        )
        ORDER BY fe.ordem ASC, fe.id ASC
      )
      FROM public.funil_estagios fe
      WHERE fe.empresa_id = v_empresa_id
    ),
    '[]'::jsonb
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.importar_leads_batch(
  p_lista_id uuid,
  p_leads jsonb,
  p_sessao_id text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_corretor_id uuid;
  v_empresa_id uuid;
  v_lista_id uuid;
  v_user_email text;
  v_sessao_id text;
  v_request_fingerprint text;
  v_inserted integer := 0;
  v_invalidos integer := 0;
  v_skipped integer := 0;
  v_lead jsonb;
  v_e164 text;
  v_claim_rows integer := 0;
  v_existing_lista_id uuid;
  v_existing_fingerprint text;
  v_existing_result jsonb;
  v_existing_completed_at timestamptz;
  v_result jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Autenticação obrigatória');
  END IF;

  IF public.is_root() THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Sem permissão');
  END IF;

  SELECT c.id, c.empresa_id
  INTO v_corretor_id, v_empresa_id
  FROM public.corretores c
  WHERE c.user_id = auth.uid()
    AND coalesce(c.ativo, true) = true
    AND c.empresa_id IS NOT NULL;

  IF v_corretor_id IS NULL OR v_empresa_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Perfil ativo não encontrado');
  END IF;

  SELECT li.id
  INTO v_lista_id
  FROM public.listas li
  WHERE li.id = p_lista_id
    AND li.empresa_id = v_empresa_id
  FOR KEY SHARE;

  IF v_lista_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Lista não encontrada ou sem permissão');
  END IF;

  IF p_sessao_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('error', 'sessao_id obrigatório');
  END IF;

  v_sessao_id := pg_catalog.btrim(p_sessao_id);

  IF v_sessao_id = ''
     OR pg_catalog.char_length(v_sessao_id) > 128 THEN
    RETURN pg_catalog.jsonb_build_object('error', 'sessao_id inválido');
  END IF;

  IF p_leads IS NULL
     OR pg_catalog.jsonb_typeof(p_leads) IS DISTINCT FROM 'array' THEN
    RETURN pg_catalog.jsonb_build_object('error', 'p_leads deve ser um array');
  END IF;

  IF pg_catalog.jsonb_array_length(p_leads) > 100 THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Máximo de 100 leads por batch');
  END IF;

  -- Validate the COMPLETE request before the first persistent write.
  FOR v_lead IN
    SELECT e.value
    FROM pg_catalog.jsonb_array_elements(p_leads) AS e(value)
  LOOP
    IF pg_catalog.jsonb_typeof(v_lead) IS DISTINCT FROM 'object' THEN
      RETURN pg_catalog.jsonb_build_object('error', 'Lead inválido: cada item deve ser um objeto');
    END IF;

    IF EXISTS (
      SELECT 1
      FROM pg_catalog.jsonb_object_keys(v_lead) AS k(key)
      WHERE k.key NOT IN (
        'nome',
        'email',
        'endereco',
        'zona',
        'telefone_origem_1',
        'telefone_origem_2',
        'telefone_escolhido',
        'telefone_e164',
        'tipo_telefone',
        'pais_telefone',
        'ligar',
        'whatsapp',
        'fornecedor'
      )
    ) THEN
      RETURN pg_catalog.jsonb_build_object('error', 'Lead contém campo não permitido');
    END IF;

    IF EXISTS (
      SELECT 1
      FROM pg_catalog.jsonb_each(v_lead) AS e(key, value)
      WHERE pg_catalog.jsonb_typeof(e.value) NOT IN ('string', 'null')
    ) THEN
      RETURN pg_catalog.jsonb_build_object('error', 'Lead contém tipo de campo inválido');
    END IF;

    IF pg_catalog.char_length(coalesce(v_lead->>'email', '')) > 320
       OR pg_catalog.char_length(coalesce(v_lead->>'telefone_origem_1', '')) > 64
       OR pg_catalog.char_length(coalesce(v_lead->>'telefone_origem_2', '')) > 64
       OR pg_catalog.char_length(coalesce(v_lead->>'telefone_escolhido', '')) > 64
       OR pg_catalog.char_length(coalesce(v_lead->>'telefone_e164', '')) > 64
       OR pg_catalog.char_length(coalesce(v_lead->>'nome', '')) > 500
       OR pg_catalog.char_length(coalesce(v_lead->>'endereco', '')) > 500
       OR pg_catalog.char_length(coalesce(v_lead->>'zona', '')) > 255
       OR pg_catalog.char_length(coalesce(v_lead->>'fornecedor', '')) > 255
       OR pg_catalog.char_length(coalesce(v_lead->>'tipo_telefone', '')) > 64
       OR pg_catalog.char_length(coalesce(v_lead->>'pais_telefone', '')) > 64
       OR pg_catalog.char_length(coalesce(v_lead->>'ligar', '')) > 64
       OR pg_catalog.char_length(coalesce(v_lead->>'whatsapp', '')) > 64 THEN
      RETURN pg_catalog.jsonb_build_object('error', 'Lead excede limite de tamanho');
    END IF;
  END LOOP;

  v_request_fingerprint := pg_catalog.encode(
    extensions.digest(
      pg_catalog.jsonb_build_object(
        'contract', 'F1-02/PR-07/v1',
        'empresa_id', v_empresa_id::text,
        'lista_id', p_lista_id::text,
        'sessao_id', v_sessao_id,
        'leads', p_leads
      )::text,
      'sha256'
    ),
    'hex'
  );

  INSERT INTO public.importar_leads_batch_idempotency (
    empresa_id,
    sessao_id,
    lista_id,
    request_fingerprint
  )
  VALUES (
    v_empresa_id,
    v_sessao_id,
    p_lista_id,
    v_request_fingerprint
  )
  ON CONFLICT (empresa_id, sessao_id) DO NOTHING;

  GET DIAGNOSTICS v_claim_rows = ROW_COUNT;

  IF v_claim_rows = 0 THEN
    SELECT
      i.lista_id,
      i.request_fingerprint,
      i.resultado,
      i.completed_at
    INTO
      v_existing_lista_id,
      v_existing_fingerprint,
      v_existing_result,
      v_existing_completed_at
    FROM public.importar_leads_batch_idempotency i
    WHERE i.empresa_id = v_empresa_id
      AND i.sessao_id = v_sessao_id;

    IF NOT FOUND THEN
      RETURN pg_catalog.jsonb_build_object('error', 'IDEMPOTENCY_STATE_MISSING');
    END IF;

    IF v_existing_lista_id IS DISTINCT FROM p_lista_id THEN
      RETURN pg_catalog.jsonb_build_object('error', 'SESSION_LIST_MISMATCH');
    END IF;

    IF v_existing_fingerprint IS DISTINCT FROM v_request_fingerprint THEN
      RETURN pg_catalog.jsonb_build_object('error', 'SESSION_PAYLOAD_MISMATCH');
    END IF;

    IF v_existing_result IS NULL OR v_existing_completed_at IS NULL THEN
      RETURN pg_catalog.jsonb_build_object('error', 'IDEMPOTENCY_INCOMPLETE');
    END IF;

    IF pg_catalog.jsonb_typeof(v_existing_result) IS DISTINCT FROM 'object'
       OR NOT (v_existing_result ?& ARRAY['validos','invalidos','duplicados']::text[])
       OR (
         SELECT pg_catalog.count(*)
         FROM pg_catalog.jsonb_object_keys(v_existing_result)
       ) <> 3
       OR pg_catalog.jsonb_typeof(v_existing_result->'validos') IS DISTINCT FROM 'number'
       OR pg_catalog.jsonb_typeof(v_existing_result->'invalidos') IS DISTINCT FROM 'number'
       OR pg_catalog.jsonb_typeof(v_existing_result->'duplicados') IS DISTINCT FROM 'number' THEN
      RETURN pg_catalog.jsonb_build_object('error', 'IDEMPOTENCY_RESULT_INVALID');
    END IF;

    RETURN v_existing_result;
  END IF;

  SELECT u.email
  INTO v_user_email
  FROM auth.users u
  WHERE u.id = auth.uid();

  FOR v_lead IN
    SELECT e.value
    FROM pg_catalog.jsonb_array_elements(p_leads) AS e(value)
  LOOP
    v_e164 := pg_catalog.btrim(v_lead->>'telefone_e164');

    IF v_e164 IS NULL OR v_e164 = '' THEN
      v_invalidos := v_invalidos + 1;
      CONTINUE;
    END IF;

    IF EXISTS (
      SELECT 1
      FROM public.leads l
      WHERE l.empresa_id = v_empresa_id
        AND l.telefone_e164 = v_e164
    ) THEN
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    INSERT INTO public.leads (
      empresa_id,
      lista_id,
      nome,
      email,
      endereco,
      zona,
      telefone_origem_1,
      telefone_origem_2,
      telefone_escolhido,
      telefone_e164,
      tipo_telefone,
      pais_telefone,
      ligar,
      whatsapp,
      fornecedor,
      status
    )
    VALUES (
      v_empresa_id,
      p_lista_id,
      v_lead->>'nome',
      v_lead->>'email',
      v_lead->>'endereco',
      nullif(pg_catalog.btrim(v_lead->>'zona'), ''),
      v_lead->>'telefone_origem_1',
      v_lead->>'telefone_origem_2',
      v_lead->>'telefone_escolhido',
      v_e164,
      v_lead->>'tipo_telefone',
      v_lead->>'pais_telefone',
      v_lead->>'ligar',
      v_lead->>'whatsapp',
      v_lead->>'fornecedor',
      'disponivel'
    );

    v_inserted := v_inserted + 1;
  END LOOP;

  UPDATE public.listas
  SET
    leads_validos = leads_validos + v_inserted,
    leads_invalidos = leads_invalidos + v_invalidos
  WHERE id = p_lista_id
    AND empresa_id = v_empresa_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'F1-02/PR-07 import invariant failed: authorized list disappeared';
  END IF;

  v_result := pg_catalog.jsonb_build_object(
    'validos', v_inserted,
    'invalidos', v_invalidos,
    'duplicados', v_skipped
  );

  UPDATE public.importar_leads_batch_idempotency
  SET
    resultado = v_result,
    completed_at = pg_catalog.now()
  WHERE empresa_id = v_empresa_id
    AND sessao_id = v_sessao_id
    AND lista_id = p_lista_id
    AND request_fingerprint = v_request_fingerprint;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'F1-02/PR-07 import invariant failed: idempotency claim lost';
  END IF;

  INSERT INTO public.logs (
    acao,
    usuario_email,
    empresa_id,
    detalhes
  )
  VALUES (
    'import_batch',
    v_user_email,
    v_empresa_id,
    pg_catalog.jsonb_build_object(
      'sessao_id', v_sessao_id,
      'lista_id', p_lista_id,
      'resultado', v_result
    )
  );

  RETURN v_result;

EXCEPTION
  WHEN others THEN
    -- PL/pgSQL rolls back all persistent changes made in this block before
    -- entering the handler. Do not expose database error details to an untrusted client.
    RETURN pg_catalog.jsonb_build_object('error', 'Erro interno');
END;
$function$;

CREATE OR REPLACE FUNCTION public.registrar_feedback(
  p_lead_id uuid,
  p_feedback text,
  p_observacao text DEFAULT ''::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog'
AS $function$
DECLARE
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
  v_acao_sugerida       text := null;
  v_em_conversa_id      uuid;
  v_visita_ag_id        uuid;
  v_perdido_sem_id      uuid;
  v_perdido_com_id      uuid;
  v_feedback_tipo       public.lead_feedback_tipo;
  v_feedback_text       text;
  v_status_comercial    public.lead_status_comercial;
  v_iniciado_em         timestamptz;
  v_tempo               integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Autenticação obrigatória');
  END IF;

  IF public.is_root() THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Sem permissão');
  END IF;

  SELECT c.id, c.empresa_id
  INTO v_corretor_id, v_empresa_id
  FROM public.corretores c
  WHERE c.user_id = auth.uid()
    AND coalesce(c.ativo, true) = true
    AND c.empresa_id IS NOT NULL;

  IF v_corretor_id IS NULL OR v_empresa_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Corretor ativo não encontrado');
  END IF;

  IF p_feedback IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Feedback inválido');
  END IF;

  v_feedback_text := pg_catalog.btrim(p_feedback);

  IF v_feedback_text = '' THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Feedback inválido');
  END IF;

  BEGIN
    v_feedback_tipo := v_feedback_text::public.lead_feedback_tipo;
  EXCEPTION
    WHEN invalid_text_representation THEN
      RETURN pg_catalog.jsonb_build_object('error', 'Feedback inválido');
  END;

  -- From this point, all business branching uses trusted canonical feedback text.
  v_feedback_text := v_feedback_tipo::text;

  SELECT
    l.lote_id,
    l.tentativas_caiu,
    l.atendimento_iniciado_em,
    (l.telefone_e164 IS NOT NULL AND l.telefone_e164 <> '') AS tem_phone,
    (l.email IS NOT NULL AND pg_catalog.btrim(l.email) <> '') AS tem_email
  INTO
    v_lote_id,
    v_tentativas_caiu,
    v_iniciado_em,
    v_tem_phone,
    v_tem_email
  FROM public.leads l
  WHERE l.id = p_lead_id
    AND l.corretor_id = v_corretor_id
    AND l.empresa_id = v_empresa_id;

  IF v_lote_id IS NULL THEN
    RETURN pg_catalog.jsonb_build_object('error', 'Lead não encontrado ou sem permissão');
  END IF;

  IF v_iniciado_em IS NOT NULL THEN
    v_tempo := extract(epoch FROM (pg_catalog.now() - v_iniciado_em))::int;
  ELSE
    v_tempo := null;
  END IF;

  SELECT fe.id
  INTO v_em_conversa_id
  FROM public.funil_estagios fe
  WHERE fe.codigo_estagio = 'em_conversa'
    AND fe.empresa_id = v_empresa_id
  LIMIT 1;

  SELECT fe.id
  INTO v_visita_ag_id
  FROM public.funil_estagios fe
  WHERE fe.codigo_estagio = 'visita_agendada'
    AND fe.empresa_id = v_empresa_id
  LIMIT 1;

  SELECT fe.id
  INTO v_perdido_sem_id
  FROM public.funil_estagios fe
  WHERE fe.codigo_estagio = 'perdido_sem_contato'
    AND fe.empresa_id = v_empresa_id
  LIMIT 1;

  SELECT fe.id
  INTO v_perdido_com_id
  FROM public.funil_estagios fe
  WHERE fe.codigo_estagio = 'perdido_com_contato'
    AND fe.empresa_id = v_empresa_id
  LIMIT 1;

  v_status_comercial :=
    CASE
      WHEN v_feedback_text IN ('agendado_visita','enviado_informacoes','retornar_depois','em_conversa')
        THEN 'contato_efetivo'::public.lead_status_comercial
      WHEN v_feedback_text IN ('sem_interesse','lead_ja_atendido')
        THEN 'perdido_com_contato'::public.lead_status_comercial
      WHEN v_feedback_text IN (
        'nao_responde','nao_responde_email','numero_errado',
        'caixa_postal','nao_toca','chamada_caiu','whatsapp_invalido'
      )
        THEN 'perdido_sem_contato'::public.lead_status_comercial
      WHEN v_feedback_text = 'invalido'
        THEN 'invalido'::public.lead_status_comercial
      ELSE
        'sem_status'::public.lead_status_comercial
    END;

  IF v_feedback_text = 'chamada_caiu' THEN
    v_tentativas_caiu := coalesce(v_tentativas_caiu, 0) + 1;

    IF v_tentativas_caiu < 3 THEN
      v_tecnico_pendente := true;
      v_acao_sugerida := 'ligar';

      UPDATE public.leads
      SET
        feedback = v_feedback_text,
        observacao_corretor = p_observacao,
        data_feedback = pg_catalog.now(),
        atendimento_finalizado_em = pg_catalog.now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = pg_catalog.now(),
        tentativas_caiu = v_tentativas_caiu,
        tecnico_pendente = true,
        ultima_falha_tecnica = 'chamada_caiu',
        ultima_falha_em = pg_catalog.now(),
        acao_sugerida = 'ligar',
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      WHERE id = p_lead_id
        AND corretor_id = v_corretor_id
        AND empresa_id = v_empresa_id;
    ELSE
      v_tecnico_pendente := false;
      v_novo_estagio := v_perdido_sem_id;
      v_obs_auto := 'Auto: 3 tentativas técnicas esgotadas → Perdido sem contato';

      UPDATE public.leads
      SET
        feedback = v_feedback_text,
        observacao_corretor = p_observacao,
        data_feedback = pg_catalog.now(),
        atendimento_finalizado_em = pg_catalog.now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = pg_catalog.now(),
        tentativas_caiu = v_tentativas_caiu,
        tecnico_pendente = false,
        ultima_falha_tecnica = 'chamada_caiu',
        ultima_falha_em = pg_catalog.now(),
        acao_sugerida = null,
        funil_estagio_id = v_perdido_sem_id,
        funil_atualizado_em = pg_catalog.now(),
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      WHERE id = p_lead_id
        AND corretor_id = v_corretor_id
        AND empresa_id = v_empresa_id;

      INSERT INTO public.funil_movimentacoes (
        lead_id, corretor_id, estagio_id, observacao, empresa_id, origem_evento, motivo
      )
      VALUES (
        p_lead_id, v_corretor_id, v_perdido_sem_id, v_obs_auto, v_empresa_id,
        'feedback'::public.funil_origem_evento, v_feedback_text
      );
    END IF;

  ELSIF v_feedback_text = 'whatsapp_invalido' THEN
    IF v_tem_phone THEN
      v_tecnico_pendente := true;
      v_acao_sugerida := 'ligar';

      UPDATE public.leads
      SET
        feedback = v_feedback_text,
        observacao_corretor = p_observacao,
        data_feedback = pg_catalog.now(),
        atendimento_finalizado_em = pg_catalog.now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = pg_catalog.now(),
        tecnico_pendente = true,
        ultima_falha_tecnica = 'whatsapp_invalido',
        ultima_falha_em = pg_catalog.now(),
        acao_sugerida = 'ligar',
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      WHERE id = p_lead_id
        AND corretor_id = v_corretor_id
        AND empresa_id = v_empresa_id;

    ELSIF v_tem_email THEN
      v_tecnico_pendente := false;
      v_acao_sugerida := 'email';
      v_novo_estagio := v_perdido_sem_id;
      v_obs_auto := 'Auto: WhatsApp inválido, sem telefone → Mensagens por e-mail';

      UPDATE public.leads
      SET
        feedback = v_feedback_text,
        observacao_corretor = p_observacao,
        data_feedback = pg_catalog.now(),
        atendimento_finalizado_em = pg_catalog.now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = pg_catalog.now(),
        tecnico_pendente = false,
        ultima_falha_tecnica = 'whatsapp_invalido',
        ultima_falha_em = pg_catalog.now(),
        acao_sugerida = 'email',
        funil_estagio_id = v_perdido_sem_id,
        funil_atualizado_em = pg_catalog.now(),
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      WHERE id = p_lead_id
        AND corretor_id = v_corretor_id
        AND empresa_id = v_empresa_id;

      INSERT INTO public.funil_movimentacoes (
        lead_id, corretor_id, estagio_id, observacao, empresa_id, origem_evento, motivo
      )
      VALUES (
        p_lead_id, v_corretor_id, v_perdido_sem_id, v_obs_auto, v_empresa_id,
        'feedback'::public.funil_origem_evento, v_feedback_text
      );

    ELSE
      v_tecnico_pendente := false;
      v_novo_estagio := v_perdido_sem_id;
      v_obs_auto := 'Auto: WhatsApp inválido, sem canal alternativo → Perdido sem contato';

      UPDATE public.leads
      SET
        feedback = v_feedback_text,
        observacao_corretor = p_observacao,
        data_feedback = pg_catalog.now(),
        atendimento_finalizado_em = pg_catalog.now(),
        tempo_tratativa_segundos = v_tempo,
        updated_at = pg_catalog.now(),
        tecnico_pendente = false,
        ultima_falha_tecnica = 'whatsapp_invalido',
        ultima_falha_em = pg_catalog.now(),
        acao_sugerida = null,
        funil_estagio_id = v_perdido_sem_id,
        funil_atualizado_em = pg_catalog.now(),
        feedback_tipo = v_feedback_tipo,
        status_operacional = 'em_trabalho'::public.lead_status_operacional,
        status_comercial = v_status_comercial
      WHERE id = p_lead_id
        AND corretor_id = v_corretor_id
        AND empresa_id = v_empresa_id;

      INSERT INTO public.funil_movimentacoes (
        lead_id, corretor_id, estagio_id, observacao, empresa_id, origem_evento, motivo
      )
      VALUES (
        p_lead_id, v_corretor_id, v_perdido_sem_id, v_obs_auto, v_empresa_id,
        'feedback'::public.funil_origem_evento, v_feedback_text
      );
    END IF;

  ELSE
    v_tecnico_pendente := false;

    UPDATE public.leads
    SET
      feedback = v_feedback_text,
      observacao_corretor = p_observacao,
      data_feedback = pg_catalog.now(),
      atendimento_finalizado_em = pg_catalog.now(),
      tempo_tratativa_segundos = v_tempo,
      updated_at = pg_catalog.now(),
      tecnico_pendente = false,
      acao_sugerida = null,
      feedback_tipo = v_feedback_tipo,
      status_operacional = 'em_trabalho'::public.lead_status_operacional,
      status_comercial = v_status_comercial
    WHERE id = p_lead_id
      AND corretor_id = v_corretor_id
      AND empresa_id = v_empresa_id;

    v_novo_estagio := null;
    v_obs_auto := '';

    CASE v_feedback_text
      WHEN 'enviado_informacoes', 'em_conversa'
        THEN v_novo_estagio := v_em_conversa_id; v_obs_auto := 'Auto: Em conversa';
      WHEN 'nao_toca'
        THEN v_novo_estagio := v_em_conversa_id; v_obs_auto := 'Auto: Respondeu e-mail → Em conversa';
      WHEN 'retornar_depois'
        THEN v_novo_estagio := v_em_conversa_id; v_obs_auto := 'Auto: Retornar depois → Em conversa';
      WHEN 'agendado_visita'
        THEN v_novo_estagio := v_visita_ag_id; v_obs_auto := 'Auto: Visita agendada';
      WHEN 'lead_ja_atendido', 'sem_interesse'
        THEN v_novo_estagio := v_perdido_com_id; v_obs_auto := 'Auto: Perdido com contato';
      WHEN 'numero_errado', 'nao_responde', 'caixa_postal', 'nao_responde_email'
        THEN v_novo_estagio := v_perdido_sem_id; v_obs_auto := 'Auto: Perdido sem contato';
      ELSE
        v_novo_estagio := null;
    END CASE;

    IF v_novo_estagio IS NOT NULL THEN
      UPDATE public.leads
      SET
        funil_estagio_id = v_novo_estagio,
        funil_atualizado_em = pg_catalog.now()
      WHERE id = p_lead_id
        AND corretor_id = v_corretor_id
        AND empresa_id = v_empresa_id;

      INSERT INTO public.funil_movimentacoes (
        lead_id, corretor_id, estagio_id, observacao, empresa_id, origem_evento, motivo
      )
      VALUES (
        p_lead_id, v_corretor_id, v_novo_estagio, v_obs_auto, v_empresa_id,
        'feedback'::public.funil_origem_evento, v_feedback_text
      );
    END IF;
  END IF;

  SELECT pg_catalog.count(*)
  INTO v_count_fb
  FROM public.leads l
  WHERE l.lote_id = v_lote_id
    AND l.corretor_id = v_corretor_id
    AND l.empresa_id = v_empresa_id
    AND l.feedback IS NOT NULL
    AND l.feedback <> ''
    AND (l.tecnico_pendente = false OR l.tecnico_pendente IS NULL);

  UPDATE public.lotes
  SET quantidade_feedback = v_count_fb
  WHERE id = v_lote_id
    AND corretor_id = v_corretor_id
    AND empresa_id = v_empresa_id;

  IF v_count_fb >= 25 THEN
    UPDATE public.lotes
    SET
      status = 'finalizado',
      status_v2 = 'concluido'::public.lote_status,
      data_fechamento = pg_catalog.now(),
      closed_at = pg_catalog.now()
    WHERE id = v_lote_id
      AND corretor_id = v_corretor_id
      AND empresa_id = v_empresa_id
      AND status = 'aberto';

    UPDATE public.leads
    SET
      status = 'finalizado',
      status_operacional = 'finalizado'::public.lead_status_operacional
    WHERE lote_id = v_lote_id
      AND corretor_id = v_corretor_id
      AND empresa_id = v_empresa_id;

    v_lote_fechado := true;

    INSERT INTO public.logs (
      acao,
      usuario_email,
      detalhes,
      empresa_id
    )
    VALUES (
      'lote_fechado',
      pg_catalog.current_setting('request.jwt.claims', true)::pg_catalog.jsonb->>'email',
      pg_catalog.jsonb_build_object(
        'lote_id', v_lote_id,
        'corretor_id', v_corretor_id,
        'empresa_id', v_empresa_id
      ),
      v_empresa_id
    );
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'ok', true,
    'lote_fechado', v_lote_fechado,
    'tecnico_pendente', v_tecnico_pendente,
    'acao_sugerida', v_acao_sugerida,
    'tentativas_caiu', v_tentativas_caiu,
    'tempo_tratativa_segundos', v_tempo
  );
END;
$function$;

-- Rebuild the client-visible function ACLs from the approved closed set.
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

DO $postflight$
DECLARE
  v_policy_count bigint;
  v_public_table_priv boolean;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'importar_leads_batch_idempotency'
      AND c.relkind = 'r'
      AND c.relrowsecurity = true
      AND c.relforcerowsecurity = true
      AND pg_catalog.pg_get_userbyid(c.relowner) = 'postgres'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: idempotency table RLS/owner state';
  END IF;

  SELECT pg_catalog.count(*)
  INTO v_policy_count
  FROM pg_catalog.pg_policy p
  WHERE p.polrelid = 'public.importar_leads_batch_idempotency'::pg_catalog.regclass;

  IF v_policy_count <> 0 THEN
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: idempotency table must have zero client policies';
  END IF;

  IF pg_catalog.has_table_privilege('anon', 'public.importar_leads_batch_idempotency', 'SELECT')
     OR pg_catalog.has_table_privilege('anon', 'public.importar_leads_batch_idempotency', 'INSERT')
     OR pg_catalog.has_table_privilege('anon', 'public.importar_leads_batch_idempotency', 'UPDATE')
     OR pg_catalog.has_table_privilege('anon', 'public.importar_leads_batch_idempotency', 'DELETE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.importar_leads_batch_idempotency', 'SELECT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.importar_leads_batch_idempotency', 'INSERT')
     OR pg_catalog.has_table_privilege('authenticated', 'public.importar_leads_batch_idempotency', 'UPDATE')
     OR pg_catalog.has_table_privilege('authenticated', 'public.importar_leads_batch_idempotency', 'DELETE')
     OR pg_catalog.has_table_privilege('service_role', 'public.importar_leads_batch_idempotency', 'SELECT')
     OR pg_catalog.has_table_privilege('service_role', 'public.importar_leads_batch_idempotency', 'INSERT')
     OR pg_catalog.has_table_privilege('service_role', 'public.importar_leads_batch_idempotency', 'UPDATE')
     OR pg_catalog.has_table_privilege('service_role', 'public.importar_leads_batch_idempotency', 'DELETE') THEN
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: idempotency direct DML grant exists';
  END IF;

  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    CROSS JOIN LATERAL pg_catalog.aclexplode(
      coalesce(c.relacl, pg_catalog.acldefault('r', c.relowner))
    ) e
    WHERE c.oid = 'public.importar_leads_batch_idempotency'::pg_catalog.regclass
      AND e.grantee = 0
      AND e.privilege_type IN ('SELECT','INSERT','UPDATE','DELETE')
  )
  INTO v_public_table_priv;

  IF v_public_table_priv THEN
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: PUBLIC direct table privilege exists';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.importar_leads_batch_idempotency'::pg_catalog.regclass
      AND c.conname = 'importar_leads_batch_idempotency_pkey'
      AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'PRIMARY KEY (empresa_id, sessao_id)'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: idempotency primary key';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.importar_leads_batch_idempotency'::pg_catalog.regclass
      AND c.conname = 'importar_leads_batch_idempotency_lista_empresa_fkey'
      AND pg_catalog.pg_get_constraintdef(c.oid, true) =
          'FOREIGN KEY (lista_id, empresa_id) REFERENCES listas(id, empresa_id) ON DELETE CASCADE'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: composite list/tenant FK';
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
        OR p.proconfig IS DISTINCT FROM ARRAY['search_path=pg_catalog']::text[]
      )
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: hardened function metadata';
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
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: hardened function grants';
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
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: PUBLIC function EXECUTE exists';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_constraint c
    WHERE c.conrelid = 'public.logs'::pg_catalog.regclass
      AND c.conname = 'logs_sessao_id_unique'
      AND pg_catalog.pg_get_constraintdef(c.oid, true) = 'UNIQUE (sessao_id)'
  ) THEN
    RAISE EXCEPTION 'F1-02/PR-07 postflight failed: logs_sessao_id_unique changed';
  END IF;
END
$postflight$;

COMMIT;
