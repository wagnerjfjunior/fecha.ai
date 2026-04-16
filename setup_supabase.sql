-- =============================================================
-- DISCADOR — Setup Completo do Supabase
-- Versão: 1.0.0
-- Data: 2026-04-15
-- Instruções: Cole TUDO no SQL Editor do Supabase e execute.
-- =============================================================

-- 0. EXTENSÕES
create extension if not exists "uuid-ossp";

-- =============================================================
-- 1. TABELAS
-- =============================================================

-- CORRETORES
create table if not exists corretores (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users(id) unique,
  nome text not null,
  email text not null unique,
  ativo boolean default true,
  apto_para_receber boolean default true,
  is_gestor boolean default false,
  created_at timestamptz default now()
);

-- LISTAS (cada arquivo de leads comprado de um fornecedor)
create table if not exists listas (
  id uuid default uuid_generate_v4() primary key,
  nome_fornecedor text not null,
  nome_arquivo text,
  total_leads integer default 0,
  leads_validos integer default 0,
  leads_invalidos integer default 0,
  uploaded_by uuid references corretores(id),
  created_at timestamptz default now()
);

-- LOTES (cada pacote de 25 leads enviado a um corretor)
create table if not exists lotes (
  id uuid default uuid_generate_v4() primary key,
  corretor_id uuid references corretores(id) not null,
  status text default 'aberto' check (status in ('aberto','finalizado')),
  quantidade_leads integer default 25,
  quantidade_feedback integer default 0,
  data_abertura timestamptz default now(),
  data_fechamento timestamptz
);

-- LEADS (cada lead individual — cresce a cada lista comprada)
create table if not exists leads (
  id uuid default uuid_generate_v4() primary key,
  lista_id uuid references listas(id),
  lote_id uuid references lotes(id),
  corretor_id uuid references corretores(id),
  nome text,
  email text,
  endereco text,
  telefone_origem_1 text,
  telefone_origem_2 text,
  telefone_escolhido text,
  telefone_e164 text,
  tipo_telefone text,
  pais_telefone text,
  ligar text,
  whatsapp text,
  status text default 'disponivel' check (status in ('disponivel','distribuido','finalizado','invalido')),
  feedback text,
  data_feedback timestamptz,
  observacao_corretor text,
  score numeric default 0,
  fornecedor text,
  data_importacao timestamptz default now(),
  updated_at timestamptz
);

-- LOGS (auditoria completa)
create table if not exists logs (
  id uuid default uuid_generate_v4() primary key,
  acao text not null,
  usuario_email text,
  detalhes jsonb default '{}'::jsonb,
  created_at timestamptz default now()
);

-- =============================================================
-- 2. ÍNDICES (performance)
-- =============================================================

create index if not exists idx_leads_status on leads(status);
create index if not exists idx_leads_lote on leads(lote_id);
create index if not exists idx_leads_corretor on leads(corretor_id);
create index if not exists idx_leads_lista on leads(lista_id);
create index if not exists idx_leads_score on leads(score desc nulls last);
create index if not exists idx_lotes_corretor_status on lotes(corretor_id, status);
create index if not exists idx_corretores_user on corretores(user_id);

-- =============================================================
-- 3. FUNÇÕES AUXILIARES
-- =============================================================

-- Retorna o ID do corretor logado
create or replace function my_corretor_id()
returns uuid
language sql security definer stable
as $$
  select id from corretores where user_id = auth.uid() limit 1;
$$;

-- Verifica se o usuário logado é gestor
create or replace function is_gestor()
returns boolean
language sql security definer stable
as $$
  select coalesce(
    (select is_gestor from corretores where user_id = auth.uid() limit 1),
    false
  );
$$;

-- =============================================================
-- 4. RLS (Row Level Security)
-- =============================================================

alter table corretores enable row level security;
alter table listas enable row level security;
alter table lotes enable row level security;
alter table leads enable row level security;
alter table logs enable row level security;

-- CORRETORES: todos leem, só gestor insere/atualiza
create policy "corretores_select" on corretores
  for select using (true);

create policy "corretores_insert" on corretores
  for insert with check (is_gestor() or not exists (select 1 from corretores));

create policy "corretores_update" on corretores
  for update using (user_id = auth.uid() or is_gestor());

-- LISTAS: todos leem, só gestor insere
create policy "listas_select" on listas for select using (true);
create policy "listas_insert" on listas for insert with check (is_gestor());

-- LOTES: corretor vê os dele, gestor vê tudo
create policy "lotes_select" on lotes
  for select using (corretor_id = my_corretor_id() or is_gestor());

