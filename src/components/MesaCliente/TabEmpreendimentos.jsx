import { useMemo, useState } from 'react';
import {
  useEmpreendimentosMesa,
  useImportarMesaClienteParserResultado,
  useImportarMesaClienteDisponibilidadeOficial,
} from './hooks/useMesaData';
import { processMesaClienteFile } from '../../features/mesaCliente/parser/nativeFirstParser';
import { nativeRowsToParserPayload, validateParserPayloadForImport } from '../../features/mesaCliente/parser/parserPayloadAdapter';
import DisponibilidadeUploadPreview from './disponibilidade/DisponibilidadeUploadPreview';

const DOT_COLOR = { ok: 'bg-[#1D9E75]', yellow: 'bg-[#EF9F27]', red: 'bg-[#E24B4A]' };
const PILL_BG = { ok: 'bg-[#E1F5EE]', yellow: 'bg-[#FAEEDA]', red: 'bg-[#FDEAEA]' };
const PILL_TEXT = { ok: 'text-[#04342C]', yellow: 'text-[#412402]', red: 'text-[#4B1528]' };
const PILL_SUB = { ok: 'text-[#0F6E56]', yellow: 'text-[#854F0B]', red: 'text-[#993556]' };

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

const SUCCESS_BUTTON_STYLE = {
  backgroundColor: '#0f766e',
  color: '#ffffff',
  border: '1px solid #0f766e',
  boxShadow: '0 8px 18px rgba(15, 118, 110, 0.18)',
};

const DISABLED_BUTTON_STYLE = {
  backgroundColor: '#e5e7eb',
  color: '#6b7280',
  border: '1px solid #d1d5db',
};

function StatusPill({ status = 'red', title, sub, who, obs }) {
  const safeStatus = DOT_COLOR[status] ? status : 'red';

  return (
    <div className={`flex-1 min-w-[140px] rounded-xl p-[10px_12px] flex items-start gap-2 ${PILL_BG[safeStatus]}`}>
      <div className={`w-2 h-2 rounded-full mt-1 flex-shrink-0 ${DOT_COLOR[safeStatus]}`} />
      <div>
        <div className={`text-[12px] font-semibold ${PILL_TEXT[safeStatus]}`}>{title}</div>
        <div className={`text-[11px] mt-0.5 ${PILL_SUB[safeStatus]}`}>{sub}</div>
        {who && <div className="text-[10px] mt-1 opacity-70">por {who}</div>}
        {obs && <div className="text-[10px] mt-1 italic opacity-70">{obs}</div>}
      </div>
    </div>
  );
}

