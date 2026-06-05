# FECH.AI - Grant review e proposta de correcao Supabase MesaCliente v1

**Data:** 2026-06-05
**Status:** `GRANT_REVIEW_PROPOSAL_ONLY / CORRECAO_NAO_APLICADA`
**Base:** PRs #55, #56, #57, #58, #59A e #60
**Tipo:** documentation-only / grant-review / remediation-proposal-only / no-execution

Nota editorial: arquivo regravado em texto simples/ASCII limpo para remover risco de caracteres ocultos ou bidirecionais no Markdown. Este documento organiza uma proposta de correcao futura. A PR #62 nao corrige nada e nao autoriza nenhuma correcao tecnica.

---

## 1. Objetivo da PR #62

Criar um documento de grant review e proposta de correcao para as 7 RPCs R4 criticas do MesaCliente, consolidando os achados documentados nas PRs anteriores sobre grants, exposicao `anon`/`PUBLIC`, `SECURITY DEFINER`, owner, `search_path`, escrita comercial/financeira e riscos de tenant/payload/auditoria.

Esta PR #62 tem exclusivamente os objetivos abaixo:

- consolidar os achados das PRs #55, #56 e #57 sobre grants, `anon EXECUTE`, `PUBLIC EXECUTE`, `SECURITY DEFINER`, owner e `search_path`;
- relacionar esses achados com os cenarios negativos planejados na PR #58;
- relacionar esses achados com o harness/readiness das PRs #59A e #60;
- classificar riscos por RPC;
- propor classes e ordem segura de correcao futura;
- propor criterios para futuras PRs tecnicas pequenas;
- propor criterios de rollback futuro;
- propor criterios de revalidacao pos-correcao;
- registrar explicitamente que nenhuma correcao foi aplicada.

---

## 2. Status formal

Status desta PR #62:

`GRANT_REVIEW_PROPOSAL_ONLY / CORRECAO_NAO_APLICADA`

Marcadores obrigatorios:

- Documentacao apenas: sim.
- Grant review: sim, apenas documental.
- Proposta de remediacao: sim, apenas futura.
- Execucao: nao.
- Correcao aplicada: nao.
- Correcao autorizada: nao.

---

## 3. Relacao com PR #55, #56, #57, #58, #59A e #60

| PR | Papel na trilha | Como esta PR #62 usa o material |
|---|---|---|
| PR #55 | Inventario read-only do Supabase real MesaCliente. | Usa como base para o estado observado de RLS/FORCE RLS, policies, grants de routines, grants de tabelas, metadados de functions/RPCs e divergencias a reconciliar. |
| PR #56 | Matriz de risco Supabase real por RPC/tabela. | Usa a classificacao de risco P0/P1/R4, especialmente a combinacao de `anon/PUBLIC EXECUTE`, `SECURITY DEFINER`, escrita e impacto comercial/financeiro. |
| PR #57 | Body review das RPCs P0 MesaCliente. | Usa os metadados e lacunas por RPC: grantees, owner `postgres`, `search_path=public`, guardas observadas, escrita e dependencias de helpers. |
| PR #58 | Plano de testes negativos Supabase MesaCliente. | Relaciona os riscos com os cenarios negativos: anon, authenticated sem vinculo, cross-tenant, perfil insuficiente, payload invalido, escrita parcial e diff zero. |
| PR #59A | Harness spec para execucao controlada futura. | Mantem a premissa de que qualquer teste futuro precisa de harness controlado, ambiente isolado, dataset sintetico, stop conditions, evidencias sanitizadas e rollback aprovado. |
| PR #60 | Template de evidencias/readiness para execucao futura. | Mantem a execucao bloqueada ate GO formal e define que evidencias futuras devem registrar ambiente, snapshot, executor, correlacao, resultado e ausencia de dados reais/segredos. |

A PR #61 foi uma correcao editorial empilhada da PR #60 e nao e tratada como etapa de grant review nesta proposta.

---

## 4. Declaracao explicita de nao execucao e nao correcao

Nesta PR #62:

- nenhum teste foi executado;
- nenhuma RPC foi chamada;
- nenhuma query Supabase foi executada;
- nenhuma alteracao Supabase foi feita;
- nenhuma correcao tecnica esta autorizada;
- nenhuma migration foi criada;
- nenhum SQL executavel foi incluido;
- nenhum grant foi alterado;
- nenhum revoke foi aplicado;
- nenhuma policy foi alterada;
- nenhuma RLS ou FORCE RLS foi alterada;
- nenhuma RPC/function foi alterada;
- nenhum schema foi alterado;
- nenhum dado real foi usado;
- nenhuma credencial, token, JWT, cookie, header, `service_role` ou PII foi incluida.

