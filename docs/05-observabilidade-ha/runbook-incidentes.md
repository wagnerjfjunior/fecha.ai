# FECH.AI — Runbook de Incidentes

**Status:** rascunho profissional  
**Área:** observabilidade, suporte e continuidade operacional  
**Finalidade:** padronizar resposta a incidentes no FECH.AI.  
**Escopo:** processo operacional. Não altera infraestrutura.

---

## 1. Objetivo

Este runbook orienta como agir quando houver falha, indisponibilidade, erro crítico ou suspeita de problema operacional no FECH.AI.

A meta é reduzir improviso e garantir:

```text
triagem rápida
classificação de impacto
responsável definido
evidência registrada
ação segura
comunicação clara
causa raiz documentada
prevenção futura
```

---

## 2. Severidades

| Severidade | Descrição | Exemplo |
|---|---|---|
| SEV1 | indisponibilidade ampla ou risco crítico | sistema fora do ar, login geral falhando |
| SEV2 | módulo crítico impactado | MesaCliente ou CRM falhando para grupo relevante |
| SEV3 | erro funcional com alternativa | falha pontual, workaround disponível |
| SEV4 | dúvida, ajuste menor ou melhoria | baixo impacto operacional |

---

## 3. Fluxo de resposta

```text
1. Receber alerta ou chamado
2. Confirmar impacto
3. Classificar severidade
4. Definir responsável
5. Coletar evidência
6. Verificar últimos deploys/mudanças
7. Aplicar contenção segura
8. Comunicar status
9. Resolver ou escalar
10. Registrar causa raiz
11. Definir prevenção futura
```

---

## 4. Formulário mínimo de incidente

```text
ID do incidente:
Data/hora de abertura:
Responsável:
Severidade:
Cliente/empresa afetada:
Usuários afetados:
Módulo afetado:
Sintoma:
Impacto comercial:
Evidência inicial:
Última mudança conhecida:
Ação de contenção:
Status:
Causa raiz:
Correção definitiva:
Prevenção futura:
Data/hora de encerramento:
```

---

## 5. Checklist — sistema fora do ar

Verificar:

```text
Vercel status
último deploy
DNS/domínio
certificado TLS
logs de frontend
Supabase status
alertas externos de uptime
```

Ações seguras:

```text
rollback de deploy se falha começou após publicação
comunicar indisponibilidade
registrar horário de início e fim
não alterar banco sem evidência
```

---

## 6. Checklist — login falhando

Verificar:

```text
Supabase Auth
usuário ativo
sessão expirada
erro generalizado ou isolado
navegador/dispositivo
mudança recente de auth/configuração
```

Escalar para N3 se afetar múltiplos usuários ou houver suspeita de configuração global.

---

## 7. Checklist — RPC crítica com erro

Verificar:

```text
qual RPC falhou
parâmetros enviados
perfil do usuário
tenant/empresa/time
logs do Supabase
mudança recente em migration/function
se erro é generalizado ou por permissão
```

Ações seguras:

```text
não liberar grant amplo como correção rápida
não desativar RLS sem contrato
não editar function em produção sem rollback
```

---

## 8. Checklist — erro no MesaCliente

Verificar:

```text
simulação existe
histórico existe
usuário tem acesso autorizado
fluxo salvo está disponível
última mudança no módulo
console/logs do frontend
RPCs relacionadas estão aplicadas
```

Importante:

```text
Não recalcular operação financeira para corrigir visual sem contrato.
Não alterar parser ou motor financeiro durante incidente sem aprovação.
```

---

## 9. Comunicação

Para incidente relevante, comunicar:

```text
o que está acontecendo
quem foi afetado
qual módulo foi afetado
se há alternativa temporária
próxima atualização prevista
quando foi resolvido
```

Evitar linguagem técnica excessiva para cliente final.

---

## 10. Pós-incidente

Após encerrar:

```text
registrar causa raiz
registrar tempo total de indisponibilidade
registrar impacto
criar tarefa preventiva
atualizar documentação se necessário
avaliar se alerta deveria ter detectado antes
```

---

## 11. Próximos passos

1. Criar modelo de registro de incidente.
2. Definir canais de alerta.
3. Definir responsáveis por severidade.
4. Criar checklist pós-deploy.
5. Criar dashboard de saúde operacional.
