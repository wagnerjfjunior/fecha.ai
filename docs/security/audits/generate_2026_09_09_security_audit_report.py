#!/usr/bin/env python3
"""
Regenerates the FECH.AI 2026-09-09 security-audit presentation PDF from the
canonical structured snapshot in this directory.

Requirements (isolated environment recommended):
  python -m venv .venv
  . .venv/bin/activate
  pip install reportlab matplotlib

This generator is presentation-only. Canonical review inputs remain the
Markdown/live-evidence/WBS files in GitHub.
"""
from pathlib import Path
import json
import matplotlib.pyplot as plt

from reportlab.lib import colors
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image, PageBreak

BASE = Path(__file__).resolve().parent
SNAPSHOT = BASE / "2026-09-09-audit-snapshot.json"
OUT = BASE / "2026-09-09-relatorio-auditoria-seguranca.pdf"
TMP = BASE / ".audit_chart_tmp"
TMP.mkdir(exist_ok=True)

data = json.loads(SNAPSHOT.read_text(encoding="utf-8"))

PALETTE = {
    "CRITICAL": "#B91C1C",
    "HIGH": "#EA580C",
    "MEDIUM": "#D97706",
    "LOW": "#2563EB",
    "STRONG": "#059669",
}

# Charts
sev_order = ["CRITICAL", "HIGH", "MEDIUM", "LOW"]
sev_counts = [sum(1 for f in data["findings"] if f["severity"] == s) for s in sev_order]
items = [(s, n, PALETTE[s]) for s, n in zip(sev_order, sev_counts) if n]
fig, ax = plt.subplots(figsize=(6.2, 4.0))
ax.pie([n for _, n, _ in items],
       labels=[f"{s}: {n}" for s, n, _ in items],
       colors=[c for _, _, c in items],
       startangle=90,
       wedgeprops={"width": 0.42, "edgecolor": "white"})
ax.text(0, 0, str(sum(sev_counts)), ha="center", va="center", fontsize=20, fontweight="bold")
ax.set_title("Achados por severidade")
sev_png = TMP / "severity.png"
fig.tight_layout()
fig.savefig(sev_png, dpi=170, bbox_inches="tight")
plt.close(fig)

cat_counts = {
    "Tenant/DB": 4,
    "Permission": 3,
    "IDOR": 3,
    "Secrets": 0,
    "XSS": 0,
}
fig, ax = plt.subplots(figsize=(7.0, 4.0))
ax.bar(list(cat_counts), list(cat_counts.values()))
ax.set_ylabel("Achados acionaveis")
ax.set_title("Achados por categoria")
ax.tick_params(axis="x", rotation=18)
cat_png = TMP / "categories.png"
fig.tight_layout()
fig.savefig(cat_png, dpi=170, bbox_inches="tight")
plt.close(fig)

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="Small", parent=styles["BodyText"], fontSize=8, leading=10))
styles.add(ParagraphStyle(name="AuditH1", parent=styles["Heading1"], fontSize=17, leading=21))
styles.add(ParagraphStyle(name="AuditBody", parent=styles["BodyText"], fontSize=9.2, leading=13))

def p(text, style="AuditBody"):
    return Paragraph(str(text), styles[style])

def footer(canvas, doc):
    canvas.saveState()
    w, _ = A4
    canvas.setFont("Helvetica", 7)
    canvas.setFillColor(HexColor("#4B5563"))
    canvas.drawString(2 * cm, 0.8 * cm, "FECH.AI - Relatorio de Auditoria de Seguranca")
    canvas.drawRightString(w - 2 * cm, 0.8 * cm, f"Pagina {doc.page}")
    canvas.restoreState()

doc = SimpleDocTemplate(str(OUT), pagesize=A4,
                        leftMargin=1.8*cm, rightMargin=1.8*cm,
                        topMargin=1.8*cm, bottomMargin=1.5*cm,
                        title="Relatorio de Auditoria de Seguranca - FECH.AI")
story = [
    Spacer(1, 2*cm),
    p("Relatorio de Auditoria de Seguranca - FECH.AI", "Title"),
    p("2026-09-09 | Pilot Production | GitHub + Supabase live READ_ONLY"),
    Spacer(1, 0.5*cm),
    p("Escopo: main do FECH.AI, handlers backend/Edge, catalogo Supabase live, RLS, policies, grants, SECURITY DEFINER, constraints, triggers, IDOR, secrets/config e sinks XSS."),
    PageBreak(),
    p("Resumo executivo", "AuditH1"),
    p(f"Achados acionaveis: {len(data['findings'])}. Security Go permanece NOT_GRANTED."),
    Table([[Image(str(sev_png), width=7.2*cm, height=4.6*cm),
            Image(str(cat_png), width=8.2*cm, height=4.6*cm)]],
          colWidths=[7.5*cm, 8.5*cm]),
    Spacer(1, 0.3*cm),
    p("Cobertura live", "AuditH1"),
]

coverage_rows = [["Metrica", "Resultado"]] + [[k, str(v)] for k, v in data["coverage"].items()]
table = Table([[p(a, "Small"), p(b, "Small")] for a,b in coverage_rows],
              colWidths=[7.5*cm, 8.0*cm], repeatRows=1)
table.setStyle(TableStyle([
    ("BACKGROUND",(0,0),(-1,0),HexColor("#111827")),
    ("TEXTCOLOR",(0,0),(-1,0),colors.white),
    ("GRID",(0,0),(-1,-1),0.35,HexColor("#D1D5DB")),
    ("VALIGN",(0,0),(-1,-1),"TOP"),
]))
story.append(table)
story += [PageBreak(), p("Achados e WBS", "AuditH1")]

rows = [["ID","Sev.","Achado","Remediacao WBS","Prova"]]
for f in data["findings"]:
    rows.append([f["id"], f["severity"], f["title"], f["wbs"], f["proof"]])
table = Table([[p(x, "Small") for x in row] for row in rows],
              colWidths=[1.2*cm,1.7*cm,5.7*cm,4.0*cm,3.2*cm], repeatRows=1)
table.setStyle(TableStyle([
    ("BACKGROUND",(0,0),(-1,0),HexColor("#111827")),
    ("TEXTCOLOR",(0,0),(-1,0),colors.white),
    ("GRID",(0,0),(-1,-1),0.35,HexColor("#D1D5DB")),
    ("VALIGN",(0,0),(-1,-1),"TOP"),
]))
story.append(table)

story += [Spacer(1,0.4*cm), p("Finish line", "AuditH1")]
for k,v in data["final_closure_contract"].items():
    story.append(p(f"<b>{k}</b>: {v}"))

story += [Spacer(1,0.3*cm), p("Limites", "AuditH1")]
for x in data["limitations"]:
    story.append(p("- " + x))

doc.build(story, onFirstPage=footer, onLaterPages=footer)

for f in TMP.glob("*"):
    f.unlink()
TMP.rmdir()
print(OUT)
