import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'
import TenantProvisioningStandalone from './components/TenantProvisioningStandalone.jsx'
import AceleracaoOperacional from './components/AceleracaoOperacional.jsx'
import PowerMessageEngineAdmin from './components/PowerMessageEngineAdmin.jsx'
import './index.css'

const RootComponent = window.location.hash === '#tenant-provisioning'
  ? TenantProvisioningStandalone
  : window.location.hash === '#aceleracao-operacional'
    ? AceleracaoOperacional
    : window.location.hash === '#pme-admin'
      ? PowerMessageEngineAdmin
      : App

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <RootComponent />
  </React.StrictMode>,
)
