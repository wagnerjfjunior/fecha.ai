# FECH.AI / MesaCliente — Fase 20D.4.4
# Contrato canônico do fluxo financeiro

## 1. Status

```text
Status: CONTRATO TÉCNICO PROPOSTO / SEM DDL
Data: 2026-05-28
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration criada: NÃO
Migration executada no Supabase: NÃO
DML executado: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

## 2. Motivo da correção de rota

A RPC 20D.4.3 foi aplicada e validada estruturalmente, mas a análise do fluxo real do Chateau 501 revelou problemas de contrato canônico que não devem ser tratados por remendo no adaptador.

Problemas observados:

```text
1. Parcela única/chaves está persistida como tipo histórico quitacao.
2. Parcela única/chaves NÃO é quitação do saldo devedor.
3. O fluxo histórico não trouxe linha própria de financiamento, embora mesa_simulacoes.financiamento exista.
4. Valor total e valor final estão em mesa_simulacoes, mas não aparecem de forma explícita no payload financeiro consolidado.
5. Parcela Final(is)/Periodicidade não deve ser observação genérica; ela tem identidade operacional própria.
```

Decisão:

```text
Não avançar com integração final em cima de compatibilidade semântica frágil.
Corrigir o contrato canônico antes de Modo 4/5 e antes de operações financeiras avançadas.
```

## 3. Princípios não negociáveis

```text
1. Tabela importada é fonte soberana.
2. data_prevista importada prevalece sobre regra derivada.
3. Tipo de parcela não pode ser inferido por quantidade.
4. Quantidade define repetição, nunca natureza financeira.
5. Parcela única/chaves não é quitação.
6. Financiamento/saldo devedor não é parcela única/chaves.
7. Periodicidade/Final(is) não é observação genérica.
8. O adaptador não deve inventar item financeiro ausente.
9. Se o fluxo estiver incompleto frente ao resumo da simulação/tabela importada, a RPC deve diagnosticar ou bloquear, não maquiar.
10. Nenhuma camada futura de VPL, juros, amortização ou antecipação deve nascer sobre classificação errada.
```

## 4. Matriz canônica proposta

| Grupo canônico | Natureza | Entra no fluxo financeiro? | Pode repetir? | Fonte prioritária | Observações |
|---|---|---:|---:|---|---|
| `entrada_ato` | Entrada/obra | Sim | Normalmente 1 | Tabela importada | Âncora comercial do calendário |
| `entrada_complemento` | Complemento de entrada/obra | Sim | Sim | Tabela importada | +30/+60/+90/+120 etc. como fallback, não fonte primária |
| `mensal_obra` | Mensais de obra | Sim | Sim | Tabela importada | Começa após complemento, mas data oficial prevalece |
| `intermediaria_obra` | Intermediária anual/semestral | Sim | Sim | Tabela importada | Pode coincidir com mensal |
| `parcela_unica_obra` | Parcela única/chaves de obra | Sim | Normalmente 1 | Tabela importada | Precede saldo devedor; não é quitação |
| `financiamento_saldo` | Saldo devedor/financiamento/repasse | Sim | Normalmente 1 ou conforme tabela | Tabela importada/resumo oficial | Não misturar com parcela única |
| `quitacao_real` | Liquidação do saldo devedor | Sim, quando existir | Conforme tabela | Tabela importada | Alternativa ao financiamento, não sinônimo de parcela única |
| `periodicidade_obra` | Controle técnico/simbólico de prazo | Depende da decisão de produto | Pode existir | Tabela importada | Final(is)/Periodicidade, geralmente simbólica; não é observação genérica |
| `observacao_operacional` | Informação auxiliar | Não | Sim | Tabela/importação | Observações sem natureza de obrigação financeira |

## 5. Valor total, valor final e financiamento

A RPC/payload consolidado deve explicitar os totais principais vindos de `mesa_simulacoes`:

```text
valor_total
valor_final
entrada_total
financiamento_total
```

Esses campos não substituem o fluxo itemizado.

Eles servem para:

```text
1. validação de consistência;
2. conferência comercial;
3. diagnóstico de fluxo incompleto;
4. base futura de operações financeiras.
```

## 6. Regra para financiamento ausente no fluxo

Caso `mesa_simulacoes.financiamento > 0` e não exista item financeiro canônico de financiamento/saldo no fluxo:

```text
A RPC não deve inventar a linha.
A RPC deve retornar diagnóstico explícito ou bloquear em modo estrito.
```

Mensagem conceitual:

```text
Fluxo financeiro incompleto: financiamento_total existe no resumo da simulação, mas não há item de financiamento/saldo no fluxo de pagamentos.
```

Motivo:

```text
Evitar agenda canônica sem saldo devedor.
```

## 7. Regra para parcela única/chaves persistida como quitacao

O comportamento da 20D.4.3 fazia compatibilidade:

```text
tipo histórico quitacao + descrição Parcela única => parcela_unica
```

A 20D.4.4 propõe modo estrito:

```text
Não aceitar semanticamente como PASS final.
Registrar como dado legado/incompatível.
Bloquear ou diagnosticar até que o pipeline grave tipo canônico correto.
```

Mensagem conceitual:

```text
Parcela única/chaves não pode estar persistida como quitacao. Corrigir origem ou mapear para tipo canônico próprio antes da agenda final.
```

## 8. Regra para periodicidade / Final(is)

A parcela `Final(is)` ou `Periodicidade`, geralmente simbólica, não deve ser tratada como observação genérica.

Classificação proposta:

```text
periodicidade_obra
```

Com metadados:

```text
valor_simbolico: true/false
natureza: controle_periodo_obra
entra_agenda_cliente: decisão posterior
entra_motor_financeiro: decisão posterior
```

Decisão pendente:

```text
Definir se periodicidade_obra deve aparecer na agenda do cliente como obrigação simbólica ou apenas como controle interno/diagnóstico.
```

Até essa decisão, não esconder como observação genérica.

## 9. Datas oficiais

Fonte prioritária:

```text
data_prevista importada da tabela
```

Fallbacks permitidos apenas quando a tabela/importação não trouxe data explícita:

```text
+N dias para complemento de entrada
primeira mensal após último complemento
periodicidade anual/semestral quando explicitamente classificada
```

Todo fallback deve aparecer no diagnóstico.

## 10. Quantidade não classifica tipo

Proibido:

```text
1 parcela => parcela única
3 parcelas => complemento
6 parcelas => semestral
36 parcelas => mensal
```

Correto:

```text
tipo/grupo vem da tabela importada ou classificação explícita do pipeline.
quantidade apenas define quantas ocorrências devem ser expandidas.
```

## 11. Efeito sobre a 20D.4.3 aplicada

A 20D.4.3 foi aplicada com sucesso no Supabase, mas deve ser considerada:

```text
Aplicada: SIM
Estruturalmente validada: SIM
Aprovada como contrato financeiro final: NÃO
PASS funcional final: NÃO
```

Motivo:

```text
Ainda aceita compatibilidade quitacao -> parcela_unica e ainda não trata financiamento ausente/periodicidade própria como contrato canônico final.
```

## 12. Próxima entrega recomendada

Criar uma migration 20D.4.4 de substituição da RPC com modo estrito/diagnóstico:

```text
public.mesa_cliente_montar_payload_agenda_canonica(p_simulacao_id uuid)
```

Alterações esperadas:

```text
1. Retornar bloco totais_simulacao com valor_total, valor_final, entrada_total e financiamento_total.
2. Retornar diagnostico.consistencia_fluxo.
3. Detectar financiamento_total > 0 sem item financiamento no fluxo.
4. Detectar tipo quitacao usado para parcela única/chaves.
5. Tratar periodicidade/final como tipo conceitual próprio quando houver dado suficiente.
6. Não declarar ok=true se houver inconsistência crítica em modo estrito.
```

## 13. Pontos pendentes antes da migration 20D.4.4

```text
1. Confirmar se vamos corrigir a origem da persistência em mesa_fluxo_pagamentos ou apenas endurecer a RPC.
2. Confirmar se será necessário evoluir o enum mesa_fluxo_tipo.
3. Confirmar como a periodicidade_obra deve aparecer para o cliente.
4. Confirmar se financiamento deve ser persistido como linha obrigatória do fluxo sempre que financiamento_total > 0.
5. Confirmar se parcela_unica_obra/chaves terá tipo próprio ou grupo canônico derivado de metadado.
```

## 14. Decisão atual

```text
Segurar novos testes funcionais da 20D.4.3.
Formalizar contrato canônico 20D.4.4.
Só depois criar migration corretiva.
```
