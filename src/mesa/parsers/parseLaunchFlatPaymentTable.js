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

const CHECK_TOLERANCE = 10;

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
  let s = raw;
  const hasComma = s.includes(",");
  const hasDot = s.includes(".");
  if (hasComma && hasDot) s = s.replace(/\./g, "").replace(",", ".");
  else if (hasComma) s = s.replace(/\./g, "").replace(",", ".");
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
  if (!match) return "";
  return `${match[2]}-${String(Number.parseInt(match[1], 10)).padStart(2, "0")}`;
}

function displayMonthYear(value = "") {
  const iso = normalizeMonthYear(value);
  if (!iso) return "";
  const [year, month] = iso.split("-");
  return `${month}/${year}`;
}

function extractPaymentDate(source = "", label = "ATO") {
  const normalized = normalizeForMatch(source);
  const labelNorm = normalizeForMatch(label).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const match = normalized.match(new RegExp(`${labelNorm}\\s+(\\d{1,2}\\/\\d{4})`, "i"));
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
  const match = normalized.match(/EMPREENDIMENTO:\s*([^\n]+?)(?:\s+ENDEREÇO:|\s+ENDERECO:|\s+1\.\s*DATA|$)/i);
  if (match?.[1]) return match[1].trim();
  const ypy = normalized.match(/YPY\s+Alto\s+do\s+Ipiranga/i);
  if (ypy) return "YPY Alto do Ipiranga";
  return "";
}

function rowToCsv(row) {
  return CANON_COLUMNS.map((key) => String(row[key] ?? "").replace(/[\r\n;]+/g, " ").trim()).join(";");
}

export function rowsToCanonCsv(rows = []) {
  return [CANON_COLUMNS.join(";"), ...rows.map((row) => rowToCsv(row.raw || row))].join("\n");
}

function buildObservacoes({ compQtd, mensalQtd, unicaIso, unicaLabel, atoInicio, compInicio, mensalMes, financMes, diff, atoPercent, compPercent, mensalPercent, unicaPercent, financiamentoPercent }) {
  return [
    "vagas=1",
    "ato_qtd=1",
    `comp_qtd=${compQtd}`,
    `mensal_qtd=${mensalQtd}`,
    "inter_qtd=0",
    "unica_qtd=1",
    "financiamento_qtd=1",
    atoInicio ? `ato_inicio=${atoInicio}` : "",
    compInicio ? `comp_inicio=${compInicio}` : "",
    mensalMes ? `mensal_mes=${mensalMes}` : "",
    unicaIso ? `unica_mes=${unicaIso}` : "",
    unicaLabel ? `unica_label=${unicaLabel}` : "",
    financMes ? `financ_mes=${financMes}` : "",
    "payment_plan_source=launch_flat_header",
    "payment_model=ato_comp_mensal_unica_financiamento",
    "origem=launch_flat_payment_table",
    Number.isFinite(atoPercent) ? `ato_percent=${atoPercent.toFixed(4)}` : "",
    Number.isFinite(compPercent) ? `comp_percent=${compPercent.toFixed(4)}` : "",
    Number.isFinite(mensalPercent) ? `mensal_percent=${mensalPercent.toFixed(4)}` : "",
    Number.isFinite(unicaPercent) ? `unica_percent=${unicaPercent.toFixed(4)}` : "",
    Number.isFinite(financiamentoPercent) ? `financiamento_percent=${financiamentoPercent.toFixed(4)}` : "",
    Number.isFinite(diff) ? `check_diff=${diff.toFixed(2)}` : "",
    `check_tolerance=${CHECK_TOLERANCE.toFixed(2)}`,
  ].filter(Boolean).join(" | ");
}

function validateLaunchFlatRow(row) {
  const base = validateCanonRow(row);
  const compQtd = Number.parseInt(String(row.observacoes || "").match(/comp_qtd=(\d+)/)?.[1] || "0", 10) || 0;
  const expected =
    Number(row.sinal_1 || 0) +
    Number(row.a4_each || 0) * compQtd +
    Number(row.mensal_each || 0) * Number(row.mensal_qtd || 0) +
    Number(row.chaves_each || 0) +
    Number(row.financiamento || 0);
  const diff = Number(row.preco_total || 0) - expected;
  const issues = [...base.issues];
  if (Math.abs(diff) > CHECK_TOLERANCE) issues.push(`soma_fluxo_difere_total=${diff.toFixed(2)};tolerancia=${CHECK_TOLERANCE.toFixed(2)}`);
  return { valid: issues.length === 0, issues };
}