create policy "lotes_update" on lotes
  for update using (is_gestor());

-- LEADS: corretor vê só os dele, gestor vê tudo
create policy "leads_select" on leads
  for select using (corretor_id = my_corretor_id() or is_gestor());

create policy "leads_update" on leads
  for update using (corretor_id = my_corretor_id() or is_gestor());

create policy "leads_insert" on leads
  for insert with check (is_gestor());

-- LOGS: todos inserem, só gestor lê
create policy "logs_insert" on logs for insert with check (true);
create policy "logs_select" on logs for select using (is_gestor());

-- =============================================================
-- 5. RPC: IMPORTAR LEADS (chamada pela gestora após upload)
-- =============================================================

create or replace function importar_leads_batch(
  p_lista_id uuid,
  p_leads jsonb
)
returns jsonb
language plpgsql security definer
as $$
declare
  v_lead jsonb;
  v_count_valid integer := 0;
  v_count_invalid integer := 0;
  v_count_dup integer := 0;
  v_telefone text;
  v_status text;
  v_score numeric;
  v_existing integer;
begin
  for v_lead in select * from jsonb_array_elements(p_leads)
  loop
    v_telefone := coalesce(v_lead->>'telefone_e164', '');

    -- Deduplicação por nome+email+telefone
    select count(*) into v_existing
    from leads
    where lower(coalesce(nome,'')) = lower(coalesce(v_lead->>'nome',''))
      and lower(coalesce(email,'')) = lower(coalesce(v_lead->>'email',''))
      and coalesce(telefone_e164,'') = v_telefone;

    if v_existing > 0 then
      v_count_dup := v_count_dup + 1;
      continue;
    end if;

    -- Status baseado na validez do telefone
    if v_telefone = '' then
      v_status := 'invalido';
      v_count_invalid := v_count_invalid + 1;
    else
      v_status := 'disponivel';
      v_count_valid := v_count_valid + 1;
    end if;

    -- Score básico
    v_score := 0;
    if (v_lead->>'tipo_telefone') = 'br_celular' then v_score := v_score + 5; end if;
    if coalesce(v_lead->>'whatsapp','') <> '' then v_score := v_score + 3; end if;
    if length(coalesce(v_lead->>'nome','')) > 5 then v_score := v_score + 2; end if;
    if coalesce(v_lead->>'email','') <> '' then v_score := v_score + 1; end if;

    insert into leads (
      lista_id, nome, email, endereco,
      telefone_origem_1, telefone_origem_2,
      telefone_escolhido, telefone_e164,
      tipo_telefone, pais_telefone,
      ligar, whatsapp, status, score,
      fornecedor, data_importacao
    ) values (
      p_lista_id,
      v_lead->>'nome',
      lower(coalesce(v_lead->>'email','')),
      v_lead->>'endereco',
      v_lead->>'telefone_origem_1',
      v_lead->>'telefone_origem_2',
      v_lead->>'telefone_escolhido',
      v_telefone,
      v_lead->>'tipo_telefone',
      v_lead->>'pais_telefone',
      v_lead->>'ligar',
      v_lead->>'whatsapp',
      v_status,
      v_score,
      v_lead->>'fornecedor',
      now()
    );
  end loop;

  -- Atualiza contadores da lista
  update listas
  set total_leads = v_count_valid + v_count_invalid,
      leads_validos = v_count_valid,
      leads_invalidos = v_count_invalid
  where id = p_lista_id;

  -- Log
  insert into logs (acao, usuario_email, detalhes)
  values ('importacao', current_setting('request.jwt.claims', true)::jsonb->>'email',
    jsonb_build_object(
      'lista_id', p_lista_id,
      'validos', v_count_valid,
      'invalidos', v_count_invalid,
      'duplicados', v_count_dup
    )
  );

  return jsonb_build_object(
    'validos', v_count_valid,
    'invalidos', v_count_invalid,
    'duplicados', v_count_dup
  );
end;
$$;

-- =============================================================
-- 6. RPC: DISTRIBUIR LOTES (transacional e com lock)
-- =============================================================

create or replace function distribuir_lotes()
returns jsonb
language plpgsql security definer
as $$
declare
  v_corretor record;
  v_lead_ids uuid[];
  v_lote_id uuid;
  v_count integer := 0;
