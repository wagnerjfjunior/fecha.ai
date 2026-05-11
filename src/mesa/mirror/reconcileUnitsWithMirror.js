import { normalizeMirrorStatus } from "./normalizeMirrorStatus";

function normalizeUnitCode(value = "") {
  const raw = String(value || "").trim().toUpperCase();
  if (!raw) return "";

  const compact = raw
    .replace(/\s+/g, "")
    .replace(/^UNIDADE/, "")
    .replace(/^UND/, "")
    .replace(/^APTO/, "AP")
    .replace(/^APARTAMENTO/, "AP");

  if (/^\d{3,4}$/.test(compact)) {
    return `AP${compact.padStart(4, "0")}`;
  }

  if (/^AP\d{3,4}$/.test(compact)) {
    const number = compact.replace(/^AP/, "").padStart(4, "0");
    return `AP${number}`;
  }

  if (/^VG\d{3,4}$/.test(compact)) {
    return compact;
  }

  if (/^LJ\d{3,4}$/.test(compact)) {
    return compact;
  }

  return compact;
}

function extractCandidateUnitCodes(row = {}) {
  const candidates = [];

  if (row.codigo_unidade) candidates.push(row.codigo_unidade);
  if (row.unidade) candidates.push(row.unidade);
  if (row.unidade_codigo) candidates.push(row.unidade_codigo);

  if (Array.isArray(row.expanded_units)) {
    row.expanded_units.forEach((unit) => {
      if (typeof unit === "string") candidates.push(unit);
      if (unit?.unidade_codigo) candidates.push(unit.unidade_codigo);
      if (unit?.codigo_unidade) candidates.push(unit.codigo_unidade);
    });
  }

  return [...new Set(candidates.map(normalizeUnitCode).filter(Boolean))];
}

function buildMirrorIndex(mirrorUnits = []) {
  const index = new Map();

  mirrorUnits.forEach((unit) => {
    const code = normalizeUnitCode(unit.codigo_unidade || unit.unidade || unit.unit_code);
    if (!code) return;

    const normalizedStatus = normalizeMirrorStatus(
      unit.status || unit.status_espelho || unit.cor || unit.color || unit.raw_status
    );

    index.set(code, {
      ...unit,
      codigo_unidade: code,
      mirror_status: normalizedStatus.status,
      mirror_label: normalizedStatus.label,
      mirror_severity: normalizedStatus.severity,
      can_sell: normalizedStatus.can_sell,
      requires_confirmation: normalizedStatus.requires_confirmation,
      status_raw: normalizedStatus.raw,
    });
  });

  return index;
}

function summarizeMirrorMatch({ candidateCodes, matchedUnits }) {
  if (!matchedUnits.length) {
    return {
      matched: false,
      candidate_codes: candidateCodes,
      status: "desconhecido",
      label: "Sem correspondência no espelho",
      sale_state: "unmatched",
      can_sell: false,
      requires_confirmation: true,
      matched_count: 0,
      available_count: 0,
      unavailable_count: 0,
      units: [],
      available_units: [],
      unavailable_units: [],
    };
  }

  const available = matchedUnits.filter((unit) => unit.can_sell);
  const unavailable = matchedUnits.filter((unit) => !unit.can_sell);

  let saleState = "blocked";
  let label = "Indisponível no espelho";

  if (available.length && unavailable.length) {
    saleState = "partial";
    label = "Parcialmente disponível";
  } else if (available.length) {
    saleState = "available";
    label = "Disponível";
  }

  return {
    matched: true,
    candidate_codes: candidateCodes,
    status: saleState,
    label,
    sale_state: saleState,
    matched_count: matchedUnits.length,
    available_count: available.length,
    unavailable_count: unavailable.length,
    can_sell: available.length > 0,
    requires_confirmation:
      unavailable.length > 0 || matchedUnits.some((unit) => unit.requires_confirmation),
    units: matchedUnits,
    available_units: available,
    unavailable_units: unavailable,
  };
}

export function reconcileUnitsWithMirror(priceRows = [], mirrorUnits = []) {
  const mirrorIndex = buildMirrorIndex(mirrorUnits);

  return priceRows.map((row) => {
    const candidateCodes = extractCandidateUnitCodes(row);
    const matchedUnits = candidateCodes
      .map((code) => mirrorIndex.get(code))
      .filter(Boolean);

    return {
      ...row,
      mirror: summarizeMirrorMatch({ candidateCodes, matchedUnits }),
    };
  });
}

export { normalizeUnitCode };
