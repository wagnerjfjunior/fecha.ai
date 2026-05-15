# Mesa Cliente — Contrato Oficial do Parser Native First

## Status

Documento de contrato para ligar o motor Native First da Mesa Cliente ao modelo definitivo do FECH.AI.

Branch: `architecture/rpc-tanstack-definitive`  
Escopo: Parser → JSON canônico → importação segura → `estoque_snapshots` / `unidades_estoque` → Nova Mesa Cliente.

---

## Objetivo

Padronizar a saída do parser para que qualquer tabela comercial reconhecida seja convertida em um payload estável, validado e importável com segurança no banco.

O parser não deve salvar diretamente no Supabase.  
O parser não deve decidir tenant.  
O parser não deve acessar tabela.  
O parser deve entregar um JSON canônico.  
A persistência deve ocorrer por função segura no banco.

---

## Fluxo oficial

```txt
PDF / imagem / texto extraído
→ Native First parser
→ JSON canônico
→ validação leve no frontend
→ função de importação no banco
→ estoque_arquivos
→ estoque_snapshots
→ unidades_estoque
→ get_unidades_mesa
→ Nova Mesa Cliente
```

---

## Layouts atualmente aceitos

Conforme baseline documentado em `docs/mesa-cliente-native-parsers.md`, os grupos de layout aceitos são:

| Layout | Uso principal | Status |
|---|---|---|
| `range_by_final_table` | Garden Design Abril, Nova Vivere | Aceito |
| `split_block_table` | Garden Maio, Capitolo, Mozae, Bem Moema, Universo Tatuapé, Bueno Brandão, Ária | Aceito |
| `ready_stock_table` | Estoque pronto/ELO Duo | Aceito |
| Espelho sem valores | Arquivo de disponibilidade sem preço | Detectado e bloqueado para importação financeira |

Novos layouts devem ser adicionados sem quebrar os existentes.

---

## Contrato canônico — nível raiz

Payload esperado:

```json
{
  "schema_version": "mesa_parser_v1",
  "source": {
    "parser": "native_first",
    "layout": "range_by_final_table",
    "filename": "tabela.pdf",
    "hash": "sha256-opcional",
    "text_hash": "sha256-opcional",
    "extracted_at": "2026-05-15T18:00:00.000Z"
  },
  "metadata": {
    "empreendimento_nome_detectado": "Nova Vivere",
    "incorporadora_detectada": "Tegra",
    "data_referencia": "2026-04-01",
    "tabela_tipo": "tabela_trabalho",
    "moeda": "BRL"
  },
  "quality": {
    "confidence": "alta",
    "total_rows": 120,
    "valid_rows": 118,
    "invalid_rows": 2,
    "warnings": []
  },
  "units": []
}
```

---

## Campos obrigatórios do payload

| Campo | Obrigatório | Observação |
|---|---:|---|
| `schema_version` | Sim | Inicialmente `mesa_parser_v1`. |
| `source.parser` | Sim | `native_first`, `worker`, `make`, `manual`. |
| `source.layout` | Sim | Nome do layout detectado. |
| `metadata.data_referencia` | Recomendado | Se ausente, backend pode usar data atual, mas deve registrar aviso. |
| `quality.confidence` | Sim | `alta`, `media`, `baixa`, `manual_pendente`, `erro_processamento`. |
| `quality.total_rows` | Sim | Total lido pelo parser. |
| `quality.valid_rows` | Sim | Total importável. |
| `units` | Sim | Lista de unidades canônicas. |

---

## Contrato canônico — unidade

Cada unidade deve seguir:

```json
{
  "row_index": 1,
  "torre": "A",
  "unidade": "101",
  "final": "1",
  "andar": 1,
  "metragem": 72.5,
  "dormitorios": 3,
  "suites": 1,
  "vagas_quantidade": 1,
  "valor_tabela": 985000.00,
  "status_comercial": "disponivel",
  "planta_tipo": "3 dorms",
  "observacoes": "texto opcional",
  "confianca_linha": "alta",
  "raw": {
    "linha_original": "opcional",
    "tokens": []
  },
  "validation": {
    "valid": true,
    "errors": [],
    "warnings": []
  }
}
```

---

## Campos da unidade

