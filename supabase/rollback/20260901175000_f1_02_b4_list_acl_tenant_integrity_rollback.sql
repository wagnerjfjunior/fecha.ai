-- FECH.AI — F1-02/B4 / PR-06 rollback
-- Restores the exact pre-B4 database function definitions and boundary.
-- This reopens vulnerable authenticated write/helper surfaces.
-- SECURITY_GO remains DENIED. No data repair is performed.

BEGIN;

DROP TRIGGER IF EXISTS trg_f1_02_b4_lista_visibilidade_target_integrity
ON public.lista_visibilidade;

DROP FUNCTION IF EXISTS public.f1_02_b4_validate_lista_visibilidade_target();

ALTER TABLE public.lista_visibilidade
  DROP CONSTRAINT IF EXISTS lista_visibilidade_lista_id_empresa_id_fkey;

ALTER TABLE public.lista_visibilidade
  ADD CONSTRAINT lista_visibilidade_lista_id_fkey
  FOREIGN KEY (lista_id)
  REFERENCES public.listas (id)
  ON DELETE CASCADE;

ALTER TABLE public.lista_visibilidade
  DROP CONSTRAINT lista_visibilidade_target_type_check;

ALTER TABLE public.lista_visibilidade
  ADD CONSTRAINT lista_visibilidade_target_type_check
  CHECK (target_type IN ('corretor','time','empresa'));

-- Exact pre-B4 pg_get_functiondef() snapshots follow.
CREATE OR REPLACE FUNCTION public.corretor_tem_acesso_lista(p_lista_id uuid, p_corretor_id uuid, p_empresa_id uuid, p_time_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.listas li
    WHERE li.id = p_lista_id
      AND li.status = 'ativa'
      AND (
        li.escopo_distribuicao = 'global'
        OR (li.escopo_distribuicao = 'empresa' AND li.empresa_id = p_empresa_id)
        OR (li.escopo_distribuicao = 'time'    AND li.time_id    = p_time_id)
        OR (li.escopo_distribuicao = 'selecionados' AND EXISTS (
          SELECT 1 FROM public.lista_visibilidade lv
          WHERE lv.lista_id = li.id
            AND (
              (lv.target_type = 'corretor' AND lv.target_id = p_corretor_id)
              OR (lv.target_type = 'time'    AND lv.target_id = p_time_id)
              OR (lv.target_type = 'empresa' AND lv.target_id = p_empresa_id)
            )
        ))
      )
  );
