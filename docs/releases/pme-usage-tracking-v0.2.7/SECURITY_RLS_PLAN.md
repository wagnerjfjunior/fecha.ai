# SECURITY_RLS_PLAN — PME Usage Tracking & Script Utility v0.2.7

## 1. Princípio de segurança

O FECH.AI é SaaS multi-tenant e multiempresa. Portanto, eventos do PME não podem depender de tenant, empresa ou permissão enviados livremente pelo frontend.

Regra central:

> Frontend informa o clique; backend decide se pode gravar.

---

## 2. Riscos principais

| Risco | Impacto | Mitigação |
|---|---|---|
| Frontend enviar `tenant_id` falso | vazamento/corrupção cross-tenant | resolver tenant pelo `auth.uid()` no backend |
| Usuário registrar evento em lead de outra empresa | vazamento operacional | validar lead contra tenant/empresa do usuário |
| Persistir texto sensível | risco LGPD | salvar hash/metadados no MVP |
| Usar service_role no navegador | incidente crítico | proibido; nunca expor service role |
| Tracking bloquear atendimento | perda operacional | chamadas assíncronas e não bloqueantes |
| RLS fraca | acesso indevido | policies por tenant/empresa/perfil |
| Metadata livre demais | vazamento indireto | whitelist de chaves permitidas |

---

## 3. Regras obrigatórias da RPC

A RPC `registrar_pme_script_usage` deve:

1. exigir usuário autenticado;
2. obter `v_user_id := auth.uid()`;
3. resolver tenant/empresa/perfil do usuário no banco;
4. rejeitar usuário sem tenant/empresa ativa;
5. validar enums;
6. validar `lead_id`, se enviado;
7. ignorar ou sobrescrever `tenant_id`, `empresa_id` e `user_id` vindos do frontend;
8. limitar tamanho de campos textuais;
9. filtrar `metadata` por allowlist;
10. inserir evento com dados resolvidos no backend;
11. retornar resposta mínima.

---

## 4. Dados soberanos

Campos soberanos do backend:

- `tenant_id`;
- `empresa_id`;
- `user_id`;
- permissões/perfil;
- validação de lead;
- decisão de insert.

Campos aceitos do frontend apenas como contexto:

- `event_type`;
- `module_version`;
- `context`;
- `channel`;
- `approach`;
- `script_source`;
- `script_variant`;
- `script_text_hash`;
- `ai_attempt`;
- `ai_tip_hash`;
- `execution_target`;
- `client_timestamp`.

---

## 5. RLS proposta

Ativar RLS:

```sql
alter table public.pme_script_usage_events enable row level security;
```

### 5.1 Policy de SELECT

Usuário comum só vê eventos do próprio tenant/empresa, conforme perfil.

Exemplo conceitual:

```sql
create policy pme_usage_select_same_tenant
on public.pme_script_usage_events
for select
to authenticated
using (
  tenant_id in (
    select tenant_id
    from public.user_empresa_perfis
    where user_id = auth.uid()
      and ativo = true
  )
);
```

> Ajustar nomes reais das tabelas de vínculo usuário/empresa/perfil antes de aplicar.

### 5.2 Policy de INSERT

Preferência: não permitir insert direto na tabela pelo frontend. Inserir somente via RPC `security definer` com validação interna.

Modelo recomendado:

```sql
revoke insert on public.pme_script_usage_events from authenticated;
```

Depois conceder execução apenas da RPC:

```sql
grant execute on function public.registrar_pme_script_usage(jsonb) to authenticated;
```

---

## 6. RPC `security definer`

Se usar `security definer`, obrigatório:

- definir `set search_path = public` ou schema seguro explícito;
- não concatenar SQL dinâmico;
- validar todos os campos;
- não confiar em IDs enviados pelo cliente;
- auditar exceções;
- retornar erros controlados.

Exemplo conceitual:

```sql
create or replace function public.registrar_pme_script_usage(p_event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_tenant_id uuid;
  v_empresa_id uuid;
  v_event_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  -- Resolver tenant/empresa/perfil do usuário aqui.
  -- Validar lead_id aqui.
  -- Validar enums aqui.
  -- Inserir evento aqui.

  return jsonb_build_object('ok', true, 'id', v_event_id);
end;
$$;
```

---

## 7. Metadata allowlist

Para v0.2.7, `metadata` deve aceitar apenas chaves não sensíveis.

Permitidas:

- `ui_action`;
- `button_label`;
- `has_phone`;
- `has_email`;
- `modal_open`;
- `error_code`;
- `preview_mode`;
- `source_component`.

Proibidas:

- texto completo da mensagem;
- telefone puro;
- e-mail puro;
- nome completo do lead;
- documentos;
- valores financeiros pessoais;
- conversas completas;
- tokens;
- headers;
- dados de autenticação.

---

## 8. Hashes

Hash recomendado no frontend:

- SHA-256 do texto normalizado;
- lower/trim/compact spaces quando fizer sentido;
- sem enviar texto original no MVP.

Hash de telefone:

- preferencialmente calculado no backend quando possível;
- se calculado no frontend, nunca substituir validação do backend.

---

## 9. Rate limiting lógico

Evitar flood de eventos:

- `script_viewed`: debounce ou registrar apenas quando muda contexto/canal/situação;
- `script_variant_changed`: registrar clique, mas limitar spam;
- `ai_failed`: registrar com cuidado para não gerar loop;
- `script_executed`: sempre registrar tentativa de execução.

---

## 10. Checklist DevSecOps

Antes de merge:

- [ ] Sem `service_role` no frontend.
- [ ] Sem segredo no console.
- [ ] Sem texto completo sensível persistido.
- [ ] RPC valida `auth.uid()`.
- [ ] RPC resolve tenant/empresa no backend.
- [ ] RLS ativa.
- [ ] Insert direto bloqueado ou estritamente controlado.
- [ ] Select restrito por tenant/empresa/perfil.
- [ ] Erro de tracking não bloqueia atendimento.
- [ ] Logs não exibem tokens ou payload sensível.

---

## 11. Decisão para v0.2.7

A v0.2.7 deve priorizar segurança e mensuração mínima. O produto de analytics completo fica para versões futuras.
