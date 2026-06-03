# FECH.AI - Auditoria AS-IS de Codigo MesaCliente v1

**Data:** 2026-06-03
**Status:** `AS_IS_CODIGO / PENDENTE_RECONCILIACAO_SUPABASE_REAL`
**Responsavel conceitual:** GPT 0 - FECH.AI Documentation Auditor
**Especialista de dominio:** GPT 8 - MesaCliente Tabelas Propostas Specialist
**Executor operacional:** Projeto Principal FECH.AI com conector GitHub
**Arquivo:** `docs/audits/code/2026-06-03-mesacliente-code-as-is-v1.md`
**Tipo:** documentacao-only.
**Escopo proibido:** nao altera App, Supabase, RLS, RPCs, migrations, parser, motor financeiro, Worker, Make/n8n, frontend, MesaCliente runtime, LeadOps, PME, Discador, ADS/CAPI, Vercel, GitHub Actions, integracoes reais ou producao.

---

## 1. Objetivo

Auditar o codigo atual relacionado ao MesaCliente em modo AS-IS, sem implementacao, para verificar se o codigo confirma, contradiz ou nao comprova os contratos documentais inventariados na PR #52.

Esta auditoria nao autoriza correcoes nem deploy. Ela registra evidencias, riscos, lacunas e proximos passos para reconciliacao com codigo completo, testes e Supabase real.

Nota editorial: este arquivo foi normalizado em ASCII para remover risco de caracteres ocultos ou bidirecionais no Markdown.

---

## 2. Escopo realmente auditado

Esta secao separa o que foi lido diretamente do que foi apenas citado, inferido ou marcado como pendente. Essa distincao e essencial para evitar que a auditoria vire um "parece certo" sem prova operacional.

### 2.1 Arquivos lidos diretamente no codigo

```text
src/components/MesaCliente/index.jsx
src/components/MesaCliente/TabEmpreendimentos.jsx
src/components/MesaCliente/TabFluxo.jsx
src/components/MesaCliente/OperacoesFinanceirasPanel.jsx
src/components/MesaCliente/hooks/useMesaData.js
src/features/mesaCliente/api/mesaClienteApi.js
src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js
src/features/mesaCliente/parser/nativeFirstParser.js
src/pages/MesaCliente.jsx
src/pages/MesaClienteNativeFirst.jsx
src/lib/supabaseClient.js
src/components/MesaCliente/supabaseClient.js
```

Status:

```text
LIDO_DIRETAMENTE / EVIDENCIA_DE_CODIGO / AINDA_SEM_TESTE_RUNTIME
```

### 2.2 Arquivos citados, buscados ou identificados como relevantes, mas nao lidos integralmente nesta PR

```text
src/App.jsx
src/main.jsx
src/pages/MesaClienteOld.jsx
src/components/MesaCliente/TabHistorico.jsx
src/components/MesaCliente/SegundaViaHistoricoPanel.jsx
src/components/MesaCliente/FluxoBuilder.jsx
src/features/mesaCliente/parser/parserPayloadAdapter.js
src/features/mesaCliente/security/jsonAdminImport.js
src/components/MesaCliente/disponibilidade/DisponibilidadeUploadPreview.jsx
src/mesa/layoutDetector.js
src/mesa/parsers/parseRangeByFinalTable.js
src/mesa/parsers/parseSplitBlockTable.js
src/mesa/parsers/parseReadyStockTable.js
src/mesa/parsers/parseFlatTable.js
src/mesa/parsers/parseHierarchical.js
src/mesa/parsers/parseERPTable.js
src/mesa/parsers/legacyParser.js
src/mesa/validators/validateCanonRow.js
src/mesa/mirror/parsePortalVWebMirror.js
src/mesa/mirror/reconcileUnitsWithMirror.js
supabase/migrations/*mesa_cliente*.sql
supabase/rollback/*mesa_cliente*.sql
```

Status:

