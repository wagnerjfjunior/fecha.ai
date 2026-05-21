const MAX_JSON_ADMIN_BYTES = 2 * 1024 * 1024;
const MAX_JSON_ADMIN_UNITS = 500;

const ALLOWED_ROOT_KEYS = new Set([
  'schemaVersion',
  'schema_version',
  'empreendimentoNome',
  'empreendimento_nome',
  'empreendimento',
  'nome_empreendimento',
  'incorporadora',
  'bairro',
  'cidade',
  'nomeArquivo',
  'nome_arquivo',
  'fileName',
  'filename',
  'parserNome',
  'parser_nome',
  'parser',
  'layout',
  'confidence',
  'confianca',
  'quality',
  'source',
  'metadata',
  'data',
  'meta_obra_pct',
  'unidades',
  'units',
  'rows',
  'items',
]);

const ALLOWED_UNIT_KEYS = new Set([
  'row_index',
  'rowIndex',
  'torre',
  'bloco',
  'unidade',
  'apto',
  'apartamento',
  'numero',
  'id_unidade',
  'final',
  'prumada',
  'andar',
  'pavimento',
  'metragem',
  'area',
  'area_m2',
  'm2',
  'dormitorios',
  'dorms',
  'quartos',
  'suites',
  'suite',
  'vagas_quantidade',
  'vagas',
  'qtde_vagas',
  'valor_tabela',
  'valor',
  'preco',
  'total',
  'valor_total',
  'preco_total',
  'status_comercial',
  'status',
  'planta_tipo',
  'planta',
  'tipologia',
  'observacoes',
  'obs',
  'confianca_linha',
  'confianca',
  'confidence',
  'sinal_1',
  'ato',
  'ato_qtd',
  'a4_each',
  'complemento_each',
  'comp_qtd',
  'mensal_each',
  'mensais_each',
  'mensal_qtd',
  'inter_each',
  'intermediaria_each',
  'inter_qtd',
  'inter_tipo',
  'chaves_each',
  'unica_each',
  'parcela_unica_each',
  'parcela_unica',
  'unica',
  'unica_qtd',
  'financiamento',
  'principal_financ_set_29',
  'principal_financ_original_set_29',
  'financiamento_price_11_2029',
  'financ_corrigido_original_11_2029',
  'meta_obra_pct',
  'soma_pre_financiamento',
  'principal_residual_para_bater_total',
  'financiamento_pct_por_total',
  'obra_pct_por_total_menos_principal',
  'financiamento_observacao',
  'periodicidade_observacao',
  'raw',
]);

function assertPlainObject(value, label) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    throw new Error(`${label} deve ser um objeto JSON.`);
  }
}

function rejectPrototypeKeys(value, path = 'payload') {
  if (!value || typeof value !== 'object') return;

  for (const key of Object.keys(value)) {
    if (key === '__proto__' || key === 'prototype' || key === 'constructor') {
      throw new Error(`Chave proibida no JSON administrativo: ${path}.${key}`);
    }
    rejectPrototypeKeys(value[key], `${path}.${key}`);
  }
}

function warnUnknownRootKeys(root) {
  return Object.keys(root).filter(key => !ALLOWED_ROOT_KEYS.has(key));
}

function warnUnknownUnitKeys(unit) {
  return Object.keys(unit || {}).filter(key => !ALLOWED_UNIT_KEYS.has(key));
}

export function isJsonAdminFile(file) {
  const name = String(file?.name || '').toLowerCase();
  return name.endsWith('.json') || file?.type === 'application/json';
}

export function assertCanReadJsonAdminFile(file) {
  if (!file) throw new Error('Arquivo JSON administrativo ausente.');

  if (!isJsonAdminFile(file)) {
    throw new Error('Arquivo administrativo inválido. Use .json.');
  }

  if (Number(file.size || 0) > MAX_JSON_ADMIN_BYTES) {
    throw new Error('JSON administrativo excede 2MB. Divida a importação.');
  }
}

export function validateJsonAdminPayloadShape(rawInput) {
  const parsed = typeof rawInput === 'string' ? JSON.parse(rawInput) : rawInput;
  const root = Array.isArray(parsed) ? { unidades: parsed } : parsed;
  assertPlainObject(root, 'Payload administrativo');
  rejectPrototypeKeys(root);

  const unidades = root.units || root.unidades || root.data?.unidades || root.data?.units || root.rows || root.items || [];

  if (!Array.isArray(unidades) || unidades.length === 0) {
    throw new Error('JSON administrativo sem array de unidades.');
  }

  if (unidades.length > MAX_JSON_ADMIN_UNITS) {
    throw new Error(`JSON administrativo excede ${MAX_JSON_ADMIN_UNITS} unidades.`);
  }

  const rootUnknown = warnUnknownRootKeys(root);
  const unitUnknown = new Set();

  unidades.forEach((unit, index) => {
    assertPlainObject(unit, `Unidade ${index + 1}`);
    for (const key of warnUnknownUnitKeys(unit)) unitUnknown.add(key);
  });

  return {
    root,
    unidades,
    warnings: [
      ...(rootUnknown.length ? [`Campos raiz ignorados: ${rootUnknown.slice(0, 12).join(', ')}`] : []),
      ...(unitUnknown.size ? [`Campos de unidade ignorados: ${Array.from(unitUnknown).slice(0, 12).join(', ')}`] : []),
    ],
  };
}
