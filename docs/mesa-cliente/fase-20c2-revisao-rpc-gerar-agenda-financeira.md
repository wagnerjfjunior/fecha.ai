# FECH.AI / MesaCliente — Fase 20C.2
# Revisão read-only — RPC `mesa_cliente_gerar_agenda_financeira_admin`

## 1. Status

```text
Status: REVISÃO READ-ONLY
Data: 2026-05-26
Projeto Supabase: Discador-MesaCliente
RPC analisada: public.mesa_cliente_gerar_agenda_financeira_admin(uuid,date,jsonb,jsonb)
DDL executado: NÃO
DML executado: NÃO
RPC executada: NÃO
Frontend alterado: NÃO
```

Objetivo:

```text
Avaliar se a RPC 4A, responsável por gerar agenda financeira JSON-first sem persistência, está segura e coerente para destravar o Modo 3 do piloto controlado em conjunto com a RPC 4B.
```

## 2. Definição real analisada

A definição real foi lida no catálogo PostgreSQL via `pg_get_functiondef`.

Assinatura confirmada:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
) returns jsonb
```

Características confirmadas:

```text
LANGUAGE: plpgsql
VOLATILITY: STABLE
SECURITY: SECURITY DEFINER
search_path: public
retorno: jsonb
tamanho da definição: 11721 caracteres
```

## 3. Natureza da RPC

A própria resposta da função declara:

```json
{
  "fase": "4A_JSON_FIRST",
  "visao": "administrativa",
  "cliente_safe": false,
  "persistencia": false,
  "dml_financeiro": false
}
```

Classificação:

```text
PASS_4A_SEM_PERSISTENCIA_DECLARADA
```

A revisão do corpo não identificou `insert`, `update`, `delete` ou `truncate` dentro da RPC.

Classificação:

```text
PASS_4A_COMPUTACIONAL
```

## 4. Pontos positivos confirmados linha a linha

### 4.1 Autenticação obrigatória centralizada

A função chama:

```sql
v_uid := public.mesa_cliente_assert_auth();
```

A função auxiliar existe como `SECURITY DEFINER`, `STABLE`, `search_path=public`.

Classificação:

```text
PASS_ASSERT_AUTH
```

### 4.2 Parâmetros obrigatórios validados

A função rejeita:

```text
p_simulacao_id null
p_data_ato null
p_fluxo_json null
p_payload_tabela não objeto JSON
```

Classificação:

```text
PASS_PARAMETROS_OBRIGATORIOS
```

### 4.3 Simulação obrigatória e validada

A função busca a simulação em `public.mesa_simulacoes` por `p_simulacao_id` e bloqueia:

```text
simulação inexistente
simulação sem empresa_id
simulação sem empreendimento_id
```

Classificação:

```text
PASS_SIMULACAO_BASE
```

### 4.4 Empreendimento validado contra empresa

A função chama:

```sql
public.mesa_cliente_assert_empreendimento_empresa(v_sim.empresa_id, v_sim.empreendimento_id)
```

Classificação:

```text
PASS_EMPRESA_EMPREENDIMENTO
```

### 4.5 Acesso à empresa validado

A função chama:

```sql
public.mesa_cliente_can_access_empresa(v_sim.empresa_id)
```

Se não houver permissão:

```text
Sem permissão para acessar a empresa da simulação
```

Classificação:

```text
PASS_ACCESS_EMPRESA
```

### 4.6 Contexto do corretor validado para não-root

Para usuários não root, a função valida:

```text
contexto de corretor existente
usuário ativo
empresa do usuário igual à empresa da simulação
```

Classificação:

```text
PASS_CORRETOR_CONTEXT_NON_ROOT
```

### 4.7 Permissão administrativa ou dono da simulação

A função calcula:

```sql
v_is_admin := public.mesa_cliente_can_admin_empresa(v_sim.empresa_id);
v_is_owner := v_ctx.corretor_id is not null and v_sim.corretor_id is not null and v_ctx.corretor_id = v_sim.corretor_id;
```

E só permite se:

```text
root ou admin da empresa ou dono da simulação
```

Classificação:

```text
PASS_ROLE_OWNER_BASIC
```

### 4.8 Payload não é autoridade para empresa/empreendimento

A função rejeita divergência em:

```text
p_payload_tabela.empresa_id
p_payload_tabela.empreendimento_id
item.empresa_id
```

Classificação:

```text
PASS_PAYLOAD_NOT_SOVEREIGN_BASIC
```

### 4.9 Normalização flexível de fluxo

A função aceita `p_fluxo_json` como array ou objeto contendo uma das chaves:

```text
parcelas
agenda
fluxo
itens
pagamentos
```

Classificação:

```text
PASS_INPUT_COMPATIBILITY
```

### 4.10 Limites de volume

A função bloqueia:

```text
mais de 500 itens de fluxo por chamada
mais de 1000 parcelas normalizadas por chamada
quantidade por item menor que 1 ou maior que 240
```

Classificação:

```text
PASS_LIMITES_VOLUME
```

### 4.11 Validação de grupo

A função normaliza grupo via:

```sql
public.mesa_cliente_agenda_json_first_grupo(v_grupo_raw)
```

Se o grupo for inválido, bloqueia.

Classificação:

```text
PASS_GRUPO_VALIDADO
```

### 4.12 Validação numérica

A função usa:

```sql
public.mesa_cliente_agenda_json_first_parse_numeric(...)
```

E bloqueia:

```text
valor null
valor negativo
```

Classificação:

```text
PASS_VALOR_NUMERIC_BASIC
```

### 4.13 Proteção de periodicidade simbólica

A função bloqueia tentativa de marcar periodicidade simbólica como falsa ou negociável indevidamente.

Classificação:

```text
PASS_PERIODICIDADE_SIMBOLICA
```

### 4.14 Datação de parcelas

A função trata data por:

```text
data oficial do item
mes_ano / competência
dias_offset / offset_dias
fallback mensal a partir da data_ato
```

Também valida mês/ano.

Classificação:

```text
PASS_DATACAO_BASIC
```

### 4.15 Saída estruturada para 4B

A função retorna `agenda` com:

```text
ordem
item_origem_index
parcela_numero
parcelas_total_item
grupo
descricao
valor
data_vencimento
origem_data
eh_periodicidade_simbolica
negociavel
motivos_bloqueio
```

Esses campos são compatíveis com a persistência da 4B em `mesa_cliente_fluxo_parcelas`.

Classificação:

```text
PASS_OUTPUT_COMPATIVEL_4B
```

## 5. Pontos de atenção

### 5.1 Função é SECURITY DEFINER, mas computacional

A RPC é `SECURITY DEFINER`, mas não executa DML financeiro. Ainda assim, por acessar simulação e contexto administrativo, a validação interna é necessária.

Classificação:

```text
WARN_SECURITY_DEFINER_COMPUTACIONAL
```

### 5.2 `STABLE` com retorno dependente de JSON de entrada

A função é `STABLE`. Isso é aceitável para função sem DML, mas a saída depende dos parâmetros e de tabelas lidas. Não há blocker identificado.

Classificação:

```text
OK_STABLE_SEM_DML
```

### 5.3 Root bypass de contexto de corretor

Para `root`, a função não exige `v_ctx` ativo da mesma forma que exige para não-root.

Classificação:

```text
WARN_ROOT_BYPASS_CONTEXT
```

Isso pode ser aceitável para operação sistêmica, mas root/global não deve ser exposto em tela comum.

### 5.4 Permissão administrativa ampla

A função permite admin da empresa e dono da simulação. Isso parece coerente para geração administrativa de agenda, mas deve permanecer documentado.

Classificação:

```text
WARN_ADMIN_CAN_GENERATE_AGENDA
```

### 5.5 Valores financeiros vêm do fluxo informado

A função valida forma, quantidade, grupo, data e negatividade, mas não recalcula a proposta nem reconcilia o valor total do fluxo contra o total oficial da simulação.

Classificação:

```text
WARN_SEM_RECONCILIACAO_TOTAL
```

Isto não bloqueia o Modo 3, porque a Fase 4A é JSON-first/agenda, não motor financeiro completo. Mas deve ser lembrado quando voltarmos à rastreabilidade original x final.

### 5.6 Sem cliente-safe

A própria função declara `cliente_safe=false`.

Classificação:

```text
OK_NAO_CLIENTE_SAFE
```

Não deve ser chamada diretamente por experiência cliente-final.

## 6. Dependências auxiliares confirmadas

Foram encontradas as funções auxiliares usadas pela 4A:

```text
mesa_cliente_assert_auth
mesa_cliente_assert_empreendimento_empresa
mesa_cliente_can_access_empresa
mesa_cliente_current_corretor_context
mesa_cliente_can_admin_empresa
mesa_cliente_agenda_json_first_grupo
mesa_cliente_agenda_json_first_parse_numeric
mesa_cliente_agenda_json_first_parse_date
mesa_cliente_agenda_json_first_last_day
```

Classificação:

```text
PASS_DEPENDENCIAS_EXISTEM
```

## 7. Avaliação para Modo 3 do piloto

### 7.1 Modo 3 pretendido

```text
Histórico + persistência de agenda canônica.
```

### 7.2 Decisão preliminar

```text
Modo 3 pode avançar para preparação de execução controlada.
```

Motivo:

```text
A RPC 4A é computacional, sem DML financeiro, com autenticação, autorização, validação de empresa/empreendimento, limites de volume, validação de grupos, valores e datas.

