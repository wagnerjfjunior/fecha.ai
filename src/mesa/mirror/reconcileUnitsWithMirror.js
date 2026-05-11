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

export function reconcileUnitsWithMirror(priceRows = [], mirrorUnits = []) {
  const mirrorIndex = buildMirrorIndex(mirrorUnits);

  return priceRows.map((row) => {
    const candidateCodes = extractCandidateUnitCodes(row);
    const matchedUnits = candidateCodes
      .map((code) => mirrorIndex.get(code))
      .filter(Boolean);

    if (!matchedUnits.length) {
      return {
        ...row,
        mirror: {
          matched: false,
          candidate_codes: candidateCodes,
          status: "desconhecido",
          label: "Sem correspondência no espelho",
          can_sell: false,
          requires_confirmation: true,
        },
      };
    }

    const unavailable = matchedUnits.filter((unit) => !unit.can_sell);
    const available = matchedUnits.filter((unit) => unit.can_sell);

    return {
      ...row,
      mirror: {
        matched: true,
        candidate_codes: candidateCodes,
        matched_count: matchedUnits.length,
        available_count: available.length,
        unavailable_count: unavailable.length,
        can_sell: available.length > 0 && unavailable.length === 0,
        requires_confirmation: matchedUnits.some((unit) => unit.requires_confirmation),
        units: matchedUnits,
      },
    };
  });
}

export { normalizeUnitCode };
