import { useState, useEffect } from 'react'

const EDGE_URL = 'https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario'

const C = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#f1f5f9',
  muted: '#94a3b8', accent: '#2563eb', green: '#10b981', red: '#ef4444',
}

const AMBIENTE_ATUAL = typeof window !== 'undefined' ? window.location.origin : ''

function normalizarTextoErro(valor) {
  if (!valor) return ''
  if (typeof valor === 'string') return valor
  if (typeof valor === 'object') {
    return valor.error || valor.message || valor.msg || valor.details || JSON.stringify(valor)
  }
  return String(valor)
}

async function lerRespostaApi(response) {
  const texto = await response.text().catch(() => '')
  if (!texto) return {}
  try {
    return JSON.parse(texto)
  } catch {
    return { message: texto }
  }
}

function erroAmigavelCriacaoUsuario(error, response, data) {
  const status = response?.status
  const bruto = normalizarTextoErro(data) || normalizarTextoErro(error)
  const texto = bruto.toLowerCase()

  if (error?.name === 'TypeError' && texto.includes('failed to fetch')) {
    return [
      'Não consegui conectar com o serviço de criação de usuários.',
      '',
      'Isso normalmente acontece quando o ambiente atual ainda não está autorizado pela função do Supabase.',
      `Ambiente atual: ${AMBIENTE_ATUAL || 'não identificado'}`,
      '',
      'Tente novamente pela URL oficial de produção. Se estiver em um preview da Vercel, será necessário liberar esse domínio no CORS da Edge Function criar-usuario.'
    ].join('\n')
  }

  if (status === 401 || status === 403 || texto.includes('unauthorized') || texto.includes('forbidden') || texto.includes('jwt')) {
    return 'Seu acesso não foi autorizado para criar usuários. Saia, entre novamente e confirme se está usando um perfil Admin Local ou Gestor.'
  }

  if (status === 409 || texto.includes('already') || texto.includes('duplicate') || texto.includes('registered') || texto.includes('exists') || texto.includes('já existe') || texto.includes('ja existe')) {
    return 'Este e-mail já está cadastrado no sistema. Verifique se o usuário já existe antes de criar novamente.'
  }

  if (status === 400 || texto.includes('invalid') || texto.includes('required')) {
    return 'Não foi possível criar o usuário porque algum dado informado está inválido. Confira nome, e-mail, senha, tipo de usuário e time.'
  }

  if (status >= 500) {
    return 'O serviço de criação de usuários respondeu com erro interno. Tente novamente em alguns instantes. Se persistir, acione o suporte técnico.'
  }

  if (bruto) {
    return `Não foi possível criar o usuário. Detalhe técnico: ${bruto}`
  }

  return 'Não foi possível criar o usuário agora. Tente novamente ou acione o suporte técnico.'
}

function Campo({ label, type = 'text', value, onChange, placeholder, disabled }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6, fontWeight: 500 }}>{label}</label>
      <input type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder}
        disabled={disabled}
        style={{ width: '100%', padding: '12px 14px', borderRadius: 10, fontSize: 15,
          background: C.bg, border: '1px solid ' + C.border, color: C.text, outline: 'none',
          boxSizing: 'border-box', opacity: disabled ? 0.5 : 1 }} />
    </div>
  )
}

