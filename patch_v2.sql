-- =============================================================
-- DISCADOR — Patch v2 (rodar APÓS o setup_supabase.sql)
-- Adiciona: Produção do corretor, Avaliação de lista,
--           Carteira de leads, Gestão de listas, WhatsApp
-- Data: 2026-04-15
-- =============================================================

-- 1. CAMPO DE CARTEIRA NOS LEADS
alter table leads add column if not exists status_pos text;

-- 2. CAMPOS DE GESTÃO NAS LISTAS
alter table listas add column if not exists status text default 'ativa';
alter table listas add column if not exists nota_media numeric default 0;
alter table listas add column if not exists encerrada_em timestamptz;
alter table listas add column if not exists motivo_encerramento text;

-- 3. TABELA DE AVALIAÇÕES DE LISTA (corretores avaliam)
create table if not exists lista_avaliacoes (
  id uuid default uuid_generate_v4() primary key,
  lista_id uuid references listas(id) not null,
  corretor_id uuid references corretores(id) not null,
  nota integer not null check (nota between 1 and 5),
  comentario text,
  created_at timestamptz default now(),
  unique(lista_id, corretor_id)
);

alter table lista_avaliacoes enable row level security;
create policy "avaliacoes_select" on lista_avaliacoes for select using (true);
create policy "avaliacoes_insert" on lista_avaliacoes
  for insert with check (corretor_id = my_corretor_id());
create policy "avaliacoes_update" on lista_avaliacoes
  for update using (corretor_id = my_corretor_id());

create index if not exists idx_avaliacoes_lista on lista_avaliacoes(lista_id);

-- =============================================================
-- 4. RPC: PRODUÇÃO DO CORRETOR (tela "Minha Produção")
-- =============================================================

create or replace function minha_producao()
returns jsonb
language plpgsql security definer stable
as $$
declare
  v_cid uuid;
begin
  v_cid := my_corretor_id();
  if v_cid is null then return '{"error":"Corretor não encontrado"}'::jsonb; end if;

  return jsonb_build_object(
    'hoje', (
      select jsonb_build_object(
        'total', count(*),
        'visitas', count(*) filter (where feedback = 'agendado_visita'),
        'info', count(*) filter (where feedback = 'enviado_informacoes'),
        'nao_responde', count(*) filter (where feedback = 'nao_responde'),
        'errados', count(*) filter (where feedback = 'numero_errado'),
        'sem_interesse', count(*) filter (where feedback = 'sem_interesse'),
        'retornar', count(*) filter (where feedback = 'retornar_depois')
      )
      from leads
      where corretor_id = v_cid
        and data_feedback::date = current_date
    ),
    'semana', (
      select coalesce(jsonb_agg(row_to_json(d) order by d.dia), '[]'::jsonb)
      from (
        select
          data_feedback::date as dia,
          count(*) as total,
          count(*) filter (where feedback = 'agendado_visita') as visitas,
          count(*) filter (where feedback = 'numero_errado') as errados
        from leads
        where corretor_id = v_cid
          and data_feedback >= current_date - interval '7 days'
          and data_feedback is not null
        group by data_feedback::date
      ) d
    ),
    'lote_atual', (
      select jsonb_build_object(
        'id', lo.id,
        'total', lo.quantidade_leads,
        'feitos', lo.quantidade_feedback,
        'aberto_em', lo.data_abertura
      )
      from lotes lo
      where lo.corretor_id = v_cid and lo.status = 'aberto'
      limit 1
    ),
    'com_observacao', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', l.id, 'nome', l.nome, 'telefone', l.telefone_escolhido,
        'feedback', l.feedback, 'observacao', l.observacao_corretor,
        'data', l.data_feedback
      ) order by l.data_feedback desc), '[]'::jsonb)
      from leads l
      where l.corretor_id = v_cid
        and l.observacao_corretor is not null
        and l.observacao_corretor <> ''
      limit 20
    ),
    'carteira', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', l.id, 'nome', l.nome, 'telefone', l.telefone_escolhido,
        'whatsapp', l.whatsapp, 'feedback', l.feedback,
        'observacao', l.observacao_corretor, 'data', l.data_feedback
      ) order by l.data_feedback desc), '[]'::jsonb)
      from leads l
      where l.corretor_id = v_cid
        and l.status_pos = 'carteira'
    ),
    'totais', (
      select jsonb_build_object(
        'total_recebidos', count(*),
        'com_feedback', count(*) filter (where feedback is not null),
        'em_carteira', count(*) filter (where status_pos = 'carteira')
      )
      from leads where corretor_id = v_cid
    )
  );
end;
$$;

-- =============================================================
-- 5. ATUALIZAR registrar_feedback (adiciona carteira automática)
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
  v_status_pos text := null;
