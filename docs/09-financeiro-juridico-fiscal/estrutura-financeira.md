# FECH.AI — Estrutura Financeira

**Status:** rascunho profissional  
**Área:** financeiro, custos e viabilidade  
**Finalidade:** mapear custos, receitas, margem e indicadores financeiros para operar o FECH.AI como SaaS.  
**Escopo:** planejamento financeiro. Valores devem ser preenchidos com dados reais.

---

## 1. Objetivo

Este documento deve permitir avaliar se o FECH.AI é financeiramente viável como produto SaaS.

Perguntas que precisa responder:

```text
Quanto custa manter o produto no ar?
Quanto custa cada cliente?
Quanto custa cada usuário?
Quanto custa o uso de IA?
Qual margem bruta esperada?
Qual receita mínima para ponto de equilíbrio?
Qual preço mínimo por plano?
Qual custo de suporte?
```

---

## 2. Tipos de receita

| Receita | Recorrente? | Observação |
|---|---:|---|
| Assinatura mensal | sim | principal receita SaaS |
| Setup de implantação | não/por projeto | ajuda a cobrir onboarding |
| Usuário adicional | sim | expansão por cliente |
| Módulo adicional | sim | MesaCliente, IA, observabilidade etc. |
| Suporte premium | sim | operação assistida |
| Treinamento | pontual/recorrente | conforme contrato |
| Consultoria comercial | pontual/recorrente | campanhas, funil, automação |
| Integrações | pontual + mensal | WABA, e-mail, Meta, Google |

---

## 3. Custos operacionais

| Categoria | Exemplos | Tipo |
|---|---|---|
| Infraestrutura | Vercel, Supabase, domínio, storage | fixo/variável |
| IA | OpenAI/ChatGPT | variável por uso |
| Observabilidade | Sentry, uptime, logs, alertas | fixo/variável |
| Comunicação | WhatsApp/WABA, e-mail, SMS se aplicável | variável |
| Suporte | atendimento, análise, correções | variável |
| Comercial | tráfego, vendedor, comissão | variável |
| Jurídico/contábil | contador, contratos, LGPD | fixo/pontual |
| Ferramentas | gestão, documentação, automação | fixo |

---

## 4. Modelo de custo por cliente

Criar uma planilha com:

```text
cliente
plano
usuários contratados
módulos ativos
receita mensal
custo proporcional de infraestrutura
custo de IA
custo de comunicação
custo de suporte
margem bruta
margem estimada
```

---

## 5. Ponto de equilíbrio

Fórmula conceitual:

```text
ponto de equilíbrio = custos fixos mensais / margem média por cliente
```

Exemplo de leitura:

```text
Se o custo fixo mensal for alto e o ticket baixo, o SaaS precisa de volume.
Se o ticket for maior e incluir setup/suporte, precisa de menos clientes para empatar.
```

---

## 6. Indicadores financeiros

| Indicador | Função |
|---|---|
| MRR | receita recorrente mensal |
| ARR | receita recorrente anual |
| margem bruta | mede eficiência do produto |
| margem líquida | mede resultado após despesas |
| CAC | custo para adquirir cliente |
| LTV | valor de vida do cliente |
| churn | perda de clientes |
| payback | tempo para recuperar aquisição |
| ARPA | receita média por conta |

---

## 7. Cenários financeiros

Criar projeções para:

```text
cenário conservador
cenário provável
cenário agressivo
```

Cada cenário deve estimar:

```text
quantidade de clientes
receita média por cliente
MRR
custos fixos
custos variáveis
margem
ponto de equilíbrio
necessidade de suporte
```

---

## 8. Cuidados

Não assumir que todo faturamento é lucro.

Principais vazamentos de margem:

```text
suporte excessivo
customização não cobrada
uso de IA sem limite
integrações complexas sem setup
SLA prometido sem estrutura
impostos não considerados
comissão comercial não provisionada
```

---

## 9. Próximos passos

1. Levantar custos reais atuais.
2. Estimar custo por cliente e por usuário.
3. Definir preço mínimo por plano.
4. Definir setup mínimo obrigatório.
5. Validar impostos com contador.
6. Criar planilha financeira do SaaS.
7. Criar proposta comercial com margem protegida.
