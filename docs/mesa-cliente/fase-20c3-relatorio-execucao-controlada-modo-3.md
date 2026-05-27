# FECH.AI / MesaCliente — Fase 20C.3
# Relatório — Execução controlada Modo 3

## 1. Status

```text
Status: PASS
Data/hora da execução: 2026-05-27 02:04:49 UTC
Projeto Supabase: Discador-MesaCliente
Modo executado: 3 — Histórico + geração/persistência de agenda canônica
RPC 4B executada: public.mesa_cliente_persistir_agenda_financeira_admin
DML executado: SIM, via RPC autorizada
DDL executado: NÃO
Migration executada nesta etapa: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Operação financeira registrada/aplicada: NÃO
```

## 2. Autorização

Execução autorizada no chat pelo usuário após explicação de DML.

Escopo autorizado:

```text
Executar a RPC 4B para persistir a agenda canônica da simulação 6e5df1f0-79c9-4011-848b-c2d328ad6a05 usando o payload adaptado aprovado na 20C.3.
```

## 3. Simulação utilizada

```text
simulacao_id: 6e5df1f0-79c9-4011-848b-c2d328ad6a05
empresa_id: [REDACTED_EMPRESA_ID]
empreendimento_id: 69230c50-cffd-4f87-9b37-7266ec0f54fc
unidade_estoque_id: fd546fdd-4fa9-4c9d-9344-0b7a5023afe4
empreendimento: Chateau Jardin
unidade: 501
corretor: Wagner
role: admin_local
```

## 4. Contexto autenticado usado

```text
request.jwt.claim.sub: 10b90f39-84a5-49a4-8ba6-165ef7178f11
request.jwt.claim.role: authenticated
```

## 5. Payload usado

Payload conforme decisão 20C.3 Opção A:

```text
entrada -> entrada
curto_prazo -> entrada
periodica -> mensais
intermediaria -> intermediarias
quitacao -> parcela_unica
data_prevista -> data_vencimento
```

Datas oficiais explícitas usadas:

```text
Ato: 2026-05-26
+30 dias: 2026-06-26
+60 dias: 2026-07-26
+90 dias: 2026-08-26
Mensais: início em 2026-09-15
Semestrais: início em 2026-12-15
Parcela única: 2029-09-15
```

## 6. Output real da RPC 4B

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

## 7. Validação da agenda criada

Registro encontrado em `public.mesa_cliente_agendas_financeiras`:

```text
agenda_id: 904d3b09-02f7-4ab5-827e-b83c99d63c3b
empresa_id: [REDACTED_EMPRESA_ID]
simulacao_id: 6e5df1f0-79c9-4011-848b-c2d328ad6a05
empreendimento_id: 69230c50-cffd-4f87-9b37-7266ec0f54fc
unidade_estoque_id: fd546fdd-4fa9-4c9d-9344-0b7a5023afe4
versao: 1
status: ativa
origem: 4b_persistencia_agenda_financeira
checksum: 64b1aa4ffd85f48a69c3e182d64da288
totais.valor_total: 1.883.397,54
totais.qtd_parcelas: 47
metadata.protocolo: protocolo-mestre-fechai-mesacliente-v1.2
criado_por: 10b90f39-84a5-49a4-8ba6-165ef7178f11
created_at: 2026-05-27 02:04:49.329886+00
```

Classificação:

```text
PASS_AGENDA_CRIADA
```

## 8. Validação das parcelas criadas

Consulta em `public.mesa_cliente_fluxo_parcelas` para a agenda criada retornou:

```text
qtd_parcelas: 47
soma_valor_atual: 1.883.397,54
primeira_data: 2026-05-26
ultima_data: 2029-09-15
```

Resumo por grupo persistido:

| Grupo persistido | Quantidade | Total |
|---|---:|---:|
| entrada | 4 | 710.645,67 |
| mensal | 36 | 529.629,84 |
| anual | 6 | 529.629,90 |
| unica | 1 | 113.492,13 |

Observação:

```text
A 4A recebe aliases canônicos como mensais/intermediarias/parcela_unica, mas a 4B persiste em enum/grupo interno normalizado como mensal/anual/unica.
```

