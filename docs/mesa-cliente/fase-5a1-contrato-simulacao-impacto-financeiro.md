# FECH.AI / MesaCliente — Fase 5A.1 Contrato de Simulação de Impacto Financeiro

**Status:** contrato operacional inicial fechado para preflight e desenho SQL posterior  
**Branch:** `feature/mesa-cliente-engenharia-financeira`  
**Área:** Engenharia Financeira / MesaCliente  
**Fase:** 5A.1 — contrato antes do SQL  
**Data de consolidação:** 2026-05-18

---

## 1. Decisão oficial

A Fase 5A não começa com migration.

A Fase 5A começa com este contrato, documentado como **5A.1**, para evitar repetição dos erros das fases anteriores:

- deduzir coluna;
- assumir regra de cálculo sem evidência;
- misturar dry-run com persistência;
- expor campo sensível no retorno;
- transformar simulação em operação financeira antes da hora;
- criar SQL antes de inventariar o banco real.

Frase de controle desta fase:

```text
5A.1 fecha o contrato. 5A.2 só nasce após preflight read-only e validação das regras de cálculo.
```

---

## 2. Contexto herdado das fases anteriores

A trilha oficial permanece:

- **4A**: gerar agenda financeira em JSON, sem persistir.
- **4B**: persistir agenda financeira com lock, idempotência, auditoria e bloqueio contra operação confirmada.
- **4C**: ler agenda persistida e devolver payload cliente-safe.
- **5A**: simular impacto financeiro usando agenda persistida.
- **5B**: registrar operação financeira.
- **5C**: confirmar/cancelar operação financeira.
- **Depois**: integração front/BFF e testes E2E.

A 4C foi aprovada com os testes 09A e 09B. A 5A parte do princípio de que já existe uma agenda financeira ativa e persistida pela 4B.

---

## 3. Objetivo da Fase 5A

A Fase 5A deve calcular uma **simulação de impacto financeiro** sobre uma agenda financeira persistida, sem criar operação financeira definitiva.

Em termos práticos:

- recebe uma simulação/agenda existente;
- recebe uma intenção de alteração financeira;
- valida se a alteração é permitida;
- calcula o impacto estimado;
- retorna um payload administrativo seguro;
- não grava operação financeira;
- não confirma negociação;
- não altera parcelas persistidas;
- não altera agenda persistida.

A Fase 5A é um **dry-run financeiro administrativo**.

---

## 4. O que a Fase 5A.1 documenta

A Fase 5A.1 documenta apenas:

1. objetivo;
2. escopo;
3. fora de escopo;
4. fronteiras de segurança;
5. premissas que ainda precisam ser provadas por preflight;
6. contrato candidato da futura RPC;
7. dados de entrada candidatos;
8. dados de saída candidatos;
9. critérios de aceite;
10. testes obrigatórios;
11. travas para não avançar errado.

A Fase 5A.1 **não cria SQL executável**.

---

## 5. Fora de escopo da Fase 5A

A Fase 5A não pode:

- criar operação financeira em `mesa_cliente_fluxo_operacoes`;
- confirmar operação;
- cancelar operação;
- atualizar agenda;
- substituir agenda;
- atualizar parcelas;
- apagar parcelas;
- criar nova agenda;
- mexer no frontend;
- mexer no parser;
- mexer no Worker/Make/n8n;
- usar regra hardcoded no client;
- aceitar `empresa_id` soberano vindo do frontend;
- usar `service_role` no client;
- expor payload cliente-safe final;
- expor comissão, prêmio, política, taxa interna ou VPL bruto ao cliente;
- avançar para integração BFF antes de testes de banco.

Se qualquer implementação da 5A fizer `INSERT`, `UPDATE` ou `DELETE` em `mesa_cliente_fluxo_operacoes`, ela deixou de ser 5A e virou 5B indevidamente.

---

## 6. Escopo permitido da Fase 5A

A Fase 5A pode:

- ler `mesa_simulacoes`;
- ler `mesa_cliente_agendas_financeiras`;
- ler `mesa_cliente_fluxo_parcelas`;
- ler dados mínimos de `empreendimentos`, quando necessário para validar tenant/empreendimento;
- ler dados mínimos de `corretores`, quando necessário para validar usuário/perfil;
- ler políticas financeiras somente se existirem tabelas/funções oficiais de política no banco;
- calcular impacto em memória dentro da RPC;
- retornar JSON administrativo;
- indicar se a operação simulada é válida ou bloqueada;
- retornar motivos de bloqueio seguros;
- retornar totais comparativos seguros para uso interno.

A 5A é permitida como cálculo/dry-run. Persistência fica para 5B.

