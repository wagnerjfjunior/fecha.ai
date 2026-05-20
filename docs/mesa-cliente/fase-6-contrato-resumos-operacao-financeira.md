# FECH.AI / MesaCliente — Fase 6

## Contrato preliminar — resumos administrativos e visão cliente-safe de operação financeira

**Status:** contrato aberto — sem migration ainda  
**Branch:** `feature/mesa-cliente-pos-5d-alinhamento-proxima-fase`  
**Base:** `main` pós-merge da Fase 5D  
**Protocolo obrigatório:** `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`

---

## 1. Objetivo

A Fase 6 deve criar a camada de consumo seguro da trilha financeira já validada.

A fase deve consolidar informações de agenda financeira, operação financeira registrada, status administrativo e resumo comercial, separando claramente:

```text
visão administrativa
visão cliente-safe
```

A Fase 6 é a ponte técnica entre as RPCs financeiras já validadas e a futura integração BFF/front para uso no MesaCliente.

---

## 2. Dependências obrigatórias já concluídas

A Fase 6 só pode iniciar porque as fases abaixo já foram validadas/documentadas:

| Fase | Status | Função na cadeia |
|---|---:|---|
| 4A | Aprovada | Gera agenda financeira JSON-first sem persistência |
| 4B | Aprovada | Persiste agenda e parcelas |
| 4C | Aprovada | Lê agenda em visão cliente-safe |
| 5A.1 | Aprovada | Simula impacto financeiro administrativo |
| 5B | Aprovada | Registra operação financeira simulada |
| 5C | Fechada tecnicamente | Confirma/cancela operação financeira |
| 5D | Fechada tecnicamente e mergeada | Lista/obtém operação financeira em visão administrativa read-only |

---

## 3. Escopo da Fase 6

A Fase 6 deve definir e validar payloads consolidados para uso operacional.

### 3.1 Visão administrativa

A visão administrativa pode conter dados necessários para gestão, auditoria e decisão interna, desde que o usuário autenticado tenha perfil permitido.

Pode incluir, conforme contrato final:

```text
operação_id
simulacao_id
agenda_id
empresa_id quando necessário para auditoria interna
status_operacao
confirmado
confirmado_por
confirmado_em
cancelado_por
cancelado_em
motivo_cancelamento
tipo_operacao
parcela_origem/destino
valor_operacao
resultado financeiro administrativo
impacto financeiro
metadados administrativos sanitizados
auditoria resumida
flags de integridade
```

### 3.2 Visão cliente-safe

A visão cliente-safe deve ser limpa e comercial. Ela deve permitir conversa em mesa com cliente, sem expor regra interna.

Pode incluir, conforme contrato final:

```text
status comercial da condição
resumo da condição aprovada/simulada
valor original da parcela quando aplicável
novo valor/data quando aplicável
descrição comercial da alteração
parcelas impactadas em linguagem simples
totais comerciais seguros
avisos neutros sem regra interna
mensagem de orientação para atendimento
```

Não pode incluir:

```text
VPL
prêmio
comissão
política financeira interna
faixa de prêmio
taxa interna sensível
impacto administrativo bruto
metadata bruta
payload bruto
checksum
score interno
motivo técnico sensível
IDs internos desnecessários para cliente
empresa_id/tenant_id como dado exibido ao cliente
```

---

## 4. Fora do escopo

A Fase 6 não pode:

```text
alterar parser
alterar motor financeiro das fases anteriores
alterar Worker/Cloudflare
alterar Make/n8n
alterar frontend
criar cálculo soberano no frontend
registrar nova operação financeira
confirmar/cancelar operação financeira
alterar agenda financeira
alterar parcelas
recalcular operação já registrada
liberar operação automaticamente para cliente sem contrato de visibilidade
expor dados administrativos na visão cliente-safe
aceitar empresa_id/tenant_id/corretor_id vindos do frontend como autoridade soberana
```

---

## 5. Matriz inicial de DML

| Ação | Permitido na Fase 6? | Observação |
|---|---:|---|
| `SELECT` em agenda/operação/parcela via RPC | Sim | Conforme auth, tenant e perfil |
| `INSERT` em operação financeira | Não | Pertence à 5B |
| `UPDATE` de status de operação | Não | Pertence à 5C |
| `UPDATE` de agenda/parcela | Não | Proibido nesta fase |
| `DELETE` financeiro | Não | Proibido |
| Escrita de log/auditoria de leitura | A definir | Só se contrato/preflight liberarem |
| Publicação controlada cliente-safe | A definir | Exige contrato próprio de visibilidade |