```text
RELEVANTE_NAO_AUDITADO_INTEGRALMENTE / LACUNA_DOCUMENTAL / PENDENTE_PROXIMA_RODADA
```

### 2.3 Conclusoes confirmadas por codigo

```text
- O runtime observado usa uma camada de API baseada em RPCs para MesaCliente.
- O wrapper da pagina exige `sb.rpc` e `token` antes de renderizar MesaCliente.
- O painel de operacoes financeiras usa hooks/RPCs dedicadas.
- Existe sanitizacao frontend de parametros financeiros em `mesaClienteOperacoesFinanceirasApi.js`.
- O parser native-first existe e possui fallback Worker/Make.
- A UI monta fluxo financeiro a partir de unidade/payload/observacoes.
- Ha anon key hardcoded em dois clientes Supabase.
```

### 2.4 Conclusoes apenas documentais ou dependentes de verificacao posterior

```text
- Nao e possivel afirmar que RPCs reais validam auth.uid(), tenant, empresa, corretor, perfil, grants e RLS.
- Nao e possivel afirmar que cliente-safe nao vaza campos internos sem inspecionar RPC real e payload real.
- Nao e possivel afirmar que migrations documentadas estao aplicadas.
- Nao e possivel afirmar que parser nativo cobre todos os layouts reais sem testes com arquivos.
- Nao e possivel afirmar que o motor financeiro soberano esta no banco.
- Nao e possivel afirmar que runtime legado/paralelo nao esta roteado sem revisar rotas/App/main.
```

---

## 3. Buscas realizadas

```text
MesaCliente
mesa_cliente
supabase.rpc
supabase.from
createClient
OperacoesFinanceirasPanel
nativeFirstParser
```

Limitacoes:

```text
- Nao foi executado teste automatizado.
- Nao foi feito build local.
- Nao foi feita varredura completa por terminal local.
- Nao foi consultado Supabase real.
- Nao foi validado se migrations documentadas estao aplicadas.
- Nao foi alterado nenhum arquivo de codigo.
```

---

## 4. Mapa AS-IS de componentes e responsabilidades

| Arquivo | Responsabilidade observada | Classificacao | Risco |
|---|---|---|---:|
| `src/pages/MesaCliente.jsx` | Wrapper da pagina; exige `sb.rpc` e `token`; repassa `corretor`, `empresaId`, `corretorId` e `isGestor` ao componente principal. | RUNTIME_ATUAL / FRONT_WRAPPER | P1 |
| `src/components/MesaCliente/index.jsx` | Componente principal com abas `Empreendimentos`, `Fluxo`, `Historico`, `Operacoes`; resolve contexto de empresa/corretor/perfil no frontend. | RUNTIME_ATUAL / ORQUESTRADOR_UI | P1 |
| `src/components/MesaCliente/TabEmpreendimentos.jsx` | Lista empreendimentos; importa tabela comercial; valida JSON admin; processa PDF/CSV/TXT; chama mutacoes de importacao. | RUNTIME_ATUAL / IMPORTACAO_UI | P0/P1 |
| `src/components/MesaCliente/TabFluxo.jsx` | Selecao de unidade; montagem de fluxo; parsing de observacoes/payload; cria simulacao; enriquecimento manual por final/prumada. | RUNTIME_ATUAL / FLUXO_FINANCEIRO_UI | P0/P1 |
| `src/components/MesaCliente/OperacoesFinanceirasPanel.jsx` | Lista, detalha, resume e aplica operacao financeira via hooks/RPCs; possui guard visual antes de aplicar operacao. | RUNTIME_ATUAL / OPERACOES_FINANCEIRAS_UI | P0/P1 |
| `src/components/MesaCliente/hooks/useMesaData.js` | Camada React Query; centraliza queries/mutations de MesaCliente e operacoes financeiras. | RUNTIME_ATUAL / DATA_HOOKS | P1 |
| `src/features/mesaCliente/api/mesaClienteApi.js` | Wrapper generico `callMesaRpc`; centraliza RPCs principais MesaCliente. | RUNTIME_ATUAL / API_RPC | P0/P1 |
| `src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js` | Wrapper especifico de operacoes financeiras; sanitiza parametros e aplica allowlist/denylist de chaves de autoridade frontend. | RUNTIME_ATUAL / API_RPC_FINANCEIRA | P0/P1 |
| `src/features/mesaCliente/parser/nativeFirstParser.js` | Parser native-first; PDF.js; TXT/CSV; fallback Worker/Make; normalizacao de metadados de parcela unica. | RUNTIME_ATUAL / PARSER | P0/P1 |
| `src/pages/MesaClienteNativeFirst.jsx` | Pagina/parsers legados ou paralelos com Worker/PDF.js e stack nativa semelhante. | LEGACY_OU_PARALLEL_RUNTIME / PENDENTE_RECONCILIACAO | P1 |
| `src/lib/supabaseClient.js` | Cliente Supabase compartilhado com URL e anon key hardcoded. | CLIENT_SUPABASE / ACHADO_SEGURANCA | P0 |
| `src/components/MesaCliente/supabaseClient.js` | Cliente Supabase duplicado com URL e anon key hardcoded. | CLIENT_SUPABASE_DUPLICADO / ACHADO_SEGURANCA | P0 |