function makeParsedRow({ empreendimento, unidade, area, ato, comp, mensal, unica, financiamento, total, compQtd, mensalQtd, atoInicio, compInicio, mensalMes, unicaIso, unicaLabel, financMes, index }) {
  const expected = ato + comp * compQtd + mensal * mensalQtd + unica + financiamento;
  const diff = total - expected;
  const raw = {
    empreendimento,
    torre: "",
    final: inferFinalFromUnit(unidade),
    andar: inferAndarFromUnit(unidade),
    unidade,
    area_m2: formatNumber(area),
    preco_total: formatNumber(total),
    sinal_1: formatNumber(ato),
    a4_each: formatNumber(comp),
    mensal_qtd: String(mensalQtd),
    mensal_each: formatNumber(mensal),
    inter_tipo: "",
    inter_qtd: "0",
    inter_each: "0",
    chaves_each: formatNumber(unica),
    financiamento: formatNumber(financiamento),
    observacoes: buildObservacoes({
      compQtd,
      mensalQtd,
      unicaIso,
      unicaLabel,
      atoInicio,
      compInicio,
      mensalMes,
      financMes,
      diff,
      atoPercent: total > 0 ? ato / total : Number.NaN,
      compPercent: total > 0 ? (comp * compQtd) / total : Number.NaN,
      mensalPercent: total > 0 ? (mensal * mensalQtd) / total : Number.NaN,
      unicaPercent: total > 0 ? unica / total : Number.NaN,
      financiamentoPercent: total > 0 ? financiamento / total : Number.NaN,
    }),
  };
  const parsed = {
    id: `${unidade}-${index}`,
    ...raw,
    area_m2: area,
    preco_total: total,
    sinal_1: ato,
    a4_each: comp,
    mensal_qtd: mensalQtd,
    mensal_each: mensal,
    inter_tipo: "",
    inter_qtd: 0,
    inter_each: 0,
    chaves_each: unica,
    financiamento,
    raw,
    parser_meta: {
      parser: "parseLaunchFlatPaymentTable",
      payment_model: "ato_comp_mensal_unica_financiamento",
      payment_plan: { atoQtd: 1, compQtd, mensalQtd, interQtd: 0, unicaQtd: 1, financiamentoQtd: 1, atoInicio, compInicio, mensalMes, unicaMes: unicaIso, financMes, source: "launch_flat_header", tolerance: CHECK_TOLERANCE },
    },
  };
  return { ...parsed, validation: validateLaunchFlatRow(parsed) };
}

export function parseLaunchFlatPaymentTable(text, options = {}) {
  const source = compactSpaces(text);
  if (!source) return { rows: [], csvText: CANON_COLUMNS.join(";"), diagnostics: { parser: "parseLaunchFlatPaymentTable", reason: "empty_source" } };
  const normalized = normalizeForMatch(source);
  const looksLaunchFlat =
    normalized.includes("unidade") &&
    normalized.includes("area") &&
    normalized.includes("ato") &&
    normalized.includes("complemento ato") &&
    normalized.includes("mensais") &&
    normalized.includes("unica") &&
    normalized.includes("financiamento") &&
    normalized.includes("total") &&
    /\bAP\d{4}\b/i.test(source);

  if (!looksLaunchFlat) return { rows: [], csvText: CANON_COLUMNS.join(";"), diagnostics: { parser: "parseLaunchFlatPaymentTable", reason: "layout_not_matched" } };

  const atoInicio = extractPaymentDate(source, "ATO");
  const compInicio = extractPaymentDate(source, "COMPLEMENTO ATO");
  const mensalMes = extractPaymentDate(source, "MENSAIS");
  const unicaIso = extractPaymentDate(source, "UNICA");
  const unicaLabel = displayMonthYear(unicaIso ? `${unicaIso.slice(5, 7)}/${unicaIso.slice(0, 4)}` : "");
  const financMes = extractPaymentDate(source, "FINANCIAMENTO");
  const empreendimento = extractEmpreendimento(source, options.empreendimento || "");

  // YPY/Tegra compact launch tables: COMPLEMENTO ATO is 3 installments, MENSAIS date represents 1 installment month.
  const compQtd = 3;
  const mensalQtd = 1;
  const rows = [];
  const rowRegex = /\b(AP\d{4})\s+(\d{1,3},\d{1,2})\s+R\$\s*([\d.]+(?:,\d{2})?)\s+R\$\s*([\d.]+(?:,\d{2})?)\s+R\$\s*([\d.]+(?:,\d{2})?)\s+R\$\s*([\d.]+(?:,\d{2})?)\s+R\$\s*([\d.]+(?:,\d{2})?)\s+R\$\s*([\d.]+(?:,\d{2})?)\b/gi;
  let match;
  while ((match = rowRegex.exec(source)) !== null) {
    const unidade = match[1].toUpperCase();
    const area = toNumber(match[2]);
    const ato = toNumber(match[3]);
    const comp = toNumber(match[4]);
    const mensal = toNumber(match[5]);
    const unica = toNumber(match[6]);
    const financiamento = toNumber(match[7]);
    const total = toNumber(match[8]);
    if (!area || !ato || !comp || !mensal || !unica || !financiamento || !total) continue;
    rows.push(makeParsedRow({ empreendimento, unidade, area, ato, comp, mensal, unica, financiamento, total, compQtd, mensalQtd, atoInicio, compInicio, mensalMes, unicaIso, unicaLabel, financMes, index: rows.length }));
  }

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseLaunchFlatPaymentTable",
      total_rows: rows.length,
      invalid_rows: rows.filter((row) => row.validation?.valid === false).length,
      payment_model: "ato_comp_mensal_unica_financiamento",
      payment_plan: { atoQtd: 1, compQtd, mensalQtd, interQtd: 0, unicaQtd: 1, financiamentoQtd: 1, atoInicio, compInicio, mensalMes, unicaMes: unicaIso, financMes, source: "launch_flat_header", tolerance: CHECK_TOLERANCE },
      complete: rows.length > 0,
    },
  };
}
