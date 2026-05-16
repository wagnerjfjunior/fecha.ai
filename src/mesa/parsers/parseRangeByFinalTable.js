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

const FALLBACK_PAYMENT_META = {
  atoQtd: 1,
  compQtd: 3,
  mensalQtd: 35,
  interQtd: 3,
  unicaQtd: 1,
  financiamentoQtd: 1,
  interTipo: "anual",
  source: "fallback",
};

const MIN_PAYMENT_DIFF_TOLERANCE = 100;
const ROUNDING_UNIT = 100;
const ROUNDING_MARGIN = 100;

const MONTHS_PT = {
  jan: "01",
  fev: "02",
  mar: "03",
  abr: "04",
  mai: "05",
  jun: "06",
  jul: "07",
  ago: "08",
  set: "09",
  out: "10",
  nov: "11",
  dez: "12",
};

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

function areaToNumber(value = "") {
  const normalized = String(value || "").trim().replace(/\./g, "").replace(",", ".").replace(/[^\d.]/g, "");
  const parsed = Number.parseFloat(normalized);
  return Number.isFinite(parsed) ? parsed : 0;
}

function moneyToNumber(value = "") {
  const normalized = String(value || "").trim().replace(/\./g, "").replace(/,/g, ".").replace(/[^\d.]/g, "");
  const parsed = Number.parseFloat(normalized);
  return Number.isFinite(parsed) ? parsed : 0;
}

function formatNumber(value, decimals = 2) {
  const parsed = Number(value || 0);
  if (!Number.isFinite(parsed)) return "";
  return parsed.toFixed(decimals).replace(/\.00$/, "").replace(/(\.\d*[1-9])0+$/, "$1");
}

function parseFinals(label = "") {
  const finals = [...String(label || "").matchAll(/\d{1,2}/g)].map((match) => match[0].padStart(2, "0"));
  return [...new Set(finals)];
}

function parseFloorRange(label = "") {
  const floors = [...String(label || "").matchAll(/\d{1,2}/g)].map((match) => Number.parseInt(match[0], 10));
  if (!floors.length) return [];
  if (floors.length === 1) return floors;
  const start = Math.min(floors[0], floors[1]);
  const end = Math.max(floors[0], floors[1]);
  return Array.from({ length: end - start + 1 }, (_, index) => start + index);
}

function extractUnitsPerFloor(text = "") {
  const normalized = compactSpaces(text);
  const match = normalized.match(/N[ÚU]MERO\s+DE\s+UNIDADES\s+POR\s+ANDAR\s*:\s*(\d{1,2})/i);
  const value = Number.parseInt(match?.[1] || "", 10);
  return Number.isFinite(value) && value > 0 ? value : null;
}

function inferGeneratedUnitFormat({ text = "", finals = [] } = {}) {
  const unitsPerFloor = extractUnitsPerFloor(text);
  const finalNumbers = finals
    .map((final) => Number.parseInt(String(final || "").replace(/\D/g, ""), 10))
    .filter((value) => Number.isFinite(value) && value > 0);

  if (
    unitsPerFloor &&
    unitsPerFloor <= 9 &&
    finalNumbers.length > 0 &&
    Math.max(...finalNumbers) <= unitsPerFloor
  ) {
    return "floor3_final1";
  }

  return "floor2_final2";
}

function unitCode(andar, final, unitFormat = "floor2_final2") {
  const floorNumber = Number.parseInt(String(andar || "").replace(/\D/g, ""), 10);
  const finalNumber = Number.parseInt(String(final || "").replace(/\D/g, ""), 10);

  if (!Number.isFinite(floorNumber) || !Number.isFinite(finalNumber)) {
    return `AP${String(andar).padStart(2, "0")}${String(final).padStart(2, "0")}`;
  }

  if (unitFormat === "floor3_final1" && finalNumber <= 9) {
    return `AP${String(floorNumber).padStart(3, "0")}${String(finalNumber)}`;
  }

  return `AP${String(floorNumber).padStart(2, "0")}${String(finalNumber).padStart(2, "0")}`;
}

