-- MesaCliente Engenharia Financeira — 04 Validação funcional das RPCs administrativas com ROLLBACK
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Validar, em produção única e com rollback, se as RPCs administrativas conseguem:
--   - criar/atualizar uma política financeira fictícia futura;
--   - cadastrar faixas de prêmio;
--   - listar a política criada dentro da transação;
--   - obter a política completa com suas faixas;
--   - manter escrita direta bloqueada para authenticated;
--   - desfazer tudo ao final com ROLLBACK.
--
-- Segurança:
--   - Usa uma transação explícita.
--   - Finaliza com ROLLBACK.
--   - Não altera parser, motor financeiro atual, Worker, Make ou front.
--   - Não deve ser executado sem confirmação operacional, mesmo sendo transacional.
--
-- Observação importante:
--   O script usa um mês futuro de teste: 2099-01-01.
--   Se por algum motivo já existir política real nesse mês para o empreendimento escolhido,
--   o teste será abortado antes do upsert para evitar tocar em dado real.
--
-- Resultado esperado:
--   - 01_admin_candidate: PASS
--   - 02_empreendimento_candidate: PASS
--   - 03_no_policy_conflict_for_test_month: PASS
--   - 04_upsert_politica_rpc: PASS
--   - 05_upsert_faixas_rpc: PASS
--   - 06_listar_politica_criada: PASS
--   - 07_obter_politica_com_faixas: PASS
--   - 08_direct_write_still_blocked: PASS
--   - 09_rollback_notice: INFO

begin;

-- -----------------------------------------------------------------------------
-- 1. Simular sessão authenticated com usuário admin/gestor existente
-- -----------------------------------------------------------------------------

select set_config(
  'request.jwt.claim.sub',
  coalesce((
    select c.user_id::text
    from public.corretores c
    where c.user_id is not null
      and coalesce(c.ativo, true) = true
      and (
        c.role in ('admin_global', 'admin_local', 'gestor')
        or coalesce(c.is_admin_local, false) = true
        or coalesce(c.is_gestor, false) = true
      )
    order by
      case c.role
        when 'admin_global' then 1
        when 'admin_local' then 2
        when 'gestor' then 3
        else 4
      end,
      c.created_at nulls last,
      c.id
    limit 1
  ), '00000000-0000-0000-0000-000000000000'),
  true
) as simulated_auth_uid;

set local role authenticated;

-- -----------------------------------------------------------------------------
-- 2. Helpers temporários para teste
-- -----------------------------------------------------------------------------

create or replace function pg_temp.expect_error(
  p_sql text,
  p_context text
)
returns boolean
language plpgsql
security invoker
as $$
declare
  v_error_ok boolean := false;
begin
  begin
    execute p_sql;
  exception when others then
    v_error_ok := true;
  end;

  return v_error_ok;
end;
$$;

