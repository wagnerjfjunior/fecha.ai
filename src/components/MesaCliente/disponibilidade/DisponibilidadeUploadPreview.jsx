import { useMemo, useState } from 'react';
import { processMesaClienteFile } from '../../../features/mesaCliente/parser/nativeFirstParser';
import { nativeRowsToParserPayload, validateParserPayloadForImport } from '../../../features/mesaCliente/parser/parserPayloadAdapter';
import { buildAvailabilitySnapshot, summarizeAvailabilityCrosscheck } from './availabilitySnapshot';

const PRIMARY_BUTTON_STYLE = {
  backgroundColor: '#0f766e',
  color: '#ffffff',
  border: '1px solid #0f766e',
  boxShadow: '0 8px 18px rgba(15, 118, 110, 0.22)',
};

const SECONDARY_BUTTON_STYLE = {
  backgroundColor: '#ecfeff',
  color: '#155e75',
  border: '1px solid #a5f3fc',
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

function UnitPreviewRow({ unit }) {
  return (
    <div className="grid grid-cols-[1fr_auto] gap-3 rounded-xl border border-slate-200 bg-white px-3 py-2">
      <div className="min-w-0">
        <p className="text-[14px] font-bold text-slate-900 leading-tight">{unit.unidade}</p>
        <p className="text-[12px] text-slate-500">Andar {unit.andar ?? '—'} · Final {unit.final ?? '—'} · {unit.area_m2 ? `${String(unit.area_m2).replace('.', ',')} m²` : 'metragem não identificada'}</p>
        <p className="text-[12px] mt-1 text-[#0F6E56] font-semibold">✅ Disponível na tabela oficial</p>
      </div>
      <div className="text-right">
        {unit.valor_total > 0 && <p className="text-[13px] font-black text-[#0F6E56]">R$ {Math.round(unit.valor_total).toLocaleString('pt-BR')}</p>}
        <p className="text-[10px] text-slate-500">Valor de Tabela</p>
      </div>
    </div>
  );
}

export default function DisponibilidadeUploadPreview({ empreendimento, unidadesComerciais = [], onClose, onConfirmLocal }) {
  const [arquivo, setArquivo] = useState(null);
  const [result, setResult] = useState(null);
  const [processing, setProcessing] = useState(false);
  const [error, setError] = useState(null);
  const [showAll, setShowAll] = useState(false);

  const unidades = result?.snapshot?.unidades || [];
  const previewUnits = useMemo(() => (showAll ? unidades : unidades.slice(0, 40)), [showAll, unidades]);
  const crosscheck = result?.crosscheck || null;

  const handleProcessar = async () => {
    if (!arquivo || processing) return;
    setProcessing(true);
    setError(null);
    setResult(null);

    try {
      const parserResult = await processMesaClienteFile({
        file: arquivo,
        empreendimento: empreendimento?.nome || '',
      });

      const payload = nativeRowsToParserPayload({
        rows: parserResult.rows,
        empreendimentoNome: empreendimento?.nome || parserResult?.metadata?.empreendimento || '',
        nomeArquivo: arquivo.name,
        parserNome: parserResult.pipeline?.engine || 'native_first',
        layout: parserResult.detection?.layout,
        confidence: parserResult.detection?.confidence,
        csvText: parserResult.csvText,
        pipeline: parserResult.pipeline,
      });

      const validation = validateParserPayloadForImport(payload);
      if (!validation.ok) throw new Error(validation.errors.join(' | '));

      const snapshot = buildAvailabilitySnapshot({
        rows: validation.validUnits,
        metadata: {
          nomeArquivo: arquivo.name,
          gerado_em: parserResult?.metadata?.generatedAt || null,
        },
      });

      const summary = summarizeAvailabilityCrosscheck({
        unidadesComerciais,
        unidadesDisponiveis: snapshot.unidades,
      });

      setResult({
        ok: true,
        fileName: arquivo.name,
        parser: parserResult?.pipeline?.engine || 'native_first',
        layout: parserResult?.detection?.layout || null,
        confidence: parserResult?.detection?.confidence || null,
        snapshot,
        crosscheck: summary,
      });
    } catch (err) {
      setError(err?.message || 'Não foi possível ler a tabela oficial de disponibilidade.');
    } finally {
      setProcessing(false);
    }
  };

  const canConfirm = Boolean(result?.snapshot?.unidades?.length);

  return (
    <div className="fixed inset-0 bg-black/45 flex items-center justify-center z-[9999] p-3" onClick={onClose}>
      <div className="bg-white rounded-3xl w-full max-w-[960px] max-h-[90vh] overflow-y-auto shadow-2xl border border-slate-200" onClick={(e) => e.stopPropagation()}>
        <div className="sticky top-0 bg-white border-b border-slate-200 p-4 flex items-start justify-between gap-3 rounded-t-3xl z-10">
          <div>
            <p className="text-[20px] font-black text-slate-900 leading-tight">Atualizar disponibilidade</p>
            <p className="text-[13px] text-slate-500 mt-1">{empreendimento?.nome || 'Empreendimento'} · tabela oficial Tegra, prévia local</p>
          </div>
          <button onClick={onClose} className="w-9 h-9 rounded-full text-[20px]" style={SECONDARY_BUTTON_STYLE}>×</button>
        </div>

        <div className="p-4 grid gap-4">
          <div className="rounded-2xl bg-[#E1F5EE] border border-[#b7ead9] text-[#0F6E56] px-4 py-3 text-[13px] leading-relaxed">
            A tabela oficial de disponibilidade contém as unidades disponíveis no momento da geração. Nesta etapa o sistema lê a tabela, cria uma prévia e ainda não grava no banco.
          </div>

          <label className="block border border-dashed border-slate-300 rounded-2xl p-5 text-center cursor-pointer transition-colors bg-slate-50">
            <div className="text-3xl mb-2">{arquivo ? '✅' : '📋'}</div>
            <div className="text-[15px] font-bold text-slate-900">{arquivo ? arquivo.name : 'Toque para escolher a tabela oficial de disponibilidade'}</div>
            <div className="text-[12px] text-slate-500 mt-1">PDF oficial · usado para saber quais unidades estão disponíveis agora</div>
            <input type="file" accept=".pdf,.txt,.csv" className="hidden" onChange={(e) => { setArquivo(e.target.files?.[0] ?? null); setResult(null); setError(null); }} />
          </label>

          <div className="flex flex-col md:flex-row gap-2">
            <button onClick={onClose} className="flex-1 py-3 rounded-xl text-[14px] font-semibold" style={SECONDARY_BUTTON_STYLE}>Cancelar</button>
            <button onClick={handleProcessar} disabled={!arquivo || processing} className="flex-1 py-3 rounded-xl text-[14px] font-bold" style={!arquivo || processing ? DISABLED_BUTTON_STYLE : PRIMARY_BUTTON_STYLE}>
              {processing ? 'Lendo disponibilidade…' : 'Ler tabela oficial'}
            </button>
          </div>

          {error && <div className="rounded-2xl bg-[#FDEAEA] text-[#4B1528] px-4 py-3 text-[13px]">{error}</div>}

          {result && (
            <div className="grid gap-4">
              <div className="rounded-2xl border border-slate-200 bg-white p-4">
                <p className="text-[16px] font-black text-slate-900">Resumo da disponibilidade</p>
                <p className="text-[12px] text-slate-500 mt-1">Arquivo: {result.fileName}</p>
                <p className="text-[12px] text-slate-500">Motor: {result.parser}{result.layout ? ` · layout ${result.layout}` : ''}</p>
                <p className="text-[12px] text-slate-500">Data/hora oficial: {result.snapshot.gerado_em || 'ainda não identificada automaticamente'}</p>
              </div>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
                <StatBox label="Disponíveis" value={result.snapshot.total_unidades_disponiveis} hint="na tabela oficial" tone="ok" />
                <StatBox label="Comercial" value={crosscheck?.totalComercial ?? unidadesComerciais.length ?? 0} hint="unidades já carregadas" />
                <StatBox label="Cruzadas" value={crosscheck?.disponiveisCruzadas ?? 0} hint="existem nas duas bases" tone="ok" />
                <StatBox label="Indisponíveis" value={crosscheck?.indisponiveisNaOficial ?? 0} hint="existem na comercial, mas não na oficial" tone="warn" />
              </div>

              {crosscheck?.oficiaisSemComercial > 0 && (
                <div className="rounded-2xl bg-[#FAEEDA] text-[#412402] px-4 py-3 text-[13px] leading-relaxed">
                  Atenção: {crosscheck.oficiaisSemComercial} unidade(s) aparecem na tabela oficial, mas não foram encontradas na tabela comercial já carregada. Elas não devem liberar proposta até cruzar valores e fluxo.
                </div>
              )}

              <div className="rounded-2xl border border-slate-200 bg-slate-50 p-3">
                <div className="flex items-center justify-between gap-2 mb-3">
                  <div>
                    <p className="text-[15px] font-black text-slate-900">Unidades disponíveis encontradas</p>
                    <p className="text-[12px] text-slate-500">Mostrando {previewUnits.length} de {unidades.length}</p>
                  </div>
                  {unidades.length > 40 && <button onClick={() => setShowAll((v) => !v)} className="px-3 py-2 rounded-xl text-[12px] font-semibold" style={SECONDARY_BUTTON_STYLE}>{showAll ? 'Mostrar menos' : 'Mostrar todas'}</button>}
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
                  {previewUnits.map((unit) => <UnitPreviewRow key={unit.unidade} unit={unit} />)}
                </div>
              </div>

              <div className="flex flex-col md:flex-row gap-2">
                <button onClick={onClose} className="flex-1 py-3 rounded-xl text-[14px] font-semibold" style={SECONDARY_BUTTON_STYLE}>Fechar</button>
                <button
                  disabled={!canConfirm}
                  onClick={() => onConfirmLocal?.(result)}
                  className="flex-1 py-3 rounded-xl text-[14px] font-bold"
                  style={canConfirm ? PRIMARY_BUTTON_STYLE : DISABLED_BUTTON_STYLE}
                >
                  Confirmar prévia local
                </button>
              </div>

              <div className="rounded-2xl bg-slate-100 text-slate-600 px-4 py-3 text-[12px] leading-relaxed">
                Esta confirmação ainda não grava no banco. A próxima etapa será persistir o snapshot via RPC segura e aplicar a marcação visual: disponível normal; indisponível cinza com marca d’água.
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
