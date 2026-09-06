# FECH.AI — STS-M2-04D — Durable Accepted Trigger Authority Evidence

**Status:** COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT
**Evidence class:** DURABLE_SPECIALIST_RESULT / MASTER_PROJECT_ADJUDICATED / NO_IMPLEMENTATION
**Decision date:** 2026-09-06
**Repository:** wagnerjfjunior/fecha.ai

## 1. Durable provenance

~~~text
SOURCE PACKET = Markdown(20260906-200207).md colado
SOURCE PACKET SHA-256 = 6927b61338555fef95cc25892bb6097e815839b53bc217e0229084c5e5220389
SOURCE PACKET BYTES = 44144
SOURCE PACKET PYTHON splitlines() = 1165
SOURCE PACKET newline count = 1164

FECH.AI decision/evidence base =
e380387fe341dcf42527ce70ded45fd894447aa5

SES evidence ref =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e

SUPABASE TARGET =
uobxxgzshrmbtjfdolxd / Discador-MesaCliente

MUTATION_PERFORMED = NO
SECURITY_GO = NOT_GRANTED
~~~

This durable artifact preserves the complete material M2-04D decision surface: context/readiness, 9/9 per-function authority classification, 18/18 trigger-instance coverage, target mode aggregate, direct EXECUTE target classification, trigger-specific target policy, residuals, future bounded remediation D-01 through D-08 and final verdict.

It does not implement D-01 through D-08 and does not authorize M2-04E, M2-04F, Ready, merge, deploy, Supabase mutation or Security Go.

## 2. Context readiness and material drift

~~~text
PROJECT = FECH.AI
PROJECT_ID = fechai
ROLE = backend_data
ARCHETYPE_ID = backend-data-platform-specialist
ADOPTION_STATUS = ADOPTED

REQUESTED_PROOF_LEVEL = LIVE_DATABASE_AUDIT
CAPABILITY_STATUS = AVAILABLE

SUPABASE_TARGET =
uobxxgzshrmbtjfdolxd / Discador-MesaCliente

DATABASE_PROBE =
current_database = postgres
current_user = supabase_read_only_user
PostgreSQL = 17.6
is_superuser = off

FECH.AI EXPECTED MAIN =
e380387fe341dcf42527ce70ded45fd894447aa5
FECH.AI RESOLVED MAIN =
e380387fe341dcf42527ce70ded45fd894447aa5

SES EXPECTED MAIN =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e
SES RESOLVED MAIN =
a31e10cc3f0d1278c53c49e38151854d36ee9f3e

TASK_ADMISSION = ADMITTED_READ_ONLY_M2_04D
MATERIAL_DRIFT = NO
MUTATION_PERFORMED = NO
SECURITY_GO = NOT_GRANTED

TRIGGER FUNCTIONS = 9
CURRENT SECURITY DEFINER = 9 / 9
CURRENT OWNER postgres = 9 / 9
TRIGGER INSTANCES = 18
ENABLED = 18 / 18
ROW LEVEL = 18 / 18
~~~

Repository provenance consumed proportionally at the exact FECH.AI ref:
- 20260901175000_f1_02_b4_list_acl_tenant_integrity.sql — 030 provenance.
- 20260517162000_mesa_cliente_engenharia_financeira_hardening.sql — 075 provenance.
- 20260523202000_pme_usage_tracking_v028_hardening_trigger_function_grants.sql — 111 ACL provenance.
- 20260822211600_t3_admin_password_reset_boundary.sql — 130 object provenance; live body read integrally from pg_get_functiondef.
- audit-family 011–015 — complete live definitions plus accepted M2-02 provenance.

No contradictory evidence invalidated accepted M2-04C.

## 3. Nine-function authority matrix

