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

function normalizeForMatch(value = "") {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\u00a0/g, " ")
    .replace(/\s+/g, " ")
    .toLowerCase()
    .trim();
}

function compactSpaces(value = "") {
  return String(value || "")
    .replace(/\u00a0/g, " ")
    .replace(/[ \t]+/g, " ")
    .replace(/\s+\n/g, "\n")
    .replace(/\n\s+/g, "\n")
    .trim();
}

function toNumber(value = "") {
  if (typeof value === "number") return Number.isFinite(value) ? value : 0;
  const raw = String(value || "").trim();
  if (!raw) return 0;

  let s = raw.replace(/R\$/gi, "").replace(/m²|m2/gi, "").replace(/\s+/g, "");
  const hasComma = s.includes(",");
  const numericWithDotsOnly = s.replace(/[^\d.]/g, "");
  const looksLikeBrazilianThousandsOnly = !hasComma && /^\d{1,3}(?:\.\d{3})+$/.test(numericWithDotsOnly);

  if (hasComma) s = s.replace(/\./g, "").replace(",", ".");
  else if (looksLikeBrazilianThousandsOnly) s = s.replace(/\./g, "");

  s = s.replace(/[^\d.-]/g, "");
  const parsed = Number.parseFloat(s);
  return Number.isFinite(parsed) ? parsed : 0;
}

function formatNumber(value, decimals = 2) {
  const parsed = Number(value || 0);
  if (!Number.isFinite(parsed)) return "";
  return parsed.toFixed(decimals).replace(/\.00$/, "").replace(/(\.\d*[1-9])0+$/, "$1");
}

