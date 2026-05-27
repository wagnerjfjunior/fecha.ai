# FECH.AI / MesaCliente — Fase 20C.3
# Seleção read-only — Simulação candidata para Modo 3

## 1. Status

```text
Status: READ-ONLY / MASSA CANDIDATA IDENTIFICADA
Data: 2026-05-26
Projeto Supabase: Discador-MesaCliente
DML executado: NÃO
RPC executada: NÃO
DDL executado: NÃO
Frontend alterado: NÃO
```

Objetivo:

```text
Selecionar uma simulação candidata para o piloto Modo 3: histórico + geração/persistência de agenda canônica.
```

## 2. Critério usado

Foi executada consulta read-only buscando simulações com:

```text
- registros em mesa_fluxo_pagamentos;
- zero agendas canônicas;
- zero operações canônicas;
- fluxo com valores preenchidos;
- dados suficientes de empresa, corretor, empreendimento e unidade.
```

## 3. Simulação candidata recomendada

```text
simulacao_id: 6e5df1f0-79c9-4011-848b-c2d328ad6a05
empresa_id: [REDACTED_EMPRESA_ID]
corretor_id: 9be9dae0-1699-49a2-a7ab-beeef274f22b
corretor_nome: Wagner
corretor_role: admin_local
corretor_ativo: true
empreendimento_id: 69230c50-cffd-4f87-9b37-7266ec0f54fc
empreendimento_nome: Chateau Jardin
unidade_estoque_id: fd546fdd-4fa9-4c9d-9344-0b7a5023afe4
torre: Harmonie Vert e Gris
unidade: 501
andar: 1
metragem: 185.10
valor_tabela: 3.783.070,89
valor_total_simulacao: 3.783.070,89
status: rascunho
created_at: 2026-05-26 13:59:30.159591+00
```

## 4. Motivo da escolha

```text
- é recente;
- tem 7 linhas de fluxo histórico;
- todas as linhas de fluxo possuem valor;
- não possui agenda canônica;
- não possui operação canônica;
- pertence ao Chateau Jardin, unidade 501, já usado visualmente na validação anterior de 2ª via;
- corretor associado está ativo e possui role admin_local;
- empresa/empreendimento/unidade estão preenchidos.
```

## 5. Fluxo histórico encontrado

| Ordem | Tipo | Descrição | Valor | Quantidade | Periodicidade | Data prevista |
|---:|---|---|---:|---:|---|---|
| 0 | entrada | Ato | 408.000,00 | 1 | null | 2026-05-26 |
| 1 | curto_prazo | +30 dias | 100.881,89 | 1 | null | null |
| 2 | curto_prazo | +60 dias | 100.881,89 | 1 | null | null |
| 3 | curto_prazo | +90 dias | 100.881,89 | 1 | null | null |
| 4 | periodica | Mensais | 14.711,94 | 36 | null | 2026-09-15 |
| 5 | intermediaria | Semestrais | 88.271,65 | 6 | semestral | 2026-12-15 |
| 6 | quitacao | Parcela única | 113.492,13 | 1 | null | 2029-09-15 |

## 6. Observação financeira importante

A soma direta dos valores unitários das 7 linhas do fluxo é:

```text
927.121,39
```

Esse número não representa necessariamente o total expandido da proposta, porque linhas periódicas possuem `quantidade` maior que 1.

Para o Modo 3, a validação correta é a geração/persistência de agenda canônica a partir das linhas e quantidades, não apenas a soma simples do campo `valor`.

## 7. Status contra critérios da 20C.3

| Critério | Status |
|---|---|
| Existe em mesa_simulacoes | PASS |
| Tem empresa_id | PASS |
| Tem empreendimento_id | PASS |
| Tem corretor_id | PASS |
| Corretor ativo | PASS |
| Tem unidade_estoque_id | PASS |
| Tem fluxo em mesa_fluxo_pagamentos | PASS |
| Fluxo tem valores | PASS |
| Não possui agenda canônica | PASS |
| Não possui operação canônica | PASS |
| Empreendimento/unidade identificados | PASS |

## 8. Bloqueios atuais

Nenhum blocker encontrado na seleção read-only.

A execução DML permanece bloqueada até autorização explícita.

## 9. Próximo passo recomendado

Preparar a chamada da RPC 4A:

```text
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id,
  p_data_ato,
  p_fluxo_json,
  p_payload_tabela
)
```

Com:

```text
p_simulacao_id = 6e5df1f0-79c9-4011-848b-c2d328ad6a05
p_data_ato = 2026-05-26
p_fluxo_json = derivado de mesa_fluxo_pagamentos, sem alterar dados
p_payload_tabela = empresa/empreendimento coerentes com a simulação
```

Antes de executar 4A, registrar o SQL exato para conferência.
