# FECH.AI / MesaCliente — Fase 20D.4.2
# Regra financeira — Mensais após complemento de entrada e coexistência de intermediárias

## 1. Status

```text
Status: REGRA FINANCEIRA DOCUMENTADA E VERSIONADA NA MIGRATION
Data: 2026-05-27
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration atualizada: SIM
Migration executada no Supabase: NÃO
DML executado: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

## 2. Regra de negócio confirmada

A parcela mensal inicia **depois** do complemento de entrada.

Exemplos:

```text
ATO +30/+60/+90       -> primeira mensal em +120
ATO +30/+60/+90/+120  -> primeira mensal em +150
```

Ou seja:

```text
primeira_mensal = mês comercial seguinte ao último complemento de entrada
```

## 3. Regra aplicada no adaptador

A migration 20D.4 foi atualizada para calcular:

```text
ultimo_complemento_entrada
```

A partir de:

```text
- data_ato;
- itens tipo histórico curto_prazo;
- data_prevista quando existir;
- ou descrição +N dias quando data_prevista estiver nula.
```

Quando um item `periodica`/mensais vier sem `data_prevista`, o adaptador infere:

```text
data_vencimento = ultimo_complemento_entrada + 1 mês comercial
```

A regra é registrada no diagnóstico como:

```text
primeira_mensal_apos_ultimo_complemento_entrada
```

## 4. Mensal com data oficial preenchida

Se a mensal já vier com `data_prevista`, o adaptador respeita a data oficial.

Mas a data precisa ser posterior ao último complemento de entrada.

Bloqueio aplicado:

```text
mensal <= ultimo_complemento_entrada => erro controlado
```

Motivo:

```text
Mensais não devem começar antes ou no mesmo vencimento do último complemento de entrada.
```

## 5. Intermediárias anuais ou semestrais

As intermediárias podem coincidir com a mensal do mesmo mês/data.

Exemplo:

```text
Mensal: 26/05/2027
Anual:  26/05/2027
```

Nesse caso, o cliente paga duas parcelas no mesmo mês/data:

```text
1. parcela mensal;
2. parcela intermediária anual/semestral.
```

Isso é comportamento correto e **não deve gerar deduplicação**.

## 6. Regra de coexistência

O sistema não deve remover, agrupar ou compensar parcelas só porque possuem a mesma data.

Itens diferentes com mesma data podem coexistir quando representam obrigações diferentes:

```text
mensal + anual
mensal + semestral
mensal + chaves/parcela única
```

Qualquer consolidação futura deve ser apenas visual/relatorial, nunca apagando a obrigação original.

## 7. Diagnóstico atualizado

A RPC agora retorna:

```text
ultimo_complemento_entrada
```

E em `diagnostico.mapeamentos_aplicados`:

```text
primeira_mensal_inferida_pos_complemento
```

Também retorna em `diagnostico.observacoes_modelo`:

```text
mensais_iniciam_apos_ultimo_complemento_entrada
intermediarias_anuais_ou_semestrais_podem_coincidir_com_mensal_do_mes_sem_deduplicacao
```

## 8. Versionamento

Arquivo atualizado:

```text
supabase/migrations/20260527043000_mesa_cliente_20d4_adaptador_agenda_canonica.sql
```

Commit:

```text
cd53232cfaf2c98b6dd4728c6b106c426e6a5fb8
```

Versão lógica do adaptador:

```text
20D.4.2
```

## 9. Critérios de teste obrigatórios

Antes de considerar PASS:

```text
1. Caso Chateau 501 deve continuar retornando ok=true.
2. Mensais com data_prevista 2026-09-15 devem ser respeitadas.
3. Último complemento deve ser +90 em 2026-08-26 no Chateau 501.
4. Mensais devem estar após 2026-08-26.
5. Caso sintético +120 deve inferir primeira mensal em +150.
6. Intermediária com mesma data de mensal não deve ser bloqueada nem deduplicada.
```

## 10. Decisão

```text
Regra incorporada à 20D.4 antes de aplicar a migration no Supabase.
```

A mudança continua read-only no comportamento da RPC e não altera motor financeiro, parser, Worker/Make/n8n ou frontend.
