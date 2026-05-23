# DATA_MODEL — PME Usage Tracking & Script Utility v0.2.7

## 1. Princípio do modelo

O modelo deve registrar eventos de uso do PME com segurança multi-tenant, baixo acoplamento e mínima exposição de dados sensíveis.

Regra central:

> O frontend envia o evento operacional; o backend valida usuário, tenant, empresa, lead e permissão.

---

## 2. Tabela proposta

Nome sugerido:

`pme_script_usage_events`

Objetivo:

Registrar eventos de uso de scripts/mensagens do Discador Flow AI.

---

## 3. Campos propostos

| Campo | Tipo sugerido | Obrigatório | Origem | Observação |
|---|---:|---:|---|---|
| `id` | uuid | sim | banco | `gen_random_uuid()` |
| `created_at` | timestamptz | sim | banco | default `now()` |
| `tenant_id` | uuid | sim | backend | nunca confiar cegamente no frontend |
| `empresa_id` | uuid | sim | backend | resolvido/validado por usuário |
| `user_id` | uuid | sim | backend | `auth.uid()` |
| `lead_id` | uuid | não | frontend + validação | validar se lead pertence ao tenant/empresa |
| `lead_phone_hash` | text | não | frontend/backend | hash, não telefone puro |
| `module` | text | sim | frontend | ex.: `discador_flow_ai` |
| `module_version` | text | sim | frontend | ex.: `0.2.7` |
| `event_type` | text | sim | frontend validado | enum lógico |
| `context` | text | sim | frontend validado | origem do lead |
| `channel` | text | sim | frontend validado | ligação/whatsapp/email |
| `approach` | text | sim | frontend validado | situação comercial |
| `script_source` | text | sim | frontend validado | template/ai/fallback |
| `script_key` | text | não | frontend | chave futura do template |
| `script_variant` | integer | não | frontend | índice do template exibido |
| `script_text_hash` | text | não | frontend | sha256 do texto normalizado |
| `ai_attempt` | integer | não | frontend | tentativa no modal |
| `ai_tip_hash` | text | não | frontend | hash da dica, não dica completa |
| `execution_target` | text | não | frontend validado | tel/whatsapp/mailto/manual_copy |
| `client_timestamp` | timestamptz | não | frontend | para auditoria comparativa |
| `metadata` | jsonb | não | frontend filtrado | somente dados não sensíveis |

---

## 4. Enums lógicos

### 4.1 `event_type`

Valores permitidos:

- `script_viewed`
- `script_variant_changed`
- `ai_requested`
- `ai_succeeded`
- `ai_failed`
- `script_executed`
- `script_copied_fallback`

### 4.2 `context`

Valores permitidos:

- `carteira`
- `lista_fria`
- `visitou`
- `redes_sociais`
- `problemas`
- `argumentacoes`

### 4.3 `channel`

Valores permitidos:

- `ligacao`
- `whatsapp`
- `email`

### 4.4 `approach`

Valores permitidos:

- `primeira_abordagem`
- `retorno`
- `pos_ligacao`
- `convite`
- `objecao_preco`
- `objecao_entrada`
- `sem_resposta`
- `fim_contato`

### 4.5 `script_source`

Valores permitidos:

- `template`
- `ai`
- `fallback`
- `unknown`

### 4.6 `execution_target`

Valores permitidos:

- `tel`
- `whatsapp`
- `mailto`
- `manual_copy`
- `none`

---

## 5. SQL conceitual

> Atenção: SQL abaixo é proposta de design. Não aplicar em produção sem revisão de nomes reais de tabelas, tenants, empresas, leads e perfis.

```sql
create table if not exists public.pme_script_usage_events (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  tenant_id uuid not null,
  empresa_id uuid not null,
  user_id uuid not null,
  lead_id uuid null,
  lead_phone_hash text null,
  module text not null default 'discador_flow_ai',
  module_version text not null,
  event_type text not null,
  context text not null,
  channel text not null,
  approach text not null,
  script_source text not null,
  script_key text null,
  script_variant integer null,
  script_text_hash text null,
  ai_attempt integer null,
  ai_tip_hash text null,
  execution_target text null,
  client_timestamp timestamptz null,
  metadata jsonb not null default '{}'::jsonb,
  constraint pme_usage_event_type_chk check (event_type in (
    'script_viewed',
    'script_variant_changed',
    'ai_requested',
    'ai_succeeded',
    'ai_failed',
    'script_executed',
    'script_copied_fallback'
  )),
  constraint pme_usage_context_chk check (context in (
    'carteira', 'lista_fria', 'visitou', 'redes_sociais', 'problemas', 'argumentacoes'
  )),
  constraint pme_usage_channel_chk check (channel in ('ligacao', 'whatsapp', 'email')),
  constraint pme_usage_approach_chk check (approach in (
    'primeira_abordagem', 'retorno', 'pos_ligacao', 'convite',
    'objecao_preco', 'objecao_entrada', 'sem_resposta', 'fim_contato'
  )),
  constraint pme_usage_source_chk check (script_source in ('template', 'ai', 'fallback', 'unknown')),
  constraint pme_usage_execution_target_chk check (execution_target is null or execution_target in (
    'tel', 'whatsapp', 'mailto', 'manual_copy', 'none'
  ))
);
```

---

## 6. Índices propostos

```sql
create index if not exists idx_pme_usage_tenant_created
  on public.pme_script_usage_events (tenant_id, created_at desc);

create index if not exists idx_pme_usage_empresa_created
  on public.pme_script_usage_events (empresa_id, created_at desc);

create index if not exists idx_pme_usage_user_created
  on public.pme_script_usage_events (user_id, created_at desc);

create index if not exists idx_pme_usage_lead_created
  on public.pme_script_usage_events (lead_id, created_at desc)
  where lead_id is not null;

create index if not exists idx_pme_usage_context_channel_approach
  on public.pme_script_usage_events (tenant_id, context, channel, approach, created_at desc);

create index if not exists idx_pme_usage_script_hash
  on public.pme_script_usage_events (tenant_id, script_text_hash)
  where script_text_hash is not null;
```

---

## 7. RPC proposta

Nome sugerido:

`registrar_pme_script_usage`

Responsabilidade:

- validar usuário autenticado;
- resolver tenant/empresa do usuário;
- validar lead, quando enviado;
- validar enums;
- inserir evento;
- retornar `{ ok: true, id: uuid }`;
- em erro de permissão, retornar erro controlado.

Assinatura conceitual:

```sql
registrar_pme_script_usage(p_event jsonb) returns jsonb
```

---

## 8. Não persistir no MVP

Não persistir nesta etapa:

- texto completo do script;
- dica completa enviada à IA;
- telefone puro;
- e-mail puro;
- conteúdo de conversa;
- dados financeiros do cliente;
- documentos pessoais;
- qualquer dado sensível fora do mínimo necessário.

---

## 9. Futuras tabelas possíveis

Fora da v0.2.7, mas previstas:

- `pme_script_library`
- `pme_script_scores`
- `pme_ai_cache`
- `pme_script_feedback_links`
- `pme_company_ai_settings`

Essas tabelas devem ser desenhadas somente após validar o tracking de eventos.
