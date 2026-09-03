#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const crypto = await import("node:crypto");
  const { spawnSync } = await import("node:child_process");

  const PROD_REF = "uobxxgzshrmbtjfdolxd";
  const root = process.cwd();
  const matrix = JSON.parse(await fs.readFile(path.join(root,"supabase/tests/f1-02-pr08/matrix.json"),"utf8"));
  const fixturePath = process.env.FECHAI_PR08_ROLLBACK_FIXTURE_FILE;

  if (process.env.FECHAI_PR08_ROLLBACK_REAPPLY_AUTHORIZED !== "YES") throw new Error("PR08_ROLLBACK_REAPPLY_NOT_AUTHORIZED");
  if (process.env.FECHAI_PR08_ISOLATED_ENVIRONMENT !== "YES") throw new Error("PR08_ISOLATED_ENVIRONMENT_ASSERTION_REQUIRED");
  if (!fixturePath) throw new Error("PR08_ROLLBACK_FIXTURE_FILE_REQUIRED");

  const fixture = JSON.parse(await fs.readFile(path.resolve(fixturePath),"utf8"));
  const allowedFixtureKeys = new Set(["target_project_ref","environment","fixture_version","database_url_env","psql_bin","pg_dump_bin"]);
  for (const key of Object.keys(fixture)) if (!allowedFixtureKeys.has(key)) throw new Error("PR08_ROLLBACK_FIXTURE_FIELD_FORBIDDEN:"+key);

  if (!fixture.target_project_ref || !fixture.environment || !fixture.fixture_version) throw new Error("PR08_TARGET_IDENTITY_REQUIRED");
  if (!/^[a-z0-9]{20}$/.test(fixture.target_project_ref)) throw new Error("PR08_PROJECT_REF_INVALID");
  if (fixture.target_project_ref === PROD_REF) throw new Error("PR08_HARD_DENY_PRODUCTION_PROJECT_REF");
  if (fixture.environment === "production") throw new Error("PR08_HARD_DENY_PRODUCTION_ENVIRONMENT_LABEL");

  const databaseUrl = process.env[fixture.database_url_env || "FECHAI_PR08_DATABASE_URL"];
  if (!databaseUrl) throw new Error("PR08_DATABASE_URL_REQUIRED");
  const u = new URL(databaseUrl);
  const expectedHost = "db."+fixture.target_project_ref+".supabase.co";
  if (u.hostname !== expectedHost) throw new Error("PR08_DATABASE_HOST_PROJECT_BINDING_MISMATCH");
  if (u.hostname === "db."+PROD_REF+".supabase.co" || u.hostname.includes(PROD_REF)) throw new Error("PR08_HARD_DENY_PRODUCTION_DATABASE_HOST");

  const pgEnv = {
    ...process.env,
    PGHOST:u.hostname,
    PGPORT:u.port || "5432",
    PGDATABASE:u.pathname.replace(/^\//,""),
    PGUSER:decodeURIComponent(u.username),
    PGPASSWORD:decodeURIComponent(u.password),
    PGSSLMODE:u.searchParams.get("sslmode") || "require"
  };

  const selected = process.argv.slice(2);
  if (selected.length !== 1) throw new Error("PR08_EXACTLY_ONE_ROLLBACK_CASE_REQUIRED");
  const record = matrix.records.find(r=>r.runner==="rollback_reapply" && r.test_id===selected[0]);
  if (!record) throw new Error("PR08_ROLLBACK_CASE_NOT_FOUND");

  const psql = fixture.psql_bin || "psql";
  const pgDump = fixture.pg_dump_bin || "pg_dump";

  function run(bin,args,input,label) {
    const r = spawnSync(bin,args,{input,encoding:"utf8",env:pgEnv,maxBuffer:64*1024*1024});
    if (r.status !== 0) throw new Error(label+"_FAILED:"+String(r.stderr||"").slice(0,1000));
    return r.stdout || "";
  }
  function stateHash(label) {
    const dump = run(pgDump,["--schema=public","--no-comments","--format=plain"],undefined,label+"_PG_DUMP");
    return crypto.createHash("sha256").update(dump).digest("hex");
  }
  function extractEmbeddedRollback(text,marker) {
    const at = text.indexOf(marker);
    if (at < 0) throw new Error("PR08_EMBEDDED_ROLLBACK_MARKER_NOT_FOUND");
    const statements = text.slice(at+marker.length).split("\n")
      .map(line=>line.match(/^\s*--\s?(.*;\s*)$/)?.[1])
      .filter(Boolean);
    if (!statements.length) throw new Error("PR08_EMBEDDED_ROLLBACK_EMPTY");
    return statements.join("\n")+"\n";
  }

  const migration = record.migration_artifacts?.[0];
  if (!migration?.path || !migration?.blob || !migration?.final_commit) throw new Error("PR08_MIGRATION_PROVENANCE_REQUIRED");
  const migrationSql = await fs.readFile(path.join(root,migration.path),"utf8");

  let rollbackSql;
  if (record.rollback_artifact?.kind === "FILE") {
    if (!record.rollback_artifact.path || !record.rollback_artifact.blob || !record.rollback_artifact.final_commit) throw new Error("PR08_ROLLBACK_PROVENANCE_REQUIRED");
    rollbackSql = await fs.readFile(path.join(root,record.rollback_artifact.path),"utf8");
  } else if (record.rollback_artifact?.kind === "EMBEDDED_EXACT_BLOCK") {
    rollbackSql = extractEmbeddedRollback(migrationSql,record.rollback_artifact.marker);
  } else {
    throw new Error("PR08_ROLLBACK_ARTIFACT_REQUIRED");
  }

  const startedAt = new Date().toISOString();
  const initial = stateHash(record.test_id+"_INITIAL");

  run(psql,["-X","-v","ON_ERROR_STOP=1"],rollbackSql,record.test_id+"_ROLLBACK");
  const afterRollback = stateHash(record.test_id+"_AFTER_ROLLBACK");
  if (afterRollback === initial) throw new Error("PR08_ROLLBACK_STATE_DID_NOT_CHANGE");

  run(psql,["-X","-v","ON_ERROR_STOP=1"],migrationSql,record.test_id+"_REAPPLY");
  const afterReapply = stateHash(record.test_id+"_AFTER_REAPPLY");
  if (afterReapply !== initial) throw new Error("PR08_REAPPLY_STATE_NOT_RESTORED");

  const receipt = {
    schema:"fechai.pr08.rollback.receipt.v2",
    test_id:record.test_id,
    project_ref:fixture.target_project_ref,
    environment:fixture.environment,
    fixture_version:fixture.fixture_version,
    migration_blob:migration.blob,
    migration_final_commit:migration.final_commit,
    rollback_blob:record.rollback_artifact?.blob || migration.blob,
    rollback_final_commit:record.rollback_artifact?.final_commit || migration.final_commit,
    state_initial_sha256:initial,
    state_after_rollback_sha256:afterRollback,
    state_after_reapply_sha256:afterReapply,
    rollback:"PASS",
    reapply:"PASS",
    started_at:startedAt,
    finished_at:new Date().toISOString(),
    evidence_reference:process.env.FECHAI_PR08_ROLLBACK_RECEIPT_FILE || "STDOUT_ONLY"
  };

  const output = JSON.stringify(receipt,null,2)+"\n";
  if (process.env.FECHAI_PR08_ROLLBACK_RECEIPT_FILE) await fs.writeFile(path.resolve(process.env.FECHAI_PR08_ROLLBACK_RECEIPT_FILE),output,{flag:"wx"});
  process.stdout.write(output);
}
main().catch(error=>{
  process.stderr.write(JSON.stringify({error:String(error?.message||error)})+"\n");
  process.exitCode=1;
});
