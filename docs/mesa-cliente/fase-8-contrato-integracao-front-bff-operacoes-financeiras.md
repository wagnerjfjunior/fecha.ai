# FECH.AI — MesaCliente
# Fase 8 — Contrato de Integração Front/BFF com Operações Financeiras

## 1. Status do documento

**Status:** contrato inicial aprovado para início da Fase 8.

Este documento abre formalmente a Fase 8 da Engenharia Financeira do MesaCliente, após a Fase 7 ter sido fechada, mergeada e validada pós-merge.

A Fase 8 não altera o motor financeiro. Ela define como o frontend/BFF deve consumir, apresentar e acionar as capacidades financeiras já consolidadas no banco/RPC.

## 2. Contexto herdado

A Fase 7 consolidou a aplicação administrativa de operação financeira confirmada por meio da RPC:

```sql
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

A Fase 7 também consolidou:

- status canônico `aplicada`;
- DML financeiro controlado via RPC;
- bloqueio de autoridade soberana vinda do frontend;
- validação de `auth.uid()`;
- validação de perfil administrativo;
- validação de tenant/empresa;
- proteção contra execução anônima;
- separação entre visão administrativa e visão cliente-safe.

Portanto, a Fase 8 deve respeitar integralmente esse desenho.

## 3. Objetivo da Fase 8

Criar o contrato seguro para integração entre tela, camada de serviço/BFF e RPCs financeiras do MesaCliente.

A Fase 8 deve permitir que usuários autorizados consigam, pela interface:

1. listar operações financeiras;
2. abrir detalhe de uma operação;
3. obter resumo administrativo;
4. obter resumo cliente-safe;
5. aplicar uma operação financeira confirmada;
6. receber mensagens de erro tratadas;
7. visualizar o estado pós-aplicação;
8. impedir vazamento de campos internos ao cliente.

## 4. Regra-mãe

```text
Frontend apresenta, solicita e renderiza.
BFF/service orquestra e normaliza.
Supabase/RPC valida, decide, calcula, aplica e audita.
```

O frontend nunca deve ser autoridade sobre:

- empresa;
- tenant;
- perfil;
- papel administrativo;
- status financeiro;
- valores calculados;
- política financeira;
- score interno;
- VPL;
- prêmio;
- comissão;
- visibilidade cliente-safe;
- permissão de aplicação.

## 5. Escopo da Fase 8

### 5.1 Dentro do escopo

- Criar contrato de integração Front/BFF.
- Definir service/data-layer para operações financeiras.
- Definir payloads permitidos e proibidos.
- Definir mapeamento de erros RPC -> UI.
- Definir estados visuais da operação.
- Definir critérios para exibir/esconder ações.
- Definir smoke E2E controlado.
- Definir checklist de segurança de integração.

### 5.2 Fora do escopo

- Alterar parser de PDF/CSV.
- Alterar Worker/Make/n8n.
- Alterar motor financeiro.
- Alterar RPCs financeiras já consolidadas sem fase específica.
- Mover regra crítica para React.
- Aceitar `empresa_id`, `tenant_id`, `role` ou campos soberanos do frontend.
- Expor VPL/prêmio/comissão/regra interna em tela cliente-safe.

## 6. RPCs disponíveis para integração

A Fase 8 deve consumir as RPCs já existentes e versionadas nas fases anteriores.

### 6.1 Listagem admin

```sql
public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)
```

Uso esperado:

- tela administrativa;
- listagem de operações por simulação/agenda/empreendimento;
- filtros controlados;
- paginação;
- ordenação.

### 6.2 Detalhe admin

```sql
public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
```

Uso esperado:

- abrir detalhe administrativo da operação;
- inspecionar status;
- verificar confirmação/cancelamento/aplicação;
- alimentar painel de decisão.

### 6.3 Resumo admin

```sql
public.mesa_cliente_resumir_operacao_financeira_admin(uuid, jsonb)
```

Uso esperado:

- renderizar resumo interno;
- exibir impactos financeiros administrativos;
- mostrar status e auditoria;
- não deve ser usado em tela pública/cliente.

### 6.4 Resumo cliente-safe

```sql
public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid, jsonb)
```

Uso esperado:

- renderizar proposta segura para cliente;
- esconder campos internos;
- respeitar release gate;
- não expor VPL interno, prêmio, comissão ou regra de aprovação.

### 6.5 Aplicação admin da operação

```sql
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

