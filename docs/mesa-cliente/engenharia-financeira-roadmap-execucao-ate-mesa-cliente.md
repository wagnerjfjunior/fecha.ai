# MesaCliente — Roadmap de execução da Engenharia Financeira até teste em mesa

**Status:** Oficial — atualizado após aprovação da Fase 4B e abertura da Fase 4C  
**Branch oficial de trabalho:** `feature/mesa-cliente-engenharia-financeira`  
**Atualizado em:** 2026-05-18  
**Protocolo obrigatório:** `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`  
**ADR vigente:** `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`  

---

## 0. Aviso de atualização

Este roadmap foi atualizado para remover a divergência documental identificada após a validação da Fase 4B.

A leitura oficial atual é:

```txt
4A = aprovada — agenda financeira JSON-first, sem persistência
4B = aprovada em rollback transacional — persistência da agenda com lock, idempotência e auditoria
4C = aberta por contrato — leitura cliente-safe da agenda persistida
09 preflight 4C = criado — pendente de execução e envio do resultset completo
5A = pendente — simular impacto financeiro com agenda persistida
5B = pendente — registrar operação financeira
5C = pendente — confirmar/cancelar operação financeira
Depois = integração front/BFF
```

Regra curta:

> **4A pensa. 4B grava. 4C mostra para o cliente.**

Qualquer documento, teste ou comentário antigo que ainda trate a Fase 4A como persistência direta, ou que trate 4A/4B como pendentes, está subordinado a esta versão atualizada do roadmap, ao Protocolo Mestre v1.2 e aos documentos de evidência final das fases.

---

## 1. Hierarquia documental vigente

Ordem de referência para qualquer IA, dev ou conversa técnica:

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md`
4. `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`
5. `docs/mesa-cliente/fase-4a-validacao-final-json-first.md`
6. `docs/mesa-cliente/fase-4b-contrato-persistencia-agenda-financeira.md`
7. `docs/mesa-cliente/fase-4b-validacao-final-evidencias.md`
8. `docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md`
9. `supabase/tests/mesa-cliente/engenharia-financeira/09_preflight_agenda_financeira_cliente_safe_readonly.sql`
10. Este roadmap como índice operacional atualizado.

O roadmap é índice de navegação. Em caso de conflito entre roadmap e evidência final de fase, prevalece a evidência final mais recente, desde que compatível com o Protocolo Mestre.

---

## 2. Princípios não negociáveis

1. Não levar desconto simples global para `main`.
2. Não alterar parser, motor financeiro atual, Worker, Make, n8n ou `main` sem autorização explícita.
3. O app é multiempresa e multitenant por desenho, não por convenção de frontend.
4. Banco/RPC é soberano. Frontend é consultivo e nunca decide regra financeira.
5. Nenhuma regra financeira hardcoded no frontend.
6. RLS obrigatória nas tabelas financeiras.
7. `auth.uid()` obrigatório em RPCs sensíveis.
8. Toda RPC deve validar usuário, empresa, tenant, empreendimento, simulação e perfil.
9. Cliente nunca vê VPL, prêmio, comissão, política interna, impacto administrativo ou regra de remuneração.
10. Corretor/coordenador pode ver impacto administrativo conforme perfil e autorização.
11. Data oficial da tabela prevalece sobre regra calculada.
12. Quando houver apenas mês/ano, usar o dia do ato; se o mês não possuir o dia, usar o último dia válido.
13. Chaves/parcela única devem vir da tabela ou cabeçalho, podendo ser 30 ou 60 dias antes do financiamento quando o contrato permitir.
14. Periodicidade simbólica não entra como parcela negociável.
15. `anon` não executa RPC financeira administrativa ou de escrita.
16. `service_role` nunca aparece em frontend, variável pública, build client-side, storage público, log ou payload de navegador.
17. Operações financeiras de escrita passam por RPCs fortes, com validação interna e least privilege.
18. Teste em produção única usa `BEGIN` + `ROLLBACK` até liberação formal.
19. Toda fase precisa respeitar seu escopo; fase misturada é falha de engenharia.
20. Migration obsoleta não permanece como canônica em `supabase/migrations`.
21. Documento antigo não pode contrariar evidência final de fase aprovada.

---

## 3. Status atual consolidado

| Área | Status |
|---|---:|
| Backup local antes da engenharia financeira | Concluído |
| Branch de trabalho isolada | Concluído |
| Protocolo Mestre FECH.AI / MesaCliente v1.2 | Concluído |
| Protocolo Universal de Funcionamento v1.1 | Concluído |
| ADR-0001 — Fase 4A JSON-first sem persistência | Concluído |
| Contrato canônico da Fase 4A JSON-first | Concluído |
| Tabelas financeiras base | Concluído |
| RLS das tabelas financeiras | Concluído |
| Helpers de contexto/autorização | Concluído |
| RPCs administrativas de política/faixas | Concluído |
| Teste funcional de política/faixas com rollback | Concluído |
| Funções puras de cálculo composto | Concluído |
| Testes de exceção das funções financeiras | Concluído |
| RPC de simulação administrativa sem gravação | Concluído |
| Grants endurecidos sem `anon` | Concluído |
| Teste funcional positivo da simulação admin | Concluído |
| Teste funcional negativo da simulação admin | Concluído |
| Fase 4A — agenda financeira JSON-first sem persistência | Aprovada |
| Testes 07A/07B — JSON-first | Aprovados |
| Fase 4B — persistência segura da agenda financeira | Aprovada em rollback transacional |
| Testes 08A/08B/08C/08D — persistência/idempotência/negativos/operação confirmada | Aprovados |
| Fase 4C — leitura cliente-safe da agenda persistida | Contrato aberto |
| Teste 09 preflight cliente-safe | Criado, pendente de execução/resultset |
| Migration/RPC 4C cliente-safe | Pendente — bloqueada até validação do 09 preflight |
| Registro/confirmacão de operação financeira | Pendente — fase 5B/5C |
| Integração de frontend/BFF | Pendente — proibida antes da 4C validada |
| Teste controlado em mesa com cliente | Pendente |

---

## 4. Arquitetura alvo atualizada até a mesa com cliente

Fluxo alvo atual:

```text
Tabela/PDF/entrada atual
  -> parser atual preservado
  -> payload financeiro bruto
  -> Fase 4A: RPC gera agenda normalizada em JSON, sem persistir
  -> Fase 4B: RPC persiste agenda e parcelas com lock/idempotência/auditoria
  -> Fase 4C: RPC lê agenda persistida em visão cliente-safe
  -> Fase 5A: simular impacto financeiro com agenda persistida
  -> Fase 5B: registrar operação financeira
  -> Fase 5C: confirmar/cancelar operação financeira
  -> visão cliente-safe final
  -> integração front/BFF
  -> tela MesaCliente para atendimento
