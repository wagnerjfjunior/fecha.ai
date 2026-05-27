# FECH.AI / MesaCliente — Fase 20C.1
# Checklist — Preflight de Estado Real e Reconciliação GitHub x Supabase

## 1. Status

```text
Status: PLANEJADO / READ-ONLY
Branch: feature/mesa-cliente-20c-rastreabilidade-valores
Tipo: preflight documental e técnico
DDL permitido: NÃO
DML permitido: NÃO
Migration permitida: NÃO
RPC nova permitida: NÃO
Frontend permitido: NÃO
```

Objetivo:

```text
Verificar o estado real do Supabase e reconciliar banco real, GitHub e documentação antes de decidir a próxima trilha do MesaCliente.
```

## 2. Motivo

A rastreabilidade original x final foi identificada como pendência real na 2ª via, mas não deve virar implementação automática.

Antes de decidir entre:

```text
A) histórico/2ª via;
B) engenharia financeira canônica;
C) piloto controlado de mesa;
```

é obrigatório conhecer o estado real aplicado no Supabase.

## 3. Regras do preflight

```text
- Executar somente consultas read-only.
- Não criar fixture permanente.
- Não executar DDL.
- Não executar DML.
- Não criar função temporária em produção.
- Não alterar grants.
- Não alterar policies.
- Não alterar RLS.
- Não alterar migrations.
- Não considerar PASS sem output real.
- Registrar WARN quando a ausência de massa real impedir teste funcional.
```

Preferência operacional:

```sql
start transaction read only;
-- consultas de inventário
rollback;
```

## 4. Objetos a inventariar

### 4.1 Tabelas do fluxo histórico atual

```text
public.mesa_simulacoes
public.mesa_fluxo_pagamentos
public.audit_logs
```

### 4.2 Tabelas da engenharia financeira canônica

```text
public.mesa_cliente_agendas_financeiras
public.mesa_cliente_fluxo_parcelas
public.mesa_cliente_fluxo_operacoes
public.mesa_cliente_politicas_financeiras
public.mesa_cliente_politica_premio_faixas
```

### 4.3 Tabelas de contexto e autorização

```text
public.corretores
public.empresas
public.empreendimentos
public.unidades_estoque
```

### 4.4 RPCs/funções críticas

