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

function toNumberLike(value) {
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

function hasFinancialShift(cells, index) {
  const preco = cells[index.preco_total];
  const sinal = cells[index.sinal_1];
  const a4 = cells[index.a4_each];
  const mensalQtd = cells[index.mensal_qtd];

  return (
    cells.length > CANON_COLUMNS.length &&
    !preco &&
    !sinal &&
    toNumberLike(a4) > 1000 &&
    toNumberLike(mensalQtd) > 1000
  );
}

export function normalizeCanonCells(cells = [], headerIndex = {}) {
  const original = [...cells];
  const issues = [];

  if (original.length !== CANON_COLUMNS.length) {
    issues.push(`csv_colunas=${original.length};esperado=${CANON_COLUMNS.length}`);
  }

  if (!hasFinancialShift(original, headerIndex)) {
    return {
      cells: original,
      repaired: false,
      issues,
    };
  }

  // Caso típico detectado no Nova Vivere:
  // area_m2;preco_total;sinal_1;a4_each;mensal_qtd...
  // 118.20;;;40100;13400;44;3200...
  // O Make desloca os valores financeiros duas colunas para a direita.
  const repaired = [...original];

  repaired[headerIndex.preco_total] = ""; // preço total permanece bloqueado se não veio do Make
  repaired[headerIndex.sinal_1] = original[headerIndex.a4_each] || "";
  repaired[headerIndex.a4_each] = original[headerIndex.mensal_qtd] || "";
  repaired[headerIndex.mensal_qtd] = original[headerIndex.mensal_each] || "";
  repaired[headerIndex.mensal_each] = original[headerIndex.inter_tipo] || "";
  repaired[headerIndex.inter_tipo] = original[headerIndex.inter_qtd] || "";
  repaired[headerIndex.inter_qtd] = original[headerIndex.inter_each] || "";
  repaired[headerIndex.inter_each] = original[headerIndex.chaves_each] || "";
  repaired[headerIndex.chaves_each] = original[headerIndex.financiamento] || "";
  repaired[headerIndex.financiamento] = original[headerIndex.observacoes] || "";
  repaired[headerIndex.observacoes] = original[headerIndex.observacoes + 1] || original[headerIndex.observacoes] || "";

  issues.push("reparo_shift_financeiro_aplicado");
  issues.push("preco_total_nao_reconstituido_por_segurança");

  return {
    cells: repaired.slice(0, CANON_COLUMNS.length),
    repaired: true,
    issues,
  };
}
