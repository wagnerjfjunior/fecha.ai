# FECH.AI - Auditoria AS-IS de Codigo MesaCliente v1

**Data:** 2026-06-03
**Status:** `AS_IS_CODIGO / PENDENTE_RECONCILIACAO_SUPABASE_REAL`
**Responsavel conceitual:** GPT 0 - FECH.AI Documentation Auditor
**Especialista de dominio recomendado:** GPT 8 - MesaCliente Tabelas Propostas Specialist
**Executor operacional:** Projeto Principal FECH.AI com conector GitHub
**Arquivo:** `docs/audits/code/2026-06-03-mesacliente-code-as-is-v1.md`
**Tipo:** documentacao-only.
**Escopo proibido:** nao altera App, Supabase, RLS, RPCs, migrations, parser, motor financeiro, Worker, Make/n8n, frontend, MesaCliente runtime, LeadOps, PME, Discador, ADS/CAPI, Vercel, GitHub Actions, integracoes reais ou producao.

---

## 1. Objetivo

Auditar o codigo atual relacionado ao MesaCliente em modo AS-IS, sem implementacao, para verificar se o codigo confirma, contradiz ou nao comprova os contratos documentais inventariados na PR #52.

Esta auditoria nao autoriza correcoes nem deploy. Ela registra evidencias, riscos e proximos passos para reconciliacao com Supabase real.

Nota editorial: este arquivo foi normalizado em ASCII para remover risco de caracteres ocultos ou bidirecionais no Markdown.

---

## 2. Escopo de codigo verificado

Consulta operacional feita no GitHub, em modo read-only, sobre `main` apos merge da PR #52.

Arquivos e areas verificados:

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

Buscas realizadas:

```text
MesaCliente
mesa_cliente
supabase.rpc
supabase.from
createClient
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

## 3. Mapa AS-IS de componentes e responsabilidades

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

## 4. Evidencias tecnicas relevantes

### 4.1 Runtime principal usa props `sb` e `token`

`src/pages/MesaCliente.jsx` bloqueia a tela quando nao recebe `sb.rpc` ou `token`, e repassa `empresaId`, `corretorId` e `isGestor` calculados a partir de `corretor`.

Classificacao:

```text
POSITIVO: ha guarda de sessao no wrapper.
PENDENTE: empresaId/corretorId/isGestor vem do frontend e precisam ser tratados apenas como contexto de UI, nunca como autoridade final.
```

### 4.2 Componente principal nao cria cliente Supabase paralelo

`src/components/MesaCliente/index.jsx` registra em comentario que recebe `sb/token` do App principal e nao cria cliente Supabase paralelo. O runtime atual de abas repassa `sb` e `token` para componentes filhos.

Classificacao:

```text
POSITIVO: padrao de injecao de cliente/token por props.
PENDENTE: existencia de arquivos supabaseClient hardcoded precisa reconciliacao, pois ainda ha clientes Supabase exportados no codigo.
```

### 4.3 API MesaCliente centraliza chamadas via RPC

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
POSITIVO: uso centralizado de RPCs no codigo observado.
PENDENTE_SUPABASE_REAL: nao comprova que as RPCs reais validam auth.uid(), tenant, empresa, perfil, grants e RLS.
```

