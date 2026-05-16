function toNumber(value) {
  if (value === null || value === undefined || value === '') return 0;
  let s = String(value).trim();
  if (!s) return 0;
  const hasComma = s.includes(',');
  const hasDot = s.includes('.');
  if (hasComma && hasDot) {
    s = s.lastIndexOf(',') > s.lastIndexOf('.') ? s.replace(/\./g, '').replace(',', '.') : s.replace(/,/g, '');
  } else if (hasComma) {
    s = s.replace(/\./g, '').replace(',', '.');
  }
  s = s.replace(/[^0-9.-]/g, '');
  const n = Number.parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}

export function normalizeAvailabilityUnit(value) {
  const raw = String(value ?? '').trim().toUpperCase().replace(/\s+/g, '');
  if (!raw) return null;
  const match = raw.match(/^(AP|VG|LJ|CJ)?(\d{2,5})$/i) || raw.match(/\b(?:AP|VG|LJ|CJ)?\s*(\d{2,5})\b/i);
  if (!match) return null;
  const prefix = match[1] && /^(AP|VG|LJ|CJ)$/i.test(match[1]) ? match[1].toUpperCase() : 'AP';
  const digits = String(match[2] || match[1] || '').replace(/\D+/g, '');
  if (!digits || digits.length < 2) return null;
  return `${prefix}${digits.padStart(4, '0')}`;
}

export function extractAvailabilityMeta(unitCode) {
  const normalized = normalizeAvailabilityUnit(unitCode);
  if (!normalized) return { unidade: null, andar: null, final: null };
  const digits = normalized.replace(/\D+/g, '');
  const final = digits.slice(-2);
  const andarRaw = digits.slice(0, -2);
  const andar = andarRaw ? Number.parseInt(andarRaw, 10) : null;
  return {
    unidade: normalized,
    andar: Number.isFinite(andar) ? andar : null,
    final,
  };
}

export function detectAvailabilityGeneratedAt(text = '') {
  const clean = String(text || '').replace(/\s+/g, ' ').trim();
  const explicit = clean.match(/GERADO\s+EM\s+(\d{2}\/\d{2})(?:\/(\d{4}))?\s*-?\s*(\d{2}:\d{2})/i);
  if (explicit) {
    const [, dayMonth, year, hour] = explicit;
    return `${dayMonth}${year ? `/${year}` : ''} ${hour}`;
  }
  const generic = clean.match(/(\d{2}\/\d{2}\/\d{4})\s*(?:às|as|-)?\s*(\d{2}:\d{2})/i);
  if (generic) return `${generic[1]} ${generic[2]}`;
  return null;
}

export function buildAvailabilitySnapshot({ rows = [], metadata = {} } = {}) {
  const units = [];
  const seen = new Set();

  for (const row of Array.isArray(rows) ? rows : []) {
    const unidade = normalizeAvailabilityUnit(row.unidade || row.codigo_unidade || row.apartamento || row.ap || row.unit);
    if (!unidade || seen.has(unidade)) continue;
    seen.add(unidade);

    const meta = extractAvailabilityMeta(unidade);
    units.push({
      ...meta,
      status_disponibilidade: 'disponivel',
      origem_status: 'tabela_oficial_disponibilidade',
      area_m2: toNumber(row.metragem ?? row.area_m2 ?? row.area ?? row.privativa),
      valor_total: toNumber(row.valor_tabela ?? row.valor_total ?? row.total),
      sinal_ato: toNumber(row.sinal_1 ?? row.sinal ?? row.ato),
      complemento_ato: toNumber(row.a4_each ?? row.complemento ?? row.complemento_ato),
      mensal_valor: toNumber(row.mensal_each ?? row.mensal),
      mensal_qtd: Number.parseInt(row.mensal_qtd || row.qtd_mensais || '0', 10) || 0,
      intermediaria_valor: toNumber(row.inter_each ?? row.intermediaria ?? row.anual),
      intermediaria_qtd: Number.parseInt(row.inter_qtd || row.qtd_intermediarias || '0', 10) || 0,
      parcela_unica: toNumber(row.chaves_each ?? row.parcela_unica ?? row.unica),
      financiamento: toNumber(row.financiamento ?? row.financiamento_bancario),
      raw: row,
    });
  }

  return {
    origem: 'tabela_oficial_disponibilidade',
    gerado_em: metadata.gerado_em || metadata.generatedAt || null,
    arquivo_nome: metadata.nomeArquivo || metadata.fileName || null,
    total_unidades_disponiveis: units.length,
    unidades: units.sort((a, b) => {
      if ((a.andar ?? 999) !== (b.andar ?? 999)) return (b.andar ?? 999) - (a.andar ?? 999);
      return String(a.final || '').localeCompare(String(b.final || ''), 'pt-BR', { numeric: true });
    }),
  };
}

export function applyAvailabilityToCommercialUnits({ unidadesComerciais = [], unidadesDisponiveis = [] } = {}) {
  const availableMap = new Map((unidadesDisponiveis || []).map((unit) => [normalizeAvailabilityUnit(unit.unidade), unit]));

  return (unidadesComerciais || []).map((unit) => {
    const code = normalizeAvailabilityUnit(unit.unidade || unit.codigo_unidade);
    const disponibilidade = availableMap.get(code) || null;
    const isAvailable = Boolean(disponibilidade);

    return {
      ...unit,
      disponibilidade_oficial: isAvailable ? 'disponivel' : 'indisponivel',
      disponibilidade_snapshot: disponibilidade,
      disponibilidade_label: isAvailable ? 'Disponível na tabela oficial' : 'Indisponível na tabela oficial',
      disponibilidade_watermark: isAvailable ? null : 'INDISPONÍVEL',
      disabled_by_availability: !isAvailable,
    };
  });
}

export function summarizeAvailabilityCrosscheck({ unidadesComerciais = [], unidadesDisponiveis = [] } = {}) {
  const commercialSet = new Set((unidadesComerciais || []).map((u) => normalizeAvailabilityUnit(u.unidade || u.codigo_unidade)).filter(Boolean));
  const availableSet = new Set((unidadesDisponiveis || []).map((u) => normalizeAvailabilityUnit(u.unidade)).filter(Boolean));

  let disponiveisCruzadas = 0;
  let indisponiveisNaOficial = 0;
  for (const unit of commercialSet) {
    if (availableSet.has(unit)) disponiveisCruzadas += 1;
    else indisponiveisNaOficial += 1;
  }

  let oficiaisSemComercial = 0;
  for (const unit of availableSet) {
    if (!commercialSet.has(unit)) oficiaisSemComercial += 1;
  }

  return {
    totalComercial: commercialSet.size,
    totalDisponibilidadeOficial: availableSet.size,
    disponiveisCruzadas,
    indisponiveisNaOficial,
    oficiaisSemComercial,
  };
}