```

O frontend não monta cálculo soberano. Ele pode exibir, solicitar simulação e renderizar retorno seguro. Toda decisão final de elegibilidade, datas, política, limite de VPL, prêmio e gravação permanece no banco/RPC/BFF autorizado.

---

## 5. Modelo de segurança DevSecOps

### 5.1. Banco e RLS

Tabelas sensíveis devem manter RLS ativo, com escrita direta bloqueada para perfis não administrativos e operação financeira sempre intermediada por RPC validada.

Tabelas relevantes:

- `mesa_cliente_politicas_financeiras`
- `mesa_cliente_politica_premio_faixas`
- `mesa_cliente_fluxo_parcelas`
- `mesa_cliente_fluxo_operacoes`
- `mesa_cliente_agendas_financeiras`
- futuras tabelas de snapshot/auditoria financeira

Regras:

- `anon` sem `SELECT`, `INSERT`, `UPDATE`, `DELETE` em tabelas financeiras sensíveis.
- `authenticated` sem escrita direta em tabelas financeiras, salvo política específica formal e testada.
- Escrita financeira somente via RPC validada.
- Policies validam `empresa_id` via contexto confiável do usuário.
- Nenhuma policy confia em `empresa_id` enviado pelo frontend como autorização final.

### 5.2. RPCs fortes

Toda RPC financeira sensível deve seguir:

```sql
security definer
set search_path = public
```

Obrigatório:

- chamar helper de auth/contexto aplicável;
- obter contexto por `auth.uid()`;
- validar usuário ativo;
- validar empresa/tenant;
- validar empreendimento pertence à empresa;
- validar simulação pertence à empresa;
- validar perfil permitido;
- validar payload JSON item a item quando houver payload;
- rejeitar campos inválidos com erro explícito;
- não aceitar `empresa_id` do frontend como fonte soberana;
- retornar payload seguro conforme visão.

### 5.3. Grants

Padrão para RPC administrativa/financeira:

```sql
revoke all on function public.nome_da_rpc(...) from public;
revoke all on function public.nome_da_rpc(...) from anon;
grant execute on function public.nome_da_rpc(...) to authenticated;
```

`postgres` e `service_role` podem existir por necessidade operacional do Supabase, mas `service_role` não pode ser usado pelo frontend.

---

## 6. Plano de execução por fases

### Fase 4A — Agenda financeira JSON-first sem persistência

**Status:** aprovada.

Objetivo: transformar o fluxo bruto do MesaCliente em uma agenda financeira normalizada em JSON, sem DML financeiro.

RPC oficial aprovada:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

Evidência final:

```text
docs/mesa-cliente/fase-4a-validacao-final-json-first.md
```

Testes oficiais aprovados:

```text
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_financeira_json_first_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_financeira_json_first_negativos_rollback.sql
```

Aprovação comprovou:

- agenda JSON gerada corretamente;
- `cliente_safe=false`;
- `persistencia=false`;
- `dml_financeiro=false`;
- `anon` bloqueado;
- payload inválido bloqueado;
- `empresa_id` fake bloqueado;
- periodicidade simbólica não negociável;
- zero DML em `mesa_cliente_fluxo_parcelas`;
- zero DML em `mesa_cliente_fluxo_operacoes`.

### Fase 4B — Persistência segura da agenda financeira

**Status:** aprovada em rollback transacional.

Objetivo: persistir a agenda validada da 4A em cabeçalho versionado e parcelas vinculadas, com lock, idempotência e auditoria.

RPC oficial aprovada:

```sql
public.mesa_cliente_persistir_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

