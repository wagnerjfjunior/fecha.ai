# FECH.AI — Segurança Multi-Tenant e Multiempresa

**Status:** rascunho profissional  
**Área:** segurança, arquitetura e governança  
**Finalidade:** documentar os princípios de isolamento, autorização e proteção de dados do FECH.AI.  
**Escopo:** documentação. Não altera RLS, policies, grants, código ou banco.

---

## 1. Objetivo

Garantir que o FECH.AI seja operado como SaaS multi-tenant e multiempresa sem vazamento de dados entre clientes, empresas, times ou usuários.

A regra principal é:

```text
Frontend não é autoridade de segurança.
Banco/RPC/RLS são a camada soberana de validação.
```

---

## 2. Conceitos

| Termo | Significado |
|---|---|
| Tenant | agrupamento lógico de isolamento SaaS |
| Empresa | organização/cliente dentro da operação |
| Time | agrupamento comercial dentro da empresa |
| Usuário | pessoa autenticada no sistema |
| Perfil | papel funcional do usuário |
| Ownership | vínculo de posse/responsabilidade sobre lead, proposta ou fluxo |
| Cliente-safe | visão limpa, sem dados internos sensíveis |

---

## 3. Princípios obrigatórios

```text
1. Nunca confiar em tenant/empresa vindo do frontend como verdade soberana.
2. Validar auth.uid() em toda RPC sensível.
3. Validar usuário ativo.
4. Validar vínculo com empresa/tenant.
5. Validar perfil e permissão.
6. Validar ownership/time quando aplicável.
7. Bloquear anon em RPC sensível.
8. Não expor chave privilegiada no frontend.
9. Separar visão interna de visão cliente-safe.
10. Registrar evidência para mudanças críticas.
```

---

## 4. Perfis esperados

Perfis comuns do produto:

| Perfil | Escopo típico |
|---|---|
| corretor | trabalha leads, registra feedback, acessa sua carteira e propostas próprias |
| gestor | acompanha equipe/time e indicadores autorizados |
| admin_empresa | administra operação de uma empresa, conforme contrato |
| suporte | acesso limitado para diagnóstico, se existir |
| root/super_admin | uso restrito, auditado e não operacional comum |

Os nomes reais dos perfis devem ser confirmados no Supabase.

---

## 5. Regras para dados comerciais

Para leads e propostas:

```text
corretor acessa o que é dele ou o que foi atribuído
gestor acessa o que pertence ao seu time autorizado
empresa não acessa dados de outra empresa
outro tenant não acessa dados fora do seu escopo
admin/root não devem ampliar acesso em telas comuns sem contrato claro
```

---

## 6. MesaCliente e dados financeiros

MesaCliente exige proteção reforçada porque pode envolver fluxo de pagamento, proposta, histórico e operação financeira.

Regras:

```text
não expor regra financeira interna para cliente-safe
não expor política interna sem necessidade
não recalcular operação financeira fora do contrato aprovado
não permitir alteração por payload soberano do frontend
não misturar visualização histórica com edição da proposta original
```

---

## 7. RLS e RPCs

A arquitetura segura deve combinar:

```text
Supabase Auth
RLS ativa em tabelas sensíveis
policies por tenant/empresa/perfil
RPCs para escrita controlada
validação de ownership/time dentro do banco
```

Quando houver dúvida entre validar no frontend ou no banco, validar no banco.

---

## 8. Dados enviados para IA

A IA pode apoiar operação, mas não deve receber dados sem critério.

Antes de enviar conteúdo para IA, validar:

```text
finalidade
necessidade
nível de sensibilidade
mascaramento possível
registro de uso
custo
risco de exposição
```

---

## 9. Checklist pré-deploy de segurança

Antes de publicar alteração relevante:

```text
não há segredo no código
não há chave privilegiada no frontend
RLS continua ativa
RPC sensível não tem EXECUTE para anon
payload cliente-safe usa allowlist
cross-tenant foi testado quando aplicável
usuário sem permissão foi bloqueado
logs não expõem dado sensível
rollback está documentado
```

---

## 10. Próximos passos

1. Inventariar policies reais.
2. Inventariar grants reais.
3. Listar RPCs críticas.
4. Criar matriz oficial de perfis e permissões.
5. Criar checklist de revisão de segurança por PR.
6. Documentar processo de acesso a produção.
