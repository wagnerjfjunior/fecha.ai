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

const PAYMENT_DIFF_TOLERANCE = 5;
const AVAILABILITY_MARKER_VALUE = 1000;

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

function normalizeForMatch(value = "") {
  return removeAccents(value).replace(/\u00a0/g, " ").replace(/\s+/g, " ").toLowerCase().trim();
}

function toNumber(value) {
  if (value === 0) return 0;
  if (!value) return 0;
  let s = String(value).trim();
  const hasComma = s.includes(",");
  const hasDot = s.includes(".");
  if (hasComma && hasDot) {
    if (s.lastIndexOf(",") > s.lastIndexOf(".")) s = s.replace(/\./g, "").replace(",", ".");
    else s = s.replace(/,/g, "");
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
  const slice = normalized.slice(match.index, match.index + 220);
  return parseDateBR(slice);
}

function getPaymentQty(text, labelRegex, fallback = 0) {
  const match = compactSpaces(text).match(labelRegex);
  return match?.[1] ? Number.parseInt(match[1], 10) : fallback;
}

function inferInterTipo(text) {
  const normalized = removeAccents(text).toLowerCase();
  if (/semestral/.test(normalized)) return "semestral";
  if (/intermediaria\s+anual/.test(normalized) || /anual/.test(normalized)) return "anual";
  if (/unica/.test(normalized)) return "unica";
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
  const title = normalized.match(/([A-Z][A-Z\s]{8,}(?:RESIDENCE|RESIDENCIAL|PARK|DESIGN|CLUB|VIVERE|LAPA|LISSONI|MOEMA|OFFICES|STUDIOS))/);
  if (title?.[1]) return compactSpaces(title[1]);
  return "";
}

function splitMirrorBlocks(text = "") {
  const normalized = compactSpaces(text);
  const matches = [...normalized.matchAll(/E\s*spelho\s+de\s+vendas/gi)];
  if (!matches.length) return [normalized];
  return matches.map((match, index) => {
    const start = match.index || 0;
    const end = matches[index + 1]?.index ?? normalized.length;
    return normalized.slice(start, end).trim();
  }).filter(Boolean);
}

function extractPaymentPlan(block = "") {
  return {
    atoQtd: getPaymentQty(block, /(?:^|\s)(\d{1,2})\s+SINAL\s+ATO/i, 1),
    compQtd: getPaymentQty(block, /(?:^|\s)(\d{1,2})\s+(?:COMPLEMENTO\s+ATO|C\.?\s*ATO)/i, 0),
    mensalQtd: getPaymentQty(block, /(?:^|\s)(\d{1,2})\s+MENSAL/i, 0),
    interQtd: getPaymentQty(block, /(?:^|\s)(\d{1,2})\s+INTERMEDIARIA/i, 0),
    unicaQtd: getPaymentQty(block, /(?:^|\s)(\d{1,2})\s+PARCELA\s*(?:UNICA|ÚNICA)/i, 0),
    financiamentoQtd: getPaymentQty(block, /(?:^|\s)(\d{1,2})\s+FINANCIAMENTO/i, 1),
    periodicidadeQtd: getPaymentQty(block, /(?:^|\s)(\d{1,2})\s+(?:FINAL\(IS\)|PERIODICIDADE)/i, 0),
    interTipo: inferInterTipo(block),
    mensalInicio: getFirstDateAfter(block, /MENSAL/i),
    anualInicio: getFirstDateAfter(block, /INTERMEDIARIA/i),
    unica: getFirstDateAfter(block, /PARCELA\s*UNICA|PARCELA\s*ÚNICA/i),
    financMes: getFirstDateAfter(block, /FINANCIAMENTO/i),
    periodicidadeData: getFirstDateAfter(block, /FINAL\(IS\)|PERIODICIDADE/i),
    source: "split_block_header",
  };
}

function extractUnitRows(block = "") {
  const rows = [];
  const regex = /(\d{1,2})\s+([A-Z]{1,4}\d{3,5}[A-Z0-9-]*)\s+(\d{1,4}(?:[.,]\d{1,3})?)\s*m(?:²|2)?\s*\$?\s*([\d.,]+)/gi;
  let match;
  while ((match = regex.exec(block)) !== null) {
    rows.push({ andar: match[1], unidade: match[2], area_m2: toNumber(match[3]), preco_total: toNumber(match[4]), raw: match[0], index: match.index });
  }
  return rows;
}

function extractInlineFinancialRows(block = "") {
  const rows = [];
  const money = "(?:R\\$|\\$)\\s*([\\d.,]+)";
  const regex = new RegExp(
    `(\\d{1,2})\\s+([A-Z]{1,4}\\d{3,5}[A-Z0-9-]*)\\s+` +
    `(\\d{1,4}(?:[.,]\\d{1,3})?)\\s*m(?:²|2)?\\s+` +
    `${money}\\s+${money}\\s+${money}\\s+${money}\\s+${money}\\s+${money}\\s+${money}`,
    "gi"
  );
  let match;
  while ((match = regex.exec(block)) !== null) {
    rows.push({
      andar: match[1],
      unidade: match[2],
      area_m2: toNumber(match[3]),
      sinal_1: toNumber(match[4]),
      a4_each: toNumber(match[5]),
      mensal_each: toNumber(match[6]),
      inter_each: toNumber(match[7]),
      chaves_each: toNumber(match[8]),
      financiamento: toNumber(match[9]),
      preco_total: toNumber(match[10]),
      raw: match[0],
      index: match.index,
    });
  }
  return rows;
}

function extractMoneyValues(block = "") {
  return [...String(block || "").matchAll(/\$\s*([\d.,]+)/g)].map((match) => toNumber(match[1]));
}

function isAvailabilityMarker(value) {
  return Math.abs(Number(value || 0) - AVAILABILITY_MARKER_VALUE) < 0.01;
}

function buildFinanceRows(financeValues = [], expectedRows = 0, paymentPlan = {}) {
  if (!expectedRows) return { financeRows: [], mode: "none", stride: 0 };

  const rowsWithMarker = [];
  if (financeValues.length >= expectedRows * 7) {
    for (let i = 0; i + 6 < financeValues.length && rowsWithMarker.length < expectedRows; i += 7) {
      const candidate = financeValues.slice(i, i + 7);
      if (!isAvailabilityMarker(candidate[6])) break;
      rowsWithMarker.push({ values: candidate.slice(0, 6), periodicidadeValor: candidate[6] });
    }
    if (rowsWithMarker.length === expectedRows) {
      return { financeRows: rowsWithMarker, mode: "split_blocks_by_index_status_marker_7", stride: 7 };
    }
  }

  const compactUnicaFinalRows = [];
  if (
    paymentPlan.financiamentoQtd &&
    paymentPlan.unicaQtd &&
    paymentPlan.periodicidadeQtd &&
    !paymentPlan.compQtd &&
    !paymentPlan.mensalQtd &&
    !paymentPlan.interQtd &&
    financeValues.length >= expectedRows * 4
  ) {
    for (let i = 0; i + 3 < financeValues.length && compactUnicaFinalRows.length < expectedRows; i += 4) {
      const candidate = financeValues.slice(i, i + 4);
      compactUnicaFinalRows.push({ values: [candidate[0], 0, 0, 0, candidate[1], candidate[3]], periodicidadeValor: candidate[2] });
    }
    if (compactUnicaFinalRows.length === expectedRows) {
      return { financeRows: compactUnicaFinalRows, mode: "split_blocks_ato_unica_final_financiamento_4", stride: 4 };
    }
  }

  const compactFinalRows = [];
  if (paymentPlan.financiamentoQtd && !paymentPlan.unicaQtd && !paymentPlan.compQtd && !paymentPlan.mensalQtd && !paymentPlan.interQtd && financeValues.length >= expectedRows * 3) {
    for (let i = 0; i + 2 < financeValues.length && compactFinalRows.length < expectedRows; i += 3) {
      const candidate = financeValues.slice(i, i + 3);
      compactFinalRows.push({ values: [candidate[0], 0, 0, 0, 0, candidate[1]], periodicidadeValor: candidate[2] });
    }
    if (compactFinalRows.length === expectedRows) {
      return { financeRows: compactFinalRows, mode: "split_blocks_ato_financiamento_final_obs_3", stride: 3 };
    }
  }

  const rowsWithoutMarker = [];
  for (let i = 0; i + 5 < financeValues.length && rowsWithoutMarker.length < expectedRows; i += 6) {
    rowsWithoutMarker.push({ values: financeValues.slice(i, i + 6), periodicidadeValor: 0 });
  }
  return { financeRows: rowsWithoutMarker, mode: "split_blocks_by_index", stride: 6 };
}

function buildObservacoes({ paymentPlan, diff, parserMode, periodicidadeValor }) {
  return [
    `ato_qtd=${paymentPlan.atoQtd || 1}`,
    `comp_qtd=${paymentPlan.compQtd || 0}`,
    `mensal_qtd=${paymentPlan.mensalQtd || 0}`,
    `inter_qtd=${paymentPlan.interQtd || 0}`,
    `unica_qtd=${paymentPlan.unicaQtd || 0}`,
    `financiamento_qtd=${paymentPlan.financiamentoQtd || 1}`,
    paymentPlan.periodicidadeQtd ? `periodicidade_qtd=${paymentPlan.periodicidadeQtd}` : "",
    Number(periodicidadeValor || 0) > 0 ? `periodicidade_valor=${formatNumber(periodicidadeValor)}` : "",
    paymentPlan.periodicidadeData ? `periodicidade_data=${paymentPlan.periodicidadeData}` : "",
    paymentPlan.mensalInicio ? `mensal_inicio=${paymentPlan.mensalInicio}` : "",
    paymentPlan.anualInicio ? `anual_inicio=${paymentPlan.anualInicio}` : "",
    paymentPlan.unica ? `unica=${paymentPlan.unica}` : "",
    paymentPlan.financMes ? `financ_mes=${paymentPlan.financMes.slice(0, 7)}` : "",
    `payment_plan_source=${paymentPlan.source}`,
    parserMode ? `parser_mode=${parserMode}` : "",
    Number.isFinite(diff) ? `check_diff=${diff.toFixed(2)}` : "",
    `check_tolerance=${PAYMENT_DIFF_TOLERANCE.toFixed(2)}`,
  ].filter(Boolean).join(" | ");
}

function paymentDiff(row, paymentPlan) {
  return Number(row.preco_total || 0) - (
    Number(row.sinal_1 || 0) * Number(paymentPlan.atoQtd || 1) +
    Number(row.a4_each || 0) * Number(paymentPlan.compQtd || 0) +
    Number(row.mensal_each || 0) * Number(paymentPlan.mensalQtd || 0) +
    Number(row.inter_each || 0) * Number(paymentPlan.interQtd || 0) +
    Number(row.chaves_each || 0) * Number(paymentPlan.unicaQtd || 0) +
    Number(row.financiamento || 0) * Number(paymentPlan.financiamentoQtd || 1)
  );
}

function validateSplitRow(row, paymentPlan) {
  const base = validateCanonRow(row);
  const diff = paymentDiff(row, paymentPlan);
  const issues = [...base.issues];
  if (Math.abs(diff) > PAYMENT_DIFF_TOLERANCE) {
    issues.push(`soma_fluxo_difere_valor_total=${diff.toFixed(2)};tolerancia=${PAYMENT_DIFF_TOLERANCE.toFixed(2)}`);
  }
  return { valid: issues.length === 0, issues };
}

function rowToCsv(row) {
  return CANON_COLUMNS.map((key) => String(row[key] ?? "").replace(/[\r\n;]+/g, " ").trim()).join(";");
}

export function rowsToCanonCsv(rows = []) {
  return [CANON_COLUMNS.join(";"), ...rows.map((row) => rowToCsv(row.raw || row))].join("\n");
}

function makeParsedRow({ unit, paymentPlan, empreendimento, blockIndex, index, parserMode }) {
  const diff = paymentDiff(unit, paymentPlan);
  const observacoes = buildObservacoes({ paymentPlan, diff, parserMode, periodicidadeValor: unit.periodicidadeValor });
  const raw = {
    empreendimento,
    torre: "",
    final: inferFinalFromUnit(unit.unidade),
    andar: unit.andar,
    unidade: unit.unidade,
    area_m2: formatNumber(unit.area_m2),
    preco_total: formatNumber(unit.preco_total),
    sinal_1: formatNumber(unit.sinal_1),
    a4_each: formatNumber(unit.a4_each),
    mensal_qtd: paymentPlan.mensalQtd || "0",
    mensal_each: formatNumber(unit.mensal_each),
    inter_tipo: paymentPlan.interTipo,
    inter_qtd: paymentPlan.interQtd || "0",
    inter_each: formatNumber(unit.inter_each),
    chaves_each: formatNumber(unit.chaves_each),
    financiamento: formatNumber(unit.financiamento),
    observacoes,
  };
  const parsed = {
    id: `${unit.unidade}-${blockIndex}-${index}`,
    ...raw,
    area_m2: unit.area_m2,
    preco_total: unit.preco_total,
    sinal_1: Number(unit.sinal_1 || 0),
    a4_each: Number(unit.a4_each || 0),
    mensal_qtd: Number(paymentPlan.mensalQtd || 0),
    mensal_each: Number(unit.mensal_each || 0),
    inter_tipo: paymentPlan.interTipo,
    inter_qtd: Number(paymentPlan.interQtd || 0),
    inter_each: Number(unit.inter_each || 0),
    chaves_each: Number(unit.chaves_each || 0),
    financiamento: Number(unit.financiamento || 0),
    observacoes,
    raw,
    parser_meta: {
      parser: "parseSplitBlockTable",
      block_index: blockIndex,
      row_index: index,
      matched_financial_row: true,
      parser_mode: parserMode,
      payment_plan: paymentPlan,
      periodicidade_valor: Number(unit.periodicidadeValor || 0),
    },
  };
  return { ...parsed, validation: validateSplitRow(parsed, paymentPlan) };
}

export function parseSplitBlockTable(text, options = {}) {
  const source = compactSpaces(text);
  if (!source) return { rows: [], csvText: CANON_COLUMNS.join(";"), diagnostics: { reason: "empty_source" } };

  const blocks = splitMirrorBlocks(source);
  const rows = [];
  const blockDiagnostics = [];

  blocks.forEach((block, blockIndex) => {
    const normalized = normalizeForMatch(block);
    const hasRequiredHeader = normalized.includes("andar") && normalized.includes("unidade") && normalized.includes("area") && normalized.includes("valor total");
    if (!hasRequiredHeader) return;

    const paymentPlan = extractPaymentPlan(block);
    const empreendimento = extractEmpreendimento(block, options.empreendimento || "");
    const inlineRows = extractInlineFinancialRows(block);
    if (inlineRows.length) {
      inlineRows.forEach((unit, index) => rows.push(makeParsedRow({ unit, paymentPlan, empreendimento, blockIndex, index, parserMode: "inline_financial_rows" })));
      blockDiagnostics.push({ block_index: blockIndex, parser_mode: "inline_financial_rows", units: inlineRows.length, finance_rows: inlineRows.length, invalid_rows: rows.filter((row) => row.parser_meta?.block_index === blockIndex && row.validation?.valid === false).length, payment_plan: paymentPlan, complete: true });
      return;
    }

    const units = extractUnitRows(block);
    if (!units.length) return;
    const moneyValues = extractMoneyValues(block);
    const financeValues = moneyValues.slice(units.length);
    const { financeRows, mode: financeMode, stride } = buildFinanceRows(financeValues, units.length, paymentPlan);

    units.forEach((unit, index) => {
      const financialRow = financeRows[index] || { values: [], periodicidadeValor: 0 };
      const financial = financialRow.values || [];
      rows.push(makeParsedRow({
        unit: { ...unit, sinal_1: Number(financial[0] || 0), a4_each: Number(financial[1] || 0), mensal_each: Number(financial[2] || 0), inter_each: Number(financial[3] || 0), chaves_each: Number(financial[4] || 0), financiamento: Number(financial[5] || 0), periodicidadeValor: Number(financialRow.periodicidadeValor || 0) },
        paymentPlan,
        empreendimento,
        blockIndex,
        index,
        parserMode: financeMode,
      }));
    });
    blockDiagnostics.push({ block_index: blockIndex, parser_mode: financeMode, units: units.length, money_values: moneyValues.length, finance_values: financeValues.length, finance_stride: stride, finance_rows: financeRows.length, invalid_rows: rows.filter((row) => row.parser_meta?.block_index === blockIndex && row.validation?.valid === false).length, payment_plan: paymentPlan, complete: financeRows.length >= units.length });
  });

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseSplitBlockTable",
      blocks: blocks.length,
      parsed_blocks: blockDiagnostics.length,
      total_rows: rows.length,
      invalid_rows: rows.filter((row) => row.validation?.valid === false).length,
      block_diagnostics: blockDiagnostics,
      complete: blockDiagnostics.every((item) => item.complete),
    },
  };
}
