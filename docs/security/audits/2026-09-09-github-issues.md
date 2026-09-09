# Issues para GitHub - FECH.AI Security Audit

--- ISSUE 1 ---
# [Segurança] Vincular aprovação/rejeição de MesaCliente ao tenant e ao recurso autorizado

Labels sugeridas: `security, severity:high`

## Descrição
`public.aprovar_rejeitar_mesa(p_simulacao_id, ...)` é `SECURITY DEFINER` e valida `is_gestor()`, mas não prova que `p_simulacao_id` pertence à empresa/time do chamador antes do `UPDATE`.

## Por que é explorável
Um gestor autenticado que conheça o UUID de uma simulação de outro tenant pode alterar seu status.

## Evidência
- Supabase live: `public.aprovar_rejeitar_mesa(uuid,text,text)`
- Caller: `src/features/mesaCliente/api/mesaClienteApi.js:120-126`
- Frontend gate: `src/components/MesaCliente/TabHistorico.jsx:29-35`

## Impacto
Mutação cross-tenant em aprovação/rejeição de proposta/simulação e auditoria associada.

## Sugestão de correção
Derivar actor/empresa/time server-side, carregar a simulação com predicate tenant-bound e manter o `UPDATE` condicionado por `id + empresa_id`/ownership.

## Critérios de aceite
- [ ] Gestor do tenant A não consegue aprovar/rejeitar UUID do tenant B.
- [ ] Gestor autorizado continua operando recursos do seu escopo.
- [ ] Root, se permitido, usa branch explícito e auditável.
- [ ] Teste negativo cross-tenant executado em ambiente isolado.
- [ ] Nenhum dado real de produção é usado como fixture ofensiva.

--- FIM ISSUE 1 ---

--- ISSUE 2 ---
# [Segurança] Fechar leitura cross-tenant nas RPCs de relatório e analytics

Labels sugeridas: `security, severity:high`

## Descrição
Há RPCs `SECURITY DEFINER` que aceitam gestor e consultam dados sem binding de tenant:
- `relatorio_fornecedor(p_lista_id)`
- `get_dashboard_master()`
- `get_stats_horario()`

## Por que é explorável
`relatorio_fornecedor` usa o UUID fornecido diretamente. `get_dashboard_master` e `get_stats_horario` agregam dados globais sem `empresa_id`.

## Evidência
- Supabase live definitions, registradas em `docs/security/audits/2026-09-09-live-db-evidence.md`
- Classificação histórica de `relatorio_fornecedor`: `docs/security/evidence/2026-09-05-sts-m2-04b3-routine-authority-classification.csv:100`

## Impacto
Exposição cross-tenant de métricas comerciais, metadados de listas e avaliações.

## Sugestão de correção
Derivar `empresa_id`, time e actor no servidor; filtrar todas as subqueries; validar `p_lista_id` no escopo do chamador; reduzir `SECURITY DEFINER` quando caller authority/RLS for suficiente.

## Critérios de aceite
- [ ] Gestor comum nunca recebe dados de outra empresa.
- [ ] UUID de lista externa retorna denied/not found sem distinguir existência.
- [ ] Analytics globais ficam restritos a root explicitamente autorizado.
- [ ] Negative tests cobrem tenant A -> tenant B.
- [ ] AppSec independente revisa o fechamento.

--- FIM ISSUE 2 ---

--- ISSUE 3 ---
# [Segurança] Endurecer integridade tenant-bound de lista_avaliacoes

Labels sugeridas: `security, severity:high`

## Descrição
`lista_avaliacoes` aceita `INSERT/UPDATE` autenticado, mas a policy valida somente `corretor_id = my_corretor_id()`. `empresa_id`, `lista_id` e `lote_id` não são vinculados entre si por constraint/trigger tenant-bound.

## Por que é explorável
Um corretor pode escrever uma avaliação com sua identidade mas relacioná-la a objetos de outra empresa, desde que conheça UUIDs válidos.

## Evidência
Supabase live: grants, policies e FKs de `public.lista_avaliacoes`; `docs/security/audits/2026-09-09-live-db-evidence.md`.

## Impacto
Contaminação cross-tenant e corrupção de integridade de avaliações/listas/lotes.

## Sugestão de correção
Adicionar constraints compostas ou trigger fail-closed para garantir a mesma empresa em todas as relações; reforçar `WITH CHECK`.

## Critérios de aceite
- [ ] `(lista_id, empresa_id)` só referencia lista da mesma empresa.
- [ ] `lote_id`, quando presente, pertence à mesma empresa/lista aplicável.
- [ ] `corretor_id` pertence à empresa efetiva.
- [ ] INSERT e UPDATE mixed-tenant falham.
- [ ] Testes positivos do tenant legítimo permanecem verdes.

--- FIM ISSUE 3 ---

--- ISSUE 4 ---
# [Segurança] Endurecer relações multi-tenant dos catálogos PME

Labels sugeridas: `security, severity:high`

