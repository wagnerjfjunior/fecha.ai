# FECH.AI / MesaCliente — Fase 20D.5
# Migration: fluxo canônico em shadow mode

## 1. Status

```text
Status: MIGRATION APLICADA NO SUPABASE / TESTES SHADOW EXECUTADOS
Data de criação: 2026-05-28
Data de aplicação/validação: 2026-05-29
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration criada: SIM
Migration executada no Supabase: SIM
DML executado: SIM — simulações piloto de validação
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

Evidências detalhadas dos testes:

```text
docs/mesa-cliente/fase-20d5-evidencias-testes-shadow.md
```

## 2. Arquivo criado

```text
supabase/migrations/20260528013000_mesa_cliente_20d5_fluxo_canonico_shadow.sql
```

Commit original da criação da migration:

```text
dd57e1970430dd7763e83cbc1d7a4a885f260379
```

## 3. Objetivo

Criar uma camada canônica paralela para fluxo financeiro, sem quebrar o legado.

A tabela legada continua existindo:

```text
public.mesa_fluxo_pagamentos
```

A nova tabela shadow é:

```text
public.mesa_fluxo_pagamentos_canonico
```

## 4. Por que shadow mode

Porque o legado ainda possui mapeamento histórico problemático:

```text
grupo u => tipo quitacao
```

Mas no negócio:

```text
u = parcela única/chaves de obra
u != quitação do saldo devedor
```

O shadow mode permite:

```text
1. preservar compatibilidade com telas antigas;
2. criar origem canônica correta para novas simulações;
3. comparar legado x canônico;
4. validar Chateau/Garden/Sereno/Bosque/ELO/Capitolo;
5. promover depois a fonte canônica com segurança.
```

## 5. O que a migration faz

### 5.1 Cria helper

```text
public.mesa_cliente_extract_obs_kv(text, text)
```

Uso:

```text
extrair chave=valor de unidades_estoque.observacoes
```

Exemplo:

```text
financiamento_data=2029-09-15
```

### 5.2 Cria tabela canônica

```text
public.mesa_fluxo_pagamentos_canonico
```

Campos principais:

```text
empresa_id
simulacao_id
fluxo_pagamento_id
grupo_original
grupo_canonico
natureza_financeira
descricao
ordem
valor_unitario
quantidade
valor_total
periodicidade
data_prevista
origem_data
fonte_tipo
fonte_valor
entra_agenda
entra_motor_financeiro
valor_simbolico
metadata
```

### 5.3 Atualiza `public.criar_mesa_simulacao`

A função passa a gravar:

```text
1. mesa_simulacoes;
2. mesa_fluxo_pagamentos legado;
3. mesa_fluxo_pagamentos_canonico shadow.
```

## 6. Matriz de mapeamento canônico

| Grupo frontend | Legado atual | Canônico shadow | Observação |
|---|---|---|---|
| `e` | entrada | entrada_ato | Ato/entrada |
| `c` | curto_prazo | entrada_complemento | Complemento de entrada |
| `m` | periodica | mensal_obra | Mensais de obra |
| `a` | intermediaria | intermediaria_obra | Anual/semestral |
| `u` | quitacao | parcela_unica_obra | Chaves/parcela única; não é quitação |
| `f` | financiamento | financiamento_saldo | Grupo novo suportado |
| `p` | observacao | periodicidade_obra | Final(is)/periodicidade simbólica |

## 7. Financiamento residual

Se o frontend não enviar grupo `f`, mas houver saldo residual:

```text
financiamento_total = valor_total - obra_total
```

A migration cria uma linha canônica:

```text
grupo_original = f_residual
grupo_canonico = financiamento_saldo
natureza_financeira = saldo_devedor_financiamento
fonte_tipo = residual_valor_total_menos_fluxo_obra
```

Isso corrige o problema observado no Chateau:

```text
mesa_simulacoes.financiamento existe;
mesa_fluxo_pagamentos não tinha linha de financiamento.
```

No legado, nada é inventado. No canônico, o saldo fica explícito e auditável.

## 8. Periodicidade / Final(is)

A migration aceita grupo `p` como:

```text
grupo_canonico = periodicidade_obra
natureza_financeira = controle_periodo_obra
entra_agenda = false
entra_motor_financeiro = false
valor_simbolico = true
```

Não entra no cálculo de obra_total.

A decisão de exibir ou não ao cliente fica para fase posterior.

## 9. Segurança

A tabela canônica nasce com:

```text
RLS habilitado
anon sem acesso
authenticated sem acesso direto
service_role com DML
```

O acesso operacional deve ocorrer por RPC `SECURITY DEFINER`, não por CRUD direto do frontend.

Validação pós-aplicação:

```text
PASS: RLS ativo.
PASS: anon sem acesso direto.
PASS: authenticated sem acesso direto.
PASS: service_role com DML.
PASS: criar_mesa_simulacao continua SECURITY DEFINER.
```

## 10. Não altera

```text
parser
Worker
Make/n8n
frontend
motor financeiro
propostas antigas
```

## 11. Resultado da validação

A validação forte foi executada com:

```text
usuário real autenticado
corretor ativo
empresa real
empreendimento real
unidade real 501 do Chateau Jardin
valor real de tabela
PostgREST real
RPC real
escrita real no legado
escrita real no canônico shadow
```

Simulação E2E criada por curl:

```text
0e8ed676-50e6-4401-b767-0532c2481209
```

Resultado resumido:

```text
20D.5 migration aplicada: PASS
20D.5 estrutura/RLS/grants: PASS
20D.5 piloto SQL controlado: PASS
20D.5 curl/API E2E com unidade real 501: PASS
20D.5 escrita no legado: PASS
20D.5 escrita no canônico shadow: PASS
20D.5 u -> parcela_unica_obra: PASS
20D.5 f_residual -> financiamento_saldo: PASS
20D.5 p -> periodicidade_obra: PASS
20D.5 bloqueio direto anon/authenticated por grants/RLS/role SQL: PASS
```

## 12. Próximos passos

```text
1. Manter a PR como draft até decisão explícita sobre promoção do canônico para leitura operacional.
2. Não promover mesa_fluxo_pagamentos_canonico como fonte oficial do frontend sem nova fase, novo diff e autorização explícita.
3. Executar evidência HTTP/curl adicional para bloqueio direto da tabela shadow com token válido, se desejado.
4. Preparar fase posterior para leitura canônica/controlada, sem quebrar legado.
```
