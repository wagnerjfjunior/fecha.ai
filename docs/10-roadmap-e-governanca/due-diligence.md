# FECH.AI — Due Diligence para Sócio, Investidor ou Venda

**Status:** rascunho profissional  
**Área:** governança, venda e sociedade  
**Finalidade:** organizar as informações necessárias para apresentar o FECH.AI a um possível sócio, comprador, investidor ou parceiro estratégico.  
**Escopo:** documentação e preparação. Não altera código, banco ou contrato.

---

## 1. Objetivo

Este documento define o checklist mínimo para avaliar o FECH.AI como produto, negócio e ativo tecnológico.

A due diligence deve responder:

```text
O que está pronto?
O que ainda está em construção?
Quem é dono do quê?
Onde o sistema roda?
Quais são os custos?
Quais são os riscos?
Como o produto gera receita?
Como o suporte funciona?
Como o produto escala?
```

---

## 2. Escopo da due diligence

A avaliação deve cobrir:

```text
produto
tecnologia
infraestrutura
banco de dados
segurança
LGPD/privacidade
financeiro
comercial
contratos
propriedade intelectual
operação e suporte
roadmap
riscos e pendências
```

---

## 3. Produto

Checklist:

```text
visão executiva criada
proposta de valor definida
módulos documentados
público-alvo definido
problemas resolvidos descritos
jornada do usuário mapeada
status funcional por módulo
roadmap priorizado
```

Evidências esperadas:

```text
demonstração funcional
prints ou vídeo de navegação
lista de módulos disponíveis
lista de módulos futuros
casos de uso reais
```

---

## 4. Tecnologia

Checklist:

```text
repositório GitHub identificado
branch principal definida
PRs relevantes documentados
arquitetura atual documentada
topologia cloud documentada
ambientes documentados
processo de deploy documentado
rollback documentado ou planejado
```

Evidências esperadas:

```text
link do repositório
histórico de commits
PRs relevantes
lista de dependências
comandos de build
último build válido
```

---

## 5. Banco de dados e segurança

Checklist:

```text
mapa inicial de tabelas criado
dicionário de dados iniciado
RPCs/functions inventariadas ou planejadas
RLS/policies a validar
campos sensíveis classificados
modelo multi-tenant documentado
gestão de permissões documentada
```

Evidências esperadas:

```text
inventário read-only do Supabase
lista de migrations
lista de RPCs críticas
policies e grants relevantes
relatório de drift, se houver
```

---

## 6. Infraestrutura e operação

Checklist:

```text
GitHub documentado
Vercel documentado
Supabase documentado
OpenAI/ChatGPT documentado
observabilidade planejada
runbook de incidentes criado
suporte N1/N2/N3 definido
backup/restore a validar
```

Evidências esperadas:

```text
projetos cloud reais
variáveis de ambiente mapeadas sem expor segredo
logs disponíveis
ferramentas de uptime/erro definidas
plano de contingência
```

---

## 7. Comercial e monetização

Checklist:

```text
modelo SaaS definido
planos comerciais desenhados
serviços recorrentes listados
setup de implantação definido
métricas SaaS listadas
proposta comercial base criada
precificação a validar
```

Evidências esperadas:

```text
tabela de planos
calculadora de custo/margem
proposta comercial padrão
estimativa de MRR/ARR
pipeline ou clientes pilotos, se houver
```

---

## 8. Financeiro, fiscal e jurídico

Checklist:

```text
custos operacionais mapeados
modelo financeiro iniciado
checklist fiscal criado
pontos para contador documentados
pontos jurídicos documentados
estrutura societária a definir
propriedade intelectual a formalizar
```

Evidências esperadas:

```text
custos mensais atuais
contratos ou minutas
termos de uso
política de privacidade
validação contábil futura
acordo de sócios, se aplicável
```

---

## 9. Propriedade intelectual

Validar:

```text
quem é dono do código
quem é dono da marca
quem é dono dos domínios
quem administra GitHub
quem administra Vercel
quem administra Supabase
quem administra APIs externas
licenças de bibliotecas utilizadas
condições para entrada de sócio
condições para venda parcial ou total
```

---

## 10. Riscos conhecidos

| Risco | Mitigação |
|---|---|
| documentação incompleta | criar pacote documental progressivo |
| drift GitHub x Supabase | executar preflight read-only |
| ausência de observabilidade | implantar uptime/logs/alertas |
| custo cloud/IA sem controle | medir por cliente/módulo |
| dependência de conhecimento do fundador | documentação e runbooks |
| questões fiscais indefinidas | validar com contador |
| LGPD incompleta | validar com assessoria jurídica |

---

## 11. Critério de pronto para apresentação

O FECH.AI estará minimamente pronto para apresentação profissional quando tiver:

```text
resumo executivo
arquitetura atual
topologia cloud
modelo SaaS
planos comerciais
estrutura financeira
mapa de banco inicial
segurança multitenant
observabilidade planejada
runbook de suporte
due diligence preenchida
roadmap priorizado
```

---

## 12. Próximo passo

Preencher este checklist com evidências reais e classificar cada item como:

```text
pronto
parcial
pendente
bloqueado
não aplicável
```
