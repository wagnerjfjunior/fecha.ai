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

const DEFAULT_PAYMENT_META = {
  compQtd: 3,
  mensalQtd: 35,
  interQtd: 3,
  interTipo: "anual",
  mensalInicio: "2026-09-05",
  anualInicio: "2027-04-05",
  unica: "2029-08-05",
  financMes: "2029-10",
};

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

function extractEmpreendimento(text = "", fallback = "") {
  if (fallback) return fallback;
  const normalized = compactSpaces(text);
  const title = normalized.match(/Tabela\s+de\s+Lançamento\s*-\s*([^\n]+?)(?:\s+UNIDADE|\s+VALOR\s+TOTAL|\s+1\s+3\s+35\s+3\s+1\s+1)/i);
  if (title?.[1]) return compactSpaces(title[1]);
  if (/Garden\s+Design/i.test(normalized)) return "Garden Design Private Park Residence";
  return "";
}

function rowToCsv(row) {
  return CANON_COLUMNS.map((key) => String(row[key] ?? "").replace(/[\r\n;]+/g, " ").trim()).join(";");
}

export function rowsToCanonCsv(rows = []) {
  return [CANON_COLUMNS.join(";"), ...rows.map((row) => rowToCsv(row.raw || row))].join("\n");
}

function buildObservacoes({ vagas, faixaAndar, diff }) {
  return [
    `vagas=${vagas || 0}`,
    `comp_qtd=${DEFAULT_PAYMENT_META.compQtd}`,
    `mensal_inicio=${DEFAULT_PAYMENT_META.mensalInicio}`,
    `anual_inicio=${DEFAULT_PAYMENT_META.anualInicio}`,
    `unica=${DEFAULT_PAYMENT_META.unica}`,
    `financ_mes=${DEFAULT_PAYMENT_META.financMes}`,
    "origem=range_by_final_table",
    faixaAndar ? `faixa_andar=${faixaAndar}` : "",
    Number.isFinite(diff) ? `check_diff=${diff.toFixed(2)}` : "",
  ]
    .filter(Boolean)
    .join(" | ");
}

function paymentDiff(row) {
  const expected =
    Number(row.sinal_1 || 0) +
    Number(row.a4_each || 0) * DEFAULT_PAYMENT_META.compQtd +
    Number(row.mensal_each || 0) * DEFAULT_PAYMENT_META.mensalQtd +
    Number(row.inter_each || 0) * DEFAULT_PAYMENT_META.interQtd +
    Number(row.chaves_each || 0) +
    Number(row.financiamento || 0);

  return Number(row.preco_total || 0) - expected;
}

function validateRangeRow(row) {
  const base = validateCanonRow(row);
  const diff = paymentDiff(row);
  const issues = [...base.issues];

  if (Math.abs(diff) > 10) {
    issues.push(`soma_fluxo_difere_valor_total=${diff.toFixed(2)}`);
  }

  return {
    valid: issues.length === 0,
    issues,
  };
}

function removeNonFinancialNoise(text = "") {
  const normalized = compactSpaces(text);
  const first = normalized.search(/Final\s+0?1\b/i);
  if (first < 0) return normalized;
  return normalized.slice(first);
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

  const normalizedForDetection = removeAccents(source).toLowerCase();
  const looksCommercial =
    normalizedForDetection.includes("final 01") &&
    normalizedForDetection.includes("valor total") &&
    normalizedForDetection.includes("financiamento") &&
    /\d{1,2}\s*(?:º|o|°)?\s*(?:e|a)\s*\d{1,2}\s*(?:º|o|°)?\s*andar/i.test(source);

  if (!looksCommercial) {
    return {
      rows: [],
      csvText: CANON_COLUMNS.join(";"),
      diagnostics: { parser: "parseRangeByFinalTable", reason: "layout_not_matched" },
    };
  }

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

    const rowRegex = /((?:\d{1,2}\s*(?:º|o|°)?\s*(?:e|a)\s*\d{1,2}\s*(?:º|o|°)?|\d{1,2}\s*(?:º|o|°)?)\s*andar)\s+(\d{1,3},\d{1,2})\s+(\d{1,2})\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/gi;

    let parsedRanges = 0;
    let generatedUnits = 0;
    let match;

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
          const raw = {
            empreendimento,
            torre: "",
            final,
            andar: String(andar),
            unidade: unitCode(andar, final),
            area_m2: formatNumber(area),
            preco_total: formatNumber(total),
            sinal_1: formatNumber(sinal),
            a4_each: formatNumber(complemento),
            mensal_qtd: String(DEFAULT_PAYMENT_META.mensalQtd),
            mensal_each: formatNumber(mensal),
            inter_tipo: DEFAULT_PAYMENT_META.interTipo,
            inter_qtd: String(DEFAULT_PAYMENT_META.interQtd),
            inter_each: formatNumber(anual),
            chaves_each: formatNumber(unica),
            financiamento: formatNumber(financiamento),
            observacoes: buildObservacoes({ vagas, faixaAndar, diff: total - (sinal + complemento * DEFAULT_PAYMENT_META.compQtd + mensal * DEFAULT_PAYMENT_META.mensalQtd + anual * DEFAULT_PAYMENT_META.interQtd + unica + financiamento) }),
          };

          const parsed = {
            id: `${raw.unidade}-${finalIndex}-${rows.length}`,
            ...raw,
            area_m2: area,
            preco_total: total,
            sinal_1: sinal,
            a4_each: complemento,
            mensal_qtd: DEFAULT_PAYMENT_META.mensalQtd,
            mensal_each: mensal,
            inter_tipo: DEFAULT_PAYMENT_META.interTipo,
            inter_qtd: DEFAULT_PAYMENT_META.interQtd,
            inter_each: anual,
            chaves_each: unica,
            financiamento,
            raw,
            parser_meta: {
              parser: "parseRangeByFinalTable",
              final_label: finalLabel,
              faixa_andar: faixaAndar,
              generated_from_range: true,
            },
          };

          rows.push({
            ...parsed,
            validation: validateRangeRow(parsed),
          });
          generatedUnits += 1;
        });
      });
    }

    finalDiagnostics.push({
      final_label: finalLabel,
      finals,
      parsed_ranges: parsedRanges,
      generated_units: generatedUnits,
    });
  });

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseRangeByFinalTable",
      final_blocks: finalMatches.length,
      parsed_final_blocks: finalDiagnostics.filter((item) => item.parsed_ranges > 0).length,
      total_rows: rows.length,
      invalid_rows: rows.filter((row) => row.validation?.valid === false).length,
      final_diagnostics: finalDiagnostics,
      complete: rows.length > 0,
    },
  };
}
