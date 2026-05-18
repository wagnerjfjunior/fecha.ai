# MesaCliente — Fase 4B — Contrato Pós-Preflight de Persistência da Agenda Financeira

## Status

**Contrato técnico pós-preflight da Fase 4B consolidado.**

Este documento substitui a leitura inicial da Fase 4B e passa a ser o contrato operacional para a criação da migration candidata de persistência da agenda financeira.

A Fase 4B está autorizada, a partir deste documento, para a criação de:

```txt
supabase/migrations/<timestamp>_mesa_cliente_fase_4b_persistencia_agenda_financeira.sql
supabase/tests/mesa-cliente/engenharia-financeira/08a_validacao_persistencia_agenda_financeira_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08b_validacao_persistencia_agenda_financeira_idempotencia_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08c_validacao_persistencia_agenda_financeira_negativos_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08d_validacao_bloqueio_operacao_confirmada_rollback.sql
```

A criação da migration candidata **não significa aplicação cega em produção**. Antes da aplicação definitiva, os testes devem ser executados com `BEGIN + ROLLBACK` e o resultado deve ser documentado.

## Fontes normativas

Este documento segue a hierarquia abaixo:

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md`
4. `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`
5. `docs/mesa-cliente/fase-4a-validacao-final-json-first.md`
6. `supabase/tests/mesa-cliente/engenharia-financeira/08_preflight_persistencia_agenda_readonly.sql`
7. Este documento.

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

A Fase 4B só existe porque a agenda foi validada em modo JSON-first antes de qualquer persistência.

## Evidência do preflight da 4B

O preflight read-only da Fase 4B foi criado em:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/08_preflight_persistencia_agenda_readonly.sql
```

Ele foi executado até o bloco final:

```json
[
  {
    "section": "99_end",
    "instruction": "Preflight read-only 4B concluído. Envie todos os resultsets antes de criar qualquer migration de persistência."
  }
]
```

Depois, foi executado um bloco consolidado para permitir leitura única dos pontos mais relevantes.

### Achados principais

O preflight confirmou:

- `mesa_cliente_fluxo_parcelas` existe;
- `mesa_cliente_fluxo_operacoes` existe;
- `mesa_simulacoes` existe;
- as tabelas financeiras estavam vazias no momento da leitura;
- `mesa_cliente_fluxo_parcelas = 0`;
- `mesa_cliente_fluxo_operacoes = 0`;
- `mesa_simulacoes = 0`;
- `authenticated` não possui grant direto amplo de escrita nas tabelas financeiras;
- `anon` não aparece com grant direto perigoso;
- policies diretas de escrita estão bloqueadas por desenho;
- `mesa_cliente_fluxo_parcelas` não possui colunas próprias suficientes para versionamento/idempotência/auditoria robustos;
- `mesa_cliente_fluxo_operacoes` usa coluna real `status_operacao`, não `status`;
- estados relevantes de operação devem considerar `status_operacao`, com valores como `simulada`, `confirmada`, `cancelada` e `bloqueada`, conforme schema real.

### Correção de diagnóstico

O bloco inicial do preflight procurava uma coluna genérica chamada `status` em `mesa_cliente_fluxo_operacoes`. Isso gerou leitura incompleta.

A interpretação correta é:

```txt
mesa_cliente_fluxo_operacoes.status_operacao é a coluna real de status operacional.
```

Portanto, qualquer bloqueio de operação confirmada na 4B deve usar `status_operacao`, não `status`.

## Decisão arquitetural da Fase 4B

A decisão oficial pós-preflight é:

> Fase 4B = persistência append-only versionada, com cabeçalho de agenda financeira, lock transacional, idempotência e auditoria.

Não será adotado o modelo simples de `DELETE + INSERT` em `mesa_cliente_fluxo_parcelas`.

Motivo:

- produção única;
- SaaS multiempresa;
- dados financeiros sensíveis;
- necessidade de auditoria;
- necessidade de idempotência;
- possibilidade futura de operação financeira confirmada;
- ausência de colunas nativas suficientes em `mesa_cliente_fluxo_parcelas` para controlar versão/hash/status de forma limpa;
- risco operacional de apagar/recriar parcelas em fluxo financeiro.

## Objetivo da Fase 4B

Persistir, de forma segura, auditável, idempotente e versionada, a agenda financeira gerada pela Fase 4A.

A Fase 4B deve transformar a agenda normalizada retornada pela RPC da 4A em registros persistidos em `mesa_cliente_fluxo_parcelas`, vinculados a um cabeçalho de agenda em nova tabela própria.

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

