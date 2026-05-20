# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 6 — Fechamento técnico

**Status:** fase tecnicamente validada e pronta para PR/merge controlado.

**Escopo da fase:** resumos read-only de operação financeira, com separação física entre visão administrativa e visão cliente-safe.

**Migration principal:**

```text
supabase/migrations/20260520213000_mesa_cliente_fase_6_resumos_operacao_financeira_readonly.sql
```

**RPCs entregues:**

```text
public.mesa_cliente_resumir_operacao_financeira_admin(uuid, jsonb)
public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid, jsonb)
```

---

## 1. Contrato funcional fechado

A Fase 6 entrega duas RPCs read-only para resumir uma operação financeira já persistida.

A separação entre as RPCs foi adotada como decisão de segurança, evitando uma única função com parâmetro de visão. A visão administrativa e a visão cliente-safe possuem contratos físicos separados.

A fase **não** cria operação, **não** altera agenda, **não** altera parcelas, **não** confirma operação, **não** cancela operação, **não** recalcula operação, **não** executa DML financeiro e **não** aceita autoridade soberana vinda do frontend.

A visão administrativa retorna dados financeiros internos para gestão, auditoria e análise operacional.

A visão cliente-safe retorna apenas dados comerciais seguros para apresentação ao cliente, sem expor taxa, VPL, política financeira, prêmio, comissão, metadados internos, tenant, empresa ou dados administrativos sensíveis.

---

## 2. Princípios preservados

| Princípio | Situação |
|---|---:|
| `auth.uid()` obrigatório | Preservado |
| Corretor ativo obrigatório | Preservado |
| Tenant/empresa validado em banco | Preservado |
| Admin global com escopo global | Preservado |
| Admin local/gestor/coordenador limitado por empresa | Preservado |
| Corretor comum limitado ao próprio escopo | Preservado |
| Outro corretor do mesmo tenant bloqueado quando não é dono | Preservado |
| Admin de outro tenant bloqueado quando não é global | Preservado |
| Frontend sem autoridade soberana | Preservado |
| Payload com chaves proibidas bloqueado | Preservado |
| Cliente-safe depende de `visivel_cliente=true` | Preservado |
| Read-only absoluto | Preservado |
| Nenhum DML financeiro | Preservado |
| Sem alteração de agenda | Preservado |
| Sem alteração de parcelas | Preservado |
| Sem recalcular operação | Preservado |
| Sem vazamento de campos sensíveis no cliente-safe | Preservado |
| RPCs separadas por visão | Preservado |

---

## 3. Contrato técnico das RPCs

### 3.1 RPC administrativa

```text
public.mesa_cliente_resumir_operacao_financeira_admin(uuid, jsonb)
```

Contrato top-level validado:

```text
altera_agenda
altera_operacao
altera_parcelas
cliente_safe
dml_financeiro
fase
flags_integridade
ids
ok
operacao
readonly
recalcula_operacao
resumo_financeiro_admin
simulacao
visao
```

A visão administrativa é interna e contém `resumo_financeiro_admin`.

### 3.2 RPC cliente-safe

```text
public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid, jsonb)
```

Contrato top-level validado:

```text
altera_agenda
altera_operacao
altera_parcelas
avisos
cliente
cliente_safe
dml_financeiro
fase
ok
parcelas_impactadas
readonly
recalcula_operacao
resumo_condicao
status_comercial
visao
```

A visão cliente-safe é comercial, sem exposição de campos internos.

Campos sensíveis explicitamente bloqueados no topo e por inspeção textual:

```text
empresa_id
tenant_id
politica_id
checksum_operacao
metadata
resumo_financeiro_admin
taxa_ano_pct
vpl_aplicado_pct
premio_corretor_pct
status_premio
confirmado_por
cancelado_por
vpl
taxa
prêmio
premio
comissao
comissão
```

---

## 4. Contrato de catálogo validado

As duas RPCs foram validadas com:

| Item | Situação |
|---|---:|
| Funções existem no schema `public` | PASS |
| `SECURITY DEFINER` | PASS |
| Volatilidade `STABLE` | PASS |
| `search_path=public, pg_temp` | PASS |
| `EXECUTE` para `authenticated` | PASS |
| `EXECUTE` negado para `anon` | PASS |
| Sem grant público implícito | PASS |
| Comentário de catálogo presente | PASS |

