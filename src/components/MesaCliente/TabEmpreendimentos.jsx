import { useState } from 'react';
import {
  useEmpreendimentosMesa,
  useRegistrarUpload,
  useImportarMesaClienteParserResultado,
} from './hooks/useMesaData';
import {
  normalizeParserPayload,
  validateParserPayloadForImport,
} from '../../features/mesaCliente/parser/parserPayloadAdapter';

const DOT_COLOR = { ok: 'bg-[#1D9E75]', yellow: 'bg-[#EF9F27]', red: 'bg-[#E24B4A]' };
const PILL_BG   = { ok: 'bg-[#E1F5EE]', yellow: 'bg-[#FAEEDA]', red: 'bg-[#FDEAEA]' };
const PILL_TEXT = { ok: 'text-[#04342C]', yellow: 'text-[#412402]', red: 'text-[#4B1528]' };
const PILL_SUB  = { ok: 'text-[#0F6E56]', yellow: 'text-[#854F0B]', red: 'text-[#993556]' };

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

function ImportParserModal({ onClose, onSuccess, empresaId, sb, token }) {
  const [empreendimentoNome, setEmpreendimentoNome] = useState('');
  const [incorporadora, setIncorporadora] = useState('');
  const [bairro, setBairro] = useState('');
  const [cidade, setCidade] = useState('');
  const [jsonText, setJsonText] = useState('');
  const [localError, setLocalError] = useState(null);
  const [preview, setPreview] = useState(null);
  const { mutateAsync, isLoading, error } = useImportarMesaClienteParserResultado({ sb, token });

  const handleParsePreview = () => {
    setLocalError(null);
    const normalized = normalizeParserPayload(jsonText);

    const merged = {
      ...normalized,
      empreendimentoNome: empreendimentoNome || normalized.empreendimentoNome,
      incorporadora: incorporadora || normalized.incorporadora,
      bairro: bairro || normalized.bairro,
      cidade: cidade || normalized.cidade,
    };

    if (!empreendimentoNome && normalized.empreendimentoNome) setEmpreendimentoNome(normalized.empreendimentoNome);
    if (!incorporadora && normalized.incorporadora) setIncorporadora(normalized.incorporadora);
    if (!bairro && normalized.bairro) setBairro(normalized.bairro);
    if (!cidade && normalized.cidade) setCidade(normalized.cidade);

    const validation = validateParserPayloadForImport(merged);
    setPreview({ normalized: merged, validation });
    return { normalized: merged, validation };
  };

  const handleImportar = async () => {
    try {
      setLocalError(null);
      const { normalized, validation } = handleParsePreview();
      if (!validation.ok) throw new Error(validation.errors.join(' '));

      await mutateAsync({
        empresaId,
        empreendimentoNome: normalized.empreendimentoNome,
        incorporadora: normalized.incorporadora,
        bairro: normalized.bairro,
        cidade: normalized.cidade,
        nomeArquivo: normalized.nomeArquivo,
        parserNome: normalized.layout ? `${normalized.parserNome}:${normalized.layout}` : normalized.parserNome,
        unidades: validation.validUnits,
      });

      onSuccess?.();
      onClose();
    } catch (err) {
      setLocalError(err.message || 'Erro ao validar/importar JSON');
    }
  };

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-[9999] p-4" onClick={onClose}>
      <div className="bg-[var(--color-background-primary)] rounded-2xl p-5 w-full max-w-[720px] relative shadow-2xl" onClick={e => e.stopPropagation()}>
        <button onClick={onClose} className="absolute top-3 right-3 w-7 h-7 rounded-full bg-[var(--color-background-secondary)] flex items-center justify-center text-base">×</button>
        <p className="text-[15px] font-semibold mb-1">Modo técnico: importar JSON do parser</p>
        <p className="text-[12px] text-[var(--color-text-secondary)] mb-4">
          Uso restrito para validar a ponte parser → banco. O fluxo operacional do corretor será por tabela/PDF.
        </p>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mb-3">
          <input value={empreendimentoNome} onChange={e => setEmpreendimentoNome(e.target.value)} placeholder="Nome real do empreendimento *" className="px-3 py-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] text-[13px] outline-none" />
          <input value={incorporadora} onChange={e => setIncorporadora(e.target.value)} placeholder="Incorporadora" className="px-3 py-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] text-[13px] outline-none" />
          <input value={bairro} onChange={e => setBairro(e.target.value)} placeholder="Bairro" className="px-3 py-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] text-[13px] outline-none" />
          <input value={cidade} onChange={e => setCidade(e.target.value)} placeholder="Cidade" className="px-3 py-2 rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-primary)] text-[13px] outline-none" />
        </div>

        <textarea
          rows={12}
          value={jsonText}
          onChange={e => { setJsonText(e.target.value); setPreview(null); }}
          placeholder={'Exemplo:\n{\n  "empreendimento_nome": "Garden Design",\n  "incorporadora": "Tegra",\n  "unidades": [\n    { "unidade": "101", "andar": 1, "metragem": 76, "valor_tabela": 950000 }\n  ]\n}'}
          className="w-full rounded-xl border border-[var(--color-border-secondary)] bg-[var(--color-background-secondary)] p-3 text-[12px] font-mono outline-none resize-y"
        />

        <div className="bg-[#FAEEDA] text-[#412402] rounded-xl px-3 py-2 text-[11px] my-3 leading-relaxed">
          ⚠️ Nesta etapa o espelho de vendas ainda não filtra vendidas. Todas as unidades importadas aparecerão para conferência e montagem de mesa.
        </div>

        {(localError || error) && <div className="bg-[#FDEAEA] text-[#4B1528] rounded-xl px-3 py-2 text-[11px] mb-3">{localError || error}</div>}
        {preview && (
          <div className="bg-[#E1F5EE] text-[#0F6E56] rounded-xl px-3 py-2 text-[11px] mb-3">
            JSON validado: {preview.validation.validUnits.length} unidade(s) válida(s), {preview.validation.invalidUnits.length} inválida(s).
            {preview.validation.warnings.length > 0 && ` Avisos: ${preview.validation.warnings.slice(0, 2).join(' ')}`}
          </div>
        )}

        <div className="flex gap-2 justify-end">
          <button onClick={onClose} className="px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[12px]">Cancelar</button>
          <button onClick={() => { try { handleParsePreview(); } catch (err) { setLocalError(err.message); } }} className="px-4 py-2 rounded-xl bg-[var(--color-background-info)] text-[var(--color-text-info)] text-[12px] font-medium">Validar JSON</button>
          <button onClick={handleImportar} disabled={isLoading || !jsonText.trim()} className={`px-4 py-2 rounded-xl bg-[var(--color-text-primary)] text-[var(--color-background-primary)] text-[12px] font-medium ${isLoading || !jsonText.trim() ? 'opacity-50' : ''}`}>
            {isLoading ? 'Importando…' : 'Importar'}
          </button>
        </div>
      </div>
    </div>
  );
}

