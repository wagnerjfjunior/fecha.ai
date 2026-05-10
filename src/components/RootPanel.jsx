import { useEffect, useState } from 'react'
import TenantProvisioningRoot from './TenantProvisioningRoot'

const C = {
  bg: '#0f172a',
  card: '#1e293b',
  card2: '#111827',
  border: '#334155',
  text: '#f1f5f9',
  muted: '#94a3b8',
  accent: '#2563eb',
  green: '#10b981',
  red: '#ef4444',
  amber: '#f59e0b',
  emerald: '#047857',
}

function statusStyle(status) {
  if (status === 'ACTIVE') return { label: 'Ativo', color: C.green, bg: C.green + '18' }
  if (status === 'PENDING_ADMIN') return { label: 'Sem admin', color: C.amber, bg: C.amber + '18' }
  if (status === 'INCOMPLETE') return { label: 'Incompleto', color: C.amber, bg: C.amber + '18' }
  if (status === 'SUSPENDED') return { label: 'Suspenso', color: C.red, bg: C.red + '18' }
  return { label: status || 'Indefinido', color: C.muted, bg: C.border }
}

function formatDate(value) {
  if (!value) return '—'
  try {
    return new Intl.DateTimeFormat('pt-BR', { dateStyle: 'short', timeStyle: 'short' }).format(new Date(value))
  } catch (_) {
    return value
  }
}

function money(value) {
  const n = Number(value || 0)
  return new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(n)
}

function TabButton({ active, children, onClick }) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: '10px 14px',
        borderRadius: 999,
        border: '1px solid ' + (active ? C.accent : C.border),
        background: active ? C.accent : C.card,
        color: active ? 'white' : C.text,
        fontWeight: 800,
        cursor: 'pointer',
      }}
    >
      {children}
    </button>
  )
}

function StatCard({ label, value, hint }) {
  return (
    <div style={{ background: C.card2, border: '1px solid ' + C.border, borderRadius: 14, padding: 14 }}>
      <p style={{ margin: 0, color: C.muted, fontSize: 12, fontWeight: 700 }}>{label}</p>
      <p style={{ margin: '4px 0 0', color: C.text, fontSize: 22, fontWeight: 900 }}>{value}</p>
      {hint && <p style={{ margin: '4px 0 0', color: C.muted, fontSize: 11 }}>{hint}</p>}
    </div>
  )
}

function ActionButton({ children, danger, disabled, onClick }) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      style={{
        border: '1px solid ' + (danger ? C.red : C.green),
        color: danger ? C.red : C.green,
        background: (danger ? C.red : C.green) + '12',
        borderRadius: 9,
        padding: '7px 9px',
        cursor: disabled ? 'not-allowed' : 'pointer',
        fontWeight: 800,
        fontSize: 12,
        opacity: disabled ? 0.55 : 1,
        whiteSpace: 'nowrap',
      }}
    >
      {children}
    </button>
  )
}

function PrimaryButton({ children, disabled, onClick }) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      style={{
        border: 'none',
        color: 'white',
        background: disabled ? C.border : C.accent,
        borderRadius: 10,
        padding: '10px 12px',
        cursor: disabled ? 'not-allowed' : 'pointer',
        fontWeight: 900,
        fontSize: 13,
      }}
    >
      {children}
    </button>
  )
}

