# MesaCliente — Plano Técnico de Implementação da Engenharia Financeira

## 1. Escopo

Este documento descreve todas as ações necessárias para implementar a Engenharia Financeira do MesaCliente.

A implementação deve permitir:

- política financeira por empresa, empreendimento e vigência;
- VPL comercial informado pela incorporadora;
- faixas de prêmio do corretor;
- taxa de antecipação anual;
- taxa de postergação anual;
- agenda de parcelas datadas;
- simulação de VPL, antecipação e postergação;
- confirmação controlada pelo corretor/coordenador;
- tela limpa para cliente;
- segurança multiempresa e multitenant.

## 2. Premissas obrigatórias

1. Não levar o desconto simples global para `main`.
2. Não aplicar desconto diretamente sobre o valor total como regra principal.
3. Não usar regra comercial hardcoded.
4. O front não é autoridade financeira.
5. Toda regra financeira deve vir do banco.
6. Toda escrita sensível deve ocorrer via RPC segura.
7. Toda operação deve validar tenant, empresa, empreendimento e perfil.
8. Toda confirmação financeira deve ser auditada.
9. Cliente não deve receber VPL, prêmio, comissão ou regra interna.
10. Periodicidade simbólica não deve entrar como parcela negociável.

## 3. Branch de trabalho

Usar a branch:

```txt
feature/mesa-cliente-engenharia-financeira
```

Não reutilizar como base final a branch experimental de desconto simples:

```txt
feature/mesa-cliente-desconto-governanca
```

## 4. Ordem geral de execução

A implementação deve seguir esta ordem:

```txt
1. Banco de dados
2. Constraints e índices
3. RLS e permissões
4. RPCs de política financeira
5. RPCs de agenda financeira
6. RPCs de simulação e confirmação
7. API/front data layer
8. Tela admin/coordenador de política
9. Tela interna da mesa
10. Tela limpa do cliente
11. Testes de segurança
12. Testes financeiros
13. Hardening e checklist final
```

Não iniciar pela tela antes de fechar banco e RPCs.

## 5. Fase 1 — Migração de banco

### 5.1. Criar tabela `mesa_cliente_politicas_financeiras`

Objetivo: armazenar política financeira vigente por empresa, empreendimento e período.

Campos mínimos:

```sql
id uuid primary key default gen_random_uuid(),
empresa_id uuid not null,
empreendimento_id uuid not null,
mes_referencia date null,
vigencia_inicio date not null,
vigencia_fim date not null,
vpl_max_pct numeric not null,
taxa_antecipacao_ano_pct numeric not null,
taxa_postergacao_ano_pct numeric not null,
metodo_calculo text not null,
base_tempo text not null,
permite_vpl_mensais boolean not null default false,
permite_vpl_anuais boolean not null default true,
permite_vpl_chaves boolean not null default true,
permite_vpl_financiamento boolean not null default true,
permite_antecipacao_mensais boolean not null default true,
permite_antecipacao_anuais boolean not null default true,
permite_antecipacao_chaves boolean not null default true,
permite_antecipacao_financiamento boolean not null default true,
permite_postergacao_mensais boolean not null default true,
permite_postergacao_anuais boolean not null default true,
permite_postergacao_chaves boolean not null default true,
permite_postergacao_financiamento boolean not null default true,
ativo boolean not null default true,
criado_por uuid null,
atualizado_por uuid null,
created_at timestamptz not null default now(),
updated_at timestamptz not null default now()
```

Adicionar foreign keys conforme tabelas existentes:

- `empresa_id` → `empresas.id`;
- `empreendimento_id` → `empreendimentos.id`;
- `criado_por` e `atualizado_por` conforme padrão atual do projeto.

### 5.2. Criar constraints da política

Adicionar checks:

```sql
vpl_max_pct >= 0 and vpl_max_pct <= 100
taxa_antecipacao_ano_pct >= 0 and taxa_antecipacao_ano_pct <= 100
taxa_postergacao_ano_pct >= 0 and taxa_postergacao_ano_pct <= 100
vigencia_fim >= vigencia_inicio
metodo_calculo in ('composto')
base_tempo in ('dias_365')
```

Observação: `composto` e `dias_365` são valores de política, não constantes escondidas no front.

### 5.3. Criar tabela `mesa_cliente_politica_premio_faixas`

