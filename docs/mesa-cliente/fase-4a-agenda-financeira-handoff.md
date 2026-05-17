# MesaCliente — Fase 4A: Agenda Financeira — handoff obrigatório

Branch de trabalho: `feature/mesa-cliente-engenharia-financeira`.

Este documento é o contrato de execução da Fase 4A da Engenharia Financeira do MesaCliente. Ele deve ser lido antes de escrever qualquer migration, teste ou patch relacionado à agenda financeira.

A Fase 4A cria a espinha dorsal da agenda financeira: transformar o fluxo bruto do MesaCliente em parcelas datadas e persistidas em `mesa_cliente_fluxo_parcelas`, sem alterar frontend, parser, Worker, Make/n8n ou motor atual fora da migration proposta.

---

## 1. Trava obrigatória antes de qualquer implementação

Antes de escrever a migration, respeitar integralmente este contrato:

1. Não mexer no frontend.
2. Não mexer no parser.
3. Não mexer no Worker, Make ou n8n.
4. Não mexer no motor financeiro atual fora da migration proposta.
5. Não criar regra hardcoded no client.
6. Não criar RPC com `empresa_id` soberano vindo do frontend.
7. Não expor VPL, prêmio, comissão ou política para visão cliente-safe.
8. Não conceder `EXECUTE` para `anon`.
9. Não fazer merge na `main` sem aprovação explícita.
10. Não criar operação financeira antes da agenda financeira estar validada.
11. Não iniciar tela bonita antes de banco/RPC/testes estarem blindados.

A outra conversa/IA deve começar confirmando que entendeu esta trava. Se a resposta dela tentar alterar front, parser ou operação financeira antes da agenda, parar e corrigir o rumo.

---

## 2. Plano para previews Vercel e múltiplos previews vindos da `main`

Há muitos previews gerados a partir da `main`. Para a Fase 4A, eles não devem ser usados como fonte de verdade.

### Regra operacional

1. A fonte técnica da Fase 4A é a branch:

```text
feature/mesa-cliente-engenharia-financeira
```

2. A Fase 4A é essencialmente banco/RPC/teste SQL. Preview Vercel não prova segurança de RPC.
3. Previews baseados na `main` devem ser ignorados para validar Engenharia Financeira.
4. Enquanto não houver integração de frontend, preview Vercel é apenas sinal de que o app não quebrou build; não é validação funcional financeira.
5. Antes de qualquer PR para `main`, comparar branch contra `main` e verificar que não houve alteração de front, parser, Worker, Make ou n8n.

### Plano prático

- Manter a branch `feature/mesa-cliente-engenharia-financeira` como linha oficial.
- Criar migrations e testes apenas nessa branch.
- Validar no Supabase SQL Editor com `BEGIN` + `ROLLBACK`.
- Só depois abrir PR draft, com checklist de segurança.
- Não promover preview para produção antes dos gates de banco, RLS, auth, tenant e cliente-safe.

---

## 3. Objetivo exato da Fase 4A

Criar uma RPC forte para gerar a agenda financeira de parcelas de uma simulação do MesaCliente.

A RPC deve:

1. Receber uma simulação existente.
2. Receber a data do ato.
3. Receber um payload financeiro bruto, derivado do parser atual.
4. Resolver `empresa_id` e `empreendimento_id` no banco.
5. Validar usuário, tenant, empresa, empreendimento, simulação e perfil.
6. Gerar parcelas em `mesa_cliente_fluxo_parcelas`.
7. Aplicar regras de data conforme contrato.
8. Marcar periodicidade simbólica como não negociável.
9. Retornar resumo seguro da agenda criada.
10. Não expor cálculo administrativo sensível.

---

## 4. Arquivos esperados da Fase 4A

Criar, no mínimo:

```text
supabase/migrations/<timestamp>_mesa_cliente_rpc_gerar_agenda_parcelas.sql
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_parcelas_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_parcelas_negativos_rollback.sql
```

O timestamp deve seguir o padrão já usado no projeto, sem sobrescrever migrations existentes.

---

## 5. RPC obrigatória

Nome proposto:

```sql
public.gerar_mesa_cliente_agenda_parcelas(
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
revoke all on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) from public;
revoke all on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) from anon;
grant execute on function public.gerar_mesa_cliente_agenda_parcelas(uuid, date, jsonb, jsonb) to authenticated;
```

`anon` deve falhar com `permission denied for function` ou equivalente.

---

## 6. Validações obrigatórias dentro da RPC

A RPC deve validar, nesta ordem lógica:

1. `auth.uid()` obrigatório via `mesa_cliente_assert_auth()`.
2. Contexto do usuário via `mesa_cliente_current_corretor_context()`.
3. Usuário ativo.
4. Empresa/tenant resolvido pelo banco, não pelo frontend.
5. Simulação existente em `mesa_simulacoes`.
6. Simulação pertence à empresa do usuário.
7. `empreendimento_id` da simulação pertence à empresa.
8. Usuário pode acessar a empresa via `mesa_cliente_can_access_empresa()`.
9. Perfil permitido para gerar agenda.
10. `p_data_ato` obrigatório.
11. `p_fluxo_json` não nulo.
12. Payload deve ter estrutura suportada.
13. Valores financeiros não podem ser negativos.
14. Grupo deve ser conhecido.
15. Periodicidade simbólica deve ser gravada como informativa e não negociável.

### Perfis permitidos

A agenda pode ser gerada por perfis operacionais autorizados, desde que dentro da empresa/tenant correta. Política mínima recomendada:

- `admin_global`
- `admin_local`
- `gestor`
- corretor ativo da empresa, se o fluxo de mesa exigir operação pelo corretor

Se houver dúvida, começar mais restritivo e liberar corretor somente após teste de uso real. Segurança primeiro; conforto depois.

---

## 7. Regras de data obrigatórias

| Cenário | `origem_data` | `regra_data` | Regra |
|---|---|---|---|
| data oficial completa | `tabela_oficial` | null ou origem textual | prevalece sempre |
| data comercial completa | `tabela_comercial_data` | null ou origem textual | usar data informada |
| somente mês/ano | `tabela_comercial_mes` | `usar_dia_do_ato` | usar o dia do ato |
| mês/ano sem dia válido | `tabela_comercial_mes` | `ultimo_dia_valido_mes` | exemplo: ato dia 31 e mês 02 => último dia de fevereiro |
| chaves por cabeçalho 30 dias | `cabecalho_regra` | `cabecalho_30_dias` | 30 dias antes do financiamento/data base aplicável |
| chaves por cabeçalho 60 dias | `cabecalho_regra` | `cabecalho_60_dias` | 60 dias antes do financiamento/data base aplicável |
| calculada pelo ato | `calculada_ato` | regra explícita | usar data do ato como base |
| sem informação confiável | `estimada` | regra explícita | permitir apenas quando documentado no metadata |
| ajuste manual | `manual` | motivo obrigatório | usar somente para caso administrativo autorizado |

Observação: não alterar enum em produção para encaixar nomes novos. Usar os enums existentes e complementar `regra_data`/`metadata`.

---

## 8. Mapeamento para `mesa_cliente_fluxo_parcelas`

Schema atual conhecido:

| Campo lógico | Coluna real |
|---|---|
| empresa resolvida | `empresa_id` |
| simulação | `simulacao_id` |
| empreendimento | `empreendimento_id` |
| unidade, se existir | `unidade_estoque_id` |
| grupo | `grupo` |
| descrição | `descricao` |
| valor original | `valor_original` |
| valor atual | `valor_atual` |
| data original | `data_original` |
| data atual | `data_atual` |
| origem da data | `origem_data` |
| regra aplicada | `regra_data` |
| ordem | `ordem` |
| periodicidade simbólica | `eh_periodicidade_simbolica` |
| elegível VPL | `pode_receber_vpl` |
| elegível antecipação | `pode_receber_antecipacao` |
| elegível postergação | `pode_receber_postergacao` |
| payload adicional sanitizado | `metadata` |
| auditoria | `criado_por`, `atualizado_por`, `created_at`, `updated_at` |

A RPC deve preencher `empresa_id` pelo contexto/simulação, nunca pelo payload do cliente.

---

## 9. Idempotência da agenda

A agenda deve ser idempotente por `simulacao_id`.

Opção recomendada para Fase 4A:

```text
Ao gerar agenda novamente para a mesma simulação, apagar parcelas anteriores da simulação e recriar.
```

Condições:

- Só pode apagar parcelas da mesma `empresa_id` e `simulacao_id`.
- Se já houver operação financeira confirmada vinculada às parcelas, a RPC deve bloquear recriação e exigir cancelamento/auditoria futura.
- Como a Fase 4A ainda antecede operação financeira, o teste inicial pode validar recriação simples.

---

## 10. Contrato mínimo do payload de entrada

A RPC deve suportar um payload previsível. Exemplo de formato recomendado para teste:

```json
{
  "parcelas": [
    {
      "grupo": "entrada",
      "descricao": "Ato",
      "valor": 50000,
      "data_oficial": "2026-05-17",
      "ordem": 1
    },
    {
      "grupo": "mensais",
      "descricao": "Mensal 01",
      "valor": 3000,
      "mes_ano": "2026-06",
      "ordem": 2
    },
    {
      "grupo": "periodicidade",
      "descricao": "28 mensais",
      "valor": 0,
      "eh_periodicidade_simbolica": true,
      "ordem": 3
    }
  ],
  "regras_cabecalho": {
    "chaves_dias_antes_financiamento": 60,
    "data_financiamento": "2028-09-30"
  }
}
```