```text
public.criar_mesa_simulacao(...)
public.mesa_cliente_obter_simulacao_fluxo_historico(uuid,jsonb)
public.mesa_cliente_gerar_agenda_financeira_admin(uuid,date,jsonb,jsonb)
public.mesa_cliente_persistir_agenda_financeira_admin(uuid,date,jsonb,jsonb)
public.mesa_cliente_obter_agenda_financeira_cliente_safe(uuid)
public.mesa_cliente_registrar_operacao_financeira_admin(uuid,uuid,text,uuid,date,date,numeric,jsonb)
public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

Observação:

```text
Assinaturas reais devem ser confirmadas no catálogo pg_proc. Não deduzir por documentação.
```

## 5. Checklist de tabelas

Para cada tabela listada:

```text
[ ] existe no schema public
[ ] colunas reais inventariadas
[ ] tipos reais inventariados
[ ] constraints principais inventariadas
[ ] índices relevantes inventariados
[ ] RLS habilitada/desabilitada registrado
[ ] policies inventariadas
[ ] grants diretos inventariados
[ ] divergência contra GitHub/documentação registrada
```

## 6. Checklist de RPCs

Para cada RPC/função crítica:

```text
[ ] existe no catálogo pg_proc
[ ] assinatura real registrada
[ ] volatility registrada
[ ] SECURITY DEFINER/INVOKER registrado
[ ] search_path registrado
[ ] grants EXECUTE registrados
[ ] anon bloqueado quando sensível
[ ] authenticated liberado quando aplicável
[ ] comentário de catálogo registrado quando aplicável
[ ] divergência contra GitHub/documentação registrada
```

## 7. Checklist de segurança

```text
[ ] auth.uid() é exigido nas RPCs sensíveis conforme contrato
[ ] empresa/tenant é resolvido pelo banco/RPC
[ ] frontend não possui service_role
[ ] anon não possui DML direto nas tabelas financeiras sensíveis
[ ] authenticated não possui escrita direta indevida nas tabelas financeiras sensíveis
[ ] policies não confiam em empresa_id vindo do frontend como autoridade final
[ ] RPCs administrativas não expõem payload cliente-safe
[ ] RPCs cliente-safe não expõem VPL, prêmio, comissão, política interna, checksum ou metadata sensível
```

## 8. Checklist de dados/massa real

Registrar, sem expor dados sensíveis:

```text
[ ] existe simulação real acessível para histórico/2ª via
[ ] existe fluxo em mesa_fluxo_pagamentos
[ ] existe agenda ativa em mesa_cliente_agendas_financeiras
[ ] existe parcela em mesa_cliente_fluxo_parcelas
[ ] existe operação financeira em mesa_cliente_fluxo_operacoes
[ ] existe operação confirmada
[ ] existe operação visivel_cliente=true
[ ] existe massa suficiente para reexecutar smoke Fase 6 sobre operação real
```

Quando não houver massa:

```text
Status correto: SKIP_DATA ou WARN_DATA
Não usar PASS funcional sem execução real.
```

## 9. Checklist GitHub x Supabase

```text
[ ] migrations aplicadas listadas no Supabase
[ ] última migration financeira aplicada identificada
[ ] migrations da branch/main comparadas com tabela de migrations aplicada
[ ] funções do banco comparadas com migrations versionadas
[ ] diferenças classificadas como OK/WARN/BLOCKER
[ ] drift explicado antes de qualquer próxima fase
```

## 10. Saída esperada do preflight

Criar documento posterior:

```text
docs/mesa-cliente/fase-20c1-relatorio-preflight-estado-real.md
```

Conteúdo mínimo:

```text
1. ambiente/branch/base analisada;
2. lista de objetos encontrados;
3. lista de objetos ausentes;
4. diferenças GitHub x Supabase;
5. avaliação de segurança;
6. massa real disponível;
7. bloqueios;
8. WARNs;
9. recomendação de próxima trilha: A, B ou C;
10. decisão sobre rastreabilidade: manter pendente, implementar histórico, absorver na engenharia canônica ou piloto.
```

## 11. Critério de PASS

O preflight 20C.1 só pode ser considerado PASS quando:

```text
- todos os objetos críticos forem inventariados;
- grants/RLS/policies forem registrados;
- RPCs críticas forem conferidas no catálogo;
- GitHub x Supabase for reconciliado;
- divergências forem classificadas;
- não houver blocker sem plano;
- relatório final for versionado.
```

## 12. Critério de bloqueio

Bloquear próxima fase se ocorrer:

```text
- schema real divergente sem explicação;
- função crítica ausente;
- anon com EXECUTE indevido em RPC sensível;
- anon ou authenticated com DML direto indevido em tabela financeira sensível;
- RLS ausente onde deveria estar ativa;
- migration aplicada fora do GitHub sem documentação;
- documentação afirmando PASS sem output real;
- massa real inexistente sendo tratada como PASS funcional.
```

## 13. Próxima decisão após 20C.1

Com o relatório em mãos, escolher explicitamente:

```text
A) Histórico/2ª via:
   melhorar rastreabilidade comercial do fluxo salvo.

B) Engenharia financeira canônica:
   avançar agenda/parcelas/operações/resumo com mesa_cliente_fluxo_parcelas como fonte estrutural.

C) Piloto controlado de mesa:
   testar fluxo real com menor alteração possível antes de criar novas camadas.
```

Sem essa decisão, nenhuma implementação de rastreabilidade deve avançar.
