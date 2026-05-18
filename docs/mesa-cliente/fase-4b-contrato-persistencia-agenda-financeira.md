# MesaCliente — Fase 4B — Contrato final da Persistência da Agenda Financeira

## Status

**Fase 4B aprovada em rollback transacional.**

Este documento foi atualizado após a validação final da Fase 4B para refletir a assinatura e o comportamento efetivamente aprovados.

A Fase 4B já teve seus testes 08A, 08B, 08C e 08D aprovados com `BEGIN + ROLLBACK`, conforme evidência final em:

```text
docs/mesa-cliente/fase-4b-validacao-final-evidencias.md
```

Este documento permanece como contrato técnico da 4B, mas a evidência final prevalece se houver divergência histórica.

---

## Fontes normativas

Hierarquia aplicável:

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md`
4. `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`
5. `docs/mesa-cliente/fase-4a-validacao-final-json-first.md`
6. `docs/mesa-cliente/fase-4b-validacao-final-evidencias.md`
7. Este documento.

Frase de controle:

> **4A pensa. 4B grava. 4C mostra para o cliente.**

---

## Decisão de passagem da 4A para 4B

A Fase 4A foi validada como JSON-first, sem persistência, sem DML financeiro e sem cliente-safe.

A Fase 4B só existe porque a agenda foi validada em modo JSON-first antes de qualquer persistência.

---

## Objetivo da Fase 4B

Persistir, de forma segura, auditável, idempotente e versionada, a agenda financeira gerada pela Fase 4A.

A Fase 4B transforma a agenda normalizada retornada pela RPC da 4A em:

- cabeçalho persistido em `mesa_cliente_agendas_financeiras`;
- parcelas persistidas em `mesa_cliente_fluxo_parcelas`;
- vínculo por `agenda_id`;
- retorno administrativo seguro.

---

## Fora de escopo da Fase 4B

A Fase 4B não implementa:

- frontend;
- BFF;
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
- envio para cliente;
- renderização de tabela para cliente;
- alteração do motor financeiro fora da persistência da agenda.

---

## RPC oficial aprovada da Fase 4B

Assinatura final aprovada:

```sql
public.mesa_cliente_persistir_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

### Decisão sobre `p_idempotency_key`

A proposta inicial com parâmetro adicional:

```sql
p_idempotency_key text default null
```

foi abandonada para a Fase 4B aprovada.

Motivo:

- a idempotência aprovada é por checksum canônico calculado no banco;
- não se deve depender de chave idempotente enviada pelo frontend;
- o contrato final ficou mais simples e menos vulnerável a uso soberano de dado externo.

Portanto, qualquer referência anterior a `p_idempotency_key` deve ser lida como proposta histórica substituída.

---

## Dependência obrigatória da 4A

A 4B deve usar a RPC já validada da 4A:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

A 4B persiste a agenda gerada pela 4A. Ela não cria uma segunda normalização divergente.

---

## Significado do sufixo `_admin`

O sufixo `_admin` significa:

- uso interno/administrativo seguro;
- retorno não cliente-safe;
- acesso controlado por perfil;
- dados adequados para backend, BFF, gestor ou corretor autorizado.

Não significa que apenas `admin_global` pode executar.

---

## Estrutura oficial da persistência

### Cabeçalho de agenda

Tabela oficial:

```sql
public.mesa_cliente_agendas_financeiras
```

Responsabilidades:

- identificar a agenda da simulação;
- armazenar checksum/hash canônico;
- indicar agenda ativa;
- permitir idempotência;
- registrar auditoria mínima;
- bloquear substituição quando houver operação confirmada;
- servir como âncora para parcelas persistidas.

### Parcelas financeiras

Tabela oficial:

```sql
public.mesa_cliente_fluxo_parcelas
```

Responsabilidades na 4B:

- receber as parcelas normalizadas;
- vincular cada parcela ao `agenda_id`;
- preservar `empresa_id`, `simulacao_id` e `empreendimento_id` coerentes;
- manter data, valor, grupo, negociabilidade e metadados seguros para uso interno.

---

## Decisão arquitetural da Fase 4B

A decisão final da 4B é:

```text
persistência append-only/versionada
cabeçalho em mesa_cliente_agendas_financeiras
agenda_id em mesa_cliente_fluxo_parcelas
uma agenda ativa por simulação
checksum canônico calculado no banco
lock transacional por simulação
idempotência por checksum
bloqueio por operação confirmada
sem DELETE de parcelas
sem DML em operações, exceto fixtures transacionais de teste
sem cliente-safe
sem VPL/prêmio/comissão/política exposta
```

Não foi adotado o modelo simples de `DELETE + INSERT` em `mesa_cliente_fluxo_parcelas`.

---

## Tabelas envolvidas

### Leitura permitida

A 4B pode ler:

- `mesa_simulacoes`;
- `corretores`;
- `empresas`;
- `empreendimentos`;
- `mesa_cliente_fluxo_parcelas`;
- `mesa_cliente_fluxo_operacoes`;
- `mesa_cliente_agendas_financeiras`.

### Escrita permitida

A 4B pode executar DML em:

- `mesa_cliente_agendas_financeiras`;
- `mesa_cliente_fluxo_parcelas`.

### Escrita proibida

A Fase 4B não deve fazer DML real de negócio em:

- `mesa_cliente_fluxo_operacoes`;
- tabelas de leads;
- tabelas de usuários/corretores;
- tabelas de empresas;
- tabelas de empreendimentos;
- tabelas do parser;
- tabelas de frontend/configuração que não façam parte da agenda financeira.

Observação: o teste 08D criou uma operação confirmada como fixture transacional apenas para validar o bloqueio. Isso não é comportamento da RPC 4B.

---

## DML permitido

Permitido:

- `INSERT` em `mesa_cliente_agendas_financeiras` para nova agenda;
- `UPDATE` em `mesa_cliente_agendas_financeiras` para marcar agenda ativa anterior como substituída, quando aplicável;
- `INSERT` em `mesa_cliente_fluxo_parcelas` para parcelas da nova agenda;
- `SELECT` em `mesa_cliente_fluxo_operacoes` para verificar existência de operação confirmada;
- lock transacional por simulação.

## DML proibido

Proibido na 4B:

- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` destrutivo em `mesa_cliente_fluxo_parcelas`;
- `INSERT` real de negócio em `mesa_cliente_fluxo_operacoes`;
- `UPDATE` real de negócio em `mesa_cliente_fluxo_operacoes`;
- `DELETE` em `mesa_cliente_fluxo_operacoes`;
- criação de operação financeira;
- confirmação de operação;
- cancelamento de operação;
- gravação/exposição de VPL;
- gravação/exposição de prêmio;
- gravação/exposição de comissão;
- exposição de política interna sensível;
- aceitação de `empresa_id` do payload como fonte soberana;
- concessão de execução para `anon`;
- criação de grants diretos amplos de escrita para `authenticated` nas tabelas financeiras.

---

## Fluxo oficial da RPC 4B

A RPC deve seguir este fluxo lógico:

1. validar `auth.uid()`;
2. resolver usuário/corretor ativo;
3. validar perfil autorizado;
4. obter lock transacional por `p_simulacao_id`;
5. validar simulação no banco;
6. validar empresa/tenant da simulação;
7. validar empreendimento da simulação;
8. verificar se existe operação confirmada em `mesa_cliente_fluxo_operacoes` usando `status_operacao = 'confirmada'`;
9. chamar `public.mesa_cliente_gerar_agenda_financeira_admin(...)`;
10. validar que o retorno da 4A tem `ok=true`, `fase='4A_JSON_FIRST'`, `persistencia=false`, `dml_financeiro=false`;
11. calcular checksum canônico da agenda no banco;
12. verificar se já existe agenda ativa com o mesmo checksum;
13. se existir, retornar idempotente sem inserir novas parcelas;
14. se existir agenda ativa com checksum diferente e não houver operação confirmada, substituir logicamente a agenda anterior;
15. criar novo cabeçalho em `mesa_cliente_agendas_financeiras`;
16. inserir parcelas vinculadas ao `agenda_id`;
17. retornar JSON administrativo.

---

## Lock transacional

A Fase 4B deve usar lock por simulação.

Regra:

- duas chamadas concorrentes para a mesma simulação não podem gerar agendas ativas divergentes;
- a persistência deve ser atômica;
- o lock não pode depender do frontend.

---

## Idempotência

A Fase 4B aprovada é idempotente por checksum canônico calculado no banco.

Regras:

- chamadas repetidas com a mesma entrada não duplicam parcelas;
- o checksum é calculado no banco;
- o checksum considera a agenda normalizada material;
- campos voláteis não podem quebrar idempotência;
- idempotência não permite acesso cross-tenant.

---

## Auditoria

Auditoria mínima esperada no cabeçalho:

- `simulacao_id`;
- `empresa_id` resolvido pelo banco;
- `empreendimento_id` resolvido pelo banco;
- usuário/corretor responsável quando aplicável;
- quantidade de parcelas persistidas;
- valor total persistido;
- checksum da agenda;
- status da agenda;
- timestamps;
- metadata mínima.

---

## Bloqueio por operação confirmada

Regra aprovada:

```text
Se existir operação com status_operacao = 'confirmada' para a simulação, a agenda não pode ser substituída.
```

O teste 08D comprovou:

- bloqueio com `SQLSTATE 55000`;
- preservação da agenda original;
- preservação do checksum original;
- preservação da versão original;
- não recriação indevida das parcelas;
- não criação de operação extra.

---

## Segurança e autorização

A RPC da 4B deve:

- usar `security definer`;
- definir `set search_path = public`;
- validar auth/contexto por banco;
- validar usuário ativo;
- validar empresa/tenant;
- validar simulação;
- validar empreendimento;
- validar perfil;
- bloquear `anon`;
- conceder `EXECUTE` apenas para `authenticated`;
- não conceder grants diretos amplos de escrita para `authenticated` nas tabelas financeiras;
- não aceitar `empresa_id` soberano vindo do frontend/payload.

---

## Retorno esperado aprovado da RPC

A RPC da 4B retorna JSON administrativo, não cliente-safe.

Campos esperados:

```json
{
  "ok": true,
  "fase": "4B_PERSISTENCIA_AGENDA",
  "visao": "administrativa",
  "cliente_safe": false,
  "persistencia": true,
  "dml_financeiro": true,
  "simulacao_id": "uuid",
  "agenda_id": "uuid",
  "status_agenda": "ativa",
  "idempotente": false,
  "checksum": "hash",
  "totais": {
    "qtd_parcelas": 0,
    "valor_total_agenda": 0
  }
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

---

## Testes obrigatórios aprovados da Fase 4B

### 08A — Persistência positiva

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/08a_validacao_persistencia_agenda_financeira_rollback.sql
```

Status: aprovado.

Comprovou:

- criação de agenda;
- criação de 6 parcelas no cenário fixture;
- valores persistidos batendo com payload;
- periodicidade bloqueada;
- datas resolvidas;
- zero DML em operações;
- rollback transacional.

### 08B — Idempotência

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/08b_validacao_persistencia_agenda_financeira_idempotencia_rollback.sql
```

Status: aprovado.

Comprovou:

- duas chamadas equivalentes não duplicam parcelas;
- segunda chamada retorna `idempotente=true`;
- checksum consistente;
- uma única agenda ativa.

### 08C — Negativos

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/08c_validacao_persistencia_agenda_financeira_negativos_rollback.sql
```

Status: aprovado.

Comprovou bloqueio para:

- `anon` sem execute;
- simulação inexistente;
- `empresa_id` fake no payload;
- item com `empresa_id` fake;
- valor negativo;
- grupo desconhecido;
- periodicidade fraudada;
- periodicidade simbólica marcada como negociável.

### 08D — Operação confirmada

Arquivo:

```text
supabase/tests/mesa-cliente/engenharia-financeira/08d_validacao_persistencia_agenda_financeira_operacao_confirmada_rollback.sql
```

Status: aprovado.

Comprovou:

- operação confirmada bloqueia substituição de agenda;
- erro controlado com `SQLSTATE 55000`;
- agenda original permanece intacta;
- parcelas originais não são recriadas indevidamente;
- não cria operação extra;
- rollback transacional.

---

## Erros encontrados e correções incorporadas

Durante a Fase 4B foram encontrados e corrigidos:

1. suposição de coluna `inserted_at` inexistente;
2. suposição de coluna `a.ativa` inexistente;
3. suposição de coluna `cliente_email` inexistente em `mesa_simulacoes`;
4. uso frágil de tabela temporária sob `SET LOCAL ROLE authenticated`;
5. necessidade de trocar a coleta de resultados do 08D para função `pg_temp`/estratégia compatível;
6. divergência de constraint em `mesa_cliente_fluxo_operacoes.grupo_origem`, que aceitava `mensal` e não `mensais`;
7. necessidade de tratar erro não esperado como bloco `00_falha_nao_tratada` para não mascarar falha.

Esses erros reforçaram o padrão do Protocolo Mestre: nenhum teste deve assumir coluna, constraint ou tabela sem preflight do schema real.

---

## Critérios de aceite da Fase 4B — atendidos

A Fase 4B foi considerada aprovada porque:

1. a RPC usa contrato seguro;
2. `anon` está bloqueado;
3. `authenticated` executa a RPC;
4. tenant/empresa são resolvidos pelo banco;
5. `empresa_id` do payload não é soberano;
6. há idempotência comprovada;
7. há cabeçalho de agenda;
8. parcelas são vinculadas por `agenda_id`;
9. operação confirmada bloqueia substituição;
10. testes 08A/08B/08C/08D passaram;
11. tudo rodou com `BEGIN + ROLLBACK`;
12. não houve cliente-safe;
13. não houve VPL/prêmio/comissão/política exposta;
14. não houve `DELETE` de parcelas;
15. não houve DML real de negócio em operações.

---

## Relação com fases futuras

### Fase 4C

Só começa depois da 4B validada.

Objetivo: leitura cliente-safe da agenda persistida.

A Fase 4C está aberta por contrato em:

```text
docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md
```

O preflight read-only já foi criado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/09_preflight_agenda_financeira_cliente_safe_readonly.sql
```

Próxima ação: executar o 09 preflight e enviar o resultset completo antes de criar qualquer migration 4C.

### Fase 5A

Só começa depois da 4C validada, salvo decisão formal.

### Fase 5B

Objetivo futuro: registrar operação financeira.

### Fase 5C

Objetivo futuro: confirmar/cancelar operação financeira.

---

## Decisão final

A Fase 4B está aprovada em rollback transacional.

Próxima ação prática:

```text
Executar o preflight read-only da Fase 4C:
supabase/tests/mesa-cliente/engenharia-financeira/09_preflight_agenda_financeira_cliente_safe_readonly.sql
```

Conclusão:

> A agenda já sabe nascer em JSON e já sabe ser gravada com identidade, checksum, parcelas e trava contra operação confirmada. Agora ela precisa aprender a falar com o cliente sem entregar a planilha secreta da cozinha.
