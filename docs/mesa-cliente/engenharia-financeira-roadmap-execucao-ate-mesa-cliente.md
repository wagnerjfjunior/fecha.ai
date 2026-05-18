# MesaCliente — Roadmap de execução da Engenharia Financeira até teste em mesa

**Status:** Oficial, atualizado para o contrato JSON-first da Fase 4A  
**Branch oficial de trabalho:** `feature/mesa-cliente-engenharia-financeira`  
**Atualizado em:** 2026-05-18  
**Protocolo obrigatório:** `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`  
**ADR vigente:** `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`  
**Contrato canônico da Fase 4A:** `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`  

---

## 0. Aviso de atualização

Este roadmap substitui a leitura anterior que tratava a Fase 4A como persistência direta em `mesa_cliente_fluxo_parcelas`.

A decisão oficial agora é:

```txt
4A = gerar agenda financeira em JSON, sem persistir
4B = persistir agenda com lock, idempotência e auditoria
4C = leitura cliente-safe
5A = simular impacto financeiro com agenda persistida
5B = registrar operação financeira
5C = confirmar/cancelar operação
Depois = integração front/BFF
```

Regra curta:

> **4A pensa. 4B grava. 4C mostra para o cliente.**

Qualquer referência antiga a persistência, recriação, `INSERT`, `UPDATE` ou `DELETE` de agenda dentro da Fase 4A está substituída por este roadmap, pelo ADR-0001 e pelo contrato canônico JSON-first.

---

## 1. Princípios não negociáveis

1. Não levar desconto simples global para `main`.
2. Não alterar parser, motor financeiro atual, Worker, Make, n8n ou `main` sem autorização explícita.
3. O app é multiempresa e multitenant por desenho, não por convenção de frontend.
4. Banco/RPC é soberano. Frontend é consultivo e nunca deve decidir regra financeira.
5. Nenhuma regra financeira hardcoded no frontend.
6. RLS obrigatória nas tabelas financeiras.
7. `auth.uid()` obrigatório em todas as RPCs sensíveis.
8. Toda RPC deve validar usuário, empresa, tenant, empreendimento, simulação e perfil.
9. Cliente nunca vê VPL, prêmio, comissão, política interna, impacto administrativo ou regra de remuneração.
10. Corretor/coordenador pode ver impacto administrativo conforme perfil e autorização.
11. Antecipação e postergação usam cálculo composto, mas isso não pertence à Fase 4A.
12. Data do ato é a base de cálculo quando a tabela não trouxer data oficial.
13. Data oficial da tabela prevalece sobre regra calculada.
14. Quando houver apenas mês/ano, usar o dia do ato; se o mês não possuir o dia, usar o último dia válido.
15. Chaves/parcela única devem vir da tabela ou cabeçalho, podendo ser 30 ou 60 dias antes do financiamento.
16. Periodicidade simbólica não entra como parcela negociável.
17. `anon` não executa RPC financeira administrativa ou de escrita.
18. `service_role` nunca pode aparecer em frontend, variável pública, build client-side, storage público, log ou payload de navegador.
19. Operações financeiras de escrita devem passar por RPCs fortes, com validação interna e least privilege.
20. Todo teste em produção única deve usar `BEGIN` + `ROLLBACK` até a liberação final.
21. Toda fase precisa respeitar seu escopo; fase misturada é falha de engenharia.
22. Nenhuma migration obsoleta deve permanecer como canônica em `supabase/migrations`.

---

## 2. Status atual consolidado

| Área | Status |
|---|---:|
| Backup local antes da engenharia financeira | Concluído |
| Branch de trabalho isolada | Concluído |
| Documentação de arquitetura | Concluído |
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
| Fase 4A — agenda financeira JSON-first sem persistência | Pendente |
| Fase 4B — persistência segura da agenda financeira | Pendente |
| Fase 4C — leitura cliente-safe da agenda | Pendente |
| Registro/confirmacão de operação financeira | Pendente |
| Visão cliente-safe final | Pendente |
| Integração de frontend/BFF | Pendente |
| Teste controlado em mesa com cliente | Pendente |

---

## 3. Arquitetura alvo atualizada até a mesa com cliente

