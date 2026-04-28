import { useState, useEffect, useCallback } from 'react'

const C = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#f1f5f9',
  muted: '#94a3b8', accent: '#2563eb', green: '#10b981', red: '#ef4444',
  yellow: '#f59e0b', purple: '#8b5cf6',
}

function Badge({ label, color }) {
  return (
    <span style={{ background: color + '22', color, border: '1px solid ' + color + '44',
      borderRadius: 6, padding: '2px 8px', fontSize: 11, fontWeight: 600 }}>
      {label}
    </span>
  )
}

function ModalResetSenha({ corretor, onClose, onConfirm }) {
  const [senha, setSenha] = useState('')
  const [confirma, setConfirma] = useState('')
  const [erro, setErro] = useState('')
  const [ok, setOk] = useState('')
  const [carregando, setCarregando] = useState(false)

  async function salvar() {
    setErro('')
    if (senha.length < 8) { setErro('Mínimo 8 caracteres'); return }
    if (senha !== confirma) { setErro('Senhas não coincidem'); return }
    setCarregando(true)
    const result = await onConfirm(corretor, senha)
    setCarregando(false)
    if (result && result.error) setErro(result.error)
    else { setOk('✅ Senha redefinida!'); setTimeout(onClose, 1500) }
  }

  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: '#00000088',
      display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: 16 }}>
      <div onClick={e => e.stopPropagation()} style={{ background: C.card, borderRadius: 20,
        padding: 24, width: '100%', maxWidth: 380, border: '1px solid ' + C.border }}>
        <div style={{ fontWeight: 700, fontSize: 17, color: C.text, marginBottom: 6 }}>Redefinir senha</div>
        <div style={{ color: C.muted, fontSize: 13, marginBottom: 20 }}>{corretor.nome} ({corretor.email})</div>
        {['Nova senha', 'Confirmar senha'].map((label, i) => (
          <div key={i} style={{ marginBottom: 14 }}>
            <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6 }}>{label}</label>
            <input type="password" value={i === 0 ? senha : confirma}
              onChange={e => i === 0 ? setSenha(e.target.value) : setConfirma(e.target.value)}
              placeholder="••••••••"
              style={{ width: '100%', padding: '12px 14px', borderRadius: 10, fontSize: 15,
                background: C.bg, border: '1px solid ' + C.border, color: C.text,
                outline: 'none', boxSizing: 'border-box' }} />
          </div>
        ))}
        {erro && <div style={{ color: C.red, fontSize: 13, marginBottom: 12 }}>{erro}</div>}
        {ok && <div style={{ color: C.green, fontSize: 13, marginBottom: 12 }}>{ok}</div>}
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={onClose} style={{ flex: 1, padding: 12, borderRadius: 10, fontSize: 14,
            background: 'transparent', border: '1px solid ' + C.border, color: C.muted, cursor: 'pointer' }}>
            Cancelar
          </button>
          <button onClick={salvar} disabled={carregando} style={{ flex: 1, padding: 12, borderRadius: 10,
            fontSize: 14, background: C.accent, border: 'none', color: 'white', fontWeight: 600,
            cursor: 'pointer', opacity: carregando ? 0.6 : 1 }}>
            {carregando ? 'Salvando...' : 'Salvar'}
          </button>
        </div>
      </div>
    </div>
  )
}