export default function CriarUsuarioForm({ session, corretor, sb, token, onUsuarioCriado, onCancelar }) {
  const [nome, setNome] = useState('')
  const [email, setEmail] = useState('')
  const [senha, setSenha] = useState('')
  const [confirma, setConfirma] = useState('')
  const [isGestor, setIsGestor] = useState(false)
  const [isAdmin, setIsAdmin] = useState(false)
  const [timeId, setTimeId] = useState('')
  const [times, setTimes] = useState([])
  const [carregando, setCarregando] = useState(false)
  const [carregandoTimes, setCarregandoTimes] = useState(false)
  const [erro, setErro] = useState('')
  const [sucesso, setSucesso] = useState('')
  const isAdminLocal =
    corretor?.is_admin_local === true ||
    corretor?.role === 'admin_local' ||
    corretor?.role === 'admin_global'

  useEffect(() => {
    (async () => {
      setCarregandoTimes(true)
      try {
        const res = await sb.rpc('get_meus_times', {}, token)
        const lista = (res && res.times) || []
        setTimes(lista)
        if (lista.length === 1) setTimeId(lista[0].id)
      } catch(e) { console.error(e) }
      setCarregandoTimes(false)
    })()
  }, [sb, token])

  const tipoLabel = isAdmin ? 'admin local' : isGestor ? 'gestor' : 'corretor'

  async function handleCriar() {
    setErro(''); setSucesso('')
    if (!nome.trim() || !email.trim() || !senha || !confirma) { setErro('Preencha nome, e-mail, senha e confirmação para continuar.'); return }
    if (senha.length < 8) { setErro('A senha precisa ter pelo menos 8 caracteres.'); return }
    if (senha !== confirma) { setErro('As senhas não conferem. Digite novamente a confirmação.'); return }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) { setErro('Digite um e-mail válido para continuar.'); return }
    if (!isAdmin && !isGestor && !timeId) { setErro('Escolha o time que este corretor fará parte.'); return }
    setCarregando(true)
    try {
      const r = await fetch(EDGE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + session.access_token },
        body: JSON.stringify({
          nome: nome.trim(), email: email.trim().toLowerCase(), password: senha,
          is_gestor_novo: isGestor && !isAdmin,
          is_admin_local_novo: isAdmin,
          time_id: (isAdmin || isGestor) ? null : (timeId || null),
        }),
      })
      const data = await lerRespostaApi(r)
      if (!r.ok || data.error) {
        setErro(erroAmigavelCriacaoUsuario(null, r, data))
        return
      }
      setSucesso('✅ ' + nome + ' criado com sucesso!')
      setNome(''); setEmail(''); setSenha(''); setConfirma('')
      setIsGestor(false); setIsAdmin(false); setTimeId('')
      if (onUsuarioCriado) onUsuarioCriado(data)
    } catch(e) { setErro(erroAmigavelCriacaoUsuario(e)) }
    finally { setCarregando(false) }
  }

  return (
    <div style={{ minHeight: '100vh', background: C.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16 }}>
      <div style={{ background: C.card, borderRadius: 20, padding: 24, width: '100%', maxWidth: 420, border: '1px solid ' + C.border }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 24 }}>
          <button onClick={onCancelar} style={{ background: 'none', border: 'none', color: C.muted, fontSize: 20, cursor: 'pointer' }}>←</button>
          <div>
            <h2 style={{ color: C.text, fontWeight: 700, fontSize: 18, margin: 0 }}>Novo usuário</h2>
            <p style={{ color: C.muted, fontSize: 12, margin: '2px 0 0' }}>{tipoLabel.charAt(0).toUpperCase() + tipoLabel.slice(1)}</p>
          </div>
        </div>
        {isAdminLocal && (
          <div style={{ marginBottom: 20 }}>
            <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 8, fontWeight: 500 }}>Tipo de usuário</label>
            <div style={{ display: 'flex', gap: 8 }}>
              {[{id:'corretor',label:'🎯 Corretor',active:!isGestor&&!isAdmin},{id:'gestor',label:'👔 Gestor',active:isGestor&&!isAdmin},{id:'admin',label:'🔑 Admin',active:isAdmin}].map(t => (
                <button key={t.id} onClick={() => { setIsAdmin(t.id==='admin'); setIsGestor(t.id==='gestor'); if(t.id!=='corretor') setTimeId(''); }}
                  style={{ flex:1, padding:'10px 8px', borderRadius:10, fontSize:13, fontWeight:600, cursor:'pointer', border:'none',
                    background: t.active ? C.accent : C.bg, color: t.active ? 'white' : C.muted }}>
                  {t.label}
                </button>
              ))}
            </div>
          </div>
        )}
        <Campo label="Nome completo" value={nome} onChange={setNome} placeholder="Ex: Maria Silva" />
        <Campo label="E-mail" type="email" value={email} onChange={setEmail} placeholder="maria@empresa.com.br" />
        <Campo label="Senha" type="password" value={senha} onChange={setSenha} placeholder="Mínimo 8 caracteres" />
        <Campo label="Confirmar senha" type="password" value={confirma} onChange={setConfirma} placeholder="Repita a senha" />
        {!isAdmin && !isGestor && (
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6, fontWeight: 500 }}>Time</label>
            {carregandoTimes
              ? <div style={{ color: C.muted, fontSize: 13 }}>Carregando times...</div>
              : times.length === 0
                ? <div style={{ color: C.red, fontSize: 13 }}>Nenhum time disponível. Crie um time primeiro.</div>
                : (
                  <select value={timeId} onChange={e => setTimeId(e.target.value)}
                    style={{ width:'100%', padding:'12px 14px', borderRadius:10, fontSize:15,
                      background:C.bg, border:'1px solid ' + (timeId ? C.border : C.red+'88'),
                      color: timeId ? C.text : C.muted, outline:'none', boxSizing:'border-box' }}>
                    <option value="">Selecione o time...</option>
                    {times.map(t => <option key={t.id} value={t.id}>{t.nome} ({t.total_corretores} corretor{t.total_corretores!==1?'es':''})</option>)}
                  </select>
                )
            }
          </div>
        )}
        {!isAdminLocal && !isAdmin && (
          <div style={{ marginBottom: 16, display: 'flex', alignItems: 'center', gap: 10 }}>
            <input type="checkbox" id="isGestor" checked={isGestor}
              onChange={e => { setIsGestor(e.target.checked); if(e.target.checked) setTimeId(''); }}
              style={{ width: 16, height: 16, cursor: 'pointer' }} />
            <label htmlFor="isGestor" style={{ color: C.muted, fontSize: 14, cursor: 'pointer' }}>
              Este usuário é um gestor/gerente
            </label>
          </div>
        )}
        {erro    && <div style={{ color:C.red,   fontSize:13, marginBottom:14, padding:'8px 12px', background:C.red+'18',   borderRadius:8, whiteSpace:'pre-line', lineHeight:1.45 }}>{erro}</div>}
        {sucesso && <div style={{ color:C.green, fontSize:13, marginBottom:14, padding:'8px 12px', background:C.green+'18', borderRadius:8 }}>{sucesso}</div>}
        <button onClick={handleCriar} disabled={carregando}
          style={{ width:'100%', padding:14, borderRadius:12, fontSize:16, fontWeight:700, border:'none',
            cursor:'pointer', background: carregando ? C.border : C.accent, color: carregando ? C.muted : 'white' }}>
          {carregando ? 'Criando...' : 'Criar ' + tipoLabel}
        </button>
      </div>
    </div>
  )
}