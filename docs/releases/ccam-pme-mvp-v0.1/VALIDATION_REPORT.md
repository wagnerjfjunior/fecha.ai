# Validation Report — Discador Flow AI / PME MVP v0.1

**Status:** em aberto

---

## Evidência analisada

HAR enviado: `chateau IA json tela anonima console root login fecha-ai.vercel.app.har`

### Achados iniciais

- RPC `get_contagens_corretor` retornando `401 JWT expired`.
- Edge Function `functions/v1/assistente-ai` com `OPTIONS 200`.
- POST para `assistente-ai` aparece com status `0`, típico de bloqueio/falha de rede/CORS/runtime sem resposta visível ao navegador.
- No POST da IA no HAR, não havia header `Authorization` com Bearer token visível.
- O preflight `OPTIONS` permitia `authorization` e `content-type`; por isso o frontend v0.2.1 removeu `apikey` da chamada da Edge Function e passou a usar somente `Authorization` + `Content-Type`.

## Hipótese técnica inicial

A IA não está funcionando por combinação de:

1. sessão/JWT expirada;
2. POST da Edge Function sem `Authorization` válido;
3. possível bloqueio de CORS quando headers fora da allowlist são enviados;
4. ausência de fallback claro no frontend.

## Correções aplicadas no frontend v0.2.1

- Header visual com título `Discador Flow AI`.
- Bloco de informações do lead.
- Badges centralizados no mobile e desktop.
- Canais centralizados no mobile e desktop.
- Power Dial, Power Zap e Power Mail posicionados acima dos badges Ligação, WhatsApp e E-mail.
- Removidos da tela principal os botões redundantes:
  - Abrir/editar;
  - Trocar opção;
  - Copiar texto;
  - Copiar e-mail;
  - Score de utilidade do script.
- Tela principal agora usa apenas 4 ações:
  - Utilizar;
  - Voltar;
  - Próximo;
  - Melhorar com IA.
- Evento de clique passou a usar delegação única para reduzir falha de clique duplo causada por re-render.
- Chamada da IA agora valida token ausente/expirado antes do POST.
- Chamada da IA removeu `apikey` para evitar conflito com CORS da Edge Function atual.

## Testes pendentes

- [ ] Reautenticar usuário e repetir chamada.
- [ ] Validar Edge Function via curl com JWT válido.
- [ ] Validar resposta OPTIONS e POST.
- [ ] Confirmar se `assistente-ai` retorna JSON padronizado.
- [ ] Confirmar se frontend exibe erro amigável.
- [ ] Confirmar que o fluxo manual funciona sem IA.
- [ ] Validar se os badges respondem com um clique no mobile.
- [ ] Validar se os badges ficam centralizados no desktop.
- [ ] Validar se Power Dial/Power Zap/Power Mail aparecem acima dos canais corretos.

## Resultado final

Pendente.