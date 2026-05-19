# FECH.AI / MesaCliente — Fechamento da Fase 4C Cliente-Safe

**Status:** aprovado com testes 09A e 09B  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 4C — leitura cliente-safe da agenda financeira  
**Data de consolidação:** 2026-05-18

---

## 1. Decisão oficial

A Fase 4C foi considerada **aprovada tecnicamente** após validação do caminho positivo e dos cenários negativos/hostis da RPC cliente-safe.

A RPC validada foi:

```sql
public.mesa_cliente_obter_agenda_financeira_cliente_safe(
  p_simulacao_id uuid
)
returns jsonb
```

A decisão de arquitetura permanece:

- **4A**: gera agenda financeira em JSON, sem persistência.
- **4B**: persiste agenda financeira com lock, idempotência, auditoria e bloqueio contra operação confirmada.
- **4C**: lê agenda persistida e devolve payload cliente-safe.
- **5A+**: usa agenda persistida para impacto financeiro/operação.

A 4C **não cria agenda**, **não cria parcelas**, **não cria operação financeira** e **não altera dados financeiros**. Ela apenas lê a agenda ativa persistida e devolve uma visão filtrada para cliente.

---

## 2. Princípio de segurança aprovado

A Fase 4C foi fechada sob a seguinte regra:

> Cliente-safe não é apenas “um JSON bonitinho para tela”. Cliente-safe é uma fronteira de segurança.

Portanto, o retorno da RPC não pode expor:

- `checksum`;
- `metadata`;
- `payload_origem`;
- `criado_por`;
- `atualizado_por`;
- `confirmado_por`;
- `cancelado_por`;
- `pode_receber_vpl`;
- `vpl_aplicado_pct`;
- `premio_corretor_pct`;
- `status_premio`;
- `politica_id`;
- `taxa_ano_pct`;
- `desconto_calculado`;
- `acrescimo_calculado`;
- `economia_liquida`;
- qualquer payload bruto interno que possa revelar regra comercial, auditoria, política, cálculo, prêmio ou VPL.

Campos internos podem existir no banco e em payloads administrativos, mas **não podem atravessar a fronteira cliente-safe**.

---

## 3. Resultado consolidado dos testes

### 3.1 Teste 09A — caminho positivo

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/09_validacao_agenda_financeira_cliente_safe_rollback.sql
```

Objetivo:

Validar que a RPC cliente-safe retorna uma agenda ativa persistida, com parcelas e aliases esperados, sem vazar campos sensíveis e sem executar DML financeiro.

Resultado final:

| Bloco | Resultado | Interpretação |
|---|---:|---|
| fixture transacional | PASS | Criou simulação, agenda e parcelas apenas dentro da transação |
| RPC cliente-safe executou | PASS | Retornou payload válido |
| payload cliente-safe | PASS | `cliente_safe = true`, `persistencia = false`, `dml_financeiro = false` |
| agenda ativa retornada | PASS | Agenda fixture ativa foi localizada |
| parcelas cliente-safe | PASS | Totalizadores e quantidade de parcelas coerentes |
| aliases e derivações | PASS | `data_vencimento`, `negociavel`, `parcela_numero`, `parcelas_total_item` derivados corretamente |
| campos sensíveis | PASS | Nenhum campo proibido apareceu no retorno |
| grants | PASS | `anon` bloqueado e `authenticated` liberado |
| operações financeiras | PASS | Zero DML em `mesa_cliente_fluxo_operacoes` |
| rollback | INFO/PASS operacional | Fixture transacional revertida |

Conclusão do 09A:

```text
PASS — caminho positivo aprovado.
```

---

### 3.2 Teste 09B — negativos e cenários hostis

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/09b_validacao_agenda_financeira_cliente_safe_negativos_rollback.sql
```

Objetivo:

Validar que a RPC cliente-safe bloqueia acessos indevidos, não retorna agenda inválida/substituída, não permite vazamento de payload hostil e não gera DML financeiro.

Resultado final:

| Bloco | Resultado | Interpretação |
|---|---:|---|
| fixture transacional | PASS | Cenários negativos criados sem dados permanentes |
| grants da RPC | PASS | `anon` sem `EXECUTE`; `authenticated` com `EXECUTE` |
| sem auth | PASS | Bloqueado corretamente |
| simulação inexistente | PASS | Bloqueada corretamente |
| simulação sem agenda ativa | PASS | Bloqueada corretamente |
| agenda substituída | PASS | Não retornada |
| cross-tenant | PASS | Usuário de outra empresa bloqueado |
| payload sujo | PASS | Nenhum campo sensível vazou |
| periodicidade | PASS | Continuou não negociável no cliente-safe |
| operações financeiras | PASS | Zero DML em `mesa_cliente_fluxo_operacoes` |
| rollback | INFO/PASS operacional | Fixture transacional revertida |

