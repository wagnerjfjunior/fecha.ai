# Changelog — GPT 3 e GPT 4 Stack Specialists

**Data:** 2026-06-01  
**Tipo:** documentação e governança  
**Branch:** `docs/gpt34-stack-specialists`

---

## Resumo

Criação documental dos especialistas GPT 3 e GPT 4 do FECH.AI, separando a camada de stack em dois papéis mais precisos:

```text
GPT 3: FECH.AI — Supabase Security Specialist
GPT 4: FECH.AI — Vercel/GitHub CI-CD Specialist
```

---

## Alterações

Arquivos criados:

```text
docs/skills/fechai-gpt3-supabase-security-specialist.md
docs/skills/fechai-gpt4-vercel-github-cicd-specialist.md
```

---

## Justificativa

A disciplina DevSecOps Stack foi dividida para evitar um GPT operacional grande demais e genérico.

Separação definida:

- GPT 3 cuida de Supabase, Auth, RLS, RPCs, migrations, policies, grants e segurança multi-tenant.
- GPT 4 cuida de Vercel, GitHub, CI/CD, branches, PRs, previews, production, releases, env vars, rollback e changelog.

Essa separação reduz ambiguidade, melhora precisão e mantém o GPT 1 Arquiteto SaaS como coordenador das decisões críticas.

---

## Impacto

Documentação apenas.

Não altera código, banco, Supabase, RLS, RPCs, migrations, Vercel, GitHub Actions, Make/n8n, MesaCliente, parser, motor financeiro, regras comerciais ou produção.

---

## Validação

Validar que:

- GPT 3 está focado em Supabase e segurança multi-tenant;
- GPT 4 está focado em Vercel, GitHub e CI/CD;
- ambos acionam conceitualmente o GPT 1 quando houver impacto estrutural;
- ambos preservam MesaCliente quando houver risco sobre parser, motor financeiro ou proposta;
- nenhum documento sugere alteração direta em produção sem aprovação.

---

## Rollback

Rollback documental:

1. Remover ou reverter os arquivos criados nesta alteração.
2. Restaurar modelo anterior de GPT 3 único, se necessário.
3. Atualizar `docs/skills/fechai-gpt-registry.md` após decisão.