function explicitUnitToAndarFinal(unit = "", unitFormat = "floor2_final2") {
  const digits = String(unit || "").replace(/\D/g, "").padStart(4, "0");

  if (unitFormat === "floor3_final1") {
    return {
      andar: String(Number.parseInt(digits.slice(0, 3), 10)),
      final: digits.slice(3).padStart(2, "0"),
    };
  }

  return {
    andar: String(Number.parseInt(digits.slice(0, -2), 10)),
    final: digits.slice(-2),
  };
}

function extractEmpreendimento(text = "", fallback = "") {
  if (fallback) return fallback;
  const normalized = compactSpaces(text);
  const empreendimento = normalized.match(/EMPREENDIMENTO:\s*([^\n]+?)(?:\s+ENDEREÇO|\s+ENDERECO|$)/i);
  if (empreendimento?.[1]) return compactSpaces(empreendimento[1]);
  const title = normalized.match(/Tabela\s+de\s+Lançamento\s*-\s*([^\n]+?)(?:\s+UNIDADE|\s+VALOR\s+TOTAL|\s+1\s+3\s+\d{1,2}\s+\d{1,2}\s+1\s+1)/i);
  if (title?.[1]) return compactSpaces(title[1]);
  if (/Garden\s+Design/i.test(normalized)) return "Garden Design Private Park Residence";
  return "";
}

function isPaymentPlanCandidate(values = []) {
  if (!Array.isArray(values) || values.length !== 6 || values.some((value) => !Number.isFinite(value))) return false;
  const [atoQtd, compQtd, mensalQtd, interQtd, unicaQtd, financiamentoQtd] = values;
  return atoQtd >= 0 && atoQtd <= 5 && compQtd >= 0 && compQtd <= 12 && mensalQtd >= 1 && mensalQtd <= 120 && interQtd >= 0 && interQtd <= 12 && unicaQtd >= 0 && unicaQtd <= 5 && financiamentoQtd >= 0 && financiamentoQtd <= 5;
}

function parseHeaderNumbers(header = "") {
  const compact = compactSpaces(header);
  const candidates = [...compact.matchAll(/(?:^|\s)(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})(?:\s|$)/g)]
    .map((match) => match.slice(1, 7).map((value) => Number.parseInt(value, 10)))
    .filter(isPaymentPlanCandidate);
  if (!candidates.length) return null;
  return candidates.find((values) => values[2] >= 6) || candidates[0];
}

function normalizePaymentDate(value = "") {
  const raw = normalizeForMatch(value).replace(/\./g, "");
  const withDay = raw.match(/\b(\d{1,2})-(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)-(\d{2})\b/i);
  if (withDay) {
    const month = MONTHS_PT[withDay[2]];
    return month ? `20${withDay[3]}-${month}-${withDay[1].padStart(2, "0")}` : value;
  }
  const monthYear = raw.match(/\b(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)-(\d{2})\b/i);
  if (monthYear) {
    const month = MONTHS_PT[monthYear[1]];
    return month ? `20${monthYear[2]}-${month}` : value;
  }
  return value;
}

function parseHeaderDates(header = "") {
  const dates = [...String(header || "").matchAll(/\b(?:\d{1,2}-)?(?:jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)-\d{2}\b/gi)].map((match) => normalizePaymentDate(match[0]));
  return dates.length >= 6 ? dates.slice(0, 7) : [];
}

function findFinancialHeaderIndex(source = "") {
  const directHeaderRegex = /(\d{1,3}\s+\d{1,3}\s+\d{1,3}\s+\d{1,3}\s+\d{1,3}\s+\d{1,3})\s+[ÁA]REA\s+VAGAS\s+ATO\s+C\.?\s*ATO\s+MENSAIS\s+ANUAIS\s+[ÚU]NICA\s+FINANCIAMENTO/i;
  const direct = source.match(directHeaderRegex);
  if (direct?.index != null) return direct.index;
  const financialHeaderRegex = /[ÁA]REA\s+VAGAS\s+ATO\s+C\.?\s*ATO\s+MENSAIS\s+ANUAIS\s+[ÚU]NICA\s+FINANCIAMENTO/i;
  const label = source.match(financialHeaderRegex);
  if (label?.index != null) return Math.max(0, label.index - 160);
  return -1;
}

