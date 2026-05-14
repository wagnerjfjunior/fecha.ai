export const PME_CALL_SCRIPT_SEEDS = [
  {
    id: 'call-lista-fria-base-001',
    leadType: 'lista_fria',
    title: 'Lista fria — abertura com permissão',
    objective: 'Validar interesse sem parecer ligação invasiva.',
    opening: 'Oi, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}, da {{empresa}}. Prometo ser breve.',
    context: 'Estou falando com algumas pessoas que avaliam imóveis em São Paulo e queria entender se esse assunto ainda faz sentido para você neste momento.',
    firstQuestion: 'Você está procurando imóvel hoje, apenas acompanhando oportunidades ou prefere que eu não siga com esse contato?',
    qualification: [
      'Você procura para morar ou investir?',
      'Tem alguma região específica que faz sentido?',
      'Existe uma faixa de valor ou metragem que você considera?',
      'É algo para agora ou para mais para frente?',
    ],
    commercialHook: 'Se fizer sentido, eu te mando apenas uma seleção objetiva pelo WhatsApp, sem ficar te enchendo de informação aleatória.',
    objections: [
      {
        objection: 'Não estou procurando agora.',
        response: 'Perfeito, sem problema. Prefere que eu pause seu contato ou posso te chamar futuramente se aparecer algo realmente interessante?',
      },
      {
        objection: 'Como você conseguiu meu contato?',
        response: 'Estou trabalhando uma base comercial de pessoas com possível interesse imobiliário. Mas se você preferir, eu encerro o contato por aqui sem problema.',
      },
      {
        objection: 'Pode mandar depois.',
        response: 'Claro. Para eu mandar algo útil, você prefere apartamento para morar, investir ou só acompanhar oportunidades?',
      },
    ],
    closing: 'Combinado. Vou te mandar uma mensagem objetiva no WhatsApp e você olha no seu tempo. Se não fizer sentido, me avisa que eu pauso por aqui.',
    feedbackOptions: [
      'interessado',
      'enviar_informacoes',
      'retornar_depois',
      'sem_interesse',
      'nao_quer_contato',
      'numero_errado',
      'nao_atendeu',
    ],
  },
  {
    id: 'call-lista-fria-direta-002',
    leadType: 'lista_fria',
    title: 'Lista fria — triagem objetiva',
    objective: 'Separar rápido quem tem potencial de quem deve sair da cadência.',
    opening: 'Olá, {{nome_lead}}, tudo bem? Sou {{nome_corretor}}, da {{empresa}}.',
    context: 'Estou atualizando alguns contatos para entender quem ainda avalia compra de imóvel e quem prefere não receber esse tipo de abordagem.',
    firstQuestion: 'Posso te fazer uma pergunta rápida: imóvel é um assunto aberto para você hoje?',
    qualification: [
      'Se sim, seria para morar ou investir?',
      'Você já tem região definida?',
      'Está olhando lançamento, pronto ou ainda não decidiu?',
      'Tem previsão de compra ou está só pesquisando?',
    ],
    commercialHook: 'A ideia é te mandar algo que realmente tenha aderência, não um monte de anúncio sem sentido.',
    objections: [
      {
        objection: 'Estou sem tempo.',
        response: 'Sem problema. Posso te mandar uma mensagem curta no WhatsApp e você me responde quando puder?',
      },
      {
        objection: 'Não tenho interesse.',
        response: 'Tranquilo. Vou registrar aqui para não seguir te incomodando.',
      },
      {
        objection: 'Depende do valor.',
        response: 'Perfeito. Você tem uma faixa aproximada para eu não te mandar algo fora da realidade?',
      },
    ],
    closing: 'Obrigado pela clareza. Vou seguir conforme você preferir: envio uma opção objetiva, marco retorno ou pauso o contato.',
    feedbackOptions: [
      'interessado',
      'enviar_informacoes',
      'retornar_depois',
      'sem_interesse',
      'nao_quer_contato',
      'numero_errado',
      'nao_atendeu',
    ],
  },
  {
    id: 'call-visitou-plantao-base-001',
    leadType: 'visitou_plantao',
    title: 'Visitou plantão — retomada consultiva',
    objective: 'Dar continuidade à visita e descobrir objeção principal.',
    opening: 'Oi, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}, da {{empresa}}.',
    context: 'Estou te ligando para dar continuidade ao atendimento depois da sua visita ao plantão do {{empreendimento}}.',
    firstQuestion: 'Você conseguiu avaliar com calma o que achou do projeto?',
    qualification: [
      'O que mais chamou sua atenção na visita?',
      'Ficou alguma dúvida sobre planta, valor, fluxo de pagamento ou disponibilidade?',
      'Você está comparando com outro empreendimento?',
      'Existe alguém que decide junto com você?',
      'Faria sentido montar uma simulação mais ajustada?',
    ],
    commercialHook: 'Como você já conhece o plantão, agora o mais importante é olhar disponibilidade e fluxo dentro do que realmente combina com seu perfil.',
    objections: [
      {
        objection: 'Achei caro.',
        response: 'Entendo. Vamos olhar o fluxo completo, porque às vezes a percepção muda bastante quando ajustamos unidade, entrada e parcelas.',
      },
      {
        objection: 'Estou pensando ainda.',
        response: 'Perfeito. O que está pesando mais na sua decisão hoje: valor, planta, localização ou comparação com outro projeto?',
      },
      {
        objection: 'Preciso falar com minha família.',
        response: 'Claro. Posso te mandar um resumo objetivo para ajudar nessa conversa e depois marcamos um retorno?',
      },
    ],
    closing: 'Vou te enviar pelo WhatsApp um resumo com os próximos passos e, se fizer sentido, já vejo uma simulação ou nova visita mais focada.',
    feedbackOptions: [
      'quer_simulacao',
      'agendou_visita',
      'retornar_depois',
      'em_comparacao',
      'sem_interesse',
      'nao_atendeu',
    ],
  },
  {
    id: 'call-visitou-plantao-decisao-002',
    leadType: 'visitou_plantao',
    title: 'Visitou plantão — foco em decisão',
    objective: 'Levar o lead pós-visita para simulação, retorno ou encerramento claro.',
    opening: 'Olá, {{nome_lead}}. Aqui é {{nome_corretor}}, da {{empresa}}. Tudo bem?',
    context: 'Estou retomando seu atendimento porque você já visitou o plantão do {{empreendimento}} e queria entender se ainda faz sentido avançarmos.',
    firstQuestion: 'Hoje você sente que o projeto ainda está no seu radar ou acabou perdendo prioridade?',
    qualification: [
      'Se ainda está no radar, qual ponto precisamos resolver para avançar?',
      'Você quer rever valores ou disponibilidade?',
      'Seria útil comparar duas opções de unidade?',
      'Você prefere retorno por WhatsApp ou nova visita?',
    ],
    commercialHook: 'Como você já passou da etapa de conhecer o produto, agora podemos trabalhar com mais precisão: unidade, fluxo, simulação e condição realista.',
    objections: [
      {
        objection: 'Estou vendo outros imóveis.',
        response: 'Faz sentido. Posso te ajudar a comparar de forma objetiva para você não decidir só por impressão ou preço isolado.',
      },
      {
        objection: 'Não sei se é o momento.',
        response: 'Sem problema. Quer que eu deixe um retorno agendado ou prefere que eu pause por enquanto?',
      },
      {
        objection: 'Gostei, mas preciso melhorar condição.',
        response: 'Entendi. Para avaliar margem real de composição, primeiro preciso entender entrada, prazo e forma de pagamento que fazem sentido para você.',
      },
    ],
    closing: 'Perfeito. Vou registrar aqui e seguir com o próximo passo combinado, sem te mandar mensagens fora do que fizer sentido.',
    feedbackOptions: [
      'quer_simulacao',
      'agendou_visita',
      'retornar_depois',
      'em_comparacao',
      'negociacao',
      'sem_interesse',
      'nao_atendeu',
    ],
  },
]

export function getCallScriptsByLeadType(leadType) {
  return PME_CALL_SCRIPT_SEEDS.filter((script) => script.leadType === leadType)
}

export function getCurrentOperationCallScripts() {
  return PME_CALL_SCRIPT_SEEDS.filter((script) =>
    ['lista_fria', 'visitou_plantao'].includes(script.leadType),
  )
}
