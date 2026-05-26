# FECH.AI — MesaCliente
# Fase 8A — Preflight de Integração Front/BFF com Operações Financeiras

## 1. Identificação

**Fase:** `8A — Preflight de Integração Front/BFF`  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Base declarada:** `main`  
**Base commit:** `040f3de29314025d5254cddce45263f5b5952876`  
**Contrato:** `docs/mesa-cliente/fase-8-contrato-integracao-front-bff-operacoes-financeiras.md`  
**Status:** `APROVADO PARA IMPLEMENTAÇÃO INCREMENTAL 8B`

---

## 2. Objetivo do preflight

Validar a estrutura real do frontend antes de ativar, na interface, os recursos de operações financeiras já consolidados pelas Fases 5D, 6 e 7.

A Fase 8A é somente análise e documentação de integração. Não altera motor financeiro, parser, Worker, Make, n8n ou RPCs consolidadas.

---

## 3. Regra-mãe preservada

```text
Frontend apresenta, solicita e renderiza.
Service/BFF orquestra, sanitiza e normaliza.
Supabase/RPC valida, decide, calcula, aplica e audita.
```

O frontend não pode ser autoridade sobre empresa, tenant, perfil, status financeiro, valor calculado, política financeira, VPL, prêmio, comissão, visibilidade cliente-safe ou permissão de aplicação.

---

## 4. Estrutura real localizada

### 4.1 API/data-layer atual

Arquivo existente:

```text
src/features/mesaCliente/api/mesaClienteApi.js
```

Responsabilidade atual:

- centraliza `callMesaRpc`;
- valida presença de cliente RPC e sessão/token;
- normaliza erro básico;
- executa RPCs já usadas pelo MesaCliente;
- converte retornos esperados como array quando necessário.

Leitura técnica:

```text
Existe uma camada de API reaproveitável.
Não é recomendável espalhar chamadas financeiras diretamente nos componentes React.
A integração financeira deve usar service próprio, consumindo callMesaRpc.
```

### 4.2 Hooks atuais

Arquivo existente:

```text
src/components/MesaCliente/hooks/useMesaData.js
```

Responsabilidade atual:

- React Query para empreendimentos, unidades, histórico, importação, simulação e aprovação/rejeição;
- invalidação de cache via `MESA_KEYS`;
- compatibilidade de loading/error.

Leitura técnica:

```text
O padrão correto para a Fase 8 é criar hooks específicos para operações financeiras, sem misturar regra financeira no componente.
```

### 4.3 Tela de montagem de fluxo

Arquivo existente:

```text
src/components/MesaCliente/FluxoBuilder.jsx
```

Responsabilidade atual:

- montar visualmente fluxo de pagamento;
- ajustar tiles de entrada, complementos, mensais, anuais e chaves;
- calcular resumo visual local de proposta;
- salvar a mesa via `onSalvar`.

Leitura técnica:

```text
FluxoBuilder não deve aplicar operação financeira.
Aplicação financeira é ação administrativa posterior e deve ficar em painel próprio ligado à operação persistida.
```

### 4.4 Histórico de propostas

Arquivo existente:

```text
src/components/MesaCliente/TabHistorico.jsx
```

Responsabilidade atual:

- listar simulações/propostas;
- permitir aprovação/rejeição por gestor;
- exibir status da proposta.

Leitura técnica:

```text
Este é o ponto inicial mais seguro para acoplar visualização administrativa de operações financeiras por simulação/proposta.
```

---

## 5. RPCs disponíveis para integração

A Fase 8 deve consumir RPCs já existentes:

```text
public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)
public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
public.mesa_cliente_resumir_operacao_financeira_admin(uuid, jsonb)
public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid, jsonb)
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid, jsonb)
```

Nenhuma dessas RPCs deve ser chamada diretamente por componentes React.

---

## 6. Observação crítica de compatibilidade

A Fase 7 adicionou o status canônico:

```text
aplicada
```

A constraint de banco já aceita:

```text
simulada
confirmada
aplicada
cancelada
bloqueada
```

Para a Fase 8, a UI deve tratar esses cinco estados.

Caso alguma RPC antiga de listagem ainda possua filtro restritivo sem `aplicada`, a integração inicial deve evitar filtro por status `aplicada` até haver fase técnica específica para ajuste de contrato da RPC. A listagem sem filtro continua sendo o caminho mais seguro para não alterar motor financeiro nesta etapa.

---

## 7. Ponto de atenção de segurança encontrado

Arquivo observado:

```text
src/lib/supabaseClient.js
```

Achado:

```text
Existe chave pública anon embutida no código-fonte atual.
```

Leitura técnica:

```text
A anon key não é segredo equivalente a service_role, mas hardcode em código-fonte reduz governança entre ambientes e dificulta rotação/segregação.
```

Decisão para a Fase 8:

```text
Não bloquear a integração financeira por este achado, mas registrar como item obrigatório de hardening.
A correção recomendada é migrar para variáveis de ambiente Vite, sem impactar motor financeiro.
```

