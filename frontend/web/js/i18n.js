const translations = {
    pt: {
        nav_about: "Sobre Nós",
        nav_terms: "Termos",
        nav_privacy: "Privacidade",
        nav_contact: "Contato",
        
        last_updated: "Última atualização: 7 de outubro de 2026",
        
        // General text
        placeholder_text: "Para obter mais informações, entre em contato conosco ou consulte a seção de ajuda.",
        
        // Terms
        terms_title: "Termos e Condições de Uso",
        terms_p1: "Bem-vindo aos Termos de Uso do CATAS. Ao usar nossa plataforma de automação com IA, você concorda com estes termos.",
        terms_h2_1: "1. Aceitação dos Termos",
        terms_p2: "O uso do CATAS (Context Aware Task Automation System) está sujeito a estes termos e a eventuais atualizações.",
        terms_h2_2: "2. Assinaturas e Créditos",
        terms_p3: "Os planos (Free, Pro, Max) operam com um sistema de tokens. A renovação ocorre mensalmente e os créditos não acumulam.",
        terms_h2_3: "3. Uso Aceitável da IA",
        terms_p4: "Você concorda em não usar o CATAS para fins ilícitos, spam ou tentativas de engenharia reversa do nosso Maestro Agent.",
        
        // Privacy
        privacy_title: "Política de Privacidade",
        privacy_p1: "A privacidade dos seus dados e integrações é nossa prioridade no CATAS. Coletamos apenas as informações necessárias para operar o serviço e garantir sua segurança.",
        privacy_h2_1: "1. Coleta de Dados",
        privacy_p2: "Coletamos dados essenciais, como nome, e‑mail e tokens OAuth das integrações que você conecta, para permitir a autenticação e comunicação com serviços externos.",
        privacy_h2_2: "2. Como a IA processa seus dados",
        privacy_p3: "Os dados de integrações são lidos apenas durante a execução de uma automação explicitamente iniciada. A IA não utiliza esses dados para treinar seus modelos.",
        privacy_h2_3: "3. Retenção e Segurança",
        privacy_p4: "Utilizamos criptografia AES‑256 no banco de dados Supabase para proteger seus tokens e dados sensíveis.",
        
        // Refund
        refund_title: "Política de Reembolso",
        refund_p1: "Entenda as condições aplicáveis ao reembolso de assinaturas CATAS gerenciadas via Stripe.",
        refund_h2_1: "1. Prazo de Cancelamento",
        refund_p2: "Você pode cancelar a qualquer momento. Reembolsos são concedidos em até 7 dias corridos após a compra inicial, desde que o consumo de créditos não tenha excedido 20% da quota.",
        
        // Cookies
        cookies_title: "Política de Cookies",
        cookies_p1: "O CATAS utiliza cookies para melhorar a experiência do usuário, garantindo sessões estáveis e preferências preservadas.",
        cookies_h2_1: "1. Cookies Essenciais",
        cookies_p2: "Usamos apenas cookies essenciais para gerenciar sessões de login seguras, manter a continuidade de estado e proteger contra CSRF.",        
        // Security
        security_title: "Centro de Segurança e Confiança",
        security_p1: "Conheça os mecanismos robustos de segurança do motor Temporal e da orquestração da nossa plataforma.",
        security_h2_1: "1. Arquitetura Maestro Segura",
        security_p2: "Cada plano gerado por IA passa por um agente secundário (ValidationAgent) que garante que nenhuma API externa será chamada com payloads destrutivos não autorizados.",
        
        // About
        about_title: "Sobre o CATAS",
        about_p1: "Este projeto nasceu nas salas de aula do Cotemig. Somos um time de alunos apaixonados por tecnologia, que aceitou o desafio de um trabalho de escola com a ambição de ser destaque. Não queríamos que o projeto ficasse apenas na escola; queremos levá‑lo para a vida real e transformar o CATAS em uma startup de verdade.",
        about_h2_1: "Nossa Visão",
        about_p2: "Nossa visão é democratizar o acesso a workflows B2B complexos sem exigir experiência em programação ou ferramentas nocode, colocando a IA como interface definitiva.",
        about_h2_2: "Nossa Missão",
        about_p3: "Eliminar a complexidade desnecessária da automação, ajudando pessoas e empresas a reduzir tarefas manuais, otimizar processos e dedicar mais tempo ao que realmente importa.",
        about_h2_3: "O que nos move",
        about_p4: "Acreditamos que a tecnologia deve se adaptar às pessoas, e não o contrário. É essa convicção que orienta o desenvolvimento do CATAS e nossa busca por uma forma mais simples, inteligente e acessível de automatizar o trabalho. Estamos construindo o CATAS com a ambição de transformar essa visão em uma solução real, útil e escalável.",
        
        // Contact
        contact_title: "Contato e Suporte",
        contact_p1: "Precisa de ajuda com uma integração ou automação que não está funcionando?",
        contact_email: "Email de Suporte: contact.catas@gmail.com",
        
        footer_rights: "© 2026 CATAS. Todos os direitos reservados."
    },
    en: {
        nav_about: "About Us",
        nav_terms: "Terms",
        nav_privacy: "Privacy",
        nav_contact: "Contact",
        
        last_updated: "Last updated: October 7, 2026",
        
        // General text
        placeholder_text: "For more information, contact us or see the help section.",
        
        // Terms
        terms_title: "Terms and Conditions of Use",
        terms_p1: "Welcome to CATAS Terms of Use. By using our AI automation platform, you agree to these terms.",
        terms_h2_1: "1. Acceptance of Terms",
        terms_p2: "The use of CATAS (Context Aware Task Automation System) is subject to these terms and any future updates.",
        terms_h2_2: "2. Subscriptions and Credits",
        terms_p3: "Plans (Free, Pro, Max) operate on a token-based credit system. Renewals happen monthly and unused credits do not roll over.",
        terms_h2_3: "3. Acceptable AI Usage",
        terms_p4: "You agree not to use CATAS for illegal purposes, spamming, or reverse‑engineering our Maestro Agent.",
        
        // Privacy
        privacy_title: "Privacy Policy",
        privacy_p1: "The privacy of your data and API integrations is our top priority at CATAS. We only collect data essential to operate the service and keep it secure.",
        privacy_h2_1: "1. Data Collection",
        privacy_p2: "We collect essential data such as name, email, and OAuth tokens of the platforms you connect, to enable authentication and communication with external services.",
        privacy_h2_2: "2. How AI processes your data",
        privacy_p3: "Integration data is read only during the execution of an explicitly started automation. The AI does not use this data to train its models.",
        privacy_h2_3: "3. Security and Retention",
        privacy_p4: "We use AES‑256 encryption in the Supabase database to protect your tokens and sensitive data.",
        
        // Refund
        refund_title: "Refund Policy",
        refund_p1: "Understanding the conditions for refunds of CATAS subscriptions processed via Stripe.",
        refund_h2_1: "1. Cancellation and Refunds",
        refund_p2: "Cancel at any time. Refunds are granted within 7 days of the initial purchase, provided credit usage has not exceeded 20% of the quota.",
        
        // Cookies
        cookies_title: "Cookie Policy",
        cookies_p1: "CATAS uses cookies to improve user experience, ensuring stable sessions and preserving preferences.",
        cookies_h2_1: "1. Essential Cookies",
        cookies_p2: "We only use essential cookies to handle secure logins, maintain state continuity, and protect against CSRF.",
        
        // Security
        security_title: "Security & Trust Center",
        security_p1: "Learn about the robust security mechanisms of our Temporal engine and AI orchestration.",
        security_h2_1: "1. Secure Maestro Architecture",
        security_p2: "Each AI‑generated plan is vetted by a secondary ValidationAgent, ensuring no external API is called with unauthorized destructive payloads.",
        
        // About
        about_title: "About CATAS",
        about_p1: "This project was born in the classrooms of Cotemig. We are a team of students passionate about technology, who took on a school assignment with the ambition to stand out. We didn’t want the project to stay only in school; we want to take it into real life and turn CATAS into a real startup.",
        about_h2_1: "Our Vision",
        about_p2: "Our vision is to democratize access to complex B2B workflows without requiring programming experience or complex no‑code tools, making AI the ultimate interface.",
        about_h2_2: "Our Mission",
        about_p3: "Eliminate unnecessary complexity in automation, helping people and companies reduce manual tasks, optimise processes and spend more time on what truly matters.",
        about_h2_3: "What drives us",
        about_p4: "We believe technology should adapt to people, not the other way around. This conviction drives CATAS development and our search for a simpler, smarter, and more accessible way to automate work. We're building CATAS with the ambition to turn this vision into a real, useful, and scalable solution.",
        
        // Contact
        contact_title: "Contact & Support",
        contact_p1: "Having trouble with an integration or automation?",
        contact_email: "Support Email: contact.catas@gmail.com",
        
        footer_rights: "© 2026 CATAS. All rights reserved."
    }
};

document.addEventListener('DOMContentLoaded', () => {
    const langSelect = document.getElementById('lang-select');
    
    // Check local storage or browser language
    let currentLang = localStorage.getItem('catas_lang') || 
                      (navigator.language.includes('pt') ? 'pt' : 'en');
    
    if (langSelect) {
        langSelect.value = currentLang;
        langSelect.addEventListener('change', (e) => {
            currentLang = e.target.value;
            localStorage.setItem('catas_lang', currentLang);
            updateContent();
            updateHTMLAttribute();
        });
    }

    function updateHTMLAttribute() {
        document.documentElement.lang = currentLang;
    }

    function updateContent() {
        const elements = document.querySelectorAll('[data-i18n]');
        elements.forEach(el => {
            const key = el.getAttribute('data-i18n');
            if (translations[currentLang] && translations[currentLang][key]) {
                el.innerHTML = translations[currentLang][key];
            }
        });
    }

    updateHTMLAttribute();
    updateContent();
});
