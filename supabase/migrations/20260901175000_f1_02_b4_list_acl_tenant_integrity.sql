-- FECH.AI — F1-02/B4 / PR-06
-- Tenant-safe list visibility.
-- No data repair. Runtime-negative PASS is NOT established. SECURITY_GO remains DENIED.

BEGIN;

DO $preflight$
BEGIN
  IF EXISTS (SELECT 1 FROM public.lista_visibilidade WHERE target_type = 'empresa') THEN
    RAISE EXCEPTION 'F1-02/B4 preflight failed: empresa ACL target exists';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.lista_visibilidade lv
    LEFT JOIN public.listas li ON li.id = lv.lista_id
    WHERE li.id IS NULL OR li.empresa_id IS DISTINCT FROM lv.empresa_id
  ) THEN
    RAISE EXCEPTION 'F1-02/B4 preflight failed: list/company ACL mismatch exists';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.lista_visibilidade lv
    LEFT JOIN public.corretores c
      ON lv.target_type = 'corretor' AND c.id = lv.target_id
    WHERE lv.target_type = 'corretor'
      AND (c.id IS NULL OR c.empresa_id IS DISTINCT FROM lv.empresa_id
           OR coalesce(c.ativo, true) IS DISTINCT FROM true)
  ) THEN
    RAISE EXCEPTION 'F1-02/B4 preflight failed: invalid broker ACL target exists';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.lista_visibilidade lv
    LEFT JOIN public.times t
      ON lv.target_type = 'time' AND t.id = lv.target_id
    WHERE lv.target_type = 'time'
      AND (t.id IS NULL OR t.empresa_id IS DISTINCT FROM lv.empresa_id
           OR coalesce(t.ativo, true) IS DISTINCT FROM true)
  ) THEN
    RAISE EXCEPTION 'F1-02/B4 preflight failed: invalid team ACL target exists';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.lista_visibilidade
    WHERE target_type NOT IN ('corretor','time')
       OR target_type IS NULL OR target_id IS NULL
       OR lista_id IS NULL OR empresa_id IS NULL
  ) THEN
    RAISE EXCEPTION 'F1-02/B4 preflight failed: unsupported/null ACL identity exists';
  END IF;
END
$preflight$;

REVOKE INSERT, UPDATE, DELETE
ON TABLE public.lista_visibilidade
FROM authenticated;

ALTER TABLE public.lista_visibilidade
  DROP CONSTRAINT lista_visibilidade_lista_id_fkey;

ALTER TABLE public.lista_visibilidade
  ADD CONSTRAINT lista_visibilidade_lista_id_empresa_id_fkey
  FOREIGN KEY (lista_id, empresa_id)
  REFERENCES public.listas (id, empresa_id)
  ON DELETE CASCADE;

ALTER TABLE public.lista_visibilidade
  DROP CONSTRAINT lista_visibilidade_target_type_check;

ALTER TABLE public.lista_visibilidade
  ADD CONSTRAINT lista_visibilidade_target_type_check
  CHECK (target_type IN ('corretor','time'));

CREATE OR REPLACE FUNCTION public.f1_02_b4_validate_lista_visibilidade_target()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.lista_id IS NULL OR NEW.empresa_id IS NULL
     OR NEW.target_type IS NULL OR NEW.target_id IS NULL THEN
    RAISE EXCEPTION 'Invalid list visibility identity';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.listas li
    WHERE li.id = NEW.lista_id AND li.empresa_id = NEW.empresa_id
  ) THEN
    RAISE EXCEPTION 'List/company mismatch';
  END IF;

  IF NEW.target_type = 'corretor' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.corretores c
      WHERE c.id = NEW.target_id
        AND c.empresa_id = NEW.empresa_id
        AND coalesce(c.ativo, true) = true
    ) THEN
      RAISE EXCEPTION 'Invalid broker visibility target';
    END IF;
  ELSIF NEW.target_type = 'time' THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.times t
      WHERE t.id = NEW.target_id
        AND t.empresa_id = NEW.empresa_id
        AND coalesce(t.ativo, true) = true
    ) THEN
      RAISE EXCEPTION 'Invalid team visibility target';
    END IF;
  ELSE
    RAISE EXCEPTION 'Unsupported visibility target type';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL
ON FUNCTION public.f1_02_b4_validate_lista_visibilidade_target()
FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_f1_02_b4_lista_visibilidade_target_integrity
ON public.lista_visibilidade;

CREATE TRIGGER trg_f1_02_b4_lista_visibilidade_target_integrity
BEFORE INSERT OR UPDATE ON public.lista_visibilidade
FOR EACH ROW
EXECUTE FUNCTION public.f1_02_b4_validate_lista_visibilidade_target();

