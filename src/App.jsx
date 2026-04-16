import { useState, useEffect, useCallback, useRef } from "react";
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts";
import Papa from "papaparse";

const SUPABASE_URL = "https://uobxxgzshrmbtjfdolxd.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvYnh4Z3pzaHJtYnRqZmRvbHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjcyOTUsImV4cCI6MjA5MTg0MzI5NX0.0RiMkrtJlGbprp8AqVPXC9Y5LxP6QiELfP7NoYEXJ9w";

const FEEDBACKS = [
  { id: "agendado_visita", label: "Agendou visita", color: "bg-emerald-600", icon: "✓" },
  { id: "enviado_informacoes", label: "Enviou info", color: "bg-blue-600", icon: "ℹ" },
  { id: "retornar_depois", label: "Retornar depois", color: "bg-amber-500", icon: "↻" },
  { id: "nao_responde", label: "Não responde", color: "bg-gray-500", icon: "—" },
  { id: "sem_interesse", label: "Sem interesse", color: "bg-purple-600", icon: "✕" },
  { id: "numero_errado", label: "Número errado", color: "bg-red-600", icon: "!" },
  { id: "caixa_postal", label: "Caixa postal", color: "bg-orange-500", icon: "▶" },
  { id: "nao_toca", label: "Não toca", color: "bg-gray-400", icon: "✗" },
  { id: "lead_ja_atendido", label: "Já atendido", color: "bg-red-400", icon: "⊘" },
];

const COL_ALIASES = {
  nome: ["nome","name","cliente","nome_cliente","nome completo","full_name"],
  email: ["email","e-mail","e_mail","email_address"],
  celular: ["celular","cel","mobile","whatsapp","whats","cell"],
  telefone_1: ["telefone","tel","phone","telefone_1","tel1","fone"],
  telefone_2: ["telefone_2","tel2","telefone 2"],
  fixo: ["fixo","landline","telefone_fixo","residencial","comercial"],
  endereco: ["endereco","endereço","address","end","logradouro"],
};

function getSaudacao() { const h = new Date().getHours(); return h < 12 ? "Bom dia" : h < 18 ? "Boa tarde" : "Boa noite"; }
function getPrimeiroNome(n) { return (n || "").split(" ")[0] || ""; }
function buildWhatsAppLink(lead) {
  if (!lead.telefone_e164) return null;
  const num = lead.telefone_e164.replace("+", "");
  const nome = getPrimeiroNome(lead.nome);
  const msg = encodeURIComponent(`${getSaudacao()}, ${nome}! Tudo bem?\n\nSou corretor(a) e estou entrando em contato sobre seu interesse em imóveis.\nPosso te ajudar com mais informações?`);
  return `https://wa.me/${num}?text=${msg}`;
}

function onlyDigits(s) { return (s || "").replace(/\D/g, ""); }
function parsePhone(raw) {
  if (!raw) return { e164: "", nacional: "", tipo: "", pais: "", ligar: "", whatsapp: "" };
  const c = String(raw).trim(), d = onlyDigits(c);
  if (!d || d.length < 8) return { e164: "", nacional: c, tipo: "desconhecido", pais: "", ligar: "", whatsapp: "" };
  if (c.startsWith("+") && !d.startsWith("55")) return { e164: "+" + d, nacional: c, tipo: "internacional", pais: "outro", ligar: "+" + d, whatsapp: "" };
  if (d.startsWith("55") && d.length >= 12) return classifyBR(d.substring(2));
  if (d.length >= 8 && d.length <= 11) return classifyBR(d);
  return { e164: "", nacional: d, tipo: "desconhecido", pais: "", ligar: "", whatsapp: "" };
}
function classifyBR(d) {
  if (d.length === 8) return { e164: "+5511" + d, nacional: "(11) " + d.substring(0, 4) + "-" + d.substring(4), tipo: "br_fixo", pais: "BR", ligar: "011" + d, whatsapp: "" };
  if (d.length === 9 && d[0] === "9") return { e164: "+5511" + d, nacional: "(11) " + d.substring(0, 5) + "-" + d.substring(5), tipo: "br_celular", pais: "BR", ligar: "011" + d, whatsapp: "https://wa.me/5511" + d };
  if (d.length === 10) { const dd = d.substring(0, 2), n = d.substring(2); return { e164: "+55" + d, nacional: `(${dd}) ${n.substring(0, 4)}-${n.substring(4)}`, tipo: "br_fixo", pais: "BR", ligar: "0" + d, whatsapp: "" }; }
  if (d.length === 11) { const dd = d.substring(0, 2), n = d.substring(2), cel = n[0] === "9"; return { e164: "+55" + d, nacional: `(${dd}) ${cel ? n.substring(0, 5) + "-" + n.substring(5) : n.substring(0, 4) + "-" + n.substring(4)}`, tipo: cel ? "br_celular" : "br_fixo", pais: "BR", ligar: "0" + d, whatsapp: cel ? "https://wa.me/55" + d : "" }; }
  return { e164: "", nacional: d, tipo: "desconhecido", pais: "", ligar: "", whatsapp: "" };
}
function pickBestPhone(r) {
  let best = null;
  for (const raw of [r.celular, r.telefone_1, r.telefone_2, r.fixo].filter(Boolean)) {
    const p = parsePhone(raw);
    if (!p.e164) continue;
    if (!best || (p.tipo === "br_celular" && best.tipo !== "br_celular")) best = p;
  }
  return best || { e164: "", nacional: "", tipo: "", pais: "", ligar: "", whatsapp: "" };
}

