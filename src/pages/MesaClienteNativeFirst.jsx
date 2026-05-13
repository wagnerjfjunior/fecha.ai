import { useMemo, useState } from "react";
import { detectLayout } from "../mesa/layoutDetector";
import { legacyParser } from "../mesa/parsers/legacyParser";
import { parseFlatTable } from "../mesa/parsers/parseFlatTable";
import { parseHierarchical } from "../mesa/parsers/parseHierarchical";
import { parseERPTable } from "../mesa/parsers/parseERPTable";
import { parseSplitBlockTable } from "../mesa/parsers/parseSplitBlockTable";
import { parseRangeByFinalTable } from "../mesa/parsers/parseRangeByFinalTable";
import { parseReadyStockTable } from "../mesa/parsers/parseReadyStockTable";
import { parsePortalVWebMirror } from "../mesa/mirror/parsePortalVWebMirror";
import { reconcileUnitsWithMirror } from "../mesa/mirror/reconcileUnitsWithMirror";

const WORKER_URL = import.meta.env.VITE_MESA_CLIENTE_WORKER_URL || import.meta.env.VITE_MESA_WORKER_URL || "https://mesacliente.wagnerjfjunior.workers.dev/";
const PDFJS_URL = "https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.min.js";
const PDFJS_WORKER_URL = "https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js";

const brl = (v) => new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(Number(v) || 0);
const num = (v) => new Intl.NumberFormat("pt-BR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(Number(v) || 0);
const validRow = (u) => u?.validation?.valid !== false;
const mirrorLoaded = (m) => Array.isArray(m?.units) && m.units.length > 0;
const isSelectableUnit = (u) => /^(AP|SC|SU|LJ)\d{4}$/i.test(String(u?.unidade || "").trim());
const isApartmentUnit = isSelectableUnit;

function loadScriptOnce(src, globalName) {
  return new Promise((resolve, reject) => {
    if (globalName && window[globalName]) return resolve(window[globalName]);
    const existing = document.querySelector(`script[src="${src}"]`);
    if (existing) {
      existing.addEventListener("load", () => resolve(globalName ? window[globalName] : true));
      existing.addEventListener("error", reject);
      return;
    }
    const script = document.createElement("script");
    script.src = src;
    script.async = true;
    script.onload = () => resolve(globalName ? window[globalName] : true);
    script.onerror = () => reject(new Error(`Falha ao carregar script: ${src}`));
    document.head.appendChild(script);
  });
}

async function extractPdfText(file) {
  const pdfjsLib = await loadScriptOnce(PDFJS_URL, "pdfjsLib");
  pdfjsLib.GlobalWorkerOptions.workerSrc = PDFJS_WORKER_URL;
  const buffer = await file.arrayBuffer();
  const pdf = await pdfjsLib.getDocument({ data: new Uint8Array(buffer) }).promise;
  const pages = [];
  let text = "";
  for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
    const page = await pdf.getPage(pageNumber);
    const content = await page.getTextContent();
    const pageText = content.items.map((item) => item.str).join(" ").trim();
    text += `${pageText}\n`;
    pages.push({
      page: pageNumber,
      chars: pageText.length,
      hasValorTotal: /valor\s+total/i.test(pageText),
      hasFinanciamento: /financiamento/i.test(pageText),
      hasUnidade: /unidade/i.test(pageText),
      start: pageText.slice(0, 120),
      end: pageText.slice(-120),
    });
  }
  const clean = text.trim();
  return { text: clean, diagnostics: { total_pages: pdf.numPages, total_chars: clean.length, pages } };
}

async function workerConvert({ text, filename, empreendimento }) {
  const res = await fetch(WORKER_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-mesa-version": "fechai-native-first" },
    body: JSON.stringify({ mode: "mergeY", text, filename, empreendimento: empreendimento || "" }),
  });
  const raw = await res.text();
  let data;
  try { data = JSON.parse(raw); } catch { data = { csv_text: raw }; }
  if (!res.ok) throw new Error(data?.error || `Worker retornou HTTP ${res.status}`);
  if (!data?.csv_text) throw new Error("Worker não retornou csv_text.");
  return data.csv_text;
}