begin
  -- Lock global para evitar concorrência
  perform pg_advisory_xact_lock(hashtext('distribuicao'));

  for v_corretor in
    select c.id, c.nome, c.email
    from corretores c
    where c.ativo = true
      and c.apto_para_receber = true
      and not exists (
        select 1 from lotes l
        where l.corretor_id = c.id and l.status = 'aberto'
      )
  loop
    -- Seleciona 25 leads disponíveis com lock (evita race condition)
    select array_agg(sub.id) into v_lead_ids
    from (
      select id from leads
      where status = 'disponivel'
        and lote_id is null
        and corretor_id is null
      order by score desc nulls last, data_importacao asc
      limit 25
      for update skip locked
    ) sub;

    -- Se não tem 25 leads, não distribui
    if v_lead_ids is null or array_length(v_lead_ids, 1) < 25 then
      continue;
    end if;

    -- Cria o lote
    insert into lotes (corretor_id, status, quantidade_leads)
    values (v_corretor.id, 'aberto', 25)
    returning id into v_lote_id;

    -- Atualiza os leads (tudo na mesma transação)
    update leads
    set status = 'distribuido',
        corretor_id = v_corretor.id,
        lote_id = v_lote_id,
        updated_at = now()
    where id = any(v_lead_ids);

    v_count := v_count + 1;

    insert into logs (acao, usuario_email, detalhes)
    values ('distribuicao', v_corretor.email,
      jsonb_build_object('corretor', v_corretor.nome, 'lote_id', v_lote_id, 'leads', 25)
    );
  end loop;

  return jsonb_build_object('lotes_criados', v_count);
end;
$$;

-- =============================================================
-- 7. RPC: REGISTRAR FEEDBACK (corretor usa no discador)
-- =============================================================

create or replace function registrar_feedback(
  p_lead_id uuid,
  p_feedback text,
  p_observacao text default ''
)
returns jsonb
language plpgsql security definer
as $$
declare
  v_lead record;
  v_lote_id uuid;
  v_feedbacks_count integer;
  v_corretor_id uuid;
  v_feedbacks_validos text[] := array[
    'agendado_visita','enviado_informacoes','nao_responde',
    'numero_errado','caixa_postal','sem_interesse',
    'nao_toca','retornar_depois','lead_ja_atendido'
  ];
  v_lote_fechado boolean := false;
begin
  -- Valida feedback
  if not (p_feedback = any(v_feedbacks_validos)) then
    return jsonb_build_object('error', 'Feedback inválido: ' || p_feedback);
  end if;

  -- Busca o lead e verifica permissão
  v_corretor_id := my_corretor_id();
  select * into v_lead from leads where id = p_lead_id;

  if v_lead is null then
    return jsonb_build_object('error', 'Lead não encontrado');
  end if;

  if v_lead.corretor_id <> v_corretor_id and not is_gestor() then
    return jsonb_build_object('error', 'Lead não pertence a você');
  end if;

  if v_lead.status <> 'distribuido' then
    return jsonb_build_object('error', 'Lead não está em atendimento');
  end if;

  -- Registra feedback (NÃO muda status para finalizado ainda)
  update leads
  set feedback = p_feedback,
      observacao_corretor = p_observacao,
      data_feedback = now(),
      updated_at = now()
  where id = p_lead_id;

  v_lote_id := v_lead.lote_id;

  -- Conta feedbacks válidos do lote
  select count(*) into v_feedbacks_count
  from leads
  where lote_id = v_lote_id
    and feedback = any(v_feedbacks_validos);

  -- Atualiza contador no lote
  update lotes
  set quantidade_feedback = v_feedbacks_count
  where id = v_lote_id;

  -- Se 25/25: fecha o lote e finaliza os leads
  if v_feedbacks_count >= 25 then
    update lotes
    set status = 'finalizado', data_fechamento = now()
    where id = v_lote_id;

    update leads
    set status = 'finalizado', updated_at = now()
    where lote_id = v_lote_id;

    v_lote_fechado := true;

    insert into logs (acao, usuario_email, detalhes)
    values ('lote_fechado', '',
      jsonb_build_object('lote_id', v_lote_id, 'corretor_id', v_corretor_id)
    );
  end if;

  return jsonb_build_object(
    'ok', true,
    'feedbacks_no_lote', v_feedbacks_count,
    'lote_fechado', v_lote_fechado
  );
end;
$$;

-- =============================================================
-- 8. RPC: DASHBOARD STATS (para o painel do gestor)
-- =============================================================

create or replace function get_dashboard_stats()
returns jsonb
language plpgsql security definer stable
as $$
declare
  v_result jsonb;