Objetivo: armazenar faixas de prêmio do corretor por política.

Campos mínimos:

```sql
id uuid primary key default gen_random_uuid(),
politica_id uuid not null,
empresa_id uuid not null,
empreendimento_id uuid not null,
vpl_de_pct numeric not null,
vpl_ate_pct numeric not null,
premio_corretor_pct numeric not null,
status text not null,
descricao text null,
ordem integer not null default 0,
ativo boolean not null default true,
created_at timestamptz not null default now(),
updated_at timestamptz not null default now()
```

Adicionar foreign keys:

- `politica_id` → `mesa_cliente_politicas_financeiras.id`;
- `empresa_id` → `empresas.id`;
- `empreendimento_id` → `empreendimentos.id`.

Adicionar checks:

```sql
vpl_de_pct >= 0
vpl_ate_pct >= vpl_de_pct
premio_corretor_pct >= 0
status in ('premio_cheio', 'premio_parcial', 'sem_premio', 'fora_politica')
```

Não calcular prêmio por fórmula linear. A faixa deve informar diretamente o prêmio restante.

### 5.4. Criar tabela `mesa_cliente_fluxo_parcelas`

Objetivo: armazenar o fluxo expandido em parcelas datadas por simulação.

Campos mínimos:

```sql
id uuid primary key default gen_random_uuid(),
empresa_id uuid not null,
simulacao_id uuid not null,
empreendimento_id uuid not null,
unidade_id uuid null,
grupo text not null,
descricao text not null,
valor_original numeric not null,
valor_atual numeric not null,
data_original date not null,
data_atual date not null,
origem_data text not null,
regra_data text null,
ordem integer not null,
quantidade_origem integer null,
parcela_numero integer null,
eh_periodicidade_simbolica boolean not null default false,
pode_receber_vpl boolean not null default false,
pode_receber_antecipacao boolean not null default false,
pode_receber_postergacao boolean not null default false,
metadata jsonb not null default '{}'::jsonb,
created_at timestamptz not null default now(),
updated_at timestamptz not null default now()
```

Checks sugeridos:

```sql
grupo in ('ato', 'complemento', 'mensal', 'anual', 'chaves', 'financiamento', 'periodicidade', 'outro')
origem_data in ('tabela_oficial', 'tabela_comercial_data', 'tabela_comercial_mes', 'cabecalho_30_dias', 'cabecalho_60_dias', 'calculada_por_ato', 'estimada', 'manual')
valor_original >= 0
valor_atual >= 0
```

### 5.5. Criar tabela `mesa_cliente_fluxo_operacoes`

Objetivo: armazenar operações simuladas ou confirmadas de VPL, antecipação e postergação.

Campos mínimos:

```sql
id uuid primary key default gen_random_uuid(),
empresa_id uuid not null,
empreendimento_id uuid not null,
simulacao_id uuid not null,
politica_id uuid null,
tipo_operacao text not null,
grupo_origem text null,
grupo_destino text null,
parcela_origem_id uuid null,
parcela_destino_id uuid null,
valor_movido numeric not null default 0,
valor_base numeric not null default 0,
data_origem date null,
data_destino date null,
dias_calculo integer null,
taxa_ano_pct numeric null,
vpl_aplicado_pct numeric null,
desconto_calculado numeric not null default 0,
acrescimo_calculado numeric not null default 0,
economia_liquida numeric not null default 0,
status text not null,
confirmado boolean not null default false,
criado_por uuid null,
confirmado_por uuid null,
metadata jsonb not null default '{}'::jsonb,
created_at timestamptz not null default now(),
updated_at timestamptz not null default now()
```

Checks sugeridos:

```sql
tipo_operacao in ('vpl', 'antecipacao', 'postergacao')
status in ('simulado', 'recomendado', 'confirmado', 'bloqueado', 'cancelado')
valor_movido >= 0
valor_base >= 0
desconto_calculado >= 0
acrescimo_calculado >= 0
economia_liquida >= 0
```

## 6. Fase 2 — Índices

Criar índices para consultas por tenant e vigência:

```sql
create index on public.mesa_cliente_politicas_financeiras (empresa_id, empreendimento_id, ativo);
create index on public.mesa_cliente_politicas_financeiras (empresa_id, empreendimento_id, vigencia_inicio, vigencia_fim);
create index on public.mesa_cliente_politica_premio_faixas (politica_id, ativo, ordem);
create index on public.mesa_cliente_fluxo_parcelas (empresa_id, simulacao_id, ordem);
create index on public.mesa_cliente_fluxo_parcelas (empresa_id, empreendimento_id, grupo);
create index on public.mesa_cliente_fluxo_operacoes (empresa_id, simulacao_id, status);
create index on public.mesa_cliente_fluxo_operacoes (empresa_id, empreendimento_id, tipo_operacao);
```

## 7. Fase 3 — RLS e permissões

### 7.1. Ativar RLS

```sql
alter table public.mesa_cliente_politicas_financeiras enable row level security;
alter table public.mesa_cliente_politica_premio_faixas enable row level security;
alter table public.mesa_cliente_fluxo_parcelas enable row level security;
alter table public.mesa_cliente_fluxo_operacoes enable row level security;
```

### 7.2. Política de leitura por tenant

Permitir leitura apenas quando:

```txt
public.is_root() = true
OU usuário autenticado possui corretor ativo na mesma empresa_id da linha.
```

Não permitir leitura cross-tenant.

### 7.3. Escrita direta

Não criar policies abertas de insert/update/delete para usuários comuns.

Toda escrita deve ocorrer via RPC `security definer`.

## 8. Fase 4 — RPCs de política financeira

### 8.1. Criar `salvar_mesa_cliente_politica_financeira`

Responsabilidade:

- criar ou atualizar política financeira;
- validar tenant;
- validar perfil;
- validar empreendimento;
- validar taxas;
- impedir sobreposição de políticas ativas conflitantes;
- registrar auditoria.

Parâmetros mínimos:

```txt
p_politica_id uuid null
p_empresa_id uuid
p_empreendimento_id uuid
p_mes_referencia date
p_vigencia_inicio date
p_vigencia_fim date
p_vpl_max_pct numeric
p_taxa_antecipacao_ano_pct numeric
p_taxa_postergacao_ano_pct numeric
p_metodo_calculo text
p_base_tempo text
p_flags jsonb
p_ativo boolean
```

Permissão:

```txt
root
admin_local
gestor
coordenador, se configurado como permitido
```

Corretor comum não pode configurar política.

### 8.2. Criar `salvar_mesa_cliente_premio_faixas`

Responsabilidade:

- substituir ou atualizar faixas da política;
- validar que todas as faixas pertencem ao mesmo tenant;
- validar que não há sobreposição;
- validar que `vpl_ate_pct` não ultrapassa `vpl_max_pct` da política;
- registrar auditoria.

Parâmetros mínimos:

```txt
p_politica_id uuid
p_faixas jsonb
```

Formato esperado:

```json
[
  {
    "vpl_de_pct": 0,
    "vpl_ate_pct": 3,
    "premio_corretor_pct": 2,
    "status": "premio_cheio",
    "descricao": "Prêmio completo"
  }
]
```

### 8.3. Criar `get_mesa_cliente_politica_financeira_vigente`

Responsabilidade:

- buscar política ativa vigente;
- retornar faixas de prêmio;
- retornar flags de grupos permitidos;
- retornar alertas de vigência.

Parâmetros:

```txt
p_empreendimento_id uuid
p_data_referencia date null
```

Alertas possíveis:

```txt
sem_politica_configurada
politica_vencida
politica_proxima_do_vencimento
validar_vpl_e_premio
validar_taxa_antecipacao
```

## 9. Fase 5 — RPCs de agenda financeira

### 9.1. Criar `gerar_mesa_cliente_agenda_parcelas`

Responsabilidade:

- expandir cards agregados em parcelas datadas;
- preservar data oficial quando existir;
- usar data do ato como base;
- calcular mês/ano com dia do ato;
- usar último dia válido quando mês não tiver o dia;
- identificar chaves/parcela única;
- identificar periodicidade simbólica;
- marcar elegibilidade de cada parcela.

Parâmetros:

```txt
p_simulacao_id uuid
p_data_ato date
p_fluxo_json jsonb
p_payload_tabela jsonb
```

Regras:

```txt
data oficial > data comercial completa > mês/ano + dia do ato > cabeçalho > estimada > manual
```

