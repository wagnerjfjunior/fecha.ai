const SUPABASE_URL = process.env.SUPABASE_URL || process.env.VITE_SUPABASE_URL;

export default async function handler(req, res) {
  if (req.method === 'OPTIONS') {
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'authorization, content-type');
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Método não permitido.' });
  }

  if (!SUPABASE_URL) {
    return res.status(500).json({ error: 'SUPABASE_URL ausente no ambiente Vercel.' });
  }

  const authorization = req.headers.authorization || '';
  if (!authorization.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token de autenticação obrigatório.' });
  }

  try {
    const upstream = await fetch(`${SUPABASE_URL}/functions/v1/criar-usuario`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: authorization,
      },
      body: JSON.stringify(req.body || {}),
    });

    const text = await upstream.text();
    let payload;
    try {
      payload = text ? JSON.parse(text) : {};
    } catch (_) {
      payload = { raw: text };
    }

    return res.status(upstream.status).json(payload);
  } catch (error) {
    return res.status(502).json({ error: error?.message || 'Erro ao acionar criar-usuario.' });
  }
}