| Ord | Exact signature | Instances | Trigger authority class | Current | Target | Caller sufficient | Privileged boundary | Target direct EXECUTE |
|---|---|---:|---|---|---|---|---|---|
| 011 | audit_trail_log_corretores_critical_update() | 1 | AUDIT_SIDE_EFFECT_TRIGGER | DEFINER | DEFINER | NO | YES | NONE |
| 012 | audit_trail_log_empresas_governance() | 1 | AUDIT_SIDE_EFFECT_TRIGGER | DEFINER | DEFINER | NO | YES | NONE |
| 013 | audit_trail_log_lista_visibilidade_acl() | 1 | AUDIT_SIDE_EFFECT_TRIGGER | DEFINER | DEFINER | NO | YES | NONE |
| 014 | audit_trail_log_listas_governance() | 1 | AUDIT_SIDE_EFFECT_TRIGGER | DEFINER | DEFINER | NO | YES | NONE |
| 015 | audit_trail_log_times_governance() | 1 | AUDIT_SIDE_EFFECT_TRIGGER | DEFINER | DEFINER | NO | YES | NONE |
| 030 | f1_02_b4_validate_lista_visibilidade_target() | 1 | RELATIONAL_INVARIANT_TRIGGER | DEFINER | DEFINER | NO | YES | NONE |
| 075 | mesa_cliente_financeiro_assert_integridade() | 4 | TENANT_INTEGRITY_TRIGGER | DEFINER | DEFINER | NO | YES | NONE |
| 111 | pme_set_updated_at() | 5 | TECHNICAL_ROW_MAINTENANCE_TRIGGER | DEFINER | INVOKER | YES | NO | NONE |
| 130 | t3_guard_admin_password_reset_lease() | 3 | SECURITY_FENCE_TRIGGER | DEFINER | DEFINER | NO | YES | NONE |

## 4. Per-function target contracts

### 011 — audit_trail_log_corretores_critical_update()

~~~text
TRIGGER = AFTER UPDATE / ROW / corretores
CURRENT = SECURITY DEFINER / owner postgres / search_path public
DIRECT EXECUTE = PUBLIC false / anon false / authenticated true / service_role true
TARGET = DEFINER
ELEVATION = privileged audit persistence + trusted actor lookup
ACTOR = auth.uid() -> corretores actor id/role
TENANT = coalesce(NEW.empresa_id, OLD.empresa_id)
OBJECT = NEW.id from actual trigger row
READS = corretores
WRITES = audit_trail
RLS BYPASS MATERIAL = YES
TARGET DIRECT EXECUTE = NONE
FAILURE IMPACT = loss/incompleteness of critical audit record
RESIDUAL = runtime audit-failure behavior not hostile-tested
FINDING = ACCEPTABLE WITH RESIDUAL RISK
FUTURE = retain DEFINER; remove unnecessary direct authenticated/service EXECUTE
~~~

### 012 — audit_trail_log_empresas_governance()

~~~text
TRIGGER = AFTER INSERT/UPDATE/DELETE / ROW / empresas
CURRENT = DEFINER postgres / search_path public
DIRECT EXECUTE = PUBLIC false / anon false / authenticated true / service_role true
TARGET = DEFINER
ELEVATION = governance audit must persist independently of caller audit privileges
ACTOR = audit_trail_actor_context() -> auth.uid() -> corretores
TENANT = empresa row id
OBJECT = actual OLD/NEW trigger row
READS = transitive corretores
WRITES = audit_trail
TRANSITIVE = audit_trail_actor_context()
RLS BYPASS MATERIAL = YES
TARGET DIRECT EXECUTE = NONE
FAILURE IMPACT = missing tenant-governance audit evidence
FINDING = ACCEPTABLE WITH RESIDUAL RISK
~~~

### 013 — audit_trail_log_lista_visibilidade_acl()

~~~text
TRIGGER = AFTER INSERT/UPDATE/DELETE / ROW / lista_visibilidade
CURRENT = DEFINER postgres / search_path public
DIRECT EXECUTE = PUBLIC false / anon false / authenticated true / service_role true
TARGET = DEFINER
ELEVATION = list-ACL governance requires guaranteed audit_trail INSERT
ACTOR = audit_trail_actor_context() / auth.uid()
TENANT = trigger-row empresa_id
OBJECT = trigger-row lista_visibilidade.id
READS = transitive corretores
WRITES = audit_trail
TRANSITIVE = audit_trail_actor_context()
RLS BYPASS MATERIAL = YES
TARGET DIRECT EXECUTE = NONE
FAILURE IMPACT = loss of visibility-ACL governance audit evidence
FINDING = ACCEPTABLE WITH RESIDUAL RISK
~~~