function UploadModal({ empreendimento, tipoInicial, onClose, onSuccess, empresaId, sb, token }) {
  const [tipo, setTipo] = useState(tipoInicial || 'tabela');
  const [subTipo, setSubTipo] = useState(tipoInicial === 'tabela' ? 'trabalho' : null);
  const [arquivo, setArquivo] = useState(null);
  const { mutateAsync, isLoading, error } = useRegistrarUpload({ sb, token });

  const tipoFinal = tipo === 'tabela' ? (subTipo === 'oficial' ? 'tabela_oficial' : 'tabela_trabalho') : tipo;
  const pronto = tipoFinal && arquivo && empreendimento?.id;

  const handleEnviar = async () => {
    if (!pronto) return;
    await mutateAsync({
      empresaId,
      empreendimentoId: empreendimento.id,
      tipoArquivo: tipoFinal,
      nomeArquivo: arquivo.name,
      storagePath: null,
      observacoes: 'Upload registrado pela preview Mesa Cliente. Processamento real do arquivo será feito na etapa do parser/storage.',
    });
    onSuccess?.();
    onClose();
  };

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-[9999] p-4" onClick={onClose}>
      <div className="bg-[var(--color-background-primary)] rounded-2xl p-5 w-full max-w-[380px] relative shadow-2xl" onClick={e => e.stopPropagation()}>
        <button onClick={onClose} className="absolute top-3 right-3 w-7 h-7 rounded-full bg-[var(--color-background-secondary)] flex items-center justify-center text-base">×</button>

        <p className="text-[15px] font-semibold mb-1">Importar tabela/PDF</p>
        <p className="text-[12px] text-[var(--color-text-secondary)] mb-4">
          {empreendimento ? empreendimento.nome : 'A importação automática sem empreendimento será conectada na próxima camada do parser.'}
        </p>

        <div className="grid grid-cols-2 gap-2 mb-4">
          {[
            { key: 'tabela', icon: '📊', label: 'Tabela comercial', sub: 'PDF ou imagem' },
            { key: 'espelho', icon: '🪞', label: 'Espelho de vendas', sub: 'Disponibilidade' },
          ].map(opt => (
            <button key={opt.key} onClick={() => { setTipo(opt.key); setSubTipo(opt.key === 'tabela' ? 'trabalho' : null); }} className={`border rounded-xl p-3 text-center transition-all ${tipo === opt.key ? 'border-[var(--color-text-info)] bg-[var(--color-background-info)] ring-1 ring-[var(--color-text-info)]' : 'border-[var(--color-border-tertiary)] hover:border-[var(--color-border-secondary)]'}`}>
              <div className="text-xl mb-1">{opt.icon}</div>
              <div className="text-[12px] font-semibold">{opt.label}</div>
              <div className="text-[10px] text-[var(--color-text-tertiary)] mt-0.5">{opt.sub}</div>
            </button>
          ))}
        </div>

        {tipo === 'tabela' && (
          <div className="grid grid-cols-2 gap-2 mb-4">
            {[
              { key: 'trabalho', label: '📝 De trabalho', sub: 'WhatsApp · provisória' },
              { key: 'oficial', label: '✅ Oficial', sub: 'Incorporadora' },
            ].map(opt => (
              <button key={opt.key} onClick={() => setSubTipo(opt.key)} className={`border rounded-xl p-2.5 text-center transition-all ${subTipo === opt.key ? 'border-[var(--color-text-info)] bg-[var(--color-background-info)]' : 'border-[var(--color-border-tertiary)] hover:border-[var(--color-border-secondary)]'}`}>
                <div className="text-[12px] font-semibold">{opt.label}</div>
                <div className="text-[10px] text-[var(--color-text-tertiary)] mt-0.5">{opt.sub}</div>
              </button>
            ))}
          </div>
        )}

        <label className="block border border-dashed border-[var(--color-border-secondary)] rounded-xl p-5 text-center cursor-pointer hover:border-[var(--color-text-info)] transition-colors mb-4">
          <div className="text-2xl mb-1">{arquivo ? '✅' : '📄'}</div>
          <div className="text-[13px] font-medium">{arquivo ? arquivo.name : 'Toque para escolher o arquivo'}</div>
          <div className="text-[11px] text-[var(--color-text-tertiary)] mt-1">PDF, imagem · máx. 20MB</div>
          <input type="file" accept=".pdf,image/*" className="hidden" onChange={e => setArquivo(e.target.files?.[0] ?? null)} />
        </label>

        <div className="bg-[var(--color-background-secondary)] rounded-xl px-3 py-2 text-[11px] text-[var(--color-text-secondary)] mb-4 leading-relaxed">
          🔍 Nesta etapa o arquivo é registrado para auditoria quando já existe empreendimento. A ligação com o parser automático será a próxima camada.
        </div>

        {!empreendimento?.id && (
          <div className="bg-[#FAEEDA] text-[#412402] rounded-xl px-3 py-2 text-[11px] mb-3">
            Para importar a primeira tabela sem empreendimento prévio, precisamos conectar o parser automático. Por enquanto, o modo técnico JSON cria o empreendimento e as unidades.
          </div>
        )}

        {error && <div className="bg-[#FDEAEA] text-[#4B1528] rounded-xl px-3 py-2 text-[11px] mb-3">{error}</div>}

        <div className="flex gap-2">
          <button onClick={onClose} className="flex-1 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[12px]">Cancelar</button>
          <button onClick={handleEnviar} disabled={!pronto || isLoading} className={`flex-1 py-2 rounded-xl text-[12px] font-medium transition-opacity bg-[var(--color-text-primary)] text-[var(--color-background-primary)] ${!pronto || isLoading ? 'opacity-50' : ''}`}>
            {isLoading ? 'Enviando…' : 'Registrar'}
          </button>
        </div>
      </div>
    </div>
  );
}

