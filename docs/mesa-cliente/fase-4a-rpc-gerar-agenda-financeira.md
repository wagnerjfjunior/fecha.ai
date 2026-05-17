# Mesa do Cliente — Fase 4A: RPC de agenda financeira segura

## Status

Fase pronta para execução controlada na branch `feature/mesa-cliente-engenharia-financeira`.

Esta fase é a primeira entrega de backend operacional da engenharia financeira. O objetivo é criar a espinha dorsal da agenda financeira por simulação, sem alterar frontend, parser, Worker, Make, n8n ou motor financeiro atual fora da migration proposta.

## Trava obrigatória para qualquer conversa/dev/IA antes de escrever a migration

Antes de qualquer SQL ser criado, alterado ou aplicado, respeitar integralmente este contrato:

1. Não mexer no frontend.
2. Não mexer no parser.
3. Não mexer no Worker/Make/n8n.
4. Não mexer no motor financeiro atual fora da migration proposta.
5. Não criar regra hardcoded no client.
6. Não criar RPC com `empresa_id` soberano vindo do frontend.
7. Não expor VPL, prêmio, comissão ou política para resposta client-safe.
8. Não conceder `execute` para `anon`.
9. Toda RPC nova precisa usar `security definer`.
10. Toda RPC nova precisa usar `set search_path = public`.
11. Toda execução real precisa passar por teste com `BEGIN` + `ROLLBACK` antes de qualquer commit lógico de dados.

Se qualquer item acima for quebrado, a implementação deve ser considerada inválida, mesmo que compile. Segurança aqui não é enfeite de bolo; é a massa do bolo.

---

## Objetivo técnico da Fase 4A

Criar uma RPC administrativa para gerar uma agenda financeira normalizada a partir de uma simulação existente do Mesa do Cliente.

A RPC deve:

- receber apenas identificadores mínimos e parâmetros de simulação;
- derivar tenant/empresa pelo usuário autenticado e pelo relacionamento da simulação;
- validar usuário ativo;
- validar vínculo de tenant/empresa;
- validar empreendimento;
- validar simulação;
- validar perfil/autorização;
- gerar linhas de agenda em JSON ou persistir em tabela própria, conforme decisão de schema;
- nunca confiar em `empresa_id` enviado pelo frontend como verdade soberana;
- nunca retornar campos sensíveis em modo cliente-safe.

---

## Entregável esperado

### 1. Migration única da Fase 4A

Nome sugerido:

```text
supabase/migrations/YYYYMMDDHHMMSS_mesa_cliente_fase_4a_rpc_gerar_agenda_financeira.sql
```

A migration deve conter, no mínimo:

- criação da função/RPC;
- `revoke execute on function ... from anon`;
- `grant execute on function ... to authenticated`;
- comentários de segurança;
- bloco de teste rollback documentado no final como comentário, ou arquivo separado de teste SQL.

### 2. RPC proposta

Nome sugerido:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(...)
```

Sugestão de assinatura inicial:

```sql
create or replace function public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_modo text default 'admin'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
...
$$;
```

Observação: não usar `p_empresa_id` como parâmetro soberano. Caso seja tecnicamente necessário receber empresa para compatibilidade futura, a função deve tratar esse campo apenas como filtro/conferência, nunca como autoridade.

---

## Validações obrigatórias dentro da RPC

### 1. Autenticação

A RPC deve bloquear chamada sem usuário autenticado:

```sql
if auth.uid() is null then
  raise exception 'AUTH_REQUIRED';
