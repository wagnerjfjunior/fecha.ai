import { useEffect, useMemo, useState } from 'react'

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY

const MODULES = [
  {
    title: 'Templates WhatsApp',
    description: 'Pools de mensagens por tipo de lead, fase, tom e objetivo comercial.',
    status: 'Próxima fase',
    icon: '💬',
  },
  {
    title: 'Templates E-mail',
    description: 'Modelos formais para reforço, nutrição, proposta e retomada de leads.',
    status: 'Planejado',
    icon: '✉️',
  },
  {
    title: 'Scripts de Ligação',
    description: 'Roteiros em blocos para orientar o corretor durante a chamada.',
    status: 'Planejado',
    icon: '📞',
  },
  {
    title: 'Cadências',
    description: 'Sequências assistidas para primeira, segunda, terceira e última tentativa.',
    status: 'Planejado',
    icon: '🧭',
  },
  {
    title: 'Piloto Automático',
    description: 'Motor assistivo de próxima ação, lembretes e pausa de cadência.',
    status: 'Futuro seguro',
    icon: '⚙️',
  },
  {
    title: 'Métricas de Uso',
    description: 'Leitura futura de performance por template, canal, corretor e lista.',
    status: 'Futuro',
    icon: '📊',
  },
]

const FIRST_SEEDS = [
  'lead_quente + primeira_mensagem',
  'lista_fria + primeira_mensagem',
  'lista_quente + primeira_mensagem',
  'visitou_plantao + primeira_mensagem',
]

const SAFE_RULES = [
  'Sem envio automático nesta versão.',
  'Sem alteração em banco, RPCs, RLS ou discador.',
  'Sem disparo massivo de WhatsApp.',
  'Configuração primeiro; operação depois.',
]

function createSB(url, key) {
  if (!url || !key) throw new Error('Configuração Supabase ausente no ambiente Vercel.')

  const headers = (token) => ({
    apikey: key,
    Authorization: 'Bearer ' + (token || key),
    'Content-Type': 'application/json',
  })

  return {
    async rpc(fn, args, token) {
      const response = await fetch(url + '/rest/v1/rpc/' + fn, {
        method: 'POST',
        headers: headers(token),
        body: JSON.stringify(args || {}),
      })
      const data = await response.json().catch(() => null)
      if (!response.ok) throw new Error(data?.message || data?.error || 'Erro RPC ' + fn)
      return data
    },
    async query(table, params, token) {
      const response = await fetch(url + '/rest/v1/' + table + '?' + (params || ''), {
        headers: headers(token),
      })
      const data = await response.json().catch(() => null)
      if (!response.ok) throw new Error(data?.message || 'Erro ao consultar ' + table)
      return data
    },
  }
}

function carregarSessaoFechai() {
  try {
    const raw = localStorage.getItem('fechai_session')
    if (!raw) return null
    const parsed = JSON.parse(raw)
    if (!parsed?.access_token || !parsed?.user?.id) return null
    return parsed
  } catch (_) {
    return null
  }
}

function hasAdminProfile(row) {
  if (!row || row.ativo === false || row.active === false) return false

  const role = String(row.role || row.perfil || row.tipo || row.nivel || row.nivel_acesso || '').toLowerCase()
  const nomePerfil = String(row.nome_perfil || row.profile || '').toLowerCase()

  return Boolean(
    row.is_admin === true ||
    row.admin === true ||
    row.is_gestor === true ||
    row.gestor === true ||
    role.includes('admin') ||
    role.includes('gestor') ||
    role.includes('root') ||
    nomePerfil.includes('admin') ||
    nomePerfil.includes('gestor')
  )
}

async function safeQuery(sb, table, params, token) {
  try {
    return await sb.query(table, params, token)
  } catch (_) {
    return []
  }
}

