/**
 * FECH.AI — App principal
 * Versão: 2.0.0
 * Data: 2026-04-17
 * Mudanças:
 *   - Funil CRM kanban mobile-first (9 estágios imobiliários)
 *   - FunilTab: colunas por estágio, cards clicáveis, navegação horizontal
 *   - FunilCardModal: mover lead no funil + ligar/WhatsApp/email por estágio
 *   - Template de email automático conforme estágio do funil
 *   - Fix: solicitar_lote corrigido no banco (CTE + FOR UPDATE SKIP LOCKED)
 * Rollback: Vercel Dashboard → Deployments → selecionar build anterior → Redeploy
 */

import { useState, useEffect, useCallback, useRef } from "react";
import {
  Tooltip as RTooltip, ResponsiveContainer,
  AreaChart, Area, XAxis, YAxis, CartesianGrid,
  BarChart, Bar,
} from "recharts";
import Papa from "papaparse";
import CriarUsuario from "./components/CriarUsuario";
import HomeActions from "./components/HomeActions";
import TimesTab from './components/TimesTab'
import CriarUsuarioForm from './components/CriarUsuarioForm'
import MesaCliente from './pages/MesaCliente'


const APP_VERSION = "2.1.0";
const APP_BUILD   = "2026-04-17";

const FECHAI_DASHBOARD_RESPONSIVE_CSS = `
  @media (max-width: 1180px) {
    [style*="grid-template-columns:repeat(6,1fr)"] {
      grid-template-columns: repeat(3, minmax(0, 1fr)) !important;
    }
    [style*="grid-template-columns:1.2fr repeat(3,.8fr)"],
    [style*="grid-template-columns:1.2fr .9fr .9fr .9fr"] {
      grid-template-columns: repeat(2, minmax(0, 1fr)) !important;
    }
  }
  @media (max-width: 760px) {
    body { overflow-x: hidden; }
    [style*="grid-template-columns:repeat(6,1fr)"],
    [style*="grid-template-columns:repeat(4,1fr)"],
    [style*="grid-template-columns:repeat(3,1fr)"],
    [style*="grid-template-columns:1.2fr repeat(3,.8fr)"],
    [style*="grid-template-columns:1.2fr .9fr .9fr .9fr"],
    [style*="grid-template-columns:1.4fr .7fr .7fr .7fr .7fr .7fr"],
    [style*="grid-template-columns:36px 1.4fr .7fr .7fr .7fr .7fr .7fr"],
    [style*="grid-template-columns:1.4fr .65fr .65fr .65fr .65fr .75fr .75fr"] {
      grid-template-columns: 1fr !important;
    }
    [style*="min-width:260px"] { min-width: 0 !important; width: 100% !important; }
    [style*="font-size:28px"]  { font-size: 24px !important; }
    [style*="padding:16px"]    { padding: 13px !important; }
    [style*="gap:16px"]        { gap: 10px !important; }
  }
  @media (max-width: 480px) {
    [style*="grid-template-columns"] { grid-template-columns: 1fr !important; }
    [style*="height:260px"],[style*="height:280px"],[style*="height:300px"] { height: 220px !important; }
    button, a { touch-action: manipulation; }
  }
`;

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL || "https://uobxxgzshrmbtjfdolxd.supabase.co";
const SUPABASE_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY || "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvYnh4Z3pzaHJtYnRqZmRvbHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjcyOTUsImV4cCI6MjA5MTg0MzI5NX0.0RiMkrtJlGbprp8AqVPXC9Y5LxP6QiELfP7NoYEXJ9w";