function parseCsvFallback(csv, text, options) {
  const detection = detectLayout(text);
  if (detection.layout === "hierarchical_tegra") return { rows: parseHierarchical(csv), detection };
  if (detection.layout === "singleline_flat") return { rows: parseFlatTable(csv), detection };
  if (detection.layout === "erp_table") return { rows: parseERPTable(csv, options), detection };
  return { rows: legacyParser(csv), detection };
}

async function parseNativeFirst({ text, filename, empreendimento, pdfDiagnostics }) {
  const detection = detectLayout(text);
  if (detection.layout === "sales_mirror_without_values") {
    return {
      rows: [],
      csvText: "",
      detection: { ...detection, source: "parser_nativo" },
      pipeline: { engine: "sales_mirror_without_values", worker_used: false, make_used: false, rows: 0, pdf: pdfDiagnostics },
      hardError: "Este arquivo é um espelho de vendas com unidades, áreas e vagas, mas não contém valores financeiros. Envie a tabela comercial com valor total, sinal/ato e financiamento para montar a Mesa do Cliente.",
    };
  }
  if (detection.layout === "ready_stock_table") {
    const native = parseReadyStockTable(text, { empreendimento });
    if (native.rows.length) {
      return {
        rows: native.rows,
        csvText: native.csvText,
        detection: { ...detection, source: "parser_nativo" },
        pipeline: { engine: "parseReadyStockTable", worker_used: false, make_used: false, rows: native.rows.length, pdf: pdfDiagnostics, parser: native.diagnostics },
      };
    }
  }
  if (detection.layout === "range_by_final_table") {
    const native = parseRangeByFinalTable(text, { empreendimento });
    if (native.rows.length) {
      return {
        rows: native.rows,
        csvText: native.csvText,
        detection: { ...detection, source: "parser_nativo" },
        pipeline: { engine: "parseRangeByFinalTable", worker_used: false, make_used: false, rows: native.rows.length, pdf: pdfDiagnostics, parser: native.diagnostics },
      };
    }
  }
  if (detection.layout === "split_block_table") {
    const native = parseSplitBlockTable(text, { empreendimento });
    if (native.rows.length) {
      return {
        rows: native.rows,
        csvText: native.csvText,
        detection: { ...detection, source: "parser_nativo" },
        pipeline: { engine: "parseSplitBlockTable", worker_used: false, make_used: false, rows: native.rows.length, pdf: pdfDiagnostics, parser: native.diagnostics },
      };
    }
  }
  const csv = await workerConvert({ text, filename, empreendimento });
  const parsed = parseCsvFallback(csv, text, { empreendimento });
  return {
    rows: parsed.rows,
    csvText: csv,
    detection: { ...parsed.detection, source: "worker_make_fallback" },
    pipeline: { engine: "worker_make", worker_used: true, make_used: true, rows: parsed.rows.length, csv_chars: csv.length, pdf: pdfDiagnostics },
  };
}

function resumo(u) {
  if (!u || !validRow(u)) return { total: 0, entrada: 0, curto: 0, mensais: 0, inter: 0, chaves: 0, financiamento: 0, area: 0, m2: 0 };
  const total = Number(u.preco_total) || 0;
  const curtoQtd = getObsInt(u.observacoes, "comp_qtd", 3);
  return {
    total,
    entrada: Number(u.sinal_1) || 0,
    curto: (Number(u.a4_each) || 0) * curtoQtd,
    mensais: (Number(u.mensal_each) || 0) * (Number(u.mensal_qtd) || 0),
    inter: (Number(u.inter_each) || 0) * (Number(u.inter_qtd) || 0),
    chaves: Number(u.chaves_each) || 0,
    financiamento: Number(u.financiamento) || 0,
    area: Number(u.area_m2) || 0,
    m2: Number(u.area_m2) > 0 ? total / Number(u.area_m2) : 0,
  };
}

