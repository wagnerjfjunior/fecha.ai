# ADR-0001 — IA como módulo pago, auditável e com cache de respostas

**Status:** proposta aprovada para desenho do MVP  
**Data:** 2026-05-22  
**Contexto:** Discador Flow AI / PME  
**Risco:** R3/R4 quando envolver backend, billing, dados pessoais ou Supabase.

---

## Contexto

O FECH.AI terá recursos de IA para melhorar mensagens, scripts de ligação e argumentos comerciais em tempo quase real.

Como o produto é SaaS multiempresa, a IA não deve ser tratada como recurso gratuito e ilimitado. Ela precisa ser:

- configurável por empresa;
- controlada por permissão;
- medida por uso;
- cobrável como módulo;
- auditável;
- reaproveitável para reduzir custo.

---

## Decisão

A IA será tratada como **módulo pagável do SaaS**, não como dependência obrigatória do discador.

O fluxo manual da PME deve funcionar mesmo sem IA.

---

## Diretrizes

1. Modelo de IA não pode ficar hardcoded no frontend.
2. Chave de IA nunca pode ir para o navegador.
3. Toda chamada de IA deve passar por backend controlado ou edge function segura.
4. A permissão deve ser validada por usuário, empresa e plano.
5. Toda resposta gerada deve registrar evento de auditoria.
6. Respostas utilizadas devem alimentar uma base de conhecimento operacional.
7. Antes de chamar IA, o sistema deve tentar localizar resposta reaproveitável quando fizer sentido.
8. Dados pessoais devem seguir mínimo necessário.
9. Nenhum envio automático será feito pela IA no MVP.

---

## Eventos mínimos para mensuração

- `script_viewed`
- `script_copied`
- `whatsapp_opened`
- `email_prepared`
- `call_script_copied`
- `ai_requested`
- `ai_generated`
- `ai_failed`
- `ai_response_used`
- `ai_response_edited`
- `ai_response_rejected`
- `feedback_saved`
- `score_saved`

---

## Cache e reaproveitamento

O sistema deve avaliar se uma resposta semelhante já existe antes de gerar nova resposta com IA.

Chaves candidatas para reaproveitamento:

- empresa_id/tenant resolvido no backend;
- origem do lead;
- canal;
- tipo de abordagem;
- empreendimento;
- objeção;
- perfil do lead;
- idioma/tom;
- hash do prompt sanitizado.

O objetivo não é só economizar. É descobrir quais textos realmente funcionam.

---

## Métricas futuras

- custo por empresa;
- custo por corretor;
- custo por lead trabalhado;
- respostas mais copiadas;
- respostas com melhor feedback associado;
- respostas que mais geram visita;
- taxa de uso da IA versus base pronta;
- taxa de rejeição de respostas IA;
- economia estimada por cache.

---

## Consequências

### Positivas

- Reduz custo operacional de IA.
- Gera inteligência comercial própria.
- Permite monetização do módulo.
- Protege o produto contra uso descontrolado.
- Evita dependência total de IA para operar.

### Negativas / riscos

- Exige backend seguro.
- Exige modelagem de auditoria.
- Exige cuidado com LGPD.
- Exige UX clara para o corretor entender quando a IA está indisponível.

---

## Decisão canônica

A IA será uma camada auxiliar e pagável. A PME/base de scripts será o núcleo resiliente. O cache e a base de respostas usadas serão tratados como ativo estratégico do FECH.AI.