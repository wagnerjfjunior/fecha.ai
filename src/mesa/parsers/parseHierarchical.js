import { parseFloorRange } from "../utils/parseFloorRange";
import { legacyParser } from "./legacyParser";

function normalizeFinal(value = "") {
  const raw = String(value || "").trim();
  if (!raw) return "";

  const match = raw.match(/(\d{1,2})(?:\s*e\s*(\d{1,2}))?/i);
  if (!match) return raw;

  if (match[2]) {
    return `${match[1].padStart(2, "0")} e ${match[2].padStart(2, "0")}`;
  }

  return match[1].padStart(2, "0");
}

function looksLikeFloorRange(value = "") {
  const s = String(value || "").toLowerCase();
  return (
    s.includes("andar") ||
    s.includes("º") ||
    s.includes("°") ||
    /\d+\s*(o|º|°)?\s*(ao|a|e)\s*\d+/i.test(s) ||
    /garden/i.test(s)
  );
}

function enrichHierarchicalContext(rows = []) {
  let currentFinal = "";
  let currentAndar = "";

  return rows.map((row) => {
    const next = { ...row };

    if (next.final) {
      currentFinal = normalizeFinal(next.final);
      next.final = currentFinal;
    } else if (currentFinal) {
      next.final = currentFinal;
    }

    if (looksLikeFloorRange(next.andar)) {
      currentAndar = next.andar;
    } else if (!next.andar && currentAndar) {
      next.andar = currentAndar;
    }

    const floorMeta = parseFloorRange(next.andar);

    if (/garden/i.test(String(next.andar || "")) && /^ap\d+/i.test(String(next.unidade || ""))) {
      next.tipo = "Garden";
    }

    return {
      ...next,
      floor_meta: floorMeta,
      parser_meta: {
        ...(next.parser_meta || {}),
        parser: "parseHierarchical",
        inherited_final: !row.final && !!currentFinal,
        inherited_andar: !row.andar && !!currentAndar,
        floor_tipo: floorMeta.tipo,
      },
    };
  });
}

export function parseHierarchical(csvText) {
  const rows = legacyParser(csvText);
  return enrichHierarchicalContext(rows);
}
