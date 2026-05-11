import { legacyParser } from "./legacyParser";

export function parseFlatTable(csvText) {
  return legacyParser(csvText);
}
