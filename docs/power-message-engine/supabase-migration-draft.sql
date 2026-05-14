-- FECH.AI — Power Message Engine
-- Supabase migration draft
-- Status: DRAFT ONLY. Do not apply in production before schema audit.
-- Branch: feature/pme-admin-shell
--
-- Objetivo:
-- Criar a base persistente da PME com templates, scripts, cadências,
-- estado por lead e histórico de uso.
--
-- Regra operacional:
-- Este arquivo NÃO deve ser aplicado antes de validar o schema real do FECH.AI,
-- especialmente tabelas de tenants/empresas, leads, corretores, admins e feedbacks.

begin;

-- =========================================================
-- 0. Extensões
-- =========================================================

create extension if not exists pgcrypto;

-- =========================================================
-- 1. Tipos e domínios via CHECK constraints
-- =========================================================
-- Escolha proposital: não criar ENUM nesta primeira versão.
-- Motivo: lead_type, phase e status devem evoluir sem migrations pesadas.

-- =========================================================
-- 2. Templates de mensagem
-- =========================================================

create table if not exists public.pme_message_templates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  empresa_id uuid null,
  empreendimento_id uuid null,

  channel text not null check (channel in ('whatsapp', 'email', 'call_note')),
  lead_type text not null check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  phase text not null check (phase in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final')),
  tone text not null check (tone in ('consultivo', 'direto', 'executivo', 'leve', 'reativacao', 'urgencia_elegante')),

  title text not null,
  objective text null,
  body text not null,
  variables jsonb not null default '[]'::jsonb,

  weight integer not null default 1 check (weight >= 0 and weight <= 100),
  is_active boolean not null default true,
  is_seed boolean not null default false,
  seed_key text null,

  created_by uuid null,
  updated_by uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pme_message_templates_seed_key_unique unique (tenant_id, seed_key),
  constraint pme_message_templates_body_not_blank check (length(trim(body)) > 0),
  constraint pme_message_templates_title_not_blank check (length(trim(title)) > 0)
);

comment on table public.pme_message_templates is 'PME: templates de mensagens por tenant, canal, tipo de lead e fase.';
comment on column public.pme_message_templates.tenant_id is 'Escopo multi-tenant. Validar FK real antes de aplicar em produção.';
comment on column public.pme_message_templates.seed_key is 'Chave estável para importar seeds versionados do frontend sem duplicar registros.';

create index if not exists idx_pme_message_templates_lookup
  on public.pme_message_templates (tenant_id, channel, lead_type, phase, is_active);

create index if not exists idx_pme_message_templates_empresa
  on public.pme_message_templates (tenant_id, empresa_id);

create index if not exists idx_pme_message_templates_empreendimento
  on public.pme_message_templates (tenant_id, empreendimento_id);

-- =========================================================
-- 3. Scripts de ligação
-- =========================================================

create table if not exists public.pme_call_scripts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  empresa_id uuid null,
  empreendimento_id uuid null,

  lead_type text not null check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  title text not null,
  objective text null,

  opening text not null,
  context text not null,
  first_question text not null,
  qualification jsonb not null default '[]'::jsonb,
  commercial_hook text null,
  objections jsonb not null default '[]'::jsonb,
  closing text not null,
  feedback_options text[] not null default array[]::text[],

  is_active boolean not null default true,
  is_seed boolean not null default false,
  seed_key text null,

  created_by uuid null,
  updated_by uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pme_call_scripts_seed_key_unique unique (tenant_id, seed_key),
  constraint pme_call_scripts_title_not_blank check (length(trim(title)) > 0),
  constraint pme_call_scripts_opening_not_blank check (length(trim(opening)) > 0)
);

comment on table public.pme_call_scripts is 'PME: roteiros de ligação por tenant e tipo de lead.';

create index if not exists idx_pme_call_scripts_lookup
  on public.pme_call_scripts (tenant_id, lead_type, is_active);

-- =========================================================
-- 4. Cadências
-- =========================================================

create table if not exists public.pme_cadences (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  empresa_id uuid null,
  empreendimento_id uuid null,

  lead_type text not null check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  title text not null,
  objective text null,
  risk_level text not null default 'medio' check (risk_level in ('baixo', 'medio', 'alto')),
  recommended_mode text not null default 'assistido' check (recommended_mode in ('assistido', 'automatico_bloqueado', 'automatico_futuro')),

  guardrails jsonb not null default '[]'::jsonb,
  stop_on_feedbacks text[] not null default array[]::text[],
  pause_on_feedbacks text[] not null default array[]::text[],

  is_active boolean not null default true,
  is_seed boolean not null default false,
  seed_key text null,

  created_by uuid null,
  updated_by uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pme_cadences_seed_key_unique unique (tenant_id, seed_key),
  constraint pme_cadences_title_not_blank check (length(trim(title)) > 0)
);

comment on table public.pme_cadences is 'PME: cadências comerciais assistidas por tipo de lead.';

create index if not exists idx_pme_cadences_lookup
  on public.pme_cadences (tenant_id, lead_type, is_active);

-- =========================================================
-- 5. Passos das cadências
-- =========================================================

