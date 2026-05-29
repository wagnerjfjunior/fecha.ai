# FECH.AI / MesaCliente — Fase 20D.3
# Proposta técnica — RPC adaptadora read-only histórico -> agenda canônica

## 1. Status

```text
Status: PROPOSTA TÉCNICA / SEM MIGRATION
Data: 2026-05-27
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
DDL executado: NÃO
DML executado: NÃO
RPC criada/alterada: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

Este documento define a proposta técnica da RPC adaptadora que converterá o fluxo histórico salvo em `mesa_fluxo_pagamentos` para payload canônico aceito pelas RPCs financeiras 4A/4B.

## 2. Objetivo

Criar uma RPC read-only, determinística e tenant-safe que receba apenas:

```sql
p_simulacao_id uuid
```

E retorne:

```text
- data_ato;
- fluxo_json canônico;
- payload_tabela canônico;
- diagnóstico de adaptação;
- warnings controlados quando aplicável.
```

A RPC não deve persistir nada e não deve aceitar valores financeiros soberanos vindos do frontend.

## 3. Nome proposto

```sql
public.mesa_cliente_montar_payload_agenda_canonica(
  p_simulacao_id uuid
) returns jsonb
```

## 4. Natureza da função

Proposta:

```sql
language plpgsql
security definer
stable
set search_path = public
```

Justificativa:

```text
- SECURITY DEFINER: necessário porque as tabelas base não possuem grants diretos para authenticated.
- STABLE: a função apenas lê dados e monta JSON; não executa DML.
- search_path=public: evita resolução ambígua de objetos.
```

## 5. Escopo permitido

A função pode:

```text
- ler public.mesa_simulacoes;
- ler public.mesa_fluxo_pagamentos;
- ler public.corretores ou usar helpers de contexto já existentes;
- validar empresa/tenant;
- validar autorização do usuário;
- montar JSON canônico;
- retornar diagnóstico.
```

A função não pode:

```text
- inserir agenda;
- inserir parcelas;
- atualizar simulação;
- alterar fluxo histórico;
- registrar operação financeira;
- aplicar operação financeira;
- recalcular motor financeiro;
- alterar parser/Worker/Make;
- depender de payload financeiro vindo do frontend.
```

## 6. Segurança obrigatória

### 6.1 Autenticação

A função deve exigir `auth.uid()` válido.

Preferência:

```sql
v_auth_uid := public.mesa_cliente_assert_auth();
```

Bloqueio esperado:

```text
Usuário não autenticado
```

### 6.2 Simulação como fonte de autoridade

A função deve buscar a simulação no banco:

```sql
select *
into v_sim
from public.mesa_simulacoes
where id = p_simulacao_id;
```

Deve bloquear:

```text
p_simulacao_id null
simulação inexistente
simulação sem empresa_id
simulação sem empreendimento_id
```

### 6.3 Empresa/tenant

A empresa válida é sempre:

```text
v_sim.empresa_id
```

Nunca deve aceitar `empresa_id` do frontend como autoridade.

A função deve validar acesso à empresa por helper existente, por exemplo:

```sql
public.mesa_cliente_can_access_empresa(v_sim.empresa_id)
```

ou por lógica equivalente já aprovada no projeto.

### 6.4 Corretor/contexto

Para usuários não root/global, validar:

```text
- corretor/contexto existe;
- usuário ativo;
- usuário pertence à empresa da simulação;
- usuário é dono da simulação ou possui perfil administrativo compatível.
```

Perfis administrativos compatíveis devem seguir o padrão já revisado na 4A:

```text
root
admin_global
admin_local
gestor/coordenador se helper de admin permitir
corretor dono da simulação
```

Observação:

```text
A política exata deve reaproveitar helpers existentes para evitar duplicação divergente de regra.
```

## 7. Dados de entrada lidos do banco

### 7.1 `mesa_simulacoes`

Campos usados:

```text
id
empresa_id
corretor_id
empreendimento_id
unidade_estoque_id
status
valor_total
entrada
financiamento
valor_final
snapshot_payload
created_at
```

### 7.2 `mesa_fluxo_pagamentos`

Campos usados:

```text
id
empresa_id
simulacao_id
tipo
descricao
valor
quantidade
periodicidade
data_prevista
ordem
created_at
```

Consulta base recomendada:

```sql
select *
from public.mesa_fluxo_pagamentos
where simulacao_id = p_simulacao_id
  and empresa_id = v_sim.empresa_id
