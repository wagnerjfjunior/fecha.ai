# FECH.AI — Mesa Cliente — Mirror Engine Garden Design v1.0.0

## Objetivo

Documentar a primeira fundação do **Espelho de Vendas** dentro do Mesa Cliente nativo do FECH.AI, usando o empreendimento **Garden Design Private Park Residence** como caso real.

O objetivo operacional é cruzar:

1. **Tabela oficial de preço** — fonte dos valores, fluxos e condições.
2. **Espelho oficial de vendas** — fonte do status operacional da unidade.
3. **Mesa Cliente** — motor que apresenta somente o que pode ser ofertado com segurança.

---

## Contexto de negócio

O corretor trabalha com tabela oficial, mas não pode vender tudo que está na tabela.

A unidade só deve ser ofertada se estiver disponível no espelho de vendas.

No Garden Design:

- unidades brancas no espelho indicam disponibilidade;
- unidades azuis indicam vendidas/escrituradas;
- outras cores representam estados operacionais como reservado, contrato em processo, contrato assinado, permuta, fora de venda ou bloqueio;
- vagas e lojas podem aparecer no espelho visual, mas não necessariamente fazem parte da mesma contagem residencial da tabela de unidades.

---

## Separação conceitual obrigatória

### Tabela de preço

Responsável por:

- preço total;
- ato;
- complemento;
- mensais;
- anuais/intermediárias;
- financiamento;
- periodicidade;
- competência mensal;
- atualização por INCC.

### Espelho de vendas

Responsável por:

- status da unidade;
- disponibilidade real;
- vendido/reservado/bloqueado;
- contrato em processo;
- contrato assinado;
- permuta;
- unidades inexistentes no pavimento.

### Regra fundamental

A tabela não define disponibilidade.  
O espelho não define preço.  
O FECH.AI cruza as duas fontes.

---

## Arquivos implementados

### `src/mesa/mirror/normalizeMirrorStatus.js`

Normaliza status vindos de legenda, cor, texto ou parser.

Status normalizados:

- `disponivel`
- `vendida`
- `reservada`
- `bloqueada`
- `fora_de_venda`
- `contrato_processo`
- `contrato_assinado`
- `permuta`
- `inexistente`
- `desconhecido`

Também retorna:

- label amigável;
- severidade operacional;
- `can_sell`;
- `requires_confirmation`.

### `src/mesa/mirror/reconcileUnitsWithMirror.js`

Cruza linhas da tabela de preço com unidades extraídas do espelho.

Responsabilidades:

- normalizar códigos de unidade;
- aceitar formatos como `AP1401`, `1401`, `Unidade 1401`, `VG0300`, `LJ0001`;
- montar índice do espelho;
- anexar status operacional à linha de preço;
- indicar se a unidade pode ser vendida;
- marcar linhas sem correspondência para conferência.

---

## Modelo de conciliação

Entrada esperada da tabela:

```json
{
  "codigo_unidade": "AP1401",
  "area_m2": 62.78,
  "preco_total": 725034
}
```

Entrada esperada do espelho:

```json
{
  "codigo_unidade": "AP1401",
  "status": "branco"
}
```

Saída reconciliada:

```json
{
  "codigo_unidade": "AP1401",
  "area_m2": 62.78,
  "preco_total": 725034,
  "mirror": {
    "matched": true,
    "can_sell": true,
    "units": [
      {
        "codigo_unidade": "AP1401",
        "mirror_status": "disponivel",
        "mirror_label": "Disponível"
      }
    ]
  }
}
```

---

## Regra comercial inicial

| Status normalizado | Pode vender? | Comportamento UI |
|---|---:|---|
| disponivel | Sim | liberar simulação |
| vendida | Não | bloquear proposta |
| reservada | Não direto | exigir confirmação |
| bloqueada | Não | bloquear proposta |
| fora_de_venda | Não | bloquear proposta |
| contrato_processo | Não direto | exigir confirmação |
| contrato_assinado | Não | bloquear proposta |
| permuta | Não direto | exigir confirmação |
| inexistente | Não | ocultar ou neutralizar |
| desconhecido | Não | exigir revisão manual |

---

## Garden Design — uso esperado

Fluxo operacional futuro:

1. Corretor/gestor seleciona Garden Design.
2. Sobe a tabela oficial do mês.
3. Sobe o espelho oficial.
4. FECH.AI extrai unidades e status do espelho.
5. FECH.AI cruza com a tabela.
6. Dashboard mostra:
   - unidades disponíveis;
   - unidades vendidas;
   - unidades reservadas;
   - unidades bloqueadas;
   - unidades sem correspondência;
   - botão de simulação apenas nas disponíveis.

---

## Próxima etapa técnica

Criar parser específico do espelho do portal:

```text
src/mesa/mirror/parsePortalVWebMirror.js
```

Entrada ideal:

- HTML original do portal; ou
- PDF gerado pelo botão `Gerar Espelho`; ou
- imagem com leitura assistida.

Evitar depender exclusivamente de screenshot JPG para produção, pois OCR/visão pode ter margem de erro em unidade pequena, cor comprimida e ícones.

---

## Observação crítica

O espelho precisa ter data/hora de geração.

A tabela comercial pode ser mensal.  
O espelho de vendas pode mudar diariamente ou até várias vezes ao dia.

A UI deve sempre exibir:

- competência da tabela;
- data/hora do espelho;
- fonte do espelho;
- confiança de leitura;
- alerta de confirmação para status não disponível.

---

## Rollback

Os arquivos adicionados são isolados em `src/mesa/mirror/` e não alteram o motor atual do Mesa Cliente.

Rollback seguro:

- remover `src/mesa/mirror/normalizeMirrorStatus.js`;
- remover `src/mesa/mirror/reconcileUnitsWithMirror.js`;
- remover este checkpoint.

Nenhuma alteração destrutiva foi aplicada ao parser principal, ao Worker, ao Supabase ou ao fluxo atual de simulação.
