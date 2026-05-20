# FECH.AI / MesaCliente — Fase 5D

## Contrato Técnico — Leitura/consulta administrativa de operações financeiras

**Status:** ABERTA PARA DESENHO TÉCNICO  
**Fase anterior:** 5C — Confirmação/cancelamento administrativo de operação financeira  
**Branch:** `feature/mesa-cliente-5d-leitura-operacoes-admin`  
**Escopo:** backend Supabase/PostgreSQL — RPCs read-only administrativas  

---

## 1. Objetivo

A Fase 5D deve criar uma camada segura de leitura administrativa para consultar operações financeiras registradas pela Fase 5B e administradas pela Fase 5C.

A 5D deve permitir que uma futura UI administrativa consiga:

```text
listar operações financeiras de uma simulação/agenda
obter detalhes de uma operação financeira específica
exibir status administrativo da operação
exibir auditoria de confirmação/cancelamento
exibir cálculo/resultado já persistido pela 5B
exibir metadados técnicos controlados
```

Sem:

```text
alterar dados
recalcular operação
alterar agenda
alterar parcelas
confirmar/cancelar operação
expor automaticamente ao cliente
aceitar soberania do frontend para tenant/empresa/perfil
```

---

## 2. Princípios obrigatórios

A 5D deve seguir os mesmos princípios já fechados nas fases anteriores:

```text
Banco/RPC é soberano.
Frontend não define tenant, empresa, corretor, perfil ou permissão.
Toda autorização crítica usa auth.uid() e dados persistidos no banco.
Toda RPC deve ser multi-tenant e multiempresa.
Toda RPC deve bloquear anon.
Toda RPC deve ser read-only.
Toda RPC deve preservar agenda e parcelas.
Toda RPC deve preservar o motor financeiro.
```

---

## 3. RPCs propostas

### 3.1 Listagem administrativa

```sql
public.mesa_cliente_listar_operacoes_financeiras_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid default null,
  p_filtros jsonb default '{}'::jsonb
)
returns jsonb
```

Responsabilidade:

```text
listar operações financeiras vinculadas à simulação
opcionalmente filtrar por agenda
opcionalmente filtrar por status/tipo/visibilidade/data
retornar resumo administrativo seguro
não retornar dados fora do tenant/empresa autorizados
```

### 3.2 Obtenção administrativa de operação

```sql
public.mesa_cliente_obter_operacao_financeira_admin(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
```

Responsabilidade:

```text
obter detalhe administrativo de uma operação específica
validar pertencimento a tenant/empresa autorizados
retornar cálculo persistido e auditoria
não recalcular nada
não alterar nada
```

---

## 4. Fora do escopo da 5D

A 5D não deve implementar:

```text
publicação cliente-safe
visibilidade para cliente
PDF/relatório cliente
alteração de status
estorno/reversão de operação confirmada
novo cálculo financeiro
alteração de agenda
alteração de parcelas
alteração no frontend
alteração no Worker
alteração no Make/n8n
```

Esses itens devem ser tratados em fases próprias.

---

## 5. Segurança esperada

### 5.1 Grants

Para cada RPC 5D:

```sql
revoke all on function ... from public;
revoke all on function ... from anon;
grant execute on function ... to authenticated;
```

Validação esperada:

```text
anon_execute = false
public_execute = false
authenticated_execute = true
```

### 5.2 Autenticação

Toda chamada deve exigir:

```text
auth.uid() presente
```

Sem `auth.uid()`, retornar erro controlado, preferencialmente:

```text
SQLSTATE 28000
```

### 5.3 Autorização multi-tenant/multiempresa

A RPC deve derivar do banco:

```text
user_id = auth.uid()
corretor/perfil ativo
empresa autorizada
papel/perfil administrativo autorizado
```

A RPC não deve aceitar como autoridade soberana:

```text
empresa_id
tenant_id
corretor_id
user_id
role
perfil
is_admin
is_gestor
```

Se algum desses campos vier no payload/filtros como tentativa autoritativa, a RPC deve bloquear ou ignorar de forma documentada. Preferência: bloquear com erro controlado para não normalizar payload perigoso.

---

## 6. Filtros permitidos na listagem

