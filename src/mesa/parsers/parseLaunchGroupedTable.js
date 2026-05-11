import { expandHierarchicalUnits } from "../expanders/expandHierarchicalUnits";
import { parseFloorRange } from "../utils/parseFloorRange";
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
  if (value === "-" || value === null || value === undefined || value === "") return 0;

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
  } else if (hasDot) {
    const parts = s.split(".");
    if (parts.length > 1 && parts[parts.length - 1].length === 3) {
      s = s.replace(/\./g, "");
    }
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

function normalizeFinal(value = "") {
  const matches = String(value || "").match(/\d{1,2}/g) || [];
  return matches.map((item) => item.padStart(2, "0")).join(" e ");
}

function extractEmpreendimento(text = "", fallback = "") {
  if (fallback) return fallback;
  const normalized = compactSpaces(text);
  const match = normalized.match(/EMPREENDIMENTO:\s*([^\n]+?)(?:ENDEREÇO|ENDERECO|\d+\.)/i);
  if (match?.[1]) return compactSpaces(match[1]);
  if (/Nova\s+Vivere/i.test(normalized)) return "Nova Vivere";
  return "";
}

function getIntBefore(text, labelRegex, fallback = 0) {
  const normalized = removeAccents(compactSpaces(text));
  const match = normalized.match(labelRegex);
  if (!match?.index) return fallback;
  const before = normalized.slice(Math.max(0, match.index - 20), match.index);
  const nums = before.match(/\d+/g) || [];
  return nums.length ? Number.parseInt(nums[nums.length - 1], 10) : fallback;
}

function inferHeaderConfig(text = "") {
  return {
    complemento_qtd: getIntBefore(text, /C\.\s*ATO|C\s+ATO|COMPLEMENTO/i, 3),
    mensal_qtd: getIntBefore(text, /MENSAIS|MENSAL/i, 44),
    inter_qtd: getIntBefore(text, /ANUAIS|INTERMEDIARIA|INTERMEDIÁRIA/i, 4),
    inter_tipo: /ANUAIS|ANUAL/i.test(removeAccents(text)) ? "anual" : "",
  };
}

function rowToCsv(row) {
  return CANON_COLUMNS.map((key) => String(row[key] ?? "").replace(/[\r\n;]+/g, " ").trim()).join(";");
}

export function rowsToGroupedLaunchCsv(rows = []) {
  return [CANON_COLUMNS.join(";"), ...rows.map((row) => rowToCsv(row.raw || row))].join("\n");
}

function buildUnitLabel(finalCode, andar, explicitUnit) {
  if (explicitUnit) return explicitUnit;
  const finalLabel = finalCode.includes(" e ") ? `Finais ${finalCode}` : `Final ${finalCode}`;
  return `${finalLabel} - ${andar}`;
}

function buildRow({ source, empreendimento, finalCode, andar, explicitUnit, area, vagas, values, rowIndex, sectionIndex, header }) {
  const [ato, complemento, mensal, anual, unica, financiamento, total] = values;
  const floorMeta = parseFloorRange(andar);
  const unidade = buildUnitLabel(finalCode, andar, explicitUnit);
  const raw = {
    empreendimento,
    torre: "",
    final: finalCode,
    andar,
    unidade,
    area_m2: formatNumber(area),
    preco_total: formatNumber(total),
    sinal_1: formatNumber(ato),
    a4_each: formatNumber(complemento),
    mensal_qtd: header.mensal_qtd || "",
    mensal_each: formatNumber(mensal),
    inter_tipo: header.inter_tipo || "anual",
    inter_qtd: header.inter_qtd || "",
    inter_each: formatNumber(anual),
    chaves_each: formatNumber(unica),
    financiamento: formatNumber(financiamento),
    observacoes: [
      vagas ? `vagas=${vagas}` : "",
      header.complemento_qtd ? `comp_qtd=${header.complemento_qtd}` : "",
      "parser=grouped_launch_native",
    ].filter(Boolean).join(" | "),
  };

  const parsed = {
    id: `${unidade}-${sectionIndex}-${rowIndex}`,
    ...raw,
    area_m2: Number(area || 0),
    preco_total: Number(total || 0),
    sinal_1: Number(ato || 0),
    a4_each: Number(complemento || 0),
    mensal_qtd: Number(header.mensal_qtd || 0),
    mensal_each: Number(mensal || 0),
    inter_tipo: header.inter_tipo || "anual",
    inter_qtd: Number(header.inter_qtd || 0),
    inter_each: Number(anual || 0),
    chaves_each: Number(unica || 0),
    financiamento: Number(financiamento || 0),
    observacoes: raw.observacoes,
    floor_meta: floorMeta,
    raw,
    parser_meta: {
      parser: "parseLaunchGroupedTable",
      section_index: sectionIndex,
      row_index: rowIndex,
      explicit_unit: Boolean(explicitUnit),
      raw_source: source,
      floor_tipo: floorMeta.tipo,
    },
  };

  const expandedUnits = expandHierarchicalUnits({ ...parsed, floor_meta: floorMeta });

  return {
    ...parsed,
    expanded_units: explicitUnit && /^ap\d+/i.test(explicitUnit)
      ? [{ unidade_codigo: explicitUnit.replace(/^AP/i, ""), final: finalCode, andar: Number(explicitUnit.match(/AP(\d{2})/)?.[1] || 0), grupo_id: parsed.id, original_unidade: explicitUnit, expanded_from_range: false }]
      : expandedUnits,
    validation: validateCanonRow(parsed),
  };
}

export function parseLaunchGroupedTable(text, options = {}) {
  const source = compactSpaces(text);
  const normalized = removeAccents(source).toLowerCase();

  if (!source || !normalized.includes("final") || !normalized.includes("mensais") || !normalized.includes("financiamento")) {
    return {
      rows: [],
      csvText: CANON_COLUMNS.join(";"),
      diagnostics: { parser: "parseLaunchGroupedTable", reason: "not_grouped_launch_table" },
    };
  }

  const empreendimento = extractEmpreendimento(source, options.empreendimento || "");
  const header = inferHeaderConfig(source);
  const rows = [];
  const sections = [];
  const finalRegex = /Final\s+(\d{1,2}(?:\s*e\s*\d{1,2})?)/gi;
  const matches = [...source.matchAll(finalRegex)];

  matches.forEach((match, sectionIndex) => {
    const start = match.index || 0;
    const end = matches[sectionIndex + 1]?.index ?? source.length;
    const finalRaw = match[1];
    const finalCode = normalizeFinal(finalRaw);
    const section = source.slice(start, end).replace(/NOTAS:[\s\S]*$/i, "");
    const sectionRows = [];

    const gardenRegex = /Garden\s+(AP\d{4})\s+(\d{2,3},\d{2})\s+(\d+|-)?\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/gi;
    let gardenMatch;
    while ((gardenMatch = gardenRegex.exec(section)) !== null) {
      sectionRows.push(buildRow({
        source: gardenMatch[0],
        empreendimento,
        finalCode,
        andar: "Garden",
        explicitUnit: gardenMatch[1],
        area: toNumber(gardenMatch[2]),
        vagas: gardenMatch[3] || "",
        values: gardenMatch.slice(4, 11).map(toNumber),
        rowIndex: rows.length,
        sectionIndex,
        header,
      }));
    }

    const rangeRegex = /((?:\d{1,2}\s*(?:º|°|o)?\s*(?:ao|a|e)\s*\d{1,2}\s*(?:º|°|o)?\s*andar))\s+(\d{2,3},\d{2})\s+(\d+|-)?\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)/gi;
    let rangeMatch;
    while ((rangeMatch = rangeRegex.exec(section)) !== null) {
      sectionRows.push(buildRow({
        source: rangeMatch[0],
        empreendimento,
        finalCode,
        andar: compactSpaces(rangeMatch[1]),
        explicitUnit: "",
        area: toNumber(rangeMatch[2]),
        vagas: rangeMatch[3] || "",
        values: rangeMatch.slice(4, 11).map(toNumber),
        rowIndex: rows.length,
        sectionIndex,
        header,
      }));
    }

    sectionRows.sort((a, b) => (a.parser_meta.raw_source.length > b.parser_meta.raw_source.length ? 0 : 0));
    rows.push(...sectionRows);
    sections.push({ final: finalCode, rows: sectionRows.length });
  });

  const validRows = rows.filter((row) => row.validation.valid).length;

  return {
    rows,
    csvText: rowsToGroupedLaunchCsv(rows),
    diagnostics: {
      parser: "parseLaunchGroupedTable",
      empreendimento,
      sections: sections.length,
      total_rows: rows.length,
      valid_rows: validRows,
      invalid_rows: rows.length - validRows,
      section_diagnostics: sections,
      header,
      skipped_non_apartment_sections: normalized.includes("vagas") ? ["Vagas"] : [],
    },
  };
}
