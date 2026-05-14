/**
 * MesaCliente/index.jsx
 * Componente principal da Mesa Cliente.
 * 3 abas: Empreendimentos | Fluxo | Histórico
 */

import { useState } from 'react';
import TabEmpreendimentos from './TabEmpreendimentos';
import TabFluxo from './TabFluxo';
import TabHistorico from './TabHistorico';

const TABS = [
  { id: 'emp',   label: 'Empreendimentos', icon: '🏢' },
  { id: 'fluxo', label: 'Fluxo',           icon: '🌋' },
  { id: 'hist',  label: 'Histórico',        icon: '📂' },
];

export default function MesaCliente({ empresaId, corretorId, isGestor = false }) {
  const [tab, setTab] = useState('emp');
  const [empSelecionado, setEmp] = useState(null);

  const abrirFluxo = (e) => { setEmp(e); setTab('fluxo'); };
  const voltarParaEmps = () => setTab('emp');

  return (
    <div className="flex flex-col h-full bg-[var(--color-background-primary)]">
      <nav className="flex border-b border-[var(--color-border-tertiary)] bg-[var(--color-background-secondary)] flex-shrink-0">
        {TABS.map(t => (
          <button key={t.id} onClick={() => setTab(t.id)}
            className={`flex-1 flex items-center justify-center gap-1.5 px-2 py-3 text-[12px] font-medium border-b-2 transition-all ${tab === t.id ? 'border-[var(--color-text-primary)] text-[var(--color-text-primary)] bg-[var(--color-background-primary)]' : 'border-transparent text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-background-tertiary)]'}`}>
            <span className="text-[15px]">{t.icon}</span>
            <span className="hidden sm:inline">{t.label}</span>
          </button>
        ))}
      </nav>
      <div className="flex-1 overflow-y-auto">
        {tab === 'emp' && <TabEmpreendimentos empresaId={empresaId} isGestor={isGestor} onAbrirFluxo={abrirFluxo} />}
        {tab === 'fluxo' && <TabFluxo empresaId={empresaId} corretorId={corretorId} isGestor={isGestor} empreendimento={empSelecionado} onVoltar={voltarParaEmps} onIrParaEmps={() => setTab('emp')} />}
        {tab === 'hist' && <TabHistorico empresaId={empresaId} corretorId={isGestor ? null : corretorId} isGestor={isGestor} />}
      </div>
    </div>
  );
}