function ModalCriarTime({ gestores, onClose, onConfirm }) {
  const [nome, setNome] = useState('')
  const [gestorId, setGestorId] = useState(gestores[0] && gestores[0].id || '')
  const [erro, setErro] = useState('')
  const [carregando, setCarregando] = useState(false)

  async function salvar() {
    if (!nome.trim()) { setErro('Nome obrigatório'); return }
    setCarregando(true)
    const result = await onConfirm(nome.trim(), gestorId || null)
    setCarregando(false)
    if (result && result.error) setErro(result.error)
    else onClose()
  }

  return (
    <div onClick={onClose} style={{ position: 'fixed', inset: 0, background: '#00000088',
      display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000, padding: 16 }}>
      <div onClick={e => e.stopPropagation()} style={{ background: C.card, borderRadius: 20,
        padding: 24, width: '100%', maxWidth: 380, border: '1px solid ' + C.border }}>
        <div style={{ fontWeight: 700, fontSize: 17, color: C.text, marginBottom: 20 }}>Novo Time</div>
        <div style={{ marginBottom: 14 }}>
          <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6 }}>Nome do time</label>
          <input type="text" value={nome} onChange={e => setNome(e.target.value)}
            placeholder="Ex: Time Alphaville" autoFocus
            style={{ width: '100%', padding: '12px 14px', borderRadius: 10, fontSize: 15,
              background: C.bg, border: '1px solid ' + C.border, color: C.text,
              outline: 'none', boxSizing: 'border-box' }} />
        </div>
        {gestores.length > 1 && (
          <div style={{ marginBottom: 14 }}>
            <label style={{ display: 'block', fontSize: 12, color: C.muted, marginBottom: 6 }}>Gestor responsável</label>
            <select value={gestorId} onChange={e => setGestorId(e.target.value)}
              style={{ width: '100%', padding: '12px 14px', borderRadius: 10, fontSize: 15,
                background: C.bg, border: '1px solid ' + C.border, color: C.text,
                outline: 'none', boxSizing: 'border-box' }}>
              {gestores.map(g => <option key={g.id} value={g.id}>{g.nome}</option>)}
            </select>
          </div>
        )}
        {erro && <div style={{ color: C.red, fontSize: 13, marginBottom: 12 }}>{erro}</div>}
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={onClose} style={{ flex: 1, padding: 12, borderRadius: 10, fontSize: 14,
            background: 'transparent', border: '1px solid ' + C.border, color: C.muted, cursor: 'pointer' }}>
            Cancelar
          </button>
          <button onClick={salvar} disabled={carregando} style={{ flex: 1, padding: 12, borderRadius: 10,
            fontSize: 14, background: C.accent, border: 'none', color: 'white', fontWeight: 600,
            cursor: 'pointer', opacity: carregando ? 0.6 : 1 }}>
            {carregando ? 'Criando...' : 'Criar time'}
          </button>
        </div>
      </div>
    </div>
  )
}

function CorretorCard({ corretor, onResetSenha, onMoverTime, onToggleApto, times }) {
  const [expandido, setExpandido] = useState(false)
  const [carregando, setCarregando] = useState(false)
  return (
    <div style={{ background: C.bg, borderRadius: 12, border: '1px solid ' + C.border, overflow: 'hidden' }}>
      <div onClick={() => setExpandido(e => !e)}
        style={{ padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12, cursor: 'pointer' }}>
        <div style={{ width: 38, height: 38, borderRadius: '50%', background: corretor.ativo ? C.accent : C.border,
          display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 15, fontWeight: 700,
          color: 'white', flexShrink: 0 }}>
          {(corretor.apelido || corretor.nome || '?')[0].toUpperCase()}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ color: C.text, fontWeight: 600, fontSize: 14, whiteSpace: 'nowrap',
            overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {corretor.apelido || corretor.nome}
          </div>
          <div style={{ color: C.muted, fontSize: 12 }}>{corretor.email}</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4 }}>
          {corretor.lote_aberto && <Badge label={String(corretor.feedbacks_lote || 0) + '/25'} color={C.yellow} />}
          {!corretor.ativo && <Badge label="Inativo" color={C.red} />}
          {!corretor.apto_para_receber && corretor.ativo && <Badge label="Pausado" color={C.yellow} />}
          {corretor.is_gestor && <Badge label="Gestor" color={C.purple} />}
        </div>
        <span style={{ color: C.muted, fontSize: 12 }}>{expandido ? '▲' : '▼'}</span>
      </div>
      {expandido && (
        <div style={{ borderTop: '1px solid ' + C.border, padding: 16, display: 'flex', flexDirection: 'column', gap: 10 }}>
          {corretor.telefone_prof && <div style={{ fontSize: 13, color: C.muted }}>📞 {corretor.telefone_prof}</div>}
          {corretor.time_nome && (
            <div style={{ fontSize: 13, color: C.muted }}>
              {'👥 Time: '}<span style={{ color: C.text }}>{corretor.time_nome}</span>
            </div>
          )}
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, marginTop: 4 }}>
            <button disabled={carregando}
              onClick={async () => { setCarregando(true); await onToggleApto(corretor.id, !corretor.apto_para_receber); setCarregando(false); }}
              style={{ padding: '7px 14px', borderRadius: 8, fontSize: 12, fontWeight: 600, border: 'none',
                cursor: 'pointer', background: corretor.apto_para_receber ? '#f59e0b22' : '#10b98122',
                color: corretor.apto_para_receber ? C.yellow : C.green }}>
              {corretor.apto_para_receber ? '⏸ Pausar leads' : '▶ Reativar leads'}
            </button>
            {times && times.length > 1 && (
              <select onChange={e => { if (e.target.value) onMoverTime(corretor.id, e.target.value); e.target.value = ''; }}
                style={{ padding: '7px 10px', borderRadius: 8, fontSize: 12, background: C.card,
                  color: C.muted, border: '1px solid ' + C.border, cursor: 'pointer' }}>
                <option value="">{'↔ Mover de time'}</option>
                {times.filter(t => t.id !== corretor.time_id).map(t => (
                  <option key={t.id} value={t.id}>{t.nome}</option>
                ))}
              </select>
            )}
            <button onClick={() => onResetSenha(corretor)}
              style={{ padding: '7px 14px', borderRadius: 8, fontSize: 12, fontWeight: 600,
                border: '1px solid ' + C.border, cursor: 'pointer', background: 'transparent', color: C.muted }}>
              {'🔑 Redefinir senha'}
            </button>
          </div>
        </div>
      )}
    </div>
  )
}