---

## 7. Dependência obrigatória: agenda ativa persistida

A Fase 5A depende de agenda financeira ativa persistida.

A futura RPC da 5A deve bloquear se:

- a simulação não existir;
- a simulação não pertencer ao tenant do usuário;
- a simulação não tiver empreendimento válido;
- não existir agenda ativa para a simulação;
- a agenda estiver `substituida` ou `bloqueada`;
- houver inconsistência entre `empresa_id`, `simulacao_id`, `empreendimento_id` e `agenda_id`;
- a agenda ativa tiver parcelas inexistentes/inconsistentes;
- a agenda tiver operação financeira confirmada que impeça nova simulação, se essa regra for confirmada no contrato da 5A.2.

---

## 8. Contrato candidato da RPC 5A

A RPC candidata da Fase 5A será:

```sql
public.mesa_cliente_simular_impacto_financeiro_admin(
  p_simulacao_id uuid,
  p_agenda_id uuid default null,
  p_operacao_json jsonb,
  p_parametros_json jsonb default '{}'::jsonb
)
returns jsonb
```

Este contrato ainda depende de preflight antes da migration.

### 8.1 Significado do sufixo `_admin`

`_admin` significa:

```text
visão interna/administrativa segura
```

Não significa necessariamente apenas `admin_global`.

A autorização final deve ser resolvida pelo banco e pode incluir, conforme política validada:

- `admin_global`/root;
- admin local;
- gestor/coordenador;
- corretor dono da simulação, se a operação for permitida para o fluxo do MesaCliente.

A permissão exata deve ser validada em preflight e teste negativo.

---

## 9. Princípios obrigatórios da futura RPC

A futura RPC deve seguir:

```text
security definer
set search_path = public
revoke execute from public
revoke execute from anon
grant execute to authenticated
```

E deve validar:

- `auth.uid()` obrigatório;
- usuário ativo;
- empresa/tenant resolvido pelo banco;
- perfil autorizado;
- simulação existente;
- simulação pertencente ao tenant;
- empreendimento válido;
- agenda ativa existente;
- agenda pertencente à mesma simulação/empresa/empreendimento;
- parcelas pertencentes à agenda ativa;
- operação solicitada permitida;
- parcelas-alvo elegíveis;
- valores não negativos;
- datas válidas;
- periodicidade simbólica não negociável;
- ausência de payload soberano vindo do frontend.

---

## 10. Entrada candidata: `p_operacao_json`

O JSON de operação deve ser tratado como **intenção**, não como autoridade.

Campos candidatos:

```json
{
  "tipo_operacao": "antecipacao | postergacao | alteracao_valor | renegociacao",
  "parcelas": [
    {
      "parcela_id": "uuid",
      "novo_valor": 0,
      "nova_data": "YYYY-MM-DD"
    }
  ],
  "justificativa": "texto opcional"
}
```

Nenhum campo abaixo pode ser aceito como autoridade do frontend:

- `empresa_id`;
- `corretor_id`;
- `empreendimento_id`;
- `agenda_id` sem validação cruzada;
- `taxa_ano_pct`;
- `vpl_aplicado_pct`;
- `politica_id`;
- `premio_corretor_pct`;
- `desconto_calculado`;
- `acrescimo_calculado`;
- `economia_liquida`;
- qualquer total calculado pelo client.

Se esses campos vierem no payload, a RPC deve ignorar ou bloquear, conforme decisão final da 5A.2. A recomendação inicial é bloquear campos soberanos e sensíveis para reduzir risco de fraude silenciosa.

---

## 11. Tipos de operação candidatos

A Fase 5A pode começar com um escopo mínimo, sem tentar abraçar o mundo como polvo em liquidação.

Tipos candidatos:

| Tipo | Descrição | Status no contrato 5A.1 |
|---|---|---:|
| `antecipacao` | Trazer parcela para data anterior | candidato |
| `postergacao` | Levar parcela para data posterior | candidato |
| `alteracao_valor` | Alterar valor de parcela sem mudar data | candidato com cautela |
| `renegociacao` | Combinar data e valor | candidato futuro |

Recomendação de implantação:

```text
Começar 5A.2 com antecipação e/ou postergacao. Não implementar todos os tipos no primeiro SQL se a política financeira ainda não estiver explícita.
```

---

## 12. Elegibilidade das parcelas

A futura RPC deve usar as flags persistidas pela 4B como fonte primária de elegibilidade:

- `pode_receber_antecipacao`;
- `pode_receber_postergacao`;
- `pode_receber_vpl`;
- `eh_periodicidade_simbolica`.

Regras mínimas:

- `eh_periodicidade_simbolica = true` nunca pode ser negociável;
- parcela sem elegibilidade para o tipo solicitado deve bloquear;
- parcela de outro tenant deve bloquear;
- parcela de outra agenda deve bloquear;
- parcela de agenda substituída/bloqueada deve bloquear;
- valor negativo deve bloquear;
- data inválida deve bloquear;
- operação sem parcelas deve bloquear.

---

## 13. Cálculo financeiro: ponto ainda não autorizado para inferência

A fórmula de impacto financeiro **não será inventada** nesta fase documental.

Antes da migration 5A.2, é obrigatório confirmar:

- se a taxa é anual, mensal ou diária;
- se o cálculo é simples, composto, pró-rata, VPL ou outra regra;
- se a base de dias usa 30/360, dias corridos, dias úteis ou outra convenção;
- se antecipação gera desconto;
- se postergacao gera acréscimo;
- se existe política por empreendimento, empresa, tabela, campanha ou perfil;
- se prêmio/comissão entra no cálculo da simulação ou apenas em fase posterior;
- se arredondamento é por parcela, por operação ou no total;
- quantas casas decimais usar;
- se IOF, INCC, juros ou atualização monetária entram agora ou ficam fora.

Regra de segurança:

```text
Sem fonte oficial da fórmula, a 5A.2 não pode implementar cálculo financeiro definitivo.
```

A 5A.2 pode implementar cálculo somente se:

1. a fórmula estiver documentada;
2. o preflight indicar de onde vêm taxa/política;
3. os testes cobrirem exemplos numéricos controlados;
4. o retorno separar cálculo administrativo de retorno cliente-safe futuro.

---

## 14. Saída candidata da RPC 5A

A saída da futura RPC deve ser administrativa, não cliente-safe.

Formato candidato:

```json
{
  "ok": true,
  "fase": "5A_SIMULACAO_IMPACTO_FINANCEIRO",
  "visao": "administrativa",
  "cliente_safe": false,
  "persistencia": false,
  "dml_financeiro": false,
  "simulacao_id": "uuid",
  "agenda_id": "uuid",
  "tipo_operacao": "antecipacao",
  "resultado": {
    "valida": true,
    "motivos_bloqueio": [],
    "qtd_parcelas_afetadas": 1,
    "valor_original_total": 0,
    "valor_simulado_total": 0,
    "impacto_estimado": 0
  },
  "parcelas": []
}
```

Campos proibidos no retorno se o payload for reaproveitado em cliente-safe no futuro:

- política interna completa;
- prêmio de corretor;
- comissão;
- payload bruto;
- dados de auditoria;
- `service_role`/claims;
- qualquer segredo de cálculo.

Na 5A, por ser admin, alguns campos de cálculo interno podem aparecer **somente se forem necessários para auditoria interna**, mas devem ser explicitamente classificados como `admin_only` e nunca usados no cliente-safe.

---

## 15. Persistência proibida na Fase 5A

A Fase 5A deve provar ausência de DML em:

```text
mesa_cliente_agendas_financeiras
mesa_cliente_fluxo_parcelas
mesa_cliente_fluxo_operacoes
```

Critério obrigatório dos testes:

```text
count_before = count_after
```

Para as três áreas:

- agendas financeiras;
- parcelas financeiras;
- operações financeiras.

Se qualquer teste da 5A criar linha em `mesa_cliente_fluxo_operacoes`, ele está errado para 5A.

---

## 16. Testes obrigatórios da Fase 5A