order by ordem, created_at;
```

## 8. Validações obrigatórias do fluxo

A função deve bloquear:

```text
fluxo vazio
item com empresa_id divergente da simulação
item sem tipo
item financeiro sem valor
valor negativo
quantidade menor que 1
quantidade maior que 240
tipo histórico não mapeado
observacao entrando como item financeiro
data_vencimento impossível de determinar
```

Regra de quantidade:

```text
coalesce(quantidade, 1)
```

Mas após o `coalesce`, validar:

```text
1 <= quantidade <= 240
```

## 9. Mapeamento de grupos

| Tipo histórico | Grupo canônico 4A | Status |
|---|---|---|
| `entrada` | `entrada` | permitido |
| `curto_prazo` | `entrada` | permitido |
| `periodica` | `mensais` | permitido |
| `intermediaria` | `intermediarias` | permitido |
| `quitacao` | `parcela_unica` | permitido |
| `financiamento` | `financiamento` | permitido |
| `observacao` | null | bloquear no fluxo financeiro |

Regra:

```sql
case f.tipo::text
  when 'entrada' then 'entrada'
  when 'curto_prazo' then 'entrada'
  when 'periodica' then 'mensais'
  when 'intermediaria' then 'intermediarias'
  when 'quitacao' then 'parcela_unica'
  when 'financiamento' then 'financiamento'
  when 'observacao' then null
  else null
end
```

## 10. Regras de data

### 10.1 Data base da proposta

A função deve determinar `data_ato` nesta ordem:

```text
1. data_prevista do item tipo=entrada com menor ordem, quando existir;
2. menor data_prevista do fluxo, quando existir;
3. data de criação da simulação convertida para date;
4. erro controlado se nenhuma data puder ser determinada.
```

Para a amostra Chateau 501:

```text
data_ato = 2026-05-26
```

### 10.2 Data de vencimento por item

Ordem de precedência:

```text
1. usar f.data_prevista quando preenchida;
2. para curto_prazo com descrição +30/+60/+90, inferir por meses comerciais a partir da data_ato;
3. para demais itens sem data_prevista, bloquear com erro controlado.
```

### 10.3 Curto prazo por mês comercial

Não usar dias corridos.

Regra proposta:

```sql
v_data_ato + make_interval(months => v_meses_offset)
```

Mapeamento inicial:

| Descrição detectada | Meses comerciais |
|---|---:|
| `+30` | 1 |
| `+60` | 2 |
| `+90` | 3 |

Exemplo:

```text
2026-05-26 + 1 mês = 2026-06-26
2026-05-26 + 2 meses = 2026-07-26
2026-05-26 + 3 meses = 2026-08-26
```

### 10.4 Regex sugerido para curto prazo

```sql
case
  when f.descricao ~* '\+\s*30' then 1
  when f.descricao ~* '\+\s*60' then 2
  when f.descricao ~* '\+\s*90' then 3
  else null
