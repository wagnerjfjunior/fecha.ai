# Post Merge Checklist — Discador Flow AI / PME MVP v0.1

Checklist para depois do merge em `main`.

---

## Verificação imediata

- [ ] Deploy Vercel finalizado com sucesso.
- [ ] Login funcionando.
- [ ] Discador abre no desktop.
- [ ] Discador abre no celular.
- [ ] Lead ativo carrega.
- [ ] Bloco PME aparece onde esperado.
- [ ] Feedback manual registra.
- [ ] Próximo lead funciona.

## IA

- [ ] Botão IA aparece somente quando previsto.
- [ ] IA responde quando sessão válida.
- [ ] IA falha com mensagem clara quando sessão expirada.
- [ ] Texto base permanece utilizável sem IA.

## Segurança

- [ ] Console sem chave secreta.
- [ ] Network sem `service_role`.
- [ ] Nenhum envio automático disparado.

## Monitoramento

- [ ] Verificar console do navegador.
- [ ] Verificar logs da Edge Function, se aplicável.
- [ ] Verificar erro 401/JWT expired.
- [ ] Verificar CORS.

## Decisão pós-merge

- [ ] Manter ativo.
- [ ] Desativar IA.
- [ ] Rollback visual.
- [ ] Rollback completo.