// Feedbacks: esquerdo = positivos, direito = negativos
const FEEDBACKS_ESQ = [
  { id:"agendado_visita",    label:"Agendou visita",            color:"bg-emerald-600", hex:"#059669", icon:"✓" },
  { id:"enviado_informacoes",label:"Em conversa - info",         color:"bg-blue-600",    hex:"#2563eb", icon:"ℹ" },
  { id:"retornar_depois",    label:"Retornar depois",            color:"bg-amber-500",   hex:"#f59e0b", icon:"🕒" },
  { id:"lead_ja_atendido",   label:"Já comprou / atendido", color:"bg-orange-500",  hex:"#f97316", icon:"⊘" },
  { id:"sem_interesse",      label:"Sem interesse",             color:"bg-orange-500",  hex:"#f97316", icon:"✕" },
];
const FEEDBACKS_DIR = [
  { id:"caixa_postal",      label:"Caixa postal",      color:"bg-red-600",    hex:"#dc2626", icon:"▶" },
  { id:"nao_responde",      label:"Não responde", color:"bg-red-600",    hex:"#dc2626", icon:"📵" },
  { id:"numero_errado",     label:"Número errado",color:"bg-red-600",    hex:"#dc2626", icon:"!" },
  { id:"chamada_caiu",      label:"Chamada caiu",      color:"bg-slate-500",  hex:"#64748b", icon:"📞" },
  { id:"whatsapp_invalido", label:"WhatsApp inválido", color:"bg-slate-500", hex:"#64748b", icon:"💬" },
];
// Feedbacks exclusivos da aba E-mail/WhatsApp (não aparecem no discador)
const FEEDBACKS_EMAIL = [
  { id:"nao_toca",           label:"Respondeu e-mail",   color:"bg-teal-500",    hex:"#14b8a6", icon:"📧" },
  { id:"nao_responde_email", label:"Não responde e-mail",color:"bg-gray-600",    hex:"#4b5563", icon:"✉✗" },
];
const FEEDBACKS = [...FEEDBACKS_ESQ, ...FEEDBACKS_DIR];

const COL_ALIASES = {
  nome:       ["nome","name","cliente","nome_cliente","nome_completo","full_name","razao_social","nome cliente"],
  email:      ["email","e-mail","e_mail","email_address","email_cliente","e_mail_cliente"],
  celular:    ["celular","cel","mobile","whatsapp","whats","cell","tel_celular","tel celular"],
  telefone_1: ["telefone","tel","phone","telefone_1","tel1","fone","fone1","tel_residencial","tel residencial","telefone_residencial","tel.residencial","tel._residencial"],
  telefone_2: ["telefone_2","tel2","telefone 2","tel_outro","tel outro","telefone_outro","tel.outro","tel._outro"],
  fixo:       ["fixo","landline","telefone_fixo","residencial","comercial","tel_fixo"],
  ddd:        ["ddd","cod_area","codigo_area","area_code","ddd1"],
  ddd_cel:    ["ddd_cel","ddd_celular","dddcel","ddd2"],
  ddd_fix:    ["ddd_fix","ddd_fixo","dddfix","ddd_residencial"],
  endereco:   ["endereco","endereço","address","end","logradouro","rua"],
  bairro:     ["bairro","neighborhood","district"],
  cidade:     ["cidade","city","municipio","munic"],
  uf:         ["uf","estado","state","sg_uf"],
  cep:        ["cep","zip","zipcode","postal_code"],
  zona:       ["zona","regiao","região","zone","area_geografica"],
};

function combinarDDD(ddd, numero) {
  if (!ddd || !numero) return numero || "";
  const d = String(ddd).replace(/\D/g,"").slice(-2);
  const n = String(numero).replace(/\D/g,"");
  if (n.length >= 10) return numero; // DDD já embutido, ignora coluna DDD
  if (n.length >= 7) return d + n;
  return numero;
}

function detectColumns(h) {
  const m={};
  const nr=h.map(x=>String(x||"").toLowerCase().trim()
    .normalize("NFD").replace(/[\u0300-\u036f]/g,"")
    .replace(/\s+/g,"_").replace(/\./g,""));
  for (const [f,al] of Object.entries(COL_ALIASES)) {
    const i=nr.findIndex(x=>al.some(a=>x===a.replace(/\s+/g,"_").replace(/\./g,"")||x.includes(a.replace(/\s+/g,"_").replace(/\./g,""))));
    if(i>=0) m[f]=i;
  }
  return m;
}

