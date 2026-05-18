# MesaCliente — Fase 4B — Contrato Técnico de Persistência da Agenda Financeira

## Status

**Contrato técnico inicial da Fase 4B.**

Este documento define o acordo operacional, arquitetural e de segurança para a Fase 4B da Engenharia Financeira do MesaCliente.

A Fase 4B ainda **não está autorizada para migration SQL** até que o preflight específico desta fase seja executado e documentado.

## Fontes normativas

Este documento segue a hierarquia abaixo:

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md`
4. `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`
5. `docs/mesa-cliente/fase-4a-validacao-final-json-first.md`
6. Este documento da Fase 4B.

Frase de controle obrigatória:

> Primeiro contrato. Depois validação. Depois dry-run. Depois persistência.

Resumo operacional:

> 4A pensa. 4B grava. 4C mostra para o cliente.

## Decisão de passagem da 4A para 4B

A Fase 4A foi validada tecnicamente e documentada em:

```txt
 docs/mesa-cliente/fase-4a-validacao-final-json-first.md
```

A Fase 4A comprovou:

- geração de agenda financeira em JSON;
- retorno administrativo;
- `cliente_safe=false`;
- `persistencia=false`;
- `dml_financeiro=false`;
- bloqueio de `anon`;
- validação de simulação, empresa/tenant, empreendimento e perfil;
- bloqueio de `empresa_id` soberano vindo do payload;
- rejeição de dados inválidos;
- periodicidade simbólica não negociável;
- zero DML em `mesa_cliente_fluxo_parcelas`;
- zero DML em `mesa_cliente_fluxo_operacoes`.

A Fase 4B pode existir porque a agenda já foi validada em modo JSON-first.

## Objetivo da Fase 4B

Persistir, de forma segura, auditável e idempotente, a agenda financeira gerada pela Fase 4A.

A Fase 4B deve transformar a agenda normalizada retornada pela RPC da 4A em registros persistidos em `mesa_cliente_fluxo_parcelas`, respeitando:

- lock transacional por simulação;
- idempotência;
- auditoria;
- validação multiempresa;
- bloqueio contra alteração quando existir operação financeira confirmada;
- controle de perfil;
- ausência de exposição cliente-safe;
- ausência de VPL, prêmio, comissão e política interna.

## Fora de escopo da Fase 4B

A Fase 4B **não** deve implementar:

- frontend;
- parser;
- Worker;
- Make/n8n;
- leitura cliente-safe;
- VPL definitivo;
- prêmio;
- comissão;
- política interna exposta;
- criação de operação financeira;
- confirmação de operação financeira;
- cancelamento de operação financeira;
- simulação de impacto financeiro sobre operação confirmada;
- envio para cliente;
- renderização de tabela para cliente;
- alteração do motor financeiro fora da persistência da agenda.

## Princípio fundamental

A 4B não deve recriar, duplicar ou reinterpretar a regra de normalização da 4A sem justificativa explícita.

A persistência deve preferencialmente usar a RPC já validada:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
```

A 4B deve persistir a agenda gerada pela 4A, e não criar uma segunda fonte de verdade divergente.

## Nome proposto da RPC da Fase 4B

Nome proposto, sujeito ao preflight de schema:

```sql
public.mesa_cliente_persistir_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb,
  p_idempotency_key text default null,
  p_modo text default 'replace_draft'
)
returns jsonb
```

Observação importante:

- este nome ainda é contrato proposto;
- não criar migration até o preflight confirmar schema, constraints, RLS, grants e colunas reais;
- não alterar a assinatura sem atualizar este contrato.

## Significado do sufixo `_admin`

O sufixo `_admin` significa:

- uso interno/administrativo seguro;
- retorno não cliente-safe;
- acesso controlado por perfil;
- dados adequados para backend, BFF, gestor ou corretor autorizado.

O sufixo `_admin` **não** significa que apenas `admin_global` pode executar.

Perfis possíveis, sujeitos à validação da RPC:

- `root` / `is_root()`;
- `admin_global`;
- `admin_local`;
- `gestor`;
- corretor dono da simulação, se permitido operacionalmente.

A decisão final de perfil deve ser confirmada no preflight e nos testes.

## Tabelas envolvidas

### Tabelas que a 4B pode ler

A 4B poderá ler, com validação adequada:

