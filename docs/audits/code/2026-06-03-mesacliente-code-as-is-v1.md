# FECH.AI — Auditoria AS-IS de Código MesaCliente v1

**Data:** 2026-06-03  
**Status:** `AS_IS_CODIGO / PENDENTE_RECONCILIACAO_SUPABASE_REAL`  
**Responsável conceitual:** GPT 0 — FECH.AI Documentation Auditor  
**Especialista de domínio recomendado:** GPT 8 — MesaCliente Tabelas Propostas Specialist  
**Executor operacional:** Projeto Principal FECH.AI com conector GitHub  
**Arquivo:** `docs/audits/code/2026-06-03-mesacliente-code-as-is-v1.md`  
**Tipo:** documentação-only.  
**Escopo proibido:** não altera App, Supabase, RLS, RPCs, migrations, parser, motor financeiro, Worker, Make/n8n, frontend, MesaCliente runtime, LeadOps, PME, Discador, ADS/CAPI, Vercel, GitHub Actions, integrações reais ou produção.

---

## 1. Objetivo

Auditar o código atual relacionado ao MesaCliente em modo AS-IS, sem implementação, para verificar se o código confirma, contradiz ou não comprova os contratos documentais inventariados na PR #52.

Esta auditoria não autoriza correções nem deploy. Ela registra evidências, riscos e próximos passos para reconciliação com Supabase real.

---

## 2. Escopo de código verificado

Consulta operacional feita no GitHub, em modo read-only, sobre `main` após merge da PR #52.

Arquivos e áreas verificados:

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

Limitações:

```text
- Não foi executado teste automatizado.
- Não foi feito build local.
- Não foi feita varredura completa por terminal local.
- Não foi consultado Supabase real.
- Não foi validado se migrations documentadas estão aplicadas.
- Não foi alterado nenhum arquivo de código.
```

---

## 3. Mapa AS-IS de componentes e responsabilidades

| Arquivo | Responsabilidade observada | Classificação | Risco |
|---|---|---|---:|
| `src/pages/MesaCliente.jsx` | Wrapper da página; exige `sb.rpc` e `token`; repassa `corretor`, `empresaId`, `corretorId` e `isGestor` ao componente principal. | RUNTIME_ATUAL / FRONT_WRAPPER | P1 |
| `src/components/MesaCliente/index.jsx` | Componente principal com abas `Empreendimentos`, `Fluxo`, `Histórico`, `Operações`; resolve contexto de empresa/corretor/perfil no frontend. | RUNTIME_ATUAL / ORQUESTRADOR_UI | P1 |
| `src/components/MesaCliente/TabEmpreendimentos.jsx` | Lista empreendimentos; importa tabela comercial; valida JSON admin; processa PDF/CSV/TXT; chama mutações de importação. | RUNTIME_ATUAL / IMPORTACAO_UI | P0/P1 |
| `src/components/MesaCliente/TabFluxo.jsx` | Seleção de unidade; montagem de fluxo; parsing de observações/payload; cria simulação; enriquecimento manual por final/prumada. | RUNTIME_ATUAL / FLUXO_FINANCEIRO_UI | P0/P1 |
| `src/components/MesaCliente/OperacoesFinanceirasPanel.jsx` | Lista, detalha, resume e aplica operação financeira via hooks/RPCs; possui guard visual antes de aplicar operação. | RUNTIME_ATUAL / OPERACOES_FINANCEIRAS_UI | P0/P1 |
| `src/components/MesaCliente/hooks/useMesaData.js` | Camada React Query; centraliza queries/mutations de MesaCliente e operações financeiras. | RUNTIME_ATUAL / DATA_HOOKS | P1 |
| `src/features/mesaCliente/api/mesaClienteApi.js` | Wrapper genérico `callMesaRpc`; centraliza RPCs principais MesaCliente. | RUNTIME_ATUAL / API_RPC | P0/P1 |
| `src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js` | Wrapper específico de operações financeiras; sanitiza parâmetros e aplica allowlist/denylist de chaves de autoridade frontend. | RUNTIME_ATUAL / API_RPC_FINANCEIRA | P0/P1 |
| `src/features/mesaCliente/parser/nativeFirstParser.js` | Parser native-first; PDF.js; TXT/CSV; fallback Worker/Make; normalização de metadados de parcela única. | RUNTIME_ATUAL / PARSER | P0/P1 |
| `src/pages/MesaClienteNativeFirst.jsx` | Página/parsers legados ou paralelos com Worker/PDF.js e stack nativa semelhante. | LEGACY_OU_PARALLEL_RUNTIME / PENDENTE_RECONCILIACAO | P1 |
| `src/lib/supabaseClient.js` | Cliente Supabase compartilhado com URL e anon key hardcoded. | CLIENT_SUPABASE / ACHADO_SEGURANCA | P0 |
| `src/components/MesaCliente/supabaseClient.js` | Cliente Supabase duplicado com URL e anon key hardcoded. | CLIENT_SUPABASE_DUPLICADO / ACHADO_SEGURANCA | P0 |

