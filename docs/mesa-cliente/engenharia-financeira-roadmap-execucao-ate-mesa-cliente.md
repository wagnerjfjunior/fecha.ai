# MesaCliente — Roadmap de execução da Engenharia Financeira até teste em mesa

**Status:** Oficial — atualizado após merge da Fase 5D na `main`  
**Branch oficial de alinhamento:** `feature/mesa-cliente-pos-5d-alinhamento-proxima-fase`  
**Base:** `main` pós-merge do PR #11 / merge commit `9784d4416adf02f50a4d66ca8f26a9228b8cfa75`  
**Atualizado em:** 2026-05-20  
**Protocolo obrigatório:** `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`  
**ADR vigente:** `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`

---

## 0. Aviso de atualização pós-5D

Este roadmap substitui o estado operacional antigo que ainda tratava 4C/5A/5B/5C como pendências.

A leitura oficial atual é:

```text
4A  = aprovada — agenda financeira JSON-first, sem persistência
4B  = aprovada — persistência segura da agenda financeira
4C  = aprovada — leitura cliente-safe da agenda persistida
5A.1 = aprovada — simulação administrativa de impacto com agenda persistida
5B  = aprovada — registro administrativo de operação financeira
5C  = fechada tecnicamente — confirmação/cancelamento administrativo de operação financeira
5D  = fechada tecnicamente e mergeada na main — leitura administrativa read-only de operações financeiras
Smoke 5D pós-produção = estrutural aprovado com SKIP_DATA por ausência de operação financeira real acessível
Próxima fase canônica = Fase 6 — resumos administrativos e visão cliente-safe de operação financeira / handoff para integração
```

Regra curta:

> **4A pensa. 4B grava agenda. 4C mostra agenda ao cliente. 5A simula impacto. 5B registra operação. 5C muda status. 5D consulta operação. 6 prepara resumo seguro para uso real.**

Qualquer documento antigo que trate 5B, 5C ou 5D como pendente está subordinado a este roadmap, aos documentos de fechamento das fases e ao Protocolo Mestre v1.2.

---

## 1. Hierarquia documental vigente

