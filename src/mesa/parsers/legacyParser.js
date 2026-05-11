const CANON_COLUMNS = [
  "empreendimento",
  "torre",
  "final",
  "andar",
  "unidade",
  "area_m2",
  "preco_total",
  "sinal_1",
  "a4_each",
  "mensal_qtd",
  "mensal_each",
  "inter_tipo",
  "inter_qtd",
  "inter_each",
  "chaves_each",
  "financiamento",
  "observacoes",
];

function toNum(value) {
  if (value === 0) return 0;
  if (!value) return 0;

  let s = String(value).trim();
  const hasComma = s.includes(",");
  const hasDot = s.includes(".");

  if (hasComma && (!hasDot || s.lastIndexOf(",") > s.lastIndexOf("."))) {
    s = s.replace(/\./g, "").replace(",", ".");
  } else {
    s = s.replace(/,/g, "");
  }

  s = s.replace(/[^\d.-]/g, "");
  const n = Number.parseFloat(s);
  return Number.isFinite(n) ? n : 0;
}

export function legacyParser(csvText) {
  const normalized = String(csvText || "").trim();
  if (!normalized) return [];

  const lines = normalized.split(/\r?\n/).filter(Boolean);
  if (lines.length < 2) return [];

  const header = lines[0]
    .split(";")
    .map((h) => h.trim().toLowerCase());

  const index = {};

  header.forEach((h, i) => {
    if (!h) return;

    // evita sobrescrever primeira ocorrência válida
    if (index[h] === undefined) {
      index[h] = i;
    }
  });

  const get = (cells, key) => {
    const i = index[key];
    return i === undefined ? "" : cells[i] ?? "";
  };

  return lines
    .slice(1)
    .map((line, rowIndex) => {
      const cells = line.split(";");

      const row = {};

      CANON_COLUMNS.forEach((key) => {
        row[key] = get(cells, key);
      });

      return {
        id: `${row.unidade || "unidade"}-${rowIndex}`,
        empreendimento: row.empreendimento,
        torre: row.torre,
        final: row.final,
        andar: row.andar,
        unidade: row.unidade || `Linha ${rowIndex + 1}`,
        area_m2: toNum(row.area_m2),
        preco_total: toNum(row.preco_total),
        sinal_1: toNum(row.sinal_1),
        a4_each: toNum(row.a4_each),
        mensal_qtd: toNum(row.mensal_qtd),
        mensal_each: toNum(row.mensal_each),
        inter_tipo: row.inter_tipo,
        inter_qtd: toNum(row.inter_qtd),
        inter_each: toNum(row.inter_each),
        chaves_each: toNum(row.chaves_each),
        financiamento: toNum(row.financiamento),
        observacoes: row.observacoes,
        raw: row,
      };
    })
    .filter((row) => row.unidade || row.preco_total > 0);
}
