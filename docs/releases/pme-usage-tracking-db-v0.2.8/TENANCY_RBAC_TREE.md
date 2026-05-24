# TENANCY_RBAC_TREE — PME Usage Tracking DB v0.2.8

## 1. Objetivo

Definir a árvore hierárquica de tenancy, empresa, equipes e papéis administrativos para orientar a implementação segura do tracking do Discador Flow AI / PME.

Este documento complementa o contrato da v0.2.7 e deve ser usado como base para desenhar as tabelas, RPCs, RLS e regras de visibilidade da v0.2.8.

---

## 2. Árvore hierárquica recomendada

```txt
FECH.AI Platform
└── Root
    ├── Admin Global / Platform Admin
    │   └── Tenant
    │       ├── Admin Local / Tenant Admin
    │       │   └── Empresa / Conta Comercial
    │       │       ├── Admin da Empresa
    │       │       │   └── Todos os times/equipes da empresa
    │       │       ├── Time / Equipe / Carteira
    │       │       │   ├── Gestor
    │       │       │   ├── Coordenador
    │       │       │   └── Corretores
    │       │       └── Usuários individuais, quando aplicável
    │       └── Outras empresas do mesmo tenant, se o plano permitir
    └── Auditoria / Suporte técnico controlado
```

---

## 3. Definições conceituais

### 3.1 Root

O **Root** é o nível máximo da plataforma FECH.AI.

Uso previsto:

- provisionamento estrutural;
- suporte técnico avançado;
- auditoria controlada;
- manutenção de plataforma;
- gestão de planos globais;
- criação/remoção de tenants, quando aplicável.

Regras:

- Não deve ser usado na operação diária.
- Não deve aparecer como papel comum para empresas/clientes.
- Deve ter acesso extremamente restrito.
- Ações críticas devem ser auditadas.
- Quando possível, usar lógica de break-glass, justificativa e logs.

### 3.2 Admin Global / Platform Admin

O **Admin Global** é um administrador da plataforma, abaixo do Root.

Uso previsto:

- gestão operacional da plataforma;
- acompanhamento de tenants;
- suporte administrativo;
- configuração global de templates oficiais da plataforma;
- ativação/desativação de módulos por plano.

Diferença para Root:

- Root é soberano e técnico-estrutural.
- Admin Global opera a plataforma, mas não deve ter poderes irrestritos de banco/segurança.

### 3.3 Tenant

O **Tenant** é o isolamento SaaS principal.

O tenant representa o ambiente lógico do cliente dentro do FECH.AI.

Exemplos:

```txt
Tenant: Imobiliária XPTO
Tenant: Grupo Comercial ABC
Tenant: Corretor Individual Wagner
Tenant: Incorporadora/Operação Comercial Y
```

Regras:

- O tenant isola dados entre clientes.
- Um tenant pode ter uma ou mais empresas, dependendo do plano.
- Mesmo que no MVP seja 1 tenant = 1 empresa, o modelo deve permitir expansão.

### 3.4 Admin Local / Tenant Admin

O **Admin Local** é o administrador do tenant.

Uso previsto:

- administrar o ambiente do cliente;
- configurar empresas vinculadas ao tenant;
- criar administradores de empresa;
- configurar módulos contratados;
- definir políticas internas do tenant;
- visualizar dados agregados do tenant, conforme perfil/plano.

Importante:

- O Admin Local não é Root.
- O Admin Local não deve acessar outro tenant.
- O Admin Local pode atuar sobre todas as empresas do seu tenant, se o plano e as permissões permitirem.

### 3.5 Empresa / Conta Comercial

A **Empresa** é a entidade comercial/legal ou operacional dentro do tenant.

Pode representar:

- CNPJ;
- CPF profissional;
- filial;
- unidade comercial;
- operação específica;
- marca ou conta comercial.

Exemplos:

```txt
Empresa: Imobiliária XPTO LTDA / CNPJ
Empresa: Wagner Fernandes / CPF
Empresa: Tegra Vendas / CNPJ
Empresa: AW Realty / CNPJ
```

Regras:

- Uma empresa pertence a um tenant.
- Uma empresa pode ter uma ou várias equipes.
- Uma empresa pequena pode ter apenas 1 gestor e 1 corretor.
- Uma empresa maior pode ter vários gestores, coordenadores e equipes.

### 3.6 Admin da Empresa

O **Admin da Empresa** administra uma empresa específica dentro do tenant.

Uso previsto:

- criar times/equipes;
- vincular gestores/coordenadores;
- gerenciar corretores da empresa;
- criar itens PME visíveis para toda a empresa;
- visualizar métricas da empresa, conforme permissão;
- administrar listas, scripts, templates e configurações operacionais da empresa.

Diferença para Admin Local:

- Admin Local administra o tenant.
- Admin da Empresa administra uma empresa específica dentro do tenant.

### 3.7 Time / Equipe / Carteira

O **Time**, **Equipe** ou **Carteira** é a segmentação operacional.

Este é o nível correto para separar atuação de gestores e seus corretores.

Exemplos:

```txt
Empresa: Imobiliária XPTO
├── Equipe Zona Norte
│   ├── Gestor A
│   └── Corretores 1, 2, 3
└── Equipe Alto Padrão
    ├── Gestor B
    ├── Coordenador C
    └── Corretores 4, 5, 6
```

Regra central:

> O conteúdo deve pertencer preferencialmente à equipe/time, e não diretamente ao gestor.

Motivo:

- gestor pode sair;
- equipe pode ganhar outro coordenador;
- corretores podem mudar de time;
- métricas históricas continuam coerentes;
- RLS fica mais estável.

### 3.8 Gestor

O **Gestor** é um usuário com permissão operacional sobre uma ou mais equipes.

Uso previsto:

- acompanhar corretores da equipe;
- criar itens PME para sua equipe;
- visualizar eventos e métricas da equipe;
- gerenciar scripts, argumentos e mensagens do time;
- acompanhar qualidade dos leads, dentro do escopo permitido.

Regra:

- Gestor não deve acessar dados de outra equipe se não estiver explicitamente vinculado a ela.

### 3.9 Coordenador

O **Coordenador** é um papel intermediário, normalmente abaixo do gestor ou paralelo a ele, conforme a operação.

Uso previsto:

- auxiliar o gestor;
- acompanhar corretores;
- validar scripts;
- acompanhar produtividade;
- criar ou sugerir itens PME, se permitido.

Regra:

- Permissões do coordenador devem ser configuráveis e sempre limitadas por equipe/empresa/tenant.

### 3.10 Corretor

O **Corretor** é o usuário operacional.

Uso previsto:

- trabalhar leads;
- usar scripts/mensagens PME;
- melhorar mensagens com IA, se o módulo estiver habilitado;
- executar ligação, WhatsApp ou e-mail;
- registrar feedback;
- consumir itens globais, da empresa, da equipe e, se existir, itens privados.

Regra:

- Corretor não deve gerenciar dados de outro corretor, salvo permissão específica futura.

---

## 4. Escopos de visibilidade para itens PME

Scripts, argumentos, mensagens, templates e conteúdos do PME devem ter escopo de visibilidade.

Escopos recomendados:

```txt
platform_global
tenant_global
empresa_global
team_only
user_private
```

### 4.1 platform_global

Criado por Root ou Admin Global.

Visível para múltiplos tenants, conforme produto/plano.

Exemplo:

- scripts padrão FECH.AI;
- técnicas gerais de cold call;
- templates genéricos de objeção.

### 4.2 tenant_global

Criado por Admin Local.

Visível para todas as empresas e equipes do tenant, conforme permissão.

Exemplo:

- padrão comercial do cliente;
- regras de abordagem do grupo;
- mensagens oficiais do tenant.

### 4.3 empresa_global

Criado por Admin da Empresa ou Admin Local.

Visível para todas as equipes da empresa.

Exemplo:

- script oficial de uma incorporadora;
- mensagem padrão de atendimento da empresa;
- argumentos comerciais de um produto específico.

### 4.4 team_only

Criado por gestor/coordenador/admin da empresa.

Visível somente para uma equipe/carteira específica.

Exemplo:

- roteiro de abordagem da equipe Alto Padrão;
- script específico para carteira de leads frios;
- mensagens internas do time do gestor.

### 4.5 user_private

Criado por um usuário específico.

Visível somente para ele.

Exemplo:

- anotação pessoal;
- variação de mensagem própria;
- script pessoal ainda não aprovado pelo gestor.

---

## 5. Matriz resumida de permissões

| Papel | Escopo principal | Pode criar conteúdo para | Pode ver métricas de | Observação |
|---|---|---|---|---|
| Root | Plataforma | Plataforma inteira | Plataforma inteira | Uso restrito e auditado |
| Admin Global | Plataforma | `platform_global` | Global/agregado | Sem acesso irrestrito técnico por padrão |
| Admin Local | Tenant | `tenant_global`, empresas do tenant | Tenant/empresas do tenant | Não acessa outro tenant |
| Admin da Empresa | Empresa | `empresa_global`, equipes da empresa | Empresa/equipes | Não acessa outra empresa sem vínculo |
| Gestor | Equipe(s) | `team_only` das equipes vinculadas | Equipe(s) | Não depende da pessoa para ownership histórico |
| Coordenador | Equipe(s) | `team_only`, se permitido | Equipe(s), se permitido | Permissão configurável |
| Corretor | Próprio usuário/equipe | `user_private`, se permitido | Próprios eventos | Consome conteúdo autorizado |

