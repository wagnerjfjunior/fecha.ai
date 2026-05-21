# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 7 — Contrato técnico: aplicação controlada de operação financeira na agenda

**Branch:** `feature/mesa-cliente-pos-fase-6-proxima-fase`

**Status:** contrato aberto para implementação controlada.

**Base:** `main` pós-merge da Fase 6 e smoke 14F.

---

## 1. Objetivo da Fase 7

A Fase 7 deve criar a camada segura para aplicar, de forma controlada, uma operação financeira já registrada sobre a agenda financeira do MesaCliente.

Até a Fase 6, o sistema consegue:

1. Persistir agenda financeira base;
2. Registrar operação financeira simulada;
3. Resumir operação na visão administrativa;
4. Resumir operação na visão cliente-safe;
5. Validar catálogo pós-produção das RPCs da Fase 6.

A Fase 7 muda o patamar de risco: ela deixa de apenas registrar/resumir e passa a efetivar alteração real em parcelas/agendas/operação.

Por isso, esta fase deve ser tratada como fase de DML financeiro controlado.

---

## 2. Escopo positivo

A Fase 7 deve entregar uma RPC administrativa para aplicar uma operação financeira previamente registrada.

RPC proposta:

```text
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid, jsonb)
```

Assinatura:

```sql
public.mesa_cliente_aplicar_operacao_financeira_admin(
  p_operacao_id uuid,
  p_parametros jsonb default '{}'::jsonb
) returns jsonb
```

Responsabilidades esperadas:

- validar autenticação por `auth.uid()`;
- validar corretor/usuário ativo;
- validar tenant/empresa em banco;
- validar perfil autorizado;
- validar operação existente;
- validar operação vinculada a agenda e simulação;
- validar que a operação pertence ao mesmo tenant/empresa da agenda, parcelas e simulação;
- validar que a operação está em status aplicável;
- validar que a operação ainda não foi aplicada;
- aplicar a mutação financeira de forma transacional;
- marcar operação como aplicada/confirmada conforme contrato final;
- atualizar parcelas impactadas;
- preservar rastreabilidade em `metadata`;
- retornar payload de auditoria e resumo da aplicação;
- impedir reexecução destrutiva.

---

## 3. Fora de escopo nesta fase

A Fase 7 **não** deve:

- alterar parser;
- alterar Worker;
- alterar Make/n8n;
- alterar UI;
- receber regra soberana do frontend;
- aceitar taxa, VPL, empresa, tenant, política ou valor final como autoridade vinda da tela;
- recalcular engenharia financeira fora do banco;
- permitir operação sem autenticação;
- permitir aplicação cross-tenant;
- permitir corretor comum aplicar operação de outro corretor;
- permitir DML direto nas tabelas financeiras fora da RPC;
- criar regra de publicação cliente-safe nova;
- substituir a Fase 6;
- remover compatibilidade com 4B, 5B, 5C e 6.

---

## 4. Tabelas envolvidas

Leitura real do schema apontou as tabelas críticas:

```text
public.mesa_cliente_fluxo_operacoes
public.mesa_cliente_fluxo_parcelas
public.mesa_cliente_agendas_financeiras
public.mesa_simulacoes
public.corretores
```

Tabelas de operação e parcelas possuem RLS ativo e bloqueiam DML direto por policies:

```text
mcfo_no_direct_insert
mcfo_no_direct_update
mcfo_no_direct_delete
mcfp_no_direct_insert
mcfp_no_direct_update
mcfp_no_direct_delete
```

Conclusão: a aplicação deve ocorrer via RPC `SECURITY DEFINER`, com validação interna rigorosa.

---

## 5. Campos críticos já identificados

### 5.1 Operações

Tabela:

```text
public.mesa_cliente_fluxo_operacoes
```

Campos críticos:

```text
id
empresa_id
simulacao_id
empreendimento_id
politica_id
tipo_operacao
grupo_origem
grupo_destino
parcela_origem_id
parcela_destino_id
valor_base
valor_movido
data_origem
data_destino
taxa_ano_pct
vpl_aplicado_pct
desconto_calculado
acrescimo_calculado
economia_liquida
premio_corretor_pct
status_premio
visivel_cliente
confirmado
confirmado_por
confirmado_em
status_operacao
agenda_id
checksum_operacao
cancelado_por
cancelado_em
motivo_cancelamento
metadata
criado_por
created_at
updated_at
```

### 5.2 Parcelas

Tabela:

```text
public.mesa_cliente_fluxo_parcelas
```

Campos críticos:

```text
id
empresa_id
simulacao_id
empreendimento_id
unidade_estoque_id
agenda_id
grupo
descricao
valor_original
valor_atual
data_original
data_atual
origem_data
regra_data
ordem
eh_periodicidade_simbolica
pode_receber_vpl
pode_receber_antecipacao
pode_receber_postergacao
metadata
criado_por
atualizado_por
created_at
updated_at
```

### 5.3 Agenda

Tabela:

```text
public.mesa_cliente_agendas_financeiras
```

Campos críticos:

```text
id
empresa_id
simulacao_id
empreendimento_id
unidade_estoque_id
versao
status
origem
checksum
payload_origem
totais
metadata
criado_por
substituida_em
substituida_por
created_at
updated_at
```

---

## 6. Regra de autoridade

A RPC da Fase 7 deve considerar o banco como autoridade.

O frontend pode enviar apenas parâmetros operacionais não soberanos, por exemplo:

```json
{
  "origem": "mesa_cliente_ui",
  "motivo": "aplicacao_confirmada_pelo_gestor",
  "observacao": "texto livre opcional"
}
```

Devem ser bloqueados, se enviados em `p_parametros`, campos como:

```text
empresa_id
tenant_id
corretor_id
simulacao_id
agenda_id
empreendimento_id
politica_id
parcela_origem_id
parcela_destino_id
valor_base
valor_movido
taxa_ano_pct
vpl_aplicado_pct
premio_corretor_pct
desconto_calculado
acrescimo_calculado
economia_liquida
status_operacao
confirmado
visivel_cliente
metadata
```

Motivo: esses campos são soberanos e devem ser lidos/calculados no banco.

---

## 7. Perfis autorizados

A aplicação financeira é operação administrativa sensível.

Perfis esperados:

- `admin_global`;
- `admin_local` da mesma empresa;
- `gestor` da mesma empresa;
- `coordenador` da mesma empresa, se já aceito pela matriz de perfis;
- corretor dono somente se o protocolo final permitir explicitamente.

Decisão inicial segura: **corretor comum não aplica operação financeira real**, salvo decisão formal posterior.

---

## 8. Pré-condições obrigatórias

Antes de aplicar, a RPC deve validar:

1. `auth.uid()` não nulo;
2. usuário/corretor ativo;
3. operação existe;
4. operação não cancelada;
5. operação possui `agenda_id`;
6. operação possui `simulacao_id`;
7. agenda existe;
8. simulação existe;
9. parcelas origem/destino existem quando exigidas pelo tipo de operação;
10. todos os registros pertencem à mesma `empresa_id`;
11. todos os registros pertencem à mesma `simulacao_id`;
12. todos os registros pertencem ao mesmo `agenda_id`, quando aplicável;
13. operação está em status aplicável;
14. operação ainda não foi aplicada/confirmada;
15. operação não viola flags das parcelas (`pode_receber_antecipacao`, `pode_receber_postergacao`, `pode_receber_vpl`);
16. valor não é negativo;
17. aplicação não gera parcela negativa indevida;
18. payload não possui parâmetros soberanos.

---

## 9. Estados propostos

A Fase 7 deve formalizar o fluxo mínimo de status em `mesa_cliente_fluxo_operacoes.status_operacao`.

Estados já observados:

```text
simulada
```

Estados-alvo propostos para contrato:

```text
simulada
confirmada
aplicada
cancelada
```

A aplicação deve aceitar somente operação em estado previamente permitido, preferencialmente:

```text
confirmada
```

Enquanto o projeto não tiver separação formal entre confirmar e aplicar, o contrato deve deixar explícito se a aplicação também marca `confirmado=true`. A recomendação técnica é separar:

- confirmar/liberar condição comercial;
- aplicar mutação financeira real.

---

## 10. Mutação esperada por tipo de operação

O contrato final da migration deve respeitar `tipo_operacao`.

Como regra geral:

### Antecipação

- reduz valor/data de parcela origem ou retira parte do valor de uma posição futura;
- move valor para parcela destino/data destino;
- aplica desconto/economia conforme operação já calculada;
- preserva rastreabilidade nos metadados das parcelas afetadas.

### Postergação

- move valor/data para posição posterior;
- pode aplicar acréscimo conforme operação já calculada;
- preserva rastreabilidade.

### VPL/desconto

- aplica ajuste financeiro calculado previamente;
- não deve aceitar percentual de VPL vindo da tela.

A Fase 7 não deve inventar cálculo novo se a operação já contém os campos calculados pela Fase 5B.

---

## 11. Idempotência