function extractFinancialHeaderWindow(source = "") {
  const index = findFinancialHeaderIndex(source);
  if (index < 0) return "";
  return source.slice(index, Math.min(source.length, index + 900));
}

function getPaymentDiffTolerance(paymentPlan = FALLBACK_PAYMENT_META) {
  const installmentCount = Number(paymentPlan.atoQtd || 0) + Number(paymentPlan.compQtd || 0) + Number(paymentPlan.mensalQtd || 0) + Number(paymentPlan.interQtd || 0) + Number(paymentPlan.unicaQtd || 0) + Number(paymentPlan.financiamentoQtd || 0);
  const roundingTolerance = installmentCount * (ROUNDING_UNIT / 2) + ROUNDING_MARGIN;
  return Math.max(MIN_PAYMENT_DIFF_TOLERANCE, Math.ceil(roundingTolerance));
}

function extractPaymentPlan(text = "") {
  const source = compactSpaces(text);
  const financialHeaderWindow = extractFinancialHeaderWindow(source);
  const headerEnd = financialHeaderWindow ? source.indexOf(financialHeaderWindow) + financialHeaderWindow.length : source.search(/Final\s+0?\d{1,2}\s+(?:\d{1,2}\s*(?:º|o|°|a\.)?|Garden\s+AP)/i);
  const header = headerEnd > -1 ? source.slice(0, headerEnd) : source.slice(0, 1500);
  const numbers = parseHeaderNumbers(financialHeaderWindow) || parseHeaderNumbers(header);
  const windowDates = parseHeaderDates(financialHeaderWindow);
  const dates = windowDates.length ? windowDates : parseHeaderDates(header);
  if (!numbers) {
    const fallback = { ...FALLBACK_PAYMENT_META, dates, warning: "payment_plan_header_not_found" };
    return { ...fallback, tolerance: getPaymentDiffTolerance(fallback) };
  }
  const [atoQtd, compQtd, mensalQtd, interQtd, unicaQtd, financiamentoQtd] = numbers;
  const paymentPlan = {
    atoQtd,
    compQtd,
    mensalQtd,
    interQtd,
    unicaQtd,
    financiamentoQtd,
    interTipo: "anual",
    atoInicio: dates[0] || "",
    complementoInicio: dates[1] || "",
    mensalInicio: dates[2] || "",
    anualInicio: dates[3] || "",
    unica: dates[4] || "",
    financMes: dates[5] || "",
    periodicidadeData: dates[6] || "",
    dates,
    source: financialHeaderWindow ? "financial_header" : "header",
  };
  return { ...paymentPlan, tolerance: getPaymentDiffTolerance(paymentPlan) };
}

function rowToCsv(row) {
  return CANON_COLUMNS.map((key) => String(row[key] ?? "").replace(/[\r\n;]+/g, " ").trim()).join(";");
}

export function rowsToCanonCsv(rows = []) {
  return [CANON_COLUMNS.join(";"), ...rows.map((row) => rowToCsv(row.raw || row))].join("\n");
}

function calcDiff({ total, sinal, complemento, mensal, anual, unica, financiamento, periodicidade = 0, paymentPlan }) {
  return total - (sinal * Number(paymentPlan.atoQtd || 1) + complemento * Number(paymentPlan.compQtd || 0) + mensal * Number(paymentPlan.mensalQtd || 0) + anual * Number(paymentPlan.interQtd || 0) + unica * Number(paymentPlan.unicaQtd || 1) + financiamento * Number(paymentPlan.financiamentoQtd || 1) + Number(periodicidade || 0));
}

