import { useEffect, useMemo, useState } from 'react'
import { buscarProximoLeadOperacional, registrarFeedbackOperacional } from '../services/aceleracaoOperacionalService'

const CHANNELS = [
  { id: 'whatsapp', label: 'WhatsApp', icon: '💬' },
  { id: 'call', label: 'Ligação', icon: '📞' },
  { id: 'email', label: 'E-mail', icon: '📧' },
]

const CONTEXTS = [
  { id: 'primeira_abordagem', label: 'Primeira abordagem', hint: 'Ainda não falei com o cliente.' },
  { id: 'reforco', label: 'Já falei com cliente', hint: 'Usar tom de reforço e continuidade.' },
]

const FEEDBACKS = [
  { id: 'agendado_visita', label: 'Agendou visita', icon: '🏠' },
  { id: 'enviado_informacoes', label: 'Enviou informações', icon: '📨' },
  { id: 'em_conversa', label: 'Em conversa', icon: '💬' },
  { id: 'retornar_depois', label: 'Retornar depois', icon: '⏰' },
  { id: 'nao_responde', label: 'Não respondeu', icon: '📵' },
  { id: 'sem_interesse', label: 'Sem interesse', icon: '❌' },
]

function StatCard({ label, value, hint, tone = 'default' }) {
  const cls = {
    default: 'bg-white border-gray-100 text-gray-900',
    success: 'bg-emerald-50 border-emerald-100 text-emerald-900',
    warning: 'bg-amber-50 border-amber-100 text-amber-900',
    danger: 'bg-red-50 border-red-100 text-red-900',
  }[tone]

  return (
    <div className={`rounded-2xl border p-4 shadow-sm ${cls}`}>
      <div className="text-xs font-semibold uppercase tracking-wide opacity-70">{label}</div>
      <div className="mt-1 text-2xl font-black">{value}</div>
      {hint && <div className="mt-1 text-xs opacity-70">{hint}</div>}
    </div>
  )
}

function getLeadName(lead) {
  return lead?.nome || lead?.lead_nome || lead?.cliente || 'Lead sem nome'
}

function getLeadPhone(lead) {
  return lead?.telefone_escolhido || lead?.telefone_e164 || lead?.celular || lead?.telefone || 'Telefone não informado'
}

function getLeadEmail(lead) {
  return lead?.email || 'E-mail não informado'
}

function buildHint(channel, context) {
  if (channel === 'call') return 'Faça a ligação. O feedback da chamada define o próximo passo.'
  if (channel === 'whatsapp' && context === 'reforco') return 'WhatsApp de reforço: continuidade, nome do corretor e orientação de stand.'
  if (channel === 'whatsapp') return 'WhatsApp de primeira abordagem com tom leve e direto.'
  if (channel === 'email' && context === 'reforco') return 'E-mail de consolidação: conforme conversamos e próximos passos.'
  return 'E-mail de curiosidade para tentar contato por outro canal.'
}