Uso esperado:

- aplicar operação financeira já confirmada;
- uso apenas administrativo;
- não deve ser chamada em tela cliente;
- não deve receber campos soberanos.

## 7. Camada recomendada no frontend

A integração deve ser feita por uma camada única de serviço, evitando chamadas diretas `supabase.rpc()` espalhadas em componentes React.

Nome recomendado:

```text
src/services/mesaClienteOperacoesFinanceirasService.js
```

Alternativas aceitáveis conforme arquitetura real:

```text
src/features/mesa-cliente/services/operacoesFinanceiras.js
src/modules/mesa-cliente/services/operacoesFinanceiras.service.js
src/lib/mesaCliente/operacoesFinanceiras.js
```

A escolha final deve respeitar a estrutura existente do repositório.

## 8. Contratos de funções do service

### 8.1 Listar operações

Assinatura sugerida:

```ts
listarOperacoesFinanceirasAdmin(input: {
  simulacaoId?: string;
  agendaId?: string;
  filtros?: {
    status_operacao?: string;
    tipo_operacao?: string;
    somente_confirmadas?: boolean;
    somente_aplicaveis?: boolean;
    page?: number;
    pageSize?: number;
  };
}): Promise<ListarOperacoesFinanceirasResult>
```

Observação: IDs de escopo devem ser tratados conforme o contrato real da RPC. O service não deve inventar escopo financeiro.

### 8.2 Obter detalhe administrativo

```ts
obterOperacaoFinanceiraAdmin(input: {
  operacaoId: string;
}): Promise<OperacaoFinanceiraAdminResult>
```

### 8.3 Obter resumo administrativo

```ts
resumirOperacaoFinanceiraAdmin(input: {
  operacaoId: string;
}): Promise<ResumoOperacaoAdminResult>
```

### 8.4 Obter resumo cliente-safe

```ts
obterResumoOperacaoClienteSafe(input: {
  operacaoId: string;
}): Promise<ResumoOperacaoClienteSafeResult>
```

### 8.5 Aplicar operação financeira

```ts
aplicarOperacaoFinanceiraAdmin(input: {
  operacaoId: string;
  parametros?: ParametrosAplicacaoPermitidos;
}): Promise<AplicacaoOperacaoFinanceiraResult>
```

## 9. Payload permitido para aplicação

O payload permitido para `p_parametros` deve ser mínimo, não soberano e voltado a rastreabilidade de interface.

Exemplo permitido:

```json
{
  "origem_interface": "mesa_cliente_admin",
  "acao_usuario": "confirmar_aplicacao_operacao",
  "motivo_interface": "aplicacao_confirmada_pelo_gestor",
  "correlation_id": "uuid-gerado-no-client-ou-bff"
}
```

Campos permitidos sugeridos:

```text
origem_interface
action_source
acao_usuario
motivo_interface
correlation_id
client_request_id
observacao_nao_soberana
```

Esses campos são informativos. Eles não podem alterar regra, escopo, status, cálculo ou permissão.

## 10. Payload proibido

O frontend/BFF não deve enviar campos soberanos para `p_parametros`.

Campos proibidos:

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

Se qualquer campo desse tipo for necessário para tomada de decisão, ele deve ser inferido/validado pelo banco/RPC a partir do usuário autenticado e dos dados persistidos.

## 11. Sanitização obrigatória no service

Antes de chamar a RPC de aplicação, o service deve executar uma sanitização defensiva.

Pseudocódigo:

```ts
const FORBIDDEN_KEYS = new Set([
  'empresa_id', 'tenant_id', 'simulacao_id', 'agenda_id', 'empreendimento_id',
  'politica_id', 'parcela_origem_id', 'parcela_destino_id', 'corretor_id',
  'user_id', 'auth_uid', 'role', 'perfil', 'is_admin', 'is_gestor',
  'is_admin_local', 'tipo_operacao', 'valor_base', 'valor_movido',
  'taxa_ano_pct', 'vpl_aplicado_pct', 'desconto_calculado',
  'acrescimo_calculado', 'economia_liquida', 'premio_corretor_pct',
  'status_premio', 'status_operacao', 'confirmado', 'confirmado_por',
  'confirmado_em', 'cancelado_por', 'cancelado_em', 'motivo_cancelamento',
  'visivel_cliente', 'checksum_operacao', 'metadata', 'created_at',
  'updated_at', 'cliente_safe', 'visao'
]);

function sanitizeParametrosAplicacao(params = {}) {
  for (const key of Object.keys(params)) {
    if (FORBIDDEN_KEYS.has(key)) {
      throw new Error(`Parametro proibido para aplicacao financeira: ${key}`);
    }
  }

  return {
    origem_interface: params.origem_interface ?? 'mesa_cliente_admin',
    acao_usuario: params.acao_usuario ?? 'confirmar_aplicacao_operacao',
    motivo_interface: params.motivo_interface ?? null,
    correlation_id: params.correlation_id ?? crypto.randomUUID?.()
  };
}
```

A sanitização no frontend/BFF é defesa em profundidade. A autoridade real continua sendo a RPC.

## 12. Estados da operação na UI

A UI deve tratar os estados abaixo:

```text
simulada
confirmada
aplicada
cancelada
bloqueada
```

### 12.1 Estado `simulada`

Comportamento:

- exibir resumo simulado;
- permitir análise administrativa;
- não permitir aplicação;
- permitir avanço para confirmação somente por fluxo próprio da Fase 5C.

### 12.2 Estado `confirmada`

Comportamento:

- exibir resumo administrativo;
- exibir resumo cliente-safe se liberado;
- permitir botão `Aplicar operação` somente para perfil permitido;
- exigir confirmação modal antes da chamada da RPC.

### 12.3 Estado `aplicada`

Comportamento:

- esconder botão de aplicação;
- exibir selo `Operação aplicada`;
- exibir auditoria administrativa;
- manter cliente-safe protegido;
- não permitir reaplicação.

### 12.4 Estado `cancelada`

Comportamento:

- esconder botão de aplicação;
- exibir motivo de cancelamento se disponível;
- impedir confirmação/aplicação.

### 12.5 Estado `bloqueada`

Comportamento:

- esconder botão de aplicação;
- exibir motivo técnico/comercial do bloqueio quando disponível;
- exigir ação administrativa fora da aplicação direta.

## 13. Regras para exibir botão Aplicar Operação

O botão `Aplicar Operação` só pode aparecer se todas as condições forem verdadeiras:

```text
status_operacao = confirmada
confirmado = true
visao = administrativa
usuario_autenticado = true
usuario_tem_perfil_admin = true
operacao_nao_aplicada = true
operacao_nao_cancelada = true
operacao_nao_bloqueada = true
```

Mesmo que o botão apareça por falha de UI, a RPC deve continuar bloqueando qualquer tentativa inválida.

## 14. Confirmação modal obrigatória

Antes da aplicação, a UI deve abrir uma confirmação explícita.

Texto recomendado:

```text
Você está prestes a aplicar esta operação financeira.
Essa ação altera o fluxo financeiro da proposta e não deve ser repetida.
Confirme somente se a operação já foi validada com o cliente e/ou gestor responsável.
```

Botões:

```text
Cancelar
Aplicar operação financeira
```

Após clicar em aplicar, o botão deve entrar em estado loading e impedir clique duplo.

## 15. Idempotência e clique duplo

A UI deve evitar duplo clique, mas não deve depender disso para segurança.

Regras:

- bloquear botão durante chamada;
- usar `correlation_id` quando possível;
- recarregar operação após retorno;
- se a RPC retornar `operacao_already_applied`, tratar como estado final conhecido, não como falha catastrófica.

