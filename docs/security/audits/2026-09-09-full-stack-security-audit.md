# Relatório de Auditoria de Segurança — FECH.AI

- Data: 2026-09-09
- Repository: `wagnerjfjunior/fecha.ai`
- Main auditada: `ac20a30fea9095f036d8d466e83794432d58ca89`
- Ambiente: Pilot Production / SaaS multi-tenant / multiempresa
- Banco: Supabase uobxxgzshrmbtjfdolxd / Discador-MesaCliente / PostgreSQL 17.6

## Resumo executivo

Foram verificados 10 achados acionáveis: ALTA=5, MÉDIA=3, BAIXA=2.
Os riscos centrais são falhas cross-tenant em RPCs SECURITY DEFINER e integridade relacional em `lista_avaliacoes`/PME. Não foi verificado XSS explorável nem bypass puro baseado somente em UI.

## Cobertura

| Superfície | Universo | Estado |
|---|---:|---|
| GitHub main | ac20a30...ca89 | LIVE REF RESOLVIDO |
| Tree do repositório | 634 blobs | ENUMERADO |
| Backend HTTP/Edge handlers | 4/4 | INTEGRAL_READ |
| public tables | 44/44 | ACL/RLS ENUMERADOS |
| public views | 8/8 | ACL + security_invoker ENUMERADOS |
| public policies | 82/82 | ENUMERADAS |
| public functions | 160/160 | ACL/mode/owner/config ENUMERADOS |
| SECURITY DEFINER | 137/137 | UNIVERSO RECONCILIADO; blockers revalidados live |
| public triggers | 31/31 | ENUMERADOS; 16 funções únicas fingerprintadas |
| public constraints | 271/271 | ENUMERADAS + análise tenant-FK |
| Schemas não-public | auth/storage/realtime/extensions/vault/etc. | ACLs de relações e rotinas ENUMERADOS; sem deep audit vendor |
| Git history por segredos | não exaustivo | NOT_VERIFIED |
| Hostile-client em produção | não executado | PROIBIDO / NOT_PERFORMED |

## Achados

### F-01 — ALTA — Gestor pode aprovar/rejeitar simulação de outro tenant por UUID
- Categoria: IDOR / Banco sem tranca
- Evidência: Supabase live: public.aprovar_rejeitar_mesa(uuid,text,text); caller em src/features/mesaCliente/api/mesaClienteApi.js:120-126
- Verificação: A função é SECURITY DEFINER e autenticada. Valida apenas is_gestor(), busca mesa_simulacoes por id e executa UPDATE WHERE id = p_simulacao_id sem empresa/ownership binding.
- Explorabilidade: Um gestor autenticado que obtenha UUID de uma simulação de outra empresa pode alterar o status para aprovada/rejeitada e ainda gerar audit_log no tenant alvo.
- Condições: Requer papel gestor válido e conhecimento do UUID alvo. Nenhum teste destrutivo foi executado.
- WBS: STS-M3-03 remediation (per-RPC resource binding) -> STS-M3-04-09 negative proofs
- Correção: Derivar empresa/time/actor server-side; carregar a simulação com predicate tenant-bound antes do UPDATE; negar se não houver vínculo; manter UPDATE condicionado por id+empresa; adicionar teste cross-tenant isolado.

### F-02 — ALTA — relatorio_fornecedor lê lista de outro tenant sob SECURITY DEFINER
- Categoria: IDOR / Banco sem tranca
- Evidência: Supabase live: public.relatorio_fornecedor(uuid); evidência canônica docs/security/evidence/2026-09-05-sts-m2-04b3-routine-authority-classification.csv:100
- Verificação: A função checa apenas is_gestor() e usa p_lista_id diretamente em listas, leads e lista_avaliacoes. Não há binding da lista à empresa/time do chamador.
- Explorabilidade: Gestor autenticado com UUID de lista externa consegue obter metadados e agregados/avaliações do tenant alvo apesar das RLS das tabelas, porque a função roda como owner.
- Condições: Requer UUID da lista de outro tenant.
- WBS: STS-M3-03 remediation -> STS-M3-04-09 -> STS-M3-04-10
- Correção: Resolver actor empresa/time; exigir lista autorizada; preferir INVOKER se suficiente ou manter DEFINER apenas com binding explícito; negar UUID fora do escopo.

### F-03 — ALTA — Dashboard master e estatística horária agregam dados de todas as empresas
- Categoria: Banco sem tranca / Permissão server-side
- Evidência: Supabase live: public.get_dashboard_master(); public.get_stats_horario()
- Verificação: Ambas são SECURITY DEFINER e liberam gestor; get_dashboard_master consulta leads/listas/corretores sem empresa_id; get_stats_horario agrega leads globais por hora/dia sem tenant filter.
- Explorabilidade: Qualquer gestor autenticado pode obter métricas comerciais globais de outros tenants via RPC direta.
- Condições: Não requer UUID alvo; apenas sessão de gestor.
- WBS: STS-M3-03 remediation (authority/tenant scope) -> STS-M3-04-09
- Correção: Substituir o gate genérico por contexto server-derived empresa/time e aplicar o filtro em todas as subqueries; root global deve ser branch explícito e auditável.