function csvToLead(row, cm, forn) {
  const g=(f)=>cm[f]!==undefined?String(row[cm[f]]||"").trim():"";
  const dddGeral=g("ddd"), dddCel=g("ddd_cel")||dddGeral, dddFix=g("ddd_fix")||dddGeral;
  const rawCel=combinarDDD(dddCel,g("celular"));
  const rawTel1=combinarDDD(dddFix,g("telefone_1"));
  const rawTel2=combinarDDD(dddFix,g("telefone_2"));
  const rawFixo=combinarDDD(dddFix,g("fixo"));
  const ph=pickBestPhone({celular:rawCel,telefone_1:rawTel1,telefone_2:rawTel2,fixo:rawFixo});
  const endParts=[g("endereco"),g("bairro"),g("cidade"),g("uf")].filter(Boolean);
  return {
    nome:g("nome"),email:g("email"),
    endereco:endParts.join(", "),
    zona:g("zona"),
    telefone_origem_1:rawTel1||rawCel||"",
    telefone_origem_2:rawTel2||rawFixo||"",
    telefone_escolhido:ph.nacional,telefone_e164:ph.e164,
    tipo_telefone:ph.tipo,pais_telefone:ph.pais,
    ligar:ph.ligar,whatsapp:ph.whatsapp,fornecedor:forn,
  };
}

async function lerXlsx(file) {
  return new Promise((resolve,reject)=>{
    const reader=new FileReader();
    reader.onload=(e)=>{
      try {
        const XLSX=window.XLSX;
        if(!XLSX){reject(new Error("Biblioteca Excel não disponível"));return;}
        const wb=XLSX.read(e.target.result,{type:"array",cellText:true,cellNF:false});
        const ws=wb.Sheets[wb.SheetNames[0]];
        const data=XLSX.utils.sheet_to_json(ws,{header:1,defval:"",raw:false});
        resolve(data.filter(r=>r.some(c=>String(c||"").trim()!=="")));
      } catch(err){reject(err);}
    };
    reader.onerror=reject;
    reader.readAsArrayBuffer(file);
  });
}

const FIELD_LABELS={
  nome:"Nome",celular:"Celular",telefone_1:"Tel.1",telefone_2:"Tel.2",
  fixo:"Fixo",ddd:"DDD",ddd_cel:"DDD Cel",ddd_fix:"DDD Fix",
  email:"E-mail",endereco:"Endereço",bairro:"Bairro",
  cidade:"Cidade",uf:"UF",cep:"CEP",zona:"Zona",
};
const FIELD_COLORS={
  nome:"#3b82f6",celular:"#10b981",telefone_1:"#06b6d4",telefone_2:"#0891b2",
  fixo:"#64748b",ddd:"#f59e0b",ddd_cel:"#f59e0b",ddd_fix:"#f59e0b",
  email:"#8b5cf6",endereco:"#ec4899",bairro:"#ec4899",
  cidade:"#ec4899",uf:"#ec4899",cep:"#ec4899",zona:"#f97316",
};
function getPrimeiroNome(n) { return (n||"").split(" ")[0]||""; }

function buildWhatsAppLink(lead) {
  if (!lead.telefone_e164) return null;
  const num = lead.telefone_e164.replace("+","");
  const msg = encodeURIComponent(`${getSaudacao()}, ${getPrimeiroNome(lead.nome)}! Tudo bem?\n\nSou corretor(a) e estou entrando em contato sobre seu interesse em imóveis.\nPosso te ajudar a encontrar a opção ideal?\n\nAguardo seu retorno 🏠`);
  return `https://wa.me/${num}?text=${msg}`;
}

