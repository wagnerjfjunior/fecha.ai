/**
 * MesaCliente.jsx
 * Wrapper de rota para a nova Mesa Cliente SaaS.
 *
 * Antes esta rota exportava diretamente `MesaClienteNativeFirst`, por isso o botão
 * Mesa Cliente abria a tela antiga de "Carregar tabela / Espelho".
 *
 * Nesta preview, a rota passa a abrir `src/components/MesaCliente`, usando a sessão
 * autenticada já salva pelo App principal em `fechai_session`.
 *
 * Rollback imediato:
 *   trocar este arquivo de volta para:
 *   export { default } from "./MesaClienteNativeFirst";
 */

import { useMemo } from 'react';
import MesaClienteApp from '../components/MesaCliente';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

function readSessionToken() {
  try {
    const raw = localStorage.getItem('fechai_session');
    if (!raw) return null;
    const session = JSON.parse(raw);
    return session?.access_token || null;
  } catch (_) {
    return null;
  }
}

function createRpcClient(url, key) {
  const headers = (token) => ({
    apikey: key,
    Authorization: `Bearer ${token || key}`,
    'Content-Type': 'application/json',
  });

  return {
    async rpc(functionName, args = {}, token) {
      const response = await fetch(`${url}/rest/v1/rpc/${functionName}`, {
        method: 'POST',
        headers: headers(token),
        body: JSON.stringify(args || {}),
      });

      if (!response.ok) {
        let message = `Erro ${functionName}`;
        try {
          const err = await response.json();
          message = err.message || err.details || err.hint || message;
        } catch (_) {}
        throw new Error(message);
      }

      return response.json();
    },
  };
}

function isGestorLike(corretor) {
  const role = String(corretor?.role || corretor?.perfil || corretor?.tipo_usuario || '').trim().toLowerCase();
  return Boolean(
    corretor?.is_gestor === true ||
    corretor?.is_admin_local === true ||
    corretor?.is_root === true ||
    ['gestor', 'admin', 'admin_local', 'admin_global', 'root', 'root_admin', 'super_admin'].includes(role)
  );
}

export default function MesaClientePage({ corretor, onVoltar }) {
  const token = readSessionToken();
  const sb = useMemo(() => {
    if (!SUPABASE_URL || !SUPABASE_KEY) return null;
    return createRpcClient(SUPABASE_URL, SUPABASE_KEY);
  }, []);

  if (!SUPABASE_URL || !SUPABASE_KEY) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-lg p-6 text-center max-w-sm">
          <div className="text-4xl mb-3">⚙️</div>
          <p className="text-gray-800 font-semibold text-base">Mesa Cliente sem configuração</p>
          <p className="text-gray-500 text-sm mt-2">
            As variáveis VITE_SUPABASE_URL e VITE_SUPABASE_ANON_KEY precisam estar disponíveis no ambiente da preview.
          </p>
          <button className="mt-4 text-blue-600 text-sm" onClick={onVoltar}>Voltar</button>
        </div>
      </div>
    );
  }

  if (!token) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-lg p-6 text-center max-w-sm">
          <div className="text-4xl mb-3">🔒</div>
          <p className="text-gray-800 font-semibold text-base">Sessão não encontrada</p>
          <p className="text-gray-500 text-sm mt-2">
            Entre novamente no FECH.AI para abrir a Mesa Cliente.
          </p>
          <button className="mt-4 text-blue-600 text-sm" onClick={onVoltar}>Voltar</button>
        </div>
      </div>
    );
  }

  return (
    <MesaClienteApp
      sb={sb}
      token={token}
      corretor={corretor}
      empresaId={corretor?.empresa_id}
      corretorId={corretor?.id}
      isGestor={isGestorLike(corretor)}
      onVoltar={onVoltar}
    />
  );
}
