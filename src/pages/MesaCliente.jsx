import { useMemo, useState } from "react";
import { detectLayout } from "../mesa/layoutDetector";
import { legacyParser } from "../mesa/parsers/legacyParser";
import { parseFlatTable } from "../mesa/parsers/parseFlatTable";
import { parseHierarchical } from "../mesa/parsers/parseHierarchical";
import { parseERPTable } from "../mesa/parsers/parseERPTable";

const WORKER_URL =
  import.meta.env.VITE_MESA_CLIENTE_WORKER_URL ||
  "https://quiet-surf-d4a0.wagnerjfjunior.workers.dev/";

const PDFJS_URL = "https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.min.js";
const PDFJS_WORKER_URL = "https://cdn.jsdelivr.net/npm/pdfjs-dist@3.11.174/build/pdf.worker.min.js";

function fmtBRL(value) {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "BRL",
  }).format(Number(value) || 0);
}

function fmtNum(value) {
  return new Intl.NumberFormat("pt-BR", {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(Number(value) || 0);
}

function loadScriptOnce(src, globalName) {
  return new Promise((resolve, reject) => {
    if (globalName && window[globalName]) {
      resolve(window[globalName]);
      return;
    }

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

  let text = "";
  for (let pageNumber = 1; pageNumber <= pdf.numPages; pageNumber += 1) {
    const page = await pdf.getPage(pageNumber);
    const content = await page.getTextContent();
    text += content.items.map((item) => item.str).join(" ") + "\n";
  }

  return text.trim();
}

async function processarTextoNoWorker({ text, filename, empreendimento }) {
  const response = await fetch(WORKER_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-mesa-version": "fechai-mesa-cliente-v0.1.0",
    },
    body: JSON.stringify({
      mode: "mergeY",
      text,
      filename,
      empreendimento: empreendimento || "",
    }),
  });

  const raw = await response.text();
  let data;

  try {
    data = JSON.parse(raw);
  } catch {
    data = { csv_text: raw };
  }

  if (!response.ok) {
    throw new Error(data?.error || `Worker retornou HTTP ${response.status}`);
  }

  if (!data?.csv_text) {
    throw new Error("Worker não retornou csv_text.");
  }

  return data.csv_text;
}

function parseMesaByLayout(csvText, extractedText) {
  const detection = detectLayout(extractedText);

  switch (detection.layout) {
    case "hierarchical_tegra":
      return {
        rows: parseHierarchical(csvText),
        detection,
      };

    case "singleline_flat":
      return {
        rows: parseFlatTable(csvText),
        detection,
      };

    case "erp_table":
      return {
        rows: parseERPTable(csvText),
        detection,
      };

    default:
      return {
        rows: legacyParser(csvText),
        detection,
      };
  }
}

function buildResumoFinanceiro(unidade) {
  if (!unidade) {
    return {
      total: 0,
      entrada: 0,
      curtoPrazo: 0,
      mensais: 0,
      intermediarias: 0,
      chaves: 0,
      financiamento: 0,
      area: 0,
      valorM2: 0,
    };
  }

  const curtoPrazo = unidade.a4_each * 3;
  const mensais = unidade.mensal_each * unidade.mensal_qtd;
  const intermediarias = unidade.inter_each * unidade.inter_qtd;
  const total = unidade.preco_total;
  const valorM2 = unidade.area_m2 > 0 ? total / unidade.area_m2 : 0;

  return {
    total,
    entrada: unidade.sinal_1,
    curtoPrazo,
    mensais,
    intermediarias,
    chaves: unidade.chaves_each,
    financiamento: unidade.financiamento,
    area: unidade.area_m2,
    valorM2,
  };
}

function StatCard({ label, value, helper, tone = "blue" }) {
  const tones = {
    blue: "border-blue-500 bg-blue-50 text-blue-800",
    emerald: "border-emerald-500 bg-emerald-50 text-emerald-800",
    orange: "border-orange-500 bg-orange-50 text-orange-800",
    purple: "border-purple-500 bg-purple-50 text-purple-800",
    gray: "border-gray-500 bg-gray-50 text-gray-800",
  };

  return (
    <div className={`rounded-2xl border-l-4 p-4 shadow-sm ${tones[tone] || tones.blue}`}>
      <p className="text-xs font-bold uppercase tracking-wide opacity-70">{label}</p>
      <p className="mt-1 text-xl font-black">{value}</p>
      {helper && <p className="mt-1 text-xs opacity-70">{helper}</p>}
    </div>
  );
}

export default function MesaCliente({ corretor, onVoltar }) {
  const [file, setFile] = useState(null);
  const [empreendimento, setEmpreendimento] = useState("");
  const [status, setStatus] = useState("idle");
  const [erro, setErro] = useState("");
  const [csvText, setCsvText] = useState("");
  const [layoutInfo, setLayoutInfo] = useState(null);
  const [unidades, setUnidades] = useState([]);
  const [selectedId, setSelectedId] = useState("");

  const unidadeSelecionada = useMemo(
    () => unidades.find((u) => u.id === selectedId) || null,
    [unidades, selectedId]
  );

  const resumo = useMemo(() => buildResumoFinanceiro(unidadeSelecionada), [unidadeSelecionada]);

  async function carregarTabela() {
    if (!file) return;

    setStatus("processing");
    setErro("");
    setCsvText("");
    setLayoutInfo(null);
    setUnidades([]);
    setSelectedId("");

    try {
      const text = await extractPdfText(file);

      if (!text || text.length < 20) {
        throw new Error("Texto extraído do PDF ficou vazio ou muito curto.");
      }

      const csv = await processarTextoNoWorker({
        text,
        filename: file.name,
        empreendimento,
      });

      const { rows, detection } = parseMesaByLayout(csv, text);

      if (!rows.length) {
        throw new Error("CSV retornou sem unidades válidas.");
      }

      setCsvText(csv);
      setLayoutInfo(detection);
      setUnidades(rows);
      setSelectedId(rows[0].id);
      setStatus("done");
    } catch (error) {
      setErro(error.message || "Falha ao processar a tabela.");
      setStatus("error");
    }
  }

  function montarWhatsApp() {
    if (!unidadeSelecionada) return;

    const msg = [
      `Mesa do Cliente — ${empreendimento || unidadeSelecionada.empreendimento || "Empreendimento"}`,
      `Unidade: ${unidadeSelecionada.unidade}`,
      `Área: ${fmtNum(unidadeSelecionada.area_m2)} m²`,
      `Preço total: ${fmtBRL(resumo.total)}`,
      `Entrada/Sinal: ${fmtBRL(resumo.entrada)}`,
      `Mensais: ${unidadeSelecionada.mensal_qtd}x de ${fmtBRL(unidadeSelecionada.mensal_each)}`,
      `Intermediárias: ${unidadeSelecionada.inter_qtd}x de ${fmtBRL(unidadeSelecionada.inter_each)}`,
      `Financiamento: ${fmtBRL(resumo.financiamento)}`,
    ].join("\n");

    window.open(`https://wa.me/?text=${encodeURIComponent(msg)}`, "_blank", "noopener,noreferrer");
  }

  return (
    <div className="min-h-screen bg-gray-50 text-gray-900">
      <div className="bg-white border-b border-gray-100 px-5 py-4 sticky top-0 z-20">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-3">
          <div>
            <p className="text-xs text-gray-400 font-semibold uppercase tracking-wide">
              FECH.AI / Mesa Cliente
            </p>
            <h1 className="text-xl font-black">Mesa do Cliente</h1>
            <p className="text-sm text-gray-500">
              Upload de tabela PDF, conversão via Worker e leitura inicial das unidades.
            </p>
          </div>

          <button
            onClick={onVoltar}
            className="rounded-xl bg-gray-900 text-white px-4 py-2 text-sm font-bold active:scale-95"
          >
            Voltar
          </button>
        </div>
      </div>

      <main className="max-w-7xl mx-auto p-5 space-y-5">
        <section className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
          <div className="grid grid-cols-1 lg:grid-cols-4 gap-3">
            <div className="lg:col-span-1">
              <label className="block text-xs font-bold text-gray-400 uppercase mb-1">
                Empreendimento
              </label>
              <input
                value={empreendimento}
                onChange={(e) => setEmpreendimento(e.target.value)}
                placeholder="Ex.: Caminhos da Lapa"
                className="w-full rounded-xl border border-gray-200 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="lg:col-span-2">
              <label className="block text-xs font-bold text-gray-400 uppercase mb-1">
                Tabela PDF
              </label>
              <input
                type="file"
                accept="application/pdf,.pdf"
                onChange={(e) => setFile(e.target.files?.[0] || null)}
                className="w-full rounded-xl border border-gray-200 px-4 py-3 bg-white"
              />
            </div>

            <div className="flex items-end">
              <button
                onClick={carregarTabela}
                disabled={!file || status === "processing"}
                className="w-full rounded-xl bg-blue-600 text-white px-4 py-3 font-black disabled:opacity-50 active:scale-95"
              >
                {status === "processing" ? "Processando..." : "Carregar tabela"}
              </button>
            </div>
          </div>

          {layoutInfo && (
            <div className="mt-4 rounded-xl border border-blue-200 bg-blue-50 p-4 text-sm text-blue-800">
              <strong>Layout detectado:</strong> {layoutInfo.layout}
              <br />
              <strong>Confiança:</strong> {(layoutInfo.confidence * 100).toFixed(0)}%
              <br />
              <strong>Motivo:</strong> {layoutInfo.reason}
            </div>
          )}

          {file && (
            <p className="mt-3 text-sm text-gray-500">
              Arquivo selecionado: <span className="font-semibold">{file.name}</span>
            </p>
          )}

          {erro && (
            <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700">
              {erro}
            </div>
          )}
        </section>

        {unidades.length > 0 && (
          <>
            <section className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-3 items-end">
                <div className="lg:col-span-2">
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">
                    Unidade
                  </label>
                  <select
                    value={selectedId}
                    onChange={(e) => setSelectedId(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 px-4 py-3 bg-white outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {unidades.map((u) => (
                      <option key={u.id} value={u.id}>
                        {u.unidade} — {fmtNum(u.area_m2)} m² — {fmtBRL(u.preco_total)}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex gap-2">
                  <button
                    onClick={montarWhatsApp}
                    className="flex-1 rounded-xl bg-emerald-600 text-white px-4 py-3 font-black active:scale-95"
                  >
                    WhatsApp
                  </button>
                  <button
                    onClick={() => window.print()}
                    className="flex-1 rounded-xl bg-gray-900 text-white px-4 py-3 font-black active:scale-95"
                  >
                    Imprimir
                  </button>
                </div>
              </div>
            </section>

            <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
              <StatCard label="Preço total" value={fmtBRL(resumo.total)} helper="Valor tabela" tone="blue" />
              <StatCard label="Financiamento" value={fmtBRL(resumo.financiamento)} helper="Saldo informado/estimado" tone="gray" />
              <StatCard label="Área" value={`${fmtNum(resumo.area)} m²`} helper={`m²: ${fmtBRL(resumo.valorM2)}`} tone="purple" />
              <StatCard label="Entrada / Sinal" value={fmtBRL(resumo.entrada)} helper="Pagamento inicial" tone="emerald" />
            </section>

            <section className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
              <StatCard label="Curto prazo" value={fmtBRL(resumo.curtoPrazo)} helper={`3x de ${fmtBRL(unidadeSelecionada?.a4_each)}`} tone="orange" />
              <StatCard label="Mensais" value={fmtBRL(resumo.mensais)} helper={`${unidadeSelecionada?.mensal_qtd || 0}x de ${fmtBRL(unidadeSelecionada?.mensal_each)}`} tone="blue" />
              <StatCard label="Intermediárias" value={fmtBRL(resumo.intermediarias)} helper={`${unidadeSelecionada?.inter_qtd || 0}x de ${fmtBRL(unidadeSelecionada?.inter_each)}`} tone="purple" />
              <StatCard label="Chaves" value={fmtBRL(resumo.chaves)} helper="Parcela única/chaves" tone="emerald" />
            </section>

            <details className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
              <summary className="cursor-pointer font-bold text-gray-700">
                Diagnóstico técnico do CSV retornado
              </summary>
              <pre className="mt-4 max-h-80 overflow-auto rounded-xl bg-gray-950 p-4 text-xs text-gray-100">
                {csvText}
              </pre>
            </details>
          </>
        )}
      </main>
    </div>
  );
}
