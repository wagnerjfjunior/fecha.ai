# FECH.AI — Mapa Inicial de Tabelas

**Status:** rascunho / pendente de reconciliação com Supabase real  
**Área:** banco de dados  
**Finalidade:** iniciar o inventário das tabelas do FECH.AI para suporte, venda, auditoria, due diligence e evolução técnica.  
**Escopo:** documentação. Este arquivo não cria nem altera tabelas.

---

## 1. Regra principal

Este mapa não deve ser tratado como verdade final enquanto não for reconciliado com o Supabase real.

Fonte da verdade para banco:

```text
1. Supabase aplicado
2. migrations do GitHub
3. documentação técnica
4. informação operacional
5. inferência declarada
```

---

## 2. Objetivo do mapa

O mapa de tabelas deve permitir responder:

```text
Quais tabelas existem?
Para que servem?
Qual módulo usa cada tabela?
A tabela contém informação sensível?
Tem RLS?
Tem escrita direta ou via RPC?
Quais RPCs leem ou escrevem?
Pode aparecer para cliente?
```

---

## 3. Tabelas por domínio

### 3.1 Core / Multiempresa

| Tabela | Finalidade | Sensível | RLS esperado | Observação |
|---|---|---:|---:|---|
| `empresas` | empresas/clientes/tenants comerciais | sim | sim | validar schema real |
| `corretores` | usuários operacionais, corretores e perfis | sim | sim | validar schema real |
| `times` | equipes comerciais | sim | sim | confirmar existência |
| `usuarios` | usuários internos, se existir separado | sim | sim | confirmar existência |

### 3.2 CRM / Leads / Discador

| Tabela | Finalidade | Sensível | RLS esperado | Observação |
|---|---|---:|---:|---|
| `leads` | cadastro e acompanhamento de leads | sim | sim | confirmar nome real |
| `listas` | agrupamento de leads por campanha/fornecedor | sim | sim | confirmar nome real |
| `lista_leads` | vínculo entre lista e leads | sim | sim | confirmar nome real |
| `feedbacks` | histórico de classificação do lead | sim | sim | confirmar nome real |
| `atividades` | ações comerciais e follow-ups | sim | sim | confirmar nome real |

### 3.3 MesaCliente

| Tabela | Finalidade | Sensível | RLS esperado | Observação |
|---|---|---:|---:|---|
| `mesa_simulacoes` | simulações/propostas do MesaCliente | sim | sim | validada em docs anteriores |
| `mesa_cliente_agendas_financeiras` | cabeçalho/versionamento da agenda financeira | crítico | sim | validar schema real |
| `mesa_cliente_fluxo_parcelas` | parcelas datadas da agenda | crítico | sim | validar schema real |
| `mesa_cliente_fluxo_operacoes` | operações financeiras simuladas/confirmadas | crítico | sim | validar schema real |
| `mesa_cliente_politicas_financeiras` | políticas financeiras por empresa/empreendimento | crítico | sim | validar existência atual |
| `mesa_cliente_politica_premio_faixas` | faixas de remuneração interna | crítico | sim | validar existência atual |

### 3.4 Auditoria / Logs

| Tabela | Finalidade | Sensível | RLS esperado | Observação |
|---|---|---:|---:|---|
| `audit_logs` | auditoria geral, se existir | sim | sim | confirmar existência |
| `event_logs` | eventos operacionais, se existir | sim | sim | confirmar existência |
| `message_logs` | mensagens e tentativas, se existir | sim | sim | confirmar existência |

---

## 4. Categorias de campos que exigem atenção

Classificar como sensíveis, no inventário oficial, campos relacionados a:

```text
identificação pessoal
contato
credenciais e chaves
escopo de tenant/empresa/time
perfil e permissão
política comercial interna
metadados técnicos
payloads brutos
valores financeiros internos
regras de remuneração
```

Regra:

```text
Campo sensível não deve aparecer em payload cliente-safe sem contrato explícito.
```

---

## 5. Modelo de inventário final

Cada tabela deverá ter uma ficha neste formato:

```markdown
## Nome da tabela

### Finalidade

### Módulo

### Colunas
| Coluna | Tipo | Obrigatória | Default | Sensível | Observação |
|---|---|---:|---|---:|---|

### Chaves e relacionamentos

### Índices

### RLS e policies

### RPCs que leem

### RPCs que escrevem

### Pode aparecer para cliente?

### Riscos

### Observações
```

---

## 6. Próximo passo para versão oficial

Executar inventário read-only no Supabase para gerar:

```text
lista real de tabelas
lista real de colunas
chaves primárias
chaves estrangeiras
índices
policies
RLS ativo/inativo
grants
functions/RPCs
```

Depois comparar com:

```text
supabase/migrations/*
docs/mesa-cliente/*
docs/protocolos/*
```

---

## 7. Critério de aceite

Este mapa só poderá virar oficial quando:

```text
schema real tiver sido consultado
RLS tiver sido conferida
RPCs tiverem sido listadas
migrations tiverem sido reconciliadas
campos sensíveis tiverem sido classificados
pendências e drifts tiverem sido documentados
```
