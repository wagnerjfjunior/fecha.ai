# MesaCliente — Fase 5D — Validação 13D

**Status:** validada pelo usuário com resultado PASS no SQL Editor/Supabase.  
**Data de registro:** 2026-05-20.  
**Branch:** `feature/mesa-cliente-5d-leitura-operacoes-admin`.  
**Arquivo de teste:** `supabase/tests/mesa-cliente/engenharia-financeira/13d_validacao_zero_dml_readonly_rigido_leitura_operacoes_admin_rollback.sql`.

## Objetivo técnico

Validar que as RPCs administrativas de leitura da Fase 5D são rigidamente read-only e não executam DML financeiro, nem mesmo atualização silenciosa:

- `public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)`
- `public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)`

O teste confirma que as leituras 5D não alteram:

- `public.mesa_simulacoes`;
- `public.mesa_cliente_agendas_financeiras`;
- `public.mesa_cliente_fluxo_parcelas`;
- `public.mesa_cliente_fluxo_operacoes`;
- `updated_at`;
- `checksum_operacao`;
- `status_operacao`;
- contagens de agenda, parcelas, operações e visibilidade cliente;
- `xmin` das linhas monitoradas.

## Critério diferencial

Além de comparar hashes completos de conteúdo, o teste compara `xmin` antes/depois. Esse critério detecta `UPDATE` silencioso no PostgreSQL, inclusive quando o update grava o mesmo valor e o conteúdo final parece igual.

Isso torna o 13D mais forte do que uma validação comum de payload, porque comprova ausência real de mutação nas linhas monitoradas.

## Fixture transacional

O teste cria uma fixture transacional controlada:

1. Cria simulação de teste.
2. Cria política financeira e faixas de prêmio.
3. Persiste agenda via Fase 4B.
4. Registra três operações financeiras via Fase 5B.
5. Confirma uma operação via Fase 5C.
6. Cancela uma operação via Fase 5C.
7. Mantém uma operação em estado `simulada`.
8. Tira snapshot antes das chamadas 5D.
9. Executa leituras 5D.
10. Tira snapshot depois das chamadas 5D.
11. Compara hashes, `xmin`, contagens, status, `updated_at` e `checksum_operacao`.
12. Encerra com `ROLLBACK`.

## Resultado validado pelo usuário

O resultset informado pelo usuário contém os blocos abaixo em PASS/INFO:

| Ordem | Bloco | Status | Evidência validada |
|---:|---|---|---|
| 1 | `00_setup_fixture_13d` | PASS | Fixture base criada com 3 faixas e política financeira. |
| 2 | `00b_agenda_parcelas_fixture_13d` | PASS | Agenda criada e 3 parcelas elegíveis selecionadas. |
| 3 | `01_fixture_5b_5c_preparada_para_readonly` | PASS | 3 operações preparadas: 1 confirmada, 1 cancelada e 1 simulada. |
| 4 | `02_snapshot_before_tem_base_valida` | PASS | Snapshot inicial consistente antes das leituras 5D. |
| 5 | `03_chamadas_5d_retorno_canonico_readonly` | PASS | Retorno 5D canônico com `readonly=true`, `dml_financeiro=false`, `escopo_dml=nenhum`. |
| 6 | `04_hashes_completos_preservados` | PASS | Hashes de simulação, agenda, parcelas e operações preservados. |
| 7 | `05_xmin_versions_preservados_sem_update_silencioso` | PASS | `xmin` preservado em simulação, agenda, parcelas e operações. |
| 8 | `06_contagens_status_updated_at_checksum_preservados` | PASS | Contagens, status, `updated_at` e checksums preservados. |
| 9 | `07_leituras_repetidas_deterministicas_sem_efeito_colateral` | PASS | Leituras repetidas retornam payload determinístico e sem efeito colateral. |
| 10 | `99_rollback_notice` | INFO | Teste transacional encerrado com `ROLLBACK`. |

## Evidências principais

- A listagem 5D retornou `fase = 5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN`.
- O detalhe 5D retornou `fase = 5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN`.
- O payload declarou `readonly = true`.
- O payload declarou `dml_financeiro = false`.
- O payload declarou `escopo_dml = nenhum`.
- O total de operações foi 3.
- O snapshot preservou 1 operação `confirmada`, 1 `cancelada` e 1 `simulada`.
- `qtd_visivel_cliente` permaneceu 0.
- Os hashes antes/depois foram idênticos.
- Os `xmin` antes/depois foram idênticos.
- A leitura repetida da agenda retornou o mesmo hash.
- A leitura repetida do detalhe da operação retornou a mesma operação e o mesmo `checksum_operacao`.

## Conclusão técnica

A validação 13D está aprovada para a Fase 5D quanto a zero DML/read-only rígido.

A Fase 5D demonstrou que suas RPCs administrativas de leitura:

- não recalculam operação;
- não alteram agenda;
- não alteram parcelas;
- não alteram operações;
- não alteram metadados persistidos;
- não alteram `updated_at`;
- não alteram `xmin`;
- não produzem efeito colateral em leituras repetidas.

## Status operacional

Com 13A, 13B, 13C e 13D validados, a Fase 5D fica tecnicamente coberta em:

- contrato de listagem;
- contrato de detalhe;
- segurança negativa;
- tenant-safe;
- grants/autenticação;
- payload soberano bloqueado;
- read-only rígido;
- zero DML comprovado por hash e `xmin`.

## Próximo passo recomendado

Seguir para o fechamento da Fase 5D com documentação executiva e checklist de merge, sem reabrir os testes já aprovados, salvo alteração em RPC, grants, RLS, contrato JSON ou engine financeiro.
