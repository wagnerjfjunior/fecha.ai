import { normalizeMirrorCells, summarizeMirrorUnits } from './normalizeMirror';

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

function inferSymbolsNearText(items, index) {
  const base = items[index];
  if (!base) return [];

  const [, , , , x, y] = base.transform || [];
  const symbols = [];

  items.forEach((item, itemIndex) => {
    if (itemIndex === index) return;
    const text = String(item.str || '').trim();
    if (!/[$!]|\bid\b/i.test(text)) return;
    const [, , , , ix, iy] = item.transform || [];
    const dx = Math.abs(Number(ix || 0) - Number(x || 0));
    const dy = Math.abs(Number(iy || 0) - Number(y || 0));
    if (dx <= 45 && dy <= 28) symbols.push(text);
  });

  return symbols;
}

function textItemsToCandidateCells(items = [], pageNumber) {
  const cells = [];

  items.forEach((item, index) => {
    const text = String(item.str || '').trim();
    const match = text.match(/\b(?:AP)?\s*\d{4,5}\b/i);
    if (!match) return;

    const [, , , , x, y] = item.transform || [];
    cells.push({
      text,
      label: match[0],
      symbols: inferSymbolsNearText(items, index),
      bbox: {
        x: Number(x || 0),
        y: Number(y || 0),
        width: Number(item.width || 0),
        height: Number(item.height || 0),
      },
      page: pageNumber,
    });
  });

  return cells;
}

function extractGeneratedAt(fullText = '') {
  const normalized = String(fullText || '').replace(/\s+/g, ' ');
  const match = normalized.match(/(\d{2}\/\d{2}\/\d{4})\s*(?:às|as|-)?\s*(\d{2}:\d{2}(?::\d{2})?)/i)
    || normalized.match(/(\d{2}\/\d{2}\/\d{4})/i);
  if (!match) return null;
  return match[2] ? `${match[1]} ${match[2]}` : match[1];
}

export async function extractSalesMirrorPdf(file) {
  if (!file) throw new Error('Selecione um PDF do espelho de vendas.');

  const name = String(file.name || '').toLowerCase();
  const type = String(file.type || '').toLowerCase();
  if (!name.endsWith('.pdf') && !type.includes('pdf')) {
    throw new Error('Nesta etapa o espelho precisa ser PDF. Imagem/screenshot entra em uma etapa própria com validação visual.');
  }

  const pdfjsLib = await loadScriptOnce(PDFJS_URL, 'pdfjsLib');
  pdfjsLib.GlobalWorkerOptions.workerSrc = PDFJS_WORKER_URL;

  const buffer = await file.arrayBuffer();
  const pdf = await pdfjsLib.getDocument({ data: new Uint8Array(buffer) }).promise;

  const pages = [];
  const candidateCells = [];
  let fullText = '';

  for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
    const page = await pdf.getPage(pageNumber);
    const content = await page.getTextContent();
    const items = content.items || [];
    const pageText = items.map((item) => String(item.str || '')).join(' ').trim();
    fullText += `${pageText}\n`;

    const pageCells = textItemsToCandidateCells(items, pageNumber);
    candidateCells.push(...pageCells);
    pages.push({
      page: pageNumber,
      chars: pageText.length,
      candidates: pageCells.length,
      hasDollar: /[$＄]/.test(pageText),
      hasStatusSymbols: /[$＄!！]|\bid\b/i.test(pageText),
    });
  }

  const unidades = normalizeMirrorCells(candidateCells);

  return {
    ok: true,
    fileName: file.name,
    generatedAtText: extractGeneratedAt(fullText),
    totalPages: pdf.numPages,
    totalChars: fullText.trim().length,
    unidades,
    resumo: summarizeMirrorUnits(unidades),
    diagnostics: {
      pages,
      candidateCells: candidateCells.length,
      note: 'V1 usa texto selecionável e símbolos próximos. Cores rasterizadas do PDF podem exigir etapa visual/canvas na V2.',
    },
  };
}