function parseCsvRecords(text = "") {
  const rows = [];
  let row = [];
  let field = "";
  let inQuotes = false;

  const source = String(text || "").replace(/^\uFEFF/, "");

  for (let i = 0; i < source.length; i += 1) {
    const ch = source[i];
    const next = source[i + 1];

    if (ch === '"') {
      if (inQuotes && next === '"') {
        field += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (ch === "," && !inQuotes) {
      row.push(field.trim());
      field = "";
      continue;
    }

    if ((ch === "\n" || ch === "\r") && !inQuotes) {
      if (ch === "\r" && next === "\n") i += 1;
      row.push(field.trim());
      if (row.some((cell) => String(cell || "").trim())) rows.push(row);
      row = [];
      field = "";
      continue;
    }

    field += ch;
  }

  row.push(field.trim());
  if (row.some((cell) => String(cell || "").trim())) rows.push(row);
  return rows;
}

function looksLikeHeader(row = []) {
  const normalized = row.map(normalizeForMatch).join(" ");
  return (
    normalized.includes("andar") &&
    normalized.includes("unidades") &&
    normalized.includes("area util") &&
    normalized.includes("vagas") &&
    normalized.includes("ato") &&
    normalized.includes("principal financ") &&
    normalized.includes("total")
  );
}

function isSectionTitle(row = []) {
  const first = normalizeForMatch(row[0] || "");
  return first.includes("torre harmonie") || first.includes("torre lumiere");
}

function resolveTorre(row = []) {
  const first = String(row[0] || "").trim();
  const normalized = normalizeForMatch(first);

  if (normalized.includes("torre harmonie")) return "Harmonie Vert e Gris";
  if (normalized.includes("torre lumiere")) return "Lumière Bleu e Blanc";
  return "";
}

function inferFinalFromUnit(unit = "") {
  const digits = String(unit || "").replace(/\D/g, "");
  return digits.length >= 2 ? digits.slice(-2) : "";
}

function resolveAndar(andarLabel = "") {
  const normalized = normalizeForMatch(andarLabel);
  if (normalized.includes("garden")) return 0;
  if (normalized.includes("cobertura")) return 14;

  const match = String(andarLabel || "").match(/\d+/);
  return match ? Number.parseInt(match[0], 10) : null;
}

function resolvePlantaTipo(andarLabel = "") {
  const normalized = normalizeForMatch(andarLabel);
  if (normalized.includes("garden")) return "Garden";
  if (normalized.includes("cobertura")) return "Cobertura";
  return "Apartamento Tipo";
}

function expandGroupedUnits(value = "") {
  const raw = String(value || "").trim();
  if (!raw) return [];

  const rangeMatch = raw.match(/^(\d{2,4})\s*(?:a|ao|até|ate|-|–)\s*(\d{2,4})$/i);
  if (rangeMatch) {
    const start = Number.parseInt(rangeMatch[1], 10);
    const end = Number.parseInt(rangeMatch[2], 10);
    if (Number.isFinite(start) && Number.isFinite(end) && end >= start) {
      const startFinal = String(start).slice(-2);
      const endFinal = String(end).slice(-2);
      const step = startFinal === endFinal && end - start >= 100 ? 100 : 1;
      const expanded = [];
      for (let n = start; n <= end; n += step) expanded.push(String(n));
      return expanded;
    }
  }

  if (raw.includes(",")) {
    return raw
      .split(",")
      .map((part) => part.trim())
      .filter(Boolean);
  }

  return [raw];
}

function resolveCommercialGroup({ torre, unidade, area }) {
  const normalizedTorre = normalizeForMatch(torre);
  const final = inferFinalFromUnit(unidade);
  const numericUnit = Number.parseInt(String(unidade || "").replace(/\D/g, ""), 10);

  if (normalizedTorre.includes("lumiere")) {
    return {
      grupoPrumada: "Prumadas Blanc/Bleu",
      metragemBase: "355m²",
      unidadesPorPavimento: 4,
    };
  }

  if (numericUnit === 100 || numericUnit === 200 || final === "01" || final === "02" || area >= 240) {
    return {
      grupoPrumada: "Prumadas 1 e 2",
      metragemBase: "248m²",
      unidadesPorPavimento: 2,
    };
  }

  if (final === "03" || final === "04" || (area >= 210 && area < 240)) {
    return {
      grupoPrumada: "Prumadas 3 e 4",
      metragemBase: "215m²",
      unidadesPorPavimento: 2,
    };
  }

  return {
    grupoPrumada: "Prumadas 5 e 6",
    metragemBase: "185m²",
    unidadesPorPavimento: 2,
  };
}

function buildObservacoes({
  torre,
  unidade,
  unidadeGrupoOriginal,
  andarLabel,
  plantaTipo,
  vagas,
  group,
  financiamentoProjetado,
  checkDiff,
}) {
  return [
    `vagas=${vagas || 0}`,
    "ato_qtd=1",
    "comp_qtd=3",
    "mensal_qtd=36",
    "inter_tipo=semestral",
    "inter_qtd=6",
    "unica_qtd=1",
    "financiamento_qtd=1",
    "unica_mes=2029-09",
    "financ_mes=2029-09",
    "financ_proj_mes=2029-11",
    `financ_proj_valor=${formatNumber(financiamentoProjetado)}`,
    `torre_nome=${torre}`,
    `grupo_prumada=${group.grupoPrumada}`,
    `metragem_base=${group.metragemBase}`,
    `perfil=${plantaTipo}`,
    `unidade_grupo_original=${unidadeGrupoOriginal}`,
    `unidade_expandida=${unidade}`,
    `andar_label=${andarLabel}`,
    `unidades_por_pavimento=${group.unidadesPorPavimento}`,
    "reajuste_obra=INCC_FGV_ate_2029-09",
    "reajuste_pos_chaves=IGPM_a_partir_2029-10",
    "juros_price=1pct_a_m_a_partir_2029-09",
    "custos_comprador=cartorio_ITBI_assessoria_repasse_condominio_taxas",
    `check_diff=${formatNumber(checkDiff)}`,
    Math.abs(checkDiff) <= CHECK_TOLERANCE ? "check_status=ok" : "check_status=divergencia_tabela_original",
    "origem=chateau_jardin_pre_lancamento_csv",
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

function validateChateauRow(row) {
  const base = validateCanonRow(row);
  return {
    valid: base.issues.length === 0,
    issues: [...base.issues],
  };
}

function makeParsedRowsFromCsvRecord({ empreendimento, torre, record, rowIndex }) {
  const [andarLabel, unidadesOriginal, areaRaw, vagasRaw, atoRaw, compRaw, mensalRaw, semestralRaw, unicaRaw, principalRaw, financProjRaw, totalRaw] = record;

  const area = toNumber(areaRaw);
  const vagas = Math.trunc(toNumber(vagasRaw));
  const ato = toNumber(atoRaw);
  const complemento = toNumber(compRaw);
  const mensal = toNumber(mensalRaw);
  const semestral = toNumber(semestralRaw);
  const unica = toNumber(unicaRaw);
  const financiamento = toNumber(principalRaw);
  const financiamentoProjetado = toNumber(financProjRaw);
  const total = toNumber(totalRaw);
  const andar = resolveAndar(andarLabel);
  const plantaTipo = resolvePlantaTipo(andarLabel);
  const unidades = expandGroupedUnits(unidadesOriginal);

  if (!torre || !unidades.length || !area || !total || !financiamento) return [];

  const expectedTotal = ato + complemento * 3 + mensal * 36 + semestral * 6 + unica + financiamento;
  const checkDiff = total - expectedTotal;

  return unidades.map((unidade, unitIndex) => {
    const group = resolveCommercialGroup({ torre, unidade, area });
    const raw = {
      empreendimento,
      torre,
      final: inferFinalFromUnit(unidade),
      andar: andar === null ? "" : String(andar),
      unidade: String(unidade).trim(),
      area_m2: formatNumber(area),
      preco_total: formatNumber(total),
      sinal_1: formatNumber(ato),
      a4_each: formatNumber(complemento),
      mensal_qtd: "36",
      mensal_each: formatNumber(mensal),
      inter_tipo: "semestral",
      inter_qtd: "6",
      inter_each: formatNumber(semestral),
      chaves_each: formatNumber(unica),
      financiamento: formatNumber(financiamento),
      observacoes: buildObservacoes({
        torre,
        unidade,
        unidadeGrupoOriginal: unidadesOriginal,
        andarLabel,
        plantaTipo,
        vagas,
        group,
        financiamentoProjetado,
        checkDiff,
      }),
    };

    const parsed = {
      id: `${torre}-${unidade}-${rowIndex}-${unitIndex}`,
      ...raw,
      area_m2: area,
      preco_total: total,
      valor_tabela: total,
      sinal_1: ato,
      a4_each: complemento,
      mensal_qtd: 36,
      mensal_each: mensal,
      inter_tipo: "semestral",
      inter_qtd: 6,
      inter_each: semestral,
      chaves_each: unica,
      financiamento,
      vagas,
      vagas_quantidade: vagas,
      planta_tipo: plantaTipo,
      status_comercial: "disponivel",
      confianca_linha: Math.abs(checkDiff) <= CHECK_TOLERANCE ? "alta" : "media",
      raw,
      parser_meta: {
        parser: "parseChateauJardinPreLancamentoCsv",
        layout: "chateau_jardin_pre_lancamento_csv",
        unidade_grupo_original: unidadesOriginal,
        unidade_expandida: unidade,
        payment_model: "ato_3_complementos_36_mensais_6_semestrais_unica_financiamento",
        payment_plan: {
          atoQtd: 1,
          complementoQtd: 3,
          mensalQtd: 36,
          interTipo: "semestral",
          interQtd: 6,
          unicaQtd: 1,
          financiamentoQtd: 1,
          unicaMes: "2029-09",
          financiamentoMes: "2029-09",
          financiamentoProjetadoMes: "2029-11",
          tolerance: CHECK_TOLERANCE,
          checkDiff,
        },
      },
    };

    return {
      ...parsed,
      validation: validateChateauRow(parsed),
    };
  });
}

export function parseChateauJardinPreLancamentoCsv(text, options = {}) {
  const source = compactSpaces(text);
  const normalized = normalizeForMatch(source);

  const looksChateau =
    normalized.includes("chateau jardin") &&
    normalized.includes("unidades") &&
    normalized.includes("area util") &&
    normalized.includes("principal financ") &&
    normalized.includes("financ") &&
    normalized.includes("total") &&
    (normalized.includes("torre harmonie") || normalized.includes("torre lumiere"));

  if (!looksChateau) {
    return {
      rows: [],
      csvText: CANON_COLUMNS.join(";"),
      diagnostics: { parser: "parseChateauJardinPreLancamentoCsv", reason: "layout_not_matched" },
    };
  }

  const records = parseCsvRecords(text);
  const empreendimento = options.empreendimento || "Chateau Jardin";
  let currentTorre = "";
  const rows = [];
  const skipped = [];

  records.forEach((record, index) => {
    if (isSectionTitle(record)) {
      currentTorre = resolveTorre(record);
      return;
    }

    if (looksLikeHeader(record)) return;

    const first = String(record[0] || "").trim();
    const second = String(record[1] || "").trim();
    if (!first || !second || record.length < 12) return;

    const parsedRows = makeParsedRowsFromCsvRecord({
      empreendimento,
      torre: currentTorre,
      record,
      rowIndex: index + 1,
    });

    if (!parsedRows.length) {
      skipped.push({ index: index + 1, record });
      return;
    }

    rows.push(...parsedRows);
  });

  return {
    rows,
    csvText: rowsToCanonCsv(rows),
    diagnostics: {
      parser: "parseChateauJardinPreLancamentoCsv",
      layout: "chateau_jardin_pre_lancamento_csv",
      source_records: records.length,
      rows: rows.length,
      skipped_rows: skipped.length,
      skipped,
      torres: Array.from(new Set(rows.map((row) => row.torre).filter(Boolean))),
      grupos: Array.from(new Set(rows.map((row) => row.parser_meta?.unidade_grupo_original).filter(Boolean))).length,
    },
  };
}
