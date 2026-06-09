# FECH.AI / Supabase - criar_empresa_root Live Apply Evidence

Date: 2026-06-09
Status: POST-MERGE LIVE APPLY CHECKPOINT
Scope: documentation-only evidence for PR #75 live application

---

## 1. Purpose

This document records the live Supabase application and catalog validation of the narrow EXECUTE hardening introduced by PR #75.

This checkpoint is documentation-only. It does not change database objects, migrations, RLS, policies, RPC bodies, frontend code, Edge Functions, MesaCliente, Worker, Make, n8n, Vercel, or production runtime.

---

## 2. Related change

Related PR:

```text
PR #75 - fix(supabase): harden criar_empresa_root execute grants
```

Merge result:

```text
merged: true
merge method: squash
merge sha: aef74a75c68371d1d4d5a5b906cf972908098960
expected head sha used for merge: 1a55b6f83c543a1b0bf53972b1411ef779e3f81b
```

Migration applied live:

```text
name: 20260609173000_criar_empresa_root_revoke_anon_public_execute
apply_migration success: true
```

---

## 3. Function under validation

```text
schema: public
function: criar_empresa_root
identity args: p_nome text, p_slug text, p_plano_id uuid, p_trial_dias integer
```

The reviewed body fingerprint remained unchanged during validation.

```text
body fingerprint source: sanitized lower(pg_get_functiondef(oid)) digest from read-only live catalog review
body fingerprint algorithm: md5
body fingerprint digest: b94e9ff1a640af22768ccdc9ba34f84f
raw body committed: no
```

---

## 4. Live post-apply catalog result

Read-only live catalog validation after applying the migration returned:

| check | observed |
|---|---:|
| body digest | `b94e9ff1a640af22768ccdc9ba34f84f` |
| SECURITY DEFINER | true |
| function config | `search_path=public` |
| volatility | `v` |
| anon EXECUTE | false |
| authenticated EXECUTE | true |
| service_role EXECUTE | true |
| PUBLIC execute ACL | false |

Effective EXECUTE grantees after hardening:

```text
authenticated
postgres
service_role
```

---

## 5. Validation conclusion

The live catalog now confirms the intended PR #75 hardening state:

```text
PUBLIC EXECUTE removed: yes
anon EXECUTE removed: yes
authenticated EXECUTE preserved: yes
service_role EXECUTE preserved: yes
function body digest unchanged: yes
function body changed: no
```

This confirms that the narrow grant hardening is effective on the live Supabase project for the reviewed `public.criar_empresa_root(text, text, uuid, integer)` signature.

---

## 6. Runtime and product impact

This evidence PR does not apply any new runtime change.

The already-applied PR #75 migration was intentionally scoped to EXECUTE grants for one RPC signature only.

No evidence in this checkpoint indicates changes to:

- RLS;
- policies;
- function body;
- table data;
- frontend;
- Edge Functions;
- MesaCliente parser;
- MesaCliente financial engine;
- Worker;
- Make;
- n8n;
- Vercel.

---

## 7. Remaining validation reservations

The live catalog validation confirms the grant state.

Functional negative tests may still be executed or documented separately for full end-to-end runtime assurance:

| test | expected |
|---|---|
| unauthenticated client call | blocked before function body |
| anon client call | blocked before function body |
| authenticated non-root call | blocked by server-side `is_root` guard |
| authenticated local tenant or company admin call | blocked by server-side `is_root` guard |
| valid root actor call | still succeeds |
| invalid plan id | blocked |
| duplicate slug | safe failure |
| malformed slug | blocked or normalized safely |
| audit path | preserved |

These functional tests are not claimed as completed by this checkpoint.

---

## 8. Non-goals

This checkpoint does not authorize or perform additional hardening.

It does not include:

- hardening of other root or billing RPCs;
- hardening of `salvar_mesa_cliente_enriquecimento`;
- direct DML replacement for `corretores`;
- broad grants cleanup;
- broad RLS changes;
- FORCE RLS changes;
- frontend changes;
- Edge Function changes;
- MesaCliente changes;
- production data changes.

---

## 9. Recommended next step

Next technical work should be opened in a separate focused PR.

Recommended next candidate group:

```text
root/billing/status RPCs with anon_execute=true
```

Do not mix this checkpoint with MesaCliente, direct DML replacement, broad grants cleanup, or multiple unrelated hardening actions.

---

## 10. Final conclusion

PR #75 is complete as a narrow Supabase EXECUTE grant hardening step.

The live post-apply catalog state confirms that unauthenticated and broad PUBLIC EXECUTE exposure were removed from `public.criar_empresa_root(text, text, uuid, integer)` while preserving authenticated and service_role execution paths and keeping the reviewed function body digest unchanged.