---

## 4. Evidências técnicas relevantes

### 4.1 Runtime principal usa props `sb` e `token`

`src/pages/MesaCliente.jsx` bloqueia a tela quando não recebe `sb.rpc` ou `token`, e repassa `empresaId`, `corretorId` e `isGestor` calculados a partir de `corretor`.

Classificação:

```text
POSITIVO: há guarda de sessão no wrapper.
PENDENTE: empresaId/corretorId/isGestor vêm do frontend e precisam ser tratados apenas como contexto de UI, nunca como autoridade final.
```

### 4.2 Componente principal não cria cliente Supabase paralelo

`src/components/MesaCliente/index.jsx` registra em comentário que recebe `sb/token` do App principal e não cria cliente Supabase paralelo. O runtime atual de abas repassa `sb` e `token` para componentes filhos.

Classificação:

```text
POSITIVO: padrão de injeção de cliente/token por props.
PENDENTE: existência de arquivos supabaseClient hardcoded precisa reconciliação, pois ainda há clientes Supabase exportados no código.
```

### 4.3 API MesaCliente centraliza chamadas via RPC

`src/features/mesaCliente/api/mesaClienteApi.js` define `callMesaRpc({ sb, token, fn, args })`, valida presença de `sb.rpc` e `token`, executa `sb.rpc(fn, args, token)` e normaliza erro/resultado.

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

Classificação:

```text
POSITIVO: uso centralizado de RPCs no código observado.
PENDENTE_SUPABASE_REAL: não comprova que as RPCs reais validam auth.uid(), tenant, empresa, perfil, grants e RLS.
```

### 4.4 API de operações financeiras usa RPCs dedicadas e sanitização

`src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js` define RPCs financeiras dedicadas:

```text
mesa_cliente_listar_operacoes_financeiras_admin
mesa_cliente_obter_operacao_financeira_admin
mesa_cliente_resumir_operacao_financeira_admin
mesa_cliente_obter_resumo_operacao_cliente_safe
mesa_cliente_aplicar_operacao_financeira_admin
```

O arquivo também define uma lista de chaves que não devem ser aceitas como autoridade do frontend, incluindo `empresa_id`, `tenant_id`, `corretor_id`, `role`, `perfil`, `valor_base`, `valor_movido`, cálculos financeiros, status, flags cliente-safe, metadata e campos de auditoria.

Classificação:

```text
POSITIVO: há sanitização explícita de parâmetros e bloqueio de chaves sensíveis no frontend financeiro.
PENDENTE_SUPABASE_REAL: a segurança final precisa estar em RPC/banco; sanitização frontend é defesa auxiliar, não controle soberano.
```

### 4.5 Painel de operações financeiras possui guard visual, mas a autoridade final deve ser RPC

`OperacoesFinanceirasPanel.jsx` consulta lista/detalhe/resumo/admin/cliente-safe e só exibe a ação de aplicar quando `modo === 'admin'`, `usuarioPodeAplicar` e `canAplicarOperacaoFinanceira(...)` permitem. O próprio texto da UI indica que a RPC continua sendo autoridade final antes de alterar fluxo financeiro.

