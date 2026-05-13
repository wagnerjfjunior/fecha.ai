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

function escapeRegExp(value = "") {
  return String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
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
  const labelNorm = escapeRegExp(normalizeForMatch(label));
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

function getQtyBeforeLabel(source = "", labelRegex) {
  const normalized = compactSpaces(source);
  const matches = [...normalized.matchAll(new RegExp(`(?:^|\\s)(\\d{1,3})\\s+(?:parcela[s]?\\s+)?${labelRegex}`, "gi"))];
  if (!matches.length) return null;
  const values = matches.map((match) => Number.parseInt(match[1], 10)).filter((value) => Number.isFinite(value));
  return values.length ? values[0] : null;
}

function getHeaderWindow(source = "") {
  const firstRow = String(source || "").search(/\b(?:AP|SC|SU|LJ)\d{4}\b/i);
  return firstRow > 0 ? source.slice(0, firstRow) : source.slice(0, 2000);
}

function extractHeaderPaymentPlan(source = "") {
  const header = getHeaderWindow(source);
  const atoQtd = getQtyBeforeLabel(header, "(?:SINAL\\s+)?ATO\\b");
  const compQtd = getQtyBeforeLabel(header, "(?:COMPLEMENTO\\s+ATO|C\\.?\\s*ATO)\\b");
  const mensalQtd = getQtyBeforeLabel(header, "MENS(?:AIS|AL)\\b");
  const unicaQtd = getQtyBeforeLabel(header, "(?:PARCELA\\s+)?[ÚU]NICA\\b");
  const financiamentoQtd = getQtyBeforeLabel(header, "FINANCIAMENTO\\b");

  const plan = {
    atoQtd: atoQtd ?? 1,
    compQtd: compQtd ?? null,
    mensalQtd: mensalQtd ?? null,
    interQtd: 0,
    unicaQtd: unicaQtd ?? 1,
    financiamentoQtd: financiamentoQtd ?? 1,
    source: "launch_flat_header_dynamic",
  };

  const unresolved = [];
  if (plan.compQtd == null) unresolved.push("compQtd");
  if (plan.mensalQtd == null) unresolved.push("mensalQtd");
  return { ...plan, unresolved };
}

function inferLaunchPaymentPlan(rows = [], partialPlan = {}) {
  const usableRows = rows.filter((row) => row.total > 0 && row.ato > 0 && row.financiamento > 0).slice(0, 60);
  const compCandidates = partialPlan.compQtd == null ? Array.from({ length: 13 }, (_, index) => index) : [partialPlan.compQtd];
  const mensalCandidates = partialPlan.mensalQtd == null ? Array.from({ length: 121 }, (_, index) => index) : [partialPlan.mensalQtd];

  let best = null;
  for (const compQtd of compCandidates) {
    for (const mensalQtd of mensalCandidates) {
      let totalAbsDiff = 0;
      let maxAbsDiff = 0;
      let invalidCount = 0;
      for (const row of usableRows) {
        const expected =
          row.ato * Number(partialPlan.atoQtd || 1) +
          row.comp * compQtd +
          row.mensal * mensalQtd +
          row.unica * Number(partialPlan.unicaQtd || 1) +
          row.financiamento * Number(partialPlan.financiamentoQtd || 1);
        const diff = Math.abs(row.total - expected);
        totalAbsDiff += diff;
        maxAbsDiff = Math.max(maxAbsDiff, diff);
        if (diff > CHECK_TOLERANCE) invalidCount += 1;
      }
      const score = invalidCount * 1_000_000_000 + totalAbsDiff;
      if (!best || score < best.score) best = { compQtd, mensalQtd, totalAbsDiff, maxAbsDiff, invalidCount, score };
    }
  }

  if (!best) {
    return {
      ...partialPlan,
      compQtd: Number(partialPlan.compQtd || 0),
      mensalQtd: Number(partialPlan.mensalQtd || 0),
      source: "payment_plan_unresolved",
      warning: "payment_plan_unresolved",
    };
  }

  const inferredFields = [];
  if (partialPlan.compQtd == null) inferredFields.push("compQtd");
  if (partialPlan.mensalQtd == null) inferredFields.push("mensalQtd");

  return {
    ...partialPlan,
    compQtd: best.compQtd,
    mensalQtd: best.mensalQtd,
    source: inferredFields.length ? "launch_flat_inferred_by_total" : partialPlan.source,
    inferredFields,
    inference: {
      sampleRows: usableRows.length,
      maxAbsDiff: best.maxAbsDiff,
      totalAbsDiff: best.totalAbsDiff,
      invalidCount: best.invalidCount,
    },
  };
}

function buildObservacoes({ plan, unicaIso, unicaLabel, atoInicio, compInicio, mensalMes, financMes, diff, atoPercent, compPercent, mensalPercent, unicaPercent, financiamentoPercent }) {
  return [
    "vagas=1",
    `ato_qtd=${plan.atoQtd || 1}`,
    `comp_qtd=${plan.compQtd || 0}`,
    `mensal_qtd=${plan.mensalQtd || 0}`,
    `inter_qtd=${plan.interQtd || 0}`,
    `unica_qtd=${plan.unicaQtd || 1}`,
    `financiamento_qtd=${plan.financiamentoQtd || 1}`,
    atoInicio ? `ato_inicio=${atoInicio}` : "",
    compInicio ? `comp_inicio=${compInicio}` : "",
    mensalMes ? `mensal_mes=${mensalMes}` : "",
    unicaIso ? `unica_mes=${unicaIso}` : "",
    unicaLabel ? `unica_label=${unicaLabel}` : "",
    financMes ? `financ_mes=${financMes}` : "",
    `payment_plan_source=${plan.source}`,
    plan.warning ? `payment_plan_warning=${plan.warning}` : "",
    plan.inferredFields?.length ? `payment_plan_inferred_fields=${plan.inferredFields.join(",")}` : "",
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
  const plan = row.parser_meta?.payment_plan || {};
  const expected =
    Number(row.sinal_1 || 0) * Number(plan.atoQtd || 1) +
    Number(row.a4_each || 0) * Number(plan.compQtd || 0) +
    Number(row.mensal_each || 0) * Number(row.mensal_qtd || 0) +
    Number(row.chaves_each || 0) * Number(plan.unicaQtd || 1) +
    Number(row.financiamento || 0) * Number(plan.financiamentoQtd || 1);
  const diff = Number(row.preco_total || 0) - expected;
  const issues = [...base.issues];
  if (plan.warning === "payment_plan_unresolved") issues.push("payment_plan_unresolved");
  if (Math.abs(diff) > CHECK_TOLERANCE) issues.push(`soma_fluxo_difere_total=${diff.toFixed(2)};tolerancia=${CHECK_TOLERANCE.toFixed(2)}`);
  return { valid: issues.length === 0, issues };
}

function makeParsedRow({ empreendimento, unidade, area, ato, comp, mensal, unica, financiamento, total, plan, atoInicio, compInicio, mensalMes, unicaIso, unicaLabel, financMes, index }) {
  const expected = ato * Number(plan.atoQtd || 1) + comp * Number(plan.compQtd || 0) + mensal * Number(plan.mensalQtd || 0) + unica * Number(plan.unicaQtd || 1) + financiamento * Number(plan.financiamentoQtd || 1);
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
    mensal_qtd: String(plan.mensalQtd || 0),
    mensal_each: formatNumber(mensal),
    inter_tipo: "",
    inter_qtd: "0",
    inter_each: "0",
    chaves_each: formatNumber(unica),
    financiamento: formatNumber(financiamento),
    observacoes: buildObservacoes({
      plan,
      unicaIso,
      unicaLabel,
      atoInicio,
      compInicio,
      mensalMes,
      financMes,
      diff,
      atoPercent: total > 0 ? (ato * Number(plan.atoQtd || 1)) / total : Number.NaN,
      compPercent: total > 0 ? (comp * Number(plan.compQtd || 0)) / total : Number.NaN,
      mensalPercent: total > 0 ? (mensal * Number(plan.mensalQtd || 0)) / total : Number.NaN,
      unicaPercent: total > 0 ? (unica * Number(plan.unicaQtd || 1)) / total : Number.NaN,
      financiamentoPercent: total > 0 ? (financiamento * Number(plan.financiamentoQtd || 1)) / total : Number.NaN,
    }),
  };
  const parsed = {
    id: `${unidade}-${index}`,
    ...raw,
    area_m2: area,
    preco_total: total,
    sinal_1: ato,
    a4_each: comp,
    mensal_qtd: Number(plan.mensalQtd || 0),
    mensal_each: mensal,
    inter_tipo: "",
    inter_qtd: 0,
    inter_each: 0,
    chaves_each: unica,
    financiamento,
    raw,
    parser_meta: {
      parser: "parseLaunchFlatPaymentTable",
      parser_mode: "launch_flat_payment_table",
      payment_model: "ato_comp_mensal_unica_financiamento",
      payment_plan: { ...plan, interQtd: 0, atoInicio, compInicio, mensalMes, unicaMes: unicaIso, financMes, tolerance: CHECK_TOLERANCE },
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
    /\b(AP|SC|SU|LJ)\d{4}\b/i.test(source);

  if (!looksLaunchFlat) return { rows: [], csvText: CANON_COLUMNS.join(";"), diagnostics: { parser: "parseLaunchFlatPaymentTable", reason: "layout_not_matched" } };

  const atoInicio = extractPaymentDate(source, "ATO");
  const compInicio = extractPaymentDate(source, "COMPLEMENTO ATO");
  const mensalMes = extractPaymentDate(source, "MENSAIS");
  const unicaIso = extractPaymentDate(source, "UNICA");
  const unicaLabel = displayMonthYear(unicaIso ? `${unicaIso.slice(5, 7)}/${unicaIso.slice(0, 4)}` : "");
  const financMes = extractPaymentDate(source, "FINANCIAMENTO");
  const empreendimento = extractEmpreendimento(source, options.empreendimento || "");

  const rowCandidates = [];
  const rowRegex = new RegExp(
    `\\b((?:AP|SC|SU|LJ)\\d{4})\\s+` +
    `(\\d{1,4}(?:[,.]\\d{1,3})?)\\s+` +
    `${MONEY_TOKEN}\\s+${MONEY_TOKEN}\\s+${MONEY_TOKEN}\\s+${MONEY_TOKEN}\\s+${MONEY_TOKEN}\\s+${MONEY_TOKEN}\\b`,
    "gi"
  );
  let match;
  while ((match = rowRegex.exec(source)) !== null) {
    const candidate = {
      unidade: match[1].toUpperCase(),
      area: toNumber(match[2]),
      ato: toNumber(match[3]),
      comp: toNumber(match[4]),
      mensal: toNumber(match[5]),
      unica: toNumber(match[6]),
      financiamento: toNumber(match[7]),
      total: toNumber(match[8]),
    };
    if (!candidate.area || !candidate.ato || !candidate.comp || !candidate.mensal || !candidate.unica || !candidate.financiamento || !candidate.total) continue;
    rowCandidates.push(candidate);
  }

  const headerPlan = extractHeaderPaymentPlan(source);
  const plan = inferLaunchPaymentPlan(rowCandidates, headerPlan);
  const rows = rowCandidates.map((candidate, index) => makeParsedRow({ empreendimento, ...candidate, plan, atoInicio, compInicio, mensalMes, unicaIso, unicaLabel, financMes, index }));

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseLaunchFlatPaymentTable",
      parser_mode: "launch_flat_payment_table",
      total_rows: rows.length,
      invalid_rows: rows.filter((row) => row.validation?.valid === false).length,
      payment_model: "ato_comp_mensal_unica_financiamento",
      payment_plan: { ...plan, atoInicio, compInicio, mensalMes, unicaMes: unicaIso, unicaLabel, financMes, tolerance: CHECK_TOLERANCE },
      payment_plan_inference: plan.inference || null,
      complete: rows.length > 0,
    },
  };
}