---

## 8. Service recomendado para 8B

Criar:

```text
src/services/mesaClienteOperacoesFinanceirasService.js
```

Responsabilidades:

- listar operações financeiras admin;
- obter detalhe admin;
- obter resumo admin;
- obter resumo cliente-safe;
- aplicar operação financeira admin;
- sanitizar payload de aplicação;
- bloquear campos soberanos antes da chamada RPC;
- mapear erros RPC para mensagens de UI;
- normalizar estados visuais.

---

## 9. Hooks recomendados para 8B

Atualizar:

```text
src/components/MesaCliente/hooks/useMesaData.js
```

Adicionar hooks:

```text
useOperacoesFinanceirasMesa
useResumoOperacaoFinanceiraAdmin
useResumoOperacaoClienteSafe
useAplicarOperacaoFinanceiraAdmin
```

Regras:

- queries habilitadas apenas com `sb`, `token` e IDs necessários;
- mutation de aplicação deve invalidar caches financeiros e histórico;
- botão de aplicação deve usar loading para impedir duplo clique;
- erros devem usar mapper do service.

---

## 10. Componente recomendado para 8C

Criar componente isolado:

```text
src/components/MesaCliente/OperacoesFinanceirasPanel.jsx
```

Responsabilidades:

- renderizar operações associadas à simulação/proposta;
- exibir status visual;
- abrir resumo administrativo;
- abrir prévia cliente-safe protegida;
- exibir botão `Aplicar operação` somente quando elegível;
- abrir modal de confirmação obrigatório;
- recarregar dados após aplicação.

---

## 11. Guardas obrigatórios de UI

O botão `Aplicar operação` só pode aparecer quando:

```text
status_operacao = confirmada
confirmado = true
visao administrativa
usuário autenticado
usuário com perfil administrativo/gestor conforme escopo de UI
operação não aplicada
operação não cancelada
operação não bloqueada
```

Mesmo com guarda de UI, a RPC segue sendo a autoridade final.

---

## 12. Campos proibidos no payload de aplicação

O service deve bloquear, antes da chamada RPC, qualquer campo soberano como:

```text
empresa_id
tenant_id
simulacao_id
agenda_id
empreendimento_id
politica_id
parcela_origem_id
parcela_destino_id
corretor_id
user_id
auth_uid
role
perfil
is_admin
is_gestor
is_admin_local
tipo_operacao
valor_base
valor_movido
taxa_ano_pct
vpl_aplicado_pct
desconto_calculado
acrescimo_calculado
economia_liquida
premio_corretor_pct
status_premio
status_operacao
confirmado
confirmado_por
confirmado_em
cancelado_por
cancelado_em
motivo_cancelamento
visivel_cliente
checksum_operacao
metadata
created_at
updated_at
cliente_safe
visao
```

---

## 13. Campos proibidos na tela cliente-safe

A tela cliente-safe não deve exibir:

```text
vpl_interno
vpl_aplicado_pct
premio_corretor_pct
status_premio
comissao
margem_empresa
score_politica
regra_aprovacao_interna
metadata bruta
auditoria interna
user_id
corretor_id administrativo
role/perfil
empresa_id/tenant_id técnico
```

Se algum desses campos aparecer no payload cliente-safe, a UI deve tratar como falha crítica e não renderizar a prévia para cliente.

---

## 14. Sequência incremental recomendada

### 8B — Service e hooks

Implementar somente camada de serviço/hook, sem alterar fluxo visual principal.

### 8C — Painel administrativo no histórico

Integrar painel em `TabHistorico.jsx`, preferencialmente dentro do card da proposta, com lazy-load por botão.

### 8D — Aplicação admin com modal

Ativar botão aplicar operação com confirmação, sanitizer, loading e refresh pós-aplicação.

### 8E — Cliente-safe preview e checagem de vazamento

Renderizar prévia cliente-safe com allowlist e bloqueio de campos proibidos.

### 8F — Smoke pós-merge/deploy

Registrar evidências de listagem, detalhe, resumo admin, cliente-safe e aplicação controlada quando houver fixture segura.

---

## 15. Resultado do preflight

```text
estrutura_front_mapeada = true
supabase_client_localizado = true
api_layer_localizada = true
hooks_localizados = true
componentes_mesa_localizados = true
ponto_integracao_recomendado = TabHistorico.jsx + painel isolado
diff_minimo_possivel = true
motor_financeiro_preservado = true
parser_preservado = true
worker_make_n8n_preservados = true
readiness_8b = true
```

---

## 16. Parecer

A Fase 8A está aprovada para implementação incremental.

Próximo passo técnico seguro:

```text
8B — criar service centralizado e hooks de operações financeiras.
```

Não há autorização técnica para mudar motor financeiro. Qualquer necessidade de ajuste em RPC, status, cálculo ou regra de aplicação deve parar a Fase 8 e abrir fase específica.