| Campo | Obrigatório | Tipo | Regra |
|---|---:|---|---|
| `unidade` | Sim | string | Identificador comercial da unidade. Aceita AP, SC, SU, LJ e números. |
| `valor_tabela` | Sim para mesa financeira | number | Deve ser maior que zero para abrir simulação. |
| `torre` | Não | string/null | Obrigatório apenas quando o empreendimento tiver torres distintas. |
| `final` | Não | string/null | Usado principalmente por `range_by_final_table`. |
| `andar` | Não | integer/null | Quando inferível pela unidade ou tabela. |
| `metragem` | Recomendado | number/null | Ajuda filtro e validação comercial. |
| `dormitorios` | Não | integer/null | Pode ser nulo para studios, lojas ou salas. |
| `suites` | Não | integer/null | Pode ser nulo. |
| `vagas_quantidade` | Não | integer/null | Pode ser nulo se não constar na tabela. |
| `status_comercial` | Sim | enum | Inicialmente `disponivel` quando vem de tabela comercial. |
| `planta_tipo` | Não | string/null | Ex.: `2 dorms`, `studio`, `loja`. |
| `observacoes` | Não | string/null | Informações auxiliares. |
| `confianca_linha` | Sim | enum | `alta`, `media`, `baixa`, `manual_pendente`, `erro_processamento`. |

---

## Enums reais do banco

### Status de processamento

- `pendente`
- `processando`
- `processado`
- `validado`
- `erro`
- `cancelado`

### Confiança de extração

- `alta`
- `media`
- `baixa`
- `manual_pendente`
- `erro_processamento`

### Status comercial da unidade

- `disponivel`
- `reservada`
- `proposta`
- `vendida`
- `bloqueada`
- `indisponivel`

---

## Mapeamento para `estoque_arquivos`

| Payload | Coluna |
|---|---|
| empresa resolvida no banco | `empresa_id` |
| empreendimento validado | `empreendimento_id` |
| usuário/corretor autenticado | `enviado_por` |
| `source.filename` | `nome_arquivo` |
| `metadata.tabela_tipo` | `tipo_arquivo` |
| storage futuro | `storage_bucket` |
| storage futuro | `storage_path` |
| texto extraído quando disponível | `texto_extraido` |
| `source.hash` ou `source.text_hash` | `hash_arquivo` |
| importação concluída | `status_processamento` |
| `quality.confidence` | `confianca_extracao` |
| `metadata.data_referencia` | `data_referencia` |
| hora da importação | `processado_em` |
| observações/warnings | `observacoes` |

---

## Mapeamento para `estoque_snapshots`

| Payload | Coluna |
|---|---|
| empresa resolvida no banco | `empresa_id` |
| empreendimento validado | `empreendimento_id` |
| arquivo criado/relacionado | `arquivo_origem_id` |
| `source.parser` + `source.layout` | `fonte` |
| `metadata.data_referencia` | `data_referencia` |
| hora da importação | `data_processamento` |
| importação concluída | `status_processamento` |
| `quality.confidence` | `confianca_extracao` |
| novo snapshot ativo | `ativo` |
| validação posterior | `validado` |
| warnings/resumo | `observacoes` |

Regra de ativação: antes de criar o novo snapshot ativo para o empreendimento, a função de importação deve inativar snapshots anteriores do mesmo `empresa_id + empreendimento_id` quando o novo snapshot for aceito.

---

## Mapeamento para `unidades_estoque`

| Unidade canônica | Coluna |
|---|---|
| snapshot criado | `snapshot_id` |
| empresa resolvida no banco | `empresa_id` |
| empreendimento validado | `empreendimento_id` |
| `torre` | `torre` |
| `unidade` | `unidade` |
| `final` | `final` |
| `andar` | `andar` |
| `metragem` | `metragem` |
| `dormitorios` | `dormitorios` |
| `suites` | `suites` |
| `vagas_quantidade` | `vagas_quantidade` |
| `valor_tabela` | `valor_tabela` |
| `status_comercial` | `status_comercial` |
| default do banco | `orientacao_solar` |
| default do banco | `vista` |
| default do banco | `vaga_posicao` |
| default do banco | `vaga_tipo` |
| default do banco | `vaga_propriedade` |
| `planta_tipo` | `planta_tipo` |
| `observacoes` + warnings | `observacoes` |
| `confianca_linha` | `confianca_linha` |
| hora da importação | `extraido_em` |

---

## Regras de validação antes da importação

### Bloqueantes

A linha não deve ser importada quando:

1. `unidade` está ausente.
2. `valor_tabela` está ausente ou menor/igual a zero em tabela financeira.
3. `valor_tabela` não é número após normalização.
4. `status_comercial` não pertence ao enum real.
5. `confianca_linha = erro_processamento`.
6. Linha parece cabeçalho, subtotal, rodapé, observação ou legenda.

### Warnings

A linha pode ser importada com alerta quando:

1. `metragem` ausente.
2. `andar` não inferido.
3. `torre` ausente em empreendimento com torres.
4. `vagas_quantidade` ausente.
5. Valor muito fora da curva do mesmo empreendimento.
6. `final` ausente em layout que normalmente possui final.

