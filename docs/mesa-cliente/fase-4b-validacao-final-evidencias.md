# FECH.AI / MesaCliente — Fase 4B

## Validação final e evidências da persistência da agenda financeira

**Status:** aprovado em rollback transacional  
**Data de consolidação:** 2026-05-18  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Escopo:** Engenharia Financeira — MesaCliente  
**Documento complementar ao Protocolo Mestre FECH.AI / MesaCliente v1.2**

---

## 1. Decisão oficial

A Fase 4B está validada do ponto de vista de banco para o escopo definido:

> Persistir agenda financeira com lock, idempotência e auditoria, sem criar operação financeira automaticamente e sem expor retorno cliente-safe.

A validação foi feita com testes transacionais usando `BEGIN` + `ROLLBACK`, preservando o banco real sem resíduos permanentes.

Frase de controle:

> **Fase 4B validada em rollback transacional. Persistência, idempotência, negativos e bloqueio por operação confirmada aprovados.**

---

## 2. Hierarquia documental

Este documento **não substitui** os documentos superiores. Ele registra a evidência operacional da Fase 4B.

Ordem de referência:

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`
4. `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md`
5. Este documento: `docs/mesa-cliente/fase-4b-validacao-final-evidencias.md`

---

## 3. Escopo validado na Fase 4B

A Fase 4B validou:

- criação de agenda financeira persistida;
- criação de parcelas financeiras persistidas vinculadas à agenda;
- retorno administrativo, não cliente-safe;
- idempotência para chamadas repetidas com o mesmo checksum;
- bloqueios negativos de segurança e integridade;
- bloqueio de substituição quando já existe operação financeira confirmada;
- preservação da agenda original em caso de bloqueio;
- não criação automática de operação financeira pela RPC de persistência;
- execução em rollback transacional.

---

## 4. Fora de escopo da Fase 4B

A Fase 4B **não libera**:

- frontend;
- BFF;
- parser;
- Worker;
- Make/n8n;
- cliente-safe;
- VPL;
- prêmio;
- comissão;
- política comercial exposta;
- registro de operação financeira real pelo usuário;
- confirmação/cancelamento de operação;
- teste em mesa com cliente.

Esses itens pertencem às próximas fases.

---

## 5. RPC validada

RPC canônica da Fase 4B:

```sql
public.mesa_cliente_persistir_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

Critérios observados:

- uso administrativo/interno;
- retorno não cliente-safe;
- `anon` bloqueado;
- `authenticated` permitido;
- validação de auth e contexto via banco;
- sem autoridade soberana vinda do frontend;
- sem criação de operação financeira automática;
- persistência de agenda e parcelas apenas na Fase 4B.

---

## 6. Testes oficiais aprovados

| Teste | Arquivo | Objetivo | Status |
|---|---|---|---|
| 08A | `supabase/tests/mesa-cliente/engenharia-financeira/08a_validacao_persistencia_agenda_financeira_rollback.sql` | Persistência positiva da agenda e parcelas | Aprovado |
| 08B | `supabase/tests/mesa-cliente/engenharia-financeira/08b_validacao_persistencia_agenda_financeira_idempotencia_rollback.sql` | Idempotência e não duplicação | Aprovado |
| 08C | `supabase/tests/mesa-cliente/engenharia-financeira/08c_validacao_persistencia_agenda_financeira_negativos_rollback.sql` | Cenários negativos, grants e bloqueios | Aprovado |
| 08D | `supabase/tests/mesa-cliente/engenharia-financeira/08d_validacao_persistencia_agenda_financeira_operacao_confirmada_rollback.sql` | Bloqueio de substituição quando existe operação confirmada | Aprovado |

---

## 7. Evidência consolidada — 08A

O teste 08A validou a criação de agenda e parcelas persistidas dentro de transação com rollback.

Critérios aceitos:

- RPC retornou `ok = true`;
- fase retornada: `4B_PERSISTENCIA_AGENDA`;
- retorno administrativo com `cliente_safe = false`;
- persistência declarada com `persistencia = true` e `dml_financeiro = true`;
- agenda persistida;
- parcelas persistidas;
- periodicidade simbólica bloqueada;
- datas resolvidas;
- nenhuma operação financeira criada automaticamente;
- rollback preservado.

