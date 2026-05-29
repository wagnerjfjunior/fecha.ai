# PME — Empreendimentos — Changelog de Implementação v1

**Projeto:** FECH.AI  
**Módulo:** PME — Power Message Engine  
**Fase:** Gate 3 — Patch R2 frontend assistido  
**Branch:** `feature/pme-empreendimentos-gate3-frontend-r2`  
**Arquivo operacional alterado:** `public/pme-call-assistant-beta.js`  
**Risco:** R2 — Frontend assistido, sem banco  

---

## 1. Objetivo da alteração

Implementar, no assistente beta da PME do Discador, o primeiro fluxo operacional do grupo de mensagens **Empreendimentos**, preservando o fluxo geral/base atual.

O primeiro empreendimento operacional incluído foi:

```txt
Château Jardin
```

---

## 2. Alterações aplicadas

### 2.1 Versão do assistente

Atualizado o identificador interno:

```txt
0.2.6 -> 0.3.0
```

### 2.2 Novo grupo de mensagens

Adicionado seletor de grupo:

```txt
Geral / Base atual
Empreendimentos
```

O grupo `Geral / Base atual` preserva a lógica anterior baseada em origem/contexto do lead.

O grupo `Empreendimentos` ativa a seleção de empreendimento antes do canal e da situação do lead.

### 2.3 Empreendimento inicial

Adicionado:

```txt
chateau_jardin = Château Jardin
```

Dados contextuais incluídos no frontend:

```txt
Endereço: Rua Ministro Nelson Hungria, 400
Contexto: alto padrão no novo eixo Cidade Jardim
Inspiração: jardins franceses
Metragens: 185 m², 215 m², 248 m² e 355 m²
```

### 2.4 Situações de lead para Empreendimentos

Adicionadas as opções:

```txt
primeiro_contato
convite_lancamento
pediu_plantas
pediu_valores
pediu_material
ja_conhece_projeto
visitou_plantao
pos_visita
quer_levar_familia
comparando
sem_resposta
```

Nesta primeira versão operacional, todas reutilizam o pool inicial do Château Jardin para manter entrega pragmática e segura.

### 2.5 Canais preservados

Mantidos os canais existentes:

```txt
Ligação
WhatsApp
E-mail
```

Sem envio automático.

### 2.6 Mensagens adicionadas

Incluído catálogo frontend/local com:

```txt
20 variações para WhatsApp
10 variações para ligação
10 variações para e-mail
```

Contexto comercial das mensagens:

```txt
Château Jardin
lançamento amanhã / evento de lançamento
Rua Ministro Nelson Hungria, 400
Tegra + Exto
novo eixo Cidade Jardim
paisagismo internacional EDSA
inspiração nos jardins franceses
arquitetura clássica com leitura contemporânea
metragens 185 m², 215 m², 248 m² e 355 m²
quadra de tênis de saibro
padel
piscina coberta
wellness
lazer de alto padrão
```

### 2.7 Assinatura dinâmica

WhatsApp e e-mail passam a aplicar assinatura dinâmica no fluxo de Empreendimentos:

```txt
{{corretor}}
{{telefone_corretor}}
WhatsApp: {{link_whatsapp_corretor}}

Ao chegar, por gentileza, solicite por {{corretor}} na recepção para que eu possa te receber pessoalmente.
```

Ligação passa a aplicar fechamento verbal:

```txt
O evento será na Rua Ministro Nelson Hungria, 400. Quando chegar, por gentileza, solicite por {{corretor}} na recepção para que eu possa te receber pessoalmente e apresentar o projeto com calma.
```

### 2.8 Termos bloqueados

Foi incluída verificação visual de termos bloqueados na mensagem renderizada:

```txt
últimas unidades
condição exclusiva
desconto de lançamento
tabela especial garantida
diretoria liberou
reserva garantida
preço fechado
melhor condição só amanhã
```

Se algum termo bloqueado aparecer no texto ativo, o assistente exibe alerta antes do uso.

### 2.9 Execução assistida preservada

O comportamento operacional continua assistido:

```txt
WhatsApp: abre wa.me com texto pronto
E-mail: abre mailto com assunto/corpo
Ligação: copia o texto e aciona tel quando houver telefone
```

Nada é enviado automaticamente.

---

## 3. Arquivos alterados

```txt
public/pme-call-assistant-beta.js
docs/power-message-engine/pme-empreendimentos-implementation-changelog-v1.md
```

---

## 4. Arquivos não alterados

Não houve alteração em:

```txt
Supabase
migrations
RLS
grants
RPCs
seed de banco
auth
MesaCliente
Worker
Make
n8n
src/components/AceleracaoOperacional.jsx
src/services/aceleracaoOperacionalService.js
src/components/PowerMessageEngineAdmin.jsx
src/components/pme/*
```

---

## 5. Matriz DML

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
| Envio automático | Não |

---

## 6. Validações realizadas

### 6.1 Sintaxe local

Foi executada validação local de sintaxe JavaScript com:

```bash
node --check /mnt/data/pme-call-assistant-beta.js
```

Resultado: sem erro de sintaxe no arquivo preparado antes do commit operacional.

### 6.2 Varredura de termos bloqueados no catálogo ativo

Foi feita varredura local do bloco de mensagens do Château Jardin contra os termos bloqueados.

Resultado: os termos bloqueados não foram encontrados no catálogo ativo de mensagens.

---

## 7. Critérios de aceite sugeridos

1. Ao selecionar `Geral / Base atual`, o fluxo antigo continua exibindo origem do lead, canal, situação e mensagem sugerida.
2. Ao selecionar `Empreendimentos`, o assistente exibe `Château Jardin` como empreendimento.
3. Ao selecionar WhatsApp + Convite para lançamento, a PME exibe uma das 20 variações.
4. Botão `Próxima` alterna as variações.
5. Botão `Revisar e executar` abre modal de revisão.
6. WhatsApp abre link `wa.me` com texto pronto.
7. E-mail abre `mailto` com assunto e corpo.
8. Ligação copia o script e aciona `tel:` quando houver telefone.
9. Mensagem contém assinatura dinâmica.
10. Não há chamada Supabase, RPC, migration, auth ou envio automático.

---

## 8. Observação técnica

Este patch é deliberadamente frontend-only e assistido. A persistência, governança multiempresa, controle por tenant, histórico de uso e feedback estruturado devem continuar fora desta etapa até aprovação de nova fase com contrato próprio.
