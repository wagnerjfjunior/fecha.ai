# FECH.AI / MesaCliente — Handoff técnico pré-PR para `main`

## 1. Identificação

**Projeto:** FECH.AI / MesaCliente  
**Área:** Engenharia Financeira + Front MesaCliente + Histórico/2ª via  
**Branch:** `feature/mesa-cliente-fase-8-front-operacoes-financeiras`  
**Base de destino prevista:** `main`  
**Status:** pronto para abertura de PR técnico, sem merge automático  
**Data:** 2026-05-26

Este documento consolida o estado da branch antes da abertura do PR para atualizar a `main`, evitando perda de contexto entre conversas e reduzindo o risco de reinterpretação indevida do que já foi feito.

---

## 2. Protocolo obrigatório

A branch deve continuar subordinada a:

```text
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
docs/protocolos/protocolo-operacional-universal-fechai-v1.0.md
```

Regras preservadas neste ciclo:

```text
Não alterar parser sem autorização explícita.
Não alterar Worker/Make/n8n sem autorização explícita.
Não alterar motor financeiro central sem autorização explícita.
Não aceitar payload soberano do frontend como autoridade de tenant/empresa/time/corretor.
Manter auth.uid(), RLS/RPC, multi-tenant e DevSecOps como fonte de verdade.
Não considerar PASS sem evidência real de Action, build, HAR ou Supabase.
```

---

## 3. Escopo consolidado da branch

A branch saiu de uma etapa de integração Front/BFF de operações financeiras e avançou até a reabertura read-only de proposta histórica.

Escopo consolidado:

```text
8B  — Adapter Front/BFF para operações financeiras.
8C  — Painel administrativo de operações financeiras.
8D  — Build/integração estática do painel.
8E/8K — Correções de payload completo do fluxo e smoke runtime.
19A-19E — Correções de gravação de fluxo, payload completo e parcela única.
20A — RPC read-only para reconstruir fluxo salvo pelo histórico.
20A.1/20A.2/20A.5 — Hardening de visibilidade comercial por ownership/time/tenant.
20B — Segunda via read-only da proposta a partir do histórico.
```

---

## 4. Resultado funcional atual

### 4.1 Operações financeiras

A tela de operações financeiras foi conectada ao contexto de simulação/histórico, mas continua dependente de sessão, token e simulação válidos.

A mensagem abaixo é esperada quando falta contexto mínimo:

```text
Operações financeiras indisponíveis
Não foi possível identificar sessão, token ou simulação. A consulta foi bloqueada antes de chamar os hooks de dados.
```

Interpretação correta: isso é bloqueio defensivo no frontend, não erro de RPC.

### 4.2 Gravação de fluxo

A gravação do fluxo foi corrigida para enviar payload completo ao `criar_mesa_simulacao`, incluindo grupos como:

```text
e = entrada
c = curto prazo / complementos
m = mensais
a = intermediárias / anuais
u = parcela única / quitação
```

A parcela única deve permanecer tratada como caso legítimo, pois alguns empreendimentos possuem esse item no fluxo.

### 4.3 Histórico e 2ª via

A 2ª via read-only já abre a proposta histórica pelo Histórico.

Comportamento validado visualmente:

```text
Histórico -> abrir 2ª via -> renderizar fluxo salvo -> permitir acesso às operações financeiras associadas.
```

A 2ª via é leitura histórica. Ela não deve editar a proposta original por esta tela.

---

## 5. Matriz de visibilidade comercial aprovada

Regra normativa aprovada para propostas/fluxos históricos:

| Perfil | Mesmo tenant/empresa | Mesmo time do dono | Dono da proposta | Acesso |
|---|---:|---:|---:|---:|
| Corretor dono | Sim | Irrelevante | Sim | Sim |
| Corretor não dono | Sim | Sim ou não | Não | Não |
| Gestor do time do corretor dono | Sim | Sim | Não | Sim |
| Gestor de outro time | Sim | Não | Não | Não |
| Admin local puro | Sim | Irrelevante | Não | Não |
| Admin global puro | Sim | Irrelevante | Não | Não |
| Root puro | Sim | Irrelevante | Não | Não |
| Qualquer perfil de outro tenant/empresa | Não | Irrelevante | Irrelevante | Não |

Observação importante:

```text
Se o usuário também for o corretor dono, a precedência é ownership.
Exemplo: usuário com flag administrativa, mas dono da proposta, acessa como corretor_dono.
```

---

## 6. Evidências consolidadas nesta branch

A branch possui documentação e artefatos de validação para:

```text
17B — validação estática Front/BFF de operações financeiras.
17C — contrato e existência do painel de operações financeiras.
17D — build/validação do painel de operações financeiras.
18A-18D — correções de contexto, sessão, token e integração visual.
19A-19D — gravação de fluxo e payload completo.
19E — smoke runtime de payload completo Fluxo -> RPC -> Supabase.
20A — RPC para reabrir fluxo histórico read-only.
20A.1/20A.2/20A.5 — hardening de visibilidade comercial.
20B — 2ª via read-only conectada ao Histórico.
```

