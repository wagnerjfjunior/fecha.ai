# FECH.AI — PME Schema Audit

Status: **AUDITORIA SOMENTE LEITURA**  
Projeto Supabase: `Discador-MesaCliente`  
Project ref: `uobxxgzshrmbtjfdolxd`  
Data: 2026-05-14

Este documento registra a auditoria real do schema atual antes de qualquer migration da PME.

Nenhuma alteração foi aplicada no banco.

---

## 1. Conclusão executiva

O FECH.AI já possui uma estrutura multi-empresa funcional baseada em `empresa_id`.

Para a PME, a melhor interpretação técnica é:

```txt
empresa_id = tenant operacional real do FECH.AI hoje
```

Não existe, no schema auditado, uma tabela separada chamada `tenants`. A tabela `empresas` é o eixo de isolamento atual.

Portanto, para a primeira persistência da PME, o caminho mais seguro é:

```txt
pme_* tables usando empresa_id obrigatório
```

E não `tenant_id` obrigatório neste momento.

A nomenclatura `tenant` pode continuar nos documentos de arquitetura SaaS, mas no banco real atual o campo operacional deve ser `empresa_id`.

---

## 2. Projeto auditado

Projeto Supabase encontrado:

```txt
Nome: Discador-MesaCliente
Ref: uobxxgzshrmbtjfdolxd
Região: sa-east-1
Status: ACTIVE_HEALTHY
Postgres: 17.6.1.104
```

---

## 3. Tabela central de empresas / tenant operacional

Tabela real:

```txt
public.empresas
```

Colunas relevantes:

```txt
id uuid primary key
nome text
slug text unique
plano_id uuid
ativa boolean
criada_por uuid
trial_ate timestamptz
created_at timestamptz
updated_at timestamptz
```

RLS:

```txt
rls_enabled = true
```

Policies relevantes:

```sql
empresas_select:
  is_root() OR id = my_empresa_id()

empresas_insert:
  is_root()

empresas_update:
  is_root()
```

Empresas encontradas:

```txt
Tegra Incorporadora
FECH.AI SISTEMA
Helbor
Lopes
AW-Realty
Abyara
gafisa
Tecnisa
Trisul
MRV
```

Leitura crítica:

- `empresas` é a tabela de isolamento real.
- `empresa_id` já aparece nas tabelas operacionais centrais.
- O nome `tenant_id` não deve ser inventado para a PME sem necessidade.

---

## 4. Usuários operacionais / corretores / RBAC

Tabela real:

```txt
public.corretores
```

Comentário da tabela no banco:

```txt
Tabela crítica do FECH.AI. Centraliza identidade operacional, RBAC, isolamento multi-tenant e ownership operacional.
```

Colunas relevantes:

```txt
id uuid primary key
user_id uuid unique -> auth.users.id
nome text
email text unique
ativo boolean
apto_para_receber boolean
is_gestor boolean
is_admin_local boolean
role text
empresa_id uuid not null -> public.empresas.id
time_id uuid -> public.times.id
lista_preferencial_id uuid -> public.listas.id
```

Campo legado:

```txt
empresa text
```

Comentário do banco:

```txt
CAMPO LEGADO. Não utilizar para isolamento multi-tenant. O tenant oficial é definido por empresa_id.
```

Role oficial:

```txt
role in ('admin_global', 'admin_local', 'gestor', 'corretor')
```

Comentário do banco:

```txt
RBAC oficial do FECH.AI. Fonte principal de autorização operacional. Valores válidos: corretor, gestor, admin_local, admin_global.
```

Distribuição atual de roles:

```txt
corretor ativo: 12
corretor inativo: 3
gestor ativo: 3
admin_local ativo: 3
admin_local + gestor ativo: 1
admin_global ativo: 2
```

Leitura crítica:

- A PME deve usar `corretores.id` como `corretor_id` operacional.
- A PME deve usar `auth.uid()` apenas via funções auxiliares, não diretamente em regras complexas repetidas.
- A autorização deve se apoiar em `empresa_id`, `role`, `is_gestor`, `is_admin_local` e `ativo`.

