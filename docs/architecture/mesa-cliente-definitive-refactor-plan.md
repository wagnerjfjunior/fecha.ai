# Mesa Cliente — Plano de Refatoração Definitiva

## Objetivo

Transformar a Mesa Cliente em módulo definitivo do FECH.AI, seguindo a arquitetura oficial:

```txt
React UI
→ TanStack Query hooks
→ FECH.AI RPC client único
→ RPCs Supabase tenant-safe
→ RLS/grants
```

Este plano substitui o modo provisório que mistura `supabaseClient` duplicado, client local em página, leitura de sessão por `localStorage` e hooks desalinhados.

---

## Problemas reais identificados

### P0 — Risco de tela branca em `src/pages/MesaCliente.jsx`

O arquivo usa:

```jsx
empresaId={session?.user?.empresa_id}
```

Porém `session` não existe no escopo do componente. Isso pode quebrar a renderização da Mesa Cliente.

Correção definitiva:

- `App.jsx` deve passar `empresaId` explicitamente.
- `MesaCliente.jsx` deve ser wrapper puro, sem tentar descobrir sessão sozinho.

---

### P0 — Client local dentro da página

`src/pages/MesaCliente.jsx` cria `createRpcClient` local.

Problema:

- cria fonte paralela de comunicação;
- duplica lógica de headers;
- ignora client `sb` já existente no App;
- dificulta refresh de token;
- aumenta risco de bug entre módulos.

Correção definitiva:

- remover `createRpcClient` da página;
- usar `sb` recebido do App ou client único centralizado.

---

### P0 — Clients Supabase duplicados com configuração hardcoded

Arquivos identificados:

```txt
src/lib/supabaseClient.js
src/components/MesaCliente/supabaseClient.js
```

Problema:

- duplicidade;
- URL e anon key hardcoded;
- risco de divergência;
- feature Mesa Cliente isolada do padrão do FECH.AI.

Correção definitiva:

- remover client local de `src/components/MesaCliente`;
- refatorar `src/lib/supabaseClient.js` ou substituí-lo por `src/services/fechaiRpcClient.js`;
- usar variáveis `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`.

---

### P1 — Hooks Mesa Cliente usam Supabase client diretamente

`src/components/MesaCliente/hooks/useMesaData.js` usa:

```js
import { supabase } from '../supabaseClient';
```

Problema:

- prende a feature a client próprio;
- dificulta passagem do token real do App;
- cria risco de sessão desconectada do login principal.

Correção definitiva:

- criar camada `mesaClienteApi.js` com chamadas RPC;
- hooks TanStack usam API layer;
- API layer usa client único e token/contexto do App.

---

### P1 — `App.jsx` ainda passa pouco contexto para Mesa Cliente

Hoje:

```jsx
<MesaCliente corretor={corretor} onVoltar={() => setTela('home')} />
```

Correção definitiva:

```jsx
<MesaCliente
  sb={sb}
  token={session.access_token}
  corretor={corretor}
  empresaId={corretor?.empresa_id}
  corretorId={corretor?.id}
  isGestor={canAccessAdmin}
  isRoot={isRoot}
  onVoltar={() => setTela('home')}
/>
```

---

### P1 — Query keys e invalidações precisam padronização

O módulo já usa TanStack Query, mas precisa padronização definitiva:

```js
mesaKeys.root
mesaKeys.empreendimentos(empresaId)
mesaKeys.config(empresaId)
mesaKeys.unidades(empreendimentoId)
mesaKeys.historico(empresaId, corretorId, filtros)
```

---

## Plano de implementação em commits

### Commit 1 — Documentação arquitetural

Arquivos:

- `docs/architecture/rpc-tanstack-definitive.md`
- `docs/architecture/mesa-cliente-definitive-refactor-plan.md`

Status: concluído na branch `architecture/rpc-tanstack-definitive`.

---

### Commit 2 — Criar client único FECH.AI

Arquivo novo:

```txt
src/services/fechaiRpcClient.js
```

Contrato esperado:

```js
export function createFechaiRpcClient({ url, anonKey })
export function normalizeRpcError(error, fallback)
```

Interface mínima:

```js
client.rpc(functionName, args, token)
client.query(table, params, token) // temporário, para compatibilidade com App
client.insert(table, data, token)  // temporário, para compatibilidade com App
client.patch(table, query, data, token) // temporário
```

