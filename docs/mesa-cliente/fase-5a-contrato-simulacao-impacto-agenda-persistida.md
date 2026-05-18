# FECH.AI / MesaCliente — Fase 5A — Contrato e Planejamento da Simulação de Impacto com Agenda Persistida

**Status:** contrato inicial aprovado para planejamento — sem SQL nesta etapa  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5A — simular impacto financeiro administrativo usando agenda persistida  
**Data de abertura:** 2026-05-18

---

## 1. Contexto de entrada

A Fase 5A só pode começar porque as fases anteriores criaram uma base segura:

```text
4A = gera agenda financeira em JSON, sem persistência
4B = persiste agenda financeira com lock, checksum, idempotência e auditoria
4C = lê agenda persistida em visão cliente-safe, sem vazamento de dados internos
5A = simula impacto financeiro administrativo sobre a agenda persistida, sem gravar operação
```

A 5A não substitui a 4C e não usa payload cliente-safe como fonte soberana.

A fonte soberana da 5A é a agenda persistida no banco:

```text
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_politicas_financeiras
mesa_cliente_politica_premio_faixas
```

---

## 2. Decisão oficial da Fase 5A

A Fase 5A deve criar uma camada administrativa de simulação de impacto financeiro baseada na agenda persistida pela 4B.

Ela deve permitir simular, sem confirmar e sem gravar operação financeira definitiva:

- antecipação;
- postergação;
- VPL administrativo por parcela/camada;
- impacto financeiro agregado;
- melhor aplicação financeira sugerida;
- impacto de prêmio/faixa administrativa quando aplicável.

A Fase 5A deve ser uma simulação administrativa.

Portanto:

```text
5A calcula e recomenda.
5B registra operação simulada/aprovada.
5C confirma ou cancela operação.
```

---

## 3. Objetivo

Criar uma RPC administrativa que leia a agenda ativa persistida, aplique a política financeira vigente e retorne alternativas de impacto financeiro para tomada de decisão interna.

A 5A deve responder perguntas como:

```text
Se o cliente antecipar R$ X, em qual camada/parcela isso gera maior benefício?
Se o cliente quiser postergar R$ Y, qual será o acréscimo financeiro?
Se aplicar VPL de Z%, quais parcelas/camadas são elegíveis e qual impacto administrativo?
Qual opção deve ser recomendada ao corretor/coordenador?
```

---

## 4. Fora de escopo

A Fase 5A não deve:

- alterar frontend;
- alterar parser;
- alterar Worker;
- alterar Make/n8n;
- alterar agenda persistida;
- inserir operação financeira definitiva;
- confirmar operação financeira;
- cancelar operação financeira;
- alterar parcelas persistidas;
- gerar payload cliente-safe final;
- usar payload cliente-safe da 4C como base soberana;
- permitir cálculo financeiro no frontend;
- expor dados administrativos para cliente;
- usar taxa, VPL ou faixa vindos do frontend como autoridade final;
- aceitar `empresa_id` do frontend como fonte soberana.

---

## 5. RPC candidata

Nome proposto:

```sql
public.mesa_cliente_simular_impacto_agenda_persistida_admin(
  p_simulacao_id uuid,
  p_data_referencia date default current_date,
  p_modo text default 'melhor_aplicacao',
  p_parametros jsonb default '{}'::jsonb
)
returns jsonb
```

### 5.1. Justificativa do nome

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

Essa RPC é útil, mas recebe operações já montadas por payload. A 5A deve dar um passo acima:

```text
ler agenda persistida -> montar cenários elegíveis -> chamar/reutilizar cálculo composto -> recomendar alternativas
```

Ou seja, a 5A deve ser agenda-first, não payload-first.

---

## 6. Modos permitidos

O parâmetro `p_modo` deve aceitar inicialmente:

```text
melhor_aplicacao
antecipacao
postergacao
vpl
comparativo
```

### 6.1. `melhor_aplicacao`

Usado quando o corretor informa um valor disponível para melhorar a condição.

Exemplo:

```json
{
  "valor_disponivel": 50000,
  "data_base": "2026-05-18",
  "grupos_preferenciais": ["financiamento", "chaves", "anuais", "mensais"]
}
```

A RPC deve simular onde aplicar o valor para maximizar benefício administrativo/comercial dentro da política.

### 6.2. `antecipacao`

Simula antecipação de parcelas futuras para uma data anterior.

Exemplo:

```json
{
  "valor_disponivel": 30000,
  "data_nova": "2026-05-18",
  "grupos_destino": ["financiamento", "chaves", "anuais"]
}
```

### 6.3. `postergacao`

Simula deslocamento de valor de uma parcela anterior para data futura.

Exemplo:

```json
{
  "valor_movido": 20000,
  "data_destino": "2028-09-30",
  "grupos_origem": ["mensal", "anual", "chaves"]
}
```

### 6.4. `vpl`

Simula impacto administrativo de VPL aplicado sobre parcelas elegíveis.

Exemplo:

```json
{
  "vpl_aplicado_pct": 3.5,
  "grupos_destino": ["financiamento", "chaves", "anual"]
}
```

### 6.5. `comparativo`

Retorna comparação entre alternativas, sem sugerir apenas uma.

---

## 7. Fonte de dados autorizada

A RPC 5A deve ler:

- `mesa_simulacoes`;
- `corretores`;
- `empresas`;
- `empreendimentos`;
- `mesa_cliente_agendas_financeiras`;
- `mesa_cliente_fluxo_parcelas`;
- `mesa_cliente_politicas_financeiras`;
- `mesa_cliente_politica_premio_faixas`;
- opcionalmente `mesa_cliente_fluxo_operacoes` apenas para verificar bloqueios/status já confirmados.

