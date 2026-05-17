# MesaCliente — Arquitetura da Engenharia Financeira

## 1. Objetivo

Este documento define a arquitetura do módulo de **Engenharia Financeira / Inteligência Financeira** do MesaCliente.

O módulo existe para transformar regras comerciais e financeiras complexas de incorporação imobiliária em uma experiência simples para corretor, coordenador e cliente.

O sistema deve permitir:

- configurar política financeira por empresa, empreendimento e vigência;
- configurar VPL comercial informado pela incorporadora;
- configurar faixas de prêmio do corretor;
- configurar taxa de antecipação anual;
- configurar taxa de postergação anual;
- gerar agenda financeira com parcelas datadas;
- simular VPL, antecipação e postergação;
- evidenciar a melhor aplicação financeira para o corretor/coordenador confirmar;
- apresentar ao cliente uma visão limpa, comercial e não técnica;
- validar tudo no banco, por RPC segura, com isolamento multiempresa e multitenant.

## 2. Princípio central

O MesaCliente **não deve trabalhar com desconto simples global sobre valor total** como regra principal.

Modelo incorreto:

```txt
valor_total - desconto_global = valor_com_desconto
```

Modelo correto:

```txt
valor de tabela
→ política de VPL
→ parcelas datadas
→ antecipação/postergação por camada
→ fluxo final negociado
```

A branch antiga de desconto simples não deve ser promovida para `main` como funcionalidade final.

## 3. Conceitos de negócio

### 3.1. VPL

No contexto do MesaCliente, VPL é uma faixa comercial de desconto autorizada pela incorporadora para um empreendimento e uma vigência.

Exemplo:

```txt
Empreendimento: Garden
VPL máximo autorizado: 6%
Prêmio cheio até: 3%
Faixas administrativas de prêmio configuráveis
```

O VPL é informação interna para corretor, coordenador, gestor e incorporadora.

O cliente não deve ver:

- VPL;
- prêmio;
- comissão;
- faixa administrativa;
- regra interna da incorporadora.

O cliente deve ver:

- condição especial;
- economia total;
- novo fluxo;
- vantagem financeira descrita em linguagem comercial.

### 3.2. Prêmio do corretor

O prêmio do corretor é informação administrativa.

Ele não deve ser convertido automaticamente em desconto para o cliente.

O corretor recebe:

```txt
corretagem fixa + prêmio variável conforme a negociação
```

A perda do prêmio não é linear por fórmula fixa. Ela deve ser configurada por faixas de VPL.

Exemplo:

```txt
VPL 0% até 3%      → prêmio do corretor: 2%
VPL acima de 3% até 4% → prêmio do corretor: 1%
VPL acima de 4% até 6% → prêmio do corretor: 0%
```

O sistema deve guardar diretamente o prêmio restante de cada faixa.

Não calcular assim:

```txt
perda_premio = vpl_aplicado - limite_com_premio
```

Esse cálculo é incorreto porque cada empreendimento pode ter teto de prêmio diferente, como 1%, 1,5%, 2% ou 3%.

### 3.3. Antecipação

Antecipação ocorre quando o cliente aumenta o valor no início do fluxo, normalmente no ato ou entrada, e esse valor é usado para abater parcelas futuras.

Exemplo:

```txt
Cliente deseja colocar +R$ 20.000 no ato.
Sistema simula onde aplicar esse valor:
- financiamento;
- chaves/parcela única;
- anuais;
- últimas mensais.
```

O sistema deve evidenciar onde há maior benefício financeiro.

O cálculo deve ser composto:

```txt
valor_presente = valor_futuro / (1 + taxa_anual) ^ (dias / 365)
desconto = valor_futuro - valor_presente
```

A taxa anual de antecipação deve vir da política financeira vigente. Não pode existir taxa hardcoded no front, no banco ou na RPC.

### 3.4. Postergação

Postergação ocorre quando o cliente reduz valores em parcelas anteriores e desloca esse valor para uma parcela futura.

