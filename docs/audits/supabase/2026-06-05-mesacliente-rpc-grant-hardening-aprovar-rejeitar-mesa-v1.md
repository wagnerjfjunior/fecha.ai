# FECH.AI - PR #63 - grant-hardening aprovar_rejeitar_mesa v1

Nota editorial: arquivo regravado em ASCII limpo para remover risco de caracteres ocultos ou bidirecionais.

**Data:** 2026-06-05
**Status:** `CORRECAO_TECNICA_VERSIONADA / TESTES_LOCAIS_PASS / NAO_EXECUTADA_NO_SUPABASE`
**Tipo:** Classe A / grant-hardening / single-rpc
**RPC alvo:** `public.aprovar_rejeitar_mesa`

## 1. Escopo

A PR #63 cria uma correcao tecnica controlada, minima e de baixo blast radius para remover exposicao indevida de `PUBLIC` e `anon` na RPC `public