A RPC 5A não deve depender de dados soberanos enviados pelo frontend.

---

## 8. DML permitido e proibido

### 8.1. DML permitido

Na Fase 5A:

```text
Nenhum DML de negócio é permitido.
```

A 5A deve ser read-only do ponto de vista financeiro.

### 8.2. DML proibido

Proibido:

- `INSERT` em `mesa_cliente_fluxo_operacoes`;
- `UPDATE` em `mesa_cliente_fluxo_operacoes`;
- `DELETE` em `mesa_cliente_fluxo_operacoes`;
- `INSERT` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` em `mesa_cliente_fluxo_parcelas`;
- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `INSERT/UPDATE/DELETE` em `mesa_cliente_agendas_financeiras`;
- qualquer escrita em tabelas comerciais, usuários, empresas, empreendimentos, parser ou frontend.

Fixtures transacionais em testes rollback são permitidas apenas dentro de `BEGIN + ROLLBACK`.

---

## 9. Segurança obrigatória

A RPC 5A deve seguir:

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

## 10. Perfis autorizados

A 5A retorna payload administrativo, portanto deve ser mais restrita que 4C cliente-safe.

Perfis sugeridos:

```text
admin_global
admin_local
gestor
coordenador
corretor dono da simulação
```

Corretor que não é dono da simulação só deve acessar se for gestor/coordenador/admin da mesma empresa.

---

## 11. Política financeira

A RPC deve buscar política vigente pelo banco:

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

## 12. Parcelas elegíveis

A RPC deve considerar apenas parcelas da agenda ativa.

Parcelas com `eh_periodicidade_simbolica = true` devem ser excluídas de qualquer cálculo.

Elegibilidade por tipo:

### 12.1. Antecipação

Usar parcelas com:

```text
pode_receber_antecipacao = true
valor_atual > 0
data_atual > data_nova/data_base
não periodicidade simbólica
```

### 12.2. Postergação

Usar parcelas com:

```text
pode_receber_postergacao = true
valor_atual > 0
data_destino > data_atual
não periodicidade simbólica
```

### 12.3. VPL

Usar parcelas com:

```text
pode_receber_vpl = true
valor_atual > 0
não periodicidade simbólica
grupo permitido pela política
```

---

## 13. Reutilização obrigatória do motor de cálculo já criado

A 5A deve reutilizar as funções puras existentes:

```sql
public.mesa_cliente_financeiro_calcular_antecipacao_composta(...)
public.mesa_cliente_financeiro_calcular_postergacao_composta(...)
public.mesa_cliente_financeiro_calcular_vpl_parcela(...)
```

E pode reutilizar a RPC administrativa existente quando fizer sentido:

```sql
public.mesa_cliente_simular_impacto_financeiro_admin(...)
```

Mas a 5A não deve delegar soberania ao frontend para montar toda a lista de operações.

A lista de alternativas deve nascer da agenda persistida.

---

## 14. Retorno esperado da RPC 5A

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

## 15. Campos administrativos permitidos

Permitido no retorno 5A:

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

Esses campos são proibidos em cliente-safe, mas são permitidos aqui porque a visão é administrativa.

---

## 16. Campos proibidos no retorno 5A

Mesmo sendo administrativo, a 5A não deve retornar:

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

## 17. Estratégia de recomendação inicial

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

## 18. Relação com 5B e 5C

A 5A não grava operação.

A 5B deverá receber uma alternativa gerada/validada e registrar operação financeira como `simulada` ou `recomendada`.

A 5C deverá confirmar/cancelar com nova validação, auditando o responsável.

Portanto, a 5A deve retornar identificadores suficientes para futura 5B, mas não deve prometer que a operação está confirmada.

---

## 19. Testes obrigatórios da 5A

### 19.1. Preflight

Arquivo proposto:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_simulacao_impacto_agenda_persistida_readonly.sql
```

Objetivo:

- inventariar RPCs/funções de cálculo existentes;
- inventariar colunas reais de agenda/parcelas/política/faixas;
- validar constraints reais;
- validar grants atuais;
- confirmar nome real de status/colunas antes de escrever migration;
- evitar erro de coluna deduzida.

### 19.2. Teste positivo

Arquivo proposto:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_simulacao_impacto_agenda_persistida_rollback.sql
```

Deve validar:

- cria fixture transacional de simulação/agenda/parcelas/política/faixas;
- chama RPC 5A;
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

### 19.3. Teste negativo

Arquivo proposto:

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

### 19.4. Teste de zero DML

Arquivo proposto:

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

## 20. Critérios de aceite

A Fase 5A só pode ser aprovada se:

1. contrato estiver documentado;
2. preflight 10 confirmar schema real;
3. migration/RPC 5A for criada sem DML de negócio;
4. `anon` estiver bloqueado;
5. `authenticated` autorizado executar apenas via RPC;
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

## 21. Sequência de execução autorizada

Ordem correta:

```text
1. Revisar este contrato.
2. Executar/criar preflight 10 read-only.
3. Validar resultset do preflight.
4. Criar migration da RPC 5A somente após preflight.
5. Criar testes 10A/10B/10C.
6. Executar testes com BEGIN + ROLLBACK.
7. Criar documento de fechamento da 5A.
8. Só então abrir 5B.
```

---

## 22. Frase de controle

```text
4C mostra com segurança. 5A simula impacto administrativo com agenda persistida. 5B registra. 5C confirma ou cancela.
```

---

## 23. Veredito inicial

A Fase 5A está autorizada apenas em nível de contrato e planejamento.

Próxima ação técnica segura:

```text
Criar/executar o preflight 10 read-only antes de qualquer migration 5A.
```

Não criar SQL de implementação da 5A sem o preflight 10.