begin
  if not (p_feedback = any(v_feedbacks_validos)) then
    return jsonb_build_object('error', 'Feedback inválido');
  end if;

  v_corretor_id := my_corretor_id();
  select * into v_lead from leads where id = p_lead_id;
  if v_lead is null then return jsonb_build_object('error', 'Lead não encontrado'); end if;
  if v_lead.corretor_id <> v_corretor_id and not is_gestor() then
    return jsonb_build_object('error', 'Lead não pertence a você');
  end if;
  if v_lead.status <> 'distribuido' then
    return jsonb_build_object('error', 'Lead já processado');
  end if;

  -- Determina status_pos (carteira automática)
  if p_feedback in ('agendado_visita', 'enviado_informacoes', 'retornar_depois') then
    v_status_pos := 'carteira';
  end if;

  update leads
  set feedback = p_feedback,
      observacao_corretor = p_observacao,
      data_feedback = now(),
      status_pos = v_status_pos,
      updated_at = now()
  where id = p_lead_id;

  v_lote_id := v_lead.lote_id;

  select count(*) into v_feedbacks_count
  from leads
  where lote_id = v_lote_id and feedback = any(v_feedbacks_validos);

  update lotes set quantidade_feedback = v_feedbacks_count where id = v_lote_id;

  if v_feedbacks_count >= 25 then
    update lotes set status = 'finalizado', data_fechamento = now() where id = v_lote_id;
    update leads set status = 'finalizado', updated_at = now() where lote_id = v_lote_id;
    v_lote_fechado := true;
    insert into logs (acao, usuario_email, detalhes)
    values ('lote_fechado', '', jsonb_build_object('lote_id', v_lote_id));
  end if;

  return jsonb_build_object(
    'ok', true,
    'feedbacks_no_lote', v_feedbacks_count,
    'lote_fechado', v_lote_fechado,
    'em_carteira', v_status_pos = 'carteira'
  );
end;
$$;

-- =============================================================
-- 6. RPC: AVALIAR LISTA (corretor dá nota para a lista)
-- =============================================================

create or replace function avaliar_lista(
  p_lista_id uuid,
  p_nota integer,
  p_comentario text default ''
)
returns jsonb
language plpgsql security definer
as $$
declare
  v_cid uuid;
  v_media numeric;
begin
  v_cid := my_corretor_id();
  if v_cid is null then return '{"error":"Corretor não encontrado"}'::jsonb; end if;
  if p_nota < 1 or p_nota > 5 then return '{"error":"Nota deve ser entre 1 e 5"}'::jsonb; end if;

  insert into lista_avaliacoes (lista_id, corretor_id, nota, comentario)
  values (p_lista_id, v_cid, p_nota, p_comentario)
  on conflict (lista_id, corretor_id)
  do update set nota = p_nota, comentario = p_comentario, created_at = now();

  select round(avg(nota), 1) into v_media
  from lista_avaliacoes where lista_id = p_lista_id;

  update listas set nota_media = v_media where id = p_lista_id;

  return jsonb_build_object('ok', true, 'nota_media', v_media);
end;
$$;

-- =============================================================
-- 7. RPC: GESTÃO DE LISTAS (gestora pausa/encerra)
-- =============================================================

create or replace function gerenciar_lista(
  p_lista_id uuid,
  p_acao text,
  p_motivo text default ''
)
returns jsonb
language plpgsql security definer
as $$
begin
  if not is_gestor() then return '{"error":"Apenas gestor"}'::jsonb; end if;

  if p_acao = 'pausar' then
    update listas set status = 'pausada' where id = p_lista_id;
    -- Leads disponíveis desta lista ficam bloqueados
    update leads set status = 'invalido'
    where lista_id = p_lista_id and status = 'disponivel';
  elsif p_acao = 'reativar' then
    update listas set status = 'ativa' where id = p_lista_id;
  elsif p_acao = 'encerrar' then
    update listas set status = 'encerrada', encerrada_em = now(), motivo_encerramento = p_motivo
    where id = p_lista_id;
    update leads set status = 'invalido'
    where lista_id = p_lista_id and status = 'disponivel';
  end if;

  insert into logs (acao, usuario_email, detalhes)
  values ('gestao_lista', '', jsonb_build_object('lista_id', p_lista_id, 'acao', p_acao, 'motivo', p_motivo));

  return jsonb_build_object('ok', true);
end;
$$;

-- =============================================================
-- 8. RPC: RELATÓRIO DO FORNECEDOR (para gestora exportar)
-- =============================================================

