-- MesaCliente Engenharia Financeira — 05B Validação de exceções das funções base de cálculo
-- Branch: feature/mesa-cliente-engenharia-financeira
--
-- Objetivo:
--   Validar explicitamente que inputs inválidos são bloqueados pelas funções base.
--
-- Segurança:
--   - Não cria dados de negócio.
--   - Não altera schema permanente.
--   - Usa função temporária pg_temp dentro de transação.
--   - Finaliza com ROLLBACK.
--
-- Resultado esperado:
--   01_valor_negativo_bloqueado          PASS
--   02_taxa_negativa_bloqueada           PASS
--   03_taxa_acima_100_bloqueada          PASS
--   04_base_tempo_invalida_bloqueada     PASS
--   05_data_base_nula_bloqueada          PASS
--   06_data_alvo_nula_bloqueada          PASS
--   07_data_original_nula_bloqueada      PASS
--   08_data_nova_nula_bloqueada          PASS
--   09_funcoes_validas_continuam_ok      PASS
--   10_rollback_notice                   INFO

begin;

create or replace function pg_temp.capture_error(
  p_sql text
)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_sqlstate text;
  v_message text;
begin
  begin
    execute p_sql;
    return jsonb_build_object(
      'erro_capturado', false,
      'sqlstate', null,
      'message', null
    );
  exception when others then
    get stacked diagnostics
      v_sqlstate = returned_sqlstate,
      v_message = message_text;

    return jsonb_build_object(
      'erro_capturado', true,
      'sqlstate', v_sqlstate,
      'message', v_message
    );
  end;
end;
$$;

with tests as (
  select
    pg_temp.capture_error($sql$
      select public.mesa_cliente_financeiro_valor_presente_composto(-1, 12, 365, 'dias_365')
    $sql$) as valor_negativo,

    pg_temp.capture_error($sql$
      select public.mesa_cliente_financeiro_valor_presente_composto(100000, -1, 365, 'dias_365')
    $sql$) as taxa_negativa,

    pg_temp.capture_error($sql$
      select public.mesa_cliente_financeiro_valor_presente_composto(100000, 101, 365, 'dias_365')
    $sql$) as taxa_acima_100,

    pg_temp.capture_error($sql$
      select public.mesa_cliente_financeiro_valor_presente_composto(100000, 12, 365, 'dias_360')
    $sql$) as base_tempo_invalida,

    pg_temp.capture_error($sql$
      select public.mesa_cliente_financeiro_dias_entre(null::date, date '2027-01-01')
    $sql$) as data_base_nula,

    pg_temp.capture_error($sql$
      select public.mesa_cliente_financeiro_dias_entre(date '2026-01-01', null::date)
    $sql$) as data_alvo_nula,

    pg_temp.capture_error($sql$
      select public.mesa_cliente_financeiro_calcular_antecipacao_composta(100000, null::date, date '2026-01-01', 12, 'dias_365')
    $sql$) as data_original_nula,

    pg_temp.capture_error($sql$
      select public.mesa_cliente_financeiro_calcular_postergacao_composta(100000, date '2026-01-01', null::date, 12, 'dias_365')
    $sql$) as data_nova_nula,

    public.mesa_cliente_financeiro_valor_presente_composto(100000, 12, 365, 'dias_365') as vp_ok,
    public.mesa_cliente_financeiro_valor_futuro_composto(100000, 12, 365, 'dias_365') as vf_ok
)
select
  '01_valor_negativo_bloqueado' as bloco,
  case when (valor_negativo->>'erro_capturado')::boolean is true and valor_negativo->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end as status,
  valor_negativo as detalhe
from tests

union all

select
  '02_taxa_negativa_bloqueada' as bloco,
  case when (taxa_negativa->>'erro_capturado')::boolean is true and taxa_negativa->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end as status,
  taxa_negativa as detalhe
from tests

union all

select
  '03_taxa_acima_100_bloqueada' as bloco,
  case when (taxa_acima_100->>'erro_capturado')::boolean is true and taxa_acima_100->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end as status,
  taxa_acima_100 as detalhe
from tests

union all

select
  '04_base_tempo_invalida_bloqueada' as bloco,
  case when (base_tempo_invalida->>'erro_capturado')::boolean is true and base_tempo_invalida->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end as status,
  base_tempo_invalida as detalhe
from tests

union all

select
  '05_data_base_nula_bloqueada' as bloco,
  case when (data_base_nula->>'erro_capturado')::boolean is true and data_base_nula->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end as status,
  data_base_nula as detalhe
from tests

union all

select
  '06_data_alvo_nula_bloqueada' as bloco,
  case when (data_alvo_nula->>'erro_capturado')::boolean is true and data_alvo_nula->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end as status,
  data_alvo_nula as detalhe
from tests

union all

select
  '07_data_original_nula_bloqueada' as bloco,
  case when (data_original_nula->>'erro_capturado')::boolean is true and data_original_nula->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end as status,
  data_original_nula as detalhe
from tests

union all

select
  '08_data_nova_nula_bloqueada' as bloco,
  case when (data_nova_nula->>'erro_capturado')::boolean is true and data_nova_nula->>'sqlstate' = '22023' then 'PASS' else 'FAIL' end as status,
  data_nova_nula as detalhe
from tests

union all

select
  '09_funcoes_validas_continuam_ok' as bloco,
  case when vp_ok = 89285.71 and vf_ok = 112000.00 then 'PASS' else 'FAIL' end as status,
  jsonb_build_object(
    'valor_presente_ok', vp_ok,
    'valor_futuro_ok', vf_ok
  ) as detalhe
from tests

union all

select
  '10_rollback_notice' as bloco,
  'INFO' as status,
  jsonb_build_object(
    'mensagem', 'A função pg_temp.capture_error será descartada automaticamente; a transação termina com ROLLBACK.'
  ) as detalhe;

rollback;
