# FECH.AI / MesaCliente — Fase 20D
# Contrato — Adaptador histórico -> agenda canônica

## 1. Status

```text
Status: CONTRATO INICIAL
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Base: main após merge da PR #28
DDL executado: NÃO
DML executado: NÃO
RPC criada/alterada: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

## 2. Contexto

A Fase 20C validou o Modo 3 com sucesso:

```text
- geração de agenda JSON-first via RPC 4A;
- persistência de agenda canônica via RPC 4B;
- criação de agenda em mesa_cliente_agendas_financeiras;
- criação de 47 parcelas em mesa_cliente_fluxo_parcelas;
- validação cliente-safe sem vazamento interno.
```

Entretanto, o piloto usou payload adaptado manual/controlado porque o fluxo histórico atual não é diretamente compatível com a entrada esperada pela RPC 4A.

Esta Fase 20D transforma essa adaptação controlada em contrato técnico oficial.

## 3. Objetivo da 20D

Criar uma camada segura e determinística para converter:

```text
public.mesa_fluxo_pagamentos
```

em payload canônico compatível com:

```text
public.mesa_cliente_gerar_agenda_financeira_admin
public.mesa_cliente_persistir_agenda_financeira_admin
```

Sem depender de payload manual.

## 4. Fora de escopo

Esta fase não deve implementar:

```text
- antecipação;
- amortização;
- juros;
- VPL;
- registro de operação financeira;
- aplicação de operação financeira;
- rastreabilidade original x ajustado;
- alteração de motor financeiro;
- alteração de parser;
- alteração de Worker/Make/n8n;
- alteração de frontend;
- alteração das regras centrais de agenda já validadas.
```

## 5. Problema confirmado na 20C

O fluxo histórico usa tipos/nomes de campos como:

```text
entrada
curto_prazo
periodica
intermediaria
quitacao
data_prevista
```

A RPC 4A espera grupos e campos como:

```text
entrada
mensais
intermediarias
parcela_unica
data_vencimento
```

Resultado prático observado:

```text
- curto_prazo foi recusado como grupo inválido;
- data_prevista foi ignorada pela 4A;
- dias_offset para +30/+60/+90 produziu dias corridos, não datas comerciais mensais;
- payload adaptado com datas oficiais explícitas funcionou.
```

## 6. Mapeamento mínimo aprovado como baseline

| Origem histórica | Canônico para 4A |
|---|---|
| `entrada` | `entrada` |
| `curto_prazo` | `entrada` |
| `periodica` | `mensais` |
| `intermediaria` | `intermediarias` |
| `quitacao` | `parcela_unica` |
| `data_prevista` | `data_vencimento` |

## 7. Regras de adaptação propostas

### 7.1 Fonte soberana

A fonte do adaptador deve ser o banco:

```text
public.mesa_simulacoes
public.mesa_fluxo_pagamentos
public.empreendimentos
public.unidades_estoque
```

O frontend não deve enviar autoridade soberana de:

```text
empresa_id
empreendimento_id
unidade_estoque_id
corretor_id
perfil/permissão
```

### 7.2 Entrada sugerida da futura RPC adaptadora

```sql
public.mesa_cliente_montar_payload_agenda_canonica(
  p_simulacao_id uuid
) returns jsonb
```

### 7.3 Saída sugerida

```json
{
  "ok": true,
  "fase": "20D_ADAPTADOR_HISTORICO_AGENDA_CANONICA",
  "simulacao_id": "...",
  "empresa_id": "...",
  "empreendimento_id": "...",
  "unidade_estoque_id": "...",
  "p_data_ato": "YYYY-MM-DD",
  "fluxo_json": [],
  "payload_tabela": {},
  "diagnostico": {
    "qtd_itens_origem": 0,
    "qtd_itens_adaptados": 0,
    "warnings": [],
    "bloqueios": []
  }
}
```

### 7.4 Segurança obrigatória

A futura RPC deve:

```text
- exigir auth.uid();
- validar corretor ativo;
- validar empresa da simulação;
- bloquear cross-tenant;
- permitir corretor dono ou perfil administrativo compatível;
- não aceitar empresa_id do frontend como autoridade;
- não executar DML;
- retornar somente JSON;
- ter search_path explícito;
- usar SECURITY DEFINER somente se necessário e com validação interna forte.
```

## 8. Regras de data

### 8.1 Campo de origem

Quando `mesa_fluxo_pagamentos.data_prevista` existir, o adaptador deve mapear para:

```text
data_vencimento
```

### 8.2 Curto prazo sem data

Para tipos `curto_prazo` sem `data_prevista`, o adaptador não deve inventar datas silenciosamente.

Opções permitidas:

```text
1. derivar a partir da descrição apenas se houver regra determinística validada;
2. retornar warning/bloqueio solicitando data explícita;
3. usar fallback somente se documentado e marcado no diagnóstico.
```

### 8.3 +30/+60/+90

A Fase 20C provou que dias corridos podem gerar datas diferentes da expectativa comercial.

Portanto:

```text
+30/+60/+90 devem preferir data oficial explícita.
```

Se for necessário inferir, a inferência deve ser documentada no diagnóstico e não pode ocorrer sem marcação.

## 9. Regras de grupo

### 9.1 `entrada`

```text
entrada -> entrada
```

### 9.2 `curto_prazo`

```text
curto_prazo -> entrada
```

Justificativa:

```text
No fluxo atual do MesaCliente, +30/+60/+90 representam complementos de entrada/curto prazo, não mensais de financiamento.
```

### 9.3 `periodica`

```text
periodica -> mensais
```

### 9.4 `intermediaria`

```text
intermediaria -> intermediarias
```

### 9.5 `quitacao`

```text
quitacao -> parcela_unica
```

## 10. Regras de quantidade e valor

O adaptador deve preservar:

```text
valor
quantidade
periodicidade
descricao
ordem
```

E bloquear:

```text
valor null
valor negativo
quantidade null quando necessária
quantidade menor que 1
quantidade incompatível com limite da 4A
```

## 11. Diagnóstico obrigatório

O adaptador deve retornar diagnóstico com pelo menos:

```text
- tipos encontrados;
- tipos mapeados;
- itens sem data;
- itens com data inferida;
- itens bloqueados;
- soma unitária;
- soma expandida estimada, quando possível;
- warnings.
```

## 12. Critérios de PASS da 20D

```text
[ ] contrato aprovado;
[ ] schema real de mesa_fluxo_pagamentos revisado;
[ ] RPC/função adaptadora proposta;
[ ] migration criada;
[ ] teste read-only com Chateau Jardin unidade 501;
[ ] payload gerado pelo adaptador passa na 4A;
[ ] output da 4A bate com o piloto 20C;
[ ] sem DML na fase de adaptação;
[ ] documentação com outputs reais.
```

## 13. Próximo passo imediato

Executar revisão read-only do schema real de:

```text
public.mesa_fluxo_pagamentos
public.mesa_simulacoes
```

E confirmar todos os campos disponíveis para o adaptador.
