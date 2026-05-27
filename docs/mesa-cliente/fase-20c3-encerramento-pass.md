# FECH.AI / MesaCliente — Fase 20C.3
# Encerramento — PASS

## 1. Status final

```text
Status: PASS
Fase: 20C.3 — Execução controlada Modo 3
Modo: Histórico + geração/persistência de agenda canônica
Branch: feature/mesa-cliente-20c-rastreabilidade-valores
Data de encerramento: 2026-05-26
```

A Fase 20C.3 está encerrada como PASS.

## 2. Escopo executado

Foi executado o piloto controlado Modo 3 com a simulação:

```text
simulacao_id: 6e5df1f0-79c9-4011-848b-c2d328ad6a05
empreendimento: Chateau Jardin
unidade: 501
corretor: Wagner
role: admin_local
```

O piloto validou:

```text
1. seleção read-only de simulação candidata;
2. geração de agenda JSON-first via RPC 4A;
3. persistência de agenda canônica via RPC 4B autorizada;
4. criação de agenda em mesa_cliente_agendas_financeiras;
5. criação de parcelas em mesa_cliente_fluxo_parcelas;
6. leitura cliente-safe da agenda;
7. ausência de vazamento de campos internos no payload cliente-safe validado;
8. versionamento do hardening de grants da agenda financeira.
```

## 3. Evidências principais

### 3.1 RPC 4A — geração JSON-first

Resultado validado em read-only:

```text
ok=true
qtd_parcelas=47
soma_valores_expandidos=1.883.397,54
primeira_data=2026-05-26
ultima_data=2029-09-15
```

### 3.2 RPC 4B — persistência canônica

Resultado real da execução autorizada:

```json
{
  "ok": true,
  "fase": "4B_PERSISTENCIA_AGENDA",
  "visao": "administrativa",
  "versao": 1,
  "checksum": "64b1aa4ffd85f48a69c3e182d64da288",
  "agenda_id": "904d3b09-02f7-4ab5-827e-b83c99d63c3b",
  "idempotente": false,
  "cliente_safe": false,
  "persistencia": true,
  "simulacao_id": "6e5df1f0-79c9-4011-848b-c2d328ad6a05",
  "dml_financeiro": true,
  "valor_total_agenda": 1883397.54,
  "qtd_parcelas_persistidas": 47,
  "agenda_anterior_substituida": false
}
```

### 3.3 Agenda criada

```text
agenda_id: 904d3b09-02f7-4ab5-827e-b83c99d63c3b
status: ativa
versao: 1
valor_total: 1.883.397,54
qtd_parcelas: 47
checksum: 64b1aa4ffd85f48a69c3e182d64da288
```

### 3.4 Parcelas persistidas

```text
qtd_parcelas: 47
soma_valor_atual: 1.883.397,54
primeira_data: 2026-05-26
ultima_data: 2029-09-15
```

Resumo por grupo persistido:

| Grupo | Quantidade | Total |
|---|---:|---:|
| entrada | 4 | 710.645,67 |
| mensal | 36 | 529.629,84 |
| anual | 6 | 529.629,90 |
| unica | 1 | 113.492,13 |

### 3.5 Cliente-safe

Validação resumida:

```text
ok: true
fase: 4C_CLIENTE_SAFE
visao: cliente_safe
agenda_status: ativa
valor_total: 1.883.397,54
qtd_parcelas: 47
qtd_parcelas_array: 47
```

Validação de não vazamento:

```text
expõe_checksum_na_raiz: false
expõe_metadata_na_raiz: false
expõe_payload_origem_na_raiz: false
parcela_expõe_chave_interna: false
```

## 4. Hardening versionado

Foi criada migration para versionar hardening já aplicado no Supabase real:

```text
supabase/migrations/20260526162000_mesa_cliente_20c2_hardening_agendas_grants.sql
```

Escopo da migration:

```sql
revoke references on table public.mesa_cliente_agendas_financeiras from authenticated;
revoke trigger on table public.mesa_cliente_agendas_financeiras from authenticated;
revoke truncate on table public.mesa_cliente_agendas_financeiras from authenticated;

grant select on table public.mesa_cliente_agendas_financeiras to authenticated;
```

## 5. Decisões tomadas

### 5.1 Rastreabilidade original x ajustado

A rastreabilidade não foi implementada nesta fase.

Decisão:

```text
A rastreabilidade será planejada em fase própria, após consolidação do fluxo canônico e do adaptador histórico -> agenda canônica.
```

### 5.2 Payload adaptado para o piloto

Foi aprovada a Opção A:

```text
usar payload adaptado manual/controlado apenas no piloto.
```

Mapeamento usado:

| Histórico | Canônico |
|---|---|
| entrada | entrada |
| curto_prazo | entrada |
| periodica | mensais |
| intermediaria | intermediarias |
| quitacao | parcela_unica |
| data_prevista | data_vencimento |

### 5.3 Adaptador definitivo

A compatibilização definitiva entre `mesa_fluxo_pagamentos` e agenda canônica não foi implementada.

Decisão:

```text
Abrir fase própria para adaptador histórico -> agenda canônica antes de avançar para Modo 4/5.
```

## 6. Limitações conhecidas

```text
1. O fluxo histórico não é diretamente compatível com a entrada esperada pela 4A.
2. A 4A não aceita `curto_prazo`, `periodica`, `intermediaria`, `quitacao` como grupos diretos.
3. A 4A não reconhece `data_prevista`; reconhece campos como `data_vencimento`.
4. A 4B normaliza grupos persistidos para `mensal`, `anual`, `unica`.
5. Não houve registro/aplicação de operação financeira.
6. Não houve alteração de UI.
7. Não houve alteração de parser, Worker, Make ou motor financeiro.
```

## 7. Não escopo confirmado

Esta fase não implementou:

```text
- rastreabilidade original x ajustado;
- antecipação;
- amortização;
- juros;
- VPL;
- operação financeira aplicada;
- adaptador oficial;
- mudanças no frontend;
- mudanças no parser;
- mudanças no Worker/Make/n8n.
```

## 8. Próxima fase recomendada

```text
Fase 20D — Adaptador histórico -> agenda canônica
```

Objetivo:

```text
Criar contrato e implementação segura para converter `mesa_fluxo_pagamentos` em payload canônico aceito pela 4A/4B, sem depender de payload manual no piloto.
```

Escopo sugerido:

```text
1. contrato de mapeamento histórico/canônico;
2. função/RPC read-only de adaptação;
3. validação de datas comerciais;
4. validação de grupos;
5. teste com Chateau Jardin unidade 501;
6. preparação para Modo 4 somente depois.
```

## 9. Decisão final

```text
20C.3 encerrada como PASS.
A branch pode seguir para PR contra main.
Modo 4/5 permanecem bloqueados até a fase do adaptador.
```
