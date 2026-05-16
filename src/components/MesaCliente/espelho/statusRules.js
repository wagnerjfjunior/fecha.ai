const DEFAULT_SYMBOL_RULES = [
  {
    id: 'money_signal',
    match: (value) => /[$＄]/.test(value),
    status: 'provavel_disponivel',
    confidence: 0.72,
    label: 'Sinal comercial encontrado',
    reason: 'O espelho trouxe símbolo de valor próximo à unidade.',
  },
  {
    id: 'alert_signal',
    match: (value) => /[!！]/.test(value),
    status: 'atencao_validar',
    confidence: 0.52,
    label: 'Atenção / validar status',
    reason: 'O espelho trouxe símbolo de alerta próximo à unidade.',
  },
  {
    id: 'id_signal',
    match: (value) => /\bid\b/i.test(value),
    status: 'tem_identificador',
    confidence: 0.48,
    label: 'Identificador encontrado',
    reason: 'O espelho trouxe marcação de identificação próxima à unidade.',
  },
];

const COLOR_RULES = [
  {
    id: 'blue_or_purple_cell',
    status: 'provavel_disponivel',
    confidence: 0.78,
    label: 'Cor comercial positiva',
    reason: 'A célula possui cor próxima de azul/roxo, comum em unidades com sinal comercial no espelho.',
    test: ({ r, g, b }) => b >= 110 && r <= 130 && g <= 150,
  },
  {
    id: 'dark_cell',
    status: 'atencao_validar',
    confidence: 0.58,
    label: 'Cor escura / validar',
    reason: 'A célula possui cor escura. Sem legenda oficial, o status precisa ser validado.',
    test: ({ r, g, b }) => r <= 70 && g <= 70 && b <= 70,
  },
  {
    id: 'orange_cell',
    status: 'atencao_validar',
    confidence: 0.56,
    label: 'Cor laranja / validar',
    reason: 'A célula possui cor de alerta. Sem legenda oficial, o status precisa ser validado.',
    test: ({ r, g, b }) => r >= 180 && g >= 90 && g <= 180 && b <= 120,
  },
];

export function normalizeRgb(color) {
  if (!color) return null;
  if (Array.isArray(color) && color.length >= 3) {
    const [r, g, b] = color.map((v) => Math.round(Number(v) <= 1 ? Number(v) * 255 : Number(v)));
    if ([r, g, b].every(Number.isFinite)) return { r, g, b };
  }
  if (typeof color === 'object') {
    const r = Math.round(Number(color.r));
    const g = Math.round(Number(color.g));
    const b = Math.round(Number(color.b));
    if ([r, g, b].every(Number.isFinite)) return { r, g, b };
  }
  return null;
}

export function inferStatusFromEvidence({ symbols = [], color = null } = {}) {
  const evidence = [];

  const joinedSymbols = symbols.filter(Boolean).join(' ');
  for (const rule of DEFAULT_SYMBOL_RULES) {
    if (rule.match(joinedSymbols)) {
      evidence.push({
        source: 'symbol',
        rule: rule.id,
        status: rule.status,
        confidence: rule.confidence,
        label: rule.label,
        reason: rule.reason,
      });
    }
  }

  const rgb = normalizeRgb(color);
  if (rgb) {
    for (const rule of COLOR_RULES) {
      if (rule.test(rgb)) {
        evidence.push({
          source: 'color',
          rule: rule.id,
          status: rule.status,
          confidence: rule.confidence,
          label: rule.label,
          reason: rule.reason,
          rgb,
        });
      }
    }
  }

  if (!evidence.length) {
    return {
      status: 'sem_status_no_espelho',
      disponibilidade: 'indefinida',
      confidence: 0.25,
      label: 'Sem sinal claro no espelho',
      evidence: [],
    };
  }

  const best = evidence.slice().sort((a, b) => b.confidence - a.confidence)[0];
  return {
    status: best.status,
    disponibilidade: best.status === 'provavel_disponivel' ? 'provavel_disponivel' : 'validar',
    confidence: best.confidence,
    label: best.label,
    evidence,
  };
}

export function statusToUi(status) {
  const map = {
    provavel_disponivel: { icon: '🟦', label: 'Provável disponível', tone: 'ok' },
    atencao_validar: { icon: '⚠️', label: 'Validar status', tone: 'warn' },
    tem_identificador: { icon: '🪪', label: 'Com identificação', tone: 'info' },
    sem_status_no_espelho: { icon: '▫️', label: 'Sem status claro', tone: 'muted' },
  };
  return map[status] || map.sem_status_no_espelho;
}
