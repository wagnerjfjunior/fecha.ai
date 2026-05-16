# Mesa Cliente — Refatoração por Camadas

## Objetivo

Organizar a Mesa Cliente no modelo definitivo do FECH.AI, separando responsabilidades e evitando que UI, parser, cache e RPC fiquem misturados no mesmo arquivo.

## Camadas oficiais

```txt
src/components/MesaCliente/*
→ UI e interação visual

src/components/MesaCliente/hooks/useMesaData.js
→ TanStack Query, cache, loading, mutations e invalidação

src/features/mesaCliente/api/mesaClienteApi.js
→ contrato de chamadas RPC da feature

src/features/mesaCliente/parser/parserPayloadAdapter.js
→ normalização e validação do payload do parser

Supabase RPCs
→ isolamento tenant, validação de permissão e persistência
```

## O que mudou

### 1. `useMesaData.js`

Antes o hook misturava:

- TanStack Query;
- montagem dos argumentos RPC;
- chamada direta ao `sb.rpc`;
- tratamento de erro.

Agora ele fica limitado a:

- declarar query keys;
- executar queries/mutations;
- invalidar cache;
- compatibilizar `isLoading`, `reload` e `error` para a UI atual.

### 2. `mesaClienteApi.js`

Nova camada criada para concentrar as chamadas RPC da Mesa Cliente.

Responsabilidades:

- validar presença de `sb` e `token`;
- chamar RPCs tenant-safe;
- montar argumentos padronizados;
- normalizar erros de execução.

Essa camada não conhece React e não usa TanStack Query.

### 3. `parserPayloadAdapter.js`

Nova camada criada para a ponte parser → banco.

Responsabilidades:

- aceitar JSON canônico `mesa_parser_v1` ou formatos compatíveis;
- normalizar unidade, valor, metragem, status e confiança;
- validar unidades antes da importação;
- separar unidades válidas e inválidas.

Essa camada não salva nada no banco. Ela apenas prepara o payload.

### 4. `TabEmpreendimentos.jsx`

O botão de JSON foi rebaixado para modo técnico e fica disponível apenas para gestor/admin.

O fluxo visual principal volta a ser:

```txt
Importar tabela/PDF
```

O JSON deixa de parecer caminho operacional do corretor.

## Estado atual

A aplicação ainda não executa o parser automático ao selecionar PDF/imagem. Nesta fase, o botão operacional registra a intenção de upload/auditoria. A próxima camada será conectar:

```txt
arquivo selecionado
→ parser Native First
→ parserPayloadAdapter
→ importar_mesa_cliente_parser_resultado
→ get_unidades_mesa
```

## Regra de segurança

A UI pode informar contexto, mas nunca é fonte soberana de empresa/tenant. As RPCs devem continuar validando usuário autenticado, empresa e permissão no banco.

## Critério de aceite desta etapa

- UI não deve abrir modal JSON para corretor comum.
- Hooks não devem importar `supabaseClient` paralelo.
- Feature deve usar `sb` e `token` recebidos do App.
- Adapter deve validar unidades antes da importação técnica.
- `main` não deve ser alterada nesta etapa.
