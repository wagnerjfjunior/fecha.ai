import PMEScopeNotice from './PMEScopeNotice'
import { getCurrentOperationCallScripts } from './pmeCallScriptSeeds'
import { PME_LEAD_TYPES } from './pmeSeedTemplates'

function getLeadTypeName(key) {
  return PME_LEAD_TYPES.find((item) => item.key === key)?.name || key
}

function ScriptCard({ script }) {
  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <p className="text-xs uppercase tracking-widest text-slate-400 font-black">
            {getLeadTypeName(script.leadType)}
          </p>
          <h3 className="mt-2 text-lg font-black text-slate-900">{script.title}</h3>
          <p className="mt-2 text-sm leading-6 text-slate-500">{script.objective}</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <span className="w-fit rounded-full bg-violet-50 px-3 py-1 text-xs font-black text-violet-700">
            Seed Global
          </span>
          <span className="w-fit rounded-full bg-blue-50 px-3 py-1 text-xs font-black text-blue-700">
            {script.id}
          </span>
        </div>
      </div>

      <div className="mt-5 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Abertura</p>
          <p className="mt-2 text-sm leading-6 text-slate-700">{script.opening}</p>
        </div>
        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Contexto</p>
          <p className="mt-2 text-sm leading-6 text-slate-700">{script.context}</p>
        </div>
        <div className="rounded-2xl bg-blue-50 p-4 lg:col-span-2">
          <p className="text-xs uppercase tracking-widest text-blue-500 font-black">Primeira pergunta</p>
          <p className="mt-2 text-sm font-bold leading-6 text-blue-950">{script.firstQuestion}</p>
        </div>
      </div>

      <div className="mt-5 grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div>
          <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Qualificacao</p>
          <div className="mt-3 space-y-2">
            {script.qualification.map((question) => (
              <div key={question} className="rounded-2xl border border-slate-100 bg-slate-50 px-4 py-3 text-sm text-slate-700">
                {question}
              </div>
            ))}
          </div>
        </div>

        <div>
          <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Objecoes</p>
          <div className="mt-3 space-y-2">
            {script.objections.map((item) => (
              <div key={item.objection} className="rounded-2xl border border-amber-100 bg-amber-50 px-4 py-3">
                <p className="text-sm font-black text-amber-950">{item.objection}</p>
                <p className="mt-1 text-sm leading-6 text-amber-900">{item.response}</p>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div className="mt-5 rounded-2xl border border-emerald-100 bg-emerald-50 p-4">
        <p className="text-xs uppercase tracking-widest text-emerald-600 font-black">Fechamento sugerido</p>
        <p className="mt-2 text-sm leading-6 text-emerald-950">{script.closing}</p>
      </div>

      <div className="mt-5">
        <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Feedbacks esperados</p>
        <div className="mt-3 flex flex-wrap gap-2">
          {script.feedbackOptions.map((feedback) => (
            <span key={feedback} className="rounded-full bg-slate-100 px-3 py-1 text-xs font-black text-slate-600">
              {feedback}
            </span>
          ))}
        </div>
      </div>
    </div>
  )
}

export default function PMECallScriptsPanel() {
  const scripts = getCurrentOperationCallScripts()

  return (
    <div className="space-y-5">
      <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Scripts de Ligacao</p>
            <h2 className="mt-2 text-xl font-black text-slate-900">Roteiros da operacao atual</h2>
            <p className="mt-2 text-sm leading-6 text-slate-500">
              Scripts iniciais para lista fria/comprada e leads que visitaram plantao. A ideia e guiar a ligacao sem engessar o corretor.
            </p>
          </div>
          <button
            className="rounded-2xl bg-blue-600 px-5 py-3 text-sm font-black text-white opacity-60 cursor-not-allowed"
            title="Disponivel quando criarmos persistencia no banco"
          >
            Novo Script
          </button>
        </div>
      </div>

      <PMEScopeNotice compact />

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm">
          <p className="text-sm text-slate-500">Scripts criados</p>
          <p className="mt-1 text-3xl font-black text-slate-900">{scripts.length}</p>
          <p className="mt-2 text-xs text-slate-500">Seeds versionados</p>
        </div>
        <div className="rounded-3xl border border-emerald-100 bg-emerald-50 p-5 shadow-sm">
          <p className="text-sm text-emerald-800">Prioridades cobertas</p>
          <p className="mt-1 text-3xl font-black text-emerald-950">2</p>
          <p className="mt-2 text-xs text-emerald-700">Lista fria e visitou plantao</p>
        </div>
        <div className="rounded-3xl border border-amber-100 bg-amber-50 p-5 shadow-sm">
          <p className="text-sm text-amber-800">Status</p>
          <p className="mt-1 text-3xl font-black text-amber-950">v0.1</p>
          <p className="mt-2 text-xs text-amber-700">Ainda sem integracao no discador</p>
        </div>
      </div>

      <div className="space-y-4">
        {scripts.map((script) => (
          <ScriptCard key={script.id} script={script} />
        ))}
      </div>

      <div className="rounded-3xl border border-blue-100 bg-blue-50 p-5 text-sm leading-6 text-blue-950">
        <p className="font-black">Proximo encaixe futuro</p>
        <p className="mt-1">
          Quando a PME for conectada ao discador, estes blocos devem aparecer lateralmente durante a ligacao, junto com botoes rapidos de feedback. O corretor nao precisa ver toda a engenharia: so o roteiro certo para aquele lead.
        </p>
      </div>
    </div>
  )
}