function buildObservacoes({ vagas, faixaAndar, diff, paymentPlan, explicitUnit = false, periodicidadeValor = 0 }) {
  const tolerance = Number(paymentPlan.tolerance || getPaymentDiffTolerance(paymentPlan));
  return [
    `vagas=${vagas || 0}`,
    `ato_qtd=${paymentPlan.atoQtd || 1}`,
    `comp_qtd=${paymentPlan.compQtd || 0}`,
    `mensal_qtd=${paymentPlan.mensalQtd || 0}`,
    `inter_qtd=${paymentPlan.interQtd || 0}`,
    `unica_qtd=${paymentPlan.unicaQtd || 1}`,
    `financiamento_qtd=${paymentPlan.financiamentoQtd || 1}`,
    paymentPlan.atoInicio ? `ato_inicio=${paymentPlan.atoInicio}` : "",
    paymentPlan.complementoInicio ? `comp_inicio=${paymentPlan.complementoInicio}` : "",
    paymentPlan.mensalInicio ? `mensal_inicio=${paymentPlan.mensalInicio}` : "",
    paymentPlan.anualInicio ? `anual_inicio=${paymentPlan.anualInicio}` : "",
    paymentPlan.unica ? `unica=${paymentPlan.unica}` : "",
    paymentPlan.financMes ? `financ_mes=${paymentPlan.financMes}` : "",
    Number(periodicidadeValor || 0) > 0 ? `periodicidade_valor=${formatNumber(periodicidadeValor)}` : "",
    Number(periodicidadeValor || 0) > 0 && paymentPlan.periodicidadeData ? `periodicidade_data=${paymentPlan.periodicidadeData}` : "",
    Number(periodicidadeValor || 0) > 0 ? "periodicidade_alerta=true" : "",
    paymentPlan.warning ? `payment_plan_warning=${paymentPlan.warning}` : "",
    `payment_plan_source=${paymentPlan.source}`,
    "payment_rounding_tolerance=dynamic_by_installment_count",
    "origem=range_by_final_table",
    explicitUnit ? "explicit_unit=true" : "",
    faixaAndar ? `faixa_andar=${faixaAndar}` : "",
    Number.isFinite(diff) ? `check_diff=${diff.toFixed(2)}` : "",
    `check_tolerance=${tolerance.toFixed(2)}`,
  ].filter(Boolean).join(" | ");
}

function paymentDiff(row) {
  const plan = row.parser_meta?.payment_plan || FALLBACK_PAYMENT_META;
  const periodicidade = Number(row.parser_meta?.periodicidade?.valor || 0);
  const expected = Number(row.sinal_1 || 0) * Number(plan.atoQtd || 1) + Number(row.a4_each || 0) * Number(plan.compQtd || 0) + Number(row.mensal_each || 0) * Number(plan.mensalQtd || 0) + Number(row.inter_each || 0) * Number(plan.interQtd || 0) + Number(row.chaves_each || 0) * Number(plan.unicaQtd || 1) + Number(row.financiamento || 0) * Number(plan.financiamentoQtd || 1) + periodicidade;
  return Number(row.preco_total || 0) - expected;
}

function validateRangeRow(row) {
  const base = validateCanonRow(row);
  const diff = paymentDiff(row);
  const tolerance = Number(row.parser_meta?.payment_plan?.tolerance || getPaymentDiffTolerance(row.parser_meta?.payment_plan));
  const issues = [...base.issues];
  if (Math.abs(diff) > tolerance) {
    issues.push(`soma_fluxo_difere_valor_total=${diff.toFixed(2)};tolerancia=${tolerance.toFixed(2)}`);
  }
  return { valid: issues.length === 0, issues };
}

function removeNonFinancialNoise(text = "") {
  const normalized = compactSpaces(text);
  const financialHeaderIndex = findFinancialHeaderIndex(normalized);
  if (financialHeaderIndex >= 0) return normalized.slice(financialHeaderIndex);
  const first = normalized.search(/Final\s+0?1\b|Final\s+0?3\b|Garden\s+AP\d{4}/i);
  return first >= 0 ? normalized.slice(first) : normalized;
}

