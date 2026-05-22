# Fluxo 13 níveis — Discador Flow AI / PME v0.1

## Visão geral

Fluxo funcional inicial para transformar discador + PME + IA em uma jornada guiada de atendimento.

```mermaid
flowchart TD
  N1[1. Início] --> N2[2. Situação do lead]
  N2 --> B1[Lista fria]
  N2 --> B2[Já visitou]
  N2 --> B3[Redes Sociais]
  N2 --> B4[Problemas]
  N2 --> B5[Argumentações]

  B1 --> N3[3. Canal]
  B2 --> N3
  B3 --> N3
  B4 --> N3
  B5 --> N3

  N3 --> C1[WhatsApp]
  N3 --> C2[Ligações]
  N3 --> C3[E-mail]

  C1 --> N4[4. Tipo de abordagem]
  C2 --> N4
  C3 --> N4

  N4 --> A1[Primeira Abordagem]
  N4 --> A2[Retorno]
  N4 --> A3[Pós-Ligação]
  N4 --> A4[Convite]
  N4 --> A5[Objeção de preço]
  N4 --> A6[Objeção de Entrada]
  N4 --> A7[Sem Resposta]
  N4 --> A8[Fim de contato]

  A1 --> N5[5. Melhorar com IA?]
  A2 --> N5
  A3 --> N5
  A4 --> N5
  A5 --> N5
  A6 --> N5
  A7 --> N5
  A8 --> N5

  N5 --> SIM[Sim]
  N5 --> NAO[Não]

  SIM --> N6[6. Dê uma dica para IA]
  N6 --> N7[7. Escolha uma resposta ou tente novamente]
  NAO --> N7

  N7 --> N8[8. Score]
  N8 --> N9[9. Feedback]
  N9 --> N10[10. Associar nota com feedback]
  N10 --> N11[11. Nota final]
  N11 --> N12[12. Salvar na base]
  N12 --> N13[13. Encerrar ou próximo lead]
```

---

## Nível 1 — Início

Entrada do corretor no fluxo operacional do lead ativo.

Dados mínimos desejáveis:

- lead_id;
- nome;
- telefone;
- origem;
- empreendimento, quando existir;
- corretor autenticado;
- empresa/tenant resolvido pelo backend/banco.

---

## Nível 2 — Situação do lead

Badges principais:

- Lista fria;
- Já visitou;
- Redes Sociais;
- Problemas;
- Argumentações.

Esses badges determinam o contexto comercial inicial.

---

## Nível 3 — Canal

O corretor escolhe o canal:

- WhatsApp;
- Ligações;
- E-mail.

Regra: canal muda o formato da saída. Não deve haver três botões com função parecida confundindo o corretor.

---

## Nível 4 — Tipo de abordagem

Opções iniciais:

- Primeira abordagem;
- Retorno;
- Pós-ligação;
- Convite;
- Objeção de preço;
- Objeção de entrada;
- Sem resposta;
- Fim de contato.

---

## Nível 5 — Melhorar com IA?

Opção simples:

- Sim;
- Não.

Se não, usa texto da base PME.
Se sim, abre campo de dica.

---

## Nível 6 — Dica para IA

Campo curto para o corretor orientar a IA.

Exemplos:

- cliente achou caro;
- cliente quer entrada menor;
- cliente pediu para falar com esposa;
- cliente já visitou e está comparando;
- lead veio do Instagram e está frio.

---

## Nível 7 — Escolha uma ou tente novamente

A IA ou a base PME deve exibir opções reaproveitáveis.

Ações possíveis:

- usar esta;
- editar manualmente;
- pedir nova versão;
- copiar;
- abrir WhatsApp;
- preparar e-mail;
- copiar fala de ligação.

---

## Nível 8 — Score

Score operacional simples para o MVP.

Sugestão inicial:

- 0 = ruim / não útil;
- 1 = neutra;
- 2 = útil;
- 3 = muito útil;
- 4 = alta chance de avanço;
- 5 = converteu ou gerou ação forte.

---

## Nível 9 — Feedback

Feedback continua sendo decisão do corretor.

Não automatizar feedback por IA no MVP.

---

## Nível 10 — Associar nota com feedback

A resposta usada deve ser associada ao feedback final para medir efetividade.

Exemplo:

- origem: Lista fria;
- canal: WhatsApp;
- abordagem: Primeira abordagem;
- texto usado: script_id ou resposta_ia_id;
- score: 4;
- feedback: enviado_informacoes.

---

## Nível 11 — Nota final

Nota final pode combinar:

- score do corretor;
- feedback;
- canal;
- ação executada;
- se houve resposta do cliente futuramente.

No MVP, a nota pode começar simples e evoluir depois.

---

## Nível 12 — Salvar na base

Salvar evento de uso para aprendizado.

No MVP, antes de criar tabela definitiva, o contrato técnico deve definir se isso será mock/local/log controlado ou tabela auditável no Supabase.

---

## Nível 13 — Encerrar ou próximo lead

O fluxo termina com uma das ações:

- salvar e voltar ao lead;
- salvar e próximo lead;
- salvar e agendar retorno;
- salvar e finalizar contato.

---

## Observação de UX

No celular, o fluxo deve parecer um assistente guiado, não um painel técnico espremido. Corretor em plantão ou ligação não tem tempo para lutar contra botão. O sistema precisa trabalhar para ele, não o contrário.