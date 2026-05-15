export function normalizeParserPayload(rawInput) {
  const parsed = typeof rawInput === 'string' ? JSON.parse(rawInput) : rawInput;
  const root = Array.isArray(parsed) ? { unidades: parsed } : parsed;

  if (!root || typeof root !== 'object') {
    throw new Error('Payload do parser inválido. Esperado objeto JSON ou array de unidades.');
  }

  const unidades = root.units || root.unidades || root.data?.unidades || root.data?.units || root.rows || root.items || [];

  if (!Array.isArray(unidades) || unidades.length === 0) {
    throw new Error('JSON sem array de unidades. Use { "unidades": [...] } ou cole diretamente um array.');
  }

  return {
    schemaVersion: root.schema_version || root.schemaVersion || 'mesa_parser_v1',
    empreendimentoNome:
      root.empreendimento_nome ||
      root.empreendimento ||
      root.nome_empreendimento ||
      root.metadata?.empreendimento_nome_detectado ||
      root.data?.empreendimento_nome ||
      '',
    incorporadora:
      root.incorporadora ||
      root.metadata?.incorporadora_detectada ||
      root.data?.incorporadora ||
      '',
    bairro: root.bairro || root.metadata?.bairro || root.data?.bairro || '',
    cidade: root.cidade || root.metadata?.cidade || root.data?.cidade || '',
    nomeArquivo:
      root.nome_arquivo ||
      root.fileName ||
      root.filename ||
      root.source?.filename ||
      'parser-json-manual.json',
    parserNome:
      root.parser_nome ||
      root.parser ||
      root.source?.parser ||
      'manual_json_preview',
    layout: root.layout || root.source?.layout || null,
    confidence: root.quality?.confidence || root.confianca || null,
    unidades: unidades.map(normalizeUnit),
    raw: root,
  };
}

function parseNumber(value) {
  if (value === null || value === undefined || value === '') return null;
  if (typeof value === 'number') return Number.isFinite(value) ? value : null;

  const text = String(value)
    .replace(/R\$/gi, '')
    .replace(/m²/gi, '')
    .replace(/m2/gi, '')
    .replace(/\s/g, '')
    .trim();

  if (!text) return null;

  const hasComma = text.includes(',');
  const normalized = hasComma
    ? text.replace(/\./g, '').replace(',', '.')
    : text.replace(/,/g, '');

  const n = Number(normalized);
  return Number.isFinite(n) ? n : null;
}

function parseInteger(value) {
  const n = parseNumber(value);
  return n === null ? null : Math.trunc(n);
}

function normalizeStatus(value) {
  const status = String(value || 'disponivel').trim().toLowerCase();
  const allowed = new Set(['disponivel', 'reservada', 'proposta', 'vendida', 'bloqueada', 'indisponivel']);
  return allowed.has(status) ? status : 'disponivel';
}

function normalizeConfidence(value) {
  const confidence = String(value || 'alta').trim().toLowerCase();
  const allowed = new Set(['alta', 'media', 'baixa', 'manual_pendente', 'erro_processamento']);
  return allowed.has(confidence) ? confidence : 'media';
}

export function normalizeUnit(unit, index = 0) {
  const unidade = unit.unidade || unit.apto || unit.apartamento || unit.numero || unit.id_unidade || null;
  const valorTabela = parseNumber(unit.valor_tabela ?? unit.valor ?? unit.preco ?? unit.total ?? unit.valor_total);

  return {
    row_index: unit.row_index ?? unit.rowIndex ?? index + 1,
    torre: unit.torre ?? unit.bloco ?? null,
    unidade: unidade === null || unidade === undefined ? null : String(unidade).trim(),
    final: unit.final === null || unit.final === undefined ? null : String(unit.final).trim(),
    andar: parseInteger(unit.andar ?? unit.pavimento),
    metragem: parseNumber(unit.metragem ?? unit.area ?? unit.area_m2 ?? unit.m2),
    dormitorios: parseInteger(unit.dormitorios ?? unit.dorms ?? unit.quartos),
    suites: parseInteger(unit.suites ?? unit.suite),
    vagas_quantidade: parseInteger(unit.vagas_quantidade ?? unit.vagas ?? unit.qtde_vagas),
    valor_tabela: valorTabela,
    status_comercial: normalizeStatus(unit.status_comercial ?? unit.status),
    planta_tipo: unit.planta_tipo ?? unit.planta ?? unit.tipologia ?? null,
    observacoes: unit.observacoes ?? unit.obs ?? null,
    confianca_linha: normalizeConfidence(unit.confianca_linha ?? unit.confianca ?? unit.confidence),
    raw: unit.raw || unit,
  };
}

export function validateParserPayloadForImport(payload) {
  const errors = [];
  const warnings = [];

  if (!payload?.empreendimentoNome?.trim()) {
    errors.push('Informe o nome real do empreendimento.');
  }

  if (!Array.isArray(payload?.unidades) || payload.unidades.length === 0) {
    errors.push('Nenhuma unidade encontrada no payload.');
  }

  const validUnits = [];
  const invalidUnits = [];

  for (const unit of payload?.unidades || []) {
    const unitErrors = [];
    if (!unit.unidade) unitErrors.push('unidade ausente');
    if (!unit.valor_tabela || Number(unit.valor_tabela) <= 0) unitErrors.push('valor_tabela ausente ou inválido');
    if (unit.confianca_linha === 'erro_processamento') unitErrors.push('linha com erro_processamento');

    if (unitErrors.length > 0) {
      invalidUnits.push({ unit, errors: unitErrors });
    } else {
      if (!unit.metragem) warnings.push(`Unidade ${unit.unidade}: metragem ausente.`);
      validUnits.push(unit);
    }
  }

  if (validUnits.length === 0) {
    errors.push('Nenhuma unidade válida para importação.');
  }

  return {
    ok: errors.length === 0,
    errors,
    warnings,
    totalRows: payload?.unidades?.length || 0,
    validUnits,
    invalidUnits,
  };
}
