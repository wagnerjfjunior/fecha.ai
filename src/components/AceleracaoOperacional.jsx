import { useMemo, useState } from 'react'

const CHANNELS = [
  { id: 'whatsapp', label: 'WhatsApp', icon: '💬', helper: 'Mensagem pronta em 1 clique' },
  { id: 'call', label: 'Ligação', icon: '📞', helper: 'Feedback após a chamada' },
  { id: 'email', label: 'E-mail', icon: '📧', helper: 'Reforço ou curiosidade' },
]

const CONTEXTS = [
  { id: 'primeira_abordagem', label: 'Primeira abordagem', description: 'Ainda não falei com o cliente.' },
  { id: 'reforco', label: 'Já falei com cliente', description: 'Usar tom de reforço e continuidade.' },
]

const QUICK_FEEDBACKS = [
  { id: 'agendado_visita', label: 'Agendou visita', icon: '🏠', tone: 'success' },
  { id: 'enviado_informacoes', label: 'Enviar informações', icon: '📨', tone: 'info' },
  { id: 'em_conversa', label: 'Em conversa', icon: '💬', tone: 'info' },
  { id: 'retornar_depois', label: 'Retornar depois', icon: '⏰', tone: 'warning' },
  { id: 'nao_responde', label: 'Não respondeu', icon: '📵', tone: 'danger' },
  { id: 'sem_interesse', label: 'Sem interesse', icon: '❌', tone: 'muted' },
]

const DEFAULT_STATS = {
  metaVisitas: 10,
  visitasAgendadas: 0,
  leadsPorAgendamento: 18,
  ligacoes: 0,
  whatsapps: 0,
  emails: 0,
}

function StatCard({ label, value, hint, tone = 'default' }) {
  const toneMap = {
    default: 'bg-white border-gray-100 text-gray-900',
    success: 'bg-emerald-50 border-emerald-100 text-emerald-900',
    warning: 'bg-amber-50 border-amber-100 text-amber-900',
    danger: 'bg-red-50 border-red-100 text-red-900',
  }

  return (
    <div className={`rounded-2xl border p-4 shadow-sm ${toneMap[tone] || toneMap.default}`}>
      <p className="text-xs font-semibold uppercase tracking-wide opacity-70">{label}</p>
      <p className="mt-1 text-2xl font-black">{value}</p>
      {hint && <p className="mt-1 text-xs opacity-70">{hint}</p>}
    </div>
  )
}

function ChannelButton({ channel, selected, index, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-2xl border p-4 text-left transition-all active:scale-95 ${
        selected
          ? 'border-blue-500 bg-blue-50 shadow-sm shadow-blue-100'
          : 'border-gray-200 bg-white hover:border-blue-200'
      }`}
    >
      <div className="flex items-center gap-3">
        <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-gray-100 text-xl">{channel.icon}</span>
        <div>
          <p className="font-bold text-gray-900">{index + 1}. {channel.label}</p>
          <p className="text-xs text-gray-500">{channel.helper}</p>
        </div>
      </div>
    </button>
  )
}

function ContextButton({ context, selected, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-2xl border p-4 text-left transition-all active:scale-95 ${
        selected
          ? 'border-emerald-500 bg-emerald-50 shadow-sm shadow-emerald-100'
          : 'border-gray-200 bg-white hover:border-emerald-200'
      }`}
    >
      <p className="font-bold text-gray-900">{context.label}</p>
      <p className="mt-1 text-sm text-gray-500">{context.description}</p>
    </button>
  )
}

function buildOperationalHint(channelId, contextId) {
  if (channelId === 'call') return 'Faça a ligação. O feedback depois da chamada define o próximo passo.'
  if (channelId === 'whatsapp' && contextId === 'reforco') return 'Usar mensagem de reforço: continuidade, nome do corretor e orientação de stand.'
  if (channelId === 'whatsapp') return 'Usar mensagem de primeira abordagem com tom leve e direto.'
  if (channelId === 'email' && contextId === 'reforco') return 'Usar e-mail de consolidação: “conforme conversamos” e próximos passos.'
  if (channelId === 'email') return 'Usar e-mail de curiosidade para tentar chamar atenção por outro canal.'
  return 'Selecione o canal e execute a próxima ação.'
}

