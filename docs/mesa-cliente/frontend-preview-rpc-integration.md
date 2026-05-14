# Mesa Cliente — Integração Frontend RPC Preview

## Objetivo

Integrar a nova tela da Mesa Cliente ao motor real do FECH.AI para exibir todas as unidades extraídas pelo parser e permitir a montagem da mesa de pagamento usando dados persistidos no Supabase.

Nesta etapa, o espelho de vendas ainda não filtra unidades vendidas. Portanto, a tela exibe todas as unidades importadas pelo parser para o empreendimento selecionado.

## Escopo desta preview

- Usar a branch `feature/mesa-unidades-parser-preview`.
- Manter a implementação NativeFirst atual como rollback funcional.
- Adaptar os componentes novos de `src/components/MesaCliente` para usar o cliente RPC real do FECH.AI.
- Não criar `supabaseClient` paralelo.
- Não expor anon key, service role key, senha ou segredo no frontend.
- Não instalar `@tanstack/react-query` nesta etapa, porque a dependência ainda não existe no projeto e poderia quebrar build/lockfile.
- Usar `useEffect/useState` com `sb.rpc` e token autenticado já existentes no App principal.

## Arquivos alterados

### `src/components/MesaCliente/hooks/useMesaData.js`

Adaptado para:

- remover dependência de `@tanstack/react-query`;
- remover import de `../../lib/supabaseClient`;
- receber `sb` e `token` por props;
- chamar RPCs via `sb.rpc(nome, args, token)`;
- centralizar tratamento de erro;
- criar hooks para:
  - `useEmpreendimentosMesa`;
  - `useEmpresaMesaConfig`;
  - `useUnidadesMesa`;
  - `useHistoricoMesas`;
  - `useRegistrarUpload`;
  - `useImportarUnidadesMesaParser`;
  - `useCriarMesaSimulacao`;
  - `useAprovarRejeitarMesa`.

### `src/components/MesaCliente/index.jsx`

Adaptado para:

- receber `sb`, `token`, `corretor`, `empresaId`, `corretorId` e `isGestor`;
- resolver contexto de empresa/corretor sem criar autenticação paralela;
- bloquear a tela quando sessão, empresa ou corretor não estiverem disponíveis;
- repassar `sb/token` para as abas internas.

### `src/components/MesaCliente/TabEmpreendimentos.jsx`

Adaptado para:

- buscar empreendimentos via `get_empreendimentos_mesa`;
- registrar intenção de upload via `registrar_upload_arquivo_mesa`;
- manter aviso claro de que storage/parser automático entram em etapa posterior;
- permitir abrir a mesa do empreendimento selecionado.

### `src/components/MesaCliente/TabFluxo.jsx`

Adaptado para:

- carregar configuração da empresa via `get_empresa_mesa_config`;
- carregar unidades via `get_unidades_mesa`;
- exibir todas as unidades importadas pelo parser;
- informar que a disponibilidade ainda não é validada pelo espelho de vendas;
- exigir seleção de unidade antes de abrir o simulador;
- salvar simulação via `criar_mesa_simulacao`.

### `src/components/MesaCliente/TabHistorico.jsx`

Adaptado para:

- carregar histórico via `get_historico_mesas`;
- permitir que gestor aprove/rejeite via `aprovar_rejeitar_mesa`;
- manter corretor limitado ao próprio histórico quando `corretorId` for informado.

## Segurança

A segurança real fica no banco e nas RPCs. O frontend apenas consome as funções com token autenticado.

Regras esperadas:

- Corretor só acessa empresa vinculada ao próprio usuário.
- Gestor/admin local só acessa empresas sob sua permissão.
- Root/admin global depende de função administrativa segura já existente.
- RPCs devem validar `auth.uid()`.
- RPCs devem validar vínculo com `empresa_id`.
- `SECURITY DEFINER` deve usar `set search_path = public`.
- Nenhuma RPC deve confiar apenas em parâmetros enviados pelo frontend.
- Nenhuma chave secreta deve ir para o cliente.

## TanStack Query

Foi deliberadamente adiado.

Motivo: o projeto ainda não tinha `@tanstack/react-query` no `package.json`. Instalar agora adicionaria uma dependência nova e exigiria ajuste em lockfile e provider global. Para esta preview, o mais seguro é usar React nativo.

TanStack Query pode entrar depois para:

- cache por query key;
- invalidação automática pós-mutation;
- retry controlado;
- melhor deduplicação de requests;
- melhor UX em carregamentos recorrentes.

## Próximo passo obrigatório

A tela nova ainda precisa ser conectada ao roteamento real do `App.jsx`, passando:

```jsx
<MesaCliente
  sb={sb}
  token={session?.access_token || token}
  corretor={corretor}
  empresaId={corretor?.empresa_id}
  corretorId={corretor?.id}
  isGestor={isGestor || isAdmin || isRoot}
  onVoltar={() => setTela('home')}
/>
```

Como `App.jsx` é grande e crítico, esta ligação deve ser feita em bloco separado, com diff pequeno e revisão cuidadosa.

## Rollback

Rollback imediato:

- manter `src/pages/MesaCliente.jsx` com o NativeFirst atual;
- não alterar banco além das migrations versionadas;
- reverter os commits da branch `feature/mesa-unidades-parser-preview` se o preview falhar.

## Status

Documentação criada antes da ligação final no `App.jsx`.

A próxima etapa é alterar somente o roteamento do App para renderizar a Mesa Cliente nova dentro da preview, sem apagar a versão anterior.
