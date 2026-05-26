# FECH.AI / MesaCliente — Fase 20C
# Contrato — Rastreabilidade de Valores do Fluxo Histórico e 2ª Via

## 1. Status

```text
Status: Proposto para aprovação técnica antes de migration/RPC/frontend.
Branch: feature/mesa-cliente-20c-rastreabilidade-valores
Base: main após PR #25
Risco previsto: R3/R4 quando houver migration/RPC/frontend com dados financeiros.
```

Este documento formaliza o contrato da Fase 20C antes de qualquer alteração de banco, RPC, frontend ou regra de fluxo.

Regra-mãe aplicada:

```text
Primeiro contrato. Depois evidência. Depois dry-run. Depois teste rollback. Depois persistência controlada.
```

## 2. Decisão de nomenclatura

Em conversa anterior, o tema apareceu como Fase 20B. Nesta continuidade, a branch oficial criada para a entrega é:

```text
feature/mesa-cliente-20c-rastreabilidade-valores
```

Portanto, a decisão canônica desta thread é:

```text
Fase 20C — Rastreabilidade de Valores do Fluxo Histórico e 2ª Via
```

Não criar fase paralela 20B para o mesmo escopo sem ADR de conflito.

## 3. Objetivo exato

A partir das novas propostas salvas, registrar e exibir rastreabilidade financeira por linha do fluxo:

- valor original;
- valor ajustado/final;
- diferença absoluta;
- diferença percentual;
- indicador se houve ajuste manual;
- origem do valor original;
- origem do valor ajustado;
- usuário/corretor que salvou a proposta;
- vínculo com a simulação e com a linha final em `mesa_fluxo_pagamentos`.

A 2ª via read-only deve exibir essas informações quando existirem, sem recalcular proposta antiga.

## 4. Problema comprovado

O histórico/2ª via atual lê o fluxo final persistido em `public.mesa_fluxo_pagamentos`.

A linha final contém `valor` e `quantidade`, mas não carrega, no retorno atual da RPC de 2ª via, os campos de comparação original x ajustado.

Consequência:

```text
Se o usuário altera o Ato de R$ 226.984 para R$ 408.000, a 2ª via mostra apenas R$ 408.000.
```

Isso impede rastreabilidade comercial e prepara mal o terreno para operações financeiras futuras.

## 5. Escopo da Fase 20C

Dentro do escopo:

1. Registrar rastreabilidade de valores em propostas novas.
2. Preservar `mesa_fluxo_pagamentos` como estado final vigente.
3. Criar camada lateral/auditável para original x ajustado.
4. Calcular diferença absoluta e percentual no backend/RPC.
5. Exibir rastreabilidade na 2ª via read-only.
6. Não recuperar propostas antigas obrigatoriamente.
7. Manter compatibilidade com futuras camadas de operações financeiras.

Fora do escopo:

1. Recalcular motor financeiro.
2. Alterar parser.
3. Alterar Worker/Make/n8n.
4. Alterar regra central de agenda.
5. Alterar operação financeira, antecipação, amortização, juros ou VPL.
6. Editar simulação histórica original.
7. Expor VPL, prêmio, comissão, política interna, margem ou taxa interna em cliente-safe.
8. Fazer recuperação retroativa obrigatória de propostas antigas.

## 6. Pipeline aprovado para a fase

```text
1. Parser / tabela / unidade oficial
2. Normalização do fluxo base
3. Geração de baseline imutável da proposta
4. Usuário edita fluxo na tela
5. Salvamento da proposta
6. Backend/RPC calcula diff original x ajustado
7. Persistência da simulação + fluxo final + auditoria
8. 2ª via read-only exibe rastreabilidade
9. Futuro: operações financeiras
   - antecipação
   - amortização
   - juros
   - VPL
   - comparação de cenários
```

## 7. Princípio arquitetural

A rastreabilidade não é motor financeiro.

Ela é camada lateral/auditável.

`mesa_fluxo_pagamentos` deve continuar representando o estado final vigente da proposta:

```text
Ato: R$ 408.000
+30 dias: R$ 100.882
Parcela única: R$ X
Financiamento: R$ Y
```

A nova camada deve explicar:

```text
de onde veio;
quanto mudou;
quem salvou;
quando salvou;
qual era o valor original;
qual ficou o valor final.
```

Operações futuras devem incidir sobre o fluxo final salvo. A diferença original x ajustado não deve alterar a base de cálculo operacional futura por si só.

## 8. Modelo de persistência proposto

Não adicionar campos soltos e desorganizados em `mesa_fluxo_pagamentos`.

Criar tabela lateral:

```sql
public.mesa_fluxo_pagamentos_auditoria
```

Campos propostos:

```text
id uuid primary key
empresa_id uuid not null
simulacao_id uuid not null
fluxo_pagamento_id uuid not null
grupo text null
tipo text null
descricao text null
ordem integer null
valor_original numeric not null
valor_ajustado numeric not null
diferenca_valor numeric not null
diferenca_percentual numeric null
foi_alterado boolean not null
origem_valor_original text not null
origem_valor_ajustado text not null
alterado_por uuid null
alterado_por_user_id uuid null
alterado_em timestamptz not null default now()
metadata jsonb not null default '{}'::jsonb
created_at timestamptz not null default now()
```

Observação: nomes finais de FK, índices, constraints, RLS e grants só devem ser fechados após validação do schema real no Supabase.

## 9. Regra de cálculo

```text
diferenca_valor = valor_ajustado - valor_original
```

```text
diferenca_percentual =
  se valor_original > 0:
    ((valor_ajustado - valor_original) / valor_original) * 100
  senão:
    null
```

Exemplo:

```text
Ato
Valor original: R$ 226.984
Valor ajustado: R$ 408.000
Diferença: +R$ 181.016
Variação: +79,75%
Badge: Ajustado manualmente
```

## 10. Regra de baseline

O sistema precisa registrar o baseline original da proposta no momento do salvamento das novas propostas.

Estado verificado no GitHub:

```text
A RPC atual recebe p_fluxo_json e grava o valor final em mesa_fluxo_pagamentos.
O fluxo inicial é montado no frontend a partir do parser/tabela/unidade.
O p_fluxo_json atual não contém, de forma obrigatória, valor_original por linha.
```

Decisão proposta para 20C, sem alterar a assinatura da RPC existente:

```text
1. O frontend passará a enviar, dentro de cada item de p_fluxo_json, campos de baseline:
   - valor_original
   - origem_valor_original
   - baseline_key/metadados mínimos de pareamento

2. A RPC public.criar_mesa_simulacao continuará recebendo p_fluxo_json.

3. A RPC calculará no banco:
   - valor_ajustado = valor final recebido para a linha
   - diferenca_valor
   - diferenca_percentual
   - foi_alterado

4. A RPC persistirá o fluxo final em mesa_fluxo_pagamentos e a rastreabilidade em mesa_fluxo_pagamentos_auditoria.
```

Importante:

```text
O frontend não será fonte soberana de empresa, tenant, perfil, permissão, corretor ou autorização.
```

O baseline enviado pelo frontend será usado como insumo operacional de rastreabilidade da proposta, não como fonte de autorização.

Se for necessário elevar o grau de confiança do baseline em fase futura, criar etapa própria de baseline server-side/pre-simulação, com contrato separado.

## 11. Compatibilidade com propostas antigas

Para propostas antigas sem auditoria:

```text
valor_original = não disponível
valor_ajustado = valor final salvo
foi_alterado = não disponível ou false por ausência de evidência
```

A 2ª via deve evitar inventar diferença.

Texto visual recomendado quando não houver auditoria:

```text
Rastreabilidade não disponível para esta proposta.
```

ou por linha:

```text
Sem histórico de ajuste manual registrado.
```

Nunca reconstruir diferença retroativa por dedução visual.

## 12. Retorno esperado da RPC de 2ª via

A RPC `public.mesa_cliente_obter_simulacao_fluxo_historico` deve continuar read-only.

Campos adicionais por item de fluxo quando houver auditoria:

```json
{
  "id": "uuid",
  "ordem": 0,
  "tipo": "entrada",
  "grupo": "e",
  "descricao": "Ato",
  "valor": 408000,
  "quantidade": 1,
  "total": 408000,
  "rastreabilidade": {
    "disponivel": true,
    "valor_original": 226984,
    "valor_ajustado": 408000,
    "diferenca_valor": 181016,
    "diferenca_percentual": 79.75,
    "foi_alterado": true,
    "origem_valor_original": "parser_initial_fluxo",
    "origem_valor_ajustado": "usuario_fluxo_final",
    "alterado_em": "timestamp"
  }
}
```

Para linha sem auditoria:

```json
{
  "rastreabilidade": {
    "disponivel": false,
    "foi_alterado": false
  }
}
```

## 13. Regras visuais para 2ª via

Para linha alterada:

```text
Ato
Valor ajustado: R$ 408.000
Original: R$ 226.984
Diferença: +R$ 181.016 (+79,75%)
Badge: Ajustado manualmente
```

Para linha sem alteração, mas com auditoria:

```text
+30 dias
R$ 100.882
Sem ajuste manual
```

Para linha sem auditoria:

```text
+30 dias
R$ 100.882
Rastreabilidade não disponível para esta proposta.
```

## 14. Matriz DML prevista

### 14.1 Salvamento de nova proposta com rastreabilidade

| Tabela | SELECT | INSERT | UPDATE | DELETE |
|---|---:|---:|---:|---:|
| `public.corretores` | Sim | Não | Não | Não |
| `public.empreendimentos` | Sim | Não | Não | Não |
| `public.unidades_estoque` | Sim | Não | Não | Não |
| `public.mesa_simulacoes` | Não/Sim conforme função atual | Sim | Não | Não |
| `public.mesa_fluxo_pagamentos` | Não/Sim conforme função atual | Sim | Não | Não |
| `public.mesa_fluxo_pagamentos_auditoria` | Não/Sim | Sim | Não | Não |
| `public.audit_logs` | Não | Sim | Não | Não |

