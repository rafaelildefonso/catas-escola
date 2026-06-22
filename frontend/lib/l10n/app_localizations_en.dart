// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CATAS';

  @override
  String get chatTitle => 'Chat';

  @override
  String get settingsTitle => 'Account Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSubLabel => 'Choose your preferred language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Portuguese';

  @override
  String get basicInfo => 'BASIC INFORMATION';

  @override
  String get fullName => 'Full Name';

  @override
  String get dangerZone => 'DANGER ZONE';

  @override
  String get deleteAccount => 'Permanently Delete Account';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get profileUpdated => 'Profile updated successfully';

  @override
  String get systemLanguage => 'System Default';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get actionRename => 'Rename';

  @override
  String get actionPin => 'Pin';

  @override
  String get actionUnpin => 'Unpin';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete your account? This action is permanent and cannot be undone.';

  @override
  String get actionSave => 'Save';

  @override
  String get drawerNewChat => 'New Chat';

  @override
  String get drawerAutomations => 'Automations';

  @override
  String get drawerIntegrations => 'Integrations';

  @override
  String get drawerDashboard => 'Dashboard';

  @override
  String get drawerRecentChats => 'Recent chats';

  @override
  String get drawerSeeAll => 'See all';

  @override
  String get drawerLoading => 'Loading...';

  @override
  String get drawerNoRecentChats => 'No recent chats';

  @override
  String get drawerNoResults => 'No results';

  @override
  String get renameChatTitle => 'Rename chat';

  @override
  String get renameChatHint => 'New name';

  @override
  String get deleteChatTitle => 'Delete chat?';

  @override
  String get deleteChatContent => 'This action cannot be undone.';

  @override
  String get upgradeRequired => 'Upgrade required';

  @override
  String get viewPlans => 'View Plans';

  @override
  String fileAttached(String fileName) {
    return 'File \'$fileName\' attached to Chat';
  }

  @override
  String get logOutTitle => 'Log out?';

  @override
  String get logOutContent => 'You will need to log in again.';

  @override
  String get logOutAction => 'Log out';

  @override
  String connectIntegrationFirst(String integrationName) {
    return 'Connect $integrationName in settings first.';
  }

  @override
  String get text => 'Text';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get edit => 'Edit';

  @override
  String get selectText => 'Select text';

  @override
  String get share => 'Share';

  @override
  String get grantAccess => 'Grant Access';

  @override
  String automationRemoved(String title) {
    return '\"$title\" removed from automations';
  }

  @override
  String get deleteAutomation => 'Delete automation';

  @override
  String get deleteAutomationTitle => 'Delete automation?';

  @override
  String get loginGoogleFailed =>
      'Failed to authenticate with Google. Try again.';

  @override
  String get loginAppleFailed =>
      'Failed to authenticate with Apple. Try again.';

  @override
  String get loginEmailSoon => 'Email login coming soon. Use Google for now.';

  @override
  String get openingCheckout => 'Opening checkout in secure browser...';

  @override
  String paymentError(String error) {
    return 'Error processing payment: $error';
  }

  @override
  String get cancelSubscriptionTitle => 'Cancel Subscription?';

  @override
  String get cancelPlan => 'Cancel plan';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get addNewCard => 'Add new card';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get feedbackThanks => 'Thank you for your feedback!';

  @override
  String openingLink(String title) {
    return 'Opening $title...';
  }

  @override
  String get configPermissions => 'Configure Permissions';

  @override
  String get sendFeedback => 'Send Feedback';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get sendSupportEmail => 'Send Support Email';

  @override
  String get accessDocs => 'Access Documentation';

  @override
  String get joinDiscordBrowser => 'Join Discord via Browser';

  @override
  String get couldNotLoadImage => 'Could not load image';

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSub => 'Receive notifications';

  @override
  String get settingsNotifAll => 'All';

  @override
  String get settingsNotifImportant => 'Important';

  @override
  String get settingsNotifNone => 'None';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsAppearanceSub => 'Interface theme';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSub => 'Interface language';

  @override
  String get settingsAccountSubsciption => 'Account & Subscription';

  @override
  String get settingsAccountConfig => 'Account Settings';

  @override
  String get settingsManageSub => 'Manage Subscription';

  @override
  String get settingsConnections => 'Connections';

  @override
  String get settingsScheduledTasks => 'Scheduled Tasks';

  @override
  String get settingsAutomations => 'Automations';

  @override
  String get settingsIntegrations => 'Integrations';

  @override
  String get settingsInfoSupport => 'Information & Support';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsGetHelp => 'Get Help';

  @override
  String get settingsLogout => 'Logout';

  @override
  String get settingsCancel => 'Cancel';

  @override
  String get integrationsConnectors => 'Connectors';

  @override
  String get integrationsManage => 'Manage connectors';

  @override
  String get integrationsConfigure => 'Configure';

  @override
  String get thinkingProcessing => 'Processing...';

  @override
  String get thinkingReasoning => 'Reasoning...';

  @override
  String get thinkingPlanning => 'Planning...';

  @override
  String get thinkingExecuting => 'Executing automation...';

  @override
  String get copied => 'Copied';

  @override
  String get textDialogTitle => 'Text';

  @override
  String get errorSelectDocument => 'Error selecting document:';

  @override
  String get errorSelectImage => 'Error selecting image:';

  @override
  String goodMorning(String name) {
    return 'Good morning $name!';
  }

  @override
  String goodAfternoon(String name) {
    return 'Good afternoon $name!';
  }

  @override
  String goodEvening(String name) {
    return 'Good evening $name!';
  }

  @override
  String get noMessages => 'No messages';

  @override
  String get aiExclusive => 'AI use is exclusive to subscribers.';

  @override
  String get unlockAccess => 'Unlock Access';

  @override
  String get askAnything => 'Ask anything...';

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get addIntegrations => 'Add Integrations';

  @override
  String get generationInterrupted => 'Generation interrupted';

  @override
  String get stopGeneration => 'Stop generation';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get files => 'Files';

  @override
  String get tools => 'Tools';

  @override
  String get webSearch => 'Web Search';

  @override
  String get integrations => 'Integrations';

  @override
  String get navigationContext => 'Navigation Context';

  @override
  String get audioComingSoon => 'Audio coming soon';

  @override
  String get recordAudio => 'Record audio';

  @override
  String get executingAutomation => 'Executing Automation:';

  @override
  String get actionExecuted => 'Action Executed';

  @override
  String get dataComplete => 'Data Complete';

  @override
  String get waitingForInfo => 'Waiting for information...';

  @override
  String get howCanIHelp => 'How can I help you today?';

  @override
  String get like => 'Like';

  @override
  String get dislike => 'Dislike';

  @override
  String get feedbackTitle => 'Why was this answer good?';

  @override
  String get feedbackTitleBad => 'Why was this answer not good?';

  @override
  String get feedbackAutomationWorked => 'Automation executed correctly';

  @override
  String get feedbackClearAnswer => 'Clear and objective answer';

  @override
  String get feedbackUsefulInfo => 'Useful and complete information';

  @override
  String get feedbackResolvedDoubt => 'Resolved my question';

  @override
  String get feedbackFastResponse => 'Fast response';

  @override
  String get feedbackAutomationFailed => 'Automation failed / didn\'t execute';

  @override
  String get feedbackConfusing => 'Confusing or hard to understand';

  @override
  String get feedbackIncorrectInfo => 'Incorrect information';

  @override
  String get feedbackIncomplete => 'Incomplete answer (missing something)';

  @override
  String get feedbackNotAnswered => 'Didn\'t answer my question';

  @override
  String get feedbackSkip => 'I prefer not to answer';

  @override
  String get feedbackSent => 'Thanks for your feedback!';

  @override
  String get loginSubtitle => 'Your AI doesn\'t just talk.';

  @override
  String get loginSubtitleExecution => 'It executes.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get loginWithEmail => 'Log in with Email';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get loginEmailFailed =>
      'Login failed. Please check your email and password.';

  @override
  String get signingUp => 'Creating account...';

  @override
  String get signUpSuccess =>
      'Account created! Please check your email to verify your account.';

  @override
  String get signUpFailed => 'Sign up failed. Please try again.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get emailHint => 'Enter your email';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get googleConnecting => 'Connecting with Google...';

  @override
  String get appleConnecting => 'Connecting with Apple...';

  @override
  String get termsAgreementPrefix => 'By continuing, you agree to our\n';

  @override
  String get andLabel => ' and ';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmpty => 'No conversation history yet.';

  @override
  String get automationActive => 'Active';

  @override
  String get automationPaused => 'Paused';

  @override
  String get automationFailed => 'Failed';

  @override
  String automationActivated(String title) {
    return '$title activated';
  }

  @override
  String automationPausadaFeedback(String title) {
    return '$title paused';
  }

  @override
  String get automationOptions => 'Options';

  @override
  String automationCreatedOn(String date, String time) {
    return 'Created on $date at $time';
  }

  @override
  String get automationIntegrations => 'Integrations:';

  @override
  String get automationViewDetails => 'View Details';

  @override
  String get automationPause => 'Pause Automation';

  @override
  String get automationActivate => 'Activate Automation';

  @override
  String get integrationsSearchHint =>
      'Search integrations (ex: Gmail, Slack...)';

  @override
  String get integrationsConnected => 'Connected';

  @override
  String get integrationsDisconnected => 'Disconnected';

  @override
  String get integrationsBlocked => 'Blocked';

  @override
  String get integrationsCategoryAll => 'All';

  @override
  String get integrationsCategoryGoogle => 'Google';

  @override
  String get integrationsCategoryProductivity => 'Productivity';

  @override
  String get integrationsCategoryCommunication => 'Communication';

  @override
  String get integrationsCategoryCRM => 'CRM/Sales';

  @override
  String get integrationsDisconnect => 'Disconnect';

  @override
  String get integrationsConnect => 'Connect';

  @override
  String get appBrandName => 'CATAS';

  @override
  String get planSuffix => 'PLAN';

  @override
  String get defaultUserName => 'User';

  @override
  String get dropFileHint => 'Drop file to attach';

  @override
  String get viewAction => 'View';

  @override
  String get searchConversations => 'Search conversations...';

  @override
  String get modifiedAt => 'Modified';

  @override
  String get featureInDevelopment => 'Feature in development';

  @override
  String get pageTitleChat => 'Chat';

  @override
  String get pageTitleAutomations => 'Automations';

  @override
  String get pageTitleIntegrations => 'Integrations';

  @override
  String get pageTitleSettings => 'Settings';

  @override
  String get pageTitleHistory => 'History';

  @override
  String get pageTitlePricing => 'Plans';

  @override
  String get pageTitleDashboard => 'Dashboard';

  @override
  String get manageBillingStripe => 'Manage Billing & Invoices at Stripe';

  @override
  String get changeProfilePhoto => 'Tap to change profile photo';

  @override
  String get account => 'Account';

  @override
  String get logout => 'Logout';

  @override
  String get nameLabel => 'Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get magicLinkButton => 'Email me a magic link';

  @override
  String get magicLinkSent => 'Check your email. Open the link to sign in.';

  @override
  String get magicLinkFailed => 'Could not send the link.';

  @override
  String get onboardingHeadline => 'What do you want to automate?';

  @override
  String get onboardingPage1Body =>
      'Pick repetitive work: email, calendar, spreadsheets, and more.';

  @override
  String get onboardingPage2Body =>
      'Describe it in plain language. CATAS builds the plan and runs it safely.';

  @override
  String get onboardingPage3Body => 'Watch every step update live in the chat.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Start in chat';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingSelectToolsTitle => 'Select your tools';

  @override
  String get onboardingSelectToolsSubtitle =>
      'Choose the integrations you want to connect to automate your routine';

  @override
  String get dashboardEstimatedROI => 'Estimated ROI';

  @override
  String get dashboardSavedInTasks => 'saved in tasks';

  @override
  String get dashboardTasksExecuted => 'Tasks Executed';

  @override
  String get dashboardCredits => 'Credits';

  @override
  String dashboardOfCredits(int limit) {
    return 'of $limit credits';
  }

  @override
  String get dashboardYouSaved => 'You saved ';

  @override
  String get dashboardHoursThisMonth => ' hours this month with CATAS.';

  @override
  String get dashboardTopIntegrations => 'Top Integrations';

  @override
  String get dashboardMostUsedTools => 'Your most used tools';

  @override
  String dashboardUnlock(String plan) {
    return 'Unlock $plan';
  }

  @override
  String get dashboardUpgrade => 'Upgrade';

  @override
  String get dashboardMaxPlanActive => 'MAX Plan Active';

  @override
  String get dashboardMaxPlanDescription =>
      'You have full access to all AI models, custom workflows and maximum execution priority.';

  @override
  String get dashboardUsed => 'used';

  @override
  String get dashboardSeeMore => 'See more...';

  @override
  String get dashboardExplorePrompts => 'Explore more prompts';

  @override
  String get dashboardWeeklyDayMon => 'Mon';

  @override
  String get dashboardWeeklyDayTue => 'Tue';

  @override
  String get dashboardWeeklyDayWed => 'Wed';

  @override
  String get dashboardWeeklyDayThu => 'Thu';

  @override
  String get dashboardWeeklyDayFri => 'Fri';

  @override
  String get dashboardWeeklyDaySat => 'Sat';

  @override
  String get dashboardWeeklyDaySun => 'Sun';

  @override
  String get dashboardAutomationsExecuted => 'Automations Executed';

  @override
  String get dashboardLast7Days => 'Last 7 days';

  @override
  String get dashboardTasks => 'tasks';
}
