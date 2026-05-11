export function detectLayout(text = "") {
  const raw = String(text || "");
  const t = raw
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .toLowerCase();

  const has = (...terms) => terms.every((term) => t.includes(String(term).toLowerCase()));
  const hasAny = (...terms) => terms.some((term) => t.includes(String(term).toLowerCase()));

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
