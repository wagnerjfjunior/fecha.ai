# Manifesto de arquivos locais — Chateau Jardin — 2026-05

Este manifesto registra os artefatos gerados para a importação do Chateau Jardin sem versionar os dados comerciais sensíveis no GitHub público.

## Motivo para não versionar os arquivos completos

O repositório `wagnerjfjunior/fecha.ai` está público. Os arquivos abaixo contêm valores reais de unidades, parcelas, fluxo de pagamento e auditoria comercial. Portanto, devem ficar fora do repositório.

## Artefatos locais gerados

| Arquivo local | Tamanho | SHA-256 | Uso |
|---|---:|---|---|
| `chateau_jardin_payload_rpc_enriquecido_v7_prumada_financiamento_45.json` | 314858 bytes | `5924c016ff390668f33b6dc15d3b466812d6bc008da2e16831ce71687d5eabc9` | Payload final para importação admin/root |
| `chateau_jardin_unidades_expandidas_enriquecidas_v7_prumada_financiamento_45.csv` | 148611 bytes | `d146eb75ff28f5db02c8588cc9efb312b994e8efd382ae75eed3685fb7c206d6` | CSV expandido para conferência operacional |
| `chateau_jardin_auditoria_fluxo_v7_prumada_financiamento_45.csv` | 11484 bytes | `28e64ef0dd6b060b37fb57a8f6d7149b9439543973d263f16ee36b8e0447b615` | Auditoria de fluxo/grupos comerciais |
| `20260521193000_mesa_cliente_json_admin_preserve_fluxo_fields.sql` | 9463 bytes | `0870211a11cbed2ff0843e7d0b2ae42e3b2baf28b28b4b6050596b7e24866efd` | Migration versionável copiada para `supabase/migrations` |
| `fluxobuilder_meta_e_financiamento_oficial_payload.patch` | 4974 bytes | `8c783a690978473ee6892a743a7389524946dfb535c19668b76dd80daa873c90` | Patch opcional de leitura visual no FluxoBuilder |

## Convenção validada

```text
201 = prumada 2 / andar 01
102 = prumada 1 / andar 02
514 = prumada 5 / andar 14
100, 300, 500 = Gardens / andar 0
```

## Campos financeiros que precisam sobreviver à importação

```text
sinal_1
a4_each
mensal_each
inter_each
chaves_each
financiamento
principal_financ_set_29
financiamento_price_11_2029
meta_obra_pct
valor_total
mensal_qtd
inter_qtd
comp_qtd
ato_qtd
unica_qtd
```

## Validação pós-importação

A validação deve confirmar:

1. total de unidades importadas;
2. snapshot ativo mais recente;
3. prumada/andar corretos para exemplos 201, 102, 514 e Gardens;
4. `financiamento` igual ao **Principal Financ. (set/29)**;
5. `financiamento_price_11_2029` apenas informativo;
6. `meta_obra_pct` = 45.
