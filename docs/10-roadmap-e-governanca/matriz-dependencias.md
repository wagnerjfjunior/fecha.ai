# FECH.AI — Matriz de Dependências

**Status:** rascunho profissional  
**Área:** roadmap, governança e arquitetura  
**Finalidade:** mapear dependências técnicas, comerciais e operacionais entre as frentes do FECH.AI.  
**Escopo:** documentação e planejamento. Não altera implementação.

---

## 1. Objetivo

Evitar que o projeto avance fora de ordem.

A matriz de dependências ajuda a responder:

```text
O que precisa vir antes?
O que bloqueia o quê?
O que pode rodar em paralelo?
O que exige validação no Supabase?
O que exige decisão comercial?
O que exige validação jurídica/contábil?
```

---

## 2. Tipos de dependência

| Tipo | Significado |
|---|---|
| Técnica | depende de código, banco, RPC, infraestrutura ou integração |
| Segurança | depende de RLS, grants, LGPD, acesso ou governança |
| Comercial | depende de preço, plano, proposta ou posicionamento |
| Operacional | depende de suporte, runbook, monitoramento ou equipe |
| Jurídico/Fiscal | depende de contador, advogado, contrato ou regime |

---

## 3. Matriz principal

| Frente | Depende de | Tipo | Pode paralelizar? | Observação |
|---|---|---|---:|---|
| Resumo executivo | visão do produto | comercial | sim | base para pitch |
| Arquitetura atual | leitura GitHub/docs | técnica | sim | sem alterar sistema |
| Topologia cloud | inventário cloud | técnica | sim | requer dados reais depois |
| Mapa de banco | Supabase real | técnica/segurança | parcial | não oficializar sem inventário |
| Dicionário de dados | mapa de banco | técnica/segurança | não | depende do schema real |
| RPCs e functions | Supabase + migrations | técnica/segurança | não | exige reconciliação |
| Observabilidade | topologia cloud | operacional | sim | pode desenhar antes de implantar |
| Runbook incidentes | observabilidade | operacional | sim | melhora suporte |
| Segurança multitenant | banco/RLS/RPCs | segurança | parcial | regras podem ser documentadas antes |
| LGPD | dados e contratos | jurídico | parcial | precisa validação especializada |
| Planos e preços | custos + público | comercial/financeiro | parcial | requer custos reais |
| Proposta comercial | planos e preços | comercial | não | depende da oferta |
| PRE-20C | GitHub + Supabase | técnica/segurança | sim/read-only | não implementa |
| Fase 20C | PRE-20C aprovado | técnica | não | exige decisão posterior |

---

## 4. O que pode rodar em paralelo

Pode paralelizar:

```text
documentação executiva
leitura de roadmap
mapeamento de riscos
modelo comercial
checklists fiscais/jurídicos
observabilidade em desenho
suporte e runbooks
inventário read-only
```

---

## 5. O que não deve paralelizar

Não paralelizar sem coordenação:

```text
migrations
RPCs
RLS/policies/grants
componentes do MesaCliente
mudança em parser
mudança em motor financeiro
alteração de Supabase real
PRs que mexem nos mesmos arquivos
contratos comerciais definitivos
```

---

## 6. Dependências críticas para venda

Para apresentar a sócio/comprador, priorizar:

```text
resumo executivo
arquitetura atual
topologia cloud
modelo SaaS
estrutura financeira
segurança multitenant
observabilidade planejada
due diligence
roadmap priorizado
```

---

## 7. Dependências críticas para implantação

Para implantar em cliente, priorizar:

```text
ambientes documentados
variáveis de ambiente
onboarding cliente
perfis e permissões
suporte N1/N2/N3
runbook de incidentes
backup/restore
observabilidade mínima
```

---

## 8. Dependências críticas para 20C

Antes da Fase 20C:

```text
PRE-20C concluído
GitHub reconciliado
Supabase reconciliado
RPCs de histórico confirmadas
campos/payloads disponíveis confirmados
RLS e acesso confirmados
contrato visual aprovado
fora de escopo validado
```

---

## 9. Regra de governança

Quando duas frentes dependerem do mesmo arquivo, mesma migration, mesma RPC ou mesma área de segurança, apenas uma deve implementar por vez.

Leitura pode ser paralela. Escrita precisa ser serializada.
