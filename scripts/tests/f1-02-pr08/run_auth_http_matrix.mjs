#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const crypto = await import("node:crypto");
  const { spawnSync } = await import("node:child_process");

  const PROD_REF = "uobxxgzshrmbtjfdolxd";
  const root = process.cwd();
  const matrix = JSON.parse(await fs.readFile(path.join(root,"supabase/tests/f1-02-pr08/matrix.json"),"utf8"));
  const fixturePath = process.env.FECHAI_PR08_HTTP_FIXTURE_FILE;

  if (process.env.FECHAI_PR08_EXECUTION_AUTHORIZED !== "YES") throw new Error("PR08_EXECUTION_NOT_AUTHORIZED");
  if (!fixturePath) throw new Error("PR08_HTTP_FIXTURE_FILE_REQUIRED");

  const fixture = JSON.parse(await fs.readFile(path.resolve(fixturePath),"utf8"));
  const allowedFixtureKeys = new Set(["target_project_ref","environment","fixture_version","variables"]);
  for (const key of Object.keys(fixture)) if (!allowedFixtureKeys.has(key)) throw new Error("PR08_FIXTURE_FIELD_FORBIDDEN:"+key);
  if (!fixture.target_project_ref || !fixture.environment || !fixture.fixture_version || !fixture.variables) throw new Error("PR08_FIXTURE_IDENTITY_REQUIRED");
  if (!/^[a-z0-9]{20}$/.test(fixture.target_project_ref)) throw new Error("PR08_PROJECT_REF_INVALID");

  if (fixture.target_project_ref === PROD_REF) {
    if (fixture.environment !== "production") throw new Error("PR08_PRODUCTION_ENVIRONMENT_LABEL_MISMATCH");
    if (process.env.FECHAI_PR08_ALLOW_PRODUCTION !== "YES" || process.env.FECHAI_PR08_PRODUCTION_EXECUTION_AUTHORIZED !== "YES") {
      throw new Error("PR08_PRODUCTION_EXECUTION_NOT_AUTHORIZED");
    }
  } else if (fixture.environment === "production") {
    throw new Error("PR08_NONPROD_PROJECT_CANNOT_DECLARE_PRODUCTION");
  }

  const args = process.argv.slice(2);
  if (!args.length) throw new Error("PR08_EXPLICIT_CASE_SELECTION_REQUIRED");
  const runAll = args.length === 1 && args[0] === "--all";
  if (args.includes("--all") && !runAll) throw new Error("PR08_ALL_FLAG_MUST_BE_EXCLUSIVE");
  const requestedIds = runAll ? null : new Set(args);
  const records = matrix.records.filter(r=>r.runner==="http_matrix" && (runAll || requestedIds.has(r.test_id)));
  if (!records.length) throw new Error("PR08_NO_HTTP_CASES_SELECTED");
  if (!runAll) {
    const found = new Set(records.map(r=>r.test_id));
    for (const id of requestedIds) if (!found.has(id)) throw new Error("PR08_UNKNOWN_OR_NON_HTTP_CASE:"+id);
  }

  const origin = new URL("https://" + fixture.target_project_ref + ".supabase.co");
  if (origin.hostname !== fixture.target_project_ref + ".supabase.co") throw new Error("PR08_ORIGIN_BINDING_FAILED");
  const variables = fixture.variables;

  function valueFromVar(name) {
    if (!(name in variables)) throw new Error("PR08_VARIABLE_REQUIRED:"+name);
    return variables[name];
  }
  function renderString(value, encode) {
    if (typeof value !== "string") return value;
    return value.replace(/\$\{([A-Z0-9_]+)\}/g, (_,name) => {
      const raw = String(valueFromVar(name));
      return encode ? encodeURIComponent(raw) : raw;
    });
  }
  function renderDeep(value) {
    if (Array.isArray(value)) return value.map(renderDeep);
    if (value && typeof value === "object") {
      if (value.$generator === "synthetic_leads") {
        const count = Number(value.count);
        const prefix = variables[value.phone_prefix_var];
        if (!Number.isInteger(count) || count < 1 || count > 1000 || !prefix) throw new Error("PR08_SYNTHETIC_GENERATOR_INVALID");
        return Array.from({length:count},(_,i)=>({
          nome:"PR08 Synthetic "+String(i+1),
          email:"pr08.synthetic."+String(i+1)+"@example.invalid",
          telefone_e164:String(prefix)+String(i+1).padStart(3,"0")
        }));
      }
      return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,renderDeep(v)]));
    }
    return renderString(value,false);
  }
  function bindPath(template) {
    if (typeof template !== "string" || !template.startsWith("/") || template.startsWith("//") || /^[a-z]+:/i.test(template)) {
      throw new Error("PR08_ABSOLUTE_OR_INVALID_PATH_FORBIDDEN");
    }
    const rendered = renderString(template,true);
    const url = new URL(rendered,origin);
    if (url.origin !== origin.origin || url.hostname !== origin.hostname) throw new Error("PR08_TARGET_ORIGIN_MISMATCH");
    return url;
  }

  const canonical = value => Array.isArray(value) ? value.map(canonical) :
    value && typeof value === "object" ? Object.fromEntries(Object.keys(value).sort().map(k=>[k,canonical(value[k])])) : value;
  const stable = value => JSON.stringify(canonical(value));
  const sha256 = value => crypto.createHash("sha256").update(stable(value)).digest("hex");
  const redact = value => String(typeof value === "string" ? value : JSON.stringify(value))
    .replace(/Bearer\s+[A-Za-z0-9._-]+/gi,"Bearer [REDACTED]")
    .replace(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g,"[JWT_REDACTED]")
    .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/gi,"[UUID_REDACTED]")
    .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi,"[EMAIL_REDACTED]")
    .replace(/\+?\d[\d\s().-]{7,}\d/g,"[PHONE_REDACTED]");
  const slug = value => String(value||"").normalize("NFKD").replace(/[^A-Za-z0-9]+/g,"_").replace(/^_+|_+$/g,"").slice(0,80).toUpperCase();

  async function doSpec(spec) {
    if (!spec?.method || !spec?.path_template) throw new Error("PR08_VERSIONED_REQUEST_SPEC_REQUIRED");
    const method = String(spec.method).toUpperCase();
    if (!["GET","POST","PATCH","DELETE","HEAD"].includes(method)) throw new Error("PR08_METHOD_FORBIDDEN:"+method);
    const url = bindPath(spec.path_template);
    const anonKey = variables.SUPABASE_ANON_KEY;
    if (!anonKey) throw new Error("PR08_SUPABASE_ANON_KEY_REQUIRED");
    const headers = {apikey:String(anonKey)};
    if (spec.auth_token_var) {
      headers.Authorization = "Bearer "+String(valueFromVar(spec.auth_token_var));
    }
    for (const [k,v] of Object.entries(spec.headers_template||{})) headers[k] = renderString(v,false);
    const body = spec.body_template === null || spec.body_template === undefined ? undefined : JSON.stringify(renderDeep(spec.body_template));
    const startMs = Date.now();
    const startedAt = new Date(startMs).toISOString();
    const response = await fetch(url,{method,headers,body});
    const finishMs = Date.now();
    const finishedAt = new Date(finishMs).toISOString();
    const raw = await response.text();
    let parsed; try { parsed = JSON.parse(raw); } catch { parsed = raw; }
    return {status:response.status,body:parsed,start_ms:startMs,finish_ms:finishMs,started_at:startedAt,finished_at:finishedAt,duration_ms:finishMs-startMs};
  }

  function errorEvidence(response) {
    const body=response.body;
    const code=body && typeof body==="object" && !Array.isArray(body) && typeof body.code==="string" ? body.code : null;
    const message=body && typeof body==="object" && !Array.isArray(body)
      ? (typeof body.error==="string" ? body.error : (typeof body.message==="string" ? body.message : ""))
      : (typeof body==="string" ? body : "");
    const sanitizedMessage=redact(message);
    return {
      code:code?redact(code):null,
      message:sanitizedMessage,
      normalized_code:code?redact(code):"HTTP_"+response.status+"_"+slug(sanitizedMessage||"NO_BODY")
    };
  }
  function responsePass(assertion,response) {
    if (assertion.mode === "EMPTY_ARRAY_DENIAL") {
      return assertion.allowed_statuses.includes(response.status) && Array.isArray(response.body) && response.body.length===0;
    }
    if (assertion.mode === "DENIAL_SEMANTIC") {
      if (!assertion.expected_statuses.includes(response.status)) return false;
      const ev=errorEvidence(response);
      if (assertion.expected_error_codes?.length && !assertion.expected_error_codes.includes(ev.code)) return false;
      if (assertion.expected_error_exact && ev.message!==assertion.expected_error_exact) return false;
      if (assertion.expected_error_regex && !(new RegExp(assertion.expected_error_regex,"i")).test((ev.code||"")+" "+ev.message)) return false;
      return true;
    }
    if (assertion.mode === "ALLOW_SEMANTIC") {
      if (Math.floor(response.status/100)!==assertion.allowed_status_class) return false;
      if (assertion.reject_json_error && response.body && typeof response.body==="object" && !Array.isArray(response.body) && response.body.error) return false;
      return true;
    }
    throw new Error("PR08_RESPONSE_ASSERTION_UNKNOWN");
  }

  function asSet(value) {
    if (Array.isArray(value)) return new Set(value.map(String));
    if (typeof value === "string") {
      try { const p=JSON.parse(value); if(Array.isArray(p)) return new Set(p.map(String)); } catch {}
      return new Set(value.split(",").map(x=>x.trim()).filter(Boolean));
    }
    throw new Error("PR08_VAR_SET_REQUIRED");
  }
  function anyTrue(row,clauses) {
    return clauses.some(c=>{
      if (Object.prototype.hasOwnProperty.call(c,"equals")) return row?.[c.field]===c.equals;
      if (Array.isArray(c.in)) return c.in.includes(row?.[c.field]);
      return row?.[c.field]===true;
    });
  }
  function fixtureBool(name) {
    const v=valueFromVar(name);
    if(typeof v==="boolean") return v;
    const s=String(v).trim().toLowerCase();
    if(["true","1","yes","y"].includes(s)) return true;
    if(["false","0","no","n"].includes(s)) return false;
    throw new Error("PR08_BOOLEAN_VARIABLE_REQUIRED:"+name);
  }
  function topologyAssertionPass(assertion,body) {
    if (assertion.mode==="VARIABLE_NOT_EQUAL") return String(valueFromVar(assertion.left))!==String(valueFromVar(assertion.right));
    if (assertion.mode==="FIXTURE_BOOLEAN_TRUE") return fixtureBool(assertion.var)===true;
    if (assertion.mode==="OBJECT_FIELD_EQUALS_VAR") return body && typeof body==="object" && !Array.isArray(body) && String(body[assertion.field])===String(valueFromVar(assertion.var));
    if (assertion.mode==="ZERO_ROWS") return Array.isArray(body) && body.length===0;
    if (assertion.mode==="ROW_IDS_EQUAL_VAR_SET") {
      if(!Array.isArray(body)) return false;
      const actual=new Set(body.map(x=>String(x.id))),expected=asSet(valueFromVar(assertion.var));
      return actual.size===expected.size && [...actual].every(x=>expected.has(x));
    }
    if (assertion.mode==="EXACTLY_ONE_ROW") {
      if(!Array.isArray(body)||body.length!==1) return false;
      const row=body[0];
      for(const [f,vn] of Object.entries(assertion.field_equals_vars||{})) if(String(row[f])!==String(valueFromVar(vn))) return false;
      for(const [f,vn] of Object.entries(assertion.field_not_equals_vars||{})) if(String(row[f])===String(valueFromVar(vn))) return false;
      for(const [f,lit] of Object.entries(assertion.field_equals_literals||{})) if(row[f]!==lit) return false;
      for(const f of assertion.field_not_null||[]) if(row[f]===null||row[f]===undefined) return false;
      for(const f of assertion.field_null||[]) if(row[f]!==null) return false;
      if(assertion.any_true?.length && !anyTrue(row,assertion.any_true)) return false;
      return true;
    }
    throw new Error("PR08_TOPOLOGY_ASSERTION_UNKNOWN:"+assertion.mode);
  }
  async function runTopologyPreflight(record) {
    const checksById=new Map((matrix.topology_contract?.checks||[]).map(x=>[x.check_id,x]));
    const ids=[...new Set([...(matrix.topology_contract?.global_check_ids||[]),...(record.topology_dependencies||[])])];
    const passed=[];
    for(const id of ids) {
      const check=checksById.get(id);
      if(!check) throw new Error("PR08_TOPOLOGY_CHECK_UNKNOWN:"+record.test_id+":"+id);

      if(check.assertion?.mode==="SERVER_ROOT_AUTHORITY") {
        ensureServerContext();
        const n=Number(serverExec(
          "SELECT count(*)::text FROM public.admins WHERE user_id="+sqlUuidVar(check.assertion.user_var)+" AND ativo IS TRUE AND role='admin_global';",
          "PR08_TOPOLOGY_ROOT_AUTHORITY"
        ));
        if(n!==1) throw new Error("PR08_TOPOLOGY_ASSERTION_FAILED:"+id);
      } else if(["VARIABLE_NOT_EQUAL","FIXTURE_BOOLEAN_TRUE"].includes(check.assertion?.mode)) {
        if(!topologyAssertionPass(check.assertion,null)) throw new Error("PR08_TOPOLOGY_ASSERTION_FAILED:"+id);
      } else {
        const response=await doSpec(check.request);
        if(Math.floor(response.status/100)!==2) throw new Error("PR08_TOPOLOGY_HTTP_FAILED:"+id+":"+response.status);
        if(!topologyAssertionPass(check.assertion,response.body)) throw new Error("PR08_TOPOLOGY_ASSERTION_FAILED:"+id);
      }
      passed.push(id);
    }
    return passed;
  }

  async function httpProbeState(specs) {
    const observations=[];
    for(const spec of specs||[]) {
      const r=await doSpec(spec);
      if(Math.floor(r.status/100)!==2) throw new Error("PR08_MUTATION_PROBE_FAILED_HTTP:"+r.status);
      observations.push({status:r.status,body:r.body});
    }
    return observations;
  }

  // -------------------------------------------------------------------------
  // Owner-side non-production evidence/lifecycle channel.
  // This does not alter grants, RLS or policies and hard-denies production.
  // -------------------------------------------------------------------------
  let serverCtx=null;
  let serverBoundaryPreflightDone=false;

  function sqlLiteral(value) {
    if (value===null || value===undefined) return "NULL";
    return "'" + String(value).replace(/'/g,"''") + "'";
  }
  function sqlUuidVar(name) { return sqlLiteral(valueFromVar(name))+"::uuid"; }
  function sqlTextVar(name) { return sqlLiteral(valueFromVar(name)); }
  function sqlJson(value) { return sqlLiteral(JSON.stringify(value))+"::jsonb"; }
  function sqlTyped(value,type) {
    if(value===null||value===undefined) return "NULL";
    return sqlLiteral(value)+"::"+type;
  }

  function ensureServerContext() {
    if(serverCtx) return serverCtx;
    if(fixture.target_project_ref===PROD_REF) throw new Error("PR08_SERVER_EVIDENCE_HARD_DENY_PRODUCTION_PROJECT_REF");
    if(fixture.environment==="production") throw new Error("PR08_SERVER_EVIDENCE_HARD_DENY_PRODUCTION_ENVIRONMENT");
    if(process.env.FECHAI_PR08_SERVER_EVIDENCE_AUTHORIZED!=="YES") throw new Error("PR08_SERVER_EVIDENCE_NOT_AUTHORIZED");
    if(process.env.FECHAI_PR08_ISOLATED_ENVIRONMENT!=="YES") throw new Error("PR08_SERVER_EVIDENCE_ISOLATED_ENVIRONMENT_REQUIRED");

    const raw=process.env.FECHAI_PR08_DATABASE_URL;
    if(!raw) throw new Error("PR08_DATABASE_URL_REQUIRED");
    const u=new URL(raw);
    const expectedHost="db."+fixture.target_project_ref+".supabase.co";
    if(u.hostname!==expectedHost) throw new Error("PR08_SERVER_DATABASE_HOST_PROJECT_BINDING_MISMATCH");
    if(u.hostname.includes(PROD_REF)) throw new Error("PR08_SERVER_EVIDENCE_HARD_DENY_PRODUCTION_DATABASE_HOST");

    const pgEnv={
      ...process.env,
      PGHOST:u.hostname,
      PGPORT:u.port||"5432",
      PGDATABASE:u.pathname.replace(/^\//,""),
      PGUSER:decodeURIComponent(u.username),
      PGPASSWORD:decodeURIComponent(u.password),
      PGSSLMODE:u.searchParams.get("sslmode")||"require"
    };
    serverCtx={
      psql:process.env.FECHAI_PR08_PSQL_BIN||"psql",
      pgDump:process.env.FECHAI_PR08_PG_DUMP_BIN||"pg_dump",
      pgEnv
    };
    return serverCtx;
  }

  function psqlRun(args,input,label) {
    const ctx=ensureServerContext();
    const r=spawnSync(ctx.psql,args,{input,encoding:"utf8",env:ctx.pgEnv,cwd:root,maxBuffer:64*1024*1024});
    if(r.status!==0) throw new Error(label+"_FAILED:"+redact(String(r.stderr||"")).slice(0,1000));
    return String(r.stdout||"").trim();
  }
  function serverBoundaryPreflight() {
    if(serverBoundaryPreflightDone) return;
    const sqlFile=path.join(root,"supabase/tests/f1-02-pr08/runtime_security_matrix.sql");
    psqlRun([
      "-X","-q","-v","ON_ERROR_STOP=1",
      "-v","PR08_SQL_CASE=SERVER-EVIDENCE-PREFLIGHT",
      "-v","PR08_TARGET_PROJECT_REF="+fixture.target_project_ref,
      "-f",sqlFile
    ],undefined,"PR08_SERVER_EVIDENCE_PREFLIGHT");
    serverBoundaryPreflightDone=true;
  }
  function serverExec(sql,label) {
    serverBoundaryPreflight();
    return psqlRun(["-X","-Atq","-v","ON_ERROR_STOP=1","-c",sql],undefined,label);
  }
  function serverJson(sql,label) {
    const out=serverExec(sql,label).split("\n").map(x=>x.trim()).filter(Boolean);
    if(!out.length) throw new Error(label+"_EMPTY_JSON");
    try { return JSON.parse(out[out.length-1]); } catch { throw new Error(label+"_INVALID_JSON"); }
  }
  function queryArray(selectSql,label) {
    return serverJson("SELECT COALESCE(pg_catalog.jsonb_agg(to_jsonb(q) ORDER BY q.__ord), '[]'::jsonb) FROM ("+selectSql+") q;",label);
  }
  function oneObject(selectSql,label) {
    return serverJson("SELECT COALESCE((SELECT to_jsonb(q) FROM ("+selectSql+") q LIMIT 1),'null'::jsonb);",label);
  }

  const tableColumnCache=new Map();

  function qident(name) {
    return '"'+String(name).replace(/"/g,'""')+'"';
  }
  function tableColumns(table) {
    if(tableColumnCache.has(table)) return tableColumnCache.get(table);
    const cols=serverJson(
      "SELECT COALESCE(pg_catalog.jsonb_agg(a.attname ORDER BY a.attnum),'[]'::jsonb) "+
      "FROM pg_catalog.pg_attribute a "+
      "WHERE a.attrelid="+sqlLiteral(table)+"::pg_catalog.regclass "+
      "AND a.attnum>0 AND NOT a.attisdropped AND a.attgenerated='';",
      "PR08_TABLE_COLUMNS"
    );
    if(!Array.isArray(cols)||!cols.length) throw new Error("PR08_TABLE_COLUMNS_EMPTY:"+table);
    tableColumnCache.set(table,cols);
    return cols;
  }
  function fullRow(table,where,label) {
    return oneObject("SELECT t.* FROM "+table+" t WHERE "+where,label);
  }
  function fullSet(table,where,orderExpr,label) {
    const rows=queryArray(
      "SELECT t.*, ("+orderExpr+")::text AS __ord FROM "+table+" t WHERE "+where+" ORDER BY "+orderExpr,
      label
    );
    for(const row of rows) delete row.__ord;
    return rows;
  }
  function insertRows(table,rows,label) {
    if(!rows?.length) return;
    const cols=tableColumns(table);
    const list=cols.map(qident).join(",");
    serverExec(
      "INSERT INTO "+table+" ("+list+") "+
      "SELECT "+list+" FROM pg_catalog.jsonb_populate_recordset(NULL::"+table+","+sqlJson(rows)+") r;",
      label
    );
  }
  function restoreFullRow(table,row,pkFields,label) {
    if(!row) return;
    const cols=tableColumns(table);
    const list=cols.map(qident).join(",");
    const conflict=pkFields.map(qident).join(",");
    const updates=cols.filter(c=>!pkFields.includes(c)).map(c=>qident(c)+"=EXCLUDED."+qident(c)).join(",");
    serverExec(
      "INSERT INTO "+table+" ("+list+") "+
      "SELECT "+list+" FROM pg_catalog.jsonb_populate_record(NULL::"+table+","+sqlJson(row)+") r "+
      "ON CONFLICT ("+conflict+") DO UPDATE SET "+updates+";",
      label
    );
  }
  function restoreReplaceSet(table,where,rows,label) {
    serverExec("DELETE FROM "+table+" WHERE "+where+";",label+"_DELETE");
    insertRows(table,rows,label+"_INSERT");
  }
  function restoreScopedSetById(table,where,rows,label) {
    const ids=(rows||[]).map(x=>sqlLiteral(x.id)+"::uuid");
    serverExec(
      "DELETE FROM "+table+" WHERE "+where+(ids.length?" AND id NOT IN ("+ids.join(",")+")":"")+";",
      label+"_DELETE_EXTRAS"
    );
    for(const row of rows||[]) restoreFullRow(table,row,["id"],label+"_UPSERT");
  }
  function restoreWholeTableById(table,rows,label) {
    const ids=(rows||[]).map(x=>sqlLiteral(x.id)+"::uuid");
    serverExec(
      "DELETE FROM "+table+(ids.length?" WHERE id NOT IN ("+ids.join(",")+")":"")+";",
      label+"_DELETE_EXTRAS"
    );
    for(const row of rows||[]) restoreFullRow(table,row,["id"],label+"_UPSERT");
  }
  function allAuditRows() {
    return fullSet("public.audit_logs","true","id::text","PR08_AUDIT_ALL_STATE");
  }
  function publicDataHash(label) {
    serverBoundaryPreflight();
    const ctx=ensureServerContext();
    const r=spawnSync(ctx.pgDump,[
      "--data-only","--schema=public","--no-comments","--no-owner","--no-privileges",
      "--format=plain","--restrict-key=FECHAIPR08CASESTATE"
    ],{encoding:"utf8",env:ctx.pgEnv,cwd:root,maxBuffer:128*1024*1024});
    if(r.status!==0) throw new Error(label+"_PG_DUMP_FAILED:"+redact(String(r.stderr||"")).slice(0,1000));
    return crypto.createHash("sha256").update(String(r.stdout||"")).digest("hex");
  }
  function sequenceState() {
    const names=serverJson(
      "SELECT COALESCE(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object('schema',n.nspname,'name',c.relname) ORDER BY n.nspname,c.relname),'[]'::jsonb) "+
      "FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace "+
      "WHERE c.relkind='S' AND n.nspname='public';",
      "PR08_SEQUENCE_NAMES"
    );
    return (names||[]).map((x,i)=>{
      const qualified=qident(x.schema)+"."+qident(x.name);
      const state=oneObject("SELECT last_value,is_called FROM "+qualified,"PR08_SEQUENCE_STATE_"+i);
      return {...x,last_value:state?.last_value,is_called:state?.is_called};
    });
  }
  function restoreSequences(state) {
    for(const s of state||[]) {
      if(s.last_value===null||s.last_value===undefined) continue;
      serverExec(
        "SELECT pg_catalog.setval(pg_catalog.format('%I.%I',"+sqlLiteral(s.schema)+","+sqlLiteral(s.name)+")::pg_catalog.regclass,"+
        String(s.last_value)+","+(s.is_called?"true":"false")+");",
        "PR08_SEQUENCE_RESTORE"
      );
    }
  }

  function importScopeState(scope,index) {
    const company=sqlUuidVar(scope.company_var);
    const session=sqlTextVar(scope.session_var);
    const listIds=scope.list_vars.map(n=>sqlUuidVar(n)).join(",");
    const lists=fullSet(
      "public.listas",
      "id IN ("+listIds+")",
      "id::text",
      "PR08_SERVER_IMPORT_LISTS_"+index
    );

    let leadWhere="empresa_id="+company+" AND false";
    if(scope.phone_vars?.length) {
      const phones=scope.phone_vars.map(n=>sqlLiteral(valueFromVar(n))).join(",");
      leadWhere="empresa_id="+company+" AND telefone_e164 IN ("+phones+")";
    } else if(scope.phone_prefix_var) {
      leadWhere="empresa_id="+company+" AND telefone_e164 LIKE "+sqlLiteral(String(valueFromVar(scope.phone_prefix_var))+"%");
    }
    const leads=fullSet("public.leads",leadWhere,"id::text","PR08_SERVER_IMPORT_LEADS_"+index);
    const markers=fullSet(
      "public.importar_leads_batch_idempotency",
      "empresa_id="+company+" AND sessao_id="+session,
      "(empresa_id::text||':'||sessao_id)",
      "PR08_SERVER_IMPORT_MARKERS_"+index
    );
    const logs=fullSet(
      "public.logs",
      "empresa_id="+company+" AND detalhes->>'sessao_id'="+session,
      "id::text",
      "PR08_SERVER_IMPORT_LOGS_"+index
    );
    return {lists,leads,markers,logs};
  }

  function leadState(leadVar,label) {
    const leadId=sqlUuidVar(leadVar);
    const lead=fullRow("public.leads","id="+leadId,label+"_LEAD");
    const movements=fullSet("public.funil_movimentacoes","lead_id="+leadId,"id::text",label+"_MOVEMENTS");
    return {lead,movements};
  }

  function serverState(plan) {
    serverBoundaryPreflight();

    if(plan.kind==="BROKER") {
      return {
        broker:fullRow("public.corretores","id="+sqlUuidVar(plan.broker_id_var),"PR08_BROKER_STATE"),
        audit_logs:plan.include_full_audit_logs?allAuditRows():[]
      };
    }
    if(plan.kind==="PASSWORD_T3") {
      const authority=sqlUuidVar(plan.authority_user_id_var),target=sqlUuidVar(plan.target_user_id_var);
      return {
        broker:fullRow("public.corretores","id="+sqlUuidVar(plan.broker_id_var),"PR08_T3_BROKER_STATE"),
        audit_logs:allAuditRows(),
        t3_proofs:fullSet(
          "public.t3_admin_password_reset_edge_proofs",
          "actor_user_id="+authority+" OR target_user_id="+target,
          "proof_id::text",
          "PR08_T3_PROOF_STATE"
        ),
        t3_leases:fullSet(
          "public.t3_admin_password_reset_leases",
          "actor_user_id IN ("+authority+","+target+") OR target_user_id IN ("+authority+","+target+")",
          "lease_id::text",
          "PR08_T3_LEASE_STATE"
        )
      };
    }
    if(plan.kind==="ACL") {
      const listId=sqlUuidVar(plan.list_id_var);
      return {
        list:fullRow("public.listas","id="+listId,"PR08_ACL_LIST_STATE"),
        acl_rows:fullSet("public.lista_visibilidade","lista_id="+listId,"(target_type||':'||target_id::text)","PR08_ACL_ROWS_STATE"),
        audit_logs:allAuditRows()
      };
    }
    if(plan.kind==="LEAD" || plan.kind==="FUNNEL") return leadState(plan.lead_id_var,"PR08_"+plan.kind+"_STATE");
    if(plan.kind==="FEEDBACK") {
      const base=leadState(plan.lead_id_var,"PR08_FEEDBACK_STATE");
      if(!base.lead?.lote_id) throw new Error("PR08_FEEDBACK_LEAD_LOTE_REQUIRED");
      const lot=fullRow("public.lotes","id="+sqlLiteral(base.lead.lote_id)+"::uuid","PR08_FEEDBACK_LOT_STATE");
      const otherCount=Number(serverExec(
        "SELECT count(*)::text FROM public.leads WHERE lote_id="+sqlLiteral(base.lead.lote_id)+"::uuid AND id<>"+sqlUuidVar(plan.lead_id_var)+" AND feedback IS NOT NULL AND feedback<>'' AND (tecnico_pendente=false OR tecnico_pendente IS NULL);",
        "PR08_SERVER_OTHER_FEEDBACK_COUNT"
      ));
      return {...base,lot,other_feedback_count:otherCount};
    }
    if(plan.kind==="LOT") {
      return {lot:fullRow("public.lotes","id="+sqlUuidVar(plan.lot_id_var),"PR08_LOT_STATE")};
    }
    if(plan.kind==="LEAD_NAMESPACE") {
      const phones=plan.phone_vars.map(n=>sqlLiteral(valueFromVar(n))).join(",");
      return {leads:fullSet("public.leads","lista_id="+sqlUuidVar(plan.list_id_var)+" AND telefone_e164 IN ("+phones+")","id::text","PR08_LEAD_NAMESPACE_STATE")};
    }
    if(plan.kind==="DISTRIBUTION") {
      return {
        lists:fullSet("public.listas","true","id::text","PR08_DISTRIBUTION_LISTS"),
        lots:fullSet("public.lotes","true","id::text","PR08_DISTRIBUTION_LOTS"),
        leads:fullSet("public.leads","true","id::text","PR08_DISTRIBUTION_LEADS"),
        broker:fullRow("public.corretores","id="+sqlUuidVar(plan.actor_corretor_id_var),"PR08_DISTRIBUTION_BROKER"),
        audit_logs:allAuditRows()
      };
    }
    if(plan.kind==="IMPORT") return {scopes:plan.scopes.map((s,i)=>importScopeState(s,i))};
    throw new Error("PR08_SERVER_PLAN_KIND_UNKNOWN:"+plan.kind);
  }

  function assertCleanImportOriginal(plan,original) {
    original.scopes.forEach((state,i)=>{
      const expectedLists=plan.scopes[i].list_vars.length;
      if(state.lists.length!==expectedLists) throw new Error("PR08_IMPORT_LIST_FIXTURE_MISSING:"+i);
      if(state.leads.length!==0 || state.markers.length!==0 || state.logs.length!==0) throw new Error("PR08_IMPORT_NAMESPACE_NOT_CLEAN:"+i);
    });
  }
  function syntheticLeads(phoneVars) {
    return phoneVars.map(n=>({nome:"PR08 Synthetic",email:"pr08.synthetic@example.invalid",telefone_e164:String(valueFromVar(n))}));
  }
  function seedCompletedImport(plan,scope) {
    if(!plan.claims_var) throw new Error("PR08_IMPORT_SEED_CLAIMS_VAR_REQUIRED");
    const listVar=scope.seed_list_var;
    const phones=scope.seed_phone_vars||scope.phone_vars;
    const leads=syntheticLeads(phones);
    const sql=
      "BEGIN;"+
      "SELECT pg_catalog.set_config('request.jwt.claims',"+sqlTextVar(plan.claims_var)+",true);"+
      "SELECT public.importar_leads_batch("+sqlUuidVar(listVar)+","+sqlJson(leads)+","+sqlTextVar(scope.session_var)+")::text;"+
      "COMMIT;";
    const lines=serverExec(sql,"PR08_IMPORT_SEED_COMPLETED").split("\n").map(x=>x.trim()).filter(Boolean);
    const jsonLine=[...lines].reverse().find(x=>x.startsWith("{"));
    if(!jsonLine) throw new Error("PR08_IMPORT_SEED_RESULT_MISSING");
    const result=JSON.parse(jsonLine);
    if(result.error) throw new Error("PR08_IMPORT_SEED_RESULT_ERROR:"+redact(result.error));
  }
  function seedIncompleteImport(scope) {
    const phones=scope.seed_phone_vars||scope.phone_vars;
    const leads=syntheticLeads(phones);
    const company=sqlUuidVar(scope.company_var);
    const listId=sqlUuidVar(scope.seed_list_var);
    const session=sqlTextVar(scope.session_var);
    const payload=sqlJson(leads);
    const sql=
      "INSERT INTO public.importar_leads_batch_idempotency(empresa_id,sessao_id,lista_id,request_fingerprint) "+
      "VALUES ("+company+","+session+","+listId+",pg_catalog.encode(extensions.digest(pg_catalog.jsonb_build_object("+
      "'contract','F1-02/PR-07/v1','empresa_id',("+company+")::text,'lista_id',("+listId+")::text,'sessao_id',"+session+",'leads',"+payload+
      ")::text,'sha256'),'hex'));";
    serverExec(sql,"PR08_IMPORT_SEED_INCOMPLETE");
  }

  function updateBrokerPrepare(plan) {
    const sets=[];
    if(Object.prototype.hasOwnProperty.call(plan.prepare_patch||{},"must_change_password")) sets.push("must_change_password="+(plan.prepare_patch.must_change_password?"true":"false"));
    if(Object.prototype.hasOwnProperty.call(plan.prepare_patch||{},"ativo")) sets.push("ativo="+(plan.prepare_patch.ativo?"true":"false"));
    if(plan.prepare_patch?.time_id_var) sets.push("time_id="+sqlUuidVar(plan.prepare_patch.time_id_var));
    if(!sets.length) return;
    const n=Number(serverExec(
      "WITH u AS (UPDATE public.corretores SET "+sets.join(",")+" WHERE id="+sqlUuidVar(plan.broker_id_var)+" RETURNING 1) SELECT count(*)::text FROM u;",
      "PR08_BROKER_PREPARE"
    ));
    if(n!==1) throw new Error("PR08_BROKER_PREPARE_TARGET_COUNT");
  }

  function t3PreparePasswordState(plan,original) {
    if(!original.broker) throw new Error("PR08_T3_BROKER_REQUIRED");
    if(original.broker.must_change_password!==plan.require_original_must_change_password) throw new Error("PR08_T3_ORIGINAL_PASSWORD_STATE_INVALID");
    if(original.t3_proofs.length||original.t3_leases.length) throw new Error("PR08_T3_ORIGINAL_PROOF_LEASE_STATE_NOT_CLEAN");

    const proof=serverExec(
      "SELECT public.t3_issue_admin_password_reset_edge_proof("+sqlUuidVar(plan.authority_user_id_var)+","+sqlUuidVar(plan.target_user_id_var)+")::text;",
      "PR08_T3_ISSUE_PROOF"
    ).split("\n").map(x=>x.trim()).filter(Boolean).pop();
    if(!proof) throw new Error("PR08_T3_PROOF_MISSING");

    const prepareSql=
      "BEGIN;"+
      "SELECT pg_catalog.set_config('request.jwt.claims',"+sqlTextVar(plan.authority_claims_var)+",true);"+
      "SELECT public.t3_prepare_admin_password_reset("+sqlUuidVar(plan.target_user_id_var)+","+sqlLiteral(proof)+"::uuid)::text;"+
      "COMMIT;";
    const lines=serverExec(prepareSql,"PR08_T3_PREPARE").split("\n").map(x=>x.trim()).filter(Boolean);
    const jsonLine=[...lines].reverse().find(x=>x.startsWith("{"));
    if(!jsonLine) throw new Error("PR08_T3_PREPARE_RESULT_MISSING");
    const result=JSON.parse(jsonLine);
    if(result.ok!==true||!result.lease_id) throw new Error("PR08_T3_PREPARE_RESULT_INVALID");
    plan.__runtime_lease_id=String(result.lease_id);

    const released=serverExec(
      "SELECT public.t3_release_admin_password_reset_lease("+sqlLiteral(plan.__runtime_lease_id)+"::uuid,"+
      sqlUuidVar(plan.authority_user_id_var)+","+sqlUuidVar(plan.target_user_id_var)+")::text;",
      "PR08_T3_RELEASE_PRETEST"
    ).split("\n").map(x=>x.trim()).filter(Boolean).pop();
    if(released!=="t"&&released!=="true") throw new Error("PR08_T3_RELEASE_PRETEST_FAILED");

    const prepared=fullRow("public.corretores","id="+sqlUuidVar(plan.broker_id_var),"PR08_T3_PREPARED_BROKER");
    if(prepared?.must_change_password!==true) throw new Error("PR08_T3_PASSWORD_STATE_NOT_PREPARED");
  }

  function prepareServerCase(plan,original) {
    if(plan.kind==="BROKER") {
      if(!original.broker) throw new Error("PR08_BROKER_ORIGINAL_REQUIRED");
      if(plan.password_state_guard && original.broker.must_change_password!==false) throw new Error("PR08_PASSWORD_GUARD_REQUIRES_FALSE_ORIGINAL");
      updateBrokerPrepare(plan);
      return;
    }
    if(plan.kind==="PASSWORD_T3") return t3PreparePasswordState(plan,original);
    if(plan.kind==="ACL") {
      if(plan.prepare_target_absent) {
        serverExec(
          "DELETE FROM public.lista_visibilidade WHERE lista_id="+sqlUuidVar(plan.list_id_var)+" AND target_type="+sqlLiteral(plan.request_target_type)+" AND target_id="+sqlUuidVar(plan.request_target_id_var)+";",
          "PR08_ACL_PREPARE_TARGET_ABSENT"
        );
      }
      return;
    }
    if(plan.kind==="FUNNEL") {
      if(plan.prepare_stage_var) {
        if(!original.lead) throw new Error("PR08_FUNNEL_LEAD_REQUIRED");
        const n=Number(serverExec(
          "WITH u AS (UPDATE public.leads l SET funil_estagio_id="+sqlUuidVar(plan.prepare_stage_var)+",funil_atualizado_em=pg_catalog.now(),updated_at=pg_catalog.now() "+
          "WHERE l.id="+sqlUuidVar(plan.lead_id_var)+" AND EXISTS (SELECT 1 FROM public.funil_estagios fe WHERE fe.id="+sqlUuidVar(plan.prepare_stage_var)+" AND fe.empresa_id=l.empresa_id) RETURNING 1) SELECT count(*)::text FROM u;",
          "PR08_FUNNEL_PREPARE"
        ));
        if(n!==1) throw new Error("PR08_FUNNEL_PREPARE_FAILED");
      }
      return;
    }
    if(plan.kind==="FEEDBACK") {
      if(plan.prepare_feedback_baseline) {
        if(!original.lead||!original.lot) throw new Error("PR08_FEEDBACK_FIXTURE_REQUIRED");
        if(original.other_feedback_count>plan.max_other_feedback) throw new Error("PR08_FEEDBACK_LOT_TOO_CLOSE_TO_AUTO_CLOSE");
        const n=Number(serverExec(
          "WITH u AS (UPDATE public.leads l SET "+
          "feedback=NULL,observacao_corretor=NULL,data_feedback=NULL,atendimento_finalizado_em=NULL,tempo_tratativa_segundos=NULL,"+
          "tentativas_caiu=0,tecnico_pendente=false,ultima_falha_tecnica=NULL,ultima_falha_em=NULL,acao_sugerida=NULL,feedback_tipo=NULL,"+
          "status_operacional='em_trabalho'::public.lead_status_operacional,status_comercial='sem_status'::public.lead_status_comercial,"+
          "funil_estagio_id="+sqlUuidVar(plan.baseline_stage_var)+",funil_atualizado_em=pg_catalog.now(),updated_at=pg_catalog.now() "+
          "WHERE l.id="+sqlUuidVar(plan.lead_id_var)+" AND EXISTS (SELECT 1 FROM public.funil_estagios fe WHERE fe.id="+sqlUuidVar(plan.baseline_stage_var)+" AND fe.empresa_id=l.empresa_id) RETURNING 1) SELECT count(*)::text FROM u;",
          "PR08_FEEDBACK_PREPARE"
        ));
        if(n!==1) throw new Error("PR08_FEEDBACK_PREPARE_FAILED");
      }
      return;
    }
    if(plan.kind==="IMPORT") {
      assertCleanImportOriginal(plan,original);
      for(const scope of plan.scopes) {
        if(scope.seed_mode==="COMPLETED") seedCompletedImport(plan,scope);
        else if(scope.seed_mode==="INCOMPLETE") seedIncompleteImport(scope);
        else if(scope.seed_mode!=="NONE") throw new Error("PR08_IMPORT_SEED_MODE_UNKNOWN");
      }
      return;
    }
    if(plan.kind==="LEAD_NAMESPACE") {
      if(plan.require_clean&&original.leads.length!==0) throw new Error("PR08_LEAD_NAMESPACE_NOT_CLEAN");
      return;
    }
    if(["LEAD","LOT","DISTRIBUTION"].includes(plan.kind)) return;
    throw new Error("PR08_SERVER_PREPARE_KIND_UNKNOWN:"+plan.kind);
  }

  function cleanupPasswordT3(plan,original) {
    const current=fullRow("public.corretores","id="+sqlUuidVar(plan.broker_id_var),"PR08_T3_CLEANUP_CURRENT");
    if(current?.must_change_password===true) {
      const sql=
        "BEGIN;"+
        "SELECT pg_catalog.set_config('request.jwt.claims',"+sqlTextVar(plan.target_claims_var)+",true);"+
        "SELECT public.marcar_senha_inicial_definida()::text;"+
        "COMMIT;";
      serverExec(sql,"PR08_T3_SELF_SERVICE_CLEANUP");
    }

    if(plan.__runtime_lease_id) {
      const n=Number(serverExec(
        "SELECT count(*)::text FROM public.t3_admin_password_reset_leases WHERE lease_id="+sqlLiteral(plan.__runtime_lease_id)+"::uuid;",
        "PR08_T3_LEFTOVER_LEASE_COUNT"
      ));
      if(n===1) {
        serverExec(
          "SELECT public.t3_release_admin_password_reset_lease("+sqlLiteral(plan.__runtime_lease_id)+"::uuid,"+
          sqlUuidVar(plan.authority_user_id_var)+","+sqlUuidVar(plan.target_user_id_var)+")::text;",
          "PR08_T3_LEFTOVER_LEASE_RELEASE"
        );
      }
    }

    const authority=sqlUuidVar(plan.authority_user_id_var),target=sqlUuidVar(plan.target_user_id_var);
    restoreReplaceSet(
      "public.t3_admin_password_reset_edge_proofs",
      "actor_user_id="+authority+" OR target_user_id="+target,
      original.t3_proofs,
      "PR08_T3_PROOFS_RESTORE"
    );
    restoreReplaceSet(
      "public.t3_admin_password_reset_leases",
      "actor_user_id IN ("+authority+","+target+") OR target_user_id IN ("+authority+","+target+")",
      original.t3_leases,
      "PR08_T3_LEASES_RESTORE"
    );
    restoreFullRow("public.corretores",original.broker,["id"],"PR08_T3_BROKER_RESTORE");
    restoreWholeTableById("public.audit_logs",original.audit_logs,"PR08_T3_AUDIT_RESTORE");
  }

  function cleanupImport(plan,original) {
    plan.scopes.forEach((scope,i)=>{
      const company=sqlUuidVar(scope.company_var),session=sqlTextVar(scope.session_var);
      serverExec("DELETE FROM public.logs WHERE empresa_id="+company+" AND detalhes->>'sessao_id'="+session+";","PR08_IMPORT_LOG_CLEANUP_"+i);
      serverExec("DELETE FROM public.importar_leads_batch_idempotency WHERE empresa_id="+company+" AND sessao_id="+session+";","PR08_IMPORT_MARKER_CLEANUP_"+i);
      if(scope.phone_vars?.length) {
        const phones=scope.phone_vars.map(n=>sqlLiteral(valueFromVar(n))).join(",");
        serverExec("DELETE FROM public.leads WHERE empresa_id="+company+" AND telefone_e164 IN ("+phones+");","PR08_IMPORT_LEAD_CLEANUP_"+i);
      } else if(scope.phone_prefix_var) {
        serverExec("DELETE FROM public.leads WHERE empresa_id="+company+" AND telefone_e164 LIKE "+sqlLiteral(String(valueFromVar(scope.phone_prefix_var))+"%")+";","PR08_IMPORT_LEAD_PREFIX_CLEANUP_"+i);
      }
      for(const list of original.scopes[i].lists) restoreFullRow("public.listas",list,["id"],"PR08_IMPORT_LIST_RESTORE_"+i);
    });
  }

  function cleanupServerCase(plan,original) {
    if(plan.kind==="BROKER") {
      restoreFullRow("public.corretores",original.broker,["id"],"PR08_BROKER_RESTORE");
      if(plan.include_full_audit_logs) restoreWholeTableById("public.audit_logs",original.audit_logs,"PR08_BROKER_AUDIT_RESTORE");
      return;
    }
    if(plan.kind==="PASSWORD_T3") return cleanupPasswordT3(plan,original);
    if(plan.kind==="ACL") {
      restoreFullRow("public.listas",original.list,["id"],"PR08_ACL_LIST_RESTORE");
      restoreReplaceSet("public.lista_visibilidade","lista_id="+sqlUuidVar(plan.list_id_var),original.acl_rows,"PR08_ACL_ROWS_RESTORE");
      restoreWholeTableById("public.audit_logs",original.audit_logs,"PR08_ACL_AUDIT_RESTORE");
      return;
    }
    if(plan.kind==="LEAD"||plan.kind==="FUNNEL") {
      restoreFullRow("public.leads",original.lead,["id"],"PR08_LEAD_RESTORE");
      restoreScopedSetById("public.funil_movimentacoes","lead_id="+sqlUuidVar(plan.lead_id_var),original.movements,"PR08_MOVEMENT_RESTORE");
      return;
    }
    if(plan.kind==="FEEDBACK") {
      restoreFullRow("public.lotes",original.lot,["id"],"PR08_FEEDBACK_LOT_RESTORE");
      restoreFullRow("public.leads",original.lead,["id"],"PR08_FEEDBACK_LEAD_RESTORE");
      restoreScopedSetById("public.funil_movimentacoes","lead_id="+sqlUuidVar(plan.lead_id_var),original.movements,"PR08_FEEDBACK_MOVEMENT_RESTORE");
      return;
    }
    if(plan.kind==="LOT") {
      restoreFullRow("public.lotes",original.lot,["id"],"PR08_LOT_RESTORE");
      return;
    }
    if(plan.kind==="LEAD_NAMESPACE") {
      const phones=plan.phone_vars.map(n=>sqlLiteral(valueFromVar(n))).join(",");
      serverExec("DELETE FROM public.leads WHERE lista_id="+sqlUuidVar(plan.list_id_var)+" AND telefone_e164 IN ("+phones+");","PR08_LEAD_NAMESPACE_CLEANUP");
      return;
    }
    if(plan.kind==="DISTRIBUTION") {
      restoreWholeTableById("public.leads",original.leads,"PR08_DISTRIBUTION_LEADS_RESTORE");
      restoreWholeTableById("public.lotes",original.lots,"PR08_DISTRIBUTION_LOTS_RESTORE");
      restoreWholeTableById("public.listas",original.lists,"PR08_DISTRIBUTION_LISTS_RESTORE");
      restoreFullRow("public.corretores",original.broker,["id"],"PR08_DISTRIBUTION_BROKER_RESTORE");
      restoreWholeTableById("public.audit_logs",original.audit_logs,"PR08_DISTRIBUTION_AUDIT_RESTORE");
      return;
    }
    if(plan.kind==="IMPORT") return cleanupImport(plan,original);
    throw new Error("PR08_SERVER_CLEANUP_KIND_UNKNOWN:"+plan.kind);
  }

  function valueAt(obj,pathString) {
    return String(pathString).split(".").reduce((acc,key)=>{
      if(acc===null||acc===undefined) return undefined;
      const k=/^\d+$/.test(key)?Number(key):key;
      return acc[k];
    },obj);
  }
  function multisetDelta(beforeRows,afterRows) {
    const counts=new Map();
    for(const row of beforeRows||[]) { const k=stable(row); counts.set(k,(counts.get(k)||0)+1); }
    const delta=[];
    for(const row of afterRows||[]) {
      const k=stable(row),n=counts.get(k)||0;
      if(n>0) counts.set(k,n-1); else delta.push(row);
    }
    return delta;
  }
  function serverDelta(before,after,pathString) {
    const b=valueAt(before,pathString),a=valueAt(after,pathString);
    if(!Array.isArray(b)||!Array.isArray(a)) throw new Error("PR08_SERVER_DELTA_ARRAY_REQUIRED:"+pathString);
    return multisetDelta(b,a);
  }
  function responseBody(responses,index) {
    if(!responses[index]) throw new Error("PR08_RESPONSE_INDEX_MISSING:"+index);
    return responses[index].body;
  }

  function semanticAssertionPass(a,responses,httpBefore,httpAfter,serverBefore,serverAfter) {
    const body=()=>responseBody(responses,a.response_index||0);
    if(a.mode==="NO_JSON_ERROR") return !(body()&&typeof body()==="object"&&!Array.isArray(body())&&body().error);
    if(a.mode==="RESPONSE_EQUALS_LITERAL") return stable(body())===stable(a.value);
    if(a.mode==="RESPONSE_OBJECT_FIELD_EQUALS_LITERAL") return body()&&!Array.isArray(body())&&body()[a.field]===a.value;
    if(a.mode==="RESPONSE_OBJECT_FIELD_EQUALS_VAR") return body()&&!Array.isArray(body())&&String(body()[a.field])===String(valueFromVar(a.var));
    if(a.mode==="RESPONSE_FIRST_ROW_FIELD_EQUALS_VAR") return Array.isArray(body())&&body().length>0&&String(body()[0]?.[a.field])===String(valueFromVar(a.var));
    if(a.mode==="RESPONSE_OBJECT_NUMERIC_FIELDS") return body()&&!Array.isArray(body())&&a.fields.every(f=>typeof body()[f]==="number"&&Number.isFinite(body()[f]));
    if(a.mode==="RESPONSE_ARRAY_EMPTY") return Array.isArray(body())&&body().length===0;
    if(a.mode==="RESPONSE_ARRAY_NONEMPTY") return Array.isArray(body())&&body().length>0;
    if(a.mode==="RESPONSE_ARRAY_IDS_EQUAL_VAR_SET") {
      if(!Array.isArray(body())) return false;
      const actual=new Set(body().map(x=>String(x.id))),expected=asSet(valueFromVar(a.var));
      return actual.size===expected.size&&[...actual].every(x=>expected.has(x));
    }
    if(a.mode==="RESPONSE_ARRAY_IDS_EXCLUDE_VAR_SET") {
      if(!Array.isArray(body())) return false;
      const denied=asSet(valueFromVar(a.var)); return body().every(x=>!denied.has(String(x.id)));
    }
    if(a.mode==="RESPONSE_ARRAY_ORDER_ASC") {
      if(!Array.isArray(body())) return false;
      for(let i=1;i<body().length;i++){const p=body()[i-1],c=body()[i];for(const f of a.fields){if(p[f]===c[f])continue;if(p[f]>c[f])return false;break;}}
      return true;
    }
    if(a.mode==="RESPONSE_OBJECT_ARRAY_CONTAINS_TARGET") {
      const arr=body()?.[a.field]; return Array.isArray(arr)&&arr.some(x=>x.target_type===a.target_type&&String(x.target_id)===String(valueFromVar(a.target_id_var)));
    }
    if(a.mode==="ALL_RESPONSE_BODIES_CANONICALLY_EQUAL") return responses.every(r=>stable(r.body)===stable(responses[0].body));

    if(a.mode==="SERVER_STATE_UNCHANGED") return stable(serverBefore)===stable(serverAfter);
    if(a.mode==="SERVER_AFTER_PATH_EQUALS_LITERAL") return stable(valueAt(serverAfter,a.path))===stable(a.value);
    if(a.mode==="SERVER_AFTER_PATH_EQUALS_VAR") return String(valueAt(serverAfter,a.path))===String(valueFromVar(a.var));
    if(a.mode==="SERVER_AFTER_PATH_EQUALS_BEFORE") return stable(valueAt(serverAfter,a.path))===stable(valueAt(serverBefore,a.path));
    if(a.mode==="SERVER_DELTA_ARRAY_COUNT_EQUALS") return serverDelta(serverBefore,serverAfter,a.path).length===a.count;
    if(a.mode==="SERVER_DELTA_ARRAY_ALL_FIELD_EQUALS_VAR") {
      const rows=serverDelta(serverBefore,serverAfter,a.path); return rows.length>0&&rows.every(x=>String(x[a.field])===String(valueFromVar(a.var)));
    }
    if(a.mode==="SERVER_DELTA_ARRAY_ALL_FIELD_EQUALS_LITERAL") {
      const rows=serverDelta(serverBefore,serverAfter,a.path); return rows.length>0&&rows.every(x=>x[a.field]===a.value);
    }
    if(a.mode==="SERVER_AFTER_ARRAY_COUNT_EQUALS") { const rows=valueAt(serverAfter,a.path); return Array.isArray(rows)&&rows.length===a.count; }
    if(a.mode==="SERVER_AFTER_ARRAY_UNIQUE_FIELD") {
      const rows=valueAt(serverAfter,a.path); if(!Array.isArray(rows)) return false;
      const vals=rows.map(x=>String(x[a.field])); return new Set(vals).size===vals.length;
    }
    if(a.mode==="SERVER_AFTER_ARRAY_CONTAINS_TARGET") {
      const rows=valueAt(serverAfter,a.path); return Array.isArray(rows)&&rows.some(x=>x.target_type===a.target_type&&String(x.target_id)===String(valueFromVar(a.target_id_var)));
    }

    // Legacy HTTP-probe assertions remain for non-server-managed cases.
    if(a.mode==="AFTER_FIRST_ROW_FIELD_EQUALS_VAR" || a.mode==="AFTER_FIRST_ROW_FIELD_EQUALS_LITERAL" || a.mode==="AFTER_ROWS_CONTAIN_TARGET" || a.mode==="DELTA_ROW_COUNT_EQUALS" || a.mode==="DELTA_ROW_COUNT_RANGE" || a.mode==="DELTA_ROWS_ALL_FIELD_EQUALS_VAR" || a.mode==="AFTER_ROWS_UNIQUE_FIELD") {
      const beforeRows=httpBefore?.[a.probe_index]?.body,afterRows=httpAfter?.[a.probe_index]?.body;
      if(!Array.isArray(afterRows)) return false;
      if(a.mode==="AFTER_FIRST_ROW_FIELD_EQUALS_VAR") return afterRows.length>0&&String(afterRows[0]?.[a.field])===String(valueFromVar(a.var));
      if(a.mode==="AFTER_FIRST_ROW_FIELD_EQUALS_LITERAL") return afterRows.length>0&&afterRows[0]?.[a.field]===a.value;
      if(a.mode==="AFTER_ROWS_CONTAIN_TARGET") return afterRows.some(x=>x.target_type===a.target_type&&String(x.target_id)===String(valueFromVar(a.target_id_var)));
      const d=multisetDelta(beforeRows||[],afterRows);
      if(a.mode==="DELTA_ROW_COUNT_EQUALS") return d.length===a.count;
      if(a.mode==="DELTA_ROW_COUNT_RANGE") return d.length>=a.min&&d.length<=a.max;
      if(a.mode==="DELTA_ROWS_ALL_FIELD_EQUALS_VAR") return d.length>0&&d.every(x=>String(x[a.field])===String(valueFromVar(a.var)));
      if(a.mode==="AFTER_ROWS_UNIQUE_FIELD"){const vals=afterRows.map(x=>String(x[a.field]));return new Set(vals).size===vals.length;}
    }
    throw new Error("PR08_SEMANTIC_ASSERTION_UNKNOWN:"+a.mode);
  }

  function recordApplicable(record) {
    if(!record.applicability) return true;
    if(record.applicability.mode==="FIXTURE_BOOLEAN") {
      const actual=fixtureBool(record.applicability.var);
      return actual===Boolean(record.applicability.execute_when);
    }
    throw new Error("PR08_APPLICABILITY_MODE_UNKNOWN:"+record.test_id);
  }

  const receipts=[];
  for(const record of records) {
    if(!recordApplicable(record)) {
      receipts.push({
        test_id:record.test_id,
        requirement_id:record.requirement_id,
        exact_application_commit:matrix.base_application_commit,
        exact_migration_commits:record.exact_migration_commits,
        supabase_project_ref:fixture.target_project_ref,
        environment:fixture.environment,
        fixture_version:fixture.fixture_version,
        actual_authorization_result:"NOT_APPLICABLE",
        actual_data_mutation:"NOT_APPLICABLE",
        semantic_assertions:[],
        concurrency:null,
        sanitized_error_code:null,
        cleanup_restored:null,
        pass_fail:"NOT_APPLICABLE",
        timestamp:new Date().toISOString(),
        evidence_reference:process.env.FECHAI_PR08_RECEIPT_FILE||"STDOUT_ONLY"
      });
      continue;
    }

    const plan=record.server_case_plan ? matrix.server_case_plans?.[record.server_case_plan] : null;
    if(record.server_case_plan && !plan) throw new Error("PR08_SERVER_CASE_PLAN_MISSING:"+record.test_id);

    let originalServer=null,serverBefore=null,serverAfter=null,cleanupState=null;
    let originalGlobalHash=null,cleanupGlobalHash=null,originalSequences=null;
    let cleanupRestored=plan?false:null;
    let topologyPassed=[];
    let httpBefore=[],httpAfter=[];
    let caseError=null;
    let responses=[];
    let receipt=null;

    try {
      topologyPassed=await runTopologyPreflight(record);

      if(plan) {
        ensureServerContext();
        if(plan.global_data_hash) {
          originalGlobalHash=publicDataHash("PR08_CASE_ORIGINAL_"+record.test_id);
          originalSequences=sequenceState();
        }
        originalServer=serverState(plan);
        prepareServerCase(plan,originalServer);
        serverBefore=serverState(plan);
      } else {
        if(!record.mutation_probe_plan?.before?.length || !record.mutation_probe_plan?.after?.length) throw new Error("PR08_VERSIONED_HTTP_PROBE_PLAN_MISSING:"+record.test_id);
        httpBefore=await httpProbeState(record.mutation_probe_plan.before);
      }

      if(!record.request_plan?.requests?.length) throw new Error("PR08_VERSIONED_REQUEST_PLAN_MISSING:"+record.test_id);
      if(record.execution_mode==="CONCURRENT_HTTP") responses=await Promise.all(record.request_plan.requests.map(doSpec));
      else for(const spec of record.request_plan.requests) responses.push(await doSpec(spec));

      if(plan) serverAfter=serverState(plan);
      else httpAfter=await httpProbeState(record.mutation_probe_plan.after);

      const authPass=responses.every(r=>responsePass(record.request_plan.response_assertion,r));
      const relationPass=record.request_plan.response_relation==="ALL_CANONICAL_BODIES_EQUAL" ? responses.every(r=>stable(r.body)===stable(responses[0].body)) : true;

      const beforeEvidence=plan?serverBefore:httpBefore;
      const afterEvidence=plan?serverAfter:httpAfter;
      const beforeHash=sha256(beforeEvidence),afterHash=sha256(afterEvidence);
      const observed=beforeHash===afterHash?"UNCHANGED":"CHANGED";
      const expected=record.mutation_probe_plan.expectation;
      const mutationPass=expected==="MUST_EQUAL"?observed==="UNCHANGED":expected==="MUST_CHANGE"?observed==="CHANGED":false;

      const semanticResults=(record.semantic_assertions||[]).map(a=>({
        mode:a.mode,
        pass:semanticAssertionPass(a,responses,httpBefore,httpAfter,serverBefore,serverAfter)
      }));
      const semanticPass=semanticResults.every(x=>x.pass);

      let concurrency=null,concurrencyPass=true;
      if(record.concurrency_assertion?.require_positive_overlap) {
        if(responses.length<2) throw new Error("PR08_CONCURRENCY_NEEDS_TWO_REQUESTS:"+record.test_id);
        const overlapMs=Math.min(...responses.map(r=>r.finish_ms))-Math.max(...responses.map(r=>r.start_ms));
        concurrency={overlap_ms:overlapMs,required_min_ms:record.concurrency_assertion.min_overlap_ms,timings:responses.map(r=>({started_at:r.started_at,finished_at:r.finished_at,duration_ms:r.duration_ms}))};
        concurrencyPass=overlapMs>=record.concurrency_assertion.min_overlap_ms;
      }

      const errors=responses.map(errorEvidence);
      const errorCodes=errors.map(e=>e.normalized_code);

      receipt={
        test_id:record.test_id,
        requirement_id:record.requirement_id,
        exact_application_commit:matrix.base_application_commit,
        exact_migration_commits:record.exact_migration_commits,
        supabase_project_ref:fixture.target_project_ref,
        environment:fixture.environment,
        fixture_version:fixture.fixture_version,
        topology_checks_passed:topologyPassed,
        evidence_channel:plan?"PSQL_POSTGRES_OWNER_NON_PRODUCTION_ONLY":"VERSIONED_HTTP_PROBES",
        actual_authorization_result:responses.map(r=>r.status),
        actual_data_mutation:{observed,before_sha256:beforeHash,after_sha256:afterHash,expected},
        semantic_assertions:semanticResults,
        concurrency,
        sanitized_error_code:errorCodes.length===1?errorCodes[0]:errorCodes,
        sanitized_error_evidence:errors.map(e=>({code:e.code,message:e.message})),
        cleanup_restored:cleanupRestored,
        pass_fail:(authPass&&relationPass&&mutationPass&&semanticPass&&concurrencyPass)?"PASS":"FAIL",
        timestamp:new Date().toISOString(),
        evidence_reference:process.env.FECHAI_PR08_RECEIPT_FILE||"STDOUT_ONLY",
        response_bodies_sanitized:responses.map(r=>redact(r.body))
      };
    } catch(error) {
      caseError=error;
    } finally {
      if(plan && originalServer) {
        try {
          cleanupServerCase(plan,originalServer);
          if(originalSequences) restoreSequences(originalSequences);
          cleanupState=serverState(plan);

          const scopedRestored=stable(cleanupState)===stable(originalServer);
          if(plan.global_data_hash) cleanupGlobalHash=publicDataHash("PR08_CASE_FINAL_"+record.test_id);
          const globalRestored=!plan.global_data_hash || cleanupGlobalHash===originalGlobalHash;
          cleanupRestored=scopedRestored&&globalRestored;

          if(receipt) {
            receipt.cleanup_restored=cleanupRestored;
            receipt.cleanup_scoped_original_sha256=sha256(originalServer);
            receipt.cleanup_scoped_final_sha256=sha256(cleanupState);
            receipt.cleanup_global_original_sha256=originalGlobalHash;
            receipt.cleanup_global_final_sha256=cleanupGlobalHash;
            if(!cleanupRestored) receipt.pass_fail="FAIL";
          }
          if(!cleanupRestored && !caseError) caseError=new Error("PR08_CASE_CLEANUP_NOT_RESTORED:"+record.test_id);
        } catch(cleanupError) {
          if(receipt){receipt.cleanup_restored=false;receipt.pass_fail="FAIL";}
          if(!caseError) caseError=cleanupError;
        }
      }
    }

    if(receipt) receipts.push(receipt);
    if(caseError) throw caseError;
  }

  const output=JSON.stringify({schema:"fechai.pr08.http.receipt.v5",receipts},null,2)+"\n";
  if(process.env.FECHAI_PR08_RECEIPT_FILE) await fs.writeFile(path.resolve(process.env.FECHAI_PR08_RECEIPT_FILE),output,{flag:"wx"});
  process.stdout.write(output);
  if(receipts.some(r=>r.pass_fail==="FAIL")) process.exitCode=1;
}
main().catch(error=>{
  process.stderr.write(JSON.stringify({error:String(error?.message||error)})+"\n");
  process.exitCode=1;
});
