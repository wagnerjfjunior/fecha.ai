function normalizeFinals(finalValue = "") {
  const raw = String(finalValue || "").trim();
  if (!raw) return [];

  const matches = raw.match(/\d{1,2}/g) || [];

  return [...new Set(matches.map((m) => m.padStart(2, "0")))];
}

function buildUnitCode(andar, finalCode) {
  const floor = String(Number(andar)).padStart(2, "0");
  return `${floor}${finalCode}`;
}

export function expandHierarchicalUnits(row) {
  const floorMeta = row?.floor_meta || {};
  const finals = normalizeFinals(row?.final);

  if (!finals.length) {
    return [];
  }

  const pavimentos = Array.isArray(floorMeta.pavimentos)
    ? floorMeta.pavimentos
    : [];

  if (!pavimentos.length) {
    return finals.map((finalCode) => ({
      unidade_codigo: finalCode,
      final: finalCode,
      andar: null,
      grupo_id: row?.id || null,
      original_unidade: row?.unidade || null,
      expanded_from_range: false,
    }));
  }

  const expanded = [];

  pavimentos.forEach((andar) => {
    finals.forEach((finalCode) => {
      expanded.push({
        unidade_codigo: buildUnitCode(andar, finalCode),
        final: finalCode,
        andar,
        grupo_id: row?.id || null,
        original_unidade: row?.unidade || null,
        expanded_from_range: true,
      });
    });
  });

  return expanded;
}
