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

const CHECK_TOLERANCE = 1;
const UNIT_PREFIX = "(?:AP|SC|SU|LJ)";
const MONEY_TOKEN = "(?:R\\$|\\$)?\\s*([0-9]{1,3}(?:\\.[0-9]{3})*,[0-9]{2}|[0-9]+,[0-9]{2}|[0-9]{1,3}(?:\\.[0-9]{3})+|[0-9]+)";

function compactSpaces(value = "") {
  return String(value || "")
    .replace(/\u00a0/g, " ")
    .replace(/[ \t]+/g, " ")
    .replace(/\s+\n/g, "\n")
    .replace(/\n\s+/g, "\n")
    .replace(/\s+/g, " ")
    .trim();
}

function normalizeForMatch(value = "") {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\u00a0/g, " ")
    .replace(/\s+/g, " ")
    .toLowerCase()
    .trim();
}

function toNumber(value = "") {
  if (value === 0) return 0;
  const raw = String(value || "").trim();
  if (!raw) return 0;

  let s = raw.replace(/\s+/g, "");
  const hasComma = s.includes(",");
  const hasDot = s.includes(".");
  const numericWithDotsOnly = s.replace(/[^\d.]/g, "");
  const looksLikeBrazilianThousandsOnly = !hasComma && /^\d{1,3}(?:\.\d{3})+$/.test(numericWithDotsOnly);

  if (hasComma && hasDot) s = s.replace(/\./g, "").replace(",", ".");
  else if (hasComma) s = s.replace(/\./g, "").replace(",", ".");
  else if (hasDot && looksLikeBrazilianThousandsOnly) s = s.replace(/\./g, "");

  s = s.replace(/[^\d.-]/g, "");
  const parsed = Number.parseFloat(s);
  return Number.isFinite(parsed) ? parsed : 0;
}

function formatNumber(value, decimals = 2) {
  const parsed = Number(value || 0);
  if (!Number.isFinite(parsed)) return "";
  return parsed.toFixed(decimals).replace(/\.00$/, "").replace(/(\.\d*[1-9])0+$/, "$1");
}

function normalizeMonthYear(value = "") {
  const match = String(value || "").match(/\b(\d{1,2})\/(\d{4})\b/);
  return match ? `${match[2]}-${String(Number.parseInt(match[1], 10)).padStart(2, "0")}` : "";
}

