# FECH.AI — Instruções de integração das mudanças

## O que foi feito no Supabase (já aplicado, não precisa fazer nada)

1. **Edge Function `criar-usuario`** — ativa em:
   `https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario`
   - Recebe: `{ nome, email, senha, is_gestor }`
   - Valida que o chamador é gestor via JWT
   - Cria o usuário no Supabase Auth com service role (senha NUNCA vai ao banco)
   - Insere na tabela `corretores` linkado ao auth.users
   - Faz rollback do auth user se o insert falhar
   - Registra no log

2. **Correção do log duplicado** — `importar_leads_batch` agora aceita `p_sessao_id`
   - Passe um UUID fixo por importação (não por batch)
   - O log faz UPSERT acumulando os totais de todos os batches
   - 1 entrada de log por importação, independente de quantos batches

3. **RLS corrigida** — INSERT em `corretores` agora requer is_gestor()

---

## O que você precisa adicionar ao repositório

### 1. Copiar os dois componentes novos

```
src/
  components/
    CriarUsuario.jsx    ← arquivo gerado
    HomeActions.jsx     ← arquivo gerado
```

### 2. Mudanças no App.jsx

#### A. Importar os novos componentes no topo
```jsx
import CriarUsuario from './components/CriarUsuario';
import HomeActions from './components/HomeActions';
```

#### B. Adicionar estado de tela no componente principal
```jsx
// Adicione ao useState existente do componente raiz
const [tela, setTela] = useState('home'); // 'home' | 'oferta' | 'gestor' | 'criar-usuario'
```

#### C. Substituir o render pós-login pela HomeActions

Onde hoje você renderiza direto o dashboard ou fila de leads após o login,
substitua por:

```jsx
// Logo após validar que o usuário está logado:
if (tela === 'home') {
  return (
    <HomeActions
      nome={nomeCorretor}       // variável que já tem o nome
      isGestor={isGestor}       // variável que já existe no app
      onOfertaAtiva={() => setTela('oferta')}
      onPainelGestor={() => setTela('gestor')}
    />
  );
}

if (tela === 'criar-usuario') {
  return (
    <CriarUsuario
      session={session}         // objeto session do Supabase Auth
      onUsuarioCriado={(c) => {
        // opcional: atualizar lista de corretores
        setTela('gestor');
      }}
      onCancelar={() => setTela('gestor')}
    />
  );
}

// tela === 'oferta' → seu componente atual de leads
// tela === 'gestor' → seu dashboard atual de gestor
```

#### D. No painel gestor, adicionar botão "Novo usuário"
Onde você lista corretores ou no menu do gestor, adicione:

```jsx
<button
  onClick={() => setTela('criar-usuario')}
  className="bg-blue-600 text-white px-4 py-2 rounded-xl text-sm font-medium"
>
  + Novo usuário
</button>
```

#### E. Corrigir o log duplicado na importação

Localize onde `importar_leads_batch` é chamado (provavelmente dentro de um loop de batches).
Antes do loop, gere um UUID de sessão único:

```jsx
import { v4 as uuidv4 } from 'uuid'; // já deve ter no projeto

// Antes do loop de batches:
const sessaoId = uuidv4();

// Dentro do loop, passe o sessaoId:
await supabase.rpc('importar_leads_batch', {
  p_lista_id: listaId,
  p_leads: JSON.stringify(batch),  // ou como já está
  p_sessao_id: sessaoId,           // ADICIONE ESTE PARÂMETRO
});
```

---

## Resumo do que cada mudança resolve

| Mudança | Problema resolvido |
|---|---|
| Edge Function `criar-usuario` | Gestor cria usuários sem ir ao Supabase |
| Edge Function usa service role | Senha nunca fica exposta no frontend |
| `p_sessao_id` na importação | 14 logs → 1 log por importação |
| RLS corretores INSERT | Evita insert direto sem passar pela Edge Function |
| `HomeActions` | Tela inicial com Oferta Ativa + Mesa do Cliente |
| `CriarUsuario` | Formulário de criação de usuário para gestores |

---

## URL da Edge Function para testar

```bash
curl -X POST https://uobxxgzshrmbtjfdolxd.supabase.co/functions/v1/criar-usuario \
  -H "Authorization: Bearer SEU_JWT_AQUI" \
  -H "Content-Type: application/json" \
  -d '{"nome":"Novo Corretor","email":"novo@empresa.com","senha":"senha123","is_gestor":false}'
```
