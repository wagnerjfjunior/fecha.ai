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

  const expected={AUTH:5,COR:13,CRM:15,FUN:8,ACL:10,STG:7,IMP:16,FDB:11,ROL:11,PRD:2,TOTAL:98};
  const counts={TOTAL:matrix.records.length};
  const ids=new Set();

  if(matrix.schema!=="fechai.f1-02.pr08.matrix.v3") throw new Error("MATRIX_SCHEMA_DRIFT");
  if(matrix.execution_contract?.fixture_topology!=="MANDATORY_VERSIONED_PREFLIGHT") throw new Error("TOPOLOGY_CONTRACT_MISSING");
  if(matrix.execution_contract?.denial_semantics!=="EXACT_STATUS_AND_EXPECTED_ERROR_EVIDENCE") throw new Error("DENIAL_CONTRACT_MISSING");
  if(matrix.execution_contract?.explicit_selection!=="REQUIRED_UNLESS_EXPLICIT_ALL") throw new Error("SELECTION_CONTRACT_MISSING");
  if(!Array.isArray(matrix.topology_contract?.checks) || matrix.topology_contract.checks.length<30) throw new Error("TOPOLOGY_CHECK_COVERAGE_TOO_SMALL");

  const topologyIds=new Set(matrix.topology_contract.checks.map(x=>x.check_id));
  for(const rel of matrix.topology_contract.variable_relations||[]){
    if(rel.mode!=="NOT_EQUAL" || !rel.left || !rel.right) throw new Error("TOPOLOGY_VARIABLE_RELATION_INVALID");
  }
  for(const check of matrix.topology_contract.checks){
    if(!check.check_id || !check.request?.path_template || !check.assertion?.mode) throw new Error("TOPOLOGY_CHECK_INVALID");
    if(!check.request.path_template.startsWith("/") || check.request.path_template.startsWith("//") || /^[a-z]+:/i.test(check.request.path_template)) {
      throw new Error("TOPOLOGY_ABSOLUTE_PATH_FORBIDDEN:"+check.check_id);
    }
  }

  const required=matrix.required_record_fields||[];
  for(const rec of matrix.records){
    if(!rec.test_id || ids.has(rec.test_id)) throw new Error("DUPLICATE_OR_MISSING_TEST_ID:"+rec.test_id);
    ids.add(rec.test_id);
    const cat=rec.test_id.split("-")[0];
    counts[cat]=(counts[cat]||0)+1;
    for(const field of required) if(!(field in rec)) throw new Error("MISSING_FIELD:"+rec.test_id+":"+field);

    if(rec.exact_application_commit!=="9d05c64281c2aeeae9d67b139eab674720184fb1") throw new Error("APP_COMMIT_DRIFT:"+rec.test_id);
    if(rec.pass_fail!=="NOT_EXECUTED" || rec.actual_authorization_result!=="NOT_EXECUTED" || rec.actual_data_mutation!=="NOT_EXECUTED") throw new Error("EXECUTION_OVERCLAIM:"+rec.test_id);

    const artifactCommits=[];
    for(const a of rec.migration_artifacts||[]){
      const expectedCommit=matrix.artifact_binding?.migration_final_commits?.[a.path];
      if(!expectedCommit || a.final_commit!==expectedCommit) throw new Error("MIGRATION_FINAL_COMMIT_DRIFT:"+rec.test_id+":"+a.path);
      if(!/^[0-9a-f]{40}$/.test(a.blob) || !/^[0-9a-f]{40}$/.test(a.final_commit)) throw new Error("MIGRATION_PROVENANCE_FORMAT:"+rec.test_id);
      artifactCommits.push(a.final_commit);
    }
    const exact=[...new Set(artifactCommits)];
    if(JSON.stringify(exact)!==JSON.stringify(rec.exact_migration_commits)) throw new Error("EXACT_MIGRATION_COMMITS_MISMATCH:"+rec.test_id);

    for(const dep of rec.topology_dependencies||[]) if(!topologyIds.has(dep)) throw new Error("UNKNOWN_TOPOLOGY_DEPENDENCY:"+rec.test_id+":"+dep);

    if(rec.runner==="http_matrix"){
      if(!rec.request_plan?.requests?.length) throw new Error("VERSIONED_REQUEST_PLAN_MISSING:"+rec.test_id);
      if(!rec.mutation_probe_plan?.before?.length || !rec.mutation_probe_plan?.after?.length) throw new Error("VERSIONED_PROBE_PLAN_MISSING:"+rec.test_id);
      for(const spec of [...rec.request_plan.requests,...rec.mutation_probe_plan.before,...rec.mutation_probe_plan.after]){
        if(typeof spec.path_template!=="string" || !spec.path_template.startsWith("/") || spec.path_template.startsWith("//") || /^[a-z]+:/i.test(spec.path_template)) throw new Error("ABSOLUTE_OR_INVALID_PATH:"+rec.test_id);
        if(!["GET","POST","PATCH","DELETE","HEAD"].includes(spec.method)) throw new Error("METHOD_NOT_VERSIONED:"+rec.test_id);
        if("url" in spec || "origin" in spec) throw new Error("ABSOLUTE_TARGET_FIELD_FORBIDDEN:"+rec.test_id);
      }

      const deny=rec.request_plan.response_assertion?.mode==="DENIAL_SEMANTIC";
      if(deny){
        const a=rec.request_plan.response_assertion;
        if(!Array.isArray(a.expected_statuses) || !a.expected_statuses.length) throw new Error("DENY_STATUS_MISSING:"+rec.test_id);
        if(a.allowed_http_error_class!==undefined) throw new Error("BROAD_4XX_CLASS_FORBIDDEN:"+rec.test_id);
        if(!a.expected_error_exact && !a.expected_error_regex && !a.expected_error_codes?.length) throw new Error("DENY_ERROR_EVIDENCE_MISSING:"+rec.test_id);
      }

      const nontrivialPositive=!String(rec.expected_authorization_result).startsWith("DENY") &&
        !["AUTH-001","AUTH-004","AUTH-005","STG-001","STG-002","STG-007","PRD-002"].includes(rec.test_id);
      if(nontrivialPositive && !rec.semantic_assertions?.length) throw new Error("POSITIVE_SEMANTIC_ASSERTION_MISSING:"+rec.test_id);

      if(rec.execution_mode==="CONCURRENT_HTTP"){
        if(!rec.concurrency_assertion?.require_positive_overlap || rec.concurrency_assertion.min_overlap_ms<1 || !rec.concurrency_assertion.receipt_per_request_timing) throw new Error("CONCURRENCY_OVERLAP_ASSERTION_MISSING:"+rec.test_id);
        if(rec.request_plan.requests.length<2) throw new Error("CONCURRENCY_REQUEST_COUNT:"+rec.test_id);
      }
    }

    if(rec.runner==="rollback_reapply"){
      if(rec.supabase_project_ref!=="NON_PRODUCTION_REQUIRED") throw new Error("ROLLBACK_PROJECT_POLICY_DRIFT:"+rec.test_id);
      if(rec.verification_contract?.isolation!=="EXACTLY_ONE_ROL_CASE_PER_INVOCATION") throw new Error("ROLLBACK_ISOLATION_CONTRACT_MISSING:"+rec.test_id);
      if(rec.verification_contract?.after_reapply!=="SHA256_MUST_EQUAL_INITIAL") throw new Error("REAPPLY_STATE_RESTORE_CONTRACT_MISSING:"+rec.test_id);
    }
  }

  for(const [k,v] of Object.entries(expected)) if(counts[k]!==v) throw new Error("COUNT_MISMATCH:"+k+":"+counts[k]+"!="+v);

  const probeMustMention={
    "COR-003":"FOREIGN_CORRETOR_ID",
    "CRM-006":"FOREIGN_LISTA_ID",
    "CRM-011":"WRONG_OWNER_LEAD_ID",
    "CRM-012":"FOREIGN_LEAD_ID",
    "CRM-013":"FOREIGN_LOTE_ID",
    "IMP-004":"FOREIGN_LISTA_ID",
    "IMP-SESSION-LIST-MISMATCH":"MISMATCH_LISTA_ID",
    "FDB-005":"WRONG_OWNER_LEAD_ID",
    "FDB-006":"FOREIGN_LEAD_ID"
  };
  for(const [id,varName] of Object.entries(probeMustMention)){
    const rec=matrix.records.find(x=>x.test_id===id);
    if(!JSON.stringify(rec.mutation_probe_plan).includes("\+varName+")) throw new Error("MUTATION_PROBE_TARGET_MISMATCH:"+id+":"+varName);
  }

  const semanticMust={
    "STG-003":["RESPONSE_ARRAY_IDS_EQUAL_VAR_SET"],
    "STG-004":["RESPONSE_ARRAY_IDS_EQUAL_VAR_SET","RESPONSE_ARRAY_IDS_EXCLUDE_VAR_SET"],
    "STG-005":["RESPONSE_ARRAY_ORDER_ASC"],
    "STG-006":["RESPONSE_ARRAY_EMPTY"],
    "FUN-007":["AFTER_FIRST_ROW_FIELD_EQUALS_VAR","DELTA_ROWS_ALL_FIELD_EQUALS_VAR"],
    "FDB-008":["AFTER_FIRST_ROW_FIELD_EQUALS_LITERAL"],
    "ACL-010":["RESPONSE_OBJECT_ARRAY_CONTAINS_TARGET","AFTER_ROWS_CONTAIN_TARGET"],
    "IMP-001":["DELTA_ROW_COUNT_EQUALS","AFTER_ROWS_UNIQUE_FIELD","ALL_RESPONSE_BODIES_CANONICALLY_EQUAL"],
    "IMP-003":["DELTA_ROW_COUNT_EQUALS","AFTER_ROWS_UNIQUE_FIELD","ALL_RESPONSE_BODIES_CANONICALLY_EQUAL"],
    "IMP-002":["DELTA_ROW_COUNT_EQUALS"],
    "IMP-010":["DELTA_ROW_COUNT_EQUALS","AFTER_ROWS_UNIQUE_FIELD"],
    "IMP-011":["DELTA_ROW_COUNT_EQUALS"]
  };
  for(const [id,modes] of Object.entries(semanticMust)){
    const rec=matrix.records.find(x=>x.test_id===id);
    const present=new Set((rec.semantic_assertions||[]).map(x=>x.mode));
    for(const mode of modes) if(!present.has(mode)) throw new Error("SEMANTIC_MODE_MISSING:"+id+":"+mode);
  }

  if(matrix.residuals?.["IMP-003"]!=="NOT_DETERMINED") throw new Error("IMP003_STATUS_DRIFT");
  if(matrix.residuals?.ROLLBACK_REAPPLY!=="NOT_DETERMINED") throw new Error("ROLLBACK_STATUS_DRIFT");
  if(matrix.records.find(r=>r.test_id==="IMP-003")?.prior_evidence!==null) throw new Error("IMP003_PRIOR_PASS_OVERCLAIM");

  if(/CUSTOM_ASSERTED_BY_FIXTURE/.test(matrixText+http)) throw new Error("CUSTOM_FIXTURE_ASSERTION_FORBIDDEN");
  if(/allowed_http_error_class/.test(matrixText+http)) throw new Error("BROAD_4XX_CLASS_REMAINS");
  if(/fixture\.cases|spec\.url|fetch\(spec\.url/.test(http)) throw new Error("FIXTURE_OR_ARBITRARY_URL_EXECUTION_FORBIDDEN");

  for(const needle of [
    "PR08_EXPLICIT_CASE_SELECTION_REQUIRED",
    "PR08_ALL_FLAG_MUST_BE_EXCLUSIVE",
    "runTopologyPreflight",
    "PR08_TOPOLOGY_ASSERTION_FAILED",
    "expected_statuses.includes",
    "sanitized_error_code:errorCodes",
    "semanticAssertionPass",
    "DELTA_ROW_COUNT_EQUALS",
    "overlap_ms"
  ]) if(!http.includes(needle)) throw new Error("HTTP_CONTRACT_MISSING:"+needle);

  if(!rollback.includes("PR08_EXACTLY_ONE_ROLLBACK_CASE_REQUIRED") || !rollback.includes("PR08_DATABASE_HOST_PROJECT_BINDING_MISMATCH") || !rollback.includes("state_after_reapply_sha256")) throw new Error("ROLLBACK_CONTRACT_REGRESSION");
  if(!sql.includes("IMP-CLAIMANT-ROLLBACK") || !sql.includes("no_claimant_marker_residue")) throw new Error("CLAIMANT_SQL_PLAN_REGRESSION");

  if(/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i.test(matrixText)) throw new Error("UUID_FORBIDDEN");
  if(/eyJ[A-Za-z0-9_-]{10,}\./.test(matrixText)) throw new Error("JWT_FORBIDDEN");

  process.stdout.write(JSON.stringify({
    status:"PASS",
    counts,
    topology_checks:matrix.topology_contract.checks.length,
    imp003:"NOT_DETERMINED",
    rollback_reapply:"NOT_DETERMINED"
  })+"\n");
}
main().catch(error=>{
  process.stderr.write(JSON.stringify({status:"FAIL",error:String(error?.message||error)})+"\n");
  process.exitCode=1;
});