## 16. Mapeamento de erros RPC -> UI

| Erro RPC | Mensagem de UI | Severidade |
|---|---|---|
| `auth_required` | Sessão expirada. Faça login novamente. | alta |
| `active_corretor_not_found` | Usuário sem cadastro ativo para executar esta ação. | alta |
| `profile_not_allowed` | Seu perfil não permite aplicar operação financeira. | alta |
| `cross_tenant_denied` | Operação fora do seu escopo de empresa. | crítica |
| `frontend_authority_forbidden:*` | Parâmetro inválido bloqueado por segurança. | crítica |
| `operacao_not_found` | Operação financeira não encontrada. | média |
| `operacao_already_applied` | Esta operação já foi aplicada. | informativa |
| `operacao_cancelada` | Esta operação foi cancelada e não pode ser aplicada. | média |
| `operacao_not_applicable_status` | A operação ainda não está confirmada para aplicação. | média |
| `operacao_without_agenda` | Operação sem agenda financeira vinculada. | alta |
| `operacao_without_simulacao` | Operação sem simulação vinculada. | alta |
| `parcela_origem_required` | Operação sem parcela de origem. | alta |
| `simulacao_not_found` | Simulação vinculada não encontrada. | alta |
| `agenda_not_found` | Agenda financeira vinculada não encontrada. | alta |
| `agenda_not_active` | Agenda financeira não está ativa. | média |
| `parcela_origem_not_found` | Parcela de origem não encontrada. | alta |
| `parcela_simbolica_not_applicable` | Parcela simbólica não pode receber esta operação. | média |
| `valor_movido_invalid` | Valor da operação inválido. | alta |
| `parcela_flag_denied` | Parcela não permite este tipo de operação. | média |
| `saldo_parcela_insuficiente` | Saldo insuficiente na parcela de origem. | média |
| `data_destino_required` | Data de destino obrigatória para postergação. | média |
| `data_destino_invalid` | Data de destino inválida. | média |
| `tipo_operacao_not_supported` | Tipo de operação ainda não suportado para aplicação. | alta |
| `valor_final_parcela_negativo` | A aplicação deixaria a parcela com valor negativo. | alta |

Mensagens técnicas completas devem ir para log interno, não para o cliente final.

## 17. Payload esperado de sucesso da aplicação

A RPC de aplicação retorna payload administrativo. A UI deve tratar como resposta interna.

Campos esperados:

```json
{
  "ok": true,
  "fase": "7_APLICACAO_OPERACAO_FINANCEIRA",
  "visao": "administrativa",
  "cliente_safe": false,
  "readonly": false,
  "dml_financeiro": true,
  "altera_operacao": true,
  "altera_agenda": true,
  "altera_parcelas": true,
  "recalcula_operacao": false,
  "operacao_id": "uuid",
  "agenda_id": "uuid",
  "simulacao_id": "uuid",
  "empresa_id": "uuid",
  "status_operacao_anterior": "confirmada",
  "status_operacao_final": "aplicada",
  "parcelas_afetadas": [],
  "resumo_aplicacao": {},
  "auditoria": {}
}
```

A UI administrativa pode usar esse retorno para feedback imediato, mas deve recarregar o detalhe da operação após a aplicação para garantir estado canônico.

## 18. Dados proibidos em tela cliente-safe

Tela cliente-safe não deve exibir:

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

Se algum desses campos aparecer em payload cliente-safe, deve ser tratado como falha crítica.

## 19. Fluxo E2E desejado

```text
1. Admin abre MesaCliente.
2. Front chama listagem administrativa de operações.
3. Admin seleciona operação confirmada.
4. Front chama detalhe administrativo.
5. Front chama resumo administrativo.
6. Front opcionalmente chama resumo cliente-safe para visualização segura.
7. UI exibe botão Aplicar Operação se permitido.
8. Admin confirma em modal.
9. Service sanitiza parâmetros.
10. Service chama RPC de aplicação.
11. RPC valida auth, perfil, tenant, status e escopo.
12. RPC aplica DML controlado.
13. RPC retorna payload administrativo.
14. Front recarrega detalhe/resumo.
15. UI mostra status aplicada.
16. Botão Aplicar desaparece.
17. Cliente-safe continua sem vazamento.
```

