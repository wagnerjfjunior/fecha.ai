# FECH.AI / MesaCliente — Fase 20A.1/20A.2
# Validação — Hardening de Acesso ao Fluxo Histórico

## 1. Objetivo

Padronizar e validar a regra de acesso a propostas/fluxos históricos do MesaCliente.

A proposta/fluxo de cliente é considerada dado comercial sensível. Portanto, a regra é mais restritiva do que a regra administrativa geral.

## 2. Regra aprovada

| Perfil | Tenant/empresa | Time | Dono | Resultado |
|---|---:|---:|---:|---:|
| Corretor dono | Mesmo | Qualquer | Sim | Acessa |
| Corretor não dono | Mesmo | Mesmo ou outro | Não | Bloqueia |
| Gestor do time do corretor dono | Mesmo | Mesmo | Não | Acessa |
| Gestor de outro time | Mesmo | Outro | Não | Bloqueia |
| Admin local não dono | Mesmo | Qualquer | Não | Bloqueia |
| Admin global não dono | Mesmo | Qualquer | Não | Bloqueia |
| Root não dono | Mesmo | Qualquer | Não | Bloqueia pela RPC comum |
| Qualquer perfil de outro tenant/empresa | Outro | Qualquer | Qualquer | Bloqueia |

Observação importante: **corretor dono tem precedência**. Se um usuário possui flag administrativa, mas também é o corretor dono da simulação, o acesso é concedido por ownership, não por papel administrativo.

## 3. Ajustes aplicados

### 20A.1

Criado hardening de acesso comercial por tenant/time/ownership:

```text
security(mesa-cliente): endurecer acesso ao fluxo histórico por time e ownership
```

Migration:

```text
supabase/migrations/20260525182000_mesa_cliente_20a1_hardening_fluxo_historico_tenant_time_owner.sql
```

### 20A.2

Ajustada precedência do corretor dono:

```text
security(mesa-cliente): ajustar precedência do corretor dono no fluxo histórico
```

Migration:

```text
supabase/migrations/20260525182500_mesa_cliente_20a2_precedencia_owner_fluxo_historico.sql
```

Commit:

```text
a224c0988c948f7ce052b90cb1347d6a56beeb86
```

## 4. Evidência positiva — corretor dono

Simulação usada:

```text
363fb2fe-6ee8-4da6-9d25-4118dd56a069
```

Usuário autenticado:

```text
10b90f39-84a5-49a4-8ba6-165ef7178f11
```

Esse usuário possui `role=admin_local`, mas também é o corretor dono da simulação. Pela regra de precedência, o acesso deve ser concedido por ownership.

Resultado real:

```json
{
  "ok": "true",
  "acesso_por": "corretor_dono",
  "role": "admin_local",
  "is_admin_local": "true",
  "fluxo_count": 7
}
```

Conclusão: PASS.

## 5. Evidências negativas — bloqueios corretos

A validação transacional executou os seguintes cenários contra a mesma simulação:

```json
[
  {
    "cenario": "admin_global_mesma_empresa_nao_dono",
    "expected": "BLOCK",
    "result": "BLOCK",
    "ok": true,
    "msg": "Acesso negado ao fluxo da simulação"
  },
  {
    "cenario": "admin_local_mesma_empresa_nao_dono",
    "expected": "BLOCK",
    "result": "BLOCK",
    "ok": true,
    "msg": "Acesso negado ao fluxo da simulação"
  },
  {
    "cenario": "admin_local_outro_tenant",
    "expected": "BLOCK",
    "result": "BLOCK",
    "ok": true,
    "msg": "Acesso negado à simulação informada"
  },
  {
    "cenario": "corretor_mesma_empresa_nao_dono",
    "expected": "BLOCK",
    "result": "BLOCK",
    "ok": true,
    "msg": "Acesso negado ao fluxo da simulação"
  },
  {
    "cenario": "gestor_outro_time",
    "expected": "BLOCK",
    "result": "BLOCK",
    "ok": true,
    "msg": "Acesso negado ao fluxo da simulação"
  }
]
```

Conclusão: PASS para os bloqueios testáveis com a massa atual.

## 6. Cenário não testável com a massa atual

O cenário abaixo **não foi marcado como PASS**, porque não existe massa atual compatível:

```text
gestor_mesmo_time
```

Motivo:

- a simulação de referência pertence ao corretor Wagner;
- o Wagner está no time `b0000000-0000-0000-0000-000000000001`;
- os gestores disponíveis Sabrina/Wislane estão no time `15d262e2-3b0f-4d58-813d-1c1f98db70e7`;
- não há simulação existente de corretor do time `15d262e2-3b0f-4d58-813d-1c1f98db70e7`.

Resultado real ao tentar usar Sabrina como gestora da simulação do Wagner:

```json
{
  "cenario": "gestor_mesmo_time",
  "expected": "PASS",
  "result": "BLOCK",
  "ok": false,
  "msg": "Acesso negado ao fluxo da simulação"
}
```

Esse resultado não é falha da regra; é massa de teste incompatível. Na prática, Sabrina não é gestora do time do Wagner.

## 7. Status

```text
corretor dono = PASS
gestor outro time = PASS bloqueio
corretor não dono = PASS bloqueio
admin local não dono = PASS bloqueio
admin global não dono = PASS bloqueio
outro tenant = PASS bloqueio
gestor mesmo time = pendente por ausência de massa compatível
```

## 8. Recomendação

Antes de considerar 20A.1 completamente fechada, criar uma massa de homologação controlada com:

- um corretor comum no time de Sabrina/Wislane;
- uma simulação desse corretor;
- fluxo salvo nessa simulação;
- teste da gestora Sabrina ou Wislane acessando essa simulação.

Sem isso, a regra está implementada, mas o cenário positivo de gestor mesmo time permanece sem evidência runtime.

## 9. Escopo preservado

Durante os ajustes:

```text
Motor financeiro: preservado
Parser: preservado
Worker/Make: preservado
Agenda: preservada
Parcelas: preservadas
Operações financeiras: preservadas
DML financeiro da RPC: false
```