A RPC 4B já foi revisada como OK preliminar com WARNs e persiste a agenda canônica com lock, checksum, versionamento e bloqueio de substituição quando há operação confirmada.
```

### 7.3 Condição antes de executar

Antes de executar Modo 3 com DML via 4B:

```text
- selecionar massa controlada;
- definir ambiente explicitamente;
- registrar comandos/RPCs a executar;
- confirmar autorização explícita para DML controlado;
- capturar output real;
- gerar relatório de execução.
```

## 8. Status final

```text
RPC 4A geração: OK PRELIMINAR COM WARNS
RPC 4B persistência: OK PRELIMINAR COM WARNS
Gate B para Modo 3: TECNICAMENTE DESTRAVADO PARA PREPARAÇÃO
Execução DML: ainda depende de autorização explícita e seleção de massa controlada
Modo 4/5: continuam bloqueados até revisão de registrar/resumir/aplicar operação financeira
```

## 9. Próxima ação recomendada

Criar plano de execução do Modo 3:

```text
Fase 20C.3 — Execução controlada Modo 3: histórico + geração/persistência de agenda canônica
```

Escopo:

```text
1. selecionar simulação/unidade candidata;
2. validar histórico read-only;
3. gerar agenda 4A, se permitido;
4. persistir agenda 4B, somente com autorização explícita;
5. validar criação de registros em mesa_cliente_agendas_financeiras e mesa_cliente_fluxo_parcelas;
6. validar cliente-safe da agenda;
7. documentar output real.
```
