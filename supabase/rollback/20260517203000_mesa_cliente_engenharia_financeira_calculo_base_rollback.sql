-- Rollback — MesaCliente Engenharia Financeira Fase 3A: Funções base de cálculo composto
-- Migration relacionada:
-- supabase/migrations/20260517203000_mesa_cliente_engenharia_financeira_calculo_base.sql
--
-- Objetivo:
--   Remover as funções puras de cálculo financeiro composto criadas na Fase 3A.
--
-- O que este rollback faz:
--   - Remove funções de validação, fator composto, valor presente/futuro,
--     antecipação, postergação e VPL de parcela.
--
-- O que este rollback NÃO faz:
--   - Não remove tabelas financeiras.
--   - Não remove RPCs administrativas.
--   - Não altera RLS.
--   - Não altera parser, motor financeiro atual, Worker, Make ou front.

begin;

drop function if exists public.mesa_cliente_financeiro_calcular_vpl_parcela(numeric, date, date, numeric, text);
drop function if exists public.mesa_cliente_financeiro_calcular_postergacao_composta(numeric, date, date, numeric, text);
drop function if exists public.mesa_cliente_financeiro_calcular_antecipacao_composta(numeric, date, date, numeric, text);
drop function if exists public.mesa_cliente_financeiro_valor_futuro_composto(numeric, numeric, integer, text);
drop function if exists public.mesa_cliente_financeiro_valor_presente_composto(numeric, numeric, integer, text);
drop function if exists public.mesa_cliente_financeiro_fator_composto(numeric, integer, text);
drop function if exists public.mesa_cliente_financeiro_dias_entre(date, date);
drop function if exists public.mesa_cliente_financeiro_assert_calculo_input(numeric, numeric, text);

commit;
