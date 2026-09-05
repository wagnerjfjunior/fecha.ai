# FECH.AI — STS-M2-03 Index / ACL Contradictions — Accepted Evidence

**Status:** `COMPLETE / ACCEPTED WITH RESIDUALS`  
**Program:** Issue #141 — `FECH.AI Security-to-Scale 2026`  
**Task:** `STS-M2-03 — Índices / ACL contraditórias`  
**Decision date:** `2026-09-05`  
**Decision anchor main:** `682837dab2c719330c2e6e72e885ed6de5e2f171`  
**Environment:** `Pilot Production / SaaS multi-tenant / multiempresa`  
**Security Go:** `NOT_GRANTED`

## 1. Product Authority decision

```text
STS-M2-03 = COMPLETE / ACCEPTED WITH RESIDUALS
STS-M2-03 AS-IS INDEX / ACL CONTRADICTION SURFACE = SUFFICIENTLY UNDERSTOOD
APPSEC_NOT_REQUIRED_FOR_STS_M2_03_ACCEPTANCE
Security Go = NOT_GRANTED
```

This acceptance closes the STS-M2-03 evidence/planning task only. It does not authorize index creation/removal, ACL remediation, RLS/policy/grant/default-privilege changes, runtime testing, deploy, STS-M2-04 implementation or Security Go.

## 2. Exact anchors and evidence chain

```text
FECH.AI repository = wagnerjfjunior/fecha.ai
FECH.AI exact main = 682837dab2c719330c2e6e72e885ed6de5e2f171
SES exact main = 285b08206d334971b182e2d46646ba0b6938bdfe
Supabase project = uobxxgzshrmbtjfdolxd / Discador-MesaCliente
Issue #141 = OPEN
```

Independent specialist verdicts:

```text
BACKEND_DATA_RECOMMENDS_STS_M2_03_ACCEPTANCE_WITH_RESIDUALS
ARCHITECTURE_RECOMMENDS_STS_M2_03_ACCEPTANCE_WITH_RESIDUALS
```

Backend/Data evidence fingerprint:

```text
SHA-256 =
b5a41bf04495ee9783cd70a1d08926611c8c78ecfb644f6178fba161207cb52f
```

The Architecture gate initially blocked only because that complete Backend/Data artifact had not been integrally read. After the exact artifact was supplied, Architecture recorded `INTEGRAL_READ`, fingerprint `MATCH`, blocker `CLOSED`, no material contradiction and the final acceptance-with-residuals verdict.

## 3. Accepted index AS-IS

```text
public tables = 44
public indexes = 201
access method btree = 201
primary indexes = 44
PK / UNIQUE / EXCLUDE constraint-backed indexes = 74
other unique indexes = 39
partial indexes = 17
expression indexes = 1
INCLUDE indexes = 0
invalid indexes = 0
not-ready indexes = 0
not-live indexes = 0

idx_scan = 0 = 118
idx_scan = 0 + observed table writes > 0 = 34

public foreign keys = 129
FKs without supporting prefix index = 70
```

Statistics boundary:

```text
observation timestamp = 2026-09-05 12:19:08 UTC
PostgreSQL postmaster start = 2026-07-19 04:58:01 UTC
pg_stat_database.stats_reset = NULL
```

Accepted semantic boundaries:

```text
idx_scan = 0 != safe to drop
unindexed FK != index automatically required
catalog overlap != safe removal
catalog/statistics observation != performance bottleneck proven
```

### 3.1 Definition-equal redundancy candidate

`public.funil_movimentacoes`:

```text
idx_funil_mov
idx_funil_mov_empresa_lead
effective definition = btree (empresa_id, lead_id)
unique = false
predicate = none
expression = none
```

Accepted class:

```text
DEFINITION-EQUAL REDUNDANCY
CANDIDATE REDUNDANCY
SAFE REMOVAL = NOT PROVEN
```

### 3.2 Other overlap candidates

Three explicit indexes overlap lookup keys supplied by UNIQUE constraint indexes:

- `corretores.idx_corretores_user(user_id)`;
- `empresas.idx_empresas_slug(slug)`;
- `empresas_configuracoes.idx_empresas_config_empresa(empresa_id)`.

Architecture accepted 20 prefix/same-key pairs as `POTENTIAL OVERLAP` only. All removal decisions require separately bounded workload/contract/planner evidence and authorization.

## 4. Accepted ACL / policy AS-IS

```text
write policies total = 46
structurally authenticated-reachable = 14
non-reachable = 32

of the 32:
13 = genuine latent / grant-blocked
19 = false-predicate policies

authenticated direct-write grant tables = 9
authenticated MAINTAIN tables = 12
```

Nine authenticated direct-write grant tables:

```text
lista_avaliacoes
logs
mesa_cliente_unidade_enriquecimentos
pme_cadence_steps
pme_cadences
pme_call_scripts
pme_lead_message_state
pme_message_templates
pme_message_usage
```

