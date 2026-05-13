# Mesa Cliente — Native First Production Baseline

Checkpoint técnico da frente **Mesa Cliente Native First** no FECH.AI.

Este documento registra o baseline validado dos parsers nativos de tabelas comerciais, com foco em execução determinística, barata e sem dependência obrigatória de Make/IA para os layouts já conhecidos.

---

## Objetivo

O Mesa Cliente deve conseguir ler tabelas comerciais em PDF/texto e transformar o conteúdo em uma estrutura canônica de unidades e fluxo financeiro.

A prioridade arquitetural é:

1. detectar o layout da tabela;
2. executar o parser nativo correspondente;
3. validar quantidade de unidades e consistência financeira;
4. bloquear proposta quando houver ausência de dados financeiros ou inconsistência relevante;
5. usar Worker/Make apenas como fallback quando o parser nativo não conseguir gerar linhas úteis e quando o arquivo não for um caso conhecido/bloqueável.

Esse desenho reduz custo, latência e imprevisibilidade. O Make continua existindo como contingência, não como primeira escolha para tabelas já aprendidas.

---

## Decisão de release

Baseline aprovado para rollout controlado em produção sob o marco:

```txt
Mesa Cliente — Native First Production Release
```

Regras do rollout:

- preservar rollback para a versão anterior;
- manter `feature/mesa-garden-commercial-range-parser` como branch de origem do release;
- consolidar em `main` apenas após checklist mínimo;
- validar em produção com arquivos sentinela antes de uso amplo.

Arquivos sentinela pós-deploy:

1. Garden Design Maio — valida fluxo completo com complemento, mensais, intermediárias, parcela única, financiamento e marcador.
2. Ária Higienópolis — valida fluxo compacto ATO + financiamento + final/periodicidade.
3. Bueno Brandão 257 sem valores — valida bloqueio correto de espelho sem dados financeiros.

---

## Escopo atual validado

| Arquivo / Empreendimento | Layout detectado | Parser / comportamento | Status |
|---|---|---|---|
| Garden Design Abril — Tabela Comercial | `range_by_final_table` | `parseRangeByFinalTable` | OK |
| Garden Design Maio — Original/Espelho Oficial | `split_block_table` | `parseSplitBlockTable` | OK |
| Nova Vivere Abril 2026 | `range_by_final_table` | `parseRangeByFinalTable` | OK |
| Capitolo by Piero Lissoni | `split_block_table` | `parseSplitBlockTable` | OK |
| ELO Duo — Caminhos da Lapa | `ready_stock_table` | `parseReadyStockTable` | OK |
| Mozae Higienópolis Maio 2026 | `split_block_table` | `parseSplitBlockTable` | OK |
| Bem Moema Studios & Offices | `split_block_table` | `parseSplitBlockTable` compacto | OK |
| Universo Tatuapé Órbita | `split_block_table` | `parseSplitBlockTable` compacto | OK |
| Bueno Brandão Studios | `split_block_table` | `parseSplitBlockTable` compacto com parcela única | OK |
| Bueno Brandão 257 — espelho sem valores | `sales_mirror_without_values` | bloqueio nativo sem fallback | OK |
| Ária Higienópolis | `split_block_table` | `parseSplitBlockTable` compacto | OK |

Esses arquivos passam a ser baseline de regressão funcional. Qualquer mudança futura em parser deve preservar o funcionamento desses casos antes de ser considerada segura.

---

## Arquivos principais

| Arquivo | Responsabilidade |
|---|---|
| `src/mesa/layoutDetector.js` | Detecta o tipo de layout antes do roteamento para parser. |
| `src/pages/MesaClienteNativeFirst.jsx` | Orquestra a leitura Native First, bloqueios e fallback. |
| `src/mesa/parsers/parseRangeByFinalTable.js` | Parser para tabelas por final/faixa de andar. |
| `src/mesa/parsers/parseSplitBlockTable.js` | Parser para espelhos oficiais/split block Tegra. |
| `src/mesa/parsers/parseReadyStockTable.js` | Parser para estoque/pronto para morar com ato + financiamento. |
| `src/mesa/validators/validateCanonRow.js` | Validação estrutural e financeira da linha canônica. |
| `src/mesa/mirror/parsePortalVWebMirror.js` | Leitura de espelho/disponibilidade quando usado como arquivo auxiliar. |
| `src/mesa/mirror/reconcileUnitsWithMirror.js` | Conciliação entre tabela financeira e espelho de disponibilidade. |

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
- Bem Moema Studios & Offices.
- Universo Tatuapé Órbita.
- Bueno Brandão Studios.
- Ária Higienópolis.

Modos internos relevantes:

| Modo | Quando ocorre |
|---|---|
| `inline_financial_rows` | Quando a própria linha já contém unidade + todos os campos financeiros. |
| `split_blocks_by_index` | Quando unidades e valores financeiros precisam ser casados por posição. |
| `split_blocks_by_index_status_marker_7` | Quando há 7 valores financeiros por unidade e o 7º é marcador/status de disponibilidade. |
| `split_blocks_ato_financiamento_final_obs_3` | Fluxo compacto: sinal/ato + financiamento + final/periodicidade em observação. |
| `split_blocks_ato_unica_final_financiamento_4` | Fluxo compacto: sinal/ato + parcela única + final/periodicidade em observação + financiamento. |

