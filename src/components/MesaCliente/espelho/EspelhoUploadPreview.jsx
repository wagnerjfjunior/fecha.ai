import { useMemo, useState } from 'react';
import { extractSalesMirrorPdf } from './pdfMirrorExtractor';
import { statusToUi } from './statusRules';

const PRIMARY_BUTTON_STYLE = {
  backgroundColor: '#2563eb',
  color: '#ffffff',
  border: '1px solid #1d4ed8',
  boxShadow: '0 8px 18px rgba(37, 99, 235, 0.22)',
};

const SECONDARY_BUTTON_STYLE = {
  backgroundColor: '#eef2ff',
  color: '#1e3a8a',
  border: '1px solid #c7d2fe',
};

const DISABLED_BUTTON_STYLE = {
  backgroundColor: '#e5e7eb',
  color: '#6b7280',
  border: '1px solid #d1d5db',
};

function StatBox({ label, value, hint, tone = 'neutral' }) {
  const cls = tone === 'ok'
    ? 'bg-[#E1F5EE] text-[#0F6E56]'
    : tone === 'warn'
      ? 'bg-[#FAEEDA] text-[#854F0B]'
      : tone === 'danger'
        ? 'bg-[#FDEAEA] text-[#993556]'
        : 'bg-slate-100 text-slate-700';

  return (
    <div className={`rounded-2xl px-4 py-3 ${cls}`}>
      <p className="text-[11px] font-bold uppercase tracking-wide opacity-80">{label}</p>
      <p className="text-[22px] font-black leading-tight mt-1">{value}</p>
      {hint && <p className="text-[11px] mt-1 opacity-75 leading-snug">{hint}</p>}
    </div>
  );
}

