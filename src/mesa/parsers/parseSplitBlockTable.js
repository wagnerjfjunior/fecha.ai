import { validateCanonRow } from "../validators/validateCanonRow";

const CANON_COLUMNS = [
  "empreendimento",
  "torre",
  "final",
  "andar",
  "unidade",
  "area_m2",
  "preco_total",
  "sinal_1",
  "a4_each",
  "mensal_qtd",
  "mensal_each",
  "inter_tipo",
  "inter_qtd",
  "inter_each",
  "chaves_each",
  "financiamento",
  "observacoes",
];

function compactSpaces(value = "") {
  return String(value || "")
    .replace(/\u00a0/g, " ")
    .replace(/[ \t]+/g, " ")
    .replace(/\s+\n/g, "\n")
    .replace(/\n\s+/g, "\n")
    .trim();
}

function removeAccents(value = "") {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

function toNumber(value) {
  if (value === 0) return 0;
  if (!value) return 0;

  let s = String(value).trim();
  const hasComma = s.includes(",");
  const hasDot = s.includes(".");

  if (hasComma && hasDot) {
    if (s.lastIndexOf(",") > s.lastIndexOf(".")) {
      s = s.replace(/\./g, "").replace(",", ".");
    } else {
      s = s.replace(/,/g, "");
    }
  } else if (hasComma) {
    s = s.replace(/\./g, "").replace(",", ".");
  }

  s = s.replace(/[^\d.-]/g, "");
  const n = Number.parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}

function formatNumber(value, decimals = 2) {
  const n = Number(value || 0);
  if (!Number.isFinite(n)) return "";
  return n.toFixed(decimals).replace(/\.00$/, "").replace(/(\.\d*[1-9])0+$/, "$1");
}

function parseDateBR(value = "") {
  const match = String(value || "").match(/(\d{2})\/(\d{2})\/(\d{4})/);
  if (!match) return "";
  return `${match[3]}-${match[2]}-${match[1]}`;
}

function getFirstDateAfter(text, labelRegex) {
  const normalized = compactSpaces(text);
  const match = normalized.match(labelRegex);
  if (!match || match.index === undefined) return "";
  const slice = normalized.slice(match.index, match.index + 180);
  return parseDateBR(slice);
}

function getHeaderInt(text, regex, fallback = 0) {
  const match = compactSpaces(text).match(regex);
  return match ? Number.parseInt(match[1], 10) : fallback;
}

function inferInterTipo(text) {
  const normalized = removeAccents(text).toLowerCase();
  if (/semestral/.test(normalized)) return "semestral";
  if (/unica/.test(normalized)) return "unica";
  if (/anual/.test(normalized)) return "anual";
  return "";
}

function inferFinalFromUnit(unit = "") {
  const match = String(unit || "").match(/(\d{2})$/);
  return match ? match[1] : "";
}

function extractEmpreendimento(text = "", fallback = "") {
  if (fallback) return fallback;

  const normalized = compactSpaces(text);
  const bloco = normalized.match(/Bloco:\s*([^\n]+?)\s+(?:Bloco:|ANDAR\s+UNIDADE|ANDAR)/i);
  if (bloco?.[1]) return compactSpaces(bloco[1]).replace(/\s+/g, " ");

  const title = normalized.match(/([A-Z][A-Z\s]{8,}(?:RESIDENCE|RESIDENCIAL|PARK|DESIGN|CLUB|VIVERE|LAPA))/);
  if (title?.[1]) return compactSpaces(title[1]);

  return "";
}

function splitMirrorBlocks(text = "") {
  const normalized = compactSpaces(text);
  const matches = [...normalized.matchAll(/E\s*spelho\s+de\s+vendas/gi)];

  if (!matches.length) {
    return [normalized];
  }

  return matches
    .map((match, index) => {
      const start = match.index || 0;
      const end = matches[index + 1]?.index ?? normalized.length;
      return normalized.slice(start, end).trim();
    })
    .filter(Boolean);
}

function extractUnitRows(block = "") {
  const rows = [];
  const regex = /(\d{1,2})\s+([A-Z]{1,4}\d{3,5}[A-Z0-9-]*)\s+(\d{1,4}(?:[.,]\d{1,3})?)\s*m(?:²|2)?\s*\$?\s*([\d.,]+)/gi;
  let match;

  while ((match = regex.exec(block)) !== null) {
    rows.push({
      andar: match[1],
      unidade: match[2],
      area_m2: toNumber(match[3]),
      preco_total: toNumber(match[4]),
      raw: match[0],
      index: match.index,
    });
  }

  return rows;
}

function extractMoneyValues(block = "") {
  return [...String(block || "").matchAll(/\$\s*([\d.,]+)/g)].map((match) => toNumber(match[1]));
}

function buildObservacoes({ compQtd, mensalInicio, anualInicio, unica, financMes }) {
  return [
    compQtd ? `comp_qtd=${compQtd}` : "",
    mensalInicio ? `mensal_inicio=${mensalInicio}` : "",
    anualInicio ? `anual_inicio=${anualInicio}` : "",
    unica ? `unica=${unica}` : "",
    financMes ? `financ_mes=${financMes.slice(0, 7)}` : "",
  ]
    .filter(Boolean)
    .join(" | ");
}

function rowToCsv(row) {
  return CANON_COLUMNS.map((key) => String(row[key] ?? "").replace(/[\r\n;]+/g, " ").trim()).join(";");
}

export function rowsToCanonCsv(rows = []) {
  return [CANON_COLUMNS.join(";"), ...rows.map((row) => rowToCsv(row.raw || row))].join("\n");
}

export function parseSplitBlockTable(text, options = {}) {
  const source = compactSpaces(text);
  if (!source) {
    return {
      rows: [],
      csvText: CANON_COLUMNS.join(";"),
      diagnostics: { reason: "empty_source" },
    };
  }

  const blocks = splitMirrorBlocks(source);
  const rows = [];
  const blockDiagnostics = [];

  blocks.forEach((block, blockIndex) => {
    const normalized = removeAccents(block).toLowerCase();
    const hasRequiredHeader =
      normalized.includes("andar") &&
      normalized.includes("unidade") &&
      normalized.includes("area") &&
      normalized.includes("valor total");

    if (!hasRequiredHeader) return;

    const units = extractUnitRows(block);
    if (!units.length) return;

    const moneyValues = extractMoneyValues(block);
    const financeValues = moneyValues.slice(units.length);
    const financeRows = [];

    for (let i = 0; i + 5 < financeValues.length && financeRows.length < units.length; i += 6) {
      financeRows.push(financeValues.slice(i, i + 6));
    }

    const compQtd = getHeaderInt(block, /(\d+)\s+(?:COMPLEMENTO\s+ATO|C\.?\s*ATO)/i, 0);
    const mensalQtd = getHeaderInt(block, /(\d+)\s+MENSAL/i, 0);
    const interQtd = getHeaderInt(block, /(\d+)\s+INTERMEDIARIA/i, 0);
    const interTipo = inferInterTipo(block);
    const mensalInicio = getFirstDateAfter(block, /MENSAL/i);
    const anualInicio = getFirstDateAfter(block, /INTERMEDIARIA/i);
    const unica = getFirstDateAfter(block, /PARCELA\s+UNICA|PARCELA\s+ÚNICA/i);
    const financMes = getFirstDateAfter(block, /FINANCIAMENTO/i);
    const empreendimento = extractEmpreendimento(block, options.empreendimento || "");
    const observacoes = buildObservacoes({ compQtd, mensalInicio, anualInicio, unica, financMes });

    units.forEach((unit, index) => {
      const financial = financeRows[index] || [];
      const raw = {
        empreendimento,
        torre: "",
        final: inferFinalFromUnit(unit.unidade),
        andar: unit.andar,
        unidade: unit.unidade,
        area_m2: formatNumber(unit.area_m2),
        preco_total: formatNumber(unit.preco_total),
        sinal_1: formatNumber(financial[0]),
        a4_each: formatNumber(financial[1]),
        mensal_qtd: mensalQtd || "",
        mensal_each: formatNumber(financial[2]),
        inter_tipo: interTipo,
        inter_qtd: interQtd || "",
        inter_each: formatNumber(financial[3]),
        chaves_each: formatNumber(financial[4]),
        financiamento: formatNumber(financial[5]),
        observacoes,
      };

      const parsed = {
        id: `${unit.unidade}-${blockIndex}-${index}`,
        ...raw,
        area_m2: unit.area_m2,
        preco_total: unit.preco_total,
        sinal_1: Number(financial[0] || 0),
        a4_each: Number(financial[1] || 0),
        mensal_qtd: Number(mensalQtd || 0),
        mensal_each: Number(financial[2] || 0),
        inter_tipo: interTipo,
        inter_qtd: Number(interQtd || 0),
        inter_each: Number(financial[3] || 0),
        chaves_each: Number(financial[4] || 0),
        financiamento: Number(financial[5] || 0),
        observacoes,
        raw,
        parser_meta: {
          parser: "parseSplitBlockTable",
          block_index: blockIndex,
          row_index: index,
          matched_financial_row: Boolean(financial.length),
        },
      };

      rows.push({
        ...parsed,
        validation: validateCanonRow(parsed),
      });
    });

    blockDiagnostics.push({
      block_index: blockIndex,
      units: units.length,
      money_values: moneyValues.length,
      finance_rows: financeRows.length,
      complete: financeRows.length >= units.length,
    });
  });

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseSplitBlockTable",
      blocks: blocks.length,
      parsed_blocks: blockDiagnostics.length,
      total_rows: rows.length,
      block_diagnostics: blockDiagnostics,
      complete: blockDiagnostics.every((item) => item.complete),
    },
  };
}