### F-04 — ALTA — lista_avaliacoes permite criar/alterar relações cross-tenant
- Categoria: Banco sem tranca / IDOR de escrita
- Evidência: Supabase live: public.lista_avaliacoes grants/policies/FKs; residual já mapeado em STS-M3-04-04
- Verificação: authenticated tem INSERT/UPDATE. INSERT WITH CHECK valida apenas corretor_id=my_corretor_id(); UPDATE usa o mesmo predicate. empresa_id/lista_id/lote_id possuem FKs simples, sem constraint/trigger que force mesma empresa.
- Explorabilidade: Corretor pode gravar sua própria avaliação apontando empresa/lista/lote de outro tenant se conhecer UUIDs válidos; a linha pode tornar-se visível ao tenant alvo.
- Condições: Requer UUIDs relacionados válidos de outro tenant.
- WBS: STS-M3-04-04 -> STS-M3-04-07 -> STS-M3-04-09
- Correção: Criar invariantes tenant-bound no banco (FK composta/trigger equivalente), reforçar WITH CHECK para actor+empresa+lista+lote e cobrir INSERT/UPDATE cross-tenant com testes negativos.

### F-05 — ALTA — Catálogos PME aceitam IDs relacionados de outro tenant
- Categoria: Banco sem tranca / Integridade estrutural
- Evidência: supabase/migrations/20260523173000_pme_usage_tracking_db_v028.sql:396-405,415-424,434-443,453-462,694-697 + catálogo live
- Verificação: RLS de INSERT/UPDATE só exige pme_is_empresa_admin(empresa_id). FKs para cadence_id/empreendimento_id/created_by/updated_by são simples e não incluem empresa_id; triggers PME são apenas updated_at.
- Explorabilidade: Admin do tenant A pode manter empresa_id=A e referenciar cadence/empreendimento/corretor do tenant B se conhecer o UUID, criando relacionamento inválido cross-tenant.
- Condições: Requer papel administrativo PME no tenant A e UUID relacionado do tenant B.
- WBS: STS-M3-04-05 -> STS-M3-04-07 -> STS-M3-04-09
- Correção: Adicionar invariantes compostos empresa+objeto (ou triggers fail-closed equivalentes), server-derive created_by/updated_by e testar mixed-tenant inserts/updates.

### F-06 — MÉDIA — lead_tem_acao_real funciona como oracle cross-tenant de lead
- Categoria: IDOR
- Evidência: Supabase live: public.lead_tem_acao_real(uuid); classificação canônica CSV:47
- Verificação: SECURITY DEFINER, EXECUTE para authenticated e nenhuma checagem de auth/tenant/ownership no corpo; consulta leads por p_lead_id e retorna booleano derivado do estado do lead.
- Explorabilidade: Usuário autenticado com UUID de lead externo consegue inferir se esse lead tem ação/estado real, atravessando o isolamento de informação.
- Condições: Requer UUID do lead; vazamento limitado a booleano.
- WBS: STS-M3-03 internal-only reachability + STS-M3-04-08 call-site sweep
- Correção: Remover EXECUTE direto se helper interno; ou bindar p_lead_id a actor+empresa/ownership antes de consultar.

### F-07 — BAIXA — acquire_lote_lock está executável por anon sem autenticação
- Categoria: Permissão / superfície de RPC
- Evidência: Supabase live: public.acquire_lote_lock(uuid,uuid); residual M3-03 internal-only reachability
- Verificação: SECURITY DEFINER, anon EXECUTE, aceita UUIDs e chama pg_advisory_xact_lock sem auth.uid().
- Explorabilidade: Chamador anônimo pode disputar advisory locks de pares arbitrários. Como o lock é transacional e a chamada isolada termina rápido, DoS sustentado não foi provado.
- Condições: Impacto de disponibilidade depende de concorrência/timing; sem data compromise provado.
- WBS: STS-M3-03 remediation - internal-only reachability
- Correção: REVOKE de anon/authenticated se o helper for apenas interno e preservar chamada pelo parent autorizado; validar dependências antes.

### F-08 — MÉDIA — mesa-worker-proxy aceita POST sem autenticação e retransmite body
- Categoria: Permissão server-side
- Evidência: api/mesa-worker-proxy.js:3-19
- Verificação: O handler verifica apenas método POST; não valida Authorization/JWT/role e encaminha req.body para Worker configurado/default.
- Explorabilidade: Se a rota estiver deployada, qualquer origem pode usar o FECH.AI como relay para consumo do Worker, ampliando abuso/custo/DoS do processamento upstream.
- Condições: Caller atual no frontend não foi encontrado; deployment/runtime dessa rota não foi revalidado nesta auditoria.
- WBS: STS-M3-06 service/runtime boundary -> STS-M5 integrated security
- Correção: Exigir JWT válido e contexto autorizado; aplicar limites de tamanho/rate limiting; remover rota se realmente órfã; não expor worker_url em erro/retorno.