$function$
;
CREATE OR REPLACE FUNCTION public.gerenciar_visibilidade_lista(p_lista_id uuid, p_targets jsonb DEFAULT NULL::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_corretor_id  uuid;
  v_empresa_id   uuid;
  v_time_id      uuid;
  v_is_admin     boolean;
  v_is_gestor    boolean;
  v_lista        record;
  v_membros      jsonb;
  v_selecionados jsonb;
  v_time_info    jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('error', 'Autenticação obrigatória');
  END IF;

  SELECT c.id, c.empresa_id, c.time_id,
    (c.role IN ('admin_local','admin_global') OR coalesce(c.is_admin_local,false) OR public.is_root()),
    (c.role = 'gestor' OR coalesce(c.is_gestor,false))
  INTO v_corretor_id, v_empresa_id, v_time_id, v_is_admin, v_is_gestor
  FROM public.corretores c
  WHERE c.user_id = auth.uid()
    AND coalesce(c.ativo, true) = true
  LIMIT 1;

  IF NOT (v_is_admin OR v_is_gestor OR public.is_root()) THEN
    RETURN jsonb_build_object('error', 'Sem permissão');
  END IF;

  -- Buscar lista com permissão
  SELECT li.id, li.nome_fornecedor, li.time_id, li.escopo_distribuicao, li.origem_nivel
  INTO v_lista
  FROM public.listas li
  WHERE li.id = p_lista_id
    AND li.empresa_id = v_empresa_id
    AND (
      public.is_root()
      OR v_is_admin
      OR li.uploaded_by = v_corretor_id
      OR li.time_id IN (SELECT id FROM public.times WHERE gestor_id = v_corretor_id)
    )
  LIMIT 1;

  IF v_lista.id IS NULL THEN
    RETURN jsonb_build_object('error', 'Lista não encontrada ou sem permissão');
  END IF;

  -- Info do time dono da lista
  SELECT jsonb_build_object(
    'id',           t.id,
    'nome',         t.nome,
    'gestor',       g.nome,
    'membros_count', (
      SELECT COUNT(*) FROM public.corretores c
      WHERE c.time_id = t.id
        AND coalesce(c.ativo, true) = true
        AND c.id != t.gestor_id
    )
  )
  INTO v_time_info
  FROM public.times t
  JOIN public.corretores g ON g.id = t.gestor_id
  WHERE t.id = v_lista.time_id;

  -- ── ESCRITA ───────────────────────────────────────────────────────────────
  IF p_targets IS NOT NULL THEN
    DECLARE
      v_target      jsonb;
      v_novo_escopo text;
      v_tem_empresa boolean;
    BEGIN
      -- Validar targets
      FOR v_target IN SELECT * FROM jsonb_array_elements(p_targets)
      LOOP
        IF (v_target->>'target_type') NOT IN ('corretor','time','empresa') THEN
          RETURN jsonb_build_object('error', 'target_type inválido: ' || (v_target->>'target_type'));
        END IF;
        IF NOT v_is_admin AND (v_target->>'target_type') = 'empresa' THEN
          RETURN jsonb_build_object('error', 'Gestor não pode definir escopo empresa');
        END IF;
      END LOOP;

      SELECT EXISTS (
        SELECT 1 FROM jsonb_array_elements(p_targets) t
        WHERE t->>'target_type' = 'empresa'
      ) INTO v_tem_empresa;

      IF jsonb_array_length(p_targets) = 0 THEN
        v_novo_escopo := 'time';
      ELSIF v_tem_empresa THEN
        v_novo_escopo := 'empresa';
      ELSE
        v_novo_escopo := 'selecionados';
      END IF;

      UPDATE public.listas SET escopo_distribuicao = v_novo_escopo
      WHERE id = p_lista_id AND empresa_id = v_empresa_id;

      DELETE FROM public.lista_visibilidade WHERE lista_id = p_lista_id;

      IF v_novo_escopo = 'selecionados' THEN
        INSERT INTO public.lista_visibilidade (lista_id, target_type, target_id, adicionado_por, empresa_id)
        SELECT p_lista_id, t->>'target_type', (t->>'target_id')::uuid, v_corretor_id, v_empresa_id
        FROM jsonb_array_elements(p_targets) t
        ON CONFLICT (lista_id, target_type, target_id) DO NOTHING;
      END IF;

      -- Atualizar para retornar novo escopo
      v_lista.escopo_distribuicao := v_novo_escopo;

      INSERT INTO public.audit_logs(
        empresa_id, action, acao, entidade, entidade_id,
        ator_user_id, actor_id, actor_email, payload
      )
      SELECT v_empresa_id, 'visibilidade_lista', 'visibilidade_lista', 'listas', p_lista_id,
        auth.uid(), auth.uid(), c.email,
        jsonb_build_object('lista', v_lista.nome_fornecedor, 'escopo', v_novo_escopo, 'targets', p_targets)
      FROM public.corretores c WHERE c.id = v_corretor_id;
    END;
  END IF;

  -- ── LEITURA ───────────────────────────────────────────────────────────────
  -- Membros disponíveis para seleção
  IF v_is_admin THEN
    SELECT COALESCE(jsonb_agg(sub ORDER BY sub->>'tipo' DESC, sub->>'nome' ASC), '[]')
    INTO v_membros
    FROM (
      SELECT jsonb_build_object('id',t.id,'nome',t.nome,'tipo','time',
        'extra',jsonb_build_object('gestor',g.nome,'corretores',
          (SELECT COUNT(*) FROM public.corretores c2 WHERE c2.time_id=t.id AND c2.id!=t.gestor_id)
        )) AS sub
      FROM public.times t JOIN public.corretores g ON g.id=t.gestor_id
      WHERE t.empresa_id=v_empresa_id
      UNION ALL
      SELECT jsonb_build_object('id',c.id,'nome',c.nome,'tipo','corretor',
        'extra',jsonb_build_object('email',c.email))
      FROM public.corretores c
      WHERE c.empresa_id=v_empresa_id AND coalesce(c.ativo,true)=true
        AND c.role NOT IN ('admin_global') AND c.id!=v_corretor_id
    ) sub;
  ELSE
    SELECT COALESCE(jsonb_agg(jsonb_build_object('id',c.id,'nome',c.nome,'tipo','corretor',
      'extra',jsonb_build_object('email',c.email)) ORDER BY c.nome), '[]')
    INTO v_membros
    FROM public.corretores c
    WHERE c.time_id=v_time_id AND c.empresa_id=v_empresa_id
      AND coalesce(c.ativo,true)=true AND c.id!=v_corretor_id;
  END IF;

  -- ACL atual
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'target_type',lv.target_type,'target_id',lv.target_id)), '[]')
  INTO v_selecionados
  FROM public.lista_visibilidade lv WHERE lv.lista_id=p_lista_id;

  RETURN jsonb_build_object(
    'lista_id',    p_lista_id,
    'lista_nome',  v_lista.nome_fornecedor,
    'escopo_atual',v_lista.escopo_distribuicao,
    'time_info',   v_time_info,
    'membros',     COALESCE(v_membros,'[]'),
    'selecionados',v_selecionados
  );

