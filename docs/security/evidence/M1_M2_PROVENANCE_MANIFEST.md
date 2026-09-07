# FECH.AI — M1/M2 Provenance Manifest

**Status:** `DOCUMENTATION_PROVENANCE_HARDENING / CURRENT_DECISIONS_RECONSTRUCTIBLE / RAW_SOURCE_FORENSICS_PARTIAL`  
**Repository:** `wagnerjfjunior/fecha.ai`  
**Hardening base:** `dd118baa89b68281bbd7c8df43c8e24c0e9b66bf`  
**Mutation class:** `DOCUMENTATION_ONLY`

## 1. Purpose

This manifest hardens M1/M2 evidence provenance without replaying closed gates and without turning the repository into a chat archive.

It answers:

```text
Can the current M1/M2 state, Product Authority decisions,
accepted evidence boundaries, residuals and next-safe program state
be reconstructed from GitHub without conversation history?
```

Current answer:

```text
CURRENT OPERATIONAL / DECISION RECONSTRUCTIBILITY = PASS
RAW SOURCE FORENSIC REPRODUCIBILITY = PARTIAL
```

This distinction is deliberate.

## 2. Repository admission rule — anti-noise / anti-chat-dump

A raw source packet may be versioned only when all applicable conditions below are satisfied:

```text
1. DECISION-GRADE:
   it contains material evidence not already preserved equivalently
   by a canonical durable artifact;

2. PROVENANCE-BOUND:
   an historical SHA-256 or equivalent exact fingerprint can be matched,
   or the limitation is explicitly classified before admission;

3. SANITIZED:
   no secrets, credentials, JWTs, passwords, service-role material,
   customer PII, real database payloads or unnecessary personal data;

4. NON-DUPLICATIVE:
   it is not a redundant copy of an existing durable artifact;

5. BOUNDED:
   it maps to an exact M1/M2 decision/evidence obligation;

6. NON-BOOTSTRAP:
   historical raw evidence does not become a normal bootstrap source.
```

Do **not** version merely because content existed in a conversation:

```text
chat transcripts
salutations / conversational filler
prompts that only restate an existing contract
assistant reasoning
tool chatter
duplicate handoffs
intermediate drafts superseded by durable final evidence
screenshots when exact textual evidence exists
raw packets whose material evidence is already fully preserved
and whose only additional value is conversational history
```

Repository principle:

```text
GITHUB = durable product truth + decision-grade evidence
GITHUB != conversation warehouse
```

## 3. Evidence classes

| Class | Meaning | Repository treatment |
|---|---|---|
| `CANONICAL_DURABLE` | Current accepted material decision/evidence is fully versioned | Keep as authority |
| `STRUCTURED_DURABLE` | Row/matrix evidence is fully versioned | Keep as authority |
| `HASH_BOUND_RAW_NOT_VERSIONED` | Original packet has recorded digest but raw text is outside GitHub | Do not add unless unique evidence is missing |
| `RAW_SOURCE_NOT_HASH_BOUND` | Historical manual source has no exact recorded digest | Do not present later recovery as exact historical source without qualification |
| `LIVE_EVIDENCE_RECORDED` | Material live observations are durably summarized with exact capture boundaries | Preserve record; do not dump query transcripts by default |
| `DO_NOT_VERSION` | Conversational/redundant/non-probative material | Exclude |

## 4. Critical M1/M2 provenance matrix

