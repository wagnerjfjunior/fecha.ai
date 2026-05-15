# FECH.AI — Arquitetura Definitiva RPC-centric + TanStack Query

## Status

Documento de decisão arquitetural oficial para a evolução do FECH.AI.

Data: 2026-05-15  
Escopo inicial: Mesa Cliente  
Escopo futuro: Discador, Oferta Ativa, Dashboard, CRM, Lead Distribution Engine, Tenant Provisioning e módulos SaaS multiempresa.

---

## Decisão

O FECH.AI adotará como modelo definitivo:

```txt
React UI
→ hooks com TanStack Query
→ client único oficial do FECH.AI
→ RPCs Supabase tenant-safe
→ RLS/grants como defesa adicional
→ tabelas PostgreSQL
```

A aplicação deve continuar **RPC-centric**. O TanStack Query será usado como camada de cache, estado assíncrono, invalidação e padronização de UX, nunca como justificativa para acessar tabelas sensíveis diretamente pelo frontend.

---

## O que está proibido

1. Criar `supabaseClient` paralelo dentro de features.
2. Criar clients locais dentro de páginas, como `createRpcClient` em `src/pages/MesaCliente.jsx`.
3. Ler token diretamente do `localStorage` dentro de feature/page operacional.
4. Usar `empresa_id` vindo do browser como verdade de segurança.
5. Consultar tabelas sensíveis diretamente pelo frontend quando existir regra de negócio ou isolamento multi-tenant.
6. Usar `service_role` no frontend.
7. Duplicar URL/chave Supabase em múltiplos arquivos.
8. Criar hooks React manuais permanentes para dados compartilhados se TanStack já estiver disponível.

---

## O que está permitido

1. Um único client oficial de dados do FECH.AI.
2. Hooks com TanStack Query chamando RPCs.
3. RPCs com `SECURITY DEFINER`, `search_path` fixo e validação explícita.
4. RLS nas tabelas como segunda camada de proteção.
5. Queries diretas apenas para dados explicitamente públicos ou administrativos de baixo risco, e mesmo assim com justificativa documentada.

---

## Estado real encontrado no repositório

### 1. TanStack Query já está instalado

`package.json` já possui:

```json
"@tanstack/react-query": "^5.74.4"
```

Portanto, não é necessário tratar TanStack como nova dependência.

### 2. QueryClientProvider já existe

`src/main.jsx` já cria `QueryClient` e envolve o App com `QueryClientProvider`.

Isso confirma que a arquitetura final pode usar TanStack sem alterar a raiz da aplicação.

### 3. Existem clients Supabase duplicados

Foram identificados pelo menos:

- `src/lib/supabaseClient.js`
- `src/components/MesaCliente/supabaseClient.js`

Ambos criam `createClient` com URL/chave hardcoded. Isso deve ser removido/refatorado para client único com variáveis de ambiente.

### 4. A rota Mesa Cliente ainda tem integração provisória

`src/pages/MesaCliente.jsx` atualmente:

- cria client RPC próprio;
- lê sessão via `localStorage`;
- usa `session?.user?.empresa_id` sem `session` no escopo, causando risco de tela branca;
- passa contexto incompleto para a feature.

Isso precisa ser corrigido antes do merge definitivo.

### 5. O App principal já possui client `sb`

`src/App.jsx` já possui função interna `createSB` com métodos `auth`, `refreshToken`, `query`, `patch`, `insert`, `rpc`.

Esse padrão deve ser extraído para um client oficial compartilhado, sem quebrar compatibilidade do App.

---

## Arquitetura alvo

### Pasta de serviços

```txt
src/services/fechaiRpcClient.js
```

Responsabilidades:

- centralizar URL Supabase e anon key por variáveis de ambiente;
- montar headers seguros;
- executar RPCs;
- padronizar erro;
- aceitar token autenticado fornecido pelo App/Auth context;
- não expor `service_role`;
- não conter regra visual;
- não conhecer componentes de UI.

### Pasta de dados da Mesa Cliente

```txt
src/features/mesaCliente/api/mesaClienteApi.js
src/features/mesaCliente/hooks/useMesaClienteQueries.js
```

Responsabilidades:

- `mesaClienteApi.js`: funções finas que chamam RPCs via client único;
- `useMesaClienteQueries.js`: hooks TanStack Query/mutation;
- componentes React consomem hooks, não chamam RPC diretamente.

### Componentes de UI