A persistência deve usar a RPC já validada:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
```

A 4B deve persistir a agenda gerada pela 4A, e não criar uma segunda fonte de verdade divergente.

## Nome oficial proposto da RPC da Fase 4B

```sql
public.mesa_cliente_persistir_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb,
  p_idempotency_key text default null
)
returns jsonb
```

Não incluir `p_empresa_id` como parâmetro. Empresa/tenant devem ser resolvidos pelo banco.

Não incluir `p_modo` neste momento, para evitar comportamento ambíguo. O modo oficial da 4B será append-only versionado.

## Significado do sufixo `_admin`

O sufixo `_admin` significa:

- uso interno/administrativo seguro;
- retorno não cliente-safe;
- acesso controlado por perfil;
- dados adequados para backend, BFF, gestor ou corretor autorizado.

O sufixo `_admin` **não** significa que apenas `admin_global` pode executar.

Perfis possíveis, sujeitos aos testes:

- `root` / `is_root()`;
- `admin_global`;
- `admin_local`;
- `gestor`;
- corretor dono da simulação, se permitido operacionalmente.

## Estrutura oficial da persistência

### Nova tabela de cabeçalho

A 4B deve criar uma tabela de cabeçalho de agenda financeira.

Nome oficial proposto:

```sql
public.mesa_cliente_agendas_financeiras
```

Responsabilidades:

- identificar a versão da agenda da simulação;
- armazenar hash canônico da agenda;
- indicar qual agenda está ativa;
- permitir idempotência;
- registrar auditoria mínima;
- bloquear substituição quando houver operação confirmada;
- servir como âncora para as parcelas persistidas.

Colunas mínimas esperadas:

```txt
id uuid primary key
empresa_id uuid not null
simulacao_id uuid not null
empreendimento_id uuid not null
versao integer not null
agenda_hash text not null
idempotency_key text null
status_agenda text not null default 'ativa'
gerada_por uuid null
gerada_em timestamptz not null default now()
substituida_por uuid null
substituida_em timestamptz null
metadata jsonb not null default '{}'::jsonb
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
```

Status permitidos inicialmente:

```txt
ativa
substituida
cancelada
bloqueada
```

A 4B usará inicialmente:

```txt
ativa
substituida
```

`cancelada` e `bloqueada` ficam reservados para fases futuras, salvo necessidade explícita.

### Alteração em `mesa_cliente_fluxo_parcelas`

Adicionar colunas mínimas para vínculo com a agenda:

```txt
agenda_id uuid
parcela_numero integer
parcelas_total_item integer
item_origem_index integer
```

Se alguma dessas colunas já existir no schema real, a migration deve usar `add column if not exists` ou estratégia equivalente segura.

A coluna `agenda_id` deve referenciar:

```txt
public.mesa_cliente_agendas_financeiras(id)
```

## Índices e constraints esperados

A migration da 4B deve criar, no mínimo:

### Uma agenda ativa por simulação

Índice único parcial:

```sql
unique (simulacao_id)
where status_agenda = 'ativa'
```

### Idempotência por simulação e hash

Índice recomendado:

```sql
unique (simulacao_id, agenda_hash)
```

### Busca por agenda

Índices recomendados:

```txt
mesa_cliente_fluxo_parcelas(agenda_id)
mesa_cliente_fluxo_parcelas(simulacao_id)
mesa_cliente_fluxo_parcelas(empresa_id)
mesa_cliente_agendas_financeiras(simulacao_id, status_agenda)
mesa_cliente_agendas_financeiras(empresa_id, simulacao_id)
```

## Tabelas envolvidas

### Leitura permitida

A 4B poderá ler:

- `mesa_simulacoes`;
- `corretores`;
- `empresas`;
- `empreendimentos`;
- `mesa_cliente_fluxo_parcelas`;
- `mesa_cliente_fluxo_operacoes`;
- `mesa_cliente_agendas_financeiras`.

### Escrita permitida

A 4B poderá executar DML em:

- `mesa_cliente_agendas_financeiras`;
- `mesa_cliente_fluxo_parcelas`.

### Escrita proibida

A Fase 4B não deve fazer INSERT, UPDATE ou DELETE em:

- `mesa_cliente_fluxo_operacoes`, exceto leitura para bloqueio de operação confirmada;
- tabelas de leads;
- tabelas de usuários/corretores;
- tabelas de empresas;
- tabelas de empreendimentos;
- tabelas do parser;
- tabelas de frontend/configuração que não façam parte da agenda financeira.

## DML permitido

Permitido:

- `INSERT` em `mesa_cliente_agendas_financeiras` para nova agenda;
- `UPDATE` em `mesa_cliente_agendas_financeiras` para marcar agenda ativa anterior como `substituida`;
- `INSERT` em `mesa_cliente_fluxo_parcelas` para parcelas da nova agenda;
- `SELECT` em `mesa_cliente_fluxo_operacoes` para verificar existência de operação confirmada;
- `SELECT ... FOR UPDATE` em `mesa_simulacoes`, se usado para lock de linha.

## DML proibido

Proibido na 4B:

- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` destrutivo em `mesa_cliente_fluxo_parcelas`;
- `INSERT` em `mesa_cliente_fluxo_operacoes`;
- `UPDATE` em `mesa_cliente_fluxo_operacoes`;
- `DELETE` em `mesa_cliente_fluxo_operacoes`;
- criação de operação financeira;
- confirmação de operação;
- cancelamento de operação;
- gravação de VPL;
- gravação de prêmio;
- gravação de comissão;
- gravação de política interna sensível;
- persistência de dados vindos do frontend como autoridade sem validação do banco;
- aceitação de `empresa_id` do payload como fonte soberana;
- concessão de execução para `anon`;
- criação de grants diretos amplos de escrita para `authenticated` nas tabelas financeiras.

