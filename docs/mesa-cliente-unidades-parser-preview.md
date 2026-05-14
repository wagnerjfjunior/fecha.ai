# Mesa Cliente — Integração Preview de Unidades Extraídas pelo Parser

Documento de planejamento técnico para a próxima etapa do **Mesa Cliente** dentro do FECH.AI.

Esta etapa tem um objetivo específico e controlado: **exibir na tela de simulação todas as unidades extraídas da tabela comercial pelo parser**, sem depender ainda do espelho de vendas.

---

## 1. Objetivo da etapa

A nova tela do Mesa Cliente em `src/components/MesaCliente/` foi criada como camada operacional de simulação comercial: empreendimento, fluxo de pagamento, histórico e aprovação.

A camada Native First existente em `src/pages/MesaClienteNativeFirst.jsx` e `src/mesa/` já contém o motor de leitura de PDFs/tabelas, detecção de layout e parsers nativos.

O objetivo desta integração é ligar essas duas partes de forma segura:

```txt
Tabela comercial/PDF
  ↓
Parser Native First
  ↓
Unidades normalizadas
  ↓
Banco Supabase com isolamento por empresa/tenant
  ↓
Tela Mesa Cliente lista unidades extraídas
  ↓
Corretor escolhe unidade
  ↓
FluxoBuilder usa valor real da tabela
```

---

## 2. Escopo desta preview

### Incluído

- Criar documentação técnica antes de qualquer alteração funcional.
- Trabalhar em branch isolada de preview.
- Exibir todas as unidades identificadas pelo parser da tabela comercial.
- Não aplicar filtro por disponibilidade de espelho nesta fase.
- Remover uso de valor financeiro placeholder/fallback no fluxo.
- Criar ou ajustar RPCs tenant-safe para leitura/importação de unidades.
- Usar RLS existente como defesa adicional, mas não depender apenas dela.
- Preservar o motor Native First atual como fonte de parsing.
- Preservar rollback para a tela antiga.
- Usar TanStack Query apenas como camada de cache/estado da tela, sem introduzir um segundo padrão de autenticação Supabase sem análise.

### Fora do escopo

- Espelho de vendas com status real de disponibilidade.
- Ocultar unidades vendidas/reservadas.
- Upload final para Supabase Storage.
- Processamento assíncrono completo por fila/worker.
- Alteração ampla da autenticação do app.
- Uso de service role no frontend.
- Uso de senha, token secreto ou credencial aberta no código.
- Substituição definitiva do `MesaClienteNativeFirst` sem rollback.

---

## 3. Decisão sobre espelho de vendas

O espelho de vendas ainda não está pronto.

Nesta preview, a regra oficial será:

```txt
Na ausência de espelho de vendas processado, a Mesa Cliente exibirá todas as unidades extraídas da tabela comercial, com aviso de que a disponibilidade ainda não foi validada pelo espelho.
```

A tela **não deve** afirmar que a unidade está disponível de forma confirmada.

Texto recomendado para UI:

```txt
Unidade identificada na tabela comercial.
Disponibilidade ainda não validada pelo espelho de vendas.
Antes de confirmar a proposta, valide a unidade com o gestor/incorporadora.
```

---

## 4. Estado atual validado

### 4.1 Frontend

Hoje existem duas camadas distintas:

| Camada | Caminho | Função atual |
|---|---|---|
| Motor Native First | `src/pages/MesaClienteNativeFirst.jsx` + `src/mesa/` | Extrai PDF, detecta layout, executa parser, monta linhas canônicas |
| Nova UI SaaS | `src/components/MesaCliente/` | Interface de abas, empreendimentos, fluxo, histórico e aprovação |

A tela nova ainda não consome diretamente as unidades extraídas pelo parser.

O `TabFluxo.jsx` atualmente usa fallback financeiro:

```jsx
precoTotal={empreendimento.valor_tabela ?? 850000}
```

Esse fallback deverá ser removido antes de qualquer uso operacional.

### 4.2 Banco Supabase

Foram identificadas tabelas relevantes já existentes:

- `empreendimentos`
- `estoque_arquivos`
- `estoque_snapshots`
- `unidades_estoque`
- `mesa_simulacoes`
- `mesa_fluxo_pagamentos`
- `mesa_eventos`
- `mesa_arquivos`

Policies de SELECT relevantes já seguem o padrão:

```sql
is_root() OR empresa_id = my_empresa_id()
```

Helpers existentes:

- `my_empresa_id()`
- `is_root()`
- `is_admin_global()`
- `is_admin_local()`
- `is_gestor()`

RPCs existentes da Mesa:

- `get_empreendimentos_mesa`
- `get_empresa_mesa_config`
- `get_historico_mesas`
- `registrar_upload_arquivo_mesa`
- `criar_mesa_simulacao`
- `aprovar_rejeitar_mesa`

---

## 5. Segurança e multitenancy

### 5.1 Princípios obrigatórios

- O frontend nunca poderá gravar diretamente em `unidades_estoque`.
- O frontend nunca poderá usar `service_role`.
- O frontend nunca poderá decidir sozinho a empresa real do usuário.
- Toda RPC deverá validar `auth.uid()`.
- Toda RPC deverá validar corretor ativo.
- Toda RPC deverá validar que o empreendimento pertence à empresa do usuário.
- Gestor/admin/root poderão importar dados de tabela conforme regra de negócio.
- Corretor comum poderá ler unidades do seu tenant e simular, mas não validar estoque global.
- Root poderá auditar, respeitando trilha operacional.

### 5.2 Modelo de acesso previsto

| Papel | Pode ler unidades | Pode importar parser | Pode simular | Pode aprovar |
|---|---:|---:|---:|---:|
| corretor | Sim, somente próprio tenant | Não, salvo decisão futura | Sim | Não |
| gestor | Sim, próprio tenant | Sim, próprio tenant | Sim | Sim |
| admin_local | Sim, próprio tenant | Sim, próprio tenant | Sim | Sim |
| admin_global/root | Sim, multiempresa | Sim | Sim | Sim |

---

## 6. RPCs propostas

### 6.1 `get_unidades_mesa`

Objetivo: retornar todas as unidades extraídas da tabela comercial para um empreendimento.

Características:

- `SECURITY DEFINER`
- `SET search_path = public`
- usa `auth.uid()`
- ignora empresa informada pelo browser
- valida tenant via `my_empresa_id()` ou `is_root()`
- busca o snapshot ativo/mais recente do empreendimento
- retorna todas as unidades do snapshot
- não filtra disponibilidade por espelho nesta fase

Assinatura sugerida:

```sql
get_unidades_mesa(p_empreendimento_id uuid)
```

Retorno sugerido:

```txt
id uuid
empreendimento_id uuid
unidade text
torre text
andar integer
final text
metragem numeric
vagas_quantidade integer
valor_tabela numeric
status_comercial text
disponibilidade_validada boolean
aviso text
fluxo_original jsonb
snapshot_id uuid
atualizado_em timestamptz
```

Regra de retorno para preview:

```txt
disponibilidade_validada = false
aviso = 'Disponibilidade ainda não validada pelo espelho de vendas'
```

### 6.2 `importar_unidades_mesa_parser`

Objetivo: receber o resultado canônico do parser e gravar um novo snapshot de unidades.

Características:

- `SECURITY DEFINER`
- `SET search_path = public`
- valida `auth.uid()`
- valida role: gestor, admin_local, admin_global/root
- valida empreendimento e tenant
- recebe JSONB de unidades parseadas
- cria `estoque_snapshots`
- insere em `unidades_estoque`
- não aceita empresa arbitrária do frontend sem checagem
- retorna `snapshot_id`, `quantidade_importada` e `status`

Assinatura sugerida:

```sql
importar_unidades_mesa_parser(
  p_empreendimento_id uuid,
  p_arquivo_id uuid,
  p_parser_nome text,
  p_unidades jsonb
)
```

Payload esperado por unidade:

```json
{
  "unidade": "AP1204",
  "torre": "Torre 1",
  "andar": 12,
  "final": "4",
  "metragem": 72,
  "vagas_quantidade": 1,
  "valor_tabela": 850000,
  "fluxo_original": {
    "sinal": 85000,
    "mensais": { "quantidade": 36, "valor": 1200 },
    "intermediarias": { "quantidade": 3, "valor": 25000 },
    "financiamento": 540000
  }
}
```

---

## 7. Mudanças previstas no frontend

### 7.1 `src/components/MesaCliente/hooks/useMesaData.js`

Adicionar hooks:

- `useUnidadesMesa(empreendimentoId)`
- `useImportarUnidadesMesaParser()`

Ponto de atenção:

A implementação atual usa TanStack Query e importa `supabase` de um path ainda não aderente ao projeto. Nesta preview, a decisão é **não introduzir um segundo client Supabase sem compatibilização com a autenticação atual**.