function EmpCard({ emp, onAbrirFluxo, onUpload }) {
  const [open, setOpen] = useState(false);
  const tabelaStatus = emp.tabela_status || 'red';
  const espelhoStatus = emp.espelho_status || 'red';
  const tabelaTitle = tabelaStatus === 'ok' ? 'Tabela atualizada' : tabelaStatus === 'yellow' ? 'Tabela antiga' : 'Tabela desatualizada';
  const espelhoTitle = espelhoStatus === 'ok' ? 'Espelho do dia' : espelhoStatus === 'yellow' ? 'Espelho de ontem' : 'Espelho desatualizado';
  const dataFmt = (iso) => iso ? new Date(iso).toLocaleDateString('pt-BR') : 'Nunca';

  return (
    <div className="bg-[var(--color-background-primary)] border border-[var(--color-border-tertiary)] rounded-2xl overflow-hidden hover:border-[var(--color-border-secondary)] transition-colors mb-3">
      <div className="flex items-center gap-3 p-3 cursor-pointer" onClick={() => setOpen(v => !v)}>
        <div className="w-10 h-10 rounded-xl flex items-center justify-center text-white text-[14px] font-bold flex-shrink-0" style={{ background: emp.cor || '#534AB7' }}>
          {String(emp.nome || 'EM').slice(0, 2).toUpperCase()}
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-[14px] font-semibold truncate">{emp.nome}</div>
          <div className="text-[11px] text-[var(--color-text-tertiary)]">{emp.incorporadora}{emp.bairro ? ` · ${emp.bairro}` : ''}</div>
        </div>
        <div className="flex gap-3 items-center">
          <button onClick={e => { e.stopPropagation(); onUpload(emp, 'tabela'); }} className="flex flex-col items-center gap-1" title="Tabela comercial">
            <div className={`w-3 h-3 rounded-full ${DOT_COLOR[tabelaStatus] || DOT_COLOR.red}`} />
            <span className="text-[9px] text-[var(--color-text-tertiary)] uppercase tracking-wide">Tabela</span>
          </button>
          <button onClick={e => { e.stopPropagation(); onUpload(emp, 'espelho'); }} className="flex flex-col items-center gap-1" title="Espelho de vendas">
            <div className={`w-3 h-3 rounded-full ${DOT_COLOR[espelhoStatus] || DOT_COLOR.red}`} />
            <span className="text-[9px] text-[var(--color-text-tertiary)] uppercase tracking-wide">Espelho</span>
          </button>
        </div>
        <span className="text-[var(--color-text-tertiary)] ml-1">{open ? '▲' : '▼'}</span>
      </div>

      {open && (
        <div className="px-3 pb-3 border-t border-[var(--color-border-tertiary)]">
          <div className="flex gap-2 mt-3 flex-wrap">
            <StatusPill status={tabelaStatus} title={tabelaTitle} sub={`${dataFmt(emp.tabela_data)}${emp.tabela_tipo ? ` · ${emp.tabela_tipo}` : ''}`} who={emp.tabela_enviado_por} obs={tabelaStatus === 'red' ? 'Tabela desatualizada — suba a tabela do mês' : null} />
            <StatusPill status={espelhoStatus} title={espelhoTitle} sub={dataFmt(emp.espelho_data)} who={emp.espelho_enviado_por} obs={espelhoStatus === 'red' ? 'Espelho desatualizado — nesta preview as unidades da tabela serão exibidas mesmo assim' : null} />
          </div>
          <div className="flex gap-2 mt-3 flex-wrap">
            <button onClick={() => onAbrirFluxo(emp)} disabled={!emp.pode_abrir_mesa} className={`px-3 py-1.5 rounded-xl text-[12px] font-medium transition-opacity ${emp.pode_abrir_mesa ? 'bg-[#E1F5EE] text-[#0F6E56]' : 'bg-[var(--color-background-secondary)] text-[var(--color-text-tertiary)] opacity-50'}`}>
              📋 Abrir Mesa
            </button>
            <button onClick={() => onUpload(emp, 'tabela')} className="px-3 py-1.5 rounded-xl text-[12px] bg-[var(--color-background-info)] text-[var(--color-text-info)]">📊 Subir tabela</button>
            <button onClick={() => onUpload(emp, 'espelho')} className="px-3 py-1.5 rounded-xl text-[12px] bg-[var(--color-background-info)] text-[var(--color-text-info)]">🪞 Subir espelho</button>
          </div>
          <p className="text-[10px] text-[var(--color-text-tertiary)] mt-2">🔍 Todas as ações são registradas com usuário, data e hora.</p>
        </div>
      )}
    </div>
  );
}