#### Modelo completo com marcador/status

Regra implementada:

```txt
sinal
complemento
mensal
intermediária
parcela única
financiamento
marcador/status de disponibilidade ← ignorado no fluxo financeiro
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

O parser validou o casamento posicional dos valores com modo `split_blocks_by_index_status_marker_7`.

#### Modelo compacto ATO + FINANCIAMENTO + FINAL

Regra implementada:

```txt
sinal_1 = valor do ATO
financiamento = valor do financiamento
periodicidade/final = observacoes
```

O valor de `FINAL(IS)` / periodicidade não cria campo novo. Ele fica em `observacoes`:

```txt
periodicidade_qtd=1 | periodicidade_valor=1000 | periodicidade_data=AAAA-MM-DD
```

Validados por esse padrão:

- Bem Moema Studios & Offices.
- Universo Tatuapé Órbita.
- Ária Higienópolis.

#### Modelo compacto com parcela única

Regra implementada:

```txt
sinal_1 = valor do ATO
chaves_each = parcela única
periodicidade/final = observacoes
financiamento = financiamento bancário
```

Modo interno:

```txt
split_blocks_ato_unica_final_financiamento_4
```

Validado por:

- Bueno Brandão Studios.

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

### 4. `sales_mirror_without_values`

Usado para arquivos que são espelhos de disponibilidade/estoque, mas **não contêm valores financeiros**.

Exemplo validado:

- Bueno Brandão 257 — espelho com APs, áreas e vagas, mas sem valor total, sinal/ato e financiamento.

Comportamento esperado:

- detectar nativamente;
- não acionar Worker/Make;
- não gerar CSV financeiro incompleto;
- exibir mensagem clara para o usuário;
- bloquear Mesa Cliente financeira.

Mensagem operacional:

```txt
Este arquivo é um espelho de vendas com unidades, áreas e vagas, mas não contém valores financeiros. Envie a tabela comercial com valor total, sinal/ato e financiamento para montar a Mesa do Cliente.
```

Esse arquivo pode ser útil futuramente como espelho auxiliar de disponibilidade, mas não serve sozinho para proposta financeira.

---

## Tipos de unidades selecionáveis

A Mesa Cliente não deve ser centrada apenas em apartamentos.

Unidades aceitas na UI:

```txt
AP0000 = apartamento
SC0000 = sala comercial
SU0000 = studio
LJ0000 = loja
```

Regex operacional:

```txt
/^(AP|SC|SU|LJ)\d{4}$/i
```

Motivo: tabelas como Bem Moema e Ária Higienópolis misturam residenciais, studios, salas comerciais e/ou lojas.

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
- periodicidade/final quando for informação complementar;
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

Inconsistência financeira não deve ser escondida. Quando houver divergência relevante, o parser deve marcar a linha como inválida e a UI deve bloquear a proposta.

Princípio:

```txt
Cair no parser errado e falhar é aceitável.
Cair no parser errado, montar valores trocados e não avisar é inaceitável.
```

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
Arquivo conhecido sem valores financeiros → bloqueia sem Make.
Parser nativo não gerou linhas úteis em layout desconhecido → pode acionar fallback.
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
7. Bem Moema Studios & Offices.
8. Universo Tatuapé Órbita.
9. Bueno Brandão Studios.
10. Bueno Brandão 257 — espelho sem valores.
11. Ária Higienópolis.

Critérios mínimos esperados:

- layout correto detectado;
- parser nativo acionado quando o layout já é conhecido;
- Make não acionado nos casos validados nativos;
- quantidade de unidades compatível com o arquivo;
- fluxo financeiro sem troca de colunas;
- inconsistências bloqueantes zeradas ou justificadas por arredondamento/documento;
- espelho sem valores bloqueado antes de fallback.

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

### 2. Composição percentual do fluxo

Adicionar leitura comercial por unidade:

```txt
% sinal/ato
% complemento
% mensais
% intermediárias
% parcela única
% financiamento
```

Fórmula:

```txt
percentual = etapa / preco_total * 100
```

Isso deve permitir frases automáticas como:

```txt
Fluxo identificado: 40% durante obra + 60% financiamento.
```

### 3. Ocultar cards zerados

Na UI, ocultar cards financeiros com valor zero quando não fizerem sentido para o fluxo carregado, reduzindo poluição visual para modelos compactos.

### 4. Suíte automatizada de regressão

Criar testes automatizados com fixtures baseadas nos PDFs validados.

A suíte deve falhar quando:

- o layout detectado mudar indevidamente;
- o parser nativo deixar de retornar unidades;
- a quantidade de unidades cair ou explodir;
- colunas financeiras forem trocadas;
- o fallback for acionado em arquivo já suportado.

### 5. Alerta de tabela possivelmente desatualizada

No futuro, implementar alerta consultivo comparando:

- mês/ano da tabela;
- data atual;
- data de entrega/chaves/financiamento quando disponível.

Esse alerta deve ser informativo, não deve alterar automaticamente o fluxo financeiro lido da tabela.

---

## Princípio de proteção

Não quebrar o que já está funcionando.

Novos parsers devem ser adicionados de forma incremental, sem mexer no comportamento dos layouts já validados, salvo quando houver correção específica acompanhada de regressão completa.
