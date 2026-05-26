# FECH.AI — MesaCliente
# Fase 8I — Contrato de Correção da RPC criar_mesa_simulacao para mesa_fluxo_tipo

## 1. Identificação

Projeto: FECH.AI / MesaCliente  
Fase: 8I — Correção cirúrgica da RPC criar_mesa_simulacao  
Branch: feature/mesa-cliente-fase-8-front-operacoes-financeiras  
Risco: R3/R4 — RPC em banco real de produção única  
Status: contrato criado para implementação controlada.

## 2. Contexto verificado

Após as correções 8G e 8H, o salvamento do Fluxo avançou e passou a falhar em novo ponto da mesma RPC.

Erro observado no HAR:

```text
HTTP 400
code = 22P02
invalid input value for enum mesa_fluxo_tipo: "unica"
```

Consulta direta ao Supabase confirmou que o enum real `public.mesa_fluxo_tipo` possui os valores:

```text
entrada
curto_prazo
intermediaria
financiamento
quitacao
periodica
observacao
```

A RPC ainda mapeia o grupo `u` para:

```sql
'unica'::mesa_fluxo_tipo
```

Esse valor não existe no enum real.

O payload real do HAR continha os grupos:

```text
e = Ato
c = +30/+60/+90 dias
m = Mensais
a = Anuais
u = Parcela única
```

## 3. Objetivo

Corrigir exclusivamente o mapeamento interno da RPC `public.criar_mesa_simulacao` entre os grupos vindos do frontend/parser e o enum real `public.mesa_fluxo_tipo`.

## 4. Correção autorizada

Mapeamento autorizado:

```sql
case (v_item->>'grupo')
  when 'e' then 'entrada'::mesa_fluxo_tipo
  when 'c' then 'curto_prazo'::mesa_fluxo_tipo
  when 'm' then 'periodica'::mesa_fluxo_tipo
  when 'a' then 'intermediaria'::mesa_fluxo_tipo
  when 'u' then 'quitacao'::mesa_fluxo_tipo
  else 'financiamento'::mesa_fluxo_tipo
end
```

Justificativa:

- `e` representa ato/entrada.
- `c` representa curto prazo, 30/60/90.
- `m` representa mensais, logo `periodica`.
- `a` representa anuais/intermediárias, logo `intermediaria`.
- `u` representa parcela única/chaves/quitação, logo `quitacao`.
- fallback financeiro permanece `financiamento`.

## 5. Escopo permitido

Permitido:

1. Criar migration corretiva posterior à 8H.
2. Recriar `public.criar_mesa_simulacao` preservando assinatura, `security definer` e `search_path`.
3. Corrigir somente o CASE de `v_tipo_fluxo`.
4. Preservar as correções 8G e 8H.
5. Criar teste estático 19C.
6. Aplicar e validar a função no Supabase após validação do artefato.

## 6. Fora de escopo

Não alterar:

- frontend;
- parser;
- Worker;
- Make;
- n8n;
- motor financeiro 4A/4B/5A/5B/5C/5D;
- RPCs de operações financeiras;
- tabelas;
- enums;
- RLS;
- policies;
- grants;
- agenda;
- parcelas;
- UX de taxa/juros;
- cliente-safe.

## 7. Segurança

A função deve permanecer com:

```sql
language plpgsql
security definer
set search_path = public
```

Permissões existentes não devem ser ampliadas. `anon` não deve receber `EXECUTE`.

## 8. Critérios de aceite

Aceitar quando:

1. Migration corretiva criada.
2. Teste 19C retorna PASS.
3. Migration aplicada no Supabase sem erro.
4. Função real não contém `'unica'::mesa_fluxo_tipo`.
5. Função real contém `when 'u' then 'quitacao'::mesa_fluxo_tipo`.
6. Função real contém `when 'c' then 'curto_prazo'::mesa_fluxo_tipo`.
7. Função real contém `when 'a' then 'intermediaria'::mesa_fluxo_tipo`.
8. Função real preserva correções 8G e 8H.
9. Smoke de salvar fluxo deixa de retornar erro `22P02` para `mesa_fluxo_tipo`.

## 9. Decisão

A correção autorizada é cirúrgica: alinhar os grupos do payload da mesa ao enum real `public.mesa_fluxo_tipo`, sem mudar motor financeiro, frontend, parser ou estrutura de banco.

Status: APROVADO PARA IMPLEMENTAÇÃO CONTROLADA.