Esta PR nao deve ser usada como permissao para executar correcoes, testes, migrations ou qualquer operacao contra Supabase.

---

## 5. Escopo das 7 RPCs R4

As RPCs no escopo documental desta PR #62 sao:

1. `aprovar_rejeitar_mesa`
2. `importar_mesa_cliente_disponibilidade_oficial`
3. `mesa_cliente_upsert_faixas_premio`
4. `mesa_cliente_upsert_politica_financeira`
5. `registrar_upload_arquivo_mesa`
6. `salvar_mesa_cliente_desconto_politica`
7. `salvar_mesa_cliente_enriquecimento`

Essas RPCs permanecem bloqueadas para correcao automatica nesta PR. Qualquer mudanca futura deve ocorrer somente em PR tecnica separada, pequena, revisada e explicitamente aprovada.

---

## 6. Matriz de risco por RPC

Legenda:

- `sim`: achado aplicavel com base nas PRs #55, #56 e #57.
- `parcial`: risco aplicavel por dependencia, lacuna ou necessidade de prova negativa.
- `a validar`: requer revisao/teste futuro antes de afirmar seguranca final.
- `nao observado`: nao foi registrado como achado principal nas PRs de base.

| RPC | anon EXECUTE | PUBLIC EXECUTE | SECURITY DEFINER | owner postgres | search_path=public | Escrita comercial/financeira | Risco cross-tenant | Risco de confianca em payload | Risco de escrita parcial | Risco de auditoria insuficiente | Classe inicial sugerida |
|---|---:|---:|---:|---:|---:|---|---|---|---|---|---|
| `aprovar_rejeitar_mesa` | sim | sim | sim | sim | sim | sim, aprovacao/rejeicao de proposta | sim, UPDATE por `p_simulacao_id` exige prova de ownership/empresa | sim, `p_simulacao_id` e `p_acao` controlam decisao | parcial, deve provar no-write quando acao/recurso invalidos | parcial, grava audit mas precisa provar ator/tenant/empresa suficientes | A, B, C, E, F |
| `importar_mesa_cliente_disponibilidade_oficial` | sim | nao observado | sim | sim | sim | sim, disponibilidade oficial/unidades/importacao | sim, empreendimento/empresa/corretor precisam bloquear tenant indevido | sim, payload de disponibilidade pode divergir de snapshot comercial | sim, importacao/updates precisam falhar sem escrita parcial | parcial, root/corretor/audit_actor precisam evidencia suficiente | A, B, C, D, E, F |
| `mesa_cliente_upsert_faixas_premio` | sim | nao observado | sim | sim | sim | sim, faixas de premio/regra financeira | sim, `p_empresa_id` precisa validacao via helper | sim, faixas, ranges e valores chegam do cliente | sim, DELETE seguido de INSERT exige atomicidade | parcial, escrita R4 precisa trilha clara | A, B, C, D, E, F |
| `mesa_cliente_upsert_politica_financeira` | sim | nao observado | sim | sim | sim | sim, VPL/taxas/politica financeira | sim, empresa/empreendimento precisam validacao estrita | sim, parametros financeiros sensiveis chegam do cliente | parcial, upsert deve provar no-write-on-failure | parcial, mudanca financeira R4 precisa auditoria | A, B, C, D, E, F |
| `registrar_upload_arquivo_mesa` | sim | nao observado | sim | sim | sim | sim, registro de upload/importacao | sim, `empresa_id`/corretor/storage devem bater com tenant | sim, nome/tipo/storage_path/metadados chegam do cliente | parcial, registro nao deve persistir se validacao falhar | sim, trilha de arquivo precisa ator, empresa e origem sanitizada | A, B, C, E, F |
| `salvar_mesa_cliente_desconto_politica` | sim | nao observado | sim | sim | sim | sim, desconto/regra comercial/proposta | sim, empresa/tenant/empreendimento/perfil precisam prova | sim, politica, faixas, vigencia e limites chegam do cliente | parcial, save deve falhar sem alterar politica anterior indevidamente | parcial, mudanca comercial R4 precisa auditabilidade | A, B, C, D, E, F |
| `salvar_mesa_cliente_enriquecimento` | sim | nao observado | sim | sim | sim | sim, enriquecimento de unidade/proposta | sim, empresa/empreendimento/unidade precisam prova | sim, conteudo de enriquecimento chega do cliente | parcial, overwrite/uniqueness precisam prova | parcial, tabela foi marcada para policy review e exige trilha | A, B, C, D, E, F |

