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

  const expected = {AUTH:5,COR:13,CRM:15,FUN:8,ACL:10,STG:7,IMP:16,FDB:11,ROL:11,PRD:2,TOTAL:98};
  const required = matrix.required_record_fields || [];
  const ids = new Set();
  const counts = {TOTAL:(matrix.records||[]).length};

  if (matrix.schema !== "fechai.f1-02.pr08.matrix.v2") throw new Error("MATRIX_SCHEMA_DRIFT");
  if (matrix.execution_contract?.request_specs !== "VERSIONED_IN_MATRIX") throw new Error("REQUEST_SPEC_CONTRACT_MISSING");
  if (matrix.execution_contract?.fixture_role !== "VALUES_AND_SECRETS_ONLY") throw new Error("FIXTURE_ROLE_DRIFT");
  if (matrix.execution_contract?.arbitrary_fixture_url_method_probe !== "FORBIDDEN") throw new Error("FIXTURE_REQUEST_AUTHORITY_NOT_FORBIDDEN");

  const forbiddenFixtureFields = new Set(matrix.fixture_contract?.forbidden_top_level_fields || []);
  for (const f of ["cases","request","requests","url","origin","method","expected_statuses","mutation_probe"]) {
    if (!forbiddenFixtureFields.has(f)) throw new Error("FIXTURE_FORBIDDEN_FIELD_CONTRACT_MISSING:"+f);
  }

  for (const r of matrix.records || []) {
    if (!r.test_id || ids.has(r.test_id)) throw new Error("DUPLICATE_OR_MISSING_TEST_ID:"+r.test_id);
    ids.add(r.test_id);
    const category = r.test_id.split("-")[0];
    counts[category] = (counts[category] || 0) + 1;

    for (const field of required) if (!(field in r)) throw new Error("MISSING_FIELD:"+r.test_id+":"+field);
    if (r.exact_application_commit !== "9d05c64281c2aeeae9d67b139eab674720184fb1") throw new Error("APP_COMMIT_DRIFT:"+r.test_id);
    if (r.pass_fail !== "NOT_EXECUTED" || r.actual_authorization_result !== "NOT_EXECUTED" || r.actual_data_mutation !== "NOT_EXECUTED") {
      throw new Error("EXECUTION_OVERCLAIM:"+r.test_id);
    }

    const artifactCommits = [];
    for (const artifact of r.migration_artifacts || []) {
      const expectedCommit = matrix.artifact_binding?.migration_final_commits?.[artifact.path];
      if (!expectedCommit || artifact.final_commit !== expectedCommit) throw new Error("MIGRATION_FINAL_COMMIT_DRIFT:"+r.test_id+":"+artifact.path);
      if (!/^[0-9a-f]{40}$/.test(artifact.blob) || !/^[0-9a-f]{40}$/.test(artifact.final_commit)) throw new Error("MIGRATION_PROVENANCE_FORMAT:"+r.test_id);
      artifactCommits.push(artifact.final_commit);
    }
    const exact = [...new Set(artifactCommits)];
    if (JSON.stringify(exact) !== JSON.stringify(r.exact_migration_commits)) throw new Error("EXACT_MIGRATION_COMMITS_MISMATCH:"+r.test_id);

    if (r.runner === "http_matrix") {
      if (!r.request_plan?.requests?.length) throw new Error("VERSIONED_REQUEST_PLAN_MISSING:"+r.test_id);
      if (!r.request_plan?.response_assertion?.mode) throw new Error("RESPONSE_ASSERTION_MISSING:"+r.test_id);
      if (!r.mutation_probe_plan?.before?.length || !r.mutation_probe_plan?.after?.length) throw new Error("VERSIONED_PROBE_PLAN_MISSING:"+r.test_id);
      if (!["MUST_EQUAL","MUST_CHANGE"].includes(r.mutation_probe_plan.expectation)) throw new Error("MUTATION_EXPECTATION_INVALID:"+r.test_id);

      for (const spec of [...r.request_plan.requests,...r.mutation_probe_plan.before,...r.mutation_probe_plan.after]) {
        if (typeof spec.path_template !== "string" || !spec.path_template.startsWith("/") || spec.path_template.startsWith("//") || /^[a-z]+:/i.test(spec.path_template)) {
          throw new Error("ABSOLUTE_OR_INVALID_PATH:"+r.test_id);
        }
        if (!["GET","POST","PATCH","DELETE","HEAD"].includes(spec.method)) throw new Error("METHOD_NOT_VERSIONED:"+r.test_id);
        if ("url" in spec || "origin" in spec) throw new Error("ABSOLUTE_TARGET_FIELD_FORBIDDEN:"+r.test_id);
      }

      if (r.execution_mode === "CONCURRENT_HTTP") {
        if (!r.concurrency_assertion?.require_positive_overlap || r.concurrency_assertion.min_overlap_ms < 1 || !r.concurrency_assertion.receipt_per_request_timing) {
          throw new Error("CONCURRENCY_OVERLAP_ASSERTION_MISSING:"+r.test_id);
        }
        if (r.request_plan.requests.length < 2) throw new Error("CONCURRENCY_REQUEST_COUNT:"+r.test_id);
      }
    }

    if (r.runner === "rollback_reapply") {
      if (r.supabase_project_ref !== "NON_PRODUCTION_REQUIRED") throw new Error("ROLLBACK_PROJECT_POLICY_DRIFT:"+r.test_id);
      if (r.verification_contract?.isolation !== "EXACTLY_ONE_ROL_CASE_PER_INVOCATION") throw new Error("ROLLBACK_ISOLATION_CONTRACT_MISSING:"+r.test_id);
      if (r.verification_contract?.after_rollback !== "SHA256_MUST_DIFFER_FROM_INITIAL") throw new Error("ROLLBACK_STATE_CHANGE_CONTRACT_MISSING:"+r.test_id);
      if (r.verification_contract?.after_reapply !== "SHA256_MUST_EQUAL_INITIAL") throw new Error("REAPPLY_STATE_RESTORE_CONTRACT_MISSING:"+r.test_id);
      if (r.rollback_artifact?.kind === "FILE") {
        const expectedCommit = matrix.artifact_binding?.rollback_final_commits?.[r.rollback_artifact.path];
        if (!expectedCommit || r.rollback_artifact.final_commit !== expectedCommit) throw new Error("ROLLBACK_FINAL_COMMIT_DRIFT:"+r.test_id);
      }
    }
  }

  for (const [k,v] of Object.entries(expected)) if (counts[k] !== v) throw new Error("COUNT_MISMATCH:"+k+":"+counts[k]+"!="+v);
  if (matrix.residuals?.["IMP-003"] !== "NOT_DETERMINED") throw new Error("IMP003_STATUS_DRIFT");
  if (matrix.residuals?.ROLLBACK_REAPPLY !== "NOT_DETERMINED") throw new Error("ROLLBACK_STATUS_DRIFT");
  if (matrix.records.find(r=>r.test_id==="IMP-003")?.prior_evidence !== null) throw new Error("IMP003_PRIOR_PASS_OVERCLAIM");

  if (/CUSTOM_ASSERTED_BY_FIXTURE/.test(matrixText+http)) throw new Error("CUSTOM_FIXTURE_ASSERTION_FORBIDDEN");
  if (/fixture\.cases|spec\.url|fetch\(spec\.url/.test(http)) throw new Error("FIXTURE_OR_ARBITRARY_URL_EXECUTION_FORBIDDEN");
  if (!http.includes("PR08_TARGET_ORIGIN_MISMATCH") || !http.includes('fixture.target_project_ref + ".supabase.co"')) throw new Error("HTTP_TARGET_BINDING_GUARD_MISSING");
  if (!http.includes("before_sha256") || !http.includes("after_sha256") || !http.includes("actual_data_mutation:{observed")) throw new Error("HTTP_MUTATION_EVIDENCE_MISSING");
  if (!http.includes("overlap_ms") || !http.includes("started_at") || !http.includes("finished_at")) throw new Error("CONCURRENCY_TIMING_EVIDENCE_MISSING");

  if (!rollback.includes("PR08_EXACTLY_ONE_ROLLBACK_CASE_REQUIRED")) throw new Error("ROLLBACK_SINGLE_CASE_GUARD_MISSING");
  if (!rollback.includes("PR08_DATABASE_HOST_PROJECT_BINDING_MISMATCH") || !rollback.includes("PR08_HARD_DENY_PRODUCTION_PROJECT_REF")) throw new Error("ROLLBACK_TARGET_BINDING_MISSING");
  if (!rollback.includes("state_after_rollback_sha256") || !rollback.includes("state_after_reapply_sha256") || !rollback.includes("PR08_REAPPLY_STATE_NOT_RESTORED")) {
    throw new Error("ROLLBACK_STATE_ASSERTION_MISSING");
  }

  if (!sql.includes("IMP-CLAIMANT-ROLLBACK") || !sql.includes("BEGIN;") || !sql.includes("ROLLBACK;") || !sql.includes("no_claimant_marker_residue")) {
    throw new Error("CLAIMANT_SQL_PLAN_MISSING");
  }

  if (/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i.test(matrixText)) throw new Error("UUID_FORBIDDEN");
  if (/eyJ[A-Za-z0-9_-]{10,}\./.test(matrixText)) throw new Error("JWT_FORBIDDEN");

  process.stdout.write(JSON.stringify({status:"PASS",counts,imp003:"NOT_DETERMINED",rollback_reapply:"NOT_DETERMINED"})+"\n");
}
main().catch(error=>{
  process.stderr.write(JSON.stringify({status:"FAIL",error:String(error?.message||error)})+"\n");
  process.exitCode=1;
});
