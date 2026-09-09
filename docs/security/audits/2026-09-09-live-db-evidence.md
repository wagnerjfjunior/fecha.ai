L0001 ## E00 - Identidade e cobertura live
L0002 Repository: wagnerjfjunior/fecha.ai
L0003 Main: ac20a30fea9095f036d8d466e83794432d58ca89
L0004 Supabase project: uobxxgzshrmbtjfdolxd / Discador-MesaCliente
L0005 public tables: 44; RLS enabled: 44
L0006 public views: 8
L0007 public functions: 160; SECURITY DEFINER: 137
L0008 anon-executable public functions: 31; anon+DEFINER: 22; mutation-hint: 9
L0009 public policies: 82; triggers: 31; constraints: 271
L0010 authenticated direct-write public tables: 7
L0011 anon direct public table privileges: 0
L0012
L0013 ## E01 - public.aprovar_rejeitar_mesa live
L0014 SECURITY DEFINER; authenticated EXECUTE=true; anon EXECUTE=false
L0015 IF NOT is_gestor() THEN RAISE EXCEPTION ...
L0016 SELECT empresa_id INTO v_empresa_id FROM mesa_simulacoes WHERE id = p_simulacao_id;
L0017 UPDATE mesa_simulacoes
L0018 SET status = v_novo_status, updated_at = now(), ...
L0019 WHERE id = p_simulacao_id;
L0020 INSERT INTO audit_logs (empresa_id,usuario_id,...)
L0021 VALUES (v_empresa_id,auth.uid(),...);
L0022 No predicate binds p_simulacao_id to actor empresa/time/ownership before UPDATE.
L0023
L0024 ## E02 - public.relatorio_fornecedor live
L0025 SECURITY DEFINER; authenticated EXECUTE=true
L0026 Guard: is_gestor()
L0027 Input: p_lista_id uuid
L0028 Reads public.listas WHERE id=p_lista_id
L0029 Reads public.leads WHERE lista_id=p_lista_id
L0030 Reads public.lista_avaliacoes WHERE lista_id=p_lista_id
L0031 No actor empresa/time/list authorization predicate is present.
L0032 Canonical classification already marks cross-tenant scope risk as BLOCKING.
L0033
L0034 ## E03 - global dashboard RPCs live
L0035 public.get_dashboard_master(): SECURITY DEFINER; authenticated EXECUTE=true
L0036 Guard: is_gestor()
L0037 Aggregates FROM leads without empresa_id predicate
L0038 Aggregates FROM listas without empresa_id predicate
L0039 Aggregates corretores LEFT JOIN leads without tenant predicate
L0040
L0041 public.get_stats_horario(): SECURITY DEFINER; authenticated EXECUTE=true
L0042 Guard: is_gestor() OR is_root()
L0043 Aggregates FROM leads for last 7/14 days without empresa_id predicate
L0044
L0045 ## E04 - public.lista_avaliacoes live
L0046 authenticated privileges: SELECT, INSERT, UPDATE
L0047 RLS enabled=true; FORCE RLS=true
L0048 INSERT policy WITH CHECK: corretor_id = my_corretor_id()
L0049 UPDATE policy USING: corretor_id = my_corretor_id(); no independent tenant/object check
L0050 SELECT policy: is_root() OR empresa_id = my_empresa_id()
L0051 FKs:
L0052   corretor_id -> corretores(id)
L0053   empresa_id -> empresas(id)
L0054   lista_id -> listas(id)
L0055   lote_id -> lotes(id)
L0056 No composite tenant FK. Only non-internal trigger is updated_at.
L0057
L0058 ## E05 - PME catalogs live
L0059 Direct authenticated INSERT/UPDATE: pme_message_templates, pme_call_scripts, pme_cadences, pme_cadence_steps
L0060 INSERT/UPDATE policies gate only pme_is_empresa_admin(empresa_id)
L0061 Relevant FKs are simple:
L0062   pme_cadence_steps.cadence_id -> pme_cadences(id)
L0063   pme_* .empreendimento_id -> empreendimentos(id)
L0064   pme_* .created_by / updated_by -> corretores(id)
L0065 No composite FK includes empresa_id for those related IDs.
L0066 PME catalog triggers observed are pme_set_updated_at only.
L0067
L0068 ## E06 - public.lead_tem_acao_real live
L0069 SECURITY DEFINER; authenticated EXECUTE=true
L0070 Input: p_lead_id uuid
L0071 No caller/tenant/ownership guard in body.
L0072 Reads public.leads by id and returns a boolean derived from lead state.
L0073 Canonical classification labels it DB_INTERNAL while direct authenticated EXECUTE remains an ACL/class residual.
L0074
L0075 ## E07 - public.acquire_lote_lock live
L0076 SECURITY DEFINER; anon EXECUTE=true; authenticated EXECUTE=true
L0077 Inputs: p_corretor_id uuid, p_empresa_id uuid
L0078 No auth.uid() check.
L0079 Computes deterministic key from supplied UUID pair and executes pg_advisory_xact_lock.
L0080 Canonical target: DB_INTERNAL_HELPER / NO DIRECT CLIENT EXECUTE.
L0081
L0082 ## E08 - default privileges live
L0083 Owner postgres / schema public:
L0084   default relations: broad privileges to anon, authenticated, service_role
L0085   default functions: EXECUTE to anon, authenticated, service_role
L0086 Owner supabase_admin also has broad client default ACLs in public.
L0087 Current mitigation: 44/44 public tables have RLS.
L0088 Future risk: newly created public relation starts without RLS unless migration hardens it explicitly.
L0089
L0090 ## E09 - non-public schemas
L0091 auth: 23 tables; 16 RLS; 7 no RLS (vendor-managed)
L0092 storage: 8/8 tables RLS-enabled; client role table ACLs exist and are subject to storage RLS
L0093 realtime: messages RLS-enabled; subscription/vendor relations differ
L0094 extensions: pg_stat_statements views have client ACLs in catalog
L0095 No finding is asserted solely from those ACLs because API schema exposure/runtime reachability was not proven.