## 10. Fase 6 — RPCs de simulação financeira

### 10.1. Criar `simular_mesa_cliente_engenharia_financeira`

Responsabilidade:

- simular VPL;
- simular antecipação;
- simular postergação;
- ordenar alternativas;
- evidenciar melhor opção;
- não confirmar automaticamente.

Parâmetros mínimos:

```txt
p_simulacao_id uuid
p_tipo_operacao text
p_valor_movido numeric
p_data_ato date
p_vpl_aplicado_pct numeric null
p_grupos_destino jsonb null
p_politica_id uuid null
```

Para antecipação:

- origem normalmente é data do ato;
- destino são parcelas futuras elegíveis;
- calcular desconto composto por destino;
- ordenar maior economia.

Para postergação:

- origem são parcelas reduzidas;
- destino é parcela futura;
- calcular acréscimo composto.

Para VPL:

- validar contra `vpl_max_pct`;
- identificar faixa de prêmio;
- simular aplicação nas camadas permitidas.

### 10.2. Criar `confirmar_mesa_cliente_operacao_financeira`

Responsabilidade:

- confirmar operação simulada;
- revalidar política vigente;
- revalidar tenant e perfil;
- aplicar alterações no fluxo de parcelas;
- marcar operação como confirmada;
- registrar auditoria.

Parâmetros:

```txt
p_simulacao_id uuid
p_operacao_id uuid
```

### 10.3. Criar `validar_mesa_cliente_operacao_financeira`

Responsabilidade:

- validar integridade antes de gerar tela cliente/proposta;
- garantir que política, taxas e parcelas permanecem válidas;
- impedir operação adulterada.

## 11. Fase 7 — Funções internas de cálculo

### 11.1. Valor presente composto

Criar função interna:

```txt
calcular_valor_presente_composto(valor_futuro numeric, taxa_ano_pct numeric, dias integer)
```

Fórmula:

```txt
taxa = taxa_ano_pct / 100
valor_presente = valor_futuro / power(1 + taxa, dias / 365.0)
desconto = valor_futuro - valor_presente
```

### 11.2. Valor futuro composto

Criar função interna:

```txt
calcular_valor_futuro_composto(valor_presente numeric, taxa_ano_pct numeric, dias integer)
```

Fórmula:

```txt
taxa = taxa_ano_pct / 100
valor_futuro = valor_presente * power(1 + taxa, dias / 365.0)
acrescimo = valor_futuro - valor_presente
```

### 11.3. Regras de cálculo

- usar `numeric`;
- não usar `float`;
- arredondar dinheiro em 2 casas;
- dias <= 0 não gera benefício financeiro;
- taxa zero retorna sem desconto/acréscimo;
- valor movido não pode exceder parcela destino, salvo regra explícita.

## 12. Fase 8 — API/front data layer

Criar funções API:

```txt
getMesaClientePoliticaFinanceiraVigente
salvarMesaClientePoliticaFinanceira
salvarMesaClientePremioFaixas
gerarMesaClienteAgendaParcelas
simularMesaClienteEngenhariaFinanceira
confirmarMesaClienteOperacaoFinanceira
validarMesaClienteOperacaoFinanceira
```

Criar hooks React Query:

```txt
useMesaClientePoliticaFinanceiraVigente
useSalvarMesaClientePoliticaFinanceira
useSalvarMesaClientePremioFaixas
useGerarMesaClienteAgendaParcelas
useSimularMesaClienteEngenhariaFinanceira
useConfirmarMesaClienteOperacaoFinanceira
```

Cache keys:

```txt
['mesa', 'politica-financeira', empreendimentoId]
['mesa', 'agenda-financeira', simulacaoId]
['mesa', 'engenharia-financeira', simulacaoId]
```

## 13. Fase 9 — Tela admin/coordenador

Criar tela:

```txt
MesaCliente > Configurações Financeiras
```

Campos:

- empreendimento;
- mês referência;
- vigência início;
- vigência fim;
- VPL máximo permitido;
- taxa de antecipação ao ano;
- taxa de postergação ao ano;
- método de cálculo;
- base de tempo;
- permissões por grupo;
- faixas de prêmio;
- ativo/inativo.

Editor de faixas:

- VPL de;
- VPL até;
- prêmio corretor %;
- status;
- descrição.

