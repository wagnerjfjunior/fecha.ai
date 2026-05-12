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

const PAYMENT_DIFF_ABS_TOLERANCE = 100;

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
  const s = String(value || "").trim().replace(/\./g, "").replace(",", ".").replace(/[^\d.]/g, "");
  const n = Number.parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}

function moneyToNumber(value = "") {
  const s = String(value || "").trim().replace(/\./g, "").replace(/,/g, ".").replace(/[^\d.]/g, "");
  const n = Number.parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}

function formatNumber(value, decimals = 2) {
  const n = Number(value || 0);
  if (!Number.isFinite(n)) return "";
  return n.toFixed(decimals).replace(/\.00$/, "").replace(/(\.\d*[1-9])0+$/, "$1");
}

function parseFinals(label = "") {
  const matches = [...String(label || "").matchAll(/\d{1,2}/g)].map((m) => m[0].padStart(2, "0"));
  return [...new Set(matches)];
}

function parseFloorRange(label = "") {
  const numbers = [...String(label || "").matchAll(/\d{1,2}/g)].map((m) => Number.parseInt(m[0], 10));
  if (!numbers.length) return [];
  if (numbers.length === 1) return numbers;
  const [a, b] = numbers;
  if (!Number.isFinite(a) || !Number.isFinite(b)) return [];
  const start = Math.min(a, b);
  const end = Math.max(a, b);
  return Array.from({ length: end - start + 1 }, (_, i) => start + i);
}

function unitCode(andar, final) {
  return `AP${String(andar).padStart(2, "0")}${String(final).padStart(2, "0")}`;
}

function explicitUnitToAndarFinal(unit = "") {
  const digits = String(unit || "").replace(/\D/g, "").padStart(4, "0");
  if (digits.length < 4) return { andar: "", final: "" };
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
  if (!Array.isArray(values) || values.length !== 6 || values.some((value) => !Number.isFinite(value))) {
    return false;
  }

  const [atoQtd, compQtd, mensalQtd, interQtd, unicaQtd, financiamentoQtd] = values;

  // Bloqueia falso positivo vindo das páginas de espelho/vagas, como:
  // 901 902 905 906 908 909.
  return (
    atoQtd >= 0 && atoQtd <= 5 &&
    compQtd >= 0 && compQtd <= 12 &&
    mensalQtd >= 1 && mensalQtd <= 120 &&
    interQtd >= 0 && interQtd <= 12 &&
    unicaQtd >= 0 && unicaQtd <= 5 &&
    financiamentoQtd >= 0 && financiamentoQtd <= 5
  );
}

function parseHeaderNumbers(header = "") {
  const compact = compactSpaces(header);
  const matches = [...compact.matchAll(/(?:^|\s)(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})\s+(\d{1,3})(?:\s|$)/g)]
    .map((m) => m.slice(1, 7).map((v) => Number.parseInt(v, 10)))
    .filter(isPaymentPlanCandidate);

  if (!matches.length) return null;

  return matches.find((values) => values[2] >= 6) || matches[0];
}

function normalizePaymentDate(value = "") {
  const raw = normalizeForMatch(value).replace(/\./g, "");
  const withDay = raw.match(/\b(\d{1,2})-(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)-(\d{2})\b/i);
  if (withDay) {
    const day = withDay[1].padStart(2, "0");
    const month = MONTHS_PT[withDay[2]];
    const year = `20${withDay[3]}`;
    return month ? `${year}-${month}-${day}` : value;
  }

  const monthYear = raw.match(/\b(jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)-(\d{2})\b/i);
  if (monthYear) {
    const month = MONTHS_PT[monthYear[1]];
    const year = `20${monthYear[2]}`;
    return month ? `${year}-${month}` : value;
  }

  return value;
}

function parseHeaderDates(header = "") {
  const matches = [...String(header || "").matchAll(/\b(?:\d{1,2}-)?(?:jan|fev|mar|abr|mai|jun|jul|ago|set|out|nov|dez)-\d{2}\b/gi)]
    .map((m) => normalizePaymentDate(m[0]));
  if (matches.length < 6) return [];
  return matches.slice(0, 6);
}

function extractFinancialHeaderWindow(source = "") {
  const financialHeaderRegex = /[ÁA]REA\s+VAGAS\s+ATO\s+C\.?\s*ATO\s+MENSAIS\s+ANUAIS\s+[ÚU]NICA\s+FINANCIAMENTO/i;
  const directHeaderRegex = /(\d{1,3}\s+\d{1,3}\s+\d{1,3}\s+\d{1,3}\s+\d{1,3}\s+\d{1,3})\s+[ÁA]REA\s+VAGAS\s+ATO\s+C\.?\s*ATO\s+MENSAIS\s+ANUAIS\s+[ÚU]NICA\s+FINANCIAMENTO/i;

  const direct = source.match(directHeaderRegex);
  if (direct?.index != null) {
    return source.slice(Math.max(0, direct.index - 20), Math.min(source.length, direct.index + 900));
  }

  const label = source.match(financialHeaderRegex);
  if (label?.index != null) {
    return source.slice(Math.max(0, label.index - 160), Math.min(source.length, label.index + 900));
  }

  return "";
}