export default function AceleracaoOperacional({ nome }) {
  const [flow, setFlow] = useState(['whatsapp', 'call', 'email'])
  const [context, setContext] = useState('primeira_abordagem')
  const [step, setStep] = useState(0)
  const [lead, setLead] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [stats, setStats] = useState({ meta: 10, visitas: 0, media: 18, ligacoes: 0, whatsapps: 0, emails: 0 })

  const active = flow[step] || flow[0]
  const activeChannel = CHANNELS.find(c => c.id === active) || CHANNELS[0]
  const faltam = Math.max(stats.meta - stats.visitas, 0)
  const leadsNecessarios = faltam * stats.media
  const riskTone = faltam >= 7 ? 'danger' : faltam >= 3 ? 'warning' : 'success'

  const ordered = useMemo(() => flow.map(id => CHANNELS.find(c => c.id === id)).filter(Boolean), [flow])

  async function loadLead() {
    setLoading(true)
    setError('')
    const res = await buscarProximoLeadOperacional()
    if (!res.ok) setError(res.error?.message || 'Não foi possível carregar o próximo lead.')
    setLead(res.ok ? res.lead : null)
    setStep(0)
    setLoading(false)
  }

  useEffect(() => { loadLead() }, [])

  function prioritize(channelId) {
    setFlow(prev => [channelId, ...prev.filter(id => id !== channelId)])
    setStep(0)
  }

  function markActionSent() {
    setStats(prev => ({
      ...prev,
      whatsapps: active === 'whatsapp' ? prev.whatsapps + 1 : prev.whatsapps,
      ligacoes: active === 'call' ? prev.ligacoes + 1 : prev.ligacoes,
      emails: active === 'email' ? prev.emails + 1 : prev.emails,
    }))
    setStep(prev => Math.min(prev + 1, flow.length - 1))
  }

  async function feedback(feedbackId) {
    if (!lead?.id) {
      setError('Nenhum lead carregado para registrar feedback.')
      return
    }

    const res = await registrarFeedbackOperacional({ p_lead_id: lead.id, p_feedback: feedbackId })
    if (!res.ok) {
      setError(res.error?.message || 'Erro ao registrar feedback.')
      return
    }

    if (feedbackId === 'agendado_visita') {
      setStats(prev => ({ ...prev, visitas: prev.visitas + 1 }))
    }

    await loadLead()
  }

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900">
      <div className="sticky top-0 z-10 border-b border-gray-100 bg-white px-4 py-3">
        <div className="mx-auto flex max-w-5xl items-center justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-blue-600">FECH.AI</p>
            <h1 className="text-xl font-black">Aceleração Operacional</h1>
            <p className="text-sm text-gray-500">{nome ? `${nome}, foco em visitas.` : 'Foco em visitas para o final de semana.'}</p>
          </div>
          <button onClick={() => { window.location.hash = ''; window.location.reload() }} className="rounded-xl border border-gray-200 bg-white px-4 py-2 text-sm font-semibold text-gray-700">Home</button>
        </div>
      </div>

      <main className="mx-auto max-w-5xl space-y-5 p-4 pb-10">
        <section className="grid gap-3 md:grid-cols-4">
          <StatCard label="Meta fim de semana" value={stats.meta} hint="Visitas desejadas" />
          <StatCard label="Agendadas" value={stats.visitas} hint="Visitas já marcadas" tone="success" />
          <StatCard label="Faltam" value={faltam} hint="Pressão operacional" tone={riskTone} />
          <StatCard label="Leads necessários" value={leadsNecessarios} hint={`Média: 1 visita/${stats.media} leads`} tone={riskTone} />
        </section>

        {error && <div className="rounded-2xl border border-red-200 bg-red-50 p-4 font-semibold text-red-700">{error}</div>}

        <section className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
          <h2 className="text-lg font-black">Como você quer abordar?</h2>
          <p className="mb-4 text-sm text-gray-500">Toque no canal para colocá-lo em primeiro.</p>
          <div className="grid gap-3 md:grid-cols-3">
            {CHANNELS.map(channel => (
              <button key={channel.id} onClick={() => prioritize(channel.id)} className={`rounded-2xl border p-4 text-left ${flow[0] === channel.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200 bg-white'}`}>
                <div className="text-lg font-black">{channel.icon} {ordered.findIndex(c => c.id === channel.id) + 1}. {channel.label}</div>
              </button>
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
          <h2 className="text-lg font-black">Tom da conversa</h2>
          <div className="mt-4 grid gap-3 md:grid-cols-2">
            {CONTEXTS.map(item => (
              <button key={item.id} onClick={() => setContext(item.id)} className={`rounded-2xl border p-4 text-left ${context === item.id ? 'border-emerald-500 bg-emerald-50' : 'border-gray-200 bg-white'}`}>
                <div className="font-black">{item.label}</div>
                <div className="text-sm text-gray-500">{item.hint}</div>
              </button>
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-blue-100 bg-blue-50 p-4 shadow-sm">
          <p className="text-xs font-bold uppercase tracking-wide text-blue-700">Próxima ação</p>
          <div className="mt-1 text-2xl font-black text-blue-950">{activeChannel.icon} {activeChannel.label}</div>
          <p className="mt-1 text-sm text-blue-800">{buildHint(active, context)}</p>
          <div className="mt-4 flex gap-2">
            <button onClick={markActionSent} className="rounded-2xl bg-blue-600 px-5 py-3 font-bold text-white">Ação enviada</button>
            <button onClick={() => setStep(prev => Math.min(prev + 1, flow.length - 1))} className="rounded-2xl border border-blue-200 bg-white px-5 py-3 font-bold text-blue-700">Pular</button>
          </div>
        </section>

        <section className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <h2 className="text-lg font-black">Lead em trabalho</h2>
              <p className="text-sm text-gray-500">Conectado ao proximo_lead().</p>
            </div>
            <button onClick={loadLead} className="rounded-2xl bg-gray-900 px-4 py-2 text-sm font-bold text-white">Próximo lead</button>
          </div>

          {loading ? (
            <div className="rounded-2xl border border-dashed border-blue-200 bg-blue-50 p-6 text-center font-bold text-blue-700">Carregando lead...</div>
          ) : lead ? (
            <div className="rounded-2xl border border-gray-100 bg-gray-50 p-4">
              <p className="text-xl font-black">{getLeadName(lead)}</p>
              <p className="text-sm text-gray-500">{getLeadPhone(lead)}</p>
              <p className="text-sm text-gray-500">{getLeadEmail(lead)}</p>
            </div>
          ) : (
            <div className="rounded-2xl border border-dashed border-gray-200 bg-gray-50 p-6 text-center font-bold text-gray-700">Nenhum lead disponível.</div>
          )}
        </section>

        <section className="rounded-3xl border border-gray-100 bg-white p-4 shadow-sm">
          <h2 className="text-lg font-black">Feedback rápido</h2>
          <div className="mt-4 grid gap-3 md:grid-cols-3">
            {FEEDBACKS.map(item => (
              <button key={item.id} onClick={() => feedback(item.id)} className="rounded-2xl border border-gray-200 bg-white p-4 text-left font-bold hover:border-blue-200">
                <span className="mr-2">{item.icon}</span>{item.label}
              </button>
            ))}
          </div>
        </section>

        <section className="grid gap-3 md:grid-cols-3">
          <StatCard label="Ligações" value={stats.ligacoes} hint="Executadas na sessão" />
          <StatCard label="WhatsApps" value={stats.whatsapps} hint="Marcados como enviados" />
          <StatCard label="E-mails" value={stats.emails} hint="Marcados como enviados" />
        </section>
      </main>
    </div>
  )
}