function UploadModal({ empreendimento, tipoInicial, onClose, onSuccess, empresaId, sb, token }) {
  const [tipo, setTipo] = useState(tipoInicial || 'tabela');
  const [subTipo, setSubTipo] = useState(tipoInicial === 'tabela' ? 'trabalho' : null);
  const [arquivo, setArquivo] = useState(null);
  const [empreendimentoNome, setEmpreendimentoNome] = useState(empreendimento?.nome || '');
  const [feedback, setFeedback] = useState(null);
  const { mutateAsync: importarParser, isLoading: importing, error: importError } = useImportarMesaClienteParserResultado({ sb, token });

  const isTabela = tipo === 'tabela';
  const canImport = Boolean(isTabela && arquivo && empreendimentoNome.trim() && empresaId);

  const handleEnviar = async () => {
    if (!canImport || importing) return;

    try {
      setFeedback({ type: 'info', text: 'Lendo PDF e executando leitura da tabela…' });

      const parserResult = await processMesaClienteFile({
        file: arquivo,
        empreendimento: empreendimentoNome.trim(),
      });

      const payload = nativeRowsToParserPayload({
        rows: parserResult.rows,
        empreendimentoNome: empreendimentoNome.trim(),
        nomeArquivo: arquivo.name,
        parserNome: parserResult.pipeline?.engine || 'native_first',
        layout: parserResult.detection?.layout,
        confidence: parserResult.detection?.confidence,
        csvText: parserResult.csvText,
        pipeline: parserResult.pipeline,
      });

      const validation = validateParserPayloadForImport(payload);
      if (!validation.ok) throw new Error(validation.errors.join(' | '));

      setFeedback({ type: 'info', text: `Leitura identificou ${validation.validUnits.length} unidade(s). Salvando no banco com RPC segura…` });

      await importarParser({
        empresaId,
        empreendimentoNome: payload.empreendimentoNome,
        incorporadora: payload.incorporadora || null,
        bairro: payload.bairro || null,
        cidade: payload.cidade || null,
        nomeArquivo: payload.nomeArquivo,
        parserNome: payload.parserNome,
        unidades: validation.validUnits,
      });

      setFeedback({ type: 'success', text: `Tabela importada com ${validation.validUnits.length} unidade(s).` });
      onSuccess?.();
      onClose();
    } catch (err) {
      setFeedback({ type: 'error', text: err?.message || 'Erro ao processar tabela.' });
    }
  };

  const resolvedError = importError || (feedback?.type === 'error' ? feedback.text : null);

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-[9999] p-4" onClick={onClose}>
      <div className="bg-white rounded-2xl p-5 w-full max-w-[460px] relative shadow-2xl" onClick={e => e.stopPropagation()}>
        <button onClick={onClose} className="absolute top-3 right-3 w-7 h-7 rounded-full flex items-center justify-center text-base" style={SECONDARY_BUTTON_STYLE}>×</button>

        <p className="text-[15px] font-semibold mb-1 text-slate-900">Importar tabela comercial</p>
        <p className="text-[12px] text-slate-600 mb-4">
          {empreendimento ? empreendimento.nome : 'Envie a tabela comercial em PDF para criar/atualizar empreendimento e unidades.'}
        </p>

        <div className="grid grid-cols-1 gap-2 mb-4">
          <button
            onClick={() => {
              setTipo('tabela');
              setSubTipo('trabalho');
            }}
            className="border rounded-xl p-3 text-center transition-all"
            style={tipo === 'tabela' ? SECONDARY_BUTTON_STYLE : { backgroundColor: '#ffffff', color: '#111827', border: '1px solid #e5e7eb' }}
          >
            <div className="text-xl mb-1">📊</div>
            <div className="text-[12px] font-semibold">Tabela comercial</div>
            <div className="text-[10px] text-slate-500 mt-0.5">PDF com valores, parcelas e fluxo</div>
          </button>
        </div>

        <label className="block text-[11px] font-semibold text-slate-600 mb-1">Nome do empreendimento</label>
        <input
          value={empreendimentoNome}
          onChange={e => setEmpreendimentoNome(e.target.value)}
          placeholder="Ex.: Garden Design, Nova Vivere, Reserva Caminhos da Lapa…"
          className="w-full rounded-xl border border-slate-200 bg-white px-3 py-2 text-[13px] mb-3 outline-none text-slate-900"
        />

        <div className="grid grid-cols-2 gap-2 mb-4">
          {[
            { key: 'trabalho', label: '📝 De trabalho', sub: 'WhatsApp · provisória' },
            { key: 'oficial', label: '✅ Oficial', sub: 'Incorporadora' },
          ].map(opt => (
            <button
              key={opt.key}
              onClick={() => setSubTipo(opt.key)}
              className="border rounded-xl p-2.5 text-center transition-all"
              style={subTipo === opt.key ? SECONDARY_BUTTON_STYLE : { backgroundColor: '#ffffff', color: '#111827', border: '1px solid #e5e7eb' }}
            >
              <div className="text-[12px] font-semibold">{opt.label}</div>
              <div className="text-[10px] text-slate-500 mt-0.5">{opt.sub}</div>
            </button>
          ))}
        </div>

        <label className="block border border-dashed border-slate-300 rounded-xl p-5 text-center cursor-pointer transition-colors mb-4 bg-slate-50">
          <div className="text-2xl mb-1">{arquivo ? '✅' : '📄'}</div>
          <div className="text-[13px] font-medium text-slate-900">{arquivo ? arquivo.name : 'Toque para escolher o arquivo'}</div>
          <div className="text-[11px] text-slate-500 mt-1">PDF com texto selecionável · máx. 20MB</div>
          <input type="file" accept=".pdf,.txt,.csv" className="hidden" onChange={e => setArquivo(e.target.files?.[0] ?? null)} />
        </label>

        <div className="bg-slate-50 rounded-xl px-3 py-2 text-[11px] text-slate-600 mb-4 leading-relaxed">
          🔒 O arquivo é processado no navegador. A gravação no banco acontece somente via RPC com sessão autenticada e isolamento por empresa.
        </div>

        {feedback && feedback.type !== 'error' && (
          <div className={`rounded-xl px-3 py-2 text-[11px] mb-3 ${feedback.type === 'success' ? 'bg-[#E1F5EE] text-[#0F6E56]' : 'bg-[#eef2ff] text-[#1e3a8a]'}`}>
            {feedback.text}
          </div>
        )}

        {resolvedError && <div className="bg-[#FDEAEA] text-[#4B1528] rounded-xl px-3 py-2 text-[11px] mb-3">{resolvedError}</div>}

        <div className="flex gap-2">
          <button onClick={onClose} className="flex-1 py-2 rounded-xl text-[12px]" style={SECONDARY_BUTTON_STYLE}>Cancelar</button>
          <button
            onClick={handleEnviar}
            disabled={!canImport || importing || !isTabela}
            className="flex-1 py-2 rounded-xl text-[12px] font-medium transition-opacity"
            style={!canImport || importing || !isTabela ? DISABLED_BUTTON_STYLE : PRIMARY_BUTTON_STYLE}
          >
            {importing ? 'Importando…' : 'Processar tabela'}
          </button>
        </div>
      </div>
    </div>
  );
}

