# FECH.AI / MesaCliente — Fase 5A.1 — Resultado do Preflight 10 e 10P

**Status:** preflight 10 executado; 10P transacional aprovado; migration/RPC 5A.1 criada para validação  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5A.1 — simulação administrativa de impacto financeiro com agenda persistida  
**Preflight executado:** `supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_simulacao_impacto_agenda_persistida_readonly.sql`  
**Preparação executada:** `supabase/tests/mesa-cliente/engenharia-financeira/10p_preparacao_base_minima_5a_agenda_persistida_rollback.sql`  
**Migration criada:** `supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql`  
**Documento canônico relacionado:** `docs/mesa-cliente/fase-5a-contrato-simulacao-impacto-agenda-persistida.md`

---

## 1. Veredito executivo

O preflight 10 canônico da Fase 5A.1 foi executado inicialmente e retornou:

```text
13_operational_interpretation = FAIL
```

A falha não era estrutural de schema. O bloqueio ocorreu porque o ambiente não possuía base mínima operacional permanente para testar a RPC agenda-first:

```text
politicas_ativas_compostas_dias_365 = 0
agendas_ativas_com_parcelas = 0
total_fixture_candidates_5a = 0
```

Para não criar seed permanente e não contaminar o banco de produção única, foi criada a etapa intermediária 10P, com `BEGIN + ROLLBACK`.

O 10P foi executado e retornou **PASS em todos os blocos críticos**.

Resultado final deste ciclo:

```text
Preflight 10: FAIL operacional por falta de dados mínimos.
10P: PASS transacional.
Gate liberado para criar migration/RPC 5A.1.
Migration/RPC 5A.1 criada.
Testes 10A/10B/10C criados para execução em rollback.
```

---

## 2. Resultado do preflight 10 read-only

| Ordem | Seção | Status | Interpretação |
|---:|---|---|---|
| 1 | `01_tables_inventory` | PASS | Tabelas necessárias foram encontradas. |
| 2 | `02_function_inventory` | PASS | Funções/RPCs prévias necessárias foram encontradas. |
| 3 | `03_columns_inventory` | INFO | Inventário amplo de colunas retornado. |
| 4 | `04_expected_required_columns_status` | PASS | Nenhuma coluna obrigatória ausente. |
| 5 | `05_finance_column_candidates` | INFO | Candidatos financeiros mapeados. |
| 6 | `06_constraints_inventory` | INFO | Constraints inventariadas. |
| 7 | `07_indexes_inventory` | INFO | Índices inventariados. |
| 8 | `08_rls_policies_and_table_grants` | PASS | RLS/policies/grants inventariados sem bloqueio crítico. |
| 9 | `09_counts_and_data_readiness` | INFO | Ambiente sem dados mínimos para fixture/cenário real 5A. |
| 10 | `10_security_findings` | PASS | Achados de segurança sem bloqueio crítico para o preflight. |
| 11 | `11_migration_5a_contract_reminder` | INFO | Contrato 5A.1 reafirmado: administrativo, sem persistência e sem DML financeiro. |
| 13 | `13_operational_interpretation` | FAIL | Bloqueou migration/RPC 5A.1 naquele momento. |
| 99 | `99_end` | INFO | Preflight concluído. |

---

## 3. Resultado do 10P transacional