function getObsInt(observacoes = "", key, fallback = 0) {
  const match = String(observacoes || "").match(new RegExp(`${key}=([0-9]+)`, "i"));
  const value = match ? Number.parseInt(match[1], 10) : Number.NaN;
  return Number.isFinite(value) && value > 0 ? value : fallback;
}

function getObsNumber(observacoes = "", key, fallback = Number.NaN) {
  const match = String(observacoes || "").match(new RegExp(`${key}=(-?[0-9]+(?:\\.[0-9]+)?)`, "i"));
  const value = match ? Number.parseFloat(match[1]) : Number.NaN;
  return Number.isFinite(value) ? value : fallback;
}

function getPaymentDiffStatus(u) {
  if (!u?.observacoes) return null;
  const diff = getObsNumber(u.observacoes, "check_diff");
  const tolerance = getObsNumber(u.observacoes, "check_tolerance", 0);
  if (!Number.isFinite(diff) || !Number.isFinite(tolerance) || tolerance <= 0) return null;
  const abs = Math.abs(diff);
  if (abs <= 10) return { kind: "ok", diff, tolerance, label: "Conferência financeira OK" };
  if (abs <= tolerance) return { kind: "rounding", diff, tolerance, label: "Arredondamento aceito pela tabela" };
  return { kind: "blocked", diff, tolerance, label: "Diferença financeira acima da tolerância" };
}

function inferLinhaFromUnidade(unidade = "") {
  const digits = String(unidade || "").replace(/\D/g, "");
  return digits.length >= 2 ? digits.slice(-2) : "";
}

function inferAndarFromUnidade(unidade = "") {
  const digits = String(unidade || "").replace(/\D/g, "");
  if (digits.length < 4) return "";
  const andar = Number.parseInt(digits.slice(0, -2), 10);
  return Number.isFinite(andar) ? String(andar) : "";
}

function formatUnitOption(u, hasMirror = false) {
  const status = validRow(u) ? "✅" : "⚠️";
  const linha = u.final || inferLinhaFromUnidade(u.unidade);
  const andar = u.andar || inferAndarFromUnidade(u.unidade);
  const parts = [
    linha ? `Linha ${linha}` : null,
    andar ? `Andar ${andar}` : null,
    u.unidade || null,
    Number(u.area_m2) > 0 ? `${num(u.area_m2)} m²` : null,
    validRow(u) ? brl(u.preco_total) : "inconsistência",
  ].filter(Boolean);

  const mirrorInfo = hasMirror ? ` — ${u.mirror?.label || "sem espelho"}` : "";
  return `${status} ${parts.join(" — ")}${mirrorInfo}`;
}

function paymentDisplay({ total, qtd, parcela, qtdFallback = 0 }) {
  const qty = Number(qtd || 0) || qtdFallback;
  const each = Number(parcela || 0);
  const totalValue = Number(total || 0);

  if (qty > 0 && each > 0) {
    const calculatedTotal = totalValue || each * qty;
    return {
      value: brl(each),
      helper: `${qty}x de ${brl(each)}`,
      detail: `Total: ${brl(calculatedTotal)}`,
    };
  }

  return {
    value: brl(totalValue),
    helper: "",
    detail: "",
  };
}

function Card({ label, value, helper, detail }) {
  return (
    <div className="rounded-2xl border-l-4 border-blue-500 bg-white p-4 shadow-sm">
      <p className="text-xs font-bold uppercase text-gray-400">{label}</p>
      <p className="mt-1 text-xl font-black text-gray-900">{value}</p>
      {helper && <p className="mt-1 text-xs text-gray-500">{helper}</p>}
      {detail && <p className="mt-1 text-[11px] font-semibold text-gray-400">{detail}</p>}
    </div>
  );
}

