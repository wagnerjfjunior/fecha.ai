/**
 * FECH.AI — App principal
 * Versão: 1.6.0
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

const APP_VERSION = "1.6.0";
const APP_BUILD   = "2026-04-17";

const SUPABASE_URL = "https://uobxxgzshrmbtjfdolxd.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvYnh4Z3pzaHJtYnRqZmRvbHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjcyOTUsImV4cCI6MjA5MTg0MzI5NX0.0RiMkrtJlGbprp8AqVPXC9Y5LxP6QiELfP7NoYEXJ9w";

const FEEDBACKS = [
  { id:"agendado_visita",    label:"Agendou visita",  color:"bg-emerald-600", hex:"#059669", icon:"✓" },
  { id:"enviado_informacoes",label:"Enviou info",     color:"bg-blue-600",    hex:"#2563eb", icon:"ℹ" },
  { id:"retornar_depois",    label:"Retornar depois", color:"bg-amber-500",   hex:"#f59e0b", icon:"↻" },
  { id:"nao_responde",       label:"Não responde",    color:"bg-gray-500",    hex:"#6b7280", icon:"—" },
  { id:"sem_interesse",      label:"Sem interesse",   color:"bg-purple-600",  hex:"#7c3aed", icon:"✕" },
  { id:"numero_errado",      label:"Número errado",   color:"bg-red-600",     hex:"#dc2626", icon:"!" },
  { id:"caixa_postal",       label:"Caixa postal",    color:"bg-orange-500",  hex:"#f97316", icon:"▶" },
  { id:"nao_toca",           label:"Não toca",        color:"bg-gray-400",    hex:"#9ca3af", icon:"✗" },
  { id:"lead_ja_atendido",   label:"Já atendido",     color:"bg-red-400",     hex:"#f87171", icon:"⊘" },
];

const COL_ALIASES = {
  nome:       ["nome","name","cliente","nome_cliente","nome completo","full_name"],
  email:      ["email","e-mail","e_mail","email_address"],
  celular:    ["celular","cel","mobile","whatsapp","whats","cell"],
  telefone_1: ["telefone","tel","phone","telefone_1","tel1","fone"],
  telefone_2: ["telefone_2","tel2","telefone 2"],
  fixo:       ["fixo","landline","telefone_fixo","residencial","comercial"],
  endereco:   ["endereco","endereço","address","end","logradouro"],
};

// ─── Helpers ──────────────────────────────────────────────────────────────────
function getSaudacao() { const h=new Date().getHours(); return h<12?"Bom dia":h<18?"Boa tarde":"Boa noite"; }
function getPrimeiroNome(n) { return (n||"").split(" ")[0]||""; }

function buildWhatsAppLink(lead) {
  if (!lead.telefone_e164) return null;
  const num = lead.telefone_e164.replace("+","");
  const msg = encodeURIComponent(`${getSaudacao()}, ${getPrimeiroNome(lead.nome)}! Tudo bem?\n\nSou corretor(a) e estou entrando em contato sobre seu interesse em imóveis.\nPosso te ajudar a encontrar a opção ideal?\n\nAguardo seu retorno 🏠`);
  return `https://wa.me/${num}?text=${msg}`;
}

function buildEmailLink(lead) {
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
function detectColumns(h) {
  const m={},nr=h.map(x=>String(x||"").toLowerCase().trim().normalize("NFD").replace(/[\u0300-\u036f]/g,"").replace(/\s+/g,"_"));
  for (const [f,al] of Object.entries(COL_ALIASES)) { const i=nr.findIndex(x=>al.some(a=>x===a||x.includes(a))); if(i>=0) m[f]=i; }
  return m;
}
function csvToLead(row,cm,forn) {
  const g=(f)=>cm[f]!==undefined?String(row[cm[f]]||"").trim():"";
  const ph=pickBestPhone({celular:g("celular"),telefone_1:g("telefone_1"),telefone_2:g("telefone_2"),fixo:g("fixo")});
  return {nome:g("nome"),email:g("email"),endereco:g("endereco"),telefone_origem_1:g("telefone_1")||g("celular")||"",telefone_origem_2:g("telefone_2")||g("fixo")||"",telefone_escolhido:ph.nacional,telefone_e164:ph.e164,tipo_telefone:ph.tipo,pais_telefone:ph.pais,ligar:ph.ligar,whatsapp:ph.whatsapp,fornecedor:forn};
}

// ─── Componentes base ─────────────────────────────────────────────────────────
function Stars({ value, onChange }) {
  return (<div className="flex gap-1 justify-center">{[1,2,3,4,5].map(n=>(<button key={n} className={`text-3xl ${n<=value?"text-amber-400":"text-gray-300"}`} onClick={()=>onChange?.(n)}>{n<=value?"★":"☆"}</button>))}</div>);
}

function Header({ nome, isGestor, onLogout, onHome, showVersion }) {
  return (
    <div className="bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between sticky top-0 z-10">
      <div>
        <span className="font-bold text-gray-900">{nome}</span>
        <span className="ml-2 text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full">{isGestor?"Gestor":"Corretor"}</span>
        {showVersion && <span className="ml-2 text-xs text-gray-300">v{APP_VERSION}</span>}
      </div>
      <div className="flex items-center gap-3">
        {onHome && <button className="text-sm text-gray-400 hover:text-blue-500" onClick={onHome}>⌂ Início</button>}
        <button className="text-sm text-gray-400 hover:text-red-500" onClick={onLogout}>Sair</button>
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

// ─── Modal de edição de lead ──────────────────────────────────────────────────
function LeadModal({ lead, sb, token, onSalvo, onFechar }) {
  const [fb,setFb]          = useState(lead.feedback||"");
  const [obs,setObs]        = useState(lead.observacao||"");
  const [ld,setLd]          = useState(false);
  const [erro,setErro]      = useState("");
  const [aba,setAba]        = useState("feedback"); // 'feedback' | 'funil'
  const [estagios,setEstagios] = useState([]);
  const [estSel,setEstSel]  = useState(lead.estagio_id||"");
  const [obsFunil,setObsFunil] = useState("");
  const [ldFunil,setLdFunil] = useState(false);

  // Carrega estágios quando usuário abre aba funil
  useEffect(() => {
    if (aba !== "funil" || estagios.length > 0) return;
    sb.query("funil_estagios","order=ordem.asc",token)
      .then(r => { setEstagios(r); if (!estSel && r.length > 0) setEstSel(r[0].id); })
      .catch(() => {});
  }, [aba]);

  const salvar = async () => {
    if (!fb) { setErro("Selecione um feedback."); return; }
    setLd(true); setErro("");
    try {
      const r=await sb.rpc("atualizar_feedback",{p_lead_id:lead.id,p_feedback:fb,p_observacao:obs},token);
      if (r.error) throw new Error(r.error);
      onSalvo({...lead,feedback:fb,observacao:obs});
    } catch(e) { setErro(e.message); }
    setLd(false);
  };

  const moverFunil = async () => {
    if (!estSel) return;
    setLdFunil(true); setErro("");
    try {
      const r = await sb.rpc("mover_funil",{p_lead_id:lead.id,p_estagio_id:estSel,p_observacao:obsFunil},token);
      if (r.error) throw new Error(r.error);
      onSalvo({...lead, estagio_id: estSel});
    } catch(e) { setErro(e.message); }
    setLdFunil(false);
  };

  const e164=lead.telefone_e164||"";
  const wppLink=e164?buildWhatsAppLink({...lead,telefone_e164:e164}):null;
  const mailLink=buildEmailLink(lead);
  const estNomeAtual = estagios.find(e=>e.id===estSel)?.nome || "";

  return (
    <div className="fixed inset-0 bg-black/40 z-50 flex items-end" onClick={onFechar}>
      <div className="bg-white rounded-t-2xl w-full max-h-[90vh] overflow-y-auto" onClick={e=>e.stopPropagation()}>
        {/* Handle */}
        <div className="flex justify-center pt-3 pb-1"><div className="w-10 h-1 bg-gray-300 rounded-full"/></div>

        {/* Header */}
        <div className="px-5 pt-2 pb-3 border-b border-gray-100">
          <div className="flex items-start justify-between mb-3">
            <div><h3 className="font-bold text-gray-900 text-xl">{lead.nome||"Sem nome"}</h3>{lead.email&&<p className="text-sm text-gray-500 mt-0.5">{lead.email}</p>}</div>
            <button onClick={onFechar} className="text-gray-400 text-2xl leading-none">✕</button>
          </div>
          <div className="bg-gray-50 rounded-xl p-3">
            <p className="font-mono font-bold text-gray-900 text-lg">{lead.telefone||lead.telefone_escolhido||"—"}</p>
            <div className="flex gap-2 mt-2 flex-wrap">
              {(lead.telefone||lead.ligar)&&<a href={"tel:"+(lead.ligar||lead.telefone)} className="flex-1 bg-blue-600 text-white rounded-xl py-3 text-center text-base font-medium no-underline">📞 Ligar</a>}
              {wppLink&&<a href={wppLink} target="_blank" rel="noopener noreferrer" className="flex-1 bg-emerald-600 text-white rounded-xl py-3 text-center text-base font-medium no-underline">WhatsApp</a>}
              {mailLink&&<a href={mailLink} className="flex-1 bg-indigo-600 text-white rounded-xl py-3 text-center text-base font-medium no-underline">✉</a>}
            </div>
          </div>
        </div>

        {/* Abas */}
        <div className="flex border-b border-gray-100">
          {[["feedback","Feedback"],["funil","▽ Funil CRM"]].map(([id,label])=>(
            <button key={id} onClick={()=>setAba(id)}
              className={`flex-1 py-3 text-base font-medium transition-colors ${aba===id?"text-blue-600 border-b-2 border-blue-600":"text-gray-400"}`}>
              {label}
            </button>
          ))}
        </div>

        <div className="p-5 pb-8">
          {aba==="feedback" && (<>
            <p className="text-sm text-gray-500 uppercase tracking-wide mb-2">Atualizar feedback</p>
            <div className="grid grid-cols-2 gap-2 mb-4">
              {FEEDBACKS.map(f=>(
                <button key={f.id} onClick={()=>setFb(f.id)} className={`rounded-xl py-3 px-3 text-base font-medium text-left transition-all border-2 ${fb===f.id?f.color+" text-white border-transparent":"bg-gray-50 text-gray-700 border-transparent"}`}>
                  <span className="mr-1">{f.icon}</span>{f.label}
                </button>
              ))}
            </div>
            <textarea rows={3} placeholder="Observação..." value={obs} onChange={e=>setObs(e.target.value)} className="w-full border border-gray-300 rounded-xl px-3 py-3 text-base resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 mb-4"/>
            {erro&&<div className="bg-red-50 text-red-700 rounded-xl p-3 mb-3 text-base">{erro}</div>}
            <div className="flex gap-3">
              <button onClick={onFechar} className="flex-1 bg-gray-100 text-gray-700 rounded-xl py-3 text-base font-medium">Cancelar</button>
              <button onClick={salvar} disabled={ld} className="flex-1 bg-blue-600 text-white rounded-xl py-3 text-base font-semibold disabled:opacity-50">{ld?"Salvando...":"Salvar"}</button>
            </div>
          </>)}

          {aba==="funil" && (<>
            <p className="text-sm text-gray-500 uppercase tracking-wide mb-3">Posicionar no funil de vendas</p>
            {estagios.length === 0 && <p className="text-gray-400 text-center py-4">Carregando estágios...</p>}
            <div className="space-y-2 mb-4">
              {estagios.map(e=>(
                <button key={e.id} onClick={()=>setEstSel(e.id)}
                  className={`w-full flex items-center gap-3 rounded-xl px-4 py-3 text-left transition-all border-2 ${estSel===e.id?"border-blue-500 bg-blue-50":"border-transparent bg-gray-50"}`}>
                  <span className="text-xl">{e.icone}</span>
                  <div className="flex-1"><p className="font-medium text-base text-gray-900">{e.nome}</p></div>
                  <div className="w-3 h-3 rounded-full flex-shrink-0" style={{background:e.cor}}/>
                  {estSel===e.id&&<span className="text-blue-500 text-lg">✓</span>}
                </button>
              ))}
            </div>
            {/* Preview email do estágio */}
            {estNomeAtual && lead.email && (
              <a href={buildEmailFunilLink(lead, estNomeAtual)||"#"}
                className="block bg-indigo-50 rounded-xl p-3 mb-4 border border-indigo-100 no-underline">
                <p className="text-xs text-indigo-700 font-medium">✉ Email template para "{estNomeAtual}"</p>
                <p className="text-xs text-indigo-500 mt-0.5">Toque para abrir no seu app de email</p>
              </a>
            )}
            <textarea rows={2} placeholder="Observação sobre este estágio (opcional)..." value={obsFunil} onChange={e=>setObsFunil(e.target.value)} className="w-full border border-gray-300 rounded-xl px-3 py-3 text-base resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 mb-4"/>
            {erro&&<div className="bg-red-50 text-red-700 rounded-xl p-3 mb-3 text-base">{erro}</div>}
            <div className="flex gap-3">
              <button onClick={onFechar} className="flex-1 bg-gray-100 text-gray-700 rounded-xl py-3 text-base font-medium">Cancelar</button>
              <button onClick={moverFunil} disabled={ldFunil||!estSel} className="flex-1 bg-blue-600 text-white rounded-xl py-3 text-base font-semibold disabled:opacity-50">
                {ldFunil?"Movendo...":"Confirmar"}
              </button>
            </div>
          </>)}
        </div>
      </div>
    </div>
  );
}