function TimeCard({ time, corretores, onResetSenha, onMoverTime, onToggleApto, todos_times }) {
  const [expandido, setExpandido] = useState(true)
  const membros = corretores.filter(c => c.time_id === time.id)
  return (
    <div style={{ background: C.card, borderRadius: 16, border: '1px solid ' + C.border, overflow: 'hidden' }}>
      <div onClick={() => setExpandido(e => !e)}
        style={{ padding: '14px 18px', display: 'flex', alignItems: 'center', gap: 12,
          cursor: 'pointer', background: C.accent + '18' }}>
        <div style={{ width: 36, height: 36, borderRadius: 10, background: C.accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16 }}>👥</div>
        <div style={{ flex: 1 }}>
          <div style={{ color: C.text, fontWeight: 700, fontSize: 15 }}>{time.nome}</div>
          <div style={{ color: C.muted, fontSize: 12 }}>{'Gestor: ' + time.gestor_nome + ' · ' + membros.length + ' corretor' + (membros.length !== 1 ? 'es' : '')}</div>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <Badge label={String(membros.filter(c => c.lote_aberto).length) + ' ativos'} color={C.green} />
        </div>
        <span style={{ color: C.muted }}>{expandido ? '▲' : '▼'}</span>
      </div>
      {expandido && (
        <div style={{ padding: '12px 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {membros.length === 0
            ? <div style={{ textAlign: 'center', color: C.muted, padding: '20px 0', fontSize: 13 }}>Nenhum corretor neste time ainda.</div>
            : membros.map(c => (
              <CorretorCard key={c.id} corretor={c} onResetSenha={onResetSenha}
                onMoverTime={onMoverTime} onToggleApto={onToggleApto} times={todos_times} />
            ))
          }
        </div>
      )}
    </div>
  )
}

export default function TimesTab({ sb, token, session, corretor }) {
  const [times, setTimes] = useState([])
  const [corretores, setCorretores] = useState([])
  const [carregando, setCarregando] = useState(true)
  const [corretorReset, setCorretorReset] = useState(null)
  const [mostrarCriarTime, setMostrarCriarTime] = useState(false)
  const [msg, setMsg] = useState('')
  const isAdminLocal = corretor && corretor.is_admin_local === true

  const carregar = useCallback(async () => {
    setCarregando(true)
    try {
      const [r1, r2] = await Promise.all([
        sb.rpc('get_meus_times', {}, token),
        sb.rpc('get_corretores_time', {}, token),
      ])
      setTimes((r1 && r1.times) || [])
      setCorretores((r2 && r2.corretores) || [])
    } catch (err) { console.error('TimesTab:', err) }
    setCarregando(false)
  }, [sb, token])

  useEffect(() => { carregar() }, [carregar])

  async function handleResetSenha(alvo, novaSenha) {
    const r = await fetch('https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + (session && session.access_token || token) },
      body: JSON.stringify({ action: 'reset_password', user_id: alvo.user_id, password: novaSenha })
    })
    return r.json()
  }

  async function handleMoverTime(corretor_id, time_id) {
    await sb.rpc('atualizar_time_corretor', { p_corretor_id: corretor_id, p_time_id: time_id }, token)
    setMsg('✅ Corretor movido!'); setTimeout(() => setMsg(''), 2000); carregar()
  }

  async function handleToggleApto(corretor_id, novoApto) {
    await sb.rpc('atualizar_status_corretor', { p_corretor_id: corretor_id, p_apto_para_receber: novoApto }, token)
    carregar()
  }

  async function handleCriarTime(nome, gestor_id) {
    const r = await sb.rpc('criar_time', { p_nome: nome, p_gestor_id: gestor_id || null }, token)
    if (r && !r.error) { setMsg('✅ Time criado!'); setTimeout(() => setMsg(''), 2000); carregar() }
    return r
  }

  const gestores = corretores.filter(c => c.is_gestor)
  const semTime = corretores.filter(c => !c.time_id && !c.is_admin_local && !c.is_gestor)

  if (carregando) return <div style={{ padding: 24, textAlign: 'center', color: C.muted }}>Carregando times...</div>

  return (
    <div style={{ padding: 16, maxWidth: 600, margin: '0 auto', paddingBottom: 100 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ color: C.text, fontWeight: 700, fontSize: 20, margin: 0 }}>Times</h2>
          <p style={{ color: C.muted, fontSize: 13, margin: '4px 0 0' }}>
            {times.length + ' time' + (times.length !== 1 ? 's' : '') + ' · ' + corretores.length + ' corretor' + (corretores.length !== 1 ? 'es' : '')}
          </p>
        </div>
        {isAdminLocal && (
          <button onClick={() => setMostrarCriarTime(true)}
            style={{ background: C.accent, color: 'white', border: 'none', borderRadius: 12,
              padding: '10px 18px', fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>
            + Novo time
          </button>
        )}
      </div>
      {msg && (
        <div style={{ background: C.green + '22', color: C.green, border: '1px solid ' + C.green + '44',
          borderRadius: 10, padding: '10px 16px', marginBottom: 16, fontSize: 14 }}>{msg}</div>
      )}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        {times.map(time => (
          <TimeCard key={time.id} time={time} corretores={corretores}
            onResetSenha={setCorretorReset} onMoverTime={handleMoverTime}
            onToggleApto={handleToggleApto} todos_times={times} />
        ))}
      </div>
      {semTime.length > 0 && (
        <div style={{ marginTop: 24 }}>
          <div style={{ color: C.yellow, fontSize: 13, fontWeight: 600, marginBottom: 10 }}>
            {'⚠️ Sem time atribuído (' + semTime.length + ')'}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {semTime.map(c => (
              <CorretorCard key={c.id} corretor={c} onResetSenha={setCorretorReset}
                onMoverTime={handleMoverTime} onToggleApto={handleToggleApto} times={times} />
            ))}
          </div>
        </div>
      )}
      {corretorReset && <ModalResetSenha corretor={corretorReset} onClose={() => setCorretorReset(null)} onConfirm={handleResetSenha} />}
      {mostrarCriarTime && <ModalCriarTime gestores={gestores} onClose={() => setMostrarCriarTime(false)} onConfirm={handleCriarTime} />}
    </div>
  )
}