import { legacyParser } from "./legacyParser";

export function parseERPTable(csvText) {
  // Foundation inicial para layouts ERP/espelho.
  return legacyParser(csvText);
}
