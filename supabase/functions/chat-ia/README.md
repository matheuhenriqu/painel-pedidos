# Supabase Edge Function: `chat-ia`

Esta Edge Function faz a intermediação segura entre o frontend da Central de Pedidos e o provedor de IA da Groq.

**Segurança:**
- A chave `GROQ_API_KEY` fica **somente** nos Secrets da Edge Function. Nunca no frontend, nunca no repo.
- Sem override por header (`x-groq-key` removido). Sem fallback direto `api.groq.com` no frontend.
- CORS por allowlist (`ALLOWED_ORIGINS`), sem `*`. Validação de modelo/mensagens/tamanho + rate-limit.

> Se esta chave vazou antes (histórico do git), **revogue no painel Groq e gere outra**.

---

## 1. Publicar

```bash
npx supabase login
npx supabase link --project-ref SEU_PROJECT_REF

# Defina os segredos (NUNCA commite valores reais)
npx supabase secrets set GROQ_API_KEY=SUA_CHAVE_AQUI
npx supabase secrets set ALLOWED_ORIGINS=https://seu-dominio.com,https://www.seu-dominio.com

# Deploy COM verificação JWT desabilitada apenas porque o chatbot é público.
# O controle passa a ser: CORS allowlist + validação + rate-limit na função.
npx supabase functions deploy chat-ia --no-verify-jwt
```

## 2. Pelo Dashboard (sem terminal)

1. Acesse `Edge Functions > chat-ia > Secrets`.
2. Adicione `GROQ_API_KEY` = sua chave (cole uma vez, não salve em arquivo).
3. Adicione `ALLOWED_ORIGINS` = seus domínios separados por vírgula.
4. Publique o código de `index.ts`.

## 3. Rotas

- `POST /functions/v1/chat-ia` (JSON `{messages, model, max_tokens, temperature}`):
  - `model` restrito à allowlist no servidor; `max_tokens` clamp 1–600; `temperature` 0–1.
  - System prompt fixo no servidor; mensagens do cliente limitadas (20 msgs, 2000 chars cada).
- `POST /functions/v1/chat-ia` (`multipart/form-data` `file`):
  - Áudio até 5MB, `audio/*`. Também aceita `{"tipo":"transcricao_audio","audioBase64":"..."}` limitado.
