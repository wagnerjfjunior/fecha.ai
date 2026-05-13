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
const MONEY_BR = "([0-9]{1,3}(?:\\.[0-9]{3})*,[0-9]{2}|[0-9]+,[0-9]{2}|[0-9]{1,3}(?:\\.[0-9]{3})+|[0-9]+)";
const MONEY_INTEGER_OR_BR = "([0-9]{1,3}(?:\\.[0-9]{3})*(?:,[0-9]{2})?|[0-9]+(?:,[0-9]{2})?)";

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

function normalizeUnit(unit = "", prefix = "AP") {
  const digits = String(unit || "").replace(/\D/g, "");
  return digits ? `${prefix}${digits.padStart(4, "0")}` : "";
}

function inferFinalFromUnit(unit = "") {
  const digits = String(unit || "").replace(/\D/g, "");
  if (!digits) return "";
  return digits.slice(-1).padStart(2, "0");
}

function extractEmpreendimento(source = "", fallback = "") {
  if (fallback) return fallback;
  const normalized = normalizeForMatch(source);
  if (normalized.includes("bosque vila nova")) return "Bosque Vila Nova";
  if (normalized.includes("sereno jardim sao paulo")) return "Sereno Jardim São Paulo";
  return "";
}

function rowToCsv(row) {
  return CANON_COLUMNS.map((key) => String(row[key] ?? "").replace(/[\r\n;]+/g, " ").trim()).join(";");
}

export function rowsToCanonCsv(rows = []) {
  return [CANON_COLUMNS.join(";"), ...rows.map((row) => rowToCsv(row.raw || row))].join("\n");
}

function buildObservacoes({ plan, diff, periodicidadeValor = 0, parserMode, torre = "" }) {
  const tolerance = Math.max(CHECK_TOLERANCE, Number(plan.roundingTolerance || 0), Math.abs(periodicidadeValor || 0) + 1);

  return [
    plan.vagas ? `vagas=${plan.vagas}` : "",
    `ato_qtd=${plan.atoQtd || 1}`,
    `comp_qtd=${plan.compQtd || 0}`,
    `mensal_qtd=${plan.mensalQtd || 0}`,
    `inter_qtd=${plan.interQtd || 0}`,
    `unica_qtd=${plan.unicaQtd || 0}`,
    `financiamento_qtd=${plan.financiamentoQtd || 1}`,
    periodicidadeValor > 0 ? `periodicidade_valor=${formatNumber(periodicidadeValor)}` : "",
    plan.periodicidadeQtd ? `periodicidade_qtd=${plan.periodicidadeQtd}` : "",
    plan.atoInicio ? `ato_inicio=${plan.atoInicio}` : "",
    plan.compInicio ? `comp_inicio=${plan.compInicio}` : "",
    plan.mensalInicio ? `mensal_inicio=${plan.mensalInicio}` : "",
    plan.interInicio ? `inter_inicio=${plan.interInicio}` : "",
    plan.unicaInicio ? `unica_label=${plan.unicaInicio}` : "",
    plan.financMes ? `financ_mes=${plan.financMes}` : "",
    torre ? `torre=${torre}` : "",
    `payment_plan_source=${plan.source}`,
    `parser_mode=${parserMode}`,
    Number.isFinite(diff) ? `check_diff=${diff.toFixed(2)}` : "",
    `check_tolerance=${tolerance.toFixed(2)}`,
  ].filter(Boolean).join(" | ");
}

function getTolerance(plan = {}, periodicidadeValor = 0) {
  return Math.max(CHECK_TOLERANCE, Number(plan.roundingTolerance || 0), Math.abs(periodicidadeValor || 0) + 1);
}

