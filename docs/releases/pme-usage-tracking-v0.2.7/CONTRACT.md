# CONTRACT — PME Usage Tracking & Script Utility v0.2.7

## 1. Objetivo

Definir o contrato da release v0.2.7 para registrar eventos de uso do Discador Flow AI / PME, com foco em rastreabilidade comercial, reaproveitamento futuro de scripts e redução gradual de custo de IA.

A release deve criar uma base confiável para responder perguntas como:

- Quais scripts são mais utilizados?
- Em qual canal cada script funciona melhor?
- A IA é mais usada em qual tipo de situação?
- Quais textos são executados após melhoria com IA?
- Quais contextos geram maior avanço no funil?
- Quais mensagens devem virar templates oficiais?

---

## 2. Escopo funcional

A v0.2.7 deve registrar eventos quando o corretor interagir com os scripts/mensagens do PME.

Eventos mínimos:

| Evento | Momento | Observação |
|---|---|---|
| `script_viewed` | quando uma sugestão é exibida | pode ser amostrado/debounce para evitar excesso |
| `script_variant_changed` | ao clicar em Próximo/Voltar | mede navegação entre mensagens |
| `ai_requested` | ao clicar em Gerar nova versão/Gerar com esta dica | mede demanda de IA |
| `ai_succeeded` | quando IA retorna texto utilizável | mede sucesso da IA |
| `ai_failed` | quando IA falha | mede falha técnica ou sessão |
| `script_executed` | ao clicar em Efetuar ligação/Abrir WhatsApp/Preparar e-mail | evento principal |
| `script_copied_fallback` | quando cai em cópia manual por ausência de telefone/e-mail | evento operacional |

---

## 3. Dados mínimos do evento

O frontend pode enviar metadados do clique, mas a RPC deve validar e complementar dados sensíveis no backend.

Payload mínimo proposto:

```json
{
  "event_type": "script_executed",
  "module": "discador_flow_ai",
  "module_version": "0.2.7",
  "lead_id": "uuid-ou-null",
  "lead_phone_hash": "sha256-ou-null",
  "context": "lista_fria",
  "channel": "whatsapp",
  "approach": "objecao_entrada",
  "script_source": "template|ai|fallback",
  "script_key": "opcional",
  "script_variant": 0,
  "script_text_hash": "sha256",
  "ai_attempt": 1,
  "ai_tip_hash": "sha256-ou-null",
  "execution_target": "whatsapp|tel|mailto|manual_copy",
  "client_timestamp": "2026-05-23T00:00:00.000Z"
}
```

---

## 4. Regras de fonte do script

`script_source` deve indicar a origem do texto utilizado:

| Valor | Significado |
|---|---|
| `template` | texto base do banco local de templates do PME |
| `ai` | texto retornado pela IA no modal |
| `fallback` | texto copiado/usado manualmente por falha de canal |
| `unknown` | fonte não identificada; deve ser evitado |

---

## 5. Regras de privacidade

Na v0.2.7, o padrão é **não persistir texto completo**.

Persistir preferencialmente:

- hash do texto;
- metadados do contexto;
- canal;
- situação;
- fonte;
- ação;
- versão;
- lead seguro quando disponível;
- tenant/empresa/usuário resolvidos no backend.

Texto completo só deve entrar em release futura com:

- justificativa de produto;
- política de retenção;
- consentimento/governança;
- RLS forte;
- criptografia quando aplicável;
- trilha de auditoria.

---

## 6. Associação com feedback

A v0.2.7 pode preparar campos para associação futura com feedback, mas não deve alterar o motor de feedback.

Campos futuros:

- `feedback_id`;
- `feedback_tipo`;
- `feedback_result_group`;
- `utility_score`;
- `converted_to_template`.

Regra:

> A associação entre evento de script e feedback deve ser feita de forma segura e preferencialmente no backend, nunca por suposição frágil do frontend.

---

## 7. Critérios de aceite

A release é aceita quando:

- eventos são registrados sem bloquear o atendimento;
- falha no registro não impede ligação/WhatsApp/e-mail;
- login continua funcionando;
- snapshot continua funcionando;
- discador continua funcionando;
- feedback continua funcionando;
- próximo lead continua funcionando;
- não há `service_role` no frontend;
- não há segredo sensível no console/network;
- RLS impede acesso cruzado entre tenants/empresas.

---

## 8. Fora de escopo

Não pertence à v0.2.7:

- dashboard gerencial definitivo;
- ranking final de scripts;
- biblioteca curada de scripts aprovada por gestor;
- billing real de IA;
- cache semântico em produção;
- persistência de texto completo;
- alteração em `registrar_feedback`;
- alteração no motor de distribuição de leads;
- envio automático de mensagens.

---

## 9. Princípio operacional

O tracking deve ser invisível para o corretor. O corretor executa o atendimento; o sistema registra de forma assíncrona e segura.

Se o tracking falhar, o atendimento continua.
