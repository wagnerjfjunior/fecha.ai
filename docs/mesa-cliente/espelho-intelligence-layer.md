# Mesa Cliente — Espelho Intelligence Layer

## 1. Objetivo

A camada **Espelho Intelligence Layer** será responsável por importar, interpretar e cruzar o **espelho oficial de vendas em PDF** com as unidades já carregadas pela tabela comercial no Mesa Cliente.

O objetivo é permitir que o corretor trabalhe com uma visão mais próxima do estoque real, reduzindo o risco de montar proposta para unidade vendida, bloqueada, reservada ou sem disponibilidade comercial.

Esta camada nasce como um módulo separado do parser da tabela comercial.

---

## 2. Decisão arquitetural oficial

### Tabela comercial

Fonte responsável por:

- unidade;
- metragem comercial;
- valor de tabela;
- ato/sinal;
- complementos;
- mensais;
- intermediárias/anuais/semestrais;
- parcela única/chaves;
- financiamento;
- fluxo financeiro da proposta.

### Espelho oficial

Fonte responsável por:

- disponibilidade/status da unidade;
- data e hora de geração do espelho;
- leitura visual da célula da unidade;
- cor predominante da célula;
- símbolos/ícones comerciais;
- eventual tipologia e ficha técnica quando presentes no PDF;
- cruzamento com a unidade importada pela tabela comercial.

### Regra de ouro

> O espelho valida disponibilidade. A tabela comercial define valor e fluxo.

Não misturar esses motores. O parser da tabela comercial não deve ser alterado para ler disponibilidade do espelho.

---

## 3. Escopo da V1

A V1 deve importar PDF oficial de espelho e retornar uma estrutura utilizável pela Mesa Cliente.

### Deve fazer

- receber PDF oficial do espelho;
- extrair nome do empreendimento quando possível;
- extrair data/hora de geração do espelho quando presente;
- renderizar páginas relevantes do PDF;
- identificar células contendo unidades, como `AP0101`, `AP3607`, `VG0300`, `LJ0001`;
- extrair andar e final a partir da unidade;
- capturar a cor predominante da célula;
- capturar símbolos visuais relevantes quando possível;
- inferir status com base na legenda do próprio PDF ou em mapeamento visual detectado;
- gerar nível de confiança por unidade;
- cruzar unidades do espelho com unidades da tabela comercial por `empresa_id`, `empreendimento_id` e `unidade`;
- sinalizar divergências e unidades sem correspondência.

### Não deve fazer

- não alterar parser de tabela comercial;
- não hardcodar regras específicas de Garden, Nova Vivere, Elo, Reserva, Capitolo ou qualquer empreendimento;
- não assumir status absoluto quando a leitura visual for incerta;
- não permitir vazamento entre empresas/tenants;
- não depender de edição manual unidade por unidade como fluxo principal.

---

## 4. Princípio de automação

A automação deve ser prioritária. O sistema deve tentar extrair status de forma automática.

Validação humana só deve entrar como exceção:

- baixa confiança;
- legenda ausente;
- cor ambígua;
- unidade detectada sem correspondência na tabela comercial;
- célula visualmente ilegível;
- divergência entre tabela comercial e espelho.

O objetivo operacional é evitar que o gestor tenha que alimentar o espelho manualmente.

---

## 5. Modelo conceitual de status

Status normalizados propostos:

```txt
available          = disponível para venda
reserved           = reservada
proposal           = proposta/em negociação
sold               = vendida
blocked            = bloqueada/indisponível
unknown            = identificada, mas status não confiável
not_found          = unidade da tabela não encontrada no espelho
```

A UI pode traduzir esses status para:

```txt
Disponível
Reservada
Em proposta
Vendida
Bloqueada
Validar no espelho
Não encontrada no espelho
```

---

## 6. Estrutura de dados esperada por unidade

```json
{
  "unidade": "AP0112",
  "andar": 1,
  "final": "12",
  "metragem": 61.07,
  "status": "available",
  "status_label_original": "Disponível",
  "cor_hex": "#273D91",
  "simbolos": ["$"],
  "confidence": 0.94,
  "requires_review": false,
  "bbox": {
    "page": 3,
    "x": 123,
    "y": 456,
    "width": 78,
    "height": 32
  },
  "raw": {
    "texto_detectado": "AP0112",
    "cor_rgb": [39, 61, 145],
    "fonte": "pdf_oficial_tegra"
  }
}
```

---

## 7. Estrutura de importação

```json
{
  "empreendimento_nome": "Garden Design",
  "origem": "pdf_oficial_tegra",
  "gerado_em": "2026-05-16T14:07:00-03:00",
  "arquivo_nome": "[MAI] - Garden Design espelho2.pdf",
  "total_unidades_detectadas": 467,
  "total_disponiveis": 180,
  "total_indisponiveis": 240,
  "total_indefinidas": 47,
  "confidence_media": 0.88,
  "unidades": []
}
```