### 014 — audit_trail_log_listas_governance()

~~~text
TRIGGER = AFTER INSERT/UPDATE/DELETE / ROW / listas
CURRENT = DEFINER postgres / search_path public
DIRECT EXECUTE = PUBLIC false / anon false / authenticated true / service_role true
TARGET = DEFINER
ELEVATION = list-governance side effect requires privileged audit persistence
ACTOR = audit_trail_actor_context() / auth.uid()
TENANT = trigger-row empresa_id
OBJECT = trigger-row lista id
READS = transitive corretores
WRITES = audit_trail
TRANSITIVE = audit_trail_actor_context()
RLS BYPASS MATERIAL = YES
TARGET DIRECT EXECUTE = NONE
FAILURE IMPACT = governance changes without corresponding audit trail
FINDING = ACCEPTABLE WITH RESIDUAL RISK
~~~

### 015 — audit_trail_log_times_governance()

~~~text
TRIGGER = AFTER INSERT/UPDATE/DELETE / ROW / times
CURRENT = DEFINER postgres / search_path public
DIRECT EXECUTE = PUBLIC false / anon false / authenticated true / service_role true
TARGET = DEFINER
ELEVATION = team-governance audit must not depend on ordinary caller audit privileges
ACTOR = audit_trail_actor_context() / auth.uid()
TENANT = trigger-row empresa_id
OBJECT = trigger-row time id
READS = transitive corretores
WRITES = audit_trail
TRANSITIVE = audit_trail_actor_context()
RLS BYPASS MATERIAL = YES
TARGET DIRECT EXECUTE = NONE
FAILURE IMPACT = missing privileged team-governance evidence
FINDING = ACCEPTABLE WITH RESIDUAL RISK
~~~

Audit-family governing conclusion:

~~~text
AUDIT TRIGGER MUST FIRE
!=
CLIENT MUST HAVE EXECUTE ON TRIGGER FUNCTION

authenticated has no INSERT on audit_trail.
Therefore audit persistence requires the privileged trigger boundary.
Direct authenticated/service EXECUTE is not target-required.
~~~

### 030 — f1_02_b4_validate_lista_visibilidade_target()

~~~text
TRIGGER = BEFORE INSERT/UPDATE / ROW / lista_visibilidade
CURRENT = DEFINER postgres / search_path public
DIRECT EXECUTE = PUBLIC false / anon false / authenticated false / service_role true
TARGET = DEFINER
ELEVATION = authoritative relational/tenant invariant evaluation
CALLER AUTHORITY SUFFICIENT = NO
TENANT = NEW.empresa_id
OBJECT BINDING =
  lista_id -> listas.id + same empresa
  corretor target -> corretores.id + same empresa + active
  time target -> times.id + same empresa + active
READS = listas, corretores, times
WRITES = none
RLS DEPENDENCY = target invariant must NOT depend on caller-visible RLS
RLS BYPASS MATERIAL = YES
TARGET DIRECT EXECUTE = NONE
FAILURE IMPACT = invalid/cross-tenant visibility relationship or caller-dependent false rejection
RESIDUAL = runtime negative testing outside D
FINDING = ACCEPTABLE WITH RESIDUAL RISK
FUTURE = retain DEFINER; remove unnecessary service_role direct EXECUTE
~~~

Target principle:

~~~text
DATABASE INTEGRITY =
AUTHORITATIVE DATABASE ROWS,
NOT CALLER-VISIBLE ROWS
~~~

### 075 — mesa_cliente_financeiro_assert_integridade()

~~~text
TRIGGERS = 4 BEFORE INSERT/UPDATE row triggers
TABLES =
  mesa_cliente_fluxo_operacoes
  mesa_cliente_fluxo_parcelas
  mesa_cliente_politica_premio_faixas
  mesa_cliente_politicas_financeiras
