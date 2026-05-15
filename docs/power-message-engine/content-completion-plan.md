# FECH.AI — PME Content Completion Plan

Status: plano de execucao  
Escopo: completar conteudo da PME antes de persistencia e antes de substituicao da central atual.  
Banco: nenhuma alteracao nesta etapa.  
Discador/Acelerador: nenhuma alteracao nesta etapa.

---

## 1. Decisao de produto

A PME nao deve substituir a Central de Mensagens atual de forma abrupta.

Caminho aprovado:

```txt
1. Completar todos os scripts, templates e cadencias
2. Remover placeholders visuais/conceituais
3. Validar conteudo comercialmente
4. Persistir em Supabase com empresa_id
5. Rodar em paralelo com o fluxo atual
6. Integrar ao Discador e Oferta Ativa/Acelerador
7. Promover PME como central oficial
8. Manter fluxo antigo como fallback por periodo controlado
9. Desativar legado apenas apos validacao
```

Regra de ouro:

```txt
A PME primeiro prova que e melhor, mais segura e mais rastreavel. Depois vira oficial.
```

---

## 2. Estado atual verificado no codigo

Arquivos principais:

```txt
src/components/PowerMessageEngineAdmin.jsx
src/components/pme/pmeSeedTemplates.js
src/components/pme/pmeCurrentOperationSeeds.js
src/components/pme/pmeCallScriptSeeds.js
src/components/pme/pmeCadenceSeeds.js
src/components/pme/PMEWhatsappTemplatesPanel.jsx
src/components/pme/PMECallScriptsPanel.jsx
src/components/pme/PMECadencesPanel.jsx
src/components/pme/PMEScopeNotice.jsx
```

Modulo administrativo existente:

```txt
PowerMessageEngineAdmin.jsx
```

Abas atuais:

```txt
Visao Geral
Templates WhatsApp
Templates E-mail
Scripts de Ligacao
Cadencias
Governanca
Historico
```

---

## 3. Status por modulo

### 3.1 Templates WhatsApp

Status atual:

```txt
Seed frontend conectado
Prioridade atual: lista_fria e visitou_plantao
Meta visual: 10 templates por tipo de lead x fase
```

Tipos de lead definidos:

```txt
visitou_plantao
lista_fria
lista_quente
lead_quente
```

Fases definidas:

```txt
primeira_mensagem
segunda_mensagem
terceira_mensagem
mensagem_final
```

Operacao atual prioritaria:

```txt
lista_fria / lista comprada
visitou_plantao / lista quente presencial
```

Decisao:

```txt
Validar e refinar todos os textos de lista_fria e visitou_plantao antes de expandir para Meta/Google.
```

---

### 3.2 Scripts de Ligacao

Status atual:

```txt
Seed frontend conectado
```

Scripts existentes no seed:

```txt
lista_fria — abertura com permissao
lista_fria — triagem objetiva
visitou_plantao — retomada consultiva
visitou_plantao — foco em decisao
```

Estrutura ja utilizada:

```txt
opening
context
firstQuestion
qualification
commercialHook
objections
closing
feedbackOptions
```

Lacuna:

```txt
Ainda precisamos ampliar os scripts por cenario, principalmente objeções e contexto de ligacao.
```

---

### 3.3 Cadencias

Status atual:

```txt
Seed frontend conectado
```

Cadencias existentes:

```txt
lista_fria / comprada — permission-based
visitou_plantao — pos-visita consultiva
```

Cada cadencia ja possui:

```txt
leadType
objective
riskLevel
recommendedMode
guardrails
stopOnFeedbacks
pauseOnFeedbacks
steps
```

Lacuna:

```txt
Ainda falta transformar essas cadencias em regras operacionais persistidas por lead.
```

Isso fica para a fase de banco, nao agora.

---

### 3.4 Templates E-mail

Status atual:

```txt
Placeholder planejado
```

Nao existe biblioteca real de e-mail ainda.

Precisamos criar:

```txt
Apresentacao inicial
Envio de material
Pos-visita
Retomada
Simulacao/proposta
Documentacao
Ultima tentativa elegante
```

Meta inicial recomendada:

```txt
3 a 5 variacoes por cenario
```

E-mail nao precisa da mesma quantidade de variacoes do WhatsApp na v1.

---

### 3.5 Governanca

Status atual:

```txt
Conceitual/visual
```

Regras ja exibidas ou planejadas:

```txt
Sem envio automatico nesta versao
Sem alteracao em banco/RPC/RLS nesta fase
Sem disparo massivo de WhatsApp
Configurar primeiro, operar depois
Opt-out bloqueia novas sugestoes
Template inativo nunca pode ser sugerido
Corretor consome; gestor configura
```

Lacuna:

```txt
Ainda nao existe enforcement persistido dessas regras em banco.
```

