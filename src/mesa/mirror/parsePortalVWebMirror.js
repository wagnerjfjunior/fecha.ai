import { normalizeMirrorStatus } from "./normalizeMirrorStatus";
import { normalizeUnitCode } from "./reconcileUnitsWithMirror";

const UNIT_PATTERN = /\b(?:AP|VG|LJ)?\s*\d{3,4}\b/gi;

const COLOR_STATUS_RULES = [
  {
    name: "azul",
    status: "vendida",
    test: ({ hex, text }) =>
      /azul|vendid|escriturad/i.test(text) ||
      ["#0000ff", "#000099", "#0000cc", "#1d4ed8", "#2563eb", "#2f37a2", "#0033cc"].includes(hex),
  },
  {
    name: "branco",
    status: "disponivel",
    test: ({ hex, text }) =>
      /branco|disponivel|disponível|livre|estoque/i.test(text) ||
      ["#fff", "#ffffff", "white"].includes(hex),
  },
  {
    name: "laranja",
    status: "reservada",
    test: ({ hex, text }) =>
      /laranja|reservad|reserva/i.test(text) ||
      ["#f97316", "#fb923c", "#fdba74", "orange"].includes(hex),
  },
  {
    name: "preto",
    status: "bloqueada",
    test: ({ hex, text }) =>
      /preto|bloquead|indisponivel|indisponível/i.test(text) ||
      ["#000", "#000000", "black"].includes(hex),
  },
  {
    name: "cinza",
    status: "bloqueada",
    test: ({ hex, text }) =>
      /cinza|bloquead|fora de venda/i.test(text) ||
      ["#808080", "#6b7280", "#9ca3af", "gray", "grey"].includes(hex),
  },
];