Resultado consolidado:

> **08A aprovado.**

---

## 8. Evidência consolidada — 08B

O teste 08B validou idempotência.

Critérios aceitos:

- primeira chamada criou agenda;
- segunda chamada com mesmo payload retornou idempotência;
- `agenda_id` permaneceu igual;
- `checksum` permaneceu igual;
- não duplicou agenda;
- não duplicou parcelas;
- não criou operação financeira;
- rollback preservado.

Resultado consolidado:

> **08B aprovado.**

---

## 9. Evidência consolidada — 08C

O teste 08C validou cenários negativos e bloqueios.

Critérios aceitos:

- `anon` sem execute;
- `authenticated` com execute;
- simulação inexistente bloqueada;
- `empresa_id` fake no payload bloqueado;
- `empresa_id` fake em item bloqueado;
- valor negativo bloqueado;
- grupo desconhecido bloqueado;
- periodicidade simbólica fraudada bloqueada;
- periodicidade marcada como negociável bloqueada;
- zero DML em agendas após cenários negativos;
- zero DML em parcelas após cenários negativos;
- zero DML em operações após cenários negativos;
- rollback preservado.

Resultado consolidado:

> **08C aprovado.**

---

## 10. Evidência consolidada — 08D

O teste 08D validou o bloqueio crítico da Fase 4B:

> Uma agenda financeira ativa não pode ser substituída quando já existe operação financeira confirmada para a mesma simulação.

Resultado executado:

| Bloco | Validação | Status |
|---|---|---|
| 01 | Fixture transacional/contexto autorizado | PASS |
| 02 | Primeira chamada criou agenda 4B | PASS |
| 03 | Operação financeira confirmada criada | PASS |
| 04 | Substituição bloqueada por operação confirmada | PASS |
| 05 | Agenda original permaneceu intacta | PASS |
| 06 | Parcelas originais não foram recriadas | PASS |
| 07 | Não criou operação financeira extra | PASS |
| 08 | Contagem final de agendas correta | PASS |
| 09 | Rollback informado | INFO |

Evidência principal:

```text
SQLSTATE 55000
Agenda não pode ser substituída: existe operação financeira confirmada para a simulação
```

Pontos validados:

```text
agenda_id_db = agenda_id_payload1
checksum_db = checksum_payload1
versao_db = 1
qtd_agendas_ativas = 1
parcelas_after = 6
operacoes_after = 1
```

Interpretação:

- a agenda original não foi substituída;
- as parcelas originais não foram recriadas;
- nenhuma operação financeira extra foi criada pela RPC;
- a única operação existente dentro da transação foi a fixture confirmada;
- tudo foi revertido no `ROLLBACK`.

Resultado consolidado:

> **08D aprovado.**

---

## 11. Correções de processo feitas durante a Fase 4B

Durante a validação do 08D, houve erros que foram corrigidos conforme o Protocolo Mestre.

### 11.1. Erro: uso de tabela temporária para armazenar resultados

A primeira versão do 08D usava tabela temporária de resultado e alternância de role com `SET LOCAL ROLE authenticated`.

Problema:

- gerou risco de permissão em `pg_temp`;
- gerou erro de tabela temporária inexistente;
- tornou o teste mais frágil do que a regra testada.

Decisão:

- teste antigo colocado em quarentena;
- 08D reescrito sem tabela temporária de resultado;
- uso de função temporária `pg_temp` retornando `TABLE`;
- `SET LOCAL ROLE authenticated` limitado ao trecho exato da chamada da RPC.

### 11.2. Erro: suposição de colunas inexistentes

Foi evitada a repetição do erro de assumir colunas que não existem em `mesa_simulacoes`, como `cliente_email` e outras colunas não confirmadas.

Decisão:

- usar somente colunas reais confirmadas em preflight;
- não criar fixture baseada em premissa.

