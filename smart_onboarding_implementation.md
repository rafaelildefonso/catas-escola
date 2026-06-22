# 🚀 Checklist: Implementação de Onboarding Inteligente (CATAS)
**Objetivo:** Eliminar a "Síndrome da Tela em Branco" e levar o usuário ao "Aha! Moment" em menos de 2 minutos, coletando nicho e cargo para sugestões personalizadas.

## 🗄️ 1. Infraestrutura e Banco de Dados (Supabase)
- [x] **SQL Migration:** Adicionar colunas `industry` (text) e `role` (text) na tabela `profiles`.
- [x] **SQL Migration:** Adicionar coluna `onboarding_completed` (boolean, default false) em `profiles` para controle de fluxo.
- [ ] **Enum/Check Constraints:** (Opcional) Definir lista de nichos válidos (ex: 'real_estate', 'marketing', 'legal', 'sales', 'other') para facilitar a análise futura.
- [ ] **RAG Context:** Preparar a tabela `ia_memory` para receber o "Contexto do Usuário" assim que o onboarding terminar.

## 📱 2. Interface Flutter (App)
- [x] **Onboarding Screen 1 (Nicho):** Criar GridView com cards visuais (ícone + texto) para seleção de área de atuação.
- [ ] **Onboarding Screen 2 (Cargo/Dor):** Lista de múltipla escolha com as "Dores de Cabeça" mais comuns do nicho selecionado.
- [x] **Onboarding Screen 3 (The Hook):** Tela de "Gerando seu ambiente personalizado..." com um loader de IA.
- [x] **AuthProvider Update:** Criar método `completeOnboarding(String industry, String role)` que faz o update no Supabase e muda o estado local.
- [x] **Navigation Logic:** Garantir que usuários com `onboarding_completed == false` sejam redirecionados para o fluxo ao logar.

## 🤖 3. Inteligência Artificial e Backend
- [ ] **Template Mapper:** Criar um dicionário (JSON) no backend ou no Supabase que mapeia `industry` -> `list_of_template_ids`.
- [x] **Maestro Context Injection:** Atualizar o Agente Arquiteto para que ele receba o `industry` e `role` do perfil no sistema de prompts (System Message).
- [x] **Primeira Automação (Chat):** Configurar o bot para iniciar a conversa com: *"Oi! Vi que você é [Cargo] no setor [Nicho]. Quer que eu configure um fluxo de [Sugestão] para você agora?"*.

## 📊 4. Métricas e Retenção
- [ ] **Event Tracking:** Disparar evento no PostHog/Sentry ao completar cada tela do onboarding (para identificar onde as pessoas desistem).
- [ ] **Métrica de Sucesso:** Monitorar a taxa de conversão de "Onboarding Finalizado" -> "Primeira Automação Executada".

## 💡 5. Sugestões de Nichos Iniciais (MVP)
- [x] **Imobiliário:** Foco em leads de portais (Zap/VivaReal) -> WhatsApp.
- [x] **Marketing Digital:** Foco em Planilhas -> Relatórios resumidos por IA.
- [x] **Advocacia:** Foco em Resumo de processos/PDFs -> Tarefas no Notion.
