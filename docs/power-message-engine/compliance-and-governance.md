# Power Message Engine — Compliance e Governança

## 1. Objetivo

Definir cuidados mínimos para evitar bloqueios, abuso operacional, exposição jurídica e degradação da reputação dos números e das empresas.

---

## 2. Princípios

1. Não transformar produtividade em spam.
2. Não usar automação para burlar regras de plataforma.
3. Registrar consentimento, origem e histórico sempre que possível.
4. Respeitar opt-out.
5. Preservar reputação do número, do corretor e da empresa.
6. Separar claramente lead quente de lista fria.

---

## 3. WhatsApp

### 3.1 Risco

WhatsApp é sensível a bloqueios quando há:

- volume alto;
- mensagens repetidas;
- denúncias;
- contatos frios sem contexto;
- automação agressiva;
- múltiplos envios iguais;
- comportamento parecido com disparador.

### 3.2 Medidas de proteção

- variação controlada de mensagens;
- limite por corretor/tenant;
- intervalo entre tentativas;
- registro de origem do lead;
- mensagens diferentes por fase;
- parar quando houver rejeição;
- nunca insistir após opt-out;
- evitar promessas comerciais não validadas.

### 3.3 Importante

Randomização não deve ser tratada como técnica para burlar bloqueio. Deve ser usada para humanizar a comunicação e evitar repetição artificial.

---

## 4. LGPD

O sistema deve respeitar:

- finalidade do tratamento;
- origem do dado;
- registro de interações;
- possibilidade de exclusão/bloqueio;
- acesso restrito por tenant;
- logs de auditoria.

Lista fria exige cuidado maior, pois o cliente pode não reconhecer a origem do contato.

---

## 5. Opt-out

O FECH.AI deve ter status de bloqueio/opt-out por lead.

Mensagens do tipo:

```txt
Se preferir, eu não sigo com o contato por aqui.
```

podem ser usadas especialmente em lista fria ou mensagem final.

Ao identificar opt-out:

- parar cadência;
- bloquear novas sugestões;
- registrar evento;
- impedir reativação automática.

---

## 6. Governança por tenant

Cada tenant deve poder configurar:

- canais permitidos;
- templates ativos;
- limites de contato;
- horários permitidos;
- regras de cadência;
- quem pode criar templates;
- quem pode aprovar templates;
- quais listas/campanhas usam piloto automático.

---

## 7. Governança de templates

Templates devem ter status:

- `draft`;
- `active`;
- `inactive`;
- `archived`.

Fluxo recomendado:

1. criação;
2. revisão;
3. ativação;
4. monitoramento;
5. ajuste ou arquivamento.

---

## 8. Métricas de risco

Acompanhar:

- taxa de resposta;
- taxa de bloqueio/reportado;
- taxa de número inválido;
- taxa de sem resposta;
- tentativas por lead;
- templates com baixa performance;
- corretores com uso excessivo;
- listas com alto problema cadastral.

---

## 9. Regra prática

Se a automação deixa o cliente com sensação de robô insistente, a automação está errada.

O objetivo é vender com método, não fazer barulho digital.
