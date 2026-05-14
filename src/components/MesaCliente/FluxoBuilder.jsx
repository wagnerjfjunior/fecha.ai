/**
 * FluxoBuilder.jsx
 * Construtor visual de fluxo de pagamento em tiles.
 * Recebe config da empresa e empreendimento via props.
 * Toda lógica de cálculo via useMesaCalc.
 */

import { useState } from 'react';
import { useMesaCalc, fmtBRL, fmtBRLShort } from './hooks/useMesaCalc';

// ─── Paleta por grupo ──────────────────────────────────────────
const GROUP_STYLE = {
  e: { bg: 'bg-[#EEEDFE]', tile: 'bg-[#CECBF6] text-[#26215C]', active: 'ring-[#534AB7]', add: 'border-[#534AB7] text-[#534AB7]', label: 'ENTRADA', total: 'text-[#26215C]' },
  c: { bg: 'bg-[#FBEAF0]', tile: 'bg-[#F4C0D1] text-[#4B1528]', active: 'ring-[#993556]', add: 'border-[#993556] text-[#993556]', label: 'COMPLEMENTOS', total: 'text-[#4B1528]' },
  m: { bg: 'bg-[#E6F1FB]', tile: 'bg-[#B5D4F4] text-[#042C53]', active: 'ring-[#185FA5]', add: 'border-[#185FA5] text-[#185FA5]', label: 'MENSAIS', total: 'text-[#042C53]' },
  a: { bg: 'bg-[#E1F5EE]', tile: 'bg-[#9FE1CB] text-[#04342C]', active: 'ring-[#0F6E56]', add: 'border-[#0F6E56] text-[#0F6E56]', label: 'ANUAIS',   total: 'text-[#04342C]' },
  u: { bg: 'bg-[#FEF9EA]', tile: 'bg-[#FDE68A] text-[#78350F]', active: 'ring-[#D97706]', add: 'border-[#D97706] text-[#D97706]', label: 'CHAVES',   total: 'text-[#78350F]' },
};

const BAR_COLOR = { ok: '#1D9E75', yellow: '#EF9F27', red: '#E24B4A' };

// ─── Tile ──────────────────────────────────────────────────────
function Tile({ g, tile, isSelected, onSelect, onRemove }) {
  const st = GROUP_STYLE[g];
  const noRemove = g === 'e' && tile.id === 'ato';
  const disp = tile.isGroup ? `${tile.qty}× ${fmtBRLShort(tile.value)}` : fmtBRLShort(tile.value);
  return (
    <div
      onClick={() => onSelect(g, tile.id)}
      className={`relative min-h-[70px] min-w-[76px] flex-1 max-w-[160px] rounded-lg p-[9px_10px] cursor-pointer select-none
        transition-transform active:scale-[.97] hover:-translate-y-px
        border-[1.5px] ${isSelected ? `ring-2 ${st.active} border-transparent` : 'border-transparent'}
        ${st.tile}`}
    >
      {!noRemove && (
        <button
          onClick={(e) => { e.stopPropagation(); onRemove(g, tile.id); }}
          className="absolute top-1 right-1 w-5 h-5 rounded-full bg-white/75 hover:bg-white
            flex items-center justify-content-center text-sm leading-none opacity-0 group-hover:opacity-100
            transition-opacity [.tile:hover_&]:opacity-100"
          style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}
          aria-label="remover"
        >×</button>
      )}
      <div>
        <div className="text-[10px] font-semibold opacity-80 uppercase tracking-wide">{tile.label}</div>
        <div className="text-[13px] font-semibold tabular-nums mt-1">{disp}</div>
      </div>
      <div className="text-[9px] opacity-65 mt-auto pt-1">{tile.meta}</div>
    </div>
  );
}

// ─── TileAdd ──────────────────────────────────────────────────
function TileAdd({ g, label, onClick }) {
  const st = GROUP_STYLE[g];
  return (
    <button
      onClick={onClick}
      className={`min-h-[70px] w-[70px] flex-none rounded-lg border border-dashed ${st.add}
        flex flex-col items-center justify-center gap-1 text-[11px] opacity-60 hover:opacity-100
        transition-opacity text-center p-1.5 leading-tight`}
    >
      <span className="text-lg leading-none">+</span>
      <span>{label}</span>
    </button>
  );
}

