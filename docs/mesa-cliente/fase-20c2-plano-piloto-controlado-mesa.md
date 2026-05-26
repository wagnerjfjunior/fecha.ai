# FECH.AI / MesaCliente — Fase 20C.2
# Plano — Piloto Controlado de Mesa

## 1. Status

```text
Status: PLANEJADO / SEM EXECUÇÃO AINDA
Branch: feature/mesa-cliente-20c-rastreabilidade-valores
Tipo: plano operacional controlado
DDL permitido nesta fase documental: NÃO
DML permitido nesta fase documental: NÃO
Migration permitida: NÃO
RPC nova permitida: NÃO
Frontend permitido: NÃO
```

Este documento registra a decisão de seguir pela trilha:

```text
C — Piloto controlado de mesa / validação operacional mínima
```

A decisão deriva do relatório:

```text
docs/mesa-cliente/fase-20c1-relatorio-preflight-estado-real.md
```

## 2. Motivo da decisão

O preflight 20C.1 confirmou três fatos relevantes:

```text
1. A estrutura canônica de engenharia financeira existe no Supabase.
2. As tabelas canônicas de agenda/parcelas/operações/políticas estão sem massa real.
3. O histórico/2ª via atual possui massa real em mesa_simulacoes e mesa_fluxo_pagamentos.
```

Portanto, antes de criar nova camada de rastreabilidade, alterar RPCs ou avançar com frontend, o próximo passo tecnicamente mais seguro é executar um piloto controlado para gerar evidência operacional real.

## 3. Objetivo do piloto

Validar, com massa controlada, o caminho operacional mínimo do MesaCliente:

```text
1. proposta/simulação existente ou nova;
2. fluxo histórico atual;
3. 2ª via read-only;
4. geração/persistência de agenda financeira canônica, se aplicável;
5. criação de parcelas em mesa_cliente_fluxo_parcelas, se aplicável;
6. registro/simulação de operação financeira, se aplicável;
7. leitura admin/cliente-safe, se aplicável;
8. identificação do gargalo real antes de qualquer nova implementação.
```

## 4. Não objetivo

Este piloto não autoriza:

```text
- implementar rastreabilidade original x final;
- criar tabela nova;
- criar migration;
- alterar RPC;
- alterar frontend;
- alterar parser;
- alterar Worker/Make/n8n;
- alterar motor financeiro;
- expor dados financeiros internos em cliente-safe;
- considerar PASS sem output real.
```

## 5. Premissas verificadas no 20C.1

### 5.1 Estrutura histórica com massa

```text
mesa_simulacoes: 14 registros
mesa_fluxo_pagamentos: 73 registros
```

### 5.2 Estrutura canônica sem massa

```text
mesa_cliente_agendas_financeiras: 0
mesa_cliente_fluxo_parcelas: 0
mesa_cliente_fluxo_operacoes: 0
mesa_cliente_politicas_financeiras: 0
mesa_cliente_politica_premio_faixas: 0
```

### 5.3 RPCs críticas existentes

```text
criar_mesa_simulacao
mesa_cliente_obter_simulacao_fluxo_historico
mesa_cliente_gerar_agenda_financeira_admin
mesa_cliente_persistir_agenda_financeira_admin
mesa_cliente_obter_agenda_financeira_cliente_safe
mesa_cliente_registrar_operacao_financeira_admin
mesa_cliente_resumir_operacao_financeira_admin
mesa_cliente_obter_resumo_operacao_cliente_safe
mesa_cliente_aplicar_operacao_financeira_admin
```

## 6. Gates obrigatórios antes de execução

### Gate A — Definir ambiente

Antes de qualquer execução, registrar:

```text
[ ] ambiente será produção, staging ou dev?
[ ] existe risco de afetar dados reais?
[ ] haverá execução via app, SQL Editor ou RPC controlada?
[ ] haverá rollback transacional possível?
[ ] se não houver rollback, quais registros serão marcados como teste?
```

Decisão pendente:

```text
NÃO executar piloto sem confirmação explícita do ambiente.
```

### Gate B — Resolver WARNs de segurança do preflight

Analisar antes do piloto:

```text
[ ] mesa_cliente_agendas_financeiras com TRUNCATE para authenticated;
[ ] corretores com anon SELECT;
[ ] RLS forced=false em algumas tabelas canônicas;
[ ] corpo das RPCs administrativas financeiras ainda não revisado integralmente.
```

Classificação possível:

```text
OK — não bloqueia piloto;
WARN — seguir com restrição documentada;
BLOCKER — corrigir antes do piloto.
```

### Gate C — Selecionar massa controlada

Registrar sem expor dados sensíveis:

```text
[ ] empresa_id alvo;
[ ] corretor/user_id executor;
[ ] empreendimento alvo;
[ ] unidade alvo;
[ ] simulacao_id alvo, se usar simulação existente;
[ ] proposta nova ou existente;
[ ] motivo da escolha;
[ ] se Chateau Jardin será usado ou não.
```

