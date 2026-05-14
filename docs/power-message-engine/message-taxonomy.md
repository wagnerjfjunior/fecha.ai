# Power Message Engine — Taxonomia de Mensagens

## 1. Objetivo

Padronizar como mensagens, scripts e abordagens serão classificados dentro da Central de Mensagens.

A taxonomia evita que o sistema vire uma gaveta bagunçada de textos parecidos.

---

## 2. Canais

| Código | Canal | Uso |
|---|---|---|
| `whatsapp` | WhatsApp | Contato rápido e conversacional |
| `email` | E-mail | Reforço formal, material, proposta, nutrição |
| `call_script` | Ligação | Script orientativo para conversa ao vivo |

---

## 3. Tipos de lead

| Código | Nome | Abordagem |
|---|---|---|
| `lead_quente` | Lead quente | Responder rápido e avançar |
| `lista_fria` | Lista fria | Pedir permissão e abrir conversa |
| `lista_quente` | Lista quente | Retomar contexto e avançar |
| `visitou_plantao` | Visitou plantão | Consultivo, objeções e proposta |

---

## 4. Fases

| Código | Nome | Objetivo |
|---|---|---|
| `primeira_mensagem` | Primeira mensagem | Abrir contato |
| `segunda_mensagem` | Segunda mensagem | Retomar com novo ângulo |
| `terceira_mensagem` | Terceira mensagem | Última tentativa forte antes do encerramento |
| `mensagem_final` | Mensagem final | Encerrar cadência com elegância |

---

## 5. Objetivos comerciais

| Código | Objetivo |
|---|---|
| `abertura` | Iniciar conversa |
| `qualificacao` | Entender perfil e momento |
| `envio_info` | Enviar informações do projeto |
| `simulacao` | Levar para simulação |
| `visita` | Agendar visita ao plantão |
| `retorno` | Retomar conversa pausada |
| `reativacao` | Reativar lead antigo |
| `objection_handling` | Trabalhar objeção |
| `encerramento` | Finalizar cadência |

---

## 6. Tons de comunicação

| Código | Tom | Quando usar |
|---|---|---|
| `consultivo` | Consultivo | Padrão mais seguro para imóveis |
| `direto` | Direto | Lead quente ou fundo de funil |
| `executivo` | Executivo | Alto padrão, investidor, cliente formal |
| `leve` | Leve | WhatsApp inicial ou retomada suave |
| `reativacao` | Reativação | Lead parado ou base antiga |
| `urgencia_elegante` | Urgência elegante | Condição, tabela, disponibilidade |

---

## 7. Intensidade da abordagem

| Nível | Código | Descrição |
|---|---|---|
| 1 | `suave` | Baixa pressão, abertura gentil |
| 2 | `moderada` | Comercial claro, ainda consultivo |
| 3 | `forte` | Foco em conversão, visita ou resposta |
| 4 | `finalizacao` | Encerramento da cadência |

---

## 8. Regras para mensagens de WhatsApp

Cada mensagem deve:

- ser curta o suficiente para leitura rápida;
- ter uma intenção única;
- evitar textão corporativo;
- parecer humana;
- não prometer condição inexistente;
- não pressionar de forma agressiva;
- ter CTA claro.

### Exemplo de campos de classificação

```json
{
  "channel": "whatsapp",
  "lead_type": "lead_quente",
  "phase": "primeira_mensagem",
  "objective": "abertura",
  "tone": "consultivo",
  "intensity": "moderada"
}
```

---

## 9. Regras para scripts de ligação

Um script de ligação deve conter blocos, não um texto engessado.

Blocos sugeridos:

1. abertura;
2. apresentação;
3. contexto;
4. pergunta inicial;
5. qualificação;
6. gancho comercial;
7. tratamento de objeção;
8. fechamento;
9. registro de feedback.

O corretor deve sentir que está sendo guiado, não lendo bula de remédio em voz alta.

---

## 10. Tags auxiliares

Tags sugeridas:

```txt
alto_padrao
primeiro_imovel
investidor
familia
urgencia_tabela
visita_plantao
reativar_antigo
sem_resposta
pos_visita
proposta
simulacao
financiamento
permuta
```

Essas tags podem melhorar a recomendação futura por IA.
