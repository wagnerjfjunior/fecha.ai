# FECH.AI — LeadOps CRM Discador / Especificação Funcional MVP v1

**Status:** v1.0 — especificação funcional inicial  
**Data:** 2026-06-02  
**Módulo:** LeadOps, Listas, CRM e Discador  
**Fase do roadmap:** Fase 1 — MVP Operacional / LeadOps CRM Discador  
**Especialista principal:** GPT 7 — FECH.AI — LeadOps CRM Discador Specialist  
**Apoio obrigatório:** GPT 1, GPT 2, GPT 3 e GPT 5.

---

## 1. Objetivo

Definir o primeiro escopo funcional executável do módulo LeadOps CRM Discador.

O objetivo é permitir que o corretor importe uma lista real, trabalhe os contatos com poucos cliques, registre status e visualize quantas visitas conseguiu agendar para o fim de semana.

O MVP deve provar valor diário antes de avançar para automações complexas, portais, WhatsApp oficial completo, campanhas automatizadas ou app nativo.

---

## 2. Hipótese central

```text
Se o corretor conseguir importar contatos, agir rápido, registrar status e visualizar agendamentos do fim de semana, o FECH.AI cria valor prático, recorrente e monetizável.
```

---

## 3. Personas iniciais

### 3.1 Corretor

Usa o sistema para:

- importar contatos;
- ligar;
- abrir WhatsApp;
- registrar status;
- organizar retorno;
- agendar visita;
- visualizar produtividade.

### 3.2 Gestor

Usa o sistema para:

- importar listas para equipe;
- acompanhar produção;
- ver contatos trabalhados;
- ver visitas agendadas;
- identificar corretor parado;
- medir conversão por lista/origem.

### 3.3 Admin

Usa o sistema para:

- configurar tenant/empresa;
- administrar permissões;
- acompanhar uso;
- dar suporte;
- auditar importações e falhas.

---

## 4. Escopo funcional do MVP

### 4.1 Importação de listas

Entradas obrigatórias no MVP:

- CSV;
- XLSX;
- texto colado;
- cadastro manual individual.

Entradas beta/controladas:

- foto/OCR de lista de papel;
- imagem com contatos;
- PDF simples quando tecnicamente viável.

Fora do MVP inicial:

- importação automática de portais;
- app nativo/share extension;
- OCR sem revisão humana;
- enriquecimento externo de dados;
- disparo automático em massa.

---

## 5. Fluxo de importação

Fluxo recomendado:

```text
1. Usuário escolhe origem: arquivo, texto, foto/OCR ou manual.
2. Sistema lê o conteúdo.
3. Sistema apresenta prévia.
4. Usuário mapeia campos quando necessário.
5. Sistema valida telefone/e-mail.
6. Sistema detecta duplicidades.
7. Sistema mostra resumo da importação.
8. Usuário confirma.
9. Sistema grava leads/lista.
10. Sistema registra log/auditoria.
```

---

## 6. Campos mínimos do lead

Campos obrigatórios:

- nome ou identificador;
- telefone;
- corretor responsável;
- tenant;
- empresa;
- origem;
- lista;
- status;
- data de criação.

Campos opcionais:

- e-mail;
- empreendimento de interesse;
- bairro;
- perfil de imóvel;
- observação;
- valor de interesse;
- UTM source;
- UTM medium;
- UTM campaign;
- UTM content;
- UTM term;
- fbclid;
- gclid.

Campos sistêmicos:

- lead_id;
- lista_id;
- created_by;
- updated_by;
- data da última interação;
- origem técnica;
- hash/normalização de telefone quando aplicável;
- flags de duplicidade;
- confiança OCR quando aplicável.

---

## 7. Validação e deduplicação

### 7.1 Validação de telefone

O sistema deve:

- limpar espaços, símbolos e caracteres inválidos;
- reconhecer DDD;
- aceitar telefone móvel e fixo;
- sinalizar telefone incompleto;
- impedir gravação em massa de contatos sem telefone utilizável, salvo decisão explícita do usuário.

### 7.2 Deduplicação

Deduplicação mínima:

- mesmo telefone no mesmo tenant/empresa;
- mesmo telefone na mesma lista;
- mesmo telefone para o mesmo corretor.

O sistema deve mostrar:

- novos contatos;
- possíveis duplicados;
- contatos inválidos;
- contatos ignorados;
- contatos importados.

Regra: deduplicação não deve vazar dados entre tenants.

---

## 8. OCR de lista de papel

OCR no MVP deve ser beta/controlado.

Regras:

- OCR nunca é verdade absoluta;
- sempre mostrar prévia editável;
- destacar campos com baixa confiança;
- permitir correção manual;
- validar telefone antes da importação;
- registrar confiança média da leitura;
- bloquear importação se qualidade estiver crítica.

Critérios de aceite do OCR beta:

```text
1. usuário consegue tirar/enviar foto;
2. sistema extrai contatos prováveis;
3. sistema mostra prévia;
4. usuário corrige campos;
5. sistema valida telefones;
6. importação só ocorre após confirmação.
```