function EmpCard({ emp, onAbrirFluxo, onUpload }) {
  const [open, setOpen] = useState(false);
  const tabelaStatus = emp.tabela_status || 'red';
  const disponibilidadeStatus = emp.espelho_status || 'red';
  const tabelaTitle = tabelaStatus === 'ok' ? 'Tabela atualizada' : tabelaStatus === 'yellow' ? 'Tabela antiga' : 'Tabela desatualizada';
  const disponibilidadeTitle = disponibilidadeStatus === 'ok' ? 'Disponibilidade atualizada' : disponibilidadeStatus === 'yellow' ? 'Disponibilidade antiga' : 'Disponibilidade não validada';
  const dataFmt = (iso) => iso ? new Date(iso).toLocaleDateString('pt-BR') : 'Nunca';

  return (
    <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden hover:border-slate-300 transition-colors mb-3">
      <div className="flex items-center gap-3 p-3 cursor-pointer" onClick={() => setOpen(v => !v)}>
        <div className="w-10 h-10 rounded-xl flex items-center justify-center text-white text-[14px] font-bold flex-shrink-0" style={{ background: emp.cor || '#534AB7' }}>
          {String(emp.nome || 'EM').slice(0, 2).toUpperCase()}
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-[14px] font-semibold truncate text-slate-900">{emp.nome}</div>
          <div className="text-[11px] text-slate-500">{emp.incorporadora}{emp.bairro ? ` · ${emp.bairro}` : ''}</div>
        </div>
        <div className="flex gap-3 items-center">
          <button onClick={e => { e.stopPropagation(); onUpload(emp, 'tabela'); }} className="flex flex-col items-center gap-1" title="Tabela comercial">
            <div className={`w-3 h-3 rounded-full ${DOT_COLOR[tabelaStatus] || DOT_COLOR.red}`} />
            <span className="text-[9px] text-slate-500 uppercase tracking-wide">Tabela</span>
          </button>
          <button onClick={e => { e.stopPropagation(); onUpload(emp, 'disponibilidade'); }} className="flex flex-col items-center gap-1" title="Disponibilidade oficial">
            <div className={`w-3 h-3 rounded-full ${DOT_COLOR[disponibilidadeStatus] || DOT_COLOR.red}`} />
            <span className="text-[9px] text-slate-500 uppercase tracking-wide">Disp.</span>
          </button>
        </div>
        <span className="text-slate-500 ml-1">{open ? '▲' : '▼'}</span>
      </div>

      {open && (
        <div className="px-3 pb-3 border-t border-slate-200">
          <div className="flex gap-2 mt-3 flex-wrap">
            <StatusPill status={tabelaStatus} title={tabelaTitle} sub={`${dataFmt(emp.tabela_data)}${emp.tabela_tipo ? ` · ${emp.tabela_tipo}` : ''}`} who={emp.tabela_enviado_por} obs={tabelaStatus === 'red' ? 'Tabela desatualizada — suba a tabela do mês' : null} />
            <StatusPill status={disponibilidadeStatus} title={disponibilidadeTitle} sub={dataFmt(emp.espelho_data)} who={emp.espelho_enviado_por} obs={disponibilidadeStatus === 'red' ? 'Atualize com a tabela oficial Tegra para confirmar as unidades disponíveis' : null} />
          </div>
          <div className="flex gap-2 mt-3 flex-wrap">
            <button onClick={() => onAbrirFluxo(emp)} disabled={!emp.pode_abrir_mesa} className="px-3 py-1.5 rounded-xl text-[12px] font-medium" style={emp.pode_abrir_mesa ? { backgroundColor: '#E1F5EE', color: '#0F6E56' } : DISABLED_BUTTON_STYLE}>
              📋 Abrir Mesa
            </button>
            <button onClick={() => onUpload(emp, 'tabela')} className="px-3 py-1.5 rounded-xl text-[12px]" style={SECONDARY_BUTTON_STYLE}>📊 Subir tabela</button>
            <button onClick={() => onUpload(emp, 'disponibilidade')} className="px-3 py-1.5 rounded-xl text-[12px]" style={SUCCESS_BUTTON_STYLE}>✅ Atualizar disponibilidade</button>
          </div>
          <p className="text-[10px] text-slate-500 mt-2">🔍 Todas as ações são registradas com usuário, data e hora.</p>
        </div>
      )}
    </div>
  );
}

