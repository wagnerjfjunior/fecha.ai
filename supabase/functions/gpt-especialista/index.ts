import { createClient } from "npm:@supabase/supabase-js@2";

const encoder = new TextEncoder();

const SECRET_NAME = "GPT3_FECHAI_ESPECIALISTA";
const AUTH_HEADER_NAME = "x-gpt-action-key";
const PROJECT_ID = "uobxxgzshrmbtjfdolxd";
const MAX_BODY_BYTES = 2048;

const ALLOWED_OPERATIONS = [
  "health_check",
  "security_metadata_snapshot",
] as const;

type AllowedOperation = (typeof ALLOWED_OPERATIONS)[number];
type JsonObject = Record<string, unknown>;

function jsonResponse(
  body: JsonObject,
  status = 200,
  extraHeaders: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
      ...extraHeaders,
    },
  });
}

async function hashValue(value: string): Promise<Uint8Array> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    encoder.encode(value),
  );

  return new Uint8Array(digest);
}

async function secureEquals(
  suppliedValue: string,
  expectedValue: string,
): Promise<boolean> {
  if (!suppliedValue || !expectedValue) {
    return false;
  }

  const [suppliedHash, expectedHash] = await Promise.all([
    hashValue(suppliedValue),
    hashValue(expectedValue),
  ]);

  if (suppliedHash.length !== expectedHash.length) {
    return false;
  }

  let difference = 0;

  for (let index = 0; index < expectedHash.length; index += 1) {
    difference |= suppliedHash[index] ^ expectedHash[index];
  }

  return difference === 0;
}

function getSupabaseServerKey(): string | null {
  const legacyServiceRoleKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (legacyServiceRoleKey) {
    return legacyServiceRoleKey;
  }

  const secretKey = Deno.env.get("SUPABASE_SECRET_KEY");

  if (secretKey) {
    return secretKey;
  }

  const secretKeysJson = Deno.env.get("SUPABASE_SECRET_KEYS");

  if (!secretKeysJson) {
    return null;
  }

  try {
    const parsed = JSON.parse(secretKeysJson) as Record<string, unknown>;
    const defaultKey = parsed.default;

    if (typeof defaultKey === "string" && defaultKey.length > 0) {
      return defaultKey;
    }

    for (const value of Object.values(parsed)) {
      if (typeof value === "string" && value.length > 0) {
        return value;
      }
    }
  } catch {
    console.error("SUPABASE_SECRET_KEYS contains invalid JSON");
  }

  return null;
}

function isAllowedOperation(value: unknown): value is AllowedOperation {
  return typeof value === "string" &&
    ALLOWED_OPERATIONS.includes(value as AllowedOperation);
}

function validateExactRequestBody(
  body: unknown,
): { operation: AllowedOperation } | Response {
  if (
    body === null ||
    typeof body !== "object" ||
    Array.isArray(body)
  ) {
    return jsonResponse({ error: "invalid_json_body" }, 400);
  }

  const requestBody = body as Record<string, unknown>;
  const keys = Object.keys(requestBody);

  if (keys.length !== 1 || keys[0] !== "operation") {
    return jsonResponse(
      {
        error: "unexpected_request_fields",
        allowed_fields: ["operation"],
      },
      400,
    );
  }

  if (!isAllowedOperation(requestBody.operation)) {
    return jsonResponse(
      {
        error: "operation_not_allowed",
        allowed_operations: ALLOWED_OPERATIONS,
      },
      403,
    );
  }

  return { operation: requestBody.operation };
}

function validateSnapshot(data: unknown): data is JsonObject {
  if (
    data === null ||
    typeof data !== "object" ||
    Array.isArray(data)
  ) {
    return false;
  }

  const snapshot = data as JsonObject;
  const scope = snapshot.scope;

  if (
    snapshot.snapshot_version !== "pr103_preflight_v1" ||
    scope === null ||
    typeof scope !== "object" ||
    Array.isArray(scope)
  ) {
    return false;
  }

  const typedScope = scope as JsonObject;

  return typedScope.project_ref === PROJECT_ID &&
    typedScope.includes_row_data === false &&
    typedScope.includes_auth_users === false &&
    typedScope.includes_secrets === false &&
    typedScope.includes_business_payload === false;
}