function EmpresasTab({ empresas, loading, erro, onReload, onToggleTenant, actionLoading }) {
  const total = empresas.length
  const ativos = empresas.filter(e => e.provisioning_status === 'ACTIVE').length
  const pendentes = empresas.filter(e => e.provisioning_status === 'PENDING_ADMIN').length
  const usuarios = empresas.reduce((acc, e) => acc + Number(e?.totais?.usuarios || 0), 0)

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: 12, marginBottom: 16 }}>
        <StatCard label="Tenants" value={total} />
        <StatCard label="Ativos" value={ativos} />
        <StatCard label="Sem admin" value={pendentes} />
        <StatCard label="Usuários" value={usuarios} />
      </div>

      <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 18 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <h2 style={{ margin: 0, fontSize: 18, fontWeight: 900 }}>Empresas / Tenants</h2>
          <button onClick={onReload} disabled={loading} style={{ border: '1px solid ' + C.border, background: C.card2, color: C.text, borderRadius: 10, padding: '9px 12px', cursor: 'pointer', fontWeight: 800 }}>
            {loading ? 'Atualizando...' : 'Atualizar'}
          </button>
        </div>

        {erro && <div style={{ color: C.red, background: C.red + '18', padding: 12, borderRadius: 10, marginBottom: 12 }}>{erro}</div>}

        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
            <thead>
              <tr style={{ color: C.muted, textAlign: 'left', borderBottom: '1px solid ' + C.border }}>
                <th style={{ padding: 10 }}>Empresa</th>
                <th style={{ padding: 10 }}>Status</th>
                <th style={{ padding: 10 }}>Plano</th>
                <th style={{ padding: 10 }}>Usuários</th>
                <th style={{ padding: 10 }}>Admins</th>
                <th style={{ padding: 10 }}>Trial</th>
                <th style={{ padding: 10 }}>Ações</th>
              </tr>
            </thead>
            <tbody>
              {empresas.map(e => {
                const s = statusStyle(e.provisioning_status)
                const disabled = actionLoading === e.empresa_id
                return (
                  <tr key={e.empresa_id} style={{ borderBottom: '1px solid ' + C.border }}>
                    <td style={{ padding: 10 }}>
                      <strong>{e.nome}</strong>
                      <div style={{ color: C.muted, fontSize: 12 }}>{e.slug}</div>
                    </td>
                    <td style={{ padding: 10 }}>
                      <span style={{ color: s.color, background: s.bg, padding: '5px 8px', borderRadius: 999, fontWeight: 800, fontSize: 12 }}>
                        {s.label}
                      </span>
                    </td>
                    <td style={{ padding: 10 }}>{e?.plano?.nome || '—'}</td>
                    <td style={{ padding: 10 }}>{e?.totais?.usuarios || 0}</td>
                    <td style={{ padding: 10 }}>{e?.totais?.admins_locais || 0}</td>
                    <td style={{ padding: 10 }}>{formatDate(e.trial_ate)}</td>
                    <td style={{ padding: 10 }}>
                      {e.ativa === false || e.provisioning_status === 'SUSPENDED' ? (
                        <ActionButton disabled={disabled} onClick={() => onToggleTenant(e, true)}>
                          Reativar
                        </ActionButton>
                      ) : (
                        <ActionButton danger disabled={disabled} onClick={() => onToggleTenant(e, false)}>
                          Suspender
                        </ActionButton>
                      )}
                    </td>
                  </tr>
                )
              })}
              {!loading && empresas.length === 0 && (
                <tr><td colSpan={7} style={{ padding: 18, color: C.muted, textAlign: 'center' }}>Nenhuma empresa encontrada.</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  )
}

function AdminsTab({ empresas }) {
  const admins = empresas.flatMap(e => (e.admins_locais || []).map(a => ({ ...a, empresa_nome: e.nome, empresa_slug: e.slug })))

  return (
    <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 18 }}>
      <h2 style={{ margin: '0 0 12px', fontSize: 18, fontWeight: 900 }}>Admins locais</h2>
      <div style={{ overflowX: 'auto' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontSize: 13 }}>
          <thead>
            <tr style={{ color: C.muted, textAlign: 'left', borderBottom: '1px solid ' + C.border }}>
              <th style={{ padding: 10 }}>Nome</th>
              <th style={{ padding: 10 }}>Email</th>
              <th style={{ padding: 10 }}>Empresa</th>
              <th style={{ padding: 10 }}>Ativo</th>
              <th style={{ padding: 10 }}>Trocar senha</th>
              <th style={{ padding: 10 }}>Criado em</th>
            </tr>
          </thead>
          <tbody>
            {admins.map(a => (
              <tr key={a.corretor_id} style={{ borderBottom: '1px solid ' + C.border }}>
                <td style={{ padding: 10 }}>{a.nome || '—'}</td>
                <td style={{ padding: 10 }}>{a.email || '—'}</td>
                <td style={{ padding: 10 }}>{a.empresa_nome}</td>
                <td style={{ padding: 10 }}>{a.ativo ? 'Sim' : 'Não'}</td>
                <td style={{ padding: 10 }}>{a.must_change_password ? 'Sim' : 'Não'}</td>
                <td style={{ padding: 10 }}>{formatDate(a.created_at)}</td>
              </tr>
            ))}
            {admins.length === 0 && (
              <tr><td colSpan={6} style={{ padding: 18, color: C.muted, textAlign: 'center' }}>Nenhum admin local encontrado.</td></tr>
            )}
          </tbody>
        </table>
      </div>
    </section>
  )
}

