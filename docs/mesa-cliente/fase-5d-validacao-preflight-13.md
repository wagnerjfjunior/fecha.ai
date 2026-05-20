# FECH.AI / MesaCliente — Fase 5D

## Validação Preflight 13 — Leitura/consulta administrativa de operações financeiras

**Status:** APROVADO  
**Tipo:** preflight read-only  
**Escopo:** prontidão da base 5B/5C para criação das RPCs administrativas read-only da Fase 5D  
**Branch:** `feature/mesa-cliente-5d-leitura-operacoes-admin`

---

## 1. Objetivo

Validar, antes da migration 5D, se a base atual possui estrutura suficiente para criar uma camada segura de leitura administrativa das operações financeiras.

O preflight validou:

- tabelas obrigatórias;
- colunas core para leitura 5D;
- colunas financeiras persistidas pela 5B;
- colunas de auditoria da 5C;
- suporte aos status da operação;
- distribuição atual de status e visibilidade cliente;
- índices úteis para listagem;
- RLS e policies;
- grants diretos da tabela;
- dependências 5B/5C;
- ausência correta das RPCs 5D antes da migration;
- readiness para avançar.

---

## 2. Arquivo executado

```text
supabase/tests/mesa-cliente/engenharia-financeira/13_preflight_leitura_operacoes_financeiras_admin_readonly.sql
```

---

## 3. Resultado consolidado

| Bloco | Status | Interpretação |
|---|---:|---|
| `01_tabelas_obrigatorias` | PASS | Todas as tabelas obrigatórias existem. |
| `02_colunas_base_leitura_5d` | PASS | Todas as colunas core, financeiras 5B, auditoria 5C e autoria existem. |
| `03_status_operacao_suporte_5d` | PASS | Constraint suporta `simulada`, `confirmada`, `cancelada` e `bloqueada`. |
| `04_status_operacao_distribuicao_atual` | INFO | Distribuição atual informativa; nenhuma operação no momento do preflight. |
| `05_visibilidade_cliente_distribuicao_atual` | PASS | Nenhuma operação visível ao cliente. |
| `06_indices_para_listagem_5d` | PASS | Índices necessários para listagem administrativa já existem. |
| `07_rls_policies_operacoes` | PASS | RLS ativo e policies coerentes com leitura tenant-safe e bloqueio de DML direto. |
| `08_grants_tabela_operacoes` | PASS | `authenticated` tem SELECT; não tem DML direto; anon não tem DML. |
| `09_funcoes_dependencias_e_ausencia_5d` | PASS | RPCs 5B/5C existem; RPCs 5D ainda não existem, como esperado antes da migration. |
| `10_comentarios_rastreabilidade_5b_5c` | PASS | Comentários técnicos 5B/5C presentes em colunas relevantes. |
| `11_readiness_para_migration_5d` | PASS | Base pronta para desenhar migration/RPCs 5D read-only. |
| `99_readonly_notice` | INFO | Preflight read-only; sem fixture, sem DML, sem chamada de RPC 5D. |

---

## 4. Evidências técnicas principais

### 4.1 Tabelas obrigatórias

Todas existem:

```text
public.corretores
public.mesa_cliente_agendas_financeiras
public.mesa_cliente_fluxo_operacoes
public.mesa_cliente_fluxo_parcelas
public.mesa_simulacoes
```

### 4.2 Colunas core para leitura 5D

Todas existem:

```text
id
empresa_id
simulacao_id
agenda_id
parcela_origem_id
tipo_operacao
status_operacao
visivel_cliente
checksum_operacao
metadata
created_at
updated_at
```

### 4.3 Colunas financeiras 5B

Todas existem:

```text
empreendimento_id
politica_id
grupo_origem
grupo_destino
parcela_destino_id
valor_movido
valor_base
data_origem
data_destino
taxa_ano_pct
vpl_aplicado_pct
desconto_calculado
acrescimo_calculado
economia_liquida
premio_corretor_pct
dias_calculo
status_premio
```

### 4.4 Colunas de auditoria 5C

Todas existem:

```text
confirmado
confirmado_por
confirmado_em
cancelado_por
cancelado_em
motivo_cancelamento
```

### 4.5 Status suportados

A constraint atual suporta:

```text
simulada
confirmada
cancelada
bloqueada
```

Constraint:

```text
CHECK (status_operacao = ANY (ARRAY['simulada'::text, 'confirmada'::text, 'cancelada'::text, 'bloqueada'::text]))
```

### 4.6 Índices úteis já existentes

Entre os índices encontrados, o principal para a 5D é:

```text
idx_mcfo_empresa_simulacao_agenda_status
```

Definição:

```text
CREATE INDEX idx_mcfo_empresa_simulacao_agenda_status
ON public.mesa_cliente_fluxo_operacoes
USING btree (empresa_id, simulacao_id, agenda_id, status_operacao, created_at DESC)
```

Também existem índices por agenda/parcela/status, simulação/status, simulação/tipo e checksum ativo.

### 4.7 RLS e policies

RLS ativo:

```json
{
  "rls_enabled": true,
  "rls_forced": false
}
```

Policies encontradas:

```text
mcfo_no_direct_delete
mcfo_no_direct_insert
mcfo_no_direct_update
mcfo_select_tenant
```

A policy de SELECT usa `auth.uid()` com corretores ativos da mesma empresa, além de `is_root()`.

### 4.8 Grants da tabela

Resultado relevante:

```json
{
  "anon_tem_dml": false,
  "authenticated_tem_select": true,
  "authenticated_tem_dml_direto": false
}
```

### 4.9 Dependências 5B/5C

RPC 5B existe:

```text
public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb)
```

RPC 5C existe:

```text
public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb)
```

RPCs candidatas 5D ainda não existem:

```text
public.mesa_cliente_listar_operacoes_financeiras_admin(uuid,uuid,jsonb) = ausente
public.mesa_cliente_obter_operacao_financeira_admin(uuid,jsonb) = ausente
```

Isso é o comportamento esperado antes da migration canônica da 5D.

---

## 5. Readiness final

Resultado:

```text
11_readiness_para_migration_5d = PASS
```

Detalhes validados:

```text
required_tables_ok = true
core_read_cols_ok = true
financeiro_cols_ok = true
auditoria_5c_cols_ok = true
autoria_cols_ok = true
rls_enabled = true
rpc_5b_exists = true
rpc_5c_exists = true
rpc_5d_listar_exists = false
rpc_5d_obter_exists = false
has_listagem_index = true
has_status_index = true
has_checksum_index = true
suporta_simulada = true
suporta_confirmada = true
suporta_cancelada = true
suporta_bloqueada = true
```

Interpretação do preflight:

```text
Base pronta para desenhar migration/RPCs 5D read-only.
```

---

## 6. Veredito

```text
PREFLIGHT 13 = PASS
```

A base 5B/5C está pronta para a migration da Fase 5D.

---

## 7. Próximo passo

Criar a migration 5D com RPCs somente leitura:

```text
public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)
public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
```

Regras obrigatórias:

```text
read-only absoluto
sem DML
sem recalcular operação
sem alterar agenda
sem alterar parcelas
sem exposição cliente automática
sem soberania do frontend
auth.uid() obrigatório
tenant/empresa/perfil derivados do banco
anon/public sem execute
authenticated com execute
payload autoritativo bloqueado
```