| Decision / slice | Durable GitHub evidence | Blob / exact object | Product Authority | Raw-source status | Reconstruction from GitHub |
|---|---|---|---|---|---|
| M1 / F1-02 close-out | `docs/security/evidence/F1-02_REMEDIATION_MASTER_PLAN.md` | `e7022ad4efdda4428e9d8261fdd666b47c914215` | RECORDED | `RAW_SOURCE_NOT_HASH_BOUND` for final MANUAL_COPY_PASTE specialist gates | PASS for state/decision; partial for verbatim forensics |
| M2-01 | `2026-09-04-sts-m2-01-database-canonicality-matrix.md` | `281fe7372882310e186abfd068b4b4f1baab011d` | RECORDED | Phase A `c08cff0ff22e4d172fd80a061131a49a8299645ec91819e8cdbd69613f82e7ab`; Phase B/final delta `6f9b6ec784ebef206c399cea630ab9ea55f87137697c224e1682ef242cf6ba11` — raw not GitHub objects | PASS |
| M2-02 | `2026-09-05-sts-m2-02-database-authority-map.md` | `ec723587ee003427e592873efcc2fe4ef5aae615` | RECORDED | Backend/Data `cc671280dc044f4d330c131dc5854b5aec19ebaadf7a2ff64da43bb62a33cb6b`; Architecture `741014b5b75a8b1416b93c4e8af17d7024945a608f406cbe9428b6552e30a703`; AppSec `6a69557f53df293be1f6e7364b5a8a581cf67ec5a95f2cc6f53fc795eda96a52` | PASS |
| M2-03 | `2026-09-05-sts-m2-03-index-acl-contradictions.md` | `3d5cf2d890e4c5f7b37d9f01a926a8a50d0f8cc9` | RECORDED | Backend/Data fingerprint `b5a41bf04495ee9783cd70a1d08926611c8c78ecfb644f6178fba161207cb52f`; raw source not versioned | PASS |
| M2-04B1 | `2026-09-05-sts-m2-04b1-routine-authority-policy.md` | `15e771e99ce3e424ba4a869a00d4965bed733fc3` | RECORDED | packet `FECHAI-STS-M2-04B1-ROUTINE-AUTHORITY-POLICY-CORE`; SHA-256 `8171310f4101831ba34623dac9aff37b13e04aeb02f81808fc163d693cf801bf` | PASS |
| M2-04B2 | `2026-09-05-sts-m2-04b2-high-risk-routine-authority-classification.md` | `bfa43f6936b2a381552dbb95f5306f13069142af` | RECORDED | packet SHA-256 `36f90006d772404cd8d2fd297a2a70ab2ff452f8b1b17491a734f7cff68cb2ad` | PASS |
| M2-04B3 | narrative + canonical 113×40 CSV | narrative `96d31bb3c471ddbc606f391aff13cb7674358e8b`; CSV `cf3baa6e5a6ab6465688de8f6af43cba7c27d3bd` | RECORDED | historical packets retained by digest; current structured decision fully versioned | STRONG PASS |
| M2-04C1 | SFJM live RLS/DML evidence record | `docs/sfjm/EVIDENCE_FRESHNESS.md` | RECORDED | live evidence record; no default requirement to archive raw query transcript | PASS for accepted material result |
| M2-04C2 | SFJM C2 specialist/evidence record | source packet SHA-256 `ccf108437f1d84ceac29095ecb1f86a3a63c64d5278d8eb17c02588d3a633afa` | RECORDED | `HASH_BOUND_RAW_NOT_VERSIONED` | PASS for accepted material result |
| M2-04C3 | canonical 57-row adjudication CSV | `716c23d5f549eb465f3393cdfc5989dda82b69a7` | RECORDED | source SHA-256 `0e6c40a3cd515219fb6b24d5f0aaf10e63291d19da485d5e946c47fbb08d88d5`; final structured result versioned | STRONG PASS |
| M2-04C4 | **candidate standalone durable contract in this hardening PR** + SFJM | `docs/security/evidence/2026-09-06-sts-m2-04c-c4-target-rls-dml-contract.md` + existing SFJM | RECORDED | source SHA-256 `8bec01816fe72c0b9bb6605435b3f5e3cd537572929753fd93ab5949dc113125`; raw source remains noncanonical | CURRENT MAIN: reconstructible via SFJM; standalone durability becomes PASS only after merge |
| M2-04D | `2026-09-06-sts-m2-04d-trigger-authority-classification.md` | `7fdc63a95d81661598937aa0bdfa654bcb9db66a` | RECORDED | source SHA-256 `6927b61338555fef95cc25892bb6097e815839b53bc217e0229084c5e5220389`; complete material 9/9 + 18/18 surface already durable | STRONG PASS |
| M2-04E | `2026-09-06-sts-m2-04e-architecture-synthesis-acceptance.md` | `07365cae5a353bd2407512ddde0d3d4cf880352f` | RECORDED | synthesis built predominantly from exact versioned `INTEGRAL_READ` sources; no unique raw packet required | STRONG PASS |
| M2-05 | `2026-09-07-sts-m2-05-database-contract-map.md` | `8b2875e1bc095329482de095028ed31b37091d63` | RECORDED BY PRODUCT AUTHORITY / MERGED CANONICAL MAIN via PR #195 @ `d6953ea3071ada55fbcd97f21c848f5c6424ca3f` | accepted READ_ONLY result is preserved at contract/category level; a separate verbatim raw-run transcript is not versioned | PASS for accepted contract-level state; verbatim raw-run forensics remain partial |

