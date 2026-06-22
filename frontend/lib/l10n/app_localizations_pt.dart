// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'CATAS';

  @override
  String get chatTitle => 'Chat';

  @override
  String get settingsTitle => 'Configurações da Conta';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSubLabel => 'Escolha seu idioma de preferência';

  @override
  String get languageEnglish => 'Inglês';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get basicInfo => 'INFORMAÇÕES BÁSICAS';

  @override
  String get fullName => 'Nome Completo';

  @override
  String get dangerZone => 'ZONA DE PERIGO';

  @override
  String get deleteAccount => 'Excluir Conta Permanentemente';

  @override
  String get saveChanges => 'Salvar Alterações';

  @override
  String get profileUpdated => 'Perfil atualizado com sucesso';

  @override
  String get systemLanguage => 'Padrão do Sistema';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get actionRename => 'Renomear';

  @override
  String get actionPin => 'Fixar';

  @override
  String get actionUnpin => 'Desafixar';

  @override
  String get actionDelete => 'Excluir';

  @override
  String get actionCancel => 'Cancelar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get deleteAccountConfirmation =>
      'Tem certeza que deseja excluir sua conta? Esta ação é permanente e não pode ser desfeita.';

  @override
  String get actionSave => 'Salvar';

  @override
  String get drawerNewChat => 'Novo Chat';

  @override
  String get drawerAutomations => 'Automações';

  @override
  String get drawerIntegrations => 'Integrações';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerRecentChats => 'Conversas recentes';

  @override
  String get drawerSeeAll => 'Ver todos';

  @override
  String get drawerLoading => 'Carregando...';

  @override
  String get drawerNoRecentChats => 'Nenhum chat recente';

  @override
  String get drawerNoResults => 'Nenhum resultado';

  @override
  String get renameChatTitle => 'Renomear chat';

  @override
  String get renameChatHint => 'Novo nome';

  @override
  String get deleteChatTitle => 'Excluir chat?';

  @override
  String get deleteChatContent => 'Essa ação não pode ser desfeita.';

  @override
  String get upgradeRequired => 'Upgrade necessário';

  @override
  String get viewPlans => 'Ver Planos';

  @override
  String fileAttached(String fileName) {
    return 'Arquivo \'$fileName\' anexado ao Chat';
  }

  @override
  String get logOutTitle => 'Sair da conta?';

  @override
  String get logOutContent => 'Você precisará fazer login novamente.';

  @override
  String get logOutAction => 'Sair';

  @override
  String connectIntegrationFirst(String integrationName) {
    return 'Conecte o $integrationName nas configurações primeiro.';
  }

  @override
  String get text => 'Texto';

  @override
  String get close => 'Fechar';

  @override
  String get copy => 'Copiar';

  @override
  String get edit => 'Editar';

  @override
  String get selectText => 'Selecionar texto';

  @override
  String get share => 'Compartilhar';

  @override
  String get grantAccess => 'Liberar Acesso';

  @override
  String automationRemoved(String title) {
    return '\"$title\" removida das automações';
  }

  @override
  String get deleteAutomation => 'Excluir automação';

  @override
  String get deleteAutomationTitle => 'Excluir automação?';

  @override
  String get loginGoogleFailed =>
      'Falha ao autenticar com Google. Tente novamente.';

  @override
  String get loginAppleFailed =>
      'Falha ao autenticar com Apple. Tente novamente.';

  @override
  String get loginEmailSoon =>
      'Login com email em breve. Use o Google por enquanto.';

  @override
  String get openingCheckout => 'Abrindo checkout no navegador seguro...';

  @override
  String paymentError(String error) {
    return 'Erro ao processar pagamento: $error';
  }

  @override
  String get cancelSubscriptionTitle => 'Cancelar Assinatura?';

  @override
  String get cancelPlan => 'Cancelar plano';

  @override
  String get paymentMethod => 'Forma de Pagamento';

  @override
  String get addNewCard => 'Adicionar novo cartão';

  @override
  String get upgrade => 'Fazer Upgrade';

  @override
  String get feedbackThanks => 'Obrigado pelo seu feedback!';

  @override
  String openingLink(String title) {
    return 'Abrindo $title...';
  }

  @override
  String get configPermissions => 'Configurar Permissões';

  @override
  String get sendFeedback => 'Enviar Feedback';

  @override
  String get termsOfService => 'Termos de Serviço';

  @override
  String get privacyPolicy => 'Política de Privacidade';

  @override
  String get sendSupportEmail => 'Enviar Email de Suporte';

  @override
  String get accessDocs => 'Acessar Documentação';

  @override
  String get joinDiscordBrowser => 'Entrar no Discord via Navegador';

  @override
  String get couldNotLoadImage => 'Não foi possível carregar a imagem';

  @override
  String get imageUnavailable => 'Imagem indisponível';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get settingsPreferences => 'Preferências';

  @override
  String get settingsNotifications => 'Notificações';

  @override
  String get settingsNotificationsSub => 'Receber notificações';

  @override
  String get settingsNotifAll => 'Todas';

  @override
  String get settingsNotifImportant => 'Importantes';

  @override
  String get settingsNotifNone => 'Nenhuma';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsAppearanceSub => 'Tema da interface';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSub => 'Idioma da interface';

  @override
  String get settingsAccountSubsciption => 'Conta & Assinatura';

  @override
  String get settingsAccountConfig => 'Configurações da Conta';

  @override
  String get settingsManageSub => 'Gerenciar Assinatura';

  @override
  String get settingsConnections => 'Conexões';

  @override
  String get settingsScheduledTasks => 'Tarefas Agendadas';

  @override
  String get settingsAutomations => 'Automações';

  @override
  String get settingsIntegrations => 'Integrações';

  @override
  String get settingsInfoSupport => 'Informações e Suporte';

  @override
  String get settingsAbout => 'Sobre';

  @override
  String get settingsGetHelp => 'Obter Ajuda';

  @override
  String get settingsLogout => 'Sair da Conta';

  @override
  String get settingsCancel => 'Cancelar';

  @override
  String get integrationsConnectors => 'Conectores';

  @override
  String get integrationsManage => 'Gerenciar conectores';

  @override
  String get integrationsConfigure => 'Configurar';

  @override
  String get thinkingProcessing => 'Processando...';

  @override
  String get thinkingReasoning => 'Raciocinando...';

  @override
  String get thinkingPlanning => 'Planejando...';

  @override
  String get thinkingExecuting => 'Executando automação...';

  @override
  String get copied => 'Copiado';

  @override
  String get textDialogTitle => 'Texto';

  @override
  String get errorSelectDocument => 'Erro ao selecionar documento:';

  @override
  String get errorSelectImage => 'Erro ao selecionar imagem:';

  @override
  String goodMorning(String name) {
    return 'Bom dia $name!';
  }

  @override
  String goodAfternoon(String name) {
    return 'Boa tarde $name!';
  }

  @override
  String goodEvening(String name) {
    return 'Boa noite $name!';
  }

  @override
  String get noMessages => 'Nenhuma mensagem';

  @override
  String get aiExclusive => 'O uso da IA é exclusivo para assinantes.';

  @override
  String get unlockAccess => 'Liberar Acesso';

  @override
  String get askAnything => 'Pergunte o que quiser...';

  @override
  String get addAttachment => 'Adicionar anexo';

  @override
  String get addIntegrations => 'Adicionar Integrações';

  @override
  String get generationInterrupted => 'Geração interrompida';

  @override
  String get stopGeneration => 'Parar geração';

  @override
  String get camera => 'Câmera';

  @override
  String get gallery => 'Galeria';

  @override
  String get files => 'Arquivos';

  @override
  String get tools => 'Ferramentas';

  @override
  String get webSearch => 'Busca na Web';

  @override
  String get integrations => 'Integrações';

  @override
  String get navigationContext => 'Contexto de Navegação';

  @override
  String get audioComingSoon => 'Áudio em breve';

  @override
  String get recordAudio => 'Gravar áudio';

  @override
  String get executingAutomation => 'Executando Automação:';

  @override
  String get actionExecuted => 'Ação Executada';

  @override
  String get dataComplete => 'Dados Completos';

  @override
  String get waitingForInfo => 'Aguardando Informações...';

  @override
  String get howCanIHelp => 'Como posso facilitar seu dia hoje?';

  @override
  String get like => 'Gostei';

  @override
  String get dislike => 'Não gostei';

  @override
  String get feedbackTitle => 'Por que esta resposta foi boa?';

  @override
  String get feedbackTitleBad => 'Por que esta resposta não foi boa?';

  @override
  String get feedbackAutomationWorked => 'Automação executou corretamente';

  @override
  String get feedbackClearAnswer => 'Resposta clara e objetiva';

  @override
  String get feedbackUsefulInfo => 'Informação útil e completa';

  @override
  String get feedbackResolvedDoubt => 'Resolveu minha dúvida';

  @override
  String get feedbackFastResponse => 'Resposta rápida';

  @override
  String get feedbackAutomationFailed => 'Automação falhou / não executou';

  @override
  String get feedbackConfusing => 'Resposta confusa ou difícil de entender';

  @override
  String get feedbackIncorrectInfo => 'Informação incorreta';

  @override
  String get feedbackIncomplete => 'Resposta incompleta (faltou algo)';

  @override
  String get feedbackNotAnswered => 'Não respondeu minha pergunta';

  @override
  String get feedbackSkip => 'Não quero responder';

  @override
  String get feedbackSent => 'Obrigado pelo feedback!';

  @override
  String get loginSubtitle => 'Sua IA não apenas fala.';

  @override
  String get loginSubtitleExecution => 'Ela executa.';

  @override
  String get continueWithGoogle => 'Continue com Google';

  @override
  String get continueWithApple => 'Continue com Apple';

  @override
  String get loginWithEmail => 'Entrar com Email';

  @override
  String get signingIn => 'Entrando...';

  @override
  String get loginEmailFailed => 'Falha no login. Verifique seu email e senha.';

  @override
  String get signingUp => 'Criando conta...';

  @override
  String get signUpSuccess =>
      'Conta criada! Verifique seu email para confirmar sua conta.';

  @override
  String get signUpFailed => 'Falha ao criar conta. Tente novamente.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Senha';

  @override
  String get emailHint => 'Digite seu email';

  @override
  String get passwordHint => 'Digite sua senha';

  @override
  String get signIn => 'Entrar';

  @override
  String get signUp => 'Criar conta';

  @override
  String get dontHaveAccount => 'Não tem uma conta?';

  @override
  String get alreadyHaveAccount => 'Já tem uma conta?';

  @override
  String get backToLogin => 'Voltar para login';

  @override
  String get googleConnecting => 'Conectando com Google...';

  @override
  String get appleConnecting => 'Conectando com Apple...';

  @override
  String get termsAgreementPrefix => 'Ao continuar, você concorda com nossos\n';

  @override
  String get andLabel => ' e ';

  @override
  String get historyTitle => 'Histórico';

  @override
  String get historyEmpty => 'Nenhum histórico de conversa ainda.';

  @override
  String get automationActive => 'Ativa';

  @override
  String get automationPaused => 'Pausada';

  @override
  String get automationFailed => 'Falha';

  @override
  String automationActivated(String title) {
    return '$title ativada';
  }

  @override
  String automationPausadaFeedback(String title) {
    return '$title pausada';
  }

  @override
  String get automationOptions => 'Opções';

  @override
  String automationCreatedOn(String date, String time) {
    return 'Criado em $date às $time';
  }

  @override
  String get automationIntegrations => 'Integrações:';

  @override
  String get automationViewDetails => 'Ver detalhes';

  @override
  String get automationPause => 'Pausar automação';

  @override
  String get automationActivate => 'Ativar automação';

  @override
  String get integrationsSearchHint =>
      'Buscar integrações (ex: Gmail, Slack...)';

  @override
  String get integrationsConnected => 'Conectado';

  @override
  String get integrationsDisconnected => 'Desconectado';

  @override
  String get integrationsBlocked => 'Bloqueado';

  @override
  String get integrationsCategoryAll => 'Todas';

  @override
  String get integrationsCategoryGoogle => 'Google';

  @override
  String get integrationsCategoryProductivity => 'Produtividade';

  @override
  String get integrationsCategoryCommunication => 'Comunicação';

  @override
  String get integrationsCategoryCRM => 'CRM/Vendas';

  @override
  String get integrationsDisconnect => 'Desconectar';

  @override
  String get integrationsConnect => 'Conectar';

  @override
  String get appBrandName => 'CATAS';

  @override
  String get planSuffix => 'PLANO';

  @override
  String get defaultUserName => 'Usuário';

  @override
  String get dropFileHint => 'Solte o arquivo para anexar';

  @override
  String get viewAction => 'Ver';

  @override
  String get searchConversations => 'Pesquisar conversas...';

  @override
  String get modifiedAt => 'Modificado';

  @override
  String get featureInDevelopment => 'Recurso em desenvolvimento';

  @override
  String get pageTitleChat => 'Chat';

  @override
  String get pageTitleAutomations => 'Automações';

  @override
  String get pageTitleIntegrations => 'Integrações';

  @override
  String get pageTitleSettings => 'Configurações';

  @override
  String get pageTitleHistory => 'Histórico';

  @override
  String get pageTitlePricing => 'Planos';

  @override
  String get pageTitleDashboard => 'Dashboard';

  @override
  String get manageBillingStripe => 'Gerenciar Assinatura e Faturas no Stripe';

  @override
  String get changeProfilePhoto => 'Toque para alterar a foto de perfil';

  @override
  String get account => 'Conta';

  @override
  String get logout => 'Sair';

  @override
  String get nameLabel => 'Nome';

  @override
  String get emailLabel => 'Email';

  @override
  String get magicLinkButton => 'Receber link por email';

  @override
  String get magicLinkSent =>
      'Enviamos um link para seu email. Abra-o para entrar.';

  @override
  String get magicLinkFailed => 'Não foi possível enviar o link.';

  @override
  String get onboardingHeadline => 'O que você quer automatizar?';

  @override
  String get onboardingPage1Body =>
      'Escolha tarefas repetitivas: email, agenda, planilhas e muito mais.';

  @override
  String get onboardingPage2Body =>
      'Descreva em linguagem natural. O CATAS monta o plano e executa com segurança.';

  @override
  String get onboardingPage3Body =>
      'Acompanhe cada passo no chat em tempo real.';

  @override
  String get onboardingNext => 'Próximo';

  @override
  String get onboardingStart => 'Começar no chat';

  @override
  String get onboardingSkip => 'Pular';

  @override
  String get onboardingSelectToolsTitle => 'Selecione suas ferramentas';

  @override
  String get onboardingSelectToolsSubtitle =>
      'Escolha as integrações que você deseja conectar para automatizar sua rotina';

  @override
  String get dashboardEstimatedROI => 'ROI Estimado';

  @override
  String get dashboardSavedInTasks => 'economizado em tarefas';

  @override
  String get dashboardTasksExecuted => 'Tarefas Executadas';

  @override
  String get dashboardCredits => 'Créditos';

  @override
  String dashboardOfCredits(int limit) {
    return 'de $limit créditos';
  }

  @override
  String get dashboardYouSaved => 'Você já economizou ';

  @override
  String get dashboardHoursThisMonth => ' horas este mês com o CATAS.';

  @override
  String get dashboardTopIntegrations => 'Top Integrações';

  @override
  String get dashboardMostUsedTools => 'Suas ferramentas mais utilizadas';

  @override
  String dashboardUnlock(String plan) {
    return 'Desbloqueie o $plan';
  }

  @override
  String get dashboardUpgrade => 'Fazer Upgrade';

  @override
  String get dashboardMaxPlanActive => 'Plano MAX Ativo';

  @override
  String get dashboardMaxPlanDescription =>
      'Você tem acesso total a todos os modelos de IA, workflows customizados e prioridade máxima de execução.';

  @override
  String get dashboardUsed => 'usado';

  @override
  String get dashboardSeeMore => 'Ver mais...';

  @override
  String get dashboardExplorePrompts => 'Explore mais prompts';

  @override
  String get dashboardWeeklyDayMon => 'Seg';

  @override
  String get dashboardWeeklyDayTue => 'Ter';

  @override
  String get dashboardWeeklyDayWed => 'Qua';

  @override
  String get dashboardWeeklyDayThu => 'Qui';

  @override
  String get dashboardWeeklyDayFri => 'Sex';

  @override
  String get dashboardWeeklyDaySat => 'Sáb';

  @override
  String get dashboardWeeklyDaySun => 'Dom';

  @override
  String get dashboardAutomationsExecuted => 'Automações Executadas';

  @override
  String get dashboardLast7Days => 'Últimos 7 dias';

  @override
  String get dashboardTasks => 'tarefas';
}
