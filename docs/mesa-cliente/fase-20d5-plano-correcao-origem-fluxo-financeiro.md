# FECH.AI / MesaCliente — Fase 20D.5
# Plano de correção da origem do fluxo financeiro

## 1. Status

```text
Status: PLANO TÉCNICO / SEM DDL
Data: 2026-05-28
Branch: feature/mesa-cliente-20d-adaptador-agenda-canonica
Migration criada: NÃO
Migration executada no Supabase: NÃO
DML executado: NÃO
Frontend alterado: NÃO
Parser/Worker/Make alterado: NÃO
Motor financeiro alterado: NÃO
```

## 2. Decisão técnica

A correção deve ser feita na origem da persistência, não na RPC adaptadora.

Motivo:

```text
A RPC adaptadora não deve maquiar dado financeiro semanticamente errado.
```

A função `public.criar_mesa_simulacao` é hoje o ponto que grava:

```text
public.mesa_simulacoes
public.mesa_fluxo_pagamentos
```

Portanto ela deve receber/validar/persistir grupos financeiros com semântica correta.

## 3. Problemas confirmados

### 3.1 Parcela única/chaves persistida como quitação

Hoje o grupo curto `u`, usado no frontend como CHAVES/Parcela única, é persistido como:

```text
tipo = quitacao
```

Isso está conceitualmente errado.

Regra correta:

```text
Parcela única/chaves pertence ao ciclo de obra.
Não é quitação do saldo devedor.
Não é financiamento.
```

### 3.2 Financiamento calculado, mas não itemizado no fluxo

O frontend exibe financiamento como saldo calculado:

```text
financiamento = preço total - pagamento antes do financiamento
```

Mas o `serializarFluxo` envia apenas os grupos:

```text
e, c, m, a, u
```

Logo, a linha de financiamento não nasce como item em `mesa_fluxo_pagamentos`.

Resultado:

```text
mesa_simulacoes.financiamento existe;
mesa_fluxo_pagamentos não possui linha própria de financiamento em alguns fluxos.
```

Isso não é aceitável para agenda canônica completa.

### 3.3 Periodicidade/Final(is) é exibida, mas não persistida como item canônico

O frontend já reconhece dados de periodicidade/final simbólica no payload/observações da unidade e exibe como condição informativa.

Porém ela não entra no `serializarFluxo` como item com identidade própria.

Regra correta:

```text
Periodicidade/Final(is) não deve ser observação genérica.
Deve ter identidade canônica própria: periodicidade_obra.
```

## 4. Direção canônica proposta

### 4.1 Grupos de entrada no payload

Manter compatibilidade com grupos curtos, mas evoluir para semântica explícita.

Grupos atuais:

```text
e = entrada/ato
c = complemento de entrada
m = mensal obra
a = intermediária obra
u = parcela única/chaves
```

Grupos novos recomendados:

```text
f = financiamento/saldo devedor
p = periodicidade/final simbólica de obra
```

### 4.2 Tipos canônicos no banco

Opções técnicas a decidir:

#### Opção A — Evoluir enum `mesa_fluxo_tipo`

Adicionar valores:

```text
parcela_unica_obra
periodicidade_obra
```

E usar o valor já existente:

```text
financiamento
```

Vantagem:

```text
Semântica forte no banco.
Menos ambiguidade futura.
```

Cuidado:

```text
ALTER TYPE ADD VALUE é DDL sensível e deve ser aplicado com preflight.
```

#### Opção B — Não evoluir enum agora; adicionar coluna canônica

Adicionar colunas em `mesa_fluxo_pagamentos`:

```text
grupo_canonico text
natureza_financeira text
metadata jsonb
```

Vantagem:

```text
Menos risco com enum.
Mais flexível para layouts novos de tabela.
```

Cuidado:

```text
Cria dupla fonte se não houver regra rígida.
```

#### Opção C — Payload/snapshot canônico em paralelo

Manter `mesa_fluxo_pagamentos` legado e criar tabela/snapshot canônico novo.

Exemplo:

```text
mesa_fluxo_pagamentos_canonico
```

Vantagem:

```text
Não quebra legado.
Permite transição controlada.
```

Cuidado:

```text
Mais uma tabela para governar.
```

## 5. Recomendação inicial

Recomendação mais segura para multi-tenant/DevSecOps:

```text
Opção C primeiro, com modo shadow/canônico paralelo.
```

Motivo:

```text
Não altera diretamente o legado em produção.
Permite comparar fluxo legado x fluxo canônico.
Permite testes reais com Chateau/Garden/Sereno/Bosque/ELO/Capitolo.
Permite evoluir depois para escrita definitiva.
```

## 6. Comportamento esperado da nova origem

Ao criar nova simulação:

```text
1. Gravar mesa_simulacoes com valor_total, entrada_total, financiamento_total e valor_final.
2. Gravar fluxo financeiro canônico com grupos explícitos.
3. Gravar parcela única/chaves como parcela_unica_obra, nunca como quitacao.
4. Gravar financiamento/saldo como item próprio quando financiamento_total > 0.
5. Gravar periodicidade/final como periodicidade_obra ou metadado canônico próprio.
6. Preservar data_prevista importada da tabela sempre que existir.
7. Marcar fallback de data apenas quando a data oficial não existir.
```

## 7. Critérios de bloqueio

A nova origem deve bloquear:

```text
1. grupo u sendo persistido como quitacao;
2. financiamento_total > 0 sem item canônico de financiamento;
3. periodicidade/final simbólica escondida como observação genérica;
4. tipo derivado por quantidade;
5. tentativa de criar fluxo sem empresa_id/empreendimento_id válidos;
6. item financeiro sem valor quando deveria haver valor;
7. item financeiro sem fonte/sem data quando não houver fallback seguro.
```

## 8. Testes reais obrigatórios

Antes de PASS:

```text
1. Chateau 501 com ATO ajustado.
2. Garden Design com datas oficiais no cabeçalho.
3. Sereno com fluxo completo padrão.
4. Bosque VN com complemento 30/60/90/120.
5. ELO Duo pronto com fluxo simplificado entrada + financiamento.
6. Capitolo com Final(is)/Periodicidade simbólica.
```

## 9. Não fazer ainda

```text
Não aplicar migration estrutural sem aprovação.
Não alterar parser/Worker/Make.
Não alterar motor financeiro.
Não reprocessar propostas antigas.
Não declarar PASS sem output real.
```

## 10. Próxima decisão

Antes da migration 20D.5, decidir entre:

```text
A. Evoluir enum existente.
B. Adicionar colunas canônicas em mesa_fluxo_pagamentos.
C. Criar tabela canônica paralela em modo shadow.
```

Recomendação atual:

```text
C — tabela canônica paralela / shadow mode.
```