## Fluxo oficial da RPC 4B

A RPC deve seguir este fluxo lógico:

1. validar `auth.uid()` via `mesa_cliente_assert_auth()`;
2. resolver usuário/corretor ativo;
3. validar perfil autorizado;
4. obter lock transacional por `p_simulacao_id`;
5. validar simulação no banco;
6. validar empresa/tenant da simulação;
7. validar empreendimento da simulação;
8. verificar se existe operação confirmada em `mesa_cliente_fluxo_operacoes` usando `status_operacao = 'confirmada'`;
9. chamar `public.mesa_cliente_gerar_agenda_financeira_admin(...)`;
10. validar que o retorno da 4A tem `ok=true`, `fase='4A_JSON_FIRST'`, `persistencia=false`, `dml_financeiro=false`;
11. calcular hash canônico da agenda no banco;
12. verificar se já existe agenda ativa com o mesmo hash;
13. se existir, retornar idempotente sem inserir novas parcelas;
14. se existir agenda ativa com hash diferente, marcar agenda anterior como `substituida`;
15. criar novo cabeçalho em `mesa_cliente_agendas_financeiras`;
16. inserir parcelas vinculadas ao `agenda_id`;
17. retornar JSON administrativo.

## Lock transacional

A Fase 4B deve usar lock por simulação.

Estratégia preferencial:

```txt
SELECT ... FOR UPDATE na linha de mesa_simulacoes
```

Pode ser combinado com:

```txt
pg_advisory_xact_lock derivado de p_simulacao_id
```

Regra:

- duas chamadas concorrentes para a mesma simulação não podem gerar agendas ativas divergentes;
- a persistência deve ser atômica;
- o lock não pode depender do frontend.

## Idempotência

A Fase 4B deve ser idempotente.

Regras:

- chamadas repetidas com a mesma entrada não podem duplicar parcelas;
- o hash deve ser calculado no banco;
- `p_idempotency_key` pode ajudar rastreabilidade, mas não substitui o hash canônico;
- `p_idempotency_key` não substitui validação de tenant, empresa, simulação ou perfil;
- idempotência não pode permitir acesso cross-tenant.

Hash canônico:

- deve ser calculado a partir da agenda normalizada retornada pela 4A;
- deve evitar depender de ordem instável de chaves JSON;
- deve considerar `simulacao_id`, `data_ato` e conteúdo material da agenda;
- deve ignorar campos voláteis como timestamp, se existirem.

## Auditoria

Auditoria mínima esperada no cabeçalho:

- `simulacao_id`;
- `empresa_id` resolvido pelo banco;
- `empreendimento_id` resolvido pelo banco;
- `gerada_por`;
- `gerada_em`;
- quantidade de parcelas persistidas;
- valor total persistido;
- hash da agenda;
- idempotency key, se fornecida;
- status da agenda;
- metadata mínima.

Não criar tabela de auditoria separada nesta fase se o cabeçalho resolver a necessidade mínima.

## Bloqueio por operação confirmada

A Fase 4B deve verificar `mesa_cliente_fluxo_operacoes` antes de substituir a agenda ativa.

Regra:

```txt
Se existir operação com status_operacao = 'confirmada' para a simulação, a agenda não pode ser substituída.
```

A RPC deve retornar erro controlado e não deve inserir nova agenda nem novas parcelas.

A 4B não deve inventar estados além dos existentes no schema real.

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

## RLS e grants

Para a nova tabela `mesa_cliente_agendas_financeiras`:

- RLS deve ser habilitado;
- RLS deve preferencialmente ser forçado;
- não conceder escrita direta para `anon`;
- não conceder escrita direta ampla para `authenticated`;
- leitura direta só se houver policy segura por tenant; se não houver necessidade imediata, manter acesso via RPC.

Para `mesa_cliente_fluxo_parcelas`:

- não abrir escrita direta para `authenticated`;
- escrita deve ocorrer pela RPC `security definer`;
- manter políticas diretas conservadoras.

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
  "agenda_id": "uuid",
  "versao": 1,
  "status_agenda": "ativa",
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

