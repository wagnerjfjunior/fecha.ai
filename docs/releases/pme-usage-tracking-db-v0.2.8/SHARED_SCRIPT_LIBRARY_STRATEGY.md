# SHARED_SCRIPT_LIBRARY_STRATEGY — PME / FECH.AI

## 1. Objetivo

Registrar a estratégia central do FECH.AI para criação de uma grande base compartilhada de abordagens, scripts, templates, objeções e técnicas comerciais aplicáveis ao Discador Flow AI / PME.

Este documento complementa a árvore de tenancy/RBAC da v0.2.8 e formaliza o diferencial competitivo do produto: transformar o FECH.AI em uma plataforma que não apenas organiza leads, mas também orienta o corretor com repertório comercial validado, reutilizável e melhorável ao longo do tempo.

---

## 2. Tese de produto

O diferencial do FECH.AI não é apenas possuir discador, CRM, feedback ou IA.

O diferencial é criar um **motor comercial de repertório**, onde cada empresa, gestor e corretor pode acessar uma biblioteca estruturada de abordagens para diferentes momentos da venda.

A plataforma deve entregar:

- scripts de ligação;
- mensagens de WhatsApp;
- modelos de e-mail;
- respostas para objeções;
- argumentos de valor;
- técnicas de cold call;
- técnicas de retomada;
- scripts de pós-visita;
- convites para plantão/visita;
- abordagens por origem de lead;
- abordagens por fase do funil;
- conteúdos aprovados por empresa, time ou plataforma.

---

## 3. Base compartilhada como ativo da plataforma

O FECH.AI deve possuir uma base global de conhecimento comercial que possa beneficiar todas as empresas da plataforma.

Essa base pode conter conteúdos como:

```txt
- abordagem para lista fria;
- abordagem para lead de redes sociais;
- abordagem para cliente que já visitou;
- abordagem para objeção de preço;
- abordagem para objeção de entrada;
- abordagem para cliente sem resposta;
- abordagem de retorno;
- abordagem de convite;
- abordagem pós-ligação;
- abordagem de encerramento elegante;
- técnicas de argumentação por perfil de cliente;
- mensagens de retomada para leads antigos;
- scripts de ligação com abertura, diagnóstico e próximo passo.
```

Essa biblioteca deve funcionar como um repositório vivo, onde os scripts mais úteis podem ser promovidos, reaproveitados e refinados.

---

## 4. Escopos da biblioteca

A biblioteca não deve ser uma tabela plana sem governança.

Cada item precisa ter escopo de visibilidade.

Escopos recomendados:

```txt
platform_global
platform_curated
tenant_global
empresa_global
team_only
user_private
```

### 4.1 platform_global

Conteúdo geral da plataforma FECH.AI.

Criado ou aprovado por Root/Admin Global.

Pode ser disponibilizado para todas as empresas, conforme plano e módulo contratado.

Exemplos:

- script padrão de cold call;
- abordagem básica para WhatsApp;
- objeção de preço genérica;
- objeção de entrada genérica;
- encerramento educado;
- convite para visita.

### 4.2 platform_curated

Conteúdo promovido para biblioteca global após análise de uso, performance e segurança.

Pode nascer de:

- script criado pela plataforma;
- script criado por uma empresa e autorizado para generalização;
- resposta de IA muito utilizada;
- abordagem validada por métricas de uso e feedback.

Importante:

- nunca promover conteúdo privado automaticamente;
- remover dados da empresa, produto, lead, corretor, preço ou qualquer informação sensível;
- generalizar o texto antes de torná-lo reutilizável.

### 4.3 tenant_global

Conteúdo oficial de um tenant.

Criado por Admin Local.

Visível para empresas/equipes do tenant conforme regra contratual.

### 4.4 empresa_global

Conteúdo oficial de uma empresa.

Criado por Admin Local ou Admin da Empresa.

Visível para todos os times/corretores daquela empresa.

### 4.5 team_only

Conteúdo de uma equipe/carteira.

Criado por Gestor, Coordenador ou Admin da Empresa.

Visível somente para os usuários vinculados ao time.

### 4.6 user_private

Conteúdo pessoal do corretor.

Criado por usuário operacional.

Visível somente ao próprio usuário, salvo aprovação futura explícita para compartilhamento.

---

## 5. Separação entre conteúdo global e conteúdo privado

A biblioteca compartilhada deve respeitar uma regra fundamental:

> O FECH.AI pode oferecer uma base global para todas as empresas, mas não pode transformar conteúdo privado de uma empresa em conteúdo global sem curadoria, autorização e anonimização.

Isso protege:

- estratégia comercial do cliente;
- dados sensíveis;
- LGPD;
- competitividade entre empresas;
- confiança na plataforma.

---

## 6. Pipeline de curadoria recomendado

Um script ou mensagem pode seguir este ciclo:

```txt
1. Criado como template interno
2. Utilizado por corretores
3. Recebe eventos de uso
4. Recebe avaliação de utilidade
5. É associado a feedbacks/resultados
6. É identificado como potencialmente útil
7. Passa por anonimização/generalização
8. Vai para fila de curadoria
9. É aprovado por Admin Global/Curadoria FECH.AI
10. Vira conteúdo platform_curated
```

Esse ciclo impede que o sistema vire um depósito de mensagem repetida e sem controle.

---

## 7. Relação com IA