function buildEmailLinkLegacy(lead) {
  if (!lead.email) return null;
  const nome    = getPrimeiroNome(lead.nome);
  const subject = encodeURIComponent(`${getSaudacao()}, ${nome}! Sobre seu interesse em imóveis`);
  const body    = encodeURIComponent(
    `${getSaudacao()}, ${nome}!\n\nSou corretor(a) de imóveis e estou entrando em contato sobre seu interesse em adquirir um imóvel.\n\nTenho algumas opções exclusivas que podem ser do seu perfil e gostaria de apresentá-las.\n\nQuando podemos conversar? Estou à disposição!\n\nAtenciosamente,`
  );
  return `mailto:${lead.email}?subject=${subject}&body=${body}`;
}

// Templates de email por estágio do funil
const FUNIL_EMAIL_TEMPLATES = {
  "Novo contato":      (nome) => ({ subject: `${getSaudacao()}, ${nome}! Sobre seu interesse em imóveis`, body: `${getSaudacao()}, ${nome}!\n\nEntramos em contato pois identificamos seu interesse em adquirir um imóvel.\n\nGostaria de apresentar opções que se encaixam no seu perfil. Podemos conversar?\n\nAtenciosamente,` }),
  "Primeiro contato":  (nome) => ({ subject: `${nome}, tentei seu contato sobre imóveis`, body: `${getSaudacao()}, ${nome}!\n\nTentei entrar em contato por telefone para falar sobre imóveis que podem ser do seu interesse.\n\nQuando podemos conversar? Fico à disposição!\n\nAtenciosamente,` }),
  "Em conversa":       (nome) => ({ subject: `${nome}, seguem as informações que conversamos`, body: `${getSaudacao()}, ${nome}!\n\nConforme nossa conversa, segue em anexo as informações sobre os imóveis que discutimos.\n\nQualquer dúvida, estou à disposição!\n\nAtenciosamente,` }),
  "Visita agendada":   (nome) => ({ subject: `${nome}, confirmação da sua visita`, body: `${getSaudacao()}, ${nome}!\n\nEste é um lembrete da visita que agendamos. Estou ansioso(a) para apresentar o empreendimento pessoalmente.\n\nNos encontramos conforme combinado. Qualquer imprevisto, me avise!\n\nAtenciosamente,` }),
  "Visita realizada":  (nome) => ({ subject: `${nome}, o que achou da visita?`, body: `${getSaudacao()}, ${nome}!\n\nFoi um prazer te receber! Espero que tenha gostado do empreendimento.\n\nGostaria de saber sua impressão e tirar qualquer dúvida que ficou.\n\nPosso preparar uma simulação financeira personalizada para você?\n\nAtenciosamente,` }),
  "Proposta enviada":  (nome) => ({ subject: `${nome}, proposta comercial — imóvel exclusivo`, body: `${getSaudacao()}, ${nome}!\n\nSegue em anexo a proposta comercial com a simulação financeira personalizada que preparei.\n\nEstou à disposição para explicar cada detalhe e ajustar conforme sua necessidade.\n\nAguardo seu retorno!\n\nAtenciosamente,` }),
  "Em negociação":     (nome) => ({ subject: `${nome}, atualização sobre nossa negociação`, body: `${getSaudacao()}, ${nome}!\n\nGostaria de dar continuidade à nossa negociação. Tenho algumas condições especiais que podem facilitar o fechamento.\n\nPodemos conversar esta semana?\n\nAtenciosamente,` }),
  "Fechado":           (nome) => ({ subject: `${nome}, parabéns pelo seu novo imóvel! 🎉`, body: `${getSaudacao()}, ${nome}!\n\nParabéns pela aquisição do seu imóvel! Foi um prazer enorme fazer parte desta conquista.\n\nEstarei sempre à disposição. Qualquer dúvida sobre documentação ou próximos passos, pode me acionar!\n\nGrande abraço,` }),
  "Perdido":           (nome) => ({ subject: `${nome}, fico à disposição quando precisar`, body: `${getSaudacao()}, ${nome}!\n\nEntendo que o momento não era ideal, mas fico à disposição quando você desejar retomar a busca pelo seu imóvel.\n\nManterei você informado(a) sobre novidades!\n\nAtenciosamente,` }),
};

