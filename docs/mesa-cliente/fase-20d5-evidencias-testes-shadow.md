# FECH.AI / MesaCliente — Fase 20D.5
# Evidências de aplicação e testes do fluxo canônico shadow

## 1. Objetivo deste documento

Registrar as evidências reais da aplicação e validação da migration 20D.5 do MesaCliente / Engenharia Financeira.

A fase 20D.5 introduz a tabela canônica paralela `public.mesa_fluxo_pagamentos_canonico` em shadow mode, mantendo a tabela legada `public.mesa_fluxo_pagamentos` intacta para compatibilidade.

Este documento não altera regra de negócio, parser, Worker, Make/n8n, frontend ou motor financeiro. Ele apenas registra a bateria de testes executada.

---

## 2. Escopo testado

```text
Repositório: wagnerjfjunior/fecha.ai
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
PR: #29 — MesaCliente: preparar fluxo financeiro canônico shadow 20D
Migration: supabase/migrations/20260528013000_mesa_cliente_20d5_fluxo_canonico_shadow.sql
Ambiente Supabase: Discador-MesaCliente
Project ref: uobxxgzshrmbtjfdolxd
Região: sa-east-1
Banco: PostgreSQL 17.6.1.104
```

---

## 3. Bateria planejada

A bateria de validação da 20D.5 foi definida na seguinte ordem:

```text
1. Aplicar em ambiente controlado.
2. Verificar criação da tabela shadow.
3. Verificar RLS/grants.
4. Criar simulação piloto nova.
5. Confirmar escrita no legado.
6. Confirmar escrita no canônico shadow.
7. Confirmar u -> parcela_unica_obra.
8. Confirmar f_residual -> financiamento_saldo.
9. Confirmar p -> periodicidade_obra quando existir.
10. Confirmar que authenticated/anon não acessam direto a tabela shadow.
```

---

## 4. Aplicação da migration 20D.5

A migration foi aplicada no Supabase por ferramenta de migration, não por SQL parcial colado em partes.

Resultado real:

```json
{ "success": true }
```

Nome aplicado:

```text
mesa_cliente_20d5_fluxo_canonico_shadow
```

---

## 5. Validação estrutural pós-migration

### 5.1 Tabela shadow criada

Consulta executada:

```sql
select
  exists(select 1 from information_schema.tables where table_schema='public' and table_name='mesa_fluxo_pagamentos_canonico') as tabela_canonica_existe,
  (select c.relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relname='mesa_fluxo_pagamentos_canonico') as rls_enabled,
  obj_description('public.mesa_fluxo_pagamentos_canonico'::regclass, 'pg_class') as comentario_tabela;
```

Resultado real:

```json
{
  "tabela_canonica_existe": true,
  "rls_enabled": true,
  "comentario_tabela": "MesaCliente 20D.5: fluxo financeiro canônico em shadow mode. Corrige semântica de parcela única/chaves, financiamento/saldo e periodicidade sem quebrar mesa_fluxo_pagamentos legado."
}
```

### 5.2 Grants da tabela shadow

Resultado real em `information_schema.table_privileges`:

```text
postgres: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
service_role: DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE
```

Não foram encontrados privilégios diretos para:

```text
anon
authenticated
public
```

### 5.3 Função `criar_mesa_simulacao`

Resultado real:

```json
{
  "proname": "criar_mesa_simulacao",
  "security_definer": true,
  "volatility": "v",
  "comentario": "MesaCliente 20D.5: cria simulação mantendo mesa_fluxo_pagamentos legado e gravando mesa_fluxo_pagamentos_canonico em shadow mode. Parcela única/chaves não é quitação; financiamento residual é item canônico; periodicidade/final é controle de obra."
}
```

Grants da função:

```text
authenticated: EXECUTE
postgres: EXECUTE
service_role: EXECUTE
```

---

## 6. Teste piloto controlado por SQL

Antes do teste HTTP, foi criada uma simulação piloto controlada sem unidade vinculada para validar o comportamento básico da RPC em shadow mode.

Simulação criada:

```text
c86e63c2-d931-4f03-859b-a32d62f702eb
```

Resultado resumido:

```json
{
  "valor_total": "1000000.00",
  "entrada": "350000.00",
  "financiamento": "650000.00",
  "fluxo_canonico_shadow": "true",
  "fluxo_canonico_versao": "20D.5",
  "financiamento_calculado_residual": "true"
}
```

Validação agregada do canônico:

```json
{
  "u_parcela_unica_obra_ok": 1,
  "financiamento_residual_ok": 1,
  "periodicidade_obra_ok": 1,
  "total_linhas_canonicas": 7,
  "total_motor_financeiro": "1000000",
  "total_obra_sem_financiamento": "350000",
  "total_financiamento": "650000"
}
```