Ordem de referência para qualquer IA, dev ou conversa técnica:

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-validacao-final-json-first.md`
4. `docs/mesa-cliente/fase-4b-validacao-final-evidencias.md`
5. `docs/mesa-cliente/fase-4c-cliente-safe-fechamento.md`
6. `docs/mesa-cliente/fase-5a-validacao-final-simulacao-impacto-agenda-persistida.md`
7. `docs/mesa-cliente/fase-5b-fechamento-registro-operacao-financeira.md`
8. `docs/mesa-cliente/fase-5c-fechamento-tecnico.md`
9. `docs/mesa-cliente/fase-5d-fechamento-tecnico.md`
10. `docs/mesa-cliente/fase-5d-smoke-pos-producao.md`
11. `docs/mesa-cliente/fase-5d-smoke-pos-producao-execucao.md`
12. Este roadmap como índice operacional atualizado.

O roadmap é índice de navegação. Em caso de conflito entre roadmap e evidência final de fase, prevalece a evidência final mais recente, desde que compatível com o Protocolo Mestre.

---

## 2. Princípios não negociáveis

1. Não levar desconto simples global para `main`.
2. Não alterar parser, motor financeiro atual, Worker, Make, n8n ou frontend sem autorização explícita.
3. O app é multiempresa e multitenant por desenho, não por convenção de frontend.
4. Banco/RPC é soberano. Frontend é consultivo e nunca decide regra financeira.
5. Nenhuma regra financeira hardcoded no frontend.
6. RLS obrigatória nas tabelas financeiras.
7. `auth.uid()` obrigatório em RPCs sensíveis.
8. Toda RPC deve validar usuário, empresa, tenant, empreendimento, simulação e perfil.
9. Cliente nunca vê VPL, prêmio, comissão, política interna, impacto administrativo ou regra de remuneração.
10. Corretor/coordenador/gestor/admin pode ver impacto administrativo conforme perfil e autorização no banco.
11. Data oficial da tabela prevalece sobre regra calculada.
12. Quando houver apenas mês/ano, usar o dia do ato; se o mês não possuir o dia, usar o último dia válido.
13. Chaves/parcela única devem vir da tabela ou cabeçalho, podendo ser 30 ou 60 dias antes do financiamento quando o contrato permitir.
14. Periodicidade simbólica não entra como parcela negociável.
15. `anon` não executa RPC financeira administrativa ou de escrita.
16. `service_role` nunca aparece em frontend, variável pública, build client-side, storage público, log ou payload de navegador.
17. Operações financeiras de escrita passam por RPCs fortes, com validação interna e least privilege.
18. Teste em produção única usa `BEGIN` + `ROLLBACK` até liberação formal.
19. Smoke pós-produção não cria fixture, não cria função temporária e não executa DDL/DML.
20. Toda fase precisa respeitar seu escopo; fase misturada é falha de engenharia.
21. Migration obsoleta não permanece como canônica em `supabase/migrations`.
22. Documento antigo não pode contrariar evidência final de fase aprovada.
23. Não contornar teste removendo cobertura crítica; corrigir a causa mantendo a intenção de validação.

---

## 3. Status atual consolidado

| Área | Status |
|---|---:|
| Backup local antes da engenharia financeira | Concluído |
| Branches isoladas por fase | Concluído |
| Protocolo Mestre FECH.AI / MesaCliente v1.2 | Concluído |
| Protocolo Universal de Funcionamento v1.1 | Concluído |
| ADR-0001 — Fase 4A JSON-first sem persistência | Concluído |
| Tabelas financeiras base | Concluído |
| RLS das tabelas financeiras | Concluído |
| Helpers de contexto/autorização | Concluído |
| RPCs administrativas de política/faixas | Concluído |
| Funções puras de cálculo composto | Concluído |
| RPC de simulação administrativa sem gravação | Concluído |
| Grants endurecidos sem `anon` | Concluído |
| Fase 4A — agenda financeira JSON-first sem persistência | Aprovada |
| Fase 4B — persistência segura da agenda financeira | Aprovada |
| Fase 4C — leitura cliente-safe da agenda persistida | Aprovada |
| Fase 5A.1 — simulação de impacto com agenda persistida | Aprovada |
| Fase 5B — registro de operação financeira | Aprovada |
| Fase 5C — confirmação/cancelamento de operação financeira | Fechada tecnicamente |
| Fase 5D — leitura administrativa de operações financeiras | Fechada tecnicamente e mergeada na `main` |
| Smoke 5D pós-produção | Aprovado estruturalmente com `SKIP_DATA` por ausência de massa real |
| Smoke 5D funcional com operação real | Pendente por ausência de operação financeira real acessível |
| Fase 6 — resumos admin e cliente-safe / handoff | Próxima fase canônica |
| Integração frontend/BFF | Pendente — proibida antes do contrato e testes da Fase 6 |
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
  -> Fase 5A.1: RPC simula impacto financeiro administrativo com agenda persistida
  -> Fase 5B: RPC registra operação financeira simulada
  -> Fase 5C: RPC confirma/cancela operação financeira simulada
  -> Fase 5D: RPC lista/obtém operações financeiras em visão administrativa read-only
  -> Fase 6: RPC/contrato de resumo administrativo e visão cliente-safe de operação financeira
  -> integração BFF/front somente após contrato e testes da Fase 6
  -> teste controlado em mesa
```

O frontend não monta cálculo soberano. Ele pode exibir, solicitar simulação e renderizar retorno seguro. Toda decisão final de elegibilidade, datas, política, limite de VPL, prêmio, gravação, confirmação e publicação permanece no banco/RPC/BFF autorizado.

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
- futuras tabelas de snapshot/auditoria/publicação financeira

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
- validar agenda/operação/parcela pertence ao mesmo escopo;
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