Filtros aceitáveis em `p_filtros`:

```json
{
  "status_operacao": "simulada|confirmada|cancelada|bloqueada",
  "tipo_operacao": "antecipacao|postergacao|...",
  "visivel_cliente": false,
  "data_de": "YYYY-MM-DD",
  "data_ate": "YYYY-MM-DD",
  "limit": 50,
  "offset": 0,
  "order_by": "created_at|updated_at|status_operacao|tipo_operacao",
  "order_dir": "asc|desc"
}
```

Regras:

```text
p_filtros deve ser objeto JSON.
limit deve ter teto seguro.
offset deve ser >= 0.
order_by deve ser allowlist.
order_dir deve ser allowlist.
campos autoritativos devem ser bloqueados.
```

---

## 7. Payload esperado — listagem

Formato sugerido:

```json
{
  "ok": true,
  "fase": "5D_LEITURA_OPERACOES_FINANCEIRAS_ADMIN",
  "visao": "administrativa",
  "cliente_safe": false,
  "readonly": true,
  "simulacao_id": "uuid",
  "agenda_id": "uuid|null",
  "total": 0,
  "limit": 50,
  "offset": 0,
  "operacoes": []
}
```

Cada item deve conter, no mínimo:

```text
id
simulacao_id
agenda_id
empresa_id
tipo_operacao
status_operacao
confirmado
confirmado_por
confirmado_em
cancelado_por
cancelado_em
motivo_cancelamento
visivel_cliente
checksum_operacao
created_at
updated_at
resumo financeiro persistido
```

---

## 8. Payload esperado — detalhe

Formato sugerido:

```json
{
  "ok": true,
  "fase": "5D_LEITURA_OPERACAO_FINANCEIRA_ADMIN",
  "visao": "administrativa",
  "cliente_safe": false,
  "readonly": true,
  "operacao": {}
}
```

A operação deve conter:

```text
identificação e vínculos
status/auditoria 5C
campos financeiros persistidos pela 5B
resultado/cálculo persistido
metadata técnica controlada
checksum_operacao
```

---

## 9. Testes previstos

### Preflight 13 — read-only

Validar base para 5D:

```text
tabela de operações existe
colunas 5B/5C existem
RPCs 5D ainda ausentes antes da migration
RLS ativo
grants atuais seguros
status suportados
```

### 13A — listagem positiva

```text
criar fixture transacional
registrar agenda 4B
registrar operações 5B
confirmar/cancelar algumas operações 5C
listar via 5D
validar retorno administrativo
validar total/filtros básicos
rollback
```

### 13B — detalhe positivo

```text
obter uma operação específica
validar status/auditoria/cálculo/checksum
validar readonly
rollback
```

### 13C — segurança/negativos

```text
anon sem execute
sem auth.uid() bloqueado
simulação inexistente bloqueada
operação inexistente bloqueada
payload autoritativo bloqueado
p_filtros não objeto bloqueado
order_by inválido bloqueado
limit abusivo limitado ou bloqueado
cross-tenant bloqueado
```

### 13D — zero DML/read-only rígido

```text
comparar snapshots antes/depois
operações não mudam
agenda não muda
parcelas não mudam
updated_at não muda
hashes preservados
```

### 13E — filtros/paginação/ordenção

```text
filtrar por status_operacao
filtrar por tipo_operacao
filtrar por agenda_id
validar limit/offset
validar order_by allowlist
validar order_dir allowlist
```

---

## 10. Critérios de aceite

A 5D só pode ser considerada fechada quando:

```text
migration criada
RPCs criadas
anon/public sem execute
authenticated com execute
read-only comprovado
cross-tenant bloqueado
payload autoritativo bloqueado
filtros seguros validados
listagem validada
detalhe validado
zero DML validado
agenda/parcelas preservadas
documentação de todos os testes criada
smoke pós-merge definido
```

---

## 11. Decisão inicial

A 5D será uma fase de **consulta administrativa**, não de publicação ao cliente.

A exposição cliente-safe deve ser fase posterior, com contrato separado.

---

## 12. Veredito de abertura

```text
FASE 5D = ABERTA PARA CONTRATO E PREFLIGHT
```
