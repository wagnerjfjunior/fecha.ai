// CriarUsuario.jsx — Gestor cria novos corretores via Edge Function
// A senha NUNCA sai do frontend em plaintext para o banco
// Ela vai direto para o Supabase Auth via Edge Function (HTTPS + service role no servidor)

import { useState } from 'react';

const EDGE_URL = 'https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario';

export default function CriarUsuario({ session, onUsuarioCriado, onCancelar }) {
  const [nome, setNome]         = useState('');
  const [email, setEmail]       = useState('');
  const [senha, setSenha]       = useState('');
  const [confirma, setConfirma] = useState('');
  const [isGestor, setIsGestor] = useState(false);
  const [loading, setLoading]   = useState(false);
  const [erro, setErro]         = useState('');
  const [sucesso, setSucesso]   = useState('');

  async function handleCriar() {
    setErro('');
    setSucesso('');

    if (!nome.trim() || !email.trim() || !senha || !confirma) {
      setErro('Preencha todos os campos.');
      return;
    }
    if (senha.length < 8) {
      setErro('Senha deve ter no mínimo 8 caracteres.');
      return;
    }
    if (senha !== confirma) {
      setErro('As senhas não coincidem.');
      return;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email.trim())) {
      setErro('E-mail inválido.');
      return;
    }

    setLoading(true);
    try {
      // A senha vai criptografada via HTTPS para a Edge Function
      // que usa a service role no servidor para criar o usuário
      const res = await fetch(EDGE_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          // JWT do gestor logado — valida que só gestores podem criar
          'Authorization': `Bearer ${session.access_token}`,
        },
        body: JSON.stringify({
          nome: nome.trim(),
          email: email.trim().toLowerCase(),
          senha,               // trafega apenas via HTTPS, nunca exposto ao banco
          is_gestor: isGestor,
        }),
      });

      const data = await res.json();

      if (!res.ok || data.error) {
        setErro(data.error || 'Erro ao criar usuário.');
        return;
      }

      setSucesso(`Usuário ${data.corretor.nome} criado com sucesso!`);
      setNome(''); setEmail(''); setSenha(''); setConfirma(''); setIsGestor(false);
      onUsuarioCriado?.(data.corretor);

    } catch (e) {
      setErro('Erro de conexão: ' + e.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-lg w-full max-w-md p-6">

        {/* Header */}
        <div className="flex items-center gap-3 mb-6">
          <button
            onClick={onCancelar}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <div>
            <h2 className="text-lg font-bold text-gray-900">Novo usuário</h2>
            <p className="text-xs text-gray-500">Cria login e acesso ao sistema</p>
          </div>
        </div>

        {/* Campos */}
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Nome completo</label>
            <input
              type="text"
              placeholder="Ex: Laura Silva"
              value={nome}
              onChange={e => setNome(e.target.value)}
              className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">E-mail</label>
            <input
              type="email"
              placeholder="corretor@empresa.com.br"
              value={email}
              onChange={e => setEmail(e.target.value)}
              className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Senha</label>
            <input
              type="password"
              placeholder="Mínimo 8 caracteres"
              value={senha}
              onChange={e => setSenha(e.target.value)}
              className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Confirmar senha</label>
            <input
              type="password"
              placeholder="Repita a senha"
              value={confirma}
              onChange={e => setConfirma(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleCriar()}
              className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Toggle gestor */}
          <div
            className="flex items-center justify-between p-4 bg-gray-50 rounded-xl cursor-pointer"
            onClick={() => setIsGestor(!isGestor)}
          >
            <div>
              <p className="text-sm font-medium text-gray-700">Acesso de gestor</p>
              <p className="text-xs text-gray-500">Pode importar listas, distribuir lotes e ver logs</p>
            </div>
            <div className={`w-11 h-6 rounded-full transition-colors ${isGestor ? 'bg-blue-600' : 'bg-gray-300'}`}>
              <div className={`w-5 h-5 bg-white rounded-full shadow mt-0.5 transition-transform ${isGestor ? 'translate-x-5' : 'translate-x-0.5'}`} />
            </div>
          </div>
        </div>

        {/* Feedback */}
        {erro && (
          <div className="mt-4 p-3 bg-red-50 border border-red-100 rounded-xl text-sm text-red-600">
            {erro}
          </div>
        )}
        {sucesso && (
          <div className="mt-4 p-3 bg-green-50 border border-green-100 rounded-xl text-sm text-green-700">
            {sucesso}
          </div>
        )}

        {/* Botão */}
        <button
          onClick={handleCriar}
          disabled={loading}
          className="mt-6 w-full bg-blue-600 text-white font-semibold py-3 rounded-xl hover:bg-blue-700 active:scale-95 transition-all disabled:opacity-50"
        >
          {loading ? 'Criando...' : 'Criar usuário'}
        </button>

        {/* Nota de segurança */}
        <p className="mt-4 text-xs text-center text-gray-400">
          🔒 Senha criptografada via HTTPS — nunca armazenada em texto puro
        </p>
      </div>
    </div>
  );
}
