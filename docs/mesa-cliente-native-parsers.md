# Mesa Cliente — Parsers nativos

Checkpoint técnico da frente **Mesa Cliente Native First** no FECH.AI.

Este documento registra o baseline validado dos parsers nativos de tabelas comerciais, com foco em execução determinística, barata e sem dependência obrigatória de Make/IA para os layouts já conhecidos.

---

## Objetivo

O Mesa Cliente deve conseguir ler tabelas comerciais em PDF/texto e transformar o conteúdo em uma estrutura canônica de unidades e fluxo financeiro.

A prioridade arquitetural é:

1. detectar o layout da tabela;
2. executar o parser nativo correspondente;
3. validar quantidade de unidades e consistência financeira;
4. usar Worker/Make apenas como fallback quando o parser nativo não conseguir gerar linhas úteis.

Esse desenho reduz custo, latência e imprevisibilidade. O Make continua existindo como contingência, não como primeira escolha para tabelas já aprendidas.

---

## Escopo atual validado

| Arquivo / Empreendimento | Layout detectado | Parser nativo | Status |
|---|---|---|---|
| Garden Design Abril — Tabela Comercial | `range_by_final_table` | `parseRangeByFinalTable` | OK |
| Garden Design Maio — Original/Espelho Oficial | `split_block_table` | `parseSplitBlockTable` | OK |
| Nova Vivere Abril 2026 | `range_by_final_table` | `parseRangeByFinalTable` | OK |
| Capitolo by Piero Lissoni | `split_block_table` | `parseSplitBlockTable` | OK |
| ELO Duo — Caminhos da Lapa | `ready_stock_table` | `parseReadyStockTable` | OK |
| Mozae Higienópolis Maio 2026 | `split_block_table` | `parseSplitBlockTable` | OK |

Esses seis arquivos passam a ser baseline de regressão funcional. Qualquer mudança futura em parser deve preservar o funcionamento desses casos antes de ser considerada segura.

---

## Arquivos principais

| Arquivo | Responsabilidade |
|---|---|
| `src/mesa/layoutDetector.js` | Detecta o tipo de layout antes do roteamento para parser. |
| `src/pages/MesaClienteNativeFirst.jsx` | Orquestra a leitura Native First e decide quando usar fallback. |
| `src/mesa/parsers/parseRangeByFinalTable.js` | Parser para tabelas por final/faixa de andar. |
| `src/mesa/parsers/parseSplitBlockTable.js` | Parser para espelhos oficiais/split block Tegra. |
| `src/mesa/parsers/parseReadyStockTable.js` | Parser para estoque/pronto para morar com ato + financiamento. |
| `src/mesa/validators/validateCanonRow.js` | Validação estrutural e financeira da linha canônica. |

---

## Layouts suportados

### 1. `range_by_final_table`

Usado para tabelas comerciais onde a disponibilidade é organizada por **final** e **faixa de andar**.

Exemplos de comportamento esperado:

- Final 13 + 32º a 34º andar gera AP3213, AP3313 e AP3413.
- Final 01 + 1º e 2º andar gera AP0101 e AP0201.
- Final 05/06 + 4º e 5º andar gera AP0405, AP0505, AP0406 e AP0506.

Empreendimentos validados:

- Garden Design Abril — Comercial.
- Nova Vivere Abril 2026.

Características importantes:

- O parser não deve depender de quantidade fixa de parcelas.
- A quantidade de mensais, intermediárias, complemento de ato e financiamento deve ser lida da própria tabela.
- Falsos cabeçalhos, como sequências de vagas/unidades em espelhos, não podem ser aceitos como plano financeiro.

---

### 2. `split_block_table`

Usado para tabelas oficiais no modelo de **espelho de vendas** ou blocos separados por unidade e fluxo financeiro.

Empreendimentos validados:

- Garden Design Maio — Original/Espelho Oficial.
- Capitolo by Piero Lissoni.
- Mozae Higienópolis Maio 2026.

Modos internos relevantes:

| Modo | Quando ocorre |
|---|---|
| `inline_financial_rows` | Quando a própria linha já contém unidade + todos os campos financeiros. |
| `split_blocks_by_index` | Quando unidades e valores financeiros precisam ser casados por posição. |
| `split_blocks_by_index_status_marker_7` | Quando há 7 valores financeiros por unidade e o 7º é um marcador/status, como `$1,000.00`, que deve ser ignorado. |

Ponto crítico aprendido no Lissoni/Mozae:

Algumas tabelas Tegra trazem um valor marcador/status no fim da linha financeira. Esse valor não faz parte do fluxo do cliente. Se ele for tratado como parcela, desloca todas as colunas seguintes e causa troca de valores entre sinal, mensal, financiamento e total.

Regra implementada:

```txt
sinal
complemento
mensal
intermediária
parcela única
financiamento
marcador/status de disponibilidade ← ignorado
```

No Mozae Higienópolis, o plano financeiro lido pelo parser foi:

```txt
1 SINAL ATO
3 COMPLEMENTO ATO
15 MENSAL(IS)
2 INTERMEDIARIA SEMESTRAL(IS)
1 PARCELA ÚNICA
1 FINANCIAMENTO BANCÁRIO
1 FINAL(IS) / marcador de disponibilidade ignorado no fluxo
```