CURRENT = DEFINER postgres / search_path public
DIRECT EXECUTE = PUBLIC false / anon true / authenticated true / service_role true
TARGET = DEFINER
ELEVATION = protected cross-table tenant/object integrity
CALLER AUTHORITY SUFFICIENT = NO
ACTOR = auth.uid() only for atualizado_por; actor is not tenant authority
TENANT = NEW.empresa_id cross-checked against trusted referenced rows
OBJECT BINDING =
  empreendimento
  simulation
  financial policy
  source/destination parcel
  all must match tenant and relevant simulation/empreendimento
READS =
  information_schema.columns
  empreendimentos
  mesa_simulacoes
  mesa_cliente_politicas_financeiras
  mesa_cliente_fluxo_parcelas
EXTERNAL WRITES = none
NEW ROW MUTATIONS =
  updated_at
  atualizado_por
  visivel_cliente
  pode_receber_vpl
  pode_receber_antecipacao
  pode_receber_postergacao
RLS DEPENDENCY = authoritative validation must not depend on caller RLS
RLS BYPASS MATERIAL = YES
TARGET DIRECT EXECUTE = NONE
FAILURE IMPACT =
  cross-tenant financial corruption
  simulation/empreendimento mismatch
  invalid parcel relationships
  internal financial semantics exposed to customer projection
RESIDUAL = no D runtime assurance
FINDING = PLANNED FUTURE PR
FUTURE = preserve DEFINER; remove anon/authenticated/service direct EXECUTE
~~~

Current anon EXECUTE has no trigger-firing requirement and is an ACL issue independent of function mode.

### 111 — pme_set_updated_at()

~~~text
TRIGGERS = 5 BEFORE UPDATE row triggers
TABLES =
  pme_cadence_steps
  pme_cadences
  pme_call_scripts
  pme_lead_message_state
  pme_message_templates
CURRENT = DEFINER postgres / search_path public, pg_temp
DIRECT EXECUTE = PUBLIC false / anon false / authenticated false / service_role false
TARGET = INVOKER
CALLER AUTHORITY SUFFICIENT = YES
PRIVILEGED BOUNDARY REQUIRED = NO
ELEVATION = NONE
ROW AUTHORITY = same NEW row already admitted for UPDATE
READS = none
EXTERNAL WRITES = none
ROW MUTATION = NEW.updated_at := now()
TRANSITIVE = none
RLS BYPASS MATERIAL = NO
TARGET DIRECT EXECUTE = NONE
FAILURE IMPACT = stale/inaccurate updated_at only
FINDING = PLANNED FUTURE PR
FUTURE = bounded conversion to SECURITY INVOKER; preserve no-direct-EXECUTE posture
~~~

The versioned PME hardening migration records that direct EXECUTE is unnecessary for trigger firing.

### 130 — t3_guard_admin_password_reset_lease()

~~~text
TRIGGERS = 3 BEFORE INSERT/UPDATE/DELETE row triggers
TABLES = admins, corretores, times
CURRENT = DEFINER postgres / search_path pg_catalog
DIRECT EXECUTE = PUBLIC false / anon false / authenticated false / service_role false
TARGET = DEFINER
CALLER AUTHORITY SUFFICIENT = NO
PRIVILEGED BOUNDARY REQUIRED = YES
ELEVATION =
  internal authority-table access
  transactional concurrency fence
  lease unique-index arbitration
ACTOR = auth.uid()
TRUSTED CONTEXT = current_setting('fechai.t3_admin_password_reset_context', true)
OBJECT BINDING =
  admins/corretores OLD/NEW user_id <-> lease target_user_id
  times OLD/NEW id <-> lease authority_time_id
READS = t3_admin_password_reset_leases
WRITES = transactional INSERT/DELETE probes on t3_admin_password_reset_leases
RLS DEPENDENCY = lease authority intentionally independent of ordinary caller RLS
RLS BYPASS MATERIAL = YES
LEASE TABLE =
  RLS enabled
  FORCE RLS true
  no anon/authenticated/service_role table privilege
TARGET DIRECT EXECUTE = NONE
SEARCH_PATH = pg_catalog only / target-aligned
FAILURE IMPACT =
  security-fence failure
  password-reset authority race
  concurrent mutation not serialized against active lease
  possible unauthorized authority-object mutation
