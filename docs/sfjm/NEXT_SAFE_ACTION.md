# FECH.AI — SFJM Next Safe Action

**Status:** `SEMANTIC_NEXT_ACTION_VIEW / DOCUMENTATION_ONLY`  
**Updated:** `2026-08-21`  
**Repository:** `wagnerjfjunior/fecha.ai`

## 1. Authority

This file is a thin semantic view. It is not a second current-state authority.

Principal material state:

```text
docs/sfjm/CURRENT_STATE.md
```

Before any sensitive action, resolve GitHub/environment lifecycle live as required by:

```text
docs/sfjm/INDEX.md
```

## 2. Current semantic next action

```text
Resolve the safe server-side disposition and authority contract for the two remaining EditarCorretorModal administrative direct writes.
```

The refreshed 2026-08-21 repository-wide static source inventory is now established for the explicitly bounded executable/versioned source universe.

It confirms that predicate #3 is still not satisfied because these dependencies remain active:

```text
1. EditarCorretorModal.salvar()
   → direct PATCH public.corretores
   → ativo, apto_para_receber

2. EditarCorretorModal.redefinirSenha()
   → criar-usuario reset_password
   → direct PATCH public.corretores
   → must_change_password=false
```

The inventory-evidence gap is closed. Repeating the same repository-wide search without an invalidation event is not the next action.

The next specialist role is:

```text
ROLE=backend_data
→ backend-data-platform-specialist
```

The next read-only task should establish, for the two administrative transitions:

```text
caller
→ server-side command/RPC/Edge contract
→ auth.uid() actor derivation
→ actor profile/role
→ tenant/company derivation
→ target-user authorization
→ protected fields/state transition
→ authoritative tables
→ transaction/compensation semantics
→ grants/RLS/policy implications
→ auditability
→ failure semantics
→ rollback/proof obligations
```

The existing `atualizar_status_corretor` RPC used by `TimesTab` is a candidate seam for the `apto_para_receber` transition, but its authoritative body and authorization contract must be verified before equivalence or reuse is claimed.

Other material PR-03 needs remain owned by `CURRENT_STATE.md`, including:

```text
post-deploy functional smoke
post-deploy runtime fail-closed evidence
cutover observation sufficient to confirm no legitimate flow depends on direct UPDATE
controlled RPCs individually inventoried and tested for continuity under direct-UPDATE revocation
```

This statement is semantic. It does not authorize implementation, Supabase mutation, runtime testing, Ready, merge, deployment or production action.

## 3. No frozen lifecycle routing

This file must not encode a durable instruction such as:

```text
run GPT-X on PR-Y at head-Z
```

when that instruction depends only on volatile lifecycle state.

Exact PR/head/check/review/deployment facts must be resolved live at execution time.

## 4. No retrospective replay

Historical provenance gaps do not automatically become the next action.

```text
UNKNOWN != REEXECUTE
GATE_PROVENANCE_NOT_RECORDED != GATE_FAILED
AUTHORITY_PROVENANCE_NOT_RECORDED != UNAUTHORIZED
```

Replay a prior gate only when its missing provenance materially affects a current safety decision, and then perform only the minimum present-time validation required.

## 5. Update rule

Update this file only when the semantic next action changes materially.

Do not update it for:

```text
main SHA change only
Draft/Ready transition only
documentation-only closure merge
unrelated Builder documentation merge
new conversation or specialist
```