```txt
src/components/MesaCliente/
```

Responsabilidades:

- renderizar abas;
- renderizar cards;
- selecionar empreendimento/unidade;
- abrir fluxo;
- enviar ações para hooks;
- não montar headers;
- não acessar localStorage;
- não conhecer anon key/URL Supabase.

---

## Padrão obrigatório de query keys

```js
export const mesaKeys = {
  root: ['mesa-cliente'],
  empreendimentos: (empresaId) => ['mesa-cliente', 'empreendimentos', empresaId],
  config: (empresaId) => ['mesa-cliente', 'config', empresaId],
  unidades: (empreendimentoId) => ['mesa-cliente', 'unidades', empreendimentoId],
  historico: (empresaId, corretorId, filtros) => ['mesa-cliente', 'historico', empresaId, corretorId, filtros],
};
```

Invalidações mínimas:

- importar parser → invalidar empreendimentos e unidades;
- registrar upload → invalidar empreendimentos;
- salvar mesa → invalidar histórico;
- aprovar/rejeitar → invalidar histórico.

---

## Segurança obrigatória nas RPCs

Cada RPC operacional deve seguir o padrão:

1. `auth.uid()` obrigatório.
2. Identificação da empresa real pelo usuário autenticado.
3. Validação de empreendimento/lista/lead pertencente ao tenant.
4. Validação de papel quando a ação for restrita a gestor/admin/root.
5. `SECURITY DEFINER` apenas quando necessário.
6. `set search_path = public` em funções `SECURITY DEFINER`.
7. `revoke all from public`.
8. `grant execute to authenticated` quando aplicável.
9. Auditoria em ações críticas: importação, aprovação, rejeição, alteração financeira.
10. Nenhuma função deve confiar exclusivamente em parâmetros enviados pelo frontend.

---

## Papel do RLS

RLS continua obrigatório como defesa adicional.

Modelo correto:

```txt
RPC = regra de negócio e contrato de API
RLS = barreira adicional caso alguém tente acesso fora do caminho previsto
```

Não depender apenas de RLS.
Não depender apenas da RPC.
Usar defesa em profundidade.

---

## Estratégia de refatoração

A refatoração será feita em passos pequenos e versionados.

### Passo 1 — Documentação e decisão

- Criar este documento.
- Criar plano de refatoração.
- Criar checklist de segurança.

### Passo 2 — Client único

- Criar `src/services/fechaiRpcClient.js`.
- Remover duplicidade de client dentro da Mesa Cliente.
- Manter compatibilidade com `sb.rpc` atual.

### Passo 3 — Corrigir rota Mesa Cliente

- `App.jsx` deve passar `sb`, `token`, `corretor`, `empresaId`, `corretorId`, `isGestor`.
- `src/pages/MesaCliente.jsx` não deve ler localStorage nem criar client.

### Passo 4 — Hooks TanStack definitivos

- Adaptar `useMesaData.js` para usar client único.
- Remover imports de clients locais.
- Padronizar query keys.

### Passo 5 — Remover clients duplicados

- Remover ou esvaziar `src/components/MesaCliente/supabaseClient.js`.
- Refatorar `src/lib/supabaseClient.js` para não ter hardcoded secret/config.

### Passo 6 — Validar build e preview

- Build Vercel sem tela branca.
- Abertura da Mesa Cliente pela Home.
- Listagem de empreendimentos.
- Listagem de unidades do parser.
- Simulação usando unidade real.
- Histórico e aprovação funcionando.

---

## Critérios de aceite

1. `npm run build` passa.
2. Nenhum arquivo da Mesa Cliente cria Supabase client próprio.
3. Nenhuma feature lê token do localStorage diretamente.
4. Mesa Cliente abre pela Home sem tela branca.
5. Todas as chamadas operacionais da Mesa Cliente passam por RPC.
6. Corretor de uma empresa não acessa empreendimento/unidade de outra empresa.
7. Gestor só aprova/rejeita dentro de sua empresa, exceto root.
8. TanStack Query está ativo apenas como cache/estado, não como camada de autorização.
9. NativeFirst/parser antigo permanece como rollback enquanto a nova Mesa não estiver homologada.

---

## Decisão final

O FECH.AI será:

```txt
RPC-centric no backend.
TanStack-powered no frontend.
Client único na camada de dados.
Tenant-safe no banco.
Leve na UI.
Seguro por contrato, não por esperança.
```
