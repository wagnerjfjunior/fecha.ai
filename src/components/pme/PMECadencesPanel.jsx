import { getCurrentOperationCadences } from './pmeCadenceSeeds'
import { PME_LEAD_TYPES } from './pmeSeedTemplates'

function getLeadTypeName(key) {
  return PME_LEAD_TYPES.find((item) => item.key === key)?.name || key
}

function channelLabel(channel) {
  if (channel === 'whatsapp') return 'WhatsApp'
  if (channel === 'call') return 'Ligação'
  if (channel === 'email') return 'E-mail'
  return channel
}

function channelIcon(channel) {
  if (channel === 'whatsapp') return '💬'
  if (channel === 'call') return '📞'
  if (channel === 'email') return '✉️'
  return '⚙️'
}

function RiskBadge({ level }) {
  const classes = {
    alto: 'bg-red-50 text-red-700 border-red-100',
    medio: 'bg-amber-50 text-amber-700 border-amber-100',
    baixo: 'bg-emerald-50 text-emerald-700 border-emerald-100',
  }

  return (
    <span className={'rounded-full border px-3 py-1 text-xs font-black ' + (classes[level] || classes.medio)}>
      risco {level}
    </span>
  )
}

function CadenceStep({ step }) {
  return (
    <div className="relative flex gap-4 rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-2xl bg-blue-50 text-xl">
        {channelIcon(step.channel)}
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">
              Passo {step.order} · {step.when} · {channelLabel(step.channel)}
            </p>
            <h4 className="mt-1 font-black text-slate-900">{step.title}</h4>
          </div>
          <span className="w-fit rounded-full bg-slate-100 px-3 py-1 text-[11px] font-black text-slate-600">
            {step.phase}
          </span>
        </div>
        <p className="mt-3 text-sm leading-6 text-slate-600">{step.instruction}</p>
        <div className="mt-3 rounded-2xl bg-slate-50 p-3 text-sm leading-6 text-slate-500">
          <strong className="text-slate-700">Resultado esperado:</strong> {step.expectedResult}
        </div>
        {step.humanAction && (
          <p className="mt-3 text-xs font-black text-emerald-700">✓ Requer ação humana nesta versão</p>
        )}
      </div>
    </div>
  )
}

function CadenceCard({ cadence }) {
  return (
    <div className="space-y-4 rounded-[2rem] border border-slate-200 bg-slate-50 p-4 md:p-5">
      <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">
              {getLeadTypeName(cadence.leadType)} · {cadence.id}
            </p>
            <h3 className="mt-2 text-xl font-black text-slate-900">{cadence.title}</h3>
            <p className="mt-2 max-w-3xl text-sm leading-6 text-slate-500">{cadence.objective}</p>
          </div>
          <div className="flex flex-wrap gap-2">
            <RiskBadge level={cadence.riskLevel} />
            <span className="rounded-full border border-blue-100 bg-blue-50 px-3 py-1 text-xs font-black text-blue-700">
              modo {cadence.recommendedMode}
            </span>
          </div>
        </div>

        <div className="mt-5 grid grid-cols-1 gap-4 lg:grid-cols-2">
          <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-4">
            <p className="text-xs uppercase tracking-widest text-emerald-700 font-black">Guardrails</p>
            <div className="mt-3 space-y-2">
              {cadence.guardrails.map((rule) => (
                <p key={rule} className="text-sm leading-6 text-emerald-950">• {rule}</p>
              ))}
            </div>
          </div>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="rounded-2xl border border-red-100 bg-red-50 p-4">
              <p className="text-xs uppercase tracking-widest text-red-700 font-black">Parar se</p>
              <div className="mt-3 flex flex-wrap gap-2">
                {cadence.stopOnFeedbacks.map((item) => (
                  <span key={item} className="rounded-full bg-white px-2 py-1 text-[11px] font-black text-red-700">{item}</span>
                ))}
              </div>
            </div>
            <div className="rounded-2xl border border-amber-100 bg-amber-50 p-4">
              <p className="text-xs uppercase tracking-widest text-amber-700 font-black">Pausar se</p>
              <div className="mt-3 flex flex-wrap gap-2">
                {cadence.pauseOnFeedbacks.map((item) => (
                  <span key={item} className="rounded-full bg-white px-2 py-1 text-[11px] font-black text-amber-700">{item}</span>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="space-y-3">
        {cadence.steps.map((step) => (
          <CadenceStep key={cadence.id + step.order} step={step} />
        ))}
      </div>
    </div>
  )
}

export default function PMECadencesPanel() {
  const cadences = getCurrentOperationCadences()

  return (
    <div className="space-y-5">
      <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Cadências</p>
            <h2 className="mt-2 text-xl font-black text-slate-900">Fluxos assistidos da operação atual</h2>
            <p className="mt-2 text-sm leading-6 text-slate-500">
              A cadência organiza WhatsApp e ligação em uma sequência simples, com parada e pausa por feedback. Nesta fase, tudo exige ação humana.
            </p>
          </div>
          <button
            className="rounded-2xl bg-blue-600 px-5 py-3 text-sm font-black text-white opacity-60 cursor-not-allowed"
            title="Disponível quando criarmos persistência no banco"
          >
            Nova Cadência
          </button>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
        <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Cadências seed</p>
          <p className="mt-1 text-3xl font-black text-slate-900">{cadences.length}</p>
          <p className="mt-2 text-xs text-slate-500">Operação atual</p>
        </div>
        <div className="rounded-3xl border border-emerald-100 bg-emerald-50 p-5 shadow-sm">
          <p className="text-sm text-emerald-800">Modo</p>
          <p className="mt-1 text-3xl font-black text-emerald-950">100%</p>
          <p className="mt-2 text-xs text-emerald-700">Assistido por humano</p>
        </div>
        <div className="rounded-3xl border border-blue-100 bg-blue-50 p-5 shadow-sm">
          <p className="text-sm text-blue-800">Canais</p>
          <p className="mt-1 text-3xl font-black text-blue-950">2</p>
          <p className="mt-2 text-xs text-blue-700">WhatsApp + Ligação</p>
        </div>
        <div className="rounded-3xl border border-amber-100 bg-amber-50 p-5 shadow-sm">
          <p className="text-sm text-amber-800">Automação</p>
          <p className="mt-1 text-3xl font-black text-amber-950">0</p>
          <p className="mt-2 text-xs text-amber-700">Sem disparo automático</p>
        </div>
      </div>

      <div className="space-y-5">
        {cadences.map((cadence) => (
          <CadenceCard key={cadence.id} cadence={cadence} />
        ))}
      </div>

      <div className="rounded-3xl border border-blue-100 bg-blue-50 p-5 text-sm leading-6 text-blue-950">
        <p className="font-black">Próximo encaixe futuro</p>
        <p className="mt-1">
          Quando conectarmos a PME ao Acelerador, cada passo vira uma próxima melhor ação: enviar WhatsApp, ligar com script, registrar feedback, pausar ou encerrar. O corretor não precisa montar a régua; ele só executa o passo certo.
        </p>
      </div>
    </div>
  )
}