export default function TabEmpreendimentos({ sb, token, empresaId, onAbrirFluxo }) {
  const { data: empreendimentos = [], isLoading, error, reload } = useEmpreendimentosMesa({ sb, token, empresaId });
  const { mutateAsync: importarDisponibilidade } = useImportarMesaClienteDisponibilidadeOficial({ sb, token });
  const [uploadTarget, setUploadTarget] = useState(null);

  const sortedEmpreendimentos = useMemo(() => empreendimentos, [empreendimentos]);
  const handleUpload = (emp, tipo) => setUploadTarget({ emp, tipo });

  return (
    <div className="p-3">
      <div className="flex items-center justify-between gap-3 rounded-xl px-3 py-3 mb-3 flex-wrap" style={{ backgroundColor: '#eff6ff', border: '1px solid #bfdbfe' }}>
        <span className="text-[12px] font-medium" style={{ color: '#1e40af' }}>
          📤 Importe a tabela comercial para valores e atualize a disponibilidade com a tabela oficial Tegra.
        </span>
        <button
          type="button"
          onClick={() => setUploadTarget({ emp: null, tipo: 'tabela' })}
          className="text-[12px] px-4 py-2 rounded-xl font-semibold inline-flex items-center gap-1 whitespace-nowrap"
          style={PRIMARY_BUTTON_STYLE}
        >
          📄 Importar tabela/PDF
        </button>
      </div>

      {isLoading && <div className="text-center py-10 text-slate-500 text-[13px]">Carregando empreendimentos…</div>}

      {error && (
        <div className="text-center py-8">
          <p className="text-red-700 text-[13px] mb-3">{error}</p>
          <button onClick={reload} className="text-[12px] px-4 py-2 rounded-xl" style={SECONDARY_BUTTON_STYLE}>Tentar novamente</button>
        </div>
      )}

      {!isLoading && !error && sortedEmpreendimentos.length === 0 && (
        <div className="text-center py-12">
          <div className="text-4xl mb-3">🏢</div>
          <p className="text-[14px] font-semibold text-slate-800">Nenhum empreendimento com tabela</p>
          <p className="text-[12px] text-slate-600 mt-1">Quando a tabela for importada, as unidades extraídas aparecerão aqui para montagem da mesa.</p>
          <button
            type="button"
            onClick={() => setUploadTarget({ emp: null, tipo: 'tabela' })}
            className="mt-4 text-[12px] px-5 py-2.5 rounded-xl font-semibold inline-flex items-center gap-1"
            style={PRIMARY_BUTTON_STYLE}
          >
            📄 Importar primeira tabela/PDF
          </button>
        </div>
      )}

      {sortedEmpreendimentos.map(emp => (
        <EmpCard key={emp.id} emp={emp} onAbrirFluxo={onAbrirFluxo} onUpload={handleUpload} />
      ))}

      {uploadTarget?.tipo === 'disponibilidade' && (
        <DisponibilidadeUploadPreview
          empreendimento={uploadTarget.emp}
          empresaId={empresaId}
          unidadesComerciais={[]}
          importarDisponibilidade={importarDisponibilidade}
          onClose={() => setUploadTarget(null)}
          onSuccess={() => {
            setUploadTarget(null);
            reload();
          }}
        />
      )}

      {uploadTarget?.tipo !== 'disponibilidade' && uploadTarget && (
        <UploadModal
          sb={sb}
          token={token}
          empresaId={empresaId}
          empreendimento={uploadTarget.emp}
          tipoInicial={uploadTarget.tipo}
          onClose={() => setUploadTarget(null)}
          onSuccess={() => { setUploadTarget(null); reload(); }}
        />
      )}
    </div>
  );
}
