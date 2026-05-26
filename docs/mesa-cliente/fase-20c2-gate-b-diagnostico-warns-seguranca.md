# FECH.AI / MesaCliente — Fase 20C.2
# Gate B — Diagnóstico dos WARNs de segurança

## 1. Status

```text
Status: DIAGNÓSTICO ATUALIZADO / READ-ONLY
Data: 2026-05-26
Projeto Supabase: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
DDL executado por esta etapa: NÃO
DML executado por esta etapa: NÃO
Migration aplicada por esta etapa: NÃO
RPC alterada por esta etapa: NÃO
Frontend alterado por esta etapa: NÃO
```

Este documento registra o diagnóstico read-only dos WARNs levantados no preflight 20C.1 e a revalidação após hardening manual executado fora desta etapa.

## 2. WARNs analisados

```text
1. mesa_cliente_agendas_financeiras com TRUNCATE para authenticated.
2. corretores com anon SELECT.
3. RLS forced=false em tabelas financeiras canônicas.
4. corpo das RPCs administrativas financeiras ainda não revisado integralmente.
```

## 3. Estado inicial observado

Consulta inicial de privilégios diretos confirmou:

```text
corretores:
- anon SELECT
- authenticated SELECT
- authenticated UPDATE

mesa_cliente_agendas_financeiras:
- authenticated REFERENCES
- authenticated SELECT
- authenticated TRIGGER
- authenticated TRUNCATE

mesa_cliente_fluxo_operacoes:
- authenticated SELECT

mesa_cliente_fluxo_parcelas:
- authenticated SELECT

mesa_cliente_politica_premio_faixas:
- authenticated SELECT

mesa_cliente_politicas_financeiras:
- authenticated SELECT
```

## 4. Hardening manual informado e revalidado

Após execução manual de comandos de hardening, foi reexecutada consulta read-only no Supabase real para `public.mesa_cliente_agendas_financeiras` filtrando `anon`, `authenticated` e `public`.

Resultado atual confirmado:

```text
mesa_cliente_agendas_financeiras:
- authenticated SELECT
```

Não apareceram mais grants para `authenticated` de:

```text
- REFERENCES
- TRIGGER
- TRUNCATE
```

Também não apareceu grant para `anon` ou `public` nessa tabela.

## 5. Diagnóstico 1 — TRUNCATE em mesa_cliente_agendas_financeiras

### 5.1 Estado inicial

```text
A role authenticated possuía privilégio TRUNCATE direto em public.mesa_cliente_agendas_financeiras.
```

### 5.2 Impacto técnico

TRUNCATE é operação de tabela inteira. Em PostgreSQL, operações de tabela inteira como TRUNCATE e REFERENCES não são submetidas às policies de Row Level Security.

Além disso, TRUNCATE exige privilégio específico de tabela.

### 5.3 Estado atual

```text
RESOLVIDO NO BANCO REAL.
```

A role `authenticated` ficou apenas com:

```text
SELECT
```

### 5.4 Classificação atual

```text
Classificação: RESOLVED_DB / PENDING_VERSIONING
```

### 5.5 Observação de controle

A correção foi observada no banco real, mas precisa ser versionada em migration no GitHub para evitar drift entre ambientes.

## 6. Diagnóstico 2 — anon SELECT em corretores

### 6.1 Fato observado

```text
A role anon possui SELECT direto em public.corretores.
```

A policy `corretores_select` está declarada para `{public}` e usa:

```text
is_root()
is_admin_local()
is_gestor()
my_times_como_gestor()
auth.uid()
```

### 6.2 Teste efetivo read-only

Foi executado:

```sql
begin read only;
set local role anon;
select count(*)::bigint as corretores_visiveis_para_anon from public.corretores;
rollback;
```

Resultado:

```text
ERROR: permission denied for function my_empresa_id
```

Também foi executado:

```sql
begin read only;
set local role authenticated;
select count(*)::bigint as corretores_visiveis_authenticated_sem_jwt from public.corretores;
rollback;
```

Resultado:

```text
0 registros visíveis para authenticated sem JWT/auth.uid().
```

### 6.3 Grants das funções auxiliares

As funções abaixo possuem EXECUTE para authenticated, postgres e service_role, mas não para anon:

```text
is_admin_local
is_gestor
is_root
my_empresa_id
my_times_como_gestor
```

### 6.4 Classificação

```text
Classificação: WARN, não BLOCKER imediato.
```

### 6.5 Motivo

O teste efetivo indica que anon não conseguiu ler `corretores`; falhou por falta de permissão na função auxiliar usada pela policy.

Porém, manter SELECT direto para anon em tabela de corretores aumenta superfície de ataque. O correto é avaliar remoção em hardening futuro, após validar dependências públicas.

### 6.6 Ação recomendada futura

Após validação de dependências públicas:

```sql
revoke select on table public.corretores from anon;
```

## 7. Diagnóstico 3 — RLS forced=false em tabelas canônicas

### 7.1 Fato observado

```text
corretores: RLS enabled=true, forced=true
mesa_cliente_agendas_financeiras: RLS enabled=true, forced=true
mesa_cliente_fluxo_operacoes: RLS enabled=true, forced=false
mesa_cliente_fluxo_parcelas: RLS enabled=true, forced=false
mesa_cliente_politica_premio_faixas: RLS enabled=true, forced=false
mesa_cliente_politicas_financeiras: RLS enabled=true, forced=false
```

