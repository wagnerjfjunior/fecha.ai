# Protocolo Mestre FECH.AI / MesaCliente v1.2

**Status:** Oficial  
**Projeto:** FECH.AI / MesaCliente  
**Escopo:** engenharia, arquitetura, banco de dados, RPCs, migrations, segurança, testes, validação, handoff e continuidade entre conversas/IA/devs  
**Substitui:** protocolos soltos, decisões fragmentadas e orientações conflitantes anteriores  
**Regra de adoção:** toda conversa técnica futura deve iniciar ou referenciar este protocolo antes de propor código, migration, RPC, patch, frontend, alteração de banco ou mudança arquitetural.

---

## 1. Frase-mãe oficial

> **Primeiro contrato. Depois evidência. Depois dry-run. Depois teste rollback. Depois persistência controlada.**

Complemento obrigatório para banco de dados:

> **Produção não é laboratório. Migration não é rascunho. SQL que compila ainda pode estar errado.**

Frase de trava quando algo não estiver validado:

> **NÃO CONFIRMADO. Não vou transformar isso em código definitivo sem validação.**

---

## 2. Objetivo do protocolo

Este protocolo existe para impedir retrabalho, decisões concorrentes, migrations ansiosas, código baseado em premissa e soluções aparentemente bonitas, mas perigosas para produção.

Ele obriga qualquer IA, dev ou conversa técnica a trabalhar em ordem:

1. Entender o contexto.
2. Separar fato de inferência.
3. Validar fonte da verdade.
4. Travar contrato de execução.
5. Medir risco.
6. Definir testes e rollback.
7. Só então implementar.
8. Documentar evidências e handoff.

A regra central é simples: **nenhuma execução crítica nasce sem contrato e evidência.**

---

## 3. Leis fixas do FECH.AI / MesaCliente

1. Nada soberano vem do frontend.
2. Nada sensível vai para cliente-safe.
3. Nada financeiro persistido nasce sem dry-run validado.
4. Nada entra em produção sem teste rollback.
5. Nada é afirmado como fato sem evidência.
6. Produção não é laboratório.
7. Migration não é rascunho.
8. SQL que compila ainda pode estar errado.
9. Fases não se misturam.
10. Se houver conflito entre conversas, nenhuma solução é aplicada sem decisão canônica.
11. Se houver drift entre GitHub e Supabase, o trabalho para até o drift ser entendido.
12. RPC sensível não concede `EXECUTE` para `anon`.
13. `service_role` nunca vai para frontend, build público, client app ou código exposto.
14. `empresa_id`, `tenant_id`, `empreendimento_id`, perfil e permissão devem ser validados no banco/RPC.
15. Toda decisão importante vira documentação oficial ou ADR.

---

## 4. Modelo mental obrigatório: nunca partir de premissa

Toda resposta técnica deve separar explicitamente:

- **Verificado com evidência:** confirmado por banco, GitHub, arquivo, teste ou comando.
- **Informado pelo Wagner:** contexto operacional fornecido pelo usuário, ainda podendo exigir validação técnica.
- **Inferido:** conclusão lógica, mas ainda não comprovada.
- **Não confirmado:** ponto que não pode virar código definitivo.
- **Fora de escopo:** tudo que não deve ser tocado nesta entrega.

É proibido tratar inferência como fato.

Frases proibidas como base de execução:

- “provavelmente existe”
- “deve estar certo”
- “imagino que seja”
- “pelo padrão deve ser”
- “não deve dar problema”
- “é só uma alteração pequena”
- “depois corrigimos”
- “vamos aplicar e ver”

Se aparecer uma dessas ideias, a resposta correta é:

> **NÃO CONFIRMADO. Preciso validar antes de propor execução.**

---

## 5. Hierarquia oficial da fonte da verdade

Quando houver conflito entre informações, usar esta ordem:

1. **Banco real / Supabase aplicado**
2. **GitHub na branch correta**
3. **Documentação oficial versionada**
4. **Informação direta do Wagner**
5. **Inferência técnica declarada**
6. **Memória/conversa anterior**

Regras:

- Se GitHub diz uma coisa e o banco real diz outra, o banco real vence.
- Se a branch correta não foi verificada, não afirmar como fato.
- Se a migration existe no GitHub, mas não foi aplicada no banco, declarar isso.
- Se a função existe no banco, mas não está versionada no GitHub, declarar drift.

---

## 6. Bloco mestre para iniciar novas conversas técnicas

Use este bloco no começo de qualquer conversa técnica do projeto:

```text
Estamos no projeto FECH.AI / MesaCliente.

Antes de propor qualquer código, migration, RPC, patch, frontend ou alteração de banco, siga obrigatoriamente o Protocolo Mestre FECH.AI / MesaCliente v1.2.

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
- Toda migration crítica precisa ter teste positivo, teste negativo, rollback e critério de bloqueio.
- Em produção única, seguir: read-only → dry-run → rollback → aplicação controlada → validação pós-aplicação.
- Migration obsoleta não pode ficar em supabase/migrations.
- Se já existe plano oficial aprovado, não criar plano alternativo sem declarar conflito e pedir decisão.
- Se GitHub, banco real e documentação divergirem, declarar drift antes de executar.

Primeiro me diga:
1. O que você entendeu.
2. Qual fase estamos executando.
3. O que está dentro e fora do escopo.
4. Quais riscos existem.
5. Qual será o plano seguro.
6. Quais testes validarão a entrega.
```

---

## 7. Checklist obrigatório antes de qualquer execução

Antes de escrever código, SQL, migration, RPC, patch ou plano de alteração, responder:

1. Qual é o objetivo exato?
2. Qual fase do projeto estamos executando?
3. Qual é o estado verificado?
4. Qual é o estado informado pelo Wagner?
5. Quais inferências estão sendo feitas?
6. O que está não confirmado?
7. O que está dentro do escopo?
8. O que está fora do escopo?
9. Quais arquivos, tabelas, funções, RPCs ou policies serão tocados?
10. Haverá `SELECT`?
11. Haverá `INSERT`?
12. Haverá `UPDATE`?
13. Haverá `DELETE`?
14. Haverá alteração de `GRANT`, RLS, policy ou trigger?
15. Haverá dado sensível envolvido?
16. Algum dado virá do frontend?
17. Vai mexer em produção?
18. Existe staging?
19. Existe rollback de teste?
20. Existe rollback real caso já seja aplicado?
21. Como será testado?
22. Qual é o critério de aceite?
23. Qual é o critério de bloqueio?
24. Qual é o próximo passo único?

Se qualquer item estiver ambíguo e o risco for alto/crítico, parar e pedir decisão.

---

## 8. Gates obrigatórios de execução

Nenhuma entrega crítica avança se o gate anterior estiver pendente.

### Gate 0 — Contexto entendido

Obrigatório declarar:

- objetivo;
- fase;
- escopo;
- fora de escopo;
- riscos aparentes;
- pontos não confirmados.

### Gate 1 — Fonte de verdade validada

Obrigatório validar:

- branch correta;
- arquivos existentes;
- migrations existentes;
- estado do banco, quando aplicável;
- schema real;
- helpers/RPCs reais;
- drift GitHub x Supabase.

### Gate 2 — Contrato técnico aprovado

Obrigatório definir:

- assinatura da RPC, se houver;
- DML permitido/proibido;
- grants;
- RLS/policies;
- dados sensíveis;
- testes;
- rollback;
- critério de aceite;
- critério de bloqueio.

### Gate 3 — Implementação criada

Obrigatório:

- criar somente arquivos permitidos;
- não tocar fora do escopo;
- não misturar fases;
- manter nomenclatura oficial;
- manter compatibilidade multitenant/multiempresa.

### Gate 4 — Testes criados

Obrigatório:

- teste positivo;
- teste negativo;
- teste de permissão;
- teste cross-tenant, quando aplicável;
- teste anon bloqueado, quando aplicável;
- teste rollback;
- teste de ausência de efeito colateral, quando dry-run.

### Gate 5 — Execução validada

Obrigatório registrar:

- comando executado;
- saída esperada;
- saída obtida;
- PASS/FAIL por bloco;
- tabelas monitoradas;
- contagens antes/depois, quando aplicável.

### Gate 6 — Handoff/documentação final

Obrigatório documentar:

