# Rascunhos obsoletos — Fase 4A persistente

**Status:** RASCUNHO OBSOLETO — NÃO APLICAR EM PRODUÇÃO  
**Data do arquivamento:** 2026-05-18  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Documento de decisão:** `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md`  
**Protocolo obrigatório:** `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`

---

## Motivo do arquivamento

O preflight read-only da agenda legada confirmou:

```txt
migration_20260517193000_applied = false
migration_20260517223000_applied = false
legacy_function_exists = false
legacy_function_anon_can_execute = false
legacy_function_authenticated_can_execute = false
parcelas_count = 0
operacoes_count = 0
```

Portanto, as migrations legadas de agenda persistente **não foram aplicadas no Supabase real**, a RPC legada `public.gerar_mesa_cliente_agenda_parcelas` **não existe no banco**, e não há linhas permanentes em `mesa_cliente_fluxo_parcelas` ou `mesa_cliente_fluxo_operacoes`.

Com isso, o caminho seguro é retirar o conjunto legado do fluxo oficial de migrations/testes da Fase 4A e preservar a rastreabilidade pelo histórico Git.

---

## Arquivos legados retirados do caminho oficial

Os arquivos abaixo pertenciam ao desenho antigo de Fase 4A persistente:

```txt
supabase/migrations/20260517193000_mesa_cliente_engenharia_financeira_fase_4a_agenda.sql
supabase/migrations/20260517223000_mesa_cliente_rpc_gerar_agenda_parcelas.sql
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_parcelas_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_parcelas_negativos_rollback.sql
```

Esses arquivos eram coerentes com a arquitetura antiga:

```txt
gerar/recriar parcelas em mesa_cliente_fluxo_parcelas
```

Mas essa arquitetura deixou de ser canônica para a Fase 4A.

---

## Regra oficial atual

```txt
4A = JSON-first, sem persistência
4B = persistência segura com lock, idempotência e auditoria
4C = leitura cliente-safe
```

Tudo que faz `INSERT`, `UPDATE` ou `DELETE` em `mesa_cliente_fluxo_parcelas` ou `mesa_cliente_fluxo_operacoes` pertence à Fase 4B, não à Fase 4A.

---

## Conduta obrigatória

Não aplicar os arquivos legados em produção.

Não recriar RPC com o nome antigo `public.gerar_mesa_cliente_agenda_parcelas` como implementação oficial da Fase 4A.

Não usar os testes antigos `07a_validacao_agenda_parcelas_rollback.sql` e `07b_validacao_agenda_parcelas_negativos_rollback.sql` como testes oficiais da Fase 4A JSON-first.

A Fase 4A deve seguir a nova RPC oficial:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

Critério de aceite:

```txt
agenda em JSON;
zero DML em mesa_cliente_fluxo_parcelas;
zero DML em mesa_cliente_fluxo_operacoes;
count_before = count_after;
anon bloqueado;
auth/tenant/perfil validados;
sem VPL/prêmio/comissão/política interna exposta.
```

---

## Observação de rastreabilidade

O conteúdo original dos arquivos legados permanece preservado no histórico Git da branch, antes do commit de arquivamento. Este diretório registra a decisão operacional e impede que migrations persistentes antigas continuem disponíveis na pasta oficial `supabase/migrations`.
