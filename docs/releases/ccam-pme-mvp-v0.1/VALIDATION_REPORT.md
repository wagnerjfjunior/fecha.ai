# Validation Report — Discador Flow AI / PME MVP v0.1

**Status:** em aberto

---

## Evidência analisada

HAR enviado: `chateau IA json tela anonima console root login fecha-ai.vercel.app.har`

### Achados iniciais

- RPC `get_contagens_corretor` retornando `401 JWT expired`.
- Edge Function `functions/v1/assistente-ai` com `OPTIONS 200`.
- POST para `assistente-ai` aparece com status `0`, típico de bloqueio/falha de rede/CORS/runtime sem resposta visível ao navegador.

## Hipótese técnica inicial

A IA não está funcionando por combinação de:

1. sessão/JWT expirada;
2. POST da Edge Function sem resposta navegável;
3. possível problema de CORS/headers/runtime da função;
4. ausência de fallback claro no frontend.

## Testes pendentes

- [ ] Reautenticar usuário e repetir chamada.
- [ ] Validar Edge Function via curl com JWT válido.
- [ ] Validar resposta OPTIONS e POST.
- [ ] Confirmar se `assistente-ai` retorna JSON padronizado.
- [ ] Confirmar se frontend exibe erro amigável.
- [ ] Confirmar que o fluxo manual funciona sem IA.

## Resultado final

Pendente.
