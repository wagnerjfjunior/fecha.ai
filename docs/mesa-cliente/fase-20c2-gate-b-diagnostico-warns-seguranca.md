# FECH.AI / MesaCliente — Fase 20C.2
# Gate B — Diagnóstico dos WARNs de segurança

## 1. Status

```text
Status: DIAGNÓSTICO PARCIAL / READ-ONLY
Data: 2026-05-26
Projeto Supabase: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
DDL executado: NÃO
DML executado: NÃO
Migration criada: NÃO
RPC alterada: NÃO
Frontend alterado: NÃO
```

Este documento registra o diagnóstico read-only inicial dos WARNs levantados no preflight 20C.1.

## 2. WARNs analisados nesta etapa

```text
1. mesa_cliente_agendas_financeiras com TRUNCATE para authenticated.
2. corretores com anon SELECT.
3. RLS forced=false em tabelas financeiras canônicas.
4. corpo das RPCs administrativas financeiras ainda não revisado integralmente.
```

## 3. Evidência — grants diretos em tabelas

Consulta de privilégios diretos confirmou:

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

## 4. Diagnóstico 1 — TRUNCATE em mesa_cliente_agendas_financeiras

### 4.1 Fato observado

```text
A role authenticated possui privilégio TRUNCATE direto em public.mesa_cliente_agendas_financeiras.
```

### 4.2 Impacto técnico

TRUNCATE é operação de tabela inteira. Em PostgreSQL, operações de tabela inteira como TRUNCATE e REFERENCES não são submetidas às políticas de Row Level Security.

Além disso, TRUNCATE exige privilégio específico de TRUNCATE na tabela.

### 4.3 Classificação

```text
Classificação: BLOCKER antes de qualquer piloto com DML em agenda canônica.
```

### 4.4 Motivo

Mesmo que a tabela esteja vazia agora, o privilégio é incompatível com o modelo DevSecOps esperado para tabela financeira canônica multi-tenant.

O risco não é massa atual, é autorização futura indevida.

### 4.5 Ação recomendada futura

Criar migration de hardening, após aprovação explícita:

```sql
revoke truncate on table public.mesa_cliente_agendas_financeiras from authenticated;
revoke trigger on table public.mesa_cliente_agendas_financeiras from authenticated;
```

Observação:

```text
REFERENCES deve ser avaliado separadamente. Pode ser necessário para constraints/uso interno, mas normalmente não deveria ser grant amplo para cliente autenticado se não houver necessidade clara.
```

## 5. Diagnóstico 2 — anon SELECT em corretores

### 5.1 Fato observado

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

### 5.2 Teste efetivo read-only

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

### 5.3 Grants das funções auxiliares

As funções abaixo possuem EXECUTE para authenticated, postgres e service_role, mas não para anon:

```text
is_admin_local
is_gestor
is_root
my_empresa_id
my_times_como_gestor
```

### 5.4 Classificação

```text
Classificação: WARN, não BLOCKER imediato.
```

### 5.5 Motivo

O teste efetivo indica que anon não conseguiu ler `corretores`; falhou por falta de permissão na função auxiliar usada pela policy.

Porém, manter SELECT direto para anon em tabela de corretores não é desejável do ponto de vista de superfície de ataque. O correto é reduzir o grant quando possível.

### 5.6 Ação recomendada futura

Após validação de dependências públicas:

```sql
revoke select on table public.corretores from anon;
```

E manter acesso apenas por RPC/rotas explicitamente públicas, se existirem.

## 6. Diagnóstico 3 — RLS forced=false em tabelas canônicas

### 6.1 Fato observado

```text
corretores: RLS enabled=true, forced=true
mesa_cliente_agendas_financeiras: RLS enabled=true, forced=true
mesa_cliente_fluxo_operacoes: RLS enabled=true, forced=false
mesa_cliente_fluxo_parcelas: RLS enabled=true, forced=false
mesa_cliente_politica_premio_faixas: RLS enabled=true, forced=false
mesa_cliente_politicas_financeiras: RLS enabled=true, forced=false
```

### 6.2 Impacto técnico

Em PostgreSQL, o dono da tabela normalmente não está sujeito às policies de RLS, salvo quando `FORCE ROW LEVEL SECURITY` está habilitado.

### 6.3 Classificação

```text
Classificação: WARN_CONTROLADO.
```

### 6.4 Motivo