Arquivo executado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10p_preparacao_base_minima_5a_agenda_persistida_rollback.sql
```

Resultado enviado:

| Bloco | Status | Evidência principal |
|---|---|---|
| `01_contexto_transacional` | PASS | Contexto admin_global válido, empresa/corretor/empreendimento/simulação/política encontrados/criados em fixture. |
| `02_politica_financeira_ativa_composta_dias_365` | PASS | Política ativa com `metodo_calculo=composto` e `base_tempo=dias_365`. |
| `03_faixas_premio_administrativas` | PASS | 3 faixas administrativas criadas em transação. |
| `04_rpc_4b_persistiu_agenda_fixture` | PASS | RPC 4B persistiu agenda fixture com `ok=true`. |
| `05_agenda_ativa_com_parcelas` | PASS | Agenda ativa com 6 parcelas e total de R$ 29.500,50. |
| `06_parcelas_elegiveis_para_5a` | PASS | 5 parcelas elegíveis para VPL/antecipação/postergacão e 1 periodicidade simbólica. |
| `07_zero_operacoes_financeiras_confirmadas` | PASS | Nenhuma operação financeira registrada. |
| `08_readiness_para_migration_5a` | PASS | Readiness aprovado para criar migration/RPC 5A.1. |
| `99_rollback_notice` | INFO | Fixture transacional encerrada com ROLLBACK. |

Evidências relevantes:

```text
politica_valida_5a = true
agenda_valida_5a = true
total_parcelas = 6
qtd_faixas_db = 3
total_operacoes = 0
```

---

## 4. Decisão após 10P

Com o 10P aprovado, a decisão oficial passou a ser:

```text
Liberado criar a migration/RPC 5A.1 e os testes transacionais 10A/10B/10C.
```

Migration criada:

```text
supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql
```

RPC criada:

```text
public.mesa_cliente_simular_impacto_agenda_persistida_admin(
  p_simulacao_id uuid,
  p_data_referencia date default current_date,
  p_modo text default 'melhor_aplicacao',
  p_parametros jsonb default '{}'::jsonb
)
```

Características da RPC:

```text
visao = administrativa
agenda-first = true
cliente_safe = false
persistencia = false
dml_financeiro = false
security definer = true
anon = sem execute
authenticated = execute
```

---

## 5. Testes criados para validação da migration/RPC 5A.1

### 5.1. 10A — positivo

```text
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
```

Valida:

- fixture transacional;
- persistência da agenda via RPC 4B;
- chamada positiva da RPC 5A.1;
- `cliente_safe=false`;
- `persistencia=false`;
- `dml_financeiro=false`;
- alternativas geradas;
- recomendação administrativa;
- política usada com `composto/dias_365`;
- zero operação financeira;
- rollback.

### 5.2. 10B — negativos

```text
supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql
```

Valida:

- `anon` sem execute;
- chamada sem auth bloqueada;
- simulação inexistente bloqueada;
- `empresa_id` no payload bloqueado;
- valor negativo bloqueado;
- modo inválido bloqueado;
- agenda inexistente bloqueada;
- rollback.

### 5.3. 10C — zero DML

```text
supabase/tests/mesa-cliente/engenharia-financeira/10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql
```

Valida:

- chamada 5A com `comparativo`;
- flags `persistencia=false` e `dml_financeiro=false`;
- contagens de agendas inalteradas;
- contagens de parcelas inalteradas;
- contagens de operações inalteradas;
- checksum/totais da agenda inalterados;
- rollback.

---

## 6. Próxima ação operacional

A sequência obrigatória agora é:

1. Aplicar a migration:

```text
supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql
```

2. Executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
```

3. Executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql
```

4. Executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql
```

5. Enviar os três resultsets completos.

Somente após os três testes passarem, a Fase 5A.1 poderá ser marcada como aprovada.

---

## 7. Guardrails mantidos

Continuam proibidos nesta etapa:

- alterar frontend;
- alterar parser;
- alterar Worker;
- alterar Make/n8n;
- aceitar taxa, VPL, política ou `empresa_id` como autoridade do frontend;
- gravar em `mesa_cliente_fluxo_operacoes` pela RPC 5A.1;
- alterar parcelas persistidas pela RPC 5A.1;
- alterar agenda persistida pela RPC 5A.1;
- usar payload cliente-safe como base soberana;
- criar seed permanente sem decisão explícita.

---

## 8. Estado operacional atualizado

```text
4A aprovada.
4B aprovada em rollback transacional.
4C aprovada.
5A.1 contrato final fechado.
10 preflight canônico executado.
10P aprovado.
Migration/RPC 5A.1 criada.
Testes 10A/10B/10C criados.
Próxima ação: aplicar migration e executar 10A/10B/10C.
Fase 5A.1 ainda não aprovada até os testes passarem.
```

---

## 9. Veredito final

O 10P cumpriu o papel de ponte segura entre o preflight read-only e a implementação.

A 5A.1 agora tem chão para subir a parede, mas a parede ainda precisa passar no prumo: **executar 10A, 10B e 10C antes de declarar fase aprovada.**
