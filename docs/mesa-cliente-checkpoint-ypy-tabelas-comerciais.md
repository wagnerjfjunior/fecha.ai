# Mesa Cliente — Checkpoint YPY, Tabelas Comerciais e Tabelas Técnicas

Checkpoint para continuidade em nova conversa.

Data do contexto: 2026-05-12 / 2026-05-13.
Projeto: **FECH.AI / Mesa Cliente Native First**.

---

## Resumo executivo

O Mesa Cliente já validou diversos modelos de tabela comercial com parser nativo, sem depender de Make/IA nos layouts conhecidos.

O ponto atual da conversa é o arquivo:

```txt
YPY Alto do Ipiranga - Tabela_Maio_2026.pdf
```

Esse arquivo caiu inicialmente em fallback Worker/Make e, depois de tentativa de correção parcial, ainda não deve ser considerado validado em produção.

O problema conceitual corrigido durante a conversa:

```txt
Tabela técnica ≠ tabela comercial
```

A tabela técnica/espelho/ficha é um documento diferente da tabela comercial. Ela pode conter unidade, área, vaga, final, pavimento, tipologia e disponibilidade, mas não necessariamente contém fluxo financeiro.

A tabela comercial é o documento soberano para montar proposta no Mesa Cliente, porque contém valor total e fluxo financeiro.

---

## Regra conceitual definitiva

O Mesa Cliente deve classificar o arquivo carregado pelo tipo de documento:

```txt
1. Tabela comercial / financeira
   Pode montar proposta.

2. Tabela técnica / espelho / ficha sem valores financeiros
   Deve bloquear proposta, sem acionar Make.

3. Tabela desconhecida ou ainda não aprendida
   Pode acionar fallback Worker/Make.
```

### Tabela comercial / financeira

Sinais fortes:

```txt
UNIDADE
ÁREA
ATO / SINAL
COMPLEMENTO ATO
MENSAIS
INTERMEDIÁRIAS
PARCELA ÚNICA
FINANCIAMENTO
VALOR TOTAL / TOTAL
```

Comportamento esperado:

- parser nativo quando o layout já foi aprendido;
- gerar CSV canônico;
- validar soma financeira;
- bloquear se houver troca de coluna ou ausência de campo essencial;
- não usar Make quando o parser nativo resolver.

### Tabela técnica / espelho / ficha

Sinais fortes:

```txt
andar
pavimento
unidade
área
vagas
tipologia
final
status
disponibilidade
```

Mas sem:

```txt
valor total
ato/sinal
financiamento
fluxo financeiro
```

Comportamento esperado:

- detectar como documento técnico/espelho sem valores;
- bloquear Mesa Cliente financeira;
- não acionar Worker/Make;
- exibir mensagem clara pedindo tabela comercial.

Mensagem operacional sugerida:

```txt
Este arquivo parece ser uma tabela técnica/espelho, mas não contém valores financeiros. Envie a tabela comercial com valor total, ato/sinal e financiamento para montar a Mesa do Cliente.
```

---

## Baseline validado antes do YPY

Os seguintes modelos foram considerados funcionando durante a conversa e devem entrar na suíte de regressão:

| Empreendimento / Arquivo | Layout esperado | Motor esperado | Status |
|---|---|---|---|
| Garden Design Abril — Comercial | `range_by_final_table` | Parser nativo | OK |
| Garden Design Maio — Oficial/Original | `range_by_final_table` ou `split_block_table`, conforme extração | Parser nativo | OK |
| Nova Vivere Abril 2026 | `range_by_final_table` | Parser nativo | OK |
| Capitolo by Piero Lissoni | `split_block_table` | Parser nativo | OK |
| ELO Duo — Caminhos da Lapa | `ready_stock_table` | Parser nativo | OK |
| Mozae Higienópolis Maio 2026 | `split_block_table` | Parser nativo | OK |
| Bem Moema Studios & Offices | `split_block_table` | Parser nativo | OK |
| Universo Tatuapé Órbita | `split_block_table` | Parser nativo | OK |
| Bueno Brandão Studios | `split_block_table` | Parser nativo | OK |
| Bueno Brandão 257 — espelho sem valores | `sales_mirror_without_values` | Bloqueio nativo sem Make | OK |
| Ária Higienópolis | `split_block_table` | Parser nativo | OK |

Regra: qualquer novo ajuste precisa preservar esse baseline.

---

## Caso YPY Alto do Ipiranga

### Sintoma informado

Arquivo:

```txt
YPY Alto do Ipiranga - Tabela_Maio_2026.pdf
```

Resultado ruim observado:

```txt
Layout: hierarchical_tegra
Motor: Fallback Worker/Make
Confiança: 86%
Motivo: Detectados Final/Garden/faixas de andar e colunas financeiras.
Tabela processada, mas nenhuma unidade AP/SC/SU/LJ comercial foi identificada.
```

Antes disso, em outro teste, o fallback quase montou os campos corretamente, mas faltou preservar a data da parcela única:

```txt
ÚNICA 11/2026
```

O valor da parcela única veio no fluxo, mas a data/metadado não apareceu corretamente no card/observações.

### Diagnóstico

O YPY é uma **tabela comercial flat de lançamento**, não uma tabela `hierarchical_tegra`.

Modelo lógico do YPY:

```txt
UNIDADE | ÁREA | ATO | COMPLEMENTO ATO | MENSAIS | ÚNICA 11/2026 | FINANCIAMENTO | TOTAL
```

Mapeamento canônico esperado:

```txt
unidade       = APxxxx
area_m2       = ÁREA
sinal_1       = ATO
a4_each       = COMPLEMENTO ATO
mensal_qtd    = 1
mensal_each   = MENSAIS
inter_qtd     = 0
inter_each    = 0
chaves_each   = ÚNICA
financiamento = FINANCIAMENTO
preco_total   = TOTAL
observacoes   = unica_mes=2026-11;unica_label=11/2026
```

### Resultado esperado após correção final

```txt
Layout: split_block_table ou launch_flat_payment_table
Motor: Parser nativo — sem Make/IA
Confiança: ~93%
```

No diagnóstico técnico:

```txt
worker_used: false
make_used: false
engine: parseSplitBlockTable ou parseLaunchFlatPaymentTable
parser_mode: launch_flat_payment_table
```

No card:

```txt
Chaves
Parcela única — 11/2026
```

---

## Estado real do código após esta conversa

### Arquivos relacionados

| Arquivo | Status observado |
|---|---|
| `src/mesa/layoutDetector.js` | Foi alterado para tentar rotear tabela de lançamento antes de `hierarchical_tegra`. Validar em regressão. |
| `src/mesa/parsers/parseLaunchFlatPaymentTable.js` | Arquivo criado. Contém parser especializado para modelo YPY/launch flat. Ainda precisa validar regex com extração real do PDF. |
| `src/mesa/parsers/parseSplitBlockTable.js` | No estado lido após a conversa, ainda **não** estava com a delegação para `parseLaunchFlatPaymentTable` aplicada. |
| `src/pages/MesaClienteNativeFirst.jsx` | Teve enriquecimento para `ÚNICA MM/AAAA` em fallback, mas isso não resolve o caso YPY se o parser cair em caminho errado antes. |

### Importante

Não considerar o YPY como fechado até executar novo teste real e confirmar:

```txt
Motor: Parser nativo — sem Make/IA
unidades comerciais identificadas
chaves_each preenchido
unica_label=11/2026 em observacoes
sem inconsistência bloqueante indevida
```

---

## Correção técnica pendente recomendada

A opção mais segura é **não mexer no Make** e **não mexer nos parsers já estáveis** além de um encaixe controlado.

### 1. `src/mesa/layoutDetector.js`

A regra de tabela comercial flat de lançamento deve rodar antes de `hierarchical_tegra`.

Condição esperada:

```js
if (
  has("unidade") &&
  has("area") &&
  has("ato") &&
  has("complemento ato") &&
  has("mensais") &&
  hasAny("unica", "única") &&
  has("financiamento") &&
  has("total") &&
  hasSelectableUnit
) {
  return {
    layout: "split_block_table",
    confidence: 0.93,
    reason: "Detectada tabela de lançamento com ATO, complemento, mensal, parcela única, financiamento e total em linha.",
  };
}
```

Observação: usar `split_block_table` como rota evita mexer em `MesaClienteNativeFirst.jsx`, desde que o `parseSplitBlockTable` delegue internamente.

### 2. `src/mesa/parsers/parseSplitBlockTable.js`

Adicionar import:

```js
import { parseLaunchFlatPaymentTable } from "./parseLaunchFlatPaymentTable";
```

Adicionar helper depois de `normalizeForMatch`:

```js
function looksLikeLaunchFlatPaymentTable(text = "") {
  const t = normalizeForMatch(text);

  return (
    t.includes("unidade") &&
    t.includes("area") &&
    t.includes("ato") &&
    t.includes("complemento ato") &&
    t.includes("mensais") &&
    t.includes("unica") &&
    t.includes("financiamento") &&
    t.includes("total") &&
    /\b(AP|SC|SU|LJ)\d{4}\b/i.test(String(text || ""))
  );
}
```

No começo de `parseSplitBlockTable`, imediatamente após:

```js
const source = compactSpaces(text);
if (!source) return { rows: [], csvText: CANON_COLUMNS.join(";"), diagnostics: { reason: "empty_source" } };
```

inserir:

```js
if (looksLikeLaunchFlatPaymentTable(source)) {
  const launch = parseLaunchFlatPaymentTable(source, options);

  if (launch.rows.length) {
    return {
      ...launch,
      diagnostics: {
        ...launch.diagnostics,
        parser: "parseSplitBlockTable",
        delegated_parser: "parseLaunchFlatPaymentTable",
        parser_mode: "launch_flat_payment_table",
      },
    };
  }
}
```

