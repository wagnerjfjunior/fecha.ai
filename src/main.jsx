import React from 'react'
import ReactDOM from 'react-dom/client'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import App from './App.jsx'
import TenantProvisioningStandalone from './components/TenantProvisioningStandalone.jsx'
import AceleracaoOperacional from './components/AceleracaoOperacional.jsx'
import PowerMessageEngineAdmin from './components/PowerMessageEngineAdmin.jsx'
import './index.css'

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 60_000, refetchOnWindowFocus: false, retry: 1 },
  },
})

if (typeof window !== 'undefined') {
  window.FECHAI_SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL
  window.FECHAI_SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY
}

function appendScript(id, src) {
  if (typeof window === 'undefined') return
  if (document.getElementById(id)) return
  const script = document.createElement('script')
  script.id = id
  script.src = src
  script.defer = true
  document.body.appendChild(script)
}

function loadPmeCallAssistantBeta() {
  appendScript('fechai-pme-call-assistant-beta-loader', '/pme-call-assistant-beta.js')
  appendScript('fechai-pme-corretor-profile-bridge-loader', '/pme-corretor-profile-bridge.js')
  appendScript('fechai-pme-empreendimentos-inline-flow-loader', '/pme-empreendimentos-inline-flow.js')
}

loadPmeCallAssistantBeta()

const RootComponent = window.location.hash === '#tenant-provisioning'
  ? TenantProvisioningStandalone
  : window.location.hash === '#aceleracao-operacional'
    ? AceleracaoOperacional
    : window.location.hash === '#pme-admin'
      ? PowerMessageEngineAdmin
      : App

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <RootComponent />
    </QueryClientProvider>
  </React.StrictMode>,
)