### 11.3. Erro: divergência entre nomenclatura comercial e constraint normalizada

O teste tentou inserir `grupo_origem = 'mensais'`, mas a constraint real aceita `mensal`.

Decisão:

- ajustar `grupo_origem` para `mensal`;
- preservar a distinção entre payload comercial (`mensais`) e tabela normalizada de operações (`mensal`).

---

## 12. Estado oficial após a Fase 4B

| Área | Estado |
|---|---|
| Agenda JSON-first 4A | Aprovada |
| Persistência de agenda 4B | Aprovada |
| Idempotência 4B | Aprovada |
| Negativos 4B | Aprovados |
| Bloqueio por operação confirmada 4B | Aprovado |
| Cliente-safe 4C | Ainda não iniciado |
| Operação financeira real 5B | Ainda não iniciado |
| Confirmar/cancelar operação 5C | Ainda não iniciado |
| Front/BFF | Ainda não liberado |

---

## 13. Próxima fase oficial

A próxima fase técnica deve ser:

> **Fase 4C — leitura cliente-safe da agenda financeira persistida.**

A Fase 4C deve expor uma leitura segura da agenda persistida, sem vazar dados administrativos ou sensíveis.

---

## 14. Contrato inicial recomendado para a Fase 4C

A Fase 4C deve começar por contrato e preflight, não por migration direta.

Fluxo recomendado:

1. Criar documento de contrato da Fase 4C;
2. Criar preflight read-only da estrutura necessária;
3. Definir exatamente quais campos podem ser cliente-safe;
4. Definir quais campos ficam proibidos;
5. Criar RPC cliente-safe apenas após validação documental;
6. Criar testes rollback positivos e negativos;
7. Só depois considerar integração BFF/frontend.

---

## 15. Regras de segurança para a Fase 4C

A leitura cliente-safe **não pode expor**:

- VPL;
- prêmio;
- comissão;
- política comercial interna;
- taxa interna sensível;
- metadados administrativos;
- `empresa_id` como autoridade de cliente;
- dados de auditoria interna;
- flags administrativas de elegibilidade;
- justificativas internas de bloqueio que revelem regra comercial sensível;
- payload bruto vindo da tabela comercial, caso contenha metadados internos.

A leitura cliente-safe pode expor, mediante contrato:

- grupos de pagamento;
- descrições comerciais limpas;
- valores das parcelas;
- datas de vencimento;
- quantidade de parcelas;
- valor total da agenda;
- resumo comercial da condição;
- avisos neutros e seguros para cliente;
- indicação de que certos itens não são negociáveis sem explicar política interna sensível.

---

## 16. Critério de aceite para abrir a Fase 4C

A Fase 4C só deve avançar se:

- Fase 4B permanecer aprovada;
- documentação de contrato da 4C estiver criada;
- preflight read-only da 4C estiver executado;
- campos cliente-safe e campos proibidos estiverem definidos;
- RPC nova não conceder execute para `anon`, salvo decisão formal futura e justificada;
- retorno for explicitamente `cliente_safe = true`;
- testes provarem ausência de vazamento de dados sensíveis;
- testes negativos validarem cross-tenant, auth ausente e simulação inexistente.

---

## 17. Frase de controle para próximas conversas

Ao iniciar nova conversa técnica sobre este ponto, usar:

> A Fase 4B da Engenharia Financeira do MesaCliente foi aprovada em rollback transacional. Os testes 08A, 08B, 08C e 08D passaram. O próximo passo é abrir a Fase 4C com contrato e preflight read-only para leitura cliente-safe da agenda persistida. Não mexer em frontend, parser, Worker, Make/n8n ou operação financeira real antes da 4C estar validada.

---

## 18. Decisão final

A Fase 4B está encerrada para o escopo atual.

Próximo movimento permitido:

> Criar o contrato documental da Fase 4C — Agenda financeira cliente-safe.

Qualquer tentativa de avançar direto para frontend, BFF, operação financeira, VPL, prêmio, comissão ou política comercial deve ser bloqueada pelo Protocolo Mestre.