export default function AceleracaoOperacional({
  nome,
  lead,
  stats = DEFAULT_STATS,
  onVoltar,
  onProximoLead,
  onRegistrarFeedback,
}) {
  const [flow, setFlow] = useState(['whatsapp', 'call', 'email'])
  const [context, setContext] = useState('primeira_abordagem')
  const [currentStep, setCurrentStep] = useState(0)
  const [localStats, setLocalStats] = useState(stats)

  const activeChannel = CHANNELS.find(c => c.id === flow[currentStep]) || CHANNELS[0]
  const faltaVisitas = Math.max((localStats.metaVisitas || 0) - (localStats.visitasAgendadas || 0), 0)
  const leadsNecessarios = faltaVisitas * (localStats.leadsPorAgendamento || 18)
  const riskTone = faltaVisitas >= 7 ? 'danger' : faltaVisitas >= 3 ? 'warning' : 'success'

  const orderedChannels = useMemo(() => {
    return flow.map(id => CHANNELS.find(c => c.id === id)).filter(Boolean)
  }, [flow])

  function moveChannel(channelId) {
    setFlow(prev => {
      const without = prev.filter(id => id !== channelId)
      return [channelId, ...without]
    })
    setCurrentStep(0)
  }

  function registerAction(channelId) {
    setLocalStats(prev => ({
      ...prev,
      whatsapps: channelId === 'whatsapp' ? (prev.whatsapps || 0) + 1 : prev.whatsapps,
      ligacoes: channelId === 'call' ? (prev.ligacoes || 0) + 1 : prev.ligacoes,
      emails: channelId === 'email' ? (prev.emails || 0) + 1 : prev.emails,
    }))
    setCurrentStep(prev => Math.min(prev + 1, flow.length - 1))
  }

  function handleFeedback(feedbackId) {
    if (feedbackId === 'agendado_visita') {
      setLocalStats(prev => ({ ...prev, visitasAgendadas: (prev.visitasAgendadas || 0) + 1 }))
    }
    onRegistrarFeedback?.(feedbackId)
  }

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900">
      <div className="sticky top-0 z-10 border-b border-gray-100 bg-white px-4 py-3">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-blue-600">FECH.AI</p>
            <h1 className="text-xl font-black">Aceleração Operacional</h1>
            <p className="text-sm text-gray-500">{nome ? `${nome}, foco em visita no final de semana.` : 'Foco em visita no final de semana.'}</p>
          </div>
          <button
            type="button"
            onClick={onVoltar}
            className="rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700 active:scale-95"
          >
            Voltar
          </button>
        </div>
      </div>

      <main className="mx-auto max-w-5xl space-y-5 p-4 pb-10">
        <section className="grid gap-3 md:grid-cols-4">
          <StatCard label="Meta fim de semana" value={localStats.metaVisitas || 0} hint="Visitas desejadas" />
          <StatCard label="Agendadas" value={localStats.visitasAgendadas || 0} hint="Visitas já marcadas" tone="success" />
          <StatCard label="Faltam" value={faltaVisitas} hint="Pressão operacional" tone={riskTone} />
          <StatCard label="Leads necessários" value={leadsNecessarios} hint={`Média: 1 visita/${localStats.leadsPorAgendamento || 18} leads`} tone={riskTone} />
        </section>

        <section className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
          <div className="mb-4 flex items-center justify-between gap-3">
            <div>
              <h2 className="text-lg font-black">Como você quer abordar?</h2>
              <p className="text-sm text-gray-500">Toque no canal para colocá-lo em primeiro na esteira.</p>
            </div>
            <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-bold text-blue-700">MVP assistido</span>
          </div>
          <div className="grid gap-3 md:grid-cols-3">
            {CHANNELS.map(channel => (
              <ChannelButton
                key={channel.id}
                channel={channel}
                selected={flow[0] === channel.id}
                index={orderedChannels.findIndex(c => c.id === channel.id)}
                onClick={() => moveChannel(channel.id)}
              />
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
          <h2 className="text-lg font-black">Qual é o tom da conversa?</h2>
          <p className="mb-4 text-sm text-gray-500">Essa escolha muda o pool de templates: abordagem fria ou reforço profissional.</p>
          <div className="grid gap-3 md:grid-cols-2">
            {CONTEXTS.map(item => (
              <ContextButton
                key={item.id}
                context={item}
                selected={context === item.id}
                onClick={() => setContext(item.id)}
              />
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-blue-100 bg-blue-50 p-4 shadow-sm">
          <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
            <div>
              <p className="text-xs font-bold uppercase tracking-wide text-blue-700">Próxima ação</p>
              <h2 className="mt-1 text-2xl font-black text-blue-950">{activeChannel.icon} {activeChannel.label}</h2>
              <p className="mt-1 text-sm text-blue-800">{buildOperationalHint(activeChannel.id, context)}</p>
            </div>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => registerAction(activeChannel.id)}
                className="rounded-2xl bg-blue-600 px-5 py-3 font-bold text-white shadow-md shadow-blue-200 active:scale-95"
              >
                Ação enviada
              </button>
              <button
                type="button"
                onClick={() => setCurrentStep(prev => Math.min(prev + 1, flow.length - 1))}
                className="rounded-2xl border border-blue-200 bg-white px-5 py-3 font-bold text-blue-700 active:scale-95"
              >
                Pular
              </button>
            </div>
          </div>
        </section>

        <section className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h2 className="text-lg font-black">Lead em trabalho</h2>
              <p className="text-sm text-gray-500">Nesta primeira versão, o card já está preparado para receber o retorno de proximo_lead().</p>
            </div>
            <button
              type="button"
              onClick={onProximoLead}
              className="rounded-2xl bg-gray-900 px-4 py-2 text-sm font-bold text-white active:scale-95"
            >
              Próximo lead
            </button>
          </div>

          {lead ? (
            <div className="rounded-2xl border border-gray-100 bg-gray-50 p-4">
              <p className="text-xl font-black">{lead.nome || 'Lead sem nome'}</p>
              <p className="text-sm text-gray-500">{lead.telefone_escolhido || lead.telefone_e164 || 'Telefone não informado'}</p>
              <p className="text-sm text-gray-500">{lead.email || 'E-mail não informado'}</p>
            </div>
          ) : (
            <div className="rounded-2xl border border-dashed border-gray-200 bg-gray-50 p-6 text-center">
              <p className="font-bold text-gray-700">Nenhum lead carregado nesta prévia.</p>
              <p className="mt-1 text-sm text-gray-500">A integração com proximo_lead() entra no próximo commit.</p>
            </div>
          )}
        </section>

        <section className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
          <h2 className="text-lg font-black">Feedback rápido</h2>
          <p className="mb-4 text-sm text-gray-500">O feedback alimenta o funil atual. Não criaremos funil paralelo.</p>
          <div className="grid gap-3 md:grid-cols-3">
            {QUICK_FEEDBACKS.map(item => (
              <button
                key={item.id}
                type="button"
                onClick={() => handleFeedback(item.id)}
                className="rounded-2xl border border-gray-200 bg-white p-4 text-left font-bold active:scale-95 hover:border-blue-200"
              >
                <span className="mr-2">{item.icon}</span>{item.label}
              </button>
            ))}
          </div>
        </section>

        <section className="grid gap-3 md:grid-cols-3">
          <StatCard label="Ligações" value={localStats.ligacoes || 0} hint="Executadas na sessão" />
          <StatCard label="WhatsApps" value={localStats.whatsapps || 0} hint="Marcados como enviados" />
          <StatCard label="E-mails" value={localStats.emails || 0} hint="Marcados como enviados" />
        </section>
      </main>
    </div>
  )
}
