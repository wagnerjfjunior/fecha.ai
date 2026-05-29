# PME — Empreendimentos — Changelog de Implementação v1 Clean

**Projeto:** FECH.AI  
**Módulo:** PME — Power Message Engine  
**Fase:** Gate 3 — Patch R2 frontend assistido  
**Branch:** `feature/pme-empreendimentos-gate3-frontend-r2-clean`  
**Base:** `main` em `b42ae0483cc67d0cbac203220b11beac7cd9ac528`  
**Risco:** R2 — Frontend assistido, sem banco  

---

## 1. Objetivo

Adicionar o primeiro fluxo operacional do grupo **Empreendimentos** sem substituir o arquivo principal do assistente beta da PME.

A decisão desta versão clean foi preservar o front novo da `main` e carregar a funcionalidade de Empreendimentos como addon frontend isolado.

---

## 2. Arquivos alterados

```txt
src/main.jsx
public/pme-empreendimentos-addon.js
docs/power-message-engine/pme-empreendimentos-implementation-changelog-v1-clean.md
```

---

## 3. Arquivo preservado

O arquivo abaixo não foi substituído nesta versão clean:

```txt
public/pme-call-assistant-beta.js
```

Isso evita a regressão observada no PR #33, onde o diff operacional ficou amplo demais.

---

## 4. O que mudou

### 4.1 Loader público reutilizável

`src/main.jsx` passou a usar uma função auxiliar:

```txt
loadPublicScript(id, src)
```

Ela carrega scripts públicos evitando duplicidade pelo `id` do script.

### 4.2 Assistente beta preservado

O loader atual foi mantido:

```txt
/pme-call-assistant-beta.js
```

### 4.3 Addon de Empreendimentos carregado separadamente

Novo script carregado:

```txt
/pme-empreendimentos-addon.js
```

### 4.4 Módulo Empreendimentos

O addon adiciona um bloco assistido para:

```txt
Grupo: Empreendimentos
Empreendimento: Château Jardin
Endereço: Rua Ministro Nelson Hungria, 400
Situação principal: Convite para lançamento
Canais: WhatsApp, Ligação e E-mail
```

### 4.5 Conteúdo comercial incluído

O addon contém:

```txt
20 variações de WhatsApp
10 variações de ligação
10 variações de e-mail
```

Com abordagem sobre:

```txt
Château Jardin
lançamento amanhã / evento de lançamento
Rua Ministro Nelson Hungria, 400
Tegra + Exto
novo eixo Cidade Jardim
paisagismo internacional EDSA
inspiração nos jardins franceses
arquitetura clássica
metragens 185 m², 215 m², 248 m² e 355 m²
quadra de tênis de saibro
padel
piscina coberta
wellness
```

### 4.6 Execução assistida

O addon mantém modo assistido:

```txt
WhatsApp: abre wa.me com texto pronto
E-mail: abre mailto com assunto/corpo
Ligação: copia o texto e aciona tel quando houver telefone
```

Nada é enviado automaticamente.

---

## 5. Termos bloqueados

O addon mantém validação visual contra:

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

Se algum termo aparecer no texto ativo, o bloco exibe alerta.

---

## 6. O que não mudou

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
public/pme-call-assistant-beta.js
```

---

## 7. Matriz DML

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

## 8. Critérios de aceite

1. A produção atual continua preservada enquanto a branch não for mergeada.
2. O preview da branch clean deve exibir o front novo da `main`.
3. O assistente beta original deve continuar funcionando.
4. O bloco `PME — Empreendimentos` deve aparecer em contexto de lead/discador.
5. O bloco deve exibir `Château Jardin`.
6. O bloco deve permitir escolher WhatsApp, Ligação ou E-mail.
7. O bloco deve permitir escolher situação do lead.
8. O botão `Próxima variação` deve alternar mensagens.
9. O botão `Copiar` deve copiar o texto.
10. O botão `Revisar e executar` deve abrir WhatsApp, e-mail ou ligação em modo assistido.
11. Nenhum envio automático deve ocorrer.
12. Nenhuma alteração de banco/RLS/RPC/Auth deve existir.

---

## 9. Rollback

Rollback simples:

```txt
Reverter commits da branch clean ou fechar PR sem merge.
```

Como não há banco, não há rollback de dados.