function createSB(url, key) {
  const hd = (t) => ({ apikey: key, Authorization: "Bearer " + (t || key), "Content-Type": "application/json" });
  return {
    async signIn(e, p) { const r = await fetch(url + "/auth/v1/token?grant_type=password", { method: "POST", headers: { apikey: key, "Content-Type": "application/json" }, body: JSON.stringify({ email: e, password: p }) }); if (!r.ok) { const x = await r.json(); throw new Error(x.error_description || x.msg || "Erro login"); } return r.json(); },
    async signUp(e, p) { const r = await fetch(url + "/auth/v1/signup", { method: "POST", headers: { apikey: key, "Content-Type": "application/json" }, body: JSON.stringify({ email: e, password: p }) }); if (!r.ok) { const x = await r.json(); throw new Error(x.error_description || x.msg || "Erro cadastro"); } return r.json(); },
    async query(t, p, tk) { const r = await fetch(url + "/rest/v1/" + t + "?" + (p || ""), { headers: hd(tk) }); if (!r.ok) throw new Error("Erro " + t); return r.json(); },
    async insert(t, d, tk) { const r = await fetch(url + "/rest/v1/" + t, { method: "POST", headers: { ...hd(tk), Prefer: "return=representation" }, body: JSON.stringify(d) }); if (!r.ok) { const x = await r.json(); throw new Error(x.message || "Erro insert"); } return r.json(); },
    async rpc(f, a, tk) { const r = await fetch(url + "/rest/v1/rpc/" + f, { method: "POST", headers: hd(tk), body: JSON.stringify(a || {}) }); if (!r.ok) { const x = await r.json(); throw new Error(x.message || "Erro " + f); } return r.json(); },
  };
}

function detectColumns(h) {
  const m = {}, nr = h.map(x => String(x || "").toLowerCase().trim().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/\s+/g, "_"));
  for (const [f, al] of Object.entries(COL_ALIASES)) { const i = nr.findIndex(x => al.some(a => x === a || x.includes(a))); if (i >= 0) m[f] = i; }
  return m;
}
function csvToLead(row, cm, forn) {
  const g = (f) => cm[f] !== undefined ? String(row[cm[f]] || "").trim() : "";
  const ph = pickBestPhone({ celular: g("celular"), telefone_1: g("telefone_1"), telefone_2: g("telefone_2"), fixo: g("fixo") });
  return { nome: g("nome"), email: g("email"), endereco: g("endereco"), telefone_origem_1: g("telefone_1") || g("celular") || "", telefone_origem_2: g("telefone_2") || g("fixo") || "", telefone_escolhido: ph.nacional, telefone_e164: ph.e164, tipo_telefone: ph.tipo, pais_telefone: ph.pais, ligar: ph.ligar, whatsapp: ph.whatsapp, fornecedor: forn };
}

