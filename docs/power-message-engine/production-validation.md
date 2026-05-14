# FECH.AI — PME Production Validation Record

Status: PRODUCAO CONTROLADA / FRONTEND SEED  
Data: 2026-05-14  
Branch: main  
Escopo: PME Admin Shell, sem persistencia PME e sem integracao operacional.

---

## 1. Objetivo

Registrar o estado real da PME apos promocao para producao e separar claramente o que esta ativo, o que ainda e seed/frontend e o que depende de nova aprovacao.

Este documento evita a leitura errada de que a PME ja e motor operacional completo. Nao e. Ela esta publicada como central administrativa seed.

---

## 2. Estado real

A PME Admin Shell foi promovida para main via PR #5.

Commit de merge/squash:

```txt
ac54a56ad79c4ae9d022205936d5f5ad9a297a24
```

Deploy identificado como READY na Vercel:

```txt
fecha-fzfonzo24-wagnerjfjunior-3025s-projects.vercel.app
```

Como podem existir deploys mais recentes da main, a validacao funcional deve ser feita sempre na URL de producao mais recente.

---

## 3. O que entrou em producao

Entrou:

```txt
PME Admin Shell
Rota hash #pme-admin
Botao administrativo no HomeActions
Templates WhatsApp seed
Scripts de ligacao seed
Cadencias seed
Aviso visual de Seed Global FECH.AI
Documentacao de arquitetura
Auditoria de schema Supabase
Roadmap de persistencia
Draft SQL apenas documental
```

---

## 4. O que nao entrou

Nao entrou:

```txt
Migration Supabase PME
Novas tabelas pme_*
Novas policies RLS
Funcoes PME no banco
Integracao com discador
Integracao com Oferta Ativa/Acelerador
Envio automatico de WhatsApp
Integracao WABA
Integracao SMTP
Historico real de uso da PME
Randomizacao operacional persistida
```

A PME em producao, neste momento, e interface administrativa seed, nao motor operacional ativo.

---

## 5. Roteamento real

Arquivo:

```txt
src/main.jsx
```

Rota:

```txt
#pme-admin
```

Comportamento esperado:

```txt
window.location.hash === '#pme-admin' renderiza PowerMessageEngineAdmin
```

---

## 6. Entrada visual

Arquivo:

```txt
src/components/HomeActions.jsx
```

Entrada esperada:

```txt
PME — Central de Mensagens
Templates, scripts e cadencias
```

O botao deve aparecer apenas para perfis administrativos, gestores ou root.

---

## 7. Seguranca atual da tela

Arquivo principal:

```txt
src/components/PowerMessageEngineAdmin.jsx
```

A tela valida:

```txt
sessao local fechai_session
RPC is_root quando disponivel
tabela admins
tabela corretores
perfil admin/gestor/root
```

Perfis esperados com acesso:

```txt
root/admin_global
admin_local
gestor
```

Perfis sem acesso:

```txt
corretor comum sem papel gestor/admin
usuario sem sessao
usuario inativo
```

Essa validacao e suficiente para fase frontend/seed administrativa, mas nao substitui RLS de banco quando houver persistencia real.

---

## 8. Escopo dos conteudos atuais

Os conteudos atuais sao:

```txt
Seed Global FECH.AI
```

Eles ainda nao pertencem a empresa especifica.

Nao possuem ainda:

```txt
empresa_id
tenant_id
empreendimento_id
```

A interface deve deixar isso explicito com aviso visual de escopo.

---

## 9. Estado dos modulos

### Templates WhatsApp

Status: seed frontend funcional.

Contem:

```txt
90 templates WhatsApp seed
prioridade para lista_fria e visitou_plantao
badge Seed Global
aviso de ausencia de vinculo com empresa
```

### Scripts de Ligacao

Status: seed frontend funcional.

Contem scripts para:

```txt
lista_fria
visitou_plantao
```

Ainda nao integrado ao discador.

### Cadencias

Status: seed frontend funcional.

Contem cadencias assistidas para:

```txt
lista_fria
visitou_plantao
```

Ainda nao calcula proxima acao real por lead.

### Templates E-mail

Status: placeholder planejado.

Nao existe seed real de e-mail nesta fase.

### Historico

Status: placeholder planejado.

Nao existe tabela PME de historico nem registro real de uso.

---

## 10. Central de Mensagens atual / compatibilidade

Foi identificada funcao real existente no Supabase:

```txt
public.registrar_mensagem(p_lead_id uuid, p_canal text, p_seq integer)
```

Interpretacao atual:

```txt
registrar_mensagem = fluxo atual simples de mensagens
PME = novo motor administrativo e futuro motor assistivo
```

Decisao de governanca:

```txt
Nao remover nem substituir registrar_mensagem agora.
```

Antes da persistencia da PME, sera necessario definir uma ponte entre:

```txt
registrar_mensagem
leads.seq_email
leads.seq_whatsapp
futuro pme_message_usage
futuro pme_lead_message_state
```

---

## 11. Checklist obrigatorio de validacao

Validar em producao:

```txt
[ ] Root acessa a PME
[ ] Admin local acessa a PME
[ ] Gestor acessa a PME
[ ] Corretor comum nao acessa a PME
[ ] Usuario sem sessao nao acessa a PME
[ ] Botao PME aparece apenas para perfis permitidos
[ ] Botao voltar ao painel funciona
[ ] Aba Templates WhatsApp abre
[ ] Aba Scripts de Ligacao abre
[ ] Aba Cadencias abre
[ ] Aba E-mail aparece como planejada/placeholder
[ ] Aba Historico aparece como planejada/placeholder
[ ] Aviso Seed Global aparece
[ ] Nao ha erro visual quebrando a pagina
[ ] Nao ha escrita Supabase disparada pela PME
[ ] Discador continua funcionando como antes
[ ] Fluxo atual de mensagens nao foi afetado
```

---

## 12. Criterio para avancar para persistencia

So avancar para migration real quando:

```txt
[ ] Checklist de producao seed validado
[ ] Draft SQL revisado de tenant_id para empresa_id
[ ] Funcoes PME de acesso por empresa definidas
[ ] RLS desenhada com base nas funcoes reais
[ ] Ponte com registrar_mensagem definida
[ ] Estrategia de importacao de seeds definida
[ ] Rollback preparado
```

---

## 13. Decisao tecnica atual

A PME esta aprovada em producao somente como:

```txt
PME Admin v0.5 — frontend seed, admin-only, sem impacto operacional direto
```

Qualquer proxima fase envolvendo banco, RLS, discador, acelerador ou envio real precisa de aprovacao explicita.
