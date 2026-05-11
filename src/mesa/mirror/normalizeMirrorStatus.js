const STATUS_MAP = {
  // Disponibilidade comercial
  disponivel: "disponivel",
  disponível: "disponivel",
  estoque: "disponivel",
  livre: "disponivel",
  branco: "disponivel",
  white: "disponivel",

  // Vendida / escriturada
  vendida: "vendida",
  vendido: "vendida",
  escriturada: "vendida",
  escriturado: "vendida",
  azul: "vendida",
  blue: "vendida",

  // Reservas
  reservado: "reservada",
  reservada: "reservada",
  reserva: "reservada",
  laranja: "reservada",
  orange: "reservada",
  bege: "reservada",

  // Bloqueios / fora de venda
  bloqueada: "bloqueada",
  bloqueado: "bloqueada",
  bloqueio: "bloqueada",
  indisponivel: "bloqueada",
  indisponível: "bloqueada",
  preta: "bloqueada",
  preto: "bloqueada",
  black: "bloqueada",
  cinza: "bloqueada",
  gray: "bloqueada",
  grey: "bloqueada",

  "fora de venda": "fora_de_venda",
  "fora venda": "fora_de_venda",
  "fora_de_venda": "fora_de_venda",
  "fora de louvor": "fora_de_venda",

  // Processo jurídico/comercial
  "contrato processo": "contrato_processo",
  "contrato em processo": "contrato_processo",
  "em contrato": "contrato_processo",
  processo: "contrato_processo",

  "contrato assinado": "contrato_assinado",
  assinado: "contrato_assinado",

  // Permuta
  permuta: "permuta",

  // Célula inexistente no espelho
  "-": "inexistente",
  vazio: "inexistente",
  inexistente: "inexistente",
};

export const MIRROR_STATUS_LABELS = {
  disponivel: "Disponível",
  vendida: "Vendida",
  reservada: "Reservada",
  bloqueada: "Bloqueada",
  fora_de_venda: "Fora de venda",
  contrato_processo: "Contrato em processo",
  contrato_assinado: "Contrato assinado",
  permuta: "Permuta",
  inexistente: "Inexistente",
  desconhecido: "Desconhecido",
};

export const MIRROR_STATUS_SEVERITY = {
  disponivel: "success",
  vendida: "blocked",
  reservada: "warning",
  bloqueada: "blocked",
  fora_de_venda: "blocked",
  contrato_processo: "warning",
  contrato_assinado: "blocked",
  permuta: "warning",
  inexistente: "neutral",
  desconhecido: "warning",
};

export function normalizeMirrorStatus(input) {
  const raw = String(input || "").trim();
  if (!raw) {
    return {
      status: "desconhecido",
      label: MIRROR_STATUS_LABELS.desconhecido,
      severity: MIRROR_STATUS_SEVERITY.desconhecido,
      raw,
      can_sell: false,
      requires_confirmation: true,
    };
  }

  const key = raw
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/\s+/g, " ")
    .trim();

  const status = STATUS_MAP[key] || STATUS_MAP[raw.toLowerCase()] || "desconhecido";
  const label = MIRROR_STATUS_LABELS[status] || MIRROR_STATUS_LABELS.desconhecido;
  const severity = MIRROR_STATUS_SEVERITY[status] || MIRROR_STATUS_SEVERITY.desconhecido;

  return {
    status,
    label,
    severity,
    raw,
    can_sell: status === "disponivel",
    requires_confirmation: ["reservada", "contrato_processo", "permuta", "desconhecido"].includes(status),
  };
}

export function canSellMirrorStatus(input) {
  return normalizeMirrorStatus(input).can_sell;
}
