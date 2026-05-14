# Mesa Cliente — Guia de Integração no FECH.AI

## Estrutura criada

```
src/components/MesaCliente/
  index.jsx              ← componente de entrada (3 abas)
  TabEmpreendimentos.jsx ← lista com bolinhas + upload
  TabFluxo.jsx           ← wrapper do FluxoBuilder
  TabHistorico.jsx       ← histórico com filtros e aprovação
  FluxoBuilder.jsx       ← construtor visual de tiles
  hooks/
    useMesaCalc.js       ← cálculos puros (sem Supabase)
    useMesaData.js       ← queries TanStack + mutations Supabase
```

## Passo 1 — Copiar arquivos

Copiar a pasta `MesaCliente/` para dentro de `src/components/` do projeto.

## Passo 2 — Verificar path do supabaseClient

Em `hooks/useMesaData.js`, linha 8:
```js
import { supabase } from '../../lib/supabaseClient';
```
Ajustar o path conforme onde está o cliente Supabase no projeto.
Geralmente em `src/lib/supabaseClient.js` ou `src/supabaseClient.js`.

## Passo 3 — Adicionar a rota/aba no App.jsx

Encontrar onde as abas principais do FECH.AI são definidas (provavelmente
um array de tabs ou um switch/router) e adicionar a Mesa Cliente:

```jsx
// Importar
import MesaCliente from './components/MesaCliente';

// Adicionar na lista de abas (onde ficam Leads, Dashboard, etc.)
{ id: 'mesa', label: 'Mesa Cliente', icon: '📋' }

// Renderizar no conteúdo
{activeTab === 'mesa' && (
  <MesaCliente
    empresaId={user.empresa_id}
    corretorId={user.id}
    isGestor={user.role === 'gestor' || user.role === 'admin'}
  />
)}
```

## Passo 4 — Verificar dependências

O projeto já usa TanStack Query. Confirmar que está instalado:
```bash
npm list @tanstack/react-query
```
Se não estiver: `npm install @tanstack/react-query`

## Passo 5 — Verificar QueryClient no App

O TanStack Query precisa de um QueryClient no root. Se já existe
(usado em outras partes do projeto), não precisa fazer nada.
Se não existe, adicionar em `main.jsx` ou `App.jsx`:

```jsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 60_000, refetchOnWindowFocus: false }
  }
});

// Envolver o app:
<QueryClientProvider client={queryClient}>
  <App />
</QueryClientProvider>
```

## Passo 6 — Classes Tailwind customizadas

O FluxoBuilder usa classes Tailwind com valores arbitrários como
`bg-[#CECBF6]` e `grid-cols-[3fr_7fr]`. O Tailwind 3 do projeto
já suporta isso nativamente. Não precisa configurar nada.

## RPCs criadas no Supabase (migration: mesa_cliente_rpcs_v1)

| RPC | Descrição |
|-----|-----------|
| `get_empreendimentos_mesa(empresa_id)` | Lista com status tabela/espelho |
| `get_empresa_mesa_config(empresa_id)` | Config (meta %, ato mínimo, etc.) |
| `get_historico_mesas(...)` | Histórico filtrado por corretor/status/busca |
| `registrar_upload_arquivo_mesa(...)` | Registra upload com auditoria |
| `criar_mesa_simulacao(...)` | Cria simulação + fluxo de pagamentos |
| `aprovar_rejeitar_mesa(...)` | Guard is_gestor() obrigatório |

## Próximos passos (Etapa 2 do plano)

1. **Storage Supabase**: criar bucket `mesa-arquivos` e implementar
   o upload real do PDF antes de chamar `registrar_upload_arquivo_mesa`.
   Hoje o `storage_path` vai como null (registro de intenção).

2. **Parser conectado ao banco**: quando o parser da Mesa processa
   um PDF, deve chamar `registrar_upload_arquivo_mesa` com o path
   real e atualizar `status_processamento` para 'processado'.

3. **Valor da unidade**: `empreendimento.valor_tabela` ainda não
   existe no retorno da RPC. Quando o parser gravar dados em
   `unidades_estoque`, a RPC pode ser atualizada para retornar
   o valor médio ou específico da unidade selecionada.

4. **Seleção de unidade**: antes de abrir o FluxoBuilder, o corretor
   deveria escolher a unidade específica (AP1204, LJ0001 etc.) via
   `get_unidades_disponiveis`. Hoje abre direto no empreendimento.

## Auditoria — o que fica registrado

Toda ação grava em `audit_logs`:
- Upload de tabela ou espelho (quem, quando, tipo)
- Criação de simulação (corretor, cliente, valor, parcelas)
- Aprovação ou rejeição (gestor, justificativa, novo status)

A tabela `audit_logs` já existe no banco com 65 registros.
Nada novo foi criado — apenas novas linhas são inseridas.

## Permissões (RLS)

As RPCs usam `SECURITY DEFINER` com `auth.uid()` para identificar
o usuário logado. A função `is_gestor()` já existe no banco e
é usada como guard na RPC `aprovar_rejeitar_mesa`.

Nenhuma política RLS nova foi criada — as RPCs são o único ponto
de entrada e já fazem o controle por `empresa_id`.