function buildEmailFunilLink(lead, nomeEstagio) {
  if (!lead.email) return null;
  const nome = getPrimeiroNome(lead.nome);
  const tmpl = FUNIL_EMAIL_TEMPLATES[nomeEstagio]?.(nome) || FUNIL_EMAIL_TEMPLATES["Novo contato"](nome);
  return `mailto:${lead.email}?subject=${encodeURIComponent(tmpl.subject)}&body=${encodeURIComponent(tmpl.body)}`;
}

function onlyDigits(s) { return (s||"").replace(/\D/g,""); }
function parsePhone(raw) {
  if (!raw) return {e164:"",nacional:"",tipo:"",pais:"",ligar:"",whatsapp:""};
  const c=String(raw).trim(), d=onlyDigits(c);
  if (!d||d.length<8) return {e164:"",nacional:c,tipo:"desconhecido",pais:"",ligar:"",whatsapp:""};
  if (c.startsWith("+")&&!d.startsWith("55")) return {e164:"+"+d,nacional:c,tipo:"internacional",pais:"outro",ligar:"+"+d,whatsapp:""};
  if (d.startsWith("55")&&d.length>=12) return classifyBR(d.substring(2));
  if (d.length>=8&&d.length<=11) return classifyBR(d);
  return {e164:"",nacional:d,tipo:"desconhecido",pais:"",ligar:"",whatsapp:""};
}
function classifyBR(d) {
  if (d.length===8) return {e164:"+5511"+d,nacional:"(11) "+d.slice(0,4)+"-"+d.slice(4),tipo:"br_fixo",pais:"BR",ligar:"011"+d,whatsapp:""};
  if (d.length===9&&d[0]==="9") return {e164:"+5511"+d,nacional:"(11) "+d.slice(0,5)+"-"+d.slice(5),tipo:"br_celular",pais:"BR",ligar:"011"+d,whatsapp:"https://wa.me/5511"+d};
  if (d.length===10) { const dd=d.slice(0,2),n=d.slice(2); return {e164:"+55"+d,nacional:`(${dd}) ${n.slice(0,4)}-${n.slice(4)}`,tipo:"br_fixo",pais:"BR",ligar:"0"+d,whatsapp:""}; }
  if (d.length===11) { const dd=d.slice(0,2),n=d.slice(2),cel=n[0]==="9"; return {e164:"+55"+d,nacional:`(${dd}) ${cel?n.slice(0,5)+"-"+n.slice(5):n.slice(0,4)+"-"+n.slice(4)}`,tipo:cel?"br_celular":"br_fixo",pais:"BR",ligar:"0"+d,whatsapp:cel?"https://wa.me/55"+d:""}; }
  return {e164:"",nacional:d,tipo:"desconhecido",pais:"",ligar:"",whatsapp:""};
}
function pickBestPhone(r) {
  let best=null;
  for (const raw of [r.celular,r.telefone_1,r.telefone_2,r.fixo].filter(Boolean)) {
    const p=parsePhone(raw); if (!p.e164) continue;
    if (!best||(p.tipo==="br_celular"&&best.tipo!=="br_celular")) best=p;
  }
  return best||{e164:"",nacional:"",tipo:"",pais:"",ligar:"",whatsapp:""};
}

