# FECH.AI — Prefácio da Documentação

**Status:** rascunho profissional  
**Data:** 2026-05-26  
**Finalidade:** organizar a documentação do FECH.AI para venda do produto, entrada de sócio, implantação, operação, suporte e evolução segura.  
**Escopo:** documentação. Este pacote não altera código, banco, migration, RPC, frontend, Supabase, Vercel ou regra de negócio.

---

## 1. Como navegar

Esta documentação foi organizada para que uma pessoa que nunca participou das conversas anteriores consiga entender o produto, avaliar o potencial comercial, revisar a arquitetura e oferecer suporte.

Use a navegação abaixo conforme o objetivo.

| Objetivo | Ler primeiro |
|---|---|
| Entender o produto para venda ou sociedade | `docs/00-visao-executiva/resumo-executivo.md` |
| Entender a arquitetura técnica | `docs/02-arquitetura-tecnica/arquitetura-atual.md` |
| Entender onde o sistema roda hoje | `docs/03-infraestrutura-cloud/topologia-cloud.md` |
| Entender o banco de dados | `docs/04-banco-de-dados/mapa-tabelas.md` |
| Documentar tabelas e campos | `docs/04-banco-de-dados/dicionario-de-dados.md` |
| Documentar RPCs e functions | `docs/04-banco-de-dados/rpcs-e-functions.md` |
| Planejar monitoramento e alta disponibilidade | `docs/05-observabilidade-ha/observabilidade-non-stop.md` |
| Responder incidentes | `docs/05-observabilidade-ha/runbook-incidentes.md` |
| Entender segurança multi-tenant | `docs/06-seguranca-compliance/seguranca-multitenant.md` |
| Preparar LGPD e privacidade | `docs/06-seguranca-compliance/lgpd.md` |
| Organizar suporte operacional | `docs/07-operacao-suporte/guia-suporte-n1-n2-n3.md` |
| Definir monetização SaaS | `docs/08-comercial-monetizacao/modelo-saas.md` |
| Mapear financeiro, custos e impostos | `docs/09-financeiro-juridico-fiscal/estrutura-financeira.md` |
| Validar tributação e notas fiscais | `docs/09-financeiro-juridico-fiscal/impostos-e-regime-tributario.md` |
| Preparar Fase 20C com segurança | `docs/mesa-cliente/pre-20c-reconciliacao-github-supabase.md` |

---

## 2. O que é o FECH.AI

O FECH.AI é uma plataforma SaaS para operação comercial imobiliária. O produto combina CRM, distribuição de leads, discador operacional, feedback estruturado, gestão de produtividade, MesaCliente e automação assistida por IA.

A proposta é transformar a rotina de atendimento imobiliário em um processo mensurável, seguro e escalável.

---

## 3. Documentos deste pacote

```text
docs/
  README.md
  00-visao-executiva/
    resumo-executivo.md
  02-arquitetura-tecnica/
    arquitetura-atual.md
  03-infraestrutura-cloud/
    topologia-cloud.md
  04-banco-de-dados/
    mapa-tabelas.md
    dicionario-de-dados.md
    rpcs-e-functions.md
  05-observabilidade-ha/
    observabilidade-non-stop.md
    runbook-incidentes.md
  06-seguranca-compliance/
    seguranca-multitenant.md
    lgpd.md
  07-operacao-suporte/
    guia-suporte-n1-n2-n3.md
  08-comercial-monetizacao/
    modelo-saas.md
  09-financeiro-juridico-fiscal/
    estrutura-financeira.md
    impostos-e-regime-tributario.md
  mesa-cliente/
    pre-20c-reconciliacao-github-supabase.md
```

---

## 4. Regra de ouro

Antes de alterar código, banco, migration, RPC, frontend ou produção, validar:

1. objetivo;
2. fonte da verdade;
3. branch correta;
4. impacto técnico;
5. impacto comercial;
6. risco;
7. rollback;
8. evidências;
9. aprovação.

Produção não é laboratório. Documentação não é enfeite. E drift técnico costuma cobrar juros compostos.

---

## 5. Fonte da verdade

Quando houver conflito entre informação antiga e nova, usar esta ordem:

1. banco real / Supabase aplicado;
2. GitHub na branch correta;
3. documentação oficial vigente;
4. decisão direta do Wagner;
5. inferência técnica declarada;
6. memória ou conversa anterior.

---

## 6. Próximos documentos recomendados

Após este pacote, criar:

```text
docs/mesa-cliente/fase-20c-rastreabilidade-fluxo-historico.md
docs/10-roadmap-e-governanca/backlog-priorizado.md
docs/10-roadmap-e-governanca/matriz-dependencias.md
docs/10-roadmap-e-governanca/due-diligence.md
docs/08-comercial-monetizacao/planos-e-precos.md
docs/08-comercial-monetizacao/proposta-comercial.md
```
