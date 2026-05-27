# FECH.AI / MesaCliente — Fase 20C Rastreabilidade do Fluxo Histórico

**Status:** rascunho / depende do PRE-20C  
**Área:** MesaCliente, histórico, 2ª via e rastreabilidade  
**Finalidade:** definir o contrato funcional e técnico da Fase 20C antes de implementação.  
**Escopo:** documentação. Não altera código, banco, RPC, migration ou frontend.

---

## 1. Objetivo

A Fase 20C deve permitir visualizar, no contexto de histórico/proposta/2ª via, a rastreabilidade entre o valor original e o valor final salvo.

A rastreabilidade deve mostrar:

```text
valor original
valor final salvo
diferença absoluta
diferença percentual
```

---

## 2. Dependência obrigatória

A Fase 20C só deve começar após conclusão do documento:

```text
docs/mesa-cliente/pre-20c-reconciliacao-github-supabase.md
```

Sem PRE-20C aprovado, não implementar.

---

## 3. Problema que resolve

Hoje a 2ª via/histórico pode mostrar o fluxo salvo/final, mas ainda precisa evidenciar de forma clara:

```text
de onde saiu o valor original
qual valor foi salvo como final
quanto mudou
qual percentual da mudança
```

Isso aumenta transparência, suporte e rastreabilidade sem recalcular a operação financeira.

---

## 4. Escopo funcional

A Fase 20C deve:

```text
exibir valor original por item relevante
exibir valor final salvo
calcular diferença absoluta para exibição
calcular diferença percentual para exibição
identificar itens sem alteração
identificar itens alterados
manter leitura histórica read-only
preservar acesso por ownership/time/tenant
```

---

## 5. Fora do escopo

Proibido nesta fase:

```text
recalcular VPL
recalcular juros
recalcular antecipação
recalcular amortização
alterar parser
alterar motor financeiro
alterar operação financeira
alterar proposta original
permitir edição pela 2ª via
expor regra interna sensível
ampliar acesso de admin/root em tela comum
```

---

## 6. Visões esperadas

### 6.1 Visão interna autorizada

Pode mostrar informações suficientes para suporte e rastreabilidade operacional, respeitando perfil e permissão.

### 6.2 Visão cliente-safe

Deve mostrar apenas dados comerciais seguros, sem expor regra interna, política financeira, remuneração, metadados brutos ou dados técnicos desnecessários.

---

## 7. Modelo conceitual de exibição

| Item | Valor original | Valor final | Diferença R$ | Diferença % | Status |
|---|---:|---:|---:|---:|---|
| Entrada | a definir | a definir | a definir | a definir | alterado/igual |
| Mensais | a definir | a definir | a definir | a definir | alterado/igual |
| Intermediárias | a definir | a definir | a definir | a definir | alterado/igual |
| Chaves | a definir | a definir | a definir | a definir | alterado/igual |
| Financiamento | a definir | a definir | a definir | a definir | alterado/igual |

O layout final deve ser validado antes da implementação.

---

## 8. Regras de cálculo visual

A diferença absoluta é:

```text
valor final - valor original
```

A diferença percentual é:

```text
((valor final - valor original) / valor original) * 100
```

Cuidados:

```text
se valor original for zero ou nulo, tratar sem divisão inválida
se item não existir, marcar como não aplicável
se valor final for igual ao original, marcar como sem alteração
```

Essa lógica é para rastreabilidade visual, não para redefinir regra financeira soberana.

---

## 9. Dados necessários

Validar no PRE-20C se existem:

```text
valor original salvo ou recuperável
valor final salvo
identificador do item/linha/parcela
contexto da simulação
contexto da proposta histórica
metadados suficientes para exibição
```

Se não existir fonte confiável para valor original, a 20C deve ser bloqueada ou ter escopo revisado.

---

## 10. Segurança e acesso

Manter as regras já consolidadas:

```text
corretor dono pode acessar
corretor não dono não pode acessar
gestor do mesmo time pode acessar quando autorizado
gestor de outro time não pode acessar
outro tenant/empresa não pode acessar
admin/root não ampliam acesso em tela comum sem contrato
```

---

## 11. Testes obrigatórios

Antes de considerar pronto:

```text
usuário autorizado visualiza rastreabilidade
usuário não autorizado é bloqueado
cross-tenant é bloqueado
valor igual exibe sem alteração
valor diferente exibe diferença correta
valor original nulo/zero não quebra tela
dados cliente-safe não expõem informação interna
build passa
sem mudança em parser/motor financeiro
```

---

## 12. Critérios de bloqueio

Bloquear implementação se:

```text
PRE-20C não foi concluído
não há fonte confiável para valor original
não há fonte confiável para valor final
RPCs de histórico divergem do GitHub
RLS/grants não estão confirmados
há risco de vazamento de dado interno
há tentativa de recalcular regra financeira
```

---

## 13. Critério de aceite

A Fase 20C será aceita quando:

```text
rastreabilidade aparece no histórico/2ª via
valores batem com dados salvos
diferença absoluta e percentual estão corretas
acesso respeita ownership/time/tenant
não houve alteração no motor financeiro
não houve alteração no parser
não houve ampliação indevida de permissão
documentação foi atualizada
```

---

## 14. Próximo passo

Concluir o PRE-20C e, somente depois, decidir se a implementação da 20C seguirá por frontend, RPC, payload existente ou ajuste controlado em banco.