RESIDUAL = concurrency/runtime hostile assurance not authorized in D
FINDING = ACCEPTABLE WITH RESIDUAL RISK
FUTURE = preserve DEFINER/no-direct-EXECUTE; independently runtime-assure concurrency
~~~

Current postgres owner has BYPASSRLS; the function-body fence is therefore the material boundary.

## 5. Eighteen-trigger coverage matrix

| # | Trigger | Table | Func | Timing | Events | Row | Enabled | Invariant/side effect | Tenant/security material | Target |
|---:|---|---|---:|---|---|---|---|---|---|---|
| 1 | trg_audit_trail_corretores_critical_update | corretores | 011 | AFTER | UPDATE | ROW | YES | critical-field audit | YES / YES | KEEP ENABLED |
| 2 | trg_audit_trail_empresas_governance | empresas | 012 | AFTER | I/U/D | ROW | YES | tenant governance audit | YES / YES | KEEP ENABLED |
| 3 | trg_audit_trail_lista_visibilidade_acl | lista_visibilidade | 013 | AFTER | I/U/D | ROW | YES | ACL governance audit | YES / YES | KEEP ENABLED |
| 4 | trg_audit_trail_listas_governance | listas | 014 | AFTER | I/U/D | ROW | YES | list governance audit | YES / YES | KEEP ENABLED |
| 5 | trg_audit_trail_times_governance | times | 015 | AFTER | I/U/D | ROW | YES | team governance audit | YES / YES | KEEP ENABLED |
| 6 | trg_f1_02_b4_lista_visibilidade_target_integrity | lista_visibilidade | 030 | BEFORE | I/U | ROW | YES | relational target integrity | YES / YES | KEEP ENABLED |
| 7 | trg_mcfo_assert_integridade | mesa_cliente_fluxo_operacoes | 075 | BEFORE | I/U | ROW | YES | financial tenant integrity | YES / YES | KEEP ENABLED |
| 8 | trg_mcfp_assert_integridade | mesa_cliente_fluxo_parcelas | 075 | BEFORE | I/U | ROW | YES | simulation/tenant/empreendimento integrity | YES / YES | KEEP ENABLED |
| 9 | trg_mcppf_assert_integridade | mesa_cliente_politica_premio_faixas | 075 | BEFORE | I/U | ROW | YES | policy/company integrity | YES / YES | KEEP ENABLED |
| 10 | trg_mcpf_assert_integridade | mesa_cliente_politicas_financeiras | 075 | BEFORE | I/U | ROW | YES | empreendimento/company integrity | YES / YES | KEEP ENABLED |
| 11 | trg_pme_cadence_steps_updated_at | pme_cadence_steps | 111 | BEFORE | UPDATE | ROW | YES | updated_at maintenance | NO / LOW | KEEP; FUNCTION TARGET INVOKER |
| 12 | trg_pme_cadences_updated_at | pme_cadences | 111 | BEFORE | UPDATE | ROW | YES | updated_at maintenance | NO / LOW | KEEP; FUNCTION TARGET INVOKER |
| 13 | trg_pme_call_scripts_updated_at | pme_call_scripts | 111 | BEFORE | UPDATE | ROW | YES | updated_at maintenance | NO / LOW | KEEP; FUNCTION TARGET INVOKER |
| 14 | trg_pme_lead_message_state_updated_at | pme_lead_message_state | 111 | BEFORE | UPDATE | ROW | YES | updated_at maintenance | NO / LOW | KEEP; FUNCTION TARGET INVOKER |
| 15 | trg_pme_message_templates_updated_at | pme_message_templates | 111 | BEFORE | UPDATE | ROW | YES | updated_at maintenance | NO / LOW | KEEP; FUNCTION TARGET INVOKER |
| 16 | trg_t3_fence_admin_password_reset_admins | admins | 130 | BEFORE | I/U/D | ROW | YES | password-reset concurrency fence | AUTHORITY / CRITICAL | KEEP ENABLED |
| 17 | trg_t3_fence_admin_password_reset_corretores | corretores | 130 | BEFORE | I/U/D | ROW | YES | password-reset concurrency fence | AUTHORITY / CRITICAL | KEEP ENABLED |
| 18 | trg_t3_fence_admin_password_reset_times | times | 130 | BEFORE | I/U/D | ROW | YES | password-reset concurrency fence | AUTHORITY / CRITICAL | KEEP ENABLED |