function escapeRegExp(value = "") {
  return String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function extractPaymentDate(source = "", label = "ATO") {
  const normalized = compactSpaces(source);
  const labelRegex = escapeRegExp(label).replace(/\s+/g, "\\s+");
  const match = normalized.match(new RegExp(`${labelRegex}\\s+(\\d{1,2}\\/\\d{4})`, "i"));
  return match ? normalizeMonthYear(match[1]) : "";
}

function inferFinalFromUnit(unit = "") {
  const digits = String(unit || "").replace(/\D/g, "");
  return digits.length >= 2 ? digits.slice(-2) : "";
}

function inferAndarFromUnit(unit = "") {
  const digits = String(unit || "").replace(/\D/g, "").padStart(4, "0");
  const andar = Number.parseInt(digits.slice(0, -2), 10);
  return Number.isFinite(andar) ? String(andar) : "";
}

function extractEmpreendimento(text = "", fallback = "") {
  if (fallback) return fallback;
  const normalized = compactSpaces(text);

  const match = normalized.match(/EMPREENDIMENTO\s*[:.]*\s*([^\n]+?)(?:\s+ENDEREÇO|\s+ENDERECO|\s+1\.?\s*DATA|$)/i);
  if (match?.[1]) return compactSpaces(match[1]).replace(/\.{2,}/g, "").replace(/\s*:\s*$/, "");

  const known = [
    [/ELO\s+Duo\s*-\s*Caminhos\s+da\s+Lapa/i, "ELO Duo - Caminhos da Lapa"],
    [/ELO\s+2\s+CAMINHOS\s+DA\s+LAPA\s*-\s*TORRE\s+B/i, "ELO 2 Caminhos da Lapa - Torre B"],
    [/TEG\s*-?\s*SACOM[ÃA]/i, "TEG Sacomã"],
    [/BEM\s+MOEMA/i, "Bem Moema"],
    [/[ÓO]RBITA/i, "Órbita"],
  ];
  for (const [regex, name] of known) {
    if (regex.test(normalized)) return name;
  }

  return "";
}

function buildObservacoes({ vagas, atoInicio, financMes, diff, atoPercent, financiamentoPercent }) {
  return [
    `vagas=${vagas || 0}`,
    "ato_qtd=1",
    "comp_qtd=0",
    "mensal_qtd=0",
    "inter_qtd=0",
    "unica_qtd=0",
    "financiamento_qtd=1",
    atoInicio ? `ato_inicio=${atoInicio}` : "",
    financMes ? `financ_mes=${financMes}` : "",
    "payment_plan_source=ready_stock_header",
    "payment_model=ato_financiamento_pronto_para_morar",
    "origem=ready_stock_table",
    Number.isFinite(atoPercent) ? `ato_percent=${atoPercent.toFixed(4)}` : "",
    Number.isFinite(financiamentoPercent) ? `financiamento_percent=${financiamentoPercent.toFixed(4)}` : "",
    Number.isFinite(diff) ? `check_diff=${diff.toFixed(2)}` : "",
    `check_tolerance=${CHECK_TOLERANCE.toFixed(2)}`,
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

function validateReadyStockRow(row) {
  const base = validateCanonRow(row);
  const expected = Number(row.sinal_1 || 0) + Number(row.financiamento || 0);
  const diff = Number(row.preco_total || 0) - expected;
  const issues = [...base.issues];

  if (Math.abs(diff) > CHECK_TOLERANCE) {
    issues.push(`soma_ato_financiamento_difere_total=${diff.toFixed(2)};tolerancia=${CHECK_TOLERANCE.toFixed(2)}`);
  }

  return {
    valid: issues.length === 0,
    issues,
  };
}

function makeParsedRow({ empreendimento, unidade, area, vagas, ato, financiamento, total, atoInicio, financMes, index }) {
  const diff = total - (ato + financiamento);
  const atoPercent = total > 0 ? ato / total : Number.NaN;
  const financiamentoPercent = total > 0 ? financiamento / total : Number.NaN;
  const raw = {
    empreendimento,
    torre: "",
    final: inferFinalFromUnit(unidade),
    andar: inferAndarFromUnit(unidade),
    unidade,
    area_m2: formatNumber(area),
    preco_total: formatNumber(total),
    sinal_1: formatNumber(ato),
    a4_each: "0",
    mensal_qtd: "0",
    mensal_each: "0",
    inter_tipo: "",
    inter_qtd: "0",
    inter_each: "0",
    chaves_each: "0",
    financiamento: formatNumber(financiamento),
    observacoes: buildObservacoes({ vagas, atoInicio, financMes, diff, atoPercent, financiamentoPercent }),
  };

  const parsed = {
    id: `${unidade}-${index}`,
    ...raw,
    area_m2: area,
    preco_total: total,
    sinal_1: ato,
    a4_each: 0,
    mensal_qtd: 0,
    mensal_each: 0,
    inter_tipo: "",
    inter_qtd: 0,
    inter_each: 0,
    chaves_each: 0,
    financiamento,
    raw,
    parser_meta: {
      parser: "parseReadyStockTable",
      payment_model: "ato_financiamento_pronto_para_morar",
      payment_plan: {
        atoQtd: 1,
        compQtd: 0,
        mensalQtd: 0,
        interQtd: 0,
        unicaQtd: 0,
        financiamentoQtd: 1,
        atoInicio,
        financMes,
        source: "ready_stock_header",
        tolerance: CHECK_TOLERANCE,
      },
    },
  };

  return {
    ...parsed,
    validation: validateReadyStockRow(parsed),
  };
}

export function parseReadyStockTable(text, options = {}) {
  const source = compactSpaces(text);
  if (!source) {
    return {
      rows: [],
      csvText: CANON_COLUMNS.join(";"),
      diagnostics: { parser: "parseReadyStockTable", reason: "empty_source" },
    };
  }

  const normalized = normalizeForMatch(source);
  const unitRegex = new RegExp(`\\b${UNIT_PREFIX}\\d{4}\\b`, "i");
  const rowProbeRegex = new RegExp(
    `\\b${UNIT_PREFIX}\\d{4}\\b\\s+\\d{1,4}(?:[,.]\\d{1,3})?\\s+\\d{1,2}(?:\\s+Moto)?\\s+${MONEY_TOKEN}\\s+${MONEY_TOKEN}\\s+${MONEY_TOKEN}`,
    "i"
  );
  const looksReadyStock =
    normalized.includes("unidade") &&
    normalized.includes("area") &&
    normalized.includes("vagas") &&
    normalized.includes("ato") &&
    normalized.includes("financiamento") &&
    normalized.includes("total") &&
    unitRegex.test(source) &&
    rowProbeRegex.test(source) &&
    !normalized.includes("mensais") &&
    !normalized.includes("c. ato") &&
    !normalized.includes("complemento ato");

  if (!looksReadyStock) {
    return {
      rows: [],
      csvText: CANON_COLUMNS.join(";"),
      diagnostics: { parser: "parseReadyStockTable", reason: "layout_not_matched" },
    };
  }

  const atoInicio = extractPaymentDate(source, "ATO");
  const financMes = extractPaymentDate(source, "FINANCIAMENTO");
  const empreendimento = extractEmpreendimento(source, options.empreendimento || "");
  const rows = [];

  const rowRegex = new RegExp(
    `\\b(${UNIT_PREFIX}\\d{4})\\s+` +
      `(\\d{1,4}(?:[,.]\\d{1,3})?)\\s+` +
      `(\\d{1,2})(?:\\s+Moto)?\\s+` +
      `${MONEY_TOKEN}\\s+${MONEY_TOKEN}\\s+${MONEY_TOKEN}\\b`,
    "gi"
  );
  let match;

  while ((match = rowRegex.exec(source)) !== null) {
    const unidade = match[1].toUpperCase();
    const area = toNumber(match[2]);
    const vagas = Number.parseInt(match[3], 10) || 0;
    const ato = toNumber(match[4]);
    const financiamento = toNumber(match[5]);
    const total = toNumber(match[6]);

    if (!area || !ato || !financiamento || !total) continue;

    rows.push(makeParsedRow({
      empreendimento,
      unidade,
      area,
      vagas,
      ato,
      financiamento,
      total,
      atoInicio,
      financMes,
      index: rows.length,
    }));
  }

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseReadyStockTable",
      total_rows: rows.length,
      invalid_rows: rows.filter((row) => row.validation?.valid === false).length,
      payment_model: "ato_financiamento_pronto_para_morar",
      payment_plan: {
        atoQtd: 1,
        compQtd: 0,
        mensalQtd: 0,
        interQtd: 0,
        unicaQtd: 0,
        financiamentoQtd: 1,
        atoInicio,
        financMes,
        source: "ready_stock_header",
        tolerance: CHECK_TOLERANCE,
      },
      complete: rows.length > 0,
    },
  };
}
