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

  const hasFloorRange = /\d{1,2}\s*(?:º|o|°)?\s*(?:e|a)\s*\d{1,2}\s*(?:º|o|°)?\s*andar/i.test(raw);
  const hasFinalBlock = /final\s+0?\d{1,2}(?:\s+e\s+0?\d{1,2})?/i.test(raw);

  // Tabela comercial por Final + faixa de andar.
  // Ex.: Garden Design - Tabela de Lançamento, sem unidade explícita AP3313.
  // Deve rodar antes dos layouts genéricos para não cair em hierarchical_tegra.
  // A extração do PDF.js vem com espaçamento irregular no cabeçalho, por isso
  // a detecção precisa ser semântica e não depender de uma frase única compacta.
  if (
    hasAny("garden design private park residence", "empreendimento: garden design") &&
    hasFinalBlock &&
    hasFloorRange &&
    has("area") &&
    has("vagas") &&
    has("ato") &&
    hasAny("c. ato", "c ato") &&
    has("mensais") &&
    has("anuais") &&
    has("financiamento") &&
    has("valor total") &&
    hasAny("negocio imobiliario", "negócio imobiliário")
  ) {
    return {
      layout: "range_by_final_table",
      confidence: 0.94,
      reason: "Detectada tabela comercial Garden por final e faixa de andar.",
    };
  }

  // Espelhos Portal/Vendas em que a extração do PDF separa o bloco de unidades
  // do bloco de valores financeiros. Ex.: Garden Design.
  if (
    hasAny("espelho de vendas", "tabela de vendas") &&
    hasAny("andar") &&
    hasAny("unidade") &&
    hasAny("area", "m2", "m²") &&
    hasAny("sinal ato") &&
    hasAny("complemento ato", "c. ato") &&
    hasAny("mensal") &&
    hasAny("intermediaria", "intermediária") &&
    hasAny("financiamento bancario", "financiamento bancário") &&
    hasAny("valor total")
  ) {
    return {
      layout: "split_block_table",
      confidence: 0.91,
      reason: "Detectado espelho com unidades e valores financeiros em blocos separados.",
    };
  }

  // Tabelas hierárquicas/contextuais, comuns em Tegra/Caminhos/Nova Vivere/Garden.
  // Geralmente possuem Final, faixas de andar, Garden e herança de contexto.
  if (
    hasAny("final 01", "final 1", "final 02", "final 03", "garden ap") &&
    hasAny("1o ao", "1º ao", "7o e 8o", "7º e 8º", "andar") &&
    hasAny("financiamento", "valor total", "negocio imobiliario")
  ) {
    return {
      layout: "hierarchical_tegra",
      confidence: 0.86,
      reason: "Detectados Final/Garden/faixas de andar e colunas financeiras.",
    };
  }

  // Tabelas agrupadas por fluxo/pavimento/unidades, exemplo Sereno e variações.
  if (
    hasAny("fluxo de pagamento", "unidades 71", "unidades 72", "pavimento") &&
    hasAny("ato", "mensais", "financiamento")
  ) {
    return {
      layout: "grouped_sereno",
      confidence: 0.78,
      reason: "Detectado fluxo de pagamento com agrupamento por unidade/pavimento.",
    };
  }

  // Tabelas flat/linha a linha, comuns em AW/Bosque/Elo/Cyrela simples.
  if (
    hasAny("andar", "unidade") &&
    hasAny("area privativa", "area", "m2", "m²") &&
    hasAny("preco da unidade", "preço da unidade", "valor total", "valor")
  ) {
    return {
      layout: "singleline_flat",
      confidence: 0.72,
      reason: "Detectada tabela linha-a-linha com unidade, área e preço.",
    };
  }

  // Tabelas estilo espelho/ERP, com muitas colunas financeiras horizontais.
  if (
    hasAny("espelho de vendas", "tabela de vendas") &&
    hasAny("intermediaria", "intermediaria", "parcela", "saldo")
  ) {
    return {
      layout: "erp_table",
      confidence: 0.74,
      reason: "Detectado layout amplo tipo espelho/ERP de vendas.",
    };
  }

  return {
    layout: "legacy",
    confidence: 0.5,
    reason: "Nenhum layout especializado detectado; usando parser legado.",
  };
}
