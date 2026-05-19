# Protocolo Mestre FECH.AI / MesaCliente v1.1 — Versão Final

**Status:** Oficial  
**Substitui:** decisões soltas em conversas, protocolos parciais, orientações fragmentadas e versões anteriores não consolidadas.  
**Aplicação:** todas as conversas técnicas, IAs, devs, revisões, migrations, RPCs, arquitetura, testes, banco de dados, frontend, integrações e decisões críticas do projeto FECH.AI / MesaCliente.  

---

## 1. Frase de controle oficial

> **Primeiro contrato. Depois validação. Depois dry-run. Depois persistência.**

Essa frase é a trava de segurança do projeto. Nenhuma IA, conversa ou dev deve avançar para código, migration, RPC, patch ou alteração estrutural antes de validar contrato, evidência, risco e escopo.

---

## 2. Objetivo do protocolo

Este protocolo existe para impedir retrabalho, decisões paralelas, migrations perigosas, respostas inventadas, premissas não validadas e alterações indevidas em ambiente sensível.

O objetivo é padronizar o modo de trabalho para que todas as conversas atuem com:

- engenharia;
- arquitetura;
- segurança;
- rastreabilidade;
- prudência;
- validação;
- testes;
- rollback;
- clareza de fase;
- respeito ao ambiente de produção.

O projeto FECH.AI / MesaCliente é um SaaS multiempresa, multitenant, com dados financeiros e comerciais sensíveis. Portanto, a régua de segurança deve ser alta.

---

## 3. Leis fixas do projeto

1. **Nada soberano vem do frontend.**
2. **Nada sensível vai para cliente-safe.**
3. **Nada financeiro persistido nasce sem dry-run validado.**
4. **Nada entra em produção sem teste rollback.**
5. **Nada é afirmado como fato sem evidência.**
6. **Produção não é laboratório.**
7. **Migration oficial não é rascunho.**
8. **SQL que compila ainda pode estar errado.**
9. **Se existe plano oficial aprovado, não criar plano alternativo sem declarar conflito.**
10. **Se algo não foi verificado, deve ser marcado como NÃO CONFIRMADO.**
11. **Se houver drift entre GitHub e Supabase, o trabalho para até o drift ser entendido.**
12. **Se houver duas soluções concorrentes, nenhuma é aplicada até existir decisão canônica.**
13. **Fases não se misturam.**
14. **Ambiente de produção único exige modo cirúrgico.**
15. **Teste bonito sem critério de bloqueio não protege produção.**

---

## 4. Hierarquia de fonte da verdade

Quando houver conflito entre informações, seguir esta hierarquia:

1. **Banco real / Supabase aplicado**
2. **GitHub na branch correta**
3. **Documentação oficial versionada**
4. **Informação direta do Wagner**
5. **Inferência técnica declarada**
6. **Memória ou conversa anterior**

### Regra prática

- Se GitHub diz uma coisa e o banco real diz outra, o banco real vence.
- Se a IA não verificou a branch correta, ela não pode afirmar como fato.
- Se algo veio de memória, deve ser tratado como hipótese até validação.
- Se uma informação não foi confirmada, deve ser marcada como **NÃO CONFIRMADO**.

---

## 5. Regra do “NÃO CONFIRMADO”

É proibido transformar em código definitivo frases como:

- “provavelmente existe”;
- “deve estar certo”;
- “imagino que seja”;
- “pelo padrão deve ser”;
- “não deve dar problema”;
- “parece que compila”;
- “acho que a tabela tem esse campo”.

Forma correta:

> **NÃO CONFIRMADO. Não vou transformar isso em código definitivo sem validação.**

---

## 6. Separação obrigatória de contexto

Toda análise técnica deve separar:

1. **Estado verificado** — confirmado em arquivo, banco, branch, teste ou evidência.
2. **Estado informado pelo usuário** — dito pelo Wagner, mas ainda não validado tecnicamente.
3. **Inferências feitas** — deduções técnicas, sempre marcadas como inferência.
4. **Estado não confirmado** — tudo que ainda precisa de validação.
5. **Riscos identificados** — riscos técnicos, operacionais, financeiros, segurança ou produção.
6. **Próximo passo único** — uma única ação segura recomendada.

