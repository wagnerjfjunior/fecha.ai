# FECH.AI — Mesa Cliente Layout Engine v1.1.0

## Status

Checkpoint técnico da evolução do Mesa Cliente nativo para uma arquitetura modular de interpretação documental imobiliária.

Branch de trabalho:

```text
feature/mesa-layout-engine-foundation
```

Pull Request:

```text
PR #3 — feat(mesa): foundation do layout engine documental
```

## Contexto

O Mesa Cliente deixou de ser apenas uma tela de upload/conversão de PDF e passou a caminhar para uma arquitetura de Document Intelligence imobiliário.

O problema real identificado não era apenas erro visual ou erro de cálculo. O problema estrutural era que as tabelas imobiliárias possuem famílias de layout diferentes:

- tabelas flat/linha-a-linha;
- tabelas hierárquicas com Final, andar e contexto herdado;
- tabelas estilo espelho/ERP;
- tabelas com Garden, faixa de pavimento e unidades implícitas.

A arquitetura anterior dependia demais de CSV perfeito vindo do Worker/Make. Quando o Make retornava linhas deslocadas, por exemplo:

```text
118.20;;;40100;13400;44;3200
```

os campos financeiros eram empurrados para colunas erradas e o Mesa poderia renderizar proposta incorreta.

Este checkpoint cria a base para evitar esse risco.

---

## Arquitetura atual após este checkpoint

Fluxo lógico:

```text
PDF
→ pdf.js
→ Worker Cloudflare
→ Make
→ CSV canônico
→ Layout Detector
→ Parser Dispatcher
→ Normalizer
→ Validator
→ UI Mesa Cliente
```

Para layouts hierárquicos:

```text
CSV canônico
→ legacyParser
→ parseHierarchical
→ herança de contexto
→ parseFloorRange
→ validação financeira
→ UI
```

---

## Arquivos adicionados

### `src/mesa/layoutDetector.js`

Responsável por detectar a família do layout a partir do texto extraído do PDF.

Layouts iniciais:

- `hierarchical_tegra`
- `grouped_sereno`
- `singleline_flat`
- `erp_table`
- `legacy`

Retorna:

```js
{
  layout,
  confidence,
  reason
}
```

---

### `src/mesa/parsers/legacyParser.js`

O parser anterior foi isolado como fallback seguro.

Responsabilidades atuais:

- ler CSV canônico;
- mapear colunas para objeto interno;
- converter valores numéricos;
- aplicar normalização de células;
- aplicar validação financeira;
- retornar linhas enriquecidas com `validation` e `parser_meta`.

---

### `src/mesa/parsers/parseFlatTable.js`

Parser foundation para tabelas simples/flat.

Estado atual:

```text
adapter para legacyParser
```

Uso previsto:

- Bosque Vila Nova;
- Elo Duo;
- AW simples;
- tabelas linha-a-linha.

---

### `src/mesa/parsers/parseHierarchical.js`

Parser foundation para tabelas hierárquicas/contextuais.

Responsabilidades já implementadas:

- herança de `final`;
- normalização de final (`1` → `01`);
- herança de `andar`;
- detecção de Garden;
- integração com `parseFloorRange`;
- enriquecimento com `floor_meta`;
- metadados de parser.

---

### `src/mesa/parsers/parseERPTable.js`

Parser foundation para layouts tipo espelho/ERP.

Estado atual:

```text
adapter para legacyParser
```

Uso previsto:

- tabelas amplas;
- espelhos de vendas;
- estruturas muito horizontais.

---

### `src/mesa/normalizers/normalizeCanonCells.js`

Normalizador de linhas CSV canônicas.

Responsabilidades:

- detectar quantidade inesperada de colunas;
- detectar shift financeiro típico do Make;
- reparar campos financeiros quando houver evidência forte de deslocamento;
- nunca inventar `preco_total` quando ele não veio de forma confiável.

Exemplo de caso tratado:

```text
area_m2;preco_total;sinal_1;a4_each;mensal_qtd;mensal_each
118.20;;;40100;13400;44;3200
```

Reparo controlado:

```text
sinal_1 = 40100
a4_each = 13400
mensal_qtd = 44
mensal_each = 3200
```

`preco_total` permanece vazio quando não houver origem segura.

---

### `src/mesa/validators/validateCanonRow.js`

Validador financeiro canônico.

Responsabilidades:

- validar `area_m2`;
- validar presença de `preco_total`;
- validar presença de `financiamento`;
- detectar `mensal_qtd` absurda;
- detectar `inter_qtd` absurda;
- detectar valores de parcela maiores que o preço total;
- sinalizar possível deslocamento de colunas.

Retorno:

```js
{
  valid: boolean,
  issues: string[]
}
```

---

### `src/mesa/utils/parseFloorRange.js`

Parser semântico de pavimentos.

Converte strings como:

```text
19º ao 23º andar
4º e 5º andar
7º ao 8º andar
Garden AP0601
```

em estrutura:

```js
{
  raw,
  tipo,
  inicio,
  fim,
  pavimentos
}
```

