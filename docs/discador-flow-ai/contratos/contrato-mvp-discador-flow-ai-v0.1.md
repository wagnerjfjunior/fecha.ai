# Contrato MVP — Discador Flow AI / PME v0.1

**Projeto:** FECH.AI  
**Módulo:** Discador Flow AI / PME — Power Message Engine  
**Status:** contrato inicial para implementação controlada  
**Branch de trabalho:** `feature/ccam-pme-mvp-v0.1`  
**Branch alvo futura:** `main`, somente via PR validado  
**PR:** #20  
**Protocolo obrigatório:** Protocolo Mestre FECH.AI / MesaCliente v1.2  
**Classificação inicial:** R1/R2 para frontend isolado; R3/R4 se tocar Supabase, RPC, RLS, auth, tenant, billing ou dados pessoais.

---

## 1. Objetivo do MVP

Transformar a tela atual do discador em um **fluxo assistido de atendimento do corretor**, reduzindo confusão visual e aumentando velocidade operacional.

O MVP deve permitir que o corretor:

1. selecione a origem/situação do lead por badges;
2. escolha canal de atuação: WhatsApp, Ligação ou E-mail;
3. escolha o tipo de abordagem;
4. veja scripts e mensagens rápidas;
5. abra a mensagem em modal;
6. copie ou abra o canal adequado;
7. opcionalmente peça melhoria com IA;
8. registre feedback;
9. gere score operacional;
10. salve a resposta utilizada para análise e possível reaproveitamento.

---

## 2. Problemas observados

- No celular, o script de ligação está visualmente encavalado no canto esquerdo.
- Botões como `Lista fria` e `Pode mandar no WhatsApp` não estão funcionando corretamente.
- Há redundância entre ações de copiar, abrir WhatsApp e copiar fala.
- A PME aparece como uma seção solta, não como uma jornada operacional.
- A IA não está funcionando no fluxo atual.
- O corretor precisa de argumentos praticamente em tempo real, sem ficar caçando texto.

---

## 3. Diagnóstico inicial da IA

Arquivo HAR analisado indicou:

- `get_contagens_corretor` retornando `401 JWT expired`;
- `OPTIONS` da Edge Function `assistente-ai` retornando `200`;
- `POST` para `assistente-ai` aparecendo com status `0` no navegador.

Hipótese inicial: a IA falha por combinação de sessão expirada, ausência de tratamento claro de erro no frontend e possível falha de CORS/runtime/resposta na Edge Function.

Regra de MVP: **falha da IA nunca pode travar a operação manual da PME**.

---

## 4. Escopo do MVP

### Dentro do escopo

- Reorganização visual mobile-first do bloco PME/discador.
- Criação dos badges iniciais:
  - Lista fria;
  - Já visitou;
  - Redes Sociais;
  - Problemas;
  - Argumentações.
- Fluxo por canal:
  - WhatsApp;
  - Ligações;
  - E-mail.
- Tipos de abordagem:
  - Primeira abordagem;
  - Retorno;
  - Pós-ligação;
  - Convite;
  - Objeção de preço;
  - Objeção de entrada;
  - Sem resposta;
  - Fim de contato.
- Modal de mensagem/script selecionado.
- Botão único e claro por ação:
  - copiar texto;
  - abrir WhatsApp com texto;
  - copiar script de ligação;
  - gerar assunto/corpo de e-mail quando canal for E-mail.
- Melhoria assistida por IA mediante dica do corretor.
- Registro de resposta selecionada/utilizada para futura base de conhecimento.
- Score simples da interação.
- Associação entre nota, feedback e resposta utilizada.
- Registro documental de branch, main, release, rollback e checklist.

### Fora do escopo nesta primeira etapa

- Não alterar `registrar_feedback`, `proximo_lead`, `solicitar_lote` sem contrato próprio.
- Não alterar RLS, grants, policies ou auth.
- Não criar billing definitivo do módulo de IA.
- Não criar automação de envio em massa.
- Não enviar WhatsApp automaticamente.
- Não enviar e-mail automaticamente.
- Não expor `service_role` ou chave sensível no frontend.
- Não mexer no MesaCliente, parser, Worker ou Make/n8n.
- Não fazer merge direto em `main`.

---

## 5. Estratégia de IA no MVP

A IA entra como **copiloto de texto**, não como dona do fluxo.

No MVP, a IA deve:

- receber contexto mínimo necessário;
- usar nome do lead, telefone e situação somente quando permitido;
- respeitar tenant/empresa/perfil quando a camada de backend estiver implementada;
- retornar variações curtas, úteis e comerciais;
- nunca decidir feedback automaticamente;
- nunca enviar mensagem automaticamente;
- retornar erro tratável quando JWT estiver expirado;
- permitir fallback para texto base quando a Edge Function falhar.

