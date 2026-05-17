# MesaCliente — Roadmap de execução da Engenharia Financeira até teste em mesa

Branch oficial de trabalho: `feature/mesa-cliente-engenharia-financeira`.

Este documento define o plano executivo completo para levar a Engenharia Financeira do MesaCliente da fase atual até o primeiro teste controlado em mesa com cliente. Ele consolida a estratégia técnica, os gates de segurança, a sequência de migrations/RPCs, os testes obrigatórios e os critérios de liberação.

## 1. Princípios não negociáveis

1. Não levar desconto simples global para `main`.
2. Não alterar parser, motor financeiro atual, Worker, Make, n8n ou `main` sem autorização explícita.
3. O app é multiempresa e multitenant por desenho, não por convenção de frontend.
4. Banco/RPC é soberano. Frontend é consultivo e nunca deve decidir regra financeira.
5. Nenhuma regra financeira hardcoded no frontend.
6. RLS obrigatória nas tabelas financeiras.
7. `auth.uid()` obrigatório em todas as RPCs sensíveis.
8. Toda RPC deve validar usuário, empresa, tenant, empreendimento e perfil.
9. Cliente nunca vê VPL, prêmio, comissão, política interna, impacto administrativo ou regra de remuneração.
10. Corretor/coordenador pode ver impacto administrativo conforme perfil e autorização.
11. Antecipação e postergação usam cálculo composto.
12. Data do ato é a base de cálculo quando a tabela não trouxer data oficial.
13. Data oficial da tabela prevalece sobre regra calculada.
14. Quando houver apenas mês/ano, usar o dia do ato; se o mês não possuir o dia, usar o último dia válido.
15. Chaves/parcela única devem vir da tabela ou cabeçalho, podendo ser 30 ou 60 dias antes do financiamento.
16. Periodicidade simbólica não entra como parcela negociável.
17. `anon` não executa RPC financeira administrativa ou de escrita.
18. `service_role` nunca pode aparecer em frontend, variável pública, build client-side, storage público, log ou payload de navegador.
19. Operações financeiras de escrita devem passar por RPCs fortes, com validação interna e least privilege.
20. Todo teste em produção única deve usar `BEGIN` + `ROLLBACK` até a liberação final.

## 2. Status atual consolidado

| Área | Status |
|---|---:|
| Backup local antes da engenharia financeira | Concluído |
| Branch de trabalho isolada | Concluído |
| Documentação de arquitetura | Concluído |
| Plano técnico inicial | Concluído |
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
| Persistência de agenda financeira | Pendente |
| Registro/confirmacão de operação financeira | Pendente |
| Visão cliente-safe | Pendente |
| Integração de frontend | Pendente |
| Teste controlado em mesa com cliente | Pendente |

## 3. Arquitetura alvo até a mesa com cliente

Fluxo alvo:

```text
Tabela/PDF/entrada atual
  -> parser atual preservado
  -> payload financeiro bruto
  -> RPC gerar agenda de parcelas
  -> mesa_cliente_fluxo_parcelas
  -> RPC simular impacto financeiro admin
  -> revisão administrativa
  -> RPC registrar operação financeira
  -> mesa_cliente_fluxo_operacoes
  -> RPC confirmar operação financeira
  -> visão cliente-safe
  -> tela MesaCliente para atendimento
```

O frontend não deve montar cálculo soberano. Ele pode exibir, solicitar simulação e renderizar o retorno seguro. Toda decisão final de elegibilidade, datas, política, limite de VPL, prêmio e gravação permanece no banco.

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

- chamar `mesa_cliente_assert_auth()`;
- obter contexto por `auth.uid()`;
- validar usuário ativo;
- validar empresa;
- validar empreendimento pertence à empresa;
- validar perfil: admin global, admin local, gestor ou papel explicitamente permitido;
- validar política vigente quando houver cálculo financeiro;
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

Sobre arquitetura client-side: se houver uso de Supabase client no navegador, ele deve servir apenas para bootstrap autenticado com token de sessão, sem permissão real em tabelas financeiras. Para operações financeiras sensíveis, preferir BFF/API server-side ou RPC com JWT autenticado e RLS forte. Se a decisão do projeto for literalmente zero chave pública Supabase no browser, criar camada BFF antes de integrar a tela.

### 4.5. Auditoria e rastreabilidade

Toda gravação financeira deve registrar:

- `empresa_id` resolvido no banco;
- `empreendimento_id` validado;
- `simulacao_id`;
- `politica_id` utilizada;
- `criado_por = auth.uid()` ou corretor resolvido pelo contexto;
- timestamp;
- payload de origem sanitizado;
- snapshot do cálculo no `metadata` quando necessário;
- status da operação;
- confirmação por perfil autorizado.

## 5. Plano de execução por fases

### Fase 4A — RPC de agenda financeira

Objetivo: transformar o fluxo bruto do MesaCliente em parcelas datadas dentro de `mesa_cliente_fluxo_parcelas`.

Entregáveis:

1. Migration: `supabase/migrations/*_mesa_cliente_rpc_gerar_agenda_parcelas.sql`
2. Teste rollback: `supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_parcelas_rollback.sql`
3. Preflight read-only de grants/RLS da RPC.

RPC proposta:

```sql
public.gerar_mesa_cliente_agenda_parcelas(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
```

Validações obrigatórias:

- `p_simulacao_id` obrigatório;
- `p_data_ato` obrigatório;
- `p_fluxo_json` deve ser array ou objeto conhecido;
- simulação deve existir;
- simulação deve pertencer à empresa do usuário;
- empreendimento da simulação deve pertencer à empresa;
- usuário precisa acessar empresa;
- se agenda anterior existir para a simulação, a RPC deve ser idempotente: apagar e recriar, ou versionar conforme decisão explícita.

Regras de datas:

| Cenário | Origem gravada | Regra |
|---|---|---|
| data oficial completa | `tabela_oficial` | prevalece sempre |
| data comercial completa | `tabela_comercial_data` | usar data informada |
| apenas mês/ano | `tabela_comercial_mes` | usar dia do ato; se inválido, último dia do mês |
| chaves por cabeçalho 30 dias | `cabecalho_regra` | `regra_data = cabecalho_30_dias` |
| chaves por cabeçalho 60 dias | `cabecalho_regra` | `regra_data = cabecalho_60_dias` |
| data estimada pelo ato | `calculada_ato` | usar base do ato |

Critério de pronto:

- agenda gera parcelas corretas;
- datas batem com casos extremos;
- periodicidade simbólica é gravada com `eh_periodicidade_simbolica = true` e flags negociáveis falsas;
- `anon` não executa;
- teste com rollback passa 100%.

### Fase 4B — RPC cliente-safe de leitura da agenda

Objetivo: permitir que o frontend leia a agenda sem expor campos administrativos.

Entregáveis:

1. RPC: `mesa_cliente_obter_agenda_cliente_safe(p_simulacao_id uuid)`
2. RPC/admin: `mesa_cliente_obter_agenda_admin(p_simulacao_id uuid)`
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

### Fase 5A — RPC registrar operação financeira

Objetivo: persistir uma operação financeira simulada/aprovada em `mesa_cliente_fluxo_operacoes`.

Entregáveis:

1. Migration: `supabase/migrations/*_mesa_cliente_rpc_registrar_operacao_financeira.sql`
2. Teste positivo com rollback: `08a_validacao_registrar_operacao_financeira_rollback.sql`
3. Teste negativo com rollback: `08b_validacao_registrar_operacao_financeira_negativos_rollback.sql`

RPC proposta:

```sql
public.mesa_cliente_registrar_operacao_financeira_admin(
  p_simulacao_id uuid,
  p_empreendimento_id uuid,
  p_data_ato date,
  p_operacoes jsonb,
  p_politica_id uuid default null,
  p_observacao text default null
)
```

Estratégia:

- chamar internamente `mesa_cliente_simular_impacto_financeiro_admin`;
- só gravar operações válidas;
- se houver rejeição, retornar erro ou payload `ok=false` sem gravar, conforme regra definida antes da implementação;
- gravar `status_operacao = 'simulada'` ou `pendente_confirmacao`;
- `visivel_cliente = false` por padrão;
- `confirmado = false` por padrão;
- preencher `metadata` com snapshot sanitizado do cálculo;
- nunca aceitar valores calculados enviados pelo frontend como verdade.

Mapeamento para schema atual:

| Campo lógico | Coluna real |
|---|---|
| empresa | `empresa_id` |
| simulação | `simulacao_id` |
| empreendimento | `empreendimento_id` |
| política | `politica_id` |
| tipo | `tipo_operacao` |
| grupo de origem | `grupo_origem` |
| grupo de destino | `grupo_destino` |
| parcela origem | `parcela_origem_id` |
| parcela destino | `parcela_destino_id` |
| valor base/original | `valor_base` e/ou `valor_movido` |
| valor movimentado | `valor_movido` |
| data original | `data_origem` |
| data nova | `data_destino` |
| taxa | `taxa_ano_pct` |
| impacto pct | `vpl_aplicado_pct` |
| desconto | `desconto_calculado` |
| acréscimo | `acrescimo_calculado` |
| economia | `economia_liquida` |
| prêmio | `premio_corretor_pct` |
| status do prêmio | `status_premio` |
| status da operação | `status_operacao` |
| auditoria | `criado_por`, `created_at`, `metadata` |

