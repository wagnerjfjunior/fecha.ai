# FECH.AI / MesaCliente — Fase 20C.3
# Evidência — Geração de agenda 4A JSON-first

## 1. Status

```text
Status: EXECUTADO / READ-ONLY
Data: 2026-05-26
Projeto Supabase: Discador-MesaCliente
RPC executada: public.mesa_cliente_gerar_agenda_financeira_admin
DML executado: NÃO
Transação: begin read only + rollback
Persistência: NÃO
Frontend alterado: NÃO
```

Objetivo:

```text
Executar a RPC 4A em modo computacional/JSON-first para validar se a simulação candidata consegue gerar agenda financeira canônica antes de qualquer persistência via 4B.
```

## 2. Simulação candidata

```text
simulacao_id: 6e5df1f0-79c9-4011-848b-c2d328ad6a05
empreendimento: Chateau Jardin
unidade: 501
corretor: Wagner
role: admin_local
```

## 3. Tentativas e achados

### 3.1 Tentativa 1 — chamada sem contexto autenticado

Resultado:

```text
ERROR 28000: Usuário não autenticado
CONTEXT: PL/pgSQL function mesa_cliente_assert_auth()
```

Classificação:

```text
PASS_SECURITY_AUTH_REQUIRED
```

A RPC não roda sem contexto de usuário autenticado.

### 3.2 Tentativa 2 — contexto authenticated + CTE externa lendo fluxo histórico

Resultado:

```text
ERROR 42501: permission denied for table mesa_fluxo_pagamentos
```

Classificação:

```text
INFO_READ_DIRECT_BLOCKED
```

A falha ocorreu na leitura direta externa de `mesa_fluxo_pagamentos`, não dentro da 4A. Para testar a RPC, o payload foi montado como JSON controlado com base na seleção read-only anterior.

### 3.3 Tentativa 3 — payload literal com grupos históricos originais

Resultado:

```text
ERROR 22023: grupo inválido no item 2: curto_prazo
```

Classificação:

```text
WARN_COMPATIBILIDADE_GRUPOS_HISTORICO_CANONICO
```

A função normalizadora `mesa_cliente_agenda_json_first_grupo` aceita grupos como:

```text
entrada
mensais
intermediarias
anuais
chaves
financiamento
parcela_unica
periodicidade
```

O histórico atual usa tipos como:

```text
curto_prazo
periodica
intermediaria
quitacao
```

Portanto, existe necessidade de camada adaptadora entre fluxo histórico e agenda canônica.

### 3.4 Tentativa 4 — grupos adaptados, mas campo `data_prevista`

A agenda foi gerada com `ok=true`, porém a RPC ignorou `data_prevista`, pois espera campos de data como:

```text
data
data_vencimento
vencimento
data_original
data_parcela
dt_vencimento
```

Resultado funcional observado:

```text
Parcela única saiu em 2026-11-26, embora o histórico tivesse 2029-09-15.
```

Classificação:

```text
WARN_COMPATIBILIDADE_DATA_PREVISTA
```

### 3.5 Tentativa 5 — data por `dias_offset`

A agenda foi gerada, mas `+30/+60/+90` usando dias corridos resultou em:

```text
+30 dias: 2026-06-25
+60 dias: 2026-07-25
+90 dias: 2026-08-24
```

Classificação:

```text
WARN_DIAS_CORRIDOS_VS_LOGICA_COMERCIAL_MENSAL
```

Para preservar a lógica comercial da proposta, datas oficiais explícitas são mais adequadas.

### 3.6 Tentativa 6 — payload adaptado com grupos canônicos e datas oficiais

Resultado:

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

Classificação:

```text
PASS_4A_JSON_FIRST_COM_ADAPTACAO_CONTROLADA
```

## 4. Amostra da agenda gerada

| Ordem | Grupo | Descrição | Valor | Data vencimento | Origem data | Parcela | Total item |
|---:|---|---|---:|---|---|---:|---:|
| 1 | entrada | Ato | 408.000,00 | 2026-05-26 | data_oficial | 1 | 1 |
| 2 | entrada | +30 dias | 100.881,89 | 2026-06-26 | data_oficial | 1 | 1 |
| 3 | entrada | +60 dias | 100.881,89 | 2026-07-26 | data_oficial | 1 | 1 |
| 4 | entrada | +90 dias | 100.881,89 | 2026-08-26 | data_oficial | 1 | 1 |
| 5 | mensais | Mensais | 14.711,94 | 2026-09-15 | data_oficial | 1 | 36 |
| 40 | mensais | Mensais | 14.711,94 | 2029-08-15 | data_oficial | 36 | 36 |
| 41 | intermediarias | Semestrais | 88.271,65 | 2026-12-15 | data_oficial | 1 | 6 |
| 46 | intermediarias | Semestrais | 88.271,65 | 2027-05-15 | data_oficial | 6 | 6 |
| 47 | parcela_unica | Parcela única | 113.492,13 | 2029-09-15 | data_oficial | 1 | 1 |

## 5. Conclusão técnica

A RPC 4A funciona e gera a agenda canônica corretamente quando recebe:

```text
- grupos canônicos;
- datas em campos reconhecidos pela RPC;
- datas oficiais explícitas para marcos comerciais sensíveis.
```

Porém, o fluxo histórico atual não é diretamente compatível com a entrada esperada pela 4A.

## 6. Achado central

Antes de persistir via 4B, é necessário decidir como será feita a camada de adaptação entre:

```text
mesa_fluxo_pagamentos histórico
```

e:

```text
mesa_cliente_gerar_agenda_financeira_admin / agenda canônica
```

Mapeamento usado no teste:

| Histórico | Canônico 4A |
|---|---|
| entrada | entrada |
| curto_prazo | entrada |
| periodica | mensais |
| intermediaria | intermediarias |
| quitacao | parcela_unica |
| data_prevista | data_vencimento |

## 7. Status para Modo 3

```text
4A: PASS com payload adaptado
DML/Persistência 4B: AINDA NÃO EXECUTADA
Bloqueio atual: definir/adotar adaptação controlada do fluxo histórico para payload canônico
```

## 8. Próxima decisão necessária

Antes de executar a 4B, escolher uma das opções:

```text
Opção A — usar payload adaptado manual/controlado apenas no piloto.
Opção B — criar função/RPC adaptadora read-only para converter mesa_fluxo_pagamentos em payload canônico.
Opção C — alterar a 4A para aceitar aliases históricos como curto_prazo, periodica, quitacao e data_prevista.
```

Recomendação preliminar:

```text
Para o piloto controlado, usar Opção A.
Para produto, avaliar Opção B ou C em fase própria, sem misturar com a execução 20C.3.
```
