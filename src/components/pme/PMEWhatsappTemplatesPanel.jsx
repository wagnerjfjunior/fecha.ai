import PMEScopeNotice from './PMEScopeNotice'
import {
  PME_LEAD_TYPES,
  PME_TEMPLATE_PHASES,
  PME_INITIAL_WHATSAPP_SEEDS,
  countSeedsByLeadTypeAndPhase,
  getSeedCompletionStats,
} from './pmeSeedTemplates'

const CURRENT_OPERATION_PRIORITY = ['visitou_plantao', 'lista_fria']

function getLeadTypeName(key) {
  return PME_LEAD_TYPES.find((item) => item.key === key)?.name || key
}

function getPhaseName(key) {
  return PME_TEMPLATE_PHASES.find((item) => item.key === key)?.name || key
}

function ProgressBar({ value }) {
  const safeValue = Math.max(0, Math.min(Number(value) || 0, 100))

  return (
    <div className="h-3 w-full overflow-hidden rounded-full bg-slate-100">
      <div
        className="h-full rounded-full bg-blue-600 transition-all"
        style={{ width: safeValue + '%' }}
      />
    </div>
  )
}

function MatrixCell({ leadType, phase }) {
  const count = countSeedsByLeadTypeAndPhase(leadType, phase)
  const complete = count >= 10
  const partial = count > 0 && count < 10

  return (
    <div
      className={
        'rounded-2xl border p-3 ' +
        (complete
          ? 'border-emerald-100 bg-emerald-50'
          : partial
            ? 'border-amber-100 bg-amber-50'
            : 'border-slate-100 bg-slate-50')
      }
    >
      <p className="text-xs font-black text-slate-700">{getPhaseName(phase)}</p>
      <div className="mt-2 flex items-end justify-between gap-2">
        <p className="text-2xl font-black text-slate-900">{count}</p>
        <p className="text-[11px] font-bold text-slate-500">/ 10</p>
      </div>
      <p
        className={
          'mt-2 text-[11px] font-black ' +
          (complete ? 'text-emerald-700' : partial ? 'text-amber-700' : 'text-slate-500')
        }
      >
        {complete ? 'Completo' : partial ? 'Em montagem' : 'Pendente'}
      </p>
    </div>
  )
}

function SeedPreviewCard({ template }) {
  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs uppercase tracking-widest text-slate-400 font-black">
            {getLeadTypeName(template.leadType)} · {getPhaseName(template.phase)}
          </p>
          <h3 className="mt-2 font-black text-slate-900">{template.title}</h3>
        </div>
        <div className="flex flex-wrap gap-2">
          <span className="w-fit rounded-full bg-violet-50 px-3 py-1 text-[11px] font-black text-violet-700">
            Seed Global
          </span>
          <span className="w-fit rounded-full bg-slate-100 px-3 py-1 text-[11px] font-black text-slate-600">
            {template.tone}
          </span>
        </div>
      </div>
      <p className="mt-4 rounded-2xl bg-slate-50 p-4 text-sm leading-6 text-slate-700">
        {template.body}
      </p>
      <div className="mt-4 flex flex-wrap gap-2 text-[11px] font-bold text-slate-500">
        <span className="rounded-full bg-blue-50 px-2 py-1 text-blue-700">{template.id}</span>
        <span className="rounded-full bg-slate-100 px-2 py-1">{template.channel}</span>
        <span className="rounded-full bg-violet-50 px-2 py-1 text-violet-700">nao vinculado a empresa</span>
      </div>
    </div>
  )
}

function CurrentPriorityCard({ leadType }) {
  const lead = PME_LEAD_TYPES.find((item) => item.key === leadType)
  const total = PME_TEMPLATE_PHASES.reduce((sum, phase) => sum + countSeedsByLeadTypeAndPhase(leadType, phase.key), 0)
  const percent = Math.round((total / 40) * 100)

  return (
    <div className="rounded-3xl border border-emerald-100 bg-emerald-50 p-5 shadow-sm">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs uppercase tracking-widest text-emerald-700 font-black">Prioridade operacional atual</p>
          <h3 className="mt-2 text-lg font-black text-emerald-950">{lead?.name || leadType}</h3>
          <p className="mt-1 text-sm leading-6 text-emerald-800">{lead?.hint}</p>
        </div>
        <span className="rounded-2xl bg-white px-3 py-2 text-xl font-black text-emerald-700">{total}</span>
      </div>
      <div className="mt-4">
        <div className="mb-2 flex justify-between text-xs font-black text-emerald-800">
          <span>Completude operacional</span>
          <span>{percent}%</span>
        </div>
        <div className="h-3 overflow-hidden rounded-full bg-white">
          <div className="h-full rounded-full bg-emerald-600" style={{ width: percent + '%' }} />
        </div>
      </div>
    </div>
  )
}