Critério de pronto:

- grava operação apenas se simulação interna for válida;
- rejeita tentativa cross-tenant;
- rejeita `anon`;
- rejeita usuário sem permissão;
- rejeita política inexistente;
- rejeita alteração de payload calculado pelo frontend;
- rollback test passa.

### Fase 5B — RPC confirmar operação financeira

Objetivo: permitir confirmação controlada por gestor/admin/coordenador.

Entregáveis:

1. RPC: `mesa_cliente_confirmar_operacao_financeira_admin(p_operacao_id uuid)`
2. RPC: `mesa_cliente_cancelar_operacao_financeira_admin(p_operacao_id uuid, p_motivo text)`
3. Testes positivos e negativos.

Regras:

- somente perfil autorizado confirma;
- operação precisa pertencer à empresa do usuário;
- operação não pode estar cancelada;
- confirmação grava `confirmado = true`, `confirmado_por = auth.uid()`, `confirmado_em = now()`;
- operação confirmada não pode ser editada diretamente;
- cancelamento deve preservar histórico.

### Fase 5C — auditoria e trilha antifraude

Objetivo: deixar a operação auditável e defensável.

Pode ser implementado com `metadata` ou tabela dedicada, conforme necessidade:

- snapshot de entrada;
- snapshot de política;
- snapshot de resultado;
- usuário executor;
- perfil no momento da ação;
- IP/user-agent se disponível via backend;
- motivo/observação;
- status anterior e posterior.

Critério de pronto:

- é possível explicar quem fez, quando fez, em qual empresa, em qual empreendimento, com qual política e qual resultado.

### Fase 6A — RPC de resumo administrativo

Objetivo: gerar visão para corretor/coordenador revisar impacto sem ir direto em tabela.

Entregáveis:

1. `mesa_cliente_obter_resumo_financeiro_admin(p_simulacao_id uuid)`
2. Teste de permissões.

Pode exibir:

- total original;
- total calculado;
- desconto;
- acréscimo;
- economia;
- maior impacto percentual;
- status de prêmio;
- prêmio do corretor, se perfil permitir;
- operações pendentes/confirmadas/canceladas.

### Fase 6B — RPC de resumo cliente-safe

Objetivo: gerar a visão para usar na mesa com cliente.

Entregável:

```sql
public.mesa_cliente_obter_resumo_cliente_safe(p_simulacao_id uuid)
```

Pode exibir:

- fluxo de pagamento;
- valores finais aprovados;
- datas;
- condições comerciais aprovadas;
- observações comerciais seguras.

Nunca exibir:

- `politica_id`;
- VPL;
- taxa interna;
- comissão;
- prêmio;
- desconto administrativo;
- impacto de remuneração;
- payload bruto de cálculo.

### Fase 7A — camada de frontend/BFF

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

Se for mantido Supabase client no browser, a operação deve usar sessão autenticada e RPC com grants restritos. Ainda assim, tabelas financeiras permanecem fechadas por RLS e grants.

### Fase 7B — UI administrativa da Engenharia Financeira

Objetivo: permitir que corretor/coordenador opere a engenharia financeira durante a montagem da mesa.

Componentes:

- agenda de parcelas gerada;
- seleção de parcela/grupo;
- simular antecipação;
- simular postergação;
- simular VPL;
- exibir impacto administrativo;
- botão registrar operação;
- botão solicitar/confirmar aprovação conforme perfil;
- trilha de status.

Campos sensíveis devem aparecer apenas para perfis permitidos.

### Fase 7C — UI cliente-safe da Mesa

Objetivo: apresentar ao cliente apenas a condição final segura.

Componentes:

- resumo de valores;
- agenda final;
- datas;
- forma de pagamento;
- observações comerciais;
- nada de VPL/prêmio/comissão/política interna.

Critério de pronto:

- cliente consegue entender a proposta;
- corretor consegue explicar sem expor bastidor;
- payload da tela não contém dado interno sensível.

### Fase 8 — testes integrados

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

Também validar:

- SQL injection por payload JSON;
- campos extras ignorados ou bloqueados;
- valores negativos;
- taxa fora de faixa;
- data nula;
- empreendimento de outra empresa;
- simulação de outra empresa;
- operação confirmada não editável.

### Fase 9 — hardening final antes de mesa real

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
3. gerar agenda;
4. simular uma antecipação;
5. simular uma postergação;
6. registrar operação;
7. confirmar operação;
8. abrir visão cliente-safe;
9. comparar com cálculo manual;
10. validar se a tela não expõe dado interno.

Critério para liberar teste com cliente:

- cálculo bate;
- datas batem;
- visão cliente-safe limpa;
- operação registrada com auditoria;
- rollback operacional documentado;
- nenhum acesso indevido detectado;
- usuário não autorizado bloqueado;
- `anon` bloqueado;
- gestor/corretor enxergam apenas o que devem enxergar.

## 6. Sequência recomendada dos próximos arquivos

Ordem de criação sugerida:

```text
supabase/migrations/...
  07_mesa_cliente_rpc_gerar_agenda_parcelas.sql
  08_mesa_cliente_rpc_obter_agenda_cliente_safe.sql
  09_mesa_cliente_rpc_registrar_operacao_financeira.sql
  10_mesa_cliente_rpc_confirmar_cancelar_operacao_financeira.sql
  11_mesa_cliente_rpc_resumos_admin_cliente_safe.sql

supabase/tests/mesa-cliente/engenharia-financeira/...
  07a_validacao_agenda_parcelas_rollback.sql
  07b_validacao_agenda_parcelas_negativos_rollback.sql
  08a_validacao_registrar_operacao_financeira_rollback.sql
  08b_validacao_registrar_operacao_financeira_negativos_rollback.sql
  09a_validacao_confirmar_cancelar_operacao_rollback.sql
  09b_validacao_cliente_safe_sem_dados_internos.sql
  10a_e2e_financeiro_completo_rollback.sql
  10b_e2e_crosstenant_anon_payload_malicioso.sql
```

## 7. Gates de aprovação

Nenhuma fase avança sem cumprir seu gate.

| Gate | Condição |
|---|---|
| Gate Banco | migration aplicada e preflight PASS |
| Gate RLS | policies e grants revisados |
| Gate Auth | `auth.uid()` validado em teste |
| Gate Tenant | cross-tenant bloqueado |
| Gate Cálculo | cálculo composto bate com expectativa |
| Gate Cliente-safe | payload sem VPL/prêmio/comissão |
| Gate Front | sem regra financeira soberana no client |
| Gate Mesa | piloto interno aprovado |

## 8. Riscos e mitigação

| Risco | Mitigação |
|---|---|
| frontend manipular payload | recalcular tudo na RPC |
| corretor acessar empresa errada | validar contexto + RLS + helper |
| `anon` executar RPC sensível | revoke de `anon` + teste automático |
| regra financeira hardcoded | política em banco e snapshot de política |
| cliente ver dado interno | RPC cliente-safe separada |
| alteração quebrar parser atual | não alterar parser sem autorização |
| gravação irreversível em produção única | testes com rollback e backup antes de cada fase crítica |
| cálculo divergente por data | matriz de datas e testes de último dia válido |
| operação confirmada editável | status imutável ou cancelamento auditado |

## 9. Definição de pronto final

A Engenharia Financeira estará pronta para teste em mesa com cliente quando:

1. agenda de parcelas for gerada por RPC;
2. simulação administrativa estiver integrada à agenda;
3. operação financeira puder ser registrada por RPC forte;
4. confirmação/cancelamento estiverem auditados;
5. visão cliente-safe estiver limpa;
6. frontend não tiver regra financeira soberana;
7. `anon` estiver bloqueado em RPCs/tabelas sensíveis;
8. cross-tenant estiver bloqueado;
9. todos os testes SQL com rollback passarem;
10. piloto interno bater com cálculo manual;
11. backup pré-piloto estiver feito;
12. branch continuar isolada até aprovação explícita para merge.

## 10. Próxima ação imediata

A próxima implementação deve ser a Fase 4A:

```text
Criar RPC gerar_mesa_cliente_agenda_parcelas
Criar teste 07a_validacao_agenda_parcelas_rollback
Executar em produção única apenas com ROLLBACK
```

Não iniciar frontend antes da agenda financeira e das RPCs de gravação/visão segura estarem estabilizadas. O frontend bonito sem banco blindado vira vitrine de shopping com cofre aberto no fundo.