- `mesa_simulacoes`;
- `corretores`;
- `empresas`;
- `empreendimentos`;
- `mesa_cliente_fluxo_parcelas`;
- `mesa_cliente_fluxo_operacoes`.

### Tabelas que a 4B pode gravar

A 4B poderá gravar somente após contrato validado:

- `mesa_cliente_fluxo_parcelas`.

### Tabelas que a 4B pode gravar apenas se houver contrato explícito adicional

A 4B poderá gravar em tabela de auditoria somente se o preflight identificar uma tabela adequada ou se for criado um contrato específico para isso.

Possíveis opções, sujeitas a validação:

- tabela de auditoria já existente;
- coluna de auditoria em `mesa_cliente_fluxo_parcelas`;
- nova tabela de auditoria específica da agenda financeira.

Sem essa validação, não criar auditoria improvisada.

### Tabelas proibidas para DML na 4B

A Fase 4B não deve fazer INSERT, UPDATE ou DELETE em:

- `mesa_cliente_fluxo_operacoes`, exceto leitura para bloqueio de operação confirmada;
- tabelas de leads;
- tabelas de usuários/corretores;
- tabelas de empresas;
- tabelas de empreendimentos;
- tabelas do parser;
- tabelas de frontend/configuração que não façam parte da agenda financeira.

## DML permitido

A Fase 4B poderá executar DML em `mesa_cliente_fluxo_parcelas` com uma das estratégias abaixo, após escolha explícita:

### Estratégia A — replace draft

Substitui a agenda anterior de uma simulação somente se ela estiver em estado editável.

Fluxo conceitual:

1. obter lock transacional da simulação;
2. validar auth, tenant, empresa, empreendimento, simulação e perfil;
3. verificar inexistência de operação financeira confirmada;
4. gerar agenda via RPC da 4A;
5. comparar hash/idempotência;
6. remover ou marcar como substituída a versão anterior em estado draft;
7. inserir nova versão da agenda;
8. retornar resumo administrativo.

### Estratégia B — versionamento append-only

Não apaga fisicamente a agenda anterior. Cria nova versão e marca versão ativa.

Fluxo conceitual:

1. obter lock transacional;
2. gerar agenda via 4A;
3. calcular hash;
4. se hash igual ao ativo, retornar idempotente sem recriar;
5. se hash diferente, criar nova versão;
6. desativar versão anterior ou apontar versão ativa.

### Decisão preliminar

A estratégia preferencial para produção única é **versionamento lógico / append-only**, se o schema permitir.

Se o schema atual não suportar versionamento, a alternativa mínima aceitável é `replace_draft` com lock, auditoria e testes robustos.

A decisão final depende do preflight de `mesa_cliente_fluxo_parcelas`.

## DML proibido

A 4B não pode:

- apagar agenda confirmada;
- alterar parcela vinculada a operação confirmada;
- criar operação financeira;
- confirmar operação;
- cancelar operação;
- gravar VPL;
- gravar prêmio;
- gravar comissão;
- gravar política interna sensível;
- persistir dados vindos do frontend como autoridade sem validação do banco;
- aceitar `empresa_id` do payload como fonte soberana;
- conceder execução para `anon`;
- abrir grants diretos desnecessários em tabelas;
- criar policy ampla para `authenticated` inserir/alterar tabela financeira diretamente.

## Lock transacional

A Fase 4B deve usar lock por simulação para impedir concorrência lógica.

Opções aceitáveis, sujeitas ao preflight:

1. `pg_advisory_xact_lock` derivado do `p_simulacao_id`;
2. `SELECT ... FOR UPDATE` na linha de `mesa_simulacoes`;
3. combinação de ambos, se houver justificativa.

Regra:

- a simulação deve ficar logicamente travada durante a persistência;
- duas chamadas concorrentes para a mesma simulação não podem gerar agendas divergentes;
- a persistência deve ser atômica.

## Idempotência

A Fase 4B deve ser idempotente.

Chamadas repetidas com a mesma entrada devem resultar em um dos comportamentos abaixo:

- retornar a agenda já persistida sem duplicar parcelas;
- ou criar uma nova versão somente quando houver mudança material de entrada.

Chaves possíveis de idempotência:

- `p_idempotency_key`, quando fornecida por BFF/backend confiável;
- hash canônico da agenda gerada pela 4A;
- combinação de `simulacao_id + agenda_hash + data_ato`;
- versão da agenda.

