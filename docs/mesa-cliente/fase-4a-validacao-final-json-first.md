# MesaCliente — Fase 4A — Validação Final JSON-first

## Status

**Fase 4A validada tecnicamente.**

Este documento registra a evidência operacional da validação da Fase 4A da Engenharia Financeira do MesaCliente, conforme o contrato JSON-first, sem persistência financeira.

## Fontes normativas

Este documento não substitui as fontes superiores. Ele registra a evidência final da execução.

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`
4. `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md`

## Decisão arquitetural validada

A Fase 4A é exclusivamente **dry-run / JSON-first**.

A Fase 4A:

- gera agenda financeira em JSON;
- não grava agenda financeira;
- não cria operação financeira;
- não altera o frontend;
- não altera parser;
- não altera Worker, Make ou n8n;
- não expõe visão cliente-safe;
- não expõe VPL, prêmio, comissão ou política interna;
- não aceita `empresa_id` soberano vindo do frontend/payload;
- não concede `EXECUTE` para `anon`.

Frase de controle:

> Primeiro contrato. Depois validação. Depois dry-run. Depois persistência.

## Migration canônica aplicada

Arquivo:

```txt
supabase/migrations/20260518120000_mesa_cliente_fase_4a_agenda_financeira_json_first.sql
```

Commit de criação:

```txt
4a82a650dca6d33ca50b17c956df8c6942c2c43a
```

A migration criou a RPC oficial:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

## RPC validada no Supabase

Resultado validado:

```json
[
  {
    "section": "06_rpc_json_first_status",
    "function_name": "mesa_cliente_gerar_agenda_financeira_admin",
    "arguments": "p_simulacao_id uuid, p_data_ato date, p_fluxo_json jsonb, p_payload_tabela jsonb",
    "security_definer": true,
    "volatility": "stable",
    "anon_can_execute": false,
    "authenticated_can_execute": true
  }
]
```

Interpretação:

- RPC existe no banco;
- assinatura está correta;
- `security_definer = true`;
- `set search_path = public` foi definido na migration;
- `anon` não executa;
- `authenticated` executa;
- grants estão alinhados ao contrato.

## Segurança da tabela `mesa_simulacoes`

Antes de rodar testes com fixture transacional, foi validado que `mesa_simulacoes` possui RLS ativo e forçado.

Resultado:

```json
[
  {
    "section": "01_rls_mesa_simulacoes",
    "table_name": "mesa_simulacoes",
    "rls_enabled": true,
    "rls_forced": true
  }
]
```

Policy existente:

```json
[
  {
    "section": "02_policies_mesa_simulacoes",
    "schemaname": "public",
    "tablename": "mesa_simulacoes",
    "policyname": "mesa_simulacoes_select",
    "cmd": "SELECT",
    "roles": "{authenticated}",
    "qual": "(is_root() OR (empresa_id = my_empresa_id()))",
    "with_check": null
  }
]
```

Grants relevantes:

- `anon`: sem grant direto encontrado;
- `authenticated`: sem grant direto de tabela encontrado;
- `postgres`: permissões administrativas;
- `service_role`: permissões administrativas.

Interpretação:

- o alerta do Supabase SQL Editor sobre RLS foi tratado como alerta operacional genérico;
- a fixture transacional dos testes é aceitável porque ocorre em `BEGIN + ROLLBACK`;
- não foi criada policy de INSERT para `authenticated`;
- não houve abertura indevida de superfície de acesso.

## Teste 07A — caminho positivo

Arquivo:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_financeira_json_first_rollback.sql
```

Commits relevantes:

```txt
30ed3aff7404f5e84c7ca6b812399195cb8c7660
bd299ef0e5613406b5fc2c9f05f6693e57e373fe
```

O teste 07A foi ajustado para criar fixture transacional em `mesa_simulacoes`, pois o banco estava sem linhas reais em `mesa_simulacoes`.

Condição inicial detectada:

```json
[
  {
    "section": "01_mesa_simulacoes_resumo",
    "total_simulacoes": 0,
    "com_empresa_id": 0,
    "com_empreendimento_id": 0,
    "com_empresa_e_empreendimento": 0,
    "com_corretor_id": 0
  }
]
```

Resultado final do 07A:

```json
[
  { "bloco": "01_fixture_transacional_contexto", "status": "PASS" },
  { "bloco": "02_rpc_executou_json_first", "status": "PASS" },
  { "bloco": "03_payload_admin_nao_cliente_safe", "status": "PASS" },
  { "bloco": "04_zero_persistencia_declarada", "status": "PASS" },
  { "bloco": "05_agenda_normalizada", "status": "PASS" },
  { "bloco": "06_periodicidade_nao_negociavel", "status": "PASS" },
  { "bloco": "07_datas_resolvidas", "status": "PASS" },
  { "bloco": "08_zero_dml_fluxo_parcelas", "status": "PASS" },
  { "bloco": "09_zero_dml_fluxo_operacoes", "status": "PASS" },
  { "bloco": "10_rollback_notice", "status": "INFO" }
]
```

Evidência específica de zero DML financeiro:

```json
{
  "mesa_cliente_fluxo_parcelas": {
    "before": 0,
    "after": 0
  },
  "mesa_cliente_fluxo_operacoes": {
    "before": 0,
    "after": 0
  }
}
```