ACL validada:

```text
{postgres=X/postgres,authenticated=X/postgres,service_role=X/postgres}
```

---

## 5. Matriz de testes executados

| Teste | Arquivo | Status | Objetivo |
|---|---|---:|---|
| 14 | `14_preflight_resumos_operacao_financeira_readonly.sql` | VALIDADO | Preflight estrutural da Fase 6 |
| 14A | `14a_validacao_resumo_operacao_financeira_admin_rollback.sql` | VALIDADO | Resumo administrativo positivo com fixture transacional |
| 14B | `14b_validacao_resumo_operacao_cliente_safe_rollback.sql` | VALIDADO | Resumo cliente-safe positivo com operação liberada |
| 14C | `14c_validacao_seguranca_cliente_safe_rollback.sql` | VALIDADO | Negativos cliente-safe: auth, release gate, parâmetros soberanos e read-only |
| 14D | `14d_validacao_escopo_tenant_cliente_safe_rollback.sql` | VALIDADO | Escopo, perfil e isolamento tenant na visão cliente-safe |
| 14E | `14e_regressao_final_resumos_operacao_fase_6_rollback.sql` | VALIDADO | Regressão final das duas RPCs, catálogo, execução e ausência de vazamento |

---

## 6. Evidências dos testes

### 6.1 Preflight 14

Resultado técnico:

| Bloco | Status |
|---|---:|
| `01_tabelas_obrigatorias` | PASS |
| `02_funcoes_dependencia` | PASS |
| `03_colunas_operacoes` | PASS |
| `04_colunas_parcelas` | PASS |
| `05_rls_financeiro` | INFO |
| `06_policies_existentes` | INFO |
| `07_grants_funcoes_dependencia` | INFO |
| `08_campos_sensiveis_para_cliente_safe` | INFO |
| `09_readiness_fase_6` | PASS |
| `10_probe_operacao_real_mais_recente` | INFO |
| `99_interpretacao_operacional` | INFO |

Conclusão: Fase 6 liberada tecnicamente para criação das RPCs read-only.

### 6.2 Teste 14A

Resultado técnico:

| Bloco | Status |
|---|---:|
| `00_setup_admin_fixture` | PASS |
| `01_agenda_parcela_fixture` | PASS |
| `02_operacao_5b_fixture` | PASS |
| `03_rpc_admin_basico` | PASS |
| `04_identidade_e_tenant` | PASS |
| `05_campos_financeiros_admin_presentes` | PASS |
| `06_readonly_sem_mutacao_rpc6` | PASS |
| `99_rollback_notice` | INFO |

Conclusão: RPC administrativa positiva aprovada.

### 6.3 Teste 14B

Resultado técnico:

| Bloco | Status |
|---|---:|
| `00_setup_admin_fixture` | PASS |
| `01_agenda_parcela_fixture` | PASS |
| `02_operacao_confirmada_liberada_fixture` | PASS |
| `03_rpc_cliente_safe_basico` | PASS |
| `04_payload_comercial_minimo` | PASS |
| `05_sem_vazamento_campos_sensiveis_top_level` | PASS |
| `06_sem_vazamento_campos_sensiveis_textual` | PASS |
| `07_readonly_sem_mutacao_rpc6` | PASS |
| `99_rollback_notice` | INFO |

Conclusão: RPC cliente-safe positiva aprovada.

### 6.4 Teste 14C

Resultado técnico:

| Bloco | Status |
|---|---:|
| `00_setup_admin_fixture` | PASS |
| `01_agenda_parcela_fixture` | PASS |
| `02_operacao_5b_fixture_nao_liberada` | PASS |
| `03_bloqueio_sem_auth` | PASS |
| `04_bloqueio_operacao_nao_liberada` | PASS |
| `05_bloqueio_parametros_soberanos_cliente_safe` | PASS |
| `06_bloqueio_parametros_nao_objeto` | PASS |
| `07_readonly_tentativas_negativas` | PASS |
| `99_rollback_notice` | INFO |

Parâmetros soberanos bloqueados no cliente-safe:

```text
empresa_id
tenant_id
politica_id
metadata
taxa_ano_pct
vpl_aplicado_pct
premio_corretor_pct
visao
cliente_safe
```

