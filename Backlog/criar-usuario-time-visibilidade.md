# Backlog — Criar Usuário, Time e Visibilidade de Listas

Data: 2026-05-14
Projeto: FECH.AI
Módulo: Administração de usuários / Visibilidade de listas

## Contexto

Foi validado que a regra de visibilidade de listas por time está funcionando. O problema encontrado foi operacional: um corretor recém-criado pode ficar vinculado ao time incorreto caso a interface não deixe a seleção suficientemente clara.

## Diagnóstico validado

- Admin local funcionando.
- Criação de usuário funcionando.
- Visibilidade de listas por time funcionando.
- Ponto de melhoria: clareza da interface na seleção de time durante a criação e manutenção de usuários.

## Itens de backlog

### 1. Exibir claramente o time selecionado antes de criar usuário

Mostrar um resumo antes da criação:

- Nome do usuário
- Perfil
- Empresa
- Time selecionado

Critério de aceite: o administrador deve identificar claramente o time antes de confirmar a criação.

### 2. Botão dinâmico com nome do time

Alterar o texto do botão conforme o contexto:

- Criar corretor no Time selecionado
- Criar gestor
- Criar admin local

Critério de aceite: o botão deve refletir o destino real do usuário.

### 3. Mensagem pós-criação com confirmação do time

Exibir confirmação após criação contendo:

- Nome do usuário criado
- Perfil
- Time vinculado, quando aplicável

Critério de aceite: a mensagem de sucesso deve confirmar onde o usuário foi criado.

### 4. Tela de edição rápida para trocar usuário de time

Criar ação administrativa para:

- localizar usuário
- visualizar empresa atual
- visualizar time atual
- selecionar novo time
- salvar alteração

Critério de aceite: admin local deve mover corretores apenas entre times da própria empresa.

### 5. Auditoria de criação e troca de time

Registrar eventos administrativos:

- quem criou o usuário
- usuário criado
- empresa
- perfil
- time inicial
- data e hora
- quem alterou o time
- time anterior
- novo time

Critério de aceite: criação e alteração de time devem gerar registro de auditoria consultável.

## Prioridade sugerida

Alta: itens 1, 2, 3 e 5.
Média: item 4.

## Observação técnica

Não há necessidade de alterar a regra de visibilidade de listas neste momento. A prioridade é melhorar a experiência administrativa para evitar erro operacional na escolha do time.
