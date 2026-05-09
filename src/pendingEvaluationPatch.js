// FECH.AI — UI_PATCH_LAURA_V1
// Patch isolado para tratar pendência operacional de avaliação de lote.
// Motivo: App.jsx está monolítico; este arquivo evita mexer no motor principal agora.
// Fluxo tratado:
// solicitar_lote() -> LOTE_ANTERIOR_SEM_AVALIACAO -> listar_lotes_pendentes_avaliacao() -> avaliar_lote() -> solicitar_lote(p_lista_id) novamente.

(function initPendingEvaluationPatch() {
  if (typeof window === "undefined") return;
  if (window.__FECHAI_PENDING_EVAL_PATCH_INSTALLED__) return;
  window.__FECHAI_PENDING_EVAL_PATCH_INSTALLED__ = true;

  const originalFetch = window.fetch.bind(window);
  let modalOpen = false;

  function isSolicitarLoteRequest(input) {
    const url = typeof input === "string" ? input : input?.url || "";
    return url.includes("/rest/v1/rpc/solicitar_lote");
  }

  function getUrl(input) {
    return typeof input === "string" ? input : input?.url || "";
  }

  function cloneHeaders(input, init) {
    const headers = new Headers();

    try {
      if (input && typeof input !== "string" && input.headers) {
        new Headers(input.headers).forEach((value, key) => headers.set(key, value));
      }
    } catch (_) {}

    try {
      if (init?.headers) {
        new Headers(init.headers).forEach((value, key) => headers.set(key, value));
      }
    } catch (_) {}

    if (!headers.has("Content-Type")) headers.set("Content-Type", "application/json");
    return headers;
  }

  function safeJsonParse(value) {
    try {
      if (!value) return {};
      if (typeof value === "string") return JSON.parse(value);
      return {};
    } catch (_) {
      return {};
    }
  }

  function rpcUrlFromSolicitar(url, rpcName) {
    return url.replace(/\/rest\/v1\/rpc\/solicitar_lote(?:\?.*)?$/, `/rest/v1/rpc/${rpcName}`);
  }

  function removeModal() {
    const existing = document.getElementById("fechai-pending-evaluation-modal");
    if (existing) existing.remove();
    modalOpen = false;
  }

  function formatDate(value) {
    if (!value) return "—";
    try {
      return new Date(value).toLocaleString("pt-BR", {
        day: "2-digit",
        month: "2-digit",
        year: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
    } catch (_) {
      return String(value);
    }
  }

  function createStyles() {
    if (document.getElementById("fechai-pending-evaluation-style")) return;
    const style = document.createElement("style");
    style.id = "fechai-pending-evaluation-style";
    style.textContent = `
      #fechai-pending-evaluation-modal {
        position: fixed;
        inset: 0;
        z-index: 999999;
        background: rgba(15, 23, 42, 0.58);
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 18px;
        font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      }
      .fechai-pending-card {
        width: min(520px, 100%);
        background: #fff;
        color: #0f172a;
        border-radius: 18px;
        box-shadow: 0 24px 80px rgba(15, 23, 42, .35);
        overflow: hidden;
      }
      .fechai-pending-header {
        padding: 20px 22px 14px;
        border-bottom: 1px solid #e5e7eb;
      }
      .fechai-pending-kicker {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        font-size: 12px;
        font-weight: 800;
        color: #92400e;
        background: #fffbeb;
        border: 1px solid #fde68a;
        border-radius: 999px;
        padding: 5px 10px;
        margin-bottom: 10px;
      }
      .fechai-pending-title {
        font-size: 20px;
        line-height: 1.2;
        font-weight: 850;
        margin: 0 0 6px;
      }
      .fechai-pending-subtitle {
        font-size: 14px;
        color: #64748b;
        line-height: 1.45;
        margin: 0;
      }
      .fechai-pending-body { padding: 18px 22px 22px; }
      .fechai-pending-info {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 10px;
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        border-radius: 14px;
        padding: 12px;
        margin-bottom: 16px;
      }
      .fechai-pending-info div { font-size: 13px; color: #475569; }
      .fechai-pending-info strong { display:block; color:#0f172a; font-size: 14px; margin-top: 2px; }
      .fechai-stars { display:flex; gap:6px; justify-content:center; margin: 8px 0 14px; }
      .fechai-star {
        border: 0;
        background: transparent;
        font-size: 34px;
        line-height: 1;
        cursor: pointer;
        color: #cbd5e1;
        padding: 2px;
      }
      .fechai-star.active { color: #f59e0b; }
      .fechai-pending-textarea {
        width: 100%;
        box-sizing: border-box;
        min-height: 92px;
        border: 1px solid #cbd5e1;
        border-radius: 12px;
        padding: 12px;
        font-size: 14px;
        resize: vertical;
        outline: none;
      }
      .fechai-pending-textarea:focus { border-color:#2563eb; box-shadow: 0 0 0 3px rgba(37,99,235,.12); }
      .fechai-pending-actions {
        display:flex;
        gap:10px;
        margin-top:16px;
      }
      .fechai-btn {
        border:0;
        border-radius:12px;
        padding:12px 14px;
        font-weight:800;
        cursor:pointer;
        font-size:14px;
      }
      .fechai-btn-primary { flex:1; background:#2563eb; color:#fff; }
      .fechai-btn-secondary { background:#f1f5f9; color:#334155; }
      .fechai-btn:disabled { opacity:.55; cursor:not-allowed; }
      .fechai-pending-message { margin-top:12px; font-size:13px; line-height:1.4; color:#334155; }
      .fechai-pending-error { color:#b91c1c; }
      .fechai-pending-success { color:#047857; }
      @media (max-width: 520px) {
        .fechai-pending-info { grid-template-columns: 1fr; }
        .fechai-pending-actions { flex-direction: column; }
      }
    `;
    document.head.appendChild(style);
  }

  async function loadPendingLots(solicitarUrl, headers) {
    const url = rpcUrlFromSolicitar(solicitarUrl, "listar_lotes_pendentes_avaliacao");
    const response = await originalFetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify({}),
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data?.ok === false) {
      throw new Error(data?.error || data?.message || "Não foi possível buscar o lote pendente de avaliação.");
    }
    return Array.isArray(data?.pendentes) ? data.pendentes : [];
  }

  async function avaliarLote(solicitarUrl, headers, loteId, nota, comentario) {
    const url = rpcUrlFromSolicitar(solicitarUrl, "avaliar_lote");
    const response = await originalFetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify({
        p_lote_id: loteId,
        p_nota: nota,
        p_comentario: comentario || null,
      }),
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data?.ok === false) {
      throw new Error(data?.error || data?.message || data?.code || "Não foi possível avaliar o lote.");
    }
    return data;
  }

  async function retrySolicitarLote(input, init, listaId) {
    const originalBody = safeJsonParse(init?.body || (typeof input !== "string" ? input?.body : null));
    const retryPayload = {
      ...originalBody,
      ...(listaId ? { p_lista_id: listaId } : {}),
    };

    const retryInit = {
      ...(init || {}),
      method: init?.method || (typeof input !== "string" ? input?.method : "POST") || "POST",
      headers: cloneHeaders(input, init),
      body: JSON.stringify(retryPayload),
    };
    const url = getUrl(input);
    const response = await originalFetch(url, retryInit);
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data?.ok === false) {
      throw new Error(data?.error || data?.message || data?.code || "Avaliação salva, mas ainda não foi possível solicitar novo lote.");
    }
    return data;
  }

  function renderModal({ lots, solicitarUrl, headers, input, init }) {
    createStyles();
    removeModal();
    modalOpen = true;

    const lot = lots[0] || null;
    const listaIdParaRetry = lot?.lista_id || safeJsonParse(init?.body || (typeof input !== "string" ? input?.body : null))?.p_lista_id || null;
    let nota = 0;

    const root = document.createElement("div");
    root.id = "fechai-pending-evaluation-modal";

    root.innerHTML = `
      <div class="fechai-pending-card" role="dialog" aria-modal="true" aria-label="Avaliação de lote pendente">
        <div class="fechai-pending-header">
          <div class="fechai-pending-kicker">⚠ Pendência operacional</div>
          <h2 class="fechai-pending-title">Avalie o lote anterior para continuar</h2>
          <p class="fechai-pending-subtitle">
            Para liberar um novo lote, precisamos registrar sua percepção sobre a amostra trabalhada. Isso alimenta a qualidade da lista e evita trabalho no escuro.
          </p>
        </div>
        <div class="fechai-pending-body">
          ${lot ? `
            <div class="fechai-pending-info">
              <div>Lista / fornecedor<strong>${lot.nome_fornecedor || "Lista sem nome"}</strong></div>
              <div>Leads trabalhados<strong>${lot.quantidade_feedback ?? 0} de ${lot.quantidade_leads ?? "—"}</strong></div>
              <div>Status<strong>${lot.status_v2 || lot.status || "—"}</strong></div>
              <div>Fechamento<strong>${formatDate(lot.data_fechamento)}</strong></div>
            </div>
          ` : `
            <div class="fechai-pending-info">
              <div>Lote pendente<strong>Não localizado pela RPC</strong></div>
            </div>
          `}

          <div style="font-size:14px;font-weight:800;margin-bottom:4px;text-align:center;">Como você avalia a qualidade deste lote?</div>
          <div class="fechai-stars" data-stars>
            ${[1,2,3,4,5].map(n => `<button type="button" class="fechai-star" data-star="${n}" aria-label="Nota ${n}">★</button>`).join("")}
          </div>
          <textarea class="fechai-pending-textarea" placeholder="Comentário opcional: qualidade dos contatos, números inválidos, interesse percebido, dificuldade de contato..."></textarea>
          <div class="fechai-pending-actions">
            <button type="button" class="fechai-btn fechai-btn-secondary" data-close>Agora não</button>
            <button type="button" class="fechai-btn fechai-btn-primary" data-submit disabled>Avaliar e solicitar novo lote</button>
          </div>
          <div class="fechai-pending-message" data-message></div>
        </div>
      </div>
    `;

    document.body.appendChild(root);

    const message = root.querySelector("[data-message]");
    const submit = root.querySelector("[data-submit]");
    const textarea = root.querySelector("textarea");
    const stars = Array.from(root.querySelectorAll("[data-star]"));

    function setMessage(text, type) {
      message.textContent = text || "";
      message.className = "fechai-pending-message" + (type ? ` fechai-pending-${type}` : "");
    }

    function paintStars() {
      stars.forEach((btn) => {
        const n = Number(btn.getAttribute("data-star"));
        btn.classList.toggle("active", n <= nota);
      });
      submit.disabled = !lot || nota < 1;
    }

    stars.forEach((btn) => {
      btn.addEventListener("click", () => {
        nota = Number(btn.getAttribute("data-star"));
        paintStars();
      });
    });

    root.querySelector("[data-close]").addEventListener("click", removeModal);

    submit.addEventListener("click", async () => {
      if (!lot || nota < 1) return;
      submit.disabled = true;
      setMessage("Registrando avaliação e solicitando novo lote...", "");
      try {
        await avaliarLote(solicitarUrl, headers, lot.lote_id, nota, textarea.value.trim());
        const novoLote = await retrySolicitarLote(input, init, listaIdParaRetry);
        setMessage(`Avaliação salva. Novo lote liberado${novoLote?.leads ? ` com ${novoLote.leads} leads` : ""}. Atualizando a tela...`, "success");
        window.setTimeout(() => window.location.reload(), 900);
      } catch (error) {
        setMessage(error?.message || "Não foi possível concluir a operação.", "error");
        submit.disabled = false;
      }
    });

    paintStars();
  }

  async function openPendingEvaluationFlow(input, init) {
    if (modalOpen) return;
    const solicitarUrl = getUrl(input);
    const headers = cloneHeaders(input, init);
    try {
      const lots = await loadPendingLots(solicitarUrl, headers);
      renderModal({ lots, solicitarUrl, headers, input, init });
    } catch (error) {
      console.warn("[FECH.AI] Falha ao abrir modal de avaliação pendente:", error);
    }
  }

  window.fetch = async function patchedFetch(input, init) {
    const response = await originalFetch(input, init);

    if (!isSolicitarLoteRequest(input)) return response;

    try {
      const data = await response.clone().json();
      if (data?.ok === false && data?.code === "LOTE_ANTERIOR_SEM_AVALIACAO") {
        window.setTimeout(() => openPendingEvaluationFlow(input, init), 0);
      }
    } catch (_) {
      // Não interferir no fluxo original do app.
    }

    return response;
  };
})();
