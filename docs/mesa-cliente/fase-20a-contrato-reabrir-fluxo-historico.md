# FECH.AI / MesaCliente — Fase 20A
# Contrato — Reabrir Fluxo pelo Histórico

## 1. Objetivo

Permitir que uma simulação salva no Histórico possa ser aberta novamente na experiência do Fluxo, com segurança, rastreabilidade e sem alterar o registro histórico original por acidente.

A Fase 20A inicia pelo modo mais seguro:

```text
Histórico -> obter detalhe completo da simulação -> reconstruir fluxo salvo -> visualizar/reabrir como base
```

## 2. Decisão arquitetural

A aba **Histórico** é a origem correta para reabrir uma mesa/simulação salva.

A aba **Operações financeiras** não deve virar editor de fluxo. Ela deve continuar dedicada a operações financeiras sobre simulações já criadas.

## 3. Modo inicial aprovado

A implementação inicial deve suportar:

1. **Visualizar fluxo salvo**: abrir os itens persistidos em `mesa_fluxo_pagamentos`.
2. **Preparar duplicação segura**: permitir que o fluxo salvo sirva como base para uma nova mesa/simulação posterior, preservando a original.

A edição direta da simulação histórica original fica fora do escopo inicial.

## 4. Princípios obrigatórios

- Multi-tenant obrigatório.
- Tenant-safe obrigatório.
- Autorização por `auth.uid()` obrigatória.
- RLS/RPC como fronteira de segurança.
- Nenhum payload soberano vindo do frontend.
- Sem `service_role` no frontend.
- Sem hardcoded por empresa, empreendimento ou usuário.
- Sem alteração de motor financeiro.
- Sem alteração de parser.
- Sem alteração de Worker/Make.
- Sem alteração de agenda financeira.
- Sem alteração de operações financeiras.
- Sem DML financeiro na leitura.

## 5. Nova RPC de leitura

Criar RPC read-only:

```sql
public.mesa_cliente_obter_simulacao_fluxo_historico(p_simulacao_id uuid, p_parametros jsonb default '{}'::jsonb)
returns jsonb
```

## 6. Responsabilidade da RPC

A RPC deve retornar, em JSONB:

- identificação da simulação;
- empresa;
- corretor;
- empreendimento;
- unidade;
- status;
- valores financeiros salvos;
- snapshot_payload;
- fluxo salvo em `mesa_fluxo_pagamentos`;
- flags de segurança para UI.

## 7. Segurança da RPC

A RPC deve:

- exigir `auth.uid()`;
- resolver o corretor ativo do usuário autenticado;
- validar a empresa da simulação;
- permitir acesso se:
  - root; ou
  - gestor/admin local da mesma empresa; ou
  - corretor dono da simulação;
- não aceitar `empresa_id` do frontend como fonte soberana;
- não alterar nenhum dado;
- não inserir auditoria nesta fase, por ser leitura pura.

## 8. Campos esperados da resposta

Estrutura esperada:

```json
{
  "ok": true,
  "readonly": true,
  "cliente_safe": false,
  "source": "historico",
  "simulacao": {
    "id": "uuid",
    "empresa_id": "uuid",
    "corretor_id": "uuid",
    "status": "rascunho",
    "oficial": false,
    "valor_total": 0,
    "entrada": 0,
    "financiamento": 0,
    "valor_final": 0,
    "versao": 1,
    "simulacao_origem_id": null,
    "snapshot_payload": {}
  },
  "empreendimento": {
    "id": "uuid",
    "nome": "texto",
    "incorporadora": "texto"
  },
  "unidade": {
    "id": "uuid",
    "unidade": "texto",
    "andar": 0,
    "metragem": 0,
    "valor_tabela": 0
  },
  "fluxo": [
    {
      "id": "uuid",
      "ordem": 0,
      "tipo": "entrada",
      "grupo": "e",
      "descricao": "Ato",
      "valor": 0,
      "quantidade": 1,
      "periodicidade": null,
      "data_prevista": "YYYY-MM-DD"
    }
  ],
  "ui_flags": {
    "pode_visualizar_fluxo": true,
    "pode_duplicar": true,
    "pode_editar_original": false,
    "motivo_edicao_original_bloqueada": "Edição direta de histórico fora do escopo da Fase 20A."
  }
}
```

## 9. Mapeamento tipo -> grupo visual

A RPC deve converter os tipos persistidos em `mesa_fluxo_pagamentos.tipo` para grupos visuais usados no frontend:

| tipo banco | grupo visual |
|---|---|
| `entrada` | `e` |
| `curto_prazo` | `c` |
| `periodica` | `m` |
| `intermediaria` | `a` |
| `quitacao` | `u` |
| `financiamento` | `f` |

## 10. Fora do escopo da Fase 20A

Não faz parte desta fase:

- editar diretamente a simulação histórica;
- sobrescrever `mesa_simulacoes` existente;
- excluir/recriar `mesa_fluxo_pagamentos`;
- aplicar operação financeira;
- confirmar/cancelar operação financeira;
- recalcular agenda;
- recalcular impacto financeiro;
- criar nova simulação derivada.

A criação de simulação derivada fica para fase posterior.

## 11. Critérios de PASS

A Fase 20A será considerada aprovada quando:

1. contrato estiver versionado;
2. RPC read-only existir;
3. RPC exigir autenticação;
4. RPC validar tenant/empresa/perfil;
5. RPC retornar simulação e fluxo salvo;
6. RPC retornar `readonly=true` e `cliente_safe=false`;
7. RPC não executar DML;
8. teste positivo com simulação do próprio tenant passar;
9. teste negativo cross-tenant/sem permissão bloquear;
10. nenhuma alteração no motor financeiro/parser/Worker/Make for feita.

## 12. Status

```text
Contrato criado.
Implementação planejada: RPC read-only + validações 20A/20B.
```
