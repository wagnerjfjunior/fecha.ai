# FECH.AI — Tenant Provisioning e Administração de Usuários

## Status

Documento normativo para o fluxo administrativo de usuários, empresas e isolamento multi-tenant do FECH.AI.

Este documento nasce após a validação real do ambiente Supabase, RLS, tabela `corretores`, tabela `empresas`, Edge Function `criar-usuario` e comportamento atual do frontend administrativo.

---

## Princípio soberano

No FECH.AI, `empresa_id` não é campo cadastral comum.

`empresa_id` é o boundary soberano de tenant.

Portanto:

```text
empresa_id nunca deve ser campo aberto no frontend.
```

---

## Regra oficial de usuário operacional

```text
1 login operacional = 1 tenant ativo
```

Quando uma pessoa muda de empresa:

1. o usuário operacional antigo é desativado;
2. o histórico é preservado;
3. um novo usuário operacional é criado no novo tenant;
4. o novo usuário recebe novo Auth User/JWT;
5. métricas, lotes e leads antigos permanecem no tenant de origem.

---

## Fluxo correto para criação de usuário

```text
Admin/Gestor logado
↓
Tela Administração > Usuários
↓
CriarUsuarioForm.jsx
↓
Edge Function criar-usuario
↓
Supabase Auth
↓
public.corretores
↓
must_change_password = true
↓
Primeiro login exige troca de senha
```

---

## Fluxo proibido

Não criar usuários operacionais diretamente via SQL em `public.corretores`.

Isso cria registros órfãos sem `auth.users` e sem JWT.

Exemplo proibido:

```sql
INSERT INTO public.corretores (...)
```

O fluxo correto sempre passa pela Edge Function `criar-usuario`.

---

## Campo Empresa no frontend

### Admin local

Não escolhe empresa.

A empresa deve vir do contexto autenticado:

```sql
my_empresa_id()
```

No frontend, exibir como leitura ou esconder.

### Gestor

Não escolhe empresa.

Também deve operar exclusivamente dentro da própria empresa.

### Root Platform Admin

Pode escolher empresa, mas somente via `select` controlado com IDs reais de `public.empresas`.

Nunca texto livre.

---

## Criação de empresa

A criação de empresa deve ser exclusiva de root/platform admin.

Fluxo alvo:

```text
Root Admin
↓
Criar Empresa
↓
Selecionar Plano
↓
Criar registro em public.empresas
↓
Criar public.empresas_configuracoes default
↓
Criar admin local inicial via Edge Function
↓
Criar time inicial
↓
Ativar tenant
```

---

## Tela necessária

Criar módulo futuro:

```text
Platform Admin > Empresas
```

Funções mínimas:

- listar empresas;
- criar empresa;
- selecionar plano;
- definir status ativa/inativa;
- criar admin local inicial;
- criar time inicial;
- configurar defaults do tenant.

---

## Regras de permissão

| Perfil | Pode criar empresa | Pode selecionar empresa ao criar usuário | Pode criar usuário |
|---|---:|---:|---:|
| Root | Sim | Sim, via select | Sim |
| Admin local | Não | Não | Sim, na própria empresa |
| Gestor | Não | Não | Sim, somente corretor do próprio time |
| Corretor | Não | Não | Não |

---

## Edge Function oficial

Função:

```text
criar-usuario
```

Responsabilidades:

- validar JWT do solicitante;
- validar root/admin/gestor;
- validar tenant alvo;
- criar Auth User;
- inserir em `corretores` com `user_id` preenchido;
- marcar `must_change_password = true`;
- aplicar rollback se o insert operacional falhar;
- registrar auditoria.

---

## Correção imediata decidida

1. Consolidar `CriarUsuario.jsx` como adapter para `CriarUsuarioForm.jsx`.
2. Manter `CriarUsuarioForm.jsx` como único fluxo real de criação.
3. Remover edição livre de empresa em telas administrativas.
4. Preparar, em etapa seguinte, tela root `Empresas`.

---

## Risco evitado

Esta regra evita:

- usuário órfão sem Auth;
- troca indevida de tenant;
- contaminação de métricas;
- vazamento cross-tenant;
- criação manual insegura;
- inconsistência entre Auth e `corretores`.

---

## Conclusão

O FECH.AI passa a tratar criação de usuários e empresas como processo formal de provisioning SaaS, não como edição simples de cadastro.