### 3. `src/mesa/parsers/parseLaunchFlatPaymentTable.js`

Arquivo já existe, mas precisa ser validado contra o texto real extraído do PDF do YPY.

Pontos de atenção:

- A regex atual pode estar rígida demais se o PDF extrair os valores sem `R$` em todas as colunas.
- Precisa aceitar `AP`, `SC`, `SU`, `LJ`, não apenas `AP`, se o padrão for reaproveitado.
- A data `ÚNICA 11/2026` deve virar:

```txt
unica_mes=2026-11
unica_label=11/2026
```

- `mensal_qtd=1` só é válido para o YPY se a coluna `MENSAIS` representar um único mês. Se a tabela trouxer quantidade explícita futuramente, a quantidade deve vir do cabeçalho/documento.

---

## Ordem correta de prioridade dos parsers

Ordem recomendada:

```txt
1. Tabela comercial flat de lançamento
   Ex.: YPY — unidade, área, ato, complemento ato, mensais, única, financiamento, total.

2. range_by_final_table
   Ex.: Garden Comercial, Nova Vivere.

3. split_block_table / espelho oficial com fluxo financeiro
   Ex.: Piero Lissoni, Mozae, Bem Moema, Universo Órbita, Ária.

4. ready_stock_table
   Ex.: ELO Duo, pronto para morar, ato + financiamento.

5. sales_mirror_without_values
   Ex.: Bueno Brandão 257 técnico/espelho sem valores.

6. hierarchical_tegra
   Apenas quando realmente for tabela hierárquica financeira suportada.

7. grouped_sereno / singleline_flat / legacy
   Fallbacks progressivos.

8. Worker/Make
   Somente quando o layout não for conhecido ou o parser nativo não gerar linhas úteis.
```

---

## Regras de segurança para próximos ajustes

1. Não mexer no Make para resolver YPY.
2. Não recriar parser antigo que já funciona.
3. Não alterar `App.jsx` para esse caso.
4. Não quebrar Garden, Vivere, Piero, ELO Duo, Mozae, Bem Moema, Universo, Bueno, Ária.
5. Toda alteração deve ter regressão manual mínima com os arquivos sentinela.
6. Se o parser errado preencher colunas trocadas, deve bloquear com inconsistência. Nunca pode montar proposta silenciosamente errada.
7. Documento técnico sem valor financeiro deve bloquear antes do Make.
8. Tabela comercial com fluxo financeiro deve ter prioridade sobre padrões técnicos/finais/pavimentos.

---

## Frase-chave para abrir nova conversa

Use este texto para iniciar a próxima conversa:

```txt
Continuar FECH.AI — Mesa Cliente Native First.
Checkpoint: docs/mesa-cliente-checkpoint-ypy-tabelas-comerciais.md.
Contexto: Garden Abril/Maio, Vivere, Piero Lissoni, ELO Duo, Mozae, Bem Moema, Universo Órbita, Bueno Brandão e Ária estão funcionando como baseline. O caso pendente é YPY Alto do Ipiranga, tabela comercial flat com UNIDADE/ÁREA/ATO/COMPLEMENTO ATO/MENSAIS/ÚNICA 11/2026/FINANCIAMENTO/TOTAL. Não mexer no Make. Documentos técnicos/espelhos são diferentes de tabelas comerciais. O próximo passo é finalizar a delegação do parseSplitBlockTable para parseLaunchFlatPaymentTable e validar regressão.
```

---

## Checklist do próximo teste YPY

Após aplicar a pendência, testar o arquivo:

```txt
YPY Alto do Ipiranga - Tabela_Maio_2026.pdf
```

Validar:

```txt
[ ] Não caiu em Worker/Make
[ ] Não caiu em hierarchical_tegra
[ ] Identificou unidades APxxxx
[ ] Preencheu sinal_1 com ATO
[ ] Preencheu a4_each com COMPLEMENTO ATO
[ ] Preencheu mensal_each com MENSAIS
[ ] Preencheu mensal_qtd corretamente
[ ] Preencheu chaves_each com ÚNICA
[ ] Registrou unica_mes=2026-11
[ ] Registrou unica_label=11/2026
[ ] Preencheu financiamento
[ ] Preencheu preco_total
[ ] Soma financeira bate dentro da tolerância
[ ] Card Chaves mostra Parcela única — 11/2026
[ ] Garden/Vivere/Piero/ELO/Mozae/Bem/Universo/Bueno/Ária continuam OK
```

---

## Conclusão

O Mesa Cliente está no caminho correto: parser nativo primeiro, determinístico, barato e auditável.

O ajuste do YPY é incremental, mas ainda não deve ser tratado como finalizado. O conceito mais importante consolidado nesta conversa é:

```txt
Tabela comercial monta proposta.
Tabela técnica/espelho sem valores bloqueia proposta.
Fallback só entra quando o modelo ainda não foi aprendido.
```