// ─── Discador ─────────────────────────────────────────────────────────────────
function DiscadorTab({ sb, token }) {
  const [lead,setLead]=useState(null); const [prog,setProg]=useState(null); const [msg,setMsg]=useState("");
  const [ld,setLd]=useState(true); const [fld,setFld]=useState(false);
  const [showObs,setShowObs]=useState(false); const [obs,setObs]=useState(""); const [selFb,setSelFb]=useState(null);
  const [loteDone,setLoteDone]=useState(false); const [showRate,setShowRate]=useState(false);
  const [rateNote,setRateNote]=useState(0); const [lastListaId,setLastListaId]=useState(null);
  const [solicitando,setSolicitando]=useState(false); const [solErr,setSolErr]=useState("");

  const loadNext=useCallback(async()=>{
    setLd(true); setLoteDone(false); setSolErr("");
    try {
      const r=await sb.rpc("proximo_lead",{},token);
      const l=r.lead?(typeof r.lead==="string"?JSON.parse(r.lead):r.lead):null;
      setLead(l); setProg(r.progresso||null); setMsg(r.message||"");
      if(l) setLastListaId(l.lista_id);
    } catch(e) { setMsg(e.message); }
    setLd(false);
  },[sb,token]);

  useEffect(()=>{ loadNext(); },[loadNext]);

  const handleFb=(id)=>{ setSelFb(id); setShowObs(true); };
  const submitFb=async()=>{
    setFld(true);
    try {
      const r=await sb.rpc("registrar_feedback",{p_lead_id:lead.id,p_feedback:selFb,p_observacao:obs||""},token);
      if(r.error) throw new Error(r.error);
      setObs(""); setShowObs(false); setSelFb(null);
      if(r.lote_fechado){setLoteDone(true);setShowRate(true);}else{loadNext();}
    } catch(e){setMsg(e.message);setShowObs(false);}
    setFld(false);
  };
  const submitRate=async()=>{
    if(rateNote>0&&lastListaId){try{await sb.rpc("avaliar_lista",{p_lista_id:lastListaId,p_nota:rateNote},token);}catch(e){}}
    setShowRate(false); setRateNote(0); loadNext();
  };
  const solicitarLote=async()=>{
    setSolicitando(true); setSolErr("");
    try {
      const r=await sb.rpc("solicitar_lote",{},token);
      if(r.error) throw new Error(r.error);
      loadNext();
    } catch(e){ setSolErr(e.message); setSolicitando(false); }
  };

  if(ld) return <div className="flex items-center justify-center h-64 text-gray-400 text-lg">Carregando...</div>;

  if(showRate) return (
    <div className="p-5"><div className="bg-white rounded-2xl shadow-md p-6 border text-center">
      <div className="text-5xl mb-3">🎉</div>
      <p className="font-bold text-emerald-800 text-xl mb-1">Lote completo!</p>
      <p className="text-base text-gray-600 mb-5">Como você avalia a qualidade dessa lista?</p>
      <div className="mb-5"><Stars value={rateNote} onChange={setRateNote}/></div>
      <button className="w-full bg-blue-600 text-white rounded-xl py-3 text-base font-medium" onClick={submitRate}>{rateNote>0?"Enviar avaliação":"Pular"}</button>
    </div></div>
  );

  // Sem lead — opção de solicitar novo lote
  if(!lead&&!loteDone) return (
    <div className="flex flex-col items-center justify-center min-h-64 px-5 py-8">
      <div className="text-5xl text-gray-300 mb-4">◎</div>
      <p className="text-gray-500 text-center text-lg mb-6">{msg||"Sem leads no momento."}</p>
      {solErr&&<div className="bg-red-50 text-red-700 rounded-xl p-3 mb-4 text-base w-full text-center">{solErr}</div>}
      <button onClick={solicitarLote} disabled={solicitando} className="w-full bg-blue-600 text-white rounded-xl py-4 text-lg font-bold disabled:opacity-50 mb-3">
        {solicitando?"Solicitando...":"📋 Solicitar novo lote"}
      </button>
      <button onClick={loadNext} className="text-blue-600 text-base font-medium">Verificar novamente</button>
      <p className="text-xs text-gray-400 mt-4 text-center">Ao solicitar, você recebe 25 novos leads automaticamente.</p>
    </div>
  );

  if(showObs) return (
    <div className="p-5"><div className="bg-white rounded-2xl shadow-md p-5 border">
      <h3 className="font-bold text-gray-900 text-xl mb-1">{FEEDBACKS.find(f=>f.id===selFb)?.label}</h3>
      <p className="text-base text-gray-500 mb-4">{lead?.nome}</p>
      <textarea className="w-full border border-gray-300 rounded-xl px-3 py-3 text-base resize-none" rows={4} placeholder="Observação (opcional)" value={obs} onChange={e=>setObs(e.target.value)}/>
      <div className="flex gap-3 mt-4">
        <button className="flex-1 bg-gray-200 text-gray-700 rounded-xl py-3 text-base font-medium" onClick={()=>{setShowObs(false);setSelFb(null);setObs("");}}>Voltar</button>
        <button className="flex-1 bg-blue-600 text-white rounded-xl py-3 text-base font-medium disabled:opacity-50" disabled={fld} onClick={submitFb}>{fld?"Salvando...":"Confirmar"}</button>
      </div>
    </div></div>
  );

  return (
    <div className="p-5 space-y-5">
      {prog&&(<div>
        <div className="flex justify-between text-base text-gray-500 mb-2"><span>Lote</span><span className="font-bold text-gray-900">{prog.feitos}/{prog.total}</span></div>
        <div className="w-full bg-gray-200 rounded-full h-4"><div className="bg-blue-600 h-4 rounded-full transition-all" style={{width:(prog.feitos/prog.total*100)+"%"}}/></div>
      </div>)}
      {lead&&(
        <div className="bg-white rounded-2xl shadow-md p-5 border border-gray-100">
          <h2 className="text-2xl font-bold text-gray-900">{lead.nome||"Sem nome"}</h2>
          {lead.email&&<p className="text-base text-gray-500 mt-1">{lead.email}</p>}
          {lead.endereco&&<p className="text-base text-gray-400 mt-1">{lead.endereco}</p>}
          <div className="mt-4 bg-gray-50 rounded-xl p-4">
            <p className="text-2xl font-mono font-bold text-gray-900">{lead.telefone_escolhido||lead.telefone_e164||"—"}</p>
            <p className="text-base text-gray-500 mt-1">{lead.tipo_telefone} · {lead.pais_telefone}</p>
          </div>
          <div className="flex gap-2 mt-4 flex-wrap">
            {lead.ligar&&<a href={"tel:"+lead.ligar} className="flex-1 bg-blue-600 text-white rounded-xl py-4 text-center font-bold text-xl no-underline">📞 Ligar</a>}
            {lead.telefone_e164&&lead.tipo_telefone==="br_celular"&&<a href={buildWhatsAppLink(lead)} target="_blank" rel="noopener noreferrer" className="flex-1 bg-emerald-600 text-white rounded-xl py-4 text-center font-bold text-xl no-underline">WhatsApp</a>}
            {lead.email&&<a href={buildEmailLink(lead)} className="flex-1 bg-indigo-600 text-white rounded-xl py-4 text-center font-bold text-xl no-underline">✉ Email</a>}
          </div>
        </div>
      )}
      <div>
        <p className="text-base text-gray-500 uppercase tracking-wide mb-3 font-medium">Feedback</p>
        <div className="grid grid-cols-2 gap-2">
          {FEEDBACKS.map(f=>(<button key={f.id} className={`${f.color} text-white rounded-xl py-4 px-3 text-base font-medium text-left`} onClick={()=>handleFb(f.id)}><span className="mr-1 text-lg">{f.icon}</span>{f.label}</button>))}
        </div>
      </div>
    </div>
  );
}

