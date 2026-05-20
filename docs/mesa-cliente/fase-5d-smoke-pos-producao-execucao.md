# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 5D — Registro de execução do smoke pós-produção

**Script executado:**

```text
supabase/tests/mesa-cliente/engenharia-financeira/13_smoke_pos_producao_leitura_operacoes_admin_readonly.sql
```

**Status da execução:** APROVADO COM `SKIP_DATA`

**Classificação técnica:** sanidade estrutural e read-only confirmada; validação funcional de listagem/detalhe adiada por ausência de operação financeira real acessível.

---

## 1. Resultado recebido

| Bloco | Status | Leitura técnica |
|---|---:|---|
| `00_funcoes_5d_existentes` | PASS | As duas RPCs 5D existem no ambiente alvo |
| `01_alvo_admin_operacao_real` | SKIP_DATA | Não foi encontrada operação financeira real acessível por perfil administrativo ativo |
| `02_listagem_admin_readonly_smoke` | SKIP_DATA | Listagem não executada por ausência de alvo real |
| `03_detalhe_admin_readonly_smoke` | SKIP_DATA | Detalhe não executado por ausência de alvo real |
| `04_contrato_readonly_minimo` | SKIP_DATA | Contrato mínimo não validado por ausência de payload real |
| `05_negativos_allowlist_nao_executados_no_smoke_readonly` | INFO | Negativos/allowlists permanecem cobertos por 13C/13E |
| `99_smoke_readonly_notice` | INFO | Smoke executado em transação `READ ONLY` estrita, sem DDL e sem DML |

---

## 2. Conclusão objetiva

O smoke confirmou que as RPCs da Fase 5D estão presentes no ambiente:

```text
public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)
public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
```

O smoke também confirmou que o script corrigido executa em modo `READ ONLY` estrito, sem criação de função temporária, sem fixture e sem DML financeiro.

Não houve falha de função, erro de permissão estrutural ou erro de transação read-only.

---

## 3. Limitação da execução

A execução não conseguiu validar listagem e detalhe porque o ambiente não possuía operação financeira real acessível por perfil administrativo ativo no momento do teste.

Essa condição foi tratada corretamente como `SKIP_DATA`, não como `FAIL`, pois o protocolo do smoke proíbe criar massa em produção.

---

## 4. Situação da Fase 5D após esta execução

| Camada | Status |
|---|---:|
| Testes completos 13 a 13E | VALIDADO |
| Smoke estrutural pós-produção | VALIDADO |
| Existência das RPCs em ambiente alvo | VALIDADO |
| Read-only estrito do smoke | VALIDADO |
| Smoke funcional com dado real | PENDENTE POR AUSÊNCIA DE MASSA REAL |

---

## 5. Próxima ação recomendada

Não criar fixture diretamente pelo smoke em produção.

Para concluir o smoke funcional, gerar uma operação financeira real por fluxo normal/controlado do sistema em ambiente adequado e executar novamente o mesmo script.

Enquanto não houver operação financeira real, a Fase 5D permanece tecnicamente validada pelos testes 13 a 13E e com smoke pós-produção estrutural aprovado, mas a evidência operacional de listagem/detalhe em ambiente real fica marcada como pendente por ausência de massa.
