import { detectLayout } from '../../../mesa/layoutDetector';
import { legacyParser } from '../../../mesa/parsers/legacyParser';
import { parseFlatTable } from '../../../mesa/parsers/parseFlatTable';
import { parseHierarchical } from '../../../mesa/parsers/parseHierarchical';
import { parseERPTable } from '../../../mesa/parsers/parseERPTable';
import { parseSplitBlockTable } from '../../../mesa/parsers/parseSplitBlockTable';
import { parseRangeByFinalTable } from '../../../mesa/parsers/parseRangeByFinalTable';
import { parseReadyStockTable } from '../../../mesa/parsers/parseReadyStockTable';

const WORKER_URL = import.meta.env.VITE_MESA_CLIENTE_WORKER_URL || import.meta.env.VITE_MESA_WORKER_URL || 'https://mesacliente.wagnerjfjunior.workers.dev/';
const PDFJS_URL = 'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.min.js';
const PDFJS_WORKER_URL = 'https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js';

function loadScriptOnce(src, globalName) {
  return new Promise((resolve, reject) => {
    if (globalName && window[globalName]) return resolve(window[globalName]);

    const existing = document.querySelector(`script[src="${src}"]`);
    if (existing) {
      existing.addEventListener('load', () => resolve(globalName ? window[globalName] : true), { once: true });
      existing.addEventListener('error', reject, { once: true });
      return;
    }

    const script = document.createElement('script');
    script.src = src;
    script.async = true;
    script.onload = () => resolve(globalName ? window[globalName] : true);
    script.onerror = () => reject(new Error(`Falha ao carregar biblioteca do PDF: ${src}`));
    document.head.appendChild(script);
  });
}

export async function extractPdfText(file) {
  const pdfjsLib = await loadScriptOnce(PDFJS_URL, 'pdfjsLib');
  pdfjsLib.GlobalWorkerOptions.workerSrc = PDFJS_WORKER_URL;

  const buffer = await file.arrayBuffer();
  const pdf = await pdfjsLib.getDocument({ data: new Uint8Array(buffer) }).promise;
  const pages = [];
  let text = '';

  for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
    const page = await pdf.getPage(pageNumber);
    const content = await page.getTextContent();
    const pageText = content.items.map((item) => item.str).join(' ').trim();

    text += `${pageText}\n`;
    pages.push({
      page: pageNumber,
      chars: pageText.length,
      hasValorTotal: /valor\s+total/i.test(pageText),
      hasFinanciamento: /financiamento/i.test(pageText),
      hasUnidade: /unidade/i.test(pageText),
      start: pageText.slice(0, 120),
      end: pageText.slice(-120),
    });
  }

  const clean = text.trim();
  return {
    text: clean,
    diagnostics: {
      total_pages: pdf.numPages,
      total_chars: clean.length,
      pages,
    },
  };
}

async function extractTextFromFile(file) {
  const name = String(file?.name || '').toLowerCase();
  const type = String(file?.type || '').toLowerCase();

  if (type.includes('pdf') || name.endsWith('.pdf')) {
    return extractPdfText(file);
  }

  if (type.startsWith('image/') || /\.(png|jpe?g|webp|heic)$/i.test(name)) {
    throw new Error('Imagem ainda não pode ser processada diretamente nesta camada. Envie a tabela em PDF com texto selecionável. OCR fica para uma etapa própria, sem gambiarra no plantão.');
  }

  if (/\.(txt|csv)$/i.test(name) || type.includes('text/')) {
    const text = await file.text();
    return {
      text: String(text || '').trim(),
      diagnostics: {
        total_pages: 0,
        total_chars: String(text || '').trim().length,
        source: 'text_file',
      },
    };
  }

  throw new Error('Formato não suportado. Envie PDF com texto selecionável ou TXT/CSV técnico.');
}

async function workerConvert({ text, filename, empreendimento }) {
  const res = await fetch(WORKER_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-mesa-version': 'fechai-native-first' },
    body: JSON.stringify({ mode: 'mergeY', text, filename, empreendimento: empreendimento || '' }),
  });

  const raw = await res.text();
  let data;
  try {
    data = JSON.parse(raw);
  } catch (_) {
    data = { csv_text: raw };
  }

  if (!res.ok) throw new Error(data?.error || `Worker retornou HTTP ${res.status}`);
  if (!data?.csv_text) throw new Error('Worker não retornou csv_text.');
  return data.csv_text;
}

function parseCsvFallback(csv, text, options) {
  const detection = detectLayout(text);
  if (detection.layout === 'hierarchical_tegra') return { rows: parseHierarchical(csv), detection };
  if (detection.layout === 'singleline_flat') return { rows: parseFlatTable(csv), detection };
  if (detection.layout === 'erp_table') return { rows: parseERPTable(csv, options), detection };
  return { rows: legacyParser(csv), detection };
}

function appendObs(observacoes = '', entry = '') {
  const cleanObs = String(observacoes || '').trim();
  const cleanEntry = String(entry || '').trim();
  if (!cleanEntry) return cleanObs;
  if (cleanObs.includes(cleanEntry)) return cleanObs;
  return cleanObs ? `${cleanObs};${cleanEntry}` : cleanEntry;
}

function extractUniqueInstallmentMeta(text = '') {
  const raw = String(text || '').replace(/\u00a0/g, ' ');
  const normalized = raw.normalize('NFD').replace(/[\u0300-\u036f]/g, '');
  const compact = normalized.replace(/\s+/g, ' ');
  const match = compact.match(/\bUNICA\s+(\d{1,2})\s*\/\s*(\d{4})\b/i);
  if (!match) return null;

  const month = String(Number.parseInt(match[1], 10)).padStart(2, '0');
  const year = match[2];

  return {
    month,
    year,
    label: `${month}/${year}`,
    isoMonth: `${year}-${month}`,
    obs: `unica_mes=${year}-${month};unica_label=${month}/${year}`,
  };
}

