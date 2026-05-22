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

function loadPmeScript(id, src, defer = true) {
  if (typeof window === 'undefined') return null
  if (document.getElementById(id)) return document.getElementById(id)
  const script = document.createElement('script')
  script.id = id
  script.src = src
  script.defer = defer
  document.body.appendChild(script)
  return script
}

function loadPmeCallAssistantBeta() {
  const assistant = loadPmeScript('fechai-pme-call-assistant-beta-loader', '/pme-call-assistant-beta.js')
  const loadPatch = () => loadPmeScript('fechai-pme-call-assistant-ai-context-patch-loader', '/pme-call-assistant-ai-context-patch.js')
  if (assistant) assistant.addEventListener('load', loadPatch, { once: true })
  else loadPatch()
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
