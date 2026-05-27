# FECH.AI / MesaCliente — Fase 20D.1/20D.2
# Revisão read-only — Schema real para adaptador histórico -> agenda canônica

## 1. Status

```text
Status: READ-ONLY / SCHEMA REAL MAPEADO
Data: 2026-05-27
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
DDL executado: NÃO
DML executado: NÃO
RPC executada: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
```

Objetivo:

```text
Mapear o schema real das tabelas que alimentam o futuro adaptador histórico -> agenda canônica, antes de propor qualquer migration ou função nova.
```

Tabelas revisadas:

```text
public.mesa_fluxo_pagamentos
public.mesa_simulacoes
```

## 2. Colunas reais — `mesa_fluxo_pagamentos`

| Ordem | Coluna | Tipo | Nullable | Default |
|---:|---|---|---|---|
| 1 | id | uuid | NO | gen_random_uuid() |
| 2 | empresa_id | uuid | NO | null |
| 3 | simulacao_id | uuid | NO | null |
| 4 | tipo | mesa_fluxo_tipo | NO | null |
| 5 | descricao | text | YES | null |
| 6 | valor | numeric | YES | null |
| 7 | quantidade | integer | YES | null |
| 8 | periodicidade | text | YES | null |
| 9 | data_prevista | date | YES | null |
| 10 | ordem | integer | NO | 0 |
| 11 | created_at | timestamptz | NO | now() |

## 3. Colunas reais — `mesa_simulacoes`

Campos relevantes para o adaptador:

| Coluna | Tipo | Nullable | Observação |
|---|---|---|---|
| id | uuid | NO | chave da simulação |
| empresa_id | uuid | NO | autoridade tenant/empresa |
| corretor_id | uuid | YES | dono comercial |
| empreendimento_id | uuid | YES | necessário para validação com empreendimento |
| unidade_estoque_id | uuid | YES | necessário para agenda associada à unidade |
| status | mesa_simulacao_status | NO | default rascunho |
| oficial | boolean | NO | default false |
| valor_total | numeric | YES | total da simulação |
| entrada | numeric | YES | total de entrada/obra conforme simulação |
| financiamento | numeric | YES | total financiamento |
| valor_final | numeric | YES | valor final quando existir |
| versao | integer | NO | default 1 |
| simulacao_origem_id | uuid | YES | vínculo de versão/origem |
| snapshot_payload | jsonb | NO | metadados/snapshot da simulação |
| created_at | timestamptz | NO | criação |
| updated_at | timestamptz | NO | atualização |

## 4. Enum `mesa_fluxo_tipo`

Valores reais:

| Ordem | Valor |
|---:|---|
| 1 | entrada |
| 2 | curto_prazo |
| 3 | intermediaria |
| 4 | financiamento |
| 5 | quitacao |
| 6 | periodica |
| 7 | observacao |

## 5. Enum `mesa_simulacao_status`

Valores reais:

```text
rascunho
em_analise
proposta_gerada
proposta_enviada
em_followup
aprovada
recusada
cancelada
expirada
prorrogada
revalidada
```

## 6. Constraints e FKs relevantes

### 6.1 `mesa_fluxo_pagamentos`

```text
PK: id
FK empresa_id -> empresas.id
FK simulacao_id -> mesa_simulacoes.id
NOT NULL: id, empresa_id, simulacao_id, tipo, ordem, created_at
```

### 6.2 `mesa_simulacoes`

```text
PK: id
FK empresa_id -> empresas.id
FK corretor_id -> corretores.id
FK empreendimento_id -> empreendimentos.id
FK unidade_estoque_id -> unidades_estoque.id
FK lead_id -> leads.id
FK simulacao_origem_id -> mesa_simulacoes.id
FK proposta_prorrogada_por -> corretores.id
FK estoque_confirmado_por -> corretores.id
```

## 7. Índices reais relevantes

### 7.1 `mesa_fluxo_pagamentos`

```sql
CREATE INDEX idx_mesa_fluxo_empresa_simulacao
ON public.mesa_fluxo_pagamentos USING btree (empresa_id, simulacao_id);
```

Avaliação:

```text
PASS_INDEX_ADAPTADOR_BASE
```

Esse índice atende bem o padrão do adaptador:

```text
where empresa_id = v_sim.empresa_id and simulacao_id = p_simulacao_id
```