---

## 8. Segurança multi-tenant

Toda persistência deve obedecer às mesmas regras do FECH.AI:

- `empresa_id` obrigatório em todas as tabelas de espelho;
- `empreendimento_id` obrigatório quando o espelho for aplicado a um empreendimento;
- `created_by` obrigatório;
- nenhuma RPC deve aceitar `empresa_id` livre sem validar o usuário autenticado;
- root/admin global podem auditar, mas não devem quebrar isolamento operacional;
- corretor só consome resultado aplicado ao seu contexto;
- gestor/admin da empresa pode importar/aplicar espelho;
- RLS deve bloquear leitura cruzada entre empresas.

---

## 9. Tabelas candidatas

### `mesa_espelho_importacoes`

Campos recomendados:

```txt
id
empresa_id
empreendimento_id
created_by
arquivo_nome
origem
gerado_em
status_processamento
total_unidades_detectadas
total_disponiveis
total_indisponiveis
total_indefinidas
confidence_media
raw_metadata
created_at
updated_at
```

### `mesa_espelho_unidades`

Campos recomendados:

```txt
id
empresa_id
empreendimento_id
importacao_id
unidade
andar
final
metragem
status
status_label_original
cor_hex
simbolos
confidence
requires_review
bbox
raw_payload
created_at
updated_at
```

---

## 10. RPCs candidatas

### `mesa_registrar_espelho_importacao`

Cria registro de importação, valida tenant e usuário.

### `mesa_upsert_espelho_unidades`

Grava unidades extraídas do espelho. Deve validar que o usuário pertence à empresa.

### `mesa_get_espelho_unidades`

Lista status das unidades do espelho para um empreendimento, sempre isolado por tenant.

### `mesa_aplicar_espelho_na_mesa`

Cruza espelho com unidades importadas da tabela comercial e retorna disponibilidade normalizada.

---

## 11. Cruzamento tabela x espelho

Chave principal:

```txt
empresa_id + empreendimento_id + unidade
```

Regras:

- se unidade existe na tabela e no espelho com status `available`: exibir como disponível;
- se unidade existe na tabela e no espelho com status indisponível: exibir bloqueada/rebaixada ou esconder conforme filtro;
- se unidade existe na tabela e não existe no espelho: status `not_found`;
- se unidade existe no espelho e não existe na tabela: manter no histórico da importação, mas não montar proposta sem preço.

---

## 12. UI esperada

### Na tela de empreendimentos

Adicionar ação:

```txt
Importar espelho oficial
```

### Na tela de unidades

Adicionar filtros:

```txt
Somente disponíveis
Disponíveis + validar
Vendidas/bloqueadas
Não encontradas no espelho
```

### No card da unidade

Exemplos:

```txt
✅ Disponível no espelho oficial
Atualizado em 16/05 às 14:07
```

```txt
🚫 Unidade indisponível no espelho oficial
```

```txt
⚠️ Status visual não confiável
Validar no espelho antes de avançar
```

---

## 13. Estratégia técnica de leitura visual

A leitura deve seguir pipeline:

```txt
PDF
→ renderização em imagem de alta resolução
→ detecção de regiões/células do espelho
→ OCR/extração textual da unidade
→ amostragem de cor da célula
→ normalização de cor
→ detecção de símbolos
→ classificação de status
→ confidence score
```

A classificação inicial pode usar heurística visual, mas deve registrar sempre:

- cor original;
- símbolos detectados;
- status inferido;
- nível de confiança;
- payload bruto.

---

## 14. Critérios de confiança

Sugestão inicial:

```txt
>= 0.85: alta confiança
0.65 a 0.84: média confiança
< 0.65: baixa confiança / requer validação
```

A UI não deve travar o fluxo por baixa confiança, mas deve alertar.

---

## 15. Roadmap

### V1

- parser separado para espelho oficial;
- extração de unidade, andar, final, cor e status sugerido;
- sem alterar parser comercial;
- preview técnico em console/JSON;
- cruzamento inicial com unidades da tabela.

### V2

- persistência em Supabase com RLS/RPC;
- UI de importação do espelho;
- filtros de disponibilidade na Mesa Cliente;
- selo de status nos cards.

### V3

- leitura mais refinada de legenda;
- OCR/visão por célula;
- tela de auditoria do espelho;
- histórico de espelhos por empreendimento;
- alerta quando espelho estiver antigo.

---

## 16. Decisão final

O Espelho Intelligence Layer será implementado como motor próprio, automatizado por padrão e com validação apenas em exceções.

A Mesa Cliente passa a operar com duas fontes complementares:

```txt
Tabela comercial → preço e fluxo
Espelho oficial → disponibilidade e status
```

Essa separação preserva segurança, escalabilidade e clareza operacional.