function ConfidenceBadge({ value }) {
  const pct = Math.round(Number(value || 0) * 100);
  const tone = pct >= 85 ? 'bg-[#E1F5EE] text-[#0F6E56]' : pct >= 65 ? 'bg-[#FAEEDA] text-[#854F0B]' : 'bg-[#FDEAEA] text-[#993556]';
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-[11px] font-bold ${tone}`}>{pct}%</span>;
}

function UnitPreviewRow({ unit }) {
  const ui = statusToUi(unit.status_espelho);
  return (
    <div className="grid grid-cols-[1fr_auto] gap-3 rounded-xl border border-slate-200 bg-white px-3 py-2">
      <div className="min-w-0">
        <p className="text-[14px] font-bold text-slate-900 leading-tight">{unit.unidade}</p>
        <p className="text-[12px] text-slate-500">Andar {unit.andar ?? '—'} · Final {unit.final ?? '—'} · Página {unit.page ?? '—'}</p>
        <p className="text-[12px] mt-1 text-slate-700">{ui.icon} {unit.status_label || ui.label}</p>
        {unit.symbols?.length > 0 && <p className="text-[11px] text-slate-500 mt-0.5">Sinais: {unit.symbols.join(' ')}</p>}
      </div>
      <div className="text-right flex flex-col items-end gap-1">
        <ConfidenceBadge value={unit.confidence} />
        <span className="text-[10px] text-slate-500">confiança</span>
      </div>
    </div>
  );
}

export default function EspelhoUploadPreview({ empreendimento, onClose }) {
  const [arquivo, setArquivo] = useState(null);
  const [result, setResult] = useState(null);
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState(null);
  const [showAll, setShowAll] = useState(false);

  const unidades = result?.unidades || [];
  const previewUnits = useMemo(() => (showAll ? unidades : unidades.slice(0, 30)), [showAll, unidades]);

  const handleProcessar = async () => {
    if (!arquivo || processing) return;
    setProcessing(true);
    setError(null);
    setResult(null);
    try {
      const parsed = await extractSalesMirrorPdf(arquivo);
      setResult(parsed);
    } catch (err) {
      setError(err?.message || 'Não foi possível ler o espelho de vendas.');
    } finally {
      setProcessing(false);
    }
  };

  const resumo = result?.resumo || {};

  return (
    <div className="fixed inset-0 bg-black/45 flex items-center justify-center z-[9999] p-3" onClick={onClose}>
      <div className="bg-white rounded-3xl w-full max-w-[920px] max-h-[90vh] overflow-y-auto shadow-2xl border border-slate-200" onClick={(e) => e.stopPropagation()}>
        <div className="sticky top-0 bg-white border-b border-slate-200 p-4 flex items-start justify-between gap-3 rounded-t-3xl z-10">
          <div>
            <p className="text-[20px] font-black text-slate-900 leading-tight">Importar espelho oficial</p>
            <p className="text-[13px] text-slate-500 mt-1">{empreendimento?.nome || 'Empreendimento'} · prévia local, sem gravar no banco</p>
          </div>
          <button onClick={onClose} className="w-9 h-9 rounded-full text-[20px]" style={SECONDARY_BUTTON_STYLE}>×</button>
        </div>

        <div className="p-4 grid gap-4">
          <div className="rounded-2xl bg-[#eff6ff] border border-[#bfdbfe] text-[#1e40af] px-4 py-3 text-[13px] leading-relaxed">
            O espelho será lido como camada separada da tabela comercial. Nesta etapa o sistema identifica unidades, sinais e confiança da leitura, mas ainda não altera disponibilidade no banco.
          </div>

          <label className="block border border-dashed border-slate-300 rounded-2xl p-5 text-center cursor-pointer transition-colors bg-slate-50">
            <div className="text-3xl mb-2">{arquivo ? '✅' : '🪞'}</div>
            <div className="text-[15px] font-bold text-slate-900">{arquivo ? arquivo.name : 'Toque para escolher o PDF oficial do espelho'}</div>
            <div className="text-[12px] text-slate-500 mt-1">PDF oficial da incorporadora · leitura local no navegador</div>
            <input type="file" accept=".pdf,application/pdf" className="hidden" onChange={(e) => { setArquivo(e.target.files?.[0] ?? null); setResult(null); setError(null); }} />
          </label>

          <div className="flex flex-col md:flex-row gap-2">
            <button onClick={onClose} className="flex-1 py-3 rounded-xl text-[14px] font-semibold" style={SECONDARY_BUTTON_STYLE}>Cancelar</button>
            <button onClick={handleProcessar} disabled={!arquivo || processing} className="flex-1 py-3 rounded-xl text-[14px] font-bold" style={!arquivo || processing ? DISABLED_BUTTON_STYLE : PRIMARY_BUTTON_STYLE}>
              {processing ? 'Lendo espelho…' : 'Ler espelho'}
            </button>
          </div>

          {error && <div className="rounded-2xl bg-[#FDEAEA] text-[#4B1528] px-4 py-3 text-[13px]">{error}</div>}

          {result && (
            <div className="grid gap-4">
              <div className="rounded-2xl border border-slate-200 bg-white p-4">
                <p className="text-[16px] font-black text-slate-900">Resumo da leitura</p>
                <p className="text-[12px] text-slate-500 mt-1">Arquivo: {result.fileName}</p>
                <p className="text-[12px] text-slate-500">Gerado em: {result.generatedAtText || 'não identificado no texto do PDF'}</p>
                <p className="text-[12px] text-slate-500">Páginas lidas: {result.totalPages} · caracteres: {result.totalChars}</p>
              </div>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <StatBox label="Unidades" value={resumo.total ?? 0} hint="identificadas no PDF" />
                <StatBox label="Prováveis" value={resumo.provavelDisponivel ?? 0} hint="com sinal positivo" tone="ok" />
                <StatBox label="Validar" value={resumo.validar ?? 0} hint="sinal ambíguo" tone="warn" />
                <StatBox label="Confiança" value={`${Math.round(Number(resumo.confidenceMedia || 0) * 100)}%`} hint="média da leitura" tone={Number(resumo.confidenceMedia || 0) >= 0.65 ? 'ok' : 'warn'} />
              </div>

              <div className="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                <div className="flex items-center justify-between gap-2 mb-3">
                  <div>
                    <p className="text-[15px] font-black text-slate-900">Unidades encontradas</p>
                    <p className="text-[12px] text-slate-500">Mostrando {previewUnits.length} de {unidades.length}</p>
                  </div>
                  {unidades.length > 30 && <button onClick={() => setShowAll((v) => !v)} className="px-3 py-2 rounded-xl text-[12px] font-semibold" style={SECONDARY_BUTTON_STYLE}>{showAll ? 'Mostrar menos' : 'Mostrar todas'}</button>}
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                  {previewUnits.map((unit) => <UnitPreviewRow key={`${unit.unidade}-${unit.page}`} unit={unit} />)}
                </div>
              </div>

              <div className="rounded-2xl bg-[#FAEEDA] text-[#412402] px-4 py-3 text-[13px] leading-relaxed">
                Próxima etapa: persistir este snapshot em RPC segura e cruzar com a tabela comercial. Nesta prévia, nada foi gravado nem filtrado automaticamente.
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
