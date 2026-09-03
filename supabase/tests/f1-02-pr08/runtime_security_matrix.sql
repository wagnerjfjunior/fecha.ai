-- FECH.AI — F1-02 / J4 / PR-08
-- READ_ONLY preflight aggregator. VERSIONED ONLY; NOT EXECUTED by PR-08 implementation.
-- This file intentionally performs no DDL or business DML.
\set ON_ERROR_STOP on
\echo 'FECH.AI PR-08 read-only preflight: B2'
\ir ../f1-02-b2/direct_crm_write_boundary.sql
\echo 'FECH.AI PR-08 read-only preflight: B3'
\ir ../f1-02-b3/direct_funnel_history_insert_boundary.sql
\echo 'FECH.AI PR-08 read-only preflight: B4'
\ir ../f1-02-b4/list_acl_tenant_integrity.sql
\echo 'FECH.AI PR-08 read-only preflight: PR-07'
\ir ../f1-02-pr07/funnel_reads_crm_payloads.sql
\echo 'FECH.AI PR-08 read-only preflight complete. Runtime/rollback evidence remains separate.'
