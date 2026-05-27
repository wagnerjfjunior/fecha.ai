# FECH.AI / MesaCliente — Fase 20D.4
# Status — Migration da RPC adaptadora read-only

## 1. Status

```text
Status: MIGRATION VERSIONADA / AGUARDANDO APLICAÇÃO E TESTES NO SUPABASE
Data: 2026-05-27
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration criada no repositório: SIM
Migration executada no Supabase: NÃO CONFIRMADO NESTE DOCUMENTO
DDL versionado: SIM
DML versionado: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
Modo 4/5 liberado: NÃO
```

## 2. Migration versionada

Arquivo:

```text
supabase/migrations/20260527043000_mesa_cliente_20d4_adaptador_agenda_canonica.sql
```

Função criada/alterada pela migration:

```text
public.mesa_cliente_montar_payload_agenda_canonica(p_simulacao_id uuid)
```

Objetivo da RPC:

```text
Montar payload canônico para 4A/4B a partir de mesa_fluxo_pagamentos, sem DML e sem aceitar valores financeiros soberanos do frontend.
```

## 3. Correção aplicada antes do PASS

Foi aplicado hardening defensivo na migration antes de considerar a 20D.4 pronta para teste:

```text
pré-flight de tabelas obrigatórias
pré-flight de helpers obrigatórios
comentário explícito de não DML
comentário explícito de não chamada automática da 4A/4B
payload fluxo_json limpo para 4A
diagnóstico separado em diagnostico.itens
```

Pré-requisitos validados pela própria migration:

```text
public.mesa_simulacoes
public.mesa_fluxo_pagamentos
public.is_root()
public.mesa_cliente_assert_auth()
public.mesa_cliente_current_corretor_context()
public.mesa_cliente_can_admin_empresa(uuid)
public.mesa_cliente_can_access_empresa(uuid)
public.mesa_cliente_assert_empreendimento_empresa(uuid,uuid)
```

## 4. Natureza da alteração

A migration é DDL controlado:

```text
create or replace function
comment on function
revoke execute de public/anon
grant execute para authenticated
```

A migration não deve executar:

```text
insert
update
delete
truncate
chamada 4A
chamada 4B
persistência de agenda
persistência de parcelas
persistência de operação financeira
```

## 5. Segurança

A RPC usa:

```text
security definer
set search_path = public
auth.uid validado via mesa_cliente_assert_auth()
empresa/tenant validado contra mesa_simulacoes
contexto de usuário/corretor validado
admin/dono/root validados
bloqueio de fluxo com empresa_id divergente
```

## 6. Escopo funcional

A RPC lê:

```text
public.mesa_simulacoes
public.mesa_fluxo_pagamentos
```

E retorna:

```text
ok
fase
cliente_safe=false
persistencia=false
dml_financeiro=false
simulacao_id
empresa_id
corretor_id
empreendimento_id
unidade_estoque_id
data_ato
fluxo_json
payload_tabela
diagnostico
```

## 7. Regras críticas de dados

```text
entrada -> entrada
curto_prazo -> entrada
periodica -> mensais
intermediaria -> intermediarias
quitacao -> parcela_unica
financiamento -> financiamento
observacao -> bloqueado
```

Regra de data:

```text
usar data_prevista quando existir
para curto_prazo sem data_prevista, aceitar somente +30, +60 ou +90
converter +30/+60/+90 por mês comercial a partir de data_ato
bloquear demais casos sem data_vencimento
```

## 8. Testes obrigatórios antes de PASS

A 20D.4 ainda depende de validação no Supabase.

Testes mínimos:

```text
1. Aplicar migration em ambiente controlado.
2. Confirmar que a função existe via to_regprocedure.
3. Chamada sem JWT deve ser bloqueada.
4. Usuário sem acesso deve ser bloqueado.
5. Simulação inexistente deve retornar erro controlado.
6. Chateau 501 deve retornar ok=true.
7. Chateau 501 deve retornar 7 itens adaptados.
8. +30 deve gerar 2026-06-26.
9. +60 deve gerar 2026-07-26.
10. +90 deve gerar 2026-08-26.
11. fluxo_json deve ser aceito pela 4A.
12. Nenhum count de agenda/parcela/operação deve mudar apenas com o adaptador.
```

## 9. Bloqueios mantidos

Mesmo com a migration versionada, permanecem bloqueados:

```text
Modo 4
Modo 5
persistência automática
operação financeira
amortização
juros
VPL
antecipação
frontend
parser
Worker/Make/n8n
```

## 10. Próximo passo

Executar a 20D.5:

```text
Aplicar a migration em ambiente controlado e testar a RPC read-only com Chateau Jardin unidade 501.
```

Somente após a 20D.5 passar, usar o retorno do adaptador como entrada da 4A na 20D.6.
