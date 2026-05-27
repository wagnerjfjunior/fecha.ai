# FECH.AI — Guia de Suporte N1, N2 e N3

**Status:** rascunho profissional  
**Área:** operação e suporte  
**Finalidade:** orientar atendimento, triagem, diagnóstico e escalonamento de incidentes do FECH.AI.  
**Escopo:** processo operacional. Não altera sistema.

---

## 1. Objetivo

Este guia define como atender problemas do FECH.AI sem improviso.

A meta é que suporte consiga:

```text
classificar o problema
coletar evidência
validar impacto
resolver casos simples
escalar casos técnicos
registrar causa e solução
proteger dados sensíveis
```

---

## 2. Níveis de suporte

| Nível | Responsabilidade | Exemplos |
|---|---|---|
| N1 | triagem e operação básica | login, dúvida de uso, evidência, navegador, acesso inicial |
| N2 | análise funcional/técnica | permissão, tenant, dados, RPC, regra de acesso, logs |
| N3 | engenharia | código, migration, RLS, banco, deploy, incidente crítico |

---

## 3. Fluxo de atendimento

```text
Usuário reporta problema
  ↓
N1 coleta evidência
  ↓
N1 classifica impacto
  ↓
N1 resolve ou escala
  ↓
N2 valida regra/dados/logs
  ↓
N2 resolve ou escala
  ↓
N3 corrige código/banco/deploy quando necessário
  ↓
Registro de causa e prevenção
```

---

## 4. Informações mínimas para abrir chamado

Coletar:

```text
nome do cliente/empresa
usuário afetado
módulo afetado
data e horário
passos para reproduzir
mensagem de erro
print ou vídeo curto
navegador/dispositivo
impacto comercial
se afeta um usuário ou vários
```

Não solicitar senha do usuário.

---

## 5. Classificação de impacto

| Impacto | Descrição | Prioridade |
|---|---|---|
| Crítico | sistema indisponível para vários usuários | alta |
| Alto | módulo crítico falhando | alta |
| Médio | erro com alternativa operacional | média |
| Baixo | dúvida, ajuste ou melhoria | baixa |

---

## 6. Casos comuns

### 6.1 Usuário não consegue acessar

Verificar:

```text
usuário existe
usuário está ativo
empresa/tenant correto
perfil correto
sessão expirada
erro no Supabase Auth
navegador/cache
```

### 6.2 Corretor não vê lead

Verificar:

```text
lead existe
lead está atribuído
lista está ativa
corretor pertence à empresa correta
feedback anterior bloqueia avanço
regra de lote foi respeitada
```

### 6.3 Histórico ou 2ª via não abre

Verificar:

```text
usuário é dono da proposta ou gestor autorizado
tenant/empresa conferem
time confere quando aplicável
sessão/token/simulação existem
RPC necessária está aplicada
não há erro de frontend
```

### 6.4 MesaCliente apresenta diferença no fluxo

Verificar:

```text
proposta é histórica ou nova
fluxo salvo é final
valor original está disponível?
Fase 20C foi implementada?
não recalcular regra financeira sem contrato
```

---

## 7. O que nunca fazer

```text
não pedir senha
não colar token em chamado
não compartilhar chave de API
não usar service_role no frontend
não alterar RLS em produção sem contrato
não editar dado financeiro direto no banco sem rollback
não prometer prazo sem classificação de impacto
não anexar evidência com informação sensível sem máscara
```

---

## 8. Escalonamento

Escalar para N2 quando:

```text
envolve permissão
envolve tenant/empresa/time
envolve dado inconsistente
envolve RPC
não reproduz no N1
impacta mais de um usuário
```

Escalar para N3 quando:

```text
envolve código
build/deploy falhou
envolve migration
RLS/policy precisa revisão
há risco de vazamento de dados
há indisponibilidade
há erro crítico recorrente
```

---

## 9. Registro pós-incidente

Após resolver, registrar:

```text
causa raiz
ação tomada
evidência de normalização
impacto
tempo de resolução
se precisa melhoria de produto
se precisa melhoria de monitoramento
```

---

## 10. Próximos passos

Criar:

```text
matriz de erros conhecida
runbook de incidentes críticos
base de conhecimento por módulo
checklist de validação pós-deploy
modelo de chamado padrão
```