// ─── Produção ─────────────────────────────────────────────────────────────────
function ProducaoTab({ sb, token }) {
  const [data,setData]=useState(null); const [ld,setLd]=useState(true); const [leadEdit,setLeadEdit]=useState(null);
  const load=async()=>{ setLd(true); try{setData(await sb.rpc("minha_producao",{},token));}catch(e){} setLd(false); };
  useEffect(()=>{load();},[]);
  if(ld) return <div className="p-5 text-center text-gray-400 text-lg">Carregando...</div>;
  if(!data||data.error) return <div className="p-5 text-center text-red-500 text-lg">Erro ao carregar</div>;
  const hoje=data.hoje||{},semana=data.semana||[],totais=data.totais||{};
  const chartData=semana.map(d=>({dia:new Date(d.dia).toLocaleDateString("pt-BR",{weekday:"short"}),total:d.total,visitas:d.visitas}));
  return (
    <div className="p-5 space-y-5">
      <h2 className="text-2xl font-bold text-gray-900">Minha produção</h2>
      <div className="grid grid-cols-3 gap-3">
        {[["Hoje",hoje.total||0,"text-gray-900"],["Visitas",hoje.visitas||0,"text-emerald-600"],["Errados",hoje.errados||0,"text-red-500"]].map(([l,v,c])=>(
          <div key={l} className="bg-white rounded-xl p-3 shadow-sm border border-gray-100 text-center"><p className="text-xs text-gray-500 uppercase">{l}</p><p className={`text-3xl font-bold mt-1 ${c}`}>{v}</p></div>
        ))}
      </div>
      <div className="grid grid-cols-3 gap-3">
        {[["Recebidos",totais.total_recebidos||0,"text-gray-900"],["c/ feedback",totais.com_feedback||0,"text-gray-900"],["Carteira",totais.em_carteira||0,"text-blue-600"]].map(([l,v,c])=>(
          <div key={l} className="bg-white rounded-xl p-3 shadow-sm border border-gray-100 text-center"><p className="text-xs text-gray-500 uppercase">{l}</p><p className={`text-3xl font-bold mt-1 ${c}`}>{v}</p></div>
        ))}
      </div>
      {chartData.length>0&&(<div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm"><p className="text-sm text-gray-500 uppercase mb-2">Últimos 7 dias</p><ResponsiveContainer width="100%" height={160}><BarChart data={chartData}><XAxis dataKey="dia" tick={{fontSize:13}}/><YAxis tick={{fontSize:13}} width={28}/><RTooltip/><Bar dataKey="total" fill="#3b82f6" radius={[4,4,0,0]}/><Bar dataKey="visitas" fill="#10b981" radius={[4,4,0,0]}/></BarChart></ResponsiveContainer></div>)}
      {data.com_observacao?.length>0&&(<div>
        <p className="text-base font-bold text-gray-700 mb-2">Com observação <span className="text-sm font-normal text-gray-400">(toque para editar)</span></p>
        <div className="space-y-2">{data.com_observacao.slice(0,10).map((l,i)=>(
          <div key={i} className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm cursor-pointer hover:border-blue-200 transition-all" onClick={()=>setLeadEdit(l)}>
            <div className="flex justify-between items-start">
              <span className="font-medium text-base text-gray-900">{l.nome}</span>
              <span className="text-sm bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">{FEEDBACKS.find(f=>f.id===l.feedback)?.label||l.feedback}</span>
            </div>
            <p className="text-sm text-gray-600 mt-1">{l.observacao}</p>
          </div>
        ))}</div>
      </div>)}
      {leadEdit&&<LeadModal lead={leadEdit} sb={sb} token={token} onSalvo={()=>{setLeadEdit(null);load();}} onFechar={()=>setLeadEdit(null)}/>}
    </div>
  );
}

// ─── Carteira ─────────────────────────────────────────────────────────────────
function CarteiraTab({ sb, token }) {
  const [data,setData]=useState(null); const [ld,setLd]=useState(true); const [leadEdit,setLeadEdit]=useState(null);
  const load=async()=>{ setLd(true); try{setData(await sb.rpc("minha_producao",{},token));}catch(e){} setLd(false); };
  useEffect(()=>{load();},[]);
  if(ld) return <div className="p-5 text-center text-gray-400 text-lg">Carregando...</div>;
  const cart=data?.carteira||[];
  return (
    <div className="p-5 space-y-4">
      <h2 className="text-2xl font-bold text-gray-900">Carteira <span className="text-lg font-normal text-gray-500">({cart.length})</span></h2>
      {cart.length===0&&<p className="text-base text-gray-500">Nenhum lead em carteira. Leads com "agendou visita", "enviou info" ou "retornar depois" aparecem aqui.</p>}
      <p className="text-sm text-gray-400">Toque em um card para ligar, enviar mensagem ou atualizar feedback.</p>
      <div className="space-y-2">
        {cart.map((l,i)=>{
          const e164=(l.telefone||"").replace(/\D/g,"").length===11?"+55"+(l.telefone||"").replace(/\D/g,""):(l.telefone_e164||"");
          const fbInfo=FEEDBACKS.find(f=>f.id===l.feedback);
          return (
            <div key={i} className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm cursor-pointer hover:border-blue-200 transition-all" onClick={()=>setLeadEdit({...l,telefone_e164:e164})}>
              <div className="flex justify-between items-start">
                <div><p className="font-medium text-base text-gray-900">{l.nome}</p><p className="text-sm text-gray-500 mt-0.5">{l.telefone}</p></div>
                <div className="flex items-center gap-2 flex-wrap justify-end">
                  {fbInfo&&<span className={`text-xs text-white px-2 py-0.5 rounded-full ${fbInfo.color}`}>{fbInfo.label}</span>}
                  <div className="flex gap-1" onClick={e=>e.stopPropagation()}>
                    {l.telefone&&<a href={"tel:"+l.telefone} className="text-sm bg-blue-100 text-blue-700 px-3 py-1.5 rounded-lg no-underline font-medium">📞</a>}
                    {e164&&<a href={buildWhatsAppLink({...l,telefone_e164:e164})} target="_blank" rel="noopener noreferrer" className="text-sm bg-emerald-100 text-emerald-700 px-3 py-1.5 rounded-lg no-underline font-medium">Zap</a>}
                    {l.email&&<a href={buildEmailLink(l)} className="text-sm bg-indigo-100 text-indigo-700 px-3 py-1.5 rounded-lg no-underline font-medium">✉</a>}
                  </div>
                </div>
              </div>
              {l.observacao&&<p className="text-sm text-gray-600 mt-2 bg-gray-50 rounded-lg p-2">{l.observacao}</p>}
            </div>
          );
        })}
      </div>
      {leadEdit&&<LeadModal lead={leadEdit} sb={sb} token={token} onSalvo={()=>{setLeadEdit(null);load();}} onFechar={()=>setLeadEdit(null)}/>}
    </div>
  );
}

// ─── Histórico ────────────────────────────────────────────────────────────────
function HistoricoTab({ sb, token }) {
  const [leads,setLeads]=useState([]); const [total,setTotal]=useState(0);
  const [ld,setLd]=useState(true); const [pagina,setPagina]=useState(0);
  const [leadEdit,setLeadEdit]=useState(null); const [busca,setBusca]=useState("");
  const POR_PAG=20;
  const load=async(p=0)=>{ setLd(true); try{const r=await sb.rpc("meu_historico",{p_limit:POR_PAG,p_offset:p*POR_PAG},token);setLeads(r.leads||[]);setTotal(r.total||0);setPagina(p);}catch(e){} setLd(false); };
  useEffect(()=>{load(0);},[]);
  const filtrados=busca.trim()?leads.filter(l=>[l.nome,l.email,l.telefone].join(" ").toLowerCase().includes(busca.toLowerCase())):leads;
  return (
    <div className="p-5 space-y-4">
      <div className="flex items-center justify-between"><h2 className="text-2xl font-bold text-gray-900">Histórico</h2><span className="text-sm text-gray-400">{total} atendidos</span></div>
      <input type="text" placeholder="Buscar nome, email ou telefone..." value={busca} onChange={e=>setBusca(e.target.value)} className="w-full border border-gray-200 rounded-xl px-4 py-3 text-base focus:outline-none focus:ring-2 focus:ring-blue-500"/>
      {ld?<div className="text-center text-gray-400 py-8 text-lg">Carregando...</div>:filtrados.length===0?<div className="text-center text-gray-400 py-8 text-base">{busca?"Nenhum resultado.":"Nenhum lead atendido ainda."}</div>:(
        <div className="space-y-2">
          {filtrados.map((l,i)=>{
            const fbInfo=FEEDBACKS.find(f=>f.id===l.feedback);
            return (
              <div key={i} className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm cursor-pointer hover:border-blue-200 transition-all" onClick={()=>setLeadEdit(l)}>
                <div className="flex justify-between items-start">
                  <div><p className="font-medium text-base text-gray-900">{l.nome||"—"}</p><p className="text-sm text-gray-500 mt-0.5">{l.telefone||"—"}</p></div>
                  <div className="text-right">
                    {fbInfo&&<span className={`text-xs text-white px-2 py-0.5 rounded-full ${fbInfo.color}`}>{fbInfo.label}</span>}
                    {l.data_feedback&&<p className="text-xs text-gray-400 mt-1">{new Date(l.data_feedback).toLocaleDateString("pt-BR")}</p>}
                  </div>
                </div>
                {l.observacao&&<p className="text-sm text-gray-600 mt-2 bg-gray-50 rounded-lg p-2 line-clamp-2">{l.observacao}</p>}
              </div>
            );
          })}
        </div>
      )}
      {!busca&&total>POR_PAG&&(<div className="flex justify-between items-center pt-2">
        <button disabled={pagina===0} onClick={()=>load(pagina-1)} className="text-base text-blue-600 disabled:text-gray-300">← Anterior</button>
        <span className="text-sm text-gray-400">{pagina*POR_PAG+1}–{Math.min((pagina+1)*POR_PAG,total)} de {total}</span>
        <button disabled={(pagina+1)*POR_PAG>=total} onClick={()=>load(pagina+1)} className="text-base text-blue-600 disabled:text-gray-300">Próximo →</button>
      </div>)}
      {leadEdit&&<LeadModal lead={leadEdit} sb={sb} token={token} onSalvo={(a)=>{setLeadEdit(null);setLeads(prev=>prev.map(l=>l.id===a.id?{...l,...a}:l));}} onFechar={()=>setLeadEdit(null)}/>}
    </div>
  );
}

// ─── Dashboard Gestor (DARK) ──────────────────────────────────────────────────
const DARK = { bg:"#0f172a", card:"#1e293b", border:"#334155", text:"#f1f5f9", muted:"#94a3b8", accent:"#38bdf8" };

function DKpi({ label, value, sub, color="#38bdf8" }) {
  return (
    <div style={{background:DARK.card,border:`1px solid ${DARK.border}`,borderRadius:16,padding:"14px 12px"}}>
      <p style={{color:DARK.muted,fontSize:11,textTransform:"uppercase",letterSpacing:1,margin:0}}>{label}</p>
      <p style={{color,fontSize:28,fontWeight:700,margin:"4px 0 0"}}>{value}</p>
      {sub&&<p style={{color:DARK.muted,fontSize:12,margin:"2px 0 0"}}>{sub}</p>}
    </div>
  );
}

// ─── ArcGauge — estilo Grafana ───────────────────────────────────────────────
function ArcGauge({ valor, label }) {
  const v   = Math.min(99.9, Math.max(0.2, valor||0.2));
  const p   = v / 100;
  const r   = 40, cx = 60, cy = 64;

  function ptArc(t) {
    const a = Math.PI * (1 - t);
    return [+(cx + r * Math.cos(a)).toFixed(2), +(cy - r * Math.sin(a)).toFixed(2)];
  }
  function arcD(t0, t1) {
    const [x0,y0]=ptArc(t0), [x1,y1]=ptArc(t1);
    return `M${x0},${y0} A${r},${r} 0 ${(t1-t0)>0.5?1:0},0 ${x1},${y1}`;
  }

  const numCor = p<=0.33 ? "#22c55e" : p<=0.66 ? "#f59e0b" : "#ef4444";

  // Ponta arredondada no final do preenchimento
  const tipPt  = ptArc(Math.min(p, 0.999));
  const tipCol = numCor;

  return (
    <div style={{textAlign:"center"}}>
      <svg viewBox="0 0 120 82" width="100%" style={{overflow:"visible"}}>
        {/* Trilha escura de fundo (arco completo) */}
        <path d={arcD(0,0.999)} fill="none" stroke="#1e3a5f" strokeWidth="11" strokeLinecap="round"/>
        {/* Zonas de cor sempre visíveis (opacidade reduzida = referência) */}
        <path d={arcD(0,0.333)}    fill="none" stroke="#22c55e" strokeWidth="11" strokeLinecap="round"  opacity="0.2"/>
        <path d={arcD(0.333,0.666)} fill="none" stroke="#f59e0b" strokeWidth="11" strokeLinecap="butt"   opacity="0.2"/>
        <path d={arcD(0.666,0.999)} fill="none" stroke="#ef4444" strokeWidth="11" strokeLinecap="round"  opacity="0.2"/>
        {/* Preenchimento sólido até o valor — verde */}
        {p > 0.001 && <path d={arcD(0, Math.min(p,0.333))} fill="none" stroke="#22c55e" strokeWidth="11" strokeLinecap="round"/>}
        {/* Preenchimento — âmbar */}
        {p > 0.333 && <path d={arcD(0.333, Math.min(p,0.666))} fill="none" stroke="#f59e0b" strokeWidth="11" strokeLinecap="butt"/>}
        {/* Preenchimento — vermelho */}
        {p > 0.666 && <path d={arcD(0.666, Math.min(p,0.999))} fill="none" stroke="#ef4444" strokeWidth="11" strokeLinecap="butt"/>}
        {/* Ponta circular arredondada no fim do preenchimento */}
        {p > 0.01 && <circle cx={tipPt[0]} cy={tipPt[1]} r="5.5" fill={tipCol}/>}
        {/* Número e label */}
        <text x={cx} y={cy-6} textAnchor="middle" dominantBaseline="central"
          fill={numCor} fontSize="20" fontWeight="700">{v}%</text>
        <text x={cx} y={cy+14} textAnchor="middle" fill="#64748b" fontSize="10">{label}</text>
      </svg>
    </div>
  );
}

// ─── FunilViz — funil trapezoidal com bandas coloridas ──────────────────────
// Referência: triângulo invertido, cada estágio é um trapézio colorido,
// label dentro da banda, contagem à direita, largura proporcional ao volume.
function FunilViz({ dados }) {
  if (!dados?.length) return null;

  const W    = 300;   // largura total do SVG
  const CX   = 150;   // centro horizontal
  const MAXW = 260;   // largura máxima (estágio com mais leads)
  const MINW = 24;    // largura mínima (evita bandas invisíveis)
  const H    = 30;    // altura de cada banda
  const GAP  = 2;     // espaço entre bandas

  const maxVal = Math.max(...dados.map(d => d.total), 1);
  const total  = dados.reduce((s, d) => s + d.total, 0);

  // Calcular largura de cada banda proporcional ao count
  const widths = dados.map(d => Math.max(MINW, Math.round((d.total / maxVal) * MAXW)));
  const svgH   = dados.length * (H + GAP) + 4;

  return (
    <svg viewBox={`0 0 ${W} ${svgH}`} width="100%" style={{display:"block"}}>
      {dados.map((d, i) => {
        const topW = widths[i];
        // A base do trapézio é a largura do próximo estágio (ou um pouco menor se for o último)
        const botW = i < dados.length - 1 ? widths[i + 1] : Math.max(MINW, widths[i] - 20);
        const y    = i * (H + GAP);

        // Pontos do trapézio centrado
        const tx1  = CX - topW / 2, tx2 = CX + topW / 2;
        const bx1  = CX - botW / 2, bx2 = CX + botW / 2;
        const pts  = `${tx1.toFixed(1)},${y} ${tx2.toFixed(1)},${y} ${bx2.toFixed(1)},${y+H} ${bx1.toFixed(1)},${y+H}`;

        const pctTot = total > 0 ? ((d.total / total) * 100).toFixed(0) : 0;
        const vazio  = d.total === 0;

        return (
          <g key={i}>
            <polygon points={pts} fill={d.cor || "#334155"} opacity={vazio ? 0.18 : 1}/>
            {/* Linha separadora entre bandas */}
            {i > 0 && <line x1={tx1} y1={y} x2={tx2} y2={y} stroke="#0f172a" strokeWidth="1.5"/>}
            {/* Label dentro da banda (só se tiver espaço suficiente) */}
            {topW > 60 && (
              <text x={CX} y={y + H / 2} textAnchor="middle" dominantBaseline="central"
                fill="#fff" fontSize="10" fontWeight={vazio?"400":"500"}>
                {d.icone} {d.nome}
              </text>
            )}
            {/* Contagem à direita da banda */}
            <text x={tx2 + 6} y={y + H / 2} dominantBaseline="central"
              fill={vazio ? "#334155" : "#94a3b8"} fontSize="10">
              {d.total > 0 ? `${d.total} (${pctTot}%)` : "—"}
            </text>
          </g>
        );
      })}
    </svg>
  );
}


function DashboardTab({ sb, token }) {
  const [s,setS]=useState(null); const [hr,setHr]=useState(null);
  const [funil,setFunil]=useState(null); const [ld,setLd]=useState(true);
  const load=async()=>{
    setLd(true);
    try {
      const [stats,horario,funilStats]=await Promise.all([
        sb.rpc("get_dashboard_stats",{},token),
        sb.rpc("get_stats_horario",{},token),
        sb.rpc("get_funil_stats",{},token),
      ]);
      setS(stats); setHr(horario); setFunil(funilStats);
    } catch(e){}
    setLd(false);
  };
  useEffect(()=>{load();},[]);

  if(ld) return <div style={{background:DARK.bg,minHeight:"100vh",display:"flex",alignItems:"center",justifyContent:"center",color:DARK.muted,fontSize:18}}>Carregando dashboard...</div>;
  if(!s)  return <div style={{background:DARK.bg,minHeight:"100vh",padding:20,color:"#ef4444",fontSize:18}}>Erro ao carregar.</div>;

  const fb=s.feedbacks||{}, pc=s.por_corretor||[], pf=s.por_fornecedor||[];
  const totFb=Object.values(fb).reduce((a,b)=>a+b,0);
  const txVis    =totFb>0?+((fb.agendado_visita||0)/totFb*100).toFixed(1):0;
  const txErro   =totFb>0?+(((fb.numero_errado||0)+(fb.nao_toca||0)+(fb.caixa_postal||0))/totFb*100).toFixed(1):0;
  const txContato=totFb>0?+((((fb.agendado_visita||0)+(fb.enviado_informacoes||0)+(fb.retornar_depois||0))/totFb)*100).toFixed(1):0;

  const barData=[
    {name:"Disponíveis", value:s.disponiveis||0,  cor:"#38bdf8"},
    {name:"Atendimento", value:s.distribuidos||0,  cor:"#f59e0b"},
    {name:"Finalizados", value:s.finalizados||0,   cor:"#10b981"},
    {name:"Inválidos",   value:s.invalidos||0,     cor:"#ef4444"},
  ];
  const barMax=Math.max(...barData.map(d=>d.value),1);

  const horaData=Array.from({length:24},(_,h)=>{
    const f=(hr?.por_hora||[]).find(x=>x.hora===h);
    return {hora:`${String(h).padStart(2,"0")}h`, total:f?.total||0, contatos:f?.contatos||0};
  });
  const diaData=(hr?.por_dia||[]).map(d=>({dia:d.dia,total:d.total,visitas:d.visitas}));

  function qualidadeCor(e) { return e<=10?"#10b981":e<=25?"#f59e0b":"#ef4444"; }
  function qualidadeLabel(e) { return e<=10?"Boa":e<=25?"Regular":"Ruim"; }

  return (
    <div style={{background:DARK.bg,paddingBottom:80}}>
      <div style={{background:DARK.card,borderBottom:`1px solid ${DARK.border}`,padding:"12px 16px",display:"flex",alignItems:"center",justifyContent:"space-between",position:"sticky",top:0,zIndex:10}}>
        <div><span style={{color:DARK.text,fontWeight:700,fontSize:16}}>Dashboard</span><span style={{color:DARK.muted,fontSize:12,marginLeft:8}}>v{APP_VERSION}</span></div>
        <button onClick={load} style={{color:DARK.accent,fontSize:13,background:"none",border:"none",cursor:"pointer"}}>↺ Atualizar</button>
      </div>
      <div style={{padding:16,display:"flex",flexDirection:"column",gap:16}}>

        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:8}}>
          <DKpi label="Total leads"    value={s.total_leads}      color={DARK.text}/>
          <DKpi label="Disponíveis"    value={s.disponiveis}      color="#38bdf8"/>
          <DKpi label="Em atendimento" value={s.distribuidos}     color="#f59e0b"/>
          <DKpi label="Finalizados"    value={s.finalizados}      color="#10b981"/>
          <DKpi label="Em carteira"    value={s.em_carteira||0}   color="#a78bfa"/>
          <DKpi label="Lotes abertos"  value={s.lotes_abertos||0} color="#fb923c"/>
        </div>

        <div style={{background:DARK.card,borderRadius:16,padding:16,border:`1px solid ${DARK.border}`}}>
          <p style={{color:DARK.text,fontWeight:600,fontSize:14,margin:"0 0 8px"}}>Taxas de conversão</p>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:8}}>
            <ArcGauge valor={txVis}     label="Visitas %"  cor="#10b981"/>
            <ArcGauge valor={txContato} label="Contato %"  cor="#38bdf8"/>
            <ArcGauge valor={txErro}    label="Erro %"     cor="#ef4444"/>
          </div>
        </div>

        <div style={{background:DARK.card,borderRadius:16,padding:16,border:`1px solid ${DARK.border}`}}>
          <p style={{color:DARK.text,fontWeight:600,fontSize:14,margin:"0 0 12px"}}>Distribuição dos leads</p>
          {barData.filter(d=>d.value>0).map((d,i)=>(
            <div key={i} style={{marginBottom:10}}>
              <div style={{display:"flex",justifyContent:"space-between",marginBottom:4}}>
                <span style={{color:DARK.muted,fontSize:12}}>{d.name}</span>
                <span style={{color:d.cor,fontSize:12,fontWeight:600}}>{d.value}</span>
              </div>
              <div style={{height:10,background:DARK.border,borderRadius:6,overflow:"hidden"}}>
                <div style={{height:"100%",width:(d.value/barMax*100)+"%",background:d.cor,borderRadius:6,transition:"width 0.6s"}}/>
              </div>
            </div>
          ))}
        </div>

        {funil?.estagios?.some(e=>e.total>0)&&(
          <div style={{background:DARK.card,borderRadius:16,padding:16,border:`1px solid ${DARK.border}`}}>
            <p style={{color:DARK.text,fontWeight:600,fontSize:14,margin:"0 0 12px"}}>Funil de vendas</p>
            <FunilViz dados={funil.estagios}/>
          </div>
        )}

        <div style={{background:DARK.card,borderRadius:16,padding:16,border:`1px solid ${DARK.border}`}}>
          <p style={{color:DARK.text,fontWeight:600,fontSize:14,margin:"0 0 6px"}}>Ligações por hora — últimos 7 dias</p>
          <div style={{display:"flex",gap:16,marginBottom:8}}>
            <div style={{display:"flex",alignItems:"center",gap:4}}><div style={{width:12,height:3,background:"#38bdf8",borderRadius:2}}/><span style={{color:DARK.muted,fontSize:11}}>Ligações</span></div>
            <div style={{display:"flex",alignItems:"center",gap:4}}><div style={{width:12,height:3,background:"#10b981",borderRadius:2}}/><span style={{color:DARK.muted,fontSize:11}}>Contatos produtivos</span></div>
          </div>
          <ResponsiveContainer width="100%" height={155}>
            <AreaChart data={horaData}>
              <defs>
                <linearGradient id="gH" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#38bdf8" stopOpacity={0.3}/><stop offset="95%" stopColor="#38bdf8" stopOpacity={0}/></linearGradient>
                <linearGradient id="gC" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/><stop offset="95%" stopColor="#10b981" stopOpacity={0}/></linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={DARK.border}/>
              <XAxis dataKey="hora" tick={{fontSize:9,fill:DARK.muted}} interval={3}/>
              <YAxis tick={{fontSize:9,fill:DARK.muted}} width={22}/>
              <RTooltip contentStyle={{background:DARK.card,border:`1px solid ${DARK.border}`,borderRadius:8,color:DARK.text}} formatter={(v,n)=>[v,n==="total"?"Ligações":"Contatos produtivos"]}/>
              <Area type="monotone" dataKey="total"    stroke="#38bdf8" fill="url(#gH)" strokeWidth={2} name="total"/>
              <Area type="monotone" dataKey="contatos" stroke="#10b981" fill="url(#gC)" strokeWidth={2} name="contatos"/>
            </AreaChart>
          </ResponsiveContainer>
          <p style={{color:DARK.muted,fontSize:10,marginTop:4,textAlign:"center"}}>Pico de ligações à tarde + pico de contatos de manhã = mudar horário da equipe</p>
        </div>

        {diaData.length>0&&(
          <div style={{background:DARK.card,borderRadius:16,padding:16,border:`1px solid ${DARK.border}`}}>
            <p style={{color:DARK.text,fontWeight:600,fontSize:14,margin:"0 0 12px"}}>Últimos 14 dias</p>
            <ResponsiveContainer width="100%" height={140}>
              <AreaChart data={diaData}>
                <defs>
                  <linearGradient id="gD" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#10b981" stopOpacity={0.35}/><stop offset="95%" stopColor="#10b981" stopOpacity={0}/></linearGradient>
                  <linearGradient id="gV" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#f59e0b" stopOpacity={0.35}/><stop offset="95%" stopColor="#f59e0b" stopOpacity={0}/></linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke={DARK.border}/>
                <XAxis dataKey="dia" tick={{fontSize:9,fill:DARK.muted}}/>
                <YAxis tick={{fontSize:9,fill:DARK.muted}} width={22}/>
                <RTooltip contentStyle={{background:DARK.card,border:`1px solid ${DARK.border}`,borderRadius:8,color:DARK.text}}/>
                <Area type="monotone" dataKey="total"   stroke="#10b981" fill="url(#gD)" strokeWidth={2} name="Ligações"/>
                <Area type="monotone" dataKey="visitas" stroke="#f59e0b" fill="url(#gV)" strokeWidth={2} name="Visitas"/>
              </AreaChart>
            </ResponsiveContainer>
          </div>
        )}

        {pc.length>0&&(
          <div style={{background:DARK.card,borderRadius:16,padding:16,border:`1px solid ${DARK.border}`}}>
            <p style={{color:DARK.text,fontWeight:600,fontSize:14,margin:"0 0 12px"}}>Performance por corretor</p>
            {pc.map((c,i)=>(
              <div key={i} style={{borderBottom:i<pc.length-1?`1px solid ${DARK.border}`:"none",paddingBottom:i<pc.length-1?12:0,marginBottom:i<pc.length-1?12:0}}>
                <div style={{display:"flex",justifyContent:"space-between",alignItems:"center"}}>
                  <span style={{color:DARK.text,fontSize:15,fontWeight:500}}>{c.nome}</span>
                  <span style={{color:"#10b981",fontSize:14,fontWeight:700}}>{c.taxa_visita||0}% vis</span>
                </div>
                <div style={{display:"flex",gap:16,marginTop:4}}>
                  <span style={{color:DARK.muted,fontSize:12}}>{c.total_leads} leads</span>
                  <span style={{color:"#10b981",fontSize:12}}>{c.visitas} visitas</span>
                  <span style={{color:"#ef4444",fontSize:12}}>{c.numero_errado} erros</span>
                  <span style={{color:"#a78bfa",fontSize:12}}>{c.em_carteira||0} carteira</span>
                </div>
                {c.total_leads>0&&<div style={{marginTop:6,height:6,background:DARK.border,borderRadius:4,overflow:"hidden"}}><div style={{height:"100%",background:"#10b981",borderRadius:4,width:Math.min(100,(c.com_feedback/c.total_leads)*100)+"%",transition:"width 0.5s"}}/></div>}
              </div>
            ))}
          </div>
        )}

        {pf.length>0&&(
          <div style={{background:DARK.card,borderRadius:16,padding:16,border:`1px solid ${DARK.border}`}}>
            <p style={{color:DARK.text,fontWeight:600,fontSize:14,margin:"0 0 12px"}}>Qualidade das listas</p>
            {pf.map((f,i)=>{
              const txErr=f.taxa_erro||0, cor=qualidadeCor(txErr), ql=qualidadeLabel(txErr);
              return (
                <div key={i} style={{borderBottom:i<pf.length-1?`1px solid ${DARK.border}`:"none",paddingBottom:i<pf.length-1?12:0,marginBottom:i<pf.length-1?12:0}}>
                  <div style={{display:"flex",justifyContent:"space-between",alignItems:"center"}}>
                    <div><span style={{color:DARK.text,fontSize:15,fontWeight:500}}>{f.fornecedor}</span>{f.nota_media>0&&<span style={{color:"#f59e0b",marginLeft:8,fontSize:13}}>★ {f.nota_media}</span>}</div>
                    <span style={{color:cor,fontSize:13,fontWeight:600,background:cor+"22",padding:"2px 8px",borderRadius:12}}>{ql}</span>
                  </div>
                  <div style={{marginTop:8,height:8,background:DARK.border,borderRadius:4,overflow:"hidden"}}><div style={{height:"100%",background:"#10b981",borderRadius:4,width:(f.taxa_visita||0)+"%"}}/></div>
                  <div style={{display:"flex",justifyContent:"space-between",marginTop:4}}>
                    <span style={{color:"#10b981",fontSize:11}}>{f.taxa_visita||0}% visitas</span>
                    <span style={{color:"#ef4444",fontSize:11}}>{txErr}% erro</span>
                    <span style={{color:DARK.muted,fontSize:11}}>{f.total} leads</span>
                  </div>
                </div>
              );
            })}
          </div>
        )}

      </div>
    </div>
  );
}