---

## 7. Gates obrigatórios de execução

Nenhum trabalho crítico deve avançar sem passar pelos gates abaixo.

### Gate 0 — Contexto entendido

Antes de qualquer execução, a IA/dev deve resumir:

- objetivo;
- fase;
- escopo;
- fora de escopo;
- riscos;
- fonte da verdade consultada.

### Gate 1 — Fonte de verdade validada

Validar:

- branch correta;
- commit consultado;
- arquivos lidos;
- schema real quando envolver banco;
- migrations existentes;
- migrations aplicadas, se possível;
- documentação oficial.

### Gate 2 — Contrato técnico aprovado

Antes do código, definir:

- objetivo exato;
- arquivos/tabelas/RPCs afetados;
- DML permitido/proibido;
- grants/RLS/policies/triggers;
- segurança;
- testes;
- rollback;
- critérios de aceite;
- critérios de bloqueio.

### Gate 3 — Implementação criada

Somente após contrato aprovado.

### Gate 4 — Testes criados

Toda entrega crítica deve ter testes positivos e negativos.

### Gate 5 — Execução validada

Rodar ou documentar como rodar:

- testes rollback;
- smoke tests;
- validações de grant/RLS;
- validação de ausência de efeito colateral.

### Gate 6 — Handoff/documentação final

Registrar:

- o que mudou;
- o que não mudou;
- arquivos criados/alterados;
- testes;
- riscos restantes;
- próximo passo seguro.

### Regra dos gates

> **Nenhum gate avança com pendência aberta.**

---

## 8. Definition of Ready

Uma tarefa só está pronta para execução quando tiver:

- fase definida;
- escopo definido;
- fora de escopo definido;
- branch confirmada;
- risco classificado;
- tabelas/RPCs/arquivos identificados;
- DML permitido/proibido declarado;
- critério de aceite definido;
- critério de bloqueio definido;
- rollback definido;
- fonte de verdade consultada;
- pontos não confirmados listados.

Se algum item estiver ausente, a tarefa não está pronta.

---

## 9. Definition of Done

Uma entrega só está concluída quando tiver:

- implementação criada;
- testes positivos criados;
- testes negativos criados;
- rollback validado ou documentado;
- zero DML validado quando for dry-run;
- documentação atualizada;
- arquivos obsoletos removidos ou congelados;
- handoff final escrito;
- próximo passo único definido;
- riscos residuais declarados.

---

## 10. Classificação de risco

Toda mudança deve ser classificada antes da execução.

| Risco | Tipo | Exemplos | Regra |
|---|---|---|---|
| R0 | Documentação apenas | README, handoff, ADR | Pode seguir com revisão simples |
| R1 | Read-only / diagnóstico | consultas, inspeção de schema | Sem alteração de estado |
| R2 | Dry-run sem DML | RPC que retorna JSON sem gravar | Precisa teste rollback e zero DML |
| R3 | Migration estrutural sem dados sensíveis | função auxiliar sem DML financeiro | Precisa contrato e teste |
| R4 | RPC/RLS/grants/auth/tenant/financeiro | função `security definer`, RLS, grants | Exige aprovação explícita do Wagner antes de aplicar |
| R5 | Produção crítica com DML financeiro/cross-tenant | insert/update/delete financeiro, operação, confirmação | Exige aprovação explícita, plano de parada e validação pós-aplicação |

### Regra de aprovação

- R0/R1: revisão simples.
- R2/R3: contrato + testes + rollback.
- R4/R5: aprovação explícita do Wagner antes de aplicar.

---

## 11. Classificação de dados

Toda entrega deve considerar a classificação dos dados envolvidos.

| Classe | Descrição | Exemplo | Regra |
|---|---|---|---|
| Público | Informação sem risco | nome público de empreendimento | Pode aparecer em frontend público |
| Interno | Informação operacional | status interno, logs não sensíveis | Acesso autenticado |
| Administrativo sensível | Informação de gestão | permissões, tenant, auditoria | Somente perfis autorizados |
| Financeiro restrito | Regras comerciais e financeiras internas | VPL, prêmio, comissão, política, margem | Nunca vai para cliente-safe |
| Segredo/credencial | tokens, service role, API keys | `service_role`, secrets | Nunca expor no frontend ou logs |

