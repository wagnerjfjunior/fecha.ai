# MAIN MERGE CHECKLIST — FECH.AI

Checklist obrigatório antes de promover qualquer alteração para `main`.

---

## 1. Identificação

- [ ] Branch de origem identificada.
- [ ] PR criado.
- [ ] Protocolo relacionado identificado.
- [ ] Release package criado.
- [ ] Changelog atualizado.

## 2. Segurança

- [ ] Nenhuma chave secreta no frontend.
- [ ] Nenhum `service_role` exposto.
- [ ] Nenhum `tenant_id` aceito como verdade soberana do frontend.
- [ ] Nenhum `empresa_id` aceito como verdade soberana do frontend.
- [ ] Auth/JWT revisado para chamadas sensíveis.
- [ ] CORS revisado.

## 3. Banco de dados

- [ ] Migrations revisadas, se houver.
- [ ] Rollback de migration definido, se houver.
- [ ] Tabelas novas documentadas, se houver.
- [ ] RPCs novas documentadas, se houver.
- [ ] RLS documentada, se houver.

## 4. Frontend

- [ ] Mobile validado.
- [ ] Layout não encavala.
- [ ] Botões funcionam.
- [ ] Estados de loading definidos.
- [ ] Estados de erro definidos.
- [ ] Fallback sem IA validado.

## 5. IA

- [ ] IA não é chamada com chave secreta no frontend.
- [ ] Edge Function validada.
- [ ] Erro de IA não trava operação.
- [ ] Usuário sem sessão/token recebe mensagem clara.
- [ ] Prompt não inventa preço, unidade, desconto ou condição.

## 6. Operação

- [ ] Feedback continua manual.
- [ ] Lead continua carregando.
- [ ] Próximo lead continua funcionando.
- [ ] Registrar feedback continua funcionando.
- [ ] WhatsApp não é enviado automaticamente.
- [ ] E-mail não é enviado automaticamente.

## 7. Rollback

- [ ] Rollback visual definido.
- [ ] Rollback IA definido.
- [ ] Rollback backend definido, se houver.
- [ ] Caminho de emergência documentado.

## 8. Aprovação

- [ ] Dry-run aprovado.
- [ ] Teste funcional aprovado.
- [ ] Teste segurança aprovado.
- [ ] Merge autorizado explicitamente.
