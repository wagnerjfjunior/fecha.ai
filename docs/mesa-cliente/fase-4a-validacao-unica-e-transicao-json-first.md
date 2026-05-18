# MesaCliente — Fase 4A: Validação única e transição para JSON-first

**Status:** Oficial  
**Versão:** v1.0  
**Data:** 2026-05-18  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Protocolo obrigatório:** `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`  
**ADR vigente:** `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`  
**Contrato canônico:** `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`  

---

## 1. Objetivo deste documento

Este documento consolida a validação única da Fase 4A da Engenharia Financeira do MesaCliente.

Ele existe para impedir interpretações paralelas entre conversas, IAs, desenvolvedores, documentos, migrations e testes.

A partir deste documento, a leitura oficial é:

> **Os testes 07A/07B antigos não estão errados. Eles estão corretos para validar as migrations antigas persistentes. O desenho persistente antigo, porém, deixou de ser canônico para a Fase 4A.**

---

## 2. Decisão oficial atual

A Fase 4A atual é:

```txt
4A = gerar agenda financeira em JSON, sem persistir
4B = persistir agenda com lock, idempotência e auditoria
4C = leitura cliente-safe
```

Regra curta:

> **4A pensa. 4B grava. 4C mostra para o cliente.**

Consequência direta:

Tudo que grava, recria, apaga ou atualiza parcelas financeiras pertence à Fase 4B, não à Fase 4A.

---

## 3. Validação única oficial

Os arquivos abaixo pertencem ao desenho anterior da Fase 4A persistente:

```txt
supabase/migrations/20260517193000_mesa_cliente_engenharia_financeira_fase_4a_agenda.sql
supabase/migrations/20260517223000_mesa_cliente_rpc_gerar_agenda_parcelas.sql

supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_parcelas_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_parcelas_negativos_rollback.sql
```

Esse conjunto validava a arquitetura antiga:

```txt
gerar/recriar parcelas em mesa_cliente_fluxo_parcelas
```

Essa arquitetura anterior foi substituída pelo contrato atual:

```txt
Fase 4A = Dry-run / JSON-first / zero DML financeiro
```

---

## 4. Regra de ouro de comunicação

Não dizer:

```txt
Os testes antigos estão errados.
```

Dizer:

```txt
Os testes antigos são válidos para o desenho persistente anterior, mas esse desenho deixou de ser canônico para a Fase 4A.
```

Essa distinção é obrigatória.

Ela preserva o aprendizado técnico, evita apagar histórico útil e impede que um teste coerente com uma arquitetura antiga seja tratado como erro isolado.

---

## 5. Classificação oficial dos itens legados

| Item | Classificação final | Conduta |
|---|---|---|
| `public.gerar_mesa_cliente_agenda_parcelas` | RPC legada persistente | Não usar como RPC oficial da 4A atual |
| `07a_validacao_agenda_parcelas_rollback.sql` | Teste legado coerente com a RPC antiga | Arquivar/obsoletar junto com a migration antiga |
| `07b_validacao_agenda_parcelas_negativos_rollback.sql` | Teste legado coerente com a RPC antiga | Arquivar/obsoletar junto com a migration antiga |
| `20260517193000_mesa_cliente_engenharia_financeira_fase_4a_agenda.sql` | Migration obsoleta para a 4A atual | Não aplicar como Fase 4A canônica |
| `20260517223000_mesa_cliente_rpc_gerar_agenda_parcelas.sql` | Migration obsoleta para a 4A atual | Não aplicar como Fase 4A canônica |
| `public.mesa_cliente_gerar_agenda_financeira_admin` | RPC oficial da 4A JSON-first | Criar na nova migration canônica |
| `07a_validacao_agenda_financeira_json_first_rollback.sql` | Teste oficial positivo da 4A atual | Criar |
| `07b_validacao_agenda_financeira_json_first_negativos_rollback.sql` | Teste oficial negativo da 4A atual | Criar |

---

## 6. Critério oficial de validade da Fase 4A

A Fase 4A só é válida se:

1. gerar agenda financeira em JSON;
2. não persistir parcelas;
3. não criar operação financeira;
4. não executar `INSERT`, `UPDATE` ou `DELETE` em `mesa_cliente_fluxo_parcelas`;
5. não executar `INSERT`, `UPDATE` ou `DELETE` em `mesa_cliente_fluxo_operacoes`;
6. bloquear `anon`;
7. validar `auth.uid()`;
8. validar usuário ativo;
9. validar empresa/tenant pelo banco;
10. validar simulação;
11. validar empreendimento;
12. validar perfil/permissão;
13. ignorar ou rejeitar `empresa_id` vindo do payload;
14. retornar `cliente_safe = false`;
15. não expor VPL, prêmio, comissão ou política interna;
16. provar `count_before = count_after` nas tabelas financeiras.

---

## 7. Passo 0 obrigatório — preflight GitHub x Supabase

Antes de mover, arquivar ou neutralizar qualquer migration legada, é obrigatório validar o estado real do Supabase.

Motivo: existe diferença operacional entre:

1. migration legada ainda não aplicada; e
2. migration legada já aplicada no banco real.

### 7.1. Perguntas que o preflight deve responder

```txt
1. A migration 20260517193000_mesa_cliente_engenharia_financeira_fase_4a_agenda.sql foi aplicada no Supabase?
2. A migration 20260517223000_mesa_cliente_rpc_gerar_agenda_parcelas.sql foi aplicada no Supabase?
3. A função public.gerar_mesa_cliente_agenda_parcelas existe no banco?
4. Essa função tem EXECUTE para anon?
5. Essa função tem EXECUTE para authenticated?
6. Existe dependência ativa usando essa função?
7. Existem dados permanentes em mesa_cliente_fluxo_parcelas gerados por essa RPC antiga?
8. mesa_cliente_fluxo_parcelas e mesa_cliente_fluxo_operacoes permanecem estáveis antes/depois?
```

### 7.2. Saídas possíveis do preflight

| Cenário | Conduta |
|---|---|
| Migrations legadas não aplicadas | Mover/arquivar arquivos legados como obsoletos fora de `supabase/migrations` |
| Migrations legadas já aplicadas | Não apagar histórico; criar migration corretiva posterior para revogar/depreciar a RPC antiga |
| Função antiga existe com `anon` | Criar correção urgente de `REVOKE` |
| Função antiga existe sem uso ativo | Depreciar com segurança e documentar |
| Função antiga em uso | Mapear dependência antes de desativar |

---

## 8. Próximos passos oficiais em concordância

### Passo 0 — Preflight read-only

Criar e executar um preflight read-only para validar o estado real das migrations legadas no Supabase.

Nome sugerido:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/07_preflight_agenda_legada_readonly.sql
```

Esse arquivo não deve fazer DML.

---

### Passo 1 — Neutralizar ou depreciar o conjunto legado

A ação depende do resultado do preflight.

#### Cenário A — migrations legadas não aplicadas

Mover ou arquivar como obsoleto/histórico:

```txt
supabase/migrations/20260517193000_mesa_cliente_engenharia_financeira_fase_4a_agenda.sql
supabase/migrations/20260517223000_mesa_cliente_rpc_gerar_agenda_parcelas.sql
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_parcelas_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_parcelas_negativos_rollback.sql
```

Destino sugerido:

```txt
docs/mesa-cliente/rascunhos-sql/obsoletos-fase-4a-persistente/
```

Aviso obrigatório no topo de cada arquivo arquivado:

```txt
RASCUNHO OBSOLETO — NÃO APLICAR EM PRODUÇÃO.
Este arquivo pertence ao desenho antigo de Fase 4A persistente.
Substituído pelo contrato canônico: 4A JSON-first sem persistência.
```

#### Cenário B — migrations legadas já aplicadas

Não remover a história como se nunca tivesse existido.

Criar migration corretiva posterior para:

- revogar permissões indevidas;
- depreciar ou substituir a RPC antiga;
- garantir que `anon` não executa;
- documentar que a RPC antiga não é mais canônica;
- preservar rastreabilidade da aplicação real.

---

### Passo 2 — Criar a migration canônica da 4A

Novo arquivo:

```txt
supabase/migrations/<timestamp>_mesa_cliente_fase_4a_agenda_financeira_json_first.sql
```

Essa migration deve criar:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

A RPC deve usar:

```sql
language plpgsql
security definer
set search_path = public
```

E deve conter:

```sql
revoke all on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) from public;
revoke all on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) from anon;
grant execute on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) to authenticated;
```

Proibido nessa migration:

```txt
INSERT, UPDATE ou DELETE em mesa_cliente_fluxo_parcelas
INSERT, UPDATE ou DELETE em mesa_cliente_fluxo_operacoes
```

---

### Passo 3 — Criar os novos testes oficiais

Novos arquivos:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_financeira_json_first_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_financeira_json_first_negativos_rollback.sql
```

