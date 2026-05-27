# FECH.AI / MesaCliente — Fase 20C.3
# Plano — Execução Controlada Modo 3

## 1. Status

```text
Status: PLANEJADO / AGUARDANDO SELEÇÃO DE MASSA E AUTORIZAÇÃO DML
Branch: feature/mesa-cliente-20c-rastreabilidade-valores
Modo: 3 — Histórico + geração/persistência de agenda canônica
DDL permitido: NÃO
Migration permitida: NÃO
Alteração de RPC: NÃO
Alteração de frontend: NÃO
DML via RPC 4B: SOMENTE APÓS AUTORIZAÇÃO EXPLÍCITA
```

Este documento formaliza a preparação da execução controlada do Modo 3 do piloto.

## 2. Base de decisão

A Fase 20C.1 confirmou:

```text
- estrutura canônica financeira existe;
- estrutura canônica estava sem massa real;
- histórico/2ª via atual possui massa real;
- RPCs críticas existem.
```

A Fase 20C.2 confirmou:

```text
- hardening de grants da agenda foi aplicado no banco real e versionado em migration;
- RPC 4A mesa_cliente_gerar_agenda_financeira_admin está OK preliminar com WARNs;
- RPC 4B mesa_cliente_persistir_agenda_financeira_admin está OK preliminar com WARNs;
- Modo 3 está tecnicamente destravado para preparação;
- execução DML ainda depende de autorização explícita.
```

## 3. Objetivo do Modo 3

Validar o caminho mínimo:

```text
1. selecionar uma simulação candidata com fluxo histórico;
2. validar leitura read-only do histórico/2ª via;
3. gerar agenda financeira JSON-first via RPC 4A;
4. persistir agenda canônica via RPC 4B, somente após autorização explícita;
5. validar registros criados em mesa_cliente_agendas_financeiras;
6. validar registros criados em mesa_cliente_fluxo_parcelas;
7. validar leitura cliente-safe da agenda;
8. registrar output real em relatório.
```

## 4. Escopo permitido antes da autorização DML

Permitido agora:

```text
- consultar simulações candidatas;
- consultar quantidade de itens em mesa_fluxo_pagamentos;
- consultar se já existe agenda canônica para a simulação;
- validar histórico/2ª via read-only;
- preparar payload para 4A;
- revisar SQL/RPC antes de executar.
```

Não permitido ainda:

```text
- executar mesa_cliente_persistir_agenda_financeira_admin;
- criar agenda;
- criar parcelas;
- registrar operação financeira;
- aplicar operação financeira;
- alterar qualquer dado fora da RPC 4B aprovada;
- alterar frontend;
- alterar parser;
- alterar Worker/Make/n8n.
```

## 5. Critérios para escolher simulação candidata

A simulação candidata deve:

```text
[ ] existir em public.mesa_simulacoes;
[ ] ter empresa_id;
[ ] ter empreendimento_id;
[ ] ter corretor_id ou contexto de usuário executor claro;
[ ] ter unidade_estoque_id quando possível;
[ ] ter fluxo em public.mesa_fluxo_pagamentos;
[ ] não possuir agenda canônica ativa prévia, preferencialmente;
[ ] não possuir operação financeira confirmada;
[ ] pertencer a empresa/tenant controlado;
[ ] ter risco operacional baixo;
[ ] ser adequada para teste/piloto.
```

## 6. Gates antes da execução DML

### Gate 1 — Ambiente

```text
[ ] ambiente confirmado;
[ ] impacto operacional aceito;
[ ] se produção, massa candidata explicitamente aprovada;
[ ] rollback/limpeza documentado ou decisão de manter massa piloto documentada.
```

### Gate 2 — Executor

```text
[ ] usuário executor autenticado;
[ ] corretor ativo;
[ ] perfil compatível com 4A/4B;
[ ] empresa do executor compatível com a simulação, salvo root/admin_global.
```

### Gate 3 — Simulação candidata

```text
[ ] simulacao_id escolhido;
[ ] fluxo histórico validado;
[ ] agenda prévia ausente ou status compreendido;
[ ] sem operação confirmada bloqueante.
```

### Gate 4 — Comandos aprovados

```text
[ ] RPC 4A aprovada para execução;
[ ] RPC 4B aprovada para execução DML;
[ ] queries de validação pós-execução definidas;
[ ] relatório de evidência preparado.
```

## 7. Sequência de execução prevista

### 7.1 Seleção read-only

```sql
-- selecionar simulações com fluxo e sem agenda canônica
```

### 7.2 Validação de histórico/2ª via

```sql
-- executar mesa_cliente_obter_simulacao_fluxo_historico em contexto autenticado adequado
```

### 7.3 Preparação de payload de fluxo

```sql
-- montar p_fluxo_json a partir de mesa_fluxo_pagamentos ou payload equivalente validado
```

### 7.4 Geração 4A

```sql
-- executar mesa_cliente_gerar_agenda_financeira_admin
-- sem DML financeiro
```

### 7.5 Persistência 4B

```sql
-- executar mesa_cliente_persistir_agenda_financeira_admin
-- DML controlado via RPC, somente após autorização explícita
```

### 7.6 Validação pós-persistência

```sql
-- contar agenda criada
-- contar parcelas criadas
-- validar checksum/status
-- validar cliente-safe
```

## 8. Critérios de PASS do Modo 3

```text
[ ] simulação candidata documentada;
[ ] histórico/2ª via retorna fluxo válido;
[ ] 4A retorna agenda válida;
[ ] 4B persiste agenda ativa;
[ ] mesa_cliente_agendas_financeiras recebe 1 agenda ativa;
[ ] mesa_cliente_fluxo_parcelas recebe parcelas correspondentes;
[ ] cliente-safe retorna payload sem vazamento interno;
[ ] não há erro cross-tenant;
[ ] não há DML direto fora de RPC;
[ ] evidência real registrada;
[ ] relatório versionado.
```

## 9. Critérios de bloqueio

```text
- simulação sem fluxo;
- usuário executor sem permissão;
- histórico/2ª via negado para usuário esperado;
- 4A retorna agenda inválida;
- 4B falha por segurança/autorização;
- cliente-safe expõe metadata sensível;
- agenda criada com empresa/empreendimento divergente;
- parcela criada sem valor_original/valor_atual;
- operação financeira confirmada existente bloqueia substituição;
- qualquer necessidade de alterar parser/motor/frontend para passar o teste.
```

## 10. Relatório esperado após execução

Criar:

```text
docs/mesa-cliente/fase-20c3-relatorio-execucao-controlada-modo-3.md
```

Conteúdo mínimo:

```text
1. ambiente;
2. executor/contexto;
3. simulação candidata;
4. comandos executados;
5. outputs reais;
6. registros criados;
7. validação cliente-safe;
8. erros/WARNs;
9. decisão sobre próxima fase;
10. impacto sobre rastreabilidade.
```

## 11. Status atual

```text
20C.3 ainda não executada.
Próximo passo: seleção read-only de simulação candidata.
```