### Modelo recomendado para MVP

Usar um modelo econômico e seguro para geração operacional curta, com fallback manual quando indisponível. A escolha final do modelo deve ficar em backend/configuração, nunca hardcoded no frontend.

---

## 6. IA como módulo SaaS pago

O acesso à IA será tratado como módulo comercial separado.

O MVP deve prever flags futuras:

- empresa possui módulo IA ativo;
- usuário tem permissão para usar IA;
- limite de uso por plano;
- contador de chamadas;
- cache/reaproveitamento de respostas;
- auditoria de respostas aceitas, editadas, rejeitadas e efetivamente utilizadas.

---

## 7. Base de respostas e reaproveitamento

Toda resposta usada deve poder virar dado para inteligência comercial.

Eventos mínimos:

- resposta visualizada;
- resposta copiada;
- WhatsApp aberto;
- e-mail preparado;
- script de ligação copiado;
- resposta melhorada por IA;
- resposta aceita;
- resposta editada;
- feedback final associado;
- score final.

Objetivo: identificar quais scripts convertem melhor por origem, canal, tipo de abordagem, corretor, empresa, empreendimento e feedback.

---

## 8. Governança de branch

Branch oficial desta entrega:

`feature/ccam-pme-mvp-v0.1`

Registro obrigatório:

`docs/branches/BRANCH_REGISTRY.md`

Regra: cada branch precisa ter objetivo, escopo, fora de escopo, rollback, status e condição de merge.

---

## 9. Governança de atualização para main

Arquivos obrigatórios:

- `docs/main/MAIN_UPDATE_REGISTRY.md`;
- `docs/main/MAIN_MERGE_CHECKLIST.md`;
- `docs/main/MAIN_ROLLBACK_LOG.md`;
- `docs/releases/ccam-pme-mvp-v0.1/RELEASE_NOTES.md`;
- `docs/releases/ccam-pme-mvp-v0.1/MERGE_PLAN.md`;
- `docs/releases/ccam-pme-mvp-v0.1/VALIDATION_REPORT.md`;
- `docs/releases/ccam-pme-mvp-v0.1/ROLLBACK_PLAN.md`;
- `docs/releases/ccam-pme-mvp-v0.1/POST_MERGE_CHECKLIST.md`.

Nada sobe para `main` sem passar pelo checklist.

---

## 10. Critérios de aceite

- Tela mobile não pode ter script encavalado.
- Badges devem ser clicáveis e mudar o contexto exibido.
- Cada ação deve ter função clara e não redundante.
- Corretor deve chegar a uma mensagem útil em poucos toques.
- IA deve ter estado explícito: disponível, indisponível, processando, erro ou sem permissão.
- Sem IA, o fluxo manual deve continuar funcionando.
- Nenhum dado sensível deve ser gravado ou enviado sem finalidade definida.
- Nenhum envio automático deve ocorrer no MVP.
- Deve existir caderno de testes antes do PR para `main`.

---

## 11. Critérios de bloqueio

Bloquear merge se ocorrer qualquer item abaixo:

- quebra do fluxo atual de feedback;
- exposição de chave de IA no frontend;
- `empresa_id` aceito do frontend como autoridade;
- chamada IA sem controle de permissão;
- alteração não aprovada em Supabase/RPC/RLS;
- componente mobile ilegível;
- botão que aparenta enviar mensagem automaticamente sem confirmação do usuário;
- ausência de fallback quando IA falhar;
- ausência de documentação do que foi alterado;
- PR sem checklist de main atualizado.

---

## 12. Estratégia de atualização para main

1. Trabalhar na branch `feature/ccam-pme-mvp-v0.1`.
2. Manter PR em modo draft enquanto houver risco funcional.
3. Validar diff.
4. Executar caderno de testes.
5. Registrar evidências.
6. Atualizar contrato se houver mudança de escopo.
7. Atualizar `MAIN_UPDATE_REGISTRY.md`.
8. Marcar PR pronto somente após PASS funcional.
9. Fazer merge somente com aprovação explícita.
10. Executar `POST_MERGE_CHECKLIST.md`.

---

## 13. Decisão canônica inicial

O módulo será tratado como **Assistente de Fluxo do Corretor**, não apenas como discador.

A PME será a base operacional de mensagens/scripts. A IA será uma camada opcional, pagável e auditável, usada para melhorar textos e argumentos, sempre com controle de permissão e reaproveitamento inteligente de respostas.