function KPI({ label, value, color = "text-gray-900", sub }) {
  return (<div className="bg-white rounded-xl p-3 shadow-sm border border-gray-100"><div className="text-xs text-gray-500 uppercase tracking-wide">{label}</div><div className={`text-2xl font-bold mt-1 ${color}`}>{value}</div>{sub && <div className="text-xs text-gray-400 mt-1">{sub}</div>}</div>);
}
function Header({ nome, isGestor, onLogout }) {
  return (<div className="bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between sticky top-0 z-10"><div><span className="font-bold text-gray-900 text-sm">{nome}</span><span className="ml-2 text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full">{isGestor ? "Gestor" : "Corretor"}</span></div><button className="text-xs text-gray-400 hover:text-red-500" onClick={onLogout}>Sair</button></div>);
}
function TabBar({ tabs, active, onChange }) {
  return (<div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 flex z-20">{tabs.map(t => (<button key={t.id} className={`flex-1 py-3 text-center ${active === t.id ? "text-blue-600 font-medium" : "text-gray-400"}`} onClick={() => onChange(t.id)}><div className="text-lg">{t.icon}</div><div className="text-xs mt-0.5">{t.label}</div></button>))}</div>);
}
function Stars({ value, onChange }) {
  return (<div className="flex gap-1 justify-center">{[1, 2, 3, 4, 5].map(n => (<button key={n} className={`text-3xl ${n <= value ? "text-amber-400" : "text-gray-300"}`} onClick={() => onChange?.(n)}>{n <= value ? "★" : "☆"}</button>))}</div>);
}

function LoginScreen({ sb, onLogin }) {
  const [email, setEmail] = useState(""); const [pass, setPass] = useState(""); const [ld, setLd] = useState(false); const [err, setErr] = useState("");
  const go = async () => { setLd(true); setErr(""); try { onLogin(await sb.signIn(email, pass)); } catch (e) { setErr(e.message); } setLd(false); };
  return (<div className="min-h-screen bg-gray-50 flex items-center justify-center p-4"><div className="bg-white rounded-2xl shadow-lg p-6 w-full max-w-sm"><div className="text-center mb-6"><div className="w-16 h-16 bg-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-3"><span className="text-white text-3xl font-bold">F</span></div><h1 className="text-xl font-bold text-gray-900">FECH.AI</h1><p className="text-xs text-gray-400 mt-1">Sistema de Vendas</p></div>{err && <div className="bg-red-50 text-red-700 text-sm rounded-lg p-3 mb-4">{err}</div>}<input className="w-full border border-gray-300 rounded-lg px-3 py-3 mb-3 text-sm" placeholder="Email" type="email" value={email} onChange={e => setEmail(e.target.value)} /><input className="w-full border border-gray-300 rounded-lg px-3 py-3 mb-4 text-sm" placeholder="Senha" type="password" value={pass} onChange={e => setPass(e.target.value)} onKeyDown={e => e.key === "Enter" && go()} /><button className="w-full bg-blue-600 text-white rounded-lg py-3 font-medium disabled:opacity-50" disabled={ld || !email || !pass} onClick={go}>{ld ? "Entrando..." : "Entrar"}</button></div></div>);
}

function DiscadorTab({ sb, token }) {
  const [lead, setLead] = useState(null); const [prog, setProg] = useState(null); const [msg, setMsg] = useState("");
  const [ld, setLd] = useState(true); const [fld, setFld] = useState(false); const [showObs, setShowObs] = useState(false);
  const [obs, setObs] = useState(""); const [selFb, setSelFb] = useState(null); const [loteDone, setLoteDone] = useState(false);
  const [showRate, setShowRate] = useState(false); const [rateNote, setRateNote] = useState(0); const [lastListaId, setLastListaId] = useState(null);

  const loadNext = useCallback(async () => {
    setLd(true); setLoteDone(false);
    try { const r = await sb.rpc("proximo_lead", {}, token); const l = r.lead ? (typeof r.lead === "string" ? JSON.parse(r.lead) : r.lead) : null; setLead(l); setProg(r.progresso || null); setMsg(r.message || ""); if (l) setLastListaId(l.lista_id); } catch (e) { setMsg(e.message); }
    setLd(false);
  }, [sb, token]);
  useEffect(() => { loadNext(); }, [loadNext]);

  const handleFb = (id) => { setSelFb(id); setShowObs(true); };
  const submitFb = async () => {
    setFld(true);
    try {
      const r = await sb.rpc("registrar_feedback", { p_lead_id: lead.id, p_feedback: selFb, p_observacao: obs || "" }, token);
      if (r.error) throw new Error(r.error);
      setObs(""); setShowObs(false); setSelFb(null);
      if (r.lote_fechado) { setLoteDone(true); setShowRate(true); } else { loadNext(); }
    } catch (e) { setMsg(e.message); setShowObs(false); }
    setFld(false);
  };
  const submitRate = async () => {
    if (rateNote > 0 && lastListaId) { try { await sb.rpc("avaliar_lista", { p_lista_id: lastListaId, p_nota: rateNote }, token); } catch (e) { console.error(e); } }
    setShowRate(false); setRateNote(0); loadNext();
  };

  if (ld) return <div className="flex items-center justify-center h-64 text-gray-400">Carregando...</div>;

  if (showRate) return (
    <div className="p-4"><div className="bg-white rounded-2xl shadow-md p-6 border text-center">
      <div className="text-5xl mb-3">🎉</div><p className="font-bold text-emerald-800 text-lg mb-1">Lote completo!</p>
      <p className="text-sm text-gray-600 mb-5">Como você avalia a qualidade dessa lista?</p>
      <div className="mb-5"><Stars value={rateNote} onChange={setRateNote} /></div>
      <button className="w-full bg-blue-600 text-white rounded-xl py-3 font-medium" onClick={submitRate}>{rateNote > 0 ? "Enviar avaliação" : "Pular"}</button>
    </div></div>
  );

  if (!lead && !loteDone) return (
    <div className="flex flex-col items-center justify-center h-64 px-4"><div className="text-5xl text-gray-300 mb-4">◎</div><p className="text-gray-500 text-center">{msg || "Sem leads no momento."}</p><button className="mt-4 text-blue-600 text-sm font-medium" onClick={loadNext}>Verificar novamente</button></div>
  );

  if (showObs) return (
    <div className="p-4"><div className="bg-white rounded-2xl shadow-md p-5 border">
      <h3 className="font-bold text-gray-900 mb-1">{FEEDBACKS.find(f => f.id === selFb)?.label}</h3>
      <p className="text-sm text-gray-500 mb-4">{lead?.nome}</p>
      <textarea className="w-full border border-gray-300 rounded-lg px-3 py-3 text-sm resize-none" rows={3} placeholder="Observação (opcional)" value={obs} onChange={e => setObs(e.target.value)} />
      <div className="flex gap-3 mt-4"><button className="flex-1 bg-gray-200 text-gray-700 rounded-xl py-3 font-medium" onClick={() => { setShowObs(false); setSelFb(null); setObs(""); }}>Voltar</button><button className="flex-1 bg-blue-600 text-white rounded-xl py-3 font-medium disabled:opacity-50" disabled={fld} onClick={submitFb}>{fld ? "Salvando..." : "Confirmar"}</button></div>
    </div></div>
  );

  return (
    <div className="p-4 space-y-4">
      {prog && (<div><div className="flex justify-between text-xs text-gray-500 mb-1"><span>Lote</span><span className="font-medium">{prog.feitos}/{prog.total}</span></div><div className="w-full bg-gray-200 rounded-full h-3"><div className="bg-blue-600 h-3 rounded-full transition-all" style={{ width: (prog.feitos / prog.total * 100) + "%" }} /></div></div>)}
      {lead && (<div className="bg-white rounded-2xl shadow-md p-5 border border-gray-100">
        <h2 className="text-xl font-bold text-gray-900">{lead.nome || "Sem nome"}</h2>
        {lead.email && <p className="text-sm text-gray-500 mt-1">{lead.email}</p>}
        {lead.endereco && <p className="text-sm text-gray-400 mt-1">{lead.endereco}</p>}
        <div className="mt-4 bg-gray-50 rounded-xl p-3"><p className="text-lg font-mono font-bold text-gray-900">{lead.telefone_escolhido || lead.telefone_e164 || "—"}</p><p className="text-xs text-gray-500 mt-1">{lead.tipo_telefone} · {lead.pais_telefone}</p></div>
        <div className="flex gap-3 mt-4">
          {lead.ligar && <a href={"tel:" + lead.ligar} className="flex-1 bg-blue-600 text-white rounded-xl py-4 text-center font-bold text-lg no-underline">Ligar</a>}
          {lead.telefone_e164 && lead.tipo_telefone === "br_celular" && <a href={buildWhatsAppLink(lead)} target="_blank" rel="noopener noreferrer" className="flex-1 bg-emerald-600 text-white rounded-xl py-4 text-center font-bold text-lg no-underline">WhatsApp</a>}
        </div>
      </div>)}
      <div><p className="text-xs text-gray-500 uppercase tracking-wide mb-2">Feedback</p><div className="grid grid-cols-2 gap-2">{FEEDBACKS.map(f => (<button key={f.id} className={`${f.color} text-white rounded-xl py-3.5 px-3 text-sm font-medium text-left`} onClick={() => handleFb(f.id)}><span className="mr-1">{f.icon}</span> {f.label}</button>))}</div></div>
    </div>
  );
}

function ProducaoTab({ sb, token }) {
  const [data, setData] = useState(null); const [ld, setLd] = useState(true);
  useEffect(() => { (async () => { try { setData(await sb.rpc("minha_producao", {}, token)); } catch (e) { console.error(e); } setLd(false); })(); }, []);
  if (ld) return <div className="p-4 text-center text-gray-400">Carregando...</div>;
  if (!data || data.error) return <div className="p-4 text-center text-red-500">Erro ao carregar</div>;
  const hoje = data.hoje || {}; const semana = data.semana || []; const totais = data.totais || {};
  const chartData = semana.map(d => ({ dia: new Date(d.dia).toLocaleDateString("pt-BR", { weekday: "short" }), total: d.total, visitas: d.visitas }));
  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-bold text-gray-900">Minha produção</h2>
      <div className="grid grid-cols-3 gap-2">
        <KPI label="Hoje" value={hoje.total || 0} />
        <KPI label="Visitas" value={hoje.visitas || 0} color="text-emerald-600" />
        <KPI label="Errados" value={hoje.errados || 0} color="text-red-500" />
      </div>
      <div className="grid grid-cols-3 gap-2">
        <KPI label="Recebidos" value={totais.total_recebidos || 0} />
        <KPI label="Com feedback" value={totais.com_feedback || 0} />
        <KPI label="Carteira" value={totais.em_carteira || 0} color="text-blue-600" />
      </div>
      {chartData.length > 0 && (
        <div className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
          <p className="text-xs text-gray-500 uppercase mb-2">Últimos 7 dias</p>
          <ResponsiveContainer width="100%" height={160}>
            <BarChart data={chartData}><XAxis dataKey="dia" tick={{ fontSize: 11 }} /><YAxis tick={{ fontSize: 11 }} width={28} /><Tooltip /><Bar dataKey="total" fill="#3b82f6" radius={[4, 4, 0, 0]} /><Bar dataKey="visitas" fill="#10b981" radius={[4, 4, 0, 0]} /></BarChart>
          </ResponsiveContainer>
        </div>
      )}
      {data.com_observacao?.length > 0 && (
        <div><p className="text-sm font-bold text-gray-700 mb-2">Com observação</p><div className="space-y-2">{data.com_observacao.slice(0, 10).map((l, i) => (
          <div key={i} className="bg-white rounded-xl p-3 border border-gray-100 shadow-sm">
            <div className="flex justify-between"><span className="font-medium text-sm text-gray-900">{l.nome}</span><span className="text-xs text-gray-400">{l.feedback}</span></div>
            <p className="text-xs text-gray-600 mt-1">{l.observacao}</p>
          </div>
        ))}</div></div>
      )}
    </div>
  );
}