with ctx as materialized (
  select *
  from public.mesa_cliente_current_corretor_context()
), empresa_ctx as (
  select
    (array_agg(user_id))[1] as user_id,
    (array_agg(corretor_id))[1] as corretor_id,
    (array_agg(empresa_id))[1] as empresa_id,
    (array_agg(role))[1] as role,
    bool_or(coalesce(ativo, false)) as ativo,
    count(*) as qtd_ctx
  from ctx
), empreendimento_alvo as materialized (
  select
    e.id as empreendimento_id,
    e.empresa_id,
    e.nome as empreendimento_nome
  from public.empreendimentos e
  join empresa_ctx ec on ec.empresa_id = e.empresa_id
  order by e.created_at nulls last, e.id
  limit 1
), conflito_mes_teste as (
  select
    count(*) as qtd_conflitos
  from public.mesa_cliente_politicas_financeiras p
  join empreendimento_alvo ea on ea.empreendimento_id = p.empreendimento_id
  where p.empresa_id = ea.empresa_id
    and p.mes_referencia = date '2099-01-01'
), pode_executar as (
  select
    ec.user_id,
    ec.corretor_id,
    ec.empresa_id,
    ec.role,
    ec.ativo,
    ec.qtd_ctx,
    ea.empreendimento_id,
    ea.empreendimento_nome,
    coalesce(cmt.qtd_conflitos, 0) as qtd_conflitos,
    public.mesa_cliente_can_admin_empresa(ec.empresa_id) as can_admin_empresa
  from empresa_ctx ec
  left join empreendimento_alvo ea on true
  left join conflito_mes_teste cmt on true
), upsert_politica as materialized (
  select
    case
      when pe.qtd_ctx = 1
       and pe.ativo is true
       and pe.can_admin_empresa is true
       and pe.empreendimento_id is not null
       and pe.qtd_conflitos = 0
      then public.mesa_cliente_upsert_politica_financeira(
        p_empresa_id => pe.empresa_id,
        p_empreendimento_id => pe.empreendimento_id,
        p_mes_referencia => date '2099-01-15',
        p_vigencia_inicio => date '2099-01-01',
        p_vigencia_fim => date '2099-01-31',
        p_vpl_max_pct => 6.00,
        p_taxa_antecipacao_ano_pct => 12.00,
        p_taxa_postergacao_ano_pct => 12.00,
        p_metodo_calculo => 'composto',
        p_base_tempo => 'dias_365',
        p_permite_vpl_financiamento => false,
        p_permite_vpl_chaves => true,
        p_permite_vpl_anuais => true,
        p_permite_vpl_mensais => true,
        p_permite_antecipacao_financiamento => false,
        p_permite_antecipacao_chaves => true,
        p_permite_antecipacao_anuais => true,
        p_permite_antecipacao_mensais => true,
        p_permite_postergacao_financiamento => false,
        p_permite_postergacao_chaves => true,
        p_permite_postergacao_anuais => true,
        p_permite_postergacao_mensais => true,
        p_ativo => true,
        p_observacoes => 'TESTE TRANSACIONAL FECH.AI — rollback automático'
      )
      else null::jsonb
    end as payload
  from pode_executar pe
), politica_criada as (
  select
    (payload->'politica'->>'id')::uuid as politica_id,
    (payload->'politica'->>'empresa_id')::uuid as empresa_id,
    (payload->'politica'->>'empreendimento_id')::uuid as empreendimento_id,
    (payload->'politica'->>'mes_referencia')::date as mes_referencia,
    payload as payload_politica
  from upsert_politica
  where payload is not null
), upsert_faixas as materialized (
  select
    case
      when pc.politica_id is not null then public.mesa_cliente_upsert_faixas_premio(
        p_empresa_id => pc.empresa_id,
        p_politica_id => pc.politica_id,
        p_faixas => jsonb_build_array(
          jsonb_build_object(
            'vpl_de_pct', 0,
            'vpl_ate_pct', 3,
            'premio_corretor_pct', 2,
            'status', 'premio_cheio',
            'descricao', 'Teste rollback: prêmio cheio até 3%',
            'ordem', 1,
            'ativo', true
          ),
          jsonb_build_object(
            'vpl_de_pct', 3.01,
            'vpl_ate_pct', 6,
            'premio_corretor_pct', 1,
            'status', 'premio_parcial',
            'descricao', 'Teste rollback: prêmio parcial até limite da política',
            'ordem', 2,
            'ativo', true
          )
        )
      )
      else null::jsonb
    end as payload
  from politica_criada pc
), listar_politica_criada as materialized (
  select l.*
  from politica_criada pc
  cross join lateral public.mesa_cliente_listar_politicas_financeiras(
    pc.empresa_id,
    pc.empreendimento_id,
    false,
    50,
    0
  ) l
  where l.id = pc.politica_id
), obter_politica_final as materialized (
  select
    public.mesa_cliente_obter_politica_financeira(pc.politica_id, pc.empresa_id) as payload
  from politica_criada pc
), direct_write_check as (
  select
    pg_temp.expect_error(
      format(
        $sql$
        insert into public.mesa_cliente_politicas_financeiras (
          empresa_id,
          empreendimento_id,
          mes_referencia,
          vigencia_inicio,
          vigencia_fim,
          vpl_max_pct,
          taxa_antecipacao_ano_pct,
          taxa_postergacao_ano_pct,
          metodo_calculo,
          base_tempo,
          observacoes
        ) values (
          %L::uuid,
          %L::uuid,
          date '2099-02-01',
          date '2099-02-01',
          date '2099-02-28',
          6,
          12,
          12,
          'composto',
          'dias_365',
          'Tentativa direta deve falhar'
        )
        $sql$,
        pe.empresa_id,
        pe.empreendimento_id
      ),
      'authenticated não pode inserir política diretamente'
    ) as direct_write_blocked
  from pode_executar pe
  where pe.empresa_id is not null
    and pe.empreendimento_id is not null
)
select
  '01_admin_candidate' as bloco,
  case
    when pe.qtd_ctx = 1 and pe.ativo is true and pe.can_admin_empresa is true then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'user_id', pe.user_id,
    'corretor_id', pe.corretor_id,
    'empresa_id', pe.empresa_id,
    'role', pe.role,
    'ativo', pe.ativo,
    'can_admin_empresa', pe.can_admin_empresa
  ) as detalhe