Padrão inicial recomendado: **Fase 6 read-only**.

---

## 6. Perfis e autorização

A Fase 6 deve manter a soberania do banco/RPC.

Obrigatório:

```text
auth.uid() obrigatório
usuário/corretor ativo obrigatório
perfil administrativo para visão administrativa
escopo por tenant/empresa validado no banco
admin_global com escopo global
admin_local/gestor/coordenador limitado por empresa
corretor comum apenas se contrato final permitir e com escopo estrito
anon bloqueado
payload autoritativo vindo do frontend bloqueado
```

---

## 7. RPCs candidatas

Nenhuma RPC está aprovada ainda. Os nomes abaixo são candidatos para discussão após o preflight.

```sql
public.mesa_cliente_resumir_operacao_financeira_admin(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb;
```

```sql
public.mesa_cliente_obter_resumo_operacao_cliente_safe(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb;
```

Alternativa possível:

```sql
public.mesa_cliente_obter_resumos_operacao_financeira(
  p_operacao_id uuid,
  p_visao text,
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb;
```

Decisão pendente: separar RPC administrativa e cliente-safe, ou uma RPC única com allowlist rígida de visão.

Recomendação preliminar: **separar RPCs** para reduzir risco de vazamento cliente-safe.

---

## 8. Contrato mínimo esperado de retorno

### 8.1 Campos comuns seguros

```json
{
  "fase": "6_RESUMOS_OPERACAO_FINANCEIRA",
  "visao": "administrativa|cliente_safe",
  "cliente_safe": true,
  "readonly": true,
  "dml_financeiro": false,
  "altera_agenda": false,
  "altera_parcelas": false,
  "altera_operacao": false,
  "recalcula_operacao": false
}
```

### 8.2 Visão administrativa

Deve retornar dados suficientes para auditoria e gestão, mas somente para perfis autorizados.

### 8.3 Visão cliente-safe

Deve retornar dados comerciais limpos, sem campos internos e sem capacidade de engenharia reversa de política financeira.

---

## 9. Preflight obrigatório

Antes de qualquer migration, criar e executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql
```

O preflight deve validar, no mínimo:

```text
existência das tabelas envolvidas
schema real de agenda, parcelas e operações
colunas de status/auditoria da 5C
RPCs 4C/5D existentes
policies/RLS relevantes
grants relevantes
dados sensíveis que não podem aparecer em cliente-safe
possibilidade de operação real acessível
regras de perfil existentes
risco de cross-tenant
risco de payload autoritativo
se a fase pode ser read-only ou exigirá tabela auxiliar
```

---

## 10. Testes previstos após contrato/preflight

A numeração prevista inicia em 14.

```text
14_preflight_resumos_operacao_financeira_readonly.sql
14a_validacao_resumo_operacao_admin_rollback.sql
14b_validacao_resumo_operacao_cliente_safe_rollback.sql
14c_validacao_negativos_seguranca_resumos_operacao_rollback.sql
14d_validacao_sem_vazamento_cliente_safe_rollback.sql
14e_validacao_zero_dml_readonly_resumos_operacao_rollback.sql
```

A lista pode ser ajustada depois do preflight, mas não pode reduzir cobertura de segurança.

---

## 11. Critérios de aprovação da Fase 6

A Fase 6 só pode ser considerada aprovada se:

```text
contrato fechado
preflight 14 aprovado
migration criada somente após preflight
RPCs com auth.uid()
anon bloqueado
tenant/empresa/perfil validados no banco
visão administrativa validada
visão cliente-safe validada
cliente-safe sem vazamento de campos internos
zero DML validado se a fase permanecer read-only
cross-tenant bloqueado
payload autoritativo bloqueado
rollback em todos os testes transacionais
README e roadmap atualizados
```

---

## 12. Próxima ação imediata

Criar o preflight read-only 14:

```text
supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql
```

Depois, executar no Supabase SQL Editor e validar o resultset completo antes de criar qualquer migration da Fase 6.

---

## 13. Frase de controle

```text
Fase 6 aberta por contrato. Nenhuma migration, RPC ou frontend deve ser criado antes do preflight 14 read-only e da validação do resultset completo.
```