Conclusão do 09B:

```text
PASS — negativos e cenários hostis aprovados.
```

---

## 4. Critério de aceite final da Fase 4C

A Fase 4C só poderia ser considerada aprovada se todos os critérios abaixo fossem atendidos.

| Critério | Status |
|---|---:|
| RPC cliente-safe existe e executa para `authenticated` | PASS |
| `anon` não possui `EXECUTE` | PASS |
| retorno declara `cliente_safe = true` | PASS |
| retorno declara `persistencia = false` | PASS |
| retorno declara `dml_financeiro = false` | PASS |
| agenda ativa é retornada corretamente | PASS |
| agenda substituída não é retornada | PASS |
| simulação inexistente bloqueia | PASS |
| simulação sem agenda ativa bloqueia | PASS |
| cross-tenant bloqueia | PASS |
| campos sensíveis não vazam | PASS |
| payload hostil não contamina retorno cliente-safe | PASS |
| periodicidade simbólica não vira negociável | PASS |
| zero DML em operações financeiras | PASS |
| testes rodam com `BEGIN` + `ROLLBACK` | PASS |

**Veredito:**

```text
Fase 4C aprovada.
```

---

## 5. O que deu trabalho e precisa ficar registrado

Esta fase teve falhas intermediárias importantes. Elas não devem ser apagadas porque explicam por que o teste final ficou mais robusto.

### 5.1 Erro: dedução de coluna inexistente

Durante os preflights e testes, apareceram erros de coluna inexistente, como:

```text
column "totals" does not exist
```

Correção:

A coluna real era `totais`, não `totals`.

Lição:

> Nunca deduzir nome de coluna por convenção. Sempre consultar inventário real do banco antes de escrever SQL.

---

### 5.2 Erro: coluna `data_vencimento` inexistente em tabela persistida

Foi identificado que `mesa_cliente_fluxo_parcelas` não possui `data_vencimento` como coluna física. As colunas reais são:

- `data_original`;
- `data_atual`.

Correção:

A RPC cliente-safe deriva `data_vencimento` a partir de `data_atual`/`data_original`, sem exigir alteração estrutural na tabela.

Lição:

> Cliente-safe pode expor alias derivado, mas o teste não pode tratar alias como coluna física do banco.

---

### 5.3 Erro: tabela temporária de resultados inacessível

Em versões intermediárias de teste apareceu erro do tipo:

```text
relation "_mc_09_resultados" does not exist
```

E também problemas de permissão ao inserir em tabela temporária sob mudança de role/claims.

Correção:

O teste 09B foi desenhado sem tabela temporária de resultados, usando resultset único via CTE e `set_config` transacional.

Lição:

> Em testes com simulação de auth/role no Supabase SQL Editor, tabela temporária pode virar ruído. Preferir resultset único, helper `pg_temp` e CTE simples.

---

### 5.4 Erro: CTE recursiva inválida

Houve tentativa intermediária com estrutura recursiva que gerou:

```text
recursive reference to query "walk" must not appear within its non-recursive term
```

Correção:

A verificação de campos sensíveis foi simplificada para varredura textual controlada do JSON retornado contra lista explícita de chaves proibidas.

Lição:

> Para teste de vazamento, clareza vence sofisticação. O objetivo é provar ausência de chaves proibidas, não montar um analisador recursivo elegante e frágil.

---

### 5.5 Erro: chamada da RPC antes da fixture estar visível

A RPC retornou:

```text
P0002: Simulação não encontrada
```

Esse erro ocorreu em desenho intermediário do teste, quando a criação da fixture e a chamada da RPC ficavam em estrutura que podia gerar comportamento ruim de snapshot/visibilidade.

Correção:

O teste passou a separar:

1. criação da fixture;
2. inserção de agenda/parcelas;
3. chamada da RPC;
4. leitura do resultado;
5. rollback.

Lição:

> Teste de banco precisa ser previsível. Não misturar criação de fixture e chamada da RPC no mesmo statement quando a função faz leitura dependente da fixture.

---

## 6. Contrato final da RPC cliente-safe

A RPC cliente-safe deve manter estas características:

```text
security definer
set search_path = public
revoke execute from public/anon
execute permitido somente para authenticated
```

Validações esperadas:

- `auth.uid()` obrigatório via helper de autenticação;
- usuário ativo;
- tenant/empresa resolvido pelo banco;
- simulação existente;
- simulação pertencente ao tenant do usuário, exceto root quando aplicável;
- agenda ativa existente;
- agenda substituída/bloqueada não pode ser retornada;
- parcelas vinculadas à agenda ativa;
- retorno sem dados sensíveis.