---

## 5. Admin global / root

Tabela real:

```txt
public.admins
```

Colunas relevantes:

```txt
id uuid primary key
user_id uuid unique
nome text
email text unique
ativo boolean
empresa_id uuid null -> public.empresas.id
role text default 'admin_global'
```

Funções reais encontradas:

```sql
public.is_root()
public.is_admin_global()
public.is_admin_local()
```

Definição funcional resumida:

```txt
is_root() retorna true se:
- existe registro ativo em public.admins para auth.uid(); ou
- existe corretor ativo com role = 'admin_global'.
```

```txt
is_admin_global() apenas chama is_root().
```

```txt
is_admin_local() retorna true se:
- corretor ativo do auth.uid(); e
- is_admin_local = true ou role in ('admin_local','admin_global')
```

Leitura crítica:

- A PME pode reutilizar `is_root()` com segurança conceitual.
- Para admin local/gestor, será melhor criar funções PME dedicadas, reaproveitando `my_empresa_id()` e `my_corretor_id()`.

---

## 6. Funções auxiliares existentes

Funções reais relevantes:

```sql
public.my_empresa_id()
public.my_corretor_id()
public.is_root()
public.is_admin_global()
public.is_admin_local()
public.corretor_tem_acesso_lista(p_lista_id, p_corretor_id, p_empresa_id, p_time_id)
```

### 6.1 `my_empresa_id()`

Retorna:

```txt
empresa_id do corretor ativo vinculado ao auth.uid()
```

### 6.2 `my_corretor_id()`

Retorna:

```txt
id do corretor ativo vinculado ao auth.uid()
```

### 6.3 `corretor_tem_acesso_lista(...)`

Já resolve acesso por:

```txt
global
empresa
time
selecionados
```

Leitura crítica:

- Para PME, vale criar função específica, mas seguindo o mesmo padrão.
- Não devemos duplicar lógica complexa em cada policy.

---

## 7. Leads

Tabela real:

```txt
public.leads
```

Comentário da tabela:

```txt
Lead operacional do FECH.AI. Ownership original pertence à lista/empresa. Ownership operacional temporário ocorre via lote.
```

Colunas relevantes para PME:

```txt
id uuid primary key
lista_id uuid -> public.listas.id
lote_id uuid -> public.lotes.id
corretor_id uuid -> public.corretores.id
empresa_id uuid not null -> public.empresas.id
time_id uuid -> public.times.id
nome text
email text
telefone_e164 text
whatsapp text
status text
feedback text
feedback_tipo lead_feedback_tipo
status_operacional lead_status_operacional
status_comercial lead_status_comercial
origem_tipo text default 'lista'
seq_email integer
seq_whatsapp integer
canal_preferencial text
proximo_contato_em timestamptz
acao_sugerida text
```

Origens atuais:

```txt
lista: 5258 leads
meta: 0
google: 0
manual: 0
```

Distribuição por empresa:

```txt
Tegra Incorporadora: 5257 leads
FECH.AI SISTEMA: 1 lead
```

RLS relevante:

```sql
leads_select:
  is_root()
  OR is_admin_local() AND empresa_id = my_empresa_id()
  OR corretor_id = my_corretor_id() AND empresa_id = my_empresa_id()

leads_insert:
  is_root()
  OR is_admin_local() AND empresa_id = my_empresa_id()
  OR is_gestor() AND empresa_id = my_empresa_id()

leads_update:
  is_root()
  OR corretor_id = my_corretor_id()
```

Leitura crítica:

- Para PME, `lead_id` deve referenciar `public.leads.id`.
- `empresa_id` deve ser copiado/armazenado na PME para RLS e performance.
- O tipo atual `origem_tipo` ainda é insuficiente para diferenciar `visitou_plantao` versus `lista_fria`.
- Será necessário campo PME próprio `lead_type` ou mapeamento via lista/origem/campanha.

---

## 8. Listas

Tabela real:

```txt
public.listas
```

Colunas relevantes:

```txt
id uuid primary key
nome_fornecedor text
nome_arquivo text
total_leads integer
status text
empresa_id uuid not null -> public.empresas.id
time_id uuid
time_origem_id uuid
origem_nivel integer
score_automatico numeric
escopo_distribuicao text
```

Escopo de distribuição:

```txt
time
empresa
global
selecionados
```

Leitura crítica:

- Lista comprada/fria provavelmente deve ser inferida inicialmente por `listas` + classificação manual no upload/lista.
- Hoje não existe campo claro `tipo_lista` ou `lead_temperature` em `listas`.
- Para PME, o ideal é adicionar no futuro um campo controlado em listas ou criar uma tabela de classificação PME.

---

## 9. Times

Tabela real:

```txt
public.times
```

Colunas relevantes:

```txt
id uuid primary key
empresa_id uuid not null -> public.empresas.id
gestor_id uuid not null -> public.corretores.id
nome text
ativo boolean
```

RLS já considera:

```txt
root
admin_local da empresa
gestor do time
membro do time via my_time_id()
```

Leitura crítica:

- PME pode futuramente permitir template/cadência por time.
- Não é necessário na v1 de persistência.

---

## 10. Empreendimentos

Tabela real:

```txt
public.empreendimentos
```

Status atual:

```txt
0 rows
```

Colunas relevantes:

```txt
id uuid primary key
empresa_id uuid not null -> public.empresas.id
nome text
incorporadora text
bairro text
cidade text
endereco_publico text
status empreendimento_status
```

RLS:

```sql
empreendimentos_select:
  is_root() OR empresa_id = my_empresa_id()
```

Leitura crítica:

- A tabela existe e é adequada para especialização futura da PME por empreendimento.
- Como está vazia, não deve ser obrigatória na primeira PME persistente.
- `empreendimento_id` deve ser nullable nas tabelas PME.

---

## 11. Tabela existente de templates

Tabela real existente:

```txt
public.templates_mensagens
```

Status atual:

```txt
0 rows
```

Colunas:

```txt
id uuid primary key
empresa_id uuid nullable -> public.empresas.id
nome text
canal canal_envio_tipo
origem_lead text
tipo text
conteudo text
global boolean
ativo boolean
created_at timestamptz
updated_at timestamptz
```

RLS:

```sql
templates_select:
  is_root() OR global = true OR empresa_id = my_empresa_id()
```

Leitura crítica:

Esta tabela é genérica e pode ser aproveitada ou preservada, mas não cobre bem a PME completa porque falta:

- fase estruturada;
- tom;
- objetivo;
- peso/randomização;
- seed_key;
- scripts de ligação;
- cadências;
- passos;
- histórico de uso;
- estado por lead.

Recomendação:

- Não apagar nem reaproveitar à força.
- Criar tabelas `pme_*` específicas é mais seguro para não contaminar legado.
- Se necessário, futuramente migrar/importar `templates_mensagens` para `pme_message_templates`.

---

## 12. Funil e feedbacks

Tabelas reais:

```txt
public.funil_estagios
public.funil_movimentacoes
```

Tipos relevantes em `leads`:

```txt
lead_feedback_tipo:
- agendado_visita
- enviado_informacoes
- em_conversa
- retornar_depois
- sem_interesse
- lead_ja_atendido
- nao_responde
- nao_responde_email
- numero_errado
- caixa_postal
- chamada_caiu
- whatsapp_invalido
- invalido
- nao_toca
```

```txt
lead_status_comercial:
- sem_status
- contato_iniciado
- contato_efetivo
- em_negociacao
- proposta_enviada
- ganho
- perdido_com_contato
- perdido_sem_contato
- invalido
```

Leitura crítica:

- A PME deve usar os feedbacks existentes como gatilhos de parada/pausa.
- Não devemos criar taxonomia paralela sem mapear para `lead_feedback_tipo`.
- Pode haver feedbacks comerciais desejados pela PME que ainda não existem, como `opt_out`, `em_comparacao`, `quer_simulacao`, `falar_com_familia`.
- Esses novos estados devem ser tratados inicialmente em `pme_message_usage.feedback_key`/metadata ou virar extensão futura do enum, com muito cuidado.

---