create table if not exists public.pme_cadence_steps (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  cadence_id uuid not null references public.pme_cadences(id) on delete cascade,

  step_order integer not null check (step_order > 0),
  step_when text not null,
  channel text not null check (channel in ('whatsapp', 'call', 'email')),
  phase text not null check (phase in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final')),

  title text not null,
  instruction text not null,
  expected_result text null,
  requires_human_action boolean not null default true,

  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pme_cadence_steps_unique_order unique (cadence_id, step_order),
  constraint pme_cadence_steps_title_not_blank check (length(trim(title)) > 0)
);

comment on table public.pme_cadence_steps is 'PME: passos ordenados de cada cadência.';

create index if not exists idx_pme_cadence_steps_lookup
  on public.pme_cadence_steps (tenant_id, cadence_id, step_order, is_active);

-- =========================================================
-- 6. Estado da cadência por lead
-- =========================================================

create table if not exists public.pme_lead_message_state (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  lead_id uuid not null,
  corretor_id uuid null,
  cadence_id uuid null references public.pme_cadences(id) on delete set null,

  lead_type text not null check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  current_phase text null check (current_phase is null or current_phase in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final')),
  current_step_order integer null check (current_step_order is null or current_step_order > 0),

  status text not null default 'active' check (status in ('active', 'paused', 'completed', 'stopped', 'opt_out')),
  next_action_at timestamptz null,
  last_contact_at timestamptz null,
  last_feedback text null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pme_lead_message_state_unique_lead unique (tenant_id, lead_id)
);

comment on table public.pme_lead_message_state is 'PME: estado atual da régua/cadência de mensagens por lead.';

create index if not exists idx_pme_lead_message_state_next_action
  on public.pme_lead_message_state (tenant_id, status, next_action_at);

create index if not exists idx_pme_lead_message_state_corretor
  on public.pme_lead_message_state (tenant_id, corretor_id, status);

-- =========================================================
-- 7. Histórico de uso da PME
-- =========================================================

create table if not exists public.pme_message_usage (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  lead_id uuid not null,
  corretor_id uuid null,

  template_id uuid null references public.pme_message_templates(id) on delete set null,
  call_script_id uuid null references public.pme_call_scripts(id) on delete set null,
  cadence_id uuid null references public.pme_cadences(id) on delete set null,
  cadence_step_id uuid null references public.pme_cadence_steps(id) on delete set null,

  channel text not null check (channel in ('whatsapp', 'call', 'email')),
  lead_type text not null check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  phase text null check (phase is null or phase in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final')),

  selection_mode text not null default 'suggested' check (selection_mode in ('suggested', 'manual', 'automatic_blocked')),
  rendered_body text null,
  status text not null default 'suggested' check (status in ('suggested', 'copied', 'sent_manual', 'called', 'skipped', 'failed')),

  feedback_id uuid null,
  feedback_key text null,
  metadata jsonb not null default '{}'::jsonb,

  created_at timestamptz not null default now(),

  constraint pme_message_usage_has_reference check (
    template_id is not null or call_script_id is not null or cadence_step_id is not null
  )
);

comment on table public.pme_message_usage is 'PME: auditoria de templates sugeridos, copiados, enviados manualmente e scripts usados.';

create index if not exists idx_pme_message_usage_lead
  on public.pme_message_usage (tenant_id, lead_id, created_at desc);

create index if not exists idx_pme_message_usage_corretor
  on public.pme_message_usage (tenant_id, corretor_id, created_at desc);

create index if not exists idx_pme_message_usage_template
  on public.pme_message_usage (tenant_id, template_id, created_at desc);

-- =========================================================
-- 8. Updated_at trigger
-- =========================================================

create or replace function public.pme_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_pme_message_templates_updated_at
before update on public.pme_message_templates
for each row execute function public.pme_set_updated_at();

create trigger trg_pme_call_scripts_updated_at
before update on public.pme_call_scripts
for each row execute function public.pme_set_updated_at();

create trigger trg_pme_cadences_updated_at
before update on public.pme_cadences
for each row execute function public.pme_set_updated_at();

create trigger trg_pme_cadence_steps_updated_at
before update on public.pme_cadence_steps
for each row execute function public.pme_set_updated_at();

create trigger trg_pme_lead_message_state_updated_at
before update on public.pme_lead_message_state
for each row execute function public.pme_set_updated_at();

-- =========================================================
-- 9. RLS — DRAFT
-- =========================================================
-- Atenção:
-- As policies abaixo dependem de uma função de autorização tenant-safe.
-- A implementação de public.pme_can_access_tenant(uuid) precisa ser escrita
-- somente depois de auditar o schema real do FECH.AI.
--
-- Assinatura proposta:
-- public.pme_can_access_tenant(p_tenant_id uuid) returns boolean
-- Regras esperadas:
-- - root/admin_global pode auditar;
-- - admin/gestor acessa tenant próprio;
-- - corretor pode consumir templates ativos do tenant próprio;
-- - ninguém cruza tenant.

alter table public.pme_message_templates enable row level security;
alter table public.pme_call_scripts enable row level security;
alter table public.pme_cadences enable row level security;
alter table public.pme_cadence_steps enable row level security;
alter table public.pme_lead_message_state enable row level security;
alter table public.pme_message_usage enable row level security;

-- Policies intencionalmente NÃO criadas neste draft executável,
-- para evitar falsa sensação de segurança antes da auditoria do schema real.
-- Criar policies apenas quando public.pme_can_access_tenant(uuid) estiver validada.

rollback;

-- Fim do draft.
-- Trocar rollback por commit somente após validação completa em ambiente controlado.