Observação: esse teste foi útil como validação inicial, mas não substitui o teste financeiro real com unidade vinculada.

---

## 7. Seleção da unidade real 501

Foi identificada uma unidade real para o teste forte da 20D.5:

```json
{
  "unidade_id": "fd546fdd-4fa9-4c9d-9344-0b7a5023afe4",
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "empreendimento_id": "69230c50-cffd-4f87-9b37-7266ec0f54fc",
  "empreendimento_nome": "Chateau Jardin",
  "torre": "Harmonie Vert e Gris",
  "unidade": "501",
  "final": "5",
  "andar": 1,
  "metragem": "185.10",
  "valor_tabela": "3783070.89",
  "status_comercial": "disponivel"
}
```

A unidade possui dados financeiros importados pelo parser, incluindo:

```text
sinal_1 = 226984.25
a4_each = 100881.89
mensal_each = 14711.94
inter_each = 88271.65
chaves_each = 113492.13
valor_total = 3783070.89
financiamento = 2080688.99
meta_obra_pct = 45
financiamento_data = 2029-09-15
```

---

## 8. Validação de autenticação HTTP antes do curl da RPC

O teste HTTP foi executado com usuário real autenticado.

Endpoint de validação:

```bash
curl -i "$SUPABASE_URL/auth/v1/user" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $USER_ACCESS_TOKEN"
```

Resultado real:

```text
HTTP/2 200
```

Usuário validado:

```json
{
  "id": "10b90f39-84a5-49a4-8ba6-165ef7178f11",
  "aud": "authenticated",
  "role": "authenticated",
  "email": "wagner@tegravendas.com.br"
}
```

Corretor ativo vinculado:

```json
{
  "corretor_id": "9be9dae0-1699-49a2-a7ab-beeef274f22b",
  "user_id": "10b90f39-84a5-49a4-8ba6-165ef7178f11",
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "nome": "Wagner",
  "email": "wagner@tegravendas.com.br",
  "role": "admin_local",
  "ativo": true
}
```

Não registrar neste documento nenhum token, API key, refresh token ou service role key.

---

## 9. Teste E2E via curl — RPC `criar_mesa_simulacao`

### 9.1 Chamada executada

A chamada foi feita via PostgREST/RPC:

```bash
curl -i -X POST "$SUPABASE_URL/rest/v1/rpc/criar_mesa_simulacao" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $USER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "p_empresa_id": "[REDACTED_EMPRESA_ID]",
    "p_empreendimento_id": "69230c50-cffd-4f87-9b37-7266ec0f54fc",
    "p_unidade_id": "fd546fdd-4fa9-4c9d-9344-0b7a5023afe4",
    "p_lead_id": null,
    "p_cliente_nome": "PILOTO CURL 20D.5 UNIDADE 501",
    "p_valor_total": 3783070.89,
    "p_meta_obra_pct": 45,
    "p_tabela_provisoria": false,
    "p_fluxo_json": [
      { "grupo": "e", "id": "ato", "label": "Ato", "valor": 226984.25, "qty": 1, "total": 226984.25, "date": "2026-06-01", "source": "curl_20d5_501" },
      { "grupo": "c", "id": "complementos", "label": "Complementos", "valor": 100881.89, "qty": 3, "total": 302645.67, "periodicidade": "mensal", "date": "2026-07-01", "isGroup": true, "source": "curl_20d5_501" },
      { "grupo": "m", "id": "mensais", "label": "Mensais", "valor": 14711.94, "qty": 36, "total": 529629.84, "periodicidade": "mensal", "date": "2026-09-15", "isGroup": true, "source": "curl_20d5_501" },
      { "grupo": "a", "id": "intermediarias", "label": "Intermediárias", "valor": 88271.65, "qty": 6, "total": 529629.90, "periodicidade": "semestral", "date": "2026-12-15", "isGroup": true, "source": "curl_20d5_501" },
      { "grupo": "u", "id": "parcela_unica", "label": "Parcela única / chaves", "valor": 113492.13, "qty": 1, "total": 113492.13, "date": "2029-09-15", "source": "curl_20d5_501" },
      { "grupo": "p", "id": "periodicidade_final", "label": "Periodicidade/Final(is)", "valor": 1, "qty": 1, "total": 1, "date": "2029-09-15", "periodicidade": "obra", "source": "curl_20d5_501" }
    ]
  }'
```

### 9.2 Resultado HTTP

Resultado real:

```text
HTTP/2 200
```

UUID retornado:

```text
0e8ed676-50e6-4401-b767-0532c2481209
```

---

## 10. Validação da simulação criada por curl

Consulta em `public.mesa_simulacoes`:

```json
{
  "id": "0e8ed676-50e6-4401-b767-0532c2481209",
  "empresa_id": "[REDACTED_EMPRESA_ID]",
  "corretor_id": "9be9dae0-1699-49a2-a7ab-beeef274f22b",
  "empreendimento_id": "69230c50-cffd-4f87-9b37-7266ec0f54fc",
  "unidade_estoque_id": "fd546fdd-4fa9-4c9d-9344-0b7a5023afe4",
  "cliente_nome": "PILOTO CURL 20D.5 UNIDADE 501",
  "valor_total": "3783070.89",
  "entrada": "1702381.79",
  "financiamento": "2080689.10",
  "fluxo_canonico_shadow": "true",
  "fluxo_canonico_versao": "20D.5",
  "financiamento_calculado_residual": "true",
  "created_at": "2026-05-29 14:10:32.983245+00"
}
```

---

## 11. Validação da escrita legada

Tabela validada:

```text
public.mesa_fluxo_pagamentos
```

Resultado real:

```json
[
  { "tipo": "entrada", "descricao": "Ato", "valor": "226984.25", "quantidade": 1, "periodicidade": null, "data_prevista": "2026-06-01", "ordem": 0 },
  { "tipo": "curto_prazo", "descricao": "Complementos", "valor": "100881.89", "quantidade": 3, "periodicidade": "mensal", "data_prevista": "2026-07-01", "ordem": 1 },
  { "tipo": "periodica", "descricao": "Mensais", "valor": "14711.94", "quantidade": 36, "periodicidade": "mensal", "data_prevista": "2026-09-15", "ordem": 2 },
  { "tipo": "intermediaria", "descricao": "Intermediárias", "valor": "88271.65", "quantidade": 6, "periodicidade": "semestral", "data_prevista": "2026-12-15", "ordem": 3 },
  { "tipo": "quitacao", "descricao": "Parcela única / chaves", "valor": "113492.13", "quantidade": 1, "periodicidade": null, "data_prevista": "2029-09-15", "ordem": 4 },
  { "tipo": "observacao", "descricao": "Periodicidade/Final(is)", "valor": "1.00", "quantidade": 1, "periodicidade": "obra", "data_prevista": "2029-09-15", "ordem": 5 }
]
```

Interpretação:

```text
PASS: a tabela legada continua sendo gravada.
PASS: u continua como quitacao no legado apenas por compatibilidade histórica.
PASS: p continua como observacao no legado apenas por compatibilidade histórica.
```

---

## 12. Validação da escrita canônica shadow

Tabela validada:

```text
public.mesa_fluxo_pagamentos_canonico
```

### 12.1 Linhas canônicas relevantes

#### Entrada / ato

```json
{
  "grupo_original": "e",
  "grupo_canonico": "entrada_ato",
  "natureza_financeira": "entrada_obra",
  "valor_total": "226984.25",
  "entra_motor_financeiro": true
}
```

#### Complementos

```json
{
  "grupo_original": "c",
  "grupo_canonico": "entrada_complemento",
  "natureza_financeira": "complemento_entrada_obra",
  "valor_total": "302645.67",
  "entra_motor_financeiro": true
}
```

#### Mensais

```json
{
  "grupo_original": "m",
  "grupo_canonico": "mensal_obra",
  "natureza_financeira": "mensal_obra",
  "quantidade": 36,
  "valor_total": "529629.84",
  "entra_motor_financeiro": true
}
```

#### Intermediárias

```json
{
  "grupo_original": "a",
  "grupo_canonico": "intermediaria_obra",
  "natureza_financeira": "intermediaria_obra",
  "quantidade": 6,
  "valor_total": "529629.90",
  "entra_motor_financeiro": true
}
```

#### Parcela única / chaves

```json
{
  "grupo_original": "u",
  "grupo_canonico": "parcela_unica_obra",
  "natureza_financeira": "parcela_unica_chaves_obra",
  "valor_total": "113492.13",
  "metadata": {
    "observacao": "parcela_unica_obra_nao_quitacao"
  }
}
```

#### Periodicidade / Final(is)

```json
{
  "grupo_original": "p",
  "grupo_canonico": "periodicidade_obra",
  "natureza_financeira": "controle_periodo_obra",
  "entra_agenda": false,
  "entra_motor_financeiro": false,
  "valor_simbolico": true,
  "metadata": {
    "observacao": "periodicidade_final_simbolica_controle_obra"
  }
}
```

#### Financiamento residual

```json
{
  "grupo_original": "f_residual",
  "grupo_canonico": "financiamento_saldo",
  "natureza_financeira": "saldo_devedor_financiamento",
  "valor_total": "2080689.10",
  "data_prevista": "2029-09-15",
  "origem_data": "unidades_estoque.observacoes.financiamento_data",
  "fonte_tipo": "residual_valor_total_menos_fluxo_obra",
  "fonte_valor": "mesa_simulacoes.valor_total_menos_obra_total",
  "entra_agenda": true,
  "entra_motor_financeiro": true,
  "possui_link_legado": false
}
```