Testes oficiais aprovados:

```text
07a_validacao_agenda_financeira_json_first_rollback.sql
07b_validacao_agenda_financeira_json_first_negativos_rollback.sql
```

### Fase 4B — Persistência segura da agenda financeira

**Status:** aprovada.

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

Testes oficiais aprovados:

```text
08a_validacao_persistencia_agenda_financeira_rollback.sql
08b_validacao_persistencia_agenda_financeira_idempotencia_rollback.sql
08c_validacao_persistencia_agenda_financeira_negativos_rollback.sql
08d_validacao_persistencia_agenda_financeira_operacao_confirmada_rollback.sql
```

### Fase 4C — Leitura cliente-safe da agenda financeira persistida

**Status:** aprovada.

Objetivo: permitir leitura segura da agenda persistida sem expor campos administrativos.

Contrato cliente-safe aprovado:

```text
cliente_safe=true
sem VPL
sem taxa interna
sem prêmio
sem comissão
sem política
sem impacto administrativo
sem metadata bruta
sem checksum
sem payload bruto
sem DML
```

### Fase 5A.1 — Simular impacto financeiro com agenda persistida

**Status:** aprovada.

RPC validada:

```text
public.mesa_cliente_simular_impacto_agenda_persistida_admin(uuid,date,text,jsonb)
```

Contrato validado:

```text
agenda-first
administrativa
cliente_safe=false
persistencia=false
dml_financeiro=false
sem alterar agenda, parcelas ou operações
```

Testes oficiais aprovados:

```text
10_preflight_simulacao_impacto_agenda_persistida_readonly.sql
10p_preparacao_base_minima_5a_agenda_persistida_rollback.sql
10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql
10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql
```

### Fase 5B — Registrar operação financeira administrativa

**Status:** aprovada em validação transacional.

RPC validada:

```sql
public.mesa_cliente_registrar_operacao_financeira_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid,
  p_tipo_operacao text,
  p_parcela_id uuid,
  p_data_referencia date default current_date,
  p_data_destino date default null,
  p_valor_operacao numeric default null,
  p_parametros jsonb default '{}'::jsonb
)
```

Contrato validado:

```text
fase = 5B_REGISTRO_OPERACAO_FINANCEIRA
visao = administrativa
escopo_dml = operacao_financeira
cliente_safe = false
persistencia = true
dml_financeiro = true
altera_agenda = false
altera_parcelas = false
```

Testes oficiais aprovados:

```text
11_preflight_registro_operacao_financeira_readonly.sql
11a_validacao_registro_operacao_financeira_rollback.sql
11b_validacao_registro_operacao_financeira_negativos_rollback.sql
11c_validacao_registro_operacao_financeira_idempotencia_rollback.sql
11d_validacao_registro_operacao_financeira_confirmada_rollback.sql
11e_validacao_registro_operacao_financeira_zero_mutacao_agenda_parcelas_rollback.sql
```

### Fase 5C — Confirmar/cancelar operação financeira

**Status:** fechada tecnicamente.

RPC validada:

```sql
public.mesa_cliente_atualizar_status_operacao_financeira_admin(
  p_operacao_id uuid,
  p_acao text,
  p_motivo text default null,
  p_parametros jsonb default '{}'::jsonb
)
```

Ações suportadas:

```text
confirmar
cancelar
```

Contrato validado:

```text
altera somente mesa_cliente_fluxo_operacoes
não altera agenda
não altera parcelas
não recalcula operação
não expõe ao cliente automaticamente
bloqueia anon
bloqueia payload autoritativo vindo do frontend
bloqueia cancelamento de operação confirmada nesta versão
```

Testes oficiais aprovados:

```text
12_preflight_confirmacao_cancelamento_operacao_financeira_readonly.sql
12a_validacao_confirmar_operacao_financeira_rollback.sql
12b_validacao_cancelar_operacao_financeira_simulada_rollback.sql
12c_validacao_negativos_seguranca_confirmacao_cancelamento_rollback.sql
12d_validacao_idempotencia_confirmacao_cancelamento_rollback.sql
12e_validacao_zero_mutacao_rigido_confirmacao_cancelamento_rollback.sql
```

### Fase 5D — Leitura administrativa de operações financeiras

**Status:** fechada tecnicamente e mergeada na `main`.

RPCs validadas:

```sql
public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)
public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
```

Contrato validado:

```text
read-only administrativo
cliente_safe=false
sem DML financeiro
sem alterar agenda
sem alterar parcelas
sem confirmar/cancelar operação
sem recalcular operação
sem exposição cliente-safe automática
validar auth.uid()
validar usuário ativo
validar perfil administrativo
validar tenant/empresa no banco
admin_global com escopo global
admin_local/gestor/coordenador limitado por empresa
allowlist para filtros, paginação e ordenação
```

Testes oficiais aprovados:

```text
13_preflight_leitura_operacoes_financeiras_admin_readonly.sql
13a_validacao_listar_operacoes_financeiras_admin_rollback.sql
13b_validacao_obter_operacao_financeira_admin_rollback.sql
13c_validacao_seguranca_leitura_operacoes_admin_rollback.sql
13cv2_validacao_seguranca_leitura_operacoes_admin_rollback.sql
13d_validacao_zero_dml_readonly_rigido_leitura_operacoes_admin_rollback.sql
13e_validacao_filtros_paginacao_ordenacao_leitura_operacoes_admin_rollback.sql
13_smoke_pos_producao_leitura_operacoes_admin_readonly.sql
```

Smoke pós-produção:

```text
Estrutural/read-only aprovado.
Resultado funcional com dado real = SKIP_DATA por ausência de operação financeira real acessível.
Não criar fixture diretamente em produção para forçar smoke.
Reexecutar smoke quando houver operação real criada pelo fluxo normal/controlado.
```

### Fase 6 — Resumos administrativos e visão cliente-safe / handoff para integração

**Status:** próxima fase canônica.

Objetivo: criar a camada de resumo e consumo seguro sobre a trilha já validada de agenda + operação financeira.

A Fase 6 deve separar, formalmente, pelo menos duas visões:

```text
1. Visão administrativa:
   resumo operacional interno para gestor/admin/coordenador/corretor autorizado.

2. Visão cliente-safe:
   resumo comercial limpo para atendimento em mesa, sem vazamento de regra interna.
```

A Fase 6 pode consumir dados das fases anteriores, mas não pode alterar o motor financeiro.

Fora do escopo inicial da Fase 6:

```text
alterar parser
alterar Worker/Make/n8n
alterar motor financeiro 4A/4B/5A/5B/5C/5D
criar cálculo no frontend
expor VPL/prêmio/comissão/política para cliente
publicar operação automaticamente ao cliente sem contrato de visibilidade
criar DML antes do contrato e preflight
```

Primeira ação obrigatória da Fase 6:

```text
Abrir contrato da Fase 6 e criar preflight read-only 14.
```

Arquivos previstos para iniciar a Fase 6:

```text
docs/mesa-cliente/fase-6-contrato-resumos-operacao-financeira.md
supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql
```

Migration 6 somente depois do contrato e do preflight aprovados.

### Fase 7 — Integração front/BFF

**Status:** pendente.

Opção preferencial para segurança máxima:

```text
Frontend -> BFF/API server-side -> Supabase RPC -> resposta sanitizada
```

Proibido antes da Fase 6 validada:

- tela final cliente-safe;
- BFF consumindo RPC ainda não validada;
- frontend chamando tabela financeira diretamente;
- frontend calculando regra financeira soberana.

### Fase 8 — Testes integrados

