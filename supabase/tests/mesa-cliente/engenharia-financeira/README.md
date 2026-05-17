# MesaCliente Engenharia Financeira — Execução segura com banco único de produção

Este diretório contém scripts de validação para o módulo de Engenharia Financeira do MesaCliente.

## Contexto operacional

O projeto possui somente um Supabase disponível no momento: o banco de produção.

Por isso, os testes integradores que criam dados temporários devem ser tratados com muito cuidado e **não devem ser executados em produção sem uma decisão explícita de janela controlada**.

Para produção única, o fluxo seguro é:

1. Rodar preflight somente leitura.
2. Fazer backup/snapshot pelo Supabase antes de qualquer DDL.
3. Aplicar a migration de hardening em janela controlada.
4. Rodar postcheck somente leitura.
5. Só depois avançar para RPCs.

## Scripts deste diretório

### `00_preflight_producao_readonly.sql`

Uso: antes da migration.

Características:

- Somente `SELECT`.
- Não cria dados.
- Não altera schema.
- Seguro para SQL Editor da produção.

Valida:

- tabelas obrigatórias existentes;
- funções obrigatórias existentes;
- RLS atual nas 4 tabelas financeiras;
- contagem de policies atuais;
- sinal de duplicidade de policies;
- triggers de hardening antes da migration;
- grants atuais para `anon` e escrita direta de `authenticated`.

### `01_postcheck_producao_readonly.sql`

Uso: depois da migration.

Características:

- Somente `SELECT`.
- Não cria dados.
- Não altera schema.
- Seguro para SQL Editor da produção.

Resultado esperado:

Todos os blocos críticos devem retornar `PASS`:

- `01_rls_enabled`
- `02_canonical_policies`
- `03_legacy_policies_removed`
- `04_integrity_triggers`
- `05_integrity_function`
- `06_anon_has_no_privileges`
- `07_authenticated_has_no_direct_write_grants`

## Script integrador original

Existe também o arquivo:

`supabase/tests/mesa_cliente_engenharia_financeira_hardening_test.sql`

Esse arquivo cria dados temporários dentro de transação e finaliza com `ROLLBACK`.

Ele é útil para DEV/staging/local, mas **não é recomendado para produção única** sem janela controlada e backup prévio.

## Migration relacionada

`supabase/migrations/20260517162000_mesa_cliente_engenharia_financeira_hardening.sql`

Essa migration:

- consolida policies;
- bloqueia escrita direta;
- remove duplicidades de policies/índices;
- cria trigger/função de integridade multitenant;
- preserva a premissa de banco/RPC soberano e front consultivo.

## Ordem segura para produção única

```text
1. Rodar 00_preflight_producao_readonly.sql
2. Conferir resultado
3. Fazer backup/snapshot no Supabase
4. Aplicar 20260517162000_mesa_cliente_engenharia_financeira_hardening.sql
5. Rodar 01_postcheck_producao_readonly.sql
6. Se tudo PASS, iniciar próxima fase: RPCs soberanas
```

## Regra de ouro

Não aplicar novas RPCs, telas ou cálculos antes do postcheck passar.

Produção não é laboratório. Produção é centro cirúrgico: entra com checklist, luva e plano de reversão.