### 4.1 M2-05 canonical publication anchor — 2026-09-07

~~~text
PR #195 = MERGED / CLOSED
reviewed candidate head = 643fb532e2860bdc53cbbddef529e3b9ed4e8709
merge commit = d6953ea3071ada55fbcd97f21c848f5c6424ca3f
canonical main after merge = d6953ea3071ada55fbcd97f21c848f5c6424ca3f
M2-05 durable artifact blob = 8b2875e1bc095329482de095028ed31b37091d63
~~~

This canonical publication records the already accepted M2-05 contract. It does not establish implementation completion, runtime/AppSec assurance, M2-06 execution authority or Security Go.

## 5. Raw-source disposition

### 5.1 Raw packets that are **not required** for current operation

For M2-01/02/03, B1/B2, C2/C3, D and E, current accepted material decisions are durably represented in GitHub.

Their raw historical source packets are therefore:

```text
FORENSIC_PROVENANCE_OPTIONAL
NOT_BOOTSTRAP
NOT_CURRENT_AUTHORITY
NOT_REQUIRED_FOR_ROADMAP_CONTINUATION
```

Do not add them merely to make the repository larger.

### 5.2 M1 historical manual-copy source limitation

M1 final independent verdicts are durably recorded, but the final source transport was `MANUAL_COPY_PASTE` and the current historical block does not bind each verbatim source to an exact SHA-256.

Therefore:

```text
M1 CURRENT DECISION = RECONSTRUCTIBLE
M1 RAW VERBATIM SOURCE = NOT EXACTLY HASH-BOUND
RETROACTIVE EXACTNESS FABRICATION = FORBIDDEN
```

A later recovered text may be kept outside canonical GitHub or admitted only as explicitly non-exact historical context unless exact provenance can be independently established.

### 5.3 C4 structural gap

Before this hardening, M2-04C4 had a recorded source packet/hash and material SFJM result but no standalone durable evidence artifact.

This hardening **proposes closure** of that structural documentation gap by adding:

`docs/security/evidence/2026-09-06-sts-m2-04c-c4-target-rls-dml-contract.md`

It does not alter the accepted C4 decision.

## 6. Historical lifecycle provenance exception

PR #183 remains a deliberate historical exception:

```text
historical exact-head merge authorization = NOT_RECOVERED
later Product Authority ratification = RECORDED
retroactive authorization fabrication = NO
gate replay = NOT_REQUIRED absent material contradiction
```

This is compliant with `NO_RETROACTIVE_GATE_REPLAY`.

## 7. Current audit verdict

```text
CRITICAL M1/M2 DECISION DURABILITY = PASS
CURRENT STATE RECONSTRUCTIBILITY FROM GITHUB = PASS
PRODUCT AUTHORITY TRACEABILITY = PASS
STRUCTURED B3/C3 EVIDENCE PRESERVATION = PASS
C4 STANDALONE DURABILITY = CANDIDATE_UNTIL_THIS HARDENING IS MERGED
RAW SPECIALIST SOURCE FORENSICS = PARTIAL
ROADMAP BLOCKER = NO
SECURITY GO = NOT_GRANTED
```

## 8. Invalidation / maintenance rule

Update this manifest only when a material event changes one of:

```text
canonical durable artifact
recorded source fingerprint
Product Authority decision
evidence availability classification
historical provenance exception
reconstructibility verdict
```

Do not update it for ordinary PR lifecycle, new conversations, salutations, repeated prompts or non-material documentation churn.
