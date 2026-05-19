# MesaCliente — Fase 4A: Agenda Financeira — handoff substituído

**Status:** Substituído / obsoleto para execução  
**Data da substituição:** 2026-05-18  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  

---

## Aviso obrigatório

Este documento foi preservado apenas como histórico técnico da discussão da Fase 4A.

Ele **não deve mais ser usado como contrato de execução**, porque descrevia a Fase 4A com persistência em `mesa_cliente_fluxo_parcelas`.

A decisão oficial posterior consolidou que:

```txt
4A = gerar agenda financeira em JSON, sem persistir
4B = persistir agenda com lock, idempotência e auditoria
4C = leitura cliente-safe
```

Portanto, qualquer trecho antigo que mencione `INSERT`, `UPDATE`, `DELETE`, recriação ou persistência de agenda na Fase 4A está substituído.

---

## Fonte canônica atual

A execução oficial deve seguir estes arquivos:

```txt
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md
docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md
```

---

## Regra definitiva da Fase 4A

A Fase 4A é **Dry-run / JSON-first**.

Ela não pode fazer:

- `INSERT` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` em `mesa_cliente_fluxo_parcelas`;
- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `INSERT` em `mesa_cliente_fluxo_operacoes`;
- `UPDATE` em `mesa_cliente_fluxo_operacoes`;
- `DELETE` em `mesa_cliente_fluxo_operacoes`;
- criação de operação financeira;
- confirmação/cancelamento de operação;
- cálculo ou exposição de VPL;
- cálculo ou exposição de prêmio;
- cálculo ou exposição de comissão;
- exposição de política interna;
- alteração de frontend;
- alteração de parser;
- alteração de Worker/Make/n8n;
- `EXECUTE` para `anon`;
- uso de `empresa_id` do frontend/payload como autoridade.

---

## RPC oficial da Fase 4A

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

A RPC deve retornar agenda financeira normalizada em JSON, com `cliente_safe = false`, sem dados sensíveis e sem DML financeiro.

---

## Critério obrigatório de teste

Os testes da Fase 4A devem provar:

```txt
count_before = count_after
```

Nas tabelas:

```sql
select count(*) from public.mesa_cliente_fluxo_parcelas;
select count(*) from public.mesa_cliente_fluxo_operacoes;
```

Se qualquer contagem mudar, a Fase 4A falhou.

---

## Decisão

Este arquivo não deve mais orientar implementação. Ele apenas registra o histórico da decisão que levou ao contrato canônico JSON-first.

Para qualquer implementação nova, usar exclusivamente o contrato canônico da Fase 4A.