// ─── Abas do gestor ───────────────────────────────────────────────────────────
// ─── Modal do card no funil ───────────────────────────────────────────────────
function FunilCardModal({ lead, estagios, sb, token, onMovido, onFechar }) {
  const [novoEstagio, setNovoEstagio] = useState(lead.estagio_id || "");
  const [obs, setObs]                 = useState("");
  const [ld, setLd]                   = useState(false);
  const [erro, setErro]               = useState("");
  const [abaSel, setAbaSel]           = useState("mover"); // 'mover' | 'contato'

  const estAtual = estagios.find(e => e.id === lead.estagio_id);
  const estNovo  = estagios.find(e => e.id === novoEstagio);

  const mover = async () => {
    if (!novoEstagio || novoEstagio === lead.estagio_id) { onFechar(); return; }
    setLd(true); setErro("");
    try {
      const r = await sb.rpc("mover_funil", { p_lead_id: lead.id, p_estagio_id: novoEstagio, p_observacao: obs }, token);
      if (r.error) throw new Error(r.error);
      onMovido({ ...lead, estagio_id: novoEstagio });
    } catch(e) { setErro(e.message); }
    setLd(false);
  };

  const e164     = lead.telefone_e164 || "";
  const wppLink  = e164 ? buildWhatsAppLink({ ...lead, telefone_e164: e164 }) : null;
  const mailLink = buildEmailFunilLink(lead, estNovo?.nome || estAtual?.nome || "Novo contato");

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-end" onClick={onFechar}>
      <div className="bg-white rounded-t-2xl w-full max-h-[88vh] overflow-y-auto" onClick={e => e.stopPropagation()}>

        {/* Handle */}
        <div className="flex justify-center pt-3 pb-1"><div className="w-10 h-1 bg-gray-300 rounded-full"/></div>

        {/* Header do card */}
        <div className="px-5 pt-2 pb-4 border-b border-gray-100">
          <div className="flex items-start justify-between">
            <div>
              <h3 className="font-bold text-gray-900 text-xl">{lead.nome || "Sem nome"}</h3>
              <p className="text-sm text-gray-500 mt-0.5">{lead.telefone || "—"}</p>
              {lead.email && <p className="text-xs text-gray-400">{lead.email}</p>}
            </div>
            <div className="flex flex-col items-end gap-1">
              {estAtual && (
                <span className="text-xs text-white px-2 py-1 rounded-full font-medium"
                  style={{ background: estAtual.cor }}>
                  {estAtual.icone} {estAtual.nome}
                </span>
              )}
              {lead.score > 0 && (
                <span className="text-xs bg-amber-100 text-amber-700 px-2 py-0.5 rounded-full">
                  Score {lead.score}/10
                </span>
              )}
            </div>
          </div>

          {/* Ações rápidas */}
          <div className="flex gap-2 mt-3">
            {(lead.ligar || lead.telefone) && (
              <a href={"tel:" + (lead.ligar || lead.telefone)}
                className="flex-1 bg-blue-600 text-white rounded-xl py-3 text-center text-base font-medium no-underline">
                📞 Ligar
              </a>
            )}
            {wppLink && (
              <a href={wppLink} target="_blank" rel="noopener noreferrer"
                className="flex-1 bg-emerald-600 text-white rounded-xl py-3 text-center text-base font-medium no-underline">
                WhatsApp
              </a>
            )}
            {mailLink && (
              <a href={mailLink}
                className="flex-1 bg-indigo-600 text-white rounded-xl py-3 text-center text-base font-medium no-underline">
                ✉ Email
              </a>
            )}
          </div>
        </div>

        {/* Abas */}
        <div className="flex border-b border-gray-100">
          {[["mover","Mover no funil"],["contato","Histórico"]].map(([id,label]) => (
            <button key={id} onClick={() => setAbaSel(id)}
              className={`flex-1 py-3 text-base font-medium transition-colors ${abaSel===id ? "text-blue-600 border-b-2 border-blue-600" : "text-gray-400"}`}>
              {label}
            </button>
          ))}
        </div>

        <div className="p-5 pb-8">
          {abaSel === "mover" && (
            <>
              <p className="text-sm text-gray-500 uppercase tracking-wide mb-3">Selecione o novo estágio</p>
              <div className="space-y-2 mb-4">
                {estagios.map(e => (
                  <button key={e.id} onClick={() => setNovoEstagio(e.id)}
                    className={`w-full flex items-center gap-3 rounded-xl px-4 py-3 text-left transition-all border-2 ${
                      novoEstagio === e.id ? "border-blue-500 bg-blue-50" : "border-transparent bg-gray-50"
                    }`}>
                    <span className="text-xl">{e.icone}</span>
                    <div className="flex-1">
                      <p className="font-medium text-base text-gray-900">{e.nome}</p>
                    </div>
                    <div className="w-3 h-3 rounded-full" style={{ background: e.cor }}/>
                    {novoEstagio === e.id && <span className="text-blue-500 text-lg">✓</span>}
                  </button>
                ))}
              </div>

              {/* Preview do email que será enviado */}
              {novoEstagio && novoEstagio !== lead.estagio_id && estNovo && lead.email && (
                <div className="bg-indigo-50 rounded-xl p-3 mb-4 border border-indigo-100">
                  <p className="text-xs text-indigo-700 font-medium mb-1">✉ Email disponível para este estágio</p>
                  <p className="text-xs text-indigo-600 line-clamp-2">{FUNIL_EMAIL_TEMPLATES[estNovo.nome]?.(getPrimeiroNome(lead.nome))?.subject || "Template padrão"}</p>
                  <a href={buildEmailFunilLink(lead, estNovo.nome) || "#"}
                    className="mt-2 inline-block text-xs text-indigo-700 font-medium underline">
                    Abrir no email →
                  </a>
                </div>
              )}

              <textarea rows={2} placeholder="Observação (opcional)..."
                value={obs} onChange={e => setObs(e.target.value)}
                className="w-full border border-gray-200 rounded-xl px-3 py-3 text-base resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 mb-4"/>

              {erro && <div className="bg-red-50 text-red-700 rounded-xl p-3 mb-3 text-base">{erro}</div>}

              <div className="flex gap-3">
                <button onClick={onFechar} className="flex-1 bg-gray-100 text-gray-700 rounded-xl py-3 text-base font-medium">
                  Fechar
                </button>
                <button onClick={mover} disabled={ld || !novoEstagio || novoEstagio === lead.estagio_id}
                  className="flex-1 bg-blue-600 text-white rounded-xl py-3 text-base font-semibold disabled:opacity-50">
                  {ld ? "Movendo..." : "Mover"}
                </button>
              </div>
            </>
          )}

          {abaSel === "contato" && (
            <div className="space-y-2">
              {lead.feedback && (
                <div className="bg-gray-50 rounded-xl p-3">
                  <p className="text-xs text-gray-500 uppercase mb-1">Último feedback</p>
                  <p className="text-base text-gray-900 font-medium">
                    {FEEDBACKS.find(f => f.id === lead.feedback)?.label || lead.feedback}
                  </p>
                </div>
              )}
              {lead.observacao && (
                <div className="bg-gray-50 rounded-xl p-3">
                  <p className="text-xs text-gray-500 uppercase mb-1">Observação</p>
                  <p className="text-base text-gray-700">{lead.observacao}</p>
                </div>
              )}
              {lead.data_feedback && (
                <p className="text-sm text-gray-400 text-center">
                  Último contato: {new Date(lead.data_feedback).toLocaleDateString("pt-BR")}
                </p>
              )}
              {!lead.feedback && !lead.observacao && (
                <p className="text-gray-400 text-center py-4 text-base">Nenhum histórico ainda.</p>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

// ─── Funil CRM — Kanban ───────────────────────────────────────────────────────
function FunilTab({ sb, token }) {
  const [data, setData]         = useState(null);
  const [ld, setLd]             = useState(true);
  const [estagioAtivo, setEst]  = useState(null);
  const [leadSel, setLeadSel]   = useState(null);
  const [busca, setBusca]       = useState("");
  const [modoSel, setModoSel]   = useState(false);
  const [selecionados, setSel]  = useState(new Set());
  const [showBatch, setShowBatch] = useState(false);
  const [estDest, setEstDest]   = useState("");
  const [ldBatch, setLdBatch]   = useState(false);
  const [errBatch, setErrBatch] = useState("");

  const load = async () => {
    setLd(true);
    try {
      const r = await sb.rpc("meu_funil", {}, token);
      if (r.error) throw new Error(r.error);
      setData(r);
      if (!estagioAtivo && r.estagios?.length > 0) setEst(r.estagios[0].id);
    } catch(e) {}
    setLd(false);
  };
  useEffect(() => { load(); }, []);

  const toggleSel = (id) => setSel(prev => { const n=new Set(prev); n.has(id)?n.delete(id):n.add(id); return n; });
  const selTodos  = (ids) => { if(selecionados.size===ids.length) setSel(new Set()); else setSel(new Set(ids)); };

  const moverBatch = async () => {
    if (!estDest || selecionados.size === 0) return;
    setLdBatch(true); setErrBatch("");
    try {
      const r = await sb.rpc("mover_funil_lote", { p_lead_ids: Array.from(selecionados), p_estagio_id: estDest }, token);
      if (r.error) throw new Error(r.error);
      setData(prev => ({...prev, leads: prev.leads.map(l => selecionados.has(l.id) ? {...l, estagio_id: estDest} : l)}));
      setSel(new Set()); setModoSel(false); setShowBatch(false); setEstDest("");
    } catch(e) { setErrBatch(e.message); }
    setLdBatch(false);
  };

  if (ld) return <div className="p-5 text-center text-gray-400 text-lg py-16">Carregando funil...</div>;
  if (!data?.estagios?.length) return (
    <div className="p-5 text-center py-16">
      <p className="text-4xl mb-4">🏠</p>
      <p className="text-gray-500 text-lg mb-2">Nenhum lead no funil ainda.</p>
      <p className="text-gray-400 text-base">Abra um lead → aba "▽ Funil CRM" para adicionar.</p>
    </div>
  );

  const { estagios, leads } = data;
  const cntEst = {};
  (leads||[]).forEach(l => { if(l.estagio_id) cntEst[l.estagio_id] = (cntEst[l.estagio_id]||0)+1; });

  const filtrados = (leads||[]).filter(l => {
    if (l.estagio_id !== estagioAtivo) return false;
    if (!busca.trim()) return true;
    return [l.nome,l.email,l.telefone].join(" ").toLowerCase().includes(busca.toLowerCase());
  });
  const idsVisiveis = filtrados.map(l => l.id);
  const estAtivo    = estagios.find(e => e.id === estagioAtivo);

  return (
    <div className="pb-24">

      {/* Header */}
      <div className="px-5 pt-5 pb-3">
        <div className="flex items-center justify-between mb-3">
          <h2 className="text-2xl font-bold text-gray-900">Funil CRM</h2>
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-400">{(leads||[]).length}</span>
            <button onClick={() => { setModoSel(!modoSel); setSel(new Set()); setShowBatch(false); }}
              className={`rounded-xl px-3 py-1.5 text-sm font-medium border transition-all ${modoSel ? "bg-blue-600 text-white border-blue-600" : "bg-gray-100 text-gray-700 border-gray-200"}`}>
              {modoSel ? `✓ ${selecionados.size} sel.` : "Selecionar"}
            </button>
          </div>
        </div>
        <input type="text" placeholder="Buscar lead..."
          value={busca} onChange={e => setBusca(e.target.value)}
          className="w-full border border-gray-200 rounded-xl px-4 py-2.5 text-base focus:outline-none focus:ring-2 focus:ring-blue-500"/>
      </div>

      {/* Chips de estágios */}
      <div className="flex gap-2 px-5 pb-3 overflow-x-auto" style={{WebkitOverflowScrolling:"touch"}}>
        {estagios.map(e => {
          const cnt = cntEst[e.id]||0; const ativo = e.id === estagioAtivo;
          return (
            <button key={e.id} onClick={() => { setEst(e.id); setSel(new Set()); }}
              style={{flexShrink:0, border: ativo ? `2px solid ${e.cor}` : "2px solid transparent", background: ativo ? e.cor+"22" : "#f9fafb"}}
              className="flex items-center gap-1.5 rounded-xl px-3 py-2 transition-all">
              <span className="text-base">{e.icone}</span>
              <span className={`text-sm font-medium whitespace-nowrap ${ativo ? "text-gray-900" : "text-gray-500"}`}>{e.nome}</span>
              {cnt > 0 && <span className="text-xs text-white px-1.5 py-0.5 rounded-full" style={{background:e.cor}}>{cnt}</span>}
            </button>
          );
        })}
      </div>

      {/* Barra seleção em massa */}
      {modoSel && (
        <div className="px-5 py-2 bg-blue-50 border-y border-blue-100 flex items-center gap-3">
          <button onClick={() => selTodos(idsVisiveis)} className="text-sm text-blue-600 font-medium">
            {selecionados.size === idsVisiveis.length && idsVisiveis.length > 0 ? "Desmarcar tudo" : "Selecionar tudo"}
          </button>
          {selecionados.size > 0 && (
            <button onClick={() => setShowBatch(true)}
              className="ml-auto bg-blue-600 text-white text-sm font-semibold px-4 py-1.5 rounded-xl">
              Mover {selecionados.size} →
            </button>
          )}
        </div>
      )}

      {/* Cards */}
      <div className="px-5 pt-3 space-y-3">
        {estAtivo && (
          <div className="flex items-center gap-2 mb-1">
            <div className="w-3 h-3 rounded-full" style={{background:estAtivo.cor}}/>
            <span className="font-bold text-base text-gray-900">{estAtivo.nome}</span>
            <span className="text-sm text-gray-400">({filtrados.length})</span>
          </div>
        )}

        {filtrados.length === 0 && (
          <div className="text-center py-12">
            <p className="text-4xl mb-3">{estAtivo?.icone||"○"}</p>
            <p className="text-gray-400 text-base">{busca ? "Nenhum resultado." : "Nenhum lead neste estágio."}</p>
          </div>
        )}

        {filtrados.map((l, i) => {
          const fbInfo = FEEDBACKS.find(f => f.id === l.feedback);
          const sel    = selecionados.has(l.id);
          const dias   = l.data_feedback ? Math.floor((Date.now()-new Date(l.data_feedback))/86400000) : null;
          return (
            <div key={i}
              onClick={() => modoSel ? toggleSel(l.id) : setLeadSel(l)}
              className="bg-white rounded-2xl p-4 border cursor-pointer transition-all"
              style={{border: sel ? "2px solid #3b82f6" : "1px solid #e5e7eb",
                      boxShadow: sel ? "0 0 0 3px #bfdbfe" : "0 1px 3px rgba(0,0,0,0.06)",
                      background: sel ? "#eff6ff" : "white"}}>
              <div className="flex items-start gap-3">
                {modoSel && (
                  <div className="w-6 h-6 rounded-lg flex-shrink-0 mt-0.5 flex items-center justify-center"
                    style={{background: sel?"#3b82f6":"white", border: sel?"none":"2px solid #d1d5db"}}>
                    {sel && <span className="text-white text-sm font-bold">✓</span>}
                  </div>
                )}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0">
                      <p className="font-bold text-gray-900 text-lg truncate">{l.nome||"Sem nome"}</p>
                      <p className="text-sm text-gray-500">{l.telefone||"—"}</p>
                    </div>
                    {l.score > 0 && (
                      <div className="w-9 h-9 rounded-full flex-shrink-0 ml-2 flex items-center justify-center text-white text-sm font-bold"
                        style={{background: l.score>=8?"#10b981":l.score>=5?"#f59e0b":"#9ca3af"}}>
                        {l.score}
                      </div>
                    )}
                  </div>
                  <div className="flex items-center gap-2 flex-wrap mt-2">
                    {fbInfo && <span className={`text-xs text-white px-2 py-0.5 rounded-full ${fbInfo.color}`}>{fbInfo.icon} {fbInfo.label}</span>}
                    {dias !== null && (
                      <span className={`text-xs px-2 py-0.5 rounded-full ${dias>7?"bg-red-100 text-red-700":dias>3?"bg-amber-100 text-amber-700":"bg-green-100 text-green-700"}`}>
                        {dias === 0 ? "hoje" : `${dias}d`}
                      </span>
                    )}
                  </div>
                  {l.observacao && <p className="text-sm text-gray-500 mt-1.5 line-clamp-1 italic">"{l.observacao}"</p>}
                  {!modoSel && (
                    <div className="flex gap-2 mt-3" onClick={e => e.stopPropagation()}>
                      {(l.ligar||l.telefone) && <a href={"tel:"+(l.ligar||l.telefone)} className="text-sm bg-blue-100 text-blue-700 px-3 py-1.5 rounded-lg no-underline font-medium">📞</a>}
                      {l.telefone_e164 && <a href={buildWhatsAppLink({...l})} target="_blank" rel="noopener noreferrer" className="text-sm bg-emerald-100 text-emerald-700 px-3 py-1.5 rounded-lg no-underline font-medium">Zap</a>}
                      {l.email && <a href={buildEmailFunilLink(l, estAtivo?.nome||"Novo contato")} className="text-sm bg-indigo-100 text-indigo-700 px-3 py-1.5 rounded-lg no-underline font-medium">✉</a>}
                      <span className="ml-auto text-xs text-gray-300 self-center">mover →</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Bottom sheet — mover em massa */}
      {showBatch && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end" onClick={() => setShowBatch(false)}>
          <div className="bg-white rounded-t-2xl w-full max-h-[85vh] overflow-y-auto p-5 pb-8" onClick={e => e.stopPropagation()}>
            <div className="flex justify-center mb-4"><div className="w-10 h-1 bg-gray-300 rounded-full"/></div>
            <p className="text-xl font-bold text-gray-900 mb-1">Mover {selecionados.size} lead{selecionados.size>1?"s":""}</p>
            <p className="text-sm text-gray-500 mb-4">Selecione o estágio de destino</p>
            <div className="space-y-2 mb-4">
              {estagios.map(e => (
                <button key={e.id} onClick={() => setEstDest(e.id)}
                  className="w-full flex items-center gap-3 rounded-xl px-4 py-3 text-left transition-all"
                  style={{border: estDest===e.id?"2px solid #3b82f6":"2px solid transparent", background: estDest===e.id?"#eff6ff":"#f9fafb"}}>
                  <span className="text-xl">{e.icone}</span>
                  <span className="flex-1 text-base font-medium text-gray-900">{e.nome}</span>
                  <div className="w-3 h-3 rounded-full" style={{background:e.cor}}/>
                  {estDest===e.id && <span className="text-blue-500 text-lg">✓</span>}
                </button>
              ))}
            </div>
            {errBatch && <div className="bg-red-50 text-red-700 rounded-xl p-3 mb-3 text-base">{errBatch}</div>}
            <div className="flex gap-3">
              <button onClick={() => setShowBatch(false)} className="flex-1 bg-gray-100 text-gray-700 rounded-xl py-3 text-base font-medium">Cancelar</button>
              <button onClick={moverBatch} disabled={ldBatch||!estDest}
                className="flex-1 bg-blue-600 text-white rounded-xl py-3 text-base font-bold disabled:opacity-50">
                {ldBatch ? "Movendo..." : "Confirmar"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal individual */}
      {leadSel && (
        <FunilCardModal lead={leadSel} estagios={estagios} sb={sb} token={token}
          onMovido={a => { setData(prev => ({...prev, leads: prev.leads.map(l => l.id===a.id ? {...l,...a} : l)})); setLeadSel(null); }}
          onFechar={() => setLeadSel(null)}/>
      )}
    </div>
  );
}


function UploadTab({ sb, token }) {
  const [file,setFile]=useState(null); const [forn,setForn]=useState(""); const [preview,setPreview]=useState(null);
  const [colMap,setColMap]=useState(null); const [importing,setImporting]=useState(false); const [result,setResult]=useState(null);
  const fileRef=useRef();
  const handleFile=(f)=>{ if(!f) return; setFile(f); setResult(null); Papa.parse(f,{header:false,skipEmptyLines:true,complete:(res)=>{ if(res.data.length<2) return; if(res.data.length>5001){setResult({error:"Arquivo muito grande (máx 5000 leads)"});return;} const det=detectColumns(res.data[0]); setColMap(det); setPreview({headers:res.data[0],rows:res.data.slice(1),detected:det}); }}); };
  const handleImport=async()=>{
    if(!preview||!forn||!colMap) return; setImporting(true); setResult(null);
    try {
      const lr=await sb.insert("listas",{nome_fornecedor:forn,nome_arquivo:file.name},token); const lid=lr[0].id;
      const leads=preview.rows.map(r=>csvToLead(r,colMap,forn)); const B=100; let tot={validos:0,invalidos:0,duplicados:0};
      const sessaoId=crypto.randomUUID();
      for(let i=0;i<leads.length;i+=B){const r=await sb.rpc("importar_leads_batch",{p_lista_id:lid,p_leads:leads.slice(i,i+B),p_sessao_id:sessaoId},token);tot.validos+=r.validos||0;tot.invalidos+=r.invalidos||0;tot.duplicados+=r.duplicados||0;}
      setResult(tot); setPreview(null); setFile(null); setForn("");
    } catch(e){setResult({error:e.message});} setImporting(false);
  };
  const det=colMap?Object.entries(colMap).map(([k,v])=>`${k}:col${v+1}`).join(" · "):"";
  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-bold text-gray-900">Upload de lista</h2>
      {!preview?(<div><input className="w-full border border-gray-300 rounded-lg px-3 py-3 mb-3 text-sm" placeholder="Nome do fornecedor" value={forn} onChange={e=>setForn(e.target.value)}/><div className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center cursor-pointer hover:border-blue-400" onClick={()=>fileRef.current?.click()}><div className="text-4xl text-gray-300 mb-2">↑</div><p className="text-sm text-gray-500">Toque para selecionar CSV</p><p className="text-xs text-gray-400 mt-1">Máx 5.000 leads</p></div><input ref={fileRef} type="file" accept=".csv,.txt,.tsv" className="hidden" onChange={e=>handleFile(e.target.files[0])}/></div>
      ):(<div><div className="bg-blue-50 rounded-lg p-3 mb-3"><p className="text-sm font-medium text-blue-900">{file?.name} · {preview.rows.length} leads</p>{det&&<p className="text-xs text-blue-600 mt-1">{det}</p>}</div><div className="bg-gray-50 rounded-lg p-3 mb-3">{preview.rows.slice(0,3).map((r,i)=>{const l=csvToLead(r,colMap,forn);return <div key={i} className="bg-white rounded p-2 mb-1 text-xs border">{l.nome||"—"} | {l.telefone_escolhido||"sem tel"} | {l.tipo_telefone}{l.whatsapp?" | WA✓":""}</div>;})}</div><div className="flex gap-2"><button className="flex-1 bg-gray-200 text-gray-700 rounded-lg py-3 font-medium" onClick={()=>{setPreview(null);setFile(null);}}>Cancelar</button><button className="flex-1 bg-blue-600 text-white rounded-lg py-3 font-medium disabled:opacity-50" disabled={importing||!forn} onClick={handleImport}>{importing?"Importando...":"Importar"}</button></div></div>)}
      {result&&!result.error&&<div className="bg-emerald-50 rounded-xl p-4 border border-emerald-200"><p className="font-bold text-emerald-800">Concluído</p><p className="text-sm text-emerald-700 mt-1">{result.validos} válidos · {result.invalidos} inválidos · {result.duplicados} duplicados</p></div>}
      {result?.error&&<div className="bg-red-50 rounded-xl p-4 text-red-700 text-sm">{result.error}</div>}
    </div>
  );
}

function DistribuirTab({ sb, token }) {
  const [ld,setLd]=useState(false); const [result,setResult]=useState(null); const [st,setSt]=useState(null);
  const load=async()=>{ try{const d=await sb.query("leads","status=eq.disponivel&select=id",token);const a=await sb.query("lotes","status=eq.aberto&select=id",token);const c=await sb.query("corretores","ativo=eq.true&select=id",token);setSt({d:d.length,a:a.length,c:c.length});}catch(e){} };
  useEffect(()=>{load();},[]);
  const go=async()=>{ setLd(true);setResult(null);try{setResult(await sb.rpc("distribuir_lotes",{},token));load();}catch(e){setResult({error:e.message});}setLd(false); };
  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-bold text-gray-900">Distribuir lotes</h2>
      {st&&<div className="grid grid-cols-3 gap-3"><div className="bg-white rounded-xl p-3 border text-center"><p className="text-xs text-gray-500">Disponíveis</p><p className="text-2xl font-bold text-blue-600">{st.d}</p></div><div className="bg-white rounded-xl p-3 border text-center"><p className="text-xs text-gray-500">Lotes abertos</p><p className="text-2xl font-bold text-amber-600">{st.a}</p></div><div className="bg-white rounded-xl p-3 border text-center"><p className="text-xs text-gray-500">Corretores</p><p className="text-2xl font-bold text-emerald-600">{st.c}</p></div></div>}
      <div className="bg-gray-50 rounded-xl p-4 text-sm text-gray-600"><p>Cria lotes de <strong>25 leads</strong> para cada corretor ativo sem lote aberto.</p><p className="mt-1 text-xs text-gray-400">Os próprios corretores também podem solicitar um novo lote após finalizar.</p></div>
      <button className="w-full bg-blue-600 text-white rounded-xl py-4 font-bold text-lg disabled:opacity-50" disabled={ld} onClick={go}>{ld?"Distribuindo...":"Distribuir agora"}</button>
      {result&&!result.error&&<div className="bg-emerald-50 rounded-xl p-4 border border-emerald-200"><p className="font-bold text-emerald-800">{result.lotes_criados} lote(s) criado(s)</p></div>}
      {result?.error&&<div className="bg-red-50 rounded-xl p-4 text-red-700 text-sm">{result.error}</div>}
    </div>
  );
}

function ListasTab({ sb, token }) {
  const [listas,setListas]=useState([]); const [report,setReport]=useState(null);
  const load=async()=>{ try{setListas(await sb.query("listas","order=created_at.desc",token));}catch(e){} };
  useEffect(()=>{load();},[]);
  const acao=async(id,a,m)=>{ try{await sb.rpc("gerenciar_lista",{p_lista_id:id,p_acao:a,p_motivo:m||""},token);load();}catch(e){alert(e.message);} };
  const verRelatorio=async(id)=>{ try{setReport(await sb.rpc("relatorio_fornecedor",{p_lista_id:id},token));}catch(e){alert(e.message);} };

  function qualBadge(txErr) {
    if(txErr<=10) return { label:"Boa",    bg:"bg-emerald-100", text:"text-emerald-700", bar:"bg-emerald-500" };
    if(txErr<=25) return { label:"Regular",bg:"bg-amber-100",   text:"text-amber-700",   bar:"bg-amber-500"   };
    return             { label:"Ruim",   bg:"bg-red-100",     text:"text-red-700",     bar:"bg-red-500"     };
  }

  if(report) return (
    <div className="p-4 space-y-4">
      <div className="flex justify-between items-center"><h2 className="text-lg font-bold text-gray-900">Relatório</h2><button className="text-xs text-blue-600" onClick={()=>setReport(null)}>Voltar</button></div>
      <div className="bg-white rounded-xl p-4 border shadow-sm">
        <p className="font-bold text-gray-900">{report.lista?.fornecedor}</p><p className="text-xs text-gray-500">{report.lista?.arquivo} · {report.lista?.status} · ★ {report.lista?.nota_media||"—"}</p>
        <div className="grid grid-cols-2 gap-2 mt-3">
          <div className="text-xs"><span className="text-gray-500">Total:</span> <span className="font-medium">{report.numeros?.total}</span></div>
          <div className="text-xs"><span className="text-gray-500">Válidos:</span> <span className="font-medium">{report.numeros?.validos}</span></div>
          <div className="text-xs"><span className="text-gray-500">Taxa contato:</span> <span className="font-medium text-emerald-600">{report.numeros?.taxa_contato_pct||0}%</span></div>
          <div className="text-xs"><span className="text-gray-500">Taxa erro:</span> <span className="font-medium text-red-500">{report.numeros?.taxa_erro_pct||0}%</span></div>
          <div className="text-xs"><span className="text-gray-500">Visitas:</span> <span className="font-medium text-emerald-600">{report.numeros?.agendado_visita} ({report.numeros?.taxa_visita_pct||0}%)</span></div>
        </div>
      </div>
      {report.avaliacoes?.length>0&&(<div><p className="text-sm font-bold text-gray-700 mb-2">Avaliações</p>{report.avaliacoes.map((a,i)=>(<div key={i} className="bg-white rounded-lg p-3 border mb-2"><div className="flex justify-between"><span className="text-sm font-medium">{a.corretor}</span><div className="flex gap-0.5">{[1,2,3,4,5].map(n=><span key={n} className={n<=a.nota?"text-amber-400":"text-gray-300"}>★</span>)}</div></div>{a.comentario&&<p className="text-xs text-gray-500 mt-1">{a.comentario}</p>}</div>))}</div>)}
    </div>
  );
  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-bold text-gray-900">Listas de leads</h2>
      {listas.length===0&&<p className="text-sm text-gray-500">Nenhuma lista importada ainda.</p>}
      {listas.map(l=>{
        const txErr=l.leads_validos>0?(((l.leads_invalidos||0)/l.leads_validos)*100).toFixed(0):0;
        const qb=qualBadge(+txErr);
        const txContato=l.total_leads>0?Math.round(((l.leads_validos||0)/l.total_leads)*100):0;
        return (
          <div key={l.id} className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
            <div className="flex justify-between items-start">
              <div><p className="font-medium text-sm text-gray-900">{l.nome_fornecedor}</p><p className="text-xs text-gray-500">{l.nome_arquivo} · {new Date(l.created_at).toLocaleDateString("pt-BR")}</p></div>
              <div className="flex items-center gap-2">
                <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${qb.bg} ${qb.text}`}>{qb.label}</span>
                <span className={`text-xs px-2 py-1 rounded-full font-medium ${l.status==="ativa"?"bg-emerald-100 text-emerald-700":l.status==="pausada"?"bg-amber-100 text-amber-700":"bg-red-100 text-red-700"}`}>{l.status}</span>
              </div>
            </div>
            {/* Barra de qualidade visual */}
            <div className="mt-3">
              <div className="flex justify-between text-xs text-gray-500 mb-1">
                <span>{l.total_leads} leads · {l.leads_validos} válidos</span>
                {l.nota_media>0&&<span>★ {l.nota_media}</span>}
              </div>
              <div className="w-full bg-gray-100 rounded-full h-3 overflow-hidden">
                <div className={`h-full ${qb.bar} rounded-full transition-all`} style={{width:Math.min(100,txContato)+"%"}}/>
              </div>
              <div className="flex justify-between text-xs mt-1">
                <span className="text-emerald-600">{txContato}% válidos</span>
                <span className="text-red-500">{txErr}% inválidos</span>
              </div>
            </div>
            <div className="flex gap-2 mt-3 flex-wrap">
              <button className="text-xs bg-gray-100 text-gray-700 px-3 py-1.5 rounded-lg" onClick={()=>verRelatorio(l.id)}>Relatório</button>
              {l.status==="ativa"&&<button className="text-xs bg-amber-100 text-amber-700 px-3 py-1.5 rounded-lg" onClick={()=>acao(l.id,"pausar")}>Pausar</button>}
              {l.status==="pausada"&&<button className="text-xs bg-emerald-100 text-emerald-700 px-3 py-1.5 rounded-lg" onClick={()=>acao(l.id,"reativar")}>Reativar</button>}
              {l.status!=="encerrada"&&<button className="text-xs bg-red-100 text-red-700 px-3 py-1.5 rounded-lg" onClick={()=>{if(confirm("Encerrar lista?")) acao(l.id,"encerrar","Baixa qualidade");}}>Encerrar</button>}
            </div>
          </div>
        );
      })}
    </div>
  );
}

function EquipeTab({ sb, token, onCriarUsuario }) {
  const [cs,setCs]=useState([]);
  const load=async()=>{ try{setCs(await sb.query("corretores","order=nome.asc",token));}catch(e){} };
  useEffect(()=>{load();},[]);
  return (
    <div className="p-4 space-y-4">
      <div className="flex items-center justify-between"><h2 className="text-lg font-bold text-gray-900">Equipe</h2><button onClick={onCriarUsuario} className="bg-blue-600 text-white text-xs font-semibold px-3 py-2 rounded-xl">+ Novo usuário</button></div>
      <div className="space-y-2">{cs.map(c=>(
        <div key={c.id} className="bg-white rounded-xl p-3 border shadow-sm flex justify-between items-center">
          <div><p className="font-medium text-sm">{c.nome}{c.is_gestor&&<span className="text-xs bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded-full ml-1">Gestor</span>}</p><p className="text-xs text-gray-500">{c.email}</p></div>
          <div className="flex items-center gap-2">
            {c.must_change_password&&<span className="text-xs bg-amber-100 text-amber-700 px-2 py-0.5 rounded-full">Senha provisória</span>}
            <span className={`text-xs px-2 py-1 rounded-full ${c.ativo?"bg-emerald-100 text-emerald-700":"bg-red-100 text-red-700"}`}>{c.ativo?"Ativo":"Inativo"}</span>
          </div>
        </div>
      ))}</div>
    </div>
  );
}

// ─── Login ────────────────────────────────────────────────────────────────────
function LoginScreen({ sb, onLogin }) {
  const [email,setEmail]=useState(""); const [pass,setPass]=useState(""); const [ld,setLd]=useState(false); const [err,setErr]=useState("");
  const go=async()=>{ setLd(true);setErr("");try{onLogin(await sb.signIn(email,pass));}catch(e){setErr(e.message);}setLd(false); };
  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-lg p-6 w-full max-w-sm">
        <div className="text-center mb-6"><div className="w-16 h-16 bg-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-3"><span className="text-white text-3xl font-bold">F</span></div><h1 className="text-xl font-bold text-gray-900">FECH.AI</h1><p className="text-xs text-gray-400 mt-1">Sistema de Vendas · v{APP_VERSION}</p></div>
        {err&&<div className="bg-red-50 text-red-700 text-sm rounded-lg p-3 mb-4">{err}</div>}
        <input className="w-full border border-gray-300 rounded-lg px-3 py-3 mb-3 text-base" placeholder="Email" type="email" value={email} onChange={e=>setEmail(e.target.value)}/>
        <input className="w-full border border-gray-300 rounded-lg px-3 py-3 mb-4 text-base" placeholder="Senha" type="password" value={pass} onChange={e=>setPass(e.target.value)} onKeyDown={e=>e.key==="Enter"&&go()}/>
        <button className="w-full bg-blue-600 text-white rounded-lg py-3 text-base font-medium disabled:opacity-50" disabled={ld||!email||!pass} onClick={go}>{ld?"Entrando...":"Entrar"}</button>
      </div>
    </div>
  );
}

// ─── Apps compostos ───────────────────────────────────────────────────────────
function GestorApp({ sb, token, corretor, onLogout, onVoltar, onCriarUsuario }) {
  const [tab,setTab]=useState("dashboard");
  return (
    <div style={{minHeight:"100vh",paddingBottom:64}}>
      {tab!=="dashboard"&&<Header nome={corretor.nome} isGestor onLogout={onLogout} onHome={onVoltar} showVersion/>}
      {tab==="dashboard"&&(
        <div style={{background:"#0f172a",padding:"12px 16px",display:"flex",alignItems:"center",justifyContent:"space-between",position:"sticky",top:0,zIndex:10,borderBottom:"1px solid #334155"}}>
          <div><span style={{color:"#f1f5f9",fontWeight:700}}>{corretor.nome}</span><span style={{marginLeft:8,fontSize:11,background:"#1e40af",color:"#93c5fd",padding:"2px 8px",borderRadius:12}}>Gestor</span></div>
          <div style={{display:"flex",gap:12}}>
            <button onClick={onVoltar} style={{color:"#94a3b8",fontSize:13,background:"none",border:"none",cursor:"pointer"}}>⌂ Início</button>
            <button onClick={onLogout} style={{color:"#94a3b8",fontSize:13,background:"none",border:"none",cursor:"pointer"}}>Sair</button>
          </div>
        </div>
      )}
      {tab==="dashboard"  &&<DashboardTab  sb={sb} token={token}/>}
      {tab==="upload"     &&<UploadTab     sb={sb} token={token}/>}
      {tab==="distribuir" &&<DistribuirTab sb={sb} token={token}/>}
      {tab==="listas"     &&<ListasTab     sb={sb} token={token}/>}
      {tab==="equipe"     &&<EquipeTab     sb={sb} token={token} onCriarUsuario={onCriarUsuario}/>}
      <div style={{position:"fixed",bottom:0,left:0,right:0,zIndex:20,display:"flex",background:tab==="dashboard"?"#1e293b":"white",borderTop:tab==="dashboard"?"1px solid #334155":"1px solid #e5e7eb"}}>
        {[{id:"dashboard",label:"Dashboard",icon:"◉"},{id:"upload",label:"Upload",icon:"↑"},{id:"distribuir",label:"Distribuir",icon:"→"},{id:"listas",label:"Listas",icon:"★"},{id:"equipe",label:"Equipe",icon:"◇"}].map(t=>(
          <button key={t.id} onClick={()=>setTab(t.id)} style={{flex:1,padding:"10px 0",textAlign:"center",background:"none",border:"none",cursor:"pointer",color:tab===t.id?(tab==="dashboard"?"#38bdf8":"#2563eb"):(tab==="dashboard"?"#64748b":"#9ca3af"),fontWeight:tab===t.id?500:400}}>
            <div style={{fontSize:18}}>{t.icon}</div>
            <div style={{fontSize:11,marginTop:2}}>{t.label}</div>
          </button>
        ))}
      </div>
    </div>
  );
}

function CorretorApp({ sb, token, corretor, onLogout, onVoltar }) {
  const [tab,setTab]=useState("discador");
  return (
    <div className="min-h-screen bg-gray-50 pb-20">
      <Header nome={corretor.nome} isGestor={false} onLogout={onLogout} onHome={onVoltar}/>
      {tab==="discador"  &&<DiscadorTab  sb={sb} token={token} corretor={corretor}/>}
      {tab==="funil"     &&<FunilTab     sb={sb} token={token}/>}
      {tab==="producao"  &&<ProducaoTab  sb={sb} token={token}/>}
      {tab==="carteira"  &&<CarteiraTab  sb={sb} token={token}/>}
      {tab==="historico" &&<HistoricoTab sb={sb} token={token}/>}
      <TabBar
        tabs={[
          {id:"discador", label:"Discador",  icon:"◎"},
          {id:"funil",    label:"Funil",     icon:"▽"},
          {id:"producao", label:"Produção",  icon:"◉"},
          {id:"carteira", label:"Carteira",  icon:"♦"},
          {id:"historico",label:"Histórico", icon:"↺"},
        ]}
        active={tab} onChange={setTab}
      />
    </div>
  );
}

// ─── App raiz ─────────────────────────────────────────────────────────────────
export default function App() {
  const [session,setSession]=useState(null); const [corretor,setCorretor]=useState(null);
  const [loading,setLoading]=useState(true); const [tela,setTela]=useState("home");
  const [sb]=useState(()=>createSB(SUPABASE_URL,SUPABASE_KEY));

  const saveSession=(s)=>{ try{localStorage.setItem("fechai_session",JSON.stringify(s));}catch(e){} };

  useEffect(()=>{
    try{const s=localStorage.getItem("fechai_session");if(s) setSession(JSON.parse(s));}catch(e){}
    setLoading(false);
  },[]);

  useEffect(()=>{
    if(!session?.refresh_token||!session?.expires_at) return;
    const ms=session.expires_at*1000-Date.now()-5*60*1000;
    const doRefresh=()=>sb.refreshToken(session.refresh_token).then(ns=>{setSession(ns);saveSession(ns);}).catch(()=>logout());
    if(ms<=0){doRefresh();return;}
    const t=setTimeout(doRefresh,ms);
    return ()=>clearTimeout(t);
  },[session?.expires_at]);

  useEffect(()=>{
    if(!sb||!session) return;
    (async()=>{
      try{const d=await sb.query("corretores","user_id=eq."+session.user.id+"&select=*",session.access_token);if(d.length>0) setCorretor(d[0]);else logout();}
      catch(e){logout();}
    })();
  },[sb,session?.access_token]);

  const login=(d)=>{setSession(d);setTela("home");saveSession(d);};
  const logout=()=>{setSession(null);setCorretor(null);setTela("home");try{localStorage.removeItem("fechai_session");}catch(e){}};

  if(loading) return <div className="min-h-screen bg-gray-50 flex items-center justify-center text-gray-400 text-lg">Carregando...</div>;
  if(!session) return <LoginScreen sb={sb} onLogin={login}/>;
  if(!corretor) return (<div className="min-h-screen bg-gray-50 flex items-center justify-center p-4"><div className="bg-white rounded-2xl shadow-lg p-6 text-center max-w-sm"><p className="text-gray-700 text-lg">Carregando perfil...</p><button className="mt-4 text-blue-600 text-base" onClick={logout}>Voltar</button></div></div>);

  if(corretor.must_change_password) return (
    <TrocarSenhaObrigatoria sb={sb} token={session.access_token} corretorId={corretor.id}
      onConcluido={()=>setCorretor(c=>({...c,must_change_password:false}))}
    />
  );

  if(tela==="home") return (<HomeActions nome={corretor.nome} isGestor={corretor.is_gestor} onOfertaAtiva={()=>setTela("oferta")} onPainelGestor={()=>setTela("gestor")}/>);
  if(tela==="criar-usuario") return (<CriarUsuario session={session} onUsuarioCriado={()=>setTela("gestor")} onCancelar={()=>setTela("gestor")}/>);
  if(tela==="oferta") return (<CorretorApp sb={sb} token={session.access_token} corretor={corretor} onLogout={logout} onVoltar={()=>setTela("home")}/>);
  if(tela==="gestor"&&corretor.is_gestor) return (<GestorApp sb={sb} token={session.access_token} corretor={corretor} onLogout={logout} onVoltar={()=>setTela("home")} onCriarUsuario={()=>setTela("criar-usuario")}/>);
  return (<HomeActions nome={corretor.nome} isGestor={corretor.is_gestor} onOfertaAtiva={()=>setTela("oferta")} onPainelGestor={()=>setTela("gestor")}/>);
}
