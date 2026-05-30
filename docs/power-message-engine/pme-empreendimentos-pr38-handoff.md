# PME — Empreendimentos — Handoff PR #38

## Status

Documento de passagem técnica do módulo **PME Empreendimentos**, criado para adicionar mensagens por empreendimento dentro do fluxo do Discador/Central de Mensagens do FECH.AI.

PR atual:

```txt
#38 — fix(pme): bind corretor profile and force Gmail compose
```

Branch atual:

```txt
hotfix/pme-empreendimentos-profile-gmail-r1
```

Arquivo alterado nesta PR:

```txt
public/pme-empreendimentos-inline-flow.js
```

Arquivos e áreas que não foram alterados nesta PR:

```txt
src/App.jsx
src/main.jsx
Supabase
RLS
RPC
Auth
MesaCliente
Worker
Make/n8n
motor financeiro
migrations
seed
```

## Objetivo

Adicionar ao fluxo de atendimento uma escolha entre:

```txt
Origem do lead
Empreendimentos
```

Quando o corretor escolhe **Empreendimentos**, os botões de origem são ocultados e dão lugar aos botões de empreendimentos. O primeiro empreendimento configurado é **Château Jardin**.

## Empreendimento inicial

```txt
Nome: Château Jardin
Realização: Tegra e Exto
Endereço do evento: Rua Ministro Nelson Hungria, 400
Metragens: 185 m², 215 m², 248 m² e 355 m²
Conceito: inspiração clássica e jardins franceses
Canais: Ligação, WhatsApp e E-mail
```

Termos que não devem ser usados nas mensagens:

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

## O que foi validado pelo usuário

O usuário validou a PR #38 em desktop/mobile com mais de um corretor.

Funcionou:

```txt
- Empreendimentos aparece dentro do fluxo do Discador.
- Château Jardin aparece como empreendimento inicial.
- Mensagens por WhatsApp funcionam.
- Mensagens por E-mail funcionam.
- Variáveis do corretor são substituídas.
- Gmail abre no lugar de Outlook/mailto.
- O fluxo padrão por origem do lead permanece funcionando.
```

## Problemas encontrados e lições aprendidas

### 1. URL errada de preview

O módulo parecia ter sumido porque uma URL antiga de preview da PR #37 estava sendo testada por engano.

Lição:

```txt
Nunca validar por URL solta da Vercel sem confirmar branch, PR e commit.
```

Antes de validar, confirmar:

```txt
- branch do deployment
- PR vinculada
- commit SHA
- status READY na Vercel
```

### 2. PR #37 descartada

A PR #37 gerou regressões e não deve ser usada como base.

Problemas observados:

```txt
- alternância visual entre Origem e Empreendimentos
- comportamento instável no fluxo
- e-mail voltando para cliente padrão do sistema
- variáveis do corretor inconsistentes
```

Regra:

```txt
Não reaproveitar branch, preview ou implementação da PR #37.
```

### 3. Variáveis do corretor

Sintoma anterior:

```txt
{{telefone_corretor}}
{{link_whatsapp_corretor}}
telefone não configurado
WhatsApp não configurado
```

Causa:

O app principal já carregava o perfil do corretor, mas o módulo de Empreendimentos não consumia esse retorno corretamente.

Campos confiáveis observados no perfil do corretor:

```txt
apelido
telefone_prof
empresa
```

Campos que não devem ser usados nesta etapa:

```txt
telefone
celular
whatsapp
```

Solução da PR #38:

```txt
- Captura localmente o retorno já existente de /rest/v1/corretores.
- Normaliza nome, telefone, empresa e link de WhatsApp.
- Persiste o perfil normalizado no localStorage.
- Usa esses dados nas mensagens do PME.
```

Variáveis substituídas nas mensagens:

```txt
{{nome}}
{{corretor}}
{{telefone_corretor}}
{{link_whatsapp_corretor}}
{{empresa}}
```

### 4. Gmail e From

O módulo anterior usava mailto. Isso fazia o navegador abrir Outlook ou outro cliente padrão.

A PR #38 passa a abrir Gmail Compose diretamente.

Limitação conhecida:

```txt
O campo From/De depende da configuração interna do Gmail. O FECH.AI consegue tentar direcionar a conta, mas o Gmail só permite escolher remetente se o alias estiver configurado na própria conta.
```

### 5. Link do WhatsApp do corretor