Comportamentos proibidos:

- `INSERT` em agenda;
- `UPDATE` em agenda;
- `DELETE` em agenda;
- `INSERT` em parcelas;
- `UPDATE` em parcelas;
- `DELETE` em parcelas;
- qualquer DML em `mesa_cliente_fluxo_operacoes`;
- retorno de VPL, prêmio, política, taxa interna, cálculo bruto ou auditoria interna.

---

## 7. Payload cliente-safe esperado

A resposta cliente-safe deve expor apenas dados próprios para visualização do cliente/corretor no contexto da mesa.

Campos permitidos em alto nível:

- `ok`;
- `fase`;
- `visao`;
- `cliente_safe`;
- `persistencia`;
- `dml_financeiro`;
- identificação mínima da simulação/agenda quando necessário;
- totalizadores seguros;
- lista de parcelas filtradas.

Campos seguros por parcela:

- `id`;
- `grupo`;
- `descricao`;
- `valor`;
- `data_vencimento`;
- `data_original`, se necessário para explicação;
- `origem_data` quando for seguro;
- `regra_data` somente se não revelar regra interna sensível;
- `ordem`;
- `negociavel`;
- `motivos_bloqueio` filtrados;
- `parcela_numero` derivado;
- `parcelas_total_item` derivado;
- `eh_periodicidade_simbolica`.

Campos proibidos por parcela:

- `metadata`;
- `criado_por`;
- `atualizado_por`;
- `pode_receber_vpl`;
- qualquer campo de VPL, prêmio, comissão, taxa, política ou cálculo interno.

---

## 8. Governança: o que não pode acontecer depois da 4C

Não considerar a Fase 4C como autorização para mexer no front automaticamente.

A aprovação da 4C significa apenas:

```text
A RPC cliente-safe está aprovada no banco para leitura segura da agenda financeira persistida.
```

Não significa:

- liberar integração front sem contrato BFF;
- liberar exibição irrestrita no client;
- expor payload administrativo;
- reaproveitar RPC admin no frontend;
- usar `service_role` no client;
- pular testes E2E;
- avançar para operação financeira sem novo contrato.

---

## 9. Próxima fase sugerida

O próximo passo natural, seguindo a trilha, é a **Fase 5A**.

Mas antes de criar qualquer migration da 5A, deve existir novo contrato:

- objetivo da 5A;
- escopo;
- fora de escopo;
- tabelas tocadas;
- DML permitido/proibido;
- campos sensíveis;
- perfil autorizado;
- critérios de cálculo;
- testes rollback;
- critério de aceite.

A 5A não deve começar com SQL. Deve começar com contrato.

Frase de controle:

```text
Fase 4C fechada. Próximo passo só começa após contrato da 5A.
```

---

## 10. Resumo executivo

A Fase 4C foi difícil porque envolveu três riscos ao mesmo tempo:

1. leitura de dados financeiros persistidos;
2. fronteira cliente-safe;
3. produção única/multiempresa.

A aprovação só foi aceita depois de testar:

- caminho feliz;
- ausência de vazamento;
- ausência de DML indevido;
- bloqueio de `anon`;
- bloqueio sem auth;
- bloqueio cross-tenant;
- bloqueio de simulação inexistente;
- bloqueio de simulação sem agenda ativa;
- bloqueio de agenda substituída;
- payload hostil com campos internos sujos;
- rollback completo.

Conclusão final:

```text
4C cliente-safe aprovada.
Não houve afrouxamento deliberado de segurança para passar teste.
O teste foi corrigido para respeitar o banco real, não para reduzir o contrato.
```

Essa distinção é importante: o que mudou foi a qualidade do teste, não a exigência de segurança.

---

## 11. Regra permanente aprendida nesta fase

A partir desta fase, qualquer nova etapa do MesaCliente deve seguir obrigatoriamente:

```text
Inventário real primeiro.
Contrato depois.
Teste rollback depois.
Migration só depois.
```

E, principalmente:

```text
Alias de payload não é coluna de banco.
Campo interno não é dado cliente-safe.
Teste que passa vazando dado sensível é teste ruim.
```

---

## 12. Arquivos relacionados

Testes principais:

```text
supabase/tests/mesa-cliente/engenharia-financeira/09_validacao_agenda_financeira_cliente_safe_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/09b_validacao_agenda_financeira_cliente_safe_negativos_rollback.sql
```

Documentos superiores:

```text
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md
```

Documentos de fases anteriores relacionados:

```text
docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md
docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md
```
