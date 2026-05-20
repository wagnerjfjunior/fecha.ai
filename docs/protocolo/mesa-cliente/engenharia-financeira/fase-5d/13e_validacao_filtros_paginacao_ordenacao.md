# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 5D — 13E: filtros, paginação e ordenação

**Arquivo de teste:**

```text
supabase/tests/mesa-cliente/engenharia-financeira/13e_validacao_filtros_paginacao_ordenacao_leitura_operacoes_admin_rollback.sql
```

**Status:** VALIDADO

**Resultado:** todos os blocos obrigatórios retornaram `PASS`; bloco final `99_rollback_notice` retornou `INFO`.

---

## Objetivo da validação

Validar que a RPC administrativa de leitura de operações financeiras da Fase 5D aplica corretamente:

- filtro por `agenda_id`;
- filtro por `status_operacao`;
- filtro por `tipo_operacao`;
- filtro por `visivel_cliente`;
- filtro por `data_de` e `data_ate`;
- paginação `limit` / `offset`;
- ordenação por `status_operacao` ascendente e descendente;
- ordenação por `tipo_operacao` ascendente e descendente;
- bloqueios de allowlist para `order_by` e `order_dir`;
- bloqueios de entrada inválida para `offset`, datas e booleanos.

---

## Ajustes necessários antes da validação final

Durante a execução do 13E, a massa inicial do teste revelou duas falhas de fixture, não da RPC 5D:

### 1. Postergação com data destino fixa

Erro observado:

```text
Postergação exige data destino posterior à data atual da parcela.
```

Causa:

- a fixture usava uma data fixa para `data_destino`;
- dependendo da parcela selecionada pela 4B, a data atual da parcela podia ser igual ou posterior à data destino;
- isso violava a regra soberana da RPC 5B.

Correção aplicada:

- remover data mágica/fixa;
- calcular `data_destino` a partir da própria parcela selecionada:

```sql
parcela_3.data_atual + interval '60 days'
```

### 2. Parcela selecionada com grupo incompatível com política financeira

Erro observado:

```text
Política financeira não permite antecipação para o grupo da parcela.
```

Causa:

- o teste selecionava parcelas apenas por flags genéricas;
- a RPC 5B valida o grupo financeiro normalizado da parcela contra a política;
- selecionar parcela sem respeitar o grupo permitido contaminava a fixture.

Correção aplicada:

- adicionar normalização temporária de grupo no teste;
- selecionar parcelas somente com grupo normalizado permitido pela 5B:

```text
financiamento
chaves
anuais
mensais
```

---

## Resultado executado

### Setup e fixture

| Bloco | Status | Observação |
|---|---:|---|
| `00_setup_fixture_13e` | PASS | Simulação, política e faixas criadas em transação |
| `00b_agenda_parcelas_fixture_13e` | PASS | Parcelas selecionadas com grupos permitidos |
| `01_fixture_5b_5c_preparada_para_filtros` | PASS | 4 operações criadas: confirmada, cancelada e simuladas |

### Validações positivas

| Bloco | Status | Cobertura |
|---|---:|---|
| `02_listagem_base_e_agenda_id` | PASS | Listagem base e filtro por agenda |
| `03_filtro_status_operacao` | PASS | `confirmada`, `cancelada`, `simulada` |
| `04_filtro_tipo_operacao` | PASS | `antecipacao`, `postergacao`, `vpl` |
| `05_filtros_visibilidade_e_data` | PASS | `visivel_cliente`, `data_de`, `data_ate` |
| `06_paginacao_limit_offset` | PASS | `limit=2`, `offset=0/2`, sem interseção entre páginas |
| `07_order_by_status_operacao_asc_desc` | PASS | Ordenação ascendente e descendente por status |
| `08_order_by_tipo_operacao_asc_desc` | PASS | Ordenação ascendente e descendente por tipo |

### Validações negativas / segurança de entrada

| Bloco | Status | Bloqueio validado |
|---|---:|---|
| `09a_order_by_invalido_bloqueado` | PASS | `order_by` fora da allowlist |
| `09b_order_dir_invalido_bloqueado` | PASS | `order_dir` inválido |
| `09c_offset_negativo_bloqueado` | PASS | `offset < 0` |
| `09d_data_de_formato_invalido_bloqueada` | PASS | `data_de` fora de `YYYY-MM-DD` |
| `09e_data_ate_formato_invalido_bloqueada` | PASS | `data_ate` fora de `YYYY-MM-DD` |
| `09f_data_de_maior_que_data_ate_bloqueada` | PASS | intervalo de datas invertido |
| `09g_visivel_cliente_nao_booleano_bloqueado` | PASS | `visivel_cliente` enviado como string |
| `99_rollback_notice` | INFO | Fixture transacional encerrada com `ROLLBACK` |

---

## Conclusão técnica

A validação 13E foi aprovada.

A RPC de leitura administrativa da Fase 5D demonstrou comportamento esperado para filtros, paginação, ordenação e bloqueio de parâmetros inválidos.

A fixture do teste passou a respeitar as regras soberanas das fases anteriores:

- 4B como fonte de criação da agenda;
- 5B como fonte de criação das operações financeiras;
- 5C como fonte de alteração de status;
- 5D apenas como leitura administrativa.

Não houve evidência de falha na RPC 5D durante o 13E.

---

## Próximo passo recomendado

Prosseguir para o próximo item da Fase 5D, mantendo a ordem do contrato/protocolo e sem reabrir o motor financeiro, salvo se novo teste apontar falha concreta.
