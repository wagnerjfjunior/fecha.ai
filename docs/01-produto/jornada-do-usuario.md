# FECH.AI — Jornada do Usuário

**Status:** rascunho profissional  
**Área:** produto, UX e operação  
**Finalidade:** mapear a jornada dos principais usuários do FECH.AI para orientar produto, vendas, suporte, onboarding e demonstração.  
**Escopo:** documentação funcional. Não altera frontend ou regra de negócio.

---

## 1. Objetivo

Este documento descreve como os principais perfis interagem com o FECH.AI.

Perfis considerados:

```text
corretor
gestor
admin da empresa
suporte
cliente final indiretamente, via MesaCliente/proposta
```

---

## 2. Jornada do corretor

### 2.1 Entrada

O corretor acessa a plataforma para trabalhar leads e registrar a evolução comercial.

Fluxo esperado:

```text
login
visualização da lista/lote de leads
seleção ou recebimento do próximo lead
ação de contato
registro de feedback
próxima ação sugerida
avanço no funil
```

### 2.2 Necessidades do corretor

```text
saber qual lead trabalhar agora
acionar rápido por ligação ou WhatsApp
entender origem e contexto do lead
registrar feedback sem burocracia
receber apoio de mensagem/script
não perder retorno agendado
usar MesaCliente na negociação
```

### 2.3 Resultado esperado

```text
mais produtividade
menos dispersão
follow-up mais organizado
histórico claro
atendimento mais profissional
```

---

## 3. Jornada do gestor

### 3.1 Entrada

O gestor acessa a plataforma para acompanhar equipe, produtividade, funil e qualidade das listas.

Fluxo esperado:

```text
login
visão geral do dashboard
análise por corretor
análise por origem/lista
identificação de gargalos
redistribuição ou orientação
acompanhamento de resultado
```

### 3.2 Necessidades do gestor

```text
saber quem está trabalhando
saber quem não está trabalhando
medir contato efetivo
medir avanço
avaliar perda com contato e sem contato
identificar lista ruim
acompanhar campanha/origem
apoiar corretores com baixa performance
```

### 3.3 Resultado esperado

```text
gestão com evidência
menos achismo
melhor decisão sobre listas e mídia
mais controle operacional
```

---

## 4. Jornada do admin da empresa

### 4.1 Entrada

O admin configura a operação da empresa no FECH.AI.

Fluxo esperado:

```text
criação/configuração da empresa
cadastro de usuários
configuração de perfis
configuração de listas/funis
parametrização de regras
acompanhamento de uso
```

### 4.2 Necessidades do admin

```text
controlar usuários
controlar acessos
manter operação organizada
ter segurança por empresa/time
acompanhar uso e custos
```

---

## 5. Jornada do suporte

### 5.1 Entrada

O suporte atua quando há dúvida, erro ou incidente.

Fluxo esperado:

```text
receber chamado
classificar impacto
coletar evidência
validar usuário/empresa/módulo
consultar runbook
resolver ou escalar
registrar causa e solução
```

### 5.2 Necessidades do suporte

```text
documentação clara
runbook
matriz de erros
logs disponíveis
informações mínimas do chamado
regras de escalonamento
```

---

## 6. Jornada da MesaCliente

Fluxo conceitual:

```text
corretor seleciona contexto/proposta
MesaCliente exibe simulação/fluxo
corretor conduz negociação
histórico registra proposta/fluxo
2ª via pode ser reaberta em modo seguro
rastreabilidade futura mostra valor original x final
```

Pontos críticos:

```text
não recalcular histórico indevidamente
não expor dado interno ao cliente
respeitar ownership/time/tenant
manter visão read-only quando for 2ª via
```

---

## 7. Momentos de valor

| Momento | Valor entregue |
|---|---|
| Primeiro acesso | operação começa organizada |
| Primeiro lote trabalhado | corretor entende produtividade |
| Primeiro dashboard gestor | gestão vê gargalos |
| Primeira lista avaliada | empresa entende qualidade da base |
| Primeira negociação com MesaCliente | corretor ganha apoio comercial |
| Primeiro incidente resolvido por runbook | suporte mostra maturidade |

---

## 8. Gargalos a observar

```text
corretor resistir ao feedback obrigatório
gestor não usar dashboard
admin configurar usuários de forma errada
suporte sem logs suficientes
MesaCliente ser usado fora do fluxo previsto
cliente pedir customização antes do produto estabilizar
```

---

## 9. Uso deste documento

A jornada deve orientar:

```text
roteiro de demonstração
onboarding de cliente
treinamento de usuários
priorização de UX
materiais comerciais
suporte N1/N2/N3
```
