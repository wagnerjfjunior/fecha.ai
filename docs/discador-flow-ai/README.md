# Discador Flow AI — Assistente operacional do corretor

**Status:** organização inicial do módulo  
**Branch:** `feature/ccam-pme-mvp-v0.1`  
**Base de protocolo:** Protocolo Mestre FECH.AI / MesaCliente v1.2  
**Risco desta alteração:** R0 — documentação e diretórios; sem alteração de motor, banco, RPC, RLS ou produção.

---

## Objetivo

Organizar a evolução do discador atual para um **flow operacional de atendimento do corretor**, integrando:

- discador;
- PME — Power Message Engine;
- scripts de ligação;
- mensagens de WhatsApp;
- e-mails;
- badges de situação do lead;
- melhoria assistida por IA;
- score, feedback e reaproveitamento de respostas.

A ideia central não é criar apenas um discador. O objetivo é criar uma esteira de atendimento rápido, guiado e mensurável, para o corretor saber o que falar, quando falar e qual próxima ação executar.

---

## Documentos principais

1. `contratos/contrato-mvp-discador-flow-ai-v0.1.md`  
   Contrato oficial do MVP, escopo, fora de escopo, riscos, critérios de aceite e bloqueio.

2. `fluxos/fluxo-13-niveis-discador-flow-ai-v0.1.md`  
   Fluxo funcional dos 13 níveis informados.

3. `adr/ADR-0001-ia-modulo-pago-cache-respostas.md`  
   Decisão arquitetural sobre IA como módulo SaaS pago, gravação de uso, cache e base de respostas.

4. `backlog/backlog-mvp-discador-flow-ai-v0.1.md`  
   Backlog técnico e funcional do MVP.

5. `testes/caderno-testes-mvp-discador-flow-ai-v0.1.md`  
   Caderno de testes obrigatório antes de qualquer merge para `main`.

---

## Regra de ouro

Não mexer no motor atual do app, feedback, parser, Worker, Make/n8n, Supabase/RPC ou `main` sem contrato, diff, teste e aprovação explícita.

Esta pasta é o ponto canônico para a evolução do módulo.