Agenda positiva validada:

- quantidade de itens de origem: `4`;
- quantidade de parcelas normalizadas: `6`;
- valor total da agenda: `29500.50`;
- periodicidade simbólica marcada como não negociável;
- datas de mensalidade resolvidas com `origem_data = tabela_comercial_mes`;
- primeira mensalidade validada em `2099-06-30`, respeitando o último dia válido do mês quando o dia do ato é 31.

## Teste 07B — cenários negativos

Arquivo:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_financeira_json_first_negativos_rollback.sql
```

Commits relevantes:

```txt
cee8e9210e02947d2cdb9c12d9cd78fa78a2434b
```

Resultado final do 07B:

```json
[
  { "bloco": "01_fixture_transacional_contexto", "status": "PASS" },
  { "bloco": "02_grants_rpc_anon_bloqueado_authenticated_liberado", "status": "PASS" },
  { "bloco": "03_simulacao_inexistente_bloqueada", "status": "PASS" },
  { "bloco": "04_payload_empresa_fake_bloqueado", "status": "PASS" },
  { "bloco": "05_item_empresa_fake_bloqueado", "status": "PASS" },
  { "bloco": "06_valor_negativo_bloqueado", "status": "PASS" },
  { "bloco": "07_grupo_desconhecido_bloqueado", "status": "PASS" },
  { "bloco": "08_periodicidade_fraudada_bloqueada", "status": "PASS" },
  { "bloco": "09_periodicidade_negociavel_bloqueada", "status": "PASS" },
  { "bloco": "10_zero_dml_fluxo_parcelas", "status": "PASS" },
  { "bloco": "11_zero_dml_fluxo_operacoes", "status": "PASS" },
  { "bloco": "12_rollback_notice", "status": "INFO" }
]
```

Bloqueios validados:

| Cenário | Resultado |
|---|---|
| `anon` sem execute | PASS |
| `authenticated` com execute | PASS |
| simulação inexistente | PASS — `P0002` |
| `empresa_id` fake no `payload_tabela` | PASS — `42501` |
| `empresa_id` fake no item do fluxo | PASS — `42501` |
| valor negativo | PASS — `22023` |
| grupo desconhecido | PASS — `22023` |
| periodicidade simbólica fraudada | PASS — `22023` |
| periodicidade simbólica marcada como negociável | PASS — `22023` |
| zero DML em `mesa_cliente_fluxo_parcelas` | PASS |
| zero DML em `mesa_cliente_fluxo_operacoes` | PASS |

## Critério de aceite da Fase 4A

A Fase 4A só seria considerada válida se comprovasse:

1. geração de agenda financeira em JSON;
2. ausência de persistência em `mesa_cliente_fluxo_parcelas`;
3. ausência de persistência em `mesa_cliente_fluxo_operacoes`;
4. bloqueio de `anon`;
5. validação de simulação;
6. validação de empresa/tenant;
7. rejeição de `empresa_id` soberano vindo do payload;
8. rejeição de dados inválidos;
9. classificação de periodicidade simbólica como não negociável;
10. retorno administrativo, não cliente-safe.

Todos os critérios foram atendidos.

## Veredito

**Fase 4A JSON-first aprovada.**

A RPC oficial cumpre o contrato técnico e operacional da Fase 4A:

- gera agenda financeira normalizada;
- retorna JSON administrativo;
- preserva isolamento multiempresa;
- bloqueia tentativa de autoridade vinda do payload;
- não grava em tabelas financeiras;
- não cria operação financeira;
- passa nos testes positivo e negativo;
- preserva o contrato de produção única.

## Próxima fase autorizada

A próxima fase é a **Fase 4B — Persistência segura da agenda financeira**.

Nenhuma migration da 4B deve ser criada antes do contrato técnico da 4B.

## Pré-contrato da Fase 4B

A Fase 4B deverá tratar persistência da agenda financeira, mas somente após contrato explícito.

A 4B deverá incluir, no mínimo:

- lock transacional por simulação;
- idempotência;
- auditoria;
- proteção contra alteração quando existir operação confirmada;
- validação de simulação, empresa/tenant, empreendimento e perfil;
- proibição de `empresa_id` soberano vindo do frontend;
- `security definer` com `set search_path = public`;
- grants restritos;
- bloqueio de `anon`;
- testes com `BEGIN + ROLLBACK`;
- teste de repetição idempotente;
- teste de concorrência lógica quando aplicável;
- teste de bloqueio quando houver operação confirmada;
- teste de zero exposição cliente-safe;
- teste de integridade das parcelas persistidas.

A 4B não deverá incluir:

- frontend;
- parser;
- Worker;
- Make/n8n;
- leitura cliente-safe;
- VPL definitivo;
- prêmio;
- comissão;
- política interna exposta;
- confirmação/cancelamento de operação financeira.

## Regra de passagem para 4B

Antes de qualquer SQL da 4B, deve existir um documento de contrato com:

- objetivo;
- escopo;
- fora de escopo;
- tabelas tocadas;
- DML permitido;
- DML proibido;
- auth;
- tenant;
- perfil;
- RLS/grants;
- locks;
- idempotência;
- auditoria;
- rollback;
- testes;
- critérios de aceite;
- plano de parada.

Conclusão operacional:

> 4A pensa. 4B grava. 4C mostra para o cliente.
