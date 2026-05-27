# FECH.AI / MesaCliente — Fase 20D.4
# Status — Migration da RPC adaptadora read-only

## 1. Status

```text
Status: BLOQUEADA PELA CAMADA DE SEGURANÇA DA FERRAMENTA / NÃO COMMITADA
Data: 2026-05-27
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration criada no repositório: NÃO
Migration executada no Supabase: NÃO
DDL executado: NÃO
DML executado: NÃO
```

## 2. Contexto

Após aprovação operacional da 20D.3, foi preparada a migration para criar a RPC read-only:

```text
public.mesa_cliente_montar_payload_agenda_canonica(p_simulacao_id uuid)
```

Objetivo da RPC:

```text
Montar payload canônico para 4A/4B a partir de mesa_fluxo_pagamentos, sem DML e sem aceitar valores soberanos do frontend.
```

## 3. Resultado da tentativa

A tentativa de criar o arquivo abaixo no GitHub foi bloqueada pela camada de segurança da ferramenta antes da gravação:

```text
supabase/migrations/20260527043000_mesa_cliente_20d4_adaptador_agenda_canonica.sql
```

Classificação:

```text
NO_COMMIT
NO_DDL
NO_DML
NO_SUPABASE_CHANGE
```

## 4. Importante

Não considerar a migration como criada.

Não considerar a RPC como existente.

Não considerar 20D.4 como PASS.

## 5. Próximo caminho seguro

Opções disponíveis:

```text
Opção A — o SQL da migration ser fornecido no chat para criação manual no Codespace/local.
Opção B — reduzir o escopo do arquivo e tentar novo commit em partes/documentação técnica.
Opção C — criar primeiro um arquivo .md com o contrato SQL revisável e depois promover manualmente para migration.
```

Recomendação:

```text
Usar Opção A ou C para manter rastreabilidade e evitar afirmar que algo foi gravado quando a ferramenta bloqueou.
```