Regra de segurança:

- `p_idempotency_key` não substitui validação de tenant, empresa, simulação ou perfil;
- idempotência não pode ser usada para acessar agenda de outra empresa;
- hash deve ser calculado no banco, não confiado ao frontend.

## Auditoria

A Fase 4B deve registrar evidência de persistência.

Auditoria mínima desejada:

- `simulacao_id`;
- `empresa_id` resolvido pelo banco;
- `empreendimento_id` resolvido pelo banco;
- `corretor_id` / usuário executor;
- timestamp;
- quantidade de parcelas persistidas;
- valor total persistido;
- hash da agenda;
- modo de persistência;
- origem da chamada;
- se foi chamada idempotente ou nova persistência.

O local da auditoria depende do preflight.

Sem preflight, não inventar tabela, coluna ou mecanismo de auditoria.

## Bloqueio por operação confirmada

A Fase 4B deve verificar `mesa_cliente_fluxo_operacoes` antes de persistir agenda.

Regra conceitual:

- se existir operação financeira confirmada/efetivada para a simulação, a agenda não pode ser substituída ou alterada;
- a RPC deve retornar erro controlado;
- qualquer alteração posterior deve pertencer a fase específica de operação financeira, cancelamento, estorno ou nova versão autorizada.

Estados a mapear no preflight:

- confirmado;
- cancelado;
- rascunho;
- pendente;
- expirado;
- outros estados existentes no schema real.

Nenhuma regra de status deve ser inventada sem consultar o banco.

## Segurança e autorização

A RPC da 4B deverá obrigatoriamente:

- usar `security definer`;
- definir `set search_path = public`;
- chamar `mesa_cliente_assert_auth()`;
- validar usuário ativo;
- validar empresa/tenant resolvido pelo banco;
- validar simulação;
- validar empreendimento;
- validar perfil;
- bloquear `anon`;
- conceder `EXECUTE` apenas para `authenticated`;
- não conceder grants diretos de escrita para `authenticated` nas tabelas financeiras;
- não aceitar `empresa_id` soberano vindo do frontend/payload.

## Retorno esperado da RPC

A RPC da 4B deve retornar JSON administrativo, não cliente-safe.

Campos mínimos esperados:

```json
{
  "ok": true,
  "fase": "4B_PERSISTENCIA_AGENDA",
  "visao": "administrativa",
  "cliente_safe": false,
  "persistencia": true,
  "simulacao_id": "uuid",
  "empresa_id": "uuid",
  "empreendimento_id": "uuid",
  "modo": "replace_draft ou append_only",
  "idempotente": false,
  "agenda_hash": "hash",
  "totais": {
    "qtd_parcelas_persistidas": 0,
    "valor_total_agenda": 0
  },
  "warnings": []
}
```

O retorno não deve conter:

- VPL;
- prêmio;
- comissão;
- política interna;
- dados cliente-safe finais;
- dados de outra empresa;
- conteúdo bruto sensível desnecessário.

## Preflight obrigatório antes da migration 4B

Antes de qualquer SQL executável da 4B, criar e rodar um preflight read-only:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/08_preflight_persistencia_agenda_readonly.sql
```

O preflight deve mapear:

1. colunas de `mesa_cliente_fluxo_parcelas`;
2. constraints de `mesa_cliente_fluxo_parcelas`;
3. índices de `mesa_cliente_fluxo_parcelas`;
4. triggers de `mesa_cliente_fluxo_parcelas`;
5. RLS e policies de `mesa_cliente_fluxo_parcelas`;
6. grants de `mesa_cliente_fluxo_parcelas`;
7. colunas de `mesa_cliente_fluxo_operacoes`;
8. constraints de `mesa_cliente_fluxo_operacoes`;
9. índices de `mesa_cliente_fluxo_operacoes`;
10. triggers de `mesa_cliente_fluxo_operacoes`;
11. RLS e policies de `mesa_cliente_fluxo_operacoes`;
12. grants de `mesa_cliente_fluxo_operacoes`;
13. status reais existentes em `mesa_cliente_fluxo_operacoes`, se houver dados;
14. funções existentes relacionadas a agenda, parcelas, operação, confirmação e cancelamento;
15. migrations já aplicadas que possam afetar agenda/operação;
16. existência de tabela/colunas de auditoria;
17. possibilidade real de idempotência pelo schema atual;
18. necessidade ou não de nova coluna, índice ou constraint.

Regra:

- sem esse preflight, não criar migration 4B.

## Testes obrigatórios da Fase 4B

A Fase 4B deve criar novos testes, ainda a definir após preflight.

Nomes propostos:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/08a_validacao_persistencia_agenda_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08b_validacao_persistencia_agenda_idempotencia_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08c_validacao_persistencia_agenda_negativos_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08d_validacao_bloqueio_operacao_confirmada_rollback.sql
```

