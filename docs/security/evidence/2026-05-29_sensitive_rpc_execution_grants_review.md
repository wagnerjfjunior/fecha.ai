# FECH.AI / MesaCliente - Sensitive RPC Execution Grants Review

Date: 2026-05-29
Branch: security/supabase-rls-grants-hardening
Scope: public SECURITY DEFINER functions matching sensitive patterns: password/auth/vault/service role/root audit
Status: SANITIZED PUBLIC EVIDENCE

---

## Sanitization rule

This public evidence file intentionally does not expose raw email, user_id, broker id, company id, team id, audit id, token, password, secret, or customer data.

---

## 1. Initial routine privileges returned by Supabase

Initial sanitized result before RPC execute hardening:

```text
public.get_corretores_time              authenticated EXECUTE
public.importar_leads_batch             authenticated EXECUTE
public.listar_empresas_root             anon EXECUTE
public.listar_empresas_root             authenticated EXECUTE
public.registrar_root_audit             anon EXECUTE
public.registrar_root_audit             authenticated EXECUTE
```

Initial interpretation:

```text
OPEN - anon had EXECUTE on root/audit SECURITY DEFINER RPCs. This was unnecessary attack surface and required hardening.
```

---

## 2. Classification

### P0/P1 - public.redefinir_senha_corretor(uuid, text)

Finding:

```text
The function has a password-like argument, but the function body does not update auth.users and does not store the password. It only sets corretores.must_change_password = true and returns the target user id.
```

Risk:

```text
Even if the password-like value is currently unused, accepting a plaintext password-shaped input into a public SQL RPC is not acceptable. The value may be sent through client payloads, network traces, API logs, function observability, browser dev tools, or incident snapshots.
```

Recommended action:

```text
Do not expose this RPC to anon/authenticated/PUBLIC.
Move password reset/change flows to Supabase Auth or server-side Edge Function with service role kept server-side only.
Remove the password parameter from any public SQL function API.
Validate tenant/admin/root ownership before any user reset operation.
```

Current execution grant state:

```text
No anon/authenticated/PUBLIC EXECUTE row was returned for redefinir_senha_corretor.
Keep it locked down. Do not grant authenticated EXECUTE.
```

### P1 - public.listar_empresas_root()

Finding:

```text
The function contains an internal public.is_root() guard, but EXECUTE was initially granted to anon and authenticated.
```

Risk:

```text
The internal guard is good, but anon EXECUTE on a SECURITY DEFINER root-only RPC is unnecessary attack surface.
```

Recommended action:

```text
Revoke EXECUTE from anon and PUBLIC.
Keep authenticated only if the logged root panel calls the RPC through an authenticated user session.
```

### P1 - public.registrar_root_audit(text, uuid, jsonb)

Finding:

```text
The function contains an internal public.is_root() guard and writes root audit logs server-side, but EXECUTE was initially granted to anon and authenticated.
```

Risk:

```text
The function should not be executable by anon. Even with the root guard, anonymous EXECUTE on a SECURITY DEFINER audit function is not least privilege.
```

Recommended action:

```text
Revoke EXECUTE from anon and PUBLIC.
Keep authenticated only if root actions call this RPC from an authenticated root session.
```

### P1 - public.importar_leads_batch(uuid, jsonb, text)

Finding:

```text
The function rejects unauthenticated calls, resolves empresa_id from auth.uid(), verifies that p_lista_id belongs to the resolved tenant, inserts leads using server-resolved empresa_id, and deduplicates by session id.
```

Risk:

```text
The tenant boundary is directionally correct. Remaining review: session deduplication must be assessed for tenant scoping and collision behavior in the next hardening phase.
```

Recommended action:

```text
Keep authenticated EXECUTE if this is a normal logged-in import path.
Ensure deduplication includes empresa_id.
Add payload size/rate controls outside SQL or in Edge/API layer.
```

### P2 - public.get_corretores_time(uuid)

Finding:

```text
The function requires authenticated user context, blocks users without broker/root context, and then allows only gestor/admin_local/root.
```

Risk:

```text
Authenticated EXECUTE is probably acceptable because the function has role guards. Functional negative test using a common broker is still required.
```

Recommended action:

```text
Keep authenticated EXECUTE.
Run functional negative test as common broker: expected forbidden.
```

---

## 3. Migration applied

Migration file:

```text
supabase/migrations/20260529163000_security_rpc_execute_hardening.sql
```

Purpose:

```text
- Remove anon/PUBLIC EXECUTE from sensitive SECURITY DEFINER RPCs.
- Keep authenticated EXECUTE only where needed for logged-in app flows.
- Keep redefinir_senha_corretor unavailable to client roles.
```