- o que mudou;
- o que não mudou;
- evidências;
- riscos remanescentes;
- arquivos criados/alterados;
- próximos passos;
- decisão canônica.

---

## 9. Definition of Ready e Definition of Done

### Definition of Ready

Uma tarefa só está pronta para implementação quando tiver:

- fase definida;
- escopo definido;
- fora de escopo definido;
- branch confirmada;
- risco classificado;
- fonte da verdade validada;
- tabelas/RPCs/arquivos identificados;
- DML permitido/proibido declarado;
- dados sensíveis mapeados;
- critério de aceite definido;
- critério de bloqueio definido;
- rollback definido;
- testes planejados.

### Definition of Done

Uma tarefa só está concluída quando tiver:

- implementação criada;
- testes positivos criados;
- testes negativos criados;
- rollback validado;
- zero DML validado quando for dry-run;
- documentação atualizada;
- arquivos obsoletos removidos/congelados;
- handoff final escrito;
- riscos remanescentes declarados;
- próximos passos claros.

---

## 10. Classificação de risco e aprovação

Toda mudança deve ser classificada antes de execução.

| Risco | Exemplo | Regra | Aprovador mínimo |
|---|---|---|---|
| R0 — Documental | README, documentação, comentário | Pode executar com revisão simples | IA/dev responsável |
| R1 — Baixo | Ajuste visual isolado sem regra crítica | Diff e validação simples | Responsável técnico |
| R2 — Médio | Frontend sem regra financeira/autorização | Diff, teste funcional e rollback de código | Responsável técnico |
| R3 — Alto | RPC, migration, RLS, grants, auth, trigger | Contrato + testes + rollback | Wagner ou responsável técnico designado |
| R4 — Crítico | Produção, financeiro, tenant, dados sensíveis | Dry-run + rollback + aprovação explícita | Wagner |
| R5 — Emergencial | Correção em produção com impacto ativo | Plano de parada + evidência + validação pós | Wagner |

Qualquer alteração em Supabase, RLS, RPC, policies, grants, triggers, auth, tenant, empresa_id, mesa financeira, operação financeira ou dados de cliente é automaticamente R3 ou superior.

---

## 11. Classificação de dados

Toda entrega deve classificar o dado envolvido.

| Classe | Exemplos | Pode ir para cliente-safe? | Observação |
|---|---|---:|---|
| Público | Nome público do empreendimento, bairro, descrição comercial | Sim | Desde que autorizado comercialmente |
| Interno operacional | IDs internos, contexto de simulação, logs técnicos | Não | Apenas admin/gestão/dev autorizado |
| Sensível comercial | política, desconto, VPL, prêmio, comissão, margem, taxa interna | Não | Nunca expor em cliente-safe |
| Dados pessoais | nome, telefone, e-mail, CPF, lead, cliente | Não sem finalidade e autorização | LGPD e mínimo necessário |
| Secreto | service_role, tokens, credenciais, webhooks privados | Nunca | Proibido em frontend, commit e logs |
| Cliente-safe | agenda limpa, valores finais permitidos, datas comerciais autorizadas | Sim | Deve ser versão sanitizada |
| Admin/internal-safe | retorno administrativo sem segredo crítico | Não é cliente-safe | Pode conter diagnóstico operacional controlado |

Regra: **cliente-safe é uma visão própria, não é “admin com menos campos por acaso”.**

---

## 12. Regras para ambiente de produção única

Como o ambiente atual tem banco de produção único, sem staging separado, o fluxo padrão é:

1. Read-only.
2. Dry-run.
3. Teste com `BEGIN` + `ROLLBACK`.
4. Aplicação controlada.
5. Validação pós-aplicação.
6. Handoff documentado.

É proibido:

- aplicar para “ver se funciona”;
- testar DML destrutivo direto;
- assumir que backup substitui teste;
- ignorar falha parcial;
- aplicar migration crítica sem plano de parada.

Para R4/R5, exigir:

- horário controlado;
- comando exato;
- validação prévia;
- validação pós-aplicação;
- plano de correção;
- critério de parada.

Critérios de parada imediata:

- erro em migration;
- erro de grant;
- erro cross-tenant;
- dado sensível exposto;
- DML inesperado;
- teste rollback falhou;
- contagem antes/depois divergente em fase dry-run;
- drift não explicado entre GitHub e banco.

---

## 13. Protocolo de drift GitHub x Supabase

Antes de migration crítica, verificar:

- se a migration existe no GitHub;
- se a migration já foi aplicada no Supabase;
- se há migration na branch que ainda não entrou;
- se existe função no banco que não está versionada;
- se o nome/timestamp da migration conflita com outra;
- se a branch correta foi usada.

Se houver divergência:

1. Parar.
2. Documentar o drift.
3. Declarar impacto.
4. Corrigir versionamento ou criar migration corretiva.
5. Só então continuar.

Nunca apagar arquivo de migration já aplicada como se nada tivesse acontecido.

---

## 14. Padrão para banco de dados / Supabase

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

### 14.1 RPC sensível

Toda RPC sensível deve ter:

```sql
language plpgsql
security definer
set search_path = public
```

E deve validar:

- `auth.uid()` obrigatório;
- usuário ativo;
- empresa/tenant resolvido pelo banco;
- perfil/permissão;
- recurso pertence à empresa;
- empreendimento pertence à empresa;
- simulação pertence à empresa;
- payload não é soberano;
- `anon` bloqueado;
- retorno sem dados sensíveis indevidos.

É proibido:

- aceitar `empresa_id` do frontend como verdade;
- usar `service_role` no frontend;
- conceder `EXECUTE` para `anon` em RPC sensível;
- expor VPL, prêmio, comissão, margem, política interna ou taxa interna em cliente-safe;
- DML destrutivo sem trava e rollback;
- migration obsoleta em `supabase/migrations`.

### 14.2 Checklist SECURITY DEFINER

Toda função `security definer` precisa passar por este checklist:

- [ ] `set search_path = public`
- [ ] sem SQL dinâmico desnecessário
- [ ] se houver SQL dinâmico, usar `format`, `%I`, `%L` e/ou `quote_*` corretamente
- [ ] `auth.uid()` obrigatório
- [ ] usuário ativo validado
- [ ] tenant/empresa resolvido pelo banco
- [ ] recurso validado contra empresa real
- [ ] perfil/permissão validado
- [ ] `anon` sem `EXECUTE`
- [ ] `public` sem `EXECUTE`
- [ ] grants restritos ao necessário
- [ ] retorno sem dado sensível indevido
- [ ] payload validado por tamanho, tipo e formato
- [ ] não confia em payload para permissão
- [ ] não usa `empresa_id` do frontend como autoridade

`security definer` é poderoso como motosserra: útil, mas não é brinquedo.

---

## 15. Regras de autenticação, autorização e chaves

1. Funcionalidades financeiras/administrativas não devem depender de `anon key` como mecanismo de autorização.
2. O frontend pode usar sessão autenticada quando necessário, mas a regra soberana fica no banco/RPC.
3. `service_role` é proibido em frontend, bundle, navegador, mobile app, logs ou repositório.
4. RPC sensível deve conceder `EXECUTE` somente para roles necessárias, normalmente `authenticated`.
5. `anon` deve ser revogado explicitamente quando a função for sensível.
6. RLS deve permanecer habilitada em tabelas multitenant.
7. Qualquer bypass de RLS via `security definer` deve compensar com validação explícita de tenant/perfil/recurso.
8. Dados de cliente e regras financeiras devem seguir mínimo necessário.

---

## 16. Matriz de DML obrigatória

Toda fase crítica deve declarar uma matriz de DML.

Exemplo para Fase 4A JSON-first:

| Tabela | SELECT | INSERT | UPDATE | DELETE |
|---|---:|---:|---:|---:|
| `public.mesa_simulacoes` | Sim | Não | Não | Não |
| `public.mesa_cliente_fluxo_parcelas` | Sim/contagem | Não | Não | Não |
| `public.mesa_cliente_fluxo_operacoes` | Sim/contagem | Não | Não | Não |
| `public.empreendimentos` | Sim | Não | Não | Não |
| `public.corretores` | Sim | Não | Não | Não |

Critério: se a fase é dry-run, qualquer `INSERT`, `UPDATE` ou `DELETE` em tabela financeira é falha automática.