// ─── GrupoTiles ───────────────────────────────────────────────
function GrupoTiles({ g, tiles, selected, onSelect, onRemove, onAdd, addLabel, showAdd }) {
  const st = GROUP_STYLE[g];
  const titleLabel = g === 'a' && tiles.some(t => t.per === 'semestral') ? 'SEMESTRAIS' : st.label;
  const total = tiles.reduce((s, t) => s + (t.isGroup ? (t.value || 0) * (t.qty || 1) : (t.value || 0)), 0);
  return (
    <div className={`${st.bg} rounded-xl p-[10px_11px]`}>
      <div className="flex justify-between items-center mb-2">
        <span className={`text-[10px] font-bold uppercase tracking-wider ${st.total}`}>{titleLabel}</span>
        <span className={`text-[12px] font-semibold tabular-nums ${st.total}`}>{fmtBRL(total)}</span>
      </div>
      <div className="flex flex-wrap gap-1.5 group">
        {tiles.map(t => (
          <Tile key={t.id} g={g} tile={t}
            isSelected={selected?.g === g && selected?.id === t.id}
            onSelect={onSelect} onRemove={onRemove} />
        ))}
        {showAdd && <TileAdd g={g} label={addLabel} onClick={() => onAdd(g)} />}
      </div>
    </div>
  );
}