Twelve authenticated MAINTAIN tables:

```text
audit_trail
lista_visibilidade
mesa_cliente_agendas_financeiras
mesa_cliente_desconto_politicas
mesa_cliente_unidade_enriquecimentos
pme_cadence_steps
pme_cadences
pme_call_scripts
pme_lead_message_state
pme_message_templates
pme_message_usage
root_audit_logs
```

### 4.1 Historical versus current metric

Accepted M2-02 historical split:

```text
15 authenticated-reachable
31 latent / grant-blocked
```

Current M2-03 live split:

```text
14 structurally authenticated-reachable
32 non-reachable
```

Accepted adjudication:

```text
HISTORICAL CAUSE = NOT DETERMINED
CAUSE_NOT_DETERMINED_BUT_CURRENT_LIVE_STATE_SUFFICIENTLY_KNOWN
```

This is a historical provenance residual. It does not globally reopen STS-M2-02 and does not block STS-M2-03 acceptance.

### 4.2 False-predicate policy terminology

The 19 false-predicate policies must not be generically overclaimed as global deny policies.

Accepted Architecture vocabulary:

```text
FALSE-PREDICATE POLICY
STRUCTURALLY NON-AUTHORIZING IN ITS OWN PERMISSIVE CONTRIBUTION
DEFENSIVE INTENT POSSIBLE
EFFECTIVE DENY DEPENDS ON POLICY COMPOSITION
TARGET-POLICY INPUT FOR M2-04
```

Policy composition must account for PERMISSIVE/RESTRICTIVE, command, role, USING/WITH CHECK and other applicable policies.

### 4.3 Material ACL contradictions / target inputs

`mesa_cliente_unidade_enriquecimentos`:

```text
authenticated INSERT / UPDATE / DELETE grants = present
RLS = enabled
policies = 0
semantic class = GRANT/POLICY MISMATCH / CONTRADICTORY / INTENT UNCLEAR
```

Routine caller / ACL surfaces:

```text
avaliar_lista(uuid, integer, text):
  canonical static app caller exists
  authenticated EXECUTE = false
  class = STATIC CALLER × LIVE ACL CONTRADICTION
  runtime = NOT_TESTED

trilha_lead(uuid):
  canonical static app caller exists
  authenticated EXECUTE = false
  class = STATIC CALLER × LIVE ACL CONTRADICTION
  runtime = NOT_TESTED

acquire_lote_lock(uuid, uuid):
  PUBLIC / anon / authenticated / service_role EXECUTE = true
  class = CURRENT EXECUTE ACL SURFACE / INTENT UNCLEAR
  lock-abuse runtime = NOT_TESTED
```

Broad default privileges for future tables/sequences/functions remain a `FUTURE FAIL-OPEN PROVISIONING HAZARD`; this does not assert retroactive exposure of existing objects.

## 5. Finding disposition

```text
BLOCKING = NONE
REQUIRED IN THIS PR = NONE
```

Accepted residuals:

- definition-equal index redundancy candidate; safe removal not proven;
- constraint and structural overlap candidates requiring workload evidence;
- zero-scan/statistics observation boundary;
- 70/129 FK-support review candidates;
- historical 15/31 → current 14/32 provenance gap;
- 13 latent/grant-blocked policies;
- 19 false-predicate policies requiring composition-aware target treatment;
- authenticated direct-DML authority surfaces;
- `mesa_cliente_unidade_enriquecimentos` grant/policy mismatch;
- 12 authenticated MAINTAIN grants with intent/necessity unresolved;
- future default-privilege fail-open provisioning hazard;
- `avaliar_lista(3)` caller × ACL contradiction, runtime not tested;
- `trilha_lead` caller × ACL contradiction, runtime not tested;
- `acquire_lote_lock` reachable EXECUTE ACL surface, intent unclear.

## 6. Downstream boundary

Future target/remediation inputs, not implementation authority:

- workload proof before index creation/removal;
- target direct-DML authority;
- latent grant/policy normalization;
- composition-aware false-predicate treatment;
- target posture for authenticated MAINTAIN;
- fail-closed default privileges;
- routine EXECUTE/caller contract reconciliation;
- explicit grant/RLS contract for `mesa_cliente_unidade_enriquecimentos`.

```text
STS-M2-04 = NEXT GATE ONLY
STS-M2-04 implementation = NOT_AUTHORIZED
Security Go = NOT_GRANTED
```

## 7. Invalidation events

Revalidate proportionally if any material change occurs to public index definitions/statistics material to a decision; table grants, MAINTAIN, RLS, policies or default privileges; routine EXECUTE ACLs or canonical callers; production catalog/runtime evidence; or Product Authority scope/Security Go decision.

Absent such an event, do not reopen STS-M2-01, globally reopen STS-M2-02, or repeat STS-M2-03 specialist gates.
