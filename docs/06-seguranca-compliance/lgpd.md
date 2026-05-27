# FECH.AI — Guia Preliminar de LGPD e Privacidade

**Status:** rascunho / pendente de validação jurídica  
**Área:** segurança, privacidade e compliance  
**Finalidade:** orientar a preparação do FECH.AI para tratar dados pessoais de forma responsável em contexto SaaS B2B.  
**Escopo:** checklist interno. Não substitui assessoria jurídica.

---

## 1. Aviso importante

Este documento não é parecer jurídico.

Ele serve para organizar perguntas, responsabilidades e controles que devem ser validados com assessoria especializada antes de venda em escala, contrato enterprise ou entrada de sócio/investidor.

---

## 2. Por que LGPD importa no FECH.AI

O FECH.AI pode tratar dados relacionados a:

```text
usuários do sistema
corretores
gestores
leads
histórico de atendimento
interações comerciais
simulações e propostas
logs operacionais
```

Por isso, o produto precisa documentar finalidade, acesso, segurança, retenção e responsabilidades.

---

## 3. Papéis a definir em contrato

Validar para cada cliente:

| Papel | Pergunta |
|---|---|
| Controlador | quem decide a finalidade do uso dos dados? |
| Operador | quem processa dados em nome do cliente? |
| Suboperadores | quais provedores ajudam a processar dados? |
| Usuário autorizado | quem pode acessar a plataforma? |

---

## 4. Finalidades de tratamento

Mapear finalidades legítimas, como:

```text
gestão de leads
atendimento comercial
registro de feedback
acompanhamento de produtividade
suporte técnico
auditoria operacional
segurança da plataforma
melhoria do produto
```

---

## 5. Suboperadores de tecnologia

Documentar provedores utilizados ou planejados:

| Provedor | Função | Dados envolvidos | Status |
|---|---|---|---|
| Vercel | hospedagem frontend | dados técnicos de acesso | validar |
| Supabase | banco, auth e APIs | dados operacionais | validar |
| OpenAI/ChatGPT | IA assistiva | dados enviados sob controle | validar |
| Provedor de e-mail | comunicação | a definir | futuro |
| WhatsApp/WABA | comunicação | a definir | futuro |

---

## 6. Princípios operacionais

```text
coletar apenas o necessário
restringir acesso por perfil
proteger dados por tenant/empresa
registrar logs relevantes
mascarar dados quando possível
não enviar dados sensíveis para IA sem finalidade clara
não exportar base sem autorização
não manter dados além do necessário sem política definida
```

---

## 7. Direitos dos titulares

Preparar procedimento para solicitações como:

```text
acesso
correção
exclusão
portabilidade
revogação de consentimento quando aplicável
informação sobre uso dos dados
```

A operação exata deve ser definida juridicamente conforme o papel do FECH.AI em cada contrato.

---

## 8. Retenção e exclusão

Definir política para:

```text
leads inativos
usuários desligados
logs técnicos
histórico comercial
propostas e simulações
backups
exportações
```

Não apagar dado crítico sem avaliar obrigação comercial, legal, contratual ou de auditoria.

---

## 9. Segurança mínima esperada

```text
autenticação individual
perfis e permissões
RLS por tenant/empresa
controle de acesso a produção
gestão de segredos
logs de ações críticas
backup
monitoramento de incidentes
processo de resposta a incidente
```

---

## 10. Checklist antes de vender para empresas

```text
termos de uso
política de privacidade
contrato SaaS
cláusulas de proteção de dados
lista de suboperadores
procedimento de incidente
procedimento de exclusão/retensão
matriz de acesso
contato responsável por privacidade
```

---

## 11. Próximos passos

1. Mapear dados pessoais por tabela.
2. Mapear fluxos de dados por módulo.
3. Definir política de retenção.
4. Validar contrato SaaS com jurídico.
5. Criar política de privacidade.
6. Criar procedimento de incidente de segurança.