CREATE OR REPLACE FUNCTION public.corretor_tem_acesso_lista(
  p_lista_id uuid,
  p_corretor_id uuid,
  p_empresa_id uuid,
  p_time_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
  WITH broker AS (
    SELECT c.id, c.empresa_id, c.time_id
    FROM public.corretores c
    WHERE c.id = p_corretor_id
      AND c.empresa_id = p_empresa_id
      AND coalesce(c.ativo, true) = true
      AND c.time_id IS NOT DISTINCT FROM p_time_id
  )
  SELECT EXISTS (
    SELECT 1
    FROM public.listas li
    JOIN broker b ON true
    WHERE li.id = p_lista_id
      AND li.empresa_id = p_empresa_id
      AND li.status = 'ativa'
      AND (
        li.escopo_distribuicao = 'global'
        OR li.escopo_distribuicao = 'empresa'
        OR (li.escopo_distribuicao = 'time' AND li.time_id = b.time_id)
        OR (
          li.escopo_distribuicao = 'selecionados'
          AND EXISTS (
            SELECT 1
            FROM public.lista_visibilidade lv
            WHERE lv.lista_id = li.id
              AND lv.empresa_id = li.empresa_id
              AND (
                (lv.target_type = 'corretor' AND lv.target_id = b.id)
                OR (lv.target_type = 'time' AND lv.target_id = b.time_id)
              )
          )
        )
      )
  );
$function$;

REVOKE ALL
ON FUNCTION public.corretor_tem_acesso_lista(uuid, uuid, uuid, uuid)
FROM PUBLIC, anon, authenticated;

GRANT EXECUTE
ON FUNCTION public.corretor_tem_acesso_lista(uuid, uuid, uuid, uuid)
TO service_role;

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
    SELECT COALESCE(jsonb_agg(sub ORDER BY sub->>'tipo' DESC, sub->>'nome' ASC), '[]')
    INTO v_membros
    FROM (
      SELECT jsonb_build_object(
        'id',t.id,'nome',t.nome,'tipo','time',
        'extra',jsonb_build_object(
          'gestor',g.nome,
          'corretores',(SELECT COUNT(*) FROM public.corretores c2
                        WHERE c2.time_id=t.id AND c2.id!=t.gestor_id)
        )
      ) AS sub
      FROM public.times t
      JOIN public.corretores g ON g.id=t.gestor_id
      WHERE t.empresa_id=v_empresa_id
      UNION ALL
      SELECT jsonb_build_object(
        'id',c.id,'nome',c.nome,'tipo','corretor',
        'extra',jsonb_build_object('email',c.email)
      )
      FROM public.corretores c
      WHERE c.empresa_id=v_empresa_id
        AND coalesce(c.ativo,true)=true
        AND c.role NOT IN ('admin_global')
        AND c.id!=v_corretor_id
    ) sub;
  ELSE
    SELECT COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id',c.id,'nome',c.nome,'tipo','corretor',
          'extra',jsonb_build_object('email',c.email)
        )
        ORDER BY c.nome ASC
      ),
      '[]'
    )
    INTO v_membros
    FROM public.corretores c
    WHERE c.empresa_id=v_empresa_id
      AND coalesce(c.ativo,true)=true
      AND c.id!=v_corretor_id
      AND EXISTS (
        SELECT 1
        FROM public.times t
        WHERE t.id=c.time_id
          AND t.gestor_id=v_corretor_id
          AND t.empresa_id=v_empresa_id
          AND coalesce(t.ativo,true)=true
      );
  END IF;

  RETURN jsonb_build_object('membros', COALESCE(v_membros, '[]'));

EXCEPTION
  WHEN others THEN
    RETURN jsonb_build_object('error', 'Erro interno: ' || SQLERRM);
END;
$function$;