### 7.2 `mesa_simulacoes`

Índices relevantes:

```sql
idx_mesa_simulacoes_empresa_corretor (empresa_id, corretor_id, created_at desc)
idx_mesa_simulacoes_empresa_lead (empresa_id, lead_id)
idx_mesa_simulacoes_empresa_status (empresa_id, status)
idx_mesa_simulacoes_unidade (empresa_id, unidade_estoque_id)
mesa_simulacoes_pkey (id)
uq_mesa_simulacao_oficial_por_lead (empresa_id, lead_id) where oficial = true and lead_id is not null
```

## 8. RLS e policies

### 8.1 RLS

Ambas as tabelas estão com:

```text
rls_enabled: true
rls_forced: true
```

Classificação:

```text
PASS_RLS_FORCED
```

### 8.2 Policies SELECT

Policies encontradas:

```sql
mesa_fluxo_pagamentos:
  SELECT to authenticated
  using (is_root() OR empresa_id = my_empresa_id())

mesa_simulacoes:
  SELECT to authenticated
  using (is_root() OR empresa_id = my_empresa_id())
```

Classificação:

```text
PASS_RLS_EMPRESA_SCOPE_SELECT
```

## 9. Grants diretos para authenticated

Consulta de privilégios para `anon`, `authenticated`, `public` e `service_role` mostrou apenas grants para `service_role` nessas duas tabelas.

Não foram encontrados grants diretos para `authenticated` ou `anon` em:

```text
mesa_fluxo_pagamentos
mesa_simulacoes
```

Classificação:

```text
PASS_NO_DIRECT_AUTHENTICATED_GRANTS
```

Observação:

```text
O acesso aplicativo deve ocorrer por RPCs seguras/SECURITY DEFINER ou por políticas/grants explicitamente revisados. Isso é coerente com a estratégia de reduzir superfície de acesso direto.
```

## 10. Amostra controlada — Chateau Jardin unidade 501

Simulação usada:

```text
simulacao_id: 6e5df1f0-79c9-4011-848b-c2d328ad6a05
empresa_id: [REDACTED_EMPRESA_ID]
corretor_id: 9be9dae0-1699-49a2-a7ab-beeef274f22b
empreendimento_id: 69230c50-cffd-4f87-9b37-7266ec0f54fc
unidade_estoque_id: fd546fdd-4fa9-4c9d-9344-0b7a5023afe4
status: rascunho
oficial: false
valor_total: 3.783.070,89
entrada: 1.883.397,54
financiamento: 0,00
valor_final: null
```

Fluxo histórico:

| Ordem | Tipo | Descrição | Valor | Quantidade | Periodicidade | Data prevista |
|---:|---|---|---:|---:|---|---|
| 0 | entrada | Ato | 408.000,00 | 1 | null | 2026-05-26 |
| 1 | curto_prazo | +30 dias | 100.881,89 | 1 | null | null |
| 2 | curto_prazo | +60 dias | 100.881,89 | 1 | null | null |
| 3 | curto_prazo | +90 dias | 100.881,89 | 1 | null | null |
| 4 | periodica | Mensais | 14.711,94 | 36 | null | 2026-09-15 |
| 5 | intermediaria | Semestrais | 88.271,65 | 6 | semestral | 2026-12-15 |
| 6 | quitacao | Parcela única | 113.492,13 | 1 | null | 2029-09-15 |

## 11. Mapeamento sugerido confirmado pela amostra

Consulta read-only aplicando regra de mapeamento sugerida retornou:

| Ordem | Tipo histórico | Descrição | Grupo canônico sugerido | Data vencimento sugerida |
|---:|---|---|---|---|
| 0 | entrada | Ato | entrada | 2026-05-26 |
| 1 | curto_prazo | +30 dias | entrada | 2026-06-26 |
| 2 | curto_prazo | +60 dias | entrada | 2026-07-26 |
| 3 | curto_prazo | +90 dias | entrada | 2026-08-26 |
| 4 | periodica | Mensais | mensais | 2026-09-15 |
| 5 | intermediaria | Semestrais | intermediarias | 2026-12-15 |
| 6 | quitacao | Parcela única | parcela_unica | 2029-09-15 |

Classificação:

```text
PASS_MAPPING_BASELINE_CHATEAU_501
```

## 12. Regras mínimas para o adaptador