A IA deve ser usada para:

- melhorar texto escolhido pelo corretor;
- adaptar mensagem ao canal;
- adaptar mensagem à origem do lead;
- adaptar mensagem à situação comercial;
- sugerir variações;
- resumir técnicas de abordagem;
- transformar um script específico em modelo genérico;
- propor versão curada sem dados sensíveis.

A IA não deve:

- publicar conteúdo global automaticamente;
- misturar dados entre empresas;
- salvar texto completo sem regra clara;
- inventar preço, desconto, condição ou disponibilidade;
- substituir revisão humana em conteúdos globais.

---

## 8. Métricas de utilidade da biblioteca

A v0.2.7/v0.2.8 deve preparar a base para medir utilidade.

Métricas futuras recomendadas:

```txt
total_visualizacoes
total_usos
total_execucoes_ligacao
total_execucoes_whatsapp
total_execucoes_email
total_melhorias_ia
total_feedbacks_associados
score_utilidade_medio
taxa_uso_por_canal
taxa_uso_por_origem_lead
taxa_uso_por_situacao
taxa_avanco_pos_uso
taxa_agendamento_pos_uso
taxa_perda_pos_uso
```

Importante:

- no MVP, não associar resultado comercial de forma automática sem validação de regra;
- no início, priorizar evento de uso, hash, fonte e contexto;
- a associação com feedback deve ser feita com cuidado para evitar falsa causalidade.

---

## 9. Modelo conceitual de conteúdo

Tabela futura possível:

```txt
pme_script_library
├── id
├── tenant_id
├── empresa_id
├── team_id
├── created_by_user_id
├── visibility_scope
├── curation_status
├── title
├── description
├── origin_context
├── channel
├── approach
├── script_type
├── content_hash
├── content_body_encrypted / content_body, se aprovado
├── tags
├── is_active
├── total_uses
├── utility_score_avg
├── created_at
├── updated_at
└── approved_at / approved_by, se curado
```

Status de curadoria sugeridos:

```txt
draft
active
needs_review
candidate_for_curation
curated
archived
rejected
```

---

## 10. Modelo conceitual de uso

Eventos de uso devem registrar contexto sem depender de texto completo.

Tabela base da v0.2.8:

```txt
pme_script_usage_events
├── id
├── tenant_id
├── empresa_id
├── team_id
├── user_id
├── lead_id
├── script_id
├── event_type
├── context
├── channel
├── approach
├── script_source
├── script_scope
├── script_text_hash
├── ai_used
├── ai_attempt
├── execution_target
├── utility_score
├── metadata
└── created_at
```

---

## 11. Benefício para empresas clientes

Todas as empresas devem ser contempladas pela base global do FECH.AI, respeitando plano, módulo e permissões.

Benefícios:

- corretor novo começa com repertório;
- gestor consegue padronizar abordagem;
- empresa reduz improviso;
- treinamento fica embutido no fluxo;
- IA melhora o texto no contexto certo;
- scripts bons são reaproveitados;
- scripts ruins perdem relevância;
- operação aprende com o uso real.

---

## 12. Benefício para o FECH.AI

A biblioteca compartilhada cria vantagem competitiva defensável.

Ao longo do tempo, o FECH.AI passa a ter:

- base proprietária de abordagens comerciais;
- inteligência por canal;
- inteligência por origem de lead;
- inteligência por objeção;
- inteligência por perfil operacional;
- menor dependência de geração de IA em tempo real;
- possibilidade de planos pagos por biblioteca premium;
- possibilidade de módulo IA com cache e reutilização;
- melhoria contínua baseada em uso, não em achismo.

---

## 13. Módulos comerciais futuros

A biblioteca pode permitir monetização por módulos:

```txt
PME Basic
- scripts globais básicos;
- modelos por canal;
- abordagem inicial.

PME Pro
- IA contextual;
- variações por situação;
- scripts por origem de lead;
- tracking de uso;
- score de utilidade.

PME Enterprise
- biblioteca própria da empresa;
- curadoria interna;
- métricas por equipe;
- aprovação de templates;
- biblioteca premium FECH.AI;
- governança multiempresa/multitime.
```

---

## 14. Regras de segurança e governança

Regras obrigatórias:

- não usar `service_role` no navegador;
- não usar `window.fetch` monkey patch global;
- não persistir texto completo sem aprovação específica;
- não compartilhar conteúdo privado sem autorização;
- não promover conteúdo para global sem curadoria;
- não gravar telefone/e-mail/nome completo em eventos de uso no MVP;
- resolver tenant/empresa/time no backend;
- aplicar RLS rigorosa;
- auditar ações de Root/Admin Global;
- permitir rollback sem quebrar atendimento.

---

## 15. Decisão técnica registrada

A base global de repertório é parte essencial do produto FECH.AI.

A estratégia correta é:

```txt
Base global FECH.AI → ajuda todas as empresas
Base do tenant → padroniza o grupo
Base da empresa → padroniza operação comercial
Base do time → adapta abordagem ao gestor/carteira
Base pessoal → permite produtividade individual
Tracking → mede uso e utilidade
Curadoria → transforma bons padrões em biblioteca reutilizável
IA → adapta e melhora, mas não publica sozinha
```

Conclusão:

> O FECH.AI deve evoluir de discador/CRM para um motor de repertório comercial orientado por contexto, IA, governança e dados reais de uso.
