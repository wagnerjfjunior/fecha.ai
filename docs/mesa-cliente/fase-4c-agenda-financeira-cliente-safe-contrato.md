# FECH.AI / MesaCliente — Fase 4C

## Contrato da agenda financeira cliente-safe

**Status:** contrato inicial aberto  
**Data:** 2026-05-18  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Escopo:** Engenharia Financeira — MesaCliente  
**Documento complementar ao Protocolo Mestre FECH.AI / MesaCliente v1.2**

---

## 1. Decisão oficial

A Fase 4C começa somente após a validação da Fase 4B.

A Fase 4B foi aprovada em rollback transacional com os testes 08A, 08B, 08C e 08D.

A Fase 4C tem um objetivo único:

> Criar uma leitura segura, cliente-safe, da agenda financeira persistida.

A Fase 4C não cria, não altera e não confirma operação financeira.

---

## 2. Frase de controle

> **4C = leitura cliente-safe da agenda financeira persistida, sem expor dado sensível, sem alterar agenda, sem criar operação financeira e sem mexer no frontend antes dos testes de segurança.**

---

## 3. Hierarquia documental

Este documento não substitui o Protocolo Mestre nem a evidência da 4B.

Ordem de referência:

1. `docs/protocolos/protocolo-mestre-fechai-mesacliente-v1.2.md`
2. `docs/mesa-cliente/adr/ADR-0001-fase-4a-json-first-sem-persistencia.md`
3. `docs/mesa-cliente/fase-4a-agenda-financeira-json-first-canonica.md`
4. `docs/mesa-cliente/fase-4a-validacao-unica-e-transicao-json-first.md`
5. `docs/mesa-cliente/fase-4b-validacao-final-evidencias.md`
6. Este documento: `docs/mesa-cliente/fase-4c-agenda-financeira-cliente-safe-contrato.md`

---

## 4. Escopo da Fase 4C

A Fase 4C deve entregar uma RPC de leitura cliente-safe da agenda financeira já persistida na Fase 4B.

Escopo permitido:

- ler a agenda financeira ativa da simulação;
- ler as parcelas vinculadas à agenda ativa;
- montar um JSON seguro para apresentação ao cliente;
- indicar `cliente_safe = true`;
- expor somente campos comerciais permitidos;
- respeitar auth, tenant, empresa, empreendimento, simulação e perfil;
- bloquear `anon`, salvo decisão formal futura;
- validar cross-tenant;
- validar simulação inexistente;
- validar agenda inexistente;
- validar que o payload não expõe campos administrativos ou sensíveis;
- usar testes com `BEGIN` + `ROLLBACK`.

---

## 5. Fora de escopo da Fase 4C

A Fase 4C não pode:

- alterar frontend;
- alterar BFF;
- alterar parser;
- alterar Worker;
- alterar Make/n8n;
- recalcular agenda a partir do payload bruto;
- persistir nova agenda;
- substituir agenda;
- criar operação financeira;
- confirmar operação financeira;
- cancelar operação financeira;
- calcular ou expor VPL;
- expor prêmio;
- expor comissão;
- expor política comercial interna;
- expor regra interna de elegibilidade;
- aceitar `empresa_id` do frontend como autoridade;
- conceder `EXECUTE` para `anon` sem decisão formal.

---

## 6. RPC candidata da Fase 4C

Nome recomendado:

```sql
public.mesa_cliente_obter_agenda_financeira_cliente_safe(
  p_simulacao_id uuid
)
returns jsonb
```

Padrão obrigatório:

```sql
security definer
set search_path = public
```

Grants esperados:

```sql
revoke all on function public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid) from public;
revoke all on function public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid) from anon;
grant execute on function public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid) to authenticated;
```

A liberação para `anon` fica proibida nesta fase.

---

## 7. Retorno esperado da RPC 4C

Formato inicial recomendado:

```json
{
  "ok": true,
  "fase": "4C_CLIENTE_SAFE",
  "cliente_safe": true,
  "visao": "cliente",
  "simulacao_id": "uuid",
  "agenda_id": "uuid",
  "status_agenda": "ativa",
  "resumo": {
    "valor_total": 0,
    "qtd_parcelas": 0,
    "grupos": []
  },
  "parcelas": [],
  "avisos": []
}
```

---

## 8. Campos permitidos para cliente-safe

Campos permitidos na leitura cliente-safe:

### Agenda

- `agenda_id`;
- `simulacao_id`;
- `status_agenda`;
- `valor_total`;
- `qtd_parcelas`;
- resumo por grupo, desde que sem regra interna sensível.

### Parcelas

- `grupo`;
- `descricao` comercial limpa;
- `parcela_numero`;
- `parcelas_total_item`;
- `data_vencimento`;
- `valor`;
- `negociavel`, com cuidado;
- aviso neutro quando não negociável.

### Avisos neutros

Exemplos permitidos:

- `Algumas condições podem depender de validação comercial.`
- `Itens específicos podem não estar disponíveis para negociação direta.`
- `A proposta está sujeita à validação da incorporadora.`

