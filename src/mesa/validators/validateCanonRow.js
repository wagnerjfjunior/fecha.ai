export function validateCanonRow(row = {}) {
  const issues = [];

  const num = (v) => Number(v || 0);

  const area = num(row.area_m2);
  const precoTotal = num(row.preco_total);
  const financiamento = num(row.financiamento);
  const mensalQtd = num(row.mensal_qtd);
  const mensalEach = num(row.mensal_each);
  const interQtd = num(row.inter_qtd);
  const interEach = num(row.inter_each);

  // Área inválida
  if (area <= 0 || area > 2000) {
    issues.push("area_m2 inválida");
  }

  // Preço total obrigatório
  if (precoTotal <= 0) {
    issues.push("preco_total ausente");
  }

  // Financiamento obrigatório
  if (financiamento <= 0) {
    issues.push("financiamento ausente");
  }

  // Quantidade de mensais normalmente pequena
  if (mensalQtd > 500 || mensalQtd < 0) {
    issues.push("mensal_qtd fora do padrão");
  }

  // Quantidade intermediárias pequena
  if (interQtd > 100 || interQtd < 0) {
    issues.push("inter_qtd fora do padrão");
  }

  // Valor mensal muito baixo ou absurdo
  if (mensalEach > precoTotal && precoTotal > 0) {
    issues.push("mensal_each maior que preco_total");
  }

  // Intermediária absurda
  if (interEach > precoTotal && precoTotal > 0) {
    issues.push("inter_each maior que preco_total");
  }

  // Sinais claros de shift de coluna
  if (mensalQtd > 1000) {
    issues.push("possível deslocamento de colunas no CSV");
  }

  return {
    valid: issues.length === 0,
    issues,
  };
}