As tabelas são owned by `postgres`. RPCs SECURITY DEFINER também operam com privilégios do dono/função. Em muitos desenhos Supabase, isto é intencional quando a função faz validação interna forte.

Entretanto, para tabelas financeiras canônicas, forced=false deve ser uma decisão consciente, não resíduo acidental.

### 6.5 Ação recomendada futura

Antes de mudar `FORCE RLS`, revisar o corpo das RPCs que fazem DML nessas tabelas.

Mudança precipitada pode quebrar RPC SECURITY DEFINER se a função depender do bypass do owner.

## 7. Diagnóstico 4 — revisão preliminar das RPCs administrativas

### 7.1 Funções analisadas por sinalizadores de corpo

Foram analisadas por metadados e busca textual no corpo:

```text
mesa_cliente_aplicar_operacao_financeira_admin
mesa_cliente_gerar_agenda_financeira_admin
mesa_cliente_obter_agenda_financeira_cliente_safe
mesa_cliente_obter_resumo_operacao_cliente_safe
mesa_cliente_persistir_agenda_financeira_admin
mesa_cliente_registrar_operacao_financeira_admin
```

### 7.2 Resultado por sinalizadores

| Função | auth.uid | active_corretor | cross_tenant | bloqueia payload soberano | FOR UPDATE |
|---|---:|---:|---:|---:|---:|
| `mesa_cliente_aplicar_operacao_financeira_admin` | Sim | Sim | Sim | Sim | Sim |
| `mesa_cliente_gerar_agenda_financeira_admin` | Não | Não | Não | Não | Não |
| `mesa_cliente_obter_agenda_financeira_cliente_safe` | Sim | Não | Não | Não | Não |
| `mesa_cliente_obter_resumo_operacao_cliente_safe` | Sim | Sim | Sim | Sim | Não |
| `mesa_cliente_persistir_agenda_financeira_admin` | Sim | Não | Não | Não | Não |
| `mesa_cliente_registrar_operacao_financeira_admin` | Sim | Não | Não | Não | Sim |

### 7.3 Classificação

```text
mesa_cliente_aplicar_operacao_financeira_admin: OK preliminar.
mesa_cliente_obter_resumo_operacao_cliente_safe: OK preliminar.
mesa_cliente_gerar_agenda_financeira_admin: WARN/BLOCKER antes de uso se gerar conteúdo financeiro sem auth.
mesa_cliente_persistir_agenda_financeira_admin: WARN antes de uso com DML.
mesa_cliente_registrar_operacao_financeira_admin: WARN antes de uso com DML.
mesa_cliente_obter_agenda_financeira_cliente_safe: WARN antes de exposição ampla.
```

### 7.4 Observação importante

Este diagnóstico usa sinalizadores textuais. Ele não substitui revisão linha a linha do corpo das funções.

## 8. Decisão do Gate B nesta versão

### 8.1 Gate B geral

```text
Status: NÃO LIBERADO para piloto com DML.
```

### 8.2 Motivo

O grant de TRUNCATE para authenticated em `mesa_cliente_agendas_financeiras` é blocker para qualquer piloto que vá persistir agenda canônica.

### 8.3 O que pode prosseguir

Pode prosseguir, sem DML:

```text
- seleção read-only de massa controlada;
- leitura de histórico/2ª via;
- revisão linha a linha das RPCs;
- preparação de migration de hardening, sem aplicar ainda;
- comparação GitHub x Supabase.
```

### 8.4 O que não deve prosseguir ainda

Não liberar ainda:

```text
- Modo 3 do piloto, se persistir agenda;
- Modo 4;
- Modo 5;
- qualquer DML em agenda/parcelas/operações;
- qualquer uso administrativo real de registrar/aplicar operação financeira.
```

## 9. Próxima ação recomendada

Criar contrato/migration de hardening para remover grants indevidos, começando por:

```sql
revoke truncate on table public.mesa_cliente_agendas_financeiras from authenticated;
revoke trigger on table public.mesa_cliente_agendas_financeiras from authenticated;
```

Antes de aplicar, validar se existe dependência legítima para `TRIGGER` e `REFERENCES` nessa tabela.

## 10. Status final

```text
Gate B: PARCIAL
Read-only: SIM
BLOCKER encontrado: SIM
BLOCKER: TRUNCATE para authenticated em mesa_cliente_agendas_financeiras
Piloto com DML: BLOQUEADO
Piloto read-only: PERMITIDO
```