---

## 4. Post-migration validation

Post-migration catalog result for the five sensitive functions:

```text
public.get_corretores_time              authenticated EXECUTE
public.importar_leads_batch             authenticated EXECUTE
public.listar_empresas_root             authenticated EXECUTE
public.registrar_root_audit             authenticated EXECUTE
```

No row returned for:

```text
anon
PUBLIC/public
public.redefinir_senha_corretor
```

Interpretation:

```text
APPROVED - anon/PUBLIC EXECUTE was removed from the sensitive RPC set.
APPROVED - redefinir_senha_corretor has no anon/authenticated/PUBLIC EXECUTE in the validated output.
APPROVED - only authenticated EXECUTE remains for the four functions required by logged-in flows.
```

---

## 5. PUBLIC effective EXECUTE diagnostic

Diagnostic method:

```text
PUBLIC pseudo-role was validated through aclexplode(...), where grantee = 0.
```

Actual sanitized result:

```text
public.get_corretores_time(uuid)                    exists=true | public_execute=false | anon_execute=false | authenticated_execute=true
public.importar_leads_batch(uuid,jsonb,text)        exists=true | public_execute=false | anon_execute=false | authenticated_execute=true
public.listar_empresas_root()                       exists=true | public_execute=false | anon_execute=false | authenticated_execute=true
public.redefinir_senha_corretor(uuid,text)          exists=true | public_execute=false | anon_execute=false | authenticated_execute=false
public.registrar_root_audit(text,uuid,jsonb)        exists=true | public_execute=false | anon_execute=false | authenticated_execute=true
```

Interpretation:

```text
APPROVED - PUBLIC and anon EXECUTE are false for all five sensitive functions covered by this phase.
APPROVED - authenticated EXECUTE remains only for the expected four logged-in RPC flows.
APPROVED - redefinir_senha_corretor remains unavailable to client roles.
```

---

## 6. Function configuration/search_path validation

Actual sanitized result:

```text
public.get_corretores_time              SECURITY DEFINER=true | search_path=public
public.importar_leads_batch             SECURITY DEFINER=true | search_path=public
public.listar_empresas_root             SECURITY DEFINER=true | search_path=public
public.redefinir_senha_corretor         SECURITY DEFINER=true | search_path=public
public.registrar_root_audit             SECURITY DEFINER=true | search_path=public
```

Interpretation:

```text
APPROVED - all five sensitive SECURITY DEFINER functions have an explicit search_path instead of NULL.
CONTROLLED RISK - current search_path is public, and non-owner client roles do not have CREATE on schema public.
HARDENING NOTE - a stricter pattern remains public, pg_temp; consider applying it in a later low-risk migration after validating dependencies.
```

---

## 7. Schema CREATE privilege validation

Actual sanitized result:

```text
anon           USAGE=true | CREATE=false on schema public
authenticated  USAGE=true | CREATE=false on schema public
PUBLIC         USAGE=true | CREATE=false on schema public
```

Interpretation:

```text
APPROVED - anon, authenticated, and PUBLIC have USAGE but do not have CREATE on schema public.
APPROVED - search_path hijacking risk through client-created objects in public is controlled for these roles.
```

---

## 8. Functional tests

Common broker negative tests:

```text
APPROVED - listar_empresas_root() fails with access denied for common broker.
APPROVED - registrar_root_audit(...) fails with access denied for common broker.
APPROVED - get_corretores_time(...) returns forbidden for common broker.
APPROVED - redefinir_senha_corretor(...) is not executable by authenticated client roles.
```

Root positive tests:

```text
APPROVED - listar_empresas_root() works for root context.
APPROVED - registrar_root_audit(...) works for root context.
```

---

## 9. Broad routine surface outside this phase

The broad routine privilege snapshot shows many RPCs outside the PR #64 scope still exposing anon and/or PUBLIC EXECUTE.

This includes root-like, MesaCliente, lock, utility, and financial helper RPCs. They require separate classification and controlled remediation.

Interpretation:

```text
OPEN - broad public routine surface remains a separate hardening backlog.
APPROVED FOR THIS PHASE - the five sensitive RPCs covered by PR #64 are validated above.
```

---

## 10. Final status for RPC EXECUTE hardening

```text
APPROVED - execution grants are hardened and validated for the five functions covered by this phase.
APPROVED - search_path is explicit on sensitive SECURITY DEFINER functions.
APPROVED - anon/authenticated/PUBLIC do not have CREATE on schema public.
CONTROLLED RISK - search_path is currently public; future hardening to public, pg_temp is recommended but not blocking.
OPEN - broad routine surface outside this phase must be reviewed in follow-up PRs.
```