function CarteiraTab({ sb, token }) {
  const [data, setData] = useState(null); const [ld, setLd] = useState(true);
  useEffect(() => { (async () => { try { setData(await sb.rpc("minha_producao", {}, token)); } catch (e) { console.error(e); } setLd(false); })(); }, []);
  if (ld) return <div className="p-4 text-center text-gray-400">Carregando...</div>;
  const cart = data?.carteira || [];
  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-bold text-gray-900">Minha carteira <span className="text-sm font-normal text-gray-500">({cart.length})</span></h2>
      {cart.length === 0 && <p className="text-sm text-gray-500">Nenhum lead em carteira ainda. Leads com feedback "agendou visita", "enviou info" ou "retornar depois" entram aqui automaticamente.</p>}
      <div className="space-y-2">{cart.map((l, i) => {
        const leadForWpp = { ...l, telefone_e164: (l.telefone || "").replace(/\D/g, "").length === 11 ? "+55" + (l.telefone || "").replace(/\D/g, "") : "" };
        return (
          <div key={i} className="bg-white rounded-xl p-3 border border-gray-100 shadow-sm">
            <div className="flex justify-between items-start"><div><p className="font-medium text-sm text-gray-900">{l.nome}</p><p className="text-xs text-gray-500 mt-0.5">{l.telefone} · {l.feedback}</p></div>
              <div className="flex gap-1">
                {l.telefone && <a href={"tel:" + l.telefone} className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded-lg no-underline">Ligar</a>}
                {l.whatsapp && <a href={buildWhatsAppLink(leadForWpp)} target="_blank" rel="noopener noreferrer" className="text-xs bg-emerald-100 text-emerald-700 px-2 py-1 rounded-lg no-underline">Zap</a>}
              </div>
            </div>
            {l.observacao && <p className="text-xs text-gray-600 mt-2 bg-gray-50 rounded p-2">{l.observacao}</p>}
          </div>
        );
      })}</div>
    </div>
  );
}