O parser validou 60 unidades em duas páginas de espelho financeiro, com `invalid_rows=0`, `finance_stride=7` e modo `split_blocks_by_index_status_marker_7`.

---

### 3. `ready_stock_table`

Usado para estoque/pronto para morar, onde não existe fluxo longo de obra.

Empreendimento validado:

- ELO Duo — Caminhos da Lapa.

Regra financeira atual:

- ATO pode chegar a aproximadamente 30%.
- FINANCIAMENTO representa o saldo.
- Mensais = 0.
- Intermediárias = 0.
- Complemento de ato = 0.
- Chaves/parcela única = 0.

Esse parser não deve forçar campos inexistentes apenas para encaixar no padrão de obras futuras. Estoque pronto tem lógica própria.

---

## Colunas canônicas

Os parsers nativos devem produzir a mesma estrutura canônica, mesmo quando o layout de origem for diferente.

```txt
empreendimento
torre
final
andar
unidade
area_m2
preco_total
sinal_1
a4_each
mensal_qtd
mensal_each
inter_tipo
inter_qtd
inter_each
chaves_each
financiamento
observacoes
```

A coluna `observacoes` é usada também como trilha técnica de auditoria, contendo dados como:

- quantidade de parcelas lidas;
- datas de início quando disponíveis;
- origem do plano financeiro;
- modo interno do parser;
- diferença de validação entre soma do fluxo e valor total.

---

## Regra de negócio: parcelas e data

A quantidade de parcelas deve vir da **tabela carregada**, não da data atual do sistema.

Motivo: a tabela é o documento comercial soberano no momento da leitura.

Exemplos:

- Se a tabela diz 44 mensais e 4 intermediárias, o Mesa Cliente calcula 44 e 4.
- Se a tabela do mês seguinte diz 43 mensais e 4 intermediárias, calcula 43 e 4.
- Se uma tabela futura diz 0 intermediárias, calcula 0.
- Se uma tabela antiga for carregada daqui a dois anos, o sistema deve respeitar o fluxo da tabela e, futuramente, apenas alertar que a tabela pode estar desatualizada.

Não recalcular automaticamente a quantidade de parcelas pela data atual, porque isso pode adulterar uma tabela real recebida de forma retroativa, comercial ou excepcional.

---

## Validação financeira

Cada linha deve passar por uma validação de soma do fluxo:

```txt
preco_total ≈
  sinal_1 * ato_qtd
+ a4_each * complemento_qtd
+ mensal_each * mensal_qtd
+ inter_each * inter_qtd
+ chaves_each * unica_qtd
+ financiamento * financiamento_qtd
```

A validação aceita pequena tolerância por arredondamento, especialmente em tabelas com muitas parcelas.

Inconsistência financeira não deve ser escondida. Quando houver divergência relevante, o parser deve marcar a linha como inválida ou indicar problema no diagnóstico.

---

## Fallback Worker/Make

O fallback deve ser acionado apenas quando:

- o layout não for reconhecido;
- o parser nativo não retornar linhas;
- o arquivo vier em um formato ainda não aprendido;
- a extração de texto do PDF falhar de forma estrutural.

O fallback não deve substituir o parser nativo quando o layout já estiver validado.

Regra prática:

```txt
Parser nativo funcionou → não aciona Make.
Parser nativo não gerou linhas úteis → pode acionar fallback.
```

---

## Regressão obrigatória

Antes de mexer em qualquer parser existente, testar novamente:

1. Garden Design Abril — Comercial.
2. Garden Design Maio — Original/Espelho Oficial.
3. Nova Vivere Abril 2026.
4. Capitolo by Piero Lissoni.
5. ELO Duo — Caminhos da Lapa.
6. Mozae Higienópolis Maio 2026.

Critérios mínimos esperados:

- layout correto detectado;
- parser nativo acionado;
- Make não acionado nos seis casos validados;
- quantidade de unidades compatível com o arquivo;
- fluxo financeiro sem troca de colunas;
- inconsistências bloqueantes zeradas ou justificadas por arredondamento/documento.

---

## Próximas melhorias recomendadas

### 1. Quadro visual de Resumo da leitura

Adicionar na UI um quadro claro com:

- arquivo lido;
- layout detectado;
- parser utilizado;
- total de unidades comerciais;
- quantidade de linhas filtradas/ignoradas;
- plano financeiro identificado;
- inconsistências encontradas;
- status Native First / Worker / Make.

### 2. Suíte automatizada de regressão

Criar testes automatizados com fixtures baseadas nos seis PDFs validados.

A suíte deve falhar quando:

- o layout detectado mudar indevidamente;
- o parser nativo deixar de retornar unidades;
- a quantidade de unidades cair ou explodir;
- colunas financeiras forem trocadas;
- o fallback for acionado em arquivo já suportado.

### 3. Alerta de tabela possivelmente desatualizada

No futuro, implementar alerta consultivo comparando:

- mês/ano da tabela;
- data atual;
- data de entrega/chaves/financiamento quando disponível.

Esse alerta deve ser informativo, não deve alterar automaticamente o fluxo financeiro lido da tabela.

---

## Princípio de proteção

Não quebrar o que já está funcionando.

Novos parsers devem ser adicionados de forma incremental, sem mexer no comportamento dos layouts já validados, salvo quando houver correção específica acompanhada de regressão completa.
