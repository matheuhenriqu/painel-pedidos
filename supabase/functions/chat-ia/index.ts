import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// Configurações de CORS para requisições seguras da aplicação web
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-groq-key',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

serve(async (req: Request) => {
  // Trata preflight request de CORS do navegador
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Obtém a chave da API do Groq das variáveis de ambiente secretas da Edge Function (ou header de override)
    const groqApiKey = Deno.env.get('GROQ_API_KEY') || req.headers.get('x-groq-key');

    if (!groqApiKey) {
      return new Response(
        JSON.stringify({
          error: 'Chave GROQ_API_KEY não configurada no Supabase.',
          detalhes: 'Defina a variável no Supabase Dashboard em Edge Functions > Secrets ou execute: supabase secrets set GROQ_API_KEY=sua_chave'
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    }

    const contentType = req.headers.get('content-type') || '';

    // 2. Rota para Transcrição de Voz (Groq Whisper) via FormData (multipart/form-data)
    if (contentType.includes('multipart/form-data')) {
      const formData = await req.formData();
      const file = formData.get('file');

      if (!file) {
        return new Response(JSON.stringify({ error: 'Nenhum arquivo de áudio recebido.' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      }

      const groqFormData = new FormData();
      groqFormData.append('file', file);
      groqFormData.append('model', 'whisper-large-v3-turbo');
      groqFormData.append('language', 'pt');
      groqFormData.append('response_format', 'json');

      const resWhisper = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${groqApiKey}`
        },
        body: groqFormData
      });

      const whisperData = await resWhisper.json();
      return new Response(JSON.stringify(whisperData), {
        status: resWhisper.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // 3. Rota para Chat Conversacional e Raciocínio (Groq Qwen 3.8 27B com fallback para 3.6 27B)
    const body = await req.json();

    // Suporte alternativo a áudio codificado em Base64
    if (body.tipo === 'transcricao_audio' && body.audioBase64) {
      const binaryString = atob(body.audioBase64);
      const bytes = new Uint8Array(binaryString.length);
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
      }
      const audioBlob = new Blob([bytes], { type: 'audio/webm' });
      const groqFormData = new FormData();
      groqFormData.append('file', audioBlob, 'gravacao.webm');
      groqFormData.append('model', 'whisper-large-v3-turbo');
      groqFormData.append('language', 'pt');
      groqFormData.append('response_format', 'json');

      const resWhisper = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${groqApiKey}`
        },
        body: groqFormData
      });

      const whisperData = await resWhisper.json();
      return new Response(JSON.stringify(whisperData), {
        status: resWhisper.status,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const messages = body.messages || [];
    const requestedModel = body.model || 'qwen/qwen3.8-27b';
    const max_tokens = body.max_tokens || 450;
    const temperature = body.temperature ?? 0.1;

    // Resiliência de modelos: tenta modelo solicitado e fallback automático caso atinja limites de taxa
    const modelosParaTentativa = [requestedModel, 'qwen/qwen3.6-27b'];
    let lastError: unknown = null;

    for (const m of modelosParaTentativa) {
      try {
        const resGroq = await fetch('https://api.groq.com/openai/v1/chat/completions', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${groqApiKey}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            model: m,
            messages,
            max_tokens,
            temperature
          })
        });

        if (!resGroq.ok) {
          const errText = await resGroq.text();
          lastError = { status: resGroq.status, error: errText };
          console.warn(`Groq modelo ${m} retornou status ${resGroq.status}: ${errText}`);
          continue;
        }

        const data = await resGroq.json();
        return new Response(JSON.stringify(data), {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        });
      } catch (err) {
        lastError = { status: 500, error: String(err) };
      }
    }

    return new Response(
      JSON.stringify({ error: 'Instabilidade momentânea no provedor de IA.', detalhes: lastError }),
      {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );

  } catch (error: any) {
    return new Response(
      JSON.stringify({ error: error?.message || 'Erro interno na Edge Function' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    );
  }
});