O link exibido no formato wa.me não funcionou como esperado no teste final. Foi ajustado para o formato mais compatível do WhatsApp Web/API.

## Assinatura final aprovada

```txt
{{corretor}} — {{telefone_corretor}}
WhatsApp: {{link_whatsapp_corretor}}

Na recepção, solicite por {{corretor}} da {{empresa}}.
```

## Arquitetura atual

O módulo é um enhancer frontend-only:

```txt
- roda em IIFE
- atua sobre o DOM existente
- não altera App.jsx
- não altera banco
- não altera Auth/RLS/RPC
- não envia mensagem automaticamente
- apenas prepara/copiar/abre canal de contato
```

Ponto de montagem esperado:

```txt
#fechai-pme-call-assistant
```

Responsabilidades do script:

```txt
- inserir seletor Origem do lead / Empreendimentos
- ocultar origens quando Empreendimentos está ativo
- exibir empreendimentos disponíveis
- exibir situações específicas de empreendimento
- montar mensagem sugerida por canal
- randomizar variações
- copiar mensagem
- abrir WhatsApp ou Gmail
- substituir variáveis de lead/corretor/empresa
```

## Guardrails para continuidade

Não fazer:

```txt
- Não mexer em App.jsx para esta correção.
- Não mexer em main.jsx para esta correção.
- Não recriar o fluxo inteiro.
- Não remover o fluxo por origem do lead.
- Não transformar Empreendimentos em página separada agora.
- Não alterar banco/RLS/RPC/Auth sem autorização explícita.
- Não usar PR #37 como base.
- Não validar por preview antigo.
```

Fazer:

```txt
- Continuar a partir da PR #38.
- Validar branch, PR e commit antes de testar.
- Preservar o layout aprovado.
- Preservar a assinatura dinâmica.
- Usar telefone_prof como origem do telefone.
- Usar empresa do cadastro na assinatura.
- Manter Gmail Compose para e-mail de Empreendimentos.
```

## Próximos passos

### 1. Validação final da PR #38

Checklist:

```txt
- Abrir preview atual da PR #38.
- Testar Empreendimentos > Château Jardin > WhatsApp.
- Confirmar nome, telefone, WhatsApp e empresa do corretor.
- Testar Empreendimentos > Château Jardin > E-mail.
- Confirmar abertura no Gmail.
- Testar com mais de um corretor.
- Confirmar fluxo padrão por origem do lead.
- Confirmar que não há alternância automática de tela.
```

### 2. Merge

Após validação:

```txt
Squash and merge da PR #38 para main.
```

Depois do merge:

```txt
- Aguardar deploy de produção na Vercel.
- Validar a URL principal.
- Confirmar que produção contém a mesma funcionalidade validada no preview.
```

### 3. Evolução futura

Depois da PR #38 em produção, planejar cadastro administrativo de empreendimentos e mensagens.

MVP sugerido:

```txt
empreendimentos
pme_empreendimento_mensagens
pme_empreendimento_variaveis
```

Qualquer evolução com banco deve respeitar multi-tenant e segurança:

```txt
auth.uid()
tenant_id
empresa_id
perfil/permissão
sem dados soberanos vindos do frontend
```

## Resumo para outra IA continuar

```txt
Estamos no FECH.AI, módulo PME/Central de Mensagens/Discador. Foi criado o módulo PME Empreendimentos dentro do fluxo de atendimento. O primeiro empreendimento é Château Jardin. A PR válida é a #38, branch hotfix/pme-empreendimentos-profile-gmail-r1. O arquivo alterado é public/pme-empreendimentos-inline-flow.js. Não mexer em App.jsx nem main.jsx.

A PR #37 foi descartada e não deve ser usada. Ela causou regressões.

A PR #38 já foi testada pelo usuário com mais de um corretor em WhatsApp e E-mail. Funcionou. Ajustes finais: assinatura “Na recepção, solicite por {{corretor}} da {{empresa}}”, link do corretor em formato compatível com WhatsApp, e Gmail Compose no e-mail.

Dados do corretor vêm do retorno existente de /rest/v1/corretores, principalmente apelido, telefone_prof e empresa. Não usar telefone/celular/whatsapp nesta etapa.

Próximo passo: validar novamente o preview da PR #38, fazer squash merge para main, aguardar produção na Vercel e testar a URL principal. Depois planejar painel administrativo de empreendimentos.
```
