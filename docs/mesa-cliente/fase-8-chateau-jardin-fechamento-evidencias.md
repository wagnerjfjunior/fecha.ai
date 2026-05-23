# FECH.AI / MesaCliente — Fase 8

## Fechamento técnico — Chateau Jardin

### Status

**Fase 8 encerrada operacionalmente para o Chateau Jardin.**

O empreendimento foi importado, validado e está simulando no MesaCliente de forma equivalente aos demais empreendimentos já suportados.

Este documento registra as evidências técnicas e os pontos que ficam como regra operacional para cargas futuras.

---

## 1. Escopo fechado

| Item | Status | Observação |
|---|---:|---|
| Chateau Jardin importado | PASS | Empreendimento existente no banco. |
| Snapshot ativo pós-importação | PASS | Snapshot ativo encontrado e processado. |
| Unidades importadas | PASS | Base carregada no snapshot ativo. |
| Valores financeiros | PASS | Valores validados no banco e no fluxo de simulação. Valores reais não são reproduzidos neste documento por serem dados comerciais sensíveis. |
| Simulação | PASS | Simulação funcional, com comportamento equivalente aos demais empreendimentos. |
| Prumada/andar | PASS | Regra operacional corrigida e validada. |
| Gardens | PASS | Gardens tratados com andar 0 quando aplicável. |
| Hardening de RPCs administrativas | PASS | `anon`/`public` sem execute nas RPCs administrativas de importação. |

---

## 2. Regra operacional validada para unidade, andar e prumada

Para o Chateau Jardin, a regra operacional validada é:

```text
primeiro dígito da unidade = prumada operacional
últimos dois dígitos da unidade = andar/pavimento
Gardens = andar 0, quando aplicável
```

Exemplos validados no banco:

```text
201 => prumada operacional 2 / andar 01
102 => prumada operacional 1 / andar 02
514 => prumada operacional 5 / andar 14
100 / 300 / 500 => Gardens / andar 0, quando aplicável
```

Observação técnica: na tabela `unidades_estoque`, a coluna usada como prumada operacional é `final`. A tabela não possui uma coluna física chamada `prumada`.

---

## 3. Torres e prumadas

A validação read-only confirmou a seguinte distribuição operacional:

| Torre registrada | Prumadas operacionais |
|---|---:|
| Harmonie Vert e Gris | 1, 2, 3, 4, 5, 6 |
| Lumière Bleu e Blanc | 1, 2, 3, 4 |

### Ponto de atenção

A separação fina entre **Vert** e **Gris**, e entre **Bleu** e **Blanc**, não está persistida em campo próprio. O banco registra a torre como texto composto:

```text
Harmonie Vert e Gris
Lumière Bleu e Blanc
```

Portanto, a pergunta “qual prumada é Vert, qual é Gris, qual é Bleu e qual é Blanc?” só deve ser respondida com base em espelho oficial, memorial ou tabela de origem que traga essa separação. Sem esse artefato, não devemos inferir por heurística.

### Decisão

Para a Fase 8, esta ausência de subtipo separado **não bloqueia** a operação, porque a simulação e a identificação comercial foram validadas com torre + unidade + final/prumada operacional + andar.

Para cargas futuras, recomenda-se adicionar o campo de subtipo quando houver espelho oficial:

```text
torre_grupo: Harmonie / Lumière
subtorre: Vert / Gris / Bleu / Blanc
prumada_operacional: final
andar: pavimento calculado
```

---

## 4. Chave operacional correta

Não usar `unidade` isolada como chave de unicidade, porque há múltiplas torres.

Chave operacional validada:

```text
torre + unidade + final/prumada_operacional + andar
```

A validação por chave composta passou sem duplicidade real.

---

## 5. Hardening das RPCs administrativas

Foi executado hardening nas RPCs administrativas de importação JSON, removendo execute de `anon` e `public` e mantendo execute apenas para `authenticated` e `service_role`.

RPCs envolvidas:

```text
public.importar_mesa_cliente_json_admin(uuid,text,text,text,text,text,text,jsonb)
public.importar_mesa_cliente_parser_resultado(uuid,text,text,text,text,text,text,jsonb)
public.usuario_pode_importar_mesa_json_admin(uuid)
```

Resultado esperado pós-hardening:

```text
anon_execute = false
public_execute = false
authenticated_execute = true
service_role_execute = true
```

---

## 6. Carga mensal futura

A próxima tabela mensal do Chateau Jardin pode ser carregada com segurança operacional, desde que siga o mesmo contrato:

1. manter o mesmo empreendimento;
2. criar novo snapshot, sem destruir histórico anterior;
3. preservar torre, unidade, final/prumada operacional e andar;
4. preservar valores financeiros necessários à simulação;
5. não usar `unidade` isolada como chave;
6. executar smoke read-only pós-importação;
7. validar amostras estruturais e financeiras;
8. validar disponibilidade via espelho oficial.

A carga mensal deve ser tratada como atualização de snapshot, não como recriação estrutural do empreendimento.

---

## 7. Espelho de disponibilidade

Para identificar unidades vendidas, disponíveis, reservadas ou indisponíveis, a próxima evolução deve incorporar o espelho oficial de disponibilidade.

### Regras propostas

| Situação | Tratamento recomendado |
|---|---|
| Unidade existe no snapshot anterior e no novo | Atualizar valores/status conforme nova carga. |
| Unidade existe no anterior e não aparece no novo | Não assumir vendida automaticamente; classificar como ausente na carga e exigir espelho. |
| Unidade aparece no espelho como vendida | Marcar como vendida/indisponível conforme regra comercial. |
| Unidade aparece no espelho como disponível | Manter disponível para simulação e front. |
| Unidade muda torre/final/andar | Bloquear e revisar manualmente, pois é dado estrutural. |
| Valor muda | Aceitar como nova tabela, preservando snapshot anterior. |

### Decisão

A disponibilidade comercial deve vir do espelho oficial, não de inferência por ausência na tabela de preços.

---

## 8. Ponte para a próxima fase

Com o Chateau Jardin encerrado operacionalmente, o próximo trabalho deve ser ativar a engenharia financeira no front:

```text
visualizar desconto por antecipação de parcelas
visualizar amortização
exibir resumo financeiro administrativo
exibir visão cliente-safe quando aplicável
conectar as RPCs das Fases 6 e 7 ao frontend
```

### RPCs já existentes no fluxo financeiro

```text
public.mesa_cliente_resumir_operacao_financeira_admin(uuid,jsonb)
public.mesa_cliente_obter_resumo_operacao_cliente_safe(uuid,jsonb)
public.mesa_cliente_aplicar_operacao_financeira_admin(uuid,jsonb)
```

### Critério de transição

A Fase 8 não deve mais bloquear a ativação do front financeiro. O próximo escopo deve ser tratado como nova fase de integração frontend/engenharia financeira.

---

## 9. Decisão final

```text
Fase 8 / Chateau Jardin: FECHADA operacionalmente.
Status: importado, corrigido, validado e simulando.
Pendência não bloqueante: separação fina Vert/Gris/Bleu/Blanc depende de espelho oficial.
Próxima etapa: ativação da engenharia financeira no front.
```