A aplicação deve ser idempotente.

Reexecução do mesmo `p_operacao_id` não pode duplicar efeito financeiro.

Critério mínimo:

- se operação já estiver aplicada/confirmada conforme contrato, retornar payload informativo e não mutar novamente; ou
- lançar erro controlado `operacao_already_applied`.

A decisão preferida para segurança é erro controlado, porque evita falsa percepção de reaplicação bem-sucedida.

---

## 12. Concorrência e lock

A RPC deve usar lock transacional nos registros críticos.

Mínimo esperado:

```sql
select ... from public.mesa_cliente_fluxo_operacoes where id = p_operacao_id for update;
```

Também deve bloquear parcelas/agenda envolvidas antes de aplicar DML.

Objetivo: impedir dupla aplicação simultânea, race condition e divergência de totais.

---

## 13. Auditoria mínima

A Fase 7 deve registrar no mínimo:

- `confirmado=true` ou `status_operacao='aplicada'`, conforme decisão final;
- `confirmado_por=auth.uid()` ou campo equivalente;
- `confirmado_em=now()` ou campo equivalente;
- `updated_at=now()`;
- `metadata.fase_7_aplicacao` com resumo técnico;
- em parcelas afetadas, `metadata.operacoes_aplicadas` ou equivalente.

Se a auditoria ficar apenas em `metadata`, o teste deve validar a presença das chaves críticas.

---

## 14. Retorno esperado da RPC

Payload mínimo esperado:

```json
{
  "ok": true,
  "fase": "7_APLICACAO_OPERACAO_FINANCEIRA",
  "readonly": false,
  "dml_financeiro": true,
  "visao": "administrativa",
  "operacao_id": "uuid",
  "agenda_id": "uuid",
  "simulacao_id": "uuid",
  "empresa_id": "uuid",
  "status_operacao_anterior": "confirmada",
  "status_operacao_final": "aplicada",
  "parcelas_afetadas": [],
  "resumo_aplicacao": {},
  "auditoria": {}
}
```

O retorno administrativo pode conter dados internos. Esta RPC não é cliente-safe.

---

## 15. Erros controlados esperados

A implementação deve lançar erros explícitos para:

```text
auth_required
p_parametros_must_be_object
frontend_authority_forbidden:<campo>
operacao_not_found
operacao_without_agenda
agenda_not_found
simulacao_not_found
cross_tenant_denied
profile_not_allowed
operacao_cancelada
operacao_not_applicable_status
operacao_already_applied
parcela_origem_not_found
parcela_destino_not_found
parcela_flag_denied
valor_movido_invalid
saldo_parcela_insuficiente
```

Códigos SQLSTATE devem ser consistentes com fases anteriores:

- `28000` para auth;
- `42501` para autorização/perfil/cross-tenant/parâmetro soberano;
- `22023` para parâmetro inválido;
- `P0001` ou equivalente controlado para regra de negócio.

---

## 16. Matriz de testes planejada

| Teste | Objetivo | Mutação |
|---|---|---:|
| 15 | Preflight estrutural da Fase 7 | Não |
| 15A | Contrato/catálogo esperado da futura RPC | Não |
| 15B | Aplicação positiva com fixture transacional e rollback | Sim, dentro de rollback |
| 15C | Segurança negativa: auth, perfil, soberania frontend, cross-tenant | Não ou rollback |
| 15D | Idempotência e dupla aplicação | Sim, dentro de rollback |
| 15E | Regressão 4B/5B/5C/6 após aplicação | Sim, dentro de rollback |
| 15F | Smoke pós-produção sem fixture | Não |

---

## 17. Critérios de aceite da Fase 7

A Fase 7 só pode ser considerada fechada se:

- contrato documentado;
- preflight 15 aprovado;
- migration criada;
- RPC com `SECURITY DEFINER` e `search_path=public, pg_temp`;
- grants corretos: `authenticated` sim, `anon` não;
- DML direto continuar bloqueado por RLS;
- aplicação positiva testada com rollback;
- negativos de segurança testados;
- idempotência testada;
- regressão com Fase 6 testada após aplicação;
- smoke pós-produção executado sem fixture persistente;
- documentação de fechamento técnico criada;
- PR e merge controlados.

---

## 18. Decisão operacional inicial

A Fase 7 será iniciada por preflight `15`, não por migration.

Motivo: antes de criar uma RPC que altera dados financeiros, precisamos validar schema real, policies, dependências, status e lacunas de auditoria.

Nenhum DML real será criado antes do contrato e do preflight serem aceitos.
