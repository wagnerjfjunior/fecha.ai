# PME Usage Tracking & Script Utility — v0.2.7

**Status:** contrato técnico em documentação  
**Branch:** `feature/pme-usage-tracking-v0.2.7`  
**Base estável:** `baseline/discador-flow-ai-pme-v0.2.6-stable`  
**Objetivo:** registrar uso real de scripts/mensagens do Discador Flow AI / PME sem quebrar login, snapshot, feedback, RPCs ou regras multi-tenant.

---

## Por que esta release existe

A v0.2.6 estabilizou o Discador Flow AI / PME com IA contextual inline. A v0.2.7 começa a transformar o módulo em uma base de inteligência comercial reutilizável.

Hoje o corretor escolhe origem, canal, situação, usa uma mensagem base ou uma mensagem melhorada por IA e depois registra feedback. O próximo passo é medir o que foi usado, em qual contexto e com qual utilidade operacional.

Isso permite:

- identificar quais scripts são realmente usados;
- medir utilidade por origem/canal/situação;
- comparar texto base versus texto gerado por IA;
- reduzir chamadas futuras de IA usando respostas reaproveitáveis;
- criar base para módulo pagável de IA por empresa/tenant;
- alimentar futuras recomendações comerciais do FECH.AI.

---

## Documentos desta release

- `CONTRACT.md` — contrato funcional e limites da v0.2.7.
- `MVP_SCOPE.md` — escopo mínimo, fora de escopo e critérios de aceite.
- `DATA_MODEL.md` — modelo de dados proposto para eventos de uso.
- `SECURITY_RLS_PLAN.md` — plano de segurança, RLS, RPC e DevSecOps.
- `ROLLBACK_PLAN.md` — estratégia de rollback e critérios de interrupção.
- `VALIDATION_CHECKLIST.md` — checklist técnico e funcional antes de merge.

---

## Regra central

Esta release **não deve transformar o frontend em fonte soberana de regra de negócio**.

O frontend pode enviar contexto operacional do clique, mas o banco/RPC deve validar:

- `auth.uid()`;
- tenant vinculado ao usuário;
- empresa vinculada ao usuário;
- perfil/permissão;
- lead pertencente ao tenant/empresa;
- ação permitida para aquele usuário.

---

## Diretriz de privacidade

No MVP, priorizar metadados e hashes. Não persistir texto completo da conversa ou mensagem gerada sem decisão explícita de produto, LGPD e governança.

Padrão recomendado para v0.2.7:

- salvar `script_text_hash`;
- salvar origem, canal, situação, fonte do script e ação;
- salvar referência do lead quando segura;
- evitar conteúdo textual sensível;
- permitir evolução futura para biblioteca curada de scripts aprovados.

---

## Resultado esperado

Ao final da v0.2.7, o FECH.AI deve saber, com segurança:

- qual script foi visualizado;
- qual script foi executado;
- se foi texto base ou IA;
- em qual canal;
- em qual origem/situação;
- por qual usuário/tenant/empresa;
- se o evento pode futuramente ser associado a feedback e nota de utilidade.
