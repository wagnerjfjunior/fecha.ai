-- FECH.AI — Power Message Engine
-- Supabase migration draft
-- Status: DRAFT ONLY. Do not apply in production before approval.
-- Branch: main
--
-- Contexto apos auditoria real do Supabase:
-- - O FECH.AI nao possui tabela tenants separada.
-- - public.empresas e o eixo real de isolamento operacional.
-- - public.corretores centraliza RBAC, ownership e empresa_id.
-- - A PME v1 deve usar empresa_id, nao tenant_id.
--
-- Regra operacional:
-- Este arquivo continua com ROLLBACK no final.
-- Ele serve para revisao tecnica, nao para aplicacao direta em producao.

begin;

-- =========================================================
-- 0. Extensoes
-- =========================================================

create extension if not exists pgcrypto;

-- =========================================================
-- 1. Funcoes auxiliares PME — DRAFT
-- =========================================================
-- Dependem das funcoes reais ja auditadas:
-- public.is_root()
-- public.my_empresa_id()
-- public.my_corretor_id()

create or replace function public.pme_can_access_empresa(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.is_root(), false)
    or (
      p_empresa_id is not null
      and public.my_empresa_id() = p_empresa_id
    );
$$;

create or replace function public.pme_is_empresa_admin(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.is_root(), false)
    or exists (
      select 1
      from public.corretores c
      where c.user_id = auth.uid()
        and c.ativo = true
        and c.empresa_id = p_empresa_id
        and (
          c.is_gestor = true
          or c.is_admin_local = true
          or c.role in ('gestor', 'admin_local', 'admin_global')
        )
    );
$$;