async function validarAcessoAdmin(sb, session) {
  const token = session.access_token
  const userId = session.user?.id
  const email = session.user?.email

  try {
    const isRoot = await sb.rpc('is_root', {}, token)
    if (isRoot === true) return { ok: true, perfil: 'Root Admin' }
  } catch (_) {
    // Continua validação por tabelas operacionais.
  }

  const checks = []

  if (userId) {
    checks.push(safeQuery(sb, 'admins', 'select=*&user_id=eq.' + encodeURIComponent(userId), token))
    checks.push(safeQuery(sb, 'corretores', 'select=*&user_id=eq.' + encodeURIComponent(userId), token))
  }

  if (email) {
    checks.push(safeQuery(sb, 'admins', 'select=*&email=eq.' + encodeURIComponent(email), token))
    checks.push(safeQuery(sb, 'corretores', 'select=*&email=eq.' + encodeURIComponent(email), token))
  }

  const results = (await Promise.all(checks)).flat()
  const adminRow = results.find(hasAdminProfile)

  if (adminRow) {
    const perfil = hasAdminProfile(adminRow) ? 'Admin/Gestor' : 'Administrador'
    return { ok: true, perfil }
  }

  return { ok: false, perfil: null }
}

function voltarAoFechai() {
  window.location.hash = ''
  window.location.reload()
}

function SecurityScreen({ title, message }) {
  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center p-4">
      <div className="w-full max-w-xl rounded-3xl border border-slate-800 bg-slate-900 p-6 shadow-2xl">
        <button onClick={voltarAoFechai} className="text-sm text-slate-400 hover:text-white mb-5">← Voltar ao FECH.AI</button>
        <p className="text-xs uppercase tracking-[0.2em] text-blue-300 font-bold">PME · Segurança</p>
        <h1 className="text-2xl font-black mt-2 mb-4">{title}</h1>
        <div className="rounded-2xl border border-red-900/60 bg-red-950/40 text-red-100 p-4 text-sm leading-6">
          {message}
        </div>
        <p className="text-sm text-slate-400 leading-6 mt-4">
          Esta área reutiliza a sessão autenticada do FECH.AI. Ela não solicita senha novamente e não cria acesso público à Central de Mensagens.
        </p>
        <button onClick={voltarAoFechai} className="mt-5 w-full rounded-2xl bg-blue-600 hover:bg-blue-700 text-white font-bold py-3">
          Voltar
        </button>
      </div>
    </div>
  )
}

function ModuleCard({ item }) {
  return (
    <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-sm hover:shadow-md transition-shadow">
      <div className="flex items-start gap-4">
        <div className="w-12 h-12 rounded-2xl bg-blue-50 flex items-center justify-center text-2xl flex-shrink-0">{item.icon}</div>
        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-3">
            <h3 className="font-black text-slate-900 text-base">{item.title}</h3>
            <span className="text-[11px] whitespace-nowrap rounded-full bg-slate-100 px-2 py-1 font-bold text-slate-500">{item.status}</span>
          </div>
          <p className="text-sm text-slate-500 leading-6 mt-2">{item.description}</p>
        </div>
      </div>
    </div>
  )
}

