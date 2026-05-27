# FECH.AI — Backlog Priorizado

**Status:** rascunho profissional  
**Área:** roadmap e governança  
**Finalidade:** organizar as próximas frentes do FECH.AI por prioridade, risco, valor comercial e dependência técnica.  
**Escopo:** planejamento. Não altera código, banco ou produto.

---

## 1. Objetivo

Este backlog prioriza o que precisa ser feito para transformar o FECH.AI em produto SaaS vendável, suportável e escalável.

A priorização considera:

```text
valor comercial
risco técnico
risco de segurança
necessidade para venda/sócio
necessidade para suporte
dependência de outras frentes
esforço estimado
```

---

## 2. Escala de prioridade

| Prioridade | Significado |
|---|---|
| P0 | crítico para segurança, operação ou venda responsável |
| P1 | muito importante para maturidade SaaS |
| P2 | importante, mas pode vir após base estável |
| P3 | melhoria futura |

---

## 3. Backlog P0 — Base crítica

| Item | Motivo | Dependência |
|---|---|---|
| Reconciliação GitHub x Supabase | evitar drift antes de novas fases | acesso read-only ao Supabase |
| Inventário real de tabelas/RPCs/RLS | base para suporte, segurança e venda | Supabase real |
| Observabilidade mínima | operar SaaS sem ficar cego | escolha de ferramenta |
| Política de segredos e acessos | reduzir risco operacional | inventário de contas |
| Segurança multi-tenant validada | requisito SaaS essencial | testes cross-tenant |
| Runbook de incidentes | suporte e operação previsíveis | matriz de severidade |

---

## 4. Backlog P1 — Produto vendável

| Item | Motivo | Dependência |
|---|---|---|
| Planos e preços | transformar produto em oferta comercial | custos reais |
| Proposta comercial padrão | facilitar venda | planos definidos |
| Calculadora de ROI | mostrar valor para imobiliárias | métricas operacionais |
| Demonstração guiada | facilitar pitch | ambiente estável |
| Due diligence preenchida | entrada de sócio/investidor | documentação base |
| Checklist LGPD/jurídico | venda B2B com menor risco | assessoria jurídica |

---

## 5. Backlog P1 — MesaCliente

| Item | Motivo | Dependência |
|---|---|---|
| PRE-20C | preparar rastreabilidade com segurança | GitHub + Supabase |
| Fase 20C | mostrar valor original x valor final | PRE-20C aprovado |
| Contrato de payload cliente-safe | evitar vazamento interno | mapeamento de dados |
| Testes de acesso histórico | garantir ownership/time/tenant | massa de teste |

---

## 6. Backlog P2 — Escala SaaS

| Item | Motivo | Dependência |
|---|---|---|
| Dashboard financeiro do SaaS | controlar MRR, custo e margem | modelo financeiro |
| Gestão de planos por tenant | cobrança e limites | planos comerciais |
| Controle de uso de IA | proteger custo | instrumentação |
| Integração WABA | canal comercial chave | governança e custo |
| E-mail transacional | comunicação escalável | domínio e reputação |
| Auditoria avançada | compliance e suporte | logs estruturados |

---

## 7. Backlog P3 — Futuro

| Item | Motivo |
|---|---|
| Marketplace de templates imobiliários | monetização adicional |
| White-label avançado | venda para redes maiores |
| BI executivo | relatórios premium |
| Integração Meta/Google Ads | aquisição e atribuição |
| App mobile dedicado | experiência de campo |
| IA de coaching comercial | aumento de produtividade |

---

## 8. Próxima sequência recomendada

Sequência segura:

```text
1. Completar pacote documental
2. Executar reconciliação GitHub x Supabase
3. Fechar inventário de banco/RPC/RLS
4. Definir observabilidade mínima
5. Definir planos e preços
6. Criar proposta comercial
7. Executar PRE-20C
8. Implementar 20C apenas após evidência
```

---

## 9. Critério de priorização futura

Qualquer novo item deve ser avaliado por:

```text
impacto em receita
impacto em segurança
impacto em suporte
impacto em escala
risco de quebrar produção
dependência de banco/RPC
necessidade de aprovação do Wagner
```
