import { createClient } from "npm:@supabase/supabase-js@2";

const encoder = new TextEncoder();

const SECRET_NAME = "GPT3_FECHAI_ESPECIALISTA";
const AUTH_HEADER_NAME = "x-gpt-action-key";
const PROJECT_ID = "uobxxgzshrmbtjfdolxd";
const SNAPSHOT_VERSION = "pr103_preflight_v1";
const FUNCTION_SOURCE_SCOPE =
  "trigger functions attached to public.corretores only";
const MAX_BODY_BYTES = 2048;
const RFC3339_PATTERN =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$/;

const ALLOWED_OPERATIONS = [
  "health_check",
  "security_metadata_snapshot",
] as const;

const SNAPSHOT_FIELDS = [
  "snapshot_version",
  "generated_at",
  "scope",
  "table",
  "columns",
  "indexes",
  "constraints",
  "triggers",
  "trigger_functions",
  "required_functions",
  "required_function_existence",
  "roles",
  "role_memberships",
  "schema_effective_privileges",
  "table_direct_acl",
  "table_effective_privileges",
  "column_direct_acl",
  "column_effective_privileges",
  "default_function_acl",
  "builtin_function_acl_for_postgres",
  "languages",
  "policies",
] as const;

const SNAPSHOT_ARRAY_FIELDS = [
  "columns",
  "indexes",
  "constraints",
  "triggers",
  "trigger_functions",
  "required_functions",
  "roles",
  "role_memberships",
  "schema_effective_privileges",
  "table_direct_acl",
  "table_effective_privileges",
  "column_direct_acl",
  "column_effective_privileges",
  "default_function_acl",
  "builtin_function_acl_for_postgres",
  "languages",
  "policies",
] as const;

const SCOPE_FIELDS = [
  "project_ref",
  "access_mode",
  "schema",
  "target_table",
  "includes_row_data",
  "includes_auth_users",
  "includes_secrets",
  "includes_business_payload",
  "includes_function_source",
  "function_source_scope",
] as const;

const TABLE_FIELDS = [
  "exists",
  "schema",
  "name",
  "relkind",
  "owner",
  "rls_enabled",
  "rls_forced",
] as const;

const COLUMN_FIELDS = [
  "name",
  "ordinal_position",
  "data_type",
  "udt_schema",
  "udt_name",
  "is_nullable",
  "column_default",
  "is_identity",
  "identity_generation",
] as const;

const REQUIRED_FUNCTION_EXISTENCE_FIELDS = [
  "auth_uid",
  "password_state_rpc",
] as const;

const REQUIRED_COLUMNS: Record<string, string> = {
  user_id: "uuid",
  ativo: "boolean",
  must_change_password: "boolean",
};