A nomenclatura proposta é:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_impacto_financeiro_readonly.sql
supabase/tests/mesa-cliente/engenharia-financeira/10a_validacao_impacto_financeiro_admin_dry_run_rollback.sql
supabase/tests/mesa-cliente/engenharia-financeira/10b_validacao_impacto_financeiro_admin_negativos_rollback.sql
```

### 16.1 Preflight 10

Deve inventariar, sem DML:

- colunas reais de `mesa_cliente_fluxo_operacoes`;
- constraints de operações;
- enums/domínios usados em operações;
- grants de operações;
- policies RLS;
- índices;
- funções financeiras já existentes;
- tabelas de política financeira, se existirem;
- funções de auth/perfil;
- RPCs existentes relacionadas a impacto financeiro;
- dados permanentes existentes;
- candidatos de fixture real, se houver.

### 16.2 Teste 10A positivo

Deve validar:

- fixture transacional;
- agenda ativa persistida;
- parcelas elegíveis;
- chamada da RPC 5A;
- retorno `ok = true`;
- `fase = 5A_SIMULACAO_IMPACTO_FINANCEIRO`;
- `persistencia = false`;
- `dml_financeiro = false`;
- cálculo coerente com fórmula oficial;
- zero DML em agendas;
- zero DML em parcelas;
- zero DML em operações;
- rollback.

### 16.3 Teste 10B negativo

Deve validar bloqueios:

- sem auth;
- anon;
- simulação inexistente;
- simulação sem agenda ativa;
- agenda substituída;
- cross-tenant;
- parcela inexistente;
- parcela de outra agenda;
- parcela de outro tenant;
- periodicidade simbólica;
- parcela sem flag de elegibilidade;
- valor negativo;
- data inválida;
- payload com `empresa_id` fake;
- payload com taxa/política fake;
- payload tentando enviar total calculado pelo client;
- operação sem parcelas;
- tipo de operação inválido;
- zero DML em todas as tabelas financeiras.

---

## 17. Definition of Ready da 5A.2

A 5A.2 só pode começar quando todos os itens abaixo estiverem atendidos:

| Item | Obrigatório |
|---|---:|
| 4C fechada/documentada | sim |
| contrato 5A.1 criado | sim |
| preflight 10 read-only executado | sim |
| resultsets do preflight analisados | sim |
| colunas reais confirmadas | sim |
| constraints confirmadas | sim |
| grants/RLS confirmados | sim |
| fórmula de cálculo definida por fonte oficial | sim |
| tipos de operação do primeiro escopo definidos | sim |
| campos sensíveis mapeados | sim |
| critérios de aceite dos testes 10A/10B aprovados | sim |

Sem esses itens, não criar migration 5A.2.

---

## 18. Definition of Done da Fase 5A

A Fase 5A só será considerada concluída quando:

- a RPC admin de dry-run existir;
- `anon` estiver bloqueado;
- `authenticated` estiver liberado somente via RPC;
- tenant for validado pelo banco;
- agenda ativa for validada;
- parcelas elegíveis forem validadas;
- cálculo for coerente com fórmula oficial;
- retorno for administrativo e não cliente-safe;
- campos sensíveis estiverem controlados;
- não houver DML em agendas, parcelas ou operações;
- testes 10A e 10B passarem;
- documentação de fechamento da 5A for criada.

---

## 19. Regra contra premissa falsa

A partir deste contrato, fica proibido assumir:

- que uma coluna existe porque o nome parece óbvio;
- que `data_vencimento` existe como coluna física;
- que `totals` existe em vez de `totais`;
- que taxa financeira pode vir do frontend;
- que `empresa_id` do payload é confiável;
- que operação simulada pode ser persistida;
- que payload admin pode virar cliente-safe;
- que fórmula de VPL é “padrão de mercado” sem validação;
- que teste passando significa segurança se os cenários hostis não foram testados.

---

## 20. Travas finais antes do SQL

Antes de qualquer SQL da 5A.2, deve ser respondido:

1. Qual tipo de operação será implementado primeiro?
2. Qual fórmula oficial será usada?
3. De onde virá a taxa/política?
4. Quais colunas reais de `mesa_cliente_fluxo_operacoes` existem hoje?
5. A 5A pode ler operações confirmadas apenas para bloqueio?
6. Qual perfil pode simular impacto?
7. O corretor dono pode simular ou somente gestor/admin?
8. O retorno admin pode exibir taxa aplicada ou isso fica restrito?
9. Qual arredondamento será adotado?
10. Quais testes numéricos serão usados como gabarito?

Sem essas respostas, qualquer SQL de cálculo financeiro é chute. E chute em financeiro é calculadora fantasiada de granada.

---

## 21. Próximo passo oficial

O próximo passo não é migration.

O próximo passo é criar e executar:

```text
supabase/tests/mesa-cliente/engenharia-financeira/10_preflight_impacto_financeiro_readonly.sql
```

Esse preflight deve ser read-only e deve enviar resultset único completo antes de qualquer SQL de implementação.

Frase de parada:

```text
Preflight 10 read-only concluído. Envie todos os resultsets antes de criar qualquer migration 5A.2.
```

---

## 22. Resumo executivo

A Fase 5A será a primeira fase de cálculo de impacto financeiro sobre a agenda persistida.

Por isso, ela é mais perigosa que a 4C:

- 4C só lia e filtrava;
- 5A calcula impacto;
- 5B vai registrar operação;
- 5C vai confirmar/cancelar.

A 5A precisa ser tratada como dry-run administrativo, com zero persistência e fórmula validada.

Veredito deste documento:

```text
Contrato 5A.1 fechado para orientar preflight e desenho da 5A.2.
Não autorizado criar migration de cálculo sem preflight e fórmula oficial.
```