function normalizeText(value = "") {
  return String(value || "")
    .replace(/&nbsp;/gi, " ")
    .replace(/<br\s*\/?/gi, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function stripTags(value = "") {
  return normalizeText(String(value || "").replace(/<[^>]*>/g, " "));
}

function normalizeHex(value = "") {
  const raw = String(value || "").trim().toLowerCase();
  if (!raw) return "";

  if (["white", "black", "orange", "gray", "grey"].includes(raw)) return raw;

  const shortHex = raw.match(/^#([0-9a-f]{3})$/i);
  if (shortHex) {
    return `#${shortHex[1]
      .split("")
      .map((c) => c + c)
      .join("")}`.toLowerCase();
  }

  const longHex = raw.match(/^#([0-9a-f]{6})$/i);
  if (longHex) return raw;

  return raw;
}

function rgbToHex(rgb = "") {
  const match = String(rgb).match(/rgba?\s*\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})/i);
  if (!match) return "";

  const toHex = (n) => Math.max(0, Math.min(255, Number(n) || 0)).toString(16).padStart(2, "0");
  return `#${toHex(match[1])}${toHex(match[2])}${toHex(match[3])}`;
}

function extractBackground(fragment = "") {
  const html = String(fragment || "");

  const bgAttr = html.match(/bgcolor=["']?([^"'\s>]+)/i)?.[1];
  if (bgAttr) return normalizeHex(bgAttr);

  const bgStyle = html.match(/background(?:-color)?\s*:\s*([^;"']+)/i)?.[1];
  if (bgStyle) {
    const value = bgStyle.trim();
    if (/rgba?\s*\(/i.test(value)) return rgbToHex(value);
    return normalizeHex(value);
  }

  const classMatch = html.match(/class=["']([^"']+)["']/i)?.[1] || "";
  if (/vendid|azul|blue/i.test(classMatch)) return "azul";
  if (/disponivel|disponível|branco|white|livre|estoque/i.test(classMatch)) return "branco";
  if (/reserv|laranja|orange/i.test(classMatch)) return "laranja";
  if (/bloq|preto|black|cinza|gray|grey/i.test(classMatch)) return "bloqueada";

  return "";
}

function inferStatusFromFragment(fragment = "") {
  const text = stripTags(fragment);
  const hex = extractBackground(fragment);

  const matchedRule = COLOR_STATUS_RULES.find((rule) => rule.test({ hex, text }));
  const raw = matchedRule?.status || hex || text || "desconhecido";
  const normalized = normalizeMirrorStatus(raw);

  return {
    raw_status: matchedRule?.name || raw,
    color: hex,
    ...normalized,
  };
}

function parseUnitMeta(unitCode = "") {
  const normalized = normalizeUnitCode(unitCode);
  const number = normalized.replace(/^(AP|VG|LJ)/, "");

  if (!/^AP\d{4}$/.test(normalized)) {
    return {
      codigo_unidade: normalized,
      andar: null,
      final: null,
      tipo: normalized.startsWith("VG") ? "vaga" : normalized.startsWith("LJ") ? "loja" : "outro",
    };
  }

  return {
    codigo_unidade: normalized,
    andar: Number(number.slice(0, -2)),
    final: number.slice(-2),
    tipo: "apartamento",
  };
}

function splitHtmlCells(input = "") {
  const html = String(input || "");
  const cellMatches = [...html.matchAll(/<(td|th|div|span|button)[^>]*>[\s\S]*?<\/\1>/gi)];

  if (!cellMatches.length) return [];

  return cellMatches
    .map((match) => match[0])
    .filter((fragment) => UNIT_PATTERN.test(fragment))
    .map((fragment) => {
      UNIT_PATTERN.lastIndex = 0;
      return fragment;
    });
}

function parseStructuredRows(rows = []) {
  return rows
    .map((row) => {
      const code = normalizeUnitCode(row.codigo_unidade || row.unidade || row.unit_code || row.code);
      if (!code) return null;

      const normalizedStatus = normalizeMirrorStatus(row.status || row.raw_status || row.cor || row.color || "desconhecido");
      const meta = parseUnitMeta(code);

      return {
        ...meta,
        status: normalizedStatus.status,
        raw_status: normalizedStatus.raw,
        label: normalizedStatus.label,
        severity: normalizedStatus.severity,
        can_sell: normalizedStatus.can_sell,
        requires_confirmation: normalizedStatus.requires_confirmation,
        source: row.source || "structured",
      };
    })
    .filter(Boolean);
}

function parseTextOrHtml(input = "") {
  const content = String(input || "");
  const fragments = splitHtmlCells(content);

  if (fragments.length) {
    return fragments.flatMap((fragment) => {
      const unitMatches = stripTags(fragment).match(UNIT_PATTERN) || [];
      const status = inferStatusFromFragment(fragment);

      return unitMatches.map((unit) => ({
        ...parseUnitMeta(unit),
        status: status.status,
        raw_status: status.raw_status,
        color: status.color,
        label: status.label,
        severity: status.severity,
        can_sell: status.can_sell,
        requires_confirmation: status.requires_confirmation,
        source: "html_fragment",
      }));
    });
  }

  const unitMatches = content.match(UNIT_PATTERN) || [];

  return unitMatches.map((unit) => {
    const meta = parseUnitMeta(unit);
    const status = inferStatusFromFragment(content);

    return {
      ...meta,
      status: status.status,
      raw_status: status.raw_status,
      color: status.color,
      label: status.label,
      severity: status.severity,
      can_sell: status.can_sell,
      requires_confirmation: true,
      source: "text_fallback",
    };
  });
}

export function parsePortalVWebMirror(input, options = {}) {
  const parsed = Array.isArray(input) ? parseStructuredRows(input) : parseTextOrHtml(input);

  const unique = new Map();

  parsed.forEach((unit) => {
    if (!unit.codigo_unidade) return;
    unique.set(unit.codigo_unidade, {
      empreendimento: options.empreendimento || "",
      mirror_source: options.source || "portal_vweb",
      mirror_generated_at: options.generated_at || null,
      ...unit,
    });
  });

  const units = [...unique.values()].sort((a, b) => a.codigo_unidade.localeCompare(b.codigo_unidade));

  return {
    ok: true,
    parser: "parsePortalVWebMirror",
    total_units: units.length,
    units,
    summary: units.reduce((acc, unit) => {
      acc[unit.status] = (acc[unit.status] || 0) + 1;
      return acc;
    }, {}),
  };
}