---

## 6. Aplicação ao PME Usage Tracking

Eventos de uso do PME devem carregar o escopo resolvido no backend.

Campos conceituais:

```txt
tenant_id
empresa_id
team_id
user_id
lead_id
event_type
context
channel
approach
script_source
script_scope
script_id
script_text_hash
ai_used
created_at
```

Regras:

- `tenant_id`, `empresa_id`, `team_id` e `user_id` devem ser resolvidos/validados no backend.
- O frontend não é fonte soberana desses campos.
- O evento deve ser gravado no escopo correto do usuário autenticado.
- Se o usuário pertencer a mais de uma equipe, a RPC deve exigir contexto operacional válido ou inferir pelo lead/lote atual.
- Se não houver `team_id`, o evento pode cair em escopo de empresa, desde que isso seja permitido pelo modelo.

---

## 7. Aplicação à biblioteca de scripts futura

Tabela futura possível:

```txt
pme_script_library
├── id
├── tenant_id
├── empresa_id
├── team_id
├── created_by_user_id
├── visibility_scope
├── title
├── script_type
├── origin_context
├── channel
├── approach
├── content_hash
├── content_encrypted / content_body, se aprovado
├── is_active
├── created_at
└── updated_at
```

Regras:

- `visibility_scope` define quem pode consumir o item.
- `team_id` só é obrigatório quando `visibility_scope = team_only`.
- `empresa_id` é obrigatório para `empresa_global` e `team_only`.
- `tenant_id` é obrigatório para todos os itens não globais de plataforma.
- Conteúdo completo deve seguir política LGPD e criptografia, quando aplicável.

---

## 8. Exemplos práticos

### 8.1 Corretor individual CPF

```txt
Tenant: Wagner Corretor
└── Empresa: Wagner Fernandes / CPF
    └── Equipe padrão
        └── Corretor/Admin: Wagner
```

### 8.2 Empresa pequena com um gestor

```txt
Tenant: Imobiliária XPTO
└── Empresa: XPTO LTDA / CNPJ
    └── Equipe principal
        ├── Gestor João
        └── Corretores A, B, C
```

### 8.3 Empresa com vários gestores

```txt
Tenant: Imobiliária XPTO
└── Empresa: XPTO LTDA / CNPJ
    ├── Equipe Lançamentos
    │   ├── Gestor Ana
    │   └── Corretores 1, 2, 3
    ├── Equipe Alto Padrão
    │   ├── Gestor Bruno
    │   ├── Coordenador Carla
    │   └── Corretores 4, 5, 6
    └── Equipe Repescagem
        ├── Gestor Daniel
        └── Corretores 7, 8, 9
```

### 8.4 Tenant com múltiplas empresas

```txt
Tenant: Grupo Comercial ABC
├── Empresa: Incorporadora A / CNPJ
│   └── Equipes comerciais
├── Empresa: Imobiliária B / CNPJ
│   └── Equipes comerciais
└── Empresa: Operação C / CPF ou CNPJ
    └── Equipes comerciais
```

---

## 9. Implicações para RLS/RPC

A RPC `registrar_pme_script_usage` deve:

- exigir autenticação;
- usar `auth.uid()`;
- resolver o vínculo do usuário com tenant/empresa/equipe;
- validar se o lead pertence ao mesmo escopo;
- validar se o script, quando houver `script_id`, é visível para aquele usuário;
- ignorar `tenant_id`, `empresa_id`, `team_id` e `user_id` vindos do frontend como verdade absoluta;
- validar enums;
- filtrar metadata por allowlist;
- gravar apenas dados permitidos no MVP.

RLS deve garantir:

- Root/Admin Global com acesso controlado e auditável;
- Admin Local restrito ao tenant;
- Admin da Empresa restrito à empresa;
- Gestor/Coordenador restrito às equipes vinculadas;
- Corretor restrito aos próprios eventos e conteúdos autorizados.

---

## 10. Decisão técnica

A segmentação correta do FECH.AI deve ser:

```txt
Tenant = isolamento SaaS
Empresa = entidade comercial/legal ou conta operacional
Equipe/Time/Carteira = segmentação operacional
Gestor/Coordenador = usuários com permissão sobre equipes
Corretor = usuário operacional
Root = soberania técnica da plataforma
Admin Global = administração operacional da plataforma
Admin Local = administração do tenant
Admin da Empresa = administração de uma empresa dentro do tenant
```

Regra final:

> Itens PME e métricas devem ser escopados por tenant, empresa e equipe. O gestor administra a equipe, mas o ownership operacional deve ficar preferencialmente na equipe, não na pessoa do gestor.