---

## 5. Evidencias tecnicas relevantes

### 5.1 Runtime principal usa props `sb` e `token`

`src/pages/MesaCliente.jsx` bloqueia a tela quando nao recebe `sb.rpc` ou `token`, e repassa `empresaId`, `corretorId` e `isGestor` calculados a partir de `corretor`.

Classificacao:

```text
CONFIRMADO_PELO_CODIGO: ha guarda de sessao no wrapper.
RISCO_P0_P1: empresaId/corretorId/isGestor vem do frontend e precisam ser tratados apenas como contexto de UI, nunca como autoridade final.
DEPENDENTE_SUPABASE_REAL: banco/RPC deve validar auth.uid(), tenant, empresa e perfil.
```

### 5.2 Componente principal nao cria cliente Supabase paralelo

`src/components/MesaCliente/index.jsx` registra em comentario que recebe `sb/token` do App principal e nao cria cliente Supabase paralelo. O runtime atual de abas repassa `sb` e `token` para componentes filhos.

Classificacao:

```text
PARCIALMENTE_CONFIRMADO: padrao de injecao de cliente/token por props no fluxo observado.
POSSIVEL_DIVERGENCIA: ainda existem arquivos supabaseClient hardcoded exportando clientes Supabase.
```

### 5.3 API MesaCliente centraliza chamadas via RPC

`src/features/mesaCliente/api/mesaClienteApi.js` define `callMesaRpc({ sb, token, fn, args })`, valida presenca de `sb.rpc` e `token`, executa `sb.rpc(fn, args, token)` e normaliza erro/resultado.

RPCs mapeadas no wrapper principal:

```text
get_empreendimentos_mesa
get_empresa_mesa_config
get_historico_mesas
get_unidades_mesa
registrar_upload_arquivo_mesa
criar_mesa_simulacao
aprovar_rejeitar_mesa
importar_mesa_cliente_parser_resultado
usuario_pode_importar_mesa_json_admin
importar_mesa_cliente_json_admin
importar_mesa_cliente_disponibilidade_oficial
salvar_mesa_cliente_enriquecimento
mesa_cliente_obter_simulacao_fluxo_historico
```

Classificacao:

```text
CONFIRMADO_PELO_CODIGO: uso centralizado de RPCs no codigo observado.
DEPENDENTE_SUPABASE_REAL: nao comprova que as RPCs reais validam auth.uid(), tenant, empresa, perfil, grants e RLS.
```

### 5.4 API de operacoes financeiras usa RPCs dedicadas e sanitizacao

`src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js` define RPCs financeiras dedicadas:

```text
mesa_cliente_listar_operacoes_financeiras_admin
mesa_cliente_obter_operacao_financeira_admin
mesa_cliente_resumir_operacao_financeira_admin
mesa_cliente_obter_resumo_operacao_cliente_safe
mesa_cliente_aplicar_operacao_financeira_admin
```

O arquivo tambem define uma lista de chaves que nao devem ser aceitas como autoridade do frontend, incluindo `empresa_id`, `tenant_id`, `corretor_id`, `role`, `perfil`, `valor_base`, `valor_movido`, calculos financeiros, status, flags cliente-safe, metadata e campos de auditoria.

Classificacao:

```text
CONFIRMADO_PELO_CODIGO: ha sanitizacao explicita de parametros e bloqueio de chaves sensiveis no frontend financeiro.
RISCO_RESIDUAL: sanitizacao frontend e defesa auxiliar, nao controle soberano.
DEPENDENTE_SUPABASE_REAL: seguranca final precisa estar em RPC/banco.
```

### 5.5 Painel de operacoes financeiras possui guard visual, mas autoridade final deve ser RPC

`OperacoesFinanceirasPanel.jsx` consulta lista/detalhe/resumo/admin/cliente-safe e so exibe a acao de aplicar quando `modo === 'admin'`, `usuarioPodeAplicar` e `canAplicarOperacaoFinanceira(...)` permitem. O proprio texto da UI indica que a RPC continua sendo autoridade final antes de alterar fluxo financeiro.

Classificacao:

```text
CONFIRMADO_PELO_CODIGO: guard visual existe.
RISCO_P0_P1: aplicar operacao financeira e fluxo financeiro critico.
DEPENDENTE_SUPABASE_REAL: RPC `mesa_cliente_aplicar_operacao_financeira_admin` deve validar autoridade final.
```

### 5.6 Parser native-first tem fallback externo Worker/Make

`nativeFirstParser.js` usa PDF.js via CDN, processa PDF/TXT/CSV, rejeita imagem/OCR direto nesta camada e usa fallback para Worker configuravel por env ou default publico.

Classificacao:

```text
CONFIRMADO_PELO_CODIGO: parser native-first existe e usa fallback Worker/Make.
PARCIALMENTE_CONFIRMADO: leitura de que parser nativo vem antes do fallback nos fluxos observados.
DEPENDENTE_TESTE_RUNTIME: nao prova cobertura de layouts reais.
RISCO_P1: dependencia operacional externa/CDN/Worker exige SRE, observabilidade e LGPD.
```

Regras que precisam de validacao posterior:

```text
- Parser nativo funcionou: nao acionar Make.
- Arquivo conhecido sem valores financeiros: bloquear sem Make.
- Parser nativo nao gerou linhas uteis em layout desconhecido: fallback pode acionar Worker/Make.
- Divergencia financeira relevante: bloquear proposta.
```

### 5.7 Fluxo financeiro da UI reconstrói fluxo a partir de observacoes/payload

`TabFluxo.jsx` possui funcoes para extrair payload de `observacoes`, interpretar parcelas, criar fluxo visual e chamar `criarMesaSimulacao` com `fluxoJson`, `valorTotal`, `metaObraPct`, `tabelaProvisoria` e IDs de empresa/empreendimento/unidade/corretor.

Classificacao:

```text
CONFIRMADO_PELO_CODIGO: fluxo visual e payload financeiro sao montados no frontend.
RISCO_P0_P1: frontend nao pode ser autoridade final sobre financeiro, tenant, empresa, permissao ou proposta.
DEPENDENTE_SUPABASE_REAL: RPC/banco deve revalidar tudo antes de persistir, aprovar ou aplicar.
```

Pendencia especifica indicada pelo GPT 8:

```text
Validar se quantidade de parcelas vem da tabela carregada e nao da data atual do sistema.
Validar se premissas financeiras ficam claras, auditaveis e revisaveis.
```

### 5.8 Busca por `supabase.from` nao retornou codigo runtime relevante

