export default function PMEScopeNotice({ compact = false }) {
  return (
    <div className="rounded-3xl border border-violet-100 bg-violet-50 p-5 shadow-sm">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <p className="text-xs uppercase tracking-widest text-violet-700 font-black">Escopo atual</p>
          <h3 className="mt-1 text-lg font-black text-violet-950">Seed Global FECH.AI</h3>
          <p className="mt-2 text-sm leading-6 text-violet-900">
            Estes conteudos ainda nao pertencem a uma empresa especifica. Eles sao uma biblioteca base neutra da PME para posterior personalizacao por tenant, empresa e empreendimento.
          </p>
        </div>
        <span className="w-fit rounded-full border border-violet-200 bg-white px-3 py-1 text-xs font-black text-violet-700">
          ainda sem vinculo de empresa
        </span>
      </div>

      {!compact && (
        <div className="mt-4 grid grid-cols-1 gap-3 md:grid-cols-4">
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[11px] uppercase tracking-widest text-slate-400 font-black">Hoje</p>
            <p className="mt-1 text-sm font-black text-slate-800">Seed global</p>
          </div>
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[11px] uppercase tracking-widest text-slate-400 font-black">Depois</p>
            <p className="mt-1 text-sm font-black text-slate-800">Tenant</p>
          </div>
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[11px] uppercase tracking-widest text-slate-400 font-black">Refino</p>
            <p className="mt-1 text-sm font-black text-slate-800">Empresa</p>
          </div>
          <div className="rounded-2xl bg-white p-3">
            <p className="text-[11px] uppercase tracking-widest text-slate-400 font-black">Especializacao</p>
            <p className="mt-1 text-sm font-black text-slate-800">Empreendimento</p>
          </div>
        </div>
      )}
    </div>
  )
}
