# FECH.AI / MesaCliente — Fase 5A.1 — Resultado final do Preflight 10, 10P, 10A, 10B e 10C

**Status:** aprovada  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5A.1 — simulação administrativa de impacto financeiro com agenda persistida  
**Preflight executado:** `supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_simulacao_impacto_agenda_persistida_readonly.sql`  
**Preparação executada:** `supabase/tests/mesa-cliente/engenharia-financeira/10p_preparacao_base_minima_5a_agenda_persistida_rollback.sql`  
**Migration principal:** `supabase/migrations/20260518193000_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql`  
**Migration corretiva:** `supabase/migrations/20260518194500_fix_mesa_cliente_5a_remover_agenda_id_operacoes.sql`  
**Documento canônico relacionado:** `docs/mesa-cliente/fase-5a-contrato-simulacao-impacto-agenda-persistida.md`  
**Fechamento final:** `docs/mesa-cliente/fase-5a-validacao-final-simulacao-impacto-agenda-persistida.md`

---

## 1. Veredito executivo final

A Fase 5A.1 está **aprovada**.

Resultados consolidados:

```text
10P = PASS
10A = PASS
10B = PASS
10C = PASS
```

A RPC administrativa de simulação de impacto financeiro foi validada com agenda persistida como fonte soberana, sem exposição cliente-safe e sem DML financeiro permanente.

---

## 2. Resultado do preflight 10 read-only

O preflight 10 canônico foi executado inicialmente e retornou:

```text
13_operational_interpretation = FAIL
```

A falha não era estrutural de schema. O bloqueio ocorreu por ausência de base mínima operacional permanente para testar a RPC agenda-first:

```text
politicas_ativas_compostas_dias_365 = 0
agendas_ativas_com_parcelas = 0
total_fixture_candidates_5a = 0
```

Interpretação aprovada:

```text
Schema e funções mínimas estavam presentes, mas não havia dados mínimos permanentes para liberar a 5A.1 sem fixture.
```

---

## 3. Resultado do 10P transacional

Arquivo executado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10p_preparacao_base_minima_5a_agenda_persistida_rollback.sql
```

Resultado:

```text
PASS
```

Evidências relevantes:

```text
politica_valida_5a = true
agenda_valida_5a = true
total_parcelas = 6
qtd_faixas_db = 3
total_operacoes = 0
```

Decisão após 10P:

```text
Liberado criar a migration/RPC 5A.1 e os testes transacionais 10A/10B/10C.
```

---

## 4. Migration/RPC 5A.1 criada

Migration principal:

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

Características contratuais:

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

## 5. Correções aplicadas durante a validação

### 5.1. Correção do 10A — escopo de CTE

Erro observado:

```text
relation "chamada_5a" does not exist
```

Causa:

```text
Uso de CTE fora do comando SQL imediatamente seguinte.
```

Correção:

```text
O 10A foi ajustado para gravar payload_4b e payload_5a no mesmo comando SQL em que as CTEs existem.
```

### 5.2. Correção da RPC 5A.1 — coluna inexistente `o.agenda_id`

Erro observado:

```text
column o.agenda_id does not exist
```

Causa:

```text
A RPC 5A.1 assumiu indevidamente que public.mesa_cliente_fluxo_operacoes possuía agenda_id.
```

Decisão técnica:

```text
Não usar agenda_id em mesa_cliente_fluxo_operacoes.
Bloquear operação confirmada por empresa_id + simulacao_id + status_operacao = 'confirmada'.
```

Migration corretiva criada:

```text
supabase/migrations/20260518194500_fix_mesa_cliente_5a_remover_agenda_id_operacoes.sql
```

### 5.3. Correção do 10B — remoção de temp table com SET LOCAL ROLE

Erros observados:

```text
permission denied for table tmp_10b_results
relation "tmp_10b_results" does not exist
```

Causa:

```text
Temp table + SET LOCAL ROLE authenticated ficou frágil no SQL Editor/Supabase.
```

Correção:

```text
O 10B deixou de usar temp table e passou a acumular resultados em variável transacional via set_config('app.mc10b.results', ..., true).
```

---

## 6. Resultado do 10A — aprovado

Arquivo executado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
```

Resultado consolidado:

| Bloco | Status | Evidência principal |
|---|---|---|
| `01_retorno_basico_5a` | PASS | Retorno `5A_SIMULACAO_IMPACTO_AGENDA_PERSISTIDA`, visão administrativa, `cliente_safe=false`, `persistencia=false`, `dml_financeiro=false`. |
| `02_alternativas_e_recomendacao` | PASS | 8 alternativas geradas; recomendação principal por antecipação. |
| `03_politica_usada` | PASS | Política `composto/dias_365`, VPL máximo 6%, taxas de antecipação/postergacão 12% a.a. |
| `04_zero_operacoes_financeiras` | PASS | `total_operacoes=0`, fixture com 6 parcelas. |
| `99_rollback_notice` | INFO | Teste encerrado com ROLLBACK. |

Veredito:

```text
10A aprovado.
```

---

## 7. Resultado do 10B — aprovado

Arquivo executado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql
```

Resultado consolidado:

| Bloco | Status | Evidência principal |
|---|---|---|
| `01_grant_anon_bloqueado` | PASS | `anon_can_execute=false`. |
| `02_sem_auth_bloqueado` | PASS | Bloqueio sem auth com SQLSTATE `28000`. |
| `03_simulacao_inexistente_bloqueada` | PASS | Simulação inexistente bloqueada com SQLSTATE `P0002`. |
| `04_empresa_id_payload_bloqueado` | PASS | `empresa_id` no payload bloqueado com SQLSTATE `42501`. |
| `05_valor_negativo_bloqueado` | PASS | Valor negativo bloqueado com SQLSTATE `22023`. |
| `06_modo_invalido_bloqueado` | PASS | Modo inválido bloqueado com SQLSTATE `22023`. |
| `07_agenda_inexistente_bloqueada` | PASS | Agenda ativa inexistente bloqueada com SQLSTATE `P0002`. |
| `99_rollback_notice` | INFO | Teste encerrado com ROLLBACK. |

Veredito:

```text
10B aprovado.
```

---

## 8. Resultado do 10C — aprovado

Arquivo executado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql
```

Resultado consolidado:

| Bloco | Status | Evidência principal |
|---|---|---|
| `01_retorno_5a_zero_dml_flags` | PASS | RPC retornou `persistencia=false` e `dml_financeiro=false`. |
| `02_contagens_inalteradas` | PASS | Antes/depois: 1 agenda, 6 parcelas, 0 operações. |
| `03_agenda_checksum_totais_inalterados` | PASS | Mesmo `agenda_id`, mesmo checksum e mesmos totais antes/depois. |
| `99_rollback_notice` | INFO | Teste encerrado com ROLLBACK. |

Evidências relevantes:

```text
agendas_before = 1
agendas_after = 1
parcelas_before = 6
parcelas_after = 6
operacoes_before = 0
operacoes_after = 0
agenda_id_before = 92f1fcc0-e280-4211-8372-4ff4bdb95587
agenda_id_after = 92f1fcc0-e280-4211-8372-4ff4bdb95587
checksum_before = 3373755171d33c447fa959808f5b2f41
checksum_after = 3373755171d33c447fa959808f5b2f41
totais_iguais = true
valor_total = 29500.5
qtd_parcelas = 6
```

Interpretação:

```text
A RPC 5A.1 não alterou agenda, parcelas, operações, checksum ou totais.
```

Veredito:

```text
10C aprovado.
```

---

## 9. Guardrails mantidos

Continuam preservados:

- sem alteração de frontend;
- sem alteração de parser;
- sem alteração de Worker;
- sem alteração de Make/n8n;
- sem seed permanente;
- sem autoridade financeira vinda do frontend;
- sem `empresa_id` soberano no payload;
- sem DML financeiro pela RPC 5A.1;
- sem escrita em `mesa_cliente_fluxo_operacoes`;
- sem alteração em `mesa_cliente_fluxo_parcelas`;
- sem alteração em `mesa_cliente_agendas_financeiras`;
- sem exposição cliente-safe.

---

## 10. Estado operacional final

```text
4A aprovada.
4B aprovada em rollback transacional.
4C aprovada.
5A.1 aprovada.
```

Próximas fases naturais:

```text
5B — registrar operação financeira em tabela própria, com lock/idempotência/auditoria.
5C — confirmar/cancelar operação financeira.
Integração Front/BFF — somente após contrato administrativo e cliente-safe estarem fechados para leitura/escrita necessária.
```

---

## 11. Veredito final

A 5A.1 cumpriu seu papel: simular impacto financeiro sobre agenda persistida, entregar visão administrativa e provar que não altera o estado financeiro.

A etapa está encerrada e aprovada.