A busca por `supabase.from` nao retornou arquivos runtime de MesaCliente, apenas documentacao/auditoria.

Classificacao:

```text
PARCIALMENTE_CONFIRMADO: nao foi observado acesso direto a tabelas via `supabase.from` no runtime inspecionado.
LIMITACAO: busca GitHub nao substitui grep local completo.
```

### 5.9 Achado P0 - anon key hardcoded em dois clientes Supabase

Foram observados dois arquivos com `createClient` e anon key hardcoded:

```text
src/lib/supabaseClient.js
src/components/MesaCliente/supabaseClient.js
```

O valor da chave foi intencionalmente redigido nesta auditoria e nao deve ser copiado para documentos, logs, comentarios ou prompts.

Classificacao:

```text
P0_SEGURANCA / BLOQUEANTE_PARA_CONCLUSAO_DE_KEYS
```

Observacao:

```text
Mesmo anon key nao sendo service_role, o requisito de governanca FECH.AI e eliminar hardcoded e usar ambiente/configuracao segura. A presenca de anon key hardcoded impede afirmar que anon keys hardcoded foram eliminadas.
```

---

## 6. Matriz Codigo AS-IS vs documentacao PR #52

A PR #52 nao declarou nenhum documento MesaCliente como `OFICIAL_VIGENTE`. Portanto, esta matriz nao trata diferencas como quebra de documentacao oficial; trata como confirmacao, confirmacao parcial, nao comprovacao ou possivel divergencia frente a documentos candidatos.

| Tema PR #52 | Evidencia no codigo PR #53 | Status | Observacao |
|---|---|---|---|
| Uso de RPCs como camada de acesso | `mesaClienteApi.js` e `mesaClienteOperacoesFinanceirasApi.js` centralizam chamadas RPC. | CONFIRMADO_PELO_CODIGO | Segurança final ainda depende do Supabase real. |
| Banco/RPC como autoridade final | Frontend chama RPCs e texto do painel declara autoridade final da RPC. | PARCIALMENTE_CONFIRMADO | Codigo frontend nao prova validacao no banco. |
| Frontend nao deve ser soberano | Frontend repassa IDs e monta payload financeiro. | POSSIVEL_DIVERGENCIA / RISCO_P0_P1 | Deve ser mitigado por RPC/RLS real. |
| Cliente-safe | Ha chamada para resumo cliente-safe no painel de operacoes. | PARCIALMENTE_CONFIRMADO | Payload real e allowlist dependem da RPC real. |
| Parser native-first | Existe `nativeFirstParser.js` com parsers nativos e fallback. | CONFIRMADO_PELO_CODIGO | Falta teste runtime com arquivos reais. |
| Worker/Make fallback | Existe fallback Worker/Make em parser. | CONFIRMADO_PELO_CODIGO | Deve ser fallback controlado, nao primeira escolha para layout conhecido. |
| Fonte soberana da tabela importada | Fluxo deriva de unidade/payload/observacoes. | PARCIALMENTE_CONFIRMADO | Necessita confirmar importacao, disponibilidade oficial e Supabase. |
| Disponibilidade oficial | Existe RPC `importar_mesa_cliente_disponibilidade_oficial` no wrapper. | PARCIALMENTE_CONFIRMADO | Necessita validar banco e UI especifica. |
| Operacoes financeiras admin | Existem RPCs dedicadas e painel admin. | CONFIRMADO_PELO_CODIGO | Aplicacao financeira depende de RPC real. |
| Auditoria/seguranca de keys | Achado de anon key hardcoded. | POSSIVEL_DIVERGENCIA | Documentacao de governanca exige eliminar hardcoded. |

---

## 7. Matriz Native First vs codigo real

