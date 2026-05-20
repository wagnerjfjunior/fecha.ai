# FECH.AI / MesaCliente — Engenharia Financeira

## Fase 5D — Fechamento técnico

**Status:** fase tecnicamente validada e pronta para handoff/smoke pós-merge.

**Escopo da fase:** leitura administrativa read-only de operações financeiras persistidas.

**Migration principal:**

```text
supabase/migrations/20260520190000_mesa_cliente_fase_5d_leitura_operacoes_financeiras_admin.sql
```

**RPCs entregues:**

```text
public.mesa_cliente_listar_operacoes_financeiras_admin(uuid, uuid, jsonb)
public.mesa_cliente_obter_operacao_financeira_admin(uuid, jsonb)
```

---

## 1. Contrato funcional fechado

A Fase 5D entrega somente leitura administrativa das operações financeiras criadas pelas fases anteriores.

A fase **não** cria operação, **não** altera agenda, **não** altera parcelas, **não** confirma/cancela operação, **não** recalcula operação e **não** expõe uma visão segura de cliente.

A visão retornada é administrativa e intencionalmente contém dados operacionais completos para auditoria, gestão e análise interna.

---

## 2. Princípios preservados

| Princípio | Situação |
|---|---:|
| `auth.uid()` obrigatório | Preservado |
| Corretor ativo obrigatório | Preservado |
| Perfil administrativo obrigatório | Preservado |
| Tenant/empresa validado em banco | Preservado |
| Admin global com escopo global | Preservado |
| Admin local/gestor/coordenador limitado por empresa | Preservado |
| Frontend sem autoridade soberana | Preservado |
| Payload com chaves proibidas bloqueado | Preservado |
| Read-only absoluto | Preservado |
| Nenhum DML financeiro | Preservado |
| Sem alteração de agenda | Preservado |
| Sem alteração de parcelas | Preservado |
| Sem recalcular operação | Preservado |
| Sem exposição cliente-safe automática | Preservado |

---

## 3. Matriz de testes executados

| Teste | Arquivo | Status | Objetivo |
|---|---|---:|---|
| 13 | `13_preflight_leitura_operacoes_financeiras_admin_readonly.sql` | VALIDADO | Preflight estrutural e contrato read-only |
| 13A | `13a_validacao_listar_operacoes_financeiras_admin_rollback.sql` | VALIDADO | Listagem administrativa positiva |
| 13B | `13b_validacao_obter_operacao_financeira_admin_rollback.sql` | VALIDADO | Detalhe administrativo positivo |
| 13C | `13c_validacao_seguranca_leitura_operacoes_admin_rollback.sql` | VALIDADO | Segurança, negativos e isolamento |
| 13CV2 | `13cv2_validacao_seguranca_leitura_operacoes_admin_rollback.sql` | VALIDADO | Versão alternativa segura, mantida sem sobrescrever o 13C |
| 13D | `13d_validacao_zero_dml_readonly_rigido_leitura_operacoes_admin_rollback.sql` | VALIDADO | Zero DML/read-only rígido com checagem de `xmin` |
| 13E | `13e_validacao_filtros_paginacao_ordenacao_leitura_operacoes_admin_rollback.sql` | VALIDADO | Filtros, paginação, ordenação e allowlists |

---

## 4. Evidências documentais produzidas

| Documento | Finalidade |
|---|---|
| `docs/mesa-cliente/fase-5d-contrato-leitura-operacoes-admin.md` | Contrato canônico da fase |
| `docs/mesa-cliente/fase-5d-validacao-preflight-13.md` | Registro do preflight |
| `docs/mesa-cliente/fase-5d-validacao-13a-listar-operacoes-admin.md` | Registro da listagem positiva |
| `docs/mesa-cliente/fase-5d-validacao-13b-obter-operacao-admin.md` | Registro do detalhe positivo |
| `docs/mesa-cliente/fase-5d-validacao-13c-seguranca-leitura-operacoes-admin.md` | Registro da segurança/negativos |
| `docs/mesa-cliente/fase-5d-validacao-13d-zero-dml-readonly-rigido.md` | Registro do zero DML/read-only rígido |
| `docs/protocolo/mesa-cliente/engenharia-financeira/fase-5d/13e_validacao_filtros_paginacao_ordenacao.md` | Registro do 13E |
| `docs/mesa-cliente/fase-5d-fechamento-tecnico.md` | Consolidação final da fase |
| `docs/mesa-cliente/fase-5d-smoke-pos-producao.md` | Protocolo de smoke pós-merge/pós-produção |

---

## 5. Correções aplicadas durante a validação

### 5.1 Correção do 13C original

Foi preservado o arquivo original `13C` e criada uma versão alternativa `13CV2`, sem sobrescrever o teste já existente.

O problema envolvendo referência a resultado temporário inexistente foi tratado no teste original sem remover cobertura crítica.

Regra mantida: **não apagar teste com problema para “passar”; corrigir a causa mantendo a intenção de validação.**

### 5.2 Correção do 13E — datas de postergação

O teste 13E inicialmente usava data fixa para postergação.

Isso violava a regra soberana da 5B quando a data destino não era posterior à data atual da parcela.

Correção aplicada:

```sql
parcela.data_atual + interval '60 days'
```

A data destino passou a ser derivada da própria parcela selecionada, eliminando data mágica.

### 5.3 Correção do 13E — grupo permitido pela política financeira

O teste 13E inicialmente selecionava parcelas apenas por flags genéricas de operação.

A RPC 5B valida também o grupo financeiro normalizado da parcela contra a política.

Correção aplicada:

- normalização temporária de grupo no teste;
- seleção apenas de grupos permitidos pela 5B:

```text
financiamento
chaves
anuais
mensais
```

Com isso, a fixture do 13E passou a respeitar a fonte soberana da 5B antes de testar a leitura 5D.

---

## 6. Conclusão técnica

A Fase 5D está fechada tecnicamente no escopo contratado.

A implementação entrega duas RPCs administrativas de leitura, ambas com controle de autenticação, autorização, tenant, allowlist de entrada e contrato read-only.

A bateria de testes 13 até 13E cobre:

- existência estrutural;
- contrato de retorno;
- listagem positiva;
- detalhe positivo;
- segurança e negativos;
- isolamento multiempresa;
- bloqueio de autoridade vinda do frontend;
- ausência de DML;
- filtros;
- paginação;
- ordenação;
- validação de parâmetros inválidos.

Não há indicação, dentro do escopo validado, de necessidade de reabrir motor financeiro, parser, Worker, Make/n8n ou regras centrais das fases anteriores.

---

## 7. Próximo passo operacional

Executar o smoke pós-merge/pós-produção descrito em:

```text
docs/mesa-cliente/fase-5d-smoke-pos-producao.md
```

Script de apoio:

```text
supabase/tests/mesa-cliente/engenharia-financeira/13_smoke_pos_producao_leitura_operacoes_admin_readonly.sql
```

O smoke é exclusivamente read-only e não cria fixture em produção.