### Regra fixa

> **Dado financeiro interno nunca vai para cliente-safe.**

---

## 12. Produção única: modo cirúrgico

Como o ambiente é sensível e sem staging separado, seguir obrigatoriamente:

1. **Read-only**
2. **Dry-run**
3. **Teste com BEGIN + ROLLBACK**
4. **Aplicação controlada**
5. **Validação pós-aplicação**
6. **Handoff documentado**

É proibido:

- “aplicar e ver”;
- “testar direto no banco”;
- “depois corrigimos”;
- “é só uma alteração pequena”;
- “não deve dar problema”.

Essas frases são bloqueadoras.

---

## 13. Janela de aplicação e critério de parada

Para mudanças R4/R5:

- aplicar em horário controlado;
- ter plano de rollback/correção;
- ter query de validação pós-aplicação;
- ter critério de parada;
- não aplicar se houver dúvida em produção.

### Critérios de parada

Parar imediatamente se ocorrer:

- erro em migration;
- erro de grant;
- erro de RLS;
- falha cross-tenant;
- dado sensível exposto;
- DML inesperado;
- teste rollback falhou;
- função criada com grant indevido para `anon`;
- divergência GitHub x Supabase não explicada.

---

## 14. Pacote obrigatório de evidências

Antes de criar código, migration ou RPC crítica, a IA/dev deve informar:

```txt
Branch consultada:
Commit consultado:
Arquivos lidos:
Migrations existentes:
Migrations aplicadas no banco:
Tabelas verificadas:
Colunas verificadas:
Enums verificados:
RPCs/helpers verificados:
Grants verificados:
RLS/policies verificadas:
Testes existentes:
Pontos não confirmados:
```

Sem evidência, não vira código definitivo.

---

## 15. ADR obrigatório para decisão importante

Toda decisão estrutural deve virar ADR.

### Modelo

```txt
ADR-000X — Título

Data:
Fase:
Branch:
Decisão:
Motivo:
Alternativas consideradas:
Riscos:
Impacto:
Critério de aceite:
Status: proposta | aprovada | substituída | obsoleta
```

### Exemplo oficial

```txt
ADR-0001 — Fase 4A será JSON-first sem persistência

Decisão:
A Fase 4A apenas gera agenda financeira em JSON e não faz DML em mesa_cliente_fluxo_parcelas.

Motivo:
Ambiente de produção único, sem staging separado, com dados financeiros sensíveis.

Alternativas:
1. Persistir direto na 4A.
2. JSON-first na 4A e persistência na 4B.

Decisão aprovada:
Alternativa 2.

Status:
Aprovada.
```

---

## 16. Regra contra soluções concorrentes

Só pode existir uma solução canônica por fase.

Se duas conversas, IAs ou devs criarem soluções diferentes:

1. Nenhuma é aplicada automaticamente.
2. As duas são comparadas.
3. Os acertos são preservados.
4. Os riscos são listados.
5. Uma versão canônica é escolhida.
6. A outra vira rascunho obsoleto.
7. A decisão vira ADR.

---

## 17. Drift GitHub x Supabase

Antes de migration crítica, verificar:

- se a migration existe no GitHub;
- se já foi aplicada no Supabase;
- se há migration local/branch que ainda não entrou;
- se existe função no banco que não está versionada;
- se o schema real bate com o repositório.

Se houver divergência:

> **Parar. Documentar o drift. Corrigir versionamento antes de continuar.**

---

## 18. Padrão de branch, commit e migration

### Branch

- Nunca trabalhar em `main` sem autorização explícita.
- Confirmar branch antes de criar arquivo.
- Quando houver preview Vercel, confirmar a branch do preview antes de assumir estado técnico.

### Commit

Usar prefixos claros:

- `docs:` documentação;
- `feat:` funcionalidade;
- `fix:` correção;
- `test:` teste;
- `chore:` organização;
- `refactor:` refatoração sem mudança funcional.

### Migration

Migration precisa ter:

