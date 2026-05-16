/**
 * MesaCliente/index.jsx
 * Componente principal da Mesa Cliente.
 * 3 abas: Empreendimentos | Fluxo | Histórico
 *
 * Preview segura:
 * - recebe sb/token do App principal;
 * - não cria cliente Supabase paralelo;
 * - mantém tenant isolation nas RPCs do banco.
 */

import { Component, useMemo, useState } from 'react';
import TabEmpreendimentos from './TabEmpreendimentos';
import TabFluxo from './TabFluxo';
import TabHistorico from './TabHistorico';

const TABS = [
  { id: 'emp',   label: 'Empreendimentos', icon: '🏢' },
  { id: 'fluxo', label: 'Fluxo',           icon: '📋' },
  { id: 'hist',  label: 'Histórico',        icon: '📂' },
];

class MesaClienteErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { error: null };
  }

  static getDerivedStateFromError(error) {
    return { error };
  }

  componentDidCatch(error, info) {
    console.error('[MesaCliente] Render error', error, info);
  }

  render() {
    if (this.state.error) {
      return (
        <div className="min-h-screen bg-white flex items-center justify-center p-6">
          <div className="max-w-[520px] w-full rounded-2xl border border-red-200 bg-red-50 p-5 text-center shadow-sm">
            <div className="text-4xl mb-3">⚠️</div>
            <p className="text-[16px] font-semibold text-red-900 mb-1">Erro ao abrir a Mesa Cliente</p>
            <p className="text-[13px] text-red-800 leading-relaxed mb-3">
              A tela encontrou um erro de renderização. A sessão e o banco podem estar ativos, mas algum dado retornou em formato inesperado.
            </p>
            <pre className="text-left text-[11px] bg-white border border-red-100 rounded-xl p-3 overflow-auto max-h-[180px] text-red-900">
              {this.state.error?.message || String(this.state.error)}
            </pre>
            <button
              type="button"
              onClick={() => this.setState({ error: null })}
              className="mt-4 px-4 py-2 rounded-xl bg-red-900 text-white text-[12px] font-semibold"
            >
              Tentar novamente
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

function getRole(corretor) {
  return String(corretor?.role || corretor?.perfil || corretor?.tipo_usuario || '').trim().toLowerCase();
}

function resolveMesaContext({ corretor, empresaId, corretorId, isGestor }) {
  const role = getRole(corretor);
  const gestor = Boolean(
    isGestor ||
    corretor?.is_gestor === true ||
    corretor?.is_admin_local === true ||
    corretor?.is_root === true ||
    ['gestor', 'admin', 'admin_local', 'admin_global', 'root', 'root_admin', 'super_admin'].includes(role)
  );

  return {
    empresaId: empresaId || corretor?.empresa_id || null,
    corretorId: corretorId || corretor?.id || null,
    isGestor: gestor,
  };
}

function MesaClienteInner({
  sb,
  token,
  corretor,
  empresaId,
  corretorId,
  isGestor = false,
  onVoltar,
}) {
  const [tab, setTab] = useState('emp');
  const [empSelecionado, setEmp] = useState(null);

  const ctx = useMemo(
    () => resolveMesaContext({ corretor, empresaId, corretorId, isGestor }),
    [corretor, empresaId, corretorId, isGestor]
  );

  const abrirFluxo = (empreendimento) => {
    setEmp(empreendimento);
    setTab('fluxo');
  };

  const voltarParaEmps = () => {
    setTab('emp');
  };

  if (!sb || !token || !ctx.empresaId || !ctx.corretorId) {
    return (
      <div className="min-h-screen bg-[var(--color-background-primary)] flex flex-col items-center justify-center p-6 text-center gap-3">
        <span className="text-5xl">🔒</span>
        <p className="text-[16px] font-semibold text-[var(--color-text-primary)]">Mesa Cliente indisponível</p>
        <p className="text-[13px] text-[var(--color-text-secondary)] max-w-[360px]">
          Não foi possível identificar sessão, empresa ou corretor. Volte para o início e entre novamente.
        </p>
        {onVoltar && (
          <button onClick={onVoltar} className="mt-2 px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[13px]">
            Voltar
          </button>
        )}
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full min-h-screen bg-[var(--color-background-primary)]">
      <div className="flex items-center justify-between px-3 py-2 border-b border-[var(--color-border-tertiary)] bg-[var(--color-background-secondary)]">
        <div>
          <p className="text-[14px] font-semibold text-[var(--color-text-primary)]">Mesa Cliente</p>
          <p className="text-[11px] text-[var(--color-text-tertiary)]">Preview: unidades extraídas pelo parser</p>
        </div>
        {onVoltar && (
          <button onClick={onVoltar} className="px-3 py-1.5 rounded-xl bg-[var(--color-background-primary)] text-[12px]">
            ← Início
          </button>
        )}
      </div>

      <nav className="flex border-b border-[var(--color-border-tertiary)] bg-[var(--color-background-secondary)] flex-shrink-0">
        {TABS.map(t => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={`flex-1 flex items-center justify-center gap-1.5 px-2 py-3 text-[12px] font-medium
              border-b-2 transition-all
              ${tab === t.id
                ? 'border-[var(--color-text-primary)] text-[var(--color-text-primary)] bg-[var(--color-background-primary)]'
                : 'border-transparent text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-background-tertiary)]'
              }`}
          >
            <span className="text-[15px]">{t.icon}</span>
            <span className="hidden sm:inline">{t.label}</span>
          </button>
        ))}
      </nav>

      <div className="flex-1 overflow-y-auto">
        {tab === 'emp' && (
          <TabEmpreendimentos
            sb={sb}
            token={token}
            empresaId={ctx.empresaId}
            isGestor={ctx.isGestor}
            onAbrirFluxo={abrirFluxo}
          />
        )}

        {tab === 'fluxo' && (
          <TabFluxo
            sb={sb}
            token={token}
            empresaId={ctx.empresaId}
            corretorId={ctx.corretorId}
            isGestor={ctx.isGestor}
            empreendimento={empSelecionado}
            onVoltar={voltarParaEmps}
            onIrParaEmps={() => setTab('emp')}
          />
        )}

        {tab === 'hist' && (
          <TabHistorico
            sb={sb}
            token={token}
            empresaId={ctx.empresaId}
            corretorId={ctx.isGestor ? null : ctx.corretorId}
            isGestor={ctx.isGestor}
          />
        )}
      </div>
    </div>
  );
}

export default function MesaCliente(props) {
  return (
    <MesaClienteErrorBoundary>
      <MesaClienteInner {...props} />
    </MesaClienteErrorBoundary>
  );
}