A migration deve documentar quais formatos aceita. Se o parser atual produzir formato diferente, adaptar no banco de forma defensiva, mas sem alterar o parser nesta fase.

---

## 11. Regras de elegibilidade por grupo

Valores iniciais recomendados para flags de negociação:

| Grupo | `pode_receber_vpl` | `pode_receber_antecipacao` | `pode_receber_postergacao` | Observação |
|---|---:|---:|---:|---|
| entrada | false | false | false | normalmente ato não negocia por VPL sem regra específica |
| ato | false | false | false | equivalente operacional da entrada |
| mensais | true | true | true | elegível conforme política |
| anuais | true | true | true | elegível conforme política |
| intermediarias | true | true | true | mapear como anuais/intermediárias |
| chaves | true | true | true | conforme política |
| parcela_unica | true | true | true | conforme política |
| financiamento | false | false | false | VPL financiamento bloqueado por padrão atual |
| periodicidade | false | false | false | sempre simbólica/informativa |

A política financeira posterior ainda é soberana para aceitar/rejeitar operações. Essas flags são apenas base de agenda e UX administrativa.

---

## 12. Retorno esperado da RPC

A RPC deve retornar JSON com resumo sem dados sensíveis:

```json
{
  "ok": true,
  "simulacao_id": "uuid",
  "empresa_id": "uuid",
  "empreendimento_id": "uuid",
  "qtd_parcelas_criadas": 10,
  "qtd_periodicidades_simbolicas": 1,
  "total_valor_original": 1000000,
  "total_valor_atual": 1000000,
  "parcelas": [
    {
      "id": "uuid",
      "grupo": "mensais",
      "descricao": "Mensal 01",
      "valor_atual": 3000,
      "data_atual": "2026-06-17",
      "origem_data": "tabela_comercial_mes",
      "eh_periodicidade_simbolica": false,
      "pode_receber_vpl": true,
      "pode_receber_antecipacao": true,
      "pode_receber_postergacao": true,
      "ordem": 2
    }
  ]
}
```

Não retornar:

- VPL;
- prêmio;
- comissão;
- política;
- taxa interna;
- metadata sensível;
- dados de outro tenant;
- payload bruto integral se contiver dados internos.

---

## 13. Teste 07A — positivo com rollback