// ─── Cliente Supabase ─────────────────────────────────────────────────────────
function createSB(url, key) {
  const hd=(t)=>({apikey:key,Authorization:"Bearer "+(t||key),"Content-Type":"application/json"});
  return {
    async signIn(e,p)        { const r=await fetch(url+"/auth/v1/token?grant_type=password",{method:"POST",headers:{apikey:key,"Content-Type":"application/json"},body:JSON.stringify({email:e,password:p})}); if(!r.ok){const x=await r.json();throw new Error(x.error_description||x.msg||"Erro login");} return r.json(); },
    async refreshToken(rt)   { const r=await fetch(url+"/auth/v1/token?grant_type=refresh_token",{method:"POST",headers:{apikey:key,"Content-Type":"application/json"},body:JSON.stringify({refresh_token:rt})}); if(!r.ok) throw new Error("Sessão expirada"); return r.json(); },
    async changePassword(tk,nova) { const r=await fetch(url+"/auth/v1/user",{method:"PUT",headers:hd(tk),body:JSON.stringify({password:nova})}); if(!r.ok){const x=await r.json();throw new Error(x.message||"Erro ao trocar senha");} return r.json(); },
    async query(t,p,tk)      { const r=await fetch(url+"/rest/v1/"+t+"?"+(p||""),{headers:hd(tk)}); if(!r.ok) throw new Error("Erro "+t); return r.json(); },
    async patch(t,q,d,tk)    { const r=await fetch(url+"/rest/v1/"+t+"?"+q,{method:"PATCH",headers:{...hd(tk),Prefer:"return=representation"},body:JSON.stringify(d)}); if(!r.ok){const x=await r.json();throw new Error(x.message||"Erro patch");} return r.json(); },
    async insert(t,d,tk)     { const r=await fetch(url+"/rest/v1/"+t,{method:"POST",headers:{...hd(tk),Prefer:"return=representation"},body:JSON.stringify(d)}); if(!r.ok){const x=await r.json();throw new Error(x.message||"Erro insert");} return r.json(); },
    async rpc(f,a,tk)        { const r=await fetch(url+"/rest/v1/rpc/"+f,{method:"POST",headers:hd(tk),body:JSON.stringify(a||{})}); if(!r.ok){const x=await r.json();throw new Error(x.message||"Erro "+f);} return r.json(); },
  };
}

// ─── CSV helpers ──────────────────────────────────────────────────────────────
// ─── Componentes base ─────────────────────────────────────────────────────────
function Stars({ value, onChange }) {
  return (<div className="flex gap-1 justify-center">{[1,2,3,4,5].map(n=>(<button key={n} className={`text-3xl ${n<=value?"text-amber-400":"text-gray-300"}`} onClick={()=>onChange?.(n)}>{n<=value?"★":"☆"}</button>))}</div>);
}

// Dark mode hook — persiste em localStorage
function useDarkMode() {
  const [dark, setDark] = useState(() => {
    try { return localStorage.getItem("fechaai_dark") === "1"; } catch { return false; }
  });
  const toggle = () => setDark(d => {
    const next = !d;
    try { localStorage.setItem("fechaai_dark", next?"1":"0"); } catch {}
    return next;
  });
  return [dark, toggle];
}

function FechAIResponsiveStyle() {
  useEffect(() => {
    if (document.getElementById("fechai-dashboard-responsive-css")) return;
    const style = document.createElement("style");
    style.id = "fechai-dashboard-responsive-css";
    style.innerHTML = FECHAI_DASHBOARD_RESPONSIVE_CSS;
    document.head.appendChild(style);
    // Carregar SheetJS para suporte a .xlsx
    if (!window.XLSX && !document.getElementById("fechai-xlsx-script")) {
      const s = document.createElement("script");
      s.id  = "fechai-xlsx-script";
      s.src = "https://cdnjs.cloudflare.com/ajax/libs/xlsx/0.18.5/xlsx.full.min.js";
      document.head.appendChild(s);
    }
  }, []);
  return null;
}