function extractPaymentPlan(text = "") {
  const source = compactSpaces(text);
  const financialHeaderWindow = extractFinancialHeaderWindow(source);
  const headerEnd = source.search(/Final\s+0?\d{1,2}\s+(?:\d{1,2}\s*(?:º|o|°|a\.)?|Garden\s+AP)/i);
  const header = headerEnd > -1 ? source.slice(0, headerEnd) : source.slice(0, 1500);

  const numbers = parseHeaderNumbers(financialHeaderWindow) || parseHeaderNumbers(header);
  const dates = parseHeaderDates(financialHeaderWindow) || parseHeaderDates(header);

  if (!numbers) {
    return {
      ...FALLBACK_PAYMENT_META,
      dates,
      warning: "payment_plan_header_not_found",
    };
  }

  const [atoQtd, compQtd, mensalQtd, interQtd, unicaQtd, financiamentoQtd] = numbers;
  return {
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
    dates,
    source: financialHeaderWindow ? "financial_header" : "header",
  };
}

function rowToCsv(row) {
  return CANON_COLUMNS.map((key) => String(row[key] ?? "").replace(/[\r\n;]+/g, " ").trim()).join(";");
}

export function rowsToCanonCsv(rows = []) {
  return [CANON_COLUMNS.join(";"), ...rows.map((row) => rowToCsv(row.raw || row))].join("\n");
}

function calcDiff({ total, sinal, complemento, mensal, anual, unica, financiamento, paymentPlan }) {
  return total - (
    sinal * Number(paymentPlan.atoQtd || 1) +
    complemento * Number(paymentPlan.compQtd || 0) +
    mensal * Number(paymentPlan.mensalQtd || 0) +
    anual * Number(paymentPlan.interQtd || 0) +
    unica * Number(paymentPlan.unicaQtd || 1) +
    financiamento * Number(paymentPlan.financiamentoQtd || 1)
  );
}

function buildObservacoes({ vagas, faixaAndar, diff, paymentPlan, explicitUnit = false }) {
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
    paymentPlan.warning ? `payment_plan_warning=${paymentPlan.warning}` : "",
    `payment_plan_source=${paymentPlan.source}`,
    "origem=range_by_final_table",
    explicitUnit ? "explicit_unit=true" : "",
    faixaAndar ? `faixa_andar=${faixaAndar}` : "",
    Number.isFinite(diff) ? `check_diff=${diff.toFixed(2)}` : "",
    `check_tolerance=${PAYMENT_DIFF_ABS_TOLERANCE.toFixed(2)}`,
  ]
    .filter(Boolean)
    .join(" | ");
}

function paymentDiff(row) {
  const plan = row.parser_meta?.payment_plan || FALLBACK_PAYMENT_META;
  const expected =
    Number(row.sinal_1 || 0) * Number(plan.atoQtd || 1) +
    Number(row.a4_each || 0) * Number(plan.compQtd || 0) +
    Number(row.mensal_each || 0) * Number(plan.mensalQtd || 0) +
    Number(row.inter_each || 0) * Number(plan.interQtd || 0) +
    Number(row.chaves_each || 0) * Number(plan.unicaQtd || 1) +
    Number(row.financiamento || 0) * Number(plan.financiamentoQtd || 1);

  return Number(row.preco_total || 0) - expected;
}

function validateRangeRow(row) {
  const base = validateCanonRow(row);
  const diff = paymentDiff(row);
  const issues = [...base.issues];

  // A tabela comercial por final trabalha com valores inteiros e parcelas repetidas.
  // O desvio de soma nasce do arredondamento acumulado da própria tabela, não de erro de coluna.
  if (Math.abs(diff) > PAYMENT_DIFF_ABS_TOLERANCE) {
    issues.push(`soma_fluxo_difere_valor_total=${diff.toFixed(2)};tolerancia=${PAYMENT_DIFF_ABS_TOLERANCE.toFixed(2)}`);
  }

  return {
    valid: issues.length === 0,
    issues,
  };
}

function removeNonFinancialNoise(text = "") {
  const normalized = compactSpaces(text);
  const first = normalized.search(/Final\s+0?1\b|Final\s+0?3\b|Garden\s+AP\d{4}/i);
  if (first < 0) return normalized;
  return normalized.slice(first);
}