Arquivo esperado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_parcelas_rollback.sql
```

O teste deve:

1. `BEGIN`.
2. Simular usuário autenticado usando `set_config('request.jwt.claim.sub', ...)`, conforme padrão dos testes anteriores.
3. Escolher admin/gestor/corretor válido.
4. Criar ou selecionar uma simulação temporária segura.
5. Chamar `gerar_mesa_cliente_agenda_parcelas`.
6. Validar quantidade de parcelas.
7. Validar data oficial prevalecendo.
8. Validar mês/ano usando dia do ato.
9. Validar dia 31 em fevereiro indo para último dia válido.
10. Validar chaves 30/60 dias antes.
11. Validar periodicidade simbólica não negociável.
12. Validar idempotência em segunda chamada.
13. Validar retorno sem campos sensíveis.
14. `ROLLBACK`.

Blocos esperados:

```text
01_auth_context                         PASS
02_simulacao_temporaria                 PASS
03_rpc_agenda_executou                  PASS
04_data_oficial_prevaleceu              PASS
05_mes_ano_usou_dia_ato                 PASS
06_mes_sem_dia_usou_ultimo_dia          PASS
07_chaves_cabecalho_30_60_dias          PASS
08_periodicidade_simbolica_bloqueada    PASS
09_flags_negociacao_corretas            PASS
10_idempotencia                         PASS
11_payload_cliente_safe                 PASS
12_rollback_notice                      INFO
```

---

## 14. Teste 07B — negativos com rollback

Arquivo esperado:

```text
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_parcelas_negativos_rollback.sql
```

O teste deve validar bloqueio de:

1. `anon` executando RPC.
2. usuário sem `auth.uid()`.
3. simulação inexistente.
4. simulação de outra empresa.
5. empreendimento inconsistente.
6. payload nulo.
7. payload malformado.
8. valor negativo.
9. grupo desconhecido.
10. tentativa de enviar `empresa_id` no payload para forçar tenant.
11. tentativa de marcar periodicidade simbólica como negociável.
12. tentativa de recriar agenda quando houver operação confirmada, se essa proteção já for possível.

Blocos esperados:

```text
01_anon_bloqueado                       PASS
02_sem_auth_bloqueado                   PASS
03_simulacao_inexistente_bloqueada      PASS
04_cross_tenant_bloqueado               PASS
05_payload_nulo_bloqueado               PASS
06_payload_malformado_bloqueado         PASS
07_valor_negativo_bloqueado             PASS
08_grupo_desconhecido_bloqueado         PASS
09_empresa_id_payload_ignorado          PASS
10_periodicidade_negociavel_bloqueada   PASS
11_rollback_notice                      INFO
```

---

## 15. Critérios de aceite da Fase 4A

A Fase 4A só pode ser considerada pronta quando:

1. Migration criada na branch correta.
2. RPC criada com `security definer` e `set search_path = public`.
3. `anon` sem `EXECUTE`.
4. `authenticated` com `EXECUTE` apenas na RPC.
5. Sem escrita direta liberada nas tabelas financeiras.
6. Teste 07A passa 100%.
7. Teste 07B passa 100%.
8. Cross-tenant bloqueado.
9. Datas batem com regra oficial.
10. Periodicidade simbólica não entra como parcela negociável.
11. Retorno da RPC não expõe dado administrativo sensível.
12. Nenhum arquivo de frontend/parser/Worker/Make/n8n foi alterado.
13. Preview Vercel não foi usado como critério principal.
14. Banco/RPC continuam soberanos.

---

## 16. Checklist de revisão antes de commit

Antes de commitar:

```text
[ ] Estou na branch feature/mesa-cliente-engenharia-financeira
[ ] Não alterei frontend
[ ] Não alterei parser
[ ] Não alterei Worker/Make/n8n
[ ] Não alterei motor financeiro fora da migration proposta
[ ] RPC usa security definer
[ ] RPC usa set search_path = public
[ ] RPC chama mesa_cliente_assert_auth()
[ ] RPC valida usuário ativo
[ ] RPC valida empresa/tenant pelo banco
[ ] RPC valida empreendimento
[ ] RPC valida simulação
[ ] RPC valida perfil
[ ] RPC não confia em empresa_id do frontend
[ ] anon não tem execute
[ ] authenticated tem execute restrito
[ ] Teste positivo usa BEGIN + ROLLBACK
[ ] Teste negativo usa BEGIN + ROLLBACK
[ ] Payload de retorno não expõe VPL/prêmio/comissão/política
```

---

## 17. Mensagem pronta para colar na outra conversa

```text
Estamos na branch feature/mesa-cliente-engenharia-financeira do projeto fecha.ai/Fech.ai.

Antes de escrever qualquer migration da Fase 4A, respeite este contrato:

- Não mexer no frontend.
- Não mexer no parser.
- Não mexer no Worker/Make/n8n.
- Não mexer no motor financeiro atual fora da migration proposta.
- Não criar regra hardcoded no client.
- Não criar RPC com empresa_id soberano vindo do frontend.
- Não expor VPL/prêmio/comissão/política para cliente-safe.
- Não conceder EXECUTE para anon.
- Não criar operação financeira antes da agenda financeira.
- Não usar preview Vercel vindo da main como validação da Fase 4A.

A próxima entrega é exclusivamente a Fase 4A: criar a RPC gerar_mesa_cliente_agenda_parcelas e os testes 07A/07B com BEGIN + ROLLBACK.

A RPC deve seguir obrigatoriamente:

security definer
set search_path = public

e deve ter:

- auth.uid() obrigatório via mesa_cliente_assert_auth()
- validação de usuário ativo
- validação de empresa/tenant pelo banco
- validação de empreendimento
- validação de simulação
- validação de perfil
- grants restritos para authenticated
- anon bloqueado
- retorno sem dados sensíveis

Não avance para frontend, registro de operação financeira ou confirmação/cancelamento antes da agenda financeira estar validada.

Documento de handoff oficial:
docs/mesa-cliente/fase-4a-agenda-financeira-handoff.md
```

---

## 18. Próxima ação após este handoff

A próxima conversa/IA deve produzir primeiro um rascunho da migration e dos testes, sem aplicar nada na `main`.

Ordem correta:

```text
1. Ler este handoff.
2. Ler engenharia-financeira-roadmap-execucao-ate-mesa-cliente.md.
3. Conferir schema real de mesa_simulacoes e mesa_cliente_fluxo_parcelas.
4. Escrever migration da RPC.
5. Escrever teste 07A positivo rollback.
6. Escrever teste 07B negativo rollback.
7. Validar grants.
8. Só depois discutir próxima fase.
```

A agenda financeira é a coluna vertebral. Operação financeira, UI e mesa com cliente só entram depois que essa coluna estiver reta.
