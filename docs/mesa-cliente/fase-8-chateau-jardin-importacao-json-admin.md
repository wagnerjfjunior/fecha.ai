# Fase 8 — Chateau Jardin — Importação JSON administrativa

## Contexto

A Fase 7 já foi finalizada e a Fase 8 foi iniciada na `main`.

O objetivo operacional desta etapa é viabilizar a entrada do empreendimento **Chateau Jardin**, da **Tegra Incorporadora**, no MesaCliente/FECH.AI usando importação JSON administrativa, sem alterar o parser, Worker ou motor financeiro central.

## Escopo aprovado

- Usar JSON administrativo restrito a admin/root.
- Preservar segurança multi-tenant.
- Não aceitar `empresa_id` como dado soberano vindo do JSON.
- Não alterar parser/Worker.
- Não alterar motor financeiro central sem aprovação explícita.
- Versionar somente estrutura, documentação e migration segura.
- Não versionar tabela comercial sensível em repositório público.

## Problemas encontrados

### 1. Convenção de unidade diferente

O Chateau Jardin usa o primeiro dígito como prumada e os dois últimos dígitos como andar.

Exemplos:

```text
201 = prumada 2 / andar 01
102 = prumada 1 / andar 02
514 = prumada 5 / andar 14
100, 300, 500 = Gardens / andar 0
```

### 2. Campos financeiros não preservados

A RPC administrativa anterior sanitizava o JSON e mantinha apenas campos básicos da unidade. Isso podia eliminar campos essenciais para o fluxo:

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
```

### 3. Financiamento correto

O valor oficial de financiamento é:

```text
Principal Financ. (set/29)
```

O valor de:

```text
Financ. (11/2029)
```

já inclui 1% a.m. pela Tabela Price e deve ser tratado como informativo.

### 4. Meta de obra

Para este caso, considerar:

```text
meta_obra_pct = 45
```

Não assumir 30% como padrão do empreendimento.

## Entregáveis versionados

```text
docs/mesa-cliente/importacoes/chateau-jardin/2026-05/README.md
docs/mesa-cliente/importacoes/chateau-jardin/2026-05/MANIFEST.local-files.md
docs/mesa-cliente/importacoes/chateau-jardin/2026-05/payload_schema.example.json
docs/mesa-cliente/importacoes/chateau-jardin/2026-05/patches/fluxobuilder_meta_e_financiamento_oficial_payload.patch
supabase/migrations/20260521193000_mesa_cliente_json_admin_preserve_fluxo_fields.sql
```

## Entregáveis não versionados

Os arquivos reais com preço e parcelas devem permanecer fora do GitHub público:

```text
chateau_jardin_payload_rpc_enriquecido_v7_prumada_financiamento_45.json
chateau_jardin_unidades_expandidas_enriquecidas_v7_prumada_financiamento_45.csv
chateau_jardin_auditoria_fluxo_v7_prumada_financiamento_45.csv
```

## Plano de execução

1. Revisar PR da estrutura Fase 8.
2. Fazer merge.
3. Aplicar migration no Supabase.
4. Importar JSON v7 pelo usuário admin/root.
5. Validar amostras de unidade/prumada/andar.
6. Validar que `financiamento` bate com Principal Financ. (set/29).
7. Validar que `financiamento_price_11_2029` não substitui o principal.
8. Validar que `meta_obra_pct` chega como 45 no payload da unidade.

## Observação

O patch de FluxoBuilder foi arquivado como opcional. Ele não deve ser aplicado sem revisão porque altera apresentação visual. A correção obrigatória desta etapa é a preservação dos campos financeiros na RPC de importação JSON administrativa.