### Gate D — Definir escopo do piloto

Escolher uma das modalidades:

```text
Modo 1 — Histórico/2ª via apenas.
Modo 2 — Histórico + geração de agenda JSON-first.
Modo 3 — Histórico + persistência de agenda canônica.
Modo 4 — Agenda + parcelas + registro de operação financeira.
Modo 5 — Fluxo completo até aplicação de operação financeira.
```

Recomendação inicial:

```text
Começar no Modo 2 ou Modo 3.
```

Motivo:

```text
As tabelas canônicas estão zeradas. O primeiro objetivo deve ser gerar massa canônica mínima antes de aplicar operação financeira.
```

## 7. Plano de execução sugerido

### 7.1 Etapa 1 — Read-only de seleção

```text
Objetivo: escolher uma simulação/unidade válida.
Tipo: read-only.
Resultado esperado: simulacao_id ou unidade candidata documentada.
```

### 7.2 Etapa 2 — Validar histórico/2ª via

```text
Objetivo: confirmar que a simulação candidata abre na RPC de histórico.
Tipo: read-only via mesa_cliente_obter_simulacao_fluxo_historico.
Resultado esperado: JSON válido com fluxo e visibilidade correta.
```

### 7.3 Etapa 3 — Gerar agenda JSON-first

```text
Objetivo: testar mesa_cliente_gerar_agenda_financeira_admin sem persistência.
Tipo: RPC read/computacional conforme contrato 4A.
Resultado esperado: JSON de agenda calculado sem inserir dados.
```

### 7.4 Etapa 4 — Persistir agenda canônica

```text
Objetivo: criar massa em mesa_cliente_agendas_financeiras e mesa_cliente_fluxo_parcelas.
Tipo: DML controlado via RPC, somente após autorização explícita.
Resultado esperado: agenda ativa + parcelas canônicas.
```

### 7.5 Etapa 5 — Cliente-safe

```text
Objetivo: validar mesa_cliente_obter_agenda_financeira_cliente_safe.
Tipo: read-only.
Resultado esperado: payload sem VPL, prêmio, comissão, política, checksum ou metadata sensível.
```

### 7.6 Etapa 6 — Operação financeira opcional

```text
Objetivo: registrar/resumir/aplicar operação somente se houver autorização posterior.
Tipo: DML controlado via RPC.
Resultado esperado: operação registrada, resumida e/ou aplicada conforme modo aprovado.
```

## 8. Critérios de PASS

O piloto só pode ser considerado PASS quando houver output real para o modo escolhido.

Exemplo para Modo 3:

```text
[ ] simulação candidata identificada;
[ ] histórico/2ª via validado;
[ ] agenda JSON-first gerada;
[ ] agenda persistida;
[ ] parcelas criadas em mesa_cliente_fluxo_parcelas;
[ ] cliente-safe validado;
[ ] sem vazamento de dados internos;
[ ] sem cross-tenant;
[ ] logs/evidências registrados;
[ ] relatório versionado.
```

## 9. Critérios de bloqueio

Bloquear execução se ocorrer:

```text
- ambiente não confirmado;
- WARN de segurança virar BLOCKER;
- usuário executor sem perfil/corretor ativo;
- simulação/unidade não pertencer à empresa correta;
- RPC depender de payload soberano do frontend;
- cliente-safe expor dado interno;
- anon conseguir executar RPC sensível;
- DML direto em tabela financeira fora de RPC;
- ausência de rollback/plano de limpeza quando necessário;
- divergência GitHub x Supabase não explicada.
```

## 10. Registro de rastreabilidade

A pendência de rastreabilidade original x final permanece registrada, mas fora da execução imediata.

Decisão:

```text
O piloto deve gerar evidência para decidir se a rastreabilidade entra no histórico atual, na estrutura canônica ou em estratégia de transição.
```

## 11. Artefato esperado após execução

Depois do piloto, criar:

```text
docs/mesa-cliente/fase-20c2-relatorio-piloto-controlado-mesa.md
```

Conteúdo mínimo:

```text
1. ambiente usado;
2. modo escolhido;
3. massa utilizada;
4. comandos/RPCs executados;
5. output real;
6. registros criados, se houver;
7. cliente-safe validado;
8. problemas encontrados;
9. decisão sobre próxima trilha;
10. impacto sobre rastreabilidade.
```

## 12. Próximo passo permitido

Antes de executar o piloto:

```text
1. revisar WARNs do 20C.1;
2. definir ambiente;
3. escolher modo do piloto;
4. selecionar massa controlada;
5. obter autorização explícita para qualquer DML via RPC.
```

Sem esses itens, este documento permanece como plano, não execução.