Observação:

- O foco final é RPC.
- Métodos `query/insert/patch` existem apenas para compatibilidade gradual com o App legado.

---

### Commit 3 — Refatorar rota Mesa Cliente

Arquivo:

```txt
src/pages/MesaCliente.jsx
```

Mudanças:

- remover leitura de `localStorage`;
- remover `createRpcClient` local;
- receber `sb`, `token`, `corretor`, `empresaId`, `corretorId`, `isGestor`, `isRoot` por props;
- renderizar `../components/MesaCliente`.

---

### Commit 4 — Refatorar chamada no App

Arquivo:

```txt
src/App.jsx
```

Mudança pequena:

```jsx
if (tela === 'mesa-cliente') return (
  <MesaCliente
    sb={sb}
    token={session.access_token}
    corretor={corretor}
    empresaId={corretor?.empresa_id}
    corretorId={corretor?.id}
    isGestor={canAccessAdmin}
    isRoot={isRoot}
    onVoltar={() => setTela('home')}
  />
);
```

Regra:

- não reescrever o App inteiro;
- trocar somente o bloco da rota Mesa Cliente.

---

### Commit 5 — Refatorar hooks Mesa Cliente

Arquivo atual:

```txt
src/components/MesaCliente/hooks/useMesaData.js
```

Opção A, rápida:

- manter arquivo no local atual;
- alterar hooks para receber/use client/contexto oficial;
- remover import de `../supabaseClient`.

Opção B, mais limpa:

- mover para `src/features/mesaCliente/hooks/useMesaData.js`;
- criar `src/features/mesaCliente/api/mesaClienteApi.js`;
- atualizar imports dos componentes.

Recomendação para menor risco agora:

- usar Opção A nesta sprint;
- mover para `features` depois que a tela estiver estável.

---

### Commit 6 — Remover client duplicado da feature

Arquivo:

```txt
src/components/MesaCliente/supabaseClient.js
```

Ação:

- remover arquivo se não houver import restante;
- se houver risco de build, transformar temporariamente em adapter que reexporta o client oficial com aviso de deprecated.

---

### Commit 7 — Sanear `src/lib/supabaseClient.js`

Ação:

- remover URL/chave hardcoded;
- usar env vars;
- documentar que client direto não deve ser usado para tabelas sensíveis;
- preferir `fechaiRpcClient` em novos módulos.

---

### Commit 8 — Validar banco/RPCs

Checklist mínimo:

- `get_unidades_mesa`
- `get_empreendimentos_mesa`
- `get_empresa_mesa_config`
- `get_historico_mesas`
- `registrar_upload_arquivo_mesa`
- `criar_mesa_simulacao`
- `aprovar_rejeitar_mesa`
- `importar_mesa_cliente_parser_resultado`

Cada uma deve validar:

- `auth.uid()`;
- empresa real;
- papel do usuário;
- tenant do empreendimento;
- grants adequados.

---

## Critérios de teste manual

### Login corretor

- Acessa Home.
- Clica Mesa Cliente.
- Vê apenas empreendimentos da própria empresa.
- Abre empreendimento.
- Vê unidades do parser.
- Cria simulação.
- Vê apenas o próprio histórico quando aplicável.

### Login gestor/admin local

- Acessa Mesa Cliente.
- Vê empreendimentos da empresa.
- Importa resultado do parser quando autorizado.
- Aprova/rejeita propostas da empresa.
- Não vê tenant de outra empresa.

### Login root

- Acesso global conforme regras existentes.
- Não deve quebrar visão administrativa.

---

## Rollback

Rollback de frontend:

```jsx
export { default } from './MesaClienteNativeFirst';
```

Rollback de client:

- manter `sb` interno do App até client único estar validado.

Rollback de banco:

- não apagar RPCs em produção sem migration reversa;
- se houver erro, revogar execute da função problemática antes de remover dados.

---

## Ordem recomendada agora

1. Corrigir `MesaCliente.jsx` para wrapper puro.
2. Corrigir chamada do `App.jsx` passando `sb/token`.
3. Refatorar hooks para TanStack + `sb.rpc` recebido por contexto/prop, sem Supabase client local.
4. Remover client duplicado da feature.
5. Validar preview Vercel.

Essa ordem resolve primeiro o risco de tela branca e a divergência arquitetural mais grave, sem mexer no parser nem no banco operacional além do necessário.
