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

function loadPublicScript(id, src) {
  if (typeof window === 'undefined') return
  if (document.getElementById(id)) return
  const script = document.createElement('script')
  script.id = id
  script.src = src
  script.defer = true
  document.body.appendChild(script)
}

function loadPmeCallAssistantBeta() {
  loadPublicScript('fechai-pme-call-assistant-beta-loader', '/pme-call-assistant-beta.js')
}

function loadPmeEmpreendimentosAddon() {
  loadPublicScript('fechai-pme-empreendimentos-addon-loader', '/pme-empreendimentos-addon.js')
}

loadPmeCallAssistantBeta()
loadPmeEmpreendimentosAddon()

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
