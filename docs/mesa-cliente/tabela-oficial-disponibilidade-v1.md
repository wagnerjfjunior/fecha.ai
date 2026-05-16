# Mesa Cliente — Tabela Oficial de Disponibilidade V1

## Descoberta operacional

Foi identificado que a tabela oficial da Tegra usada para gerar o espelho gráfico contém apenas as unidades disponíveis no momento da geração.

Isso altera a estratégia do módulo de disponibilidade:

```txt
Tabela comercial = universo completo de unidades, valores e fluxo
Tabela oficial de disponibilidade = estoque disponível atual
Espelho gráfico = visual auxiliar, não motor principal da disponibilidade
```

## Decisão arquitetural

A leitura por cor do espelho gráfico deixa de ser prioridade para a V1.

A V1 passa a priorizar o PDF em formato de tabela oficial, pois ele é:

- mais confiável;
- mais leve de processar;
- mais próximo do dado estruturado;
- menos sujeito a erro visual/OCR;
- melhor para cruzamento automático com a tabela comercial.

## Regra de produto

A Mesa Cliente não deve simplesmente esconder unidades fora da disponibilidade oficial.

Comportamento definido:

### Unidade existe na tabela comercial e também na tabela oficial

Status:

```txt
Disponível
```

Comportamento:

- aparece normal;
- pode montar proposta;
- exibe selo “Disponível na tabela oficial”.

### Unidade existe na tabela comercial, mas não aparece na tabela oficial

Status:

```txt
Indisponível
```

Comportamento:

- aparece cinza/desabilitada quando o filtro permitir;
- não deve liberar montagem de proposta por padrão;
- recebe marca d’água “INDISPONÍVEL”;
- texto auxiliar: “Não consta na tabela oficial atualizada”.

### Unidade existe na tabela oficial, mas não existe na tabela comercial

Status:

```txt
Divergente
```

Comportamento:

- aparece em alerta técnico;
- não libera proposta porque falta fluxo/valor completo da tabela comercial;
- deve ser auditada.

## Linguagem da UI

Termos técnicos removidos ou reduzidos:

```txt
Subir espelho → Atualizar disponibilidade
Espelho de vendas → Tabela oficial de disponibilidade
Parser → Leitura da tabela
Tabela Parser → Valor de Tabela
```

Frase recomendada:

```txt
Escolha uma unidade disponível para montar a proposta com o cliente.
```

Quando não houver tabela oficial atualizada:

```txt
As unidades abaixo vieram da tabela comercial. Para validar disponibilidade atual, envie a tabela oficial atualizada.
```

Quando houver tabela oficial:

```txt
Disponibilidade atualizada pela tabela oficial em DD/MM às HH:mm.
```

## Motor criado

Diretório:

```txt
src/components/MesaCliente/disponibilidade/
```

Arquivos:

```txt
availabilitySnapshot.js
index.js
DisponibilidadeUploadPreview.jsx
```

Responsabilidades:

- normalizar unidade;
- extrair andar e final;
- montar snapshot de unidades disponíveis;
- aplicar disponibilidade nas unidades comerciais;
- gerar resumo de cruzamento;
- abrir prévia local de leitura da tabela oficial;
- mostrar total de unidades disponíveis;
- mostrar cruzamento básico com a base comercial quando ela estiver disponível na tela.

## Implementação atual

Foi conectado na tela de empreendimentos:

```txt
src/components/MesaCliente/TabEmpreendimentos.jsx
```

Mudanças realizadas:

- botão “Subir espelho” substituído por “Atualizar disponibilidade”;
- status visual “Espelho” substituído por “Disp.”;
- modal antigo de espelho gráfico deixou de ser o fluxo principal;
- novo modal `DisponibilidadeUploadPreview` lê a tabela oficial com o motor já existente;
- a leitura gera prévia local, sem gravação no banco;
- a confirmação local apenas guarda o preview em estado de tela, sem persistência.

## Estrutura do snapshot

```json
{
  "origem": "tabela_oficial_disponibilidade",
  "gerado_em": "16/05 15:21",
  "arquivo_nome": "[MAI] - Garden Design tabela.pdf",
  "total_unidades_disponiveis": 120,
  "unidades": [
    {
      "unidade": "AP0112",
      "andar": 1,
      "final": "12",
      "status_disponibilidade": "disponivel",
      "origem_status": "tabela_oficial_disponibilidade",
      "area_m2": 61.07,
      "valor_total": 712458
    }
  ]
}
```

## Cruzamento

Chave principal:

```txt
unidade normalizada
```

Exemplo:

```txt
101   → AP0101
AP101 → AP0101
0112  → AP0112
```

Resultado aplicado à unidade comercial:

```json
{
  "unidade": "AP0112",
  "disponibilidade_oficial": "disponivel",
  "disponibilidade_label": "Disponível na tabela oficial",
  "disabled_by_availability": false
}
```

ou:

```json
{
  "unidade": "AP1208",
  "disponibilidade_oficial": "indisponivel",
  "disponibilidade_label": "Indisponível na tabela oficial",
  "disponibilidade_watermark": "INDISPONÍVEL",
  "disabled_by_availability": true
}
```

## Banco de dados — próxima etapa

A persistência ainda não foi aplicada nesta V1 de UI.

A próxima etapa deve criar RPC segura e tabelas de snapshot.

Tabelas candidatas:

```txt
mesa_disponibilidade_snapshots
mesa_disponibilidade_unidades
```

Regras obrigatórias:

- `empresa_id` obrigatório;
- `empreendimento_id` obrigatório;
- `created_by` obrigatório;
- snapshot versionado;
- RLS obrigatório;
- RPC valida usuário autenticado;
- front não manda `empresa_id` livre sem validação interna;
- corretor consulta apenas snapshot aplicado à própria empresa.

RPC candidata:

```sql
mesa_importar_disponibilidade_snapshot(...)
```

A RPC deve:

- validar `auth.uid()`;
- resolver empresa do usuário no banco;
- validar permissão de gestor/admin quando a regra exigir;
- inserir snapshot;
- inserir unidades normalizadas;
- marcar snapshot anterior como substituído ou manter como histórico;
- retornar resumo seguro para o front.

## Filtros recomendados

Na tela de unidades:

```txt
Somente disponíveis
Mostrar todas
Somente indisponíveis
Divergentes
```

Padrão recomendado:

```txt
Somente disponíveis
```

Mas a opção “Mostrar todas” deve existir para auditoria e transparência.

## Visual de unidade indisponível

- card cinza claro;
- opacidade reduzida;
- botão de seleção bloqueado;
- marca d’água diagonal ou central “INDISPONÍVEL”;
- texto menor: “Não consta na tabela oficial atualizada”.

## Pendências imediatas

1. Passar as unidades comerciais reais para `DisponibilidadeUploadPreview`.
2. Persistir snapshot via RPC segura.
3. Criar consulta RPC para trazer disponibilidade ativa por empreendimento.
4. Aplicar visual cinza/marca d’água na tela de escolha de unidades.
5. Adicionar filtro “Disponibilidade”.
6. Remover/depriorizar o fluxo antigo de espelho gráfico da navegação principal, mantendo-o apenas como experimento técnico se necessário.

## Decisão final

A tabela oficial de disponibilidade passa a ser o motor principal de estoque/disponibilidade do Mesa Cliente.

O espelho gráfico fica como material visual auxiliar e poderá voltar em etapa posterior, caso seja necessário validar cores/status específicos.
