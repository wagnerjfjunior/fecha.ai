/**
 * src/lib/supabaseClient.js
 * Cliente Supabase compartilhado — FECH.AI
 * Usado pelo módulo MesaCliente (useMesaData.js).
 * ANON KEY é pública (safe client-side).
 * Controle de acesso real: RPCs com SECURITY DEFINER + is_gestor().
 */
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://uobxxgzshrmbtjfdolxd.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvYnh4Z3pzaHJtYnRqZmRvbHhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjcyOTUsImV4cCI6MjA5MTg0MzI5NX0.0RiMkrtJlGbprp8AqVPXC9Y5LxP6QiELfP7NoYEXJ9w';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