function enrichRowsWithSourceMetadata(rows = [], text = '') {
  const uniqueMeta = extractUniqueInstallmentMeta(text);
  if (!uniqueMeta) return rows;

  return rows.map((row) => {
    if (!(Number(row?.chaves_each) > 0)) return row;
    const currentObs = String(row?.observacoes || '');
    if (/unica_(mes|label)=/i.test(currentObs)) return row;
    return {
      ...row,
      observacoes: appendObs(currentObs, uniqueMeta.obs),
    };
  });
}

function enrichCsvWithSourceMetadata(csv = '', text = '') {
  const uniqueMeta = extractUniqueInstallmentMeta(text);
  if (!uniqueMeta || !csv) return csv;

  const lines = String(csv || '').split(/\r?\n/);
  if (lines.length < 2) return csv;

  const header = lines[0].split(';').map((col) => col.trim());
  const chavesIdx = header.indexOf('chaves_each');
  const obsIdx = header.indexOf('observacoes');
  if (chavesIdx < 0 || obsIdx < 0) return csv;

  return lines.map((line, index) => {
    if (index === 0 || !line.trim()) return line;

    const cols = line.split(';');
    while (cols.length < header.length) cols.push('');

    const chaves = Number(String(cols[chavesIdx] || '').replace(/\./g, '').replace(',', '.'));
    if (!(chaves > 0)) return line;
    if (/unica_(mes|label)=/i.test(String(cols[obsIdx] || ''))) return line;

    cols[obsIdx] = appendObs(cols[obsIdx], uniqueMeta.obs);
    return cols.join(';');
  }).join('\n');
}

export async function parseNativeFirstText({ text, filename, empreendimento, pdfDiagnostics }) {
  const detection = detectLayout(text);

  if (detection.layout === 'sales_mirror_without_values') {
    return {
      rows: [],
      csvText: '',
      detection: { ...detection, source: 'parser_nativo' },
      pipeline: { engine: 'sales_mirror_without_values', worker_used: false, make_used: false, rows: 0, pdf: pdfDiagnostics },
      hardError: 'Este arquivo é um espelho de vendas com unidades, áreas e vagas, mas não contém valores financeiros. Envie a tabela comercial com valor total, sinal/ato e financiamento para montar a Mesa do Cliente.',
    };
  }

  if (detection.layout === 'ready_stock_table') {
    const native = parseReadyStockTable(text, { empreendimento });
    if (native.rows.length) {
      return {
        rows: native.rows,
        csvText: native.csvText,
        detection: { ...detection, source: 'parser_nativo' },
        pipeline: { engine: 'parseReadyStockTable', worker_used: false, make_used: false, rows: native.rows.length, pdf: pdfDiagnostics, parser: native.diagnostics },
      };
    }
  }

  if (detection.layout === 'range_by_final_table') {
    const native = parseRangeByFinalTable(text, { empreendimento });
    if (native.rows.length) {
      return {
        rows: native.rows,
        csvText: native.csvText,
        detection: { ...detection, source: 'parser_nativo' },
        pipeline: { engine: 'parseRangeByFinalTable', worker_used: false, make_used: false, rows: native.rows.length, pdf: pdfDiagnostics, parser: native.diagnostics },
      };
    }
  }

  if (detection.layout === 'split_block_table' || detection.layout === 'singleline_flat') {
    const native = parseSplitBlockTable(text, { empreendimento });
    if (native.rows.length) {
      return {
        rows: native.rows,
        csvText: native.csvText,
        detection: { ...detection, source: 'parser_nativo' },
        pipeline: { engine: 'parseSplitBlockTable', worker_used: false, make_used: false, rows: native.rows.length, pdf: pdfDiagnostics, parser: native.diagnostics },
      };
    }
  }

  const csv = await workerConvert({ text, filename, empreendimento });
  const parsed = parseCsvFallback(csv, text, { empreendimento });
  const enrichedRows = enrichRowsWithSourceMetadata(parsed.rows, text);
  const enrichedCsv = enrichCsvWithSourceMetadata(csv, text);
  const uniqueMeta = extractUniqueInstallmentMeta(text);

  return {
    rows: enrichedRows,
    csvText: enrichedCsv,
    detection: { ...parsed.detection, source: 'worker_make_fallback' },
    pipeline: {
      engine: 'worker_make',
      worker_used: true,
      make_used: true,
      rows: enrichedRows.length,
      csv_chars: enrichedCsv.length,
      pdf: pdfDiagnostics,
      enrichment: uniqueMeta ? { unique_installment_month: uniqueMeta.label } : null,
    },
  };
}

export async function processMesaClienteFile({ file, empreendimento }) {
  if (!file) throw new Error('Selecione um arquivo de tabela comercial.');

  const extracted = await extractTextFromFile(file);
  if (extracted.text.length < 20) {
    throw new Error('Texto extraído do arquivo ficou vazio ou muito curto. Verifique se o PDF possui texto selecionável.');
  }

  const result = await parseNativeFirstText({
    text: extracted.text,
    filename: file.name,
    empreendimento,
    pdfDiagnostics: extracted.diagnostics,
  });

  if (result.hardError) throw new Error(result.hardError);
  if (!Array.isArray(result.rows) || result.rows.length === 0) {
    throw new Error('Tabela processada, mas nenhuma unidade foi identificada.');
  }

  return {
    ...result,
    fileName: file.name,
    extractedDiagnostics: extracted.diagnostics,
  };
}