export default function PowerMessageEngineAdmin() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [access, setAccess] = useState(null)

  const sb = useMemo(() => {
    try {
      return createSB(SUPABASE_URL, SUPABASE_KEY)
    } catch (e) {
      setError(e.message || String(e))
      return null
    }
  }, [])

  useEffect(() => {
    if (!sb) {
      setLoading(false)
      return
    }

    let mounted = true

    ;(async () => {
      setLoading(true)
      setError('')

      try {
        const session = carregarSessaoFechai()
        if (!session) throw new Error('Sessão FECH.AI não encontrada. Entre primeiro no sistema como administrador.')

        const validation = await validarAcessoAdmin(sb, session)
        if (!validation.ok) throw new Error('Usuário autenticado sem permissão administrativa para acessar a PME.')

        if (mounted) setAccess(validation)
      } catch (e) {
        if (mounted) setError(e.message || String(e))
      } finally {
        if (mounted) setLoading(false)
      }
    })()

    return () => { mounted = false }
  }, [sb])

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-950 text-slate-100 flex items-center justify-center p-4">
        <div className="rounded-3xl border border-slate-800 bg-slate-900 px-6 py-5 shadow-2xl">
          Validando acesso administrativo da PME...
        </div>
      </div>
    )
  }

  if (error || !access) {
    return <SecurityScreen title="PME bloqueada" message={error || 'Não foi possível validar o acesso administrativo.'} />
  }

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <div className="bg-slate-950 text-white border-b border-slate-800">
        <div className="max-w-6xl mx-auto px-5 py-5 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <button onClick={voltarAoFechai} className="text-sm text-slate-400 hover:text-white mb-3">← Voltar ao painel</button>
            <p className="text-xs uppercase tracking-[0.22em] text-blue-300 font-black">PME · Power Message Engine</p>
            <h1 className="text-2xl sm:text-3xl font-black mt-2">Central de Mensagens</h1>
            <p className="text-sm text-slate-400 mt-2 max-w-2xl">
              Administração de mensagens, scripts e cadências. Primeiro montamos o motor; depois conectamos no discador e no Acelerador.
            </p>
          </div>
          <div className="rounded-2xl border border-slate-700 bg-slate-900 px-4 py-3">
            <p className="text-[11px] uppercase tracking-widest text-slate-500 font-bold">Acesso validado</p>
            <p className="text-sm font-black text-emerald-300">{access.perfil}</p>
            <p className="text-xs text-slate-500 mt-1">Shell Admin v0.1</p>
          </div>
        </div>
      </div>

      <main className="max-w-6xl mx-auto px-5 py-6 pb-12">
        <section className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-6">
          <div className="lg:col-span-2 rounded-3xl bg-white border border-slate-200 p-5 shadow-sm">
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Estratégia de implantação</p>
            <h2 className="text-xl font-black mt-2">PME nasce no Admin. Corretor consome depois.</h2>
            <p className="text-sm text-slate-500 leading-6 mt-3">
              Esta primeira tela é deliberadamente administrativa e segura. Ela prepara a estrutura de templates, scripts e cadências sem acoplar nada ainda ao fluxo operacional do corretor.
            </p>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mt-5">
              {['Configurar', 'Validar', 'Disponibilizar'].map((step, index) => (
                <div key={step} className="rounded-2xl bg-slate-50 border border-slate-100 p-4">
                  <p className="text-xs font-black text-blue-600">0{index + 1}</p>
                  <p className="font-black text-slate-900 mt-1">{step}</p>
                  <p className="text-xs text-slate-500 mt-1">{index === 0 ? 'Central admin' : index === 1 ? 'Templates e regras' : 'Discador/Acelerador'}</p>
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-3xl bg-blue-600 text-white p-5 shadow-sm">
            <p className="text-xs uppercase tracking-widest text-blue-100 font-black">Anti-labirinto</p>
            <h2 className="text-xl font-black mt-2">Nada de 10 minotauros soltos.</h2>
            <p className="text-sm text-blue-100 leading-6 mt-3">
              O gestor configura a lógica. O corretor verá somente a próxima melhor ação quando integrarmos ao discador.
            </p>
          </div>
        </section>

        <section className="mb-6">
          <div className="flex items-end justify-between gap-3 mb-3">
            <div>
              <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Módulos</p>
              <h2 className="text-lg font-black">Estrutura inicial da Central</h2>
            </div>
            <span className="hidden sm:inline-flex rounded-full bg-amber-50 text-amber-700 border border-amber-100 px-3 py-1 text-xs font-black">visualização administrativa</span>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {MODULES.map((item) => <ModuleCard key={item.title} item={item} />)}
          </div>
        </section>

        <section className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          <div className="rounded-3xl bg-white border border-slate-200 p-5 shadow-sm">
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Primeiros seeds recomendados</p>
            <h2 className="text-lg font-black mt-2">Começar pequeno, mas certo</h2>
            <div className="space-y-2 mt-4">
              {FIRST_SEEDS.map((item) => (
                <div key={item} className="rounded-2xl bg-slate-50 border border-slate-100 px-4 py-3 text-sm font-bold text-slate-700">
                  {item}
                </div>
              ))}
            </div>
          </div>

          <div className="rounded-3xl bg-white border border-slate-200 p-5 shadow-sm">
            <p className="text-xs uppercase tracking-widest text-slate-400 font-black">Travamento de segurança</p>
            <h2 className="text-lg font-black mt-2">O que esta versão não faz</h2>
            <div className="space-y-2 mt-4">
              {SAFE_RULES.map((item) => (
                <div key={item} className="flex items-start gap-3 rounded-2xl bg-emerald-50 border border-emerald-100 px-4 py-3 text-sm text-emerald-900">
                  <span className="font-black">✓</span>
                  <span>{item}</span>
                </div>
              ))}
            </div>
          </div>
        </section>
      </main>
    </div>
  )
}
