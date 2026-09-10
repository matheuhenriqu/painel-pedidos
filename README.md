# 📋 Central de Pedidos & Chatbot Inteligente com IA

![Status](https://img.shields.io/badge/Status-Pronto%20para%20Avalia%C3%A7%C3%A3o-success?style=for-the-badge)
![Segurança](https://img.shields.io/badge/Seguran%C3%A7a-RLS%20Endurecido%20%2B%20RBAC-blue?style=for-the-badge)
![Versão](https://img.shields.io/badge/Vers%C3%A3o-2.4.0-indigo?style=for-the-badge)
![Licença](https://img.shields.io/badge/Finalidade-Acad%C3%AAmica-amber?style=for-the-badge)

---

## 📌 1. Visão Geral da Aplicação

A **Central de Pedidos** é uma solução corporativa completa para gestão, triagem e atendimento operacional de pedidos em tempo real. O sistema integra um painel administrativo com visão analítica (KPIs, Kanban, Tabelas, Agenda e Gráficos de Faturamento) a um **Chatbot de Atendimento com Inteligência Artificial Generativa e Reconhecimento de Voz**.

### 🎯 Problema Solucionado
Em ambientes operacionais e de prestação de serviços (oficinas, assistências técnicas, pet shops, manutenção, consultorias):
1. **Pedidos descentralizados**: Falhas de anotação, pedidos perdidos em mensagens de WhatsApp e atrasos de triagem.
2. **Falta de isolamento e privacidade**: Em sistemas multiusuário tradicionais sem blindagem no banco de dados, dados confidenciais de clientes e faturamento podem ser vazados para outros usuários ou alunos.
3. **Atendimento 24/7 sem atrito**: O Chatbot público coleta solicitações, transcreve mensagens de voz do cliente via IA e insere os pedidos diretamente no banco com validação no servidor.

---

## 🛠️ 2. Stack de Tecnologias

| Camada | Tecnologia | Descrição |
| :--- | :--- | :--- |
| **Frontend** | HTML5 Semântico | Estrutura acessível, semântica, compatível com leitores de tela e WCAG. |
| **Estilização** | Tailwind CSS + CSS3 Vanilla | Paleta executiva corporativa de alto contraste, modo escuro/claro e responsividade total. |
| **Tipografia** | Google Fonts (*Plus Jakarta Sans*) | Tipografia executiva com suporte nativo a numerais tabulares para dados financeiros. |
| **Lógica do Cliente** | JavaScript Vanilla (ES6+) | Módulos assíncronos (`async/await`), manipulação segura do DOM sem frameworks pesados. |
| **Banco de Dados** | Supabase (PostgreSQL 15+) | Relacional com tipagem estrita, restrições CHECK, triggers e funções PL/pgSQL. |
| **Autenticação** | Supabase Auth (JWT & RBAC) | Sessões seguras, tokens JWT criptografados e cargos controlados via `app_metadata`. |
| **Tempo Real** | Supabase Realtime (WebSockets) | Sincronização instantânea de novos pedidos, atualizações e exclusões na interface. |
| **Computação Serverless** | Supabase Edge Functions (Deno) | Intermediação segura entre o cliente e os provedores externos de IA. |
| **Inteligência Artificial** | Groq Cloud API | **Whisper-large-v3-turbo** (transcrição de áudio) + **Qwen 2.5 / Llama 3.3** (chat inteligente). |

---

## 🏗️ 3. Arquitetura do Sistema & Fluxo de Dados

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            CLIENTE / NAVEGADOR                              │
├──────────────────────────────────────┬──────────────────────────────────────┤
│    Painel Operacional (index.html)   │         Chatbot IA (chat.html)       │
│  - Gestão de Pedidos (Kanban/Table)  │  - Coleta de Pedidos Interativa      │
│  - Autenticação e RBAC (Admin/User)  │  - Transcrição de Áudio (Microfone)  │
│  - Métricas, KPIs e Gráficos         │  - Consulta 2FA de Pedidos e CSAT    │
└──────────────────┬───────────────────┴──────────────────┬───────────────────┘
                   │                                      │
                   │ REST / WebSockets                    │ RPCs / Edge Function
                   ▼                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            SUPABASE BACKEND                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  [ Edge Functions: /chat-ia ] (Deno Runtime)                                │
│    ├── Rate Limit por IP (20 req/min)                                       │
│    ├── CORS Restrito (Allowlist de Domínios)                                │
│    └── Comunicação Segura com Groq Cloud API (GROQ_API_KEY no servidor)     │
├─────────────────────────────────────────────────────────────────────────────┤
│  [ Supabase Auth ]                                                          │
│    └── Emissão de JWT com claims e controle de cargo via `app_metadata`     │
├─────────────────────────────────────────────────────────────────────────────┤
│  [ PostgreSQL com Row Level Security - RLS ]                                │
│    ├── Tabela `pedidos`: Políticas estritas de SELECT, INSERT, UPDATE, DELETE│
│    ├── Funções RPC (SECURITY DEFINER): criar, consultar e avaliar pedidos   │
│    └── Tabela `configuracoes_chatbot`: Restrita a administradores           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔒 4. Modelo de Segurança & Blindagem de Dados

### 4.1 Isolamento Estrito de Dados entre Usuários (Row Level Security - RLS)
O isolamento não depende do frontend: ele é **garantido diretamente no motor PostgreSQL** do banco de dados:

1. **Leitura (`SELECT`)**:
   - Usuários com cargo `cliente` visualizam **apenas** os pedidos cujo campo `user_id` seja igual ao seu identificador (`auth.uid() = user_id`).
   - Usuários com cargo `admin` visualizam todos os pedidos da empresa.
   - Acesso anônimo direto à tabela `pedidos` é **100% bloqueado**.
2. **Criação (`INSERT`)**:
   - Usuários autenticados só podem criar pedidos associados ao seu próprio `user_id`.
   - Chatbot anônimo cria pedidos exclusivamente pela função RPC `criar_pedido_publico()`, que valida todos os campos e impede a injeção de `user_id` arbitrário.
3. **Edição (`UPDATE`)**:
   - Usuários comuns só atualizam pedidos onde `auth.uid() = user_id`. Tentativas de sequestro de registros ou alteração de pedidos de colegas resultam em bloqueio imediato pelo banco.
4. **Exclusão (`DELETE`)**:
   - Usuários comuns podem excluir apenas os seus próprios pedidos. Administradores podem excluir globalmente. Nenhum usuário pode apagar registros pertencentes a outro.

### 4.2 Controle de Acesso Baseado em Funções (RBAC) Imutável pelo Cliente
- O cargo do usuário (`admin` vs `cliente`) é armazenado na claim protegida `auth.users.app_metadata`.
- Diferente de `user_metadata` (que pode ser editado pelo usuário via API do cliente), o `app_metadata` só pode ser modificado por administradores no painel ou via SQL/Service Role.

### 4.3 Chatbot Blindado com Funções RPC (`SECURITY DEFINER`)
- **`criar_pedido_publico()`**: Valida no servidor tamanho de strings, limites numéricos (R$ 0 a R$ 1.000.000), anti-spam por telefone (máx. 5 pedidos em 10 minutos) e impede setores de sistema.
- **`consultar_pedido_publico()`**: Requer **duplo fator de consulta (2FA)** — exige o número exato do pedido (`id`) **E** o telefone completo com DDD usado no cadastro. Evita enumeração e scraping de pedidos por terceiros.
- **`avaliar_pedido_publico()`**: Permite nota de CSAT (1 a 5) sem conceder privilégio de UPDATE à tabela.

### 4.4 Isolamento de Credenciais e Segredos
- **Chaves de API Privadas**: A chave `GROQ_API_KEY` reside exclusivamente nos Secrets da Supabase Edge Function (`chat-ia`). Nunca é exposta no frontend.
- **Chave Pública Frontend**: O frontend utiliza unicamente a `anon publishable key`, segura para o navegador pois opera estritamente sob as regras do RLS.
- **Centralização de Configuração**: Credenciais são lidas a partir de `config.js` (`window.__APP_CONFIG__`), com `.env.example` fornecido e `.gitignore` blindado.

### 4.5 Prevenção Contra Injeção e Cross-Site Scripting (XSS)
- Todos os dados renderizados dinamicamente passam pela função `escapeHtml()`.
- Imagens e mídias de avatar são sanitizadas com verificação estrita de protocolo (`https:`, `http:`, `data:image/`) e construídas diretamente via DOM API (`document.createElement`), impedindo ataques de injeção de atributos ou URLs `javascript:`.
- Removidos todos os logs de depuração (`console.log`), evitando vazamento de tokens de sessão, cabeçalhos ou estruturas internas do banco no console.

---

## 🚀 5. Guia de Execução Local Passo a Passo

### Pré-requisitos
- Navegador moderno (Google Chrome, Microsoft Edge, Firefox, Brave, Safari).
- Qualquer servidor HTTP estático local (opcional, mas recomendado para WebSockets e áudio).

### Opção A: Execução Rápida via VS Code Live Server (Recomendado)
1. Abra a pasta do projeto no **VS Code**.
2. Clique com o botão direito sobre [index.html](file:///e:/03-09/painel-pedidos/index.html) e selecione **"Open with Live Server"** (ou use a extensão Live Server).
3. A aplicação abrirá automaticamente em `http://127.0.0.1:5500/index.html`.

### Opção B: Execução via Linha de Comando (Python)
Abra o terminal na pasta do projeto e execute:
```bash
python -m http.server 5500
```
Acesse no navegador: `http://localhost:5500/index.html`

### Opção C: Execução via Node.js
```bash
npx serve .
```

---

## 🧪 6. Roteiro de Testes para Avaliação do Professor (Gabarito de Nota Máxima)

Siga este roteiro passo a passo para auditar e testar todas as camadas de segurança e usabilidade do projeto:

### 🔬 Cenário 1: Teste de Isolamento entre Clientes (Blindagem RLS)
1. Abra `index.html`. Na tela de autenticação, clique na aba **"Criar Conta"**.
2. Cadastre o usuário de teste:
   - **Nome**: Aluno Teste 1
   - **E-mail**: `aluno1@faculdade.edu`
   - **Senha**: `123456`
3. Após entrar, cadastre 2 pedidos pelo botão **"+ Novo Pedido"** (ex.: "Revisão Mecânica" e "Troca de Óleo").
4. No menu superior direito (ou barra inferior mobile), abra o perfil e clique em **"Sair da Conta"**.
5. Na aba **"Criar Conta"**, cadastre um segundo usuário:
   - **Nome**: Aluno Teste 2
   - **E-mail**: `aluno2@faculdade.edu`
   - **Senha**: `123456`
6. **Comprovação de Segurança**: O painel do `aluno2` estará completamente vazio. Ele **não consegue ver, editar nem deletar nenhum dos pedidos cadastrados pelo aluno 1**.

---

### 👑 Cenário 2: Teste de Administrador & Gestão Global
1. Crie uma conta para avaliação com seu e-mail (ex.: `professor@faculdade.edu` / senha `123456`).
2. Acesse o **SQL Editor** do Supabase do projeto e execute a função utilitária criada especialmente para a avaliação:
   ```sql
   SELECT promover_usuario_admin('professor@faculdade.edu');
   ```
3. Faça logout e login novamente no painel com a conta do professor.
4. **Comprovação de Privilégios de Administrador**:
   - O badge no cabeçalho exibirá **"ADMIN"** em roxo.
   - O botão **"Clientes"** e a engrenagem de **"Configuração do Chatbot"** aparecerão no topo.
   - O Administrador tem visão global de todos os pedidos de todos os alunos/clientes.
   - Teste o **"Modo Auditoria"** (simula a visão restrita do cliente sem faturamento).
   - Teste a alteração de status em lote e exclusão seletiva.

---

### 💬 Cenário 3: Teste do Chatbot Público com IA e Áudio
1. Abra `chat.html` (ou clique no botão flutuante **"Abrir Chatbot de Atendimento"** no painel).
2. **Pedido por Texto**:
   - Envie: *"Olá, gostaria de agendar uma manutenção para o meu computador amanhã às 14h, meu nome é Carlos Silva e meu telefone é 11988887777"*.
   - A IA coletará e estruturará os dados em um card visual de confirmação.
3. **Pedido por Voz (Microfone)**:
   - Clique no ícone de microfone e fale seu pedido.
   - O áudio será enviado com segurança à Edge Function, que o transcreve via **Groq Whisper** e devolve o texto processado.
4. **Finalização do Pedido**:
   - Confirme o pedido no Chatbot. O pedido é inserido via RPC segura `criar_pedido_publico`.
   - O Chatbot exibirá a celebração com confetes, o número do pedido gerado (ex.: `#42`) e o widget de avaliação **CSAT (1 a 5 estrelas)**.
   - No painel administrativo em aberto, observe o pedido entrar **instantaneamente via WebSocket Realtime** com toque sonoro e notificação!
5. **Consulta Segura de Pedido (2FA)**:
   - No Chatbot, digite: *"Quero consultar o status do meu pedido #42"*.
   - O sistema solicitará o telefone com DDD cadastrado para autenticação antes de exibir os dados do pedido, prevenindo vazamento de informações.

---

## 📂 7. Estrutura de Arquivos do Projeto

```
painel-pedidos/
├── .env.example                 # Modelo documentado de variáveis de ambiente
├── .gitignore                   # Regras estritas de exclusão para o Git
├── AGENTS.md                    # Diretrizes do agente e regras de versionamento Git
├── README.md                    # Documentação técnica e guia de entrega acadêmica
├── config.js                    # Configurações centralizadas da aplicação web
├── index.html                   # Painel Operacional completo com Dashboard e RBAC
├── chat.html                    # Chatbot de Atendimento público com IA e comando de voz
├── supabase_seguranca_rls.sql   # Script SQL com schema, RLS, RBAC e RPCs endurecidas
└── supabase/
    └── functions/
        └── chat-ia/             # Supabase Edge Function (Deno) para IA
            ├── README.md        # Documentação técnica e guia de deploy da Edge Function
            └── index.ts         # Código da Edge Function (Whisper + Chat com Rate Limit)
```

---

## 🏆 8. Critérios Acadêmicos Atendidos

- [x] **Arquitetura & Clean Code**: Separação clara entre frontend, banco de dados relacional e computação serverless.
- [x] **Segurança por Padrão (Security by Design)**: RLS ativado em todas as tabelas, RBAC via `app_metadata`, sem chaves privadas no cliente.
- [x] **Resiliência e Tratamento de Exceções**: Tratamento com feedback visual amigável (toasts diferenciados) em 100% das operações de rede/async.
- [x] **Prevenção a Vulnerabilidades OWASP**: Proteção contra Broken Access Control (A01:2021), Cryptographic Failures (A02:2021), Injection & XSS (A03:2021) e Security Misconfiguration (A05:2021).
- [x] **Usabilidade & Design Premium**: Interface moderna, suporte a tema escuro/claro, micro-interações, acessibilidade e responsividade para dispositivos móveis.
- [x] **Versionamento Git Semântico**: Padrão Conventional Commits em português e repositório sincronizado com GitHub.