| Item | Status | Observacao |
|---|---|---|
| Detectar layout antes de escolher parser | PARCIALMENTE_CONFIRMADO | `nativeFirstParser.js` usa `detectLayout`, mas `layoutDetector.js` nao foi lido integralmente nesta PR. |
| Executar parser nativo para layout conhecido | PARCIALMENTE_CONFIRMADO | Chamadas para parsers nativos foram observadas; parsers individuais nao foram lidos integralmente. |
| Validar unidades e consistencia financeira | NAO_VALIDADO | `validateCanonRow.js` e testes reais nao foram lidos/rodados. |
| Bloquear arquivo sem valores financeiros | CONFIRMADO_PELO_CODIGO | Ha hardError para espelho sem valores financeiros no parser observado. |
| Worker/Make apenas como fallback | PARCIALMENTE_CONFIRMADO | Fluxo observado aciona Worker depois de tentativas nativas; precisa teste de runtime. |
| OCR/imagem | CONFIRMADO_PELO_CODIGO | Parser rejeita imagem/OCR direto nesta camada. |
| Portal/mirror | NAO_VALIDADO | Arquivos `parsePortalVWebMirror` e `reconcileUnitsWithMirror` nao foram lidos integralmente nesta PR. |

---

## 8. Matriz FluxoBuilder/TabFluxo vs codigo real

| Item | Status | Observacao |
|---|---|---|
| TabFluxo foi lido | CONFIRMADO_PELO_CODIGO | Foi observado parse de payload, filtro de unidades e chamada de criacao de simulacao. |
| FluxoBuilder foi lido integralmente | NAO_VALIDADO | Arquivo consta como leitura obrigatoria posterior. |
| Quantidade de parcelas vem da tabela | PARCIALMENTE_CONFIRMADO | TabFluxo usa campos do payload/observacoes; falta validar parser e FluxoBuilder. |
| Frontend recalcula ou reescreve premissas | PARCIALMENTE_CONFIRMADO | Ha montagem visual/fluxoJson no frontend; regra final deve ser RPC/banco. |
| Premissas expostas/auditaveis | DEPENDENTE_TESTE_RUNTIME | Precisa teste funcional com arquivos reais e proposta gerada. |

---

## 9. Matriz Operacoes Financeiras vs codigo real

| Item | Status | Observacao |
|---|---|---|
| Painel administrativo existe | CONFIRMADO_PELO_CODIGO | `OperacoesFinanceirasPanel.jsx` foi lido. |
| RPCs financeiras dedicadas existem no frontend | CONFIRMADO_PELO_CODIGO | Listar, obter, resumir, cliente-safe e aplicar. |
| Guard visual existe | CONFIRMADO_PELO_CODIGO | Depende de modo admin, permissao e gating. |
| RPC e autoridade final | DEPENDENTE_SUPABASE_REAL | Codigo nao prova funcao, grants, RLS ou policies. |
| Cliente-safe sem vazamento | DEPENDENTE_SUPABASE_REAL | Necessita payload real da RPC cliente-safe. |
| Aplicacao financeira segura | DEPENDENTE_SUPABASE_REAL | Exige teste de role, tenant, status e idempotencia. |

---

## 10. Cliente-safe e campos sensiveis

A auditoria deve tratar cliente-safe com cautela maxima.

Campos e grupos sensiveis que nao devem sair em payload cliente-safe sem contrato explicito:

```text
identificacao interna
contato do cliente
tenant_id
empresa_id
time/equipe/perfil
politica comercial interna
payloads brutos
raw parser payload
valores financeiros internos
regras de remuneracao
premio
comissao
VPL interno
metadata de auditoria
flags internas
service/debug payload
```

Status atual:

```text
DEPENDENTE_SUPABASE_REAL / DEPENDENTE_PAYLOAD_REAL
```

---

## 11. Matriz de risco AS-IS

