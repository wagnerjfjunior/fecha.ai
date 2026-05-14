# Power Message Engine — Modelo de Dados Sugerido

> Este documento é uma proposta técnica. Não aplicar migrations sem validação contra o schema real do Supabase.

## 1. Objetivo

Criar uma estrutura de dados para armazenar templates, regras de seleção, scripts, cadências e histórico de uso de mensagens dentro do FECH.AI.

---

## 2. Entidades principais

### 2.1 `message_templates`

Armazena templates de mensagens por canal, tipo de lead e fase.

Campos sugeridos:

| Campo | Tipo | Observação |
|---|---|---|
| `id` | uuid | PK |
| `tenant_id` | uuid | Escopo multi-tenant |
| `empresa_id` | uuid/null | Opcional, se existir separação por empresa |
| `empreendimento_id` | uuid/null | Opcional |
| `channel` | text | `whatsapp`, `email`, `call_script` |
| `lead_type` | text | `lead_quente`, `lista_fria`, `lista_quente`, `visitou_plantao` |
| `phase` | text | `primeira_mensagem`, `segunda_mensagem`, `terceira_mensagem`, `mensagem_final` |
| `tone` | text | `consultivo`, `direto`, `executivo`, `leve`, `reativacao` |
| `objective` | text | abertura, follow-up, visita, simulação, encerramento |
| `title` | text | Nome interno do template |
| `body` | text | Conteúdo da mensagem |
| `variables` | jsonb | Lista de variáveis usadas |
| `weight` | integer | Peso para seleção |
| `is_active` | boolean | Ativo/inativo |
| `created_by` | uuid/null | Usuário criador |
| `created_at` | timestamptz | Criação |
| `updated_at` | timestamptz | Atualização |

---

### 2.2 `message_template_usage`

Registra cada sugestão/envio de template.

Campos sugeridos:

| Campo | Tipo | Observação |
|---|---|---|
| `id` | uuid | PK |
| `tenant_id` | uuid | Escopo multi-tenant |
| `lead_id` | uuid | Lead relacionado |
| `corretor_id` | uuid/null | Corretor executor |
| `template_id` | uuid | Template usado |
| `channel` | text | Canal usado |
| `phase` | text | Fase |
| `selection_mode` | text | `automatic`, `manual`, `suggested` |
| `rendered_body` | text | Mensagem final renderizada |
| `status` | text | `suggested`, `copied`, `sent_manual`, `skipped`, `failed` |
| `feedback_id` | uuid/null | Feedback gerado após contato |
| `created_at` | timestamptz | Registro |

---

### 2.3 `message_sequences`

Define uma sequência/cadência reutilizável.

Campos sugeridos:

| Campo | Tipo | Observação |
|---|---|---|
| `id` | uuid | PK |
| `tenant_id` | uuid | Escopo multi-tenant |
| `name` | text | Ex.: Cadência lead quente Meta |
| `lead_type` | text | Tipo principal |
| `description` | text | Descrição operacional |
| `is_active` | boolean | Ativo/inativo |
| `created_at` | timestamptz | Criação |
| `updated_at` | timestamptz | Atualização |

---

### 2.4 `message_sequence_steps`

Define os passos de uma cadência.

Campos sugeridos:

| Campo | Tipo | Observação |
|---|---|---|
| `id` | uuid | PK |
| `tenant_id` | uuid | Escopo multi-tenant |
| `sequence_id` | uuid | FK |
| `step_order` | integer | Ordem |
| `channel` | text | WhatsApp, ligação, e-mail |
| `phase` | text | Fase comercial |
| `delay_hours` | integer | Espera até próximo passo |
| `requires_human_action` | boolean | Se precisa clique humano |
| `stop_on_feedbacks` | text[] | Feedbacks que encerram |
| `is_active` | boolean | Ativo/inativo |

---

### 2.5 `lead_message_state`

Estado atual da cadência de cada lead.

Campos sugeridos:

| Campo | Tipo | Observação |
|---|---|---|
| `id` | uuid | PK |
| `tenant_id` | uuid | Escopo multi-tenant |
| `lead_id` | uuid | Lead |
| `sequence_id` | uuid/null | Cadência atual |
| `current_phase` | text | Fase atual |
| `current_step_order` | integer | Passo atual |
| `status` | text | `active`, `paused`, `completed`, `stopped`, `opt_out` |
| `next_action_at` | timestamptz/null | Próxima ação sugerida |
| `last_contact_at` | timestamptz/null | Último contato |
| `updated_at` | timestamptz | Atualização |

---

## 3. Variáveis de template

Variáveis recomendadas:

```txt
{{nome_lead}}
{{nome_corretor}}
{{empresa}}
{{empreendimento}}
{{bairro}}
{{telefone_corretor}}
{{link_whatsapp}}
{{link_empreendimento}}
{{origem_lead}}
{{data_visita}}
{{proximo_passo}}
```

### Regras

- Variável sem valor não pode ser renderizada como texto quebrado.
- Sistema deve ter fallback seguro.
- Mensagem com variável crítica ausente deve bloquear envio/sugestão.

---

## 4. Seleção de template

Critérios mínimos:

```txt
tenant_id = tenant atual
is_active = true
channel = canal selecionado
lead_type = tipo do lead
phase = fase atual
empreendimento_id = empreendimento do lead OU null
```

Critérios adicionais:

- evitar template já usado no mesmo lead;
- priorizar templates menos usados recentemente;
- respeitar `weight`;
- respeitar tom escolhido;
- respeitar objetivo comercial.

---

## 5. RLS e segurança

Todas as tabelas devem ter RLS habilitado.

Regras fundamentais:

- usuário só acessa templates do próprio tenant;
- gestor/admin do tenant pode criar/editar/inativar templates;
- corretor pode usar templates ativos, mas não necessariamente editar;
- root/admin global pode auditar, conforme regra já existente no FECH.AI;
- histórico de uso não pode vazar entre tenants.

---

## 6. Observação importante

Antes de qualquer migration, validar nomes reais de tabelas existentes no projeto, principalmente:

- tenants/empresas;
- leads;
- corretores;
- admins;
- feedbacks;
- funil_movimentacoes;
- logs.

Não presumir schema. O FECH.AI já tem motor real em produção.
