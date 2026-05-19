# MesaCliente — Fase 4A: Agenda Financeira JSON-first — contrato canônico

**Status:** Oficial  
**Versão:** v1.0  
**Data:** 2026-05-18  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**ADR:** `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`  
**Protocolo obrigatório:** `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`  

---

## 1. Decisão oficial

A Fase 4A é **Dry-run / JSON-first**.

Ela gera uma agenda financeira normalizada em JSON, mas **não persiste** parcelas em `mesa_cliente_fluxo_parcelas` e **não cria** operação em `mesa_cliente_fluxo_operacoes`.

Frase de controle:

> **4A pensa. 4B grava. 4C mostra para o cliente.**

---

## 2. Fora de escopo absoluto da Fase 4A

A Fase 4A não pode fazer:

- `INSERT` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` em `mesa_cliente_fluxo_parcelas`;
- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `INSERT` em `mesa_cliente_fluxo_operacoes`;
- `UPDATE` em `mesa_cliente_fluxo_operacoes`;
- `DELETE` em `mesa_cliente_fluxo_operacoes`;
- persistência definitiva de agenda;
- operação financeira;
- confirmação/cancelamento de operação;
- cálculo ou exposição de VPL;
- cálculo ou exposição de prêmio;
- cálculo ou exposição de comissão;
- exposição de política interna;
- alteração de frontend;
- alteração de parser;
- alteração de Worker/Make/n8n;
- `EXECUTE` para `anon`;
- `empresa_id` soberano vindo do frontend/payload.

Se qualquer item acima aparecer na implementação da 4A, a entrega está errada, mesmo que compile.

---

## 3. Objetivo da Fase 4A

Criar uma RPC administrativa segura para:

1. receber uma simulação existente;
2. receber a data do ato;
3. receber o fluxo financeiro bruto em JSON;
4. receber payload complementar da tabela, quando houver;
5. validar usuário, empresa/tenant, empreendimento, simulação e perfil;
6. resolver datas da agenda;
7. normalizar parcelas;
8. classificar periodicidade simbólica;
9. retornar agenda financeira administrativa em JSON;
10. provar que nenhuma tabela financeira sofreu DML.

---

## 4. RPC oficial

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

Padrão obrigatório:

```sql
language plpgsql
security definer
set search_path = public
```

Grants obrigatórios:

```sql
revoke all on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) from public;
revoke all on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) from anon;
grant execute on function public.mesa_cliente_gerar_agenda_financeira_admin(uuid, date, jsonb, jsonb) to authenticated;
```

---

## 5. Significado de `_admin`

O sufixo `_admin` significa:

> uso interno/administrativo seguro.

Não significa cliente-safe.

A permissão pode ser definida conforme o modelo real de perfil, desde que a RPC valide tenant/empresa e não exponha dados sensíveis indevidos.

Cliente-safe fica para a Fase 4C.

---

## 6. Validações obrigatórias

A RPC deve validar:

1. `auth.uid()` obrigatório, preferencialmente via helper existente `mesa_cliente_assert_auth()` se confirmado no schema.
2. Usuário ativo.
3. Empresa/tenant resolvido pelo banco.
4. Acesso do usuário à empresa, preferencialmente via helper existente se confirmado.
5. Simulação existente.
6. Simulação pertence à empresa autorizada.
7. Empreendimento da simulação pertence à empresa autorizada.
8. Perfil/permissão autorizado.
9. `p_data_ato` obrigatório.
10. `p_fluxo_json` obrigatório.
11. Payload em estrutura suportada.
12. Valores financeiros não negativos.
13. Grupo conhecido.
14. Periodicidade simbólica sempre não negociável.
15. `empresa_id` no payload deve ser ignorado ou rejeitado, nunca usado como autoridade.

---

## 7. Payload mínimo suportado

A RPC deve aceitar, no mínimo, estrutura de parcelas em:

```json
{
  "parcelas": [
    {
      "grupo": "entrada",
      "descricao": "Ato",
      "valor": 50000,
      "data_oficial": "2026-05-18",
      "ordem": 1
    }
  ]
}
```

Pode também aceitar array direto, desde que documentado:

```json
[
  {
    "grupo": "mensais",
    "descricao": "Mensal 01",
    "valor": 3000,
    "mes_ano": "2026-06",
    "ordem": 2
  }
]
```

Campos aceitos por item:

- `grupo`;
- `descricao`;
- `valor`;
- `data_oficial`;
- `data`;
- `vencimento`;
- `mes_ano`;
- `ordem`;
- `eh_periodicidade_simbolica`;
- `metadata` sanitizado, se necessário.

---

## 8. Regras de data

| Cenário | Regra |
|---|---|
| data oficial completa | prevalece sempre |
| data/vencimento completo | usar data informada |
| apenas mês/ano | usar o dia do ato |
| mês/ano sem dia válido | usar o último dia válido do mês |
| chaves/parcela única com cabeçalho de 30 dias | calcular 30 dias antes da data base do financiamento, se disponível |
| chaves/parcela única com cabeçalho de 60 dias | calcular 60 dias antes da data base do financiamento, se disponível |
| sem data confiável | retornar erro ou marcar como estimada conforme decisão explícita na implementação |

Regra fixa: data oficial da tabela prevalece sobre regra calculada.

---

## 9. Periodicidade simbólica

Parcelas informativas de periodicidade devem retornar:

```json
{
  "eh_periodicidade_simbolica": true,
  "pode_receber_vpl": false,
  "pode_receber_antecipacao": false,
  "pode_receber_postergacao": false
}
```

A RPC deve bloquear ou corrigir qualquer tentativa de marcar periodicidade simbólica como negociável.

---

## 10. Retorno esperado

Exemplo de retorno administrativo seguro:

```json
{
  "ok": true,
  "cliente_safe": false,
  "fase": "4A_JSON_FIRST",
  "simulacao_id": "uuid",
  "empresa_id": "uuid-resolvido-no-banco",
  "empreendimento_id": "uuid-resolvido-no-banco",
  "qtd_parcelas": 3,
  "qtd_periodicidades_simbolicas": 1,
  "total_valor_original": 100000,
  "agenda": [
    {
      "grupo": "mensais",
      "descricao": "Mensal 01",
      "valor_original": 3000,
      "valor_atual": 3000,
      "data_original": "2026-06-18",
      "data_atual": "2026-06-18",
      "origem_data": "tabela_comercial_mes",
      "regra_data": "usar_dia_do_ato",
      "ordem": 2,
      "eh_periodicidade_simbolica": false,
      "pode_receber_vpl": true,
      "pode_receber_antecipacao": true,
      "pode_receber_postergacao": true
    }
  ]
}
```

Não retornar:

- VPL;
- prêmio;
- comissão;
- política financeira;
- taxa interna;
- margem;
- dados de outro tenant;
- payload bruto integral com dados sensíveis.

---

## 11. Migration esperada

Nome sugerido:

```txt
supabase/migrations/<timestamp>_mesa_cliente_fase_4a_agenda_financeira_json_first.sql
```

A migration deve conter:

- função auxiliar de resolução de data, se necessário;
- RPC `mesa_cliente_gerar_agenda_financeira_admin`;
- grants/revokes;
- comentários de segurança;
- zero DML financeiro.

---

## 12. Testes esperados

Arquivos:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_financeira_json_first_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_financeira_json_first_negativos_rollback.sql
```

