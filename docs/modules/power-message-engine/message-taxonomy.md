# Power Message Engine — Taxonomia de Mensagens

## 1. Objetivo

Este documento define a taxonomia operacional do Power Message Engine: canais, tipos de lead, fases, estados, intenções e regras de classificação.

A taxonomia é essencial para impedir que o módulo vire uma central de templates soltos sem inteligência operacional.

---

## 2. Canais

### 2.1 WhatsApp

Uso principal:

- primeira abordagem rápida;
- retomada;
- envio de link;
- convite para visita;
- continuidade de conversa.

Características:

- mensagens curtas;
- CTA objetivo;
- tom humano;
- baixa fricção.

### 2.2 Ligação

Uso principal:

- qualificação;
- avanço de negociação;
- retomada de lead quente;
- quebra de objeção;
- confirmação de visita.

Características:

- script guiado;
- perguntas abertas;
- foco em diagnóstico;
- registro obrigatório de feedback.

### 2.3 E-mail

Uso principal:

- envio formal de material;
- reforço de autoridade;
- resumo de proposta;
- nutrição de leads que não responderam WhatsApp.

Características:

- texto mais estruturado;
- assunto claro;
- CTA único;
- link rastreável.

---

## 3. Tipos de lead

### 3.1 `lead_quente`

Lead com intenção recente.

Critérios possíveis:

- formulário recente;
- campanha ativa;
- WhatsApp iniciado;
- pediu preço;
- pediu planta;
- pediu simulação;
- interagiu nos últimos dias.

### 3.2 `lista_fria`

Lead sem intenção recente validada.

Critérios possíveis:

- mailing antigo;
- lista comprada;
- base externa;
- contato sem opt-in claro para aquele empreendimento;
- ausência de interação recente.

### 3.3 `lista_quente_visitou_plantao`

Lead que já teve contato presencial ou pré-negociação.

Critérios possíveis:

- visitou plantão;
- foi atendido anteriormente;
- recebeu tabela;
- simulou unidade;
- pediu proposta;
- está comparando opções.

---

## 4. Fases de abordagem

### 4.1 `fase_1_primeira_mensagem`

Primeira tentativa estruturada.

Objetivo:

- abertura;
- apresentação;
- geração de resposta.

### 4.2 `fase_2_retomada_leve`

Segunda tentativa.

Objetivo:

- retomar contato;
- reforçar contexto;
- evitar tom de cobrança.

### 4.3 `fase_3_avanco_comercial`

Terceira tentativa.

Objetivo:

- provocar avanço;
- sugerir visita, simulação ou ligação;
- filtrar real interesse.

### 4.4 `fase_4_encerramento_elegante`

Mensagem final do ciclo.

Objetivo:

- encerrar sem desgastar;
- deixar porta aberta;
- registrar lead como sem resposta, se aplicável.

---

## 5. Status de relacionamento

### 5.1 `ainda_nao_falou`

Corretor ainda não teve contato real com o cliente.

### 5.2 `ja_falou`

Já houve conversa anterior por qualquer canal.

### 5.3 `visitou_plantao`

Lead já esteve no plantão ou stand de vendas.

### 5.4 `pediu_proposta`

Lead demonstrou intenção objetiva de compra ou comparação.

### 5.5 `sumiu`

Lead estava em contato e parou de responder.

### 5.6 `sem_interesse`

Lead declarou falta de interesse.

### 5.7 `opt_out`

Lead pediu para não receber mais contato.

---

## 6. Intenção da mensagem

Cada template deve ter uma intenção principal.

Valores sugeridos:

- `abertura`
- `retomada`
- `convite_visita`
- `envio_material`
- `pedido_simulacao`
- `confirmacao_interesse`
- `quebra_objecao`
- `urgencia_comercial`
- `encerramento`
- `pos_visita`
- `recuperacao`

---

## 7. Tom da mensagem

Cada template pode ser classificado por tom.

Valores sugeridos:

- `consultivo`
- `executivo`
- `direto`
- `acolhedor`
- `premium`
- `popular`
- `urgente`
- `neutro`
- `reativacao`

---

## 8. Regras por origem

### 8.1 Meta Ads

Preferir:

- abordagem rápida;
- menção ao interesse demonstrado;
- CTA para valores, planta ou simulação.

Evitar:

- texto longo;
- formalidade excessiva.

### 8.2 Google Ads

Preferir:

- abordagem mais objetiva;
- considerar que o lead já estava buscando ativamente;
- CTA para visita ou simulação.

### 8.3 Lista comprada

Preferir:

- abordagem cuidadosa;
- validação de interesse;
- opção clara de não continuidade.

Evitar:

- tom agressivo;
- pressupor que o lead pediu contato.

### 8.4 Visitou plantão

Preferir:

- retomada contextual;
- referência à visita;
- avanço para proposta, simulação ou escolha de unidade.

---

## 9. Estados técnicos de tentativa

Cada tentativa de comunicação deve gerar registro com status.

Valores sugeridos:

- `prepared` — mensagem preparada;
- `copied` — mensagem copiada;
- `sent_external` — enviada fora do sistema;
- `sent_integrated` — enviada por integração oficial;
- `call_started` — ligação iniciada;
- `call_completed` — ligação concluída;
- `email_generated` — e-mail gerado;
- `email_sent` — e-mail enviado;
- `failed` — falha;
- `blocked_by_opt_out` — bloqueada por opt-out;
- `skipped` — ignorada pelo corretor.

---

## 10. Regra de encerramento de ciclo

Um ciclo pode ser encerrado quando:

1. fase final foi enviada;
2. lead pediu opt-out;
3. lead foi convertido para visita/proposta;
4. lead foi classificado como sem interesse;
5. lead tem telefone inválido;
6. gestor/corretor encerrou manualmente com justificativa.

---

## 11. Regra de segurança operacional

Nenhuma ação automatizada deve ocorrer se:

- lead está em opt-out;
- telefone está marcado como inválido;
- tenant não corresponde ao usuário logado;
- corretor não tem permissão sobre o lead;
- campanha está inativa;
- template está inativo;
- canal está desativado para aquele tenant.
