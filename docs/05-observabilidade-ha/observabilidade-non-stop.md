# FECH.AI — Observabilidade Non-Stop e Alta Disponibilidade

**Status:** rascunho profissional  
**Área:** observabilidade, operação e confiabilidade  
**Finalidade:** definir o padrão mínimo de monitoramento, alertas, alta disponibilidade e resposta a incidentes para operar o FECH.AI como SaaS.  
**Escopo:** documentação e planejamento operacional. Não altera infraestrutura.

---

## 1. Objetivo

Garantir que o FECH.AI possa ser operado como produto SaaS com visibilidade contínua sobre disponibilidade, erros, desempenho, segurança operacional, uso e custo.

A meta é responder rapidamente:

```text
O sistema está no ar?
Usuários conseguem logar?
RPCs críticas estão funcionando?
O banco está saudável?
O frontend está com erro?
O custo está sob controle?
Houve incidente?
Quem deve agir?
Qual runbook seguir?
```

---

## 2. Conceito de observabilidade non-stop

Observabilidade non-stop significa monitorar continuamente o produto, não apenas olhar logs quando um cliente reclama.

Camadas mínimas:

```text
uptime
logs
métricas
alertas
incidentes
custos
segurança operacional
experiência do usuário
```

---

## 3. Indicadores mínimos

| Área | Indicador | Objetivo |
|---|---|---|
| Disponibilidade | uptime do frontend | saber se o app está acessível |
| Login | falhas de autenticação | detectar bloqueio de acesso |
| Banco | erro por RPC crítica | detectar falha de regra ou schema |
| Banco | latência de consultas | identificar lentidão |
| Frontend | erros JavaScript | identificar quebra de tela |
| Deploy | build/deploy falho | evitar publicar versão quebrada |
| Leads | leads trabalhados por período | medir operação comercial |
| Discador | ações por usuário | medir produtividade |
| MesaCliente | simulações criadas | medir uso comercial |
| Histórico | abertura de 2ª via | validar uso do fluxo histórico |
| IA | chamadas por módulo | controlar custo e uso |
| Custo | gasto mensal por serviço | proteger margem SaaS |

---

## 4. Alertas mínimos

| Alerta | Severidade inicial | Ação esperada |
|---|---|---|
| Frontend indisponível | crítico | verificar Vercel/DNS/deploy |
| Login com falha generalizada | crítico | verificar Supabase Auth |
| RPC crítica com erro recorrente | alto | acionar suporte N2/N3 |
| Build/deploy falhou | médio/alto | bloquear publicação e revisar logs |
| Aumento súbito de erro no frontend | alto | verificar release recente |
| Supabase lento ou indisponível | crítico | verificar status e plano de contingência |
| Uso de IA fora do padrão | médio | investigar custo/abuso |
| Custo perto do limite planejado | médio | revisar consumo e plano |
| Backup falhou | alto | reexecutar e registrar evidência |

---

## 5. Ferramentas candidatas

| Finalidade | Ferramentas possíveis |
|---|---|
| Uptime | UptimeRobot, Better Stack |
| Erro frontend | Sentry |
| Logs frontend/deploy | Vercel Logs |
| Logs banco/RPC | Supabase Logs |
| Métricas de produto | dashboards internos + Supabase |
| Métricas futuras | Grafana/Prometheus/OpenTelemetry |
| Alertas | e-mail, Slack, WhatsApp operacional |

A ferramenta final deve ser escolhida considerando custo, simplicidade e maturidade do SaaS.

---

## 6. Alta disponibilidade

O FECH.AI usa serviços gerenciados. Portanto, a alta disponibilidade depende de:

```text
Vercel
Supabase
DNS/domínio
OpenAI/ChatGPT
serviços de comunicação futuros
```

A documentação oficial precisa registrar:

```text
plano contratado
limites do plano
SLA do provedor
backup disponível
rollback disponível
ponto único de falha
plano de contingência
```

---

## 7. RTO e RPO

Definições:

```text
RTO = tempo máximo aceitável para restaurar o serviço
RPO = perda máxima aceitável de dados
```

Metas iniciais sugeridas, ainda pendentes de validação comercial:

| Item | Meta inicial sugerida |
|---|---:|
| RTO frontend após deploy ruim | até 30 minutos |
| RTO incidente crítico em horário comercial | até 2 horas |
| RPO banco de dados | conforme backup Supabase contratado |
| Validação de backup | mensal no início |

As metas finais devem ser alinhadas ao plano comercial vendido ao cliente.

---

## 8. SLA, SLO e SLI

| Termo | Significado |
|---|---|
| SLA | compromisso comercial com o cliente |
| SLO | meta interna de operação |
| SLI | métrica que mede se a meta foi cumprida |

Exemplo:

```text
SLA: sistema disponível 99,5% no mês
SLO: manter uptime acima de 99,7%
SLI: medição de uptime por ferramenta externa
```

Não prometer SLA comercial sem validar infraestrutura, custo, suporte e contrato.

---

## 9. Runbook mínimo de incidente

Todo incidente deve registrar:

```text
ID do incidente
data e hora
cliente/tenant afetado
módulo afetado
severidade
sintoma
impacto
primeira evidência
ação inicial
responsável
status
causa raiz
correção definitiva
prevenção futura
```

---

## 10. Classificação inicial de severidade

| Severidade | Exemplo | Resposta esperada |
|---|---|---|
| SEV1 | sistema indisponível para vários clientes | ação imediata |
| SEV2 | módulo crítico falhando | priorizar correção |
| SEV3 | erro pontual com workaround | tratar em fila operacional |
| SEV4 | dúvida, ajuste menor ou melhoria | backlog |

---

## 11. Próximos passos

1. Definir ferramenta oficial de uptime.
2. Definir ferramenta oficial de erro frontend.
3. Mapear logs disponíveis no Supabase e Vercel.
4. Criar primeiro runbook de incidente.
5. Criar dashboard mínimo de saúde operacional.
6. Mapear custo mensal por serviço.
7. Definir SLA comercial somente após medir operação real.
