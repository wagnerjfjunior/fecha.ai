# PME — Empreendimentos — Contrato Técnico de Implementação v1

**Projeto:** FECH.AI  
**Módulo:** PME — Power Message Engine  
**Área:** Central de Mensagens / Oferta Ativa / Acelerador / Discador  
**Contrato:** Implementação do módulo contextual Empreendimentos  
**Primeiro empreendimento:** Château Jardin  
**Canal alvo da primeira implementação:** Assistente PME do Discador  
**Fase:** Gate 2 — contrato técnico antes de patch operacional  
**Risco do contrato:** R0 — Documental  
**Risco estimado da implementação futura:** R2 — Frontend assistido, sem banco  
**Branch:** `feature/pme-empreendimentos-implementation-contract-v1`  
**Base:** `main` após merge do PR #31

---

## 1. Objetivo

Este documento define o contrato técnico para implementar o módulo contextual **Empreendimentos** na PME, reutilizando a estrutura já existente e sem substituir a Central de Mensagens, Oferta Ativa, Acelerador, Discador ou qualquer lógica atual.

A implementação futura deve permitir que o corretor configure o atendimento nesta ordem:

```text
1. Grupo de mensagens
2. Empreendimento
3. Canal
4. Situação do lead
5. Fase da cadência
6. Objetivo da abordagem
```

A etapa **Evento/Campanha** não deve ser uma dimensão estrutural obrigatória nesta primeira implementação. Situações específicas, como **Convite para lançamento**, pertencem à etapa **Situação do lead**.

---

## 2. Decisão canônica

A PME existente será preservada.

O upgrade adiciona uma camada de contexto comercial chamada **Empreendimentos**, que deve ser escolhida antes do canal e da situação do lead.

A seleção do empreendimento não substitui os conceitos atuais da PME. Ela apenas contextualiza a mensagem sugerida.

### 2.1 Ordem canônica corrigida

```text
1. Grupo de mensagens
   - Geral / Base atual
   - Empreendimentos

2. Empreendimento
   - Château Jardin
   - Outros empreendimentos futuros

3. Canal
   - Ligação
   - WhatsApp
   - E-mail

4. Situação do lead
   - Primeiro contato
   - Convite para lançamento
   - Pediu plantas
   - Pediu valores
   - Pediu material
   - Já conhece o projeto
   - Visitou plantão
   - Pós-visita
   - Quer levar família
   - Está comparando
   - Sem resposta

5. Fase da cadência
   - Primeira mensagem
   - Segunda mensagem
   - Terceira mensagem
   - Mensagem final

6. Objetivo da abordagem
   - Abertura
   - Envio de informação
   - Convite para visita
   - Qualificação
   - Retorno
   - Objeção
   - Encerramento
```

### 2.2 O que não entra como dimensão estrutural nesta fase

Não criar uma etapa fixa chamada:

```text
Evento / Campanha
```

Não criar chave estrutural excessivamente específica como:

```text
chateau_jardin_lancamento_2026_05_30
```

Usar:

```text
empreendimento = chateau_jardin
situacao_lead = convite_lancamento
```

A data do lançamento pode aparecer como conteúdo contextual da mensagem, mas não deve ser uma chave estrutural obrigatória do fluxo.

---

## 3. Fonte da verdade mapeada

### 3.1 Assistente PME do Discador

Arquivo mapeado:

```text
public/pme-call-assistant-beta.js
```

Estado atual identificado:

- é carregado no frontend como assistente beta da PME;
- opera em modo assistido;
- não envia mensagem automaticamente;
- abre WhatsApp com texto pronto;
- abre `mailto:` para e-mail;
- copia fala e aciona `tel:` para ligação;
- usa estado local com `context`, `channel`, `approach`, `variant` e poderes do discador;
- renderiza atualmente os passos:
  - origem do lead;
  - canal;
  - situação do cliente;
  - execução do contato.

### 3.2 PME Admin

Arquivos mapeados:

```text
src/components/PowerMessageEngineAdmin.jsx
src/components/pme/PMEWhatsappTemplatesPanel.jsx
src/components/pme/PMECallScriptsPanel.jsx
src/components/pme/PMECadencesPanel.jsx
src/components/pme/pmeSeedTemplates.js
src/components/pme/pmeCurrentOperationSeeds.js
src/components/pme/pmeCallScriptSeeds.js
src/components/pme/pmeCadenceSeeds.js
```

Estado atual:

- a PME Admin já existe;
- contém abas de templates, scripts, cadências, governança e histórico;
- usa seeds frontend/documentais;
- não deve ser alterada nesta primeira implementação operacional do módulo Empreendimentos.

### 3.3 Aceleração Operacional

Arquivos mapeados:

```text
src/components/AceleracaoOperacional.jsx
src/services/aceleracaoOperacionalService.js
```

Estado atual:

- usa canais WhatsApp, ligação e e-mail;
- possui mensagens inline simples;
- conversa com RPCs como `proximo_lead` e `registrar_feedback` via service bridge;
- não deve ser alterada nesta primeira implementação, para evitar aumentar o risco.

---

## 4. Escopo da implementação futura R2

### 4.1 Dentro do escopo

Primeira implementação operacional assistida no arquivo:

```text
public/pme-call-assistant-beta.js
```

Escopo:

1. Adicionar seleção de **Grupo de mensagens**.
2. Adicionar seleção de **Empreendimento** quando grupo for `empreendimentos`.
3. Manter o fluxo atual quando grupo for `geral` ou base atual.
4. Inserir **Château Jardin** como primeiro empreendimento.
5. Usar `convite_lancamento` como situação do lead.
6. Manter canais atuais: ligação, WhatsApp e e-mail.
7. Exibir mensagem sugerida baseada em:
   - grupo;
   - empreendimento;
   - canal;
   - situação do lead;
   - variante.
8. Aplicar assinatura dinâmica obrigatória em WhatsApp e e-mail.
9. Aplicar fechamento verbal nos scripts de ligação.
10. Bloquear ou impedir termos proibidos no catálogo ativo.
11. Preservar modo assistido:
    - WhatsApp abre link com texto pronto;
    - E-mail abre `mailto:`;
    - Ligação copia fala e aciona `tel:` quando possível.
12. Não registrar feedback automaticamente.
13. Não criar disparo automático.

### 4.2 Fora do escopo

Não alterar:

- Supabase;
- migrations;
- RLS;
- grants;
- RPCs;
- seed de banco;
- Central atual;
- AceleracaoOperacional.jsx;
- aceleracaoOperacionalService.js;
- PowerMessageEngineAdmin.jsx;
- componentes de PME Admin;
- auth;
- tenant/empresa vindo do frontend como verdade soberana;
- MesaCliente;
- Worker;
- Make;
- n8n;
- motor financeiro;
- parser.

---

## 5. Modelo lógico frontend-only

### 5.1 Grupos

```js
const MESSAGE_GROUPS = {
  geral: {
    label: 'Geral / Base atual'
  },
  empreendimentos: {
    label: 'Empreendimentos'
  }
};
```

### 5.2 Empreendimentos

```js
const DEVELOPMENTS = {
  chateau_jardin: {
    label: 'Château Jardin',
    group: 'empreendimentos',
    address: 'Rua Ministro Nelson Hungria, 400'
  }
};
```

### 5.3 Situações de lead para Empreendimentos

```js
const DEVELOPMENT_APPROACHES = {
  primeiro_contato: 'Primeiro contato',
  convite_lancamento: 'Convite para lançamento',
  pediu_plantas: 'Pediu plantas',
  pediu_valores: 'Pediu valores',
  pediu_material: 'Pediu material',
  ja_conhece_projeto: 'Já conhece o projeto',
  visitou_plantao: 'Visitou plantão',
  pos_visita: 'Pós-visita',
  quer_levar_familia: 'Quer levar família',
  comparando: 'Está comparando',
  sem_resposta: 'Sem resposta'
};
```