## 13. Recomendação de modelagem revisada

O draft anterior usava `tenant_id`. Após auditoria real, a recomendação muda para:

```txt
empresa_id uuid not null
```

Em todas as tabelas PME.

Tabelas recomendadas v1:

```txt
pme_message_templates
pme_call_scripts
pme_cadences
pme_cadence_steps
pme_lead_message_state
pme_message_usage
```

Campos comuns:

```txt
empresa_id uuid not null references public.empresas(id)
empreendimento_id uuid null references public.empreendimentos(id)
created_by uuid null references public.corretores(id)
updated_by uuid null references public.corretores(id)
```

Para histórico:

```txt
lead_id uuid not null references public.leads(id)
corretor_id uuid null references public.corretores(id)
empresa_id uuid not null references public.empresas(id)
```

---

## 14. Funções PME recomendadas

Criar funções dedicadas:

```sql
public.pme_can_access_empresa(p_empresa_id uuid) returns boolean
```

Regra:

```txt
is_root()
OR p_empresa_id = my_empresa_id()
```

Criar:

```sql
public.pme_is_empresa_admin(p_empresa_id uuid) returns boolean
```

Regra:

```txt
is_root()
OR (
  p_empresa_id = my_empresa_id()
  AND corretor ativo
  AND role in ('admin_local','admin_global','gestor')
)
```

Criar:

```sql
public.pme_can_consume_empresa(p_empresa_id uuid) returns boolean
```

Regra:

```txt
is_root()
OR p_empresa_id = my_empresa_id()
```

Observação:

Para v1, o consumo de template por corretor pode ser permitido dentro da própria empresa, mas edição deve ficar só para admin/gestor.

---

## 15. Lead type PME

O banco atual tem:

```txt
leads.origem_tipo = lista | meta | google | manual
```

Mas a PME precisa de:

```txt
lista_fria
visitou_plantao
lista_quente
lead_quente
```

Recomendação v1:

Criar `lead_type` dentro de `pme_lead_message_state` e `pme_message_usage`.

Não alterar `leads` agora.

Motivo:

- Evita mexer no motor atual.
- Permite classificar PME sem impactar discador.
- Depois podemos estudar campo oficial em `leads` ou `listas`.

---

## 16. Riscos encontrados

### Risco 1 — Confundir tenant_id com empresa_id

O schema real usa `empresa_id`. Criar `tenant_id` agora geraria duplicidade conceitual.

Decisão recomendada:

```txt
Usar empresa_id como tenant operacional da PME v1.
```

### Risco 2 — Usar tabela `templates_mensagens` para tudo

Ela existe, mas é simples demais para PME.

Decisão recomendada:

```txt
Criar pme_* e manter templates_mensagens intacta.
```

### Risco 3 — Criar novos feedbacks diretamente no enum

Enum exige migration delicada.

Decisão recomendada:

```txt
Usar feedback_key/metadata da PME para estados finos até consolidar taxonomia.
```

### Risco 4 — Dar poder demais ao corretor

Corretor deve consumir, não configurar.

Decisão recomendada:

```txt
INSERT/UPDATE de templates/scripts/cadências só para root/admin_local/gestor.
```

### Risco 5 — Histórico apagável

Histórico de uso não deve ser editável por corretor.

Decisão recomendada:

```txt
pme_message_usage: INSERT permitido; UPDATE/DELETE bloqueado na v1.
```

---

## 17. Critério para próxima migration real

Antes da migration real, revisar e converter o draft SQL para:

- remover `tenant_id`;
- usar `empresa_id not null`;
- adicionar FKs reais;
- criar funções `pme_*_empresa`;
- criar RLS com base nas funções reais;
- manter `empreendimento_id nullable`;
- manter `lead_type` PME próprio;
- manter histórico append-only.

---

## 18. Veredito

A PME pode avançar para migration real controlada, mas com ajuste importante:

```txt
Não criar tenant_id novo.
Usar empresa_id como isolamento tenant-safe atual.
```

Essa decisão deixa a PME alinhada com o FECH.AI real, sem inventar uma segunda camada de tenancy desnecessária.