Fluxo alvo atualizado:

```text
Tabela/PDF/entrada atual
  -> parser atual preservado
  -> payload financeiro bruto
  -> Fase 4A: RPC gera agenda normalizada em JSON, sem persistir
  -> validação de datas, grupos, periodicidade e segurança
  -> Fase 4B: persistência da agenda em mesa_cliente_fluxo_parcelas com lock/idempotência/auditoria
  -> Fase 4C: leitura cliente-safe da agenda
  -> Fase 5A: simular impacto financeiro com agenda persistida
  -> Fase 5B: registrar operação financeira
  -> Fase 5C: confirmar/cancelar operação financeira
  -> visão cliente-safe
  -> integração front/BFF
  -> tela MesaCliente para atendimento
```

O frontend não deve montar cálculo soberano. Ele pode exibir, solicitar simulação e renderizar o retorno seguro. Toda decisão final de elegibilidade, datas, política, limite de VPL, prêmio e gravação permanece no banco/RPC/BFF autorizado.

---

## 4. Modelo de segurança DevSecOps

### 4.1. Banco e RLS

Todas as tabelas sensíveis devem manter RLS ativo:

- `mesa_cliente_politicas_financeiras`
- `mesa_cliente_politica_premio_faixas`
- `mesa_cliente_fluxo_parcelas`
- `mesa_cliente_fluxo_operacoes`
- tabelas futuras de snapshot/auditoria financeira, se criadas

Regras:

- `anon` sem `SELECT`, `INSERT`, `UPDATE`, `DELETE` nessas tabelas.
- `authenticated` não deve ter escrita direta nas tabelas financeiras.
- Escrita financeira somente via RPC validada.
- Policies devem validar `empresa_id` via contexto confiável do usuário.
- Nenhuma policy pode confiar em `empresa_id` enviado pelo frontend como autorização final.

### 4.2. RPCs fortes

Toda RPC financeira sensível deve seguir este padrão:

```sql
security definer
set search_path = public
```

Obrigatório:

- chamar `mesa_cliente_assert_auth()`, se helper confirmado no schema;
- obter contexto por `auth.uid()`;
- validar usuário ativo;
- validar empresa/tenant;
- validar empreendimento pertence à empresa;
- validar simulação pertence à empresa;
- validar perfil permitido;
- validar payload JSON item a item;
- rejeitar campos inválidos com erro explícito;
- não aceitar `empresa_id` do frontend como fonte soberana;
- retornar payload seguro conforme tipo de visão.

### 4.3. Grants

Padrão para RPC administrativa/financeira:

```sql
revoke all on function public.nome_da_rpc(...) from public;
revoke all on function public.nome_da_rpc(...) from anon;
grant execute on function public.nome_da_rpc(...) to authenticated;
```

`postgres` e `service_role` podem existir por necessidade operacional do Supabase, mas `service_role` não pode ser usado pelo frontend.

### 4.4. Sem chave sensível no frontend

Proibido:

- `service_role` no frontend;
- secrets em `.env` público;
- tokens administrativos em browser;
- chave hardcoded em JS/HTML;
- endpoints que aceitam operação financeira sem sessão autenticada;
- RPC financeira com `EXECUTE` para `anon`.

### 4.5. Auditoria e rastreabilidade

Toda gravação financeira futura deve registrar:

- `empresa_id` resolvido no banco;
- `empreendimento_id` validado;
- `simulacao_id`;
- `politica_id` utilizada, quando aplicável;
- `criado_por = auth.uid()` ou corretor resolvido pelo contexto;
- timestamp;
- payload de origem sanitizado;
- snapshot do cálculo no `metadata` quando necessário;
- status da operação;
- confirmação por perfil autorizado.

---

## 5. Plano de execução por fases

### Fase 4A — RPC de agenda financeira JSON-first sem persistência

Objetivo: transformar o fluxo bruto do MesaCliente em uma agenda financeira normalizada em JSON, **sem DML financeiro**.

RPC oficial:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

Entregáveis:

1. Migration: `supabase/migrations/<timestamp>_mesa_cliente_fase_4a_agenda_financeira_json_first.sql`
2. Teste positivo rollback: `supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_financeira_json_first_rollback.sql`
3. Teste negativo rollback: `supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_financeira_json_first_negativos_rollback.sql`
4. Preflight read-only de grants/RLS da RPC.

Validações obrigatórias:

- `p_simulacao_id` obrigatório;
- `p_data_ato` obrigatório;
- `p_fluxo_json` deve ser array ou objeto conhecido;
- simulação deve existir;
- simulação deve pertencer à empresa do usuário;
- empreendimento da simulação deve pertencer à empresa;
- usuário precisa acessar empresa;
- perfil precisa ser autorizado;
- payload deve ser validado item a item;
- valores financeiros negativos devem ser bloqueados;
- grupos desconhecidos devem ser bloqueados;
- `empresa_id` no payload deve ser ignorado ou rejeitado, nunca usado como autoridade.

Proibido na Fase 4A:

- `INSERT`, `UPDATE` ou `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `INSERT`, `UPDATE` ou `DELETE` em `mesa_cliente_fluxo_operacoes`;
- criação de operação financeira;
- persistência definitiva de agenda;
- cálculo ou exposição de VPL/prêmio/comissão/política interna;
- alteração de frontend/parser/Worker/Make/n8n.

Regras de datas:

| Cenário | Regra |
|---|---|
| data oficial completa | prevalece sempre |
| data comercial completa | usar data informada |
| apenas mês/ano | usar dia do ato; se inválido, último dia do mês |
| chaves por cabeçalho 30 dias | 30 dias antes do financiamento/data base aplicável |
| chaves por cabeçalho 60 dias | 60 dias antes do financiamento/data base aplicável |
| sem informação confiável | bloquear ou marcar como estimada conforme contrato da RPC |

Critério de pronto:

- agenda JSON gerada corretamente;
- datas batem com casos extremos;
- periodicidade simbólica retorna flags negociáveis falsas;
- `anon` não executa;
- teste 07A passa;
- teste 07B passa;
- `count_before = count_after` em `mesa_cliente_fluxo_parcelas`;
- `count_before = count_after` em `mesa_cliente_fluxo_operacoes`.

### Fase 4B — Persistência segura da agenda financeira

Objetivo: persistir a agenda validada em `mesa_cliente_fluxo_parcelas` com segurança.

Só pode começar depois da Fase 4A aprovada.

Requisitos esperados:

- lock por `simulacao_id`;
- idempotência;
- auditoria;
- bloqueio contra alteração se houver operação confirmada;
- validação de tenant/empresa/perfil;
- rollback test;
- nenhum dado soberano vindo do frontend.

### Fase 4C — RPC cliente-safe de leitura da agenda

Objetivo: permitir que o frontend leia a agenda sem expor campos administrativos.

Entregáveis esperados:

1. RPC cliente-safe: `mesa_cliente_obter_agenda_cliente_safe(p_simulacao_id uuid)`
2. RPC/admin: `mesa_cliente_obter_agenda_admin(p_simulacao_id uuid)`, se necessário
3. Testes de diferença entre visão cliente e visão admin.

Cliente-safe pode exibir:

- grupo;
- descrição;
- valor atual;
- data atual;
- origem amigável da data;
- ordem;
- flags visuais sem regra interna.

Cliente-safe não pode exibir:

- VPL;
- taxa;
- prêmio;
- comissão;
- política;
- impacto administrativo;
- metadata interna sensível;
- IDs internos desnecessários.

### Fase 5A — Simular impacto financeiro com agenda persistida

Objetivo: usar a agenda persistida como base para simular antecipação/postergação/impacto financeiro administrativo.

Regras:

- não confiar em valores calculados pelo frontend;
- usar política vigente no banco;
- retornar visão administrativa segura;
- nunca retornar dados internos para cliente-safe.

### Fase 5B — RPC registrar operação financeira

Objetivo: persistir uma operação financeira simulada/aprovada em `mesa_cliente_fluxo_operacoes`.

Estratégia:

- chamar internamente a simulação administrativa;
- só gravar operações válidas;
- gravar `status_operacao = 'simulada'` ou `pendente_confirmacao`, conforme contrato da fase;
- `visivel_cliente = false` por padrão;
- `confirmado = false` por padrão;
- preencher `metadata` com snapshot sanitizado do cálculo;
- nunca aceitar valores calculados enviados pelo frontend como verdade.

### Fase 5C — RPC confirmar/cancelar operação financeira

Objetivo: permitir confirmação/cancelamento controlado por gestor/admin/coordenador.

Regras:

- somente perfil autorizado confirma;
- operação precisa pertencer à empresa do usuário;
- operação não pode estar cancelada;
- confirmação grava `confirmado = true`, `confirmado_por = auth.uid()`, `confirmado_em = now()`;
- operação confirmada não pode ser editada diretamente;
- cancelamento deve preservar histórico.

### Fase 6 — Resumos admin e cliente-safe

Objetivo: separar claramente visão administrativa e visão cliente.

Admin pode ver, conforme perfil:

- total original;
- total calculado;
- desconto;
- acréscimo;
- economia;
- maior impacto percentual;
- status de prêmio;
- prêmio do corretor, se perfil permitir;
- operações pendentes/confirmadas/canceladas.

Cliente-safe pode ver:

- fluxo de pagamento;
- valores finais aprovados;
- datas;
- condições comerciais aprovadas;
- observações comerciais seguras.

Cliente-safe nunca vê:

- `politica_id`;
- VPL;
- taxa interna;
- comissão;
- prêmio;
- desconto administrativo;
- impacto de remuneração;
- payload bruto de cálculo.

### Fase 7 — Integração front/BFF

Objetivo: integrar a tela sem vazar regra nem chave sensível.

Opção preferencial para segurança máxima:

```text
Frontend -> BFF/API server-side -> Supabase RPC -> resposta sanitizada
```

Regras:

- frontend não calcula VPL;
- frontend não chama tabela financeira diretamente;
- frontend não possui `service_role`;
- frontend não usa payload interno como fonte soberana;
- logs não podem imprimir payload sensível completo;
- erros exibidos ao cliente devem ser amigáveis e sem stack trace.

### Fase 8 — Testes integrados

Testes mínimos obrigatórios:

| Teste | Objetivo |
|---|---|
| `09a_e2e_agenda_simulacao_registro_rollback.sql` | agenda -> simulação -> registro |
| `09b_e2e_confirmacao_rollback.sql` | registro -> confirmação |
| `09c_e2e_cliente_safe_rollback.sql` | validar visão segura |
| `09d_e2e_cross_tenant_bloqueado.sql` | bloquear empresa errada |
| `09e_e2e_anon_bloqueado.sql` | bloquear anon |
| `09f_e2e_payload_malicioso.sql` | bloquear manipulação de JSON |
| `09g_e2e_periodicidade_simbolica.sql` | garantir que periodicidade não negocia |
| `09h_e2e_data_rules.sql` | datas oficiais/mês/ano/último dia válido |

### Fase 9 — Hardening final antes de mesa real

Checklist:

- `anon` sem execute em RPCs administrativas;
- `anon` sem grants nas tabelas financeiras;
- `authenticated` sem escrita direta em tabelas financeiras;
- RPCs com `security definer` e `search_path=public`;
- todos os inserts resolvem `empresa_id` no banco;
- logs sem segredo;
- front sem service role;
- front sem cálculo soberano;
- payload cliente-safe revisado;
- rollback local documentado;
- backup atualizado antes do teste;
- branch ainda isolada, sem merge na `main`.

### Fase 10 — piloto controlado em mesa

Antes do primeiro cliente real, executar um piloto interno:

1. escolher um empreendimento real de baixo risco;
2. usar uma simulação conhecida;
3. gerar agenda JSON-first;
4. persistir agenda somente após 4B validada;
5. simular uma antecipação;
6. simular uma postergação;
7. registrar operação;
8. confirmar operação;
9. abrir visão cliente-safe;
10. comparar com cálculo manual;
11. validar se a tela não expõe dado interno.

---

## 6. Sequência recomendada dos próximos arquivos

Ordem de criação atualizada:

```text
supabase/migrations/...
  <timestamp>_mesa_cliente_fase_4a_agenda_financeira_json_first.sql
  <timestamp>_mesa_cliente_fase_4b_persistir_agenda_financeira.sql
  <timestamp>_mesa_cliente_fase_4c_obter_agenda_cliente_safe.sql
  <timestamp>_mesa_cliente_fase_5b_registrar_operacao_financeira.sql
  <timestamp>_mesa_cliente_fase_5c_confirmar_cancelar_operacao_financeira.sql
  <timestamp>_mesa_cliente_fase_6_resumos_admin_cliente_safe.sql

