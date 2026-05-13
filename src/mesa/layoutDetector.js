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

  // Tabela de lançamento flat com fluxo completo em linha.
  // Ex.: YPY Alto do Ipiranga — UNIDADE, ÁREA, ATO, COMPLEMENTO ATO, MENSAIS, ÚNICA, FINANCIAMENTO, TOTAL.
  // Usa o caminho nativo split_block_table, que agora delega internamente para o parser launch_flat.
  // Precisa rodar antes do hierarchical_tegra, porque o mesmo PDF também tem quadro técnico por finais/pavimentos.
  if (
    has("unidade") &&
    has("area") &&
    has("ato") &&
    has("complemento ato") &&
    has("mensais") &&
    hasAny("unica", "única") &&
    has("financiamento") &&
    has("total") &&
    hasSelectableUnit
  ) {
    return {
      layout: "split_block_table",
      confidence: 0.93,
      reason: "Detectada tabela de lançamento com ATO, complemento, mensal, parcela única, financiamento e total em linha.",
    };
  }

  // Espelho de vendas sem tabela financeira.
  // Ex.: Bueno Brandão 257 high-end com apenas unidades, áreas e vagas, sem valor total/financiamento.
  // O PDF pode extrair "Espelho" como "E spelho", por isso usamos regex tolerante.
  // Este arquivo é útil como espelho/estoque, mas não permite Mesa Cliente financeira.
  if (
    hasSalesMirrorTitle &&
    hasAny("andar", "pavimento") &&
    hasSelectableUnit &&
    hasAny("m²", "m2") &&
    !hasFinancialHeader
  ) {
    return {
      layout: "sales_mirror_without_values",
      confidence: 0.91,
      reason: "Detectado espelho de vendas com unidades/áreas/vagas, mas sem valores financeiros para montar proposta.",
    };
  }

  // Espelho compacto Tegra: ATO + FINANCIAMENTO + FINAL(IS) + VALOR TOTAL.
  // Ex.: Universo Tatuapé Órbita e Bem Moema Studios & Offices.
  // Deve rodar antes de ready_stock_table para não cair indevidamente em fallback Worker/Make.
  if (
    hasSalesMirrorTitle &&
    hasAny("andar") &&
    hasAny("unidade") &&
    hasAny("area", "m2", "m²") &&
    hasAny("sinal ato") &&
    hasAny("financiamento bancario", "financiamento bancário") &&
    hasAny("final(is)", "periodicidade") &&
    hasAny("valor total")
  ) {
    return {
      layout: "split_block_table",
      confidence: 0.92,
      reason: "Detectado espelho compacto com ATO, financiamento, final/periodicidade e valor total.",
    };
  }

  // Estoque pronto para morar: uma linha por unidade, sem mensais/intermediárias.
  // Ex.: ELO Duo com ATO + FINANCIAMENTO + TOTAL.
  if (
    has("unidade") &&
    has("area") &&
    has("vagas") &&
    has("ato") &&
    has("financiamento") &&
    has("total") &&
    /\bAP\d{4}\b/i.test(raw) &&
    !hasAny("espelho de vendas", "final(is)", "periodicidade") &&
    !hasAny("mensais", "complemento ato", "c. ato", "intermediaria", "intermediária")
  ) {
    return {
      layout: "ready_stock_table",
      confidence: 0.93,
      reason: "Detectada tabela de estoque pronto para morar com ATO, financiamento e total.",
    };
  }

  // Tabela comercial por Final + faixa de andar.
  // Ex.: Garden Design, Nova Vivere e demais tabelas Tegra/Helbor com fluxo financeiro por final.
  // Deve rodar antes dos layouts genéricos para não cair em hierarchical_tegra.
  if (
    hasFinalBlock &&
    hasCommercialHeader &&
    (hasFloorRange || /garden\s+ap\d{4}/i.test(raw))
  ) {
    return {
      layout: "range_by_final_table",
      confidence: 0.94,
      reason: "Detectada tabela comercial por final, faixa de andar e fluxo financeiro.",
    };
  }

  // Espelhos Portal/Vendas em que a extração do PDF separa o bloco de unidades
  // do bloco de valores financeiros. Ex.: Garden Design.
  if (
    hasSalesMirrorTitle &&
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
    hasSalesMirrorTitle &&
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