Evidência de build local informada antes deste handoff:

```text
node -v = v24.16.0
npm -v = 11.13.0
npm install = 0 vulnerabilities
npm run build = sucesso
vite build = 745 modules transformed
chunk warning > 500 kB = warning não bloqueante
working tree limpo após restore/clean
```

Atenção: este documento não transforma evidência parcial em PASS. Ele apenas consolida as evidências já apresentadas durante o ciclo.

---

## 7. Arquivos sensíveis e pontos de segurança

### 7.1 Service role no frontend

Foi removida referência residual a `service_role`/texto equivalente do frontend principal. O objetivo foi manter o 17B sem falso positivo e, principalmente, evitar qualquer indício de chave privilegiada no client-side.

Regra permanente:

```text
service_role nunca aparece em frontend, variável pública, build client-side, storage público, log de navegador ou payload acessível ao usuário.
```

### 7.2 HAR com senha

Ao exportar HAR de login, o corpo da requisição pode conter a senha digitada em texto legível dentro do arquivo HAR, mesmo quando a transmissão real ocorre por HTTPS.

Regra operacional:

```text
HAR de login é material sensível.
Não versionar.
Não anexar em PR público.
Não colar senha em documentação.
Apagar ou mascarar antes de compartilhar.
```

Isso não significa, por si só, que a senha trafegou sem criptografia na internet; significa que o navegador/DevTools registrou o payload localmente no HAR.

---

## 8. Pendência consciente — rastreabilidade de valor original versus valor final

Foi identificado um ponto funcional importante na 2ª via:

```text
Quando o fluxo é alterado antes de salvar, a 2ª via mostra o valor final salvo,
mas ainda não mostra lado a lado o valor original da tabela/parser e o delta aplicado.
```

Decisão aprovada:

```text
Não bloquear o PR por propostas antigas.
Implementar em fase própria para não contaminar operações financeiras, antecipação, amortização, juros e VPL.
```

Próxima fase recomendada:

```text
20C — Rastreabilidade de alterações do fluxo histórico.
```

Escopo sugerido da 20C:

```text
Mostrar valor original.
Mostrar valor final.
Mostrar diferença absoluta: exemplo Diferença: +R$ 181.016.
Mostrar diferença percentual: exemplo +x%.
Separar essa camada da lógica de operações financeiras.
Não recalcular antecipação, amortização, juros ou VPL nesta etapa.
Não alterar motor financeiro.
Não alterar parser.
```

---

## 9. Risco e impacto do PR para main

### Baixo risco quando:

```text
O PR for revisado como integração acumulada da branch.
Actions rodarem novamente no PR.
Migrations forem revisadas antes de aplicar em produção.
HARs com credenciais não forem anexados ao PR.
```

### Riscos principais:

```text
1. Muitas alterações acumuladas na branch.
2. Migrations de segurança alteram a semântica de histórico e fluxo histórico.
3. 2ª via depende de RPC 20A/20A.5 aplicada no ambiente.
4. Rastreabilidade original/final ainda não foi implementada.
5. Build gera warning de bundle grande, não bloqueante, mas merece backlog técnico futuro.
```

### Mitigações:

```text
Abrir PR com descrição longa e checklist.
Não fazer merge automático.
Validar Actions do PR.
Validar deploy preview.
Validar login com usuários de times diferentes.
Validar 2ª via com corretor dono.
Validar bloqueio de proposta de outro time.
Validar gestor do mesmo time com massa compatível.
```

---

## 10. Checklist antes do merge

```text
[ ] PR aberto contra main.
[ ] Actions do PR executadas.
[ ] Build do PR sem erro.
[ ] Sem arquivo HAR versionado.
[ ] Sem senha/token/chave em documentação.
[ ] Sem service_role no frontend.
[ ] Review das migrations 20A/20A.5.
[ ] Deploy preview validado.
[ ] Corretor dono abre 2ª via.
[ ] Corretor não dono não abre proposta alheia.
[ ] Gestor de outro time não abre proposta alheia.
[ ] Admin local/global/root não ampliam acesso pela RPC comum.
[ ] Outro tenant/empresa bloqueado.
```

---

## 11. Frase de controle para próxima conversa

```text
Branch feature/mesa-cliente-fase-8-front-operacoes-financeiras está pronta para PR técnico contra main, com 2ª via read-only funcionando pelo Histórico, matriz comercial endurecida por dono/time/tenant e próxima fase sugerida 20C para rastreabilidade valor original x valor final. Não reabrir decisões já validadas sem evidência nova; revisar PR, Actions e deploy preview antes de merge.
```
