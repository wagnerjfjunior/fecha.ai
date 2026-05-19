# MesaCliente Engenharia Financeira — Produção única: backup e rollback

## Contexto

O projeto está operando com apenas um banco Supabase disponível: produção.

Antes de aplicar qualquer migration de hardening da Engenharia Financeira, é obrigatório criar uma camada mínima de recuperação.

A migration relacionada é:

```text
supabase/migrations/20260517162000_mesa_cliente_engenharia_financeira_hardening.sql
```

## Regra operacional

Não aplicar a migration diretamente no banco de produção sem pelo menos uma destas proteções:

1. backup/restauração disponível pelo painel do Supabase;
2. dump lógico local via Supabase CLI/pg_dump;
3. rollback SQL versionado e validado para a migration específica.

O ideal é ter os itens 2 e 3 antes de executar.

## Situação do plano Free

Mesmo quando há backup automático do Supabase, no plano Free o fluxo seguro é manter exportações próprias fora da plataforma.

A recomendação prática para este projeto é gerar dump lógico antes da migration.

## Backup lógico recomendado via Supabase CLI

Pré-requisitos:

- Supabase CLI instalada;
- acesso ao projeto Supabase;
- senha do banco;
- project ref do projeto.

Exemplo de fluxo:

```bash
# 1. Entrar no projeto local
cd /caminho/do/repositorio/fecha.ai

# 2. Logar na Supabase CLI
supabase login

# 3. Linkar o projeto remoto
supabase link --project-ref uobxxgzshrmbtjfdolxd

# 4. Criar diretório de backup local
mkdir -p backups/supabase/$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=$(ls -td backups/supabase/* | head -1)

# 5. Dump do schema public
supabase db dump --linked --schema public -f "$BACKUP_DIR/schema_public.sql"

# 6. Dump dos dados do schema public
supabase db dump --linked --schema public --data-only --use-copy -f "$BACKUP_DIR/data_public.sql"

# 7. Dump de roles customizadas, se existirem
supabase db dump --linked --role-only -f "$BACKUP_DIR/roles.sql"
```

## Backup mínimo alternativo

Se a CLI não estiver disponível, no mínimo:

1. salvar o resultado do `00_preflight_producao_readonly.sql`;
2. salvar uma cópia da migration aplicada;
3. manter o rollback SQL abaixo versionado;
4. aplicar em janela de baixo uso;
5. rodar imediatamente o postcheck;
6. em caso de falha, executar rollback.

Esse caminho é inferior ao dump lógico, mas ainda é melhor do que operar sem plano de volta.

## Rollback SQL relacionado

Arquivo:

```text
supabase/rollback/20260517162000_mesa_cliente_engenharia_financeira_hardening_rollback.sql
```

Esse rollback desfaz o hardening específico:

- remove triggers de integridade;
- remove a função `mesa_cliente_financeiro_assert_integridade()`;
- recria policies legadas duplicadas que existiam antes;
- recria índices legados duplicados que a migration removeu.

Importante: o rollback não restaura dados apagados, porque a migration de hardening não deve apagar dados de negócio. Ele apenas volta o desenho de policies/triggers/índices para o estado operacional anterior.

## Ordem segura

```text
1. Rodar 00_preflight_producao_readonly.sql
2. Gerar dump lógico local, se possível
3. Confirmar que o rollback SQL está disponível
4. Aplicar a migration de hardening
5. Rodar 01_postcheck_producao_readonly.sql
6. Se algum bloco crítico falhar, avaliar rollback imediato
7. Só depois avançar para RPCs
```

## Não fazer

- Não rodar o teste integrador grande em produção única.
- Não aplicar RPCs antes do postcheck passar.
- Não mexer no front antes da camada de banco estar validada.
- Não alterar parser, motor financeiro atual, Worker ou Make neste ciclo.

## Observação

Produção única exige disciplina. Aqui o objetivo não é correr, é não transformar uma melhoria de segurança em incêndio operacional.