EXCEPTION
  WHEN others THEN
    RETURN jsonb_build_object('error','Erro interno: '||SQLERRM);
END;
$function$
;
CREATE OR REPLACE FUNCTION public.listar_membros_visibilidade()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_corretor_id uuid;
  v_empresa_id  uuid;
  v_time_id     uuid;
  v_is_admin    boolean;
  v_is_gestor   boolean;
  v_membros     jsonb;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('error', 'Autenticação obrigatória');
  END IF;

  SELECT c.id, c.empresa_id, c.time_id,
    (c.role IN ('admin_local','admin_global') OR coalesce(c.is_admin_local,false) OR public.is_root()),
    (c.role = 'gestor' OR coalesce(c.is_gestor,false))
  INTO v_corretor_id, v_empresa_id, v_time_id, v_is_admin, v_is_gestor
  FROM public.corretores c
  WHERE c.user_id = auth.uid()
    AND coalesce(c.ativo, true) = true
  LIMIT 1;

  IF NOT (v_is_admin OR v_is_gestor OR public.is_root()) THEN
    RETURN jsonb_build_object('error', 'Sem permissão');
  END IF;

  IF v_is_admin OR public.is_root() THEN
    -- Admin vê times + corretores da empresa
    SELECT COALESCE(jsonb_agg(sub ORDER BY sub->>'tipo' DESC, sub->>'nome' ASC), '[]')
    INTO v_membros
    FROM (
      SELECT jsonb_build_object(
        'id',    t.id,
        'nome',  t.nome,
        'tipo',  'time',
        'extra', jsonb_build_object(
          'gestor',     g.nome,
          'corretores', (SELECT COUNT(*) FROM public.corretores c2 WHERE c2.time_id = t.id AND c2.id != t.gestor_id)
        )
      ) AS sub
      FROM public.times t
      JOIN public.corretores g ON g.id = t.gestor_id
      WHERE t.empresa_id = v_empresa_id
      UNION ALL
      SELECT jsonb_build_object(
        'id',    c.id,
        'nome',  c.nome,
        'tipo',  'corretor',
        'extra', jsonb_build_object('email', c.email)
      )
      FROM public.corretores c
      WHERE c.empresa_id = v_empresa_id
        AND coalesce(c.ativo, true) = true
        AND c.role NOT IN ('admin_global')
        AND c.id != v_corretor_id
    ) sub;
  ELSE
    -- Gestor vê só corretores do próprio time
    SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'id',    c.id,
      'nome',  c.nome,
      'tipo',  'corretor',
      'extra', jsonb_build_object('email', c.email)
    ) ORDER BY c.nome ASC), '[]')
    INTO v_membros
    FROM public.corretores c
    WHERE c.time_id    = v_time_id
      AND c.empresa_id = v_empresa_id
      AND coalesce(c.ativo, true) = true
      AND c.id != v_corretor_id;
  END IF;

  RETURN jsonb_build_object('membros', COALESCE(v_membros, '[]'));

EXCEPTION
  WHEN others THEN
    RETURN jsonb_build_object('error', 'Erro interno: ' || SQLERRM);
END;
$function$
;

GRANT INSERT, UPDATE, DELETE
ON TABLE public.lista_visibilidade
TO authenticated;

GRANT EXECUTE
ON FUNCTION public.corretor_tem_acesso_lista(uuid, uuid, uuid, uuid)
TO authenticated, service_role;
REVOKE EXECUTE
ON FUNCTION public.corretor_tem_acesso_lista(uuid, uuid, uuid, uuid)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.gerenciar_visibilidade_lista(uuid, jsonb)
TO authenticated, service_role;
REVOKE EXECUTE
ON FUNCTION public.gerenciar_visibilidade_lista(uuid, jsonb)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.listar_membros_visibilidade()
TO authenticated, service_role;
REVOKE EXECUTE
ON FUNCTION public.listar_membros_visibilidade()
FROM PUBLIC, anon;

COMMIT;