---

## 9. Funil CRM mínimo

Status mínimos:

```text
Novo
Tentando contato
Contato realizado
Qualificado
Visita agendada
Visita realizada
Proposta enviada
Perdido
Vendido
```

Regras:

- todo lead começa como Novo, salvo importação com status informado e validado;
- toda mudança de status deve registrar data, usuário e origem da alteração;
- status Perdido deve permitir motivo;
- Visita agendada deve exigir data/hora ou observação clara;
- Vendido deve exigir permissão adequada em fase futura.

---

## 10. Ações rápidas

A tela do lead deve permitir:

- ligar;
- abrir WhatsApp;
- copiar telefone;
- alterar status;
- registrar observação;
- definir próxima ação;
- agendar visita;
- marcar lead como perdido;
- avançar para próximo lead.

Meta de UX:

```text
corretor deve conseguir sair de um lead para o próximo em poucos cliques.
```

---

## 11. Power Mode v1

Power Mode é o modo de execução rápida.

Deve exibir:

- lead atual;
- telefone;
- origem/lista;
- último status;
- botão ligar;
- botão WhatsApp;
- script curto;
- botões de resultado;
- próximo lead.

Resultados rápidos sugeridos:

```text
Não atendeu
WhatsApp enviado
Contato realizado
Qualificado
Visita agendada
Sem interesse
Retornar depois
Número inválido
```

Métricas da sessão:

- leads trabalhados;
- ligações iniciadas;
- WhatsApps abertos;
- contatos realizados;
- visitas agendadas;
- leads restantes.

---

## 12. Dashboard de fim de semana

Objetivo: gerar clareza e urgência operacional.

Cards mínimos:

- meta de visitas do fim de semana;
- visitas agendadas;
- faltam X visitas;
- leads novos disponíveis;
- leads quentes/parados;
- contatos trabalhados hoje;
- conversão contato → visita.

Exemplo de mensagem:

```text
Você tem 3 visitas agendadas para o fim de semana. Faltam 5 para bater sua meta. Existem 17 leads com potencial aguardando contato.
```

Regra ética: usar pressão produtiva e clareza, não manipulação abusiva.

---

## 13. Permissões e multi-tenancy

Regras obrigatórias:

- corretor vê apenas seus leads ou leads atribuídos a ele;
- gestor vê leads da sua equipe/empresa conforme permissão;
- admin vê conforme escopo administrativo;
- nenhum usuário acessa lead de outro tenant sem vínculo real;
- tenant_id e empresa_id não devem ser aceitos apenas do frontend;
- validação deve ocorrer no banco/backend/RPC quando aplicável.

---

## 14. LGPD e compliance

Obrigatório:

- registrar origem da lista quando possível;
- permitir exclusão/opt-out quando aplicável;
- evitar logs com PII bruta;
- não expor dados sensíveis em erro;
- controlar acesso por perfil;
- não enviar dados para plataformas externas sem base adequada;
- documentar finalidade do tratamento.

---

## 15. Observabilidade mínima

Eventos/logs mínimos:

- importação iniciada;
- importação concluída;
- importação com erro;
- quantidade de contatos processados;
- contatos válidos/inválidos/duplicados;
- OCR com baixa confiança;
- alteração de status;
- ação de ligar;
- ação de WhatsApp;
- visita agendada;
- erro de permissão;
- tentativa de acesso cross-tenant bloqueada.

Métricas importantes:

- taxa de importação com sucesso;
- tempo de importação;
- leads trabalhados por dia;
- visitas agendadas;
- erros por usuário/tenant;
- duplicidade por lista.

---

## 16. Critérios de aceite

O MVP LeadOps só deve ser considerado pronto quando:

```text
1. usuário importa CSV/XLSX simples;
2. usuário cola texto e importa contatos;
3. sistema mostra prévia antes de gravar;
4. sistema valida telefone;
5. sistema detecta duplicados básicos;
6. lead entra no funil correto;
7. corretor consegue ligar/abrir WhatsApp;
8. corretor registra status rapidamente;
9. Power Mode permite trabalhar sequência de leads;
10. dashboard mostra visitas agendadas para o fim de semana;
11. permissões multi-tenant são respeitadas;
12. há logs mínimos de importação e erro;
13. fluxo funciona em desktop e mobile;
14. há caminho de rollback para release.
```

---

## 17. Fora do escopo desta especificação

Não implementar nesta etapa:

- envio automático em massa;
- WhatsApp oficial completo;
- WhatsApp não oficial;
- integração com portais;
- enriquecimento externo;
- campanha automática;
- gateway próprio de conversões;
- MesaCliente completo;
- app nativo;
- OCR sem revisão humana.

---

## 18. Próximos documentos sugeridos

Após aprovação desta especificação:

```text
docs/product/leadops-crm-discador/leadops-data-model-v1.md
docs/product/leadops-crm-discador/leadops-ux-flow-v1.md
docs/product/leadops-crm-discador/leadops-acceptance-tests-v1.md
```

Esses documentos devem anteceder qualquer implementação real via Codex.
