# FECH.AI — MesaCliente
# Fase 8B — Adapter Front/BFF para Operações Financeiras

## 1. Identificação

**Fase:** `8B — Adapter Front/BFF`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Base declarada:** `main`  
**Base commit da fase:** `040f3de29314025d5254cddce45263f5b5952876`  
**Contrato:** `docs/mesa-cliente/fase-8-contrato-integracao-front-bff-operacoes-financeiras.md`  
**Preflight anterior:** `docs/mesa-cliente/fase-8a-preflight-integracao-front-bff-operacoes-financeiras.md`  
**Status:** `IMPLEMENTADO — AGUARDANDO TESTE 17B / BUILD / SMOKE FRONT`

---

## 2. Objetivo

Criar a camada de integração do frontend com as RPCs financeiras já entregues nas Fases 5D, 6 e 7, sem alterar o motor financeiro, parser, Worker, Make, n8n ou banco.

A Fase 8B não cria migration. A mudança é exclusivamente frontend/BFF-adapter.

---

## 3. Escopo implementado

### 3.1 Novo adapter de operações financeiras

Arquivo criado:

`src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js`

Responsabilidades:

1. Encapsular chamadas RPC financeiras do MesaCliente.
2. Normalizar filtros de listagem administrativa.
3. Sanear parâmetros enviados pelo frontend.
4. Bloquear chaves soberanas no adapter antes de chamar RPCs.
5. Expor função de aplicação administrativa com payload seguro.
6. Mapear erros técnicos de RPC para mensagens operacionais do frontend.
7. Expor regra auxiliar `canAplicarOperacaoFinanceira` para gating visual/UX.

---

## 4. RPCs integradas no adapter

### 4.1 Fase 5D — leitura administrativa

RPCs consumidas:

- `public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)`
- `public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)`

Uso pretendido:

- Listar operações financeiras por simulação/agenda.
- Obter detalhe administrativo da operação.
- Exibir histórico operacional de antecipação, postergação/VPL e status.

Observação técnica:

A RPC de listagem 5D aceita filtro de `status_operacao` para:

- `simulada`
- `confirmada`
- `cancelada`
- `bloqueada`

Como a Fase 7 adicionou `aplicada`, o adapter trata `aplicada` como status canônico, mas não envia esse filtro para a RPC 5D para evitar erro legado. Quando solicitado no frontend, o filtro `aplicada` é aplicado client-side sobre o retorno da listagem.

Esse ponto não altera o banco. É compatibilidade incremental do front.

---

### 4.2 Fase 6 — resumos read-only

RPCs consumidas:

- `public.mesa_cliente_resumir_operacao_financeira_admin(uuid, jsonb)`
- `public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid, jsonb)`

Uso pretendido:

- Exibir resumo administrativo completo para gestão/corretor autorizado.
- Exibir payload cliente-safe sem vazamento de campos sensíveis.
- Permitir que o front compare visão interna e visão segura quando necessário.

Garantia preservada:

A separação física entre RPC admin e RPC cliente-safe permanece intacta. O adapter não cria parâmetro `visao` para alternar exposição.

---

### 4.3 Fase 7 — aplicação administrativa

RPC consumida:

- `public.mesa_cliente_aplicar_operacao_financeira_admin(uuid, jsonb)`

Uso pretendido:

- Aplicar operação financeira previamente confirmada.
- Efetivar mutação controlada em agenda/parcela/operação via banco.
- Atualizar o frontend após aplicação.

Payload permitido pelo adapter:

- `motivo`
- `observacao`
- `metadata_front` saneada
- `correlation_id`
- `origem_front = mesa_cliente_fase_8`

Chaves soberanas continuam bloqueadas no frontend e no banco.

---

## 5. Arquivos alterados

### 5.1 Criado

`src/features/mesaCliente/api/mesaClienteOperacoesFinanceirasApi.js`

Funções exportadas:

- `sanitizeParametrosAplicacaoFinanceira`
- `normalizeFiltrosOperacoesFinanceiras`
- `mapMesaClienteOperacaoFinanceiraError`
- `canAplicarOperacaoFinanceira`
- `listarOperacoesFinanceirasAdmin`
- `obterOperacaoFinanceiraAdmin`
- `resumirOperacaoFinanceiraAdmin`
- `obterResumoOperacaoClienteSafe`
- `aplicarOperacaoFinanceiraAdmin`

### 5.2 Alterado

`src/components/MesaCliente/hooks/useMesaData.js`

Novas integrações:

- Import do adapter financeiro.
- Novas query keys em `MESA_KEYS`.
- Hooks de leitura financeira.
- Mutation de aplicação financeira.
- Invalidação de cache após aplicação.
- Mapeamento de erro financeiro em mutation.

Hooks criados:

- `useOperacoesFinanceirasAdmin`
- `useOperacaoFinanceiraAdmin`
- `useResumoOperacaoFinanceiraAdmin`
- `useResumoOperacaoClienteSafe`
- `useAplicarOperacaoFinanceiraAdmin`

---

## 6. Garantias de segurança preservadas

### 6.1 Sem autoridade soberana no frontend

O adapter bloqueia/removerá chaves como:

- `empresa_id`
- `tenant_id`
- `simulacao_id`
- `agenda_id`
- `empreendimento_id`
- `politica_id`
- `corretor_id`
- `user_id`
- `auth_uid`
- `role`
- `perfil`
- `is_admin`
- `is_gestor`
- `is_admin_local`
- `tipo_operacao`
- `valor_base`
- `valor_movido`
- `taxa_ano_pct`
- `vpl_aplicado_pct`
- `desconto_calculado`
- `acrescimo_calculado`
- `economia_liquida`
- `premio_corretor_pct`
- `status_premio`
- `status_operacao`
- `confirmado`
- `visivel_cliente`
- `checksum_operacao`
- `metadata`
- `created_at`
- `updated_at`
- `criado_por`

O banco continua sendo a autoridade final.

---

### 6.2 Sem alteração de engine

Não foram alterados:

- Parser.
- Worker.
- Make.
- n8n.
- RPCs existentes.
- Motor financeiro.
- Regras de cálculo.
- Schema do banco.

---

### 6.3 Aplicação financeira continua server-authoritative

O frontend apenas chama:

`mesa_cliente_aplicar_operacao_financeira_admin(p_operacao_id, p_parametros)`

A decisão de aplicar ou bloquear permanece no banco, validada por:

- `auth.uid()`.
- Corretor ativo.
- Perfil administrativo.
- Tenant/empresa.
- Status `confirmada`.
- Operação existente e consistente.

---

## 7. Commits da Fase 8B

### 7.1 Adapter financeiro

Commit:

`8e0dffbbd9e4a729e504972c2815732acfea2666`

Mensagem:

`feat(mesa-cliente): adicionar API front para operacoes financeiras`

### 7.2 Hooks React Query

Commit:

`e25120a2c1b7c82025de2aa563394f03d2387a25`

Mensagem:

`feat(mesa-cliente): expor hooks de operacoes financeiras`

---

## 8. Status técnico da branch após 8B

Estado antes da documentação 8B:

- Branch: `feature/mesa-cliente-fase-8-front-operacoes-financeiras`
- Comparação contra `main`: ahead.
- Sem divergência conhecida contra `main` no início da fase.
- Fase 8A já documentada.
- Fase 8B adiciona adapter + hooks.

---

## 9. Pendências obrigatórias antes de UI final

### 9.1 Teste 17B — contrato estático front/BFF

Validar:

1. Arquivo adapter existe.
2. Hooks existem.
3. RPC names estão corretos.
4. Não há uso de `anon_key`.
5. Não há Service Role no front.
6. Não há envio de autoridade soberana pelo front.
7. Mutation de aplicação invalida caches financeiros.
8. Filtro `aplicada` não quebra RPC 5D.

### 9.2 Build/Lint

Executar no repositório:

```bash
npm install
npm run build
```

Se existir script específico:

```bash
npm run lint
```

### 9.3 Smoke funcional de front

Validar em ambiente autenticado:

1. Abrir MesaCliente.
2. Selecionar simulação com operações financeiras.
3. Listar operações financeiras.
4. Abrir detalhe administrativo.
5. Abrir resumo administrativo.
6. Validar resumo cliente-safe.
7. Confirmar que operação `confirmada` habilita ação de aplicar.
8. Aplicar operação em ambiente controlado.
9. Confirmar que operação muda para `aplicada`.
10. Confirmar invalidação/atualização da tela.
11. Confirmar que cliente-safe não vaza dados internos.

---

## 10. Próxima fase recomendada

Próximo passo técnico:

`17B — validação estática do adapter + hooks`

Depois:

`8C — componente/UX para exibir e aplicar operações financeiras no frontend`

A ordem recomendada é testar o adapter antes de plugar a tela. Do contrário, viramos reféns do clássico bug gourmet: o botão bonito chamando RPC errada com payload perigoso.