end
```

Se `tipo = curto_prazo`, `data_prevista is null` e não houver match no regex, bloquear.

## 11. Payload de retorno

### 11.1 Estrutura geral

```json
{
  "ok": true,
  "fase": "20D_ADAPTADOR_HISTORICO_AGENDA_CANONICA",
  "cliente_safe": false,
  "persistencia": false,
  "dml_financeiro": false,
  "simulacao_id": "...",
  "empresa_id": "...",
  "empreendimento_id": "...",
  "unidade_estoque_id": "...",
  "data_ato": "YYYY-MM-DD",
  "fluxo_json": [],
  "payload_tabela": {},
  "diagnostico": {}
}
```

### 11.2 `fluxo_json`

Cada item deve ter:

```json
{
  "ordem": 0,
  "tipo": "entrada",
  "grupo": "entrada",
  "descricao": "Ato",
  "valor": 408000.00,
  "quantidade": 1,
  "periodicidade": null,
  "data_vencimento": "2026-05-26",
  "origem_historica": {
    "fluxo_pagamento_id": "...",
    "tipo_original": "entrada",
    "data_prevista_original": "2026-05-26"
  }
}
```

Observação:

```text
A 4A deve ignorar campos extras desconhecidos, mas eles podem ser úteis em metadata/diagnóstico. Se houver risco de a 4A não tolerar campos extras, a migration deve optar por retorno com dois arrays: fluxo_json_limpo e fluxo_json_diagnostico.
```

Recomendação mais segura:

```text
Retornar `fluxo_json` limpo para 4A/4B e `diagnostico.itens` com rastreio de origem.
```

### 11.3 `payload_tabela`

```json
{
  "empresa_id": "...",
  "empreendimento_id": "...",
  "unidade_estoque_id": "...",
  "origem": "20D_ADAPTADOR_HISTORICO_AGENDA_CANONICA",
  "adaptador": true,
  "versao_adaptador": "20D.3",
  "fonte": "mesa_fluxo_pagamentos"
}
```

### 11.4 `diagnostico`

```json
{
  "qtd_itens_origem": 7,
  "qtd_itens_adaptados": 7,
  "qtd_itens_bloqueados": 0,
  "warnings": [],
  "mapeamentos_aplicados": {
    "curto_prazo_para_entrada": 3,
    "periodica_para_mensais": 1,
    "intermediaria_para_intermediarias": 1,
    "quitacao_para_parcela_unica": 1
  },
  "datas_inferidas": [
    {
      "ordem": 1,
      "descricao": "+30 dias",
      "data_vencimento": "2026-06-26",
      "regra": "mes_comercial_+30"
    }
  ]
}
```

## 12. Saída esperada para Chateau 501

Para a simulação:

```text
6e5df1f0-79c9-4011-848b-c2d328ad6a05
```

Resultado esperado:

```text
ok=true
data_ato=2026-05-26
qtd_itens_origem=7
qtd_itens_adaptados=7
fluxo_json[0].grupo=entrada
fluxo_json[1].grupo=entrada
fluxo_json[1].data_vencimento=2026-06-26
fluxo_json[2].data_vencimento=2026-07-26
fluxo_json[3].data_vencimento=2026-08-26
fluxo_json[4].grupo=mensais
fluxo_json[5].grupo=intermediarias
fluxo_json[6].grupo=parcela_unica
```

## 13. Critérios de PASS da 20D.3

A proposta técnica é considerada adequada se:

```text
[ ] função recebe somente p_simulacao_id;
[ ] não aceita valores financeiros do frontend;
[ ] lê simulação e fluxo no banco;
[ ] valida auth.uid();
[ ] valida empresa/tenant;
[ ] bloqueia cross-tenant;
[ ] bloqueia fluxo vazio;
[ ] bloqueia tipo não mapeado;
[ ] bloqueia observacao como item financeiro;
[ ] bloqueia valor negativo;
[ ] bloqueia data impossível de inferir;
[ ] usa mês comercial para curto_prazo +30/+60/+90;
[ ] retorna fluxo_json compatível com 4A;
[ ] retorna payload_tabela compatível com 4B;
[ ] não faz DML;
[ ] não altera motor financeiro.
```

## 14. Critérios para a futura migration 20D.4

A migration só deve ser criada se este contrato for aprovado.

A migration deverá:

```text
- criar ou substituir apenas a função adaptadora;
- revogar execute de public/anon;
- conceder execute para authenticated;
- manter search_path=public;
- documentar que a função não executa DML;
- não tocar em parser, Worker/Make, motor financeiro ou UI.
```

## 15. Testes obrigatórios após migration

### 15.1 Segurança

```text
chamada sem JWT -> erro de usuário não autenticado
chamada com usuário sem acesso -> erro de permissão
chamada com simulação inexistente -> erro controlado
```

### 15.2 Funcional

```text
Chateau 501 -> ok=true, 7 itens adaptados
+30 -> 2026-06-26
+60 -> 2026-07-26
+90 -> 2026-08-26
```

### 15.3 Integração com 4A

Usar retorno do adaptador como entrada da 4A:

```text
4A retorna ok=true
qtd_parcelas=47
valor_total=1.883.397,54
```

### 15.4 Sem persistência

Antes e depois da chamada do adaptador:

```text
count(*) em mesa_cliente_agendas_financeiras não deve mudar
count(*) em mesa_cliente_fluxo_parcelas não deve mudar
```

## 16. Decisão técnica recomendada

```text
Aprovar esta proposta e seguir para 20D.4 — migration da RPC adaptadora read-only.
```

Não avançar para Modo 4/5 antes de validar o adaptador com Chateau 501 e executar a 4A usando exclusivamente o payload gerado por ele.
