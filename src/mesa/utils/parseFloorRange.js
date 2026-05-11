function normalizeText(value = "") {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase()
    .replace(/°/g, "º")
    .trim();
}

function toInt(value) {
  const n = Number.parseInt(String(value || "").replace(/\D/g, ""), 10);
  return Number.isFinite(n) ? n : null;
}

export function parseFloorRange(value = "") {
  const original = String(value || "").trim();
  const text = normalizeText(original);

  if (!text) {
    return {
      raw: original,
      tipo: "unknown",
      inicio: null,
      fim: null,
      pavimentos: [],
    };
  }

  if (text.includes("garden")) {
    return {
      raw: original,
      tipo: "garden",
      inicio: null,
      fim: null,
      pavimentos: [],
    };
  }

  const rangeMatch = text.match(/(\d+)\s*(?:º|o)?\s*(?:ao|a)\s*(\d+)\s*(?:º|o)?/i);
  if (rangeMatch) {
    const inicio = toInt(rangeMatch[1]);
    const fim = toInt(rangeMatch[2]);
    const start = Math.min(inicio, fim);
    const end = Math.max(inicio, fim);

    return {
      raw: original,
      tipo: "range",
      inicio: start,
      fim: end,
      pavimentos: Array.from({ length: end - start + 1 }, (_, i) => start + i),
    };
  }

  const pairMatch = text.match(/(\d+)\s*(?:º|o)?\s*e\s*(\d+)\s*(?:º|o)?/i);
  if (pairMatch) {
    const a = toInt(pairMatch[1]);
    const b = toInt(pairMatch[2]);
    const start = Math.min(a, b);
    const end = Math.max(a, b);

    return {
      raw: original,
      tipo: "pair",
      inicio: start,
      fim: end,
      pavimentos: [a, b].filter((n) => n !== null),
    };
  }

  const singleMatch = text.match(/(\d+)\s*(?:º|o)?\s*andar/i);
  if (singleMatch) {
    const andar = toInt(singleMatch[1]);
    return {
      raw: original,
      tipo: "single",
      inicio: andar,
      fim: andar,
      pavimentos: andar === null ? [] : [andar],
    };
  }

  return {
    raw: original,
    tipo: "unknown",
    inicio: null,
    fim: null,
    pavimentos: [],
  };
}