| Achado | Risco | Evidencia | Bloqueio |
|---|---:|---|---|
| Anon key hardcoded em `src/lib/supabaseClient.js` | P0 | `createClient` com URL e anon key literal. | Bloqueia conclusao de eliminacao de keys hardcoded. |
| Anon key hardcoded em `src/components/MesaCliente/supabaseClient.js` | P0 | Cliente Supabase duplicado com key literal. | Bloqueia conclusao de eliminacao de keys hardcoded. |
| Frontend repassa `empresaId`, `corretorId`, `isGestor` | P0/P1 | Props derivadas do objeto `corretor`. | Banco/RPC deve ignorar autoridade do frontend e validar auth.uid/perfil. |
| RPCs recebem `p_empresa_id`, `p_empreendimento_id`, `p_unidade_id` do frontend | P0/P1 | `mesaClienteApi.js`. | Supabase real deve validar tenant/ownership. |
| Frontend monta `fluxoJson` financeiro | P0/P1 | `TabFluxo.jsx`. | RPC/motor financeiro deve validar payload e regras. |
| Aplicacao financeira possui guard visual | P1 | `OperacoesFinanceirasPanel.jsx`. | Guard visual e auxiliar; RPC deve ser autoridade. |
| Parser usa Worker/CDN externo | P1 | `nativeFirstParser.js`. | Validar SRE, disponibilidade, LGPD e fallback. |
| Runtime paralelo/legado `MesaClienteNativeFirst.jsx` | P1 | Pagina com parser/Worker proprio. | Reconciliar se ainda esta roteada/usada. |
| Busca `supabase.from` sem runtime relevante | P2/P1 | Busca GitHub. | Confirmar por grep local completo. |
| Native First core nao todo lido integralmente | P1 | Parsers/layout/mirror/validator pendentes. | Exige proxima rodada de leitura completa. |
| Testes funcionais nao executados | P1 | Sem build/teste/arquivo real. | Bloqueia conclusao de aderencia runtime. |

---

## 12. Testes e evidencias exigidos na auditoria futura

Antes de qualquer implementacao ou correcao funcional, as proximas auditorias devem exigir evidencia ou pendencia explicita para:

```text
tabela valida
tabela incompleta
PDF complexo
OCR ruim ou imagem rejeitada
unidade duplicada
valor ausente
usuario sem permissao
cross-tenant
rollback
proposta gerada
conferencia de valores esperados versus obtidos
build local ou CI
logs de RPC
payload cliente-safe real
```

Para MesaCliente, qualquer divergencia financeira relevante deve bloquear proposta. Montar valores trocados e nao avisar e inaceitavel.

---

## 13. O que pode ser afirmado com evidencia de codigo

```text
1. O runtime atual do MesaCliente usa uma camada API baseada em RPCs nos arquivos inspecionados.
2. Ha wrappers React Query para consultas e mutacoes MesaCliente.
3. Ha painel de operacoes financeiras com RPCs dedicadas para listar, obter, resumir, cliente-safe e aplicar operacao.
4. Ha sanitizacao frontend para remover chaves de autoridade em parametros financeiros.
5. Ha parser native-first com fallback Worker/Make.
6. Ha pelo menos duas anon keys hardcoded no codigo.
7. Nao e possivel afirmar seguranca multi-tenant so pelo codigo frontend.
```

---

## 14. O que nao pode ser afirmado ainda

```text
1. Nao e possivel afirmar que RPCs reais validam auth.uid(), tenant, empresa, corretor e perfil.
2. Nao e possivel afirmar que grants de anon/authenticated/service_role estao corretos.
3. Nao e possivel afirmar que RLS esta ativa e efetiva nas tabelas MesaCliente.
4. Nao e possivel afirmar que migrations documentadas estao aplicadas no Supabase real.
5. Nao e possivel afirmar que cliente-safe nao vaza campos internos sem inspecionar RPC real e payload real.
6. Nao e possivel afirmar que o motor financeiro e soberano no banco.
7. Nao e possivel afirmar que o parser/fallback Worker esta aderente a LGPD e observabilidade sem auditoria tecnica especifica.
8. Nao e possivel afirmar que anon keys hardcoded foram eliminadas; pelo contrario, a auditoria encontrou hardcoded.
9. Nao e possivel afirmar aderencia total Native First sem ler layoutDetector, parsers, validators, mirror e rodar testes.
```

