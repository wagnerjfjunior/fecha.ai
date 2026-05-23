-- FECH.AI — PME Usage Tracking DB/RLS/RPC v0.2.8
-- Fase: v0.2.8 — Banco/RPC/RLS do PME Usage Tracking
-- Branch: feature/pme-usage-tracking-db-v0.2.8
-- Base: main pós PR #22
--
-- Diretrizes aplicadas:
-- - empresa_id é o tenant operacional real do FECH.AI.
-- - não criar tenant_id paralelo.
-- - não alterar motor atual de leads/discador/MesaCliente.
-- - histórico de uso append-only.
-- - funções SECURITY DEFINER com search_path fixo public, pg_temp.
-- - nenhuma autoridade soberana vinda do frontend para empresa_id/corretor_id.

begin;

create extension if not exists pgcrypto;

-- =========================================================
-- 01. Helpers PME de autorização por empresa
-- =========================================================

create or replace function public.pme_can_access_empresa(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce(public.is_root(), false)
    or (
      p_empresa_id is not null
      and public.my_empresa_id() = p_empresa_id
    );
$$;

comment on function public.pme_can_access_empresa(uuid)
is 'PME v0.2.8: valida acesso de leitura/escopo por empresa_id, tenant operacional real do FECH.AI.';

create or replace function public.pme_is_empresa_admin(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
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

comment on function public.pme_is_empresa_admin(uuid)
is 'PME v0.2.8: valida permissão administrativa PME na empresa para gestão de templates/scripts/cadências.';

create or replace function public.pme_can_consume_empresa(p_empresa_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
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

comment on function public.pme_can_consume_empresa(uuid)
is 'PME v0.2.8: valida usuário operacional ativo da empresa para consumo/registro de uso PME.';

-- =========================================================
-- 02. Templates de mensagem PME
-- =========================================================

create table if not exists public.pme_message_templates (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  empreendimento_id uuid null references public.empreendimentos(id),
  channel text not null,
  lead_type text not null,
  phase text not null,
  tone text not null,
  title text not null,
  objective text null,
  body text not null,
  variables jsonb not null default '[]'::jsonb,
  weight integer not null default 1,
  is_active boolean not null default true,
  is_seed boolean not null default false,
  seed_key text null,
  created_by uuid null references public.corretores(id),
  updated_by uuid null references public.corretores(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pme_message_templates_channel_check check (channel in ('whatsapp', 'email', 'call_note')),
  constraint pme_message_templates_lead_type_check check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  constraint pme_message_templates_phase_check check (phase in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final')),
  constraint pme_message_templates_tone_check check (tone in ('consultivo', 'direto', 'executivo', 'leve', 'reativacao', 'urgencia_elegante')),
  constraint pme_message_templates_weight_check check (weight >= 0 and weight <= 100),
  constraint pme_message_templates_seed_key_unique unique (empresa_id, seed_key),
  constraint pme_message_templates_body_not_blank check (length(trim(body)) > 0),
  constraint pme_message_templates_title_not_blank check (length(trim(title)) > 0)
);

comment on table public.pme_message_templates is 'PME v0.2.8: templates de mensagens por empresa, canal, tipo de lead e fase.';
comment on column public.pme_message_templates.empresa_id is 'Tenant operacional real do FECH.AI. Não usar tenant_id paralelo.';
comment on column public.pme_message_templates.seed_key is 'Chave estável para seed versionado sem duplicidade por empresa.';

create index if not exists idx_pme_message_templates_lookup
  on public.pme_message_templates (empresa_id, channel, lead_type, phase, is_active);

create index if not exists idx_pme_message_templates_empreendimento
  on public.pme_message_templates (empresa_id, empreendimento_id);

-- =========================================================
-- 03. Scripts de ligação PME
-- =========================================================

create table if not exists public.pme_call_scripts (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  empreendimento_id uuid null references public.empreendimentos(id),
  lead_type text not null,
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
  constraint pme_call_scripts_lead_type_check check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  constraint pme_call_scripts_seed_key_unique unique (empresa_id, seed_key),
  constraint pme_call_scripts_title_not_blank check (length(trim(title)) > 0),
  constraint pme_call_scripts_opening_not_blank check (length(trim(opening)) > 0),
  constraint pme_call_scripts_context_not_blank check (length(trim(context)) > 0),
  constraint pme_call_scripts_first_question_not_blank check (length(trim(first_question)) > 0),
  constraint pme_call_scripts_closing_not_blank check (length(trim(closing)) > 0)
);

comment on table public.pme_call_scripts is 'PME v0.2.8: roteiros de ligação por empresa e tipo de lead.';

create index if not exists idx_pme_call_scripts_lookup
  on public.pme_call_scripts (empresa_id, lead_type, is_active);

-- =========================================================
-- 04. Cadências PME
-- =========================================================

create table if not exists public.pme_cadences (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  empreendimento_id uuid null references public.empreendimentos(id),
  lead_type text not null,
  title text not null,
  objective text null,
  risk_level text not null default 'medio',
  recommended_mode text not null default 'assistido',
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
  constraint pme_cadences_lead_type_check check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  constraint pme_cadences_risk_level_check check (risk_level in ('baixo', 'medio', 'alto')),
  constraint pme_cadences_recommended_mode_check check (recommended_mode in ('assistido', 'automatico_bloqueado', 'automatico_futuro')),
  constraint pme_cadences_seed_key_unique unique (empresa_id, seed_key),
  constraint pme_cadences_title_not_blank check (length(trim(title)) > 0)
);

comment on table public.pme_cadences is 'PME v0.2.8: cadências comerciais assistidas por empresa e tipo de lead.';

create index if not exists idx_pme_cadences_lookup
  on public.pme_cadences (empresa_id, lead_type, is_active);

-- =========================================================
-- 05. Passos de cadência PME
-- =========================================================

create table if not exists public.pme_cadence_steps (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  cadence_id uuid not null references public.pme_cadences(id) on delete cascade,
  step_order integer not null,
  step_when text not null,
  channel text not null,
  phase text not null,
  title text not null,
  instruction text not null,
  expected_result text null,
  requires_human_action boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pme_cadence_steps_order_check check (step_order > 0),
  constraint pme_cadence_steps_channel_check check (channel in ('whatsapp', 'call', 'email')),
  constraint pme_cadence_steps_phase_check check (phase in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final')),
  constraint pme_cadence_steps_unique_order unique (cadence_id, step_order),
  constraint pme_cadence_steps_title_not_blank check (length(trim(title)) > 0),
  constraint pme_cadence_steps_instruction_not_blank check (length(trim(instruction)) > 0)
);

comment on table public.pme_cadence_steps is 'PME v0.2.8: passos ordenados de cada cadência.';

create index if not exists idx_pme_cadence_steps_lookup
  on public.pme_cadence_steps (empresa_id, cadence_id, step_order, is_active);

-- =========================================================
-- 06. Estado PME por lead
-- =========================================================

create table if not exists public.pme_lead_message_state (
  id uuid primary key default gen_random_uuid(),
  empresa_id uuid not null references public.empresas(id),
  lead_id uuid not null references public.leads(id),
  corretor_id uuid null references public.corretores(id),
  cadence_id uuid null references public.pme_cadences(id) on delete set null,
  lead_type text not null,
  current_phase text null,
  current_step_order integer null,
  status text not null default 'active',
  next_action_at timestamptz null,
  last_contact_at timestamptz null,
  last_feedback text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint pme_lead_message_state_lead_type_check check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  constraint pme_lead_message_state_current_phase_check check (current_phase is null or current_phase in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final')),
  constraint pme_lead_message_state_step_order_check check (current_step_order is null or current_step_order > 0),
  constraint pme_lead_message_state_status_check check (status in ('active', 'paused', 'completed', 'stopped', 'opt_out')),
  constraint pme_lead_message_state_unique_lead unique (empresa_id, lead_id)
);

comment on table public.pme_lead_message_state is 'PME v0.2.8: estado atual da cadência de mensagens por lead.';

create index if not exists idx_pme_lead_message_state_next_action
  on public.pme_lead_message_state (empresa_id, status, next_action_at);

create index if not exists idx_pme_lead_message_state_corretor
  on public.pme_lead_message_state (empresa_id, corretor_id, status);

-- =========================================================
-- 07. Histórico append-only de uso PME
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
  channel text not null,
  lead_type text not null,
  phase text null,
  selection_mode text not null default 'suggested',
  rendered_body text null,
  status text not null default 'suggested',
  feedback_id uuid null,
  feedback_key text null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint pme_message_usage_channel_check check (channel in ('whatsapp', 'call', 'email')),
  constraint pme_message_usage_lead_type_check check (lead_type in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente')),
  constraint pme_message_usage_phase_check check (phase is null or phase in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final')),
  constraint pme_message_usage_selection_mode_check check (selection_mode in ('suggested', 'manual', 'automatic_blocked')),
  constraint pme_message_usage_status_check check (status in ('suggested', 'copied', 'sent_manual', 'called', 'skipped', 'failed')),
  constraint pme_message_usage_has_reference check (template_id is not null or call_script_id is not null or cadence_step_id is not null),
  constraint pme_message_usage_metadata_object check (jsonb_typeof(metadata) = 'object')
);

comment on table public.pme_message_usage is 'PME v0.2.8: auditoria append-only de templates sugeridos, copiados, enviados manualmente e scripts usados.';
comment on column public.pme_message_usage.empresa_id is 'Derivado do lead no RPC. Frontend não é autoridade para este campo.';
comment on column public.pme_message_usage.corretor_id is 'Derivado de my_corretor_id() no RPC quando disponível. Frontend não é autoridade.';

create index if not exists idx_pme_message_usage_lead
  on public.pme_message_usage (empresa_id, lead_id, created_at desc);

create index if not exists idx_pme_message_usage_corretor
  on public.pme_message_usage (empresa_id, corretor_id, created_at desc);

create index if not exists idx_pme_message_usage_template
  on public.pme_message_usage (empresa_id, template_id, created_at desc);

-- =========================================================
-- 08. Trigger updated_at
-- =========================================================

create or replace function public.pme_set_updated_at()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

comment on function public.pme_set_updated_at()
is 'PME v0.2.8: trigger function para updated_at em tabelas PME configuráveis.';

drop trigger if exists trg_pme_message_templates_updated_at on public.pme_message_templates;
create trigger trg_pme_message_templates_updated_at
before update on public.pme_message_templates
for each row execute function public.pme_set_updated_at();

drop trigger if exists trg_pme_call_scripts_updated_at on public.pme_call_scripts;
create trigger trg_pme_call_scripts_updated_at
before update on public.pme_call_scripts
for each row execute function public.pme_set_updated_at();

drop trigger if exists trg_pme_cadences_updated_at on public.pme_cadences;
create trigger trg_pme_cadences_updated_at
before update on public.pme_cadences
for each row execute function public.pme_set_updated_at();

drop trigger if exists trg_pme_cadence_steps_updated_at on public.pme_cadence_steps;
create trigger trg_pme_cadence_steps_updated_at
before update on public.pme_cadence_steps
for each row execute function public.pme_set_updated_at();

drop trigger if exists trg_pme_lead_message_state_updated_at on public.pme_lead_message_state;
create trigger trg_pme_lead_message_state_updated_at
before update on public.pme_lead_message_state
for each row execute function public.pme_set_updated_at();

-- =========================================================
-- 09. RLS
-- =========================================================

alter table public.pme_message_templates enable row level security;
alter table public.pme_call_scripts enable row level security;
alter table public.pme_cadences enable row level security;
alter table public.pme_cadence_steps enable row level security;
alter table public.pme_lead_message_state enable row level security;
alter table public.pme_message_usage enable row level security;

-- Recria policies para evitar drift/idempotência controlada.
drop policy if exists pme_message_templates_select on public.pme_message_templates;
drop policy if exists pme_message_templates_insert on public.pme_message_templates;
drop policy if exists pme_message_templates_update on public.pme_message_templates;
drop policy if exists pme_call_scripts_select on public.pme_call_scripts;
drop policy if exists pme_call_scripts_insert on public.pme_call_scripts;
drop policy if exists pme_call_scripts_update on public.pme_call_scripts;
drop policy if exists pme_cadences_select on public.pme_cadences;
drop policy if exists pme_cadences_insert on public.pme_cadences;
drop policy if exists pme_cadences_update on public.pme_cadences;
drop policy if exists pme_cadence_steps_select on public.pme_cadence_steps;
drop policy if exists pme_cadence_steps_insert on public.pme_cadence_steps;
drop policy if exists pme_cadence_steps_update on public.pme_cadence_steps;
drop policy if exists pme_lead_message_state_select on public.pme_lead_message_state;
drop policy if exists pme_lead_message_state_insert on public.pme_lead_message_state;
drop policy if exists pme_lead_message_state_update on public.pme_lead_message_state;
drop policy if exists pme_message_usage_select on public.pme_message_usage;
drop policy if exists pme_message_usage_insert on public.pme_message_usage;

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

create policy pme_message_usage_select
on public.pme_message_usage
for select
using (public.pme_can_access_empresa(empresa_id));

create policy pme_message_usage_insert
on public.pme_message_usage
for insert
with check (public.pme_can_consume_empresa(empresa_id));

-- Sem policy de UPDATE/DELETE em pme_message_usage: append-only por desenho.

-- =========================================================
-- 10. RPC append-only para registrar uso PME
-- =========================================================

create or replace function public.pme_registrar_message_usage(
  p_lead_id uuid,
  p_payload jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  v_payload jsonb := coalesce(p_payload, '{}'::jsonb);
  v_lead record;
  v_corretor_id uuid;
  v_template_id uuid;
  v_call_script_id uuid;
  v_cadence_id uuid;
  v_cadence_step_id uuid;
  v_channel text;
  v_lead_type text;
  v_phase text;
  v_selection_mode text;
  v_rendered_body text;
  v_status text;
  v_feedback_key text;
  v_metadata jsonb;
  v_usage_id uuid;
begin
  if auth.uid() is null then
    raise exception 'auth_required' using errcode = '28000';
  end if;

  if p_lead_id is null then
    raise exception 'p_lead_id_required' using errcode = '22023';
  end if;

  if jsonb_typeof(v_payload) <> 'object' then
    raise exception 'p_payload_must_be_object' using errcode = '22023';
  end if;

  if v_payload ?| array['empresa_id','tenant_id','corretor_id','user_id','created_by','updated_by'] then
    raise exception 'frontend_authority_forbidden' using errcode = '42501';
  end if;

  select l.id, l.empresa_id, l.corretor_id
    into v_lead
  from public.leads l
  where l.id = p_lead_id;

  if v_lead.id is null then
    raise exception 'lead_not_found' using errcode = 'P0002';
  end if;

  if not public.pme_can_consume_empresa(v_lead.empresa_id) then
    raise exception 'pme_scope_denied' using errcode = '42501';
  end if;

  v_corretor_id := public.my_corretor_id();
  v_template_id := nullif(v_payload->>'template_id', '')::uuid;
  v_call_script_id := nullif(v_payload->>'call_script_id', '')::uuid;
  v_cadence_id := nullif(v_payload->>'cadence_id', '')::uuid;
  v_cadence_step_id := nullif(v_payload->>'cadence_step_id', '')::uuid;
  v_channel := coalesce(nullif(v_payload->>'channel', ''), 'whatsapp');
  v_lead_type := coalesce(nullif(v_payload->>'lead_type', ''), 'lista_fria');
  v_phase := nullif(v_payload->>'phase', '');
  v_selection_mode := coalesce(nullif(v_payload->>'selection_mode', ''), 'suggested');
  v_rendered_body := nullif(v_payload->>'rendered_body', '');
  v_status := coalesce(nullif(v_payload->>'status', ''), 'suggested');
  v_feedback_key := nullif(v_payload->>'feedback_key', '');
  v_metadata := coalesce(v_payload->'metadata', '{}'::jsonb);

  if jsonb_typeof(v_metadata) <> 'object' then
    raise exception 'metadata_must_be_object' using errcode = '22023';
  end if;

  if v_template_id is null and v_call_script_id is null and v_cadence_step_id is null then
    raise exception 'usage_reference_required' using errcode = '22023';
  end if;

  if v_channel not in ('whatsapp', 'call', 'email') then
    raise exception 'invalid_channel' using errcode = '22023';
  end if;

  if v_lead_type not in ('visitou_plantao', 'lista_fria', 'lista_quente', 'lead_quente') then
    raise exception 'invalid_lead_type' using errcode = '22023';
  end if;

  if v_phase is not null and v_phase not in ('primeira_mensagem', 'segunda_mensagem', 'terceira_mensagem', 'mensagem_final') then
    raise exception 'invalid_phase' using errcode = '22023';
  end if;

  if v_selection_mode not in ('suggested', 'manual', 'automatic_blocked') then
    raise exception 'invalid_selection_mode' using errcode = '22023';
  end if;

  if v_status not in ('suggested', 'copied', 'sent_manual', 'called', 'skipped', 'failed') then
    raise exception 'invalid_status' using errcode = '22023';
  end if;

  if v_template_id is not null and not exists (
    select 1 from public.pme_message_templates t
    where t.id = v_template_id and t.empresa_id = v_lead.empresa_id
  ) then
    raise exception 'template_scope_denied_or_not_found' using errcode = '42501';
  end if;

  if v_call_script_id is not null and not exists (
    select 1 from public.pme_call_scripts s
    where s.id = v_call_script_id and s.empresa_id = v_lead.empresa_id
  ) then
    raise exception 'call_script_scope_denied_or_not_found' using errcode = '42501';
  end if;

  if v_cadence_id is not null and not exists (
    select 1 from public.pme_cadences c
    where c.id = v_cadence_id and c.empresa_id = v_lead.empresa_id
  ) then
    raise exception 'cadence_scope_denied_or_not_found' using errcode = '42501';
  end if;

  if v_cadence_step_id is not null and not exists (
    select 1 from public.pme_cadence_steps cs
    where cs.id = v_cadence_step_id and cs.empresa_id = v_lead.empresa_id
  ) then
    raise exception 'cadence_step_scope_denied_or_not_found' using errcode = '42501';
  end if;

  insert into public.pme_message_usage (
    empresa_id,
    lead_id,
    corretor_id,
    template_id,
    call_script_id,
    cadence_id,
    cadence_step_id,
    channel,
    lead_type,
    phase,
    selection_mode,
    rendered_body,
    status,
    feedback_key,
    metadata
  ) values (
    v_lead.empresa_id,
    p_lead_id,
    v_corretor_id,
    v_template_id,
    v_call_script_id,
    v_cadence_id,
    v_cadence_step_id,
    v_channel,
    v_lead_type,
    v_phase,
    v_selection_mode,
    v_rendered_body,
    v_status,
    v_feedback_key,
    v_metadata
  ) returning id into v_usage_id;

  return jsonb_build_object(
    'ok', true,
    'fase', 'v0.2.8_PME_USAGE_TRACKING_DB_RLS_RPC',
    'visao', 'operacional',
    'append_only', true,
    'dml', true,
    'usage_id', v_usage_id,
    'lead_id', p_lead_id,
    'empresa_id', v_lead.empresa_id,
    'corretor_id', v_corretor_id,
    'status', v_status,
    'channel', v_channel,
    'lead_type', v_lead_type,
    'phase', v_phase
  );
end;
$$;

comment on function public.pme_registrar_message_usage(uuid, jsonb)
is 'PME v0.2.8: registra uso append-only de mensagem/script/cadência para lead, derivando empresa_id do banco e corretor_id do contexto autenticado.';

-- =========================================================
-- 11. Grants explícitos
-- =========================================================

revoke all on function public.pme_can_access_empresa(uuid) from public, anon;
revoke all on function public.pme_is_empresa_admin(uuid) from public, anon;
revoke all on function public.pme_can_consume_empresa(uuid) from public, anon;
revoke all on function public.pme_set_updated_at() from public, anon;
revoke all on function public.pme_registrar_message_usage(uuid, jsonb) from public, anon;

grant execute on function public.pme_can_access_empresa(uuid) to authenticated, service_role;
grant execute on function public.pme_is_empresa_admin(uuid) to authenticated, service_role;
grant execute on function public.pme_can_consume_empresa(uuid) to authenticated, service_role;
grant execute on function public.pme_registrar_message_usage(uuid, jsonb) to authenticated, service_role;

-- Tabelas: acesso direto controlado por RLS. RPC é o caminho preferencial para usage.
grant select, insert, update on public.pme_message_templates to authenticated;
grant select, insert, update on public.pme_call_scripts to authenticated;
grant select, insert, update on public.pme_cadences to authenticated;
grant select, insert, update on public.pme_cadence_steps to authenticated;
grant select, insert, update on public.pme_lead_message_state to authenticated;
grant select, insert on public.pme_message_usage to authenticated;

commit;
