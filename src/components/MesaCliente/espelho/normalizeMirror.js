import { inferStatusFromEvidence } from './statusRules';

const UNIT_RE = /\b(?:AP|VG|LJ|CJ)?\s*(\d{2,5})\b/i;

export function onlyDigits(value) {
  return String(value ?? '').replace(/\D+/g, '');
}

export function normalizeUnitCode(value) {
  const raw = String(value ?? '').trim().toUpperCase().replace(/\s+/g, '');
  if (!raw) return null;
  const match = raw.match(/^(AP|VG|LJ|CJ)?(\d{2,5})$/i) || raw.match(UNIT_RE);
  if (!match) return null;
  const digits = onlyDigits(match[2] || match[1]);
  if (!digits || digits.length < 2) return null;
  return `AP${digits.padStart(4, '0')}`;
}

export function extractUnitMeta(unitCode) {
  const digits = onlyDigits(unitCode);
  if (digits.length < 2) return { unidade: unitCode, andar: null, final: null };
  const final = digits.slice(-2);
  const andarRaw = digits.slice(0, -2);
  const andar = andarRaw ? Number.parseInt(andarRaw, 10) : null;
  return {
    unidade: `AP${digits.padStart(4, '0')}`,
    andar: Number.isFinite(andar) ? andar : null,
    final,
  };
}

export function normalizeMirrorCell(cell = {}) {
  const code = normalizeUnitCode(cell.unidade || cell.label || cell.text || cell.code);
  if (!code) return null;

  const meta = extractUnitMeta(code);
  const symbols = Array.isArray(cell.symbols)
    ? cell.symbols
    : String(cell.text || '').split(/\s+/).filter((part) => /[$!]|\bid\b/i.test(part));

  const inferred = inferStatusFromEvidence({ symbols, color: cell.color || cell.rgb || cell.fill });

  return {
    ...meta,
    status_espelho: inferred.status,
    disponibilidade_espelho: inferred.disponibilidade,
    confidence: inferred.confidence,
    status_label: inferred.label,
    evidence: inferred.evidence,
    symbols,
    bbox: cell.bbox || null,
    page: cell.page || null,
    raw: cell,
  };
}

export function normalizeMirrorCells(cells = []) {
  const map = new Map();

  for (const cell of Array.isArray(cells) ? cells : []) {
    const normalized = normalizeMirrorCell(cell);
    if (!normalized) continue;

    const current = map.get(normalized.unidade);
    if (!current || normalized.confidence > current.confidence) {
      map.set(normalized.unidade, normalized);
    }
  }

  return Array.from(map.values()).sort((a, b) => {
    const andarA = a.andar ?? 999;
    const andarB = b.andar ?? 999;
    if (andarA !== andarB) return andarB - andarA;
    return String(a.final || '').localeCompare(String(b.final || ''), 'pt-BR', { numeric: true });
  });
}

export function summarizeMirrorUnits(units = []) {
  const total = units.length;
  const provavelDisponivel = units.filter((u) => u.disponibilidade_espelho === 'provavel_disponivel').length;
  const validar = units.filter((u) => u.disponibilidade_espelho === 'validar').length;
  const indefinida = units.filter((u) => u.disponibilidade_espelho === 'indefinida').length;

  return {
    total,
    provavelDisponivel,
    validar,
    indefinida,
    confidenceMedia: total
      ? Number((units.reduce((acc, unit) => acc + Number(unit.confidence || 0), 0) / total).toFixed(2))
      : 0,
  };
}

export function mergeCommercialUnitsWithMirror({ unidadesComerciais = [], unidadesEspelho = [] } = {}) {
  const mirrorByCode = new Map((unidadesEspelho || []).map((unit) => [normalizeUnitCode(unit.unidade), unit]));

  return (unidadesComerciais || []).map((unit) => {
    const code = normalizeUnitCode(unit.unidade || unit.codigo_unidade);
    const mirror = mirrorByCode.get(code);
    return {
      ...unit,
      espelho: mirror || null,
      disponibilidade_espelho: mirror?.disponibilidade_espelho || 'nao_cruzado',
      status_espelho: mirror?.status_espelho || 'sem_espelho',
      confidence_espelho: mirror?.confidence || 0,
    };
  });
}
