import { legacyParser } from "./legacyParser";

export function parseHierarchical(csvText) {
  // Foundation inicial.
  // Próxima etapa: herança de contexto (final/andar/garden).
  return legacyParser(csvText);
}