Classificação:

```text
PASS_PARCELAS_CRIADAS
```

## 9. Amostra das parcelas persistidas

| Ordem | Grupo | Descrição | Valor original | Valor atual | Data original | Data atual | Origem data |
|---:|---|---|---:|---:|---|---|---|
| 1 | entrada | Ato | 408.000,00 | 408.000,00 | 2026-05-26 | 2026-05-26 | tabela_oficial |
| 2 | entrada | +30 dias | 100.881,89 | 100.881,89 | 2026-06-26 | 2026-06-26 | tabela_oficial |
| 3 | entrada | +60 dias | 100.881,89 | 100.881,89 | 2026-07-26 | 2026-07-26 | tabela_oficial |
| 4 | entrada | +90 dias | 100.881,89 | 100.881,89 | 2026-08-26 | 2026-08-26 | tabela_oficial |
| 5 | mensal | Mensais | 14.711,94 | 14.711,94 | 2026-09-15 | 2026-09-15 | tabela_oficial |
| 40 | mensal | Mensais | 14.711,94 | 14.711,94 | 2029-08-15 | 2029-08-15 | tabela_oficial |
| 41 | anual | Semestrais | 88.271,65 | 88.271,65 | 2026-12-15 | 2026-12-15 | tabela_oficial |
| 46 | anual | Semestrais | 88.271,65 | 88.271,65 | 2027-05-15 | 2027-05-15 | tabela_oficial |
| 47 | unica | Parcela única | 113.492,13 | 113.492,13 | 2029-09-15 | 2029-09-15 | tabela_oficial |

Todas as parcelas amostradas possuem:

```text
valor_original = valor_atual
data_original = data_atual
pode_receber_vpl = true
pode_receber_antecipacao = true
pode_receber_postergacao = true
```

Classificação:

```text
PASS_BASELINE_CANONICO_ORIGINAL_ATUAL
```

## 10. Validação cliente-safe

A RPC `public.mesa_cliente_obter_agenda_financeira_cliente_safe` foi executada em transação read-only com o mesmo contexto autenticado.

Resumo validado:

```text
ok: true
fase: 4C_CLIENTE_SAFE
visao: cliente_safe
agenda_status: ativa
valor_total: 1.883.397,54
qtd_parcelas: 47
qtd_parcelas_array: 47
```

Validação de não vazamento interno:

```text
expõe_checksum_na_raiz: false
expõe_metadata_na_raiz: false
expõe_payload_origem_na_raiz: false
parcela_expõe_chave_interna: false
```

Classificação:

```text
PASS_CLIENTE_SAFE
```

## 11. Achados durante validação

### 11.1 Colunas reais diferem de nomes intuitivos

Na agenda, o total fica em:

```text
totais.valor_total
totais.qtd_parcelas
```

Não existe coluna direta:

```text
valor_total_agenda
qtd_parcelas
```

### 11.2 Grupo canônico persistido é normalizado

A entrada da 4A usou:

```text
mensais
intermediarias
parcela_unica
```

A persistência gravou:

```text
mensal
anual
unica
```

Isso não quebrou a validação, mas deve ser considerado na UI/API.

### 11.3 Cliente-safe retornou payload longo

A resposta completa da cliente-safe foi truncada pela ferramenta por tamanho, então foi executada validação resumida específica para totais e ausência de chaves sensíveis.

## 12. Resultado final

```text
20C.3 Modo 3: PASS
Agenda canônica criada: SIM
Parcelas canônicas criadas: SIM
Cliente-safe validado: SIM
Operação financeira registrada/aplicada: NÃO
```

## 13. Próximos passos recomendados

### 13.1 Curto prazo

```text
1. Criar decisão de encerramento da 20C.3 como PASS.
2. Abrir fase própria para adaptador histórico -> agenda canônica.
3. Só depois avançar para Modo 4: registrar/resumir operação financeira.
```

### 13.2 Não fazer ainda

```text
- não alterar motor financeiro;
- não aplicar operação financeira;
- não implementar rastreabilidade original x ajustado;
- não alterar parser;
- não alterar Worker/Make;
- não expor UI nova antes de contrato do adaptador.
```
