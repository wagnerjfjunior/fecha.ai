#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const { spawnSync } = await import("node:child_process");

  // PR08_SQL_RUNTIME_WRAPPER_V1
  const PROD_REF = "uobxxgzshrmbtjfdolxd";
  const root = process.cwd();
  const selected = process.argv.slice(2);
  if (selected.length !== 1) throw new Error("PR08_SQL_RUNTIME_EXACTLY_ONE_CASE_REQUIRED");
  if (selected[0] !== "IMP-CLAIMANT-ROLLBACK") throw new Error("PR08_SQL_RUNTIME_CASE_NOT_SUPPORTED");
  const caseId = selected[0];

  if (process.env.FECHAI_PR08_SQL_RUNTIME_AUTHORIZED !== "YES") throw new Error("PR08_SQL_RUNTIME_NOT_AUTHORIZED");

  const fixturePath = process.env.FECHAI_PR08_SQL_FIXTURE_FILE;
  if (!fixturePath) throw new Error("PR08_SQL_FIXTURE_FILE_REQUIRED");
  const fixture = JSON.parse(await fs.readFile(path.resolve(fixturePath),"utf8"));
  const allowedFixtureKeys = new Set([
    "target_project_ref","environment","fixture_version","variables",
    "expected_validos","expected_invalidos","expected_duplicados"
  ]);
  for (const key of Object.keys(fixture)) if (!allowedFixtureKeys.has(key)) throw new Error("PR08_SQL_FIXTURE_FIELD_FORBIDDEN:"+key);
  if (!fixture.target_project_ref || !fixture.environment || !fixture.fixture_version || !fixture.variables) throw new Error("PR08_SQL_FIXTURE_IDENTITY_REQUIRED");
  if (!/^[a-z0-9]{20}$/.test(fixture.target_project_ref)) throw new Error("PR08_SQL_FIXTURE_PROJECT_REF_INVALID");
  if (!fixture.variables || typeof fixture.variables !== "object" || Array.isArray(fixture.variables)) throw new Error("PR08_SQL_FIXTURE_VARIABLES_OBJECT_REQUIRED");

  const declaredProjectRef = process.env.FECHAI_PR08_TARGET_PROJECT_REF;
  if (!declaredProjectRef || !/^[a-z0-9]{20}$/.test(declaredProjectRef)) throw new Error("PR08_SQL_DECLARED_PROJECT_REF_REQUIRED");

  const databaseUrl = process.env.FECHAI_PR08_DATABASE_URL;
  if (!databaseUrl) throw new Error("PR08_SQL_DATABASE_URL_REQUIRED");
  const u = new URL(databaseUrl);
  if (!["postgres:","postgresql:"].includes(u.protocol)) throw new Error("PR08_SQL_DATABASE_URL_PROTOCOL_INVALID");
  const hostMatch = /^db\.([a-z0-9]{20})\.supabase\.co$/.exec(u.hostname);
  if (!hostMatch) throw new Error("PR08_SQL_DATABASE_HOST_UNSUPPORTED");
  const connectionProjectRef = hostMatch[1];

  // PR08_SQL_CONNECTION_PROJECT_BINDING
  if (connectionProjectRef !== fixture.target_project_ref || connectionProjectRef !== declaredProjectRef) {
    throw new Error("PR08_SQL_DATABASE_HOST_PROJECT_BINDING_MISMATCH");
  }

  const isProduction = connectionProjectRef === PROD_REF;
  if (isProduction) {
    if (fixture.environment !== "production") throw new Error("PR08_SQL_PRODUCTION_ENVIRONMENT_LABEL_MISMATCH");
    if (process.env.FECHAI_PR08_PRODUCTION_EXECUTION_AUTHORIZED !== "YES") throw new Error("PR08_SQL_PRODUCTION_EXECUTION_NOT_AUTHORIZED");
  } else if (fixture.environment === "production") {
    throw new Error("PR08_SQL_NONPROD_CONNECTION_CANNOT_DECLARE_PRODUCTION");
  }

  if (!u.username || !u.password || !u.pathname || u.pathname === "/") throw new Error("PR08_SQL_DATABASE_URL_CREDENTIALS_OR_DATABASE_MISSING");

  const variables = fixture.variables;
  function requiredVar(name) {
    if (!Object.prototype.hasOwnProperty.call(variables,name)) throw new Error("PR08_SQL_VARIABLE_REQUIRED:"+name);
    const value=variables[name];
    if (value===null || value===undefined || String(value)==="") throw new Error("PR08_SQL_VARIABLE_EMPTY:"+name);
    return value;
  }
  function asText(value) { return typeof value === "string" ? value : JSON.stringify(value); }
  function expectedCount(name,value,positive=false) {
    if (!Number.isInteger(value) || value < 0) throw new Error("PR08_SQL_EXPECTED_COUNT_INVALID:"+name);
    if (positive && value <= 0) throw new Error("PR08_SQL_EXPECTED_VALIDOS_MUST_BE_POSITIVE");
    return String(value);
  }

  const actorClaims = asText(requiredVar("ACTOR_JWT_CLAIMS"));
  const listaId = String(requiredVar("LISTA_ID"));
  const leadsJson = asText(requiredVar("LEADS_JSON"));
  const sessionId = String(requiredVar("SESSION_ID"));
  const probePhone = String(requiredVar("PROBE_PHONE"));
  const expectedValidos = expectedCount("expected_validos",fixture.expected_validos,true);
  const expectedInvalidos = expectedCount("expected_invalidos",fixture.expected_invalidos);
  const expectedDuplicados = expectedCount("expected_duplicados",fixture.expected_duplicados);

  // PR08_SQL_STRIP_INHERITED_LIBPQ_ENV
  // Keep non-libpq process environment (e.g. PATH) but discard every inherited
  // PG* variable before constructing the validated connection environment.
  const inheritedEnv = Object.fromEntries(
    Object.entries(process.env).filter(([key])=>!key.startsWith("PG"))
  );
  const pgEnv = {
    ...inheritedEnv,
    PGHOST:u.hostname,
    PGPORT:u.port || "5432",
    PGDATABASE:decodeURIComponent(u.pathname.replace(/^\//,"")),
    PGUSER:decodeURIComponent(u.username),
    PGPASSWORD:decodeURIComponent(u.password),
    PGSSLMODE:u.searchParams.get("sslmode") || "require"
  };

  const psql = process.env.FECHAI_PR08_PSQL_BIN || "psql";
  const sqlFile = path.join(root,"supabase/tests/f1-02-pr08/runtime_security_matrix.sql");
  const args = [
    "-X","-v","ON_ERROR_STOP=1",
    "-v","PR08_SQL_CASE="+caseId,
    "-v","PR08_SQL_RUNTIME_AUTHORIZED=YES",
    "-v","PR08_TARGET_PROJECT_REF="+declaredProjectRef,
    "-v","PR08_ACTOR_JWT_CLAIMS="+actorClaims,
    "-v","PR08_LISTA_ID="+listaId,
    "-v","PR08_LEADS_JSON="+leadsJson,
    "-v","PR08_SESSION_ID="+sessionId,
    "-v","PR08_PROBE_PHONE="+probePhone,
    "-v","PR08_EXPECTED_VALIDOS="+expectedValidos,
    "-v","PR08_EXPECTED_INVALIDOS="+expectedInvalidos,
    "-v","PR08_EXPECTED_DUPLICADOS="+expectedDuplicados
  ];
  if (isProduction) args.push("-v","PR08_PRODUCTION_EXECUTION_AUTHORIZED=YES");
  args.push("-f",sqlFile);

  // PR08_SQL_SAME_VALIDATED_CONNECTION
  const result = spawnSync(psql,args,{encoding:"utf8",env:pgEnv,cwd:root,maxBuffer:16*1024*1024});
  if (result.status !== 0) throw new Error("PR08_SQL_RUNTIME_PSQL_FAILED");
  process.stdout.write(String(result.stdout||""));
}
main().catch(error=>{
  process.stderr.write(JSON.stringify({error:String(error?.message||error)})+"\n");
  process.exitCode=1;
});