### 4.4 API de operacoes financeiras usa RPCs dedicadas e sanitizacao

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
POSITIVO: ha sanitizacao explicita de parametros e bloqueio de chaves sensiveis no frontend financeiro.
PENDENTE_SUPABASE_REAL: a seguranca final precisa estar em RPC/banco; sanitizacao frontend e defesa auxiliar, nao controle soberano.
```

### 4.5 Painel de operacoes financeiras possui guard visual, mas a autoridade final deve ser RPC

`OperacoesFinanceirasPanel.jsx` consulta lista/detalhe/resumo/admin/cliente-safe e so exibe a acao de aplicar quando `modo === 'admin'`, `usuarioPodeAplicar` e `canAplicarOperacaoFinanceira(...)` permitem. O proprio texto da UI indica que a RPC continua sendo autoridade final antes de alterar fluxo financeiro.

Classificacao:

```text
POSITIVO: guard visual existe e e coerente com o contrato.
PENDENTE_SUPABASE_REAL: aplicar operacao financeira e P0/P1 e precisa validacao real da RPC `mesa_cliente_aplicar_operacao_financeira_admin`.
```

### 4.6 Parser native-first tem fallback externo Worker/Make

`nativeFirstParser.js` usa PDF.js via CDN, processa PDF/TXT/CSV, rejeita imagem/OCR direto nesta camada e usa fallback para Worker configuravel por env ou default publico.

Classificacao:

```text
POSITIVO: rejeita imagem/OCR nesta camada e usa parser nativo antes do fallback.
RISCO P1: dependencia operacional externa/CDN/Worker precisa constar em SRE/observabilidade e validacao de ambiente.
PENDENTE: nao validar motor/parser sem testes com arquivos reais.
```

### 4.7 Fluxo financeiro da UI reconstrói fluxo a partir de observacoes/payload

`TabFluxo.jsx` possui funcoes para extrair payload de `observacoes`, interpretar parcelas, criar fluxo visual e chamar `criarMesaSimulacao` com `fluxoJson`, `valorTotal`, `metaObraPct`, `tabelaProvisoria` e IDs de empresa/empreendimento/unidade/corretor.

Classificacao:

```text
POSITIVO: fluxo derivado da tabela importada/payload.
RISCO P0/P1: frontend monta payload financeiro; RPC/banco deve revalidar tudo antes de persistir/aprovar/aplicar.
```

### 4.8 Busca por `supabase.from` nao retornou codigo runtime relevante

A busca por `supabase.from` nao retornou arquivos runtime de MesaCliente, apenas documentacao/auditoria.

Classificacao:

```text
POSITIVO: nao foi observado acesso direto a tabelas via supabase.from no runtime inspecionado.
LIMITACAO: busca GitHub nao substitui grep local completo.
```

### 4.9 Achado P0 - anon key hardcoded em dois clientes Supabase

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

## 5. Matriz de risco AS-IS

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

---

## 6. O que pode ser afirmado com evidencia de codigo

```text
1. O runtime atual do MesaCliente usa uma camada API baseada em RPCs, nao chamadas diretas explicitas a tabelas nos arquivos inspecionados.
2. Ha wrappers React Query para consultas e mutacoes MesaCliente.
3. Ha painel de operacoes financeiras com RPCs dedicadas para listar, obter, resumir, cliente-safe e aplicar operacao.
4. Ha sanitizacao frontend para remover chaves de autoridade em parametros financeiros.
5. Ha parser native-first com fallback Worker/Make.
6. Ha pelo menos duas anon keys hardcoded no codigo.
7. Nao e possivel afirmar seguranca multi-tenant so pelo codigo frontend.
```

---

## 7. O que nao pode ser afirmado ainda

```text
1. Nao e possivel afirmar que RPCs reais validam auth.uid(), tenant, empresa, corretor e perfil.
2. Nao e possivel afirmar que grants de anon/authenticated/service_role estao corretos.
3. Nao e possivel afirmar que RLS esta ativa e efetiva nas tabelas MesaCliente.
4. Nao e possivel afirmar que migrations documentadas estao aplicadas no Supabase real.
5. Nao e possivel afirmar que cliente-safe nao vaza campos internos sem inspecionar RPC real e payload real.
6. Nao e possivel afirmar que o motor financeiro e soberano no banco.
7. Nao e possivel afirmar que o parser/fallback Worker esta aderente a LGPD e observabilidade sem auditoria tecnica especifica.
8. Nao e possivel afirmar que anon keys hardcoded foram eliminadas; pelo contrario, a auditoria encontrou hardcoded.
```

---

## 8. Arquivos que exigem leitura completa na proxima rodada

```text
src/App.jsx
src/main.jsx
src/pages/MesaClienteOld.jsx
src/pages/MesaClienteNativeFirst.jsx
src/components/MesaCliente/TabHistorico.jsx
src/components/MesaCliente/SegundaViaHistoricoPanel.jsx
src/components/MesaCliente/FluxoBuilder.jsx
src/features/mesaCliente/parser/parserPayloadAdapter.js
src/features/mesaCliente/security/jsonAdminImport.js
src/components/MesaCliente/disponibilidade/DisponibilidadeUploadPreview.jsx
src/mesa/parsers/*
src/mesa/layoutDetector.*
supabase/migrations/*mesa_cliente*.sql
supabase/rollback/*mesa_cliente*.sql
```

---

## 9. Queries/checks read-only recomendados para proxima auditoria Supabase

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

## 10. Criterios de bloqueio antes de implementacao

Bloqueios atuais:

```text
- Remover/rotacionar anon keys hardcoded precisa ser tratado como item P0 em PR propria, mas ainda sem misturar com esta auditoria.
- Qualquer implementacao MesaCliente continua bloqueada ate Supabase real confirmar RPC/RLS/grants.
- Qualquer alteracao em parser/motor financeiro continua bloqueada sem testes de regressao com arquivos reais.
- Qualquer uso de `empresaId`, `corretorId`, `isGestor` ou perfil vindo do frontend como autoridade final e proibido.
- Qualquer conclusao sobre cliente-safe exige inspecao da RPC real e payload real.
```

---

## 11. Proximos passos sem implementacao

1. Validar esta PR documental de codigo AS-IS.
2. Abrir auditoria Supabase/RPC/RLS AS-IS do MesaCliente.
3. Mapear migrations `supabase/migrations/*mesa_cliente*.sql` contra estado real aplicado.
4. Criar matriz `Codigo -> RPC -> Migration -> Supabase real -> RLS/Grant -> Documento canonico`.
5. Abrir PR separada para seguranca de anon keys hardcoded somente apos autorizacao explicita.
6. Nao implementar parser, motor financeiro, RPC, RLS, frontend ou producao ate concluir reconciliacao.

---

## 12. Parecer final

```text
Status da auditoria de codigo: AS_IS_CODIGO / PENDENTE_RECONCILIACAO_SUPABASE_REAL
Tipo da PR: documentacao-only
Implementacao autorizada: nao
Risco global MesaCliente codigo: P0/P1
Principal achado P0: anon keys hardcoded em clientes Supabase
Principal dependencia: validar RPC/RLS/grants no Supabase real
Proxima etapa: auditoria Supabase/RPC/RLS AS-IS
```