Caminho preferencial:

- manter TanStack Query como cache/estado;
- adaptar chamadas RPC ao padrão real do FECH.AI;
- evitar duplicidade entre `createSB()` atual e `supabase-js`.

### 7.2 `src/components/MesaCliente/TabFluxo.jsx`

Alterações previstas:

- inserir etapa de seleção de unidade antes do `FluxoBuilder`;
- buscar unidades via `get_unidades_mesa`;
- listar todas as unidades retornadas;
- exibir aviso de disponibilidade não validada;
- bloquear fluxo se não houver unidade selecionada;
- bloquear fluxo se unidade não tiver `valor_tabela` válido;
- passar `unidade.valor_tabela` para `FluxoBuilder`;
- enviar `unidadeId` real em `criar_mesa_simulacao`.

Remover:

```jsx
precoTotal={empreendimento.valor_tabela ?? 850000}
```

Substituir por:

```txt
precoTotal = unidadeSelecionada.valor_tabela
```

### 7.3 `FluxoBuilder.jsx`

Possível ajuste:

- aceitar unidade selecionada como prop;
- exibir cabeçalho com unidade, torre, metragem e valor;
- iniciar fluxo com dados originais da tabela quando disponíveis;
- manter cálculo visual atual.

---

## 8. TanStack Query

TanStack Query será tratado como dependência de frontend para cache, loading, erro e invalidação.

Ele não é serviço externo e não envia dados para terceiros.

Uso pretendido:

- cache de empreendimentos;
- cache de unidades por empreendimento;
- cache de histórico;
- invalidação após importação de unidades;
- invalidação após salvar simulação.

Configuração recomendada:

```txt
Empreendimentos: staleTime 2–5 min, refetchOnWindowFocus false
Unidades: staleTime 2–5 min, refetchOnWindowFocus false
Histórico: staleTime 30–60s, refetchOnWindowFocus false ou controlado
```

Não será usado como justificativa para quebrar o modelo de autenticação atual.

---

## 9. Riscos conhecidos

| Risco | Mitigação |
|---|---|
| Vazamento entre tenants | RPC valida `auth.uid()`, empresa do usuário e empreendimento |
| Corretor importar dados indevidamente | Importação restrita a gestor/admin/root |
| Valor fake em proposta | Remover fallback financeiro |
| Duplicidade de cliente Supabase | Não introduzir `supabase-js` sem compatibilização |
| Parser gerar unidade incompleta | RPC rejeita unidade sem `unidade` e sem `valor_tabela` válido |
| Espelho ausente causar bloqueio | Exibir todas as unidades com aviso de não validação |
| Tela parecer disponibilidade confirmada | UI deve dizer “não validada pelo espelho” |
| Quebra do NativeFirst atual | Manter rollback e não remover `src/pages/MesaClienteNativeFirst.jsx` |

---

## 10. Checklist da preview

Antes de abrir PR:

- [ ] Documentação criada em branch própria.
- [ ] RPC `get_unidades_mesa` desenhada e revisada.
- [ ] RPC `importar_unidades_mesa_parser` desenhada e revisada.
- [ ] Sem service role no frontend.
- [ ] Sem segredo no GitHub.
- [ ] Sem placeholder financeiro.
- [ ] `TabFluxo` exige unidade selecionada.
- [ ] Unidades exibidas com aviso de disponibilidade não validada.
- [ ] Corretor não acessa outro tenant.
- [ ] Gestor/admin acessa apenas próprio tenant, exceto root.
- [ ] Build da preview passa no Vercel.
- [ ] Link de preview validado antes de merge.

---

## 11. Estratégia de rollback

Rollback funcional:

- manter `src/pages/MesaClienteNativeFirst.jsx` intacto;
- manter `src/pages/MesaCliente.jsx` como ponto de roteamento controlável;
- se a nova integração falhar, apontar a rota de volta para o NativeFirst.

Rollback de banco:

- novas RPCs deverão ser versionadas e não substituir RPCs existentes nesta etapa;
- se necessário, revogar permissões das novas RPCs sem remover tabelas.

---

## 12. Decisão final desta etapa

A integração será feita em preview, com escopo fechado:

```txt
Exibir todas as unidades extraídas pelo parser da tabela comercial, com isolamento tenant-safe e sem depender do espelho de vendas.
```

O espelho de vendas continuará como etapa futura para validar disponibilidade e ocultar/bloquear unidades vendidas.
