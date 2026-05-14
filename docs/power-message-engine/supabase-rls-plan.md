# FECH.AI — PME Supabase RLS Plan

Status: **DRAFT / NÃO APLICADO**

Este documento define o plano de segurança da PME antes de qualquer migration real no Supabase.

A PME não pode virar um vazamento multi-tenant gourmet. Se mensagem, script ou histórico de uma empresa aparecer para outra, acabou a brincadeira.

---

## 1. Premissas

A PME deve respeitar o modelo SaaS multi-tenant do FECH.AI.

Tabelas planejadas:

- `pme_message_templates`
- `pme_call_scripts`
- `pme_cadences`
- `pme_cadence_steps`
- `pme_lead_message_state`
- `pme_message_usage`

Todas devem ter:

- `tenant_id uuid not null`
- RLS habilitado
- bloqueio absoluto entre tenants
- acesso administrativo controlado
- histórico de uso auditável

---

## 2. Perfis de acesso

### 2.1 Root / admin global

Pode:

- auditar todos os tenants;
- visualizar templates, scripts, cadências e histórico;
- apoiar troubleshooting;
- eventualmente provisionar seeds globais.

Não deve:

- ser confundido com corretor operacional;
- ser usado como atalho para burlar tenant isolation.

---

### 2.2 Admin/Gestor do tenant

Pode, dentro do próprio tenant:

- visualizar PME;
- criar templates;
- editar templates;
- inativar templates;
- criar scripts;
- editar scripts;
- criar cadências;
- visualizar histórico;
- configurar governança.

Não pode:

- acessar templates de outro tenant;
- editar histórico de uso;
- remover rastreabilidade operacional.

---

### 2.3 Corretor

Na fase futura, poderá:

- consumir templates ativos;
- receber sugestão da próxima mensagem;
- copiar mensagem;
- registrar uso manual;
- usar script de ligação;
- registrar feedback.

Não deve:

- criar/editar templates;
- alterar cadências;
- acessar histórico amplo de outros corretores, salvo regra explícita do tenant;
- ver dados de outro tenant.

---

## 3. Função central de autorização proposta

Criar uma função única, após auditoria do schema real:

```sql
public.pme_can_access_tenant(p_tenant_id uuid) returns boolean
```

Responsabilidades:

1. Verificar `auth.uid()`.
2. Permitir root/admin global, usando a função real já validada no FECH.AI, como `public.is_root()` se aplicável.
3. Verificar vínculo do usuário ao tenant atual.
4. Bloquear usuário inativo.
5. Retornar `false` em caso de dúvida.

Pseudo-regra:

```sql
return
  public.is_root()
  or exists vínculo ativo em admins/corretores/gestores para p_tenant_id;
```

Importante: **não implementar com chute**. Validar nomes reais das tabelas e colunas.

---

## 4. Funções auxiliares recomendadas

### 4.1 `pme_is_tenant_admin(p_tenant_id uuid)`

Retorna `true` para root, admin ou gestor do tenant.

Uso:

- INSERT/UPDATE/DELETE em templates;
- INSERT/UPDATE/DELETE em scripts;
- INSERT/UPDATE/DELETE em cadências.

---

### 4.2 `pme_can_consume_tenant(p_tenant_id uuid)`

Retorna `true` para root, admin, gestor ou corretor ativo do tenant.

Uso:

- SELECT de templates ativos;
- SELECT de scripts ativos;
- INSERT em histórico de uso;
- leitura/atualização do estado da cadência do próprio lead, conforme regra.

---

## 5. Policies por tabela

### 5.1 `pme_message_templates`

SELECT:

- admin/gestor/root: todos os templates do tenant;
- corretor: templates ativos do tenant.

INSERT/UPDATE:

- somente admin/gestor/root.

DELETE:

- evitar delete físico;
- preferir `is_active = false`.

---

### 5.2 `pme_call_scripts`

SELECT:

- admin/gestor/root: todos os scripts do tenant;
- corretor: scripts ativos do tenant.

INSERT/UPDATE:

- somente admin/gestor/root.

DELETE:

- evitar delete físico.

---

### 5.3 `pme_cadences` e `pme_cadence_steps`

SELECT:

- admin/gestor/root: todas as cadências do tenant;
- corretor: cadências ativas do tenant.

INSERT/UPDATE:

- somente admin/gestor/root.

DELETE:

- evitar delete físico.

---

### 5.4 `pme_lead_message_state`

SELECT:

- admin/gestor/root: estados dos leads do tenant;
- corretor: apenas leads sob sua responsabilidade, se essa relação existir no schema real.

INSERT/UPDATE:

- admin/gestor/root: permitido;
- corretor: permitido apenas para leads atribuídos a ele.

DELETE:

- não recomendado.

---

### 5.5 `pme_message_usage`

SELECT:

- admin/gestor/root: histórico do tenant;
- corretor: histórico dos próprios leads ou dos próprios usos.

INSERT:

- corretor/admin/gestor/root dentro do tenant.

UPDATE/DELETE:

- não recomendado.
- se necessário, apenas admin/root e com log.

---

## 6. Regras anti-spam e governança

A RLS não resolve tudo. A aplicação também deve aplicar guardrails:

- opt-out bloqueia sugestão futura;
- número errado encerra cadência;
- lead já atendido para cadência;
- template inativo nunca é sugerido;
- mensagem final encerra cadência, salvo reativação manual;
- listas frias devem operar em modo assistido;
- automação real de WhatsApp fica bloqueada até integração oficial segura.

---

## 7. Ordem recomendada para implementação real

1. Auditar schema real do Supabase.
2. Identificar tabela/coluna real de tenant.
3. Identificar vínculo real usuário → tenant → papel.
4. Criar função `pme_can_access_tenant`.
5. Criar função `pme_is_tenant_admin`.
6. Criar tabelas PME em ambiente controlado.
7. Aplicar RLS.
8. Rodar testes positivos e negativos.
9. Importar seeds.
10. Conectar tela admin à persistência.
11. Só depois pensar em consumo pelo discador/acelerador.

---

## 8. Testes obrigatórios antes de produção

### Testes positivos

- root vê PME de todos os tenants;
- admin vê PME do próprio tenant;
- corretor consome templates ativos do próprio tenant;
- histórico registra uso com tenant correto.

### Testes negativos

- corretor não edita template;
- tenant A não vê tenant B;
- usuário inativo não acessa PME;
- template inativo não aparece para consumo;
- opt-out impede próxima ação;
- histórico não pode ser apagado por corretor.

---

## 9. Critério de aprovação

A PME só deve sair de seed frontend para persistência Supabase quando:

- a função de tenant access estiver validada;
- as policies estiverem testadas;
- o admin/root continuar funcionando;
- nenhum fluxo central do FECH.AI for impactado;
- o discador permanecer intacto até decisão explícita de integração.