### 08A — Persistência positiva

Deve provar:

- cria fixture transacional, se necessário;
- chama RPC da 4B;
- persiste parcelas em `mesa_cliente_fluxo_parcelas`;
- não cria operação em `mesa_cliente_fluxo_operacoes`;
- respeita `simulacao_id`, `empresa_id`, `empreendimento_id`;
- parcelas persistidas batem com agenda gerada pela 4A;
- transação termina em `ROLLBACK`.

### 08B — Idempotência

Deve provar:

- duas chamadas equivalentes não duplicam parcelas indevidamente;
- hash ou chave de idempotência é respeitado;
- retorno indica chamada idempotente quando aplicável.

### 08C — Negativos

Deve provar bloqueio para:

- `anon`;
- simulação inexistente;
- cross-tenant;
- `empresa_id` fake no payload;
- payload inválido;
- grupo inválido;
- valor negativo;
- usuário inativo;
- perfil não autorizado.

### 08D — Operação confirmada

Deve provar:

- quando existir operação financeira confirmada para a simulação, a agenda não pode ser substituída;
- nenhuma parcela confirmada é apagada ou alterada;
- erro é controlado;
- transação termina em `ROLLBACK`.

## Critérios de aceite da Fase 4B

A Fase 4B só será considerada validada se:

1. o preflight 08 for executado e documentado;
2. a migration respeitar o contrato;
3. a RPC usar `security definer` e `set search_path = public`;
4. `anon` estiver bloqueado;
5. `authenticated` tiver apenas `EXECUTE` na RPC, sem escrita direta ampla nas tabelas;
6. tenant/empresa forem resolvidos pelo banco;
7. `empresa_id` do payload não for soberano;
8. houver lock transacional por simulação;
9. houver idempotência comprovada;
10. houver auditoria mínima ou decisão documentada sobre auditoria;
11. operação confirmada bloqueie alteração de agenda;
12. testes 08A/08B/08C/08D passem;
13. tudo rode com `BEGIN + ROLLBACK` em validação;
14. nenhum dado cliente-safe seja exposto;
15. nenhum VPL, prêmio, comissão ou política interna seja exposto.

## Plano de parada

Parar imediatamente se qualquer um dos itens abaixo ocorrer:

- preflight mostrar RLS desligado em tabela financeira;
- preflight mostrar grant direto perigoso para `anon`;
- preflight mostrar grant direto amplo de escrita para `authenticated` sem justificativa;
- schema não permitir persistência segura sem nova decisão arquitetural;
- existir operação confirmada e a regra de bloqueio não estiver clara;
- idempotência não puder ser garantida;
- auditoria não puder ser definida;
- teste exigir policy ampla de INSERT/UPDATE para `authenticated`;
- migration tentar criar operação financeira;
- migration tentar implementar 4C/5A/5B junto com 4B;
- qualquer IA/conversa sugerir gravar antes do preflight.

## Relação com fases futuras

### Fase 4C

Só começa depois da 4B validada.

Objetivo: criar leitura cliente-safe da agenda persistida.

### Fase 5A

Só começa depois da 4B/4C.

Objetivo: simular impacto financeiro usando agenda persistida.

### Fase 5B

Objetivo futuro: registrar operação financeira.

### Fase 5C

Objetivo futuro: confirmar/cancelar operação financeira.

## Decisão final deste contrato

A Fase 4B está autorizada apenas para:

1. preflight read-only;
2. análise de schema real;
3. decisão de estratégia de persistência;
4. desenho dos testes;
5. revisão do contrato.

A Fase 4B ainda **não está autorizada para migration de persistência** neste documento.

A próxima ação prática é criar e rodar:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/08_preflight_persistencia_agenda_readonly.sql
```

Conclusão:

> A agenda já sabe nascer em JSON. Agora a 4B precisa provar que sabe gravar sem virar dívida técnica com CPF e contrato assinado.