O teste 07A deve validar:

- chamada autorizada;
- retorno `ok = true`;
- estrutura da agenda;
- data oficial prevalecendo;
- mês/ano usando dia do ato;
- mês sem dia válido usando último dia do mês;
- periodicidade simbólica não negociável;
- ausência de campos sensíveis;
- `count_before = count_after` em `mesa_cliente_fluxo_parcelas`;
- `count_before = count_after` em `mesa_cliente_fluxo_operacoes`.

O teste 07B deve validar:

- bloqueio sem auth;
- bloqueio de `anon`;
- bloqueio de simulação inexistente;
- bloqueio cross-tenant;
- bloqueio de payload nulo/malformado;
- bloqueio de valor negativo;
- bloqueio de grupo desconhecido;
- bloqueio/ignorar tentativa de `empresa_id` soberano;
- bloqueio de periodicidade simbólica negociável.

---

## 13. Critério de aceite

A Fase 4A só será considerada pronta quando:

1. migration canônica criada na branch correta;
2. RPC compilar;
3. `security definer` aplicado;
4. `set search_path = public` aplicado;
5. `anon` sem execute;
6. `authenticated` com execute restrito;
7. nenhuma DML financeira na RPC;
8. testes 07A/07B criados;
9. testes 07A/07B usam `BEGIN` + `ROLLBACK`;
10. testes provam zero efeito colateral;
11. documentos antigos conflitantes estiverem marcados como obsoletos ou substituídos;
12. nenhuma alteração em frontend/parser/Worker/Make/n8n.

---

## 14. Próximo passo após a Fase 4A

Apenas depois da 4A validada:

```txt
4B = persistir agenda com lock, idempotência e auditoria
4C = leitura cliente-safe
5A = simular impacto financeiro com agenda persistida
5B = registrar operação financeira
5C = confirmar/cancelar operação
Depois = integração front/BFF
```

---

## 15. Observação sobre documentos anteriores

Documentos anteriores que mencionem persistir parcelas em `mesa_cliente_fluxo_parcelas` na Fase 4A foram substituídos por este contrato canônico e pelo ADR-0001.

A persistência pertence à Fase 4B.