export default function MesaClienteNativeFirst({ onVoltar }) {
  const [file, setFile] = useState(null);
  const [mirrorFile, setMirrorFile] = useState(null);
  const [empreendimento, setEmpreendimento] = useState("");
  const [status, setStatus] = useState("idle");
  const [erro, setErro] = useState("");
  const [csvText, setCsvText] = useState("");
  const [layout, setLayout] = useState(null);
  const [pipeline, setPipeline] = useState(null);
  const [unidades, setUnidades] = useState([]);
  const [selectedId, setSelectedId] = useState("");
  const [mirror, setMirror] = useState(null);
  const [mirrorErro, setMirrorErro] = useState("");

  const hasMirror = mirrorLoaded(mirror);
  const unidadesRaw = useMemo(() => hasMirror ? reconcileUnitsWithMirror(unidades, mirror.units) : unidades, [unidades, hasMirror, mirror]);
  const unidadesView = useMemo(() => unidadesRaw.filter(isSelectableUnit), [unidadesRaw]);
  const nonApartmentCount = useMemo(() => unidadesRaw.length - unidadesView.length, [unidadesRaw, unidadesView]);
  const selected = useMemo(() => unidadesView.find((u) => u.id === selectedId) || null, [unidadesView, selectedId]);
  const r = useMemo(() => resumo(selected), [selected]);
  const curtoQtd = useMemo(() => getObsInt(selected?.observacoes, "comp_qtd", 3), [selected]);
  const curtoView = useMemo(() => paymentDisplay({ total: r.curto, qtd: curtoQtd, parcela: selected?.a4_each }), [r.curto, curtoQtd, selected]);
  const mensaisView = useMemo(() => paymentDisplay({ total: r.mensais, qtd: selected?.mensal_qtd, parcela: selected?.mensal_each }), [r.mensais, selected]);
  const interView = useMemo(() => paymentDisplay({ total: r.inter, qtd: selected?.inter_qtd, parcela: selected?.inter_each }), [r.inter, selected]);
  const diffStatus = useMemo(() => getPaymentDiffStatus(selected), [selected]);
  const podeSimular = selected && isSelectableUnit(selected) && validRow(selected) && (!hasMirror || selected.mirror?.can_sell === true);
  const invalidas = unidadesView.filter((u) => !validRow(u)).length;

  async function carregarTabela() {
    if (!file) return;
    setStatus("processing");
    setErro("");
    setCsvText("");
    setLayout(null);
    setPipeline(null);
    setUnidades([]);
    setSelectedId("");
    try {
      const extracted = await extractPdfText(file);
      if (extracted.text.length < 20) throw new Error("Texto extraído do PDF ficou vazio ou muito curto.");
      const result = await parseNativeFirst({ text: extracted.text, filename: file.name, empreendimento, pdfDiagnostics: extracted.diagnostics });
      setLayout(result.detection);
      setPipeline(result.pipeline);
      if (result.hardError) throw new Error(result.hardError);
      if (!result.rows.length) throw new Error("Tabela retornou sem unidades válidas.");
      const firstCommercialUnit = result.rows.find(isSelectableUnit);
      if (!firstCommercialUnit) throw new Error("Tabela processada, mas nenhuma unidade AP/SC/SU/LJ comercial foi identificada.");
      setCsvText(result.csvText);
      setUnidades(result.rows);
      setSelectedId(firstCommercialUnit.id);
      setStatus("done");
    } catch (e) {
      setErro(e.message || "Falha ao processar a tabela.");
      setStatus("error");
    }
  }

  async function carregarEspelho() {
    if (!mirrorFile) return;
    setMirrorErro("");
    try {
      const raw = mirrorFile.name.toLowerCase().endsWith(".pdf") ? (await extractPdfText(mirrorFile)).text : await mirrorFile.text();
      const input = mirrorFile.name.toLowerCase().endsWith(".json") ? JSON.parse(raw) : raw;
      const parsed = parsePortalVWebMirror(input, { empreendimento, source: mirrorFile.name, generated_at: new Date().toISOString() });
      if (!parsed.units.length) throw new Error("Nenhuma unidade foi identificada no espelho enviado.");
      setMirror(parsed);
    } catch (e) {
      setMirrorErro(e.message || "Falha ao processar espelho de vendas.");
    }
  }

  function abrirWhatsApp() {
    if (!podeSimular) return;
    const label = selected.mirror?.available_units?.map((u) => u.codigo_unidade).join(", ") || selected.unidade;
    const msg = [
      `Mesa do Cliente — ${empreendimento || selected.empreendimento || "Empreendimento"}`,
      `Unidade: ${label}`,
      `Área: ${num(selected.area_m2)} m²`,
      `Preço total: ${brl(r.total)}`,
      `Entrada/Sinal: ${brl(r.entrada)}`,
      `Curto prazo: ${curtoQtd}x de ${brl(selected.a4_each)}`,
      `Mensais: ${selected.mensal_qtd}x de ${brl(selected.mensal_each)}`,
      `Intermediárias: ${selected.inter_qtd}x de ${brl(selected.inter_each)}`,
      `Financiamento: ${brl(r.financiamento)}`,
    ].join("\n");
    window.open(`https://wa.me/?text=${encodeURIComponent(msg)}`, "_blank", "noopener,noreferrer");
  }

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900">
      <div className="sticky top-0 z-20 border-b bg-white px-5 py-4">
        <div className="mx-auto flex max-w-7xl items-center justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-wide text-gray-400">FECH.AI / Mesa Cliente</p>
            <h1 className="text-xl font-black">Mesa do Cliente</h1>
            <p className="text-sm text-gray-500">Parser nativo primeiro. Worker/Make apenas como fallback.</p>
          </div>
          <button onClick={onVoltar} className="rounded-xl bg-gray-900 px-4 py-2 text-sm font-bold text-white">Voltar</button>
        </div>
      </div>

      <main className="mx-auto max-w-7xl space-y-5 p-5">
        <section className="rounded-2xl border bg-white p-5 shadow-sm">
          <div className="grid grid-cols-1 gap-3 lg:grid-cols-4">
            <input value={empreendimento} onChange={(e) => setEmpreendimento(e.target.value)} placeholder="Empreendimento" className="rounded-xl border px-4 py-3" />
            <input type="file" accept="application/pdf,.pdf" onChange={(e) => setFile(e.target.files?.[0] || null)} className="rounded-xl border px-4 py-3 lg:col-span-2" />
            <button onClick={carregarTabela} disabled={!file || status === "processing"} className="rounded-xl bg-blue-600 px-4 py-3 font-black text-white disabled:opacity-50">{status === "processing" ? "Processando..." : "Carregar tabela"}</button>
          </div>
          <div className="mt-4 grid grid-cols-1 gap-3 lg:grid-cols-4">
            <input type="file" accept="application/pdf,.pdf,.html,.htm,.txt,.json" onChange={(e) => setMirrorFile(e.target.files?.[0] || null)} className="rounded-xl border px-4 py-3 lg:col-span-3" />
            <button onClick={carregarEspelho} disabled={!mirrorFile} className="rounded-xl bg-slate-900 px-4 py-3 font-black text-white disabled:opacity-50">Carregar espelho</button>
          </div>
          {layout && <div className="mt-4 rounded-xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-800"><b>Layout:</b> {layout.layout}<br /><b>Motor:</b> {layout.source === "parser_nativo" ? "Parser nativo — sem Make/IA" : "Fallback Worker/Make"}<br /><b>Confiança:</b> {(layout.confidence * 100).toFixed(0)}%<br /><b>Motivo:</b> {layout.reason}{invalidas > 0 && <><br /><b>Inconsistências bloqueantes:</b> {invalidas}</>}{nonApartmentCount > 0 && <><br /><b>Itens filtrados:</b> {nonApartmentCount}</>}</div>}
          {erro && <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-bold text-red-700">{erro}</div>}
          {mirrorErro && <div className="mt-4 rounded-xl border border-orange-200 bg-orange-50 p-4 text-sm font-bold text-orange-800">{mirrorErro}</div>}
        </section>

        {unidadesView.length > 0 && <>
          <section className="rounded-2xl border bg-white p-5 shadow-sm">
            <div className="grid grid-cols-1 gap-3 lg:grid-cols-3">
              <select value={selectedId} onChange={(e) => setSelectedId(e.target.value)} className="rounded-xl border px-4 py-3 lg:col-span-2">
                {unidadesView.map((u) => <option key={u.id} value={u.id}>{formatUnitOption(u, hasMirror)}</option>)}
              </select>
              <div className="flex gap-2">
                <button onClick={abrirWhatsApp} disabled={!podeSimular} className="flex-1 rounded-xl bg-emerald-600 px-4 py-3 font-black text-white disabled:opacity-50">WhatsApp</button>
                <button onClick={() => podeSimular && window.print()} disabled={!podeSimular} className="flex-1 rounded-xl bg-gray-900 px-4 py-3 font-black text-white disabled:opacity-50">Imprimir</button>
              </div>
            </div>
            {selected && !validRow(selected) && <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800"><b>Proposta bloqueada:</b> {selected.validation?.issues?.join(", ") || "validação não informada"}</div>}
            {selected && diffStatus?.kind === "rounding" && <div className="mt-4 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800"><b>Arredondamento aceito:</b> diferença de {brl(diffStatus.diff)} dentro da tolerância técnica de {brl(diffStatus.tolerance)}.</div>}
            {selected && diffStatus?.kind === "blocked" && <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800"><b>Diferença financeira acima da tolerância:</b> {brl(diffStatus.diff)}.</div>}
            {selected && hasMirror && !selected.mirror?.can_sell && <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800"><b>Bloqueado pelo espelho:</b> {selected.mirror?.label || "sem correspondência"}</div>}
          </section>

          {podeSimular && <section className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
            <Card label="Preço total" value={brl(r.total)} helper="Valor tabela" />
            <Card label="Financiamento" value={brl(r.financiamento)} helper="Saldo" />
            <Card label="Área" value={`${num(r.area)} m²`} helper={`m²: ${brl(r.m2)}`} />
            <Card label="Entrada" value={brl(r.entrada)} helper="Sinal" />
            <Card label="Curto prazo" value={curtoView.value} helper={curtoView.helper} detail={curtoView.detail} />
            <Card label="Mensais" value={mensaisView.value} helper={mensaisView.helper} detail={mensaisView.detail} />
            <Card label="Intermediárias" value={interView.value} helper={interView.helper} detail={interView.detail} />
            <Card label="Chaves" value={brl(r.chaves)} helper="Parcela única" />
          </section>}

          {pipeline && <details className="rounded-2xl border bg-white p-5"><summary className="cursor-pointer font-bold">Diagnóstico técnico do pipeline</summary><pre className="mt-4 max-h-80 overflow-auto rounded-xl bg-gray-950 p-4 text-xs text-gray-100">{JSON.stringify(pipeline, null, 2)}</pre></details>}
          <details className="rounded-2xl border bg-white p-5"><summary className="cursor-pointer font-bold">CSV canônico completo</summary><pre className="mt-4 max-h-80 overflow-auto rounded-xl bg-gray-950 p-4 text-xs text-gray-100">{csvText}</pre></details>
        </>}
      </main>
    </div>
  );
}
