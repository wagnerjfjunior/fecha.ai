# FECH.AI / MesaCliente — Smoke Pós-Produção da Fase 5C

## Objetivo

Validar, após o merge da Fase 5C na `main`, que a camada administrativa de confirmação e cancelamento de operação financeira está aplicada em produção.

O smoke é somente leitura e não executa confirmação/cancelamento.

## Arquivo SQL

```text
supabase/tests/mesa-cliente/engenharia-financeira/12_smoke_pos_producao_fase_5c_readonly.sql
```

## Blocos esperados

```text
01_colunas_cancelamento_existem = PASS
02_rpc_5c_existe_assinatura_correta = PASS
03_grants_restritos = PASS
04_rls_operacoes_ativo = PASS
05_status_operacao_suporta_5c = PASS
06_comentarios_colunas_5c_presentes = PASS
07_snapshot_readonly_operacoes = INFO
99_veredito_smoke_pos_producao_5c = PASS
```

## O que valida

- colunas `cancelado_por`, `cancelado_em`, `motivo_cancelamento`;
- RPC `mesa_cliente_atualizar_status_operacao_financeira_admin`;
- grants `anon=false`, `authenticated=true`, `public=false`;
- RLS ativo em `mesa_cliente_fluxo_operacoes`;
- suporte aos status `simulada`, `confirmada`, `cancelada`, `bloqueada`;
- comentários técnicos 5C nas colunas;
- snapshot informativo das operações.

## Observação

O bloco `07_snapshot_readonly_operacoes` é informativo. Ele não define sucesso ou falha do smoke.

## Próximo passo

Com o smoke aprovado, abrir contrato da Fase 5D — leitura/consulta administrativa das operações financeiras.