---

## Normalização obrigatória

### Dinheiro

Aceitar:

```txt
R$ 985.000,00
985.000,00
985000
985000.00
```

Converter para número decimal:

```txt
985000.00
```

### Área

Aceitar:

```txt
72,5
72.5
72,50 m²
```

Converter para número decimal:

```txt
72.5
```

### Unidade

Aceitar padrões:

```txt
101
AP 101
APTO 101
SC 1201
SU 305
LJ 01
```

Preservar prefixo quando ele fizer parte da identificação comercial.

### Status comercial

Tabela comercial sem espelho deve assumir:

```txt
disponivel
```

Espelho de vendas futuro poderá atualizar para:

```txt
reservada
proposta
vendida
bloqueada
indisponivel
```

---

## Função oficial de importação

Nome recomendado:

```txt
importar_mesa_cliente_parser_resultado
```

Contrato lógico:

```txt
empreendimento_id + payload jsonb
```

A função deve:

1. Exigir usuário autenticado.
2. Resolver a empresa pelo usuário autenticado.
3. Validar se o empreendimento pertence à empresa.
4. Validar se o usuário pode importar tabela para esse tenant.
5. Validar `schema_version`.
6. Validar `units` como array.
7. Criar registro em `estoque_arquivos`.
8. Inativar snapshot anterior do mesmo empreendimento.
9. Criar novo `estoque_snapshots`.
10. Inserir unidades válidas em `unidades_estoque`.
11. Registrar quantidade total, válidas, inválidas e warnings.
12. Retornar resumo da importação.

Retorno esperado:

```json
{
  "ok": true,
  "arquivo_id": "uuid",
  "snapshot_id": "uuid",
  "total_rows": 120,
  "imported_rows": 118,
  "invalid_rows": 2,
  "confidence": "alta",
  "warnings": []
}
```

---

## Segurança da função de importação

A função deve seguir o mesmo padrão de segurança das demais funções críticas do FECH.AI:

1. Escopo de execução controlado.
2. Busca da empresa real pelo usuário autenticado.
3. Validação explícita de tenant.
4. Permissão apenas para usuários autenticados.
5. Nenhuma confiança em `empresa_id` recebido do frontend.
6. Auditoria de importações e rejeições.

Se o payload trouxer `empresa_id`, ele deve ser ignorado.  
Se o payload trouxer `empreendimento_id`, deve ser comparado com o parâmetro validado.

---

## Relação com espelho de vendas

Nesta etapa, o espelho ainda não é fonte de filtro.

Regra atual:

```txt
Tabela comercial → importa todas as unidades identificadas.
Nova Mesa Cliente → exibe todas as unidades do último snapshot processado.
```

Regra futura:

```txt
Espelho de vendas → atualiza status_comercial.
Nova Mesa Cliente → pode ocultar vendidas/reservadas conforme regra de negócio.
```

Até o espelho estar pronto, a UI deve exibir aviso:

```txt
Disponibilidade ainda não validada pelo espelho de vendas.
```

---

## Testes de regressão obrigatórios

Criar fixtures com texto extraído ou JSON esperado para:

1. Garden Design Abril — `range_by_final_table`.
2. Nova Vivere — `range_by_final_table`.
3. Garden Maio — `split_block_table`.
4. Capitolo — `split_block_table`.
5. ELO Duo/pronto — `ready_stock_table`.
6. Espelho sem valores — deve bloquear importação financeira.

Cada teste deve validar:

- layout detectado;
- quantidade de unidades;
- primeira e última unidade;
- intervalo de preços;
- presença de `unidade` e `valor_tabela`;
- ausência de linhas de cabeçalho/rodapé importadas;
- warnings esperados.

---

## Critério de aceite do parser definitivo

Parser será considerado integrado ao modelo definitivo quando:

1. Gerar payload `mesa_parser_v1`.
2. Validar linhas antes da importação.
3. Enviar resultado pela função oficial de importação.
4. Criar snapshot ativo.
5. Popular `unidades_estoque`.
6. `get_unidades_mesa` listar as unidades importadas.
7. Nova Mesa Cliente usar essas unidades para simulação.
8. Testes de regressão cobrirem os layouts sentinela.

---

## Decisão

O motor Native First permanece como base.  
Não reescrever parser agora.  
O trabalho correto é criar contrato, adapter, função importadora e testes.

Resumo:

```txt
Parser atual = motor validado.
Contrato canônico = ponte obrigatória.
Importação segura = única porta de entrada no banco.
Nova Mesa Cliente = consumidora do estoque persistido.
```
