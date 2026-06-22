const translations = {
    pt: {
        nav_about: "Sobre Nós",
        nav_terms: "Termos",
        nav_privacy: "Privacidade",
        nav_contact: "Contato",
        
        last_updated: "Última atualização: [Data Placeholder]",
        
        // General text
        placeholder_text: "[Conteúdo temporário. Substitua pelo texto real na versão final.]",
        
        // Terms
        terms_title: "Termos e Condições de Uso",
        terms_p1: "[Placeholder] Bem-vindo aos Termos de Uso do CATAS. Ao utilizar nossa plataforma de automação com IA, você concorda com estes termos.",
        terms_h2_1: "1. Aceitação dos Termos",
        terms_p2: "[Placeholder] O uso do CATAS (Context Aware Task Automation System) está sujeito a estes termos e a eventuais atualizações.",
        terms_h2_2: "2. Assinaturas e Créditos",
        terms_p3: "[Placeholder] Os planos (Free, Pro, Max) operam com um sistema de tokens. A renovação ocorre mensalmente e os créditos não acumulam (sujeito à tabela de preços atual).",
        terms_h2_3: "3. Uso Aceitável da IA",
        terms_p4: "[Placeholder] Você concorda em não usar o CATAS para fins ilícitos, spam cruzado ou tentativas de engenharia reversa do nosso Maestro Agent.",
        
        // Privacy
        privacy_title: "Política de Privacidade",
        privacy_p1: "[Placeholder] A privacidade dos seus dados e integrações é nossa prioridade no CATAS.",
        privacy_h2_1: "1. Coleta de Dados",
        privacy_p2: "[Placeholder] Coletamos dados essenciais como nome, email e tokens OAuth das integrações que você escolhe conectar.",
        privacy_h2_2: "2. Como a IA processa seus dados",
        privacy_p3: "[Placeholder] Os dados de integrações só são lidos no contexto e janela de execução de uma automação expressamente solicitada. A IA **não treina** seus modelos com os dados confidenciais gerados.",
        privacy_h2_3: "3. Retenção e Segurança",
        privacy_p4: "[Placeholder] Utilizamos criptografia AES-256 no banco de dados Supabase para assegurar seus tokens restritos.",
        
        // Refund
        refund_title: "Política de Reembolso",
        refund_p1: "[Placeholder] Entender os casos aplicáveis para reembolsos de assinaturas CATAS geridas via Stripe.",
        refund_h2_1: "1. Prazo de Cancelamento",
        refund_p2: "[Placeholder] Você pode cancelar a qualquer momento. Reembolsos são aplicáveis em até 7 dias corridos após a compra inicial, desde que o consumo de créditos não tenha excedido 20%.",
        
        // Cookies
        cookies_title: "Política de Cookies",
        cookies_p1: "[Placeholder] Como o CATAS utiliza cookies para melhorar a experiência SaaS.",
        cookies_h2_1: "1. Cookies Essenciais",
        cookies_p2: "[Placeholder] Usamos cookies estritamente necessários para gerenciar sessões de login seguras, continuidade de estado temporal e segurança Cross-Site Request Forgery (CSRF).",
        
        // Security
        security_title: "Centro de Segurança e Confiança",
        security_p1: "[Placeholder] Conheça os mecanismos de proteção do motor Temporal e da nossa orquestração.",
        security_h2_1: "1. Arquitetura Maestro Segura",
        security_p2: "[Placeholder] Todo plano gerado por IA passa por um agente secundário ('ValidationAgent') garantindo que nenhuma API externa seja chamada com payloads destrutivos não autorizados.",
        
        // About
        about_title: "Sobre o CATAS",
        about_p1: "[Placeholder] O CATAS - Context Aware Task Automation System - foi construído com a visão de que falar com a máquina deveria ser suficiente para programá-la.",
        about_h2_1: "Nossa Visão",
        about_p2: "[Placeholder] Democratizar o acesso a workflows B2B complexos sem exigir experiência em lógica de programação ou ferramentas nocode complexas. A IA como interface definitiva.",
        
        // Contact
        contact_title: "Contato e Suporte",
        contact_p1: "[Placeholder] Precisa de ajuda com uma integração ou automação falha?",
        contact_email: "Email de Suporte: suporte@catas.ai [Placeholder]",
        
        footer_rights: "© 2026 CATAS. Todos os direitos reservados."
    },
    en: {
        nav_about: "About Us",
        nav_terms: "Terms",
        nav_privacy: "Privacy",
        nav_contact: "Contact",
        
        last_updated: "Last updated: [Date Placeholder]",
        
        // General text
        placeholder_text: "[Temporary content. Replace with actual text in the final version.]",
        
        // Terms
        terms_title: "Terms and Conditions of Use",
        terms_p1: "[Placeholder] Welcome to CATAS Terms of Use. By using our AI automation platform, you agree to these terms.",
        terms_h2_1: "1. Acceptance of Terms",
        terms_p2: "[Placeholder] The use of CATAS (Context Aware Task Automation System) is subject to these terms and any future updates.",
        terms_h2_2: "2. Subscriptions and Credits",
        terms_p3: "[Placeholder] Plans (Free, Pro, Max) operate on a token-based credit system. Renewals happen monthly and unused credits do not roll over.",
        terms_h2_3: "3. Acceptable AI Usage",
        terms_p4: "[Placeholder] You agree not to use CATAS for illegal purposes, spamming, or reverse-engineering our Maestro Agent pipeline.",
        
        // Privacy
        privacy_title: "Privacy Policy",
        privacy_p1: "[Placeholder] The privacy of your data and API integrations is our top priority at CATAS.",
        privacy_h2_1: "1. Data Collection",
        privacy_p2: "[Placeholder] We collect essential data such as name, email, and OAuth tokens of the platforms you connect.",
        privacy_h2_2: "2. How AI processes your data",
        privacy_p3: "[Placeholder] Integration data is read exclusively within the scope of an actively running automation. AI models **do not train** on your personal workflows.",
        privacy_h2_3: "3. Security and Retention",
        privacy_p4: "[Placeholder] We employ AES-256 encryption within our Supabase deployment to secure your API tokens.",
        
        // Refund
        refund_title: "Refund Policy",
        refund_p1: "[Placeholder] Understanding refund eligibility for CATAS subscriptions processed via Stripe.",
        refund_h2_1: "1. Cancellation and Refunds",
        refund_p2: "[Placeholder] Cancel anytime. Refunds apply if requested within 7 days of initial purchase, provided credit usage hasn't exceeded 20%.",
        
        // Cookies
        cookies_title: "Cookie Policy",
        cookies_p1: "[Placeholder] How CATAS uses cookies to enhance your SaaS experience.",
        cookies_h2_1: "1. Essential Cookies",
        cookies_p2: "[Placeholder] We only use strictly necessary cookies to handle secure logins, Temporal state continuity, and CSRF protection.",
        
        // Security
        security_title: "Security & Trust Center",
        security_p1: "[Placeholder] Learn about the robust protection of our Temporal engine and AI orchestration.",
        security_h2_1: "1. Secure Maestro Architecture",
        security_p2: "[Placeholder] Every AI-generated plan is vetted by a secondary 'ValidationAgent' meaning no external API is hit with unauthorized destructive payloads.",
        
        // About
        about_title: "About CATAS",
        about_p1: "[Placeholder] CATAS - Context Aware Task Automation System - was built upon the vision that talking to the machine should be enough to program it.",
        about_h2_1: "Our Vision",
        about_p2: "[Placeholder] To democratize B2B automation. No block-building, no code, just the AI acting as the ultimate interface.",
        
        // Contact
        contact_title: "Contact & Support",
        contact_p1: "[Placeholder] Having issues with a failing integration or automation?",
        contact_email: "Support Email: support@catas.ai [Placeholder]",
        
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
