# FECH.AI / MesaCliente — Fase 20C.3
# Decisão — Opção A: payload adaptado controlado para o piloto

## 1. Status

```text
Status: DECISÃO APROVADA PARA PILOTO / SEM DML AINDA
Data: 2026-05-26
Branch: feature/mesa-cliente-20c-rastreabilidade-valores
Escopo: Modo 3 — histórico + geração/persistência de agenda canônica
DML executado neste documento: NÃO
RPC 4B executada: NÃO
Alteração de código: NÃO
Alteração de parser/Worker/Make: NÃO
```

Este documento registra a decisão operacional de usar, apenas no piloto 20C.3, payload adaptado e controlado para converter o fluxo histórico atual em entrada compatível com a RPC 4A/4B.

## 2. Decisão

Opção aprovada para o piloto:

```text
Opção A — usar payload adaptado manual/controlado apenas no piloto.
```

Decisão complementar:

```text
Depois do piloto, a compatibilização definitiva será tratada em fase própria.
```

## 3. Motivo

A execução read-only da RPC 4A demonstrou que:

```text
- a RPC 4A funciona quando recebe grupos canônicos e campos de data reconhecidos;
- o histórico atual usa aliases/tipos comerciais que a 4A não aceita diretamente;
- data_prevista não é campo reconhecido pela 4A;
- usar dias_offset para +30/+60/+90 não preserva necessariamente a lógica comercial de mesma data mensal;
- com payload adaptado e datas oficiais explícitas, a agenda foi gerada corretamente.
```

## 4. Mapeamento aprovado para o piloto

| Origem histórica | Entrada canônica para 4A/4B |
|---|---|
| `entrada` | `entrada` |
| `curto_prazo` | `entrada` |
| `periodica` | `mensais` |
| `intermediaria` | `intermediarias` |
| `quitacao` | `parcela_unica` |
| `data_prevista` | `data_vencimento` |

## 5. Datas oficiais usadas no piloto

Para evitar ambiguidade entre dias corridos e lógica comercial de meses, o piloto usará datas oficiais explícitas:

| Descrição | Data canônica |
|---|---|
| Ato | `2026-05-26` |
| +30 dias | `2026-06-26` |
| +60 dias | `2026-07-26` |
| +90 dias | `2026-08-26` |
| Mensais | início em `2026-09-15` |
| Semestrais | início em `2026-12-15` |
| Parcela única | `2029-09-15` |

## 6. Payload aprovado para execução controlada da 4B

Simulação:

```text
simulacao_id: 6e5df1f0-79c9-4011-848b-c2d328ad6a05
p_data_ato: 2026-05-26
```

`p_fluxo_json` aprovado para o piloto:

```json
[
  {
    "ordem": 0,
    "tipo": "entrada",
    "grupo": "entrada",
    "descricao": "Ato",
    "valor": 408000.00,
    "quantidade": 1,
    "periodicidade": null,
    "data_vencimento": "2026-05-26"
  },
  {
    "ordem": 1,
    "tipo": "curto_prazo",
    "grupo": "entrada",
    "descricao": "+30 dias",
    "valor": 100881.89,
    "quantidade": 1,
    "periodicidade": null,
    "data_vencimento": "2026-06-26"
  },
  {
    "ordem": 2,
    "tipo": "curto_prazo",
    "grupo": "entrada",
    "descricao": "+60 dias",
    "valor": 100881.89,
    "quantidade": 1,
    "periodicidade": null,
    "data_vencimento": "2026-07-26"
  },
  {
    "ordem": 3,
    "tipo": "curto_prazo",
    "grupo": "entrada",
    "descricao": "+90 dias",
    "valor": 100881.89,
    "quantidade": 1,
    "periodicidade": null,
    "data_vencimento": "2026-08-26"
  },
  {
    "ordem": 4,
    "tipo": "periodica",
    "grupo": "mensais",
    "descricao": "Mensais",
    "valor": 14711.94,
    "quantidade": 36,
    "periodicidade": null,
    "data_vencimento": "2026-09-15"
  },
  {
    "ordem": 5,
    "tipo": "intermediaria",
    "grupo": "intermediarias",
    "descricao": "Semestrais",
    "valor": 88271.65,
    "quantidade": 6,
    "periodicidade": "semestral",
    "data_vencimento": "2026-12-15"
  },
  {
    "ordem": 6,
    "tipo": "quitacao",
    "grupo": "parcela_unica",
    "descricao": "Parcela única",
    "valor": 113492.13,
    "quantidade": 1,
    "periodicidade": null,
    "data_vencimento": "2029-09-15"
  }
]
```

`p_payload_tabela` aprovado para o piloto:

```json
{
  "empresa_id": "a0000000-0000-0000-0000-000000000001",
  "empreendimento_id": "69230c50-cffd-4f87-9b37-7266ec0f54fc",
  "origem": "20C.3_modo_3_piloto_payload_adaptado",
  "adaptacao_grupos_historico_para_canonico": true,
  "adaptacao_data_prevista_para_data_vencimento": true,
  "decisao": "opcao_a_payload_adaptado_controlado_piloto"
}
```

## 7. Resultado esperado da 4A com este payload

Evidência já obtida em modo read-only:

```text
ok=true
qtd_parcelas=47
soma_valores_expandidos=1.883.397,54
primeira_data=2026-05-26
ultima_data=2029-09-15
```

Resumo por grupo:

| Grupo | Quantidade | Total |
|---|---:|---:|
| entrada | 4 | 710.645,67 |
| mensais | 36 | 529.629,84 |
| intermediarias | 6 | 529.629,90 |
| parcela_unica | 1 | 113.492,13 |

## 8. Restrições

Esta decisão não autoriza:

```text
- alterar a RPC 4A;
- alterar a RPC 4B;
- alterar mesa_fluxo_pagamentos;
- alterar parser;
- alterar Worker/Make/n8n;
- implementar adaptador definitivo;
- implementar rastreabilidade original x ajustado;
- registrar ou aplicar operação financeira;
- executar Modo 4/5.
```

## 9. Próximo passo

O próximo passo técnico é executar a RPC 4B:

```text
public.mesa_cliente_persistir_agenda_financeira_admin
```

com o payload acima.

Mas essa execução executa DML controlado via RPC e só pode ocorrer após autorização explícita.

## 10. Frase de autorização necessária

Para liberar a execução, registrar no chat autorização explícita equivalente a:

```text
Autorizo executar a RPC 4B para persistir a agenda canônica da simulação 6e5df1f0-79c9-4011-848b-c2d328ad6a05 usando o payload adaptado aprovado na 20C.3.
```

Sem essa autorização, a 4B permanece não executada.
