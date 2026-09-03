#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const root = process.cwd();

  const matrixText = await fs.readFile(path.join(root,"supabase/tests/f1-02-pr08/matrix.json"),"utf8");
  const matrix = JSON.parse(matrixText);
  const http = await fs.readFile(path.join(root,"scripts/tests/f1-02-pr08/run_auth_http_matrix.mjs"),"utf8");
  const rollback = await fs.readFile(path.join(root,"scripts/tests/f1-02-pr08/run_rollback_reapply.mjs"),"utf8");
  const sql = await fs.readFile(path.join(root,"supabase/tests/f1-02-pr08/runtime_security_matrix.sql"),"utf8");
  const sqlRuntime = await fs.readFile(path.join(root,"scripts/tests/f1-02-pr08/run_sql_runtime_matrix.mjs"),"utf8");

  // PR08 Phase 1 — execution authority + SQL safety anti-regression.
  const sqlRuntimeRecords=matrix.records.filter(r=>r.runner==="sql_runtime");
  if(sqlRuntimeRecords.length!==1) throw new Error("SQL_RUNTIME_RECORD_COUNT_DRIFT:"+sqlRuntimeRecords.length);
  for(const rec of sqlRuntimeRecords){
    if(rec.sql_plan?.file!=="supabase/tests/f1-02-pr08/runtime_security_matrix.sql") throw new Error("SQL_RUNTIME_ARTIFACT_DRIFT:"+rec.test_id);
    if(!sqlRuntime.includes('"'+rec.test_id+'"')) throw new Error("SQL_RUNTIME_WRAPPER_CASE_MISSING:"+rec.test_id);
  }

  const wrapperNeedles=[
    "PR08_SQL_RUNTIME_WRAPPER_V1",
    'process.env.FECHAI_PR08_SQL_RUNTIME_AUTHORIZED !== "YES"',
    "FECHAI_PR08_DATABASE_URL",
    "FECHAI_PR08_TARGET_PROJECT_REF",
    "PR08_SQL_CONNECTION_PROJECT_BINDING",
    "connectionProjectRef !== fixture.target_project_ref",
    "connectionProjectRef !== declaredProjectRef",
    'process.env.FECHAI_PR08_PRODUCTION_EXECUTION_AUTHORIZED !== "YES"',
    "PR08_SQL_SAME_VALIDATED_CONNECTION",
    "PGHOST:u.hostname",
    "PGDATABASE:decodeURIComponent",
    "PR08_EXPECTED_VALIDOS",
    "PR08_EXPECTED_INVALIDOS",
    "PR08_EXPECTED_DUPLICADOS"
  ];
  for(const n of wrapperNeedles) if(!sqlRuntime.includes(n)) throw new Error("SQL_RUNTIME_WRAPPER_CONTRACT_MISSING:"+n);

  // P1-B: validated DSN must also be the libpq execution target.
  for(const n of [
    "PR08_SQL_STRIP_INHERITED_LIBPQ_ENV",
    "Object.entries(process.env).filter(([key])=>!key.startsWith(\"PG\"))",
    "...inheritedEnv",
    "PGHOST:u.hostname",
    "PGPORT:u.port || \"5432\"",
    "PGDATABASE:decodeURIComponent",
    "PGUSER:decodeURIComponent",
    "PGPASSWORD:decodeURIComponent",
    "PGSSLMODE:u.searchParams.get(\"sslmode\") || \"require\""
  ]) if(!sqlRuntime.includes(n)) throw new Error("SQL_RUNTIME_LIBPQ_ENV_CONTRACT_MISSING:"+n);

  if(sqlRuntime.includes("...process.env")) throw new Error("SQL_RUNTIME_INHERITED_PROCESS_ENV_FORBIDDEN");
  const sqlRuntimeCodeOnly=sqlRuntime.split("\\n").filter(line=>!line.trim().startsWith("//")).join("\\n");
  for(const forbidden of ["PGHOSTADDR","PGSERVICE","PGSERVICEFILE"]) {
    if(sqlRuntimeCodeOnly.includes(forbidden)) throw new Error("SQL_RUNTIME_LIBPQ_REDIRECT_VAR_FORBIDDEN:"+forbidden);
  }

  const sqlPhase1Needles=[
    "PR08_PHASE1_SQL_AUTHORITY_V1",
    ":'PR08_SQL_RUNTIME_AUTHORIZED' = 'YES'",
    "pr08_sql_runtime_authorized",
    "pr08_host_project_matches",
    "db.uobxxgzshrmbtjfdolxd.supabase.co",
    ":'PR08_PRODUCTION_EXECUTION_AUTHORIZED' = 'YES'",
    "PR08_PHASE1_CLAIMANT_RESULT_CAPTURE",
    "PR08_PHASE1_CLAIMANT_SUCCESS_RESULT",
    "PR08_PHASE1_POSITIVE_LEAD_BEFORE_ROLLBACK",
    "PR08_PHASE1_POSITIVE_MARKER_BEFORE_ROLLBACK",
    "PR08_PHASE1_POSITIVE_AUDIT_BEFORE_ROLLBACK",
    "PR08_PHASE1_ROLLBACK_AFTER_POSITIVE_PROOF",
    "PR08_PHASE1_POST_ROLLBACK_RESIDUE_CHECKS"
  ];
  for(const n of sqlPhase1Needles) if(!sql.includes(n)) throw new Error("SQL_PHASE1_CONTRACT_MISSING:"+n);

  const captureAt=sql.indexOf("PR08_PHASE1_CLAIMANT_RESULT_CAPTURE");
  const resultAt=sql.indexOf("PR08_PHASE1_CLAIMANT_SUCCESS_RESULT");
  const leadAt=sql.indexOf("PR08_PHASE1_POSITIVE_LEAD_BEFORE_ROLLBACK");
  const markerAt=sql.indexOf("PR08_PHASE1_POSITIVE_MARKER_BEFORE_ROLLBACK");
  const auditAt=sql.indexOf("PR08_PHASE1_POSITIVE_AUDIT_BEFORE_ROLLBACK");
  const rollbackAt=sql.indexOf("PR08_PHASE1_ROLLBACK_AFTER_POSITIVE_PROOF");
  const residueAt=sql.indexOf("PR08_PHASE1_POST_ROLLBACK_RESIDUE_CHECKS");
  if(!(captureAt<resultAt&&resultAt<leadAt&&leadAt<markerAt&&markerAt<auditAt&&auditAt<rollbackAt&&rollbackAt<residueAt)) throw new Error("SQL_CLAIMANT_PROOF_ORDER_INVALID");

  if(!sql.includes("pg_catalog.jsonb_object_keys(:'pr08_claimant_rpc_result'::jsonb)")||
     !sql.includes("?& ARRAY['validos','invalidos','duplicados']::text[]")||
     !sql.includes("resultado = :'pr08_claimant_rpc_result'::jsonb")||
     !sql.includes("detalhes->'resultado' = :'pr08_claimant_rpc_result'::jsonb")) {
    throw new Error("SQL_CLAIMANT_POSITIVE_PROOF_INCOMPLETE");
  }

  const expected={AUTH:5,COR:13,CRM:15,FUN:8,ACL:10,STG:7,IMP:16,FDB:11,ROL:11,PRD:2,TOTAL:98};
  const counts={TOTAL:matrix.records.length};
  const ids=new Set();

  if(matrix.schema!=="fechai.f1-02.pr08.matrix.v7") throw new Error("MATRIX_SCHEMA_DRIFT");
  if(matrix.execution_contract?.failure_isolation!=="ALL_MUTATION_CAPABLE_HTTP_CASES_HAVE_SERVER_LIFECYCLE") throw new Error("FAILURE_ISOLATION_CONTRACT_MISSING");
  if(matrix.execution_contract?.cleanup_global_verification!=="CANONICAL_PUBLIC_RELATION_ROWS_PLUS_SEQUENCES_SHA256_MUST_EQUAL_ORIGINAL") throw new Error("GLOBAL_CLEANUP_HASH_CONTRACT_MISSING");
  if(matrix.execution_contract?.cleanup_fail_stop!=="NO_NEXT_CASE_AFTER_UNRESTORED_STATE") throw new Error("CLEANUP_FAIL_STOP_CONTRACT_MISSING");
  if(matrix.execution_contract?.token_topology_binding!=="EVERY_VALID_VERSIONED_REQUEST_TOKEN_REQUIRES_IDENTITY_TOPOLOGY") throw new Error("TOKEN_TOPOLOGY_CONTRACT_MISSING");
  if(matrix.execution_contract?.absence_topology_evidence!=="OWNER_SIDE_SERVER_ZERO_ROWS_WITH_BYPASSRLS") throw new Error("ABSENCE_TOPOLOGY_CONTRACT_MISSING");
  if(matrix.execution_contract?.conditional_tests!=="NOT_APPLICABLE_IS_NOT_PASS") throw new Error("CONDITIONAL_TEST_CONTRACT_MISSING");

  const sec=matrix.server_evidence_contract||{};
  if(sec.mode!=="PSQL_POSTGRES_OWNER_NON_PRODUCTION_ONLY") throw new Error("SERVER_EVIDENCE_MODE_DRIFT");
  if(sec.required_database_role!=="postgres") throw new Error("SERVER_EVIDENCE_ROLE_DRIFT");
  if(!Array.isArray(sec.required_role_attributes)||!sec.required_role_attributes.includes("rolbypassrls")) throw new Error("SERVER_EVIDENCE_BYPASSRLS_CONTRACT_MISSING");
  if(sec.production_project_ref_hard_deny!=="uobxxgzshrmbtjfdolxd") throw new Error("SERVER_EVIDENCE_PROD_DENY_DRIFT");
  if(sec.grants_rls_policies_changes!=="FORBIDDEN") throw new Error("SERVER_EVIDENCE_BOUNDARY_WIDENING");
  if(sec.full_public_data_hash!=="CANONICAL_PUBLIC_RELATION_ROWS_PLUS_SEQUENCES_SHA256") throw new Error("GLOBAL_DATA_HASH_MODE_DRIFT");
  if(sec.rollback_state_fingerprint!=="SCHEMA_DUMP_SHA256_PLUS_CANONICAL_PUBLIC_DATA_SHA256") throw new Error("ROLLBACK_STATE_FINGERPRINT_DRIFT");
  if(sec.rollback_schema_restrict_key!=="FECHAIPR08STATEHASH") throw new Error("ROLLBACK_SCHEMA_HASH_KEY_DRIFT");
  if(sec.absence_evidence!=="POSTGRES_OWNER_BYPASSRLS_ZERO_ROW_COUNT") throw new Error("ABSENCE_EVIDENCE_MODE_DRIFT");

  if(matrixText.includes("/rest/v1/importar_leads_batch_idempotency")||http.includes("/rest/v1/importar_leads_batch_idempotency")) {
    throw new Error("IDEMPOTENCY_REST_CLIENT_ACCESS_FORBIDDEN");
  }

  const topologyChecks=matrix.topology_contract?.checks||[];
  const topologyIds=new Set(topologyChecks.map(x=>x.check_id));
  if(!Array.isArray(matrix.topology_contract?.global_check_ids)) throw new Error("GLOBAL_TOPOLOGY_IDS_MISSING");
  for(const id of matrix.topology_contract.global_check_ids) if(!topologyIds.has(id)) throw new Error("UNKNOWN_GLOBAL_TOPOLOGY_CHECK:"+id);

  for(const check of topologyChecks){
    if(!check.check_id||!check.assertion?.mode) throw new Error("TOPOLOGY_CHECK_INVALID");
    if(check.request?.auth_token_var==="EVIDENCE_OBSERVER_TOKEN"&&["ZERO_ROWS","ROW_IDS_EQUAL_VAR_SET"].includes(check.assertion.mode)) throw new Error("OBSERVER_COMPLETENESS_ASSERTION_FORBIDDEN:"+check.check_id);
    if(["VARIABLE_NOT_EQUAL","SERVER_ROOT_AUTHORITY","SERVER_ZERO_ROWS_BY_UUID","SERVER_ROW_IDS_EQUAL_VAR_SET"].includes(check.assertion.mode)){
      if(check.request!==null) throw new Error("NON_HTTP_TOPOLOGY_REQUEST_MUST_BE_NULL:"+check.check_id);
      if(check.assertion.mode==="SERVER_ZERO_ROWS_BY_UUID"){const allowed=new Set(["public.corretores:user_id","public.corretores:id","public.funil_estagios:empresa_id"]);if(!allowed.has(check.assertion.table+":"+check.assertion.column)||!check.assertion.var) throw new Error("SERVER_ZERO_ROWS_TARGET_INVALID:"+check.check_id);}
      if(check.assertion.mode==="SERVER_ROW_IDS_EQUAL_VAR_SET"){
        const a=check.assertion;
        if(a.table!=="public.funil_estagios"||a.id_column!=="id"||a.where_column!=="empresa_id"||!a.where_var||!a.expected_ids_var) throw new Error("SERVER_ROW_IDS_SET_TARGET_INVALID:"+check.check_id);
      }
    } else {
      if(!check.request?.path_template) throw new Error("TOPOLOGY_REQUEST_MISSING:"+check.check_id);
      if(!check.request.path_template.startsWith("/")||check.request.path_template.startsWith("//")||/^[a-z]+:/i.test(check.request.path_template)) throw new Error("TOPOLOGY_ABSOLUTE_PATH:"+check.check_id);
    }
  }

  const required=matrix.required_record_fields||[];
  const plans=matrix.server_case_plans||{};
  const mutationCapable=[];
  const negativeMutationCapable=[];

  const tokenNeeds={
    EVIDENCE_OBSERVER_TOKEN:["TOPO-TOKEN-EVIDENCE-OBSERVER"],ACTOR_TOKEN:["TOPO-TOKEN-ACTOR","TOPO-ACTOR"],MANAGER_TOKEN:["TOPO-TOKEN-MANAGER","TOPO-MANAGER"],ADMIN_TOKEN:["TOPO-TOKEN-ADMIN","TOPO-ADMIN"],ROOT_TOKEN:["TOPO-TOKEN-ROOT","TOPO-ROOT-PROFILE","TOPO-ROOT-AUTHORITY"],ACTOR_A_TOKEN:["TOPO-TOKEN-A","TOPO-ACTOR-A-PROFILE"],ACTOR_B_TOKEN:["TOPO-TOKEN-B","TOPO-ACTOR-B-PROFILE"],ZERO_STAGE_TOKEN:["TOPO-TOKEN-ZERO-STAGE","TOPO-ZERO-STAGE-ACTOR"],INACTIVE_TOKEN:["TOPO-TOKEN-INACTIVE","TOPO-INACTIVE-PROFILE"],INELIGIBLE_TOKEN:["TOPO-TOKEN-INELIGIBLE","TOPO-INELIGIBLE-PROFILE"],NO_PROFILE_TOKEN:["TOPO-TOKEN-NO-PROFILE","TOPO-NO-PROFILE"]
  };
  const declaredBindings=matrix.topology_contract?.valid_token_identity_bindings||{};
  for(const [token,needed] of Object.entries(tokenNeeds)) if(declaredBindings[token]!==needed[0]||!topologyIds.has(needed[0])) throw new Error("TOKEN_BINDING_DECLARATION_INVALID:"+token);
  for(const token of Object.keys(declaredBindings)) if(!tokenNeeds[token]) throw new Error("UNKNOWN_TOKEN_BINDING_DECLARATION:"+token);
  const negativeTokenVars=new Set(matrix.topology_contract?.unbound_negative_token_vars||[]);
  if(JSON.stringify([...negativeTokenVars].sort())!==JSON.stringify(["EXPIRED_TOKEN","INVALID_TOKEN"])) throw new Error("NEGATIVE_TOKEN_EXCEPTION_DRIFT");
  const globalDeps=new Set(matrix.topology_contract?.global_check_ids||[]);
  if(!globalDeps.has("TOPO-TOKEN-EVIDENCE-OBSERVER")) throw new Error("OBSERVER_IDENTITY_BINDING_NOT_GLOBAL");
  const observerCheck=topologyChecks.find(x=>x.check_id==="TOPO-TOKEN-EVIDENCE-OBSERVER");
  if(observerCheck?.request?.auth_token_var!=="EVIDENCE_OBSERVER_TOKEN"||observerCheck?.request?.path_template!=="/auth/v1/user"||observerCheck?.assertion?.mode!=="OBJECT_FIELD_EQUALS_VAR"||observerCheck?.assertion?.field!=="id"||observerCheck?.assertion?.var!=="EVIDENCE_OBSERVER_USER_ID") throw new Error("OBSERVER_IDENTITY_BINDING_INVALID");

  for(const rec of matrix.records){
    if(!rec.test_id||ids.has(rec.test_id)) throw new Error("DUPLICATE_OR_MISSING_TEST_ID:"+rec.test_id);
    ids.add(rec.test_id);
    const cat=rec.test_id.split("-")[0];
    counts[cat]=(counts[cat]||0)+1;
    for(const field of required) if(!(field in rec)) throw new Error("MISSING_FIELD:"+rec.test_id+":"+field);

    if(rec.exact_application_commit!=="9d05c64281c2aeeae9d67b139eab674720184fb1") throw new Error("APP_COMMIT_DRIFT:"+rec.test_id);
    if(rec.pass_fail!=="NOT_EXECUTED"||rec.actual_authorization_result!=="NOT_EXECUTED"||rec.actual_data_mutation!=="NOT_EXECUTED") throw new Error("EXECUTION_OVERCLAIM:"+rec.test_id);

    const artifactCommits=[];
    for(const a of rec.migration_artifacts||[]){
      const expectedCommit=matrix.artifact_binding?.migration_final_commits?.[a.path];
      if(!expectedCommit||a.final_commit!==expectedCommit) throw new Error("MIGRATION_FINAL_COMMIT_DRIFT:"+rec.test_id+":"+a.path);
      if(!/^[0-9a-f]{40}$/.test(a.blob)||!/^[0-9a-f]{40}$/.test(a.final_commit)) throw new Error("MIGRATION_PROVENANCE_FORMAT:"+rec.test_id);
      artifactCommits.push(a.final_commit);
    }
    const exact=[...new Set(artifactCommits)];
    if(JSON.stringify(exact)!==JSON.stringify(rec.exact_migration_commits)) throw new Error("EXACT_MIGRATION_COMMITS_MISMATCH:"+rec.test_id);

    for(const dep of rec.topology_dependencies||[]) if(!topologyIds.has(dep)) throw new Error("UNKNOWN_TOPOLOGY_DEPENDENCY:"+rec.test_id+":"+dep);

    if(rec.runner==="http_matrix"){
      if(rec.applicability?.mode==="VERSION_BOUND_FUNCTION_DEFINITION"){
        if((rec.request_plan?.requests||[]).length!==0) throw new Error("VERSION_BOUND_NOT_APPLICABLE_REQUEST_FORBIDDEN:"+rec.test_id);
        if(rec.server_case_plan!==null||rec.mutation_probe_plan!==null||rec.cleanup_contract!==null) throw new Error("VERSION_BOUND_NOT_APPLICABLE_LIFECYCLE_FORBIDDEN:"+rec.test_id);
        continue;
      }
      if(!rec.request_plan?.requests?.length) throw new Error("VERSIONED_REQUEST_PLAN_MISSING:"+rec.test_id);

      for(const q of rec.request_plan.requests){
        if(typeof q.path_template!=="string"||!q.path_template.startsWith("/")||q.path_template.startsWith("//")||/^[a-z]+:/i.test(q.path_template)) throw new Error("ABSOLUTE_OR_INVALID_PATH:"+rec.test_id);
        if(!["GET","POST","PATCH","DELETE","HEAD"].includes(q.method)) throw new Error("METHOD_NOT_VERSIONED:"+rec.test_id);
        if("url" in q||"origin" in q) throw new Error("ABSOLUTE_TARGET_FIELD_FORBIDDEN:"+rec.test_id);
        const token=q.auth_token_var;
        if(token){if(negativeTokenVars.has(token)){if(!String(rec.expected_authorization_result).startsWith("DENY")) throw new Error("NEGATIVE_TOKEN_USED_OUTSIDE_DENIAL:"+rec.test_id+":"+token);} else {const needed=tokenNeeds[token];if(!needed) throw new Error("UNBOUND_VERSIONED_REQUEST_TOKEN:"+rec.test_id+":"+token);const deps=new Set([...(rec.topology_dependencies||[]),...globalDeps]);for(const d of needed) if(!deps.has(d)) throw new Error("TOKEN_TOPOLOGY_DEPENDENCY_MISSING:"+rec.test_id+":"+token+":"+d);}}
      }

      const cat=rec.test_id.split("-")[0];
      const canMutate=!["AUTH","STG","PRD"].includes(cat)&&(rec.request_plan.requests||[]).some(q=>q.method!=="GET");
      if(canMutate){
        mutationCapable.push(rec.test_id);
        if(String(rec.expected_authorization_result).startsWith("DENY")) negativeMutationCapable.push(rec.test_id);
        if(!rec.server_case_plan||!plans[rec.server_case_plan]) throw new Error("MUTATION_CAPABLE_WITHOUT_SERVER_LIFECYCLE:"+rec.test_id);
        if(rec.mutation_probe_plan?.channel!=="SERVER_SQL_OWNER") throw new Error("MUTATION_CAPABLE_WRONG_EVIDENCE_CHANNEL:"+rec.test_id);
        if(rec.cleanup_contract?.mode!=="SCOPED_RESTORE_PLUS_GLOBAL_PUBLIC_DATA_HASH"||rec.cleanup_contract.must_restore_exactly!==true||rec.cleanup_contract.fail_stop!==true) throw new Error("MUTATION_CAPABLE_CLEANUP_CONTRACT_MISSING:"+rec.test_id);
      }

      if(rec.request_plan.response_assertion?.mode==="DENIAL_SEMANTIC"){
        const a=rec.request_plan.response_assertion;
        if(!Array.isArray(a.expected_statuses)||!a.expected_statuses.length) throw new Error("DENY_STATUS_MISSING:"+rec.test_id);
        if(a.allowed_http_error_class!==undefined) throw new Error("BROAD_4XX_CLASS_FORBIDDEN:"+rec.test_id);
        if(!a.expected_error_exact&&!a.expected_error_regex&&!a.expected_error_codes?.length) throw new Error("DENY_ERROR_EVIDENCE_MISSING:"+rec.test_id);
      }

      if(rec.execution_mode==="CONCURRENT_HTTP"){
        if(!rec.concurrency_assertion?.require_positive_overlap||rec.concurrency_assertion.min_overlap_ms<1||!rec.concurrency_assertion.receipt_per_request_timing) throw new Error("CONCURRENCY_OVERLAP_ASSERTION_MISSING:"+rec.test_id);
      }
    }

    if(rec.runner==="rollback_reapply"){
      if(rec.supabase_project_ref!=="NON_PRODUCTION_REQUIRED") throw new Error("ROLLBACK_PROJECT_POLICY_DRIFT:"+rec.test_id);
      if(rec.verification_contract?.isolation!=="EXACTLY_ONE_ROL_CASE_PER_INVOCATION") throw new Error("ROLLBACK_ISOLATION_CONTRACT_MISSING:"+rec.test_id);
      if(rec.verification_contract?.after_reapply!=="SHA256_MUST_EQUAL_INITIAL") throw new Error("REAPPLY_STATE_RESTORE_CONTRACT_MISSING:"+rec.test_id);
    }
  }

  const tokenUsages=[];
  for(const check of topologyChecks) if(check.request?.auth_token_var) tokenUsages.push({surface:"TOPOLOGY",id:check.check_id,token:check.request.auth_token_var});
  for(const rec of matrix.records){for(const q of rec.request_plan?.requests||[]) if(q.auth_token_var) tokenUsages.push({surface:"REQUEST",id:rec.test_id,token:q.auth_token_var});for(const q of [...(rec.mutation_probe_plan?.before||[]),...(rec.mutation_probe_plan?.after||[])]) if(q.auth_token_var) tokenUsages.push({surface:"PROBE",id:rec.test_id,token:q.auth_token_var});}
  for(const use of tokenUsages){if(negativeTokenVars.has(use.token)) continue;const needed=tokenNeeds[use.token];if(!needed) throw new Error("UNBOUND_VERSIONED_TOKEN_SURFACE:"+use.surface+":"+use.id+":"+use.token);if(use.token==="EVIDENCE_OBSERVER_TOKEN") for(const d of needed) if(!globalDeps.has(d)) throw new Error("OBSERVER_BINDING_NOT_GLOBAL:"+d);}
  if(topologyChecks.length!==56) throw new Error("TOPOLOGY_COUNT_DRIFT:"+topologyChecks.length);
  for(const id of ["TOPO-ZERO-STAGE-COMPANY","TOPO-NO-PROFILE"]){const c=topologyChecks.find(x=>x.check_id===id);if(c?.request!==null||c?.assertion?.mode!=="SERVER_ZERO_ROWS_BY_UUID") throw new Error("ABSENCE_PROOF_NOT_OWNER_SIDE:"+id);}

  // Phase 2 semantic-truth contracts: denial cannot substitute for fixture proof.
  const foreignLote=topologyChecks.find(x=>x.check_id==="TOPO-FOREIGN-LOTE");
  if(foreignLote?.assertion?.mode!=="EXACTLY_ONE_ROW"||foreignLote.assertion?.field_equals_vars?.id!=="FOREIGN_LOTE_ID"||foreignLote.assertion?.field_equals_vars?.lista_id!=="FOREIGN_LISTA_ID") throw new Error("CRM013_FOREIGN_LOTE_CHAIN_INVALID");
  const foreignList=topologyChecks.find(x=>x.check_id==="TOPO-FOREIGN-LIST");
  if(foreignList?.assertion?.mode!=="EXACTLY_ONE_ROW"||foreignList.assertion?.field_equals_vars?.id!=="FOREIGN_LISTA_ID"||foreignList.assertion?.field_equals_vars?.empresa_id!=="FOREIGN_EMPRESA_ID"||foreignList.assertion?.field_not_equals_vars?.empresa_id!=="ACTOR_EMPRESA_ID") throw new Error("CRM013_FOREIGN_LIST_CHAIN_INVALID");
  const crm013Deps=new Set(matrix.records.find(x=>x.test_id==="CRM-013")?.topology_dependencies||[]);
  for(const d of ["TOPO-FOREIGN-LOTE","TOPO-FOREIGN-LIST"]) if(!crm013Deps.has(d)) throw new Error("CRM013_FOREIGN_CHAIN_DEPENDENCY_MISSING:"+d);

  const nonexistentCorretor=topologyChecks.find(x=>x.check_id==="TOPO-NONEXISTENT-CORRETOR");
  if(nonexistentCorretor?.request!==null||nonexistentCorretor?.assertion?.mode!=="SERVER_ZERO_ROWS_BY_UUID"||nonexistentCorretor.assertion?.table!=="public.corretores"||nonexistentCorretor.assertion?.column!=="id"||nonexistentCorretor.assertion?.var!=="NONEXISTENT_TARGET_ID") throw new Error("ACL005_OWNER_SIDE_ABSENCE_INVALID");
  if(!(matrix.records.find(x=>x.test_id==="ACL-005")?.topology_dependencies||[]).includes("TOPO-NONEXISTENT-CORRETOR")) throw new Error("ACL005_OWNER_SIDE_ABSENCE_DEPENDENCY_MISSING");

  const foreignTime=topologyChecks.find(x=>x.check_id==="TOPO-FOREIGN-TIME");
  if(foreignTime?.assertion?.mode!=="EXACTLY_ONE_ROW"||foreignTime.assertion?.field_equals_vars?.id!=="FOREIGN_TIME_ID"||foreignTime.assertion?.field_equals_vars?.empresa_id!=="FOREIGN_EMPRESA_ID"||foreignTime.assertion?.field_not_equals_vars?.empresa_id!=="ACTOR_EMPRESA_ID"||foreignTime.assertion?.field_equals_literals?.ativo!==true) throw new Error("ACL009_ACTIVE_FOREIGN_TIME_INVALID");
  if(!(matrix.records.find(x=>x.test_id==="ACL-009")?.topology_dependencies||[]).includes("TOPO-FOREIGN-TIME")) throw new Error("ACL009_ACTIVE_FOREIGN_TIME_DEPENDENCY_MISSING");
  const completeSetContracts={
    "TOPO-OWN-STAGE-SET":{where_var:"ACTOR_EMPRESA_ID",expected_ids_var:"OWN_STAGE_IDS"},
    "TOPO-FOREIGN-STAGE-SET":{where_var:"FOREIGN_EMPRESA_ID",expected_ids_var:"FOREIGN_STAGE_IDS"}
  };
  for(const [id,expectedContract] of Object.entries(completeSetContracts)){
    const c=topologyChecks.find(x=>x.check_id===id),a=c?.assertion;
    if(c?.request!==null||a?.mode!=="SERVER_ROW_IDS_EQUAL_VAR_SET"||a.table!=="public.funil_estagios"||a.id_column!=="id"||a.where_column!=="empresa_id"||a.where_var!==expectedContract.where_var||a.expected_ids_var!==expectedContract.expected_ids_var) throw new Error("COMPLETE_SET_PROOF_NOT_OWNER_SIDE:"+id);
  }
  for(const [k,v] of Object.entries(expected)) if(counts[k]!==v) throw new Error("COUNT_MISMATCH:"+k+":"+counts[k]+"!="+v);

  // STG-001 must truly be unauthenticated.
  const stg001=matrix.records.find(x=>x.test_id==="STG-001");
  if(stg001?.request_plan?.requests?.[0]?.auth_token_var!==null) throw new Error("STG001_NOT_ACTUALLY_NO_SESSION");
  if(!/without Authorization\/session/i.test(stg001?.action_request||"")) throw new Error("STG001_ACTION_TEXT_DRIFT");

  // FUN-006 applicability is version-bound to the product contract, never fixture authority.
  const fun006=matrix.records.find(x=>x.test_id==="FUN-006");
  const fun006a=fun006?.applicability;
  if(fun006a?.mode!=="VERSION_BOUND_FUNCTION_DEFINITION"||
     fun006a.function_signature!=="public.mover_funil(uuid,uuid,text)"||
     fun006a.expected_definition_md5!=="dab988abbd2d50ae57159cc4110051d8"||
     fun006a.source_migration_commit!=="951da21db217b60463ada48e7801f0593a540687"||
     fun006a.source_blob!=="028a79c5824d90a990276d986fbbef279fd916b5"||
     fun006a.on_match!=="NOT_APPLICABLE"||
     fun006a.reason!=="VERSIONED_PRODUCT_CONTRACT_HAS_NO_TRANSITION_RULE_MECHANISM") throw new Error("FUN006_VERSION_BOUND_CONTRACT_MISSING");
  if((fun006?.request_plan?.requests||[]).length!==0||fun006?.server_case_plan!==null||fun006?.mutation_probe_plan!==null||fun006?.cleanup_contract!==null) throw new Error("FUN006_EXECUTION_SURFACE_MUST_BE_EMPTY");
  if((fun006?.topology_dependencies||[]).length!==0) throw new Error("FUN006_OBSOLETE_TOPOLOGY_DEPENDENCY_REMAINS");
  if(topologyIds.has("TOPO-FUNNEL-TRANSITION-RULES")) throw new Error("FUN006_OBSOLETE_TOPOLOGY_CHECK_REMAINS");
  if(matrixText.includes("FUNNEL_TRANSITION_RULES_ENABLED")) throw new Error("FUN006_FIXTURE_AUTHORITY_REMAINS");
  for(const n of ["PR08_APPLICABILITY_PRODUCT_CONTRACT_DRIFT","PR08_APPLICABILITY_PRODUCT_CONTRACT_EVIDENCE_INVALID","pg_catalog.pg_get_functiondef","dab988abbd2d50ae57159cc4110051d8"]) if(!http.includes(n)) throw new Error("FUN006_RUNNER_VERSION_BOUND_EVIDENCE_MISSING:"+n);

  // Privileged topology closure.
  const acl002=new Set(matrix.records.find(x=>x.test_id==="ACL-002")?.topology_dependencies||[]);
  for(const d of ["TOPO-TOKEN-MANAGER","TOPO-MANAGER","TOPO-MANAGED-TIME","TOPO-MANAGER-LIST-SCOPE","TOPO-MANAGER-TARGET-SCOPE"]) if(!acl002.has(d)) throw new Error("ACL002_MANAGER_SCOPE_MISSING:"+d);

  for(const id of ["ACL-004","STG-007"]){
    const deps=new Set(matrix.records.find(x=>x.test_id===id)?.topology_dependencies||[]);
    for(const d of ["TOPO-TOKEN-ROOT","TOPO-ROOT-PROFILE","TOPO-ROOT-AUTHORITY"]) if(!deps.has(d)) throw new Error("ROOT_TOPOLOGY_MISSING:"+id+":"+d);
  }

  const imp002=new Set(matrix.records.find(x=>x.test_id==="IMP-002")?.topology_dependencies||[]);
  for(const d of ["TOPO-TOKEN-A","TOPO-ACTOR-A-PROFILE","TOPO-TOKEN-B","TOPO-ACTOR-B-PROFILE","TOPO-TENANTS-A-B-DIFFER","TOPO-LISTS-A-B-DIFFER"]) if(!imp002.has(d)) throw new Error("IMP002_ACTOR_TOPOLOGY_MISSING:"+d);

  // ACL lifecycle must cover list row, entire ACL set and audit side effects.
  for(const id of ["ACL-001","ACL-002","ACL-003","ACL-004","ACL-005","ACL-006","ACL-007","ACL-008","ACL-009","ACL-010"]){
    const p=plans[id];
    if(p?.kind!=="ACL"||p.include_list_row!==true||p.include_all_acl_rows!==true||p.include_list_audit_rows!==true||p.global_data_hash!==true||p.cleanup_fail_stop!==true) throw new Error("ACL_FULL_LIFECYCLE_MISSING:"+id);
  }
  for(const id of ["ACL-002","ACL-003","ACL-004","ACL-010"]) if(plans[id]?.prepare_target_absent!==true) throw new Error("ACL_POSITIVE_TARGET_PREPARE_MISSING:"+id);

  // Broker lifecycles must cover audit side effects.
  for(const [id,p] of Object.entries(plans)){
    if(p.kind==="BROKER"&&p.include_full_audit_logs!==true) throw new Error("BROKER_AUDIT_LIFECYCLE_MISSING:"+id);
  }

  // COR-011 must use the real T3 state machine.
  const cor11=plans["COR-011"];
  if(cor11?.kind!=="PASSWORD_T3"||cor11.authority_claims_var!=="ADMIN_JWT_CLAIMS"||cor11.target_claims_var!=="ACTOR_JWT_CLAIMS"||cor11.include_full_audit_logs!==true||cor11.include_t3_proof_lease_rows!==true) throw new Error("COR011_T3_LIFECYCLE_CONTRACT_MISSING");
  const cor11Deps=new Set(matrix.records.find(x=>x.test_id==="COR-011")?.topology_dependencies||[]);
  for(const d of ["TOPO-TOKEN-ACTOR","TOPO-ACTOR","TOPO-TOKEN-ADMIN","TOPO-ADMIN"]) if(!cor11Deps.has(d)) throw new Error("COR011_AUTHORITY_TOPOLOGY_MISSING:"+d);

  // Distribution denial has no lista arg, so the lifecycle must cover the full distribution tables.
  if(plans["COR-008"]?.kind!=="DISTRIBUTION"||plans["COR-008"].full_distribution_tables!==true||plans["COR-008"].include_full_audit_logs!==true) throw new Error("COR008_FULL_DISTRIBUTION_GUARD_MISSING");

  // Positive feedback baseline/semantic closure.
  for(const id of ["FDB-008","FDB-009"]){
    const p=plans[id];
    if(p?.kind!=="FEEDBACK"||p.prepare_feedback_baseline!==true||p.baseline_stage_var!=="BASE_STAGE_ID"||p.expected_stage_var!=="EM_CONVERSA_STAGE_ID") throw new Error("FDB_POSITIVE_BASELINE_MISSING:"+id);
  }

  // No protected idempotency state can be observed through client REST.
  if(/CUSTOM_ASSERTED_BY_FIXTURE/.test(matrixText+http)) throw new Error("CUSTOM_FIXTURE_ASSERTION_FORBIDDEN");
  if(/allowed_http_error_class/.test(matrixText+http)) throw new Error("BROAD_4XX_CLASS_REMAINS");
  if(/fixture\.cases|spec\.url|fetch\(spec\.url/.test(http)) throw new Error("FIXTURE_OR_ARBITRARY_URL_EXECUTION_FORBIDDEN");
  if(/for \(const check of matrix\.topology_contract\?\.checks/.test(http)) throw new Error("RUNNER_EXECUTES_ALL_TOPOLOGY_CHECKS");

  const runnerNeedles=[
    "runTopologyPreflight(record)",
    "SERVER_ROOT_AUTHORITY",
    "SERVER_ROW_IDS_EQUAL_VAR_SET",
    "normalizedUuidListFromVar",
    "PR08_APPLICABILITY_PRODUCT_CONTRACT_DRIFT",
    "recordApplicable",
    'pass_fail:"NOT_APPLICABLE"',
    "publicDataHash",
    "publicDataRelations",
    "canonicalRelationState",
    "last_value::text AS last_value",
    "sequenceState",
    "restoreSequences",
    "cleanupGlobalHash",
    "PR08_CASE_CLEANUP_NOT_RESTORED",
    "t3PreparePasswordState",
    "t3_issue_admin_password_reset_edge_proof",
    "t3_prepare_admin_password_reset",
    "t3_release_admin_password_reset_lease",
    "marcar_senha_inicial_definida",
    "PR08_ACL_ROWS_RESTORE",
    "PR08_ACL_AUDIT_RESTORE",
    "PR08_BROKER_AUDIT_RESTORE",
    "PR08_DISTRIBUTION_LEADS_RESTORE",
    "PR08_DISTRIBUTION_AUDIT_RESTORE",
    "SERVER_AFTER_ARRAY_COUNT_EQUALS",
    'schema:"fechai.pr08.http.receipt.v6"'
  ];
  for(const n of runnerNeedles) if(!http.includes(n)) throw new Error("HTTP_V5_CONTRACT_MISSING:"+n);

  // Every lifecycle kind in the matrix must have a runner branch.
  const runnerKinds=new Set();
  for(const p of Object.values(plans)) if(p.kind!=="SQL_ONLY_ROLLBACK_CASE") runnerKinds.add(p.kind);
  for(const kind of runnerKinds){
    if(!http.includes('plan.kind==="'+kind+'"')&&!http.includes('plan.kind==="'+kind+'" ||')&&!http.includes('plan.kind==="'+kind+'"||')) throw new Error("RUNNER_KIND_IMPLEMENTATION_MISSING:"+kind);
  }

  // Owner-side evidence preflight must prove BYPASSRLS and preserve PR-07 boundary.
  for(const n of [
    "SERVER-EVIDENCE-PREFLIGHT",
    "server evidence channel hard-denies production",
    "server_evidence_owner_role_is_postgres",
    "server_evidence_postgres_bypassrls",
    "idempotency_zero_client_policies",
    "idempotency_no_client_direct_dml"
  ]) if(!sql.includes(n)) throw new Error("SERVER_EVIDENCE_SQL_PREFLIGHT_MISSING:"+n);

  if(http.includes("FECHAIPR08CASESTATE")||http.includes("ctx.pgDump")) throw new Error("HTTP_RAW_PG_DUMP_HASH_REGRESSION");
  if(!rollback.includes("--schema-only")||!rollback.includes("--restrict-key=FECHAIPR08STATEHASH")||!rollback.includes("canonicalPublicDataHash")||!rollback.includes("last_value::text AS last_value")) throw new Error("ROLLBACK_CANONICAL_STATE_FINGERPRINT_MISSING");
  if(rollback.includes('["--schema=public","--no-comments","--format=plain","--restrict-key=FECHAIPR08STATEHASH"]')) throw new Error("ROLLBACK_RAW_FULL_PG_DUMP_HASH_REGRESSION");
  if(!rollback.includes("PR08_EXACTLY_ONE_ROLLBACK_CASE_REQUIRED")||!rollback.includes("PR08_DATABASE_HOST_PROJECT_BINDING_MISMATCH")||!rollback.includes("state_after_reapply_sha256")) throw new Error("ROLLBACK_CONTRACT_REGRESSION");
  if(!sql.includes("IMP-CLAIMANT-ROLLBACK")||!sql.includes("no_claimant_marker_residue")) throw new Error("CLAIMANT_SQL_PLAN_REGRESSION");

  if(matrix.residuals?.["IMP-003"]!=="NOT_DETERMINED") throw new Error("IMP003_STATUS_DRIFT");
  if(matrix.residuals?.ROLLBACK_REAPPLY!=="NOT_DETERMINED") throw new Error("ROLLBACK_STATUS_DRIFT");
  if(matrix.records.find(r=>r.test_id==="IMP-003")?.prior_evidence!==null) throw new Error("IMP003_PRIOR_PASS_OVERCLAIM");

  if(/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i.test(matrixText)) throw new Error("UUID_FORBIDDEN");
  if(/eyJ[A-Za-z0-9_-]{10,}\./.test(matrixText)) throw new Error("JWT_FORBIDDEN");

  process.stdout.write(JSON.stringify({
    status:"PASS",
    counts,
    topology_checks:topologyChecks.length,
    server_case_plans:Object.keys(plans).length,
    mutation_capable_http:mutationCapable.length,
    negative_mutation_capable_http:negativeMutationCapable.length,
    imp003:"NOT_DETERMINED",
    rollback_reapply:"NOT_DETERMINED"
  })+"\n");
}
main().catch(error=>{
  process.stderr.write(JSON.stringify({status:"FAIL",error:String(error?.message||error)})+"\n");
  process.exitCode=1;
});