---

## 9. Campos proibidos para cliente-safe

A RPC cliente-safe não pode expor:

- `empresa_id` como autoridade de cliente;
- `empreendimento_id` se não houver necessidade comercial explícita;
- `created_by`;
- `updated_by`;
- `criado_por`;
- `atualizado_por`;
- `metadata` bruto;
- `snapshot_payload`;
- payload bruto da tabela comercial;
- checksum, salvo decisão formal;
- versão interna, salvo decisão formal;
- políticas internas;
- taxa interna;
- VPL;
- prêmio;
- comissão;
- desconto calculado interno;
- acréscimo calculado interno;
- economia líquida interna;
- regras de elegibilidade;
- motivos de bloqueio internos que revelem política comercial sensível;
- dados de auditoria;
- dados de operação financeira.

---

## 10. Tratamento de `negociavel` e `motivos_bloqueio`

A Fase 4C pode expor `negociavel`, mas não deve expor o motivo interno bruto.

Exemplo seguro:

```json
{
  "grupo": "periodicidade",
  "negociavel": false,
  "aviso": "Item apenas informativo, sem negociação direta."
}
```

Exemplo proibido:

```json
{
  "grupo": "periodicidade",
  "motivos_bloqueio": ["periodicidade_simbolica_nao_negociavel"]
}
```

O motivo interno pode existir no banco, mas não deve sair no cliente-safe.

---

## 11. Segurança obrigatória

A RPC 4C deve validar:

- `auth.uid()` obrigatório;
- usuário/corretor ativo;
- simulação existente;
- simulação pertence à empresa correta;
- agenda ativa pertence à simulação;
- agenda pertence à mesma empresa da simulação;
- parcelas pertencem à mesma agenda, simulação e empresa;
- perfil autorizado;
- `anon` sem execute;
- cross-tenant bloqueado.

A RPC não deve aceitar `empresa_id` como parâmetro.

---

## 12. Perfis autorizados

O sufixo cliente-safe não significa acesso público.

Perfis candidatos autorizados:

- root/admin global;
- admin local;
- gestor/coordenador;
- corretor dono da simulação, se o modelo operacional permitir;
- usuário interno autenticado com vínculo válido à empresa e à simulação.

A regra final deve ser validada no preflight e nos testes.

---

## 13. Testes oficiais da Fase 4C

Sugestão de arquivos:

```text
supabase/tests/mesa-cliente/engenharia-financeira/09_preflight_agenda_financeira_cliente_safe_readonly.sql
supabase/tests/mesa-cliente/engenharia-financeira/09a_validacao_agenda_financeira_cliente_safe_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/09b_validacao_agenda_financeira_cliente_safe_negativos_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/09c_validacao_agenda_financeira_cliente_safe_sem_vazamento_rollback.sql
```

---

## 14. Critério de aceite da Fase 4C

A Fase 4C só será aprovada se:

- RPC existir com `security definer` e `search_path = public`;
- `anon` não tiver execute;
- `authenticated` tiver execute;
- leitura positiva retornar `cliente_safe = true`;
- retorno não expuser campos proibidos;
- agenda ativa for lida corretamente;
- parcelas forem lidas corretamente;
- periodicidade simbólica for apresentada de forma neutra;
- cross-tenant for bloqueado;
- simulação inexistente for bloqueada;
- agenda inexistente for tratada sem vazar dado interno;
- testes provarem ausência de DML;
- tudo rodar com `BEGIN` + `ROLLBACK`.

---

## 15. Preflight obrigatório antes da migration 4C

Antes de criar qualquer migration da RPC 4C, deve ser executado um preflight read-only para validar:

- colunas reais de `mesa_cliente_agendas_financeiras`;
- colunas reais de `mesa_cliente_fluxo_parcelas`;
- colunas reais de `mesa_simulacoes`;
- grants e RLS das tabelas envolvidas;
- existência da RPC 4B;
- existência de dados suficientes para fixture transacional;
- campos sensíveis que não podem aparecer no retorno;
- funções auxiliares de auth/perfil existentes.

---

## 16. Critério de bloqueio

Bloquear a Fase 4C se qualquer um destes pontos ocorrer:

- tentativa de criar frontend antes dos testes;
- tentativa de expor payload bruto;
- tentativa de expor metadata bruta;
- tentativa de expor VPL, prêmio, comissão ou política;
- tentativa de aceitar `empresa_id` como parâmetro;
- tentativa de liberar `anon`;
- tentativa de misturar 4C com 5A/5B/5C;
- falta de evidência de teste rollback.

---

## 17. Próximo passo imediato

Criar e executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/09_preflight_agenda_financeira_cliente_safe_readonly.sql
```

Somente após o preflight ser enviado e validado, criar a migration da RPC 4C.

---

## 18. Decisão final

A Fase 4C está aberta em modo contrato.

Ainda não está liberado criar migration da RPC cliente-safe antes do preflight read-only.

Próxima ação permitida:

> Executar o preflight read-only da Fase 4C e enviar o resultset completo.
