#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const root = process.cwd();

  const matrixText=await fs.readFile(path.join(root,"supabase/tests/f1-02-pr08/matrix.json"),"utf8");
  const matrix=JSON.parse(matrixText);
  const http=await fs.readFile(path.join(root,"scripts/tests/f1-02-pr08/run_auth_http_matrix.mjs"),"utf8");
  const rollback=await fs.readFile(path.join(root,"scripts/tests/f1-02-pr08/run_rollback_reapply.mjs"),"utf8");
  const sql=await fs.readFile(path.join(root,"supabase/tests/f1-02-pr08/runtime_security_matrix.sql"),"utf8");

  const expected={AUTH:5,COR:13,CRM:15,FUN:8,ACL:10,STG:7,IMP:16,FDB:11,ROL:11,PRD:2,TOTAL:98};
  const counts={TOTAL:matrix.records.length};
  const ids=new Set();

  if(matrix.schema!=="fechai.f1-02.pr08.matrix.v4") throw new Error("MATRIX_SCHEMA_DRIFT");
  if(matrix.execution_contract?.server_evidence_channel!=="PSQL_POSTGRES_OWNER_NON_PRODUCTION_ONLY") throw new Error("SERVER_EVIDENCE_CONTRACT_MISSING");
  if(matrix.execution_contract?.case_isolation!=="PER_TEST_CAPTURE_PREPARE_EVIDENCE_CLEANUP_RESTORE") throw new Error("CASE_ISOLATION_CONTRACT_MISSING");
  if(matrix.execution_contract?.topology_scope!=="GLOBAL_PLUS_SELECTED_CASE_DEPENDENCIES_ONLY") throw new Error("TOPOLOGY_SCOPE_CONTRACT_MISSING");
  if(matrix.execution_contract?.idempotency_evidence!=="SERVER_SQL_ONLY_NO_REST_CLIENT_ACCESS") throw new Error("IDEMPOTENCY_EVIDENCE_CONTRACT_MISSING");
  if(matrix.execution_contract?.cleanup_verification!=="POST_CLEANUP_SHA256_MUST_EQUAL_ORIGINAL") throw new Error("CLEANUP_CONTRACT_MISSING");

  const sec=matrix.server_evidence_contract||{};
  if(sec.mode!=="PSQL_POSTGRES_OWNER_NON_PRODUCTION_ONLY") throw new Error("SERVER_EVIDENCE_MODE_DRIFT");
  if(sec.required_database_role!=="postgres") throw new Error("SERVER_EVIDENCE_ROLE_DRIFT");
  if(sec.production_project_ref_hard_deny!=="uobxxgzshrmbtjfdolxd") throw new Error("SERVER_EVIDENCE_PROD_DENY_DRIFT");
  if(sec.grants_rls_policies_changes!=="FORBIDDEN") throw new Error("SERVER_EVIDENCE_BOUNDARY_WIDENING");

  if(matrixText.includes("/rest/v1/importar_leads_batch_idempotency") || http.includes("/rest/v1/importar_leads_batch_idempotency")) {
    throw new Error("IDEMPOTENCY_REST_CLIENT_ACCESS_FORBIDDEN");
  }

  const topologyChecks=matrix.topology_contract?.checks||[];
  const topologyIds=new Set(topologyChecks.map(x=>x.check_id));
  if(!Array.isArray(matrix.topology_contract?.global_check_ids)) throw new Error("GLOBAL_TOPOLOGY_IDS_MISSING");
  for(const id of matrix.topology_contract.global_check_ids) if(!topologyIds.has(id)) throw new Error("UNKNOWN_GLOBAL_TOPOLOGY_CHECK:"+id);
  for(const check of topologyChecks){
    if(!check.check_id || !check.assertion?.mode) throw new Error("TOPOLOGY_CHECK_INVALID");
    if(check.assertion.mode==="VARIABLE_NOT_EQUAL"){
      if(check.request!==null || !check.assertion.left || !check.assertion.right) throw new Error("VARIABLE_TOPOLOGY_CHECK_INVALID:"+check.check_id);
    } else {
      if(!check.request?.path_template) throw new Error("TOPOLOGY_REQUEST_MISSING:"+check.check_id);
      if(!check.request.path_template.startsWith("/") || check.request.path_template.startsWith("//") || /^[a-z]+:/i.test(check.request.path_template)) throw new Error("TOPOLOGY_ABSOLUTE_PATH:"+check.check_id);
    }
  }

  const required=matrix.required_record_fields||[];
  const serverPlans=matrix.server_case_plans||{};
  const mutating=[];
  for(const rec of matrix.records){
    if(!rec.test_id || ids.has(rec.test_id)) throw new Error("DUPLICATE_OR_MISSING_TEST_ID:"+rec.test_id);
    ids.add(rec.test_id);
    const cat=rec.test_id.split("-")[0]; counts[cat]=(counts[cat]||0)+1;
    for(const field of required) if(!(field in rec)) throw new Error("MISSING_FIELD:"+rec.test_id+":"+field);
    if(rec.exact_application_commit!=="9d05c64281c2aeeae9d67b139eab674720184fb1") throw new Error("APP_COMMIT_DRIFT:"+rec.test_id);
    if(rec.pass_fail!=="NOT_EXECUTED" || rec.actual_authorization_result!=="NOT_EXECUTED" || rec.actual_data_mutation!=="NOT_EXECUTED") throw new Error("EXECUTION_OVERCLAIM:"+rec.test_id);

    const artifactCommits=[];
    for(const a of rec.migration_artifacts||[]){
      const expectedCommit=matrix.artifact_binding?.migration_final_commits?.[a.path];
      if(!expectedCommit || a.final_commit!==expectedCommit) throw new Error("MIGRATION_FINAL_COMMIT_DRIFT:"+rec.test_id+":"+a.path);
      if(!/^[0-9a-f]{40}$/.test(a.blob)||!/^[0-9a-f]{40}$/.test(a.final_commit)) throw new Error("MIGRATION_PROVENANCE_FORMAT:"+rec.test_id);
      artifactCommits.push(a.final_commit);
    }
    const exact=[...new Set(artifactCommits)];
    if(JSON.stringify(exact)!==JSON.stringify(rec.exact_migration_commits)) throw new Error("EXACT_MIGRATION_COMMITS_MISMATCH:"+rec.test_id);

    for(const dep of rec.topology_dependencies||[]) if(!topologyIds.has(dep)) throw new Error("UNKNOWN_TOPOLOGY_DEPENDENCY:"+rec.test_id+":"+dep);

    if(rec.runner==="http_matrix"){
      if(!rec.request_plan?.requests?.length) throw new Error("VERSIONED_REQUEST_PLAN_MISSING:"+rec.test_id);
      const hasServer=Boolean(rec.server_case_plan);
      if(hasServer){
        if(!serverPlans[rec.server_case_plan]) throw new Error("SERVER_PLAN_REFERENCE_MISSING:"+rec.test_id);
        if(rec.mutation_probe_plan?.channel!=="SERVER_SQL_OWNER") throw new Error("SERVER_PROBE_CHANNEL_DRIFT:"+rec.test_id);
        if((rec.mutation_probe_plan.before||[]).length || (rec.mutation_probe_plan.after||[]).length) throw new Error("SERVER_CASE_HAS_HTTP_MUTATION_PROBES:"+rec.test_id);
      } else {
        if(!rec.mutation_probe_plan?.before?.length || !rec.mutation_probe_plan?.after?.length) throw new Error("HTTP_PROBE_PLAN_MISSING:"+rec.test_id);
      }

      for(const spec of [...rec.request_plan.requests,...(rec.mutation_probe_plan?.before||[]),...(rec.mutation_probe_plan?.after||[])]){
        if(typeof spec.path_template!=="string" || !spec.path_template.startsWith("/") || spec.path_template.startsWith("//") || /^[a-z]+:/i.test(spec.path_template)) throw new Error("ABSOLUTE_OR_INVALID_PATH:"+rec.test_id);
        if(!["GET","POST","PATCH","DELETE","HEAD"].includes(spec.method)) throw new Error("METHOD_NOT_VERSIONED:"+rec.test_id);
        if("url" in spec || "origin" in spec) throw new Error("ABSOLUTE_TARGET_FIELD_FORBIDDEN:"+rec.test_id);
      }

      if(!["ZERO","ZERO_ADDITIONAL","ZERO_PERSISTENT","ZERO_BUSINESS"].includes(rec.expected_data_mutation)) {
        mutating.push(rec.test_id);
        if(!hasServer) throw new Error("MUTATING_CASE_WITHOUT_SERVER_LIFECYCLE:"+rec.test_id);
      }

      if(rec.request_plan.response_assertion?.mode==="DENIAL_SEMANTIC"){
        const a=rec.request_plan.response_assertion;
        if(!Array.isArray(a.expected_statuses)||!a.expected_statuses.length) throw new Error("DENY_STATUS_MISSING:"+rec.test_id);
        if(a.allowed_http_error_class!==undefined) throw new Error("BROAD_4XX_CLASS_FORBIDDEN:"+rec.test_id);
        if(!a.expected_error_exact&&!a.expected_error_regex&&!a.expected_error_codes?.length) throw new Error("DENY_ERROR_EVIDENCE_MISSING:"+rec.test_id);
      }

      const nontrivialPositive=!String(rec.expected_authorization_result).startsWith("DENY") &&
        !["AUTH-001","AUTH-004","AUTH-005","STG-001","STG-002","STG-007","PRD-002"].includes(rec.test_id);
      if(nontrivialPositive && !rec.semantic_assertions?.length) throw new Error("POSITIVE_SEMANTIC_ASSERTION_MISSING:"+rec.test_id);

      if(rec.execution_mode==="CONCURRENT_HTTP"){
        if(!rec.concurrency_assertion?.require_positive_overlap || rec.concurrency_assertion.min_overlap_ms<1 || !rec.concurrency_assertion.receipt_per_request_timing) throw new Error("CONCURRENCY_OVERLAP_ASSERTION_MISSING:"+rec.test_id);
      }
    }

    if(rec.runner==="rollback_reapply"){
      if(rec.supabase_project_ref!=="NON_PRODUCTION_REQUIRED") throw new Error("ROLLBACK_PROJECT_POLICY_DRIFT:"+rec.test_id);
      if(rec.verification_contract?.isolation!=="EXACTLY_ONE_ROL_CASE_PER_INVOCATION") throw new Error("ROLLBACK_ISOLATION_CONTRACT_MISSING:"+rec.test_id);
      if(rec.verification_contract?.after_reapply!=="SHA256_MUST_EQUAL_INITIAL") throw new Error("REAPPLY_STATE_RESTORE_CONTRACT_MISSING:"+rec.test_id);
    }
  }
  for(const [k,v] of Object.entries(expected)) if(counts[k]!==v) throw new Error("COUNT_MISMATCH:"+k+":"+counts[k]+"!="+v);

  const statefulRequired=[
    "COR-011","COR-012","COR-013","CRM-015","FUN-007","FUN-008","ACL-002","ACL-003","ACL-004","ACL-010",
    "IMP-001","IMP-002","IMP-003","IMP-010","IMP-011","IMP-SESSION-LIST-MISMATCH","IMP-SESSION-PAYLOAD-MISMATCH","IMP-INCOMPLETE-STATE",
    "FDB-008","FDB-009"
  ];
  for(const id of statefulRequired) if(!serverPlans[id]) throw new Error("STATEFUL_SERVER_PLAN_MISSING:"+id);

  const importModes={
    "IMP-011":"COMPLETED",
    "IMP-SESSION-LIST-MISMATCH":"COMPLETED",
    "IMP-SESSION-PAYLOAD-MISMATCH":"COMPLETED",
    "IMP-INCOMPLETE-STATE":"INCOMPLETE"
  };
  for(const [id,mode] of Object.entries(importModes)){
    const plan=serverPlans[id];
    if(plan.kind!=="IMPORT" || !plan.scopes?.some(s=>s.seed_mode===mode)) throw new Error("DETERMINISTIC_PRECONDITION_SETUP_MISSING:"+id);
  }

  const requiredServerModes={
    "COR-012":["SERVER_AFTER_PATH_EQUALS_LITERAL"],
    "CRM-015":["SERVER_DELTA_ARRAY_COUNT_EQUALS","SERVER_AFTER_PATH_EQUALS_VAR"],
    "FUN-007":["SERVER_DELTA_ARRAY_COUNT_EQUALS","SERVER_DELTA_ARRAY_ALL_FIELD_EQUALS_VAR"],
    "FUN-008":["SERVER_DELTA_ARRAY_COUNT_EQUALS","ALL_RESPONSE_BODIES_CANONICALLY_EQUAL"],
    "ACL-010":["SERVER_DELTA_ARRAY_COUNT_EQUALS","SERVER_AFTER_ARRAY_CONTAINS_TARGET"],
    "IMP-001":["SERVER_DELTA_ARRAY_COUNT_EQUALS","SERVER_AFTER_ARRAY_UNIQUE_FIELD"],
    "IMP-003":["SERVER_DELTA_ARRAY_COUNT_EQUALS","ALL_RESPONSE_BODIES_CANONICALLY_EQUAL"],
    "IMP-010":["SERVER_DELTA_ARRAY_COUNT_EQUALS","SERVER_AFTER_ARRAY_UNIQUE_FIELD"],
    "IMP-011":["SERVER_STATE_UNCHANGED"],
    "FDB-008":["SERVER_AFTER_PATH_EQUALS_LITERAL","SERVER_DELTA_ARRAY_COUNT_EQUALS","SERVER_DELTA_ARRAY_ALL_FIELD_EQUALS_LITERAL"],
    "FDB-009":["SERVER_AFTER_PATH_EQUALS_LITERAL","SERVER_DELTA_ARRAY_COUNT_EQUALS","SERVER_DELTA_ARRAY_ALL_FIELD_EQUALS_LITERAL"]
  };
  for(const [id,modes] of Object.entries(requiredServerModes)){
    const present=new Set((matrix.records.find(x=>x.test_id===id)?.semantic_assertions||[]).map(x=>x.mode));
    for(const mode of modes) if(!present.has(mode)) throw new Error("SERVER_SEMANTIC_MODE_MISSING:"+id+":"+mode);
  }
  const cor12=matrix.records.find(x=>x.test_id==="COR-012");
  if(!(cor12.semantic_assertions||[]).some(x=>x.mode==="SERVER_AFTER_PATH_EQUALS_LITERAL"&&x.path==="broker.ativo"&&x.value===false)) throw new Error("COR012_ACTIVE_ASSERTION_MISSING");

  function selectedFields(pathTemplate){
    const mm=String(pathTemplate||"").match(/[?&]select=([^&]+)/);
    if(!mm) return null;
    return new Set(mm[1].split(",").map(x=>x.trim()));
  }
  for(const rec of matrix.records.filter(x=>x.runner==="http_matrix"&&!x.server_case_plan)){
    const after=rec.mutation_probe_plan?.after||[];
    for(const a of rec.semantic_assertions||[]){
      if(["AFTER_FIRST_ROW_FIELD_EQUALS_VAR","AFTER_FIRST_ROW_FIELD_EQUALS_LITERAL","DELTA_ROWS_ALL_FIELD_EQUALS_VAR"].includes(a.mode)){
        const spec=after[a.probe_index],fields=selectedFields(spec?.path_template);
        if(fields && a.field && !fields.has(a.field)) throw new Error("ASSERTS_UNSELECTED_FIELD:"+rec.test_id+":"+a.field);
      }
      if(a.mode==="AFTER_ROWS_CONTAIN_TARGET"){
        const spec=after[a.probe_index],fields=selectedFields(spec?.path_template);
        if(fields && (!fields.has("target_type")||!fields.has("target_id"))) throw new Error("ASSERTS_UNSELECTED_TARGET_FIELDS:"+rec.test_id);
      }
    }
  }

  if(matrix.residuals?.["IMP-003"]!=="NOT_DETERMINED") throw new Error("IMP003_STATUS_DRIFT");
  if(matrix.residuals?.ROLLBACK_REAPPLY!=="NOT_DETERMINED") throw new Error("ROLLBACK_STATUS_DRIFT");
  if(matrix.records.find(r=>r.test_id==="IMP-003")?.prior_evidence!==null) throw new Error("IMP003_PRIOR_PASS_OVERCLAIM");

  if(/CUSTOM_ASSERTED_BY_FIXTURE/.test(matrixText+http)) throw new Error("CUSTOM_FIXTURE_ASSERTION_FORBIDDEN");
  if(/allowed_http_error_class/.test(matrixText+http)) throw new Error("BROAD_4XX_CLASS_REMAINS");
  if(/fixture\.cases|spec\.url|fetch\(spec\.url/.test(http)) throw new Error("FIXTURE_OR_ARBITRARY_URL_EXECUTION_FORBIDDEN");
  if(/for \(const check of matrix\.topology_contract\?\.checks/.test(http)) throw new Error("RUNNER_EXECUTES_ALL_TOPOLOGY_CHECKS");

  for(const needle of [
    "runTopologyPreflight(record)",
    "record.topology_dependencies",
    "PR08_SERVER_EVIDENCE_HARD_DENY_PRODUCTION_PROJECT_REF",
    "SERVER-EVIDENCE-PREFLIGHT",
    "seedCompletedImport",
    "seedIncompleteImport",
    "cleanupServerCase",
    "cleanup_restored",
    "PR08_CASE_CLEANUP_NOT_RESTORED",
    "SERVER_DELTA_ARRAY_COUNT_EQUALS",
    "overlap_ms"
  ]) if(!http.includes(needle)) throw new Error("HTTP_V4_CONTRACT_MISSING:"+needle);

  for(const needle of [
    "SERVER-EVIDENCE-PREFLIGHT",
    "server evidence channel hard-denies production",
    "server_evidence_owner_role_is_postgres",
    "idempotency_zero_client_policies",
    "idempotency_no_client_direct_dml"
  ]) if(!sql.includes(needle)) throw new Error("SERVER_EVIDENCE_SQL_PREFLIGHT_MISSING:"+needle);

  if(!rollback.includes("--restrict-key=FECHAIPR08STATEHASH")) throw new Error("ROLLBACK_DETERMINISTIC_RESTRICT_KEY_MISSING");
  if(!rollback.includes("PR08_EXACTLY_ONE_ROLLBACK_CASE_REQUIRED") || !rollback.includes("PR08_DATABASE_HOST_PROJECT_BINDING_MISMATCH") || !rollback.includes("state_after_reapply_sha256")) throw new Error("ROLLBACK_CONTRACT_REGRESSION");
  if(!sql.includes("IMP-CLAIMANT-ROLLBACK") || !sql.includes("no_claimant_marker_residue")) throw new Error("CLAIMANT_SQL_PLAN_REGRESSION");

  if(/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i.test(matrixText)) throw new Error("UUID_FORBIDDEN");
  if(/eyJ[A-Za-z0-9_-]{10,}\./.test(matrixText)) throw new Error("JWT_FORBIDDEN");

  process.stdout.write(JSON.stringify({
    status:"PASS",
    counts,
    topology_checks:topologyChecks.length,
    global_topology_checks:matrix.topology_contract.global_check_ids.length,
    server_case_plans:Object.keys(serverPlans).length,
    mutating_cases:mutating.length,
    imp003:"NOT_DETERMINED",
    rollback_reapply:"NOT_DETERMINED"
  })+"\n");
}
main().catch(error=>{
  process.stderr.write(JSON.stringify({status:"FAIL",error:String(error?.message||error)})+"\n");
  process.exitCode=1;
});
