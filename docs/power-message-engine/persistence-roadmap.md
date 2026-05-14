# FECH.AI — PME Persistence Roadmap

Status: **DRAFT / PLANEJAMENTO**

Este roadmap organiza a transição da PME de seed frontend para persistência real no Supabase.

---

## 1. Estado atual

A PME Admin já possui, na branch `feature/pme-admin-shell`:

- tela administrativa isolada;
- rota/hash dedicada;
- validação de acesso admin/root;
- painel de templates WhatsApp;
- 90 mensagens seed;
- prioridade operacional para `visitou_plantao` e `lista_fria`;
- scripts de ligação seed;
- painel de scripts;
- cadências seed;
- painel de cadências;
- governança básica;
- histórico preparado como conceito.

Nada disso altera:

- banco;
- RLS;
- RPCs centrais;
- discador;
- acelerador;
- envio real de WhatsApp.

---

## 2. Objetivo da persistência

Transformar a PME em uma estrutura operacional editável por admin/gestor, com segurança multi-tenant.

A persistência deve permitir:

- cadastrar templates;
- editar templates;
- inativar templates;
- importar seeds;
- cadastrar scripts;
- cadastrar cadências;
- registrar histórico de uso;
- registrar estado da cadência por lead;
- futuramente sugerir próxima melhor ação ao corretor.

---

## 3. Fases recomendadas

### Fase 1 — Auditoria do schema real

Antes de qualquer SQL real:

- confirmar tabela real de tenants/empresas;
- confirmar vínculo usuário → tenant;
- confirmar papéis reais: root, admin, gestor, corretor;
- confirmar tabela real de leads;
- confirmar coluna de corretor responsável pelo lead;
- confirmar tabela real de feedback;
- confirmar padrão real de migrations no projeto.

Entrega:

- documento `schema-audit-pme.md`;
- matriz de compatibilidade;
- lista de riscos.

---

### Fase 2 — Migration PME em ambiente controlado

Criar tabelas com prefixo `pme_`:

- `pme_message_templates`
- `pme_call_scripts`
- `pme_cadences`
- `pme_cadence_steps`
- `pme_lead_message_state`
- `pme_message_usage`

Regras:

- não usar FK para tabelas existentes antes de validar nomes reais;
- usar `tenant_id` obrigatório;
- usar `is_active` para desligamento lógico;
- usar `seed_key` para importação idempotente.

Entrega:

- migration real revisada;
- rollback claro;
- ambiente testado.

---

### Fase 3 — RLS e autorização

Criar funções:

- `pme_can_access_tenant(p_tenant_id uuid)`
- `pme_is_tenant_admin(p_tenant_id uuid)`
- `pme_can_consume_tenant(p_tenant_id uuid)`

Criar policies por tabela.

Entrega:

- policies testadas;
- testes positivos;
- testes negativos.

---

### Fase 4 — Seed import

Criar processo de importação para:

- templates WhatsApp;
- scripts de ligação;
- cadências;
- passos das cadências.

Regras:

- importação idempotente via `seed_key`;
- não duplicar mensagens;
- permitir marcar seeds como `is_seed = true`;
- permitir admin inativar seed sem perder histórico.

Entrega:

- script SQL ou função RPC de import;
- relatório de importação.

---

### Fase 5 — Admin PME usando Supabase

A tela admin deixa de ler apenas seeds JS e passa a ler Supabase.

Regras:

- manter fallback de seed apenas se necessário para dev;
- listar templates do tenant;
- editar/inativar templates;
- visualizar scripts;
- visualizar cadências;
- filtrar por lead_type, canal, fase e status.

Entrega:

- Admin PME persistente;
- sem integração ainda com discador.

---

### Fase 6 — Consumo assistido no Acelerador/Discador

Somente depois da Fase 5:

- detectar tipo do lead;
- sugerir próxima mensagem;
- sugerir script de ligação;
- registrar uso;
- registrar feedback;
- atualizar estado da cadência.

Regras:

- corretor sempre executa ação manualmente na primeira versão;
- sem envio automático;
- sem disparo massivo;
- respeitar opt-out.

Entrega:

- PME consumida pelo fluxo operacional;
- histórico auditável.

---

## 4. O que não fazer agora

Não fazer ainda:

- disparo automático de WhatsApp;
- integração WABA;
- integração com chip comum;
- integração com SMTP;
- automação de cadência sem ação humana;
- alteração do motor do discador;
- alteração de RPCs centrais;
- RLS sem auditoria real.

---

## 5. Definição de pronto para banco

Podemos aplicar migration real somente quando:

- schema real estiver auditado;
- nomes de tabelas e colunas forem confirmados;
- função de tenant access estiver definida;
- rollback estiver pronto;
- preview da PME continuar estável;
- root/admin continuar com acesso correto;
- corretor comum continuar sem acesso administrativo.

---

## 6. Definição de pronto para corretor

Podemos liberar para corretor somente quando:

- admin consegue gerenciar templates;
- templates têm status ativo/inativo;
- cadências têm parada por feedback;
- histórico registra uso;
- opt-out bloqueia sugestão;
- discador recebe apenas próxima ação simples;
- tela do corretor não expõe complexidade administrativa.

O corretor deve ver algo simples:

```txt
Próxima ação recomendada:
Enviar WhatsApp 2ª tentativa — Lista fria
[Copiar mensagem] [Ligar agora] [Registrar feedback]
```

Não deve ver a fábrica inteira. Quem mostra fábrica para corretor no meio da ligação merece timeout arquitetural.