### 5.4 Catálogo de mensagens

Não usar chave com data.

Modelo recomendado:

```js
const DEVELOPMENT_MESSAGES = {
  chateau_jardin: {
    whatsapp: {
      convite_lancamento: []
    },
    ligacao: {
      convite_lancamento: []
    },
    email: {
      convite_lancamento: []
    }
  }
};
```

A data do lançamento, quando necessária, entra no texto da mensagem, não na chave do objeto.

---

## 6. Dados comerciais permitidos — Château Jardin

Pode usar:

- Château Jardin;
- lançamento em 30/05/2026 como dado textual contextual;
- Rua Ministro Nelson Hungria, 400;
- novo eixo Cidade Jardim;
- Tegra + Exto;
- projeto internacional EDSA;
- arquitetura clássica com leitura contemporânea;
- inspiração na elegância dos jardins franceses;
- conceito de refúgio urbano;
- alto padrão;
- 185 m², 215 m², 248 m² e 355 m²;
- quadra de tênis de saibro;
- quadra de padel;
- piscina coberta;
- wellness;
- lazer de perfil private club;
- concierge;
- courrier;
- delivery room;
- segurança e portaria;
- plantas amplas;
- atendimento por horário.

---

## 7. Termos bloqueados

As mensagens não devem conter:

```text
últimas unidades
condição exclusiva
desconto de lançamento
tabela especial garantida
diretoria liberou
reserva garantida
preço fechado
melhor condição só amanhã
```

Também evitar:

```text
imperdível
só hoje
corra
não perca
oportunidade única
tenho acesso especial
consigo algo por fora
garantido
```

Urgência permitida:

```text
lançamento amanhã
evento de lançamento
atendimentos por horário
apresentação das plantas
conhecer o projeto desde o início
avaliar as opções iniciais
organizar uma visita
apresentar com calma
verificar melhor horário
```

---

## 8. Assinatura dinâmica obrigatória

WhatsApp e e-mail devem terminar com:

```text
{{nome_corretor}}
{{telefone_corretor}}
WhatsApp: {{link_whatsapp_corretor}}

Ao chegar, por gentileza, solicite por {{nome_corretor}} na recepção para que eu possa te receber pessoalmente.
```

Scripts de ligação devem fechar com:

```text
O evento será na Rua Ministro Nelson Hungria, 400. Quando chegar, por gentileza, solicite por {{nome_corretor}} na recepção para que eu possa te receber pessoalmente e apresentar o projeto com calma.
```

---

## 9. Matriz DML da implementação R2

| Operação | Status |
|---|---:|
| SELECT | Não |
| INSERT | Não |
| UPDATE | Não |
| DELETE | Não |
| RPC | Não |
| Migration | Não |
| RLS/Policy/Grant | Não |
| Auth | Não |
| Frontend | Sim |
| Seed frontend/local | Sim |
| Envio automático | Não |

---

## 10. Arquivos autorizados para a próxima fase

### 10.1 Patch operacional R2

```text
public/pme-call-assistant-beta.js
```

### 10.2 Documentação/changelog

```text
docs/power-message-engine/pme-empreendimentos-implementation-contract-v1.md
docs/power-message-engine/pme-empreendimentos-implementation-changelog-v1.md
```

### 10.3 Arquivos não autorizados nesta fase

```text
src/components/AceleracaoOperacional.jsx
src/services/aceleracaoOperacionalService.js
src/components/PowerMessageEngineAdmin.jsx
src/components/pme/*
supabase/migrations/*
```

---

## 11. Testes obrigatórios após patch

### 11.1 Teste de fluxo geral preservado

Cenário:

```text
Grupo = Geral / Base atual
```

Esperado:

- fluxo antigo continua funcionando;
- origem/contexto atual ainda aparece;
- canal atual ainda funciona;
- situação atual ainda funciona;
- mensagem sugerida é gerada como antes.

### 11.2 Teste de fluxo Empreendimentos

Cenário:

```text
Grupo = Empreendimentos
Empreendimento = Château Jardin
Canal = WhatsApp
Situação = Convite para lançamento
```

Esperado:

- mensagem do Château Jardin é exibida;
- texto contém Rua Ministro Nelson Hungria, 400;
- texto pode conter 30/05/2026 como dado contextual;
- texto contém metragens 185 m², 215 m², 248 m² e/ou 355 m² em variações aplicáveis;
- texto contém assinatura dinâmica;
- botão executar abre WhatsApp com revisão manual.

### 11.3 Teste de e-mail

Cenário:

```text
Grupo = Empreendimentos
Empreendimento = Château Jardin
Canal = E-mail
Situação = Convite para lançamento
```

Esperado:

- mailto é preparado;
- assunto e corpo são coerentes;
- não há emoji;
- assinatura aparece.

### 11.4 Teste de ligação

Cenário:

```text
Grupo = Empreendimentos
Empreendimento = Château Jardin
Canal = Ligação
Situação = Convite para lançamento
```

Esperado:

- fala é exibida;
- fechamento orienta solicitar o corretor na recepção;
- execução copia fala e aciona `tel:` quando telefone existir.

### 11.5 Teste de compliance textual

Buscar no arquivo ativo os termos:

```text
últimas unidades
condição exclusiva
desconto de lançamento
tabela especial garantida
diretoria liberou
reserva garantida
preço fechado
melhor condição só amanhã
```

Esperado:

- nenhum desses termos aparece em mensagens ativas do Château Jardin;
- se aparecerem em lista de bloqueio documental/compliance, não podem aparecer como copy enviada.

### 11.6 Teste de build

Executar:

```bash
npm run build
```

Esperado:

- build concluído sem erro.

---

## 12. Rollback

Como a implementação futura será frontend-only:

```text
Rollback = revert do commit da branch.
```

Não haverá:

- rollback de banco;
- restauração de dados;
- reversão de migration;
- alteração em RLS;
- alteração em RPC.

---

## 13. Critério de aceite

A implementação futura será aceita quando:

1. Grupo Empreendimentos aparecer no assistente PME do Discador.
2. Château Jardin aparecer como empreendimento.
3. Não houver etapa estrutural fixa de Evento/Campanha.
4. Convite para lançamento aparecer como situação do lead.
5. WhatsApp, ligação e e-mail funcionarem em modo assistido.
6. A mensagem mudar conforme canal + situação.
7. A assinatura dinâmica aparecer em WhatsApp/e-mail.
8. O fechamento verbal aparecer em ligação.
9. Nenhum termo bloqueado aparecer como copy ativa.
10. O fluxo antigo continuar funcionando.
11. Não houver alteração de banco, RLS, RPC, seed de banco ou auth.
12. Build passar.

---

## 14. Critério de bloqueio

Bloquear patch se:

1. A alteração exigir Supabase.
2. A alteração exigir RPC.
3. A alteração exigir RLS/grants/auth.
4. O fluxo antigo quebrar.
5. A implementação exigir persistência de feedback.
6. Algum termo bloqueado aparecer como mensagem ativa.
7. A solução tentar enviar WhatsApp automaticamente.
8. Houver hardcoded de tenant, empresa, lead real ou corretor real.
9. Houver necessidade de alterar arquivos fora do escopo sem novo contrato.

---

## 15. Próximo passo após este contrato

Após aprovação deste contrato, abrir a próxima fase:

```text
Gate 3 — Patch R2 frontend assistido
```

Patch previsto:

```text
public/pme-call-assistant-beta.js
```

Com documentação de changelog:

```text
docs/power-message-engine/pme-empreendimentos-implementation-changelog-v1.md
```

Nenhum outro arquivo deve ser alterado sem nova autorização.