### 7.2 Impacto técnico

Em PostgreSQL, o dono da tabela normalmente não está sujeito às policies de RLS, salvo quando `FORCE ROW LEVEL SECURITY` está habilitado.

### 7.3 Classificação

```text
Classificação: WARN_CONTROLADO.
```

### 7.4 Motivo

As tabelas são owned by `postgres`. RPCs SECURITY DEFINER também operam com privilégios do dono/função. Em muitos desenhos Supabase, isso é intencional quando a função faz validação interna forte.

Entretanto, para tabelas financeiras canônicas, forced=false deve ser decisão consciente, não resíduo acidental.

### 7.5 Ação recomendada futura

Antes de mudar `FORCE RLS`, revisar linha a linha o corpo das RPCs que fazem DML nessas tabelas.

Mudança precipitada pode quebrar RPC SECURITY DEFINER se a função depender do bypass do owner.

## 8. Diagnóstico 4 — revisão preliminar das RPCs administrativas

### 8.1 Funções analisadas por sinalizadores de corpo

Foram analisadas por metadados e busca textual no corpo:

```text
mesa_cliente_aplicar_operacao_financeira_admin
mesa_cliente_gerar_agenda_financeira_admin
mesa_cliente_obter_agenda_financeira_cliente_safe
mesa_cliente_obter_resumo_operacao_cliente_safe
mesa_cliente_persistir_agenda_financeira_admin
mesa_cliente_registrar_operacao_financeira_admin
```

### 8.2 Resultado por sinalizadores

| Função | auth.uid | active_corretor | cross_tenant | bloqueia payload soberano | FOR UPDATE |
|---|---:|---:|---:|---:|---:|
| `mesa_cliente_aplicar_operacao_financeira_admin` | Sim | Sim | Sim | Sim | Sim |
| `mesa_cliente_gerar_agenda_financeira_admin` | Não | Não | Não | Não | Não |
| `mesa_cliente_obter_agenda_financeira_cliente_safe` | Sim | Não | Não | Não | Não |
| `mesa_cliente_obter_resumo_operacao_cliente_safe` | Sim | Sim | Sim | Sim | Não |
| `mesa_cliente_persistir_agenda_financeira_admin` | Sim | Não | Não | Não | Não |
| `mesa_cliente_registrar_operacao_financeira_admin` | Sim | Não | Não | Não | Sim |

### 8.3 Classificação

```text
mesa_cliente_aplicar_operacao_financeira_admin: OK preliminar.
mesa_cliente_obter_resumo_operacao_cliente_safe: OK preliminar.
mesa_cliente_gerar_agenda_financeira_admin: WARN/BLOCKER antes de uso se gerar conteúdo financeiro sem auth.
mesa_cliente_persistir_agenda_financeira_admin: WARN antes de uso com DML.
mesa_cliente_registrar_operacao_financeira_admin: WARN antes de uso com DML.
mesa_cliente_obter_agenda_financeira_cliente_safe: WARN antes de exposição ampla.
```

### 8.4 Observação importante

Este diagnóstico usa sinalizadores textuais. Ele não substitui revisão linha a linha do corpo das funções.

## 9. Decisão do Gate B nesta versão

### 9.1 Gate B geral

```text
Status: PARCIALMENTE LIBERADO
```

### 9.2 O que mudou

```text
O blocker de TRUNCATE para authenticated em mesa_cliente_agendas_financeiras foi resolvido no banco real.
```

### 9.3 O que ainda impede liberação ampla

```text
- hardening manual ainda precisa ser versionado em migration;
- RPCs administrativas financeiras ainda precisam de revisão linha a linha antes de DML real;
- RLS forced=false deve permanecer como WARN_CONTROLADO;
- anon SELECT em corretores permanece como WARN.
```

### 9.4 O que pode prosseguir agora

Pode prosseguir:

```text
- seleção read-only de massa controlada;
- leitura de histórico/2ª via;
- revisão linha a linha das RPCs;
- criação de migration versionando o hardening já aplicado;
- comparação GitHub x Supabase.
```

### 9.5 O que ainda não deve prosseguir

Não liberar ainda:

```text
- Modo 4;
- Modo 5;
- qualquer uso administrativo real de registrar/aplicar operação financeira sem revisão linha a linha;
- qualquer exposição cliente-safe ampla sem validação do payload.
```

Modo 3 só pode ser considerado após versionar o hardening e revisar a RPC de persistência de agenda.

## 10. Próxima ação recomendada

Versionar o hardening aplicado manualmente em migration idempotente:

```sql
revoke references on table public.mesa_cliente_agendas_financeiras from authenticated;
revoke trigger on table public.mesa_cliente_agendas_financeiras from authenticated;
revoke truncate on table public.mesa_cliente_agendas_financeiras from authenticated;
```

Manter, por enquanto:

```sql
grant select on table public.mesa_cliente_agendas_financeiras to authenticated;
```

## 11. Status final

```text
Gate B: PARCIALMENTE LIBERADO
Read-only: SIM
BLOCKER TRUNCATE: RESOLVIDO NO BANCO REAL
Versionamento em migration: PENDENTE
Piloto read-only: PERMITIDO
Piloto Modo 3: PENDENTE DE VERSIONAMENTO + REVISÃO RPC
Piloto Modo 4/5: BLOQUEADO ATÉ REVISÃO RPC LINHA A LINHA
```