function UploadTab({ sb, token }) {
  const [file, setFile] = useState(null); const [forn, setForn] = useState(""); const [preview, setPreview] = useState(null);
  const [colMap, setColMap] = useState(null); const [importing, setImporting] = useState(false); const [result, setResult] = useState(null);
  const fileRef = useRef();
  const handleFile = (f) => { if (!f) return; setFile(f); setResult(null); Papa.parse(f, { header: false, skipEmptyLines: true, complete: (res) => { if (res.data.length < 2) return; if (res.data.length > 5001) { setResult({ error: "Arquivo muito grande (máx 5000 leads)" }); return; } const det = detectColumns(res.data[0]); setColMap(det); setPreview({ headers: res.data[0], rows: res.data.slice(1), detected: det }); } }); };
  const handleImport = async () => {
    if (!preview || !forn || !colMap) return; setImporting(true); setResult(null);
    try {
      const lr = await sb.insert("listas", { nome_fornecedor: forn, nome_arquivo: file.name }, token); const lid = lr[0].id;
      const leads = preview.rows.map(r => csvToLead(r, colMap, forn)); const B = 100; let tot = { validos: 0, invalidos: 0, duplicados: 0 };
      for (let i = 0; i < leads.length; i += B) { const r = await sb.rpc("importar_leads_batch", { p_lista_id: lid, p_leads: leads.slice(i, i + B) }, token); tot.validos += (r.validos || 0); tot.invalidos += (r.invalidos || 0); tot.duplicados += (r.duplicados || 0); }
      setResult(tot); setPreview(null); setFile(null); setForn("");
    } catch (e) { setResult({ error: e.message }); } setImporting(false);
  };
  const det = colMap ? Object.entries(colMap).map(([k, v]) => `${k}:col${v + 1}`).join(" · ") : "";
  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-bold text-gray-900">Upload de lista</h2>
      {!preview ? (<div><input className="w-full border border-gray-300 rounded-lg px-3 py-3 mb-3 text-sm" placeholder="Nome do fornecedor (ex: Meta Ads)" value={forn} onChange={e => setForn(e.target.value)} />
        <div className="border-2 border-dashed border-gray-300 rounded-xl p-8 text-center cursor-pointer hover:border-blue-400" onClick={() => fileRef.current?.click()}><div className="text-4xl text-gray-300 mb-2">↑</div><p className="text-sm text-gray-500">Toque para selecionar CSV</p><p className="text-xs text-gray-400 mt-1">Máx 5.000 leads</p></div>
        <input ref={fileRef} type="file" accept=".csv,.txt,.tsv" className="hidden" onChange={e => handleFile(e.target.files[0])} /></div>
      ) : (<div>
        <div className="bg-blue-50 rounded-lg p-3 mb-3"><p className="text-sm font-medium text-blue-900">{file?.name} · {preview.rows.length} leads</p>{det && <p className="text-xs text-blue-600 mt-1">{det}</p>}</div>
        <div className="bg-gray-50 rounded-lg p-3 mb-3">{preview.rows.slice(0, 3).map((r, i) => { const l = csvToLead(r, colMap, forn); return <div key={i} className="bg-white rounded p-2 mb-1 text-xs border">{l.nome || "—"} | {l.telefone_escolhido || "sem tel"} | {l.tipo_telefone}{l.whatsapp ? " | WA✓" : ""}</div>; })}</div>
        {!forn && <input className="w-full border rounded-lg px-3 py-3 mb-3 text-sm" placeholder="Nome do fornecedor" value={forn} onChange={e => setForn(e.target.value)} />}
        <div className="flex gap-2"><button className="flex-1 bg-gray-200 text-gray-700 rounded-lg py-3 font-medium" onClick={() => { setPreview(null); setFile(null); }}>Cancelar</button><button className="flex-1 bg-blue-600 text-white rounded-lg py-3 font-medium disabled:opacity-50" disabled={importing || !forn} onClick={handleImport}>{importing ? "Importando..." : "Importar"}</button></div>
      </div>)}
      {result && !result.error && <div className="bg-emerald-50 rounded-xl p-4 border border-emerald-200"><p className="font-bold text-emerald-800">Concluído</p><p className="text-sm text-emerald-700 mt-1">{result.validos} válidos · {result.invalidos} inválidos · {result.duplicados} duplicados</p></div>}
      {result?.error && <div className="bg-red-50 rounded-xl p-4 text-red-700 text-sm">{result.error}</div>}
    </div>
  );
}