end if;
```

### 2. Usuário ativo

Validar se o usuário autenticado existe no cadastro interno e está ativo.

A validação deve considerar o modelo real do projeto, por exemplo tabela de perfis, usuários, corretores ou memberships. Não inventar tabela se ela já existir.

Falha esperada:

```text
USER_INACTIVE_OR_NOT_FOUND
```

### 3. Tenant/empresa

A empresa/tenant deve ser derivada da relação real do usuário com a empresa e/ou da própria simulação.

Proibido:

```text
frontend envia empresa_id e RPC aceita sem conferir
```

Obrigatório:

- buscar o contexto do usuário;
- confirmar que a simulação pertence a empresa acessível pelo usuário;
- confirmar que a empresa está ativa;
- impedir acesso cruzado entre empresas.

Falha esperada:

```text
EMPRESA_FORBIDDEN
```

### 4. Empreendimento

A simulação deve estar vinculada a empreendimento válido e pertencente à empresa/tenant autorizado.

Falha esperada:

```text
EMPREENDIMENTO_INVALIDO_OU_FORA_DA_EMPRESA
```

### 5. Simulação

A simulação deve existir e estar dentro do escopo da empresa/tenant do usuário.

Falha esperada:

```text
SIMULACAO_NOT_FOUND_OR_FORBIDDEN
```

### 6. Perfil

A RPC administrativa deve restringir execução a perfis autorizados.

Perfis sugeridos para liberar:

- root;
- admin;
- gestor;
- perfil financeiro, se existir no modelo.

Perfis comerciais comuns devem ser tratados com cautela. Corretor pode ver agenda client-safe futuramente, mas não necessariamente gerar agenda administrativa com metadados financeiros sensíveis.

Falha esperada:

```text
PERFIL_SEM_PERMISSAO
```

---

## Regra de exposição de dados

A Fase 4A não deve expor para cliente-safe:

- VPL;
- prêmio;
- comissão;
- política financeira interna;
- margem;
- score interno;
- parâmetros de desconto;
- taxa interna sensível;
- qualquer campo usado para governança financeira da incorporadora/imobiliária.

A resposta client-safe, quando existir em fase futura, deve conter apenas agenda legível de parcelas e totais necessários para atendimento na mesa.

Nesta fase, se a RPC for administrativa, retornar metadados apenas para perfis autorizados.

---

## Estratégia de implementação recomendada

### Caminho A — preferencial

Gerar a agenda como `jsonb`, sem persistir ainda, até validar consistência financeira.

Vantagem:

- menor risco de sujar banco;
- fácil testar com `BEGIN` + `ROLLBACK`;
- evita refatoração prematura.

Formato mínimo esperado do JSON:

```json
{
  "ok": true,
  "simulacao_id": "uuid",
  "empresa_id": "uuid-derivado-no-banco",
  "empreendimento_id": "uuid-derivado-no-banco",
  "modo": "admin",
  "agenda": [
    {
      "grupo": "entrada",
      "ordem": 1,
      "descricao": "Sinal",
      "vencimento": "2026-05-17",
      "valor": 10000.00,
      "client_safe": true
    }
  ],
  "totais": {
    "valor_total": 0,
    "quantidade_parcelas": 0
  }
}
```

### Caminho B — apenas depois

Persistir em tabela `mesa_cliente_agenda_financeira` quando a estrutura estiver validada.

Não antecipar persistência se a agenda ainda não estiver estável. Primeiro nasce a espinha dorsal; depois coloca o terno no boneco.

---

## Padrão SQL obrigatório da RPC

```sql
create or replace function public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_modo text default 'admin'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_uid uuid;
  v_usuario record;
  v_simulacao record;
  v_empresa_id uuid;
  v_empreendimento_id uuid;
  v_result jsonb;
begin
  v_auth_uid := auth.uid();

  if v_auth_uid is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  -- 1. Buscar usuário ativo conforme schema real.
  -- 2. Validar perfil.
  -- 3. Buscar simulação e derivar empresa/empreendimento pelo banco.
  -- 4. Validar vínculo usuário x empresa.
  -- 5. Validar empreendimento x empresa.
  -- 6. Gerar agenda financeira.
  -- 7. Retornar JSON sem dados sensíveis para client-safe.

  return v_result;
end;
$$;

revoke all on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, text) from public;
revoke execute on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, text) from anon;
grant execute on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, text) to authenticated;
```

Esse bloco é modelo contratual. A implementação real deve usar os nomes reais de tabelas, colunas e funções auxiliares já existentes no banco.

---

## Teste obrigatório com BEGIN + ROLLBACK

Executar primeiro em ambiente controlado:

```sql
begin;

select public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id := '<UUID_DE_SIMULACAO_DE_TESTE>'::uuid,
  p_modo := 'admin'
);

rollback;
```

### Testes negativos obrigatórios

1. Chamada sem JWT/autenticação deve falhar com `AUTH_REQUIRED`.
2. Usuário inativo deve falhar.
3. Usuário de empresa A tentando simulação da empresa B deve falhar.
4. Empreendimento fora da empresa deve falhar.
5. Simulação inexistente deve falhar.
6. Perfil sem permissão deve falhar.
7. `anon` não pode executar a função.
8. Resposta não pode conter VPL, prêmio, comissão ou política interna quando o modo for client-safe ou equivalente.

---

## Critério de aceite da Fase 4A

A fase só pode ser considerada concluída quando:

- migration criada na branch correta;
- RPC compila;
- `security definer` aplicado;
- `search_path = public` aplicado;
- `anon` sem grant de execução;
- `authenticated` com grant restrito;
- validações obrigatórias implementadas;
- teste `BEGIN` + `ROLLBACK` executado;
- testes negativos documentados;
- nenhuma alteração feita em frontend/parser/Worker/Make/n8n;
- nenhuma regra hardcoded no client;
- nenhum dado sensível exposto para cliente-safe.

---

## Fora de escopo da Fase 4A

Não fazer nesta fase:

- tela nova;
- preview novo;
- alteração na `main`;
- alteração no parser;
- alteração no Worker/Make/n8n;
- cálculo final de prêmio/comissão;
- política financeira parametrizada completa;
- engine avançada de negociação;
- persistência definitiva de proposta;
- geração de PDF ou apresentação para cliente.

---

## Próxima fase após aprovação da 4A

Fase 4B sugerida:

- tabela normalizada de agenda financeira, se a 4A retornar JSON consistente;
- RPC client-safe separada;
- diferenciação explícita entre visão administrativa e visão de mesa;
- testes multiempresa com massa controlada;
- auditoria de grants, RLS e advisors do Supabase.
