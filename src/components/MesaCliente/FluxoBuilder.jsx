/**
 * FluxoBuilder.jsx
 * Construtor visual de fluxo de pagamento em tiles.
 * Recebe config da empresa e empreendimento via props.
 * Toda lógica oficial de persistência/validação fica nas RPCs; este componente cuida da UX.
 */

import { useState } from 'react';
import { useMesaCalc, fmtBRL } from './hooks/useMesaCalc';

const GROUP_STYLE = {
  e: { bg: 'bg-[#EEEDFE]', tile: 'bg-[#CECBF6] text-[#26215C]', active: 'ring-[#534AB7]', add: 'border-[#534AB7] text-[#534AB7]', label: 'ENTRADA', total: 'text-[#26215C]', story: 'Aceitar a sugestão da tabela ou ajustar o melhor valor de entrada para o cliente?' },
  c: { bg: 'bg-[#FBEAF0]', tile: 'bg-[#F4C0D1] text-[#4B1528]', active: 'ring-[#993556]', add: 'border-[#993556] text-[#993556]', label: 'COMPLEMENTOS', total: 'text-[#4B1528]', story: 'Vamos organizar os complementos com valores e datas que façam sentido para a negociação.' },
  m: { bg: 'bg-[#E6F1FB]', tile: 'bg-[#B5D4F4] text-[#042C53]', active: 'ring-[#185FA5]', add: 'border-[#185FA5] text-[#185FA5]', label: 'MENSAIS', total: 'text-[#042C53]', story: 'Aqui começam as parcelas mensais durante a obra. O cliente pode simular com calma.' },
  a: { bg: 'bg-[#E1F5EE]', tile: 'bg-[#9FE1CB] text-[#04342C]', active: 'ring-[#0F6E56]', add: 'border-[#0F6E56] text-[#0F6E56]', label: 'ANUAIS', total: 'text-[#04342C]', story: 'Os reforços podem acompanhar férias, 13º, PLR ou outro momento financeiro do cliente.' },
  u: { bg: 'bg-[#FEF9EA]', tile: 'bg-[#FDE68A] text-[#78350F]', active: 'ring-[#D97706]', add: 'border-[#D97706] text-[#D97706]', label: 'CHAVES', total: 'text-[#78350F]', story: 'Aqui o cliente já está perto de receber o novo lar. Esta etapa também pode ajudar a amortizar o saldo.' },
};

const BAR_COLOR = { ok: '#1D9E75', yellow: '#EF9F27', red: '#E24B4A' };

function Tile({ g, tile, isSelected, onSelect, onRemove }) {
  const st = GROUP_STYLE[g];
  const noRemove = g === 'e' && tile.id === 'ato';
  const disp = tile.isGroup ? `${tile.qty}× ${fmtBRL(tile.value)}` : fmtBRL(tile.value);
  return (
    <div onClick={() => onSelect(g, tile.id)} className={`relative min-h-[86px] min-w-[116px] flex-1 max-w-[190px] rounded-xl p-3 cursor-pointer select-none transition-transform active:scale-[.97] hover:-translate-y-px border-[1.5px] ${isSelected ? `ring-2 ${st.active} border-transparent` : 'border-transparent'} ${st.tile}`}>
      {!noRemove && <button onClick={(e) => { e.stopPropagation(); onRemove(g, tile.id); }} className="absolute top-1.5 right-1.5 w-6 h-6 rounded-full bg-white/80 hover:bg-white text-base leading-none" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }} aria-label="remover">×</button>}
      <div className="pr-5"><div className="text-[12px] font-semibold opacity-80 uppercase tracking-wide">{tile.label}</div><div className="text-[16px] font-bold tabular-nums mt-1 leading-tight">{disp}</div></div>
      <div className="text-[11px] opacity-70 mt-2">{tile.meta}</div>
    </div>
  );
}

function TileAdd({ g, label, onClick }) {
  const st = GROUP_STYLE[g];
  return <button onClick={onClick} className={`min-h-[86px] w-[92px] flex-none rounded-xl border border-dashed ${st.add} flex flex-col items-center justify-center gap-1 text-[13px] opacity-70 hover:opacity-100 transition-opacity text-center p-2 leading-tight`}><span className="text-xl leading-none">+</span><span>{label}</span></button>;
}

