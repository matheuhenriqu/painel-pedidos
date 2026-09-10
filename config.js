// ==============================================================================
// CENTRAL DE CONFIGURAÇÃO DO AMBIENTE (FRONTEND)
// ==============================================================================
// Este arquivo centraliza as credenciais públicas da aplicação web.
// IMPORTANTE: A chave abaixo é a 'anon publishable key' do Supabase, projetada
// especificamente para clientes frontend e restrita pelo Row Level Security (RLS).
// Chaves privadas (como service_role ou GROQ_API_KEY) residem estritamente no
// servidor/Edge Function e NUNCA devem ser inseridas aqui.
// ==============================================================================

window.__APP_CONFIG__ = Object.freeze({
  SUPABASE_URL: "https://xqmzysjzopyuelvhokwm.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_RfIxDPxwUdyzsaXXsa2tIw_XRvfyxAn",
  AMBIENTE: "producao_academica",
  VERSAO: "2.4.0"
});
