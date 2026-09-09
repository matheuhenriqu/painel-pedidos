# Supabase Edge Function: `chat-ia`

Esta Edge Function faz a intermediação segura entre o frontend da Central de Pedidos e o provedor de Inteligência Artificial da Groq (Qwen 3.8 27B e Whisper Large v3 Turbo).

**Vantagem de Segurança:**
A chave `GROQ_API_KEY` fica armazenada com sigilo absoluto nos segredos criptografados do Supabase, **nunca sendo exposta no código-fonte nem enviada ao navegador do cliente**.

---

## 1. Como Publicar a Edge Function

No terminal do seu projeto, utilize o Supabase CLI:

```bash
# 1. Faça login no Supabase (se ainda não fez)
npx supabase login

# 2. Vincule seu projeto (ID: xqmzysjzopyuelvhokwm)
npx supabase link --project-ref xqmzysjzopyuelvhokwm

# 3. Defina a chave secreta da API do Groq
npx supabase secrets set GROQ_API_KEY=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

# 4. Faça o deploy da função (sem validação de JWT para permitir autoatendimento público)
npx supabase functions deploy chat-ia --no-verify-jwt
```

---

## 2. Configuração pelo Supabase Dashboard (Sem Terminal)

1. Acesse: https://supabase.com/dashboard/project/xqmzysjzopyuelvhokwm/functions
2. Clique em **Edge Functions** > **Secrets** (ou **Project Settings** > **Vault**).
3. Adicione um novo segredo:
   - **Nome:** `GROQ_API_KEY`
   - **Valor:** `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`
4. Na aba **Edge Functions**, publique a função `chat-ia` com o código contido em `index.ts`.

---

## 3. Rotas e Recursos Suportados

- **POST /functions/v1/chat-ia** (JSON):
  - Envia mensagens conversacionais para o modelo `qwen/qwen3.8-27b` com fallback automático para `qwen/qwen3.6-27b`.
- **POST /functions/v1/chat-ia** (`multipart/form-data`):
  - Transcreve áudio com o modelo `whisper-large-v3-turbo` em português.