function GrupoTiles({ g, tiles, selected, onSelect, onRemove, onAdd, addLabel, showAdd }) {
  const st = GROUP_STYLE[g];
  const titleLabel = g === 'a' && tiles.some(t => t.per === 'semestral') ? 'SEMESTRAIS' : st.label;
  const total = tiles.reduce((s, t) => s + (t.isGroup ? (t.value || 0) * (t.qty || 1) : (t.value || 0)), 0);
  return (
    <div className={`${st.bg} rounded-2xl p-4`}>
      <div className="flex flex-wrap justify-between items-start gap-2 mb-3"><div><span className={`text-[13px] font-bold uppercase tracking-wider ${st.total}`}>{titleLabel}</span><p className={`text-[12px] mt-1 leading-relaxed ${st.total}`}>{st.story}</p></div><span className={`text-[15px] font-bold tabular-nums ${st.total}`}>{fmtBRL(total)}</span></div>
      <div className="flex flex-wrap gap-2 group">{tiles.map(t => <Tile key={t.id} g={g} tile={t} isSelected={selected?.g === g && selected?.id === t.id} onSelect={onSelect} onRemove={onRemove} />)}{showAdd && <TileAdd g={g} label={addLabel} onClick={() => onAdd(g)} />}</div>
    </div>
  );
}

function EditorModal({ g, tile, onClose, onUpdateField, onUpdatePer }) {
  const [draft, setDraft] = useState(() => ({ value: Math.round(tile.value || 0), qty: tile.qty || 0, date: tile.date || tile.dateStart || '', per: tile.per || 'anual' }));
  const rangeFor = (v) => {
    if (!v || v <= 0) return { min: 0, max: 50000, step: 500 };
    if (v < 5000) return { min: 0, max: 15000, step: 100 };
    if (v < 50000) return { min: 0, max: 120000, step: 500 };
    if (v < 200000) return { min: 0, max: 500000, step: 1000 };
    return { min: 0, max: 900000, step: 2000 };
  };
  const r = rangeFor(tile.value);
  const updateDraft = (field, value) => setDraft(prev => ({ ...prev, [field]: value }));
  const confirm = () => {
    if (tile.isGroup) onUpdateField(g, tile.id, 'qty', draft.qty);
    onUpdateField(g, tile.id, 'value', draft.value);
    onUpdateField(g, tile.id, tile.isGroup ? 'dateStart' : 'date', draft.date);
    if (g === 'a') onUpdatePer(g, tile.id, draft.per);
    onClose();
  };
  return (
    <div className="fixed inset-0 bg-black/55 backdrop-blur-[2px] flex items-center justify-center z-[9999] p-4">
      <div className="bg-white text-slate-900 rounded-3xl p-5 w-full max-w-[460px] relative shadow-2xl border border-slate-200" onClick={e => e.stopPropagation()}>
        <button onClick={onClose} className="absolute top-3 right-3 w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-lg text-slate-700 hover:text-slate-950">×</button>
        <p className="text-[18px] font-bold mb-1 pr-8">Ajustar {tile.label}</p><p className="text-[13px] text-slate-500 mb-5">Altere valor, quantidade ou data e confirme para aplicar no fluxo.</p>
        {tile.isGroup && <div className="grid gap-2 mb-4 pb-4 border-b border-slate-200"><span className="text-[13px] text-slate-600 font-medium">Quantidade de parcelas</span><div className="flex items-center gap-3"><input type="number" min="0" max="120" step="1" value={draft.qty} onChange={e => updateDraft('qty', e.target.value)} className="w-24 text-[16px] font-semibold text-right p-3 rounded-xl border border-slate-300 bg-white" /><span className="text-[13px] text-slate-600">total estimado: {fmtBRL((Number(draft.value) || 0) * (Number(draft.qty) || 0))}</span></div></div>}
        <div className="grid gap-2 mb-4 pb-4 border-b border-slate-200"><span className="text-[13px] text-slate-600 font-medium">{tile.isGroup ? 'Valor de cada parcela' : 'Valor'}</span><input type="range" min={r.min} max={r.max} step={r.step} value={draft.value} onChange={e => updateDraft('value', e.target.value)} className="w-full h-9 cursor-pointer accent-[#0F6E56]" /><input type="number" min="0" step={r.step} value={Math.round(draft.value || 0)} onChange={e => updateDraft('value', e.target.value)} className="w-full text-[18px] font-bold text-right p-3 rounded-xl border border-slate-300 bg-white tabular-nums" /></div>
        <div className="grid gap-2 mb-4 pb-4 border-b border-slate-200"><span className="text-[13px] text-slate-600 font-medium">Data prevista</span><input type="date" value={draft.date || ''} onChange={e => updateDraft('date', e.target.value)} className="w-full text-[15px] p-3 rounded-xl border border-slate-300 bg-white" /></div>
        {g === 'a' && <div className="flex items-center gap-4 mb-5"><span className="text-[13px] text-slate-600 font-medium">Periodicidade</span><label className="flex items-center gap-2 text-[14px] cursor-pointer"><input type="radio" name="per" value="anual" checked={draft.per !== 'semestral'} onChange={() => updateDraft('per', 'anual')} /> Anual</label><label className="flex items-center gap-2 text-[14px] cursor-pointer"><input type="radio" name="per" value="semestral" checked={draft.per === 'semestral'} onChange={() => updateDraft('per', 'semestral')} /> Semestral</label></div>}
        <div className="flex gap-2 justify-end"><button onClick={onClose} className="px-4 py-3 rounded-xl bg-slate-100 text-slate-700 text-[14px]">Cancelar</button><button onClick={confirm} className="px-5 py-3 rounded-xl bg-[#0F6E56] text-white text-[14px] font-bold">Confirmar ajuste</button></div>
      </div>
    </div>
  );
}