Classificação:

```text
POSITIVO: guard visual existe e é coerente com o contrato.
PENDENTE_SUPABASE_REAL: aplicar operação financeira é P0/P1 e precisa validação real da RPC `mesa_cliente_aplicar_operacao_financeira_admin`.
```

### 4.6 Parser native-first tem fallback externo Worker/Make

`nativeFirstParser.js` usa PDF.js via CDN, processa PDF/TXT/CSV, rejeita imagem/OCR direto nesta camada e usa fallback para Worker configurável por env ou default público.

Classificação:

```text
POSITIVO: rejeita imagem/OCR nesta camada e usa parser nativo antes do fallback.
RISCO P1: dependência operacional externa/CDN/Worker precisa constar em SRE/observabilidade e validação de ambiente.
PENDENTE: não validar motor/parser sem testes com arquivos reais.
```

### 4.7 Fluxo financeiro da UI reconstrói fluxo a partir de observações/payload

`TabFluxo.jsx` possui funções para extrair payload de `observacoes`, interpretar parcelas, criar fluxo visual e chamar `criarMesaSimulacao` com `fluxoJson`, `valorTotal`, `metaObraPct`, `tabelaProvisoria` e IDs de empresa/empreendimento/unidade/corretor.

Classificação:

```text
POSITIVO: fluxo derivado da tabela importada/payload.
RISCO P0/P1: frontend monta payload financeiro; RPC/banco deve revalidar tudo antes de persistir/aprovar/aplicar.
```

### 4.8 Busca por `supabase.from` não retornou código runtime relevante

A busca por `supabase.from` não retornou arquivos runtime de MesaCliente, apenas documentação/auditoria.

Classificação:

```text
POSITIVO: não foi observado acesso direto a tabelas via supabase.from no runtime inspecionado.
LIMITAÇÃO: busca GitHub não substitui grep local completo.
```

### 4.9 Achado P0 — anon key hardcoded em dois clientes Supabase

Foram observados dois arquivos com `createClient` e anon key hardcoded:

```text
src/lib/supabaseClient.js
src/components/MesaCliente/supabaseClient.js
```

O valor da chave foi intencionalmente redigido nesta auditoria e não deve ser copiado para documentos, logs, comentários ou prompts.

Classificação:

```text
P0_SEGURANCA / BLOQUEANTE_PARA_CONCLUSAO_DE_KEYS
```

Observação:

```text
Mesmo anon key não sendo service_role, o requisito de governança FECH.AI é eliminar hardcoded e usar ambiente/configuração segura. A presença de anon key hardcoded impede afirmar que anon keys hardcoded foram eliminadas.
```

---

## 5. Matriz de risco AS-IS

| Achado | Risco | Evidência | Bloqueio |
|---|---:|---|---|
| Anon key hardcoded em `src/lib/supabaseClient.js` | P0 | `createClient` com URL e anon key literal. | Bloqueia conclusão de eliminação de keys hardcoded. |
| Anon key hardcoded em `src/components/MesaCliente/supabaseClient.js` | P0 | Cliente Supabase duplicado com key literal. | Bloqueia conclusão de eliminação de keys hardcoded. |
| Frontend repassa `empresaId`, `corretorId`, `isGestor` | P0/P1 | Props derivadas do objeto `corretor`. | Banco/RPC deve ignorar autoridade do frontend e validar auth.uid/perfil. |
| RPCs recebem `p_empresa_id`, `p_empreendimento_id`, `p_unidade_id` do frontend | P0/P1 | `mesaClienteApi.js`. | Supabase real deve validar tenant/ownership. |
| Frontend monta `fluxoJson` financeiro | P0/P1 | `TabFluxo.jsx`. | RPC/motor financeiro deve validar payload e regras. |
| Aplicação financeira possui guard visual | P1 | `OperacoesFinanceirasPanel.jsx`. | Guard visual é auxiliar; RPC deve ser autoridade. |
| Parser usa Worker/CDN externo | P1 | `nativeFirstParser.js`. | Validar SRE, disponibilidade, LGPD e fallback. |
| Runtime paralelo/legado `MesaClienteNativeFirst.jsx` | P1 | Página com parser/Worker próprio. | Reconciliar se ainda está roteada/usada. |
| Busca `supabase.from` sem runtime relevante | P2/P1 | Busca GitHub. | Confirmar por grep local completo. |

