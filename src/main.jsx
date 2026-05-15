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

function loadPmeCallAssistantBeta() {
  if (typeof window === 'undefined') return
  if (document.getElementById('fechai-pme-call-assistant-beta-loader')) return
  const script = document.createElement('script')
  script.id = 'fechai-pme-call-assistant-beta-loader'
  script.src = '/pme-call-assistant-beta.js'
  script.defer = true
  document.body.appendChild(script)
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