REVOKE EXECUTE
ON FUNCTION public.listar_membros_visibilidade()
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.listar_membros_visibilidade()
TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.gerenciar_visibilidade_lista(
  p_lista_id uuid,
  p_targets jsonb DEFAULT NULL::jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_corretor_id uuid;
  v_empresa_id uuid;
  v_time_id uuid;
  v_is_root boolean;
  v_is_admin boolean;
  v_is_gestor boolean;
  v_lista record;
  v_membros jsonb;
  v_selecionados jsonb;
  v_time_info jsonb;
  v_target jsonb;
  v_target_type text;
  v_target_id_text text;
  v_target_id uuid;
  v_novo_escopo text;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('error', 'Autenticação obrigatória');
  END IF;

  v_is_root := public.is_root();

  SELECT c.id, c.empresa_id, c.time_id,
    (c.role IN ('admin_local','admin_global') OR coalesce(c.is_admin_local,false) OR v_is_root),
    (c.role='gestor' OR coalesce(c.is_gestor,false))
  INTO v_corretor_id, v_empresa_id, v_time_id, v_is_admin, v_is_gestor
  FROM public.corretores c
  WHERE c.user_id=auth.uid() AND coalesce(c.ativo,true)=true
  LIMIT 1;

  IF v_corretor_id IS NULL OR v_empresa_id IS NULL THEN
    RETURN jsonb_build_object('error','Perfil de usuário não encontrado, inativo ou sem empresa');
  END IF;

  IF NOT (v_is_admin OR v_is_gestor OR v_is_root) THEN
    RETURN jsonb_build_object('error','Sem permissão');
  END IF;

  IF p_targets IS NULL THEN
    SELECT li.id,li.nome_fornecedor,li.time_id,li.escopo_distribuicao,li.origem_nivel
    INTO v_lista
    FROM public.listas li
    WHERE li.id=p_lista_id
      AND li.empresa_id=v_empresa_id
      AND (
        v_is_root OR v_is_admin
        OR (v_is_gestor AND li.time_id=ANY(public.my_times_como_gestor()))
      )
    LIMIT 1;
  ELSE
    SELECT li.id,li.nome_fornecedor,li.time_id,li.escopo_distribuicao,li.origem_nivel
    INTO v_lista
    FROM public.listas li
    WHERE li.id=p_lista_id
      AND li.empresa_id=v_empresa_id
      AND (
        v_is_root OR v_is_admin
        OR (v_is_gestor AND li.time_id=ANY(public.my_times_como_gestor()))
      )
    LIMIT 1
    FOR UPDATE;
  END IF;

  IF v_lista.id IS NULL THEN
    RETURN jsonb_build_object('error','Lista não encontrada ou sem permissão');
  END IF;

  SELECT jsonb_build_object(
    'id',t.id,'nome',t.nome,'gestor',g.nome,
    'membros_count',(
      SELECT COUNT(*) FROM public.corretores c
      WHERE c.time_id=t.id AND coalesce(c.ativo,true)=true AND c.id!=t.gestor_id
    )
  )
  INTO v_time_info
  FROM public.times t
  JOIN public.corretores g ON g.id=t.gestor_id
  WHERE t.id=v_lista.time_id;

  IF p_targets IS NOT NULL THEN
    IF jsonb_typeof(p_targets) IS DISTINCT FROM 'array' THEN
      RETURN jsonb_build_object('error','Targets devem ser um array');
    END IF;

    FOR v_target IN SELECT value FROM jsonb_array_elements(p_targets)
    LOOP
      IF jsonb_typeof(v_target) IS DISTINCT FROM 'object' THEN
        RETURN jsonb_build_object('error','Target inválido');
      END IF;

      v_target_type:=v_target->>'target_type';
      v_target_id_text:=v_target->>'target_id';

      IF v_target_type IS NULL OR v_target_id_text IS NULL OR trim(v_target_id_text)='' THEN
        RETURN jsonb_build_object('error','target_type e target_id são obrigatórios');
      END IF;

      IF v_target_type NOT IN ('corretor','time') THEN
        RETURN jsonb_build_object('error','target_type inválido: '||v_target_type);
      END IF;

      BEGIN
        v_target_id:=v_target_id_text::uuid;
      EXCEPTION WHEN invalid_text_representation THEN
        RETURN jsonb_build_object('error','target_id inválido');
      END;

      IF v_target_type='corretor' THEN
        IF NOT EXISTS (
          SELECT 1 FROM public.corretores c
          WHERE c.id=v_target_id AND c.empresa_id=v_empresa_id
            AND coalesce(c.ativo,true)=true
        ) THEN
          RETURN jsonb_build_object('error','Corretor alvo inválido, inativo ou de outra empresa');
        END IF;

        IF v_is_gestor AND NOT v_is_admin AND NOT v_is_root THEN
          IF NOT EXISTS (
            SELECT 1
            FROM public.corretores c
            JOIN public.times t ON t.id=c.time_id
            WHERE c.id=v_target_id
              AND c.empresa_id=v_empresa_id
              AND coalesce(c.ativo,true)=true
              AND t.gestor_id=v_corretor_id
              AND t.empresa_id=v_empresa_id
              AND coalesce(t.ativo,true)=true
          ) THEN
            RETURN jsonb_build_object('error','Gestor só pode selecionar corretores de times que administra');
          END IF;
        END IF;
      ELSE
        IF v_is_gestor AND NOT v_is_admin AND NOT v_is_root THEN
          RETURN jsonb_build_object('error','Gestor não pode selecionar time inteiro nesta versão');
        END IF;

        IF NOT EXISTS (
          SELECT 1 FROM public.times t
          WHERE t.id=v_target_id AND t.empresa_id=v_empresa_id
            AND coalesce(t.ativo,true)=true
        ) THEN
          RETURN jsonb_build_object('error','Time alvo inválido, inativo ou de outra empresa');
        END IF;
      END IF;
    END LOOP;

    IF jsonb_array_length(p_targets)=0 THEN
      IF v_is_gestor AND NOT v_is_admin AND NOT v_is_root THEN
        v_novo_escopo:='time';
      ELSE
        v_novo_escopo:='empresa';
      END IF;
    ELSE
      v_novo_escopo:='selecionados';
    END IF;

    UPDATE public.listas
    SET escopo_distribuicao=v_novo_escopo
    WHERE id=p_lista_id AND empresa_id=v_empresa_id;

    DELETE FROM public.lista_visibilidade
    WHERE lista_id=p_lista_id AND empresa_id=v_empresa_id;

    IF v_novo_escopo='selecionados' THEN
      INSERT INTO public.lista_visibilidade(
        lista_id,target_type,target_id,adicionado_por,empresa_id
      )
      SELECT DISTINCT
        p_lista_id,
        t.value->>'target_type',
        (t.value->>'target_id')::uuid,
        v_corretor_id,
        v_empresa_id
      FROM jsonb_array_elements(p_targets) AS t(value);
    END IF;

    v_lista.escopo_distribuicao:=v_novo_escopo;

    INSERT INTO public.audit_logs(
      empresa_id,action,acao,entidade,entidade_id,
      ator_user_id,actor_id,actor_email,payload
    )
    SELECT
      v_empresa_id,'visibilidade_lista','visibilidade_lista','listas',p_lista_id,
      auth.uid(),auth.uid(),c.email,
      jsonb_build_object(
        'lista',v_lista.nome_fornecedor,'escopo',v_novo_escopo,'targets',p_targets
      )
    FROM public.corretores c
    WHERE c.id=v_corretor_id;
  END IF;

  IF v_is_admin OR v_is_root THEN
    SELECT COALESCE(jsonb_agg(sub ORDER BY sub->>'tipo' DESC,sub->>'nome' ASC),'[]')
    INTO v_membros
    FROM (
      SELECT jsonb_build_object(
        'id',t.id,'nome',t.nome,'tipo','time',
        'extra',jsonb_build_object(
          'gestor',g.nome,
          'corretores',(SELECT COUNT(*) FROM public.corretores c2
                        WHERE c2.time_id=t.id AND c2.id!=t.gestor_id)
        )
      ) AS sub
      FROM public.times t
      JOIN public.corretores g ON g.id=t.gestor_id
      WHERE t.empresa_id=v_empresa_id
      UNION ALL
      SELECT jsonb_build_object(
        'id',c.id,'nome',c.nome,'tipo','corretor',
        'extra',jsonb_build_object('email',c.email)
      )
      FROM public.corretores c
      WHERE c.empresa_id=v_empresa_id
        AND coalesce(c.ativo,true)=true
        AND c.role NOT IN ('admin_global')
        AND c.id!=v_corretor_id
    ) sub;
  ELSE
    SELECT COALESCE(
      jsonb_agg(
        jsonb_build_object(
          'id',c.id,'nome',c.nome,'tipo','corretor',
          'extra',jsonb_build_object('email',c.email)
        )
        ORDER BY c.nome
      ),
      '[]'
    )
    INTO v_membros
    FROM public.corretores c
    WHERE c.empresa_id=v_empresa_id
      AND coalesce(c.ativo,true)=true
      AND c.id!=v_corretor_id
      AND EXISTS (
        SELECT 1 FROM public.times t
        WHERE t.id=c.time_id
          AND t.gestor_id=v_corretor_id
          AND t.empresa_id=v_empresa_id
          AND coalesce(t.ativo,true)=true
      );
  END IF;

  SELECT COALESCE(
    jsonb_agg(jsonb_build_object('target_type',lv.target_type,'target_id',lv.target_id)),
    '[]'
  )
  INTO v_selecionados
  FROM public.lista_visibilidade lv
  WHERE lv.lista_id=p_lista_id AND lv.empresa_id=v_empresa_id;

  RETURN jsonb_build_object(
    'lista_id',p_lista_id,
    'lista_nome',v_lista.nome_fornecedor,
    'escopo_atual',v_lista.escopo_distribuicao,
    'time_info',v_time_info,
    'membros',COALESCE(v_membros,'[]'),
    'selecionados',COALESCE(v_selecionados,'[]')
  );

EXCEPTION
  WHEN others THEN
    RETURN jsonb_build_object('error','Erro interno: '||SQLERRM);
END;
$function$;

REVOKE EXECUTE
ON FUNCTION public.gerenciar_visibilidade_lista(uuid, jsonb)
FROM PUBLIC, anon;

GRANT EXECUTE
ON FUNCTION public.gerenciar_visibilidade_lista(uuid, jsonb)
TO authenticated, service_role;

COMMIT;