## Testes obrigatórios da Fase 4B

### 08A — Persistência positiva

Arquivo esperado:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/08a_validacao_persistencia_agenda_financeira_rollback.sql
```

Deve provar:

- cria fixture transacional, se necessário;
- chama RPC da 4B;
- persiste cabeçalho em `mesa_cliente_agendas_financeiras`;
- persiste parcelas em `mesa_cliente_fluxo_parcelas`;
- não cria operação em `mesa_cliente_fluxo_operacoes`;
- respeita `simulacao_id`, `empresa_id`, `empreendimento_id`;
- parcelas persistidas batem com agenda gerada pela 4A;
- existe exatamente uma agenda ativa para a simulação;
- transação termina em `ROLLBACK`.

### 08B — Idempotência

Arquivo esperado:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/08b_validacao_persistencia_agenda_financeira_idempotencia_rollback.sql
```

Deve provar:

- duas chamadas equivalentes não duplicam parcelas;
- hash canônico é respeitado;
- retorno indica chamada idempotente quando aplicável;
- continua existindo uma única agenda ativa para a simulação.

### 08C — Negativos

Arquivo esperado:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/08c_validacao_persistencia_agenda_financeira_negativos_rollback.sql
```

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

Arquivo esperado:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/08d_validacao_bloqueio_operacao_confirmada_rollback.sql
```

Deve provar:

- quando existir operação financeira com `status_operacao = 'confirmada'` para a simulação, a agenda não pode ser substituída;
- nenhuma agenda ativa é substituída indevidamente;
- nenhuma parcela confirmada é apagada ou alterada;
- erro é controlado;
- transação termina em `ROLLBACK`.

## Critérios de aceite da Fase 4B

A Fase 4B só será considerada validada se:

1. a migration respeitar este contrato;
2. a RPC usar `security definer` e `set search_path = public`;
3. `anon` estiver bloqueado;
4. `authenticated` tiver apenas `EXECUTE` na RPC, sem escrita direta ampla nas tabelas;
5. tenant/empresa forem resolvidos pelo banco;
6. `empresa_id` do payload não for soberano;
7. houver lock transacional por simulação;
8. houver idempotência comprovada;
9. houver cabeçalho versionado de agenda;
10. houver vínculo `agenda_id` nas parcelas;
11. operação confirmada bloqueie substituição de agenda;
12. testes 08A/08B/08C/08D passem;
13. tudo rode com `BEGIN + ROLLBACK` em validação;
14. nenhum dado cliente-safe seja exposto;
15. nenhum VPL, prêmio, comissão ou política interna seja exposto;
16. não haja `DELETE` em `mesa_cliente_fluxo_parcelas`;
17. não haja DML em `mesa_cliente_fluxo_operacoes`.

## Plano de parada

Parar imediatamente se qualquer um dos itens abaixo ocorrer:

- migration tentar usar `DELETE` em `mesa_cliente_fluxo_parcelas`;
- migration tentar criar operação financeira;
- migration tentar confirmar/cancelar operação;
- migration depender de `empresa_id` vindo do frontend;
- migration conceder escrita direta ampla para `authenticated`;
- migration conceder execução para `anon`;
- idempotência não puder ser garantida;
- bloqueio por `status_operacao = 'confirmada'` não puder ser testado;
- testes exigirem policy ampla de INSERT/UPDATE para `authenticated`;
- qualquer IA/conversa tentar implementar 4C, 5A, 5B ou 5C junto com a 4B.

## Relação com fases futuras

### Fase 4C

Só começa depois da 4B validada.

Objetivo: leitura cliente-safe da agenda persistida.

### Fase 5A

Só começa depois da 4B/4C.

Objetivo: simular impacto financeiro usando agenda persistida.

### Fase 5B

Objetivo futuro: registrar operação financeira.

### Fase 5C

Objetivo futuro: confirmar/cancelar operação financeira.

## Decisão final

A Fase 4B seguirá com:

```txt
append-only versionado
nova tabela de cabeçalho mesa_cliente_agendas_financeiras
agenda_id em mesa_cliente_fluxo_parcelas
uma agenda ativa por simulação
hash canônico calculado no banco
lock transacional por simulação
idempotência
auditoria mínima no cabeçalho
bloqueio por status_operacao = 'confirmada'
sem DELETE de parcelas
sem DML em operações
sem cliente-safe
sem VPL/prêmio/comissão/política
```

Próxima ação prática:

```txt
criar a migration candidata da Fase 4B e os testes 08A/08B/08C/08D com BEGIN + ROLLBACK.
```

Conclusão:

> A agenda já sabe nascer em JSON. Agora ela será gravada com certidão de nascimento, histórico e trava na porta — não no grito e nem no delete nervoso.
