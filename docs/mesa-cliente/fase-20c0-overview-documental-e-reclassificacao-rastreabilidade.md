# FECH.AI / MesaCliente — Fase 20C.0
# Overview documental e reclassificação da rastreabilidade

## 1. Status

```text
Status: DOCUMENTAL / ALINHAMENTO
Branch: feature/mesa-cliente-20c-rastreabilidade-valores
Tipo: sem DDL, sem DML, sem migration, sem RPC, sem frontend
Objetivo: reconciliar a pendência de rastreabilidade com a arquitetura financeira canônica antes de qualquer implementação
```

Este documento existe para evitar que a pendência “valor original x valor final” seja implementada por impulso técnico apenas porque foi identificada durante a validação da 2ª via.

Decisão de controle:

```text
A rastreabilidade está mapeada, mas NÃO está automaticamente liberada para migration/RPC/frontend.
```

## 2. Documentos considerados nesta leitura

Foram considerados como base de alinhamento:

```text
docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md
docs/mesa-cliente/engenharia-financeira-arquitetura.md
docs/mesa-cliente/engenharia-financeira-roadmap-execucao-ate-mesa-cliente.md
docs/mesa-cliente/fase-4b-contrato-persistencia-agenda-financeira.md
docs/mesa-cliente/fase-4c-cliente-safe-fechamento.md
docs/mesa-cliente/fase-5b-contrato-registro-operacao-financeira.md
docs/mesa-cliente/fase-6-smoke-pos-producao-execucao.md
docs/mesa-cliente/fase-7-aplicacao-operacao-financeira-execucao.md
docs/mesa-cliente/fase-8b-fechamento-tecnico.md
docs/mesa-cliente/fase-8k-validacao-19e-smoke-runtime-payload-completo-fluxo.md
docs/mesa-cliente/fase-20a-validacao-rpc-reabrir-fluxo-historico.md
docs/mesa-cliente/fase-20a1-validacao-hardening-acesso-fluxo-historico.md
docs/mesa-cliente/fase-8-20-pre-pr-main-handoff.md
docs/mesa-cliente/fase-20c-contrato-rastreabilidade-valores.md
```

## 3. Fato técnico identificado

A 2ª via read-only funciona sobre o fluxo salvo em `public.mesa_fluxo_pagamentos`.

A pendência identificada é:

```text
Quando o fluxo é alterado antes de salvar, a 2ª via mostra o valor final salvo, mas ainda não mostra lado a lado o valor original da tabela/parser e o delta aplicado.
```

Esta pendência já foi registrada no handoff pré-PR para main como próxima fase sugerida, mas o próprio handoff delimitou que ela não deve contaminar operações financeiras, antecipação, amortização, juros ou VPL.

## 4. Correção de rota

A existência da pendência não obriga implementação imediata.

A rastreabilidade pode ser tratada de duas formas distintas:

```text
A) Rastreabilidade comercial/histórica da 2ª via atual.
B) Rastreabilidade financeira canônica dentro da engenharia financeira oficial.
```

Esses dois caminhos não são equivalentes.

## 5. Mundo A — histórico/2ª via atual

### 5.1 Finalidade

Explicar ao corretor/gestor, na 2ª via read-only, a diferença entre:

```text
valor original carregado da tabela/parser
valor final salvo na proposta
```

### 5.2 Base técnica atual

O mundo A usa:

```text
public.mesa_simulacoes
public.mesa_fluxo_pagamentos
public.mesa_cliente_obter_simulacao_fluxo_historico(uuid,jsonb)
SegundaViaHistoricoPanel.jsx
```

### 5.3 Natureza

É uma melhoria de visualização e rastreabilidade comercial do histórico.

Não é motor financeiro.
Não é aplicação de operação financeira.
Não é VPL.
Não é antecipação.
Não é postergação.
Não é cliente-safe por definição.

### 5.4 Quando faz sentido implementar

Faz sentido se a prioridade operacional for:

```text
melhorar a explicação da 2ª via/histórico antes do piloto de mesa ou antes de avançar o uso comercial do histórico.
```

### 5.5 Risco

Mesmo sendo melhoria de histórico, se envolver migration/RPC, ela sobe para risco R3/R4 porque toca dados financeiros, tenant, empresa e visibilidade comercial.

## 6. Mundo B — engenharia financeira canônica

### 6.1 Finalidade

Manter a trilha oficial de agenda, parcelas, operações, aplicação e resumo financeiro.

### 6.2 Base arquitetural

A arquitetura oficial já prevê uma tabela canônica para parcelas financeiras:

```text
public.mesa_cliente_fluxo_parcelas
```

Esta tabela é o local natural para conceitos como:

```text
valor_original
valor_atual
data_original
data_atual
pode_receber_vpl
pode_receber_antecipacao
pode_receber_postergacao
metadata
```

### 6.3 Relação com fases já documentadas

A Fase 4B transforma a agenda validada em:

```text
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
```

A Fase 5B registra operação financeira a partir de dados soberanos do banco:

```text
mesa_simulacoes
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_politicas_financeiras
auth.uid()
```

A Fase 7 aplica operação financeira de forma controlada, alterando parcela/operação/agenda, com proteção contra payload soberano do frontend.

### 6.4 Quando faz sentido implementar

Faz sentido se a prioridade for:

```text
avançar engenharia financeira canônica: agenda -> parcelas -> operação -> aplicação -> resumo seguro.
```