function makeRow({
  empreendimento,
  unidade,
  final,
  andar,
  torre = "",
  area,
  precoTotal,
  sinal,
  comp,
  mensalQtd,
  mensal,
  interTipo = "anual",
  interQtd,
  inter,
  unica = 0,
  financiamento,
  periodicidadeValor = 0,
  plan,
  index,
  parserMode,
}) {
  const expected =
    Number(sinal || 0) * Number(plan.atoQtd || 1) +
    Number(comp || 0) * Number(plan.compQtd || 0) +
    Number(mensal || 0) * Number(mensalQtd || 0) +
    Number(inter || 0) * Number(interQtd || 0) +
    Number(unica || 0) * Number(plan.unicaQtd || 0) +
    Number(financiamento || 0) * Number(plan.financiamentoQtd || 1) +
    Number(periodicidadeValor || 0) * Number(plan.periodicidadeQtd || 0);

  const diff = Number(precoTotal || 0) - expected;
  const observacoes = buildObservacoes({ plan, diff, periodicidadeValor, parserMode, torre });
  const raw = {
    empreendimento,
    torre,
    final: final || inferFinalFromUnit(unidade),
    andar: String(andar || ""),
    unidade,
    area_m2: formatNumber(area),
    preco_total: formatNumber(precoTotal),
    sinal_1: formatNumber(sinal),
    a4_each: formatNumber(comp),
    mensal_qtd: String(mensalQtd || 0),
    mensal_each: formatNumber(mensal),
    inter_tipo: interTipo,
    inter_qtd: String(interQtd || 0),
    inter_each: formatNumber(inter),
    chaves_each: formatNumber(unica),
    financiamento: formatNumber(financiamento),
    observacoes,
  };
  const parsed = {
    id: `${unidade}-${index}`,
    ...raw,
    area_m2: area,
    preco_total: precoTotal,
    sinal_1: sinal,
    a4_each: comp,
    mensal_qtd: Number(mensalQtd || 0),
    mensal_each: mensal,
    inter_tipo: interTipo,
    inter_qtd: Number(interQtd || 0),
    inter_each: inter,
    chaves_each: unica,
    financiamento,
    observacoes,
    raw,
    parser_meta: {
      parser: "parseAWPaymentTable",
      parser_mode: parserMode,
      payment_plan: plan,
      periodicidade_valor: periodicidadeValor,
    },
  };

  const base = validateCanonRow(parsed);
  const issues = [...base.issues];
  if (Math.abs(diff) > getTolerance(plan, periodicidadeValor)) {
    issues.push(`soma_fluxo_difere_total=${diff.toFixed(2)}`);
  }

  return { ...parsed, validation: { valid: issues.length === 0, issues } };
}

function extractLastHeader(headers = [], index = 0) {
  let current = null;
  for (const header of headers) {
    if (header.index < index) current = header;
    else break;
  }
  return current;
}

function parseBosqueVilaNova(source = "", options = {}) {
  const empreendimento = extractEmpreendimento(source, options.empreendimento || "");
  const headerRegex = /Final\s+([0-9]{1,2})\s*-\s*([^0-9]{3,80}?)(?=\s+Sinal|\s+\d{1,2}\s*º?\s*Andar|$)/gi;
  const headers = [...source.matchAll(headerRegex)].map((match) => ({
    index: match.index || 0,
    final: String(match[1]).padStart(2, "0"),
    torre: String(match[2] || "").replace(/\.\.\./g, "").trim(),
  }));

  const rowRegex = new RegExp(
    `(\\d{1,2})\\s*º?\\s*Andar\\s+` +
    `(\\d{2,4})\\s+` +
    `(\\d{2,4}(?:[,.]\\d{1,3})?)\\s+` +
    `${MONEY_INTEGER_OR_BR}\\s+${MONEY_INTEGER_OR_BR}\\s+${MONEY_INTEGER_OR_BR}\\s+${MONEY_INTEGER_OR_BR}\\s+${MONEY_INTEGER_OR_BR}\\s+${MONEY_INTEGER_OR_BR}`,
    "gi"
  );
  const plan = {
    atoQtd: 1,
    compQtd: 4,
    mensalQtd: 32,
    interQtd: 3,
    unicaQtd: 0,
    financiamentoQtd: 1,
    periodicidadeQtd: 0,
    roundingTolerance: 25,
    compInicio: "150 dias",
    mensalInicio: "jan/26",
    interInicio: "set/28",
    source: "aw_bosque_header",
  };

  const rows = [];
  let match;
  while ((match = rowRegex.exec(source)) !== null) {
    const header = extractLastHeader(headers, match.index || 0) || {};
    const unidade = normalizeUnit(match[2]);
    rows.push(makeRow({
      empreendimento,
      unidade,
      final: header.final || inferFinalFromUnit(unidade),
      andar: match[1],
      torre: header.torre || "",
      area: toNumber(match[3]),
      sinal: toNumber(match[4]),
      comp: toNumber(match[5]),
      mensalQtd: plan.mensalQtd,
      mensal: toNumber(match[6]),
      interQtd: plan.interQtd,
      inter: toNumber(match[7]),
      unica: 0,
      financiamento: toNumber(match[8]),
      precoTotal: toNumber(match[9]),
      plan,
      index: rows.length,
      parserMode: "aw_bosque_final_blocks",
    }));
  }

  return rows;
}

