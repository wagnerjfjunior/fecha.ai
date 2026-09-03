#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const { fileURLToPath } = await import("node:url");
  const here = path.dirname(fileURLToPath(import.meta.url));
  const root = path.resolve(here, "../../..");
  const matrixText = await fs.readFile(path.join(root,"supabase/tests/f1-02-pr08/matrix.json"),"utf8");
  const matrix = JSON.parse(matrixText);
  const records = matrix.records || [];
  const expected = {AUTH:5,COR:13,CRM:15,FUN:8,ACL:10,STG:7,IMP:16,FDB:11,ROL:11,PRD:2,TOTAL:98};
  const required = matrix.required_record_fields || [];
  const counts={TOTAL:records.length};
  const ids=new Set();

  for (const r of records) {
    if (ids.has(r.test_id)) throw new Error("DUPLICATE_TEST_ID:" + r.test_id);
    ids.add(r.test_id);
    const category=r.test_id.split("-")[0];
    counts[category]=(counts[category]||0)+1;
    for (const field of required) if (!(field in r)) throw new Error("MISSING_FIELD:" + r.test_id + ":" + field);
    if (r.exact_application_commit !== "9d05c64281c2aeeae9d67b139eab674720184fb1") throw new Error("APP_COMMIT_DRIFT:" + r.test_id);
    if (r.pass_fail !== "NOT_EXECUTED" || r.actual_authorization_result !== "NOT_EXECUTED" || r.actual_data_mutation !== "NOT_EXECUTED") {
      throw new Error("EXECUTION_OVERCLAIM:" + r.test_id);
    }
    if (r.runner === "rollback_reapply" && r.supabase_project_ref !== "NON_PRODUCTION_REQUIRED") {
      throw new Error("ROLLBACK_PROJECT_POLICY_DRIFT:" + r.test_id);
    }
  }
  for (const [k,v] of Object.entries(expected)) if (counts[k] !== v) throw new Error("COUNT_MISMATCH:" + k + ":" + counts[k] + "!=" + v);
  if (matrix.residuals?.["IMP-003"] !== "NOT_DETERMINED") throw new Error("IMP003_STATUS_DRIFT");
  if (matrix.residuals?.ROLLBACK_REAPPLY !== "NOT_DETERMINED") throw new Error("ROLLBACK_STATUS_DRIFT");
  if (records.find(r=>r.test_id==="IMP-003")?.prior_evidence !== null) throw new Error("IMP003_PRIOR_PASS_OVERCLAIM");
  if (/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i.test(matrixText)) throw new Error("UUID_FORBIDDEN");
  if (/eyJ[A-Za-z0-9_-]{10,}\./.test(matrixText)) throw new Error("JWT_FORBIDDEN");

  const sql = await fs.readFile(path.join(root,"supabase/tests/f1-02-pr08/runtime_security_matrix.sql"),"utf8");
  if (!sql.includes("READ_ONLY") || !sql.includes("\\ir ../f1-02-b2/") || !sql.includes("\\ir ../f1-02-pr07/")) {
    throw new Error("SQL_PREFLIGHT_CONTRACT_DRIFT");
  }
  process.stdout.write(JSON.stringify({status:"PASS",counts,imp003:"NOT_DETERMINED",rollback_reapply:"NOT_DETERMINED"})+"\n");
}
main().catch(error => {
  process.stderr.write(JSON.stringify({status:"FAIL",error:String(error?.message || error)})+"\n");
  process.exitCode=1;
});