Nesse caso, não se deve criar uma tabela paralela de rastreabilidade em `mesa_fluxo_pagamentos` sem avaliar se isso duplica o papel de `mesa_cliente_fluxo_parcelas`.

## 7. Decisão atual sobre a Fase 20C criada anteriormente

O arquivo abaixo foi criado como contrato candidato inicial:

```text
docs/mesa-cliente/fase-20c-contrato-rastreabilidade-valores.md
```

A partir deste overview, sua classificação passa a ser:

```text
Status operacional: PROPOSTA CANDIDATA / PENDÊNCIA MAPEADA
Liberação para migration: NÃO
Liberação para RPC: NÃO
Liberação para frontend: NÃO
```

Ele não deve ser usado como autorização de implementação enquanto este overview não for aprovado e enquanto não houver decisão explícita de priorizar o mundo A ou o mundo B.

## 8. Regra de não implementação imediata

Fica bloqueado, por enquanto:

```text
- criar migration de rastreabilidade;
- criar tabela mesa_fluxo_pagamentos_auditoria ou equivalente;
- alterar criar_mesa_simulacao para diff original x ajustado;
- alterar mesa_cliente_obter_simulacao_fluxo_historico para retornar diff;
- alterar SegundaViaHistoricoPanel para exibir diff;
- alterar motor financeiro;
- alterar parser;
- alterar Worker/Make/n8n;
- alterar agenda/parcelas canônicas;
- misturar 2ª via/histórico com VPL/antecipação/postergação.
```

## 9. Leitura consolidada do roadmap

Mapa técnico atual, conforme documentação lida:

```text
Protocolo Mestre v1.2
  -> Arquitetura de Engenharia Financeira
  -> 4A: agenda financeira JSON-first, sem persistência
  -> 4B: persistência segura da agenda financeira
  -> 4C: leitura cliente-safe da agenda persistida
  -> 5A/5A.1: simulação administrativa de impacto
  -> 5B: registro administrativo de operação financeira
  -> 5C: confirmação/cancelamento administrativo
  -> 5D/6: leitura/resumos admin e cliente-safe
  -> 7: aplicação controlada da operação financeira
  -> 8B/8K: adapter/front/BFF e smoke runtime de payload completo
  -> 20A/20B: histórico e 2ª via read-only com hardening de visibilidade comercial
  -> pendência mapeada: rastreabilidade original x final na 2ª via
```

## 10. Posição recomendada

A recomendação técnica atual é:

```text
Não implementar rastreabilidade imediatamente.
Usar a 20C como pendência mapeada.
Escolher primeiro a próxima trilha de execução.
```

Opções válidas de próxima trilha:

### Opção A — estabilizar histórico/2ª via

```text
Criar subfase futura para rastreabilidade comercial da 2ª via, limitada a leitura histórica e sem tocar VPL/operações.
```

Pré-requisitos:

```text
- preflight de schema real;
- contrato revisado;
- decisão sobre fonte de baseline;
- testes de permissão 20A/20A.5 reaproveitados;
- proposta nova controlada para validar original x final.
```

### Opção B — avançar engenharia financeira canônica

```text
Priorizar agenda/parcelas/operações usando mesa_cliente_fluxo_parcelas como fonte canônica de valor_original/valor_atual.
```

Pré-requisitos:

```text
- reconciliar estado real do Supabase com docs das fases 4B a 7;
- validar se as RPCs financeiras estão aplicadas no ambiente atual;
- validar massa real para operação financeira;
- reexecutar smoke pendente quando houver operação real elegível.
```

### Opção C — piloto controlado de mesa

```text
Executar um fluxo real controlado do MesaCliente com proposta, histórico, 2ª via e, se aplicável, operação financeira já existente.
```

Pré-requisitos:

```text
- massa controlada;
- usuários por perfil/time;
- checklist de segurança;
- ambiente definido;
- sem novas migrations até obter evidência do gargalo real.
```

## 11. Recomendação final deste overview

Para evitar duplicidade estrutural, a ordem recomendada é:

```text
1. Fechar este overview documental.
2. Validar o estado real do Supabase contra as fases 4B, 4C, 5B, 6, 7, 8K e 20A.
3. Decidir se o próximo problema prioritário é:
   A) explicar melhor histórico/2ª via;
   B) continuar operação financeira canônica;
   C) preparar piloto controlado de mesa.
4. Só depois liberar qualquer contrato de implementação.
```

## 12. Critério de desbloqueio para rastreabilidade

A rastreabilidade só deve voltar para implementação quando houver decisão explícita sobre:

```text
- escopo: histórico comercial ou engenharia financeira canônica;
- fonte do baseline: frontend operacional, banco/RPC, agenda canônica ou snapshot próprio;
- tabela alvo: mesa_fluxo_pagamentos_rastreabilidade, mesa_cliente_fluxo_parcelas ou outra;
- visibilidade: admin/corretor/gestor/cliente-safe;
- tests reais obrigatórios;
- rollback;
- impacto em operação financeira futura.
```

Sem essa decisão, qualquer migration de rastreabilidade fica bloqueada.

## 13. Registro de pendência sem pressão de execução

Pendência preservada:

```text
Exibir, em momento oportuno, valor original, valor final, diferença absoluta e diferença percentual para linhas alteradas do fluxo.
```

Mas a pendência não redefine a próxima fase por si só.

Regra operacional:

```text
Problema identificado não é automaticamente prioridade de implementação.
Prioridade vem de roadmap, risco, dependência e decisão explícita.
```
