# Mesa Cliente — Motor de Espelho de Vendas V1

## Objetivo

Criar uma camada independente para ler o espelho oficial de vendas e preparar o cruzamento com as unidades da tabela comercial, sem alterar o parser comercial já validado.

Esta etapa nasce como motor isolado, porque o espelho possui natureza diferente da tabela comercial:

- a tabela comercial traz valores e fluxo financeiro;
- o espelho mostra status, disponibilidade, reservas, vendas e sinais visuais;
- nem todo espelho traz legenda textual confiável;
- algumas informações podem vir por cor, símbolo ou posição.

## O que foi criado

Diretório:

```txt
src/components/MesaCliente/espelho/
```

Arquivos:

```txt
statusRules.js
normalizeMirror.js
pdfMirrorExtractor.js
index.js
```

## Responsabilidade de cada arquivo

### `statusRules.js`

Define as regras genéricas de inferência de status.

A V1 não possui hardcode de Garden, Capitolo, Nova Vivere, Elo ou Reserva. As regras olham para evidências:

- símbolo de dinheiro `$`;
- símbolo de alerta `!`;
- marcação `id`;
- cor quando a cor estiver disponível como RGB;
- ausência de evidência clara.

Resultado esperado:

```js
{
  status: 'provavel_disponivel',
  disponibilidade: 'provavel_disponivel',
  confidence: 0.72,
  label: 'Sinal comercial encontrado',
  evidence: []
}
```

### `normalizeMirror.js`

Normaliza a unidade do espelho.

Exemplos:

```txt
101   -> AP0101
AP101 -> AP0101
3607  -> AP3607
```

Também extrai:

- unidade;
- andar;
- final;
- status do espelho;
- confidence;
- evidências usadas.

Além disso, prepara o cruzamento futuro:

```js
mergeCommercialUnitsWithMirror({ unidadesComerciais, unidadesEspelho })
```

### `pdfMirrorExtractor.js`

Faz a leitura client-side do PDF usando PDF.js, da mesma forma segura que a tabela comercial já usa.

Nesta V1 ele extrai:

- texto selecionável;
- unidades encontradas;
- símbolos próximos da unidade;
- data/hora textual quando disponível;
- resumo por status;
- diagnóstico por página.

Ponto importante: esta V1 ainda não faz análise raster/canvas profunda da cor pintada no PDF. Ela já aceita cor RGB caso a etapa visual passe essa informação depois.

## O que esta V1 consegue fazer

- Ler PDF de espelho com texto selecionável.
- Identificar unidades como AP0101, AP3607 etc.
- Extrair andar e final.
- Inferir status por símbolos próximos.
- Gerar confiança da leitura.
- Gerar resumo de unidades prováveis disponíveis, validar e indefinidas.
- Preparar o cruzamento com a tabela comercial.

## O que esta V1 ainda não deve prometer

- Não garante leitura perfeita de cor quando o PDF for imagem/raster.
- Não grava no banco ainda.
- Não filtra automaticamente as unidades na tela principal ainda.
- Não substitui validação humana quando `confidence` vier baixo.

## Regra de segurança

Nenhuma informação de empreendimento foi hardcoded.

O motor não sabe que:

- Garden possui 14 finais;
- Nova Vivere possui 10 finais;
- Elo possui finais específicos;
- determinada cor significa vendido ou disponível em um empreendimento específico.

Tudo precisa vir do documento ou de configuração cadastrada depois.

## Caminho arquitetural recomendado

### Etapa 1 — Motor isolado

Concluída nesta branch.

### Etapa 2 — Preview do espelho

Adicionar no modal de upload de espelho:

1. usuário sobe PDF;
2. sistema mostra resumo;
3. sistema lista unidades identificadas;
4. sistema mostra confidence;
5. usuário confirma ou cancela.

### Etapa 3 — RPC segura

Criar RPC para persistir snapshot do espelho:

```sql
mesa_importar_espelho_vendas_snapshot(...)
```

Requisitos obrigatórios:

- autenticação por `auth.uid()`;
- isolamento por `empresa_id` derivado do usuário;
- validação de perfil gestor/admin quando necessário;
- gravação de `uploaded_by`;
- versionamento por snapshot;
- nunca aceitar `empresa_id` livre do front sem validação interna.

### Etapa 4 — Cruzamento com tabela comercial

A tela de unidades deve cruzar:

```txt
unidades_comerciais + snapshot_espelho_ativo
```

Resultado:

- disponível;
- validar;
- vendido/reservado quando a legenda estiver confiável;
- sem espelho;
- divergente.

## Decisão de produto

O espelho deve entrar como camada de inteligência e não como bloqueador.

Enquanto a leitura não for 100% confiável:

- não esconder unidade automaticamente;
- mostrar selo de status;
- permitir filtro por provável disponível;
- permitir validação manual.

Isso evita matar venda por erro de interpretação visual. Melhor um corretor ver uma unidade com alerta do que o sistema esconder uma oportunidade boa. Aqui a máquina ajuda, mas ainda não vira síndica do condomínio.
