#!/usr/bin/env node
async function main() {
  const fs = await import("node:fs/promises");
  const path = await import("node:path");
  const { fileURLToPath } = await import("node:url");

  const PROD_REF = "uobxxgzshrmbtjfdolxd";
  const here = path.dirname(fileURLToPath(import.meta.url));
  const matrixPath = path.resolve(here, "../../../supabase/tests/f1-02-pr08/matrix.json");
  const fixturePath = process.env.FECHAI_PR08_HTTP_FIXTURE_FILE;

  if (process.env.FECHAI_PR08_EXECUTION_AUTHORIZED !== "YES") {
    throw new Error("PR08_EXECUTION_NOT_AUTHORIZED");
  }
  if (!fixturePath) throw new Error("PR08_HTTP_FIXTURE_FILE_REQUIRED");

  const matrix = JSON.parse(await fs.readFile(matrixPath, "utf8"));
  const fixture = JSON.parse(await fs.readFile(path.resolve(fixturePath), "utf8"));

  if (!fixture.target_project_ref || !fixture.environment || !fixture.fixture_version) {
    throw new Error("PR08_FIXTURE_IDENTITY_REQUIRED");
  }
  if (fixture.target_project_ref === PROD_REF) {
    if (process.env.FECHAI_PR08_ALLOW_PRODUCTION !== "YES" ||
        process.env.FECHAI_PR08_PRODUCTION_EXECUTION_AUTHORIZED !== "YES") {
      throw new Error("PR08_PRODUCTION_EXECUTION_NOT_AUTHORIZED");
    }
  }

  const selected = process.argv.slice(2);
  const records = matrix.records.filter(r =>
    r.runner === "http_matrix" && (selected.length === 0 || selected.includes(r.test_id))
  );
  if (!records.length) throw new Error("PR08_NO_HTTP_CASES_SELECTED");

  const redact = value => {
    const text = typeof value === "string" ? value : JSON.stringify(value);
    return text
      .replace(/Bearer\s+[A-Za-z0-9._-]+/gi, "Bearer [REDACTED]")
      .replace(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g, "[JWT_REDACTED]")
      .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/gi, "[UUID_REDACTED]")
      .replace(/[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi, "[EMAIL_REDACTED]")
      .replace(/\+?\d[\d\s().-]{7,}\d/g, "[PHONE_REDACTED]");
  };
  const stable = value => JSON.stringify(value, Object.keys(value || {}).sort());

  async function doRequest(spec) {
    if (!spec || !spec.url || !spec.method) throw new Error("PR08_REQUEST_SPEC_REQUIRED");
    const response = await fetch(spec.url, {
      method: spec.method,
      headers: spec.headers || {},
      body: spec.body === undefined ? undefined :
        (typeof spec.body === "string" ? spec.body : JSON.stringify(spec.body))
    });
    const bodyText = await response.text();
    let body;
    try { body = JSON.parse(bodyText); } catch { body = bodyText; }
    return { status: response.status, body };
  }

  async function probe(spec) {
    if (!spec) return null;
    return await doRequest(spec);
  }

  const receipts = [];
  for (const record of records) {
    const c = fixture.cases?.[record.test_id];
    if (!c) throw new Error("PR08_FIXTURE_CASE_MISSING:" + record.test_id);

    const before = await probe(c.mutation_probe?.before);
    let responses;
    if (record.execution_mode === "CONCURRENT_HTTP") {
      if (!Array.isArray(c.concurrent_requests) || c.concurrent_requests.length < 2) {
        throw new Error("PR08_CONCURRENT_REQUESTS_REQUIRED:" + record.test_id);
      }
      responses = await Promise.all(c.concurrent_requests.map(doRequest));
    } else {
      responses = [await doRequest(c.request)];
    }
    const after = await probe(c.mutation_probe?.after);

    const expectedStatuses = c.expected_statuses;
    if (!Array.isArray(expectedStatuses) || !expectedStatuses.length) {
      throw new Error("PR08_EXPECTED_STATUSES_REQUIRED:" + record.test_id);
    }
    const statusPass = responses.every(r => expectedStatuses.includes(r.status));

    let mutationPass = false;
    if (c.mutation_probe?.mode === "MUST_EQUAL") {
      mutationPass = before !== null && after !== null && stable(before.body) === stable(after.body);
    } else if (c.mutation_probe?.mode === "MUST_CHANGE") {
      mutationPass = before !== null && after !== null && stable(before.body) !== stable(after.body);
    } else if (c.mutation_probe?.mode === "CUSTOM_ASSERTED_BY_FIXTURE") {
      mutationPass = c.mutation_probe.custom_assertion_pass === true;
    } else {
      throw new Error("PR08_MUTATION_PROBE_MODE_REQUIRED:" + record.test_id);
    }

    const bodyRegex = c.expected_body_regex ? new RegExp(c.expected_body_regex) : null;
    const bodyPass = bodyRegex ? responses.every(r => bodyRegex.test(redact(r.body))) : true;
    const pass = statusPass && mutationPass && bodyPass;

    receipts.push({
      test_id: record.test_id,
      requirement_id: record.requirement_id,
      exact_application_commit: matrix.base_application_commit,
      supabase_project_ref: fixture.target_project_ref,
      environment: fixture.environment,
      fixture_version: fixture.fixture_version,
      actor_role: c.actor_role || "SANITIZED",
      actor_company_team: c.actor_company_team || "SANITIZED",
      actual_authorization_result: responses.map(r => r.status),
      actual_data_mutation: c.mutation_probe.mode,
      sanitized_error_code: pass ? null : "PR08_EXPECTATION_MISMATCH",
      pass_fail: pass ? "PASS" : "FAIL",
      timestamp: new Date().toISOString(),
      evidence_reference: process.env.FECHAI_PR08_RECEIPT_FILE || "STDOUT_ONLY",
      response_bodies_sanitized: responses.map(r => redact(r.body))
    });
  }

  const output = JSON.stringify({schema:"fechai.pr08.http.receipt.v1",receipts}, null, 2) + "\n";
  if (process.env.FECHAI_PR08_RECEIPT_FILE) {
    await fs.writeFile(path.resolve(process.env.FECHAI_PR08_RECEIPT_FILE), output, {flag:"wx"});
  }
  process.stdout.write(output);
  if (receipts.some(r => r.pass_fail !== "PASS")) process.exitCode = 1;
}
main().catch(error => {
  process.stderr.write(JSON.stringify({error:String(error?.message || error)}) + "\n");
  process.exitCode = 1;
});
