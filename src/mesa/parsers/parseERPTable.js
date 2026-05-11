import { legacyParser } from "./legacyParser";
import { parseSplitBlockTable } from "./parseSplitBlockTable";

export function parseERPTable(input, options = {}) {
  const source = String(input || "");
  const normalized = source
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();

  const looksLikeSplitBlock =
    normalized.includes("espelho de vendas") &&
    normalized.includes("andar") &&
    normalized.includes("unidade") &&
    normalized.includes("sinal ato") &&
    normalized.includes("valor total") &&
    normalized.includes("financiamento");

  if (looksLikeSplitBlock) {
    return parseSplitBlockTable(source, options).rows;
  }

  return legacyParser(source);
}