// ─── EditorModal ──────────────────────────────────────────────
function EditorModal({ g, tile, onClose, onUpdateField, onUpdatePer }) {
  const rangeFor = (v) => {
    if (!v || v <= 0) return { min: 0, max: 50000, step: 500 };
    if (v < 5000)    return { min: 0, max: 15000, step: 100 };
    if (v < 50000)   return { min: 0, max: 120000, step: 500 };
    if (v < 200000)  return { min: 0, max: 500000, step: 1000 };
    return { min: 0, max: 900000, step: 2000 };
  };
  const r = rangeFor(tile.value);

  return (
    <div
      className="fixed inset-0 bg-black/40 flex items-center justify-center z-[9999] p-4"
      onClick={onClose}
    >
      <div
        className="bg-[var(--color-background-primary)] rounded-2xl p-5 w-full max-w-[380px] relative shadow-2xl"
        onClick={e => e.stopPropagation()}
      >
        <button onClick={onClose}
          className="absolute top-2.5 right-2.5 w-7 h-7 rounded-full bg-[var(--color-background-secondary)]
            flex items-center justify-center text-base text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)]">
          ×
        </button>
        <p className="text-[14px] font-semibold mb-4 pr-8">Editar: {tile.label}</p>

        {tile.isGroup && (
          <div className="flex items-center gap-3 mb-4 pb-4 border-b border-[var(--color-border-tertiary)]">
            <span className="text-[12px] text-[var(--color-text-secondary)] font-medium min-w-[80px]">Quantidade</span>
            <input type="number" min="0" max="120" step="1" value={tile.qty}
              onChange={e => onUpdateField(g, tile.id, 'qty', e.target.value)}
              className="w-16 text-[13px] font-semibold text-right p-1.5 rounded-md border border-[var(--color-border-secondary)] bg-transparent" />
            <span className="text-[12px] text-[var(--color-text-secondary)]">
              parcelas · total: {fmtBRL((tile.value || 0) * (tile.qty || 0))}
            </span>
          </div>
        )}

        <div className="flex items-center gap-2 mb-4 pb-4 border-b border-[var(--color-border-tertiary)]">
          <span className="text-[12px] text-[var(--color-text-secondary)] font-medium min-w-[80px]">
            {tile.isGroup ? 'Valor unit.' : 'Valor'}
          </span>
          <input type="range" min={r.min} max={r.max} step={r.step} value={tile.value}
            onChange={e => onUpdateField(g, tile.id, 'value', e.target.value)}
            className="flex-1 h-8 cursor-pointer accent-[var(--color-text-primary)]" />
          <input type="number" min="0" step={r.step} value={Math.round(tile.value || 0)}
            onChange={e => onUpdateField(g, tile.id, 'value', e.target.value)}
            className="w-[100px] text-[13px] font-semibold text-right p-1.5 rounded-md border border-[var(--color-border-secondary)] bg-transparent tabular-nums" />
        </div>

        <div className="flex items-center gap-2 mb-4 pb-4 border-b border-[var(--color-border-tertiary)]">
          <span className="text-[12px] text-[var(--color-text-secondary)] font-medium min-w-[80px]">Data</span>
          <input type="date"
            value={tile.date || tile.dateStart || ''}
            onChange={e => onUpdateField(g, tile.id, tile.isGroup ? 'dateStart' : 'date', e.target.value)}
            className="flex-1 text-[13px] p-1.5 rounded-md border border-[var(--color-border-secondary)] bg-transparent" />
        </div>

        {g === 'a' && (
          <div className="flex items-center gap-4">
            <span className="text-[12px] text-[var(--color-text-secondary)] font-medium min-w-[80px]">Periodicidade</span>
            <label className="flex items-center gap-1.5 text-[13px] cursor-pointer">
              <input type="radio" name="per" value="anual"
                checked={tile.per !== 'semestral'}
                onChange={() => onUpdatePer(g, tile.id, 'anual')} /> Anual
            </label>
            <label className="flex items-center gap-1.5 text-[13px] cursor-pointer">
              <input type="radio" name="per" value="semestral"
                checked={tile.per === 'semestral'}
                onChange={() => onUpdatePer(g, tile.id, 'semestral')} /> Semestral
            </label>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Financiamento Display ────────────────────────────────────
function FinanciamentoDisplay({ precoTotal, obra, unica }) {
  const fin = precoTotal - obra - unica;
  const finPct = precoTotal > 0 ? ((fin / precoTotal) * 100).toFixed(1) : '0.0';
  return (
    <div className="bg-[#FEF0EB] rounded-xl p-[11px_14px] grid grid-cols-3 gap-4 items-center">
      <div>
        <div className="text-[10px] font-bold uppercase tracking-wider text-[#7C3B20] mb-1">
          Financiamento bancário
        </div>
        <div className="text-[20px] font-bold text-[#4A1B0C] tabular-nums">{fmtBRL(fin)}</div>
        <div className="text-[10px] text-[#A0522D] mt-1">calculado automaticamente · entrega</div>
      </div>
      <div className="text-center">
        <div className="text-[28px] font-bold text-[#4A1B0C] tabular-nums">{finPct}%</div>
        <div className="text-[10px] text-[#A0522D]">do valor total</div>
      </div>
      <div className="text-right text-[11px] text-[#7C3B20] leading-relaxed tabular-nums">
        <div>{fmtBRL(precoTotal)}</div>
        <div>− {fmtBRL(obra + unica)}</div>
        <div className="border-t border-[#E8B8A0] mt-1 pt-1 font-semibold">= {fmtBRL(fin)}</div>
        <div className="mt-2 text-[10px] bg-[rgba(154,68,30,.12)] rounded px-2 py-0.5 inline-block">
          não editável · residual
        </div>
      </div>
    </div>
  );
}

// ─── FluxoBuilder (componente principal) ──────────────────────
export default function FluxoBuilder({
  empreendimento,
  precoTotal = 850000,
  empresaConfig = {},
  tabelaProvisoria = false,
  onSalvar,
  onVoltar,
}) {
  const metaPct = empresaConfig.meta_obra_pct ?? 30;
  const [metaEspecial, setMetaEspecial] = useState(null);
  const [showMetaModal, setShowMetaModal] = useState(false);
  const [showUnica, setShowUnica] = useState(false);
  const [clienteNome, setClienteNome] = useState('');
  const [saving, setSaving] = useState(false);

  const calc = useMesaCalc({ precoTotal, metaPct, metaEspecial });
  const { state, selected, totais, barStatus, surplus, deficit, obraTarget, metaAtual,
    selectTile, closeEditor, updateField, updatePeriodicidade, removeTile, addTile, reset, serializarFluxo } = calc;

  const selectedTile = selected
    ? state[selected.g]?.find(t => t.id === selected.id)
    : null;

  const barColor = BAR_COLOR[barStatus];
  const barWidth = Math.min(100, (totais.obra / precoTotal) * 100);

  const handleSalvar = async () => {
    if (!onSalvar) return;
    setSaving(true);
    try {
      await onSalvar({
        clienteNome,
        valorTotal: precoTotal,
        metaObraPct: metaAtual,
        tabelaProvisoria,
        metaEspecial: metaEspecial !== null,
        fluxoJson: serializarFluxo(),
        totais,
      });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="flex flex-col gap-2 w-full max-w-[760px] mx-auto">

      {/* Header unidade */}
      {empreendimento && (
        <div className="flex justify-between items-center px-3 py-2 bg-[var(--color-background-secondary)] rounded-xl">
          <div>
            <span className="text-[13px] font-semibold">{empreendimento.nome}</span>
            <span className="text-[11px] text-[var(--color-text-tertiary)] ml-2">
              tabela {tabelaProvisoria ? '(de trabalho)' : '(oficial)'}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[15px] font-bold tabular-nums">{fmtBRL(precoTotal)}</span>
            {onVoltar && (
              <button onClick={onVoltar}
                className="text-[11px] px-2 py-1 rounded-lg bg-[var(--color-background-primary)] text-[var(--color-text-tertiary)]">
                ← Voltar
              </button>
            )}
          </div>
        </div>
      )}

      {/* Cliente nome */}
      <div className="flex items-center gap-2 px-3 py-2 bg-[var(--color-background-secondary)] rounded-xl">
        <span className="text-[12px] text-[var(--color-text-secondary)] min-w-[80px]">Cliente</span>
        <input type="text" placeholder="Nome do cliente (opcional)"
          value={clienteNome} onChange={e => setClienteNome(e.target.value)}
          className="flex-1 text-[13px] bg-transparent border-none outline-none" />
      </div>

      {/* Termômetro */}
      <div className="bg-[var(--color-background-primary)] border border-[var(--color-border-tertiary)] rounded-xl p-3">
        <div className="flex justify-between items-start gap-2 mb-2">
          <div>
            <div className="text-[11px] text-[var(--color-text-secondary)]">Pago durante a obra</div>
            <div className="text-[24px] font-semibold tabular-nums leading-tight">
              {totais.obraPct.toFixed(1).replace('.', ',')}%
            </div>
            <div className="text-[11px]" style={{ color: barColor }}>
              {barStatus === 'ok'
                ? `✓ Meta atingida (${metaAtual}%)`
                : `Meta: ${metaAtual}% · faltam ${(metaAtual - totais.obraPct).toFixed(1).replace('.', ',')} pontos`}
            </div>
          </div>
          <div className="text-right">
            <div className="text-[11px] text-[var(--color-text-secondary)]">
              {barStatus === 'ok' ? 'Acima da meta' : 'Falta distribuir'}
            </div>
            <div className="text-[22px] font-semibold tabular-nums leading-tight" style={{ color: barColor }}>
              {barStatus === 'ok' ? `+${fmtBRL(surplus)}` : fmtBRL(deficit)}
            </div>
            <div className="text-[11px] text-[var(--color-text-tertiary)]">
              {barStatus === 'ok' ? (surplus > 200 ? 'reduza para ajustar' : 'exato') : `de ${fmtBRL(obraTarget)}`}
            </div>
          </div>
        </div>
        <div className="text-[10px] text-[var(--color-text-tertiary)] flex justify-between mb-1">
          <span>{fmtBRL(totais.obra)} distribuído</span>
          <span>meta {metaAtual}% · fin. máx. {100 - metaAtual}%</span>
        </div>
        <div className="relative h-3 bg-[var(--color-background-secondary)] rounded-full">
          <div className="h-full rounded-full transition-all duration-200"
            style={{ width: `${barWidth}%`, background: barColor }} />
          <div className="absolute top-[-3px] w-[2px] h-[18px] bg-[var(--color-text-primary)] rounded-sm"
            style={{ left: `${Math.min(98, metaAtual)}%` }} />
        </div>
        {metaEspecial !== null && (
          <div className="mt-2 text-[11px] bg-[var(--color-background-info)] text-[var(--color-text-info)] rounded-lg px-3 py-1.5">
            🔑 Meta especial ativa ({metaEspecial}%) — proposta exige aprovação do gestor
          </div>
        )}
      </div>

      {/* Config empresa */}
      <div className="flex items-center justify-between px-3 py-2 bg-[var(--color-background-secondary)] rounded-xl text-[12px]">
        <span className="text-[var(--color-text-secondary)]">
          {empreendimento?.incorporadora ?? 'Empresa'} · obra mín.{' '}
          <strong>{metaAtual}%</strong> · financiamento máx.{' '}
          <strong>{100 - metaAtual}%</strong>
        </span>
        <button onClick={() => setShowMetaModal(true)}
          className="text-[11px] px-2 py-1 rounded-lg bg-[var(--color-background-primary)] text-[var(--color-text-secondary)]">
          % Pagamento em Obra
        </button>
      </div>

      {/* Modal meta especial */}
      {showMetaModal && (
        <div className="bg-[var(--color-background-info)] rounded-xl p-3">
          <p className="text-[12px] font-medium text-[var(--color-text-info)] mb-2">
            Percentual de pagamento durante a obra para este cliente
          </p>
          <div className="flex items-center gap-2 flex-wrap">
            <span className="text-[12px] text-[var(--color-text-info)]">% durante a obra</span>
            <input type="number" min="5" max="100" step="1"
              defaultValue={metaEspecial ?? metaPct} id="meta-esp-input"
              className="w-16 p-1.5 text-[13px] rounded-md border border-[var(--color-border-secondary)] bg-transparent" />
            <span className="text-[11px] text-[var(--color-text-info)]">(padrão: {metaPct}%)</span>
          </div>
          <div className="flex gap-2 mt-2 justify-end flex-wrap">
            <button onClick={() => setShowMetaModal(false)}
              className="text-[11px] px-3 py-1.5 rounded-lg bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)]">
              Cancelar
            </button>
            {metaEspecial !== null && (
              <button onClick={() => { setMetaEspecial(null); setShowMetaModal(false); }}
                className="text-[11px] px-3 py-1.5 rounded-lg bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)]">
                Remover especial
              </button>
            )}
            <button onClick={() => {
              const v = parseInt(document.getElementById('meta-esp-input').value);
              if (v >= 1 && v <= 100) { setMetaEspecial(v); setShowMetaModal(false); }
            }} className="text-[11px] px-3 py-1.5 rounded-lg bg-[var(--color-text-info)] text-white">
              Aplicar (exige aprovação)
            </button>
          </div>
        </div>
      )}

      {/* Row 1: Entrada (30%) + Complementos (70%) */}
      <div className="grid grid-cols-[3fr_7fr] sm:grid-cols-1 gap-2">
        <GrupoTiles g="e" tiles={state.e} selected={selected}
          onSelect={selectTile} onRemove={removeTile} onAdd={addTile}
          addLabel="" showAdd={false} />
        <GrupoTiles g="c" tiles={state.c} selected={selected}
          onSelect={selectTile} onRemove={removeTile} onAdd={addTile}
          addLabel="compl." showAdd={true} />
      </div>

      {/* Row 2: Mensais (40%) + Anuais (60%) */}
      <div className="grid grid-cols-[4fr_6fr] sm:grid-cols-1 gap-2">
        <GrupoTiles g="m" tiles={state.m} selected={selected}
          onSelect={selectTile} onRemove={removeTile} onAdd={addTile}
          addLabel="mensal" showAdd={state.m.length === 0} />
        <GrupoTiles g="a" tiles={state.a} selected={selected}
          onSelect={selectTile} onRemove={removeTile} onAdd={addTile}
          addLabel="reforço" showAdd={state.a.length === 0} />
      </div>

      {/* Parcela única (avançado) */}
      {showUnica && (
        <GrupoTiles g="u" tiles={state.u} selected={selected}
          onSelect={selectTile} onRemove={removeTile} onAdd={addTile}
          addLabel="chaves" showAdd={true} />
      )}

      {/* Financiamento */}
      <FinanciamentoDisplay precoTotal={precoTotal} obra={totais.obra} unica={totais.vU} />

      {/* Alertas */}
      <div className="flex flex-col gap-1.5">
        {barStatus !== 'ok' && (
          <div className="bg-[var(--color-background-danger)] text-[var(--color-text-danger)] rounded-xl px-3 py-2 text-[12px]">
            ! Distribua {fmtBRL(deficit)} nos grupos acima para atingir {metaAtual}%.
          </div>
        )}
        {barStatus === 'ok' && (
          <div className="bg-[var(--color-background-success)] text-[var(--color-text-success)] rounded-xl px-3 py-2 text-[12px]">
            ✓ Soma validada. Financiamento: {fmtBRL(totais.fin)} ({totais.finPct.toFixed(1)}% do total)
          </div>
        )}
        {tabelaProvisoria && (
          <div className="bg-[var(--color-background-warning)] text-[var(--color-text-warning)] rounded-xl px-3 py-2 text-[12px]">
            ⚠ Tabela de trabalho — aguardando tabela oficial do mês
          </div>
        )}
      </div>

      {/* Ações */}
      <div className="flex gap-2">
        <button onClick={reset}
          className="flex-1 text-[12px] py-2 rounded-xl bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)]">
          ↺ Padrão
        </button>
        <button onClick={() => setShowUnica(v => !v)}
          className="flex-1 text-[12px] py-2 rounded-xl bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)]">
          {showUnica ? '− Parcela única' : '+ Parcela única'}
        </button>
        <button onClick={handleSalvar} disabled={saving}
          className={`flex-1 text-[12px] py-2 rounded-xl font-medium
            ${saving ? 'opacity-60' : ''}
            bg-[var(--color-text-primary)] text-[var(--color-background-primary)]`}>
          {saving ? 'Salvando…' : 'Salvar e enviar ↗'}
        </button>
      </div>

      {/* Editor modal */}
      {selectedTile && (
        <EditorModal
          g={selected.g}
          tile={selectedTile}
          onClose={closeEditor}
          onUpdateField={updateField}
          onUpdatePer={updatePeriodicidade}
        />
      )}
    </div>
  );
}
