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
USING (true);