export default function PMEWhatsappTemplatesPanel() {
  const stats = getSeedCompletionStats(10)
  const previewTemplates = PME_INITIAL_WHATSAPP_SEEDS.filter((item) => CURRENT_OPERATION_PRIORITY.includes(item.leadType)).slice(0, 8)

  return (
    <div className="space-y-5">
      <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Templates WhatsApp</p>
            <h2 className="mt-2 text-xl font-black">Matriz inicial de mensagens da PME</h2>
            <p className="mt-2 text-sm leading-6 text-slate-500">
              Esta visao mostra os templates seed versionados no frontend. A prioridade atual da operacao e trabalhar listas de visitantes de plantao e listas frias/compradas antes da integracao com redes sociais.
            </p>
          </div>
          <button
            className="rounded-2xl bg-blue-600 px-5 py-3 text-sm font-black text-white opacity-60 cursor-not-allowed"
            title="Disponivel quando criarmos as tabelas da PME"
          >
            Novo Template
          </button>
        </div>
      </div>

      <PMEScopeNotice />

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {CURRENT_OPERATION_PRIORITY.map((leadType) => (
          <CurrentPriorityCard key={leadType} leadType={leadType} />
        ))}
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-4">
        <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Templates criados</p>
          <p className="mt-1 text-3xl font-black text-slate-900">{stats.currentTotal}</p>
          <p className="mt-2 text-xs text-slate-500">Seeds iniciais versionados</p>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Meta v1</p>
          <p className="mt-1 text-3xl font-black text-slate-900">{stats.targetTotal}</p>
          <p className="mt-2 text-xs text-slate-500">10 por tipo/fase</p>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Faltam</p>
          <p className="mt-1 text-3xl font-black text-slate-900">{stats.remainingTotal}</p>
          <p className="mt-2 text-xs text-slate-500">Para completar a matriz</p>
        </div>
        <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Completude</p>
          <p className="mt-1 text-3xl font-black text-slate-900">{stats.completionPercent}%</p>
          <div className="mt-3">
            <ProgressBar value={stats.completionPercent} />
          </div>
        </div>
      </div>

      <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="mb-4 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Matriz por combinacao</p>
            <h2 className="text-lg font-black text-slate-900">Tipos de lead x fases</h2>
          </div>
          <span className="w-fit rounded-full bg-amber-50 px-3 py-1 text-xs font-black text-amber-700 border border-amber-100">
            Meta: 10 templates por celula
          </span>
        </div>

        <div className="space-y-4">
          {PME_LEAD_TYPES.map((lead) => {
            const isPriority = CURRENT_OPERATION_PRIORITY.includes(lead.key)
            return (
              <div
                key={lead.key}
                className={
                  'rounded-3xl border p-4 ' +
                  (isPriority ? 'border-emerald-100 bg-emerald-50/60' : 'border-slate-100 bg-slate-50')
                }
              >
                <div className="mb-3 flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                  <div>
                    <h3 className="font-black text-slate-900">{lead.name}</h3>
                    <p className="mt-1 text-xs leading-5 text-slate-500">{lead.hint}</p>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    <span className="w-fit rounded-full bg-violet-50 px-3 py-1 text-[11px] font-black text-violet-700">
                      seed global
                    </span>
                    {isPriority && (
                      <span className="w-fit rounded-full bg-emerald-600 px-3 py-1 text-[11px] font-black text-white">
                        operacao atual
                      </span>
                    )}
                  </div>
                </div>
                <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-4">
                  {PME_TEMPLATE_PHASES.map((phase) => (
                    <MatrixCell key={lead.key + phase.key} leadType={lead.key} phase={phase.key} />
                  ))}
                </div>
              </div>
            )
          })}
        </div>
      </div>

      <div>
        <div className="mb-3 flex items-end justify-between gap-3">
          <div>
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Preview</p>
            <h2 className="text-lg font-black text-slate-900">Mensagens da operacao atual</h2>
          </div>
          <span className="hidden sm:inline-flex rounded-full bg-slate-100 px-3 py-1 text-xs font-black text-slate-600">
            Mostrando {previewTemplates.length} de {PME_INITIAL_WHATSAPP_SEEDS.length}
          </span>
        </div>

        <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
          {previewTemplates.map((template) => (
            <SeedPreviewCard key={template.id} template={template} />
          ))}
        </div>
      </div>

      <div className="rounded-3xl border border-blue-100 bg-blue-50 p-5 text-sm leading-6 text-blue-950">
        <p className="font-black">Proxima decisao tecnica</p>
        <p className="mt-1">
          Depois da auditoria do schema real, estes seeds poderao ser importados para o Supabase com tenant, empresa e empreendimento. Para producao SaaS, o caminho final precisa ser Supabase com RLS por tenant.
        </p>
      </div>
    </div>
  )
}