from pode_executar pe

union all

select
  '02_empreendimento_candidate' as bloco,
  case
    when pe.empreendimento_id is not null then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'empresa_id', pe.empresa_id,
    'empreendimento_id', pe.empreendimento_id,
    'empreendimento_nome', pe.empreendimento_nome
  ) as detalhe
from pode_executar pe

union all

select
  '03_no_policy_conflict_for_test_month' as bloco,
  case
    when pe.qtd_conflitos = 0 then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'mensagem', 'Deve ser 0 para evitar update em política real existente no mês futuro de teste.',
    'mes_teste', '2099-01-01',
    'qtd_conflitos', pe.qtd_conflitos
  ) as detalhe
from pode_executar pe

union all

select
  '04_upsert_politica_rpc' as bloco,
  case
    when pc.politica_id is not null
     and pc.mes_referencia = date '2099-01-01'
    then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'politica_id', pc.politica_id,
    'empresa_id', pc.empresa_id,
    'empreendimento_id', pc.empreendimento_id,
    'mes_referencia', pc.mes_referencia,
    'payload_politica', pc.payload_politica
  ) as detalhe
from politica_criada pc

union all

select
  '05_upsert_faixas_rpc' as bloco,
  case
    when jsonb_array_length(coalesce(uf.payload->'faixas_premio', '[]'::jsonb)) = 2 then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'qtd_faixas', jsonb_array_length(coalesce(uf.payload->'faixas_premio', '[]'::jsonb)),
    'payload_com_faixas', uf.payload
  ) as detalhe
from upsert_faixas uf

union all

select
  '06_listar_politica_criada' as bloco,
  case
    when count(*) = 1 then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'qtd_registros_listados', count(*),
    'politicas', coalesce(jsonb_agg(jsonb_build_object(
      'id', id,
      'empresa_id', empresa_id,
      'empreendimento_id', empreendimento_id,
      'mes_referencia', mes_referencia,
      'qtd_faixas_premio', qtd_faixas_premio
    )), '[]'::jsonb)
  ) as detalhe
from listar_politica_criada

union all

select
  '07_obter_politica_com_faixas' as bloco,
  case
    when jsonb_array_length(coalesce(opf.payload->'faixas_premio', '[]'::jsonb)) = 2 then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'qtd_faixas', jsonb_array_length(coalesce(opf.payload->'faixas_premio', '[]'::jsonb)),
    'payload_obter', opf.payload
  ) as detalhe
from obter_politica_final opf

union all

select
  '08_direct_write_still_blocked' as bloco,
  case
    when coalesce(dwc.direct_write_blocked, false) is true then 'PASS'
    else 'FAIL'
  end as status,
  jsonb_build_object(
    'mensagem', 'Confirma que authenticated continua sem INSERT direto em mesa_cliente_politicas_financeiras.',
    'direct_write_blocked', coalesce(dwc.direct_write_blocked, false)
  ) as detalhe
from direct_write_check dwc

union all

select
  '09_rollback_notice' as bloco,
  'INFO' as status,
  jsonb_build_object(
    'mensagem', 'Todos os dados criados nesta validação serão desfeitos pelo ROLLBACK ao final do script.',
    'mes_teste', '2099-01-01'
  ) as detalhe;

rollback;
