import { useMemo, useState } from "react";
import { detectLayout } from "../mesa/layoutDetector";
import { parsePortalVWebMirror } from "../mesa/mirror/parsePortalVWebMirror";
import { reconcileUnitsWithMirror } from "../mesa/mirror/reconcileUnitsWithMirror";
import { legacyParser } from "../mesa/parsers/legacyParser";
import { parseFlatTable } from "../mesa/parsers/parseFlatTable";
import { parseHierarchical } from "../mesa/parsers/parseHierarchical";
import { parseERPTable } from "../mesa/parsers/parseERPTable";

const WORKER_URL =
  import.meta.env.VITE_MESA_CLIENTE_WORKER_URL ||
  import.meta.env.VITE_MESA_WORKER_URL ||
  "https://mesacliente.wagnerjfjunior.workers.dev/";

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

async function readMirrorInput(file) {
  if (!file) return "";

  if (file.type.startsWith("image/")) {
    throw new Error(
      "Nesta versão, imagem/JPG do espelho entra como referência visual. Para leitura automática, envie HTML, TXT, JSON ou PDF textual gerado pelo portal."
    );
  }

  if (file.type === "application/pdf" || file.name.toLowerCase().endsWith(".pdf")) {
    return extractPdfText(file);
  }

  return file.text();
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

function isValidMesaRow(unidade) {
  return unidade?.validation?.valid !== false;
}

function hasMirrorLoaded(mirrorParseResult) {
  return Array.isArray(mirrorParseResult?.units) && mirrorParseResult.units.length > 0;
}

function canUseUnit(unidade, mirrorParseResult) {
  if (!isValidMesaRow(unidade)) return false;
  if (!hasMirrorLoaded(mirrorParseResult)) return true;
  return unidade?.mirror?.can_sell === true;
}

function buildResumoFinanceiro(unidade) {
  if (!unidade || !isValidMesaRow(unidade)) {
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
    red: "border-red-500 bg-red-50 text-red-800",
  };

  return (
    <div className={`rounded-2xl border-l-4 p-4 shadow-sm ${tones[tone] || tones.blue}`}>
      <p className="text-xs font-bold uppercase tracking-wide opacity-70">{label}</p>
      <p className="mt-1 text-xl font-black">{value}</p>
      {helper && <p className="mt-1 text-xs opacity-70">{helper}</p>}
    </div>
  );
}

function MirrorBadge({ mirror, mirrorLoaded }) {
  if (!mirrorLoaded) {
    return <span className="rounded-full bg-gray-100 px-2 py-1 text-xs font-bold text-gray-500">sem espelho</span>;
  }

  if (!mirror?.matched) {
    return <span className="rounded-full bg-orange-100 px-2 py-1 text-xs font-bold text-orange-700">sem match</span>;
  }

  if (mirror.sale_state === "available") {
    return <span className="rounded-full bg-emerald-100 px-2 py-1 text-xs font-bold text-emerald-700">disponível</span>;
  }

  if (mirror.sale_state === "partial") {
    return <span className="rounded-full bg-amber-100 px-2 py-1 text-xs font-bold text-amber-700">parcial</span>;
  }

  return <span className="rounded-full bg-red-100 px-2 py-1 text-xs font-bold text-red-700">bloqueada</span>;
}

export default function MesaCliente({ corretor, onVoltar }) {
  const [file, setFile] = useState(null);
  const [mirrorFile, setMirrorFile] = useState(null);
  const [empreendimento, setEmpreendimento] = useState("");
  const [status, setStatus] = useState("idle");
  const [mirrorStatus, setMirrorStatus] = useState("idle");
  const [erro, setErro] = useState("");
  const [mirrorErro, setMirrorErro] = useState("");
  const [csvText, setCsvText] = useState("");
  const [layoutInfo, setLayoutInfo] = useState(null);
  const [unidades, setUnidades] = useState([]);
  const [mirrorParseResult, setMirrorParseResult] = useState(null);
  const [selectedId, setSelectedId] = useState("");

  const mirrorLoaded = hasMirrorLoaded(mirrorParseResult);

  const unidadesComEspelho = useMemo(() => {
    if (!mirrorLoaded) return unidades;
    return reconcileUnitsWithMirror(unidades, mirrorParseResult.units);
  }, [unidades, mirrorLoaded, mirrorParseResult]);

  const unidadeSelecionada = useMemo(
    () => unidadesComEspelho.find((u) => u.id === selectedId) || null,
    [unidadesComEspelho, selectedId]
  );

  const unidadeValida = isValidMesaRow(unidadeSelecionada);
  const propostaLiberada = canUseUnit(unidadeSelecionada, mirrorParseResult);
  const invalidCount = unidadesComEspelho.filter((u) => !isValidMesaRow(u)).length;
  const mirrorBlockedCount = mirrorLoaded
    ? unidadesComEspelho.filter((u) => u.mirror && !u.mirror.can_sell).length
    : 0;
  const mirrorAvailableCount = mirrorLoaded
    ? unidadesComEspelho.filter((u) => u.mirror?.can_sell).length
    : 0;

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

  async function carregarEspelho() {
    if (!mirrorFile) return;

    setMirrorStatus("processing");
    setMirrorErro("");
    setMirrorParseResult(null);

    try {
      const raw = await readMirrorInput(mirrorFile);
      let input = raw;

      if (mirrorFile.name.toLowerCase().endsWith(".json")) {
        input = JSON.parse(raw);
      }

      const result = parsePortalVWebMirror(input, {
        empreendimento,
        source: mirrorFile.name,
        generated_at: new Date().toISOString(),
      });

      if (!result.units.length) {
        throw new Error("Nenhuma unidade foi identificada no espelho enviado.");
      }

      setMirrorParseResult(result);
      setMirrorStatus("done");
    } catch (error) {
      setMirrorErro(error.message || "Falha ao processar espelho de vendas.");
      setMirrorStatus("error");
    }
  }

  function montarWhatsApp() {
    if (!unidadeSelecionada || !propostaLiberada) return;

    const unidadesDisponiveis = unidadeSelecionada.mirror?.available_units?.map((u) => u.codigo_unidade);
    const unidadeLabel = unidadesDisponiveis?.length
      ? unidadesDisponiveis.join(", ")
      : unidadeSelecionada.unidade;

    const msg = [
      `Mesa do Cliente — ${empreendimento || unidadeSelecionada.empreendimento || "Empreendimento"}`,
      `Unidade: ${unidadeLabel}`,
      `Área: ${fmtNum(unidadeSelecionada.area_m2)} m²`,
      `Preço total: ${fmtBRL(resumo.total)}`,
      `Entrada/Sinal: ${fmtBRL(resumo.entrada)}`,
      `Mensais: ${unidadeSelecionada.mensal_qtd}x de ${fmtBRL(unidadeSelecionada.mensal_each)}`,
      `Intermediárias: ${unidadeSelecionada.inter_qtd}x de ${fmtBRL(unidadeSelecionada.inter_each)}`,
      `Financiamento: ${fmtBRL(resumo.financiamento)}`,
      mirrorLoaded ? `Status espelho: ${unidadeSelecionada.mirror?.label || "não informado"}` : "",
    ]
      .filter(Boolean)
      .join("\n");

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
              Tabela oficial + espelho de vendas para simular apenas o que pode ser ofertado.
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
                placeholder="Ex.: Garden Design, Nova Vivere, Elo Duo"
                className="w-full rounded-xl border border-gray-200 px-4 py-3 outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>

            <div className="lg:col-span-2">
              <label className="block text-xs font-bold text-gray-400 uppercase mb-1">
                Tabela oficial PDF
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

          <div className="mt-4 grid grid-cols-1 lg:grid-cols-4 gap-3">
            <div className="lg:col-span-3">
              <label className="block text-xs font-bold text-gray-400 uppercase mb-1">
                Espelho de vendas
              </label>
              <input
                type="file"
                accept="application/pdf,.pdf,.html,.htm,.txt,.json,image/*"
                onChange={(e) => setMirrorFile(e.target.files?.[0] || null)}
                className="w-full rounded-xl border border-gray-200 px-4 py-3 bg-white"
              />
              <p className="mt-1 text-xs text-gray-500">
                Para leitura automática, prefira HTML, TXT, JSON ou PDF textual do portal. JPG ainda fica como referência visual.
              </p>
            </div>

            <div className="flex items-end">
              <button
                onClick={carregarEspelho}
                disabled={!mirrorFile || mirrorStatus === "processing"}
                className="w-full rounded-xl bg-slate-900 text-white px-4 py-3 font-black disabled:opacity-50 active:scale-95"
              >
                {mirrorStatus === "processing" ? "Lendo espelho..." : "Carregar espelho"}
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
              {invalidCount > 0 && (
                <>
                  <br />
                  <strong>Validação financeira:</strong> {invalidCount} linha(s) com inconsistência detectada(s).
                </>
              )}
            </div>
          )}

          {mirrorLoaded && (
            <div className="mt-4 rounded-xl border border-emerald-200 bg-emerald-50 p-4 text-sm text-emerald-800">
              <strong>Espelho carregado:</strong> {mirrorParseResult.total_units} unidade(s) identificada(s).
              <br />
              <strong>Resumo:</strong> {Object.entries(mirrorParseResult.summary || {})
                .map(([key, value]) => `${key}: ${value}`)
                .join(" · ")}
              {unidadesComEspelho.length > 0 && (
                <>
                  <br />
                  <strong>Conciliação:</strong> {mirrorAvailableCount} grupo(s) com disponibilidade e {mirrorBlockedCount} grupo(s) bloqueado(s)/sem match.
                </>
              )}
            </div>
          )}

          {file && (
            <p className="mt-3 text-sm text-gray-500">
              Tabela selecionada: <span className="font-semibold">{file.name}</span>
            </p>
          )}
          {mirrorFile && (
            <p className="mt-1 text-sm text-gray-500">
              Espelho selecionado: <span className="font-semibold">{mirrorFile.name}</span>
            </p>
          )}

          {erro && (
            <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm font-semibold text-red-700">
              {erro}
            </div>
          )}

          {mirrorErro && (
            <div className="mt-4 rounded-xl border border-orange-200 bg-orange-50 p-4 text-sm font-semibold text-orange-800">
              {mirrorErro}
            </div>
          )}
        </section>

        {unidadesComEspelho.length > 0 && (
          <>
            <section className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-3 items-end">
                <div className="lg:col-span-2">
                  <label className="block text-xs font-bold text-gray-400 uppercase mb-1">
                    Unidade / grupo financeiro
                  </label>
                  <select
                    value={selectedId}
                    onChange={(e) => setSelectedId(e.target.value)}
                    className="w-full rounded-xl border border-gray-200 px-4 py-3 bg-white outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    {unidadesComEspelho.map((u) => {
                      const valid = isValidMesaRow(u);
                      const mirrorLabel = mirrorLoaded ? ` — ${u.mirror?.label || "sem espelho"}` : "";
                      return (
                        <option key={u.id} value={u.id}>
                          {valid ? "✅" : "⚠️"} {u.unidade} — {fmtNum(u.area_m2)} m² — {valid ? fmtBRL(u.preco_total) : "inconsistência financeira"}{mirrorLabel}
                        </option>
                      );
                    })}
                  </select>
                </div>

                <div className="flex gap-2">
                  <button
                    onClick={montarWhatsApp}
                    disabled={!propostaLiberada}
                    className="flex-1 rounded-xl bg-emerald-600 text-white px-4 py-3 font-black active:scale-95 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    WhatsApp
                  </button>
                  <button
                    onClick={() => propostaLiberada && window.print()}
                    disabled={!propostaLiberada}
                    className="flex-1 rounded-xl bg-gray-900 text-white px-4 py-3 font-black active:scale-95 disabled:cursor-not-allowed disabled:opacity-50"
                  >
                    Imprimir
                  </button>
                </div>
              </div>

              {unidadeSelecionada && (
                <div className="mt-4 flex flex-wrap items-center gap-2 text-sm text-gray-600">
                  <span className="font-bold text-gray-700">Status operacional:</span>
                  <MirrorBadge mirror={unidadeSelecionada.mirror} mirrorLoaded={mirrorLoaded} />
                  {mirrorLoaded && unidadeSelecionada.mirror?.available_units?.length > 0 && (
                    <span>
                      Disponíveis: {unidadeSelecionada.mirror.available_units.map((u) => u.codigo_unidade).join(", ")}
                    </span>
                  )}
                </div>
              )}

              {!unidadeValida && (
                <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800">
                  <strong>Proposta bloqueada:</strong> esta linha possui inconsistência financeira e não deve ser enviada ao cliente.
                  <br />
                  <strong>Motivos:</strong> {unidadeSelecionada?.validation?.issues?.join(", ") || "validação não informada"}.
                </div>
              )}

              {unidadeValida && mirrorLoaded && !unidadeSelecionada?.mirror?.can_sell && (
                <div className="mt-4 rounded-xl border border-red-200 bg-red-50 p-4 text-sm text-red-800">
                  <strong>Proposta bloqueada pelo espelho:</strong> nenhuma unidade disponível foi encontrada para este grupo/tabela.
                  <br />
                  <strong>Status:</strong> {unidadeSelecionada?.mirror?.label || "sem correspondência"}.
                </div>
              )}

              {unidadeValida && mirrorLoaded && unidadeSelecionada?.mirror?.sale_state === "partial" && (
                <div className="mt-4 rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800">
                  <strong>Atenção:</strong> este grupo financeiro possui unidades disponíveis e indisponíveis. Simule apenas as unidades listadas como disponíveis.
                </div>
              )}
            </section>

            {propostaLiberada && (
              <>
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
              </>
            )}

            <details className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
              <summary className="cursor-pointer font-bold text-gray-700">
                Diagnóstico técnico do CSV retornado
              </summary>
              <pre className="mt-4 max-h-80 overflow-auto rounded-xl bg-gray-950 p-4 text-xs text-gray-100">
                {csvText}
              </pre>
            </details>

            {mirrorLoaded && (
              <details className="bg-white rounded-2xl border border-gray-100 shadow-sm p-5">
                <summary className="cursor-pointer font-bold text-gray-700">
                  Diagnóstico técnico do espelho
                </summary>
                <pre className="mt-4 max-h-80 overflow-auto rounded-xl bg-gray-950 p-4 text-xs text-gray-100">
                  {JSON.stringify(mirrorParseResult, null, 2)}
                </pre>
              </details>
            )}
          </>
        )}
      </main>
    </div>
  );
}
