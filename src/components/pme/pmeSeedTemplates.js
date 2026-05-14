export const PME_LEAD_TYPES = [
  {
    key: 'lead_quente',
    name: 'Lead quente',
    hint: 'Meta, Google, landing page, formulário ou WhatsApp recente.',
  },
  {
    key: 'lista_fria',
    name: 'Lista fria',
    hint: 'Base importada, comprada, antiga ou sem intenção recente.',
  },
  {
    key: 'lista_quente',
    name: 'Lista quente',
    hint: 'Base própria, interação anterior ou lead reativado.',
  },
  {
    key: 'visitou_plantao',
    name: 'Visitou plantão',
    hint: 'Pessoa que já esteve no stand ou recebeu atendimento presencial.',
  },
]

export const PME_TEMPLATE_PHASES = [
  {
    key: 'primeira_mensagem',
    name: 'Primeira mensagem',
    goal: 'Abrir conversa com contexto e CTA leve.',
  },
  {
    key: 'segunda_mensagem',
    name: 'Segunda mensagem',
    goal: 'Retomar sem parecer cobrança.',
  },
  {
    key: 'terceira_mensagem',
    name: 'Terceira mensagem',
    goal: 'Trocar argumento e tentar avanço.',
  },
  {
    key: 'mensagem_final',
    name: 'Mensagem final',
    goal: 'Encerrar com elegância e deixar porta aberta.',
  },
]

export const PME_TEMPLATE_TONES = [
  'consultivo',
  'direto',
  'executivo',
  'leve',
  'reativacao',
  'urgencia_elegante',
]

