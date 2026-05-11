const DEFAULT_WORKER_URL = "https://quiet-surf-d4a0.wagnerjfjunior.workers.dev/";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST");
    return res.status(405).json({ ok: false, error: "Método não permitido. Use POST." });
  }

  const workerUrl = process.env.MESA_CLIENTE_WORKER_URL || process.env.VITE_MESA_CLIENTE_WORKER_URL || DEFAULT_WORKER_URL;

  try {
    const upstream = await fetch(workerUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-mesa-version": "fechai-mesa-cliente-v0.1.1-proxy",
      },
      body: JSON.stringify(req.body || {}),
    });

    const raw = await upstream.text();
    let payload;

    try {
      payload = JSON.parse(raw);
    } catch {
      payload = { csv_text: raw };
    }

    if (!upstream.ok) {
      return res.status(upstream.status).json({
        ok: false,
        error: payload?.error || `Worker retornou HTTP ${upstream.status}`,
        worker_status: upstream.status,
        worker_url: workerUrl,
      });
    }

    return res.status(200).json(payload);
  } catch (error) {
    return res.status(502).json({
      ok: false,
      error: "Falha ao comunicar com o Worker da Mesa do Cliente.",
      detail: error?.message || String(error),
      worker_url: workerUrl,
    });
  }
}