function FinanciamentoDisplay({ precoTotal, pagamentoFluxo }) {
  const fin = Math.max(0, precoTotal - pagamentoFluxo);
  const finPct = precoTotal > 0 ? ((fin / precoTotal) * 100).toFixed(1).replace('.', ',') : '0,0';
  return <div className="bg-[#FEF0EB] rounded-2xl p-4 grid grid-cols-1 sm:grid-cols-3 gap-4 items-center"><div className="sm:col-span-2"><div className="text-[13px] font-bold uppercase tracking-wider text-[#7C3B20] mb-1">Financiamento bancário</div><p className="text-[13px] text-[#7C3B20] leading-relaxed">Nossa assessoria pode apoiar a busca pela melhor taxa. O saldo financiado é recalculado automaticamente conforme o cliente ajusta entrada, mensais, reforços e chaves.</p></div><div className="text-left sm:text-right"><div className="text-[24px] font-bold text-[#4A1B0C] tabular-nums">{fmtBRL(fin)}</div><div className="text-[12px] text-[#A0522D]">{finPct}% do valor total</div></div></div>;
}

export default function FluxoBuilder({ empreendimento, precoTotal = 850000, empresaConfig = {}, tabelaProvisoria = false, initialFluxo = null, fluxoOrigem = 'padrao', onSalvar, onVoltar }) {
  const metaPct = empresaConfig.meta_obra_pct ?? 30;
  const [metaEspecial, setMetaEspecial] = useState(null);
  const [showMetaModal, setShowMetaModal] = useState(false);
  const [showUnica, setShowUnica] = useState(() => Boolean(initialFluxo?.u?.length));
  const [clienteNome, setClienteNome] = useState('');
  const [saving, setSaving] = useState(false);
  const calc = useMesaCalc({ precoTotal, metaPct, metaEspecial, initialFluxo, resetKey: `${precoTotal}-${fluxoOrigem}` });
  const { state, selected, totais, barStatus, surplus, deficit, metaAtual, selectTile, closeEditor, updateField, updatePeriodicidade, removeTile, addTile, reset, serializarFluxo } = calc;
  const selectedTile = selected ? state[selected.g]?.find(t => t.id === selected.id) : null;
  const barColor = BAR_COLOR[barStatus];
  const barWidth = Math.min(100, (totais.pagamentoPct / Math.max(metaAtual, 1)) * Math.min(metaAtual, 100));
  const pctText = totais.pagamentoPct.toFixed(1).replace('.', ',');
  const handleSalvar = async () => { if (!onSalvar) return; setSaving(true); try { await onSalvar({ clienteNome, valorTotal: precoTotal, metaObraPct: metaAtual, tabelaProvisoria, metaEspecial: metaEspecial !== null, fluxoJson: serializarFluxo(), totais }); } finally { setSaving(false); } };

  return (
    <div className="flex flex-col gap-3 w-full max-w-[980px] mx-auto">
      {empreendimento && <div className="flex flex-wrap justify-between items-center gap-3 px-4 py-3 bg-[var(--color-background-secondary)] rounded-2xl"><div><span className="text-[16px] font-bold">{empreendimento.nome}</span><span className="text-[12px] text-[var(--color-text-tertiary)] ml-2">{tabelaProvisoria ? 'tabela de trabalho' : 'tabela oficial'}{fluxoOrigem === 'parser' ? ' · valores sugeridos da tabela' : ' · fluxo inicial sugerido'}</span></div><div className="flex items-center gap-2"><span className="text-[18px] font-bold tabular-nums">{fmtBRL(precoTotal)}</span>{onVoltar && <button onClick={onVoltar} className="text-[13px] px-3 py-2 rounded-xl bg-[var(--color-background-primary)] text-[var(--color-text-secondary)]">← Trocar unidade</button>}</div></div>}
      <div className="rounded-2xl bg-[#E1F5EE] text-[#04342C] p-4"><h2 className="text-[22px] font-bold leading-tight">Agora vamos montar o fluxo de pagamento</h2><p className="text-[14px] leading-relaxed mt-2">O fluxo atual é uma sugestão da tabela. Brinque com entrada, parcelas, reforços e chaves até encontrar uma condição confortável para o cliente — sem perder a referência técnica da negociação.</p><p className="text-[13px] leading-relaxed mt-2 opacity-90">Depois da compra, o cliente acompanha a obra pelo portal. E, quando fizer sentido, podemos ajudar a amortizar saldo ou organizar o financiamento com assessoria.</p></div>
      <div className="flex items-center gap-2 px-4 py-3 bg-[var(--color-background-secondary)] rounded-2xl"><span className="text-[14px] text-[var(--color-text-secondary)] min-w-[90px]">Cliente</span><input type="text" placeholder="Nome do cliente (opcional)" value={clienteNome} onChange={e => setClienteNome(e.target.value)} className="flex-1 text-[15px] bg-transparent border-none outline-none" /></div>
      <div className="bg-[var(--color-background-primary)] border border-[var(--color-border-tertiary)] rounded-2xl p-4"><div className="flex flex-wrap justify-between items-start gap-4 mb-3"><div><div className="text-[13px] text-[var(--color-text-secondary)]">Pago antes do financiamento</div><div className="text-[34px] font-bold tabular-nums leading-tight">{pctText}%</div><div className="text-[13px] font-semibold" style={{ color: barColor }}>{barStatus === 'ok' ? `✓ Meta atingida (${metaAtual}%)` : `Meta: ${metaAtual}% · faltam ${(metaAtual - totais.pagamentoPct).toFixed(1).replace('.', ',')} pontos`}</div></div><div className="text-left sm:text-right"><div className="text-[13px] text-[var(--color-text-secondary)]">Status da condição</div><div className="text-[18px] font-bold leading-tight" style={{ color: barColor }}>{barStatus === 'ok' ? (surplus > 200 ? 'Acima da meta' : 'Exato') : 'Ajustar fluxo'}</div><button onClick={() => setShowMetaModal(true)} className="mt-2 text-[13px] px-3 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)]">Alterar % da obra</button></div></div><div className="relative h-4 bg-[var(--color-background-secondary)] rounded-full"><div className="h-full rounded-full transition-all duration-200" style={{ width: `${barWidth}%`, background: barColor }} /><div className="absolute top-[-3px] w-[2px] h-[22px] bg-[var(--color-text-primary)] rounded-sm" style={{ left: `${Math.min(98, metaAtual)}%` }} /></div><div className="text-[12px] text-[var(--color-text-tertiary)] flex flex-wrap justify-between gap-2 mt-2"><span>meta {metaAtual}% · financiamento máximo {100 - metaAtual}%</span><span>{barStatus === 'ok' ? `valor antes do financiamento: ${fmtBRL(totais.pagamentoFluxo)}` : `falta distribuir: ${fmtBRL(deficit)}`}</span></div>{metaEspecial !== null && <div className="mt-3 text-[13px] bg-[var(--color-background-info)] text-[var(--color-text-info)] rounded-xl px-3 py-2">🔑 Meta especial ativa ({metaEspecial}%) — proposta exige aprovação do gestor.</div>}</div>
      {showMetaModal && <div className="bg-white text-slate-900 border border-slate-200 shadow-lg rounded-2xl p-4"><p className="text-[15px] font-bold mb-2">Percentual de pagamento antes do financiamento</p><p className="text-[13px] text-slate-600 mb-3">Padrão atual: {metaPct}%. Use apenas quando a negociação exigir condição especial.</p><div className="flex items-center gap-2 flex-wrap"><span className="text-[14px] text-slate-600">%</span><input type="number" min="5" max="100" step="1" defaultValue={metaEspecial ?? metaPct} id="meta-esp-input" className="w-24 p-3 text-[16px] rounded-xl border border-slate-300 bg-white" /></div><div className="flex gap-2 mt-3 justify-end flex-wrap"><button onClick={() => setShowMetaModal(false)} className="text-[13px] px-4 py-2 rounded-xl bg-slate-100 text-slate-700">Cancelar</button>{metaEspecial !== null && <button onClick={() => { setMetaEspecial(null); setShowMetaModal(false); }} className="text-[13px] px-4 py-2 rounded-xl bg-slate-100 text-slate-700">Remover especial</button>}<button onClick={() => { const v = parseInt(document.getElementById('meta-esp-input').value); if (v >= 1 && v <= 100) { setMetaEspecial(v); setShowMetaModal(false); } }} className="text-[13px] px-4 py-2 rounded-xl bg-[#0F6E56] text-white font-bold">Aplicar percentual</button></div></div>}
      <GrupoTiles g="e" tiles={state.e} selected={selected} onSelect={selectTile} onRemove={removeTile} onAdd={addTile} addLabel="" showAdd={false} />
      <GrupoTiles g="c" tiles={state.c} selected={selected} onSelect={selectTile} onRemove={removeTile} onAdd={addTile} addLabel="compl." showAdd={true} />
      <GrupoTiles g="m" tiles={state.m} selected={selected} onSelect={selectTile} onRemove={removeTile} onAdd={addTile} addLabel="mensal" showAdd={state.m.length === 0} />
      <GrupoTiles g="a" tiles={state.a} selected={selected} onSelect={selectTile} onRemove={removeTile} onAdd={addTile} addLabel="reforço" showAdd={state.a.length === 0} />
      {showUnica && <GrupoTiles g="u" tiles={state.u} selected={selected} onSelect={selectTile} onRemove={removeTile} onAdd={addTile} addLabel="chaves" showAdd={true} />}
      <FinanciamentoDisplay precoTotal={precoTotal} pagamentoFluxo={totais.pagamentoFluxo} />
      <div className="flex flex-col gap-2">{barStatus !== 'ok' && <div className="bg-[var(--color-background-danger)] text-[var(--color-text-danger)] rounded-2xl px-4 py-3 text-[14px]">Distribua {fmtBRL(deficit)} para atingir {metaAtual}% antes do financiamento.</div>}{barStatus === 'ok' && <div className="bg-[var(--color-background-success)] text-[var(--color-text-success)] rounded-2xl px-4 py-3 text-[14px]">✓ Condição validada. Financiamento estimado: {fmtBRL(totais.fin)} ({totais.finPct.toFixed(1).replace('.', ',')}% do total).</div>}{tabelaProvisoria && <div className="bg-[var(--color-background-warning)] text-[var(--color-text-warning)] rounded-2xl px-4 py-3 text-[14px]">⚠ Tabela de trabalho — aguardando tabela oficial do mês.</div>}</div>
      <div className="flex flex-wrap gap-2"><button onClick={reset} className="flex-1 min-w-[160px] text-[14px] py-3 rounded-2xl bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)]">↺ Voltar sugestão</button><button onClick={() => setShowUnica(v => !v)} className="flex-1 min-w-[160px] text-[14px] py-3 rounded-2xl bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)]">{showUnica ? '− Remover chaves' : '+ Adicionar chaves'}</button><button onClick={handleSalvar} disabled={saving} className={`flex-[1.4] min-w-[190px] text-[15px] py-3 rounded-2xl font-bold ${saving ? 'opacity-60' : ''} bg-[#0F6E56] text-white`}>{saving ? 'Salvando…' : 'Salvar mesa do cliente'}</button></div>
      {selectedTile && <EditorModal g={selected.g} tile={selectedTile} onClose={closeEditor} onUpdateField={updateField} onUpdatePer={updatePeriodicidade} />}
    </div>
  );
}