begin
  select jsonb_build_object(
    'total_leads', (select count(*) from leads),
    'disponiveis', (select count(*) from leads where status = 'disponivel'),
    'distribuidos', (select count(*) from leads where status = 'distribuido'),
    'finalizados', (select count(*) from leads where status = 'finalizado'),
    'invalidos', (select count(*) from leads where status = 'invalido'),
    'lotes_abertos', (select count(*) from lotes where status = 'aberto'),
    'lotes_fechados', (select count(*) from lotes where status = 'finalizado'),
    'corretores_ativos', (select count(*) from corretores where ativo = true),
    'por_corretor', (
      select coalesce(jsonb_agg(row_to_json(sub)), '[]'::jsonb)
      from (
        select
          c.nome,
          count(l.id) as total_leads,
          count(case when l.feedback = 'agendado_visita' then 1 end) as visitas,
          count(case when l.feedback = 'enviado_informacoes' then 1 end) as informacoes,
          count(case when l.feedback = 'nao_responde' then 1 end) as nao_responde,
          count(case when l.feedback = 'numero_errado' then 1 end) as numero_errado,
          count(case when l.feedback = 'sem_interesse' then 1 end) as sem_interesse,
          count(case when l.feedback is not null then 1 end) as com_feedback,
          round(
            count(case when l.feedback = 'agendado_visita' then 1 end)::numeric
            / nullif(count(case when l.feedback is not null then 1 end), 0) * 100, 1
          ) as taxa_visita
        from corretores c
        left join leads l on l.corretor_id = c.id
        where c.ativo = true
        group by c.nome
        order by c.nome
      ) sub
    ),
    'por_fornecedor', (
      select coalesce(jsonb_agg(row_to_json(sub)), '[]'::jsonb)
      from (
        select
          coalesce(li.nome_fornecedor, 'Desconhecido') as fornecedor,
          count(l.id) as total,
          count(case when l.feedback = 'agendado_visita' then 1 end) as visitas,
          count(case when l.feedback = 'numero_errado' then 1 end) as errados,
          round(
            count(case when l.feedback = 'numero_errado' then 1 end)::numeric
            / nullif(count(l.id), 0) * 100, 1
          ) as taxa_erro
        from leads l
        left join listas li on li.id = l.lista_id
        group by li.nome_fornecedor
        order by li.nome_fornecedor
      ) sub
    ),
    'feedbacks', (
      select coalesce(jsonb_object_agg(f, c), '{}'::jsonb)
      from (
        select feedback as f, count(*) as c
        from leads
        where feedback is not null
        group by feedback
      ) sub
    )
  ) into v_result;

  return v_result;
end;
$$;

-- =============================================================
-- 9. RPC: PRÓXIMO LEAD DO CORRETOR
-- =============================================================

create or replace function proximo_lead()
returns jsonb
language plpgsql security definer
as $$
declare
  v_corretor_id uuid;
  v_lead record;
  v_lote record;
  v_total_lote integer;
  v_feedback_lote integer;
begin
  v_corretor_id := my_corretor_id();

  if v_corretor_id is null then
    return jsonb_build_object('error', 'Corretor não encontrado');
  end if;

  -- Busca lote aberto do corretor
  select * into v_lote
  from lotes
  where corretor_id = v_corretor_id and status = 'aberto'
  limit 1;

  if v_lote is null then
    return jsonb_build_object('lead', null, 'message', 'Sem lote aberto. Aguarde distribuição.');
  end if;

  -- Busca próximo lead sem feedback
  select * into v_lead
  from leads
  where lote_id = v_lote.id
    and status = 'distribuido'
    and feedback is null
  order by score desc nulls last
  limit 1;

  -- Progresso do lote
  select count(*) into v_total_lote from leads where lote_id = v_lote.id;
  select count(*) into v_feedback_lote from leads where lote_id = v_lote.id and feedback is not null;

  if v_lead is null then
    return jsonb_build_object(
      'lead', null,
      'message', 'Todos os leads deste lote já receberam feedback. Aguarde verificação.',
      'progresso', jsonb_build_object('total', v_total_lote, 'feitos', v_feedback_lote)
    );
  end if;

  return jsonb_build_object(
    'lead', row_to_json(v_lead),
    'progresso', jsonb_build_object('total', v_total_lote, 'feitos', v_feedback_lote)
  );
end;
$$;

-- =============================================================
-- 10. DADOS INICIAIS (equipe)
-- =============================================================
-- ATENÇÃO: Após criar os usuários no Supabase Auth (Authentication > Users),
-- pegue o UUID de cada um e atualize aqui.
-- Exemplo:
-- insert into corretores (user_id, nome, email, is_gestor)
-- values ('UUID-DO-AUTH', 'Wagner', 'wagner@email.com', true);

-- =============================================================
-- PRONTO! Agora vá em Authentication > Users e crie os 4 usuários.
-- Depois vincule cada user_id na tabela corretores.
-- =============================================================
