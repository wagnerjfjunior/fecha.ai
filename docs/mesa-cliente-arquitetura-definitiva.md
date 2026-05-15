# Mesa Cliente — Arquitetura definitiva RPC + TanStack Query

## Decisão

A Mesa Cliente deve seguir o mesmo padrão dos módulos maduros do FECH.AI:

```txt
React UI
→ TanStack Query
→ client único do App
→ RPCs Supabase
→ RLS/grants/validação por tenant no banco
```

O TanStack Query não substitui a segurança do banco. Ele fica responsável por cache, estado de carregamento, refetch e invalidação de dados no frontend.

## O que foi ajustado nesta etapa

- `src/components/MesaCliente/hooks/useMesaData.js` foi refatorado para receber `sb` e `token` por parâmetro.
- Foi removido o import de cliente Supabase paralelo dentro do hook.
- Todas as chamadas da Mesa Cliente passam por RPC.
- A camada de hooks mantém compatibilidade com os componentes atuais usando `isLoading`, `reload` e mensagens de erro normalizadas.
- O parser não foi recriado. A tela apenas consome o resultado do parser já existente.

## Pendências técnicas antes de promover para produção

1. Ajustar `src/pages/MesaCliente.jsx` para não criar cliente local e receber `sb`/`token` do `App.jsx`.
2. Ajustar `src/App.jsx` para renderizar:

```jsx
<MesaCliente
  sb={sb}
  token={session.access_token}
  corretor={corretor}
  onVoltar={() => setTela('home')}
/>
```

3. Validar se as RPCs abaixo existem e estão com grants apenas para `authenticated`:

- `get_empreendimentos_mesa`
- `get_empresa_mesa_config`
- `get_historico_mesas`
- `get_unidades_mesa`
- `registrar_upload_arquivo_mesa`
- `criar_mesa_simulacao`
- `aprovar_rejeitar_mesa`
- `importar_mesa_cliente_parser_resultado`

## Regra de segurança

O frontend nunca deve decidir sozinho qual empresa pode acessar qual dado. O frontend envia contexto mínimo; a RPC deve validar usuário autenticado, empresa, perfil e escopo.

## Estado do espelho de vendas

O espelho de vendas ainda não está pronto. Portanto, nesta fase a UI deve exibir todas as unidades extraídas pelo parser, com aviso claro de que a disponibilidade ainda não foi validada pelo espelho.