~~~text
TRIGGER INSTANCE COVERAGE = 18 / 18
~~~

## 6. Target aggregates

~~~text
D FUNCTIONS = 9
D TRIGGER INSTANCES = 18

TARGET DEFINER = 8
TARGET INVOKER = 1
TARGET NOT_DETERMINED = 0

TARGET DEFINER =
011,012,013,014,015,030,075,130

TARGET INVOKER =
111
~~~

## 7. Direct EXECUTE target classification

~~~text
TRIGGER FIRING AUTHORITY
!=
DIRECT FUNCTION EXECUTE SURFACE
!=
TABLE DML AUTHORITY

DIRECT CLIENT EXECUTE TARGET-REQUIRED = 0
DIRECT CLIENT EXECUTE TARGET-NOT-REQUIRED = 9
DIRECT CLIENT EXECUTE NOT_DETERMINED = 0

TARGET DIRECT PRINCIPALS FOR ALL NINE =
PUBLIC NO
anon NO
authenticated NO
service_role NO
~~~

Current ACL deltas to future target:
- 011–015: authenticated and service_role currently EXECUTE.
- 030: service_role currently EXECUTE.
- 075: anon, authenticated and service_role currently EXECUTE.
- 111 and 130 already have no direct client EXECUTE.

No GRANT/REVOKE was executed in D.

## 8. Trigger-specific target policy

~~~text
011–015 AUDIT:
base DML authorized independently
+ actor from trusted auth/DB context
+ tenant/object from OLD/NEW row
+ audit persistence independent of caller audit privileges
+ no direct API
=> DEFINER

030 RELATIONAL INTEGRITY:
evaluate authoritative referenced rows, independent of caller RLS visibility
=> DEFINER

075 MESACLIENTE TENANT INTEGRITY:
cross-validate NEW tenant/object identifiers against protected authoritative relations before commit
=> DEFINER

111 TECHNICAL TIMESTAMP:
only mutate own NEW row and require no external privilege
=> INVOKER

130 T3 SECURITY FENCE:
privileged internal lease access + exact auth/context/target binding + transactional uniqueness arbitration + no direct client invocation
=> DEFINER
~~~

Preserve:

~~~text
SECURITY DEFINER != AUTHORIZATION
SECURITY INVOKER != AUTOMATICALLY SAFE
TRIGGER FIRING AUTHORITY != DIRECT FUNCTION EXECUTE SURFACE != TABLE DML AUTHORITY
search_path PRESENT != search_path SAFE
~~~

## 9. Findings and residuals

PLANNED FUTURE PR:
- 111 is unnecessarily SECURITY DEFINER.
- 011–015 have direct authenticated/service EXECUTE not target-required.
- 030 has direct service_role EXECUTE not target-required.
- 075 has unnecessary anon/authenticated/service_role EXECUTE.

ACCEPTABLE WITH RESIDUAL RISK:
- 011–015 privileged audit persistence justified; runtime audit sink failure behavior not exercised.
- 030 authoritative relational integrity justified; runtime negative/cross-tenant proof remains outside D.
- 075 protected authoritative tenant-integrity reads justified; hostile runtime assurance not performed.
- 130 internal lease/concurrency boundary materially requires DEFINER; runtime concurrency stress not performed.
- search_path=public on 011–015/030/075 is less strict than 130 pg_catalog; client roles lack CREATE in public and observed sensitive relations are schema-qualified. This is hardening, not a D mode-classification blocker.

NOT RELEVANT TO THIS SCOPE:
- M2-04C 68/40/5 distribution remains unchanged; these nine trigger functions are outside those 113 rows.

No REQUIRED IN THIS PR finding remains for D evidence/classification.

## 10. Future bounded implementation backlog — design only