export default function TabEmpreendimentos({ sb, token, empresaId, isGestor = false, onAbrirFluxo }) {
  const { data: empreendimentos = [], isLoading, error, reload } = useEmpreendimentosMesa({ sb, token, empresaId });
  const [uploadTarget, setUploadTarget] = useState(null);
  const [showImportParser, setShowImportParser] = useState(false);

  const handleUpload = (emp, tipo) => setUploadTarget({ emp, tipo });

  return (
    <div className="p-3">
      <div className="flex items-center justify-between gap-3 bg-[var(--color-background-info)] rounded-xl px-3 py-2.5 mb-3 flex-wrap">
        <span className="text-[12px] text-[var(--color-text-info)]">📤 Importe uma tabela/PDF para montar a Mesa Cliente. O espelho de vendas será conectado depois para filtrar vendidas.</span>
        <div className="flex gap-2 flex-wrap">
          {isGestor && (
            <button onClick={() => setShowImportParser(true)} className="text-[12px] px-3 py-1.5 rounded-xl bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)] font-medium">Modo técnico JSON</button>
          )}
          <button onClick={() => setUploadTarget({ emp: null, tipo: 'tabela' })} className="text-[12px] px-3 py-1.5 rounded-xl bg-[var(--color-text-info)] text-white font-medium">Importar tabela/PDF</button>
        </div>
      </div>

      {isLoading && <div className="text-center py-10 text-[var(--color-text-tertiary)] text-[13px]">Carregando empreendimentos…</div>}

      {error && (
        <div className="text-center py-8">
          <p className="text-[var(--color-text-danger)] text-[13px] mb-3">{error}</p>
          <button onClick={reload} className="text-[12px] px-4 py-2 rounded-xl bg-[var(--color-background-secondary)]">Tentar novamente</button>
        </div>
      )}

      {!isLoading && !error && empreendimentos.length === 0 && (
        <div className="text-center py-12">
          <div className="text-4xl mb-3">🏢</div>
          <p className="text-[14px] font-medium text-[var(--color-text-secondary)]">Nenhum empreendimento com tabela</p>
          <p className="text-[12px] text-[var(--color-text-tertiary)] mt-1">Quando a tabela for importada, as unidades extraídas aparecerão aqui para montagem da mesa.</p>
          <button onClick={() => setUploadTarget({ emp: null, tipo: 'tabela' })} className="mt-4 text-[12px] px-4 py-2 rounded-xl bg-[var(--color-text-info)] text-white font-medium">Importar tabela/PDF</button>
          {isGestor && (
            <button onClick={() => setShowImportParser(true)} className="mt-2 ml-2 text-[12px] px-4 py-2 rounded-xl bg-[var(--color-background-secondary)] text-[var(--color-text-secondary)] font-medium">Modo técnico JSON</button>
          )}
        </div>
      )}

      {empreendimentos.map(emp => (
        <EmpCard key={emp.id} emp={emp} onAbrirFluxo={onAbrirFluxo} onUpload={handleUpload} />
      ))}

      {showImportParser && isGestor && (
        <ImportParserModal
          sb={sb}
          token={token}
          empresaId={empresaId}
          onClose={() => setShowImportParser(false)}
          onSuccess={() => { setShowImportParser(false); reload(); }}
        />
      )}

      {uploadTarget && (
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