O teste 07A deve provar:

- caminho positivo com usuário autorizado;
- retorno `ok = true`;
- retorno `fase = 4A_JSON_FIRST`;
- `cliente_safe = false`;
- agenda JSON criada;
- data oficial prevalece;
- mês/ano usa dia do ato;
- mês sem dia válido usa último dia do mês;
- periodicidade simbólica não é negociável;
- ausência de VPL/prêmio/comissão/política interna;
- `count_before = count_after` em `mesa_cliente_fluxo_parcelas`;
- `count_before = count_after` em `mesa_cliente_fluxo_operacoes`.

O teste 07B deve provar bloqueios:

- sem auth;
- `anon`;
- simulação inexistente;
- cross-tenant;
- payload inválido;
- valor negativo;
- grupo desconhecido;
- `empresa_id` fake no payload;
- periodicidade simbólica fraudada.

---

### Passo 4 — Só depois avançar para 4B

A Fase 4B pode reaproveitar parte do aprendizado do desenho antigo, mas com outro contrato:

```txt
Persistência com lock, idempotência, auditoria e proteção contra operação confirmada.
```

A 4B não deve ser implementada dentro da 4A.

---

## 9. Reaproveitamento técnico permitido

O desenho legado pode ser usado como referência histórica para a Fase 4B, especialmente em:

- lógica de ordenação de parcelas;
- interpretação de grupos financeiros;
- tratamento de periodicidade simbólica;
- validações negativas;
- ideias de idempotência;
- regras de data já discutidas.

Mas não pode ser copiado cegamente para a Fase 4A atual, porque a 4A atual não persiste.

---

## 10. O que não fazer

Não fazer:

- aplicar migration antiga como Fase 4A;
- manter migration persistente antiga em `supabase/migrations` como se fosse oficial;
- apagar arquivo aplicado no Supabase sem migration corretiva;
- chamar teste legado de teste oficial da 4A atual;
- criar nova RPC com nome antigo;
- aceitar `empresa_id` soberano do payload;
- conceder `EXECUTE` para `anon`;
- criar operação financeira na 4A;
- expor VPL/prêmio/comissão/política interna;
- mexer no frontend, parser, Worker, Make/n8n.

---

## 11. Handoff para qualquer nova conversa

Usar este bloco ao iniciar uma nova conversa técnica sobre a Fase 4A:

```txt
Estamos na Fase 4A da Engenharia Financeira do MesaCliente.

Validação única oficial:
- Os testes 07A/07B antigos são coerentes com as migrations antigas persistentes.
- O desenho persistente antigo deixou de ser canônico para a Fase 4A.
- A Fase 4A atual é JSON-first, sem persistência.
- Tudo que grava parcelas pertence à Fase 4B.

Antes de mover ou neutralizar migrations antigas, executar preflight read-only GitHub x Supabase para saber se as migrations antigas foram aplicadas.

Se não foram aplicadas: arquivar como obsoletas fora de supabase/migrations.
Se foram aplicadas: criar migration corretiva/depreciação/revoke, sem apagar histórico.

Próximos arquivos oficiais:
- supabase/migrations/<timestamp>_mesa_cliente_fase_4a_agenda_financeira_json_first.sql
- supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_financeira_json_first_rollback.sql
- supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_financeira_json_first_negativos_rollback.sql

Critério de aceite da 4A:
- agenda em JSON;
- zero DML em mesa_cliente_fluxo_parcelas;
- zero DML em mesa_cliente_fluxo_operacoes;
- count_before = count_after;
- sem VPL/prêmio/comissão/política interna;
- anon bloqueado;
- auth/tenant/perfil validados.
```

---

## 12. Decisão final

A partir deste documento, a validação única é:

> **Fase 4A só é válida se gerar agenda em JSON e provar zero efeito colateral nas tabelas financeiras.**

Tudo que grava parcelas é Fase 4B.

Tudo que mostra ao cliente é Fase 4C.

Tudo que calcula impacto financeiro sobre agenda persistida é Fase 5A em diante.