Validações visuais no front são auxiliares. RPC continua sendo autoridade final.

## 14. Fase 10 — Tela interna da mesa

Adicionar bloco:

```txt
Engenharia Financeira
```

Campos:

- data do ato;
- valor adicional para antecipação;
- valor a postergar;
- VPL aplicado;
- política vigente;
- alertas de vigência;
- impacto no prêmio.

Após cravar data do ato:

- recalcular agenda financeira;
- mostrar datas nos cards;
- manter layout e dimensão dos cards salvo aprovação explícita.

## 15. Fase 11 — Tela limpa do cliente

A tela do cliente deve mostrar:

- valor de tabela;
- condição especial intermediária;
- condição final;
- economia total;
- fluxo final;
- storytelling da vantagem financeira.

Não mostrar:

- VPL;
- prêmio;
- comissão;
- taxa de antecipação;
- taxa de postergação;
- cálculo técnico;
- faixas internas.

Exemplo de storytelling:

```txt
Com esta reorganização do fluxo, parte do pagamento foi melhor distribuída para reduzir compromissos futuros e gerar uma condição mais eficiente para fechamento.
```

## 16. Fase 12 — Testes obrigatórios

### 16.1. Segurança

Testar:

- usuário sem login não executa RPC;
- `anon` não executa RPC sensível;
- usuário de outra empresa não lê política;
- corretor comum não configura política;
- admin configura apenas política da própria empresa;
- payload adulterado é bloqueado;
- empreendimento de outro tenant é bloqueado;
- service_role não aparece no front;
- RLS está ativa.

### 16.2. Política financeira

Testar:

- criar política vigente;
- impedir data inválida;
- impedir taxa negativa;
- impedir VPL acima de 100;
- impedir faixas sobrepostas;
- impedir faixa acima do VPL máximo;
- buscar política vigente correta;
- alertar política vencida;
- alertar virada de mês.

### 16.3. Agenda financeira

Testar:

- data oficial prevalece;
- mês/ano usa dia do ato;
- 31 em fevereiro vira último dia válido;
- chaves 30 dias antes do financiamento;
- chaves 60 dias antes do financiamento;
- periodicidade simbólica não entra como destino;
- mensais expandem corretamente;
- anuais expandem corretamente;
- financiamento recebe data correta.

### 16.4. Cálculos

Testar:

- antecipação composta;
- postergação composta;
- taxa zero;
- dias zero;
- dias negativos;
- valor zero;
- valor maior que parcela destino;
- arredondamento monetário.

### 16.5. Experiência comercial

Testar:

- cliente aumenta entrada;
- sistema evidencia melhor destino;
- corretor/coordenador confirma;
- economia aparece;
- cliente vê tela limpa;
- corretor vê prêmio;
- cliente não vê prêmio.

## 17. Checklist final antes de merge

Antes de mergear qualquer PR para `main`, validar:

```txt
[ ] Não existe desconto simples global como regra final.
[ ] Nenhuma regra comercial está hardcoded.
[ ] Política financeira vem do banco.
[ ] RLS está ativa nas novas tabelas.
[ ] Escrita direta está bloqueada.
[ ] RPCs têm security definer e search_path fixo.
[ ] anon não executa RPC sensível.
[ ] auth.uid() é validado.
[ ] Tenant é validado.
[ ] Perfil é validado.
[ ] Auditoria registra alterações de política.
[ ] Auditoria registra operações confirmadas.
[ ] Cards mostram datas após data do ato.
[ ] Periodicidade simbólica não entra no cálculo.
[ ] Antecipação usa cálculo composto.
[ ] Postergação usa cálculo composto.
[ ] Cliente não vê VPL/prêmio/comissão.
[ ] Corretor/coordenador vê impacto administrativo.
[ ] Testes cross-tenant foram executados.
[ ] Testes de cálculo foram executados.
[ ] Preview foi validado antes de promover para main.
```

## 18. Resultado esperado

Ao final, o MesaCliente deve operar assim:

```txt
Banco soberano
Front consultivo
Coordenador configura
Corretor apresenta
Cliente entende
Auditoria registra
Tenant isola
RPC valida
```

Essa arquitetura evita regra escondida, desconto incorreto, vazamento de comissão, mistura de tenants e cálculo financeiro frágil.
