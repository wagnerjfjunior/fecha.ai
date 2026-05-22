# Backlog MVP — Discador Flow AI / PME v0.1

## Épico 1 — Correção visual mobile

- Corrigir script encavalado no canto esquerdo.
- Garantir layout mobile-first.
- Separar claramente: lead ativo, badges, canal, abordagem, mensagem/script e feedback.
- Remover redundância visual entre botões semelhantes.

## Épico 2 — Badges de situação

Badges iniciais:

- Lista fria;
- Já visitou;
- Redes Sociais;
- Problemas;
- Argumentações.

Cada badge deve alterar o contexto exibido pela PME.

## Épico 3 — Canal operacional

Canais:

- WhatsApp;
- Ligações;
- E-mail.

Cada canal deve gerar saída específica.

## Épico 4 — Tipos de abordagem

- Primeira abordagem;
- Retorno;
- Pós-ligação;
- Convite;
- Objeção de preço;
- Objeção de entrada;
- Sem resposta;
- Fim de contato.

## Épico 5 — Modal de mensagem/script

- Exibir texto selecionado em modal legível.
- Permitir editar manualmente antes de copiar.
- Exibir variáveis aplicadas: nome, corretor, empresa, empreendimento quando disponíveis.
- Nunca enviar automaticamente no MVP.

## Épico 6 — IA assistida

- Botão `Melhorar com IA`.
- Campo `Dê uma dica para IA`.
- Estado de carregamento.
- Estado de erro.
- Estado sem permissão/módulo inativo.
- Fallback para texto original.

## Épico 7 — Base de respostas utilizadas

- Registrar resposta visualizada.
- Registrar resposta copiada/usada.
- Associar resposta a canal, abordagem, score e feedback.
- Preparar estrutura para cache/reaproveitamento.

## Épico 8 — Score e feedback

- Score simples de 0 a 5.
- Associação com feedback final.
- Não alterar motor de feedback sem contrato separado.

## Épico 9 — E-mail

- Criar geração de assunto + corpo.
- Permitir copiar assunto.
- Permitir copiar corpo.
- Futuramente integrar SMTP/módulo e-mail, fora do MVP inicial.

## Épico 10 — Atualização para main

- Abrir PR draft.
- Validar diff.
- Executar caderno de testes.
- Registrar evidências.
- Solicitar aprovação explícita para merge.