- timestamp único;
- fase no nome;
- objetivo claro;
- ausência de ambiguidade.

Exemplo bom:

```txt
20260518XXXXXX_mesa_cliente_fase_4a_agenda_financeira_dry_run.sql
```

Exemplos ruins:

```txt
teste.sql
ajuste_final.sql
nova_rpc.sql
fase_4a_agenda.sql
```

---

## 19. Migration obsoleta

Migration errada, experimental ou substituída **não pode ficar em**:

```txt
supabase/migrations
```

Ela deve ir para:

```txt
docs/mesa-cliente/rascunhos-sql/
```

Com aviso no topo:

```txt
RASCUNHO OBSOLETO — NÃO APLICAR EM PRODUÇÃO.
Substituído pela migration oficial: <nome_da_migration>.
Preservado apenas para histórico técnico.
```

Migration problemática na pasta oficial é risco operacional real.

---

## 20. Banco de dados / Supabase

Nenhuma migration deve ser criada antes de validar:

- schema real;
- tabelas existentes;
- colunas existentes;
- enums existentes;
- funções helpers existentes;
- grants existentes;
- RLS existente;
- policies existentes;
- triggers existentes;
- dependências anteriores;
- ordem das migrations;
- se já foi aplicada ou não.

---

## 21. Checklist para RPC sensível

Toda RPC sensível deve validar:

- `auth.uid()` obrigatório;
- usuário ativo;
- empresa/tenant resolvido pelo banco;
- perfil/permissão;
- recurso pertence à empresa;
- empreendimento pertence à empresa;
- simulação pertence à empresa;
- payload não é soberano;
- `anon` bloqueado;
- `public` sem execute indevido;
- retorno sem dados sensíveis indevidos.

É proibido:

- `empresa_id` vindo do frontend como verdade;
- `service_role` no frontend;
- `grant execute` para `anon` em RPC sensível;
- expor VPL, prêmio, comissão ou política interna;
- DML destrutivo sem trava e rollback.

---

## 22. Checklist SECURITY DEFINER

Toda função `SECURITY DEFINER` deve cumprir:

- [ ] `set search_path = public`
- [ ] sem SQL dinâmico desnecessário
- [ ] se houver SQL dinâmico, usar `format`, `quote_ident`, `quote_literal` ou parâmetros corretamente
- [ ] `auth.uid()` obrigatório
- [ ] usuário ativo validado
- [ ] tenant resolvido pelo banco
- [ ] recurso validado contra empresa real
- [ ] empreendimento validado
- [ ] simulação validada, quando aplicável
- [ ] perfil validado
- [ ] `anon` sem execute
- [ ] `public` sem execute indevido
- [ ] retorno sem dado sensível indevido
- [ ] não confia em payload para permissão
- [ ] não usa `empresa_id` do frontend como autoridade

---

## 23. Matriz de DML obrigatória

Toda fase precisa declarar:

| Tabela | SELECT | INSERT | UPDATE | DELETE |
|---|---:|---:|---:|---:|
| `<tabela>` | Sim/Não | Sim/Não | Sim/Não | Sim/Não |

Se a fase é dry-run, qualquer `INSERT`, `UPDATE` ou `DELETE` em tabela crítica é falha automática.

---

## 24. Plano financeiro oficial

A sequência oficial da Engenharia Financeira é:

```txt
4A = gerar agenda financeira em JSON, sem persistir
4B = persistir agenda com lock, idempotência e auditoria
4C = leitura cliente-safe
5A = simular impacto financeiro com agenda persistida
5B = registrar operação financeira
5C = confirmar/cancelar operação
Depois = integração front/BFF
```

Regra curta:

> **4A pensa. 4B grava. 4C mostra para o cliente.**

---

## 25. Regra definitiva da Fase 4A

A Fase 4A é **Dry-run / JSON-first**.

Ela não faz:

- `INSERT` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` em `mesa_cliente_fluxo_parcelas`;
- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `INSERT` em `mesa_cliente_fluxo_operacoes`;
- `UPDATE` em `mesa_cliente_fluxo_operacoes`;
- `DELETE` em `mesa_cliente_fluxo_operacoes`;
- criação de operação financeira;
- confirmação de operação;
- cancelamento de operação;
- cálculo de VPL;
- cálculo de prêmio;
- cálculo de comissão;
- exposição de política interna;
- alteração de frontend;
- alteração de parser;
- alteração de Worker/Make/n8n;
- `EXECUTE` para `anon`;
- uso de `empresa_id` do payload como verdade.

A Fase 4A pode fazer:

- validar `auth.uid()`;
- validar usuário ativo;
- validar tenant/empresa pelo banco;
- validar simulação;
- validar empreendimento;
- validar perfil;
- ignorar ou rejeitar `empresa_id` do payload;
- resolver datas;
- normalizar parcelas;
- classificar periodicidade simbólica;
- retornar JSON administrativo.

---

## 26. RPC oficial da Fase 4A

Nome oficial:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

### Observação sobre o sufixo `_admin`

O sufixo `_admin` significa:

> uso interno/administrativo seguro.

Não significa necessariamente “somente admin global”. A permissão pode permitir, conforme regra operacional aprovada:

- root/admin global;
- admin local;
- gestor/coordenador;
- corretor dono da simulação, se fizer sentido operacional no MesaCliente.

Cliente-safe fica para a Fase 4C.

---

## 27. Testes obrigatórios

Toda entrega crítica deve ter:

- teste positivo;
- teste negativo;
- teste de permissão;
- teste cross-tenant;
- teste `anon` bloqueado;
- teste de payload malicioso;
- teste rollback;
- teste de ausência de efeito colateral.

Todo teste deve trazer:

```txt
Arquivo:
Comando para executar:
Resultado esperado:
Resultado que bloqueia:
Tabelas monitoradas antes/depois:
```

---

## 28. Teste obrigatório para dry-run

Para dry-run, o teste deve provar:

```txt
count_before = count_after
```

Nas tabelas críticas envolvidas.

Para a Fase 4A:

```sql
select count(*) from public.mesa_cliente_fluxo_parcelas;
select count(*) from public.mesa_cliente_fluxo_operacoes;
```

Se mudou linha, falhou.

---

## 29. Rollback

Separar três tipos:

### 29.1 Rollback de teste

```txt
BEGIN + ROLLBACK
```

### 29.2 Rollback de migration aplicada

Se a migration já foi aplicada, não fingir que ela nunca existiu.

Regra:

- criar migration corretiva posterior;
- documentar impacto;
- validar estado final.

### 29.3 Rollback operacional

Para R4/R5:

- backup/snapshot quando aplicável;
- plano de reversão;
- validação pós-reversão;
- critério de parada.

---

## 30. Validação pós-aplicação

Depois de aplicar qualquer migration real:

- conferir grants;
- conferir função criada;
- conferir RLS;
- conferir policies;
- conferir ausência de `anon` indevido;
- rodar smoke test;
- registrar resultado;
- documentar impacto;
- confirmar que não houve DML inesperado.

---

## 31. Frontend, parser, Worker, Make/n8n

Nenhuma fase de banco pode mexer em:

- frontend;
- parser;
- Worker;
- Make;
- n8n;
- motor financeiro atual;
- branch `main`;

sem autorização explícita.

Se o escopo é banco, o trabalho fica no banco.

Se o escopo é frontend, não altera RPC/RLS/migration sem novo contrato.

---

## 32. Modelo obrigatório antes de implementar

Antes de implementar, responder obrigatoriamente:

1. Objetivo exato
2. Fase do projeto
3. Estado verificado
4. Estado informado pelo usuário
5. Inferências feitas
6. Estado não confirmado
7. Riscos identificados
8. Classificação de risco R0-R5
9. Escopo permitido
10. Fora de escopo
11. Arquivos/tabelas/RPCs afetados
12. Matriz de DML
13. Se haverá alteração de grant/RLS/policy/trigger
14. Dados sensíveis envolvidos
15. Plano de execução seguro
16. Testes positivos
17. Testes negativos
18. Teste rollback
19. Critério de aceite
20. Critério de bloqueio
21. Próximo passo único

---

## 33. Bloco mestre para iniciar novas conversas

Use este bloco no início de qualquer conversa técnica:

```txt
Estamos no projeto FECH.AI / MesaCliente.

