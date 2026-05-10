// HomeActions.jsx — Tela principal pós-login
// Corretor vê: Oferta Ativa + Aceleração Operacional + Mesa do Cliente
// Gestor/Admin/Root vê: os mesmos + acesso ao painel administrativo
// Root vê também: Provisionar Empresa

// URL do Mesa do Cliente — ajuste conforme seu deploy
const MESA_CLIENTE_URL = 'https://quiet-surf-d4a0.wagnerjfjunior.workers.dev/';

function isRootIdentity(nome) {
  return String(nome || '').trim().toLowerCase() === 'root';
}

function abrirTenantProvisioning() {
  window.location.hash = 'tenant-provisioning';
  window.location.reload();
}

function abrirAceleracaoOperacional() {
  window.location.hash = 'aceleracao-operacional';
  window.location.reload();
}

export default function HomeActions({
  nome,
  isGestor,
  isAdminLocal,
  isRoot,
  onMesaCliente,
  onOfertaAtiva,
  onPainelGestor,
  onProvisionarEmpresa,
}) {
  const rootDetected = isRoot === true || isRootIdentity(nome);
  const canAccessAdminPanel = Boolean(isGestor || isAdminLocal || rootDetected);
  const perfilLabel = rootDetected ? 'Root' : canAccessAdminPanel ? 'Gestor' : 'Corretor';

  return (
    <div className="min-h-screen bg-gray-50 flex flex-col">

      {/* Header */}
      <div className="bg-white border-b border-gray-100 px-5 py-4">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs text-gray-400 font-medium uppercase tracking-wide">
              {perfilLabel}
            </p>
            <h1 className="text-lg font-bold text-gray-900">
              Olá, {nome?.split(' ')[0]} 👋
            </h1>
          </div>
          <div className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center">
            <span className="text-white font-bold text-sm">
              {nome?.charAt(0).toUpperCase()}
            </span>
          </div>
        </div>
      </div>

      {/* Ações principais */}
      <div className="flex-1 p-5 space-y-4">

        <p className="text-xs text-gray-400 uppercase font-semibold tracking-wide mb-2">
          O que vamos fazer agora?
        </p>

        {/* Oferta Ativa — fluxo atual preservado */}
        <button
          onClick={onOfertaAtiva}
          className="w-full bg-blue-600 text-white rounded-2xl p-5 flex items-center gap-4 hover:bg-blue-700 active:scale-95 transition-all shadow-md shadow-blue-200"
        >
          <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center flex-shrink-0">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
            </svg>
          </div>
          <div className="text-left">
            <p className="font-bold text-base">Oferta Ativa</p>
            <p className="text-blue-100 text-sm">Atender leads da minha fila</p>
          </div>
          <svg className="w-5 h-5 text-white/60 ml-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </button>

        {/* Aceleração Operacional — novo cockpit */}
        <button
          onClick={abrirAceleracaoOperacional}
          className="w-full bg-emerald-600 text-white rounded-2xl p-5 flex items-center gap-4 hover:bg-emerald-700 active:scale-95 transition-all shadow-md shadow-emerald-100"
        >
          <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center flex-shrink-0">
            <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <div className="text-left">
            <p className="font-bold text-base">Aceleração Operacional</p>
            <p className="text-emerald-100 text-sm">Abordar leads e gerar visitas</p>
          </div>
          <svg className="w-5 h-5 text-white/60 ml-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
          </svg>
        </button>

        {/* Mesa do Cliente */}
        <button
  onClick={onMesaCliente}>
  Mesa do Cliente
        </button>
          <div className="w-12 h-12 bg-indigo-50 rounded-xl flex items-center justify-center flex-shrink-0">
            <svg className="w-6 h-6 text-indigo-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
          </div>
          <div className="text-left">
            <p className="font-bold text-base text-gray-900">Mesa do Cliente</p>
            <p className="text-gray-400 text-sm">Simulação comercial de unidades</p>
          </div>
          <svg className="w-5 h-5 text-gray-300 ml-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14" />
          </svg>
        </a>

        {/* Painel Root — somente root */}
        {rootDetected && (
          <button
            onClick={() => {
              if (onProvisionarEmpresa) onProvisionarEmpresa();
              else abrirTenantProvisioning();
            }}
            className="w-full bg-emerald-700 text-white rounded-2xl p-5 flex items-center gap-4 hover:bg-emerald-800 active:scale-95 transition-all shadow-md shadow-emerald-100"
          >
            <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center flex-shrink-0">
              <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                  d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5m4 0v-5a2 2 0 00-2-2h0a2 2 0 00-2 2v5m4 0h-4" />
              </svg>
            </div>
            <div className="text-left">
              <p className="font-bold text-base">Painel Root</p>
              <p className="text-emerald-100 text-sm">Tenants, admins locais e usuários</p>
            </div>
            <svg className="w-5 h-5 text-white/60 ml-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        )}

        {/* Painel gestor/admin — gestores, admins locais e root */}
        {canAccessAdminPanel && (
          <button
            onClick={onPainelGestor}
            className="w-full bg-gray-900 text-white rounded-2xl p-5 flex items-center gap-4 hover:bg-gray-800 active:scale-95 transition-all"
          >
            <div className="w-12 h-12 bg-white/10 rounded-xl flex items-center justify-center flex-shrink-0">
              <svg className="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2}
                  d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
              </svg>
            </div>
            <div className="text-left">
              <p className="font-bold text-base">Painel Gestor/Admin</p>
              <p className="text-gray-400 text-sm">Empresas, usuários, times, listas e logs</p>
            </div>
            <svg className="w-5 h-5 text-white/40 ml-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        )}

      </div>
    </div>
  );
}