function Header({ nome, isGestor, onLogout, onHome, showVersion, dark, onToggleDark }) {
  const bg  = dark ? "#0f172a" : "#ffffff";
  const txt = dark ? "#f1f5f9" : "#111827";
  const sub = dark ? "#94a3b8" : "#6b7280";
  const bdr = dark ? "#1e293b" : "#e5e7eb";
  return (
    <div style={{background:bg,borderBottom:`1px solid ${bdr}`,color:txt,position:"sticky",top:0,zIndex:10}}
      className="px-4 py-3 flex items-center justify-between">
      <div>
        <span className="font-bold" style={{color:txt}}>{nome}</span>
        <span className="ml-2 text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full">{isGestor?"Gestor":"Corretor"}</span>
        {showVersion && <span className="ml-2 text-xs" style={{color:sub}}>v{APP_VERSION}</span>}
      </div>
      <div className="flex items-center gap-3">
        {onHome && (
          <button
            onClick={onHome}
            style={{
              background:"#2563eb",color:"#fff",
              border:"none",borderRadius:8,
              padding:"5px 12px",fontSize:13,fontWeight:600,
              cursor:"pointer",display:"flex",alignItems:"center",gap:4,
            }}>
            ⌂ Início
          </button>
        )}
        {onToggleDark !== undefined && (
          <button onClick={onToggleDark} className="text-lg leading-none" title={dark?"Modo claro":"Modo escuro"}>
            {dark ? "☀️" : "🌙"}
          </button>
        )}
        {/* Sair só aparece se não há onHome — na home o usuário usa onVoltar do App raiz */}
        {!onHome && <button style={{color:sub}} className="text-sm" onClick={onLogout}>Sair</button>}
      </div>
    </div>
  );
}

function TabBar({ tabs, active, onChange }) {
  return (<div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 flex z-20">{tabs.map(t=>(<button key={t.id} className={`flex-1 py-3 text-center ${active===t.id?"text-blue-600 font-medium":"text-gray-400"}`} onClick={()=>onChange(t.id)}><div className="text-xl">{t.icon}</div><div className="text-xs mt-0.5">{t.label}</div></button>))}</div>);
}

// ─── Troca de senha obrigatória ───────────────────────────────────────────────
function TrocarSenhaObrigatoria({ sb, token, corretorId, onConcluido }) {
  const [nova,setNova]=useState(""); const [conf,setConf]=useState("");
  const [ld,setLd]=useState(false); const [erro,setErro]=useState("");
  const salvar = async () => {
    setErro("");
    if (nova.length<8) { setErro("Mínimo 8 caracteres."); return; }
    if (nova!==conf)   { setErro("Senhas não coincidem."); return; }
    setLd(true);
    try {
      await sb.changePassword(token, nova);
      await sb.patch("corretores","id=eq."+corretorId,{must_change_password:false},token);
      onConcluido();
    } catch(e) { setErro(e.message); }
    setLd(false);
  };
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-lg p-6 w-full max-w-sm">
        <div className="text-center mb-6">
          <div className="w-14 h-14 bg-amber-100 rounded-2xl flex items-center justify-center mx-auto mb-3"><span className="text-3xl">🔑</span></div>
          <h2 className="text-xl font-bold text-gray-900">Crie sua senha</h2>
          <p className="text-base text-gray-500 mt-1">Defina uma senha pessoal antes de continuar.</p>
        </div>
        {erro && <div className="bg-red-50 text-red-700 rounded-xl p-3 mb-4 text-base">{erro}</div>}
        <input type="password" placeholder="Nova senha (mín. 8 caracteres)" value={nova} onChange={e=>setNova(e.target.value)} className="w-full border border-gray-300 rounded-xl px-4 py-3 mb-3 text-base focus:outline-none focus:ring-2 focus:ring-blue-500"/>
        <input type="password" placeholder="Confirmar senha" value={conf} onChange={e=>setConf(e.target.value)} onKeyDown={e=>e.key==="Enter"&&salvar()} className="w-full border border-gray-300 rounded-xl px-4 py-3 mb-5 text-base focus:outline-none focus:ring-2 focus:ring-blue-500"/>
        <button onClick={salvar} disabled={ld||!nova||!conf} className="w-full bg-blue-600 text-white rounded-xl py-3 text-base font-semibold disabled:opacity-50">{ld?"Salvando...":"Definir senha e entrar"}</button>
      </div>
    </div>
  );
}

...SNIP