Conclusão: segurança negativa cliente-safe aprovada.

### 6.5 Teste 14D

Resultado técnico:

| Bloco | Status |
|---|---:|
| `00_setup_escopo_fixture` | PASS |
| `01_operacao_visivel_fixture` | PASS |
| `02_owner_corretor_acessa_cliente_safe` | PASS |
| `03_outro_corretor_mesmo_tenant_bloqueado` | PASS |
| `04_admin_mesmo_tenant_acessa` | PASS |
| `05_admin_outro_tenant_bloqueado_ou_global` | PASS |
| `06_readonly_escopo_sem_mutacao` | PASS |
| `99_rollback_notice` | INFO |

Bloqueios validados:

```text
corretor_scope_denied
cross_tenant_denied
```

Conclusão: escopo, perfil e tenant aprovados.

### 6.6 Teste 14E

Resultado técnico:

| Bloco | Status |
|---|---:|
| `00_contrato_rpc_catalogo` | PASS |
| `01_setup_fixture_final` | PASS |
| `02_operacao_base_final` | PASS |
| `03_regressao_rpc_admin` | PASS |
| `04_regressao_rpc_cliente_safe` | PASS |
| `05_regressao_sem_vazamento_cliente_safe` | PASS |
| `06_readonly_regressao_duas_rpcs` | PASS |
| `99_rollback_notice` | INFO |

Conclusão: regressão final da Fase 6 aprovada.

---

## 7. Correções e decisões durante a validação

### 7.1 Separação física das RPCs

Foi mantida a decisão de criar duas RPCs separadas em vez de usar uma única RPC com parâmetro `visao`.

Motivo: reduzir risco de vazamento cliente-safe. Em uma RPC única, um `CASE` incorreto poderia expor campos administrativos para cliente.

### 7.2 Ajuste do 14E ao contrato real da migration

Durante a pré-validação, houve falso negativo no teste 14E porque a expectativa inicial cobrava `parcelas_impactadas` no payload administrativo.

O contrato real da RPC administrativa, conforme migration da Fase 6, não possui `parcelas_impactadas` no topo.

Correção aplicada no teste:

- admin validado com `ids`, `operacao`, `resumo_financeiro_admin`, `simulacao`, `flags_integridade`;
- cliente-safe validado com `parcelas_impactadas`, `resumo_condicao` e `status_comercial`.

A correção foi feita no teste, não na RPC, porque a RPC já estava aderente ao contrato versionado.

---

## 8. Conclusão técnica

A Fase 6 está fechada tecnicamente no escopo contratado.

A implementação entrega duas RPCs read-only separadas, uma administrativa e uma cliente-safe, ambas com controle de autenticação, autorização, tenant, escopo de corretor, grants, `SECURITY DEFINER`, `STABLE`, `search_path` fixo e ausência de DML financeiro.

A bateria de testes 14 até 14E cobre:

- existência estrutural;
- readiness técnico;
- catálogo das RPCs;
- grants;
- execução administrativa positiva;
- execução cliente-safe positiva;
- bloqueio sem autenticação;
- bloqueio de operação não liberada ao cliente;
- bloqueio de parâmetros soberanos vindos do frontend;
- bloqueio de JSON não objeto;
- escopo do corretor dono;
- bloqueio de outro corretor do mesmo tenant;
- acesso por admin/gestor/coordenador do mesmo tenant;
- bloqueio cross-tenant;
- ausência de vazamento cliente-safe;
- read-only das duas RPCs.

Não há indicação, dentro do escopo validado, de necessidade de reabrir parser, Worker, Make/n8n, motor financeiro anterior, persistência 4B ou registro de operação 5B.

---

## 9. Próximo passo operacional

Próxima etapa recomendada:

```text
1. Abrir PR da branch feature/mesa-cliente-pos-5d-alinhamento-proxima-fase para main.
2. Revisar diff da migration e dos testes 14–14E.
3. Fazer merge controlado.
4. Executar smoke pós-produção específico da Fase 6.
5. Após smoke aprovado, abrir nova branch limpa a partir da main para a próxima fase.
```

O smoke pós-produção da Fase 6 deve ser exclusivamente read-only e não deve criar fixture persistente em produção.
