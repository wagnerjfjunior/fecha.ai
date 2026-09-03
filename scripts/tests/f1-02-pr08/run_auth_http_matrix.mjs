#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const crypto = await import("node:crypto");

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

  function renderString(value, encode) {
    if (typeof value !== "string") return value;
    return value.replace(/\$\{([A-Z0-9_]+)\}/g, (_,name) => {
      if (!(name in variables)) throw new Error("PR08_VARIABLE_REQUIRED:"+name);
      const raw = String(variables[name]);
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
      if (!(spec.auth_token_var in variables)) throw new Error("PR08_AUTH_TOKEN_REQUIRED:"+spec.auth_token_var);
      headers.Authorization = "Bearer "+String(variables[spec.auth_token_var]);
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
    const body = response.body;
    const code = body && typeof body === "object" && !Array.isArray(body) && typeof body.code === "string" ? body.code : null;
    const message = body && typeof body === "object" && !Array.isArray(body)
      ? (typeof body.error === "string" ? body.error : (typeof body.message === "string" ? body.message : ""))
      : (typeof body === "string" ? body : "");
    const sanitizedMessage = redact(message);
    return {
      code: code ? redact(code) : null,
      message:sanitizedMessage,
      normalized_code: code ? redact(code) : "HTTP_"+response.status+"_"+slug(sanitizedMessage || "NO_BODY")
    };
  }

  function responsePass(assertion,response) {
    if (assertion.mode === "EMPTY_ARRAY_DENIAL") {
      return assertion.allowed_statuses.includes(response.status) && Array.isArray(response.body) && response.body.length === 0;
    }
    if (assertion.mode === "DENIAL_SEMANTIC") {
      if (!assertion.expected_statuses.includes(response.status)) return false;
      const ev = errorEvidence(response);
      if (assertion.expected_error_codes?.length && !assertion.expected_error_codes.includes(ev.code)) return false;
      if (assertion.expected_error_exact && ev.message !== assertion.expected_error_exact) return false;
      if (assertion.expected_error_regex && !(new RegExp(assertion.expected_error_regex,"i")).test((ev.code||"")+" "+ev.message)) return false;
      return true;
    }
    if (assertion.mode === "ALLOW_SEMANTIC") {
      if (Math.floor(response.status/100) !== assertion.allowed_status_class) return false;
      if (assertion.reject_json_error && response.body && typeof response.body === "object" && !Array.isArray(response.body) && response.body.error) return false;
      return true;
    }
    throw new Error("PR08_RESPONSE_ASSERTION_UNKNOWN");
  }

  function valueFromVar(name) {
    if (!(name in variables)) throw new Error("PR08_VARIABLE_REQUIRED:"+name);
    return variables[name];
  }
  function asSet(value) {
    if (Array.isArray(value)) return new Set(value.map(String));
    if (typeof value === "string") {
      try {
        const parsed = JSON.parse(value);
        if (Array.isArray(parsed)) return new Set(parsed.map(String));
      } catch {}
      return new Set(value.split(",").map(x=>x.trim()).filter(Boolean));
    }
    throw new Error("PR08_VAR_SET_REQUIRED");
  }
  function anyTrue(row,clauses) {
    return clauses.some(c => {
      if (Object.prototype.hasOwnProperty.call(c,"equals")) return row?.[c.field] === c.equals;
      if (Array.isArray(c.in)) return c.in.includes(row?.[c.field]);
      return row?.[c.field] === true;
    });
  }

  function topologyAssertionPass(assertion,body) {
    if (assertion.mode === "OBJECT_FIELD_EQUALS_VAR") return body && typeof body==="object" && !Array.isArray(body) && String(body[assertion.field]) === String(valueFromVar(assertion.var));
    if (assertion.mode === "ZERO_ROWS") return Array.isArray(body) && body.length === 0;
    if (assertion.mode === "ROW_IDS_EQUAL_VAR_SET") {
      if (!Array.isArray(body)) return false;
      const actual = new Set(body.map(x=>String(x.id)));
      const expected = asSet(valueFromVar(assertion.var));
      return actual.size===expected.size && [...actual].every(x=>expected.has(x));
    }
    if (assertion.mode === "EXACTLY_ONE_ROW") {
      if (!Array.isArray(body) || body.length !== 1) return false;
      const row=body[0];
      for (const [field,varName] of Object.entries(assertion.field_equals_vars||{})) if (String(row[field]) !== String(valueFromVar(varName))) return false;
      for (const [field,varName] of Object.entries(assertion.field_not_equals_vars||{})) if (String(row[field]) === String(valueFromVar(varName))) return false;
      for (const [field,literal] of Object.entries(assertion.field_equals_literals||{})) if (row[field] !== literal) return false;
      for (const field of assertion.field_not_null||[]) if (row[field] === null || row[field] === undefined) return false;
      for (const field of assertion.field_null||[]) if (row[field] !== null) return false;
      if (assertion.any_true?.length && !anyTrue(row,assertion.any_true)) return false;
      return true;
    }
    throw new Error("PR08_TOPOLOGY_ASSERTION_UNKNOWN:"+assertion.mode);
  }

  async function runTopologyPreflight() {
    for (const rel of matrix.topology_contract?.variable_relations||[]) {
      if (rel.mode === "NOT_EQUAL" && String(valueFromVar(rel.left)) === String(valueFromVar(rel.right))) {
        throw new Error("PR08_TOPOLOGY_VARIABLE_RELATION_FAILED:"+rel.left+":"+rel.right);
      }
    }
    const passed=[];
    for (const check of matrix.topology_contract?.checks||[]) {
      const response = await doSpec(check.request);
      if (Math.floor(response.status/100)!==2) throw new Error("PR08_TOPOLOGY_HTTP_FAILED:"+check.check_id+":"+response.status);
      if (!topologyAssertionPass(check.assertion,response.body)) throw new Error("PR08_TOPOLOGY_ASSERTION_FAILED:"+check.check_id);
      passed.push(check.check_id);
    }
    return passed;
  }

  async function probeFingerprint(specs) {
    const observations=[];
    for (const spec of specs) {
      const r = await doSpec(spec);
      if (Math.floor(r.status/100) !== 2) throw new Error("PR08_MUTATION_PROBE_FAILED_HTTP:"+r.status);
      observations.push({status:r.status,body:r.body});
    }
    return {sha256:sha256(observations),observations};
  }
  function rowsFrom(obs,index) {
    const body=obs?.observations?.[index]?.body;
    if (!Array.isArray(body)) throw new Error("PR08_PROBE_ROWS_REQUIRED:"+index);
    return body;
  }
  function deltaRows(before,after,index) {
    const b=rowsFrom(before,index).map(stable);
    const a=rowsFrom(after,index).map(stable);
    const counts=new Map();
    for(const x of b) counts.set(x,(counts.get(x)||0)+1);
    const delta=[];
    for(let i=0;i<a.length;i++){
      const key=a[i],n=counts.get(key)||0;
      if(n>0) counts.set(key,n-1); else delta.push(rowsFrom(after,index)[i]);
    }
    return delta;
  }
  function firstResponseBody(responses,index) {
    if (!responses[index]) throw new Error("PR08_RESPONSE_INDEX_MISSING:"+index);
    return responses[index].body;
  }

  function semanticAssertionPass(a,responses,before,after) {
    const body=()=>firstResponseBody(responses,a.response_index||0);
    if (a.mode==="NO_JSON_ERROR") return !(body() && typeof body()==="object" && !Array.isArray(body()) && body().error);
    if (a.mode==="RESPONSE_EQUALS_LITERAL") return stable(body())===stable(a.value);
    if (a.mode==="RESPONSE_FIRST_ROW_FIELD_EQUALS_VAR") return Array.isArray(body()) && body().length>0 && String(body()[0]?.[a.field])===String(valueFromVar(a.var));
    if (a.mode==="RESPONSE_OBJECT_FIELD_EQUALS_LITERAL") return body() && !Array.isArray(body()) && body()[a.field]===a.value;
    if (a.mode==="RESPONSE_OBJECT_FIELD_EQUALS_VAR") return body() && !Array.isArray(body()) && String(body()[a.field])===String(valueFromVar(a.var));
    if (a.mode==="RESPONSE_OBJECT_NUMERIC_FIELDS") return body() && !Array.isArray(body()) && a.fields.every(f=>typeof body()[f]==="number" && Number.isFinite(body()[f]));
    if (a.mode==="RESPONSE_ARRAY_EMPTY") return Array.isArray(body()) && body().length===0;
    if (a.mode==="RESPONSE_ARRAY_NONEMPTY") return Array.isArray(body()) && body().length>0;
    if (a.mode==="RESPONSE_ARRAY_IDS_EQUAL_VAR_SET") {
      if(!Array.isArray(body())) return false;
      const actual=new Set(body().map(x=>String(x.id))), expected=asSet(valueFromVar(a.var));
      return actual.size===expected.size && [...actual].every(x=>expected.has(x));
    }
    if (a.mode==="RESPONSE_ARRAY_IDS_EXCLUDE_VAR_SET") {
      if(!Array.isArray(body())) return false;
      const denied=asSet(valueFromVar(a.var));
      return body().every(x=>!denied.has(String(x.id)));
    }
    if (a.mode==="RESPONSE_ARRAY_ORDER_ASC") {
      if(!Array.isArray(body())) return false;
      for(let i=1;i<body().length;i++){
        const prev=body()[i-1],cur=body()[i];
        for(const f of a.fields){
          if(prev[f]===cur[f]) continue;
          if(prev[f]>cur[f]) return false;
          break;
        }
      }
      return true;
    }
    if (a.mode==="RESPONSE_OBJECT_ARRAY_CONTAINS_TARGET") {
      const arr=body()?.[a.field];
      return Array.isArray(arr) && arr.some(x=>x.target_type===a.target_type && String(x.target_id)===String(valueFromVar(a.target_id_var)));
    }
    if (a.mode==="ALL_RESPONSE_BODIES_CANONICALLY_EQUAL") return responses.every(r=>stable(r.body)===stable(responses[0].body));
    if (a.mode==="AFTER_FIRST_ROW_FIELD_EQUALS_VAR") {
      const rows=rowsFrom(after,a.probe_index);
      return rows.length>0 && String(rows[0]?.[a.field])===String(valueFromVar(a.var));
    }
    if (a.mode==="AFTER_FIRST_ROW_FIELD_EQUALS_LITERAL") {
      const rows=rowsFrom(after,a.probe_index);
      return rows.length>0 && rows[0]?.[a.field]===a.value;
    }
    if (a.mode==="AFTER_ROWS_CONTAIN_TARGET") {
      const rows=rowsFrom(after,a.probe_index);
      return rows.some(x=>x.target_type===a.target_type && String(x.target_id)===String(valueFromVar(a.target_id_var)));
    }
    if (a.mode==="DELTA_ROW_COUNT_EQUALS") return deltaRows(before,after,a.probe_index).length===a.count;
    if (a.mode==="DELTA_ROW_COUNT_RANGE") {
      const n=deltaRows(before,after,a.probe_index).length;
      return n>=a.min && n<=a.max;
    }
    if (a.mode==="DELTA_ROWS_ALL_FIELD_EQUALS_VAR") {
      const rows=deltaRows(before,after,a.probe_index);
      return rows.length>0 && rows.every(x=>String(x[a.field])===String(valueFromVar(a.var)));
    }
    if (a.mode==="AFTER_ROWS_UNIQUE_FIELD") {
      const rows=rowsFrom(after,a.probe_index),vals=rows.map(x=>String(x[a.field]));
      return new Set(vals).size===vals.length;
    }
    throw new Error("PR08_SEMANTIC_ASSERTION_UNKNOWN:"+a.mode);
  }

  const topologyPassed = await runTopologyPreflight();
  const receipts=[];

  for (const record of records) {
    if (!record.request_plan?.requests?.length || !record.mutation_probe_plan?.before?.length || !record.mutation_probe_plan?.after?.length) {
      throw new Error("PR08_VERSIONED_EXECUTION_PLAN_MISSING:"+record.test_id);
    }

    const before = await probeFingerprint(record.mutation_probe_plan.before);
    let responses=[];
    if (record.execution_mode === "CONCURRENT_HTTP") responses = await Promise.all(record.request_plan.requests.map(doSpec));
    else for (const spec of record.request_plan.requests) responses.push(await doSpec(spec));
    const after = await probeFingerprint(record.mutation_probe_plan.after);

    const authPass = responses.every(r=>responsePass(record.request_plan.response_assertion,r));
    const relationPass = record.request_plan.response_relation === "ALL_CANONICAL_BODIES_EQUAL"
      ? responses.every(r=>stable(r.body)===stable(responses[0].body)) : true;

    const observed = before.sha256 === after.sha256 ? "UNCHANGED" : "CHANGED";
    const expected = record.mutation_probe_plan.expectation;
    const mutationPass = expected === "MUST_EQUAL" ? observed === "UNCHANGED" :
      expected === "MUST_CHANGE" ? observed === "CHANGED" : false;

    const semanticResults=(record.semantic_assertions||[]).map(a=>({mode:a.mode,pass:semanticAssertionPass(a,responses,before,after)}));
    const semanticPass=semanticResults.every(x=>x.pass);

    let concurrency=null, concurrencyPass=true;
    if (record.concurrency_assertion?.require_positive_overlap) {
      if (responses.length < 2) throw new Error("PR08_CONCURRENCY_NEEDS_TWO_REQUESTS:"+record.test_id);
      const overlapMs = Math.min(...responses.map(r=>r.finish_ms)) - Math.max(...responses.map(r=>r.start_ms));
      concurrency={overlap_ms:overlapMs,required_min_ms:record.concurrency_assertion.min_overlap_ms,timings:responses.map(r=>({started_at:r.started_at,finished_at:r.finished_at,duration_ms:r.duration_ms}))};
      concurrencyPass=overlapMs>=record.concurrency_assertion.min_overlap_ms;
    }

    const errors=responses.map(errorEvidence);
    const errorCodes=errors.map(e=>e.normalized_code);
    const pass=authPass && relationPass && mutationPass && semanticPass && concurrencyPass;
    receipts.push({
      test_id:record.test_id,
      requirement_id:record.requirement_id,
      exact_application_commit:matrix.base_application_commit,
      exact_migration_commits:record.exact_migration_commits,
      supabase_project_ref:fixture.target_project_ref,
      environment:fixture.environment,
      fixture_version:fixture.fixture_version,
      topology_checks_passed:topologyPassed,
      actual_authorization_result:responses.map(r=>r.status),
      actual_data_mutation:{observed,before_sha256:before.sha256,after_sha256:after.sha256,expected},
      semantic_assertions:semanticResults,
      concurrency,
      sanitized_error_code:errorCodes.length===1?errorCodes[0]:errorCodes,
      sanitized_error_evidence:errors.map(e=>({code:e.code,message:e.message})),
      pass_fail:pass?"PASS":"FAIL",
      timestamp:new Date().toISOString(),
      evidence_reference:process.env.FECHAI_PR08_RECEIPT_FILE || "STDOUT_ONLY",
      response_bodies_sanitized:responses.map(r=>redact(r.body))
    });
  }

  const output=JSON.stringify({schema:"fechai.pr08.http.receipt.v3",topology_checks_passed:topologyPassed,receipts},null,2)+"\n";
  if (process.env.FECHAI_PR08_RECEIPT_FILE) await fs.writeFile(path.resolve(process.env.FECHAI_PR08_RECEIPT_FILE),output,{flag:"wx"});
  process.stdout.write(output);
  if (receipts.some(r=>r.pass_fail!=="PASS")) process.exitCode=1;
}
main().catch(error=>{
  process.stderr.write(JSON.stringify({error:String(error?.message||error)})+"\n");
  process.exitCode=1;
});
