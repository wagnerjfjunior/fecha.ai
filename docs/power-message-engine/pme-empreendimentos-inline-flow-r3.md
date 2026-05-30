# PME — Empreendimentos Inline Flow R3

## Objetivo

Adicionar a dimensão **Empreendimentos** dentro do fluxo atual de atendimento do Discador Flow AI, sem criar bloco visual separado e sem alterar banco, RPC, RLS, Auth ou automações.

## Branch

`pme-empreendimentos-inline-flow-r3`

Base: `main` em `b42ae0483cc8cd65fe0b1b93cc55ec8c864d2669`.

## Arquivos alterados

```txt
src/main.jsx
public/pme-empreendimentos-inline-flow.js
docs/power-message-engine/pme-empreendimentos-inline-flow-r3.md
```

## Arquivos preservados

```txt
public/pme-call-assistant-beta.js
src/components/AceleracaoOperacional.jsx
src/services/aceleracaoOperacionalService.js
src/components/PowerMessageEngineAdmin.jsx
src/components/pme/*
Supabase / migrations / RLS / RPC / Auth
```

## Fluxo desejado

```txt
Topo do lead permanece como está.

1. Escolha a origem ou empreendimento
   - Origem do lead
   - Empreendimentos

Se Origem do lead:
   - Carteira
   - Lista fria
   - Já visitou
   - Redes Sociais
   - Problemas
   - Argumentações

Se Empreendimentos:
   - Château Jardin

2. Escolha o canal para contato com o cliente
   - Ligação
   - WhatsApp
   - E-mail

3. Escolha em qual situação o cliente está
   - Convite para lançamento
   - Primeiro contato
   - Pediu plantas
   - Pediu valores
   - Pediu material
   - Já conhece o projeto
   - Visitou plantão
   - Pós-visita
   - Quer levar família
   - Está comparando
   - Sem resposta

Mensagem sugerida

4. Executar contato
```

## Regra da mensagem sugerida

Desktop:

```txt
Título + aproximadamente 3 linhas visíveis.
Rolagem interna quando o conteúdo for maior.
```

Mobile:

```txt
Título + aproximadamente 5 linhas visíveis.
Rolagem interna quando o conteúdo for maior.
```

## Conteúdo inicial

Empreendimento inicial:

```txt
Château Jardin
Rua Ministro Nelson Hungria, 400
```

Canais:

```txt
20 variações WhatsApp
10 variações Ligação
10 variações E-mail
```

## Termos bloqueados

O conteúdo não deve usar:

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

## Matriz DML

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

## Critérios de aceite

1. A PR #33 não deve ser usada como base final.
2. A PR #34 não deve ser usada como base final.
3. A produção permanece sem alteração até merge.
4. A nova branch deve preservar o layout atual do lead.
5. A dimensão Empreendimentos deve aparecer dentro do fluxo, não como card externo.
6. A caixa Mensagem sugerida deve limitar altura com rolagem interna.
7. O botão executar deve continuar sendo revisão assistida, sem envio automático.