function DistribuirTab({ sb, token }) {
  const [ld, setLd] = useState(false); const [result, setResult] = useState(null); const [st, setSt] = useState(null);
  const load = async () => { try { const d = await sb.query("leads", "status=eq.disponivel&select=id", token); const a = await sb.query("lotes", "status=eq.aberto&select=id", token); const c = await sb.query("corretores", "ativo=eq.true&select=id", token); setSt({ d: d.length, a: a.length, c: c.length }); } catch (e) {} };
  useEffect(() => { load(); }, []);
  const go = async () => { setLd(true); setResult(null); try { setResult(await sb.rpc("distribuir_lotes", {}, token)); load(); } catch (e) { setResult({ error: e.message }); } setLd(false); };
  return (<div className="p-4 space-y-4"><h2 className="text-lg font-bold text-gray-900">Distribuir lotes</h2>{st && <div className="grid grid-cols-3 gap-3"><KPI label="Disponíveis" value={st.d} color="text-blue-600" /><KPI label="Lotes abertos" value={st.a} color="text-amber-600" /><KPI label="Corretores" value={st.c} color="text-emerald-600" /></div>}<div className="bg-gray-50 rounded-xl p-4 text-sm text-gray-600"><p>Cria lotes de <strong>25 leads</strong> para cada corretor ativo sem lote aberto.</p></div><button className="w-full bg-blue-600 text-white rounded-xl py-4 font-bold text-lg disabled:opacity-50" disabled={ld} onClick={go}>{ld ? "Distribuindo..." : "Distribuir agora"}</button>{result && !result.error && <div className="bg-emerald-50 rounded-xl p-4 border border-emerald-200"><p className="font-bold text-emerald-800">{result.lotes_criados} lote(s) criado(s)</p></div>}{result?.error && <div className="bg-red-50 rounded-xl p-4 text-red-700 text-sm">{result.error}</div>}</div>);
}

function DashboardTab({ sb, token }) {
  const [s, setS] = useState(null); const [ld, setLd] = useState(true);
  const load = async () => { setLd(true); try { setS(await sb.rpc("get_dashboard_stats", {}, token)); } catch (e) {} setLd(false); };
  useEffect(() => { load(); }, []);
  if (ld) return <div className="p-4 text-center text-gray-400">Carregando...</div>;
  if (!s) return <div className="p-4 text-center text-red-500">Erro</div>;
  const fb = s.feedbacks || {}; const pc = s.por_corretor || []; const pf = s.por_fornecedor || [];
  const totFb = Object.values(fb).reduce((a, b) => a + b, 0);
  const txVis = totFb > 0 ? ((fb.agendado_visita || 0) / totFb * 100).toFixed(1) : "0";
  return (
    <div className="p-4 space-y-4">
      <div className="flex items-center justify-between"><h2 className="text-lg font-bold text-gray-900">Dashboard</h2><button className="text-xs text-blue-600" onClick={load}>Atualizar</button></div>
      <div className="grid grid-cols-2 gap-3"><KPI label="Total leads" value={s.total_leads} /><KPI label="Disponíveis" value={s.disponiveis} color="text-blue-600" /><KPI label="Em atendimento" value={s.distribuidos} color="text-amber-600" /><KPI label="Finalizados" value={s.finalizados} color="text-emerald-600" /><KPI label="Em carteira" value={s.em_carteira || 0} color="text-purple-600" /><KPI label="Taxa visita" value={txVis + "%"} color="text-emerald-600" /></div>
      {pc.length > 0 && (<div><h3 className="text-sm font-bold text-gray-700 mb-2">Por corretor</h3><div className="space-y-2">{pc.map((c, i) => (<div key={i} className="bg-white rounded-xl p-3 border border-gray-100 shadow-sm"><div className="flex justify-between items-center"><span className="font-medium text-sm">{c.nome}</span><span className="text-xs text-emerald-600 font-bold">{c.taxa_visita || 0}%</span></div><div className="flex gap-3 mt-1 text-xs text-gray-500"><span>{c.total_leads} leads</span><span className="text-emerald-600">{c.visitas} vis</span><span className="text-red-500">{c.numero_errado} err</span><span className="text-purple-600">{c.em_carteira || 0} cart</span></div>{c.total_leads > 0 && <div className="w-full bg-gray-100 rounded-full h-2 mt-2"><div className="bg-emerald-500 h-2 rounded-full" style={{ width: Math.min(100, (c.com_feedback / c.total_leads) * 100) + "%" }} /></div>}</div>))}</div></div>)}
      {pf.length > 0 && (<div><h3 className="text-sm font-bold text-gray-700 mb-2">Qualidade por fornecedor</h3><div className="space-y-2">{pf.map((f, i) => (<div key={i} className="bg-white rounded-xl p-3 border border-gray-100 shadow-sm"><div className="flex justify-between items-center"><div><span className="font-medium text-sm">{f.fornecedor}</span>{f.nota_media > 0 && <span className="ml-2 text-xs text-amber-500">★ {f.nota_media}</span>}<span className={`ml-2 text-xs px-1.5 py-0.5 rounded-full ${f.status_lista === "ativa" ? "bg-emerald-100 text-emerald-700" : f.status_lista === "pausada" ? "bg-amber-100 text-amber-700" : "bg-red-100 text-red-700"}`}>{f.status_lista}</span></div><span className="text-xs text-red-500 font-medium">{f.taxa_erro || 0}% erro</span></div><div className="flex gap-3 mt-1 text-xs text-gray-500"><span>{f.total} leads</span><span className="text-emerald-600">{f.visitas} vis ({f.taxa_visita || 0}%)</span><span className="text-red-500">{f.errados} err</span></div></div>))}</div></div>)}
    </div>
  );
}

