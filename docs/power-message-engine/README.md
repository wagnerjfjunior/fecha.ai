# Power Message Engine — Central de Mensagens FECH.AI

## Objetivo

O **Power Message Engine** é o módulo do FECH.AI responsável por orientar, acelerar e padronizar a comunicação comercial dos corretores com leads imobiliários, sem transformar a operação em um labirinto operacional.

A proposta é entregar três camadas complementares:

1. **Central de Mensagens** — biblioteca organizada de mensagens, scripts e modelos por canal, fase e tipo de lead.
2. **Oferta Ativa / Acelerador** — modo assistido para o corretor executar uma sequência de contato com poucos cliques.
3. **Piloto Automático** — execução controlada de réguas comerciais, respeitando regras de consentimento, limites operacionais e governança.

> Regra de ouro: o sistema deve ajudar o corretor a vender melhor, não criar um monstro de 10 telas, 40 botões e 10 minotauros soltos no corredor.

---

## Escopo da v1

A v1 deve focar em operação prática, rastreável e segura:

- WhatsApp manual assistido.
- E-mail manual assistido ou semi-automatizado.
- Ligação com script na tela.
- Sugestão automática de mensagem por tipo de lead e fase.
- Pools de mensagens com variação controlada.
- Registro obrigatório do resultado após cada contato.
- Histórico por lead.
- Respeito ao tenant, empresa, campanha, empreendimento e corretor.

A v1 **não deve** nascer como disparador massivo clandestino. O foco é produtividade comercial, não gambiarra de volume.

---

## Tipos de lead suportados

| Tipo | Descrição | Temperatura operacional |
|---|---|---|
| `lead_quente` | Lead vindo de formulário, anúncio, landing page, WhatsApp, Google ou Meta | Alta |
| `lista_fria` | Lead importado de base comprada, antiga ou sem interação recente | Baixa |
| `lista_quente` | Lista de pessoas que já interagiram, visitaram plantão, pediram informações ou já falaram com corretor | Média/Alta |
| `visitou_plantao` | Pessoa que esteve presencialmente no stand/plantão | Alta, mas exige abordagem mais consultiva |

---

## Fases de contato

Cada tipo de lead deve possuir mensagens por fase:

1. `primeira_mensagem`
2. `segunda_mensagem`
3. `terceira_mensagem`
4. `mensagem_final`

Para WhatsApp, cada combinação de `tipo_lead + fase` deve ter **mínimo de 10 variações**.

Exemplo:

```txt
lead_quente + primeira_mensagem = 10 mensagens
lead_quente + segunda_mensagem = 10 mensagens
lead_quente + terceira_mensagem = 10 mensagens
lead_quente + mensagem_final = 10 mensagens
```

Somente considerando 3 grandes tipos de lead, isso já gera pelo menos **120 mensagens de WhatsApp**.

---

## Estrutura documental

- [`spec.md`](./spec.md) — especificação funcional detalhada.
- [`data-model.md`](./data-model.md) — modelo de dados sugerido.
- [`message-taxonomy.md`](./message-taxonomy.md) — taxonomia de canais, fases, intenção e tom.
- [`automation-rules.md`](./automation-rules.md) — regras do Acelerador e Piloto Automático.
- [`call-scripts.md`](./call-scripts.md) — estrutura dos scripts de ligação.
- [`compliance-and-governance.md`](./compliance-and-governance.md) — limites, consentimento, LGPD e governança.
- [`implementation-checklist.md`](./implementation-checklist.md) — checklist para implementação.
- [`prompt-for-implementer-ai.md`](./prompt-for-implementer-ai.md) — prompt para outra IA/dev executar sem inventar arquitetura.

---

## Princípios de produto

1. **Poucos caminhos, muita clareza.**
2. **Um clique deve avançar a operação, não abrir mais confusão.**
3. **Toda mensagem precisa ter contexto: canal, fase, tipo de lead, empreendimento e objetivo.**
4. **O corretor sempre deve saber o que falar, por que falar e qual próximo passo registrar.**
5. **Toda automação precisa ter limite, auditoria e possibilidade de pausa.**
6. **O sistema deve proteger o número, a reputação da empresa e a experiência do cliente.**

---

## Status

Documento inicial criado como base de produto para evolução do módulo dentro do FECH.AI.

Próximo passo recomendado: criar a matriz completa de mensagens e validar o fluxo visual da tela do Acelerador.
