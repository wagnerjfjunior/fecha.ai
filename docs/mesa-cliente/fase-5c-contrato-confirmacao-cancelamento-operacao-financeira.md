# FECH.AI / MesaCliente — Fase 5C — Contrato de confirmação/cancelamento de operação financeira

**Status:** contrato aberto para validação antes de qualquer migration  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5C — confirmar/cancelar operação financeira administrativa  
**Pré-requisito:** Fase 5B aprovada em validação transacional  
**Documento anterior:** `docs/mesa-cliente/fase-5b-fechamento-registro-operacao-financeira.md`  
**Data:** 2026-05-19

---

## 1. Veredito inicial

A Fase 5B está aprovada e a Fase 5C pode ser aberta em contrato.

A 5C **não deve começar por SQL**. Ela deve começar por contrato porque muda o estado de uma operação financeira já registrada.

Sequência oficial:

```text
5A.1 = simular impacto, sem persistência
5B   = registrar operação financeira simulada
5C   = confirmar ou cancelar operação financeira
5D+  = aplicar efeitos definitivos/cliente-safe, se aprovado em contrato próprio
```

---

## 2. Objetivo da Fase 5C

A Fase 5C deve permitir que um usuário administrativo autorizado faça transição de estado de uma operação financeira registrada pela 5B.

Estados principais:

```text
simulada   -> confirmada
simulada   -> cancelada
confirmada -> cancelada, somente se regra de negócio aprovar
cancelada  -> estado final, sem reativação nesta fase
bloqueada  -> fora do fluxo normal da 5C, salvo contrato específico
```

A 5C não recalcula a operação. Ela decide o estado de uma operação já registrada e protegida.

---

## 3. Escopo funcional

A 5C deve criar RPC administrativa para:

```text
confirmar operação financeira simulada
cancelar operação financeira simulada
registrar usuário responsável pela transição
registrar data/hora da transição
registrar motivo administrativo quando cancelar
preservar cálculo original da operação
preservar checksum_operacao original
bloquear alteração de agenda e parcelas
bloquear autoridade financeira vinda do frontend
```

---

## 4. Não escopo da 5C

A 5C não deve:

```text
alterar frontend
alterar parser
alterar Worker
alterar Make/n8n
recalcular agenda financeira
recriar parcelas
alterar valor de parcelas
alterar datas de parcelas
alterar totais/checksum da agenda
alterar valor_movido da operação
alterar desconto/acréscimo/economia da operação
aceitar taxa do frontend
aceitar empresa_id soberano do frontend
aceitar status arbitrário do frontend
expor operação ao cliente automaticamente
aplicar efeito definitivo no fluxo financeiro final
criar nova operação financeira
confirmar operação inexistente
confirmar operação de outro tenant
reativar operação cancelada
```

Se futuramente for necessário aplicar a operação no fluxo final da mesa, isso deve entrar em fase própria.

---

## 5. Princípio central

A 5C deve ser uma transição de estado, não uma reengenharia de cálculo.

```text
5B criou a operação.
5C decide o estado da operação.
5C não muda a matemática da operação.
```

A operação confirmada deve virar uma âncora de integridade. Depois da confirmação, qualquer tentativa de criar operação conflitante já é bloqueada pela 5B, como validado no 11D.

---

## 6. Fonte soberana de dados

A RPC da 5C deve buscar autoridade no banco:

```text
auth.uid()
corretores
mesa_simulacoes
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_fluxo_operacoes
```

O frontend pode enviar intenção de ação, mas não pode definir autoridade financeira, tenant, status final arbitrário, data de confirmação ou usuário confirmador.

---

## 7. RPC candidata

Nome proposto:

```sql
public.mesa_cliente_atualizar_status_operacao_financeira_admin(
  p_operacao_id uuid,
  p_acao text,
  p_motivo text default null,
  p_parametros jsonb default '{}'::jsonb
)
```

Ações permitidas na primeira versão:

```text
confirmar
cancelar
```

Racional:

```text
p_operacao_id identifica a operação soberana criada na 5B.
p_acao evita múltiplas RPCs com lógica duplicada.
p_motivo é obrigatório para cancelamento e opcional para confirmação.
p_parametros aceita apenas metadata administrativa não soberana.
```

Alternativa futura, se o contrato preferir separar responsabilidades:

```sql
public.mesa_cliente_confirmar_operacao_financeira_admin(p_operacao_id uuid, p_parametros jsonb default '{}'::jsonb)
public.mesa_cliente_cancelar_operacao_financeira_admin(p_operacao_id uuid, p_motivo text, p_parametros jsonb default '{}'::jsonb)
```

Decisão recomendada neste momento:

```text
Usar uma RPC única com p_acao, desde que a validação de ação seja estrita.
```

---

## 8. Contrato de retorno esperado

Retorno JSONB esperado:

```json
{
  "ok": true,
  "fase": "5C_CONFIRMACAO_CANCELAMENTO_OPERACAO_FINANCEIRA",
  "visao": "administrativa",
  "cliente_safe": false,
  "persistencia": true,
  "dml_financeiro": true,
  "escopo_dml": "status_operacao_financeira",
  "altera_agenda": false,
  "altera_parcelas": false,
  "recalcula_operacao": false,
  "operacao": {
    "id": "uuid",
    "empresa_id": "uuid",
    "simulacao_id": "uuid",
    "agenda_id": "uuid",
    "parcela_origem_id": "uuid",
    "tipo_operacao": "antecipacao|postergacao|vpl",
    "status_operacao_anterior": "simulada",
    "status_operacao": "confirmada|cancelada",
    "confirmado": true,
    "confirmado_por": "uuid|null",
    "confirmado_em": "timestamp|null",
    "cancelado_por": "uuid|null",
    "cancelado_em": "timestamp|null",
    "motivo_cancelamento": "text|null",
    "visivel_cliente": false,
    "checksum_operacao": "text"
  }
}
```

Observação:

```text
Se a tabela ainda não possuir cancelado_por/cancelado_em/motivo_cancelamento, o preflight 12 deve apontar isso antes da migration.
```

---

## 9. Regras de confirmação

Para confirmar, a RPC deve validar:

```text
usuário autenticado obrigatório
auth.uid() pertence ao tenant da operação
usuário tem perfil administrativo autorizado
operação existe
operação pertence a uma simulação existente
operação possui agenda_id válido
agenda existe e pertence à mesma simulação/empresa
parcela_origem_id existe na agenda, quando aplicável
status_operacao atual = simulada
confirmado atual = false
visivel_cliente continua false nesta fase
checksum_operacao existe
não existe outra operação confirmada conflitante para a mesma simulação/parcela
```

Ao confirmar, deve atualizar somente a operação:

```text
status_operacao = confirmada
confirmado = true
confirmado_por = auth.uid()
confirmado_em = now()
updated_at = now()
metadata = metadata || dados administrativos não soberanos
```

Não deve alterar:

```text
agenda
parcelas
valor_movido
valor_base
desconto_calculado
acrescimo_calculado
economia_liquida
checksum_operacao
empresa_id
simulacao_id
agenda_id
parcela_origem_id
```

---

## 10. Regras de cancelamento

Para cancelar, a RPC deve validar:

```text
usuário autenticado obrigatório
auth.uid() pertence ao tenant da operação
usuário tem perfil administrativo autorizado
operação existe
operação pertence ao tenant do usuário
p_motivo é obrigatório e não vazio
status_operacao atual em conjunto permitido
```

Conjunto permitido inicial:

```text
simulada -> cancelada
```

Decisão pendente:

```text
confirmada -> cancelada
```

Recomendação inicial:

```text
Bloquear cancelamento de confirmada na primeira versão da 5C, salvo se houver regra explícita de estorno/auditoria.
```

Ao cancelar operação simulada, deve atualizar somente a operação:

```text
status_operacao = cancelada
confirmado = false
visivel_cliente = false
updated_at = now()
metadata = metadata || motivo e responsável administrativo
```

Se a migration criar campos próprios:

```text
cancelado_por = auth.uid()
cancelado_em = now()
motivo_cancelamento = p_motivo
```

---

## 11. Autoridade proibida no payload

A RPC deve bloquear em `p_parametros` qualquer tentativa de enviar como autoridade:

```text
empresa_id
simulacao_id
agenda_id
parcela_id
parcela_origem_id
parcela_destino_id
corretor_id
politica_id
valor_movido
valor_base
desconto_calculado
acrescimo_calculado
economia_liquida
taxa_ano_pct
taxa_antecipacao_ano_pct
taxa_postergacao_ano_pct
status_operacao
confirmado
confirmado_por
confirmado_em
cancelado_por
cancelado_em
motivo_cancelamento
visivel_cliente
checksum_operacao
idempotency_key
created_at
updated_at
```

---

## 12. Segurança e permissões

A RPC 5C deve ser:

```sql
SECURITY DEFINER
SET search_path = public, pg_temp
```

Grants esperados:

```sql
revoke all on function public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb) from public;
revoke all on function public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb) from anon;
grant execute on function public.mesa_cliente_atualizar_status_operacao_financeira_admin(uuid,text,text,jsonb) to authenticated;
```

DML direto nas tabelas financeiras deve continuar bloqueado para `authenticated` por RLS/policies.

---

## 13. Regras de bloqueio/erro esperadas

Erros esperados:

```text
sem auth -> 28000
ação inválida -> 22023
p_parametros não objeto -> 22023
p_motivo ausente em cancelamento -> 22023
operação inexistente -> P0002
operação de outro tenant -> P0002 ou 42501, conforme padrão adotado
status atual inválido para confirmação -> 55000
status atual inválido para cancelamento -> 55000
payload com autoridade proibida -> 42501
operação confirmada conflitante -> 55000
```

---

## 14. Idempotência esperada

A 5C deve tratar idempotência por estado.

### Confirmar operação já confirmada

Decisão recomendada:

```text
retornar ok=true, idempotente=true, sem alterar novamente confirmado_em
```

Motivo:

```text
Evita duplicidade operacional e preserva data original de confirmação.
```

### Cancelar operação já cancelada

Decisão recomendada:

```text
retornar ok=true, idempotente=true, sem alterar novamente cancelado_em/motivo original
```

### Confirmar operação cancelada

Decisão recomendada:

```text
bloquear com SQLSTATE 55000
```

---

## 15. Auditoria mínima

A 5C deve preservar rastreabilidade.

Campos já existentes que podem ser usados:

```text
confirmado
confirmado_por
confirmado_em
metadata
updated_at
```

Campos possivelmente necessários para cancelamento:

```text
cancelado_por
cancelado_em
motivo_cancelamento
```

Decisão pendente do preflight 12:

```text
Verificar se esses campos existem antes de propor migration.
```

Se não existirem, a migration 5C pode adicionar esses campos, ou registrar cancelamento em `metadata`. Recomendação técnica: adicionar campos explícitos para cancelamento se o produto for usar isso em auditoria/relatórios.

---

## 16. Contrato de zero mutação

A 5C deve alterar apenas a linha de `public.mesa_cliente_fluxo_operacoes` referente à operação.

Deve permanecer inalterado:

```text
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_simulacoes, salvo eventual updated_at se houver trigger externa inevitável, que deve ser apontada no teste
mesa_cliente_politicas_financeiras
mesa_cliente_politica_premio_faixas
```

Teste obrigatório deve comparar:

```text
agenda_full_hash before/after
parcelas_full_hash before/after
agenda.checksum before/after
agenda.totais before/after
valor_total_parcelas before/after
qtd_parcelas before/after
```

---

## 17. Preflight obrigatório antes da migration

Criar antes de qualquer SQL de migration:

```text
supabase/tests/mesa-cliente/engenharia-financeira/12_preflight_confirmacao_cancelamento_operacao_financeira_readonly.sql
```

O preflight 12 deve ser read-only e validar:

```text
schema real de mesa_cliente_fluxo_operacoes
colunas de confirmação existentes
colunas de cancelamento existentes ou ausentes
enums/status permitidos
constraints relevantes
índices de conflito/idempotência
RLS e policies
grants atuais
existência da RPC 5B
ausência esperada da RPC 5C antes da migration
se há triggers que alterem updated_at
se operação confirmada/cancelada já possui suporte estrutural suficiente
```

---

## 18. Testes transacionais previstos

Após preflight e migration, criar testes:

```text
12a_validacao_confirmar_operacao_financeira_rollback.sql
12b_validacao_cancelar_operacao_financeira_rollback.sql
12c_validacao_confirmacao_cancelamento_negativos_rollback.sql
12d_validacao_idempotencia_confirmacao_cancelamento_rollback.sql
12e_validacao_zero_mutacao_agenda_parcelas_confirmacao_cancelamento_rollback.sql
```

### 12A — confirmação positiva

Valida:

```text
operação simulada criada via 5B
confirmação via 5C
status_operacao=confirmada
confirmado=true
confirmado_por=auth.uid()
confirmado_em preenchido
visivel_cliente=false
sem alterar agenda/parcelas
rollback
```

### 12B — cancelamento positivo

Valida:

```text
operação simulada criada via 5B
cancelamento via 5C
status_operacao=cancelada
confirmado=false
motivo registrado
visivel_cliente=false
sem alterar agenda/parcelas
rollback
```

### 12C — negativos e segurança

Valida:

```text
anon bloqueado
sem auth bloqueado
operação inexistente
tenant/cross-tenant bloqueado
ação inválida
p_parametros não objeto
payload com autoridade proibida
cancelar sem motivo
confirmar cancelada bloqueado
cancelar confirmada bloqueado, se essa for a decisão contratual
zero mutação em tentativas negativas
rollback
```

### 12D — idempotência

Valida:

```text
confirmar duas vezes não altera confirmado_em da primeira confirmação
cancelar duas vezes não altera dados originais de cancelamento
confirmar cancelada bloqueia
sem duplicidade/efeito colateral
rollback
```

### 12E — zero mutação rígido

Valida:

```text
somente a operação alvo muda
agenda não muda
parcelas não mudam
simulação não muda, salvo trigger documentada
hashes preservados
rollback
```

---

## 19. Critérios para fechar a 5C

A 5C só pode ser considerada aprovada quando:

```text
contrato 5C estiver fechado
preflight 12 aprovado
migration 5C executada
12A aprovado
12B aprovado
12C aprovado
12D aprovado
12E aprovado
documentação de fechamento criada
README operacional atualizado
```

---

## 20. Decisões pendentes antes da migration

Antes de criar migration, decidir explicitamente:

```text
1. Cancelamento de operação confirmada será permitido ou bloqueado?
2. Cancelamento terá colunas próprias ou apenas metadata?
3. RPC única com p_acao ou duas RPCs separadas?
4. Confirmar operação já confirmada retorna idempotente=true ou bloqueia?
5. Cancelar operação já cancelada retorna idempotente=true ou bloqueia?
6. 5C deve manter visivel_cliente=false sempre ou já preparar campo para fase cliente-safe futura?
```

Recomendação inicial:

```text
1. Bloquear cancelamento de confirmada nesta primeira versão.
2. Criar colunas próprias para cancelamento se o preflight mostrar ausência.
3. Usar RPC única com p_acao.
4. Confirmada novamente = idempotente=true.
5. Cancelada novamente = idempotente=true.
6. Manter visivel_cliente=false sempre na 5C.
```

---

## 21. Próxima ação oficial

Criar e executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/12_preflight_confirmacao_cancelamento_operacao_financeira_readonly.sql
```

Somente após o resultado completo do preflight 12 será seguro fechar a migration 5C.