function ListasTab({ sb, token }) {
  const [listas, setListas] = useState([]); const [report, setReport] = useState(null);
  const load = async () => { try { setListas(await sb.query("listas", "order=created_at.desc", token)); } catch (e) {} };
  useEffect(() => { load(); }, []);
  const acao = async (id, a, m) => { try { await sb.rpc("gerenciar_lista", { p_lista_id: id, p_acao: a, p_motivo: m || "" }, token); load(); } catch (e) { alert(e.message); } };
  const verRelatorio = async (id) => { try { setReport(await sb.rpc("relatorio_fornecedor", { p_lista_id: id }, token)); } catch (e) { alert(e.message); } };

  if (report) return (
    <div className="p-4 space-y-4">
      <div className="flex justify-between items-center"><h2 className="text-lg font-bold text-gray-900">Relatório</h2><button className="text-xs text-blue-600" onClick={() => setReport(null)}>Voltar</button></div>
      <div className="bg-white rounded-xl p-4 border shadow-sm">
        <p className="font-bold text-gray-900">{report.lista?.fornecedor}</p><p className="text-xs text-gray-500">{report.lista?.arquivo} · {report.lista?.status} · ★ {report.lista?.nota_media || "—"}</p>
        <div className="grid grid-cols-2 gap-2 mt-3">
          <div className="text-xs"><span className="text-gray-500">Total:</span> <span className="font-medium">{report.numeros?.total}</span></div>
          <div className="text-xs"><span className="text-gray-500">Válidos:</span> <span className="font-medium">{report.numeros?.validos}</span></div>
          <div className="text-xs"><span className="text-gray-500">Taxa contato:</span> <span className="font-medium text-emerald-600">{report.numeros?.taxa_contato_pct || 0}%</span></div>
          <div className="text-xs"><span className="text-gray-500">Taxa erro:</span> <span className="font-medium text-red-500">{report.numeros?.taxa_erro_pct || 0}%</span></div>
          <div className="text-xs"><span className="text-gray-500">Visitas:</span> <span className="font-medium text-emerald-600">{report.numeros?.agendado_visita} ({report.numeros?.taxa_visita_pct || 0}%)</span></div>
          <div className="text-xs"><span className="text-gray-500">Nº errado:</span> <span className="font-medium text-red-500">{report.numeros?.numero_errado}</span></div>
        </div>
      </div>
      {report.avaliacoes?.length > 0 && (<div><p className="text-sm font-bold text-gray-700 mb-2">Avaliações</p>{report.avaliacoes.map((a, i) => (<div key={i} className="bg-white rounded-lg p-3 border mb-2"><div className="flex justify-between"><span className="text-sm font-medium">{a.corretor}</span><div className="flex gap-0.5">{[1,2,3,4,5].map(n => <span key={n} className={n <= a.nota ? "text-amber-400" : "text-gray-300"}>★</span>)}</div></div>{a.comentario && <p className="text-xs text-gray-500 mt-1">{a.comentario}</p>}</div>))}</div>)}
    </div>
  );

  return (
    <div className="p-4 space-y-4">
      <h2 className="text-lg font-bold text-gray-900">Listas de leads</h2>
      {listas.length === 0 && <p className="text-sm text-gray-500">Nenhuma lista importada ainda.</p>}
      {listas.map(l => (
        <div key={l.id} className="bg-white rounded-xl p-4 border border-gray-100 shadow-sm">
          <div className="flex justify-between items-start"><div><p className="font-medium text-sm text-gray-900">{l.nome_fornecedor}</p><p className="text-xs text-gray-500">{l.nome_arquivo} · {new Date(l.created_at).toLocaleDateString("pt-BR")}</p><p className="text-xs text-gray-500 mt-0.5">{l.total_leads} leads ({l.leads_validos} válidos) {l.nota_media > 0 ? `· ★ ${l.nota_media}` : ""}</p></div>
            <span className={`text-xs px-2 py-1 rounded-full font-medium ${l.status === "ativa" ? "bg-emerald-100 text-emerald-700" : l.status === "pausada" ? "bg-amber-100 text-amber-700" : "bg-red-100 text-red-700"}`}>{l.status}</span>
          </div>
          <div className="flex gap-2 mt-3 flex-wrap">
            <button className="text-xs bg-gray-100 text-gray-700 px-3 py-1.5 rounded-lg" onClick={() => verRelatorio(l.id)}>Relatório</button>
            {l.status === "ativa" && <button className="text-xs bg-amber-100 text-amber-700 px-3 py-1.5 rounded-lg" onClick={() => acao(l.id, "pausar")}>Pausar</button>}
            {l.status === "pausada" && <button className="text-xs bg-emerald-100 text-emerald-700 px-3 py-1.5 rounded-lg" onClick={() => acao(l.id, "reativar")}>Reativar</button>}
            {l.status !== "encerrada" && <button className="text-xs bg-red-100 text-red-700 px-3 py-1.5 rounded-lg" onClick={() => { if (confirm("Encerrar lista? Leads disponíveis serão invalidados.")) acao(l.id, "encerrar", "Baixa qualidade"); }}>Encerrar</button>}
          </div>
        </div>
      ))}
    </div>
  );
}