async function executeSecurityMetadataSnapshot(): Promise<Response> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServerKey = getSupabaseServerKey();

  if (!supabaseUrl || !supabaseServerKey) {
    console.error("Supabase server credentials are unavailable");

    return jsonResponse(
      { error: "database_gateway_misconfigured" },
      500,
    );
  }

  const supabaseAdmin = createClient(
    supabaseUrl,
    supabaseServerKey,
    {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
      global: {
        headers: {
          "X-Client-Info": "fechai-gpt-security-gateway/1.2.0",
        },
      },
    },
  );

  const { data, error } = await supabaseAdmin.rpc(
    "gpt_security_metadata_snapshot",
  );

  if (error) {
    console.error("Security metadata RPC failed", {
      code: error.code,
      message: error.message,
    });

    return jsonResponse(
      {
        error: "security_metadata_operation_failed",
        operation: "security_metadata_snapshot",
      },
      500,
    );
  }

  if (!validateSnapshot(data)) {
    console.error("Security metadata RPC returned an invalid contract");

    return jsonResponse(
      {
        error: "security_metadata_contract_invalid",
        operation: "security_metadata_snapshot",
      },
      502,
    );
  }

  return jsonResponse({
    ok: true,
    operation: "security_metadata_snapshot",
    service: "fechai_supabase_gateway",
    project_id: PROJECT_ID,
    environment: "production",
    access_mode: "read_only",
    database_access: true,
    row_data_access: false,
    snapshot: data,
    timestamp: new Date().toISOString(),
  });
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method !== "POST") {
    return jsonResponse(
      { error: "method_not_allowed" },
      405,
      { Allow: "POST" },
    );
  }

  const contentType = request.headers.get("content-type") ?? "";

  if (!contentType.toLowerCase().startsWith("application/json")) {
    return jsonResponse(
      { error: "unsupported_media_type" },
      415,
    );
  }

  const contentLength = Number(
    request.headers.get("content-length") ?? "0",
  );

  if (
    Number.isFinite(contentLength) &&
    contentLength > MAX_BODY_BYTES
  ) {
    return jsonResponse(
      { error: "request_body_too_large" },
      413,
    );
  }

  const expectedKey = Deno.env.get(SECRET_NAME);

  if (!expectedKey) {
    console.error(`${SECRET_NAME} is not configured`);

    return jsonResponse(
      { error: "gateway_misconfigured" },
      500,
    );
  }

  const suppliedKey =
    request.headers.get(AUTH_HEADER_NAME)?.trim() ?? "";

  if (!await secureEquals(suppliedKey, expectedKey)) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  const rawBody = await request.text();

  if (encoder.encode(rawBody).byteLength > MAX_BODY_BYTES) {
    return jsonResponse(
      { error: "request_body_too_large" },
      413,
    );
  }

  let parsedBody: unknown;

  try {
    parsedBody = JSON.parse(rawBody);
  } catch {
    return jsonResponse({ error: "invalid_json_body" }, 400);
  }

  const validated = validateExactRequestBody(parsedBody);

  if (validated instanceof Response) {
    return validated;
  }

  switch (validated.operation) {
    case "health_check":
      return jsonResponse({
        ok: true,
        operation: "health_check",
        service: "fechai_supabase_gateway",
        project_id: PROJECT_ID,
        environment: "production",
        access_mode: "read_only",
        capabilities: ALLOWED_OPERATIONS,
        database_access: false,
        row_data_access: false,
        timestamp: new Date().toISOString(),
      });

    case "security_metadata_snapshot":
      return await executeSecurityMetadataSnapshot();
  }
});
