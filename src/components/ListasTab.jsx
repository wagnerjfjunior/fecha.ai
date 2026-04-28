// ListasTab.jsx
// Upload de CSV/XLS/TXT, validação de campos, score automático, avaliação manual
// Hierarquia: Root(0) → Admin(1) → Gestor(2) → Corretor(3)

import { useState, useEffect, useCallback, useRef } from 'react'

const C = {
  bg:      '#0f172a',
  card:    '#1e293b',
  card2:   '#162032',
  border:  '#334155',
  text:    '#f1f5f9',
  muted:   '#94a3b8',
  accent:  '#2563eb',
  green:   '#10b981',
  red:     '#ef4444',
  yellow:  '#f59e0b',
  purple:  '#8b5cf6',
  cyan:    '#06b6d4',
}