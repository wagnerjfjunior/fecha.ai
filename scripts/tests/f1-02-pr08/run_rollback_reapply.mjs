#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const { fileURLToPath } = await import("node:url");
  const { spawnSync } = await import("node:child_process");

  const PROD_REF = "uobxxgzshrmbtjfdolxd";
  const PROD_HOST = "db.uobxxgzshrmbtjfdolxd.supabase.co";
  const here = path.dirname(fileURLToPath(import.meta.url));
  const root = path.resolve(here, "../../..");
  const matrix = JSON.parse(await fs.readFile(path.join(root, "supabase/tests/f1-02-pr08/matrix.json"), "utf8"));
  const fixturePath = process.env.FECHAI_PR08_ROLLBACK_FIXTURE_FILE;

  if (process.env.FECHAI_PR08_ROLLBACK_REAPPLY_AUTHORIZED !== "YES") {
    throw new Error("PR08_ROLLBACK_REAPPLY_NOT_AUTHORIZED");
  }
  if (process.env.FECHAI_PR08_ISOLATED_ENVIRONMENT !== "YES") {
    throw new Error("PR08_ISOLATED_ENVIRONMENT_ASSERTION_REQUIRED");
  }
  if (!fixturePath) throw new Error("PR08_ROLLBACK_FIXTURE_FILE_REQUIRED");

  const fixture = JSON.parse(await fs.readFile(path.resolve(fixturePath), "utf8"));
  if (!fixture.target_project_ref || !fixture.environment) throw new Error("PR08_TARGET_IDENTITY_REQUIRED");
  if (fixture.target_project_ref === PROD_REF) throw new Error("PR08_HARD_DENY_PRODUCTION_PROJECT_REF");

  const databaseUrl = process.env[fixture.database_url_env || "FECHAI_PR08_DATABASE_URL"];
  if (!databaseUrl) throw new Error("PR08_DATABASE_URL_REQUIRED");
  const u = new URL(databaseUrl);
  if (u.hostname === PROD_HOST || u.hostname.includes(PROD_REF)) {
    throw new Error("PR08_HARD_DENY_PRODUCTION_DATABASE_HOST");
  }

  const pgEnv = {...process.env,
    PGHOST:u.hostname,
    PGPORT:u.port || "5432",
    PGDATABASE:u.pathname.replace(/^\//, ""),
    PGUSER:decodeURIComponent(u.username),
    PGPASSWORD:decodeURIComponent(u.password),
    PGSSLMODE:u.searchParams.get("sslmode") || "require"
  };
  delete pgEnv.FECHAI_PR08_DATABASE_URL;

  function extractEmbeddedRollback(text, marker) {
    const at = text.indexOf(marker);
    if (at < 0) throw new Error("PR08_EMBEDDED_ROLLBACK_MARKER_NOT_FOUND");
    const statements = text.slice(at + marker.length).split("\n")
      .map(line => line.match(/^\s*--\s?(.*;\s*)$/)?.[1])
      .filter(Boolean);
    if (!statements.length) throw new Error("PR08_EMBEDDED_ROLLBACK_EMPTY");
    return statements.join("\n") + "\n";
  }
  function runSql(label, sql) {
    const r = spawnSync(fixture.psql_bin || "psql", ["-X","-v","ON_ERROR_STOP=1"], {
      input:sql, encoding:"utf8", env:pgEnv, maxBuffer:10*1024*1024
    });
    if (r.status !== 0) {
      throw new Error(label + "_FAILED:" + String(r.stderr || "").slice(0,500));
    }
  }

  const selected = process.argv.slice(2);
  const records = matrix.records.filter(r =>
    r.runner === "rollback_reapply" && (selected.length === 0 || selected.includes(r.test_id))
  );
  if (!records.length) throw new Error("PR08_NO_ROLLBACK_CASES_SELECTED");

  const receipts=[];
  for (const record of records) {
    const migration = record.migration_artifacts?.[0];
    if (!migration?.path || !migration?.blob) throw new Error("PR08_MIGRATION_ARTIFACT_REQUIRED:" + record.test_id);
    const migrationSql = await fs.readFile(path.join(root,migration.path),"utf8");

    let rollbackSql;
    if (record.rollback_artifact?.kind === "FILE") {
      rollbackSql = await fs.readFile(path.join(root,record.rollback_artifact.path),"utf8");
    } else if (record.rollback_artifact?.kind === "EMBEDDED_EXACT_BLOCK") {
      rollbackSql = extractEmbeddedRollback(migrationSql,record.rollback_artifact.marker);
    } else {
      throw new Error("PR08_ROLLBACK_ARTIFACT_REQUIRED:" + record.test_id);
    }

    const started = new Date().toISOString();
    runSql(record.test_id + "_ROLLBACK", rollbackSql);
    runSql(record.test_id + "_REAPPLY", migrationSql);
    receipts.push({
      test_id:record.test_id,
      project_ref:fixture.target_project_ref,
      environment:fixture.environment,
      rollback:"PASS",
      reapply:"PASS",
      started_at:started,
      finished_at:new Date().toISOString(),
      evidence_reference:process.env.FECHAI_PR08_ROLLBACK_RECEIPT_FILE || "STDOUT_ONLY"
    });
  }

  const output=JSON.stringify({schema:"fechai.pr08.rollback.receipt.v1",receipts},null,2)+"\n";
  if (process.env.FECHAI_PR08_ROLLBACK_RECEIPT_FILE) {
    await fs.writeFile(path.resolve(process.env.FECHAI_PR08_ROLLBACK_RECEIPT_FILE), output, {flag:"wx"});
  }
  process.stdout.write(output);
}
main().catch(error => {
  process.stderr.write(JSON.stringify({error:String(error?.message || error)})+"\n");
  process.exitCode=1;
});