Exemplo:

```js
parseFloorRange("19º ao 23º andar")
```

retorna:

```js
{
  raw: "19º ao 23º andar",
  tipo: "range",
  inicio: 19,
  fim: 23,
  pavimentos: [19, 20, 21, 22, 23]
}
```

---

## Arquivo alterado

### `src/pages/MesaCliente.jsx`

Alterações principais:

- importa `detectLayout`;
- importa parsers modulares;
- cria dispatcher `parseMesaByLayout`;
- exibe layout detectado;
- exibe confiança e motivo da detecção;
- calcula quantidade de linhas inválidas;
- sinaliza unidade válida/inválida no select;
- bloqueia WhatsApp quando linha é inválida;
- bloqueia impressão quando linha é inválida;
- bloqueia cards financeiros quando linha é inválida;
- exibe motivos técnicos da invalidação.

---

## Segurança operacional implementada

Este checkpoint preserva o comportamento do Mesa sem refatoração destrutiva:

- não altera `App.jsx`;
- não altera Supabase;
- não altera RLS;
- não altera RPCs;
- não altera funil;
- não altera oferta ativa;
- não altera dashboard;
- não remove o parser antigo;
- mantém fallback legado.

---

## Comportamento novo da UI

Quando uma linha é válida:

```text
✅ Unidade — área — preço
```

Quando uma linha é inválida:

```text
⚠️ Unidade — inconsistência financeira
```

Se a linha estiver inválida:

- os cards financeiros não são exibidos;
- o botão WhatsApp fica bloqueado;
- o botão Imprimir fica bloqueado;
- a UI mostra o motivo técnico da inconsistência.

---

## Bug real tratado

Caso identificado no Nova Vivere:

O Make retornou linhas com campos deslocados:

```text
Nova Vivere;;01;7º e 8º andar;AP0601;118.20;;;40100;13400;44;3200;anual;4;7500;50100;701200;vagas=1
```

Problema:

- `preco_total` veio vazio;
- `sinal_1` veio vazio;
- `a4_each` recebeu o valor do ato;
- `mensal_qtd` recebeu valor monetário;
- campos financeiros ficaram deslocados.

Mitigação implementada:

- normalizador tenta reencaixar campos com evidência forte;
- validador bloqueia linha se `preco_total` continuar ausente;
- UI impede envio de proposta inconsistente.

---

## Limitações conhecidas

1. `parseFlatTable.js` ainda é adapter para `legacyParser`.
2. `parseERPTable.js` ainda é adapter para `legacyParser`.
3. `parseHierarchical.js` ainda trabalha sobre CSV canônico vindo do Worker/Make, não sobre tokens espaciais do PDF.
4. `preco_total` não é inferido por soma financeira, por segurança.
5. Ainda não existe Unit Expansion Engine.
6. Ainda não existe persistência Supabase para processamentos do Mesa.
7. Ainda não existe suíte automatizada com PDFs reais.

---

## Próximas fases recomendadas

### Fase 1.2 — Unit Expansion Engine

Objetivo:

Transformar linhas de faixa de andar em unidades reais.

Exemplo:

```text
Final 01 + 19º ao 23º andar
```

pode gerar:

```text
1901
2001
2101
2201
2301
```

Benefícios:

- estoque real;
- filtros por pavimento;
- ranking por valor/m²;
- recomendação automática;
- integração CRM;
- histórico de proposta por unidade real.

---

### Fase 1.3 — Test Suite documental

Criar estrutura futura:

```text
tests/mesa/fixtures/
```

Com PDFs reais autorizados ou amostras sanitizadas.

Objetivo:

- validar regressão;
- evitar quebrar layouts já suportados;
- comparar CSV esperado vs CSV gerado;
- testar layouts Tegra, Cyrela, AW, Helbor e ERP.

---

### Fase 2 — Persistência Supabase

Tabelas planejadas:

- `mesa_cliente_processamentos`
- `mesa_cliente_simulacoes`
- `mesa_cliente_logs`
- `mesa_cliente_unidades`

Objetivo:

- histórico de mesas;
- auditoria;
- reprocessamento;
- rastreabilidade por tenant;
- integração com lead e CRM.

---

## Critério de rollback

Rollback seguro:

1. Reverter PR #3 inteiro; ou
2. Remover dispatcher de `MesaCliente.jsx` e voltar ao parser local anterior; ou
3. Manter branch sem merge até validação final em preview.

Como o parser legado foi preservado, a estratégia preferencial é manter fallback e corrigir incrementalmente, evitando rollback completo.

---

## Conclusão

Este checkpoint transforma o Mesa Cliente de um conversor PDF/CSV simples em uma base real de Layout Engine documental imobiliário.

A partir daqui, o FECH.AI começa a construir um ativo proprietário relevante:

```text
PDF imobiliário
→ interpretação semântica
→ validação financeira
→ proposta segura
→ estoque inteligente
→ CRM operacional
```

Este é o caminho correto para consolidar o Mesa Cliente como Proposal Engine nativo do FECH.AI.