function EquipeTab({ sb, token }) {
  const [cs, setCs] = useState([]);
  const load = async () => { try { setCs(await sb.query("corretores", "order=nome.asc", token)); } catch (e) {} };
  useEffect(() => { load(); }, []);
  return (<div className="p-4 space-y-4"><h2 className="text-lg font-bold text-gray-900">Equipe</h2>
    <div className="space-y-2">{cs.map(c => (<div key={c.id} className="bg-white rounded-xl p-3 border shadow-sm flex justify-between items-center"><div><p className="font-medium text-sm">{c.nome} {c.is_gestor && <span className="text-xs bg-blue-100 text-blue-700 px-1.5 py-0.5 rounded-full ml-1">Gestor</span>}</p><p className="text-xs text-gray-500">{c.email}</p></div><span className={`text-xs px-2 py-1 rounded-full ${c.ativo ? "bg-emerald-100 text-emerald-700" : "bg-red-100 text-red-700"}`}>{c.ativo ? "Ativo" : "Inativo"}</span></div>))}</div>
    <p className="text-xs text-gray-400 text-center">Para adicionar novos corretores, cadastre no Supabase Auth e insira na tabela corretores.</p>
  </div>);
}

function GestorApp({ sb, token, corretor, onLogout }) {
  const [tab, setTab] = useState("dashboard");
  return (<div className="min-h-screen bg-gray-50 pb-20"><Header nome={corretor.nome} isGestor onLogout={onLogout} />
    {tab === "dashboard" && <DashboardTab sb={sb} token={token} />}
    {tab === "upload" && <UploadTab sb={sb} token={token} />}
    {tab === "distribuir" && <DistribuirTab sb={sb} token={token} />}
    {tab === "listas" && <ListasTab sb={sb} token={token} />}
    {tab === "equipe" && <EquipeTab sb={sb} token={token} />}
    <TabBar tabs={[{ id: "dashboard", label: "Dashboard", icon: "◉" }, { id: "upload", label: "Upload", icon: "↑" }, { id: "distribuir", label: "Distribuir", icon: "→" }, { id: "listas", label: "Listas", icon: "★" }, { id: "equipe", label: "Equipe", icon: "◇" }]} active={tab} onChange={setTab} />
  </div>);
}

function CorretorApp({ sb, token, corretor, onLogout }) {
  const [tab, setTab] = useState("discador");
  return (<div className="min-h-screen bg-gray-50 pb-20"><Header nome={corretor.nome} isGestor={false} onLogout={onLogout} />
    {tab === "discador" && <DiscadorTab sb={sb} token={token} corretor={corretor} />}
    {tab === "producao" && <ProducaoTab sb={sb} token={token} />}
    {tab === "carteira" && <CarteiraTab sb={sb} token={token} />}
    <TabBar tabs={[{ id: "discador", label: "Discador", icon: "◎" }, { id: "producao", label: "Produção", icon: "◉" }, { id: "carteira", label: "Carteira", icon: "♦" }]} active={tab} onChange={setTab} />
  </div>);
}

export default function App() {
  const [session, setSession] = useState(null);
  const [corretor, setCorretor] = useState(null);
  const [loading, setLoading] = useState(true);
  const [sb] = useState(() => createSB(SUPABASE_URL, SUPABASE_KEY));

  useEffect(() => {
    try { const s = localStorage.getItem("fechai_session"); if (s) setSession(JSON.parse(s)); } catch (e) {}
    setLoading(false);
  }, []);

  useEffect(() => { if (!sb || !session) return; (async () => { try { const d = await sb.query("corretores", "user_id=eq." + session.user.id + "&select=*", session.access_token); if (d.length > 0) setCorretor(d[0]); else setSession(null); } catch (e) { setSession(null); } })(); }, [sb, session]);

  const login = (d) => { setSession(d); try { localStorage.setItem("fechai_session", JSON.stringify(d)); } catch (e) {} };
  const logout = () => { setSession(null); setCorretor(null); try { localStorage.removeItem("fechai_session"); } catch (e) {} };

  if (loading) return <div className="min-h-screen bg-gray-50 flex items-center justify-center text-gray-400">Carregando...</div>;
  if (!session) return <LoginScreen sb={sb} onLogin={login} />;
  if (!corretor) return <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4"><div className="bg-white rounded-2xl shadow-lg p-6 text-center max-w-sm"><p className="text-gray-700 mb-2">Carregando perfil...</p><button className="mt-4 text-blue-600 text-sm font-medium" onClick={logout}>Voltar</button></div></div>;
  if (corretor.is_gestor) return <GestorApp sb={sb} token={session.access_token} corretor={corretor} onLogout={logout} />;
  return <CorretorApp sb={sb} token={session.access_token} corretor={corretor} onLogout={logout} />;
}