create or replace function relatorio_fornecedor(p_lista_id uuid)
returns jsonb
language plpgsql security definer stable
as $$
begin
  if not is_gestor() then return '{"error":"Apenas gestor"}'::jsonb; end if;

  return (
    select jsonb_build_object(
      'lista', jsonb_build_object(
        'fornecedor', li.nome_fornecedor,
        'arquivo', li.nome_arquivo,
        'data_upload', li.created_at,
        'status', li.status,
        'nota_media', li.nota_media
      ),
      'numeros', (
        select jsonb_build_object(
          'total', count(*),
          'validos', count(*) filter (where l.status <> 'invalido' or l.feedback is not null),
          'invalidos', count(*) filter (where l.status = 'invalido' and l.feedback is null),
          'com_feedback', count(*) filter (where l.feedback is not null),
          'agendado_visita', count(*) filter (where l.feedback = 'agendado_visita'),
          'enviado_info', count(*) filter (where l.feedback = 'enviado_informacoes'),
          'sem_interesse', count(*) filter (where l.feedback = 'sem_interesse'),
          'nao_responde', count(*) filter (where l.feedback = 'nao_responde'),
          'numero_errado', count(*) filter (where l.feedback = 'numero_errado'),
          'caixa_postal', count(*) filter (where l.feedback = 'caixa_postal'),
          'nao_toca', count(*) filter (where l.feedback = 'nao_toca'),
          'taxa_contato_pct', round(
            count(*) filter (where l.feedback in ('agendado_visita','enviado_informacoes','sem_interesse','retornar_depois'))::numeric
            / nullif(count(*) filter (where l.feedback is not null), 0) * 100, 1
          ),
          'taxa_erro_pct', round(
            count(*) filter (where l.feedback in ('numero_errado','caixa_postal','nao_toca'))::numeric
            / nullif(count(*) filter (where l.feedback is not null), 0) * 100, 1
          ),
          'taxa_visita_pct', round(
            count(*) filter (where l.feedback = 'agendado_visita')::numeric
            / nullif(count(*) filter (where l.feedback is not null), 0) * 100, 1
          )
        )
        from leads l where l.lista_id = p_lista_id
      ),
      'avaliacoes', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'corretor', c.nome, 'nota', a.nota, 'comentario', a.comentario
        )), '[]'::jsonb)
        from lista_avaliacoes a
        join corretores c on c.id = a.corretor_id
        where a.lista_id = p_lista_id
      )
    )
    from listas li where li.id = p_lista_id
  );
end;
$$;

-- =============================================================
-- 9. ATUALIZAR DASHBOARD (incluir qualidade de listas)
-- =============================================================

create or replace function get_dashboard_stats()
returns jsonb
language plpgsql security definer stable
as $$
begin
  return jsonb_build_object(
    'total_leads', (select count(*) from leads),
    'disponiveis', (select count(*) from leads where status = 'disponivel'),
    'distribuidos', (select count(*) from leads where status = 'distribuido'),
    'finalizados', (select count(*) from leads where status = 'finalizado'),
    'invalidos', (select count(*) from leads where status = 'invalido'),
    'em_carteira', (select count(*) from leads where status_pos = 'carteira'),
    'lotes_abertos', (select count(*) from lotes where status = 'aberto'),
    'lotes_fechados', (select count(*) from lotes where status = 'finalizado'),
    'corretores_ativos', (select count(*) from corretores where ativo = true),
    'por_corretor', (
      select coalesce(jsonb_agg(row_to_json(sub) order by sub.nome), '[]'::jsonb)
      from (
        select c.nome,
          count(l.id) as total_leads,
          count(case when l.feedback = 'agendado_visita' then 1 end) as visitas,
          count(case when l.feedback = 'enviado_informacoes' then 1 end) as informacoes,
          count(case when l.feedback = 'nao_responde' then 1 end) as nao_responde,
          count(case when l.feedback = 'numero_errado' then 1 end) as numero_errado,
          count(case when l.feedback = 'sem_interesse' then 1 end) as sem_interesse,
          count(case when l.feedback is not null then 1 end) as com_feedback,
          count(case when l.status_pos = 'carteira' then 1 end) as em_carteira,
          round(count(case when l.feedback = 'agendado_visita' then 1 end)::numeric
            / nullif(count(case when l.feedback is not null then 1 end), 0) * 100, 1) as taxa_visita
        from corretores c left join leads l on l.corretor_id = c.id
        where c.ativo = true group by c.nome
      ) sub
    ),
    'por_fornecedor', (
      select coalesce(jsonb_agg(row_to_json(sub) order by sub.nota_media desc nulls last), '[]'::jsonb)
      from (
        select
          li.id as lista_id,
          li.nome_fornecedor as fornecedor,
          li.status as status_lista,
          li.nota_media,
          li.created_at as data_upload,
          count(l.id) as total,
          count(case when l.feedback = 'agendado_visita' then 1 end) as visitas,
          count(case when l.feedback = 'numero_errado' then 1 end) as errados,
          round(count(case when l.feedback = 'numero_errado' then 1 end)::numeric
            / nullif(count(l.id), 0) * 100, 1) as taxa_erro,
          round(count(case when l.feedback = 'agendado_visita' then 1 end)::numeric
            / nullif(count(case when l.feedback is not null then 1 end), 0) * 100, 1) as taxa_visita
        from listas li left join leads l on l.lista_id = li.id
        group by li.id, li.nome_fornecedor, li.status, li.nota_media, li.created_at
      ) sub
    ),
    'feedbacks', (
      select coalesce(jsonb_object_agg(f, c), '{}'::jsonb)
      from (select feedback as f, count(*) as c from leads where feedback is not null group by feedback) sub
    )
  );
end;
$$;

-- PRONTO! Execute este patch após o setup_supabase.sql