**Status:** pendente.

Deve validar ponta a ponta após as fases 4C/5A/5B/5C/5D/6.

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
1. Criar contrato da Fase 6:
   docs/mesa-cliente/fase-6-contrato-resumos-operacao-financeira.md

2. Criar preflight read-only 14:
   supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql

3. Executar o preflight 14 no Supabase SQL Editor.

4. Validar o resultset completo do preflight 14.

5. Somente se o preflight liberar, criar migration/RPCs da Fase 6.

6. Depois da Fase 6 validada, iniciar integração BFF/front.
```

Não criar arquivos de frontend antes da Fase 6 validar payload cliente-safe.

---

## 8. Gates de aprovação

| Gate | Condição |
|---|---|
| Gate Contrato | fase, escopo, fora de escopo e matriz de DML definidos |
| Gate Preflight | schema real, grants, RLS e riscos mapeados antes da migration |
| Gate Banco | migration criada e revisada somente após preflight |
| Gate RLS | policies e grants revisados |
| Gate Auth | `auth.uid()` validado em teste |
| Gate Tenant | cross-tenant bloqueado |
| Gate Zero DML | obrigatório para leituras e resumos read-only |
| Gate Persistência | obrigatório para fases de escrita, sem mutar agenda/parcela indevidamente |
| Gate Cliente-safe | payload sem VPL/prêmio/comissão/política/metadata bruta |
| Gate Admin-safe | payload administrativo autorizado apenas para perfil correto |
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
| cliente ver dado interno | RPC cliente-safe separada + teste sem vazamento |
| resumo cliente-safe vazar operação administrativa | contrato de visibilidade e sanitização explícita |
| alteração quebrar parser atual | não alterar parser sem autorização |
| gravação irreversível em produção única | testes com rollback e backup antes de fase crítica |
| cálculo divergente por data | matriz de datas e testes de último dia válido |
| operação confirmada editável | fluxo 5C bloqueia transições indevidas; futura reversão deve ter contrato próprio |
| documento antigo induzir implementação errada | roadmap atualizado + evidências finais + README de testes atualizado |

---

## 10. Definição de pronto final

A Engenharia Financeira estará pronta para teste em mesa com cliente quando:

1. 4A JSON-first estiver validada — concluído;
2. 4B persistência segura estiver validada — concluído;
3. 4C cliente-safe da agenda estiver validada — concluído;
4. simulação administrativa estiver integrada à agenda persistida — concluído;
5. operação financeira puder ser registrada por RPC forte — concluído;
6. confirmação/cancelamento estiverem auditados — concluído tecnicamente;
7. leitura administrativa de operações estiver validada — concluído tecnicamente;
8. smoke 5D funcional com operação real estiver reexecutado quando houver massa real — pendente operacional;
9. resumo cliente-safe de operação financeira estiver validado — pendente Fase 6;
10. frontend não tiver regra financeira soberana — pendente validação de integração;
11. `anon` estiver bloqueado em RPCs/tabelas sensíveis — validação contínua;
12. cross-tenant estiver bloqueado — validação contínua;
13. todos os testes SQL com rollback passarem;
14. piloto interno bater com cálculo manual;
15. backup pré-piloto estiver feito;
16. branch continuar isolada até aprovação explícita para merge.

---

## 11. Próxima ação imediata

A próxima ação não é criar migration e não é mexer no frontend.

A próxima ação é abrir o contrato da Fase 6 e o preflight read-only 14:

```text
docs/mesa-cliente/fase-6-contrato-resumos-operacao-financeira.md
supabase/tests/mesa-cliente/engenharia-financeira/14_preflight_resumos_operacao_financeira_readonly.sql
```

Frase de controle atual:

> **5D mergeada na main. Branch nova limpa. Próxima fase canônica: Fase 6 — resumos administrativos e visão cliente-safe de operação financeira. Primeiro contrato e preflight; migration só depois de evidência.**
