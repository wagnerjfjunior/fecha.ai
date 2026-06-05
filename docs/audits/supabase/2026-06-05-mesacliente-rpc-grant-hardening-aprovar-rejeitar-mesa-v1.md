# FECH.AI - PR #63 - grant-hardening aprovar_rejeitar_mesa v1

Nota editorial: arquivo regravado em ASCII limpo para remover risco de caracteres ocultos ou bidirecionais.

**Data:** 2026-06-05
**Status:** `CORRECAO_TECNICA_VERSIONADA / NAO_EXECUTADA_NO_SUPABASE`
**Tipo:** Classe A / grant-hardening / single-rpc
**RPC alvo:** `public.aprovar_rejeitar_mesa`

## 1. Escopo

A PR #63 cria uma correcao tecnica controlada, minima e de baixo blast radius para remover exposicao indevida de `PUBLIC` e `anon` na RPC `public.aprovar_rejeitar_mesa`.

A correcao esta limitada ao arquivo de migration `supabase/migrations/20260605150000_mesacliente_revoke_anon_public_aprovar_rejeitar_mesa.sql` e nao altera body de function, owner, `SECURITY DEFINER`, `search_path`, tabelas, RLS, FORCE RLS, policies, frontend, parser, motor financeiro ou outras RPCs.

## 2. Declaracao de nao execucao

- A correcao tecnica foi criada no repositorio, mas nao foi executada no Supabase por esta PR.
- O Supabase real nao foi alterado por Codex.
- Nenhum `db push`, chamada RPC, query em producao, teste Supabase, credencial, dado real ou segredo foi usado nesta PR.

## 3. Comportamento esperado da migration

A migration deve:

1. resolver `public.aprovar_rejeitar_mesa` por `pg_proc`, sem chutar tipos;
2. ser replay-safe em banco limpo criado apenas pelas migrations do repositorio;
3. fazer no-op com `RAISE NOTICE` quando `public.aprovar_rejeitar_mesa` nao existir neste banco/migration replay;
4. abortar com `RAISE EXCEPTION` se encontrar mais de 1 overload;
5. revogar `EXECUTE` de `PUBLIC` quando a function existir;
6. revogar `EXECUTE` de `anon` quando a function existir;
7. garantir `EXECUTE` para `authenticated` quando a function existir;
8. nao alterar nenhum outro objeto.

A correcao real so tera efeito em ambiente onde `public.aprovar_rejeitar_mesa` exista. Em banco limpo sem essa function, o comportamento esperado e no-op com aviso, preservando o replay das migrations versionadas.

## 4. Testes negativos obrigatorios antes de merge

A PR deve permanecer bloqueada ate que os testes negativos abaixo sejam executados em staging/clone com dataset sintetico, evidencias sanitizadas e GO operacional:

1. `anon` deve falhar ao chamar `aprovar_rejeitar_mesa`;
2. `authenticated` sem gestor deve falhar;
3. gestor de outra empresa deve falhar;
4. acao invalida deve falhar;
5. simulacao inexistente nao deve alterar nada;
6. usuario autorizado deve continuar funcionando apenas no escopo permitido.

## 5. Rollback

Rollback operacional precisa ser aprovado antes de qualquer execucao.

Rollback documental, se a migration ainda nao tiver sido aplicada, consiste em reverter/remover esta documentacao e a migration criada nesta PR.

Se a migration for aplicada indevidamente, o rollback SQL manual esta documentado como comentario dentro da propria migration e nao e executado automaticamente.

## 6. Gate de revisao

Antes de merge, esta PR precisa de revisao GPT 0, GPT 1, GPT 3 e GPT 4, alem das evidencias de testes negativos em staging/clone.