## Descrição
As policies de `pme_message_templates`, `pme_call_scripts`, `pme_cadences` e `pme_cadence_steps` validam o `empresa_id`, porém IDs relacionados usam FKs simples.

## Evidência
`supabase/migrations/20260523173000_pme_usage_tracking_db_v028.sql:396-405,415-424,434-443,453-462,694-697` e catálogo live.

## Impacto
Admin do tenant A pode criar relações que apontem para cadence/empreendimento/corretor de tenant B, produzindo integridade estrutural inválida.

## Sugestão de correção
Invariantes compostos `empresa_id + related_id`, ou triggers equivalentes; `created_by/updated_by` derivados no servidor quando possível.

## Critérios de aceite
- [ ] Nenhum catálogo PME aceita related UUID de outra empresa.
- [ ] Cadence step só referencia cadence da mesma empresa.
- [ ] Empreendimento e actor pertencem ao mesmo tenant.
- [ ] Negative tests mixed-tenant cobrem INSERT e UPDATE.
- [ ] M3-04-07 confirma os invariantes no catálogo live.

--- FIM ISSUE 4 ---

--- ISSUE 5 ---
# [Segurança] Remover reachability direta de lead_tem_acao_real ou aplicar tenant binding

Labels sugeridas: `security, severity:medium`

## Descrição
`public.lead_tem_acao_real(p_lead_id)` é `SECURITY DEFINER`, executável por `authenticated`, e consulta o lead por UUID sem validar actor/tenant.

## Impacto
Oracle cross-tenant de existência/estado de lead (retorno booleano).

## Sugestão de correção
Se for helper interno, remover EXECUTE do cliente. Se for API, validar sessão e objeto dentro do tenant/ownership.

## Critérios de aceite
- [ ] Usuário do tenant A não obtém sinal sobre lead do tenant B.
- [ ] Caller canônico continua funcional.
- [ ] ACL final corresponde à classificação INTERNAL/APP documentada.

--- FIM ISSUE 5 ---

--- ISSUE 6 ---
# [Segurança] Convergir ACLs de helpers/RPCs internos e anon-executable ao allowlist

Labels sugeridas: `security, severity:low`

## Descrição
O banco live possui 31 funções `public` executáveis por `anon`; 22 são `SECURITY DEFINER`. `acquire_lote_lock` é helper interno diretamente executável e sem auth.

## Impacto
Superfície excessiva e risco de abuso de primitives; em `acquire_lote_lock`, há possibilidade limitada de contenção de advisory lock. Não foi provado DoS sustentado.

## Sugestão de correção
Convergir por allowlist, removendo reachability cliente de helpers internos e anon EXECUTE onde não é requisito do produto.

## Critérios de aceite
- [ ] `acquire_lote_lock` não é diretamente chamável por anon/clientes.
- [ ] Parents autorizados continuam operando.
- [ ] Toda função anon-executable remanescente possui justificativa e teste.
- [ ] Não executar REVOKE em lote sem classificação por assinatura.

--- FIM ISSUE 6 ---

--- ISSUE 7 ---
# [Segurança] Exigir autenticação no mesa-worker-proxy ou remover rota órfã

Labels sugeridas: `security, severity:medium`

## Descrição
`api/mesa-worker-proxy.js` aceita `POST` e encaminha o body ao Worker sem validar JWT, role ou tenant.

## Evidência
`api/mesa-worker-proxy.js:3-19`.

## Impacto
Se deployada, a rota pode ser usada como relay para consumo de recursos do Worker e ampliar superfície de abuso/custo.

## Sugestão de correção
Validar Bearer JWT, aplicar contexto de autorização, limite de payload/rate limit; ou remover a rota se não houver caller canônico.

## Critérios de aceite
- [ ] Requisição sem JWT recebe 401.
- [ ] JWT inválido recebe 401.
- [ ] Caller autorizado continua funcional.
- [ ] Payload possui tamanho máximo.
- [ ] Se órfã, rota é removida e ausência de dependências é provada.

--- FIM ISSUE 7 ---

--- ISSUE 8 ---
# [Segurança] Tornar default privileges do schema public fail-closed

Labels sugeridas: `security, severity:medium`

## Descrição
Default ACLs live para objetos futuros em `public` concedem privilégios amplos a roles cliente. Uma tabela nova também nasce sem RLS até a migration habilitá-la.

## Impacto
Nova migration pode publicar tabela/função por acidente se esquecer hardening explícito.

## Sugestão de correção
Revogar defaults amplos e conceder apenas explicitamente. Criar gate CI que falhe para nova tabela sem RLS ou client ACL não declarada.

## Critérios de aceite
- [ ] Novas relations não herdam ALL para anon/authenticated.
- [ ] Novas functions não herdam EXECUTE cliente sem allowlist.
- [ ] Teste de migration cria objeto de prova e confirma posture fail-closed em ambiente isolado.
- [ ] Current app grants necessários são preservados explicitamente.

--- FIM ISSUE 8 ---
