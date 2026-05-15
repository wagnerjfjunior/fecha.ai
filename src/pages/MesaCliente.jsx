import MesaClienteApp from '../components/MesaCliente';

function isGestorLike(corretor) {
  const role = String(corretor?.role || corretor?.perfil || corretor?.tipo_usuario || '').trim().toLowerCase();

  return Boolean(
    corretor?.is_gestor === true ||
    corretor?.is_admin_local === true ||
    corretor?.is_root === true ||
    ['gestor', 'admin', 'admin_local', 'admin_global', 'root', 'root_admin', 'super_admin'].includes(role)
  );
}

export default function MesaClientePage({ sb, token, corretor, onVoltar }) {
  if (!sb || typeof sb.rpc !== 'function' || !token) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-lg p-6 text-center max-w-sm">
          <div className="text-4xl mb-3">🔒</div>
          <p className="text-gray-800 font-semibold text-base">Sessão não encontrada</p>
          <p className="text-gray-500 text-sm mt-2">
            Entre novamente no FECH.AI para abrir a Mesa Cliente.
          </p>
          <button className="mt-4 text-blue-600 text-sm" onClick={onVoltar}>
            Voltar
          </button>
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