const REQUIRED_ROLES = [
  "postgres",
  "authenticated",
  "anon",
  "service_role",
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

function isJsonObject(value: unknown): value is JsonObject {
  return value !== null &&
    typeof value === "object" &&
    !Array.isArray(value);
}

function hasExactKeys(
  value: JsonObject,
  expectedKeys: readonly string[],
): boolean {
  const actualKeys = Object.keys(value);
  return actualKeys.length === expectedKeys.length &&
    expectedKeys.every((key) =>
      Object.prototype.hasOwnProperty.call(value, key)
    );
}

function isNullableString(value: unknown): boolean {
  return value === null || typeof value === "string";
}

function isValidTimestamp(value: unknown): value is string {
  return typeof value === "string" &&
    RFC3339_PATTERN.test(value) &&
    Number.isFinite(Date.parse(value));
}

function hasJsonObjectItems(value: unknown): value is JsonObject[] {
  return Array.isArray(value) && value.every(isJsonObject);
}

function hasRequiredColumns(value: unknown): boolean {
  if (!Array.isArray(value) || value.length !== 3) {
    return false;
  }

  const observed = new Map<string, string>();

  for (const item of value) {
    if (!isJsonObject(item) || !hasExactKeys(item, COLUMN_FIELDS)) {
      return false;
    }

    const {
      name,
      ordinal_position: ordinalPosition,
      data_type: dataType,
      udt_schema: udtSchema,
      udt_name: udtName,
      is_nullable: isNullable,
      column_default: columnDefault,
      is_identity: isIdentity,
      identity_generation: identityGeneration,
    } = item;

    if (
      typeof name !== "string" ||
      typeof dataType !== "string" ||
      !Number.isInteger(ordinalPosition) ||
      typeof udtSchema !== "string" ||
      typeof udtName !== "string" ||
      typeof isNullable !== "string" ||
      !isNullableString(columnDefault) ||
      typeof isIdentity !== "string" ||
      !isNullableString(identityGeneration) ||
      observed.has(name)
    ) {
      return false;
    }

    observed.set(name, dataType);
  }

  return Object.entries(REQUIRED_COLUMNS).every(
    ([name, dataType]) => observed.get(name) === dataType,
  );
}

function hasRequiredRoles(value: unknown): boolean {
  if (!Array.isArray(value) || value.length !== REQUIRED_ROLES.length) {
    return false;
  }

  const observed = new Set<string>();

  for (const item of value) {
    if (
      !isJsonObject(item) ||
      typeof item.name !== "string" ||
      item.exists !== true ||
      observed.has(item.name)
    ) {
      return false;
    }

    observed.add(item.name);
  }

  return REQUIRED_ROLES.every((role) => observed.has(role));
}

function includesNamedObject(
  value: unknown,
  schema: string | null,
  name: string,
): boolean {
  return Array.isArray(value) &&
    value.some((item) =>
      isJsonObject(item) &&
      item.name === name &&
      (schema === null || item.schema === schema)
    );
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
  if (!isJsonObject(body)) {
    return jsonResponse({ error: "invalid_json_body" }, 400);
  }

  const keys = Object.keys(body);

  if (keys.length !== 1 || keys[0] !== "operation") {
    return jsonResponse(
      {
        error: "unexpected_request_fields",
        allowed_fields: ["operation"],
      },
      400,
    );
  }

  if (!isAllowedOperation(body.operation)) {
    return jsonResponse(
      {
        error: "operation_not_allowed",
        allowed_operations: ALLOWED_OPERATIONS,
      },
      403,
    );
  }

  return { operation: body.operation };
}

function validateSnapshot(data: unknown): data is JsonObject {
  if (!isJsonObject(data) || !hasExactKeys(data, SNAPSHOT_FIELDS)) {
    return false;
  }

  if (
    data.snapshot_version !== SNAPSHOT_VERSION ||
    !isValidTimestamp(data.generated_at) ||
    !isJsonObject(data.scope) ||
    !isJsonObject(data.table) ||
    !isJsonObject(data.required_function_existence)
  ) {
    return false;
  }

  const scope = data.scope;
  const table = data.table;
  const requiredFunctionExistence = data.required_function_existence;

  if (
    !hasExactKeys(scope, SCOPE_FIELDS) ||
    scope.project_ref !== PROJECT_ID ||
    scope.access_mode !== "read_only" ||
    scope.schema !== "public" ||
    scope.target_table !== "corretores" ||
    scope.includes_row_data !== false ||
    scope.includes_auth_users !== false ||
    scope.includes_secrets !== false ||
    scope.includes_business_payload !== false ||
    scope.includes_function_source !== true ||
    scope.function_source_scope !== FUNCTION_SOURCE_SCOPE
  ) {
    return false;
  }

  if (
    !hasExactKeys(table, TABLE_FIELDS) ||
    table.exists !== true ||
    table.schema !== "public" ||
    table.name !== "corretores" ||
    (table.relkind !== "r" && table.relkind !== "p") ||
    typeof table.owner !== "string" ||
    typeof table.rls_enabled !== "boolean" ||
    typeof table.rls_forced !== "boolean"
  ) {
    return false;
  }

  if (
    !SNAPSHOT_ARRAY_FIELDS.every((field) =>
      hasJsonObjectItems(data[field])
    ) ||
    !hasRequiredColumns(data.columns) ||
    !hasExactKeys(
      requiredFunctionExistence,
      REQUIRED_FUNCTION_EXISTENCE_FIELDS,
    ) ||
    requiredFunctionExistence.auth_uid !== true ||
    typeof requiredFunctionExistence.password_state_rpc !== "boolean" ||
    !hasRequiredRoles(data.roles) ||
    !includesNamedObject(data.required_functions, "auth", "uid") ||
    !includesNamedObject(data.languages, null, "plpgsql")
  ) {
    return false;
  }

  return true;
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
          "X-Client-Info": "fechai-gpt-security-gateway/1.2.1",
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