---

## 15. Queries/checks read-only recomendados para proxima auditoria Supabase

```sql
-- Functions MesaCliente
select n.nspname as schema,
       p.proname as function_name,
       pg_get_function_identity_arguments(p.oid) as args,
       pg_get_function_result(p.oid) as result,
       p.prosecdef as security_definer,
       p.provolatile as volatility
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname not in ('pg_catalog', 'information_schema')
  and (p.proname ilike '%mesa%' or p.proname ilike '%agenda%' or p.proname ilike '%operacao%');

-- Grants
select routine_schema, routine_name, grantee, privilege_type
from information_schema.routine_privileges
where routine_name ilike '%mesa%'
   or routine_name ilike '%agenda%'
   or routine_name ilike '%operacao%';

-- RLS
select schemaname, tablename, rowsecurity
from pg_tables
where tablename ilike '%mesa%'
   or tablename ilike '%agenda%'
   or tablename ilike '%operacao%';

-- Policies
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_policies
where tablename ilike '%mesa%'
   or tablename ilike '%agenda%'
   or tablename ilike '%operacao%';
```

---

## 16. Criterios de aceite da revisao AS-IS

A PR #53 pode ser aceita como auditoria tecnica AS-IS se entregar:

```text
- lista de arquivos lidos diretamente;
- lista de arquivos relevantes nao auditados integralmente;
- matriz Native First vs codigo real;
- matriz TabFluxo/FluxoBuilder vs codigo real;
- matriz Operacoes Financeiras vs codigo real;
- classificacao explicita de frontend authority;
- contrato do que e cliente-safe e do que e sensivel;
- divergencias com PR #52 separadas entre confirmadas, suspeitas e dependentes de Supabase;
- nenhuma proposta de alteracao de codigo nesta etapa.
```

Status desta PR apos ajuste GPT 8:

```text
ATENDE_COM_RESSALVAS / DOCUMENTACAO_ONLY / SEM_IMPLEMENTACAO
```

---

## 17. Bloqueios antes de implementacao

Bloqueios atuais:

```text
- Remover/rotacionar anon keys hardcoded precisa ser tratado como item P0 em PR propria, mas ainda sem misturar com esta auditoria.
- Qualquer implementacao MesaCliente continua bloqueada ate Supabase real confirmar RPC/RLS/grants.
- Qualquer alteracao em parser/motor financeiro continua bloqueada sem testes de regressao com arquivos reais.
- Qualquer uso de `empresaId`, `corretorId`, `isGestor` ou perfil vindo do frontend como autoridade final e proibido.
- Qualquer conclusao sobre cliente-safe exige inspecao da RPC real e payload real.
```

---

## 18. Proximos passos sem implementacao

1. Validar esta PR documental de codigo AS-IS.
2. Abrir auditoria Supabase/RPC/RLS AS-IS do MesaCliente.
3. Mapear migrations `supabase/migrations/*mesa_cliente*.sql` contra estado real aplicado.
4. Criar matriz `Codigo -> RPC -> Migration -> Supabase real -> RLS/Grant -> Documento canonico`.
5. Abrir PR separada para seguranca de anon keys hardcoded somente apos autorizacao explicita.
6. Nao implementar parser, motor financeiro, RPC, RLS, frontend ou producao ate concluir reconciliacao.

---

## 19. Parecer final

```text
Status da auditoria de codigo: AS_IS_CODIGO / PENDENTE_RECONCILIACAO_SUPABASE_REAL
Tipo da PR: documentacao-only
Implementacao autorizada: nao
Risco global MesaCliente codigo: P0/P1
Principal achado P0: anon keys hardcoded em clientes Supabase
Principal dependencia: validar RPC/RLS/grants no Supabase real
Ressalva GPT 8 incorporada: escopo auditado, lacunas e matrizes explicitadas
Proxima etapa: auditoria Supabase/RPC/RLS AS-IS
```