### 12.1 Entrada

```sql
public.mesa_cliente_montar_payload_agenda_canonica(
  p_simulacao_id uuid
) returns jsonb
```

### 12.2 Saída esperada

A função deve retornar JSON com, no mínimo:

```json
{
  "ok": true,
  "fase": "20D_ADAPTADOR_HISTORICO_AGENDA_CANONICA",
  "simulacao_id": "...",
  "empresa_id": "...",
  "empreendimento_id": "...",
  "unidade_estoque_id": "...",
  "data_ato": "YYYY-MM-DD",
  "fluxo_json": [
    {
      "ordem": 0,
      "tipo": "entrada",
      "grupo": "entrada",
      "descricao": "Ato",
      "valor": 408000.00,
      "quantidade": 1,
      "periodicidade": null,
      "data_vencimento": "2026-05-26"
    }
  ],
  "payload_tabela": {
    "empresa_id": "...",
    "empreendimento_id": "...",
    "origem": "20D_ADAPTADOR_HISTORICO_AGENDA_CANONICA"
  },
  "diagnostico": {
    "qtd_itens_origem": 7,
    "qtd_itens_adaptados": 7,
    "warnings": []
  }
}
```

## 13. Validações obrigatórias do adaptador

A futura função deve bloquear:

```text
p_simulacao_id null
simulação inexistente
simulação sem empresa_id
simulação sem empreendimento_id
usuário não autenticado
usuário sem acesso à empresa da simulação
fluxo vazio
item com empresa_id divergente da simulação
item sem tipo
tipo observacao como item financeiro
item sem valor em item financeiro
valor negativo
quantidade menor que 1
quantidade maior que 240
grupo histórico não mapeado
data_vencimento impossível de inferir
```

## 14. Regras de data recomendadas

Ordem de precedência:

```text
1. usar data_prevista quando preenchida;
2. para curto_prazo com descrição +30/+60/+90, inferir por meses comerciais a partir da data_ato;
3. para demais itens sem data_prevista, bloquear ou emitir erro controlado;
4. não usar dias corridos para +30/+60/+90, porque isso desloca datas comerciais.
```

Regra de meses comerciais:

```sql
p_data_ato + make_interval(months => n)
```

Exemplo:

```text
2026-05-26 + 1 mês = 2026-06-26
2026-05-26 + 2 meses = 2026-07-26
2026-05-26 + 3 meses = 2026-08-26
```

## 15. Regras de grupo recomendadas

| Tipo histórico | Grupo canônico 4A |
|---|---|
| entrada | entrada |
| curto_prazo | entrada |
| periodica | mensais |
| intermediaria | intermediarias |
| quitacao | parcela_unica |
| financiamento | financiamento |
| observacao | não financeiro / bloquear no fluxo financeiro |

## 16. Riscos e observações

### 16.1 `data_prevista` null em curto prazo

É esperado no Chateau 501. O adaptador precisa inferir pela descrição e pela data_ato.

### 16.2 Descrição como fonte de regra

Usar `descricao` para inferir +30/+60/+90 é aceitável como ponte controlada, mas deve ser documentado como regra de compatibilidade histórica, não como motor financeiro novo.

### 16.3 Total da agenda

O adaptador não deve recalcular ou alterar valores. Deve apenas adaptar os itens históricos para o formato aceito pela 4A/4B.

### 16.4 Sem autoridade do frontend

O adaptador deve ler simulação e fluxo do banco. O frontend deve fornecer apenas `p_simulacao_id`.

## 17. Decisão técnica preliminar

```text
O schema real é suficiente para implementar um adaptador read-only seguro.
```

A tabela `mesa_fluxo_pagamentos` possui os campos mínimos necessários:

```text
tipo, descricao, valor, quantidade, periodicidade, data_prevista, ordem
```

A tabela `mesa_simulacoes` possui os campos necessários de autoridade:

```text
empresa_id, corretor_id, empreendimento_id, unidade_estoque_id, valor_total, entrada, financiamento, snapshot_payload
```

## 18. Próximo passo recomendado

```text
20D.3 — Proposta técnica da RPC adaptadora read-only
```

Antes de criar migration, escrever o contrato SQL da função com:

```text
- assinatura;
- segurança;
- validações;
- payload de retorno;
- regras de erro;
- critérios de PASS.
```