supabase/tests/mesa-cliente/engenharia-financeira/...
  07a_validacao_agenda_financeira_json_first_rollback.sql
  07b_validacao_agenda_financeira_json_first_negativos_rollback.sql
  08a_validacao_persistir_agenda_financeira_rollback.sql
  08b_validacao_persistir_agenda_financeira_negativos_rollback.sql
  09a_validacao_registrar_operacao_financeira_rollback.sql
  09b_validacao_registrar_operacao_financeira_negativos_rollback.sql
  10a_validacao_confirmar_cancelar_operacao_rollback.sql
  10b_validacao_cliente_safe_sem_dados_internos.sql
```

---

## 7. Gates de aprovação

Nenhuma fase avança sem cumprir seu gate.

| Gate | Condição |
|---|---|
| Gate Contrato | fase, escopo, fora de escopo e matriz de DML definidos |
| Gate Banco | migration criada e revisada |
| Gate RLS | policies e grants revisados |
| Gate Auth | `auth.uid()` validado em teste |
| Gate Tenant | cross-tenant bloqueado |
| Gate Zero DML | obrigatório para Fase 4A |
| Gate Cálculo | cálculo composto bate com expectativa, quando a fase envolver cálculo |
| Gate Cliente-safe | payload sem VPL/prêmio/comissão |
| Gate Front | sem regra financeira soberana no client |
| Gate Mesa | piloto interno aprovado |

---

## 8. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| frontend manipular payload | recalcular/validar tudo na RPC |
| corretor acessar empresa errada | validar contexto + RLS + helper |
| `anon` executar RPC sensível | revoke de `anon` + teste automático |
| regra financeira hardcoded | política em banco e snapshot de política |
| cliente ver dado interno | RPC cliente-safe separada |
| alteração quebrar parser atual | não alterar parser sem autorização |
| gravação irreversível em produção única | 4A JSON-first, testes com rollback e backup antes de fase crítica |
| cálculo divergente por data | matriz de datas e testes de último dia válido |
| operação confirmada editável | status imutável ou cancelamento auditado |
| documento antigo induzir implementação errada | ADR + contrato canônico + obsolescência explícita |

---

## 9. Definição de pronto final

A Engenharia Financeira estará pronta para teste em mesa com cliente quando:

1. agenda JSON-first tiver sido validada sem DML;
2. agenda persistida tiver sido criada somente na Fase 4B;
3. simulação administrativa estiver integrada à agenda persistida;
4. operação financeira puder ser registrada por RPC forte;
5. confirmação/cancelamento estiverem auditados;
6. visão cliente-safe estiver limpa;
7. frontend não tiver regra financeira soberana;
8. `anon` estiver bloqueado em RPCs/tabelas sensíveis;
9. cross-tenant estiver bloqueado;
10. todos os testes SQL com rollback passarem;
11. piloto interno bater com cálculo manual;
12. backup pré-piloto estiver feito;
13. branch continuar isolada até aprovação explícita para merge.

---

## 10. Próxima ação imediata

A próxima implementação deve ser a Fase 4A canônica:

```text
Criar RPC mesa_cliente_gerar_agenda_financeira_admin
Criar teste 07a_validacao_agenda_financeira_json_first_rollback
Criar teste 07b_validacao_agenda_financeira_json_first_negativos_rollback
Executar em produção única apenas com BEGIN + ROLLBACK
Validar count_before = count_after nas tabelas financeiras
```

Não iniciar frontend antes da agenda financeira, da persistência segura e das RPCs de visão segura estarem estabilizadas. Frontend bonito sem banco blindado vira vitrine de shopping com cofre aberto no fundo.
