# MesaCliente — Fase 5D — Validação 13C

**Status:** validada pelo usuário com resultado PASS no SQL Editor/Supabase.  
**Data de registro:** 2026-05-20.  
**Branch:** `feature/mesa-cliente-5d-leitura-operacoes-admin`.  
**Arquivo de teste:** `supabase/tests/mesa-cliente/engenharia-financeira/13c_validacao_seguranca_leitura_operacoes_admin_rollback.sql`.

## Objetivo técnico

Validar a segurança negativa das RPCs administrativas de leitura de operações financeiras da Fase 5D:

- `public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)`
- `public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)`

A validação cobre autenticação obrigatória, grants, tenant-safe, bloqueio de payload soberano, filtros inválidos, acesso cross-tenant e garantia read-only.

## Correção aplicada no harness 13C

O erro anterior era:

```text
ERROR: 42P01: relation "tmp_13c_resultados" does not exist
```

A causa estava no uso de tabela temporária para acumular evidências no SQL Editor/Supabase. A correção correta não foi remover bloco de teste; foi substituir o mecanismo de acúmulo de resultados por JSONB transacional em `app.mc13c.results`, com helper temporário `pg_temp.mc13c_add_result(...)`.

O arquivo 13C original foi preservado como 13C e corrigido com a nomenclatura oficial 13C. Não deve ser documentado como 13Cv2.

## Resultado validado pelo usuário

O resultset informado pelo usuário contém os blocos abaixo em PASS/INFO:

| Ordem | Bloco | Status | Evidência esperada |
|---:|---|---|---|
| 1 | `00_setup_fixture_13c` | PASS | Fixture transacional 13C criada. |
| 2 | `00b_agenda_parcela_fixture_13c` | PASS | Agenda e parcela fixture disponíveis. |
| 3 | `01_operacao_fixture_5b_preparada` | PASS | Operação fixture 5B criada para os negativos 5D. |
| 4 | `02_grants_5d_anon_bloqueado_authenticated_liberado` | PASS | `anon/public` sem execute; `authenticated` com execute. |
| 5 | `03a_listar_sem_auth_bloqueado` | PASS | Listagem sem `auth.uid()` bloqueada com `28000`. |
| 6 | `03b_obter_sem_auth_bloqueado` | PASS | Detalhe sem `auth.uid()` bloqueado com `28000`. |
| 7 | `04a_listar_simulacao_inexistente_bloqueada` | PASS | Simulação inexistente bloqueada com `P0002`. |
| 8 | `04b_obter_operacao_inexistente_bloqueada` | PASS | Operação inexistente bloqueada com `P0002`. |
| 9 | `05a_listar_filtros_nao_objeto_bloqueado` | PASS | `p_filtros` não objeto bloqueado com `22023`. |
| 10 | `05b_obter_parametros_nao_objeto_bloqueado` | PASS | `p_parametros` não objeto bloqueado com `22023`. |
| 11 | `06a_listar_payload_soberano_bloqueado` | PASS | `empresa_id` soberano enviado pelo frontend bloqueado com `42501`. |
| 12 | `06b_obter_payload_soberano_bloqueado` | PASS | `simulacao_id` soberano enviado pelo frontend bloqueado com `42501`. |
| 13 | `07a_listar_status_invalido_bloqueado` | PASS | `status_operacao` inválido bloqueado com `22023`. |
| 14 | `07b_listar_limit_invalido_bloqueado` | PASS | `limit` inválido bloqueado com `22023`. |
| 15 | `07c_listar_agenda_incompativel_bloqueada` | PASS | Agenda incompatível bloqueada com `P0002`. |
| 16 | `08a_listar_cross_tenant_bloqueado` | PASS | Listagem cross-tenant bloqueada com `42501`. |
| 17 | `08b_obter_cross_tenant_bloqueado` | PASS | Detalhe cross-tenant bloqueado com `42501`. |
| 18 | `09_negativos_readonly_nao_mutaram_agenda_parcelas_operacoes` | PASS | Hashes de agenda, parcelas e operações permaneceram iguais. |
| 19 | `99_rollback_notice` | INFO | Teste transacional com `ROLLBACK`. |

## Conclusão técnica

A validação 13C está aprovada para a Fase 5D quanto a:

- segurança negativa;
- grants corretos;
- autenticação obrigatória;
- bloqueio de payload soberano;
- tenant-safe/cross-tenant;
- validação de filtros/parâmetros;
- comportamento read-only das RPCs administrativas de leitura;
- execução em rollback transacional, sem fixture persistente.

## Próximo passo operacional

Com o 13C validado, o próximo passo deve seguir a matriz da Fase 5D e não reabrir os blocos já aprovados, salvo se houver alteração de RPC, grant, RLS ou contrato funcional.