---

## 17. Padrão para migrations

Toda migration deve seguir:

- branch confirmada antes de criar arquivo;
- nunca trabalhar em `main` sem autorização explícita;
- timestamp único;
- nome com fase e objetivo;
- não usar nomes genéricos;
- não deixar migration experimental na pasta oficial;
- ter documentação/handoff;
- ter teste compatível.

Exemplo bom:

```text
20260518XXXXXX_mesa_cliente_fase_4a_agenda_financeira_dry_run.sql
```

Exemplos ruins:

```text
teste.sql
ajuste_final.sql
nova_rpc.sql
fase_4a_agenda.sql
```

Nome ruim é dívida técnica com perfume barato.

### 17.1 Migration obsoleta

Migration errada, experimental ou substituída não pode ficar em:

```text
supabase/migrations
```

Ela deve ir para:

```text
docs/mesa-cliente/rascunhos-sql/
```

Com aviso no topo:

```text
RASCUNHO OBSOLETO — NÃO APLICAR EM PRODUÇÃO.
Substituído pela migration oficial: <nome_da_migration>.
Preservado apenas para histórico técnico.
```

Migration problemática na pasta oficial é granada sem pino em gaveta de talher.

---

## 18. Rollback: teste, migration aplicada e operação

Existem três tipos de rollback:

### 18.1 Rollback de teste

Usa:

```sql
BEGIN;
-- teste
ROLLBACK;
```

Serve para provar comportamento sem persistir alteração.

### 18.2 Rollback de migration aplicada

Quando uma migration já foi aplicada no Supabase, não tratar como se pudesse simplesmente “apagar o arquivo”. O padrão é:

1. Criar migration corretiva posterior.
2. Documentar impacto.
3. Validar estado final.
4. Atualizar handoff.

### 18.3 Rollback operacional

Para produção:

- backup/snapshot quando disponível;
- plano de reversão;
- queries de validação;
- critério de parada;
- responsável pela aprovação.

---

## 19. Padrão de testes

Toda entrega crítica precisa ter:

- teste positivo;
- teste negativo;
- teste de permissão;
- teste cross-tenant;
- teste anon bloqueado;
- teste payload malicioso;
- teste rollback;
- teste de ausência de efeito colateral;
- comando executável;
- saída esperada;
- resultado que bloqueia.

Para dry-run, o teste deve provar:

```text
count_before = count_after
```

em todas as tabelas críticas envolvidas.

Exemplo:

```sql
select count(*) from public.mesa_cliente_fluxo_parcelas;
select count(*) from public.mesa_cliente_fluxo_operacoes;
```

Se alterou linha em fase dry-run, falhou.

### 19.1 Formato obrigatório de documentação de teste

Cada teste deve informar:

- arquivo do teste;
- comando para executar;
- resultado esperado;
- resultado que bloqueia;
- tabelas monitoradas antes/depois;
- se usa `BEGIN` + `ROLLBACK`;
- se requer usuário autenticado simulado;
- se exige dados mínimos existentes.

---

## 20. Registro formal de decisão técnica — ADR

Toda decisão relevante deve virar ADR.

Modelo:

```md
# ADR-000X — Título da decisão

Data:
Fase:
Branch:
Status: proposta | aprovada | substituída | obsoleta

## Decisão

## Motivo

## Alternativas consideradas

## Riscos

## Impacto

## Critério de aceite

## Critério de bloqueio

## Consequências
```

Exemplo:

```md
# ADR-0001 — Fase 4A será JSON-first sem persistência

Decisão:
A Fase 4A apenas gera agenda financeira em JSON e não faz DML em mesa_cliente_fluxo_parcelas.

Motivo:
Ambiente de produção único, sem staging separado, com dados financeiros sensíveis.

Alternativas:
1. Persistir direto na 4A.
2. JSON-first na 4A e persistência na 4B.

Decisão aprovada:
Alternativa 2.
```

---

## 21. Pacote obrigatório de evidências

Antes de qualquer implementação crítica, a IA/dev deve listar:

```text
Branch consultada:
Commit consultado:
Arquivos lidos:
Migrations existentes:
Migrations aplicadas no banco:
Tabelas verificadas:
Colunas verificadas:
Enums verificados:
RPCs/helpers verificados:
RLS/policies verificadas:
Grants verificados:
Triggers verificados:
Testes existentes:
Pontos não confirmados:
Decisão/ADR relacionada:
```

Sem pacote de evidências, a resposta não está pronta para código.

---

## 22. Protocolo de conflito entre IAs/conversas

Se duas conversas criarem soluções diferentes:

1. Nenhuma é aplicada automaticamente.
2. As duas são comparadas.
3. Os acertos são preservados.
4. Os riscos são listados.
5. Uma versão canônica é escolhida.
6. A outra vira rascunho obsoleto.
7. A decisão vira ADR.
8. Arquivos obsoletos saem de `supabase/migrations`.
9. O plano oficial é atualizado.

Só pode existir uma solução canônica por fase.

---

## 23. Regras específicas do FECH.AI / MesaCliente

### 23.1 Proibições estruturais sem autorização explícita

Não mexer em:

- frontend;
- parser;
- Worker;
- Make;
- n8n;
- main;
- motor financeiro atual fora da migration proposta;
- regras centrais do app;
- lógica multitenant/multiempresa;
- fluxo de autenticação;
- RLS/policies fora do escopo aprovado.

### 23.2 Regras multitenant/multiempresa

Obrigatório:

- tenant/empresa resolvido pelo banco;
- validação de `auth.uid()`;
- validação de usuário ativo;
- validação de perfil;
- validação de empresa;
- validação de empreendimento;
- validação de simulação;
- validação de propriedade do recurso;
- testes cross-tenant quando houver dado suficiente.

Proibido:

- `empresa_id` soberano vindo do frontend;
- confiar em payload para autorização;
- expor dados de outra empresa;
- usar filtros apenas no client como segurança;
- criar RPC fraca que apenas “consulta por id” sem validar dono/empresa/perfil.

---

## 24. Plano financeiro oficial da Engenharia Financeira

### 24.1 Branch oficial

```text
feature/mesa-cliente-engenharia-financeira
```

### 24.2 Fases oficiais

| Fase | Nome | Regra |
|---|---|---|
| 4A | Gerar agenda financeira em JSON | Sem persistir |
| 4B | Persistir agenda financeira | Com lock, idempotência e auditoria |
| 4C | Leitura cliente-safe | Sem VPL/prêmio/comissão/política |
| 5A | Simular impacto financeiro | Usando agenda persistida |
| 5B | Registrar operação financeira | DML controlado e auditável |
| 5C | Confirmar/cancelar operação | Fluxo de aprovação/cancelamento |
| Depois | Integração front/BFF | Só após banco validado |

### 24.3 Decisão canônica da Fase 4A

A Fase 4A é:

```text
JSON-first / Dry-run administrativo
```

Ela não grava nada em:

- `public.mesa_cliente_fluxo_parcelas`
- `public.mesa_cliente_fluxo_operacoes`

Ela apenas:

- valida segurança;
- valida tenant/empresa;
- valida simulação;
- valida empreendimento;
- valida perfil;
- normaliza fluxo;
- resolve datas;
- classifica parcelas;
- retorna agenda financeira em JSON.

### 24.4 RPC oficial da Fase 4A

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

Obrigatório:

```sql
language plpgsql
security definer
set search_path = public
```

### 24.5 Permitido na Fase 4A

- `auth.uid()` obrigatório;
- usuário ativo;
- tenant/empresa resolvido pelo banco;
- simulação validada;
- empreendimento validado;
- perfil validado;
- `empresa_id` do payload ignorado/rejeitado;
- normalização de parcelas;
- resolução de datas;
- classificação de periodicidade simbólica;
- retorno JSON administrativo;
- testes 07A/07B com `BEGIN` + `ROLLBACK`;
- contagem antes/depois para provar zero DML financeiro.

### 24.6 Proibido na Fase 4A

- `INSERT` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` em `mesa_cliente_fluxo_parcelas`;
- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `INSERT` em `mesa_cliente_fluxo_operacoes`;
- criar operação financeira;
- confirmar operação;
- cancelar operação;
- calcular VPL operacional definitivo;
- calcular prêmio;
- calcular comissão;
- expor política interna;
- expor taxa interna;
- mexer no frontend;
- mexer no parser;
- mexer no Worker/Make/n8n;
- conceder `EXECUTE` para `anon`;
- usar `empresa_id` do payload como verdade.

### 24.7 Retorno esperado da Fase 4A

Formato recomendado:

```json
{
  "ok": true,
  "fase": "4A",
  "modo": "admin",
  "cliente_safe": false,
  "simulacao_id": "uuid",
  "empresa_id": "uuid derivado do banco",
  "empreendimento_id": "uuid derivado do banco",
  "data_ato": "2026-05-17",
  "agenda": [
    {
      "ordem": 1,
      "grupo": "entrada",
      "descricao": "Ato",
      "valor": 50000,
      "data_original": "2026-05-17",
      "data_atual": "2026-05-17",
      "origem_data": "tabela_oficial",
      "regra_data": null,
      "eh_periodicidade_simbolica": false,
      "pode_receber_vpl": false,
      "pode_receber_antecipacao": false,
      "pode_receber_postergacao": false
    }
  ],
  "totais": {
    "quantidade_itens": 1,
    "quantidade_parcelas_reais": 1,
    "quantidade_periodicidades_simbolicas": 0,
    "valor_total_agenda": 50000
  }
}
```

Sem:

- VPL;
- prêmio;
- comissão;
- política;
- `politica_id`;
- taxa interna;
- margem;
- score interno;
- payload bruto sensível.

Importante: `cliente_safe = false` na Fase 4A, porque ela é administrativa/internal-safe. Cliente-safe nasce na Fase 4C.

### 24.8 Regras de datas

- Data do ato será a base para calcular parcelas.
- Se a tabela trouxer data oficial, a data oficial prevalece.
- Se trouxer apenas mês/ano, usar o dia do ato.
- Se o mês não tiver o dia do ato, usar o último dia válido do mês.
- Chaves/parcela única devem vir da tabela ou cabeçalho.
- Chaves podem ser calculadas por regra de cabeçalho 30 ou 60 dias antes do financiamento.
- Periodicidade simbólica não entra como parcela negociável.

### 24.9 Regra correta de `origem_data` e `regra_data`

Valores permitidos para `origem_data`:

- `tabela_oficial`
- `tabela_comercial_data`
- `tabela_comercial_mes`
- `cabecalho_regra`
- `calculada_ato`
- `estimada`
- `manual`

Para chaves 30/60 dias:

```json
{
  "origem_data": "cabecalho_regra",
  "regra_data": "cabecalho_60_dias"
}
```

Nunca:

```json
{
  "origem_data": "cabecalho_60_dias"
}
```

`cabecalho_30_dias` e `cabecalho_60_dias` são regra de data, não origem de data.

### 24.10 Testes oficiais da Fase 4A

Arquivos esperados:

```text
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_financeira_json_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_financeira_json_negativos_rollback.sql
```

#### 07A — positivo

Deve validar:

- auth válido;
- simulação válida;
- empresa derivada do banco;
- empreendimento validado;
- agenda retornada em JSON;
- data oficial prevalecendo;
- mês/ano usando dia do ato;
- fevereiro com último dia válido;
- chaves com `origem_data = cabecalho_regra`;
- `regra_data = cabecalho_30_dias` ou `cabecalho_60_dias`;
- periodicidade simbólica não negociável;
- retorno sem VPL/prêmio/comissão/política;
- nenhuma linha inserida/alterada/removida em `mesa_cliente_fluxo_parcelas`;
- nenhuma linha inserida/alterada/removida em `mesa_cliente_fluxo_operacoes`.

Resultado esperado:

```text
todos os blocos críticos = PASS
counts_before = counts_after
nenhum campo sensível retornado
```

#### 07B — negativo

Deve validar:

- `anon` sem `EXECUTE`;
- sem `auth.uid()` bloqueia;
- usuário inativo bloqueia;
- simulação inexistente bloqueia;
- cross-tenant bloqueia;
- perfil sem permissão bloqueia;
- payload malformado bloqueia;
- valor negativo bloqueia;
- grupo inválido bloqueia;
- `empresa_id` no payload é ignorado/rejeitado;
- VPL/prêmio/comissão no payload são descartados ou rejeitados;
- sem DML financeiro.

---

## 25. Fase 4B — persistência somente depois da 4A validada

A Fase 4B só pode começar depois que a Fase 4A passar nos testes.

RPC futura sugerida:

```sql
public.mesa_cliente_persistir_agenda_financeira_admin(...)
```

Ela poderá gravar em:

```text
public.mesa_cliente_fluxo_parcelas
```

Mas com travas obrigatórias:

- bloquear se existir operação financeira confirmada;
- usar advisory lock por `simulacao_id`;
- recriar agenda com idempotência;
- registrar auditoria;
- não apagar histórico confirmado;
- não aceitar `empresa_id` do payload;
- validar auth/tenant/perfil/recurso;
- testes positivos/negativos/rollback/cross-tenant;
- validação pós-aplicação.

---

## 26. Decisão sobre migrations antigas da Fase 4A

As migrations persistentes anteriores devem ser tratadas como rascunho técnico, não como Fase 4A oficial.

Não aplicar como canônicas se fizerem:

- `INSERT` em `mesa_cliente_fluxo_parcelas`;
- `UPDATE` em `mesa_cliente_fluxo_parcelas`;
- `DELETE` em `mesa_cliente_fluxo_parcelas`;
- criação/recriação persistente de agenda na Fase 4A;
- operação financeira;
- mistura entre gerar agenda e gravar agenda;
- `cliente_safe = true` em RPC administrativa.

Arquivos problemáticos devem sair de:

```text
supabase/migrations
```

ou ser revertidos/congelados antes de merge/aplicação.

---

## 27. Padrão de documentação/handoff de fase

Toda fase deve ter documento com:

- nome da fase;
- objetivo;
- escopo;
- fora de escopo;
- branch;
- commit(s);
- arquivos esperados;
- funções/RPCs esperadas;
- tabelas tocadas;
- DML permitido/proibido;
- grants/RLS/policies;
- segurança;
- classificação de dados;
- testes;
- comando de execução;
- resultado esperado;
- critério de aceite;
- critério de bloqueio;
- riscos remanescentes;
- próxima fase.

Sem handoff, não existe continuidade segura.

---

## 28. Padrão de resposta da IA/dev em entregas críticas

Toda resposta técnica crítica deve conter:

1. **Resumo objetivo.**
2. **O que está verificado.**
3. **O que foi informado pelo Wagner.**
4. **O que é inferência.**
5. **O que não está confirmado.**
6. **Risco e classificação.**
7. **Contrato técnico.**
8. **Escopo permitido.**
9. **Fora de escopo.**
10. **Arquivos/tabelas/RPCs afetados.**
11. **Matriz de DML.**
12. **Segurança/RLS/grants/auth.**
13. **Plano de teste.**
14. **Critério de aceite.**
15. **Critério de bloqueio.**
16. **Próximo passo único.**

---

## 29. Regra final de conduta

A IA/dev deve sempre agir assim:

1. Ler contexto e arquivos relevantes.
2. Declarar o que entendeu.
3. Declarar riscos.
4. Declarar o que não sabe.
5. Propor contrato.
6. Aguardar validação se houver risco alto/crítico.
7. Só então criar código.
8. Criar testes junto com implementação.
9. Informar exatamente o que mudou.
10. Informar o que não foi feito.

É proibido:

- criar solução no impulso;
- misturar fases;
- assumir schema;
- assumir branch;
- assumir ambiente;
- assumir que algo já foi aplicado;
- inventar tabela/coluna/função;
- responder com certeza sem evidência;
- criar plano alternativo sem declarar conflito;
- deixar rascunho perigoso em pasta oficial.

---

## 30. Veredito oficial

Este documento passa a ser o padrão oficial de trabalho para FECH.AI / MesaCliente.

Quando qualquer conversa, IA ou dev começar a acelerar demais:

```text
Pare.
Volte ao protocolo.
Valide contrato.
Busque evidência.
Execute somente o próximo passo seguro.
```

O objetivo não é andar mais devagar. É parar de pagar pedágio para retrabalho.

Engenharia boa não é a que escreve mais SQL. É a que sabe quando ainda não deve escrever SQL.
