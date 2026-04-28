import { useState, useEffect } from 'react'

const EDGE_URL = 'https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario'

const C = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#f1f5f9',
  muted: '#94a3b8', accent: '#2563eb', green: '#10b981', red: '#ef4444',
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
  const isAdminLocal = corretor && corretor.is_admin_local === true

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
    if (!nome.trim() || !email.trim() || !senha || !confirma) { setErro('Preencha todos os campos.'); return }
    if (senha.length < 8) { setErro('Senha mínimo 8 caracteres.'); return }
    if (senha !== confirma) { setErro('Senhas não coincidem.'); return }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) { setErro('E-mail inválido.'); return }
    if (!isAdmin && !isGestor && !timeId) { setErro('Selecione o time do corretor.'); return }
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
      const data = await r.json()
      if (!r.ok || data.error) { setErro(data.error || 'Erro ao criar usuário.'); return }
      setSucesso('✅ ' + nome + ' criado com sucesso!')
      setNome(''); setEmail(''); setSenha(''); setConfirma('')
      setIsGestor(false); setIsAdmin(false); setTimeId('')
      if (onUsuarioCriado) onUsuarioCriado(data)
    } catch(e) { setErro('Erro de conexão: ' + e.message) }
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
        {erro    && <div style={{ color:C.red,   fontSize:13, marginBottom:14, padding:'8px 12px', background:C.red+'18',   borderRadius:8 }}>{erro}</div>}
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