Observação: proposta anterior com `p_idempotency_key` foi substituída pela idempotência por checksum canônico calculado no banco.

Evidência final:

```text
docs/mesa-cliente/fase-4b-validacao-final-evidencias.md
```

Testes oficiais aprovados:

```text
supabase/tests/mesa-cliente/engenharia-financeira/08a_validacao_persistencia_agenda_financeira_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08b_validacao_persistencia_agenda_financeira_idempotencia_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08c_validacao_persistencia_agenda_financeira_negativos_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/08d_validacao_persistencia_agenda_financeira_operacao_confirmada_rollback.sql
```

Aprovação comprovou:

- criação de cabeçalho em `mesa_cliente_agendas_financeiras`;
- criação de parcelas em `mesa_cliente_fluxo_parcelas`;
- retorno administrativo `cliente_safe=false`;
- idempotência sem duplicar agenda ou parcelas;
- `anon` bloqueado;
- payload inválido bloqueado;
- `empresa_id` fake bloqueado;
- zero DML em `mesa_cliente_fluxo_operacoes`, exceto fixture transacional controlada no 08D;
- operação confirmada bloqueia substituição de agenda com `SQLSTATE 55000`;
- agenda original permanece intacta;
- tudo validado com `BEGIN + ROLLBACK`.

### Fase 4C — Leitura cliente-safe da agenda financeira persistida

**Status:** contrato aberto.

Objetivo: permitir leitura segura da agenda persistida sem expor campos administrativos.

Contrato atual:

```text
docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md
```

RPC candidata:

```sql
public.mesa_cliente_obter_agenda_financeira_cliente_safe(
  p_simulacao_id uuid
)
returns jsonb
```

Preflight já criado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/09_preflight_agenda_financeira_cliente_safe_readonly.sql
```

Próxima ação obrigatória:

```text
Executar o 09 preflight no Supabase SQL Editor e enviar o resultset completo antes de criar qualquer migration/RPC 4C.
```

Cliente-safe pode exibir:

- grupo;
- descrição comercial limpa;
- valor;
- data de vencimento;
- número da parcela;
- total de parcelas do item;
- status/resumo comercial neutro;
- avisos sem regra interna.

Cliente-safe não pode exibir:

- VPL;
- taxa interna;
- prêmio;
- comissão;
- política;
- impacto administrativo;
- metadata bruta;
- checksum;
- versão interna, salvo decisão formal;
- payload bruto;
- IDs internos desnecessários;
- motivos de bloqueio internos que revelem regra comercial.

### Fase 5A — Simular impacto financeiro com agenda persistida

**Status:** pendente.

Objetivo: usar a agenda persistida como base para simular antecipação/postergação/impacto financeiro administrativo.

Só começa depois da 4C validada, salvo decisão formal em contrário.

### Fase 5B — RPC registrar operação financeira

**Status:** pendente.

Objetivo futuro: persistir operação financeira simulada/aprovada em `mesa_cliente_fluxo_operacoes`.

### Fase 5C — RPC confirmar/cancelar operação financeira

**Status:** pendente.

Objetivo futuro: permitir confirmação/cancelamento controlado por gestor/admin/coordenador.

### Fase 6 — Resumos admin e cliente-safe

**Status:** pendente.

Objetivo: separar visão administrativa e visão cliente.

### Fase 7 — Integração front/BFF

**Status:** pendente.

Opção preferencial para segurança máxima:

```text
Frontend -> BFF/API server-side -> Supabase RPC -> resposta sanitizada
```

Proibido antes da 4C aprovada:

- tela final cliente-safe;
- BFF consumindo RPC ainda não validada;
- frontend chamando tabela financeira diretamente;
- frontend calculando regra financeira soberana.

### Fase 8 — Testes integrados

**Status:** pendente.

Deve validar ponta a ponta após as fases 4C/5A/5B/5C.

### Fase 9 — Hardening final antes de mesa real

**Status:** pendente.

Checklist obrigatório antes de teste real com cliente.

### Fase 10 — Piloto controlado em mesa

**Status:** pendente.

Executar somente após validação cliente-safe e trilha de operação financeira.

---

## 7. Sequência oficial atual dos próximos arquivos

Próxima sequência permitida:

```text
1. Executar:
   supabase/tests/mesa-cliente/engenharia-financeira/09_preflight_agenda_financeira_cliente_safe_readonly.sql