### 14.2 2ª via read-only

| Tabela | SELECT | INSERT | UPDATE | DELETE |
|---|---:|---:|---:|---:|
| `public.corretores` | Sim | Não | Não | Não |
| `public.mesa_simulacoes` | Sim | Não | Não | Não |
| `public.mesa_fluxo_pagamentos` | Sim | Não | Não | Não |
| `public.mesa_fluxo_pagamentos_auditoria` | Sim | Não | Não | Não |
| `public.empreendimentos` | Sim | Não | Não | Não |
| `public.unidades_estoque` | Sim | Não | Não | Não |

## 15. Segurança obrigatória

A implementação futura deve preservar:

- `auth.uid()` obrigatório;
- corretor ativo obrigatório;
- empresa/tenant resolvido pelo banco;
- empreendimento validado contra empresa;
- unidade validada contra empresa e empreendimento;
- simulação validada contra empresa;
- `anon` sem `EXECUTE` em RPC sensível;
- `service_role` proibido no frontend;
- sem dados sensíveis cliente-safe;
- sem payload soberano de `empresa_id`, `tenant_id`, perfil ou permissão vindo do frontend.

## 16. Grants/RLS previstos

A tabela de auditoria deve ter RLS habilitada.

A escrita direta pela aplicação deve ser proibida.

A persistência deve ocorrer por RPC `security definer` já autorizada, com validação explícita.

Grants previstos:

```text
- revoke all from public/anon na tabela ou RPC sensível, quando aplicável.
- grant execute apenas para authenticated na RPC necessária.
- não conceder insert/update/delete direto para anon.
```

Detalhes finais dependem de inspeção do schema real aplicado no Supabase.

## 17. Testes obrigatórios

A entrega só pode ser considerada PASS com output real.

Testes mínimos:

1. Positivo: criar nova proposta Chateau Jardin alterando Ato.
2. Positivo: criar nova proposta Chateau Jardin alterando Parcela Única.
3. Validar `mesa_fluxo_pagamentos` com valor final.
4. Validar `mesa_fluxo_pagamentos_auditoria` com original, ajustado, diferença e percentual.
5. Validar 2ª via exibindo rastreabilidade.
6. Negativo: proposta antiga sem auditoria não inventa diferença.
7. Permissão: corretor dono acessa.
8. Permissão: gestor do mesmo time acessa.
9. Bloqueio: gestor de outro time não acessa.
10. Bloqueio: corretor não dono não acessa.
11. Bloqueio: outro tenant/empresa não acessa.
12. Bloqueio: anon sem execute em RPC sensível.
13. Rollback: teste com `BEGIN` + `ROLLBACK` para provar comportamento sem persistência indevida quando aplicável.

## 18. Critério de aceite

A Fase 20C será aceita quando:

1. contrato estiver versionado;
2. migration estiver criada após validação de schema real;
3. tabela de auditoria existir com RLS/grants seguros;
4. salvamento de nova proposta registrar fluxo final + auditoria;
5. backend calcular diferença absoluta e percentual;
6. 2ª via read-only retornar rastreabilidade;
7. UI exibir original, ajustado, diferença, percentual e badge;
8. proposta antiga sem auditoria não gerar dado inventado;
9. testes reais apresentarem PASS com output;
10. não houver alteração de parser, Worker/Make/n8n, motor financeiro, agenda ou operações financeiras.

## 19. Critério de bloqueio

Bloquear a fase se ocorrer qualquer item abaixo:

- drift GitHub x Supabase não explicado;
- schema real divergente do versionado;
- migration falhar;
- RLS/grant permitir acesso indevido;
- anon conseguir executar RPC sensível;
- cross-tenant acessar dado;
- frontend enviar payload soberano de permissão;
- 2ª via inventar rastreabilidade para proposta antiga;
- cálculo percentual divergente da fórmula definida;
- teste rollback falhar;
- qualquer alteração em parser, Worker/Make/n8n ou motor financeiro fora do escopo.

## 20. Rollback previsto

Rollback de teste:

```sql
BEGIN;
-- executar cenário controlado
ROLLBACK;
```

Rollback de migration aplicada:

```text
Criar migration corretiva posterior.
Não apagar migration já aplicada como se nada tivesse acontecido.
Documentar impacto e estado final.
```

Rollback de frontend:

```text
Reverter commit da 20C ou desabilitar exibição de rastreabilidade mantendo retorno read-only compatível.
```

## 21. Próximo passo único

Antes de criar migration:

```text
Validar schema real aplicado no Supabase:
- mesa_simulacoes
- mesa_fluxo_pagamentos
- audit_logs
- corretores
- empreendimentos
- unidades_estoque
- grants/RLS/policies/triggers
- migrations aplicadas
```

Sem essa validação, a migration definitiva não deve ser criada.