function makeParsedRow({ empreendimento, final, andar, unidade, area, vagas, sinal, complemento, mensal, anual, unica, financiamento, periodicidade = 0, total, faixaAndar, finalIndex, rowsLength, paymentPlan, explicitUnit = false }) {
  const diff = calcDiff({ total, sinal, complemento, mensal, anual, unica, financiamento, periodicidade, paymentPlan });
  const raw = {
    empreendimento,
    torre: "",
    final,
    andar: String(andar || ""),
    unidade,
    area_m2: formatNumber(area),
    preco_total: formatNumber(total),
    sinal_1: formatNumber(sinal),
    a4_each: formatNumber(complemento),
    mensal_qtd: String(paymentPlan.mensalQtd || 0),
    mensal_each: formatNumber(mensal),
    inter_tipo: paymentPlan.interTipo || "anual",
    inter_qtd: String(paymentPlan.interQtd || 0),
    inter_each: formatNumber(anual),
    chaves_each: formatNumber(unica),
    financiamento: formatNumber(financiamento),
    observacoes: buildObservacoes({ vagas, faixaAndar, diff, paymentPlan, explicitUnit, periodicidadeValor: periodicidade }),
  };
  const parsed = {
    id: `${raw.unidade}-${finalIndex}-${rowsLength}`,
    ...raw,
    area_m2: area,
    preco_total: total,
    sinal_1: sinal,
    a4_each: complemento,
    mensal_qtd: Number(paymentPlan.mensalQtd || 0),
    mensal_each: mensal,
    inter_tipo: paymentPlan.interTipo || "anual",
    inter_qtd: Number(paymentPlan.interQtd || 0),
    inter_each: anual,
    chaves_each: unica,
    financiamento,
    raw,
    parser_meta: {
      parser: "parseRangeByFinalTable",
      final_label: final ? `Final ${final}` : "",
      faixa_andar: faixaAndar,
      explicit_unit: explicitUnit,
      generated_from_range: !explicitUnit,
      payment_plan: paymentPlan,
      periodicidade: Number(periodicidade || 0) > 0 ? { valor: periodicidade, data: paymentPlan.periodicidadeData || "", alerta: true, tipo: "final_simbolico" } : null,
    },
  };
  return { ...parsed, validation: validateRangeRow(parsed) };
}