---

## 6. O que pode ser afirmado com evidência de código

```text
1. O runtime atual do MesaCliente usa uma camada API baseada em RPCs, não chamadas diretas explícitas a tabelas nos arquivos inspecionados.
2. Há wrappers React Query para consultas e mutações MesaCliente.
3. Há painel de operações financeiras com RPCs dedicadas para listar, obter, resumir, cliente-safe e aplicar operação.
4. Há sanitização frontend para remover chaves de autoridade em parâmetros financeiros.
5. Há parser native-first com fallback Worker/Make.
6. Há pelo menos duas anon keys hardcoded no código.
7. Não é possível afirmar segurança multi-tenant só pelo código frontend.
```

---

## 7. O que não pode ser afirmado ainda

```text
1. Não é possível afirmar que RPCs reais validam auth.uid(), tenant, empresa, corretor e perfil.
2. Não é possível afirmar que grants de anon/authenticated/service_role estão corretos.
3. Não é possível afirmar que RLS está ativa e efetiva nas tabelas MesaCliente.
4. Não é possível afirmar que migrations documentadas estão aplicadas no Supabase real.
5. Não é possível afirmar que cliente-safe não vaza campos internos sem inspecionar RPC real e payload real.
6. Não é possível afirmar que o motor financeiro é soberano no banco.
7. Não é possível afirmar que o parser/fallback Worker está aderente à LGPD e observabilidade sem auditoria técnica específica.
8. Não é possível afirmar que anon keys hardcoded foram eliminadas; pelo contrário, a auditoria encontrou hardcoded.
```

---

## 8. Arquivos que exigem leitura completa na próxima rodada

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

## 9. Queries/checks read-only recomendados para próxima auditoria Supabase

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

## 10. Critérios de bloqueio antes de implementação

Bloqueios atuais:

```text
- Remover/rotacionar anon keys hardcoded precisa ser tratado como item P0 em PR própria, mas ainda sem misturar com esta auditoria.
- Qualquer implementação MesaCliente continua bloqueada até Supabase real confirmar RPC/RLS/grants.
- Qualquer alteração em parser/motor financeiro continua bloqueada sem testes de regressão com arquivos reais.
- Qualquer uso de `empresaId`, `corretorId`, `isGestor` ou perfil vindo do frontend como autoridade final é proibido.
- Qualquer conclusão sobre cliente-safe exige inspeção da RPC real e payload real.
```

---

## 11. Próximos passos sem implementação

1. Validar esta PR documental de código AS-IS.
2. Abrir auditoria Supabase/RPC/RLS AS-IS do MesaCliente.
3. Mapear migrations `supabase/migrations/*mesa_cliente*.sql` contra estado real aplicado.
4. Criar matriz `Código → RPC → Migration → Supabase real → RLS/Grant → Documento canônico`.
5. Abrir PR separada para segurança de anon keys hardcoded somente após autorização explícita.
6. Não implementar parser, motor financeiro, RPC, RLS, frontend ou produção até concluir reconciliação.

---

## 12. Parecer final

```text
Status da auditoria de código: AS_IS_CODIGO / PENDENTE_RECONCILIACAO_SUPABASE_REAL
Tipo da PR: documentação-only
Implementação autorizada: não
Risco global MesaCliente código: P0/P1
Principal achado P0: anon keys hardcoded em clientes Supabase
Principal dependência: validar RPC/RLS/grants no Supabase real
Próxima etapa: auditoria Supabase/RPC/RLS AS-IS
```