### F-09 — MÉDIA — Default privileges em public são fail-open para objetos futuros
- Categoria: Banco sem tranca / Configuração
- Evidência: Supabase live: pg_default_acl para owner postgres/supabase_admin no schema public
- Verificação: Novas relações de postgres herdam ALL para anon/authenticated/service_role e novas funções herdam EXECUTE; tabelas novas começam sem RLS até hardening explícito.
- Explorabilidade: Uma migration futura que crie objeto public e esqueça revoke/RLS pode publicar leitura/escrita imediatamente.
- Condições: Risco condicionado à criação futura de objeto sem hardening; hoje 44/44 tabelas public têm RLS.
- WBS: STS-M3-04-06/07 + gate de migration/CI em M5
- Correção: Alterar default privileges para fail-closed e exigir grants explícitos; adicionar teste CI que falhe com nova relation sem RLS ou client ACL não declarado.

### F-10 — BAIXA — 31 funções public são executáveis por anon, acima do target
- Categoria: Permissão / least privilege
- Evidência: Supabase live: 160 funções public; 31 anon-executable; 22 SECURITY DEFINER; 9 com indício de DML
- Verificação: O target canônico de alto risco exige anon EXECUTE=0. Diversas funções têm guards internos que bloqueiam abuso, mas a superfície efetiva continua maior que o necessário.
- Explorabilidade: A exposição aumenta superfície de ataque e custo de prova; para root RPCs verificadas, auth.uid() null faz guard falhar, portanto mutação anônima não foi provada.
- Condições: Nem toda função anon-executable é perigosa; remediation deve ser por allowlist, não REVOKE cego.
- WBS: STS-M3-03 remediation - RPC EXECUTE/root grant convergence
- Correção: Convergir ACLs ao allowlist congelado, mantendo apenas entradas explicitamente necessárias; revalidar cada parent/internal helper e evitar revoke indiscriminado.

## Pontos fortes
- 44/44 tabelas public com RLS habilitado; nenhuma tabela public app com RLS desligado.
- Nenhum privilégio direto de tabela public para anon foi observado na superfície app.
- Leads/funil e lista_visibilidade já possuem invariantes compostos/guards tenant-bound em pontos críticos.
- pme_message_usage já é write RPC-only (STS-M3-04-01) e pme_lead_message_state teve direct INSERT/UPDATE removido (STS-M3-04-02).
- criar-usuario valida Bearer JWT com admin.auth.getUser() e deriva perfil/tenant no servidor.
- gpt-especialista usa segredo de header e allowlist de operações read-only.
- get_dashboard_gestor/get_dashboard_stats/get_funil_stats/get_corretores_time possuem escopo empresa/time server-derived.
- As duas views public diretamente legíveis por authenticated observadas usam security_invoker=true.
- CREATE no schema public não está concedido a anon/authenticated/service_role.
- Sinks XSS encontrados foram estáticos ou escapados; não houve XSS verificado.

## Observações das cinco categorias
- **OBS-01 — Chaves expostas — INFORMATIVA**: Há Supabase anon JWT literal em src/lib/supabaseClient.js:8-11, src/components/MesaCliente/supabaseClient.js:3-6 e fallback em src/components/CriarUsuario.jsx:8-9. A anon key é credencial publicável por design no Supabase e não é tratada como segredo; o risco real depende das ACL/RLS. Recomenda-se centralizar config para evitar drift, sem rotular isso como vazamento de segredo.
- **OBS-02 — XSS — SEM ACHADO VERIFICADO**: src/App.jsx:283 injeta CSS constante. public/pme-call-assistant-beta.js:414 usa innerHTML, porém valores dinâmicos relevantes passam por escapeHtml() em L731 e URLs de WhatsApp/e-mail usam encodeURIComponent. Não foi verificado XSS explorável nos sinks encontrados.
- **OBS-03 — Permissão no navegador — SEM BYPASS PURO VERIFICADO**: Gates React não são usados como autoridade final nas operações privilegiadas revisadas. criar-usuario valida JWT e papel no Edge; root RPCs têm guarda server-side. HomeActions.jsx:35 ainda pode detectar 'root' pelo nome para UI, mas isso não concede autoridade backend.

## Limitações
- Nenhum teste hostile-client/cross-tenant ativo foi executado em produção.
- Nenhum dado de cliente/PII foi lido para construir a auditoria; somente catálogo, definições e código.
- Git history completo não foi varrido byte a byte; a busca de segredo no histórico é NOT_VERIFIED.
- Schemas gerenciados pelo Supabase foram enumerados quanto a ACL/RLS, mas não receberam auditoria semântica linha-a-linha de toda a implementação vendor.
- Deployment atual da rota api/mesa-worker-proxy.js não foi comprovado; finding F-08 é condicionado a ela estar publicada.
