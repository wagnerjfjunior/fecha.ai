# FECH.AI / MesaCliente — Fase 20D.4.3
# Fonte soberana: tabela importada, não inferência

## 1. Status

```text
Status: REGRA ARQUITETURAL DOCUMENTADA E VERSIONADA NA MIGRATION
Data: 2026-05-27
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration atualizada: SIM
Migration executada no Supabase: NÃO
DML executado: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

## 2. Regra central

A tabela de valores importada é a fonte soberana do fluxo financeiro.

No escopo atual da 20D.4, `public.mesa_fluxo_pagamentos` representa o histórico financeiro já derivado/importado da tabela.

Portanto:

```text
data_prevista preenchida = data oficial importada
```

E deve prevalecer sobre qualquer regra derivada.

## 3. O que não pode acontecer

O sistema não pode:

```text
1. Fixar número de parcelas por tipo.
2. Identificar tipo de parcela pela quantidade.
3. Assumir que 3 parcelas sempre significa complemento.
4. Assumir que 6 parcelas sempre significa semestral.
5. Assumir que 1 parcela sempre significa única, chaves ou financiamento.
6. Deduzir natureza financeira apenas pelo valor.
7. Reescrever datas oficiais da tabela importada.
```

Quantidade informa repetição/expansão, não natureza financeira.

A natureza financeira deve vir do cabeçalho/estrutura importada/tipo histórico já classificado.

## 4. Hierarquia de fontes

Para datas:

```text
1. data_prevista da tabela/importação/histórico financeiro;
2. fallback controlado por data_ato e descrição +N dias;
3. fallback fraco por created_at somente para data_ato, com warning;
4. bloqueio se não houver fonte segura.
```

Para tipo/natureza financeira:

```text
1. tipo importado/classificado pelo pipeline;
2. descrição apenas para compatibilidade histórica ou bloqueio de ambiguidade;
3. nunca quantidade.
```

## 5. Uso da lógica comercial

A lógica comercial continua importante, mas com função correta:

```text
- fallback controlado;
- validação;
- diagnóstico;
- detecção de inconsistência.
```

Não é fonte primária quando a tabela já trouxe a informação.

Exemplo:

```text
A tabela trouxe mensal com data_prevista 2026-09-15.
O adaptador usa 2026-09-15.
Não recalcula a mensal por regra própria.
```

## 6. Complemento de entrada

Complementos continuam sendo entrada/obra.

Se `data_prevista` existe:

```text
usar data_prevista_tabela_importada
```

Se `data_prevista` está nula e a descrição possui `+N dias`:

```text
usar fallback_compatibilidade_historica_mes_comercial_+N
```

Condições do fallback:

```text
N múltiplo de 30;
N entre 30 e 360;
sem data oficial preenchida.
```

## 7. Mensais

Se mensal possui `data_prevista`:

```text
usar data_prevista_tabela_importada
```

A data é validada para estar após o último complemento de entrada.

Se mensal não possui `data_prevista`:

```text
usar fallback_primeira_mensal_apos_ultimo_complemento_entrada
```

Esse fallback é diagnosticado e não deve ser confundido com dado oficial.

## 8. Intermediárias anuais/semestrais

Intermediárias podem coincidir com mensais na mesma data.

Isso não é duplicidade.

Exemplo:

```text
Mensal: 26/05/2027
Anual:  26/05/2027
```

O cliente paga duas obrigações:

```text
1. mensal;
2. intermediária.
```

Não deduplicar por data.

## 9. Parcela única/chaves e financiamento

Parcela única/chaves pertence ao ciclo de obra.

Financiamento/repasse/quitação real pertence ao saldo devedor final.

Não misturar.

Compatibilidade histórica:

```text
tipo histórico quitacao + descrição parcela única/chaves/entrega => parcela_unica de obra
```

Bloqueio:

```text
tipo histórico quitacao + descrição saldo/repasse/financiamento/quitação real => erro controlado
```

## 10. Final(is) / Periodicidade simbólica

Alguns empreendimentos usam uma parcela `Final(is)` ou `Periodicidade`, geralmente simbólica, por exemplo R$ 1.000, para contabilizar tempo de obra.

Na 20D.4.3, esse tipo deve ser tratado como observação não financeira/operacional quando chegar como:

```text
tipo = observacao
```

Comportamento:

```text
não entra no fluxo_json;
não alimenta 4A/4B;
não gera parcela financeira;
é registrado em diagnostico.itens_observacao.
```

## 11. Diagnóstico obrigatório

A RPC passa a expor:

```text
qtd_itens_origem_total
qtd_itens_financeiros_adaptados
qtd_itens_observacao_ignorados
datas_fallback
itens_observacao
```

E declara explicitamente:

```text
tipo_de_parcela_nao_e_derivado_por_quantidade
quantidade_define_repeticao_nao_natureza_financeira
```

## 12. Migration atualizada

Arquivo:

```text
supabase/migrations/20260527043000_mesa_cliente_20d4_adaptador_agenda_canonica.sql
```

Commit:

```text
29586a657247c03323862796a5eb87c46e8e051e
```

Versão lógica:

```text
20D.4.3
```

## 13. Critérios mínimos de teste

Antes de PASS:

```text
1. Chateau 501 deve retornar ok=true.
2. data_prevista preenchida deve aparecer como data_prevista_tabela_importada.
3. +30/+60/+90 nulos devem aparecer em datas_fallback, se não houver data oficial gravada.
4. Observação deve ser ignorada no fluxo_json e aparecer em itens_observacao.
5. Quantidade não pode ser usada para determinar tipo.
6. Intermediária com mesma data da mensal não pode ser bloqueada.
7. Nenhum INSERT/UPDATE/DELETE financeiro pode ocorrer.
```

## 14. Decisão

```text
Prosseguir com 20D.4.3 somente após atualização local no Codespace e validação SQL.
```