2. Validar resultset completo do 09 preflight.

3. Se o preflight liberar, criar:
   supabase/migrations/<timestamp>_mesa_cliente_fase_4c_agenda_financeira_cliente_safe.sql

4. Criar testes 4C:
   supabase/tests/mesa-cliente/engenharia-financeira/09a_validacao_agenda_financeira_cliente_safe_rollback.sql
   supabase/tests/mesa-cliente/engenharia-financeira/09b_validacao_agenda_financeira_cliente_safe_negativos_rollback.sql
   supabase/tests/mesa-cliente/engenharia-financeira/09c_validacao_agenda_financeira_cliente_safe_sem_vazamento_rollback.sql
```

Não criar arquivos de Fase 5 antes da Fase 4C ser validada.

---

## 8. Gates de aprovação

| Gate | Condição |
|---|---|
| Gate Contrato | fase, escopo, fora de escopo e matriz de DML definidos |
| Gate Preflight | schema real, grants, RLS e riscos mapeados antes da migration |
| Gate Banco | migration criada e revisada |
| Gate RLS | policies e grants revisados |
| Gate Auth | `auth.uid()` validado em teste |
| Gate Tenant | cross-tenant bloqueado |
| Gate Zero DML | obrigatório para Fase 4A e leituras cliente-safe |
| Gate Persistência | obrigatório para 4B, sem DML em operações |
| Gate Cliente-safe | payload sem VPL/prêmio/comissão/política/metadata bruta |
| Gate Front | sem regra financeira soberana no client |
| Gate Mesa | piloto interno aprovado |

---

## 9. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| frontend manipular payload | recalcular/validar tudo na RPC |
| corretor acessar empresa errada | contexto + RLS + helper + teste cross-tenant |
| `anon` executar RPC sensível | revoke de `anon` + teste automático |
| regra financeira hardcoded | política em banco e snapshot de política |
| cliente ver dado interno | RPC cliente-safe separada + teste 09C sem vazamento |
| alteração quebrar parser atual | não alterar parser sem autorização |
| gravação irreversível em produção única | testes com rollback e backup antes de fase crítica |
| cálculo divergente por data | matriz de datas e testes de último dia válido |
| operação confirmada editável | bloqueio 08D e fluxo futuro de cancelamento auditado |
| documento antigo induzir implementação errada | roadmap atualizado + evidências finais + README de testes atualizado |

---

## 10. Definição de pronto final

A Engenharia Financeira estará pronta para teste em mesa com cliente quando:

1. 4A JSON-first estiver validada — concluído;
2. 4B persistência segura estiver validada — concluído em rollback transacional;
3. 4C cliente-safe estiver validada — pendente;
4. simulação administrativa estiver integrada à agenda persistida — pendente;
5. operação financeira puder ser registrada por RPC forte — pendente;
6. confirmação/cancelamento estiverem auditados — pendente;
7. visão cliente-safe estiver limpa — pendente;
8. frontend não tiver regra financeira soberana — pendente;
9. `anon` estiver bloqueado em RPCs/tabelas sensíveis — em validação contínua;
10. cross-tenant estiver bloqueado — em validação contínua;
11. todos os testes SQL com rollback passarem;
12. piloto interno bater com cálculo manual;
13. backup pré-piloto estiver feito;
14. branch continuar isolada até aprovação explícita para merge.

---

## 11. Próxima ação imediata

A próxima ação não é criar nova migration.

A próxima ação é executar o preflight 09 já criado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/09_preflight_agenda_financeira_cliente_safe_readonly.sql
```

Enviar o resultset completo, principalmente a seção:

```text
13_operational_interpretation
```

Somente se o resultado liberar a 4C, criar a migration da RPC cliente-safe.

Frase de controle atual:

> **4A aprovada. 4B aprovada em rollback transacional. 4C aberta por contrato. 09 preflight cliente-safe já criado; próxima ação é executar e validar o resultset antes de qualquer migration 4C.**
