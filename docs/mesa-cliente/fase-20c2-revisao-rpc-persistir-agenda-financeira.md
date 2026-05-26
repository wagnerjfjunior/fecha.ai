# FECH.AI / MesaCliente — Fase 20C.2
# Revisão read-only — RPC `mesa_cliente_persistir_agenda_financeira_admin`

## 1. Status

```text
Status: REVISÃO READ-ONLY
Data: 2026-05-26
Projeto Supabase: Discador-MesaCliente
RPC analisada: public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)
DDL executado: NÃO
DML executado: NÃO
RPC executada: NÃO
Frontend alterado: NÃO
```

Objetivo:

```text
Avaliar se a RPC que persiste a agenda financeira canônica está conceitualmente segura para destravar o Modo 3 do piloto controlado, antes de qualquer execução com DML.
```

## 2. Definição real analisada

A definição real foi lida no catálogo PostgreSQL via `pg_get_functiondef`.

Assinatura confirmada:

```sql
public.mesa_cliente_persistir_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
) returns jsonb
```

Características confirmadas:

```text
LANGUAGE: plpgsql
SECURITY: SECURITY DEFINER
search_path: public
retorno: jsonb
```

## 3. Pontos positivos confirmados linha a linha

### 3.1 Autenticação obrigatória

A função usa:

```sql
v_auth_uid := auth.uid();
```

E bloqueia chamada sem usuário autenticado:

```sql
if v_auth_uid is null then
  raise exception 'Usuário não autenticado'
    using errcode = '28000';
end if;
```

Classificação:

```text
PASS_AUTH_UID
```

### 3.2 Corretor ativo obrigatório

A função busca `public.corretores` por `user_id = auth.uid()` e `ativo = true`.

Se não encontrar:

```sql
raise exception 'Corretor não encontrado ou inativo'
  using errcode = '42501';
```

Classificação:

```text
PASS_CORRETOR_ATIVO
```

### 3.3 Simulação obrigatória e validada

A função busca `public.mesa_simulacoes` por `p_simulacao_id` e valida existência.

Também valida:

```text
- simulação possui empresa_id;
- simulação possui empreendimento_id.
```

Classificação:

```text
PASS_SIMULACAO_BASE
```

### 3.4 Empreendimento coerente com empresa da simulação

A função busca o empreendimento e valida:

```sql
if v_empreendimento.empresa_id is distinct from v_simulacao.empresa_id then
  raise exception 'Empreendimento diverge da empresa da simulação'
    using errcode = '42501';
end if;
```

Classificação:

```text
PASS_EMPRESA_EMPREENDIMENTO
```

### 3.5 Bloqueio cross-empresa para usuários não root/global

A função valida:

```sql
if coalesce(v_corretor.role::text, '') not in ('admin_global', 'root')
   and v_corretor.empresa_id is distinct from v_simulacao.empresa_id then
  raise exception 'Usuário não pertence à empresa da simulação'
    using errcode = '42501';
end if;
```

Classificação:

```text
PASS_CROSS_EMPRESA_BASIC
```

### 3.6 Regra de perfil/dono da simulação

A função permite persistência para:

```text
admin_global
root
admin_local
gestor
coordenador
```

E para corretor comum apenas quando:

```sql
v_simulacao.corretor_id is not distinct from v_corretor.id
```

Classificação:

```text
PASS_ROLE_OWNER_BASIC
```

Observação:

```text
A regra é mais ampla que a matriz comercial 20A da 2ª via, porque aqui é persistência administrativa/canônica, não leitura comercial comum.
```

### 3.7 Payload não é autoridade para empresa_id

A função rejeita `empresa_id` divergente vindo em `p_payload_tabela`:

```sql
if p_payload_tabela ? 'empresa_id'
   and nullif(p_payload_tabela->>'empresa_id', '')::uuid is distinct from v_simulacao.empresa_id then
  raise exception 'empresa_id do payload_tabela diverge da simulação e não é autoridade'
    using errcode = '42501';
end if;
```

Classificação:

```text
PASS_EMPRESA_ID_PAYLOAD_NOT_AUTHORITY
```

### 3.8 Lock transacional por simulação

A função usa:

```sql
perform pg_advisory_xact_lock(hashtextextended('mesa_cliente_agenda_financeira:' || p_simulacao_id::text, 0));
```

Classificação:

```text
PASS_ADVISORY_LOCK
```

