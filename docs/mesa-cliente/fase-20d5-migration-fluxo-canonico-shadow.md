# FECH.AI / MesaCliente — Fase 20D.5
# Migration: fluxo canônico em shadow mode

## 1. Status

```text
Status: MIGRATION CRIADA NO GITHUB / NÃO APLICADA NO SUPABASE
Data: 2026-05-28
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration criada: SIM
Migration executada no Supabase: NÃO
DML executado: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

## 2. Arquivo criado

```text
supabase/migrations/20260528013000_mesa_cliente_20d5_fluxo_canonico_shadow.sql
```

Commit:

```text
dd57e1970430dd7763e83cbc1d7a4a885f260379
```

## 3. Objetivo

Criar uma camada canônica paralela para fluxo financeiro, sem quebrar o legado.

A tabela legada continua existindo:

```text
public.mesa_fluxo_pagamentos
```

A nova tabela shadow será:

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

## 10. Não altera

```text
parser
Worker
Make/n8n
frontend
motor financeiro
propostas antigas
```

## 11. Pontos de atenção antes de aplicar

Antes de executar no Supabase, revisar:

```text
1. Se gen_random_uuid() está disponível.
2. Se enum mesa_fluxo_tipo possui observacao.
3. Se mesa_fluxo_pagamentos aceita tipo observacao.
4. Se grupo p ainda não é enviado pelo frontend — esperado.
5. Se financiamento residual é aceito como shadow canônico, sem impactar legado.
```

## 12. Queries de validação após aplicar

### 12.1 Verificar tabela

```sql
select
  table_schema,
  table_name
from information_schema.tables
where table_schema = 'public'
  and table_name = 'mesa_fluxo_pagamentos_canonico';
```

### 12.2 Verificar RLS

```sql
select
  schemaname,
  tablename,
  rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename = 'mesa_fluxo_pagamentos_canonico';
```

### 12.3 Verificar grants

```sql
select
  grantee,
  privilege_type
from information_schema.role_table_grants
where table_schema = 'public'
  and table_name = 'mesa_fluxo_pagamentos_canonico'
order by grantee, privilege_type;
```

Esperado:

```text
service_role com DML
authenticated sem SELECT/INSERT/UPDATE/DELETE direto
anon ausente
```

### 12.4 Verificar função `criar_mesa_simulacao`

```sql
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as args,
  p.prosecdef as security_definer,
  pg_get_userbyid(p.proowner) as owner,
  obj_description(p.oid, 'pg_proc') as comentario
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname = 'criar_mesa_simulacao';
```

Comentário esperado conter:

```text
MesaCliente 20D.5
```

## 13. Teste funcional obrigatório após aplicar

Criar uma nova simulação real/piloto e validar:

```text
1. mesa_fluxo_pagamentos legado ainda gravou linhas.
2. mesa_fluxo_pagamentos_canonico gravou linhas canônicas.
3. grupo u virou parcela_unica_obra no canônico.
4. financiamento residual virou financiamento_saldo no canônico.
5. quantidade não foi usada para inferir tipo.
6. periodicidade só aparece se grupo p for enviado.
7. tabela canônica preserva empresa_id/simulacao_id.
```

## 14. Estado final desta entrega

```text
Migration criada no GitHub.
Aguardando pull no Codespace.
Aguardando revisão/aplicação manual no Supabase pelo usuário.
Sem PASS funcional ainda.
```
