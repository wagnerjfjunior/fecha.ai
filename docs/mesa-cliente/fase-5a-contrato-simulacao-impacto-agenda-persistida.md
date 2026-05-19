# FECH.AI / MesaCliente — Fase 5A.1 — Contrato Final da Simulação de Impacto com Agenda Persistida

**Status:** contrato final fechado para preflight — sem SQL de implementação nesta etapa  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5A.1 — simular impacto financeiro administrativo usando agenda persistida  
**Data de abertura:** 2026-05-18  
**Data de fechamento do contrato:** 2026-05-18  
**Documento canônico:** sim

---

## 1. Decisão final e documento principal

Este é o documento principal da Fase 5A.1.

A Fase 5A.1 fica oficialmente definida como:

```text
Simulação administrativa de impacto financeiro usando agenda persistida como fonte soberana, sem gravar operação financeira.
```

A trilha oficial passa a ser:

```text
4A = gera agenda financeira em JSON, sem persistência
4B = persiste agenda financeira com lock, checksum, idempotência e auditoria
4C = lê agenda persistida em visão cliente-safe, sem vazamento de dados internos
5A.1 = simula impacto financeiro administrativo sobre a agenda persistida, sem gravar operação
5B = registra operação financeira simulada/recomendada/aprovada
5C = confirma ou cancela operação financeira com auditoria
```

Regra curta:

> **4C mostra com segurança. 5A.1 simula impacto administrativo. 5B registra. 5C confirma ou cancela.**

---

## 2. Decisão sobre duplicidade de preflight 10

Havia dois arquivos `10_preflight` na trilha de Engenharia Financeira.

A decisão final é:

| Arquivo | Decisão |
|---|---|
| `supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_simulacao_impacto_agenda_persistida_readonly.sql` | **Canônico/oficial da Fase 5A.1** |
| `supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_impacto_financeiro_readonly.sql` | **Removido da trilha oficial e arquivado como exploratório** |

O arquivo exploratório foi preservado em:

```text
docs/mesa-cliente/rascunhos-sql/preflights-exploratorios/10_preflight_impacto_financeiro_readonly.sql
```

Motivo:

```text
O preflight antigo era genérico/payload-first e referenciava uma leitura histórica de 5A.2.
O contrato atual da Fase 5A.1 é agenda-first.
Dois preflights oficiais para a mesma fase criam ambiguidade operacional.
```