### 3.9 Bloqueio de substituição quando existe operação confirmada

A função verifica operação confirmada em `mesa_cliente_fluxo_operacoes` e, se existir agenda ativa diferente, bloqueia substituição:

```sql
if v_agenda_existente_id is not null and v_tem_operacao_confirmada is true then
  raise exception 'Agenda não pode ser substituída: existe operação financeira confirmada para a simulação'
    using errcode = '55000';
end if;
```

Classificação:

```text
PASS_LOCK_OPERACAO_CONFIRMADA
```

### 3.10 Idempotência por checksum

A função calcula checksum e retorna sem novo DML quando agenda ativa existente tem o mesmo checksum.

Classificação:

```text
PASS_IDEMPOTENCIA_CHECKSUM
```

### 3.11 Append/versionamento de agenda

Quando há agenda anterior diferente e sem operação confirmada, a função marca a anterior como `substituida` e cria nova versão ativa.

Classificação:

```text
PASS_VERSIONAMENTO_AGENDA
```

### 3.12 Persistência canônica de parcelas com original/atual

A função insere em `mesa_cliente_fluxo_parcelas` preenchendo:

```text
valor_original
valor_atual
data_original
data_atual
origem_data
ordem
pode_receber_vpl
pode_receber_antecipacao
pode_receber_postergacao
metadata
```

Classificação:

```text
PASS_PARCELAS_CANONICAS
```

## 4. Pontos de atenção

### 4.1 Dependência da RPC 4A

A função chama:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(...)
```

Essa RPC precisa ser revisada separadamente porque a persistência 4B depende diretamente da agenda gerada por ela.

Classificação:

```text
WARN_DEPENDE_4A
```

### 4.2 Payload financeiro ainda entra como JSON

A função recebe `p_fluxo_json` e `p_payload_tabela`. Ela valida `empresa_id` divergente, mas os valores financeiros da agenda vêm da 4A e do fluxo informado.

Isto é esperado para o desenho JSON-first, porém exige que 4A seja a fronteira de normalização/validação.

Classificação:

```text
WARN_VALIDAR_4A_NORMALIZACAO
```

### 4.3 Política de permissão administrativa pode ser ampla

A função libera `admin_local`, `gestor` e `coordenador` para persistir agenda de simulação da empresa, mesmo quando não são donos da simulação.

Isso pode estar correto, mas precisa ser decisão de produto/segurança.

Classificação:

```text
WARN_PERMISSAO_ADMINISTRATIVA_AMPLA
```

### 4.4 Root/global podem atravessar empresa

A função permite `admin_global` e `root` sem a restrição de empresa.

Isso pode estar correto para operação administrativa sistêmica, mas deve permanecer fora de telas comuns e ações comerciais normais.

Classificação:

```text
WARN_ROOT_GLOBAL_ADMIN
```

### 4.5 Sem audit_logs explícito nesta RPC

Na definição analisada não foi identificado insert explícito em `audit_logs` dentro da função.

Classificação:

```text
WARN_AUDIT_LOG_EXPLICITO_AUSENTE
```

Isso não bloqueia necessariamente o piloto, mas é um ponto de governança financeira.

## 5. Avaliação de segurança para Modo 3 do piloto

### 5.1 Modo 3 pretendido

```text
Histórico + persistência de agenda canônica.
```

### 5.2 Decisão preliminar

```text
Modo 3 pode avançar para preparação controlada, desde que a RPC 4A seja revisada antes da execução efetiva.
```

### 5.3 Por que não liberar execução ainda

A RPC 4B parece conceitualmente bem protegida, mas depende da RPC 4A para gerar a agenda. Sem revisar 4A, seria incompleto liberar DML de persistência.

## 6. Status final

```text
RPC 4B persistência: OK PRELIMINAR COM WARNS
Execução DML: AINDA NÃO LIBERADA
Bloqueio restante: revisão da RPC 4A geradora de agenda
```

## 7. Próxima ação recomendada

Revisar linha a linha:

```text
public.mesa_cliente_gerar_agenda_financeira_admin(uuid,date,jsonb,jsonb)
```

Critérios mínimos:

```text
- entender se é puramente computacional ou se faz DML;
- validar tratamento de p_fluxo_json;
- validar se ignora autoridade soberana do payload;
- validar se não acessa dados cross-tenant sem controle;
- validar formato de saída esperado pela 4B;
- confirmar que não expõe cliente-safe indevidamente.
```
