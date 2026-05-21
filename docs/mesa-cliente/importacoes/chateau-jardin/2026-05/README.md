# MesaCliente — Importação Chateau Jardin — Fase 8

## Objetivo

Estruturar, em diretório rastreável, a importação administrativa do empreendimento **Chateau Jardin** para o MesaCliente/FECH.AI.

Esta pasta documenta a correção da leitura do empreendimento e a separação entre:

1. arquivos de execução local/operacional, que contêm tabela comercial e valores sensíveis;
2. código versionável seguro, sem dados comerciais de preço;
3. migration necessária para preservar campos financeiros allowlistados na importação JSON administrativa.

## Status

- Fase 7: finalizada.
- Fase 8: iniciada na `main`.
- Empreendimento: Chateau Jardin.
- Incorporadora: Tegra Incorporadora.
- Importação: JSON administrativo restrito a admin/root.
- Parser/Worker: não alterados nesta etapa.
- Motor financeiro: não alterado nesta etapa.

## Regra específica do Chateau Jardin

O Chateau Jardin não segue o padrão clássico de final usado em outros empreendimentos.

Nos demais empreendimentos, normalmente o final da unidade identifica a prumada. No Chateau Jardin, a regra validada é:

```text
201 = prumada 2 / andar 01
102 = prumada 1 / andar 02
514 = prumada 5 / andar 14
100, 300, 500 = Gardens / andar 0
```

Portanto:

```text
primeiro dígito = prumada
últimos dois dígitos = andar/pavimento
```

Essa regra é crítica para filtros comerciais futuros, como face, sol, vista, torre, prumada e validação de disponibilidade.

## Financiamento e parcelas

A coluna financeira correta para o saldo financiado é:

```text
Principal Financ. (set/29)
```

A coluna:

```text
Financ. (11/2029)
```

é apenas informativa, pois já contém acréscimo de 1% a.m. pela Tabela Price.

Para o MesaCliente, a orientação é:

- `financiamento` = valor da coluna **Principal Financ. (set/29)**;
- `principal_financ_set_29` = mesmo valor principal oficial;
- `financiamento_price_11_2029` = valor informativo com Price;
- `meta_obra_pct` = 45;
- não assumir financiamento fixo de 30%.

## Dados sensíveis

O repositório `wagnerjfjunior/fecha.ai` está público. Por esse motivo, os arquivos completos com valores comerciais reais **não devem ser versionados** neste repositório.

Não versionar em GitHub público:

- JSON completo do Chateau Jardin com valores de unidades;
- CSV expandido com preços e parcelas;
- CSV de auditoria com valores financeiros por grupo.

Esses arquivos devem permanecer como artefatos locais/operacionais e podem ser conferidos pelo manifesto abaixo:

- `MANIFEST.local-files.md`

## Arquivos versionados nesta pasta

```text
README.md
MANIFEST.local-files.md
payload_schema.example.json
patches/fluxobuilder_meta_e_financiamento_oficial_payload.patch
```

## Arquivo de migration relacionado

A migration versionável fica no diretório padrão do Supabase:

```text
supabase/migrations/20260521193000_mesa_cliente_json_admin_preserve_fluxo_fields.sql
```

## Ordem correta de execução

1. Revisar o PR.
2. Aplicar a migration no Supabase.
3. Confirmar que a RPC `importar_mesa_cliente_json_admin` preserva os campos financeiros allowlistados.
4. Importar o JSON v7 pelo usuário admin/root.
5. Validar amostras:
   - `201`: prumada 2 / andar 01;
   - `102`: prumada 1 / andar 02;
   - `514`: prumada 5 / andar 14;
   - `100`, `300`, `500`: Garden / andar 0;
   - `financiamento`: deve bater com **Principal Financ. (set/29)**;
   - `financiamento_price_11_2029`: deve aparecer apenas como informativo.

## Observação operacional

A importação administrativa por JSON continua restrita a admin/root. A lógica de tenant e empresa deve permanecer sob controle de sessão/RPC, nunca como dado soberano vindo do arquivo importado.
