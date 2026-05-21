# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 7 — 15E Regressão final da aplicação de operação financeira

### Arquivo SQL

```text
supabase/tests/mesa-cliente/engenharia-financeira/15e_regressao_final_aplicacao_operacao_fase_7_rollback.sql
```

### Objetivo

Consolidar o gate final da Fase 7 antes do fechamento técnico, validando:

- contrato de catálogo da RPC de aplicação financeira;
- presença do status `aplicada` na constraint oficial;
- preservação dos status legados;
- schema mínimo das tabelas financeiras críticas;
- RLS ativo nas tabelas financeiras críticas;
- inventário read-only de operações existentes;
- readiness final da Fase 7.

### RPC validada

```sql
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

### Natureza do teste

O 15E é um teste de regressão final estrutural/readiness.

Ele não deve aplicar operação financeira por conta própria. A execução mutacional positiva e as tentativas negativas de aplicação permanecem cobertas pelos testes anteriores da Fase 7, especialmente 15B, 15C e 15D, todos com `BEGIN` + `ROLLBACK`.

### Blocos esperados

| Bloco | Status esperado | Objetivo |
|---|---:|---|
| 00_contrato_rpc_catalogo | PASS | Confirma RPC, assinatura, SECURITY DEFINER, grant authenticated, anon bloqueado, search_path e comentário. |
| 01_constraint_status_operacao_fase_7 | PASS | Confirma `aplicada` e preserva `simulada`, `confirmada`, `cancelada`, `bloqueada`. |
| 02_schema_minimo_aplicacao | PASS | Confirma colunas mínimas de operações e parcelas. |
| 03_rls_tabelas_financeiras | PASS | Confirma RLS ativo nas tabelas financeiras críticas. |
| 04_inventario_operacoes_sem_mutacao | INFO | Inventário read-only de operações por status. |
| 05_readiness_fase_7 | PASS | Consolida readiness se não houver FAIL anterior. |
| 99_rollback_notice | INFO | Declara que o teste encerra com rollback e sem aplicação financeira. |

### Garantias

- Sem fixture.
- Sem insert/update/delete.
- Sem aplicação real de operação financeira.
- Sem alteração de agenda.
- Sem alteração de parcelas.
- Sem alteração de operação.
- Encerramento obrigatório com `ROLLBACK`.

### Observação técnica

Este teste foi desenhado como fechamento estrutural da Fase 7. Caso seja necessário validar novamente a aplicação mutacional completa, a execução deve ser feita pelos testes específicos de aplicação com fixture transacional controlada.

### Status

Criado e registrado na branch:

```text
feature/mesa-cliente-pos-fase-6-proxima-fase
```

Commit de criação do SQL:

```text
d673267d37516ce689b74c1d36f36291ffb1a52e
```