## 20. Smoke E2E da Fase 8

A Fase 8 deve ser encerrada somente após smoke controlado.

### 20.1 Smoke read-only

Validar:

- service consegue chamar listagem admin;
- service consegue chamar detalhe admin;
- service consegue chamar resumo admin;
- service consegue chamar cliente-safe sem vazar campos internos;
- UI renderiza estados corretamente.

### 20.2 Smoke com rollback ou fixture controlada

Quando houver ambiente seguro para teste mutacional:

- criar operação confirmada em fixture transacional ou ambiente controlado;
- aplicar via fluxo de service/UI;
- validar status `aplicada`;
- validar desaparecimento do botão;
- validar cliente-safe pós-aplicação;
- garantir ausência de fixture residual.

## 21. Critérios de aceite

A Fase 8 só pode ser considerada fechada se:

- houver service único para operações financeiras;
- nenhum componente React chamar RPC financeira crítica diretamente;
- o payload de aplicação for sanitizado;
- campos soberanos forem bloqueados antes da chamada;
- erros RPC forem mapeados para mensagens de UI;
- botão de aplicação respeitar status/perfil/visão;
- clique duplo for bloqueado na UI;
- retorno administrativo não for exibido em tela cliente;
- cliente-safe não vazar campos internos;
- smoke E2E for documentado;
- não houver alteração de motor financeiro, parser, Worker/Make/n8n ou RPCs consolidadas sem fase própria.

## 22. Checklist de segurança antes de codar

```text
[ ] Confirmar estrutura real de pastas do frontend.
[ ] Localizar client Supabase atual.
[ ] Verificar padrão atual de services/hooks.
[ ] Verificar padrão atual de autenticação/perfil.
[ ] Criar service centralizado.
[ ] Criar sanitizer de parâmetros.
[ ] Criar mapper de erros.
[ ] Criar guards de UI.
[ ] Criar loading/disable no botão Aplicar.
[ ] Garantir refresh pós-aplicação.
[ ] Testar cliente-safe sem vazamento.
```

## 23. Riscos principais

| Risco | Impacto | Mitigação |
|---|---|---|
| Chamada RPC espalhada em componentes | perda de governança | service único |
| Front enviando campo soberano | falha crítica de segurança | sanitizer + bloqueio RPC |
| Exposição de payload admin ao cliente | vazamento comercial | separação de componentes e payloads |
| Botão aplicar disponível em estado errado | erro operacional | guards de UI + RPC soberana |
| Duplo clique | tentativa duplicada | loading + idempotência no banco |
| Erro técnico bruto na tela | UX ruim e vazamento técnico | mapper de erros |
| Alterar motor durante integração | regressão financeira | fase própria e aprovação explícita |

## 24. Decisão arquitetural

A Fase 8 adota o padrão:

```text
UI -> service/BFF -> Supabase RPC -> banco como autoridade
```

Não é permitido o padrão:

```text
UI -> cálculo financeiro local -> update direto em tabela
```

Nem:

```text
UI -> envia empresa/role/status/valor -> RPC apenas obedece
```

## 25. Próximo entregável

Após aprovação deste contrato, o próximo entregável deve ser:

```text
Fase 8A — Preflight de integração Front/BFF
```

Objetivo do preflight:

- mapear estrutura real do frontend;
- localizar Supabase client;
- localizar componentes/telas MesaCliente;
- localizar hooks/services existentes;
- confirmar ausência de chamadas diretas conflitantes;
- propor diff mínimo para integração.

## 26. Parecer

Este contrato autoriza o início da Fase 8, mas não autoriza alteração do motor financeiro.

A implementação deve ser incremental, auditável e reversível.

Regra final:

```text
Se a integração exigir mudar regra financeira, parar e abrir nova fase técnica antes de codar.
```