function makeParsedRow({ empreendimento, final, andar, unidade, area, vagas, sinal, complemento, mensal, anual, unica, financiamento, total, faixaAndar, finalIndex, rowsLength, paymentPlan, explicitUnit = false }) {
  const diff = calcDiff({ total, sinal, complemento, mensal, anual, unica, financiamento, paymentPlan });
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
    observacoes: buildObservacoes({ vagas, faixaAndar, diff, paymentPlan, explicitUnit }),
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
    },
  };

  return {
    ...parsed,
    validation: validateRangeRow(parsed),
  };
}

export function parseRangeByFinalTable(text, options = {}) {
  const source = removeNonFinancialNoise(text);
  if (!source) {
    return {
      rows: [],
      csvText: CANON_COLUMNS.join(";"),
      diagnostics: { parser: "parseRangeByFinalTable", reason: "empty_source" },
    };
  }

  const normalizedForDetection = normalizeForMatch(source);
  const looksCommercial =
    /final\s+0?\d{1,2}\b|garden\s+ap\d{4}/i.test(source) &&
    normalizedForDetection.includes("valor total") &&
    normalizedForDetection.includes("financiamento") &&
    (/\d{1,2}\s*(?:º|o|°|a\.)?\s*(?:e|a|ao)\s*\d{1,2}\s*(?:º|o|°)?\s*andar/i.test(source) || /garden\s+ap\d{4}/i.test(source));

  if (!looksCommercial) {
    return {
      rows: [],
      csvText: CANON_COLUMNS.join(";"),
      diagnostics: { parser: "parseRangeByFinalTable", reason: "layout_not_matched" },
    };
  }

  const paymentPlan = extractPaymentPlan(text);
  const finalRegex = /Final\s+(\d{1,2})(?:\s+e\s+(\d{1,2}))?/gi;
  const finalMatches = [...source.matchAll(finalRegex)];
  const rows = [];
  const finalDiagnostics = [];
  const empreendimento = extractEmpreendimento(text, options.empreendimento || "");

  finalMatches.forEach((finalMatch, finalIndex) => {
    const finalLabel = finalMatch[0];
    const finals = parseFinals(finalLabel);
    const start = finalMatch.index || 0;
    const end = finalMatches[finalIndex + 1]?.index ?? source.length;
    const segment = source.slice(start, end);

    const explicitUnitRegex = /Garden\s+(AP\d{4})\s+(\d{1,3},\d{1,2})\s+(\d{1,2})\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/gi;
    const rowRegex = /((?:\d{1,2}\s*(?:º|o|°|a\.)?\s*(?:e|a|ao)\s*\d{1,2}\s*(?:º|o|°)?|\d{1,2}\s*(?:º|o|°)?)\s*andar)\s+(\d{1,3},\d{1,2})\s+(\d{1,2})\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/gi;

    let parsedRanges = 0;
    let explicitUnits = 0;
    let generatedUnits = 0;
    let match;

    while ((match = explicitUnitRegex.exec(segment)) !== null) {
      const unidade = match[1].toUpperCase();
      const explicit = explicitUnitToAndarFinal(unidade);
      const area = areaToNumber(match[2]);
      const vagas = Number.parseInt(match[3], 10) || 0;
      const sinal = moneyToNumber(match[4]);
      const complemento = moneyToNumber(match[5]);
      const mensal = moneyToNumber(match[6]);
      const anual = moneyToNumber(match[7]);
      const unica = moneyToNumber(match[8]);
      const financiamento = moneyToNumber(match[9]);
      const total = moneyToNumber(match[10]);

      if (!area || !total) continue;
      explicitUnits += 1;
      rows.push(makeParsedRow({
        empreendimento,
        final: explicit.final,
        andar: explicit.andar,
        unidade,
        area,
        vagas,
        sinal,
        complemento,
        mensal,
        anual,
        unica,
        financiamento,
        total,
        faixaAndar: "Garden",
        finalIndex,
        rowsLength: rows.length,
        paymentPlan,
        explicitUnit: true,
      }));
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
      const total = moneyToNumber(match[10]);

      if (!andares.length || !finals.length || !area || !total) continue;
      parsedRanges += 1;

      finals.forEach((final) => {
        andares.forEach((andar) => {
          rows.push(makeParsedRow({
            empreendimento,
            final,
            andar,
            unidade: unitCode(andar, final),
            area,
            vagas,
            sinal,
            complemento,
            mensal,
            anual,
            unica,
            financiamento,
            total,
            faixaAndar,
            finalIndex,
            rowsLength: rows.length,
            paymentPlan,
            explicitUnit: false,
          }));
          generatedUnits += 1;
        });
      });
    }

    finalDiagnostics.push({
      final_label: finalLabel,
      finals,
      parsed_ranges: parsedRanges,
      explicit_units: explicitUnits,
      generated_units: generatedUnits,
    });
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
      payment_diff_tolerance: PAYMENT_DIFF_ABS_TOLERANCE,
      payment_plan: paymentPlan,
      final_diagnostics: finalDiagnostics,
      complete: rows.length > 0,
    },
  };
}
