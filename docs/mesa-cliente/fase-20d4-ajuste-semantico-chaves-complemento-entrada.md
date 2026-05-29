# FECH.AI / MesaCliente — Fase 20D.4.1
# Ajuste semântico — Complemento de entrada, parcela única/chaves e quitação real

## 1. Status

```text
Status: AJUSTE SEMÂNTICO VERSIONADO
Data: 2026-05-27
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration atualizada: SIM
Migration executada no Supabase: NÃO
DML executado: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

## 2. Motivação

Durante a revisão operacional do modelo financeiro, foi esclarecido que:

```text
Parcela única/chaves não é quitação do saldo devedor.
```

A parcela única/chaves ainda pertence ao ciclo de obra/composição de entrada e normalmente precede o saldo devedor final, que pode ser liquidado por:

```text
- financiamento bancário;
- repasse;
- quitação real do saldo devedor.
```

Portanto, chamar parcela única/chaves de quitação estava semanticamente incorreto.

## 3. Modelo financeiro correto

Sequência conceitual recomendada:

```text
1. ATO
2. Complemento de entrada: +30 / +60 / +90 / eventualmente +120 ou mais
3. Mensais de obra
4. Intermediárias de obra: anuais ou semestrais
5. Parcela única/chaves de obra
6. Saldo devedor final:
   - financiamento bancário;
   - repasse;
   - quitação real.
```

## 4. Ajustes aplicados na migration 20D.4

Arquivo atualizado:

```text
supabase/migrations/20260527043000_mesa_cliente_20d4_adaptador_agenda_canonica.sql
```

Commit:

```text
b68a67def9df1ac29f83ced3b3fbbb8d29e01055
```

## 5. Complemento de entrada dinâmico

Antes, o adaptador inferia datas apenas para:

```text
+30
+60
+90
```

Agora, o adaptador aceita complemento de entrada dinâmico no padrão:

```text
+N dias
```

Desde que:

```text
N seja múltiplo de 30;
N esteja entre 30 e 360;
o item seja tipo histórico curto_prazo;
data_prevista esteja nula.
```

Exemplos aceitos:

| Descrição | Meses comerciais | Exemplo com ATO em 2026-05-26 |
|---|---:|---|
| +30 dias | 1 | 2026-06-26 |
| +60 dias | 2 | 2026-07-26 |
| +90 dias | 3 | 2026-08-26 |
| +120 dias | 4 | 2026-09-26 |

Regra:

```text
meses_offset = N / 30
data_vencimento = data_ato + meses_offset em meses comerciais
```

Não usar dias corridos.

## 6. Parcela única/chaves x quitação

O enum histórico atual possui `tipo = quitacao`, mas não possui um tipo próprio para `chaves` ou `parcela_unica_obra`.

Por compatibilidade histórica, o adaptador agora só aceita `tipo = quitacao` como `parcela_unica` quando a descrição indicar claramente:

```text
parcela única
unica/única
chaves
entrega
```

Nesse caso, o diagnóstico marca a semântica como:

```text
parcela_unica_obra_compatibilidade_historica_tipo_quitacao
```

Se `tipo = quitacao` indicar saldo devedor, repasse, financiamento ou quitação real, o adaptador bloqueia.

Exemplos bloqueados:

```text
Quitação do saldo
Saldo devedor
Repasse
Financiamento
Quitação final
```

Motivo:

```text
Evitar classificar saldo devedor real como parcela única/chaves de obra.
```

## 7. Diagnóstico atualizado

O diagnóstico deixou de usar o nome:

```text
quitacao_para_parcela_unica
```

E passou a usar:

```text
quitacao_historica_para_parcela_unica_obra
```

Isso deixa explícito que a conversão é uma compatibilidade histórica do dado legado, não uma afirmação conceitual de que parcela única/chaves seja quitação.

## 8. Percentual de obra

A fase não hardcoda percentual de obra.

O percentual pode variar conforme padrão de produto:

```text
baixo padrão: 10% a 20% pode acontecer;
médio mercado: 30% é comum;
alto padrão: 40% a 45% pode acontecer.
```

Portanto, o adaptador não bloqueia por percentual de obra.

Qualquer validação percentual futura deve ser diagnóstica/informativa, não regra rígida universal.

## 9. Semestrais x anuais

A intermediária continua sendo:

```text
tipo histórico = intermediaria
grupo canônico = intermediarias
periodicidade = anual/semestral/outra conforme dado
```

A periodicidade deve ser validada em etapa específica antes de Modo 4/5.

## 10. Backlog obrigatório antes de Modo 4/5

```text
1. Validar geração de datas para intermediárias semestrais.
2. Validar geração de datas para intermediárias anuais.
3. Validar ausência de parcela única/chaves.
4. Validar presença de financiamento/saldo devedor real.
5. Avaliar criação futura de tipo/camada conceitual separada para:
   - chaves;
   - parcela_unica_obra;
   - saldo_devedor;
   - quitacao_real;
   - financiamento.
```

## 11. Decisão

```text
Ajuste semântico aprovado para a 20D.4 antes da execução da migration no Supabase.
```

A migration segue read-only em comportamento funcional da RPC e não executa DML financeiro.
