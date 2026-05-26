# FECH.AI / MesaCliente — Fase 8K
# Contrato 19E — Smoke runtime de payload completo do Fluxo

## 1. Identificação

Projeto: FECH.AI / MesaCliente  
Fase: 8K  
Validação: 19E — Smoke runtime de payload completo do Fluxo  
Branch: feature/mesa-cliente-fase-8-front-operacoes-financeiras  
Tipo: validação funcional com evidência real de browser + Supabase  
Status: contrato criado para execução controlada.

## 2. Base protocolar

Este teste segue o Protocolo Mestre FECH.AI / MesaCliente v1.2.

Regra-mãe aplicada:

```text
Primeiro contrato. Depois evidência. Depois dry-run. Depois teste rollback. Depois persistência controlada.
```

Como o 19E é smoke runtime, ele depende de ação real na aplicação e confirmação posterior no Supabase.

## 3. Objetivo

Validar, em runtime real, que o fluxo salvo pela tela do MesaCliente envia e persiste múltiplos grupos financeiros quando a unidade/tabela contém esses dados.

O 19E complementa o 19D:

- 19D validou a preparação estática do frontend.
- 19E valida a execução real via browser, RPC e banco.

## 4. O que o 19E precisa provar

O teste deve provar:

1. A tela Fluxo mostra mais de um grupo financeiro antes de salvar.
2. A chamada `/rest/v1/rpc/criar_mesa_simulacao` retorna HTTP 200.
3. O payload enviado para `p_fluxo_json` contém múltiplos itens.
4. O payload contém, idealmente, os grupos:
   - `e` — entrada/ato;
   - `c` — complementos/curto prazo;
   - `m` — mensais;
   - `a` — intermediárias;
   - `u` — parcela única/chaves.
5. A tabela `public.mesa_simulacoes` recebe a simulação.
6. A tabela `public.mesa_fluxo_pagamentos` recebe todos os itens enviados.
7. A tabela `public.audit_logs` recebe auditoria da criação.
8. Não ocorre erro de enum/status/corretor/audit já corrigidos nas fases anteriores.

## 5. Dentro do escopo

Dentro do escopo:

- abrir a aplicação publicada;
- selecionar empreendimento/unidade com fluxo mais completo;
- alterar ou confirmar fluxo na tela;
- clicar em salvar mesa;
- capturar HAR;
- extrair o ID retornado pela RPC;
- consultar Supabase para confirmar persistência;
- documentar evidência.

## 6. Fora do escopo

Não alterar nesta fase:

- frontend;
- parser;
- Worker;
- Make/n8n;
- migrations;
- RPCs;
- RLS;
- policies;
- agenda financeira;
- parcelas oficiais da engenharia financeira;
- operações financeiras;
- cliente-safe;
- regras comerciais de taxa/juros.

Se o smoke falhar, a falha deve ser analisada antes de qualquer patch.

## 7. Critério para escolher a unidade

A unidade ideal para o 19E deve mostrar na tela, antes de salvar, ao menos 3 grupos financeiros.

Prioridade:

1. unidade com ato + complementos + mensais + intermediárias + parcela única/chaves;
2. unidade com ato + mensais + intermediárias + chaves;
3. unidade com ato + complementos + chaves;
4. unidade com apenas ato + financiamento não fecha o 19E completo, mas pode ser registrada como smoke parcial.

## 8. Evidência exigida do browser

A evidência principal deve ser um HAR contendo a chamada:

```text
/rest/v1/rpc/criar_mesa_simulacao
```

A chamada deve conter:

- status HTTP 200;
- resposta com UUID da simulação;
- request body com `p_fluxo_json`;
- `p_fluxo_json` com mais de um item quando a unidade escolhida possuir mais de uma parcela.

## 9. Evidência exigida do banco

Após obter o UUID retornado pela RPC, consultar:

```sql
select
  ms.id,
  ms.empresa_id,
  ms.corretor_id,
  c.user_id as corretor_user_id,
  ms.status::text as status,
  ms.valor_total,
  ms.entrada,
  ms.financiamento,
  ms.created_at,
  ms.snapshot_payload
from public.mesa_simulacoes ms
left join public.corretores c on c.id = ms.corretor_id
where ms.id = '<SIMULACAO_ID>'::uuid;
```

```sql
select
  simulacao_id,
  tipo::text as tipo,
  descricao,
  valor,
  quantidade,
  periodicidade,
  data_prevista,
  ordem
from public.mesa_fluxo_pagamentos
where simulacao_id = '<SIMULACAO_ID>'::uuid
order by ordem;
```

```sql
select
  id,
  action,
  actor_id,
  ator_user_id,
  ator_corretor_id,
  acao,
  entidade,
  entidade_id,
  created_at,
  payload
from public.audit_logs
where entidade_id = '<SIMULACAO_ID>'::uuid
order by created_at desc;
```

## 10. Critérios de PASS

O 19E será PASS quando houver evidência de:

1. HTTP 200 na RPC `criar_mesa_simulacao`.
2. UUID retornado pela RPC.
3. Registro em `mesa_simulacoes` com o mesmo UUID.
4. Registros em `mesa_fluxo_pagamentos` correspondentes aos itens enviados.
5. Auditoria em `audit_logs` com `entidade_id` igual ao UUID criado.
6. `ator_user_id` e `ator_corretor_id` preenchidos corretamente.
7. Nenhum erro de:
   - `42804` status enum/texto;
   - `23503` corretor FK;
   - `22P02` enum `mesa_fluxo_tipo`;
   - schema antigo de `audit_logs`.
8. Se a unidade tiver parcela única/chaves, o payload deve conter grupo `u` e o banco deve persistir tipo `quitacao`.

## 11. Critérios de bloqueio

Bloquear fechamento do 19E se:

- a RPC retornar erro;
- a resposta não trouxer UUID;
- o HAR não contiver `p_fluxo_json`;
- o payload tiver múltiplos grupos mas o banco persistir menos itens;
- houver divergência entre request e `mesa_fluxo_pagamentos`;
- houver erro de tenant/perfil/auth;
- houver indício de `service_role` no frontend;
- houver alteração inesperada de motor financeiro, parser, Worker/Make ou banco.

## 12. Observação importante

Uma unidade que possui somente ato + financiamento pode salvar corretamente com apenas um item em `mesa_fluxo_pagamentos`.

Isso não é falha funcional, mas também não comprova payload completo.

Para fechamento integral do 19E, a unidade escolhida precisa conter múltiplos grupos financeiros.

## 13. Status

```text
Contrato 19E criado.
Execução runtime pendente.
Evidência necessária: HAR + UUID criado + validação Supabase.
```