Antes de propor qualquer código, migration, RPC, patch, frontend ou alteração de banco, siga obrigatoriamente o Protocolo Mestre FECH.AI / MesaCliente v1.1.

Regras centrais:

- Nunca partir de premissa não validada.
- Separar: verificado, informado pelo usuário, inferido e não confirmado.
- Primeiro validar contrato, schema, fase, risco e escopo.
- Não criar código antes de travar contrato de execução.
- Não mexer em frontend, parser, Worker, Make/n8n ou main sem autorização explícita.
- Não aceitar empresa_id do frontend como verdade soberana.
- Não expor VPL, prêmio, comissão, política interna ou metadata sensível para cliente-safe.
- Não conceder EXECUTE para anon em RPC sensível.
- Toda RPC sensível deve validar auth.uid(), usuário ativo, tenant/empresa, empreendimento, simulação e perfil.
- Toda migration crítica precisa ter teste positivo, negativo, rollback e critério de bloqueio.
- Em produção única, seguir: read-only → dry-run → rollback → aplicação controlada → validação pós-aplicação.
- Migration obsoleta não pode ficar em supabase/migrations.
- Se já existe plano oficial aprovado, não criar plano alternativo sem declarar conflito e pedir decisão.
- Se algo não foi confirmado, declarar NÃO CONFIRMADO e não transformar em código definitivo.

Hierarquia de fonte da verdade:

1. Banco real / Supabase aplicado
2. GitHub na branch correta
3. Documentação oficial versionada
4. Informação direta do Wagner
5. Inferência técnica
6. Memória/conversa anterior

Plano financeiro oficial:

4A = gerar agenda financeira em JSON, sem persistir.
4B = persistir agenda com lock, idempotência e auditoria.
4C = leitura cliente-safe.
5A = simular impacto financeiro com agenda persistida.
5B = registrar operação financeira.
5C = confirmar/cancelar operação.
Depois = integração front/BFF.

Na Fase 4A é proibido fazer INSERT, UPDATE ou DELETE em mesa_cliente_fluxo_parcelas ou mesa_cliente_fluxo_operacoes.

Antes de implementar, responda obrigatoriamente:

1. Objetivo exato
2. Fase do projeto
3. Estado verificado
4. Estado informado pelo usuário
5. Inferências feitas
6. Estado não confirmado
7. Riscos identificados
8. Classificação de risco R0-R5
9. Escopo permitido
10. Fora de escopo
11. Arquivos/tabelas/RPCs afetados
12. Matriz de DML
13. Se haverá alteração de grant/RLS/policy/trigger
14. Plano de execução seguro
15. Testes obrigatórios com comando e saída esperada
16. Critério de aceite
17. Critério de bloqueio
18. Próximo passo único
```

---

## 34. Frases proibidas em execução crítica

Em tarefas críticas, evitar e bloquear frases como:

- “vamos aplicar e ver”;
- “depois corrigimos”;
- “não deve dar problema”;
- “é só uma pequena alteração”;
- “provavelmente a coluna existe”;
- “deve estar certo pelo padrão”;
- “não precisa testar isso agora”;
- “o SQL compila, então está pronto”.

Forma correta:

> **Não confirmado. Vamos validar antes de executar.**

---

## 35. Handoff final obrigatório

Ao final de cada entrega, registrar:

```txt
Fase:
Branch:
Commit(s):
Arquivos criados:
Arquivos alterados:
Arquivos movidos para rascunho/obsoletos:
O que foi feito:
O que não foi feito:
DML realizado:
Grants/RLS/policies alterados:
Testes criados:
Testes executados:
Resultado esperado:
Riscos residuais:
Próximo passo único:
```

---

## 36. Decisão final do protocolo

Este é o protocolo único oficial para o projeto FECH.AI / MesaCliente.

A partir daqui, qualquer IA, conversa ou dev que criar SQL, migration, RPC, patch, alteração de banco ou mudança de arquitetura antes de contrato, evidência, risco e escopo estará fora do processo.

> **Engenharia primeiro. Ansiedade depois — e mesmo assim, com rollback.**
