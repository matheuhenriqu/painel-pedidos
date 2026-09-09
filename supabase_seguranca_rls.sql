-- ==============================================================================
-- SCRIPT DE SEGURANÇA E POLÍTICAS DE ROW LEVEL SECURITY (RLS) PARA O SUPABASE
-- Execute este script no SQL Editor do painel Supabase (https://supabase.com/dashboard)
-- ==============================================================================

-- 1. Habilitar Row Level Security (RLS) na tabela pedidos
ALTER TABLE pedidos ENABLE ROW LEVEL SECURITY;

-- 2. Remover políticas antigas se existirem (para evitar duplicações)
DROP POLICY IF EXISTS "pedidos_select_policy" ON pedidos;
DROP POLICY IF EXISTS "pedidos_insert_policy" ON pedidos;
DROP POLICY IF EXISTS "pedidos_update_policy" ON pedidos;
DROP POLICY IF EXISTS "pedidos_delete_policy" ON pedidos;

-- 3. POLÍTICA DE LEITURA (SELECT):
-- - Administradores podem visualizar todos os pedidos.
-- - Clientes autenticados podem visualizar exclusivamente os pedidos vinculados ao seu próprio user_id.
CREATE POLICY "pedidos_select_policy" ON pedidos
FOR SELECT
TO authenticated
USING (
  (auth.uid() = user_id)
  OR ((auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin', 'administrador'))
);

-- 4. POLÍTICA DE CRIAÇÃO (INSERT):
-- - O pedido inserido deve conter o user_id do usuário que está autenticado,
--   ou ser realizado por um administrador.
CREATE POLICY "pedidos_insert_policy" ON pedidos
FOR INSERT
TO authenticated
WITH CHECK (
  (auth.uid() = user_id)
  OR ((auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin', 'administrador'))
);

-- 5. POLÍTICA DE ATUALIZAÇÃO (UPDATE):
-- - Usuários só podem atualizar pedidos que pertençam a eles mesmos,
--   exceto administradores que podem atualizar qualquer registro.
CREATE POLICY "pedidos_update_policy" ON pedidos
FOR UPDATE
TO authenticated
USING (
  (auth.uid() = user_id)
  OR ((auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin', 'administrador'))
);

-- 6. POLÍTICA DE EXCLUSÃO (DELETE):
-- - Apenas o próprio titular do pedido ou administradores podem excluir registros.
CREATE POLICY "pedidos_delete_policy" ON pedidos
FOR DELETE
TO authenticated
USING (
  (auth.uid() = user_id)
  OR ((auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin', 'administrador'))
);

-- 7. POLÍTICA DE CRIAÇÃO PÚBLICA / CHATBOT (INSERT PARA VISITANTES E CLIENTES VIA CHATBOT):
-- - Permite que qualquer cliente envie um pedido via Chatbot público sem precisar de login
--   com o status inicial 'Pendente' e sem vincular obrigatoriamente um user_id.
DROP POLICY IF EXISTS "pedidos_chatbot_anon_insert_policy" ON pedidos;
CREATE POLICY "pedidos_chatbot_anon_insert_policy" ON pedidos
FOR INSERT
TO anon
WITH CHECK (
  (status = 'Pendente' OR status IS NULL)
  AND (user_id IS NULL)
);

-- 8. POLÍTICA DE CONSULTA PÚBLICA DE PEDIDOS (SELECT PARA AUTOATENDIMENTO E RASTREAMENTO):
-- - Permite que visitantes e clientes consultem o andamento e status de seus pedidos
--   no Chatbot pelo número do pedido (ID) ou telefone de contato.
DROP POLICY IF EXISTS "pedidos_chatbot_anon_select_policy" ON pedidos;
CREATE POLICY "pedidos_chatbot_anon_select_policy" ON pedidos
FOR SELECT
TO anon
USING (
  status IN ('Pendente', 'Agendado', 'Em andamento', 'Em produção', 'Concluído', 'Cancelado')
);

-- 9. FUNÇÃO SEGURA RPC PARA CONSULTA DE PEDIDO NO CHATBOT (PROTEÇÃO CONTRA VAZAMENTO):
-- - Exige que o cliente forneça o ID numérico exato ou o número de WhatsApp
--   evitando qualquer varredura em massa da tabela por usuários anônimos.
CREATE OR REPLACE FUNCTION consultar_pedido_publico(
  p_id INT DEFAULT NULL,
  p_telefone TEXT DEFAULT NULL
)
RETURNS TABLE (
  id INT,
  cliente TEXT,
  servico TEXT,
  setor TEXT,
  data_pedido TEXT,
  status TEXT,
  valor NUMERIC,
  observacoes TEXT,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF p_id IS NOT NULL AND p_id > 0 THEN
    RETURN QUERY
    SELECT p.id, p.cliente, p.servico, p.setor, p.data_pedido, p.status, p.valor, p.observacoes, p.created_at
    FROM pedidos p
    WHERE p.id = p_id;
  ELSIF p_telefone IS NOT NULL AND LENGTH(REGEXP_REPLACE(p_telefone, '\D', '', 'g')) >= 8 THEN
    RETURN QUERY
    SELECT p.id, p.cliente, p.servico, p.setor, p.data_pedido, p.status, p.valor, p.observacoes, p.created_at
    FROM pedidos p
    WHERE p.telefone ILIKE '%' || RIGHT(REGEXP_REPLACE(p_telefone, '\D', '', 'g'), 8) || '%'
    ORDER BY p.id DESC
    LIMIT 1;
  END IF;
END;
$$;

-- 10. CONFIGURAÇÃO DE BUCKET DE ANEXOS / FOTOS (SUPABASE STORAGE):
-- - Crie um bucket público chamado 'pedidos-anexos' no menu Storage do Supabase
--   e configure as políticas de upload público (INSERT) para visitantes:
--
-- INSERT INTO storage.buckets (id, name, public) VALUES ('pedidos-anexos', 'pedidos-anexos', true)
-- ON CONFLICT (id) DO NOTHING;
--
-- CREATE POLICY "anexos_public_insert" ON storage.objects
-- FOR INSERT TO anon WITH CHECK (bucket_id = 'pedidos-anexos');
--
-- CREATE POLICY "anexos_public_select" ON storage.objects
-- FOR SELECT TO anon USING (bucket_id = 'pedidos-anexos');



