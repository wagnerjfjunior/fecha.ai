# FECH.AI — Escopo MVP v1

**Status:** v1.0 — escopo inicial recomendado  
**Data:** 2026-06-02  
**Escopo:** definição do primeiro MVP funcional do FECH.AI.  
**Fonte central:** FECH.AI — Projeto Principal / Master Project.

---

## 1. Objetivo do MVP

O MVP v1 deve provar que o FECH.AI gera valor diário para o corretor, antes de expandir para automações avançadas, portais, campanhas autônomas ou gateway próprio de conversões.

Hipótese central:

```text
Se o corretor conseguir importar contatos, agir rápido, registrar status e visualizar agendamentos do fim de semana, o FECH.AI cria valor prático e recorrente.
```

---

## 2. Escopo do MVP v1

### 2.1 Importação de leads/listas

Inclui:

- importação CSV;
- importação XLSX;
- texto colado;
- importação manual;
- deduplicação básica;
- validação de telefone;
- origem da lista;
- nome da lista;
- responsável/corretor;
- tenant/empresa.

Pode entrar como beta:

- foto/OCR de lista de papel;
- prévia de OCR com revisão humana.

Fora do MVP v1:

- OCR sem revisão humana;
- importação automática complexa de portais;
- app nativo/share extension.

---

### 2.2 CRM/funil mínimo

Status mínimos:

```text
Novo
Tentando contato
Contato realizado
Qualificado
Visita agendada
Visita realizada
Proposta enviada
Perdido
Vendido
```

Campos mínimos:

- nome;
- telefone;
- e-mail opcional;
- origem;
- lista;
- empreendimento de interesse opcional;
- status;
- próxima ação;
- observação;
- corretor responsável;
- data de criação;
- data da última interação.

---

### 2.3 Discador e ações rápidas

Inclui:

- botão ligar;
- botão WhatsApp;
- copiar telefone;
- registrar status rápido;
- observação rápida;
- próxima ação;
- retorno/agendamento.

Fora do MVP v1:

- discador nativo completo;
- gravação de chamadas;
- automação total de cadência;
- envio automático em massa.

---

### 2.4 Power Mode simples

Power Mode v1 deve permitir:

- abrir próximo lead;
- ligar;
- chamar no WhatsApp;
- registrar resultado;
- avançar para próximo lead;
- mostrar progresso da sessão.

Métricas da sessão:

- contatos trabalhados;
- ligações iniciadas;
- WhatsApps abertos;
- contatos realizados;
- visitas agendadas;
- leads pendentes.

---

### 2.5 Dashboard de fim de semana

Dashboard essencial:

- meta de visitas do fim de semana;
- visitas agendadas;
- faltam X visitas;
- leads quentes disponíveis;
- leads parados;
- conversão de contato para visita;
- ranking simples por corretor quando houver gestor.

Objetivo comportamental:

```text
criar urgência operacional e clareza de execução para o corretor agir antes do fim de semana.
```

---

### 2.6 Tracking básico para origem

MVP v1 deve preservar:

- origem;
- UTM source;
- UTM medium;
- UTM campaign;
- UTM content;
- UTM term;
- fbclid quando houver;
- gclid quando houver.

Fora do MVP v1 completo:

- gateway próprio;
- automação avançada Meta/Google;
- decisão autônoma de campanha;
- troca automática de copy/criativo.

---

## 3. Requisitos não funcionais mínimos

- multi-tenant obrigatório;
- RLS obrigatório onde aplicável;
- nenhuma confiança em tenant_id/empresa_id apenas do frontend;
- logs sem PII bruta sempre que possível;
- tratamento de erro amigável;
- auditoria de importação;
- rollback de release;
- preview Vercel antes de produção;
- changelog por entrega;
- LGPD e opt-out quando aplicável.

---

## 4. Critérios de aceite do MVP

O MVP só deve ser considerado funcional quando:

```text
1. gestor/corretor consegue importar lista simples;
2. sistema detecta duplicidades básicas;
3. corretor consegue ligar ou abrir WhatsApp em poucos cliques;
4. corretor consegue registrar status;
5. funil mostra leads por etapa;
6. dashboard mostra visitas agendadas para o fim de semana;
7. dados respeitam tenant/empresa/corretor;
8. há logs mínimos de importação e erro;
9. fluxo funciona em mobile e desktop;
10. há caminho de rollback em caso de falha.
```

---

## 5. Métricas de validação

Medir nos primeiros pilotos:

- listas importadas;
- leads válidos por lista;
- duplicidades detectadas;
- leads trabalhados por dia;
- ligações iniciadas;
- WhatsApps abertos;
- contatos realizados;
- visitas agendadas;
- propostas geradas futuramente;
- usuários ativos semanais;
- tempo até primeira ação;
- retenção semanal;
- disposição a pagar.

---

## 6. Piloto recomendado

Piloto inicial:

```text
3 a 5 corretores reais
1 gestor
2 semanas de uso
foco em listas e agendamentos
sem automação avançada
```

Perguntas de validação:

```text
O corretor usou mais de uma vez?
Importou lista real?
Ligou pelo sistema?
Registrou status?
Agendou visita?
Sentiu mais controle?
Pagaria por isso?
Quanto pagaria?
Indicaria para outro corretor?
```

---

## 7. Fora do MVP v1

Itens importantes, mas não iniciais:

- importação completa de portais;
- WhatsApp oficial completo;
- WhatsApp não oficial;
- envio automático de mensagens;
- MesaCliente completo;
- importação avançada de tabela imobiliária;
- campanha criada automaticamente pelo FECH.AI;
- gateway próprio sem Stape;
- app nativo;
- IA autônoma alterando campanhas.

---

## 8. Próxima fase após MVP v1

Depois do MVP v1 validado, avançar para:

```text
Fase 2 — Tracking ADS/CAPI/Stape/CRM-to-Ads
Fase 3 — MesaCliente/Tabelas/Propostas
```

A ordem pode mudar se o mercado provar que MesaCliente gera monetização mais rápida que LeadOps.
