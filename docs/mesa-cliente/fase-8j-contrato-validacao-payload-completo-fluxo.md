# FECH.AI / MesaCliente — Fase 8J
# Contrato 19D — Validação do payload completo do Fluxo

## 1. Objetivo

Este documento define o contrato técnico da validação **19D — payload completo do Fluxo**.

O objetivo é provar, em camada estática, que a tela de Fluxo do MesaCliente está preparada para enviar para a RPC `public.criar_mesa_simulacao` todas as parcelas visíveis/relevantes do fluxo de pagamento, incluindo:

- entrada / ato;
- complementos de curto prazo;
- mensais;
- intermediárias anuais ou semestrais;
- parcela única / chaves;
- saldo de financiamento calculado por diferença.

A validação 19D existe porque a correção anterior resolveu o erro de persistência, mas a evidência de runtime pode variar conforme a unidade selecionada. Algumas unidades podem ter somente ato + financiamento, enquanto outras possuem mensais, intermediárias e parcela única. Portanto, o sucesso de uma gravação com apenas `ato` não deve ser usado sozinho como prova de cobertura completa do fluxo.

## 2. Escopo

### Dentro do escopo

- Validar que o parser visual do fluxo reconhece os campos financeiros importados.
- Validar que a parcela única/chaves é preservada como grupo `u` no frontend.
- Validar que o serializador envia os grupos `e`, `c`, `m`, `a` e `u` para `p_fluxo_json`.
- Validar que a parcela única/chaves entra no cálculo do pagamento antes do financiamento.
- Validar que o financiamento é calculado por diferença e não enviado como uma parcela editável do fluxo.
- Validar que o frontend não usa `service_role`, não injeta tenant/empresa soberana além do contexto autenticado e não executa DDL/DML financeiro.

### Fora do escopo

- Alterar parser.
- Alterar Worker/Make.
- Alterar motor financeiro.
- Alterar agenda financeira.
- Alterar parcelas no banco.
- Alterar RPCs de persistência.
- Criar novas regras de negócio.
- Recalcular operação financeira.

## 3. Premissas preservadas

A validação 19D deve respeitar as premissas já estabilizadas no projeto:

- multi-tenant;
- tenant-safe;
- RLS/RPC como fronteira de segurança;
- `auth.uid()` como base de identidade no banco;
- regras críticas no Supabase/RPC;
- frontend como camada de UX, não como fonte soberana de segurança;
- sem `service_role` no frontend;
- sem hardcoded por empreendimento;
- sem alteração de agenda, parcelas ou operação financeira.

## 4. Contrato de grupos do fluxo

O payload `p_fluxo_json` deve usar os seguintes grupos técnicos no frontend:

| Grupo | Significado visual | Origem típica |
|---|---|---|
| `e` | Entrada / Ato | `sinal_1`, `ato_qtd` |
| `c` | Complementos curto prazo | `a4_each`, `comp_qtd` |
| `m` | Mensais | `mensal_each`, `mensal_qtd` |
| `a` | Intermediárias anuais/semestrais | `inter_each`, `inter_qtd`, `inter_tipo` |
| `u` | Parcela única / Chaves | `chaves_each`, `unica_qtd`, `unica` |

O grupo `u` é deliberadamente mantido no frontend como grupo visual de chaves/parcela única. A conversão para o enum real do banco é responsabilidade da RPC corrigida na Fase 8I/19C, onde `u` deve ser persistido como `quitacao`, não como `unica`.

## 5. Regra específica — parcela única

Alguns empreendimentos possuem parcela única. Essa parcela não pode ser descartada no payload.

A regra esperada é:

- se `chaves_each > 0` e `unica_qtd > 0`, o fluxo deve conter grupo `u`;
- se `unica_qtd <= 1`, o label visual pode ser `Parcela única`;
- se `unica_qtd > 1`, o label visual pode ser `Chaves`;
- a data de referência deve vir de `meta.unica` quando existir;
- o valor deve entrar no pagamento antes do financiamento;
- o saldo financiado deve diminuir conforme a parcela única/chaves aumenta.

## 6. Regra de financiamento

O financiamento não é enviado como parcela do fluxo.

O financiamento é derivado:

```text
financiamento = valor_total - pagamento_fluxo
```

Onde:

```text
pagamento_fluxo = entrada + complementos + mensais + intermediárias + parcela_unica/chaves
```

Essa regra evita duplicidade e preserva a lógica de o banco recalcular/persistir a agenda oficial.

## 7. Leitura de evidência de runtime

Uma gravação real com payload contendo somente:

```json
[{ "grupo": "e", "id": "ato" }]
```

não significa necessariamente erro. Pode ser uma unidade cujo parser trouxe somente ato + financiamento.

Porém, essa evidência também não prova cobertura completa do fluxo. Para provar cobertura completa em runtime, será necessário testar uma unidade cujo payload importado contenha, no mínimo:

- `sinal_1`;
- `a4_each` + `comp_qtd`;
- `mensal_each` + `mensal_qtd`;
- `inter_each` + `inter_qtd`;
- `chaves_each` + `unica_qtd`.

O 19D fecha a validação estática da preparação do frontend. A confirmação final de runtime continua exigindo HAR ou artifact real.

## 8. Critérios de aprovação do 19D

O teste 19D deve retornar `PASS` quando comprovar:

1. os arquivos-base existem;
2. o contrato 8J existe;
3. `TabFluxo.jsx` monta os grupos `e`, `c`, `m`, `a`, `u` a partir do parser;
4. `TabFluxo.jsx` reconhece `chaves_each`, `unica_qtd` e `meta.unica`;
5. `FluxoBuilder.jsx` exibe/permite o grupo `u` quando `initialFluxo.u` existir;
6. `useMesaCalc.js` serializa todos os grupos para `p_fluxo_json`;
7. `useMesaCalc.js` inclui `vU` no pagamento antes do financiamento;
8. não existe uso de `service_role` no frontend inspecionado;
9. não há alteração de banco, parser, Worker/Make, agenda ou motor financeiro nesta fase.

## 9. Status esperado

- Tipo: validação estática.
- Camada: frontend / contrato de payload.
- Risco: baixo.
- DML financeiro: não.
- DDL: não.
- Alteração de RPC: não.
- Alteração de parser: não.
- Alteração do motor financeiro: não.
- Necessita evidência de runtime posterior: sim.

## 10. Resultado esperado do artifact

O artifact `19d_resultado.json` deve terminar com:

```json
{
  "bloco": "99_readiness_19d_payload_completo_fluxo",
  "status": "PASS",
  "detalhe": {
    "fail_count": 0
  }
}
```

Se qualquer bloco retornar `FAIL`, a fase 8J não deve ser considerada fechada.