---

### 3.6 Historico

Status atual:

```txt
Placeholder planejado
```

Futuro historico deve registrar:

```txt
lead
corretor
empresa
template usado
script usado
cadencia
fase
canal
status: sugerido, copiado, enviado_manual, ligado, ignorado, falhou
feedback posterior
metadata
```

Lacuna:

```txt
Depende das tabelas pme_message_usage e pme_lead_message_state.
```

---

## 4. Conteudo que precisa ser fechado antes do banco

### 4.1 WhatsApp — lista_fria

Necessario validar/refinar:

```txt
primeira_mensagem — 10 variacoes
segunda_mensagem — 10 variacoes
terceira_mensagem — 10 variacoes
mensagem_final — 10 variacoes
```

Pontos de qualidade:

```txt
permission-based
sem parecer spam
pergunta simples
saida clara
respeito ao opt-out
sem promessa falsa
sem tom robotico
```

---

### 4.2 WhatsApp — visitou_plantao

Necessario validar/refinar:

```txt
primeira_mensagem — 10 variacoes
segunda_mensagem — 10 variacoes
terceira_mensagem — 10 variacoes
mensagem_final — 10 variacoes
```

Pontos de qualidade:

```txt
retomar contexto da visita
perguntar percepcao
identificar objecao
oferecer simulacao/nova visita
nao tratar como lista fria
encerrar com elegancia
```

---

### 4.3 Scripts de Ligacao — lista_fria

Criar/ampliar scripts para cenarios:

```txt
abordagem permission-based
cliente nao lembra cadastro
cliente pergunta origem do contato
cliente esta sem tempo
cliente nao quer contato
cliente demonstra curiosidade
cliente pergunta preco
cliente ja comprou imovel
cliente investidor
cliente pede retorno futuro
```

---

### 4.4 Scripts de Ligacao — visitou_plantao

Criar/ampliar scripts para cenarios:

```txt
pos-visita consultivo
retomada de objecao
comparando com outro projeto
achou caro
gostou mas precisa falar com familia
pediu simulacao
sumiu depois da visita
quer negociar
quer visitar novamente
esperando tabela/condicao
```

---

### 4.5 E-mail

Criar biblioteca inicial:

```txt
primeiro contato formal
envio de material
pos-visita
retomada
simulacao/proposta
documentacao
ultima tentativa elegante
```

Cada e-mail deve ter:

```txt
subject
preheader opcional
body
cta
variaveis
contexto recomendado
leadType recomendado
fase recomendada
```

---

## 5. Variaveis oficiais da PME v1

Variaveis permitidas para templates:

```txt
{{nome_lead}}
{{nome_corretor}}
{{empresa}}
{{empreendimento}}
{{bairro}}
{{telefone_corretor}}
{{link_whatsapp}}
{{link_material}}
{{data_retorno}}
{{perfil_imovel}}
{{valor_referencia}}
```

Regra:

```txt
Nao criar variavel solta sem documentar aqui.
```

---

## 6. Criterio para remover placeholders

A PME so deve perder o status de placeholder quando:

```txt
[ ] WhatsApp lista_fria validado
[ ] WhatsApp visitou_plantao validado
[ ] Scripts lista_fria ampliados
[ ] Scripts visitou_plantao ampliados
[ ] E-mails criados
[ ] Cadencias revisadas
[ ] Governanca textual validada
[ ] Plano de historico/ponte com registrar_mensagem criado
```

---

## 7. Criterio para persistencia Supabase

Somente depois da etapa de conteudo:

```txt
[ ] Revisar supabase-migration-draft.sql
[ ] Confirmar empresa_id como isolamento
[ ] Criar plano de seeds por empresa
[ ] Definir ponte com registrar_mensagem
[ ] Preparar migration real sem rollback
[ ] Validar RLS em ambiente controlado
```

---

## 8. Criterio para substituir a central atual

A central atual somente deve ser substituida quando:

```txt
[ ] PME gravar historico real
[ ] PME respeitar opt-out
[ ] PME controlar cadencia por lead
[ ] PME sugerir template sem repetir indevidamente
[ ] PME integrada ao Discador/Acelerador
[ ] Fluxo atual continuar como fallback
[ ] Gestor conseguir auditar uso
[ ] Corretor conseguir usar sem labirinto
```

---

## 9. Proxima tarefa recomendada

Executar a revisao de conteudo na seguinte ordem:

```txt
1. WhatsApp lista_fria
2. WhatsApp visitou_plantao
3. Scripts de ligacao lista_fria
4. Scripts de ligacao visitou_plantao
5. Templates de e-mail
6. Cadencias finais
7. Ponte registrar_mensagem
```

Motivo:

```txt
A operacao real atual trabalha listas compradas/frias e pessoas que visitaram plantao. Meta/Google entram depois.
```
