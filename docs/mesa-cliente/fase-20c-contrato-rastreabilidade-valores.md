# FECH.AI / MesaCliente — Fase 20C
# Contrato candidato — Rastreabilidade de Valores do Fluxo Histórico e 2ª Via

## 1. Status operacional

```text
Status: PROPOSTA CANDIDATA / PENDÊNCIA MAPEADA
Branch: feature/mesa-cliente-20c-rastreabilidade-valores
Base: main após PR #25
Liberação para migration: NÃO
Liberação para RPC: NÃO
Liberação para frontend: NÃO
Liberação para DDL/DML: NÃO
Risco previsto se implementado: R3/R4
```

Este documento **não autoriza implementação**.

A decisão operacional vigente está registrada em:

```text
docs/mesa-cliente/fase-20c0-overview-documental-e-reclassificacao-rastreabilidade.md
```

Regra de controle:

```text
A rastreabilidade foi identificada como pendência real, mas não está liberada automaticamente para migration, RPC ou frontend.
```

## 2. Motivo da reclassificação

Durante a validação da 2ª via read-only foi identificado que o histórico atual mostra o fluxo final salvo em `public.mesa_fluxo_pagamentos`, mas não mostra, por linha, a comparação entre:

```text
valor original carregado da tabela/parser
valor final salvo após edição do usuário
```

Exemplo do problema:

```text
Ato
Valor original: R$ 226.984
Valor ajustado: R$ 408.000
Diferença: +R$ 181.016
Variação: +79,75%
```

A pendência é válida, mas a documentação de engenharia financeira mostra que existe uma trilha canônica baseada em:

```text
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_fluxo_operacoes
```

Portanto, implementar uma camada lateral em `mesa_fluxo_pagamentos` sem reconciliação prévia pode duplicar conceitos que pertencem à engenharia financeira canônica.

## 3. Escopo conceitual da pendência

A rastreabilidade pode existir em dois mundos diferentes:

### Mundo A — histórico/2ª via atual

```text
Finalidade: explicar a proposta salva e o delta entre original e final.
Base atual: mesa_simulacoes + mesa_fluxo_pagamentos + RPC de histórico/2ª via.
Natureza: rastreabilidade comercial/histórica.
```

### Mundo B — engenharia financeira canônica

```text
Finalidade: sustentar agenda, parcelas, operações, aplicação e resumo financeiro.
Base canônica: mesa_cliente_agendas_financeiras + mesa_cliente_fluxo_parcelas + mesa_cliente_fluxo_operacoes.
Natureza: engenharia financeira oficial.
```

A próxima decisão técnica precisa escolher explicitamente entre Mundo A, Mundo B ou uma estratégia de transição.

## 4. Fórmula de referência preservada

Caso a pendência seja implementada futuramente, a fórmula aprovada como referência é:

```text
diferenca_valor = valor_ajustado - valor_original
```

```text
diferenca_percentual =
  se valor_original > 0:
    ((valor_ajustado - valor_original) / valor_original) * 100
  senão:
    null
```

A implementação deve usar `numeric` no banco, não `float`, quando houver cálculo financeiro.

## 5. Restrições vigentes

Enquanto não houver nova decisão explícita, fica bloqueado:

```text
- criar tabela mesa_fluxo_pagamentos_auditoria;
- criar tabela mesa_fluxo_pagamentos_rastreabilidade;
- criar qualquer migration de rastreabilidade;
- alterar public.criar_mesa_simulacao para diff original x ajustado;
- alterar public.mesa_cliente_obter_simulacao_fluxo_historico para diff;
- alterar SegundaViaHistoricoPanel para exibir rastreabilidade;
- alterar parser;
- alterar Worker/Make/n8n;
- alterar motor financeiro;
- alterar agenda/parcelas/operações financeiras;
- misturar rastreabilidade de 2ª via com VPL, antecipação, postergação ou amortização.
```

## 6. Segurança obrigatória para qualquer fase futura

Qualquer retomada desta pendência deve preservar:

```text
- auth.uid() obrigatório;
- tenant/empresa resolvidos pelo banco/RPC;
- RLS ativa onde aplicável;
- anon sem EXECUTE em RPC sensível;
- service_role proibido no frontend;
- frontend sem autoridade para empresa_id, tenant_id, perfil, política, taxa, status ou permissão;
- sem cliente-safe expondo VPL, prêmio, comissão, política interna, taxa, checksum ou metadata sensível;
- testes reais com output real;
- rollback transacional quando aplicável.
```

## 7. Critério de desbloqueio

A rastreabilidade só pode voltar para implementação após decisão explícita sobre:

```text
1. escopo: histórico comercial, engenharia financeira canônica ou transição;
2. fonte do baseline: frontend operacional, banco/RPC, agenda canônica ou snapshot próprio;
3. tabela alvo: mesa_fluxo_pagamentos_*, mesa_cliente_fluxo_parcelas ou outra;
4. visibilidade: admin, gestor, corretor, cliente-safe ou apenas interno;
5. matriz DML;
6. RLS/grants;
7. testes obrigatórios;
8. rollback;
9. impacto em operações financeiras futuras.
```

## 8. Próximo passo permitido

O próximo passo permitido é documental/read-only:

```text
Fase 20C.1 — Preflight de Estado Real e Reconciliação GitHub x Supabase
```

Objetivo:

```text
Verificar o que existe de fato no Supabase, comparar com GitHub/docs e só depois decidir a próxima trilha.
```

Sem o resultado da 20C.1, este contrato permanece como pendência mapeada, não como plano de execução.