create or replace function public.pme_can_consume_empresa(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(public.is_root(), false)
    or exists (
      select 1
      from public.corretores c
      where c.user_id = auth.uid()
        and c.ativo = true
        and c.empresa_id = p_empresa_id
    );
$$;

-- =========================================================
-- 2. Templates de mensagem
-- =========================================================

create table if not exists public.pme_message_templates (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  empreendimento_id uuid null references public.empreendimentos(id),

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

  created_by uuid null references public.corretores(id),
  updated_by uuid null references public.corretores(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pme_message_templates_seed_key_unique unique (empresa_id, seed_key),
  constraint pme_message_templates_body_not_blank check (length(trim(body)) > 0),
  constraint pme_message_templates_title_not_blank check (length(trim(title)) > 0)
);

comment on table public.pme_message_templates is 'PME: templates de mensagens por empresa, canal, tipo de lead e fase.';
comment on column public.pme_message_templates.empresa_id is 'Isolamento operacional real do FECH.AI. Equivale ao tenant operacional na PME v1.';
comment on column public.pme_message_templates.seed_key is 'Chave estavel para importar seeds versionados sem duplicidade.';

create index if not exists idx_pme_message_templates_lookup
  on public.pme_message_templates (empresa_id, channel, lead_type, phase, is_active);

create index if not exists idx_pme_message_templates_empreendimento
  on public.pme_message_templates (empresa_id, empreendimento_id);

-- =========================================================
-- 3. Scripts de ligacao
-- =========================================================

create table if not exists public.pme_call_scripts (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  empreendimento_id uuid null references public.empreendimentos(id),

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

  created_by uuid null references public.corretores(id),
  updated_by uuid null references public.corretores(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pme_call_scripts_seed_key_unique unique (empresa_id, seed_key),
  constraint pme_call_scripts_title_not_blank check (length(trim(title)) > 0),
  constraint pme_call_scripts_opening_not_blank check (length(trim(opening)) > 0)
);

comment on table public.pme_call_scripts is 'PME: roteiros de ligacao por empresa e tipo de lead.';

create index if not exists idx_pme_call_scripts_lookup
  on public.pme_call_scripts (empresa_id, lead_type, is_active);

-- =========================================================
-- 4. Cadencias
-- =========================================================

create table if not exists public.pme_cadences (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  empreendimento_id uuid null references public.empreendimentos(id),

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

  created_by uuid null references public.corretores(id),
  updated_by uuid null references public.corretores(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint pme_cadences_seed_key_unique unique (empresa_id, seed_key),
  constraint pme_cadences_title_not_blank check (length(trim(title)) > 0)
);

comment on table public.pme_cadences is 'PME: cadencias comerciais assistidas por empresa e tipo de lead.';

create index if not exists idx_pme_cadences_lookup
  on public.pme_cadences (empresa_id, lead_type, is_active);

-- =========================================================
-- 5. Passos das cadencias
-- =========================================================

create table if not exists public.pme_cadence_steps (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
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

comment on table public.pme_cadence_steps is 'PME: passos ordenados de cada cadencia.';

create index if not exists idx_pme_cadence_steps_lookup
  on public.pme_cadence_steps (empresa_id, cadence_id, step_order, is_active);

-- =========================================================
-- 6. Estado da cadencia por lead
-- =========================================================

create table if not exists public.pme_lead_message_state (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  lead_id uuid not null references public.leads(id),
  corretor_id uuid null references public.corretores(id),
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

  constraint pme_lead_message_state_unique_lead unique (empresa_id, lead_id)
);

comment on table public.pme_lead_message_state is 'PME: estado atual da cadencia de mensagens por lead.';

create index if not exists idx_pme_lead_message_state_next_action
  on public.pme_lead_message_state (empresa_id, status, next_action_at);

create index if not exists idx_pme_lead_message_state_corretor
  on public.pme_lead_message_state (empresa_id, corretor_id, status);

-- =========================================================
-- 7. Historico de uso da PME
-- =========================================================

create table if not exists public.pme_message_usage (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  lead_id uuid not null references public.leads(id),
  corretor_id uuid null references public.corretores(id),

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

comment on table public.pme_message_usage is 'PME: auditoria append-only de templates sugeridos, copiados, enviados manualmente e scripts usados.';

create index if not exists idx_pme_message_usage_lead
  on public.pme_message_usage (empresa_id, lead_id, created_at desc);

create index if not exists idx_pme_message_usage_corretor
  on public.pme_message_usage (empresa_id, corretor_id, created_at desc);

create index if not exists idx_pme_message_usage_template
  on public.pme_message_usage (empresa_id, template_id, created_at desc);

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

alter table public.pme_message_templates enable row level security;
alter table public.pme_call_scripts enable row level security;
alter table public.pme_cadences enable row level security;
alter table public.pme_cadence_steps enable row level security;
alter table public.pme_lead_message_state enable row level security;
alter table public.pme_message_usage enable row level security;

-- SELECT templates: qualquer usuario ativo da empresa pode consumir templates ativos.
create policy pme_message_templates_select
on public.pme_message_templates
for select
using (
  public.pme_is_empresa_admin(empresa_id)
  or (is_active = true and public.pme_can_consume_empresa(empresa_id))
);

create policy pme_message_templates_insert
on public.pme_message_templates
for insert
with check (public.pme_is_empresa_admin(empresa_id));

create policy pme_message_templates_update
on public.pme_message_templates
for update
using (public.pme_is_empresa_admin(empresa_id))
with check (public.pme_is_empresa_admin(empresa_id));

-- Scripts
create policy pme_call_scripts_select
on public.pme_call_scripts
for select
using (
  public.pme_is_empresa_admin(empresa_id)
  or (is_active = true and public.pme_can_consume_empresa(empresa_id))
);

create policy pme_call_scripts_insert
on public.pme_call_scripts
for insert
with check (public.pme_is_empresa_admin(empresa_id));

create policy pme_call_scripts_update
on public.pme_call_scripts
for update
using (public.pme_is_empresa_admin(empresa_id))
with check (public.pme_is_empresa_admin(empresa_id));

-- Cadencias
create policy pme_cadences_select
on public.pme_cadences
for select
using (
  public.pme_is_empresa_admin(empresa_id)
  or (is_active = true and public.pme_can_consume_empresa(empresa_id))
);

create policy pme_cadences_insert
on public.pme_cadences
for insert
with check (public.pme_is_empresa_admin(empresa_id));

create policy pme_cadences_update
on public.pme_cadences
for update
using (public.pme_is_empresa_admin(empresa_id))
with check (public.pme_is_empresa_admin(empresa_id));

-- Passos de cadencia
create policy pme_cadence_steps_select
on public.pme_cadence_steps
for select
using (
  public.pme_is_empresa_admin(empresa_id)
  or (is_active = true and public.pme_can_consume_empresa(empresa_id))
);

create policy pme_cadence_steps_insert
on public.pme_cadence_steps
for insert
with check (public.pme_is_empresa_admin(empresa_id));

create policy pme_cadence_steps_update
on public.pme_cadence_steps
for update
using (public.pme_is_empresa_admin(empresa_id))
with check (public.pme_is_empresa_admin(empresa_id));

-- Estado por lead
create policy pme_lead_message_state_select
on public.pme_lead_message_state
for select
using (public.pme_can_access_empresa(empresa_id));

create policy pme_lead_message_state_insert
on public.pme_lead_message_state
for insert
with check (public.pme_can_access_empresa(empresa_id));

create policy pme_lead_message_state_update
on public.pme_lead_message_state
for update
using (public.pme_can_access_empresa(empresa_id))
with check (public.pme_can_access_empresa(empresa_id));

-- Historico append-only: insert permitido para usuarios ativos da empresa; update/delete nao criados.
create policy pme_message_usage_select
on public.pme_message_usage
for select
using (public.pme_can_access_empresa(empresa_id));

create policy pme_message_usage_insert
on public.pme_message_usage
for insert
with check (public.pme_can_consume_empresa(empresa_id));

rollback;

-- Fim do draft.
-- Trocar rollback por commit somente apos validacao completa em ambiente controlado.
