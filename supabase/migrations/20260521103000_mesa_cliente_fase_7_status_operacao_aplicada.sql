-- FECH.AI / MesaCliente
-- Engenharia Financeira — Fase 7
-- Migration: permitir status_operacao='aplicada' em mesa_cliente_fluxo_operacoes.
--
-- Contexto:
--   A Fase 7 introduz a aplicação real de uma operação financeira na agenda.
--   Para representar corretamente o estado canônico da operação após a aplicação,
--   a constraint de status_operacao deve permitir o estado 'aplicada'.
--
-- Escopo desta migration:
--   - alterar exclusivamente a constraint de status_operacao;
--   - não criar RPC;
--   - não executar DML;
--   - não alterar dados existentes;
--   - não alterar parser, motor financeiro, Worker/Make/n8n ou UI.

alter table public.mesa_cliente_fluxo_operacoes
  drop constraint if exists mesa_cliente_fluxo_operacoes_status_operacao_check;

alter table public.mesa_cliente_fluxo_operacoes
  add constraint mesa_cliente_fluxo_operacoes_status_operacao_check
  check (
    status_operacao = any (
      array[
        'simulada'::text,
        'confirmada'::text,
        'aplicada'::text,
        'cancelada'::text,
        'bloqueada'::text
      ]
    )
  );

comment on constraint mesa_cliente_fluxo_operacoes_status_operacao_check
on public.mesa_cliente_fluxo_operacoes
is 'Estados permitidos da operação financeira do MesaCliente. Fase 7 adiciona aplicada para representar operação efetivada na agenda.';