---

## 13. Validação agregada do canônico

Consulta agregada executada sobre `public.mesa_fluxo_pagamentos_canonico` para a simulação `0e8ed676-50e6-4401-b767-0532c2481209`.

Resultado real:

```json
{
  "u_parcela_unica_obra_ok": 1,
  "financiamento_residual_ok": 1,
  "periodicidade_obra_ok": 1,
  "total_linhas_canonicas": 7,
  "total_motor_financeiro": "3783070.89",
  "total_obra_sem_financiamento": "1702381.79",
  "total_financiamento": "2080689.10",
  "data_financiamento_residual": "2029-09-15"
}
```

Interpretação:

```text
PASS: u -> parcela_unica_obra.
PASS: f_residual -> financiamento_saldo.
PASS: p -> periodicidade_obra.
PASS: periodicidade_obra não entra no motor financeiro.
PASS: financiamento residual foi criado com data vinda de unidades_estoque.observacoes.financiamento_data.
PASS: total do motor financeiro fecha com valor_total da simulação.
```

---

## 14. Teste negativo de acesso direto à tabela shadow

### 14.1 Teste por role SQL — anon

Comando lógico executado:

```sql
set local role anon;
select count(*)
from public.mesa_fluxo_pagamentos_canonico
where simulacao_id = 'c86e63c2-d931-4f03-859b-a32d62f702eb'::uuid;
```

Resultado real:

```text
ERROR: 42501: permission denied for table mesa_fluxo_pagamentos_canonico
```

### 14.2 Teste por role SQL — authenticated

Comando lógico executado:

```sql
set local role authenticated;
select count(*)
from public.mesa_fluxo_pagamentos_canonico
where simulacao_id = 'c86e63c2-d931-4f03-859b-a32d62f702eb'::uuid;
```

Resultado real:

```text
ERROR: 42501: permission denied for table mesa_fluxo_pagamentos_canonico
```

Interpretação:

```text
PASS: anon sem acesso direto.
PASS: authenticated sem acesso direto.
PASS: acesso operacional deve ocorrer por RPC SECURITY DEFINER.
```

### 14.3 Observação sobre teste negativo via curl

Foi tentado acesso HTTP direto à tabela shadow antes da correção das variáveis de autenticação. O retorno inicial foi `invalid_token` / `Invalid API key`, portanto esse resultado inicial não é evidência válida de bloqueio da tabela.

Após a correção de autenticação, a RPC via curl foi validada com sucesso. O bloqueio direto da tabela shadow já está comprovado por grants/RLS e teste de role SQL. Para evidência HTTP adicional, executar posteriormente:

```bash
curl -i "$SUPABASE_URL/rest/v1/mesa_fluxo_pagamentos_canonico?select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $USER_ACCESS_TOKEN"
```

Resultado esperado:

```text
403 / permission denied for table mesa_fluxo_pagamentos_canonico
```

---

## 15. Itens explicitamente não alterados

Durante a aplicação/teste da 20D.5, não foram alterados:

```text
parser
Worker
Make/n8n
frontend
motor financeiro existente
tabela legada de forma destrutiva
propostas antigas
```

A migration apenas acrescentou a camada canônica shadow e atualizou a origem de gravação da RPC `public.criar_mesa_simulacao`.

---

## 16. Veredito

```text
20D.5 migration aplicada: PASS
20D.5 estrutura/RLS/grants: PASS
20D.5 piloto SQL controlado: PASS
20D.5 curl/API E2E com unidade real 501: PASS
20D.5 escrita no legado: PASS
20D.5 escrita no canônico shadow: PASS
20D.5 u -> parcela_unica_obra: PASS
20D.5 f_residual -> financiamento_saldo: PASS
20D.5 p -> periodicidade_obra: PASS
20D.5 bloqueio direto anon/authenticated por grants/RLS/role SQL: PASS
```

Conclusão:

```text
20D.5 validada com teste forte usando usuário real autenticado, corretor ativo, empresa real, empreendimento real, unidade real 501, valor real de tabela, PostgREST real, RPC real, gravação real no legado e gravação real no canônico shadow.
```

---

## 17. Próximos passos recomendados

```text
1. Executar e anexar também evidência HTTP/curl de bloqueio direto da tabela shadow com token válido.
2. Atualizar o status da PR #29 removendo a pendência da aplicação/testes da 20D.5.
3. Manter a PR como draft até decisão explícita sobre promoção do canônico para leitura operacional.
4. Não promover mesa_fluxo_pagamentos_canonico como fonte oficial do frontend sem nova fase, novo diff e autorização explícita.
5. Não alterar parser, Worker, Make/n8n ou motor financeiro sem aprovação específica.
```