Parecer da matriz: a combinacao de `anon EXECUTE`, `SECURITY DEFINER`, owner `postgres`, `search_path=public` e escrita R4 justifica corrigir grants/exposicao primeiro, antes de qualquer relaxamento de bloqueios.

---

## 7. Classes de correcao futura, sem aplicar

Esta secao descreve classes possiveis para PRs tecnicas futuras. Nenhuma classe esta autorizada ou aplicada nesta PR #62.

### Classe A - Remover exposicao anon/PUBLIC quando indevida

Objetivo futuro: remover exposicao indevida de RPCs R4 para `anon` e/ou `PUBLIC`, preservando somente roles necessarias e formalmente justificadas.

Regras futuras:

- tratar `aprovar_rejeitar_mesa` como prioridade por possuir `PUBLIC EXECUTE` e `anon EXECUTE`;
- revisar as demais RPCs R4 com `anon EXECUTE`;
- nao misturar esta classe com alteracao de body, frontend, RLS ou policies;
- exigir rollback explicito e revisao antes de merge.

### Classe B - Reforcar validacao `auth.uid()`, tenant, empresa e perfil dentro da RPC

Objetivo futuro: garantir que cada escrita R4 valide usuario autenticado, vinculo operacional, empresa/tenant, perfil/permissao e recurso alvo no proprio caminho de autorizacao da RPC.

Regras futuras:

- validar helpers usados por cada RPC antes de confiar neles;
- provar bloqueio de authenticated sem corretor, sem empresa, inativo, perfil insuficiente e cross-tenant;
- registrar criterios de PASS/FAIL por cenario negativo.

### Classe C - Reduzir confianca em IDs soberanos vindos do frontend

Objetivo futuro: reduzir dependencia de IDs de empresa, empreendimento, simulacao, unidade, politica ou arquivo enviados pelo cliente sem revalidacao server-side.

Regras futuras:

- resolver ownership no banco sempre que possivel;
- confrontar IDs recebidos com contexto do usuario;
- rejeitar payloads divergentes antes de qualquer escrita;
- manter evidencia de diff zero para tentativas invalidas.

### Classe D - Reforcar atomicidade/no-write-on-failure

Objetivo futuro: garantir que falhas de validacao, payload ou autorizacao nao deixem escrita parcial.

Regras futuras:

- priorizar fluxos com DELETE/INSERT, importacao ou upsert financeiro;
- exigir prova antes/depois em dataset sintetico;
- exigir rollback operacional antes da execucao;
- parar a execucao se houver escrita parcial inesperada.

### Classe E - Reforcar auditabilidade para escrita R4

Objetivo futuro: garantir que toda escrita R4 tenha trilha suficiente, sanitizada e correlacionavel sem expor segredos ou dados reais.

Regras futuras:

- registrar ator, empresa/tenant, recurso, acao e correlation id quando aplicavel;
- nao registrar JWT, cookies, headers, tokens, `service_role`, PII ou payload sensivel bruto;
- definir evidencia minima para alteracoes comerciais/financeiras.

### Classe F - Revisar `search_path`/owner/`SECURITY DEFINER` quando aplicavel

Objetivo futuro: reduzir risco estrutural em functions `SECURITY DEFINER` com owner `postgres` e `search_path=public`.

Regras futuras:

- revisar `search_path` e referencias a helpers antes de alterar behavior;
- avaliar se owner e `SECURITY DEFINER` sao indispensaveis para cada RPC;
- nao alterar owner/search_path/body na mesma PR de grant, salvo excecao formalmente aprovada;
- exigir revisao multi-GPT e rollback especifico.

---

## 8. Ordem segura sugerida para futuras PRs tecnicas

Ordem recomendada, se houver aprovacao explicita futura:

1. PR tecnica futura 1: Classe A para grants/exposicao, preferencialmente uma RPC ou pequeno grupo de RPCs por PR.
2. PR tecnica futura 2: Classe B para validacoes internas de `auth.uid()`, tenant, empresa e perfil nas RPCs que ainda dependerem de reforco.
3. PR tecnica futura 3: Classe C para reduzir confianca em IDs soberanos e payloads vindos do frontend.
4. PR tecnica futura 4: Classe D para atomicidade/no-write-on-failure em upserts, importacoes e fluxos DELETE/INSERT.
5. PR tecnica futura 5: Classe E para auditabilidade de escrita R4.
6. PR tecnica futura 6: Classe F para `search_path`, owner e `SECURITY DEFINER`, quando aplicavel e somente com revisao adicional.
7. PR futura de reexecucao dos testes negativos relevantes.
8. PR futura de fechamento da auditoria.

Regras transversais para todas as PRs tecnicas futuras:

- uma classe de correcao por PR;
- uma RPC ou pequeno grupo de RPCs por PR;
- migrations pequenas;
- rollback explicito;
- reexecucao dos testes negativos relevantes;
- revisao multi-GPT antes de merge;
- evidencia sanitizada;
- producao fora do escopo de teste destrutivo;
- dataset sintetico obrigatorio para qualquer execucao com escrita.

---

## 9. Criterios de bloqueio para futuras PRs tecnicas

Uma PR tecnica futura deve ser bloqueada se qualquer item abaixo ocorrer:

- alteracao grande demais;
- mistura de grants, RLS, function body e frontend na mesma PR;
- ausencia de rollback;
- ausencia de teste negativo;
- uso de producao;
- uso de dados reais;
- uso de `service_role` fora de procedimento controlado;
- SQL sem revisao;
- mudanca sem relacao direta com uma classe de correcao declarada;
- ausencia de diff antes/depois quando houver escrita autorizada em ambiente isolado;
- evidencia contendo credenciais, tokens, JWT, cookies, headers, PII ou payload sensivel bruto;
- tentativa de usar esta PR #62 como autorizacao de correcao tecnica.

---

## 10. Criterios para rollback futuro

Toda PR tecnica futura deve declarar rollback antes do merge.

Criterios minimos:

- rollback deve ser pequeno, revisavel e proporcional a mudanca;
- rollback deve desfazer apenas a mudanca da PR tecnica correspondente;
- rollback nao deve depender de dados reais;
- rollback nao deve expor segredo, token, JWT, cookie, header ou `service_role` no documento;
- rollback deve ter responsavel identificado no plano de execucao futura;
- rollback deve ter condicoes de disparo claras, incluindo falha de teste negativo, escrita parcial inesperada, quebra cross-tenant ou divergencia de auditoria;
- rollback documental desta PR #62: remover ou reverter este arquivo Markdown.

---

## 11. Criterios de revalidacao pos-correcao futura

Apos qualquer correcao tecnica futura, a revalidacao deve incluir:

- reexecutar os cenarios negativos relevantes da PR #58 no ambiente autorizado;
- registrar evidencias conforme harness/readiness das PRs #59A e #60;
- provar que anon falha para RPCs R4 sem exposicao anon justificada;
- provar que `PUBLIC EXECUTE` nao permanece em RPC R4 quando indevido;
- provar que authenticated sem empresa/corretor/perfil falha;
- provar que usuario de tenant B nao altera recurso de tenant A;
- provar que payload invalido falha antes de escrever;
- provar diff zero para tentativas proibidas;
- provar que controle positivo autorizado altera somente o escopo esperado;
- revisar se hashes/bodies/grants mudaram e atualizar rastreabilidade;
- manter evidencias sem credenciais, PII ou dados reais.

---

## 12. Criterios de aceite desta PR #62

A PR #62 pode ser aceita somente se todos os itens abaixo forem verdadeiros:

- apenas 1 arquivo Markdown foi criado;
- nenhum codigo foi alterado;
- nenhuma migration foi criada;
- nenhum SQL executavel foi incluido;
- nenhuma query foi executada;
- nenhuma alteracao Supabase foi feita;
- a proposta de correcao futura esta clara;
- execucao e correcao continuam bloqueadas;
- o documento declara explicitamente que a PR #62 nao corrige nada;
- o documento nao autoriza correcao tecnica;
- o rollback documental e remover/reverter o arquivo criado.

---

## 13. Proxima sequencia

Sequencia recomendada apos esta PR documental, sempre condicionada a aprovacao explicita futura:

1. PR tecnica futura 1: correcao pequena e controlada de grants/exposicao, se aprovada.
2. PR tecnica futura 2: validacoes internas auth/tenant/perfil, se necessaria.
3. PR futura de reexecucao dos testes negativos.
4. PR futura de fechamento da auditoria.

Enquanto essas PRs futuras nao existirem, forem aprovadas e passarem por revisao, o estado permanece:

`EXECUCAO_BLOQUEADA / CORRECAO_TECNICA_NAO_AUTORIZADA / CORRECAO_NAO_APLICADA`

---

## 14. Parecer final

Esta PR #62 nao corrige grants, RLS, policies, RPCs/functions, schema ou migrations. Ela apenas organiza uma proposta de correcao futura para reduzir riscos das RPCs R4 do MesaCliente em PRs tecnicas pequenas, controladas, revisadas e com rollback.

Status final deste documento:

`GRANT_REVIEW_PROPOSAL_ONLY / CORRECAO_NAO_APLICADA / NO_EXECUTION / NO_SQL_EXECUTAVEL`