function expandUnitList(value = "") {
  return String(value || "")
    .split(/\s*(?:,|\be\b)\s*/i)
    .map((part) => part.replace(/\D/g, ""))
    .filter(Boolean);
}

function parseSerenoJardim(source = "", options = {}) {
  const empreendimento = extractEmpreendimento(source, options.empreendimento || "");
  const pavimentos = [...source.matchAll(/(\d{1,2})\s*º\s*PAVIMENTO(?:\s*\(([^)]*)\))?/gi)].map((match) => ({
    index: match.index || 0,
    andar: match[1],
    tipo: match[2] || "",
  }));

  const rowRegex = new RegExp(
    `\\bUnidades?\\s+([0-9,\\se]+?)\\s+` +
    `(\\d{1,4},\\d{1,3})\\s+` +
    `([0-9])\\s+` +
    `${MONEY_BR}\\s+${MONEY_BR}\\s+${MONEY_BR}\\s+${MONEY_BR}\\s+${MONEY_BR}\\s+${MONEY_BR}\\s+${MONEY_BR}\\s+${MONEY_BR}`,
    "gi"
  );
  const basePlan = {
    atoQtd: 1,
    compQtd: 3,
    mensalQtd: 31,
    interQtd: 3,
    unicaQtd: 1,
    financiamentoQtd: 1,
    periodicidadeQtd: 1,
    atoInicio: "junho-25",
    compInicio: "julho-25",
    mensalInicio: "outubro-25",
    interInicio: "dezembro-25",
    unicaInicio: "abril-28",
    financMes: "maio-28",
    source: "aw_sereno_fluxo_pagamento",
  };

  const rows = [];
  let match;
  while ((match = rowRegex.exec(source)) !== null) {
    const pavimento = extractLastHeader(pavimentos, match.index || 0) || {};
    const units = expandUnitList(match[1]);
    const area = toNumber(match[2]);
    const vagas = Number.parseInt(match[3], 10) || 0;
    const sinal = toNumber(match[4]);
    const comp = toNumber(match[5]);
    const mensal = toNumber(match[6]);
    const inter = toNumber(match[7]);
    const unica = toNumber(match[8]);
    const financiamento = toNumber(match[9]);
    const periodicidade = toNumber(match[10]);
    const total = toNumber(match[11]);
    const plan = { ...basePlan, vagas };

    units.forEach((unitNumber) => {
      const unidade = normalizeUnit(unitNumber);
      rows.push(makeRow({
        empreendimento,
        unidade,
        final: inferFinalFromUnit(unidade),
        andar: pavimento.andar || "",
        torre: pavimento.tipo || "",
        area,
        precoTotal: total,
        sinal,
        comp,
        mensalQtd: plan.mensalQtd,
        mensal,
        interQtd: plan.interQtd,
        inter,
        unica,
        financiamento,
        periodicidadeValor: periodicidade,
        plan,
        index: rows.length,
        parserMode: "aw_sereno_grouped_units",
      }));
    });
  }

  return rows;
}

export function parseAWPaymentTable(text, options = {}) {
  const source = compactSpaces(text);
  if (!source) {
    return { rows: [], csvText: rowsToCanonCsv([]), diagnostics: { parser: "parseAWPaymentTable", reason: "empty_source" } };
  }

  const normalized = normalizeForMatch(source);
  let rows = [];
  let parserMode = "layout_not_matched";

  if (normalized.includes("bosque vila nova")) {
    rows = parseBosqueVilaNova(source, options);
    parserMode = "aw_bosque_final_blocks";
  } else if (normalized.includes("sereno jardim sao paulo") || (normalized.includes("fluxo de pagamento") && /\bUnidades?\s+\d+/i.test(source))) {
    rows = parseSerenoJardim(source, options);
    parserMode = "aw_sereno_grouped_units";
  }

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseAWPaymentTable",
      parser_mode: parserMode,
      total_rows: rows.length,
      invalid_rows: rows.filter((row) => row.validation?.valid === false).length,
      complete: rows.length > 0,
    },
  };
}