function BillingTab({ empresas, planos, billingState, onBillingChange, onSimularPlano, onAplicarPlano }) {
  const tenantsAtivos = empresas.filter(e => e.ativa !== false && e.provisioning_status !== 'SUSPENDED')
  const tenantsOperacionais = tenantsAtivos.filter(e => e.provisioning_status !== 'PENDING_ADMIN')
  const mrrContratado = tenantsAtivos.reduce((acc, e) => acc + Number(e?.plano?.preco_mensal || 0), 0)
  const mrrOperacional = tenantsOperacionais.reduce((acc, e) => acc + Number(e?.plano?.preco_mensal || 0), 0)
  const trialsAtivos = empresas.filter(e => e.trial_ate && new Date(e.trial_ate) >= new Date()).length
  const semAdmin = empresas.filter(e => e.provisioning_status === 'PENDING_ADMIN').length
  const suspensos = empresas.filter(e => e.provisioning_status === 'SUSPENDED' || e.ativa === false).length

  const porPlano = empresas.reduce((acc, e) => {
    const key = e?.plano?.nome || 'Sem plano'
    acc[key] = (acc[key] || 0) + 1
    return acc
  }, {})

  const empresaSelecionada = empresas.find(e => e.empresa_id === billingState.empresaId)
  const planosDisponiveis = planos.filter(p => p.ativo !== false && p.id !== empresaSelecionada?.plano?.id)
  const simulacao = billingState.simulacao
  const canSimular = Boolean(billingState.empresaId && billingState.novoPlanoId && !billingState.loading)
  const canAplicar = Boolean(simulacao && !billingState.loading)

  return (
    <div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5, minmax(0, 1fr))', gap: 12, marginBottom: 16 }}>
        <StatCard label="MRR contratado" value={money(mrrContratado)} hint="Empresas ativas, inclusive sem admin" />
        <StatCard label="MRR operacional" value={money(mrrOperacional)} hint="Exclui tenants sem admin" />
        <StatCard label="Trials ativos" value={trialsAtivos} />
        <StatCard label="Sem admin" value={semAdmin} />
        <StatCard label="Suspensos" value={suspensos} />
      </div>

      <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 18, marginBottom: 16 }}>
        <h2 style={{ margin: '0 0 10px', fontSize: 18, fontWeight: 900 }}>Troca de plano com pró-rata</h2>
        <p style={{ color: C.muted, lineHeight: 1.6, margin: '0 0 16px' }}>
          Simule a diferença proporcional do ciclo mensal atual antes de aplicar a troca. A cobrança real ainda não é enviada ao gateway; esta ação registra governança e audit trail.
        </p>

        {billingState.erro && <div style={{ color: C.red, background: C.red + '18', padding: 12, borderRadius: 10, marginBottom: 12 }}>{billingState.erro}</div>}
        {billingState.sucesso && <div style={{ color: C.green, background: C.green + '18', padding: 12, borderRadius: 10, marginBottom: 12 }}>{billingState.sucesso}</div>}

        <div style={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr auto auto', gap: 12, alignItems: 'end' }}>
          <div>
            <label style={{ display: 'block', color: C.muted, fontSize: 12, fontWeight: 800, marginBottom: 6 }}>Empresa</label>
            <select
              value={billingState.empresaId}
              onChange={e => onBillingChange({ empresaId: e.target.value, novoPlanoId: '', simulacao: null, erro: '', sucesso: '' })}
              style={{ width: '100%', padding: '11px 12px', borderRadius: 10, border: '1px solid ' + C.border, background: C.card2, color: C.text }}
            >
              <option value="">Selecione...</option>
              {empresas.map(e => <option key={e.empresa_id} value={e.empresa_id}>{e.nome} · {e?.plano?.nome || 'Sem plano'}</option>)}
            </select>
          </div>

          <div>
            <label style={{ display: 'block', color: C.muted, fontSize: 12, fontWeight: 800, marginBottom: 6 }}>Novo plano</label>
            <select
              value={billingState.novoPlanoId}
              onChange={e => onBillingChange({ novoPlanoId: e.target.value, simulacao: null, erro: '', sucesso: '' })}
              disabled={!empresaSelecionada}
              style={{ width: '100%', padding: '11px 12px', borderRadius: 10, border: '1px solid ' + C.border, background: C.card2, color: C.text, opacity: empresaSelecionada ? 1 : 0.55 }}
            >
              <option value="">Selecione...</option>
              {planosDisponiveis.map(p => <option key={p.id} value={p.id}>{p.nome} · {money(p.preco_mensal)}</option>)}
            </select>
          </div>

          <PrimaryButton disabled={!canSimular} onClick={onSimularPlano}>
            {billingState.loading === 'simular' ? 'Simulando...' : 'Simular'}
          </PrimaryButton>

          <PrimaryButton disabled={!canAplicar} onClick={onAplicarPlano}>
            {billingState.loading === 'aplicar' ? 'Aplicando...' : 'Aplicar troca'}
          </PrimaryButton>
        </div>

        {empresaSelecionada && (
          <div style={{ marginTop: 12, color: C.muted, fontSize: 13 }}>
            Plano atual: <strong style={{ color: C.text }}>{empresaSelecionada?.plano?.nome}</strong> · {money(empresaSelecionada?.plano?.preco_mensal)}
          </div>
        )}

        {simulacao && (
          <div style={{ marginTop: 16, display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: 12 }}>
            <StatCard label="Crédito atual" value={money(simulacao?.prorata?.credito_plano_atual)} />
            <StatCard label="Débito novo" value={money(simulacao?.prorata?.debito_plano_novo)} />
            <StatCard label="Ajuste líquido" value={money(simulacao?.prorata?.ajuste_liquido)} hint={simulacao?.prorata?.tipo} />
            <StatCard label="Fator restante" value={`${Number(simulacao?.periodo?.fator_restante || 0).toFixed(2)}x`} />
          </div>
        )}
      </section>

      <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 18, marginBottom: 16 }}>
        <h2 style={{ margin: '0 0 10px', fontSize: 18, fontWeight: 900 }}>Billing readiness</h2>
        <p style={{ color: C.muted, lineHeight: 1.6, margin: 0 }}>
          Esta tela prepara a futura integração com meios de pagamento. O FECH.AI ainda não cobra automaticamente: os valores abaixo são projeções por plano e status do tenant.
        </p>
      </section>

      <section style={{ background: C.card, border: '1px solid ' + C.border, borderRadius: 18, padding: 18 }}>
        <h2 style={{ margin: '0 0 12px', fontSize: 18, fontWeight: 900 }}>Distribuição por plano</h2>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, minmax(0, 1fr))', gap: 12 }}>
          {Object.entries(porPlano).map(([plano, total]) => (
            <div key={plano} style={{ background: C.card2, border: '1px solid ' + C.border, borderRadius: 14, padding: 14 }}>
              <p style={{ color: C.text, fontWeight: 900, margin: 0 }}>{plano}</p>
              <p style={{ color: C.muted, margin: '6px 0 0' }}>{total} tenant(s)</p>
            </div>
          ))}
        </div>
      </section>
    </div>
  )
}

