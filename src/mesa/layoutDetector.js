function normalizeForLayout(value = "") {
  return String(value || "")
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\u00a0/g, " ")
    .replace(/\s+/g, " ")
    .toLowerCase()
    .trim();
}

export function detectLayout(text = "") {
  const raw = String(text || "");
  const t = normalizeForLayout(raw);

  const has = (...terms) => terms.every((term) => t.includes(normalizeForLayout(term)));
  const hasAny = (...terms) => terms.some((term) => t.includes(normalizeForLayout(term)));

  const hasFloorRange = /\d{1,2}\s*(?:º|o|°|a\.)?\s*(?:e|a|ao)\s*\d{1,2}\s*(?:º|o|°)?\s*andar/i.test(raw);
  const hasFinalBlock = /final\s+0?\d{1,2}(?:\s+e\s+0?\d{1,2})?/i.test(raw);
  const hasSalesMirrorTitle = hasAny("espelho de vendas", "tabela de vendas") || /e\s*spelho\s+de\s+vendas/i.test(raw);
  const hasSelectableUnit = /\b(AP|SC|SU|LJ)\d{4}\b/i.test(raw);
  const hasCommercialMoneyRow = /\b(AP|SC|SU|LJ)\d{4}\b[\s\S]{0,180}(?:R\$|\$)\s*\d[\d.]*,\d{2}[\s\S]{0,260}(?:R\$|\$)\s*\d[\d.]*,\d{2}/i.test(raw);
  const hasReadyStockCommercialRow = /\b(AP|SC|SU|LJ)\d{4}\b\s+\d{1,4}(?:[,.]\d{1,3})?\s+\d{1,2}(?:\s+Moto)?\s+(?:R\$|\$)?\s*[\d.]+,\d{2}\s+(?:R\$|\$)?\s*[\d.]+,\d{2}\s+(?:R\$|\$)?\s*[\d.]+,\d{2}/i.test(raw);
  const hasFinancialHeader = hasAny(
    "valor total",
    "preco total",
    "preço total",
    "financiamento bancario",
    "financiamento bancário",
    "sinal ato",
    "parcela unica",
    "parcela única",
    "complemento ato",
    "c. ato",
    "mensal(is)",
    "intermediaria",
    "intermediária"
  );
  const hasCommercialHeader =
    has("area") &&
    has("vagas") &&
    has("ato") &&
    hasAny("c. ato", "c ato") &&
    has("mensais") &&
    has("financiamento") &&
    has("valor total") &&
    hasAny("negocio imobiliario", "negócio imobiliário");

  if (
    has("bosque vila nova") &&
    hasFinalBlock &&
    hasAny("jatoba", "jatobá", "manaca", "manacá") &&
    hasAny("sinal", "30 / 60 / 90 / 120") &&
    hasAny("finan. imobiliario", "finan. imobiliário", "financiamento") &&
    /\d{1,2}\s*º?\s*Andar\s+\d{2,4}\s+\d{2,4}/i.test(raw)
  ) {
    return { layout: "split_block_table", confidence: 0.94, reason: "Detectada tabela AW Realty por torre/final/andar com unidade numérica e fluxo financeiro explícito." };
  }

  if (
    (has("sereno jardim sao paulo") || has("fluxo de pagamento")) &&
    /\bUnidades?\s+\d+/i.test(raw) &&
    hasAny("ato") &&
    hasAny("mensal", "mensais") &&
    hasAny("anual", "anuais") &&
    hasAny("unica", "única") &&
    hasAny("periodicidade") &&
    hasAny("financiamento")
  ) {
    return { layout: "split_block_table", confidence: 0.94, reason: "Detectada tabela AW Realty com unidades numéricas agrupadas e fluxo financeiro completo." };
  }

  if (
    has("unidade") && has("area") && has("ato") && has("complemento ato") && has("mensais") &&
    hasAny("unica", "única") && has("financiamento") && has("total") && hasSelectableUnit
  ) {
    return { layout: "split_block_table", confidence: 0.93, reason: "Detectada tabela de lançamento com ATO, complemento, mensal, parcela única, financiamento e total em linha." };
  }

  if (hasSalesMirrorTitle && hasAny("andar", "pavimento") && hasSelectableUnit && hasAny("m²", "m2") && !hasFinancialHeader) {
    return { layout: "sales_mirror_without_values", confidence: 0.91, reason: "Detectado espelho de vendas com unidades/áreas/vagas, mas sem valores financeiros para montar proposta." };
  }

  if (
    has("unidade") && has("area") && has("vagas") && has("ato") && has("financiamento") && has("total") &&
    hasSelectableUnit && hasReadyStockCommercialRow &&
    !hasAny("mensais", "complemento ato", "c. ato", "intermediaria", "intermediária")
  ) {
    return { layout: "ready_stock_table", confidence: 0.94, reason: "Detectada tabela comercial pronta/estoque com ATO, financiamento e total em linha." };
  }

  if (
    hasSalesMirrorTitle && hasAny("andar") && hasAny("unidade") && hasAny("area", "m2", "m²") &&
    hasAny("sinal ato") && hasAny("financiamento bancario", "financiamento bancário") &&
    hasAny("final(is)", "periodicidade") && hasAny("valor total")
  ) {
    return { layout: "split_block_table", confidence: 0.92, reason: "Detectado espelho compacto com ATO, financiamento, final/periodicidade e valor total." };
  }

  if (hasFinalBlock && hasCommercialHeader && (hasFloorRange || /garden\s+ap\d{4}/i.test(raw))) {
    return { layout: "range_by_final_table", confidence: 0.94, reason: "Detectada tabela comercial por final, faixa de andar e fluxo financeiro." };
  }

  if (
    hasSalesMirrorTitle && hasAny("andar") && hasAny("unidade") && hasAny("area", "m2", "m²") &&
    hasAny("sinal ato") && hasAny("complemento ato", "c. ato") && hasAny("mensal") &&
    hasAny("intermediaria", "intermediária") && hasAny("financiamento bancario", "financiamento bancário") && hasAny("valor total")
  ) {
    return { layout: "split_block_table", confidence: 0.91, reason: "Detectado espelho com unidades e valores financeiros em blocos separados." };
  }

  if (hasSelectableUnit && hasCommercialMoneyRow && hasAny("ato", "sinal", "financiamento") && hasAny("valor total", "total", "preco", "preço")) {
    return { layout: "split_block_table", confidence: 0.9, reason: "Detectada tabela comercial explícita com unidade AP/SC/SU/LJ e valores financeiros em linha/bloco." };
  }

  if (hasAny("final 01", "final 1", "final 02", "final 03", "garden ap") && hasAny("1o ao", "1º ao", "7o e 8o", "7º e 8º", "andar") && hasAny("financiamento", "valor total", "negocio imobiliario")) {
    return { layout: "hierarchical_tegra", confidence: 0.86, reason: "Detectados Final/Garden/faixas de andar e colunas financeiras." };
  }

  if (hasAny("fluxo de pagamento", "unidades 71", "unidades 72", "pavimento") && hasAny("ato", "mensais", "financiamento")) {
    return { layout: "grouped_sereno", confidence: 0.78, reason: "Detectado fluxo de pagamento com agrupamento por unidade/pavimento." };
  }

  if (hasAny("andar", "unidade") && hasAny("area privativa", "area", "m2", "m²") && hasAny("preco da unidade", "preço da unidade", "valor total", "valor")) {
    return { layout: "singleline_flat", confidence: 0.72, reason: "Detectada tabela linha-a-linha com unidade, área e preço." };
  }

  if (hasSalesMirrorTitle && hasAny("intermediaria", "intermediaria", "parcela", "saldo")) {
    return { layout: "erp_table", confidence: 0.74, reason: "Detectado layout amplo tipo espelho/ERP de vendas." };
  }

  return { layout: "legacy", confidence: 0.5, reason: "Nenhum layout especializado detectado; usando parser legado." };
}