export function parseRangeByFinalTable(text, options = {}) {
  const source = removeNonFinancialNoise(text);
  if (!source) return { rows: [], csvText: CANON_COLUMNS.join(";"), diagnostics: { parser: "parseRangeByFinalTable", reason: "empty_source" } };

  const normalizedForDetection = normalizeForMatch(source);
  const looksCommercial = /final\s+0?\d{1,2}\b|garden\s+ap\d{4}/i.test(source) && normalizedForDetection.includes("valor total") && normalizedForDetection.includes("financiamento") && (/\d{1,2}\s*(?:º|o|°|a\.)?\s*(?:e|a|ao)\s*\d{1,2}\s*(?:º|o|°)?\s*andar/i.test(source) || /garden\s+ap\d{4}/i.test(source));
  if (!looksCommercial) return { rows: [], csvText: CANON_COLUMNS.join(";"), diagnostics: { parser: "parseRangeByFinalTable", reason: "layout_not_matched" } };

  const paymentPlan = extractPaymentPlan(text);
  const hasPeriodicityColumn = Boolean(paymentPlan.periodicidadeData);
  const finalRegex = /Final\s+((?:\d{1,2})(?:\s*(?:,|e)\s*\d{1,2})*)/gi;
  const finalMatches = [...source.matchAll(finalRegex)];
  const allFinals = [...new Set(finalMatches.flatMap((match) => parseFinals(match[0])))];
  const generatedUnitFormat = inferGeneratedUnitFormat({ text, finals: allFinals });
  const rows = [];
  const finalDiagnostics = [];
  const empreendimento = extractEmpreendimento(text, options.empreendimento || "");

  finalMatches.forEach((finalMatch, finalIndex) => {
    const finalLabel = finalMatch[0];
    const finals = parseFinals(finalLabel);
    const start = finalMatch.index || 0;
    const end = finalMatches[finalIndex + 1]?.index ?? source.length;
    const segment = source.slice(start, end);
    const explicitUnitRegex = hasPeriodicityColumn
      ? /(?:Garden\s+)?(AP\d{4})\s+(\d{1,3},\d{1,2})\s+(\d{1,2})\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)(?:\s+([\d.]+))?\s+([\d.]+)/gi
      : /(?:Garden\s+)?(AP\d{4})\s+(\d{1,3},\d{1,2})\s+(\d{1,2})\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/gi;
    const rowRegex = hasPeriodicityColumn
      ? /((?:\d{1,2}\s*(?:º|o|°|a\.)?\s*(?:ao|a|e)\s*\d{1,2}\s*(?:º|o|°)?|\d{1,2}\s*(?:º|o|°)?)\s*andar)\s+(\d{1,3},\d{1,2})\s+(\d{1,2})\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)(?:\s+([\d.]+))?\s+([\d.]+)/gi
      : /((?:\d{1,2}\s*(?:º|o|°|a\.)?\s*(?:ao|a|e)\s*\d{1,2}\s*(?:º|o|°)?|\d{1,2}\s*(?:º|o|°)?)\s*andar)\s+(\d{1,3},\d{1,2})\s+(\d{1,2})\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/gi;

    let parsedRanges = 0;
    let explicitUnits = 0;
    let generatedUnits = 0;
    let match;

    while ((match = explicitUnitRegex.exec(segment)) !== null) {
      const unidade = match[1].toUpperCase();
      const explicit = explicitUnitToAndarFinal(unidade, generatedUnitFormat);
      const area = areaToNumber(match[2]);
      const vagas = Number.parseInt(match[3], 10) || 0;
      const sinal = moneyToNumber(match[4]);
      const complemento = moneyToNumber(match[5]);
      const mensal = moneyToNumber(match[6]);
      const anual = moneyToNumber(match[7]);
      const unica = moneyToNumber(match[8]);
      const financiamento = moneyToNumber(match[9]);
      const periodicidade = hasPeriodicityColumn ? moneyToNumber(match[10] || "") : 0;
      const total = moneyToNumber(hasPeriodicityColumn ? match[11] : match[10]);
      if (!area || !total) continue;
      explicitUnits += 1;
      rows.push(makeParsedRow({ empreendimento, final: explicit.final, andar: explicit.andar, unidade, area, vagas, sinal, complemento, mensal, anual, unica, financiamento, periodicidade, total, faixaAndar: "Garden", finalIndex, rowsLength: rows.length, paymentPlan, explicitUnit: true }));
      generatedUnits += 1;
    }

    while ((match = rowRegex.exec(segment)) !== null) {
      const faixaAndar = compactSpaces(match[1]);
      const andares = parseFloorRange(faixaAndar);
      const area = areaToNumber(match[2]);
      const vagas = Number.parseInt(match[3], 10) || 0;
      const sinal = moneyToNumber(match[4]);
      const complemento = moneyToNumber(match[5]);
      const mensal = moneyToNumber(match[6]);
      const anual = moneyToNumber(match[7]);
      const unica = moneyToNumber(match[8]);
      const financiamento = moneyToNumber(match[9]);
      const periodicidade = hasPeriodicityColumn ? moneyToNumber(match[10] || "") : 0;
      const total = moneyToNumber(hasPeriodicityColumn ? match[11] : match[10]);
      if (!andares.length || !finals.length || !area || !total) continue;
      parsedRanges += 1;
      finals.forEach((final) => {
        andares.forEach((andar) => {
          rows.push(makeParsedRow({ empreendimento, final, andar, unidade: unitCode(andar, final, generatedUnitFormat), area, vagas, sinal, complemento, mensal, anual, unica, financiamento, periodicidade, total, faixaAndar, finalIndex, rowsLength: rows.length, paymentPlan, explicitUnit: false }));
          generatedUnits += 1;
        });
      });
    }

    finalDiagnostics.push({ final_label: finalLabel, finals, parsed_ranges: parsedRanges, explicit_units: explicitUnits, generated_units: generatedUnits });
  });

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseRangeByFinalTable",
      final_blocks: finalMatches.length,
      parsed_final_blocks: finalDiagnostics.filter((item) => item.parsed_ranges > 0 || item.explicit_units > 0).length,
      total_rows: rows.length,
      invalid_rows: rows.filter((row) => row.validation?.valid === false).length,
      payment_diff_tolerance: Number(paymentPlan.tolerance || getPaymentDiffTolerance(paymentPlan)),
      payment_diff_tolerance_mode: "dynamic_by_installment_count_and_rounding_unit",
      generated_unit_format: generatedUnitFormat,
      has_periodicity_column: hasPeriodicityColumn,
      payment_plan: paymentPlan,
      final_diagnostics: finalDiagnostics,
      complete: rows.length > 0,
    },
  };
}