export const PME_INITIAL_WHATSAPP_SEEDS = [
  {
    id: 'wpp-lq-f1-001',
    channel: 'whatsapp',
    leadType: 'lead_quente',
    phase: 'primeira_mensagem',
    tone: 'consultivo',
    title: 'Lead quente — abertura consultiva',
    body: 'Olá, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}, da {{empresa}}. Vi seu interesse no {{empreendimento}} e queria entender melhor o que você está buscando para te passar as opções mais adequadas.',
  },
  {
    id: 'wpp-lq-f1-002',
    channel: 'whatsapp',
    leadType: 'lead_quente',
    phase: 'primeira_mensagem',
    tone: 'direto',
    title: 'Lead quente — resposta rápida',
    body: 'Oi, {{nome_lead}}, tudo bem? Recebi sua solicitação sobre o {{empreendimento}}. Você procura para morar ou investir? Assim já te mando as informações certas.',
  },
  {
    id: 'wpp-lq-f2-001',
    channel: 'whatsapp',
    leadType: 'lead_quente',
    phase: 'segunda_mensagem',
    tone: 'leve',
    title: 'Lead quente — retomada leve',
    body: 'Oi, {{nome_lead}}. Passando só para saber se você conseguiu ver minha mensagem sobre o {{empreendimento}}. Posso te ajudar com valores, plantas ou disponibilidade?',
  },
  {
    id: 'wpp-lq-f3-001',
    channel: 'whatsapp',
    leadType: 'lead_quente',
    phase: 'terceira_mensagem',
    tone: 'urgencia_elegante',
    title: 'Lead quente — oportunidade elegante',
    body: '{{nome_lead}}, estou fazendo um último retorno porque algumas unidades do {{empreendimento}} podem fazer sentido para o seu perfil. Quer que eu te envie uma opção objetiva para avaliar?',
  },
  {
    id: 'wpp-lq-f4-001',
    channel: 'whatsapp',
    leadType: 'lead_quente',
    phase: 'mensagem_final',
    tone: 'consultivo',
    title: 'Lead quente — encerramento gentil',
    body: '{{nome_lead}}, não quero ser insistente. Vou pausar meu contato por aqui. Se ainda fizer sentido falar sobre o {{empreendimento}}, fico à disposição para te ajudar com calma.',
  },
  {
    id: 'wpp-lf-f1-001',
    channel: 'whatsapp',
    leadType: 'lista_fria',
    phase: 'primeira_mensagem',
    tone: 'leve',
    title: 'Lista fria — permissão inicial',
    body: 'Olá, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}, da {{empresa}}. Estou falando com algumas pessoas que avaliam imóveis na região e queria saber se faz sentido te enviar algumas opções.',
  },
  {
    id: 'wpp-lf-f1-002',
    channel: 'whatsapp',
    leadType: 'lista_fria',
    phase: 'primeira_mensagem',
    tone: 'consultivo',
    title: 'Lista fria — validação de interesse',
    body: 'Oi, {{nome_lead}}, tudo bem? Trabalho com imóveis da {{empresa}} e queria entender se você ainda está avaliando compra de imóvel ou se já resolveu essa parte.',
  },
  {
    id: 'wpp-lf-f2-001',
    channel: 'whatsapp',
    leadType: 'lista_fria',
    phase: 'segunda_mensagem',
    tone: 'leve',
    title: 'Lista fria — segunda tentativa educada',
    body: '{{nome_lead}}, só retomando minha mensagem anterior. Se imóvel não for um assunto para agora, sem problema. Caso faça sentido, posso te mandar algo bem objetivo.',
  },
  {
    id: 'wpp-lf-f3-001',
    channel: 'whatsapp',
    leadType: 'lista_fria',
    phase: 'terceira_mensagem',
    tone: 'direto',
    title: 'Lista fria — tentativa objetiva',
    body: '{{nome_lead}}, para eu não te incomodar sem necessidade: você ainda tem interesse em receber opções de imóveis ou prefere que eu encerre o contato por aqui?',
  },
  {
    id: 'wpp-lf-f4-001',
    channel: 'whatsapp',
    leadType: 'lista_fria',
    phase: 'mensagem_final',
    tone: 'leve',
    title: 'Lista fria — encerramento respeitoso',
    body: '{{nome_lead}}, como não consegui retorno, vou encerrar meu contato por aqui. Se em outro momento fizer sentido avaliar imóvel, fico à disposição.',
  },
  {
    id: 'wpp-lqt-f1-001',
    channel: 'whatsapp',
    leadType: 'lista_quente',
    phase: 'primeira_mensagem',
    tone: 'reativacao',
    title: 'Lista quente — retomada de contexto',
    body: 'Olá, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}, da {{empresa}}. Estou retomando nosso contato para saber se ainda faz sentido avaliar opções no {{empreendimento}} ou na região.',
  },
  {
    id: 'wpp-lqt-f2-001',
    channel: 'whatsapp',
    leadType: 'lista_quente',
    phase: 'segunda_mensagem',
    tone: 'consultivo',
    title: 'Lista quente — reforço consultivo',
    body: '{{nome_lead}}, pensei em te chamar porque algumas opções podem ter mudado desde nosso último contato. Quer que eu veja algo atualizado dentro do seu perfil?',
  },
  {
    id: 'wpp-lqt-f3-001',
    channel: 'whatsapp',
    leadType: 'lista_quente',
    phase: 'terceira_mensagem',
    tone: 'urgencia_elegante',
    title: 'Lista quente — oportunidade atualizada',
    body: '{{nome_lead}}, estou acompanhando a disponibilidade e pode existir uma janela interessante para avaliar agora. Quer que eu te envie uma simulação ou opção objetiva?',
  },
  {
    id: 'wpp-lqt-f4-001',
    channel: 'whatsapp',
    leadType: 'lista_quente',
    phase: 'mensagem_final',
    tone: 'consultivo',
    title: 'Lista quente — pausa elegante',
    body: '{{nome_lead}}, vou pausar meus retornos para não ficar insistente. Se voltar a fazer sentido conversar sobre imóvel, me chama por aqui que eu te ajudo.',
  },
  {
    id: 'wpp-vp-f1-001',
    channel: 'whatsapp',
    leadType: 'visitou_plantao',
    phase: 'primeira_mensagem',
    tone: 'consultivo',
    title: 'Visitou plantão — pós-visita consultivo',
    body: 'Olá, {{nome_lead}}, tudo bem? Aqui é {{nome_corretor}}, da {{empresa}}. Queria saber como ficou sua percepção depois da visita ao plantão e se ficou alguma dúvida sobre valores, plantas ou disponibilidade.',
  },
  {
    id: 'wpp-vp-f2-001',
    channel: 'whatsapp',
    leadType: 'visitou_plantao',
    phase: 'segunda_mensagem',
    tone: 'direto',
    title: 'Visitou plantão — retomada de decisão',
    body: '{{nome_lead}}, depois da sua visita, queria entender se alguma unidade fez mais sentido para você ou se prefere que eu monte uma simulação mais ajustada.',
  },
  {
    id: 'wpp-vp-f3-001',
    channel: 'whatsapp',
    leadType: 'visitou_plantao',
    phase: 'terceira_mensagem',
    tone: 'urgencia_elegante',
    title: 'Visitou plantão — disponibilidade',
    body: '{{nome_lead}}, estou acompanhando as unidades disponíveis depois da sua visita. Se ainda houver interesse, vale olharmos com calma antes que as melhores opções mudem.',
  },
  {
    id: 'wpp-vp-f4-001',
    channel: 'whatsapp',
    leadType: 'visitou_plantao',
    phase: 'mensagem_final',
    tone: 'consultivo',
    title: 'Visitou plantão — encerramento pós-visita',
    body: '{{nome_lead}}, como não consegui falar com você depois da visita, vou deixar o contato em aberto por aqui. Se quiser retomar valores, fluxo ou disponibilidade, fico à disposição.',
  },
]

export function countSeedsByLeadTypeAndPhase(leadType, phase) {
  return PME_INITIAL_WHATSAPP_SEEDS.filter(
    (item) => item.leadType === leadType && item.phase === phase,
  ).length
}

export function getSeedCompletionStats(targetPerCombination = 10) {
  const totalCombinations = PME_LEAD_TYPES.length * PME_TEMPLATE_PHASES.length
  const targetTotal = totalCombinations * targetPerCombination
  const currentTotal = PME_INITIAL_WHATSAPP_SEEDS.length

  return {
    totalCombinations,
    targetPerCombination,
    targetTotal,
    currentTotal,
    remainingTotal: Math.max(targetTotal - currentTotal, 0),
    completionPercent: targetTotal ? Math.round((currentTotal / targetTotal) * 100) : 0,
  }
}
