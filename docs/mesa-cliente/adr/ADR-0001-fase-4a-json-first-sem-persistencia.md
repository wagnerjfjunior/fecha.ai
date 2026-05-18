# ADR-0001 — Fase 4A JSON-first sem persistência

**Status:** Aprovada  
**Data:** 2026-05-18  
**Fase:** Engenharia Financeira / MesaCliente / Fase 4A  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Complementa:** `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.1.md`  

---

## 1. Contexto

Durante a preparação da Fase 4A surgiram versões concorrentes de implementação da agenda financeira.

As versões iniciais avançavam para persistência em `mesa_cliente_fluxo_parcelas` ainda na Fase 4A. Isso criava risco operacional porque o ambiente atual é sensível, multiempresa, com dados financeiros e sem staging separado.

A equipe decidiu consolidar uma linha única para evitar retrabalho, drift entre conversas/IA/devs e migrations perigosas dentro de `supabase/migrations`.

---

## 2. Decisão

A Fase 4A será obrigatoriamente **Dry-run / JSON-first**.

A RPC oficial da Fase 4A deve gerar uma agenda financeira normalizada em JSON, sem gravar, apagar ou atualizar linhas nas tabelas financeiras.

Nome oficial da RPC:

```sql
public.mesa_cliente_gerar_agenda_financeira_admin(
  p_simulacao_id uuid,
  p_data_ato date,
  p_fluxo_json jsonb,
  p_payload_tabela jsonb default '{}'::jsonb
)
returns jsonb
```

O sufixo `_admin` significa uso interno/administrativo seguro. Não significa cliente-safe final.

---

## 3. Motivo

A decisão reduz risco porque:

- evita DML em produção única antes de validar a regra;
- separa claramente validação de agenda e persistência;
- impede que a Fase 4A invada responsabilidades da Fase 4B;
- permite testar parsing financeiro, normalização, datas e permissões sem sujar banco;
- cria critério objetivo de aceite: zero efeito colateral nas tabelas financeiras.

---

## 4. Alternativas consideradas

### Alternativa A — Persistir direto na Fase 4A

A RPC geraria e gravaria parcelas em `mesa_cliente_fluxo_parcelas`.

**Rejeitada.**

Motivo: risco de apagar/recriar parcelas antes da regra estar madura, mistura de fases e risco operacional em produção única.

### Alternativa B — JSON-first na Fase 4A e persistência na Fase 4B

A RPC gera agenda normalizada em JSON, prova regras e segurança, e só depois outra fase cuida da persistência.

**Aprovada.**

---

## 5. Escopo da Fase 4A

Permitido:

- validar `auth.uid()`;
- validar usuário ativo;
- validar tenant/empresa pelo banco;
- validar simulação;
- validar empreendimento;
- validar perfil/permissão;
- ignorar ou rejeitar `empresa_id` vindo do payload;
- resolver datas;
- normalizar parcelas;
- classificar periodicidade simbólica;
- retornar JSON administrativo;
- criar teste positivo e negativo com `BEGIN` + `ROLLBACK`;
- provar zero DML em tabelas financeiras.

Proibido:

- `INSERT`, `UPDATE` ou `DELETE` em `mesa_cliente_fluxo_parcelas`;
- `INSERT`, `UPDATE` ou `DELETE` em `mesa_cliente_fluxo_operacoes`;
- criar operação financeira;
- confirmar/cancelar operação;
- calcular ou expor VPL;
- calcular ou expor prêmio;
- calcular ou expor comissão;
- expor política interna;
- alterar frontend;
- alterar parser;
- alterar Worker/Make/n8n;
- conceder `EXECUTE` para `anon`;
- usar `empresa_id` do frontend como autoridade.

---

## 6. Matriz de DML da Fase 4A

| Tabela | SELECT | INSERT | UPDATE | DELETE |
|---|---:|---:|---:|---:|
| `mesa_simulacoes` | Sim | Não | Não | Não |
| `empreendimentos` ou tabela equivalente | Sim | Não | Não | Não |
| tabela de usuários/perfis/contexto | Sim | Não | Não | Não |
| `mesa_cliente_fluxo_parcelas` | Opcional para count/validação | Não | Não | Não |
| `mesa_cliente_fluxo_operacoes` | Opcional para count/validação | Não | Não | Não |

Qualquer DML em tabela financeira na Fase 4A invalida a entrega.

---

## 7. Testes obrigatórios

Arquivos esperados:

```txt
supabase/tests/mesa-cliente/engenharia-financeira/07a_validacao_agenda_financeira_json_first_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/07b_validacao_agenda_financeira_json_first_negativos_rollback.sql
```

O teste 07A deve provar:

- RPC executa com usuário autorizado;
- agenda JSON é gerada;
- datas são resolvidas conforme contrato;
- data oficial prevalece;
- mês/ano usa o dia do ato;
- mês sem o dia do ato usa último dia válido;
- periodicidade simbólica não é negociável;
- retorno não expõe dado sensível;
- `count_before = count_after` em `mesa_cliente_fluxo_parcelas`;
- `count_before = count_after` em `mesa_cliente_fluxo_operacoes`.

O teste 07B deve provar bloqueios:

- sem auth;
- `anon`;
- simulação inexistente;
- cross-tenant;
- payload nulo/malformado;
- valor negativo;
- grupo desconhecido;
- tentativa de soberania via `empresa_id` no payload;
- tentativa de tornar periodicidade simbólica negociável.

---

## 8. Consequências

- Documentos antigos que falam em persistência na Fase 4A devem ser considerados obsoletos ou ajustados.
- Nenhuma migration persistente antiga da Fase 4A deve permanecer como canônica em `supabase/migrations`.
- A Fase 4B será responsável por persistência com lock, idempotência e auditoria.
- A Fase 4C será responsável por leitura cliente-safe.

---

## 9. Critério de aceite

A decisão estará corretamente implementada quando:

1. existir migration canônica da RPC JSON-first;
2. não houver DML financeiro na RPC;
3. `anon` estiver bloqueado;
4. `authenticated` tiver grant restrito somente na RPC;
5. testes 07A/07B existirem com `BEGIN` + `ROLLBACK`;
6. testes provarem ausência de efeito colateral;
7. documentos antigos conflitantes estiverem marcados como substituídos ou atualizados.

---

## 10. Frase de controle

> Primeiro contrato. Depois validação. Depois dry-run. Depois persistência.