| Unit | Objective | Principal risk | Exact scope | Acceptance evidence | Rollback | Specialist |
|---|---|---|---|---|---|---|
| D-01 | Convert PME timestamp helper to INVOKER | unnecessary privilege amplification | pme_set_updated_at() | live prosecdef=false; five triggers enabled; timestamp regression | restore prior DEFINER | Backend/Data |
| D-02 | Remove direct client EXECUTE from audit trigger funcs | callable privileged trigger-only functions | 011–015 ACL only | no PUBLIC/anon/auth/service direct EXECUTE; trigger integration works | restore ACL | Backend/Data |
| D-03 | Remove service direct EXECUTE from relational invariant helper | unnecessary reachability | 030 ACL only | ACL catalog + valid/invalid visibility tests | restore service EXECUTE | Backend/Data |
| D-04 | Remove anon/auth/service direct EXECUTE from Mesa trigger helper | privileged trigger-function exposure | 075 ACL only | ACL catalog + financial RPC regression | restore prior ACL | Backend/Data |
| D-05 | Optional DEFINER search_path hardening | future object-resolution ambiguity | 011–015,030,075 | exact bodies + regression + schema CREATE ACL snapshot | restore proconfig | Backend/Data |
| D-06 | Audit-side-effect runtime assurance | audit loss during authorized DML | 011–015 + audit_trail | each trigger event emits audit | rollback future remediation only | Backend/Data QA |
| D-07 | Relational/tenant hostile assurance | cross-tenant object corruption | 030 + 075 | negative cross-tenant/hidden-reference tests | rollback relevant future patch | AppSec |
| D-08 | T3 concurrency assurance | race bypasses lease fence | 130 + lease unique indexes | concurrent serialization/denial tests | rollback future T3 change | Backend/Data + AppSec |

One principal risk per future unit. No migration or implementation PR was created by D.

## 11. Final authority conclusions

011–015 remain DEFINER because authenticated lacks INSERT on audit_trail and audit events must survive caller privilege boundaries.

030 remains DEFINER because RLS-filtered existence is not authoritative database integrity truth.

075 remains DEFINER because protected MesaCliente referential checks must enforce cross-tenant consistency independently of caller-visible rows.

111 becomes INVOKER because NEW.updated_at = now() requires no privileged access, RLS bypass, authority derivation or invariant lookup.

130 remains DEFINER because the fence must access the internal lease authority independently of ordinary DML callers and rely on transactional uniqueness arbitration.

## 12. Final M2-04D verdict

~~~text
STS-M2-04D =
COMPLETE / ACCEPTED TRIGGER AUTHORITY CONTRACT

D FUNCTIONS = 9
D TRIGGER INSTANCES = 18
TARGET DEFINER = 8
TARGET INVOKER = 1
TARGET NOT_DETERMINED = 0

DIRECT CLIENT EXECUTE TARGET-REQUIRED = 0
DIRECT CLIENT EXECUTE TARGET-NOT-REQUIRED = 9
DIRECT CLIENT EXECUTE NOT_DETERMINED = 0

18 / 18 TRIGGER INSTANCES COVERED

TARGET DEFINER =
011
012
013
014
015
030
075
130

TARGET INVOKER =
111

MATERIAL_DRIFT = NO

IMPLEMENTATION = NOT PERFORMED
ALTER FUNCTION = NO
TRIGGER ALTER/CREATE/DROP = NO
GRANT/REVOKE = NO
RLS/POLICY CHANGE = NO
DATABASE MUTATION = NO

M2-04C = UNCHANGED
M2-04E = NOT_EXECUTED
M2-04F = NOT_EXECUTED

RUNTIME HOSTILE TESTING = NOT_PERFORMED
APPSEC ASSURANCE = NOT_PERFORMED

M2-04D ANALYSIS COMPLETE
!= TRIGGER REMEDIATION IMPLEMENTED
!= CONTROL PROVEN EFFECTIVE
!= SECURITY GO

READY = NOT_AUTHORIZED
MERGE = NOT_AUTHORIZED
DEPLOY = NOT_AUTHORIZED
SECURITY_GO = NOT_GRANTED
~~~