Exemplo:

```txt
Cliente deseja reduzir R$ 500 de cada mensal.
Sistema desloca essa diferença para uma parcela futura e calcula o acréscimo financeiro.
```

O cálculo também deve ser composto:

```txt
valor_futuro = valor_presente * (1 + taxa_anual) ^ (dias / 365)
acrescimo = valor_futuro - valor_presente
```

A taxa de postergação deve ter campo próprio, mesmo que inicialmente seja igual à taxa de antecipação.

Campos separados:

```txt
taxa_antecipacao_ano_pct
taxa_postergacao_ano_pct
```

### 3.5. Data do ato

A data do ato é a principal data-base para cálculo e montagem da agenda financeira.

A partir dela, o sistema deve calcular ou organizar:

- ato;
- 30 dias;
- 60 dias;
- 90 dias;
- mensais;
- anuais;
- chaves/parcela única;
- financiamento.

Prioridade para definição de datas:

```txt
1. Data completa da tabela oficial.
2. Data completa da tabela comercial.
3. Mês/ano da tabela comercial + dia do ato.
4. Regra extraída do cabeçalho.
5. Data estimada.
6. Data manual, quando permitido.
```

Quando a tabela trouxer apenas mês/ano, usar o dia do ato.

Exemplo:

```txt
Data do ato: 20/05/2026
Financiamento informado: 09/2028
Data calculada: 20/09/2028
```

Se o mês não tiver o dia do ato, usar o último dia válido do mês.

Exemplo:

```txt
Data do ato: 31/05/2026
Financiamento informado: 02/2028
Data calculada: 29/02/2028
```

### 3.6. Chaves / parcela única

Não presumir que chaves/parcela única ocorre sempre 30 dias antes do financiamento.

Regra correta:

```txt
1. Se a tabela trouxer data completa, usar a data da tabela.
2. Se o cabeçalho informar 30 dias antes do financiamento, usar financiamento - 30 dias.
3. Se o cabeçalho informar 60 dias antes do financiamento, usar financiamento - 60 dias.
4. Se a data for apenas estimada, permitir ajuste por coordenador.
```

### 3.7. Periodicidade simbólica

Algumas tabelas possuem parcela simbólica de periodicidade, por exemplo R$ 1.000 em data final.

Essa parcela deve:

- aparecer como alerta/informação;
- não receber VPL;
- não receber antecipação;
- não receber postergação;
- não ser usada como destino de desconto;
- não contaminar o cálculo de melhor aplicação.

## 4. Visões do sistema

### 4.1. Tela interna — corretor/coordenador

A tela interna pode exibir elementos administrativos e técnicos:

- VPL aplicado;
- VPL máximo permitido;
- taxa de antecipação vigente;
- taxa de postergação vigente;
- faixa de prêmio;
- prêmio estimado do corretor;
- melhor camada para aplicação;
- economia estimada;
- impacto administrativo;
- alertas de política vencida ou não configurada.

O sistema evidencia a melhor opção, mas quem confirma é o corretor/coordenador conforme permissão.

### 4.2. Tela limpa — cliente

A tela do cliente deve esconder a complexidade.

Mostrar:

- valor de tabela;
- condição especial intermediária;
- condição final com inteligência financeira;
- economia total;
- fluxo final;
- narrativa comercial da vantagem financeira.

Não mostrar:

- VPL;
- prêmio;
- comissão;
- taxa técnica;
- cálculo composto;
- faixas internas;
- regra administrativa.

Exemplo de camada visual:

```txt
Valor de tabela: R$ 1.000.000
Condição especial: R$ 970.000
Condição final com inteligência financeira: R$ 958.500
Economia total: R$ 41.500
```

Sugestão visual:

- valor de tabela: neutro;
- condição intermediária: amarelo;
- condição final: verde.

## 5. Arquitetura em camadas

A implementação deve seguir esta ordem:

```txt
1. Banco de dados
2. RLS e segurança
3. RPCs soberanas
4. Motor financeiro
5. API/front data layer
6. Tela admin/coordenador
7. Tela da mesa
8. Tela limpa do cliente
9. Testes e hardening
```

O front nunca deve ser a autoridade da regra financeira.

O banco/RPC deve validar:

- autenticação;
- tenant;
- empresa;
- empreendimento;
- perfil;
- política vigente;
- limites de VPL;
- faixas de prêmio;
- taxa aplicada;
- datas;
- parcelas elegíveis;
- periodicidade simbólica fora do cálculo.

## 6. Modelo de dados recomendado

### 6.1. `mesa_cliente_politicas_financeiras`

Finalidade: guardar a política financeira vigente por empresa, empreendimento e período.

Campos mínimos:

```txt
id uuid primary key
empresa_id uuid not null
empreendimento_id uuid not null
mes_referencia date null
vigencia_inicio date not null
vigencia_fim date not null
vpl_max_pct numeric not null
taxa_antecipacao_ano_pct numeric not null
taxa_postergacao_ano_pct numeric not null
metodo_calculo text not null
base_tempo text not null
permite_vpl_mensais boolean not null default false
permite_vpl_anuais boolean not null default true
permite_vpl_chaves boolean not null default true
permite_vpl_financiamento boolean not null default true
permite_antecipacao_mensais boolean not null default true
permite_antecipacao_anuais boolean not null default true
permite_antecipacao_chaves boolean not null default true
permite_antecipacao_financiamento boolean not null default true
permite_postergacao_mensais boolean not null default true
permite_postergacao_anuais boolean not null default true
permite_postergacao_chaves boolean not null default true
permite_postergacao_financiamento boolean not null default true
ativo boolean not null default true
criado_por uuid null
atualizado_por uuid null
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
```

Valores esperados por política, não hardcoded:

```txt
metodo_calculo = composto
base_tempo = dias_365
```

### 6.2. `mesa_cliente_politica_premio_faixas`

Finalidade: guardar faixas administrativas de prêmio do corretor por política.

Campos mínimos:

```txt
id uuid primary key
politica_id uuid not null
empresa_id uuid not null
empreendimento_id uuid not null
vpl_de_pct numeric not null
vpl_ate_pct numeric not null
premio_corretor_pct numeric not null
status text not null
descricao text null
ordem integer not null default 0
ativo boolean not null default true
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
```

Status sugeridos:

```txt
premio_cheio
premio_parcial
sem_premio
fora_politica
```

### 6.3. `mesa_cliente_fluxo_parcelas`

Finalidade: guardar o fluxo financeiro expandido em parcelas datadas por simulação.

Campos mínimos:

```txt
id uuid primary key
empresa_id uuid not null
simulacao_id uuid not null
empreendimento_id uuid not null
unidade_id uuid null
grupo text not null
descricao text not null
valor_original numeric not null
valor_atual numeric not null
data_original date not null
data_atual date not null
origem_data text not null
regra_data text null
ordem integer not null
quantidade_origem integer null
parcela_numero integer null
eh_periodicidade_simbolica boolean not null default false
pode_receber_vpl boolean not null default false
pode_receber_antecipacao boolean not null default false
pode_receber_postergacao boolean not null default false
metadata jsonb not null default '{}'::jsonb
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
```

Grupos esperados:

```txt
ato
complemento
mensal
anual
chaves
financiamento
periodicidade
outro
```

Origens de data esperadas:

```txt
tabela_oficial
tabela_comercial_data
tabela_comercial_mes
cabecalho_30_dias
cabecalho_60_dias
calculada_por_ato
estimada
manual
```

### 6.4. `mesa_cliente_fluxo_operacoes`

Finalidade: guardar operações simuladas ou confirmadas de VPL, antecipação e postergação.

Campos mínimos:

```txt
id uuid primary key
empresa_id uuid not null
empreendimento_id uuid not null
simulacao_id uuid not null
politica_id uuid null
tipo_operacao text not null
grupo_origem text null
grupo_destino text null
parcela_origem_id uuid null
parcela_destino_id uuid null
valor_movido numeric not null default 0
valor_base numeric not null default 0
data_origem date null
data_destino date null
dias_calculo integer null
taxa_ano_pct numeric null
vpl_aplicado_pct numeric null
desconto_calculado numeric not null default 0
acrescimo_calculado numeric not null default 0
economia_liquida numeric not null default 0
status text not null
confirmado boolean not null default false
criado_por uuid null
confirmado_por uuid null
metadata jsonb not null default '{}'::jsonb
created_at timestamptz not null default now()
updated_at timestamptz not null default now()
```

Tipos de operação:

```txt
vpl
antecipacao
postergacao
```

Status sugeridos:

```txt
simulado
recomendado
confirmado
bloqueado
cancelado
```

## 7. RPCs soberanas

As RPCs mínimas são:

```txt
salvar_mesa_cliente_politica_financeira
salvar_mesa_cliente_premio_faixas
get_mesa_cliente_politica_financeira_vigente
gerar_mesa_cliente_agenda_parcelas
simular_mesa_cliente_engenharia_financeira
confirmar_mesa_cliente_operacao_financeira
validar_mesa_cliente_operacao_financeira
```

Todas devem usar:

```sql
language plpgsql
security definer
set search_path = public
```

Todas devem validar:

- `auth.uid()`;
- empresa ativa;
- usuário ativo no tenant;
- empreendimento pertence à empresa;
- perfil/permissão;
- dados numéricos;
- política vigente;
- ausência de sobreposição indevida;
- parcelas elegíveis;
- periodicidade simbólica fora do cálculo.

## 8. Segurança e DevSecOps

Regras obrigatórias:

- nada hardcoded em regra comercial;
- política sempre vem do banco;
- RLS ativa em todas as tabelas novas;
- escrita direta bloqueada para usuários comuns;
- escrita apenas via RPC;
- `anon` sem permissão de executar RPCs sensíveis;
- `auth.uid()` obrigatório;
- validação de tenant obrigatória;
- validação de perfil obrigatória;
- auditoria obrigatória;
- cliente nunca recebe payload com VPL, prêmio ou comissão;
- service_role nunca deve ser usado no browser;
- não confiar em dados soberanos enviados pelo front;
- front exibe, banco decide.

## 9. Cálculos financeiros

### 9.1. Antecipação composta

```txt
taxa = taxa_ano_pct / 100
valor_presente = valor_futuro / power(1 + taxa, dias / 365.0)
desconto = valor_futuro - valor_presente
```

### 9.2. Postergação composta

```txt
taxa = taxa_ano_pct / 100
valor_futuro = valor_presente * power(1 + taxa, dias / 365.0)
acrescimo = valor_futuro - valor_presente
```

### 9.3. Regras de cálculo

- usar `numeric`, não `float`;
- arredondar valores monetários em 2 casas;
- bloquear ou ignorar cálculo com dias <= 0;
- taxa zero deve retornar sem desconto/acréscimo;
- valor zero não deve gerar operação financeira;
- valor movido não pode exceder a parcela destino sem regra explícita.

## 10. Critérios de aceite da arquitetura

A arquitetura só estará aprovada quando:

- desconto simples global não for usado como regra final;
- política financeira estiver por empresa, empreendimento e vigência;
- faixas de prêmio forem configuráveis;
- cálculo composto for aplicado no banco;
- data do ato recalcular agenda financeira;
- datas aparecerem nos cards;
- financiamento usar data oficial quando existir;
- mês/ano usar dia do ato;
- mês sem dia válido usar último dia do mês;
- chaves/parcela única vier da tabela/cabeçalho quando possível;
- periodicidade simbólica não entrar em cálculo;
- cliente não ver VPL/prêmio/comissão;
- corretor/coordenador ver impacto administrativo;
- RLS, RPCs e auditoria estiverem validadas.