Portanto, somente este arquivo governa a liberação da migration 5A.1:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_simulacao_impacto_agenda_persistida_readonly.sql
```

---

## 3. Gate atual

A partir deste fechamento, a Fase 5A.1 está autorizada apenas para a próxima etapa técnica segura:

```text
Criar/executar o preflight 10 canônico read-only.
```

Ainda não está autorizado:

```text
criar migration 5A.1
criar RPC 5A.1
criar testes 10A/10B/10C
alterar frontend
alterar parser
alterar Worker
alterar Make/n8n
registrar operação financeira
```

---

## 4. Contexto de entrada

A 5A.1 não substitui a 4C e não usa payload cliente-safe como fonte soberana.

A fonte soberana da 5A.1 é a agenda persistida no banco:

```text
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_politicas_financeiras
mesa_cliente_politica_premio_faixas
```

---

## 5. Objetivo da Fase 5A.1

Criar uma camada administrativa de simulação de impacto financeiro baseada na agenda persistida pela 4B.

A 5A.1 deve permitir simular, sem confirmar e sem gravar operação financeira definitiva:

- antecipação;
- postergação;
- VPL administrativo por parcela/camada;
- impacto financeiro agregado;
- melhor aplicação financeira sugerida;
- impacto de prêmio/faixa administrativa quando aplicável.

A 5A.1 deve responder perguntas como:

```text
Se o cliente antecipar R$ X, em qual parcela/camada isso gera maior benefício?
Se o cliente quiser postergar R$ Y, qual será o acréscimo financeiro?
Se aplicar VPL de Z%, quais parcelas são elegíveis e qual impacto administrativo?
Qual opção deve ser recomendada ao corretor/coordenador?
```

---

## 6. Fora de escopo

A Fase 5A.1 não deve:

- alterar frontend;
- alterar parser;
- alterar Worker;
- alterar Make/n8n;
- alterar agenda persistida;
- alterar parcelas persistidas;
- inserir operação financeira definitiva;
- confirmar operação financeira;
- cancelar operação financeira;
- gerar payload cliente-safe final;
- usar payload cliente-safe da 4C como base soberana;
- permitir cálculo financeiro no frontend;
- expor dados administrativos para cliente;
- usar taxa, VPL, política ou faixa vindos do frontend como autoridade final;
- aceitar `empresa_id` do frontend como fonte soberana.

---

## 7. RPC candidata

Nome aprovado para orientar o preflight e a futura migration:

```sql
public.mesa_cliente_simular_impacto_agenda_persistida_admin(
  p_simulacao_id uuid,
  p_data_referencia date default current_date,
  p_modo text default 'melhor_aplicacao',
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
```

---

## 8. Decisão agenda-first

A 5A.1 deve ser agenda-first, não payload-first.

A branch já possui uma RPC administrativa anterior:

```sql
public.mesa_cliente_simular_impacto_financeiro_admin(
  p_empresa_id uuid,
  p_empreendimento_id uuid,
  p_data_ato date,
  p_operacoes jsonb,
  p_politica_id uuid default null
)
returns jsonb
```

Essa RPC pode ser reutilizada quando fizer sentido, mas a 5A.1 não deve depender do frontend para montar toda a lista de operações.

O fluxo correto da 5A.1 é:

```text
ler agenda ativa persistida
-> identificar parcelas elegíveis
-> aplicar política financeira vigente
-> reutilizar funções puras de cálculo composto
-> gerar alternativas
-> recomendar melhor aplicação
-> não gravar nada
```

---

## 9. Modos permitidos

O parâmetro `p_modo` deve aceitar inicialmente:

```text
melhor_aplicacao
antecipacao
postergacao
vpl
comparativo
```

### 9.1. `melhor_aplicacao`

Usado quando o corretor informa um valor disponível para melhorar a condição.

Exemplo conceitual:

```json
{
  "valor_disponivel": 50000,
  "data_base": "2026-05-18",
  "grupos_preferenciais": ["financiamento", "chaves", "anuais", "mensais"]
}
```

### 9.2. `antecipacao`

Simula antecipação de parcelas futuras para uma data anterior.

Exemplo conceitual:

```json
{
  "valor_disponivel": 30000,
  "data_nova": "2026-05-18",
  "grupos_destino": ["financiamento", "chaves", "anuais"]
}
```

### 9.3. `postergacao`

Simula deslocamento de valor de uma parcela anterior para data futura.

Exemplo conceitual:

```json
{
  "valor_movido": 20000,
  "data_destino": "2028-09-30",
  "grupos_origem": ["mensal", "anual", "chaves"]
}
```

### 9.4. `vpl`

Simula impacto administrativo de VPL aplicado sobre parcelas elegíveis.

Exemplo conceitual:

```json
{
  "vpl_aplicado_pct": 3.5,
  "grupos_destino": ["financiamento", "chaves", "anual"]
}
```

### 9.5. `comparativo`

Retorna comparação entre alternativas, sem sugerir apenas uma.

---

## 10. Fonte de dados autorizada

A RPC 5A.1 pode ler:

- `mesa_simulacoes`;
- `corretores`;
- `empresas`;
- `empreendimentos`;
- `mesa_cliente_agendas_financeiras`;
- `mesa_cliente_fluxo_parcelas`;
- `mesa_cliente_politicas_financeiras`;
- `mesa_cliente_politica_premio_faixas`;
- `mesa_cliente_fluxo_operacoes`, apenas para verificar bloqueios/status já confirmados.

A RPC 5A.1 não deve depender de dados soberanos enviados pelo frontend.

---

## 11. DML permitido e proibido

### 11.1. DML permitido

Na Fase 5A.1:

```text
Nenhum DML de negócio é permitido.
```

A 5A.1 deve ser read-only do ponto de vista financeiro.

### 11.2. DML proibido

Proibido:

- `INSERT` em `mesa_cliente_fluxo_operacoes`;
- `UPDATE` em `mesa_cliente_fluxo_operacoes`;
- `DELETE` em `mesa_cliente_fluxo_operacoes`;
- `INSERT` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` em `mesa_cliente_fluxo_parcelas`;
- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `INSERT/UPDATE/DELETE` em `mesa_cliente_agendas_financeiras`;
- escrita em tabelas comerciais, usuários, empresas, empreendimentos, parser ou frontend.

Fixtures transacionais em testes rollback são permitidas apenas dentro de `BEGIN + ROLLBACK`.

---

## 12. Segurança obrigatória

A futura RPC 5A.1 deve seguir:

```sql
security definer
set search_path = public
```

Obrigatório:

- exigir `auth.uid()`;
- validar usuário/corretor ativo;
- validar empresa/tenant resolvido pelo banco;
- validar simulação existente;
- validar empreendimento vinculado à simulação;
- validar agenda ativa existente;
- bloquear cross-tenant;
- bloquear `anon`;
- permitir execução apenas para `authenticated`;
- validar perfil autorizado;
- não aceitar `empresa_id` do frontend como autoridade;
- não aceitar `politica_id` de outro tenant;
- não aceitar parcela de outra simulação/agenda;
- não usar payload cliente-safe como base de cálculo.

---

## 13. Perfis autorizados

A 5A.1 retorna payload administrativo. Portanto, deve ser mais restrita que a 4C cliente-safe.

Perfis sugeridos:

```text
admin_global
admin_local
gestor
coordenador
corretor dono da simulação
```

Corretor que não é dono da simulação só deve acessar se for gestor, coordenador ou admin da mesma empresa.

---

## 14. Política financeira

A RPC deve buscar política vigente pelo banco usando:

```text
empresa_id da simulação
empreendimento_id da simulação
p_data_referencia ou data do ato da simulação/agenda
ativo = true
vigência compatível
```

Regras:

- se não houver política vigente, retornar erro controlado;
- se houver política vencida, retornar erro ou alerta bloqueante conforme contrato do teste;
- se `metodo_calculo <> composto`, bloquear;
- se `base_tempo <> dias_365`, bloquear;
- taxa de antecipação e postergação vêm da política;
- VPL máximo vem da política;
- faixas de prêmio vêm da tabela de faixas;
- flags de grupos permitidos vêm da política.

---

## 15. Parcelas elegíveis

A RPC deve considerar apenas parcelas da agenda ativa.

Parcelas com `eh_periodicidade_simbolica = true` devem ser excluídas de qualquer cálculo.

### 15.1. Antecipação

Usar parcelas com:

```text
pode_receber_antecipacao = true
valor_atual > 0
data_atual > data_nova/data_base
não periodicidade simbólica
```

### 15.2. Postergação

Usar parcelas com:

```text
pode_receber_postergacao = true
valor_atual > 0
data_destino > data_atual
não periodicidade simbólica
```

### 15.3. VPL

Usar parcelas com:

```text
pode_receber_vpl = true
valor_atual > 0
não periodicidade simbólica
grupo permitido pela política
```

---

## 16. Reutilização obrigatória do motor de cálculo já criado

A 5A.1 deve reutilizar as funções puras existentes:

```sql
public.mesa_cliente_financeiro_calcular_antecipacao_composta(...)
public.mesa_cliente_financeiro_calcular_postergacao_composta(...)
public.mesa_cliente_financeiro_calcular_vpl_parcela(...)
```

E pode reutilizar a RPC administrativa existente quando fizer sentido:

```sql
public.mesa_cliente_simular_impacto_financeiro_admin(...)
```

Mas a lista de alternativas deve nascer da agenda persistida.

---

## 17. Retorno esperado da RPC 5A.1

A resposta deve ser administrativa e não cliente-safe.

Exemplo conceitual:

```json
{
  "ok": true,
  "fase": "5A_SIMULACAO_IMPACTO_AGENDA_PERSISTIDA",
  "visao": "administrativa",
  "cliente_safe": false,
  "persistencia": false,
  "dml_financeiro": false,
  "simulacao_id": "uuid",
  "agenda_id": "uuid",
  "politica": {
    "id": "uuid",
    "vpl_max_pct": 6,
    "taxa_antecipacao_ano_pct": 12,
    "taxa_postergacao_ano_pct": 12,
    "metodo_calculo": "composto",
    "base_tempo": "dias_365"
  },
  "parametros": {},
  "resumo": {
    "qtd_alternativas": 0,
    "melhor_tipo_operacao": "antecipacao",
    "maior_economia_liquida": 0,
    "maior_acrescimo": 0,
    "maior_impacto_pct": 0,
    "premio_corretor_pct_mais_restritivo": 0
  },
  "recomendacao": {},
  "alternativas": [],
  "rejeicoes": []
}
```

---

## 18. Campos administrativos permitidos

Permitido no retorno 5A.1:

- política usada;
- taxas administrativas;
- VPL máximo;
- faixas/status de prêmio;
- impacto percentual;
- desconto calculado;
- acréscimo calculado;
- economia líquida;
- dias de cálculo;
- parcela de origem/destino;
- grupo;
- recomendação de melhor aplicação;
- motivo de rejeição administrativa.

Esses campos são proibidos em cliente-safe, mas permitidos aqui porque a visão é administrativa.

---

## 19. Campos proibidos no retorno 5A.1

Mesmo sendo administrativo, a 5A.1 não deve retornar:

- payload bruto completo da agenda;
- metadata bruta sem filtro;
- dados de outro tenant;
- tokens;
- claims brutas;
- service role;
- dados sensíveis de usuário sem necessidade;
- SQL interno;
- stack trace.

---

## 20. Estratégia de recomendação inicial

Para `melhor_aplicacao`, a recomendação inicial deve ordenar alternativas por:

```text
1. maior economia_liquida para antecipação/VPL;
2. menor acréscimo para postergação, quando o objetivo for aliviar curto prazo;
3. maior impacto comercial permitido sem ultrapassar VPL máximo;
4. menor perda de prêmio do corretor, quando houver empate financeiro;
5. prioridade de grupos configurável/fixa nesta fase: financiamento > chaves > anual/intermediarias > mensal.
```

A prioridade acima pode ser refinada em fases futuras, mas nesta fase não deve ficar no frontend.

---

## 21. Relação com 5B e 5C

A 5A.1 não grava operação.

A 5B deverá receber uma alternativa gerada/validada e registrar operação financeira como `simulada` ou `recomendada`.

A 5C deverá confirmar/cancelar com nova validação, auditando o responsável.

Portanto, a 5A.1 deve retornar identificadores suficientes para futura 5B, mas não deve prometer que a operação está confirmada.

---

## 22. Testes obrigatórios da 5A.1

### 22.1. Preflight canônico

Arquivo oficial a executar antes da migration:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_simulacao_impacto_agenda_persistida_readonly.sql
```

Objetivo:

- inventariar RPCs/funções de cálculo existentes;
- inventariar colunas reais de agenda/parcelas/política/faixas;
- validar constraints reais;
- validar grants atuais;
- confirmar nomes reais de status/colunas antes de escrever migration;
- evitar erro de coluna deduzida.

### 22.2. Teste positivo futuro

Arquivo previsto:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
```

Deve validar:

- cria fixture transacional de simulação/agenda/parcelas/política/faixas;
- chama RPC 5A.1;
- retorna `fase = 5A_SIMULACAO_IMPACTO_AGENDA_PERSISTIDA`;
- retorna `cliente_safe = false`;
- retorna `persistencia = false`;
- retorna `dml_financeiro = false`;
- gera alternativas;
- identifica recomendação;
- usa cálculo composto;
- respeita política vigente;
- não altera parcelas;
- não cria operação;
- rollback completo.

### 22.3. Teste negativo futuro

Arquivo previsto:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_simulacao_impacto_agenda_persistida_negativos_rollback.sql
```

Deve validar bloqueios para:

- `anon`;
- sem auth;
- simulação inexistente;
- simulação sem agenda ativa;
- cross-tenant;
- política inexistente;
- política vencida;
- método de cálculo inválido;
- base de tempo inválida;
- valor negativo;
- modo inválido;
- grupo não permitido;
- periodicidade simbólica;
- parcela de outra agenda/simulação;
- payload tentando enviar `empresa_id` fake;
- tentativa de ultrapassar VPL máximo.

### 22.4. Teste zero DML futuro

Arquivo previsto:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10c_validacao_simulacao_impacto_agenda_persistida_zero_dml_rollback.sql
```

Deve validar:

- count_before = count_after em `mesa_cliente_fluxo_operacoes`;
- count_before = count_after em `mesa_cliente_fluxo_parcelas` fora da fixture transacional;
- agenda ativa não é substituída;
- nenhuma operação confirmada é criada;
- nenhuma parcela é alterada.

---

## 23. Critérios de aceite da 5A.1

A Fase 5A.1 só poderá ser aprovada se:

1. este contrato permanecer fechado;
2. preflight 10 canônico confirmar schema real;
3. migration/RPC 5A.1 for criada sem DML de negócio;
4. `anon` estiver bloqueado;
5. `authenticated` executar apenas via RPC;
6. cross-tenant for bloqueado;
7. agenda ativa for obrigatória;
8. política vigente for obrigatória;
9. cálculo composto for usado;
10. periodicidade simbólica for excluída;
11. recomendação for gerada sem frontend soberano;
12. retorno for administrativo e `cliente_safe=false`;
13. retorno declarar `persistencia=false` e `dml_financeiro=false`;
14. zero DML em operações for comprovado;
15. zero alteração de parcelas for comprovada;
16. testes 10A/10B/10C passarem com `BEGIN + ROLLBACK`.

---

## 24. Sequência de execução autorizada após este fechamento

Ordem correta:

```text
1. Executar o preflight 10 canônico read-only.
2. Validar resultset completo do preflight 10.
3. Se o preflight liberar, criar migration da RPC 5A.1.
4. Criar testes 10A/10B/10C.
5. Executar testes com BEGIN + ROLLBACK.
6. Criar documento de fechamento da 5A.1.
7. Só então abrir 5B.
```

---

## 25. Gate de bloqueio

A Fase 5A.1 fica bloqueada para SQL de implementação enquanto não existir resultado validado do preflight 10 canônico.

Não criar:

```text
supabase/migrations/<timestamp>_mesa_cliente_fase_5a_simulacao_impacto_agenda_persistida.sql
```

antes do preflight.

---

## 26. Veredito final do contrato

Contrato da Fase 5A.1 fechado.

Próxima ação técnica segura:

```text
Executar:
supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_simulacao_impacto_agenda_persistida_readonly.sql
```

Não criar SQL de implementação da 5A.1 sem o preflight 10 canônico validado.