export default function RootPanel({ session, sb, token, onCancelar, onProvisionado }) {
  const [aba, setAba] = useState('empresas')
  const [empresas, setEmpresas] = useState([])
  const [planos, setPlanos] = useState([])
  const [loading, setLoading] = useState(false)
  const [erro, setErro] = useState('')
  const [actionLoading, setActionLoading] = useState('')
  const [billingState, setBillingState] = useState({ empresaId: '', novoPlanoId: '', simulacao: null, loading: '', erro: '', sucesso: '' })

  function updateBillingState(patch) {
    setBillingState(prev => ({ ...prev, ...patch }))
  }

  async function carregarEmpresas() {
    setLoading(true)
    setErro('')
    try {
      const data = await sb.rpc('listar_empresas_root', {}, token)
      setEmpresas(Array.isArray(data) ? data : [])
    } catch (e) {
      setErro(e.message || String(e))
    } finally {
      setLoading(false)
    }
  }

  async function carregarPlanos() {
    try {
      const data = await sb.query(
        'planos',
        'select=id,nome,slug,preco_mensal,max_corretores,max_times,max_leads_mes,ativo&ativo=eq.true&order=preco_mensal.asc',
        token
      )
      setPlanos(Array.isArray(data) ? data : [])
    } catch (e) {
      setErro(e.message || String(e))
    }
  }

  async function toggleTenant(empresa, ativa) {
    const verbo = ativa ? 'reativar' : 'suspender'
    const ok = window.confirm(`Confirma ${verbo} o tenant ${empresa.nome}?`)
    if (!ok) return

    setActionLoading(empresa.empresa_id)
    setErro('')
    try {
      await sb.rpc('atualizar_status_empresa_root', {
        p_empresa_id: empresa.empresa_id,
        p_ativa: ativa,
        p_motivo: ativa ? 'Reativação manual pelo Painel Root' : 'Suspensão manual pelo Painel Root',
      }, token)
      await carregarEmpresas()
    } catch (e) {
      setErro(e.message || String(e))
    } finally {
      setActionLoading('')
    }
  }

  async function simularTrocaPlano() {
    updateBillingState({ loading: 'simular', erro: '', sucesso: '', simulacao: null })
    try {
      const data = await sb.rpc('simular_troca_plano_empresa_root', {
        p_empresa_id: billingState.empresaId,
        p_novo_plano_id: billingState.novoPlanoId,
      }, token)
      updateBillingState({ simulacao: data, sucesso: 'Simulação de pró-rata calculada.' })
    } catch (e) {
      updateBillingState({ erro: e.message || String(e) })
    } finally {
      updateBillingState({ loading: '' })
    }
  }

  async function aplicarTrocaPlano() {
    const empresa = empresas.find(e => e.empresa_id === billingState.empresaId)
    const novoPlano = planos.find(p => p.id === billingState.novoPlanoId)
    const ajuste = billingState?.simulacao?.prorata?.ajuste_liquido
    const ok = window.confirm(`Confirma trocar ${empresa?.nome || 'empresa'} para ${novoPlano?.nome || 'novo plano'}? Ajuste pró-rata: ${money(ajuste)}.`)
    if (!ok) return

    updateBillingState({ loading: 'aplicar', erro: '', sucesso: '' })
    try {
      await sb.rpc('alterar_plano_empresa_root', {
        p_empresa_id: billingState.empresaId,
        p_novo_plano_id: billingState.novoPlanoId,
        p_motivo: 'Troca manual pelo Painel Root Billing',
      }, token)
      await carregarEmpresas()
      updateBillingState({ empresaId: '', novoPlanoId: '', simulacao: null, sucesso: 'Plano alterado com sucesso e audit trail registrado.' })
    } catch (e) {
      updateBillingState({ erro: e.message || String(e) })
    } finally {
      updateBillingState({ loading: '' })
    }
  }

  useEffect(() => {
    carregarEmpresas()
    carregarPlanos()
  }, [])

  const handleProvisionado = async (payload) => {
    await carregarEmpresas()
    if (onProvisionado) onProvisionado(payload)
  }

  return (
    <div style={{ minHeight: '100vh', background: C.bg, color: C.text, padding: 16 }}>
      <div style={{ maxWidth: 1180, margin: '0 auto' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, marginBottom: 16 }}>
          <div>
            <p style={{ color: C.muted, fontSize: 12, fontWeight: 800, letterSpacing: 0.8, textTransform: 'uppercase', margin: 0 }}>Root Admin · Control Plane</p>
            <h1 style={{ margin: '4px 0 0', fontSize: 26, fontWeight: 900 }}>Painel Root</h1>
          </div>
          <button onClick={onCancelar} style={{ background: C.card, border: '1px solid ' + C.border, color: C.text, borderRadius: 10, padding: '10px 14px', cursor: 'pointer', fontWeight: 800 }}>
            ← Voltar
          </button>
        </div>

        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', marginBottom: 16 }}>
          <TabButton active={aba === 'empresas'} onClick={() => setAba('empresas')}>Empresas</TabButton>
          <TabButton active={aba === 'admins'} onClick={() => setAba('admins')}>Admins Locais</TabButton>
          <TabButton active={aba === 'billing'} onClick={() => setAba('billing')}>Billing</TabButton>
          <TabButton active={aba === 'provisionamento'} onClick={() => setAba('provisionamento')}>Provisionamento</TabButton>
        </div>

        {aba === 'empresas' && <EmpresasTab empresas={empresas} loading={loading} erro={erro} onReload={carregarEmpresas} onToggleTenant={toggleTenant} actionLoading={actionLoading} />}
        {aba === 'admins' && <AdminsTab empresas={empresas} />}
        {aba === 'billing' && (
          <BillingTab
            empresas={empresas}
            planos={planos}
            billingState={billingState}
            onBillingChange={updateBillingState}
            onSimularPlano={simularTrocaPlano}
            onAplicarPlano={aplicarTrocaPlano}
          />
        )}
        {aba === 'provisionamento' && (
          <TenantProvisioningRoot
            session={session}
            sb={sb}
            token={token}
            onProvisionado={handleProvisionado}
            onCancelar={() => setAba('empresas')}
          />
        )}
      </div>
    </div>
  )
}
