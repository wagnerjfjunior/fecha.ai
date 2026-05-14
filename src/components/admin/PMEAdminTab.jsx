export default function PMEAdminTab({ userRole = 'admin', onOpenDocs }) {
  const modules = [
    {
      title: 'Templates WhatsApp',
      status: 'Base da v1',
      description: 'Pools por tipo de lead, fase, tom e empreendimento.',
      icon: '💬',
      accent: 'emerald',
    },
    {
      title: 'Templates E-mail',
      status: 'Preparado',
      description: 'Assuntos, corpos de e-mail e mensagens de reforço comercial.',
      icon: '✉️',
      accent: 'blue',
    },
    {
      title: 'Scripts de Ligação',
      status: 'Preparado',
      description: 'Roteiros guiados para o corretor não se perder durante a chamada.',
      icon: '📞',
      accent: 'amber',
    },
    {
      title: 'Cadências',
      status: 'Planejado',
      description: 'Regras do Acelerador e do Piloto Automático assistivo.',
      icon: '⚡',
      accent: 'violet',
    },
    {
      title: 'Histórico de Uso',
      status: 'Planejado',
      description: 'Auditoria de mensagens geradas, copiadas, enviadas e respondidas.',
      icon: '🧾',
      accent: 'slate',
    },
    {
      title: 'Governança',
      status: 'Obrigatório',
      description: 'LGPD, opt-out, limites, tenant isolation e proteção de reputação.',
      icon: '🛡️',
      accent: 'rose',
    },
  ];

  const stats = [
    { label: 'Canais planejados', value: '3', hint: 'WhatsApp, E-mail e Ligação' },
    { label: 'Fases base', value: '4', hint: '1ª, 2ª, 3ª e final' },
    { label: 'Tipos de lead', value: '4', hint: 'Quente, fria, quente e pós-plantão' },
    { label: 'Templates WhatsApp alvo', value: '160', hint: '10 variações por combinação' },
  ];

  return (
    <div className="p-4 md:p-6 space-y-6 bg-gray-50 min-h-screen">
      <div className="bg-gradient-to-br from-slate-950 via-slate-900 to-blue-950 rounded-3xl p-6 md:p-8 text-white shadow-lg">
        <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
          <div>
            <p className="text-xs uppercase tracking-[0.25em] text-blue-200 font-semibold">PME</p>
            <h1 className="text-2xl md:text-3xl font-black mt-2">Power Message Engine</h1>
            <p className="text-blue-100 mt-2 max-w-3xl">
              Central administrativa para mensagens, scripts e cadências comerciais do FECH.AI.
              Nesta primeira fase, a visualização fica restrita ao administrador antes de liberar consumo no discador e no acelerador dos corretores.
            </p>
          </div>

          <div className="bg-white/10 border border-white/15 rounded-2xl p-4 min-w-[220px]">
            <p className="text-xs text-blue-100 uppercase font-semibold">Status do módulo</p>
            <p className="text-xl font-bold mt-1">Admin Shell v0.1</p>
            <p className="text-sm text-blue-100 mt-1">Sem impacto no motor atual</p>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {stats.map((item) => (
          <div key={item.label} className="bg-white border border-gray-100 rounded-2xl p-5 shadow-sm">
            <p className="text-sm text-gray-500">{item.label}</p>
            <p className="text-3xl font-black text-gray-900 mt-1">{item.value}</p>
            <p className="text-xs text-gray-400 mt-2">{item.hint}</p>
          </div>
        ))}
      </div>

      <div className="bg-white border border-gray-100 rounded-3xl p-5 md:p-6 shadow-sm">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-5">
          <div>
            <h2 className="text-xl font-bold text-gray-900">Estrutura da Central</h2>
            <p className="text-sm text-gray-500 mt-1">
              Primeiro montamos a sala de máquinas; depois conectamos no discador e na Oferta Ativa.
            </p>
          </div>
          <span className="inline-flex items-center rounded-full bg-amber-50 text-amber-700 border border-amber-100 px-3 py-1 text-xs font-semibold w-fit">
            Visualização administrativa
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {modules.map((module) => (
            <button
              key={module.title}
              type="button"
              className="text-left rounded-2xl border border-gray-100 bg-gray-50 hover:bg-white hover:border-blue-200 hover:shadow-md transition-all p-5"
            >
              <div className="flex items-start justify-between gap-3">
                <div className="w-12 h-12 rounded-2xl bg-white shadow-sm flex items-center justify-center text-2xl">
                  {module.icon}
                </div>
                <span className="text-xs font-bold rounded-full bg-white border border-gray-100 text-gray-500 px-2 py-1">
                  {module.status}
                </span>
              </div>
              <h3 className="text-base font-bold text-gray-900 mt-4">{module.title}</h3>
              <p className="text-sm text-gray-500 mt-1 leading-relaxed">{module.description}</p>
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <div className="bg-white border border-gray-100 rounded-3xl p-5 md:p-6 shadow-sm">
          <h2 className="text-lg font-bold text-gray-900">Roadmap imediato</h2>
          <div className="mt-4 space-y-3">
            {[
              'Criar aba PME no painel administrativo, admin/root only.',
              'Cadastrar/listar templates de WhatsApp por tipo de lead e fase.',
              'Adicionar scripts de ligação por cenário comercial.',
              'Registrar histórico de geração/cópia/envio manual.',
              'Liberar consumo pelo Acelerador somente depois da base validada.',
            ].map((text, index) => (
              <div key={text} className="flex gap-3">
                <div className="w-7 h-7 rounded-full bg-blue-50 text-blue-700 flex items-center justify-center text-sm font-bold flex-shrink-0">
                  {index + 1}
                </div>
                <p className="text-sm text-gray-600 pt-1">{text}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-white border border-gray-100 rounded-3xl p-5 md:p-6 shadow-sm">
          <h2 className="text-lg font-bold text-gray-900">Guardrails</h2>
          <div className="mt-4 space-y-3 text-sm text-gray-600">
            <p>• Não altera RPCs centrais: <code className="bg-gray-100 px-1 rounded">proximo_lead</code>, <code className="bg-gray-100 px-1 rounded">solicitar_lote</code> e <code className="bg-gray-100 px-1 rounded">registrar_feedback</code>.</p>
            <p>• Não dispara WhatsApp automaticamente na v0.1.</p>
            <p>• Não libera configuração para corretor.</p>
            <p>• Mantém PME como módulo administrativo até validação de templates, histórico e permissões.</p>
          </div>

          <div className="mt-5 p-4 rounded-2xl bg-slate-50 border border-slate-100">
            <p className="text-xs uppercase tracking-wide text-slate-500 font-semibold">Perfil atual</p>
            <p className="text-sm font-bold text-slate-900 mt-1">{userRole}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
