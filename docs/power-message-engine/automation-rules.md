# Power Message Engine — Regras de Automação

## 1. Objetivo

Definir limites e comportamento do **Acelerador / Oferta Ativa** e do **Piloto Automático**.

---

## 2. Acelerador / Oferta Ativa

### 2.1 Definição

Modo assistido em que o corretor executa contatos com orientação do sistema.

O sistema sugere:

- canal;
- mensagem;
- script;
- próximo passo;
- feedback esperado.

O corretor confirma e executa.

### 2.2 Regras

- Não permitir avançar sem registrar feedback.
- Não sugerir mensagem final antes das tentativas anteriores, salvo encerramento manual.
- Não repetir template já usado para o mesmo lead.
- Exibir histórico recente antes da próxima abordagem.
- Mostrar sempre o motivo da sugestão.

---

## 3. Piloto Automático

### 3.1 Definição

Modo em que o sistema controla a cadência e lembra o corretor sobre próximas ações.

Na v1, deve ser prioritariamente assistivo.

### 3.2 Ações automáticas seguras

- gerar tarefa;
- sugerir mensagem;
- lembrar retorno;
- alertar lead parado;
- sugerir mudança de canal;
- pausar cadência após limite de tentativas;
- mover para status de sem resposta conforme regra.

### 3.3 Ações que exigem política explícita

- envio automático de WhatsApp;
- envio em lote;
- reativação de lista fria;
- múltiplas tentativas no mesmo dia;
- uso de múltiplos números;
- campanhas fora do horário comercial.

---

## 4. Limites operacionais sugeridos

### 4.1 Lista fria

- Máximo de 1 tentativa de WhatsApp inicial assistida.
- Segunda tentativa somente após intervalo mínimo.
- Evitar abordagem agressiva.
- Mensagem deve pedir permissão ou abrir conversa de forma leve.

### 4.2 Lead quente

- Contato inicial o mais rápido possível.
- WhatsApp e ligação podem ser sugeridos no mesmo fluxo, mas com registro claro.
- Se houver resposta, interromper cadência automática e mover para atendimento ativo.

### 4.3 Visitou plantão

- Priorizar retorno consultivo.
- Evitar mensagem genérica.
- Sugerir ligação ou WhatsApp personalizado.
- Trabalhar objeções e próximos passos.

---

## 5. Condições de parada

A cadência deve parar quando houver:

- `agendou_visita`;
- `proposta`;
- `simulacao`;
- `sem_interesse`;
- `numero_errado`;
- `lead_ja_atendido`;
- `opt_out`;
- resposta manual relevante do cliente;
- bloqueio definido pelo gestor.

---

## 6. Condições de pausa

A cadência deve pausar quando:

- cliente pediu retorno futuro;
- corretor marcou follow-up específico;
- lead está em negociação;
- houve tentativa recente demais;
- gestor pausou campanha/lista;
- tenant atingiu limite operacional.

---

## 7. Auditoria obrigatória

Cada sugestão ou envio deve registrar:

- lead;
- corretor;
- tenant;
- canal;
- template;
- fase;
- mensagem renderizada;
- data/hora;
- status;
- feedback posterior.

Sem log, não existe operação confiável.

---

## 8. Regra anti-labirinto

A tela do corretor não deve expor complexidade de cadência.

O corretor deve ver no máximo:

- melhor próxima ação;
- mensagem/script sugerido;
- botões de execução;
- feedback rápido;
- histórico essencial.

Toda lógica pesada fica por trás.

---

## 9. Recomendação para v1

Implementar primeiro:

1. templates estruturados;
2. seleção automática;
3. histórico de uso;
4. tela de ação assistida;
5. feedback obrigatório;
6. próxima ação sugerida.

Depois evoluir para automações mais sofisticadas.
