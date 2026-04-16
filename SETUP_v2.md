# Discador v2 — Guia de Setup

**Tempo estimado**: 30 minutos

---

## Arquivos (nesta ordem de execução)

| Arquivo | O que faz |
|---------|-----------|
| `setup_supabase.sql` | Cria o banco de dados completo |
| `patch_v2.sql` | Adiciona produção, carteira, avaliação de lista, relatório |
| `discador_app_v2.jsx` | App completo com todas as funcionalidades |

---

## Passo 1: Criar o banco (SQL Editor do Supabase)

1. Cole `setup_supabase.sql` → Run
2. Cole `patch_v2.sql` → Run
3. Ambos devem retornar "Success"

## Passo 2: Criar usuários (Authentication → Users)

Crie 4 usuários com email/senha. Depois vincule no SQL Editor:

```sql
insert into corretores (user_id, nome, email, is_gestor) values
('UUID-WAGNER', 'Wagner', 'email@', true),
('UUID-SABRINA', 'Sabrina', 'email@', true),
('UUID-LAURA', 'Laura', 'email@', false),
('UUID-HELENA', 'Helena', 'email@', false);
```

## Passo 3: Configurar o app

Abra o app → informe URL + Anon Key (Settings → API no Supabase)

---

## O que cada pessoa faz

### Gestora (Sabrina)
1. **Upload**: recebe lista → abre app → aba Upload → seleciona arquivo → informa fornecedor → Importar
2. **Distribuir**: aba Distribuir → toca "Distribuir agora"
3. **Dashboard**: vê KPIs, performance por corretor, qualidade por fornecedor
4. **Listas**: gerencia listas, pausa/encerra lista ruim, vê relatório do fornecedor

### Corretor (Laura, Helena, Wagner)
1. **Discador**: vê lead → Ligar ou WhatsApp → dá feedback → próximo lead
2. **Produção**: vê resultado do dia, gráfico semanal, leads com observação
3. **Carteira**: leads que agendaram visita, enviaram info ou pediram retorno ficam aqui

---

## Funcionalidades v2

### WhatsApp inteligente
Ao tocar "WhatsApp", o app abre com mensagem pronta:
- Saudação automática (bom dia/tarde/noite baseado no horário)
- Primeiro nome do lead
- Mensagem padrão de abordagem

### Produção do corretor
- KPIs do dia (total, visitas, errados)
- Totais gerais (recebidos, com feedback, em carteira)
- Gráfico de barras dos últimos 7 dias
- Lista de leads com observação

### Carteira de leads
- Leads com feedback positivo (agendou visita, enviou info, retornar depois) entram automaticamente na carteira
- Corretor pode ligar ou enviar WhatsApp direto da carteira
- Observações ficam visíveis para follow-up

### Avaliação de lista (corretores)
- Quando o lote fecha (25/25), o corretor pode dar nota de 1 a 5 estrelas
- A nota média aparece no dashboard da gestora
- Ajuda a identificar fornecedores bons e ruins

### Gestão de listas (gestora)
- Ver todas as listas com status, nota média, taxa de erro
- **Pausar**: congela a lista (leads disponíveis ficam bloqueados)
- **Reativar**: volta a distribuir leads dessa lista
- **Encerrar**: encerra definitivamente (leads disponíveis invalidados)
- **Relatório**: mostra estatísticas completas para enviar ao fornecedor

---

## Onde ficam os dados

Tudo no PostgreSQL do Supabase (nuvem):

| Tabela | Conteúdo |
|--------|----------|
| `leads` | Todos os leads de todas as listas, com feedback e observações |
| `listas` | Cada arquivo importado, com fornecedor, status e nota média |
| `lotes` | Cada pacote de 25 leads distribuído a um corretor |
| `corretores` | Equipe com status e permissões |
| `lista_avaliacoes` | Notas que os corretores deram para cada lista |
| `logs` | Auditoria de todas as ações do sistema |

Os dados NÃO ficam no celular. Qualquer dispositivo com login acessa tudo.

---

## Regras de negócio

- 1 lote = 25 leads, ordenados por score (melhores primeiro)
- 1 corretor = 1 lote aberto por vez
- Lote só fecha com 25 feedbacks válidos
- Leads com "agendou visita", "enviou info" ou "retornar depois" vão para carteira automaticamente
- Telefone normalizado com DDD 11 quando falta
- Deduplicação por nome + email + telefone
- Transação real no PostgreSQL (sem risco de duplicar lote)
- RLS ativo (corretor só vê seus leads)
- Limite de 5.000 leads por upload (proteção contra travamento)

---

## Fluxo de qualidade de lista

```
Gestora compra lista → Upload → Distribui → Corretores trabalham
    ↓                                              ↓
Dashboard mostra taxa de erro          Corretor avalia lista (★)
    ↓                                              ↓
Se taxa de erro alta ou nota baixa → Gestora pausa/encerra lista
    ↓
Gestora gera relatório → Envia ao fornecedor
```
