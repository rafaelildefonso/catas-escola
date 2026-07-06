import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CATAS'**
  String get appTitle;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get settingsTitle;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSubLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get languageSubLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get languagePortuguese;

  /// No description provided for @basicInfo.
  ///
  /// In en, this message translates to:
  /// **'BASIC INFORMATION'**
  String get basicInfo;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get dangerZone;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Account'**
  String get deleteAccount;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// No description provided for @systemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @actionRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get actionRename;

  /// No description provided for @actionPin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get actionPin;

  /// No description provided for @actionUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get actionUnpin;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @deleteAccountConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action is permanent and cannot be undone.'**
  String get deleteAccountConfirmation;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @drawerNewChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get drawerNewChat;

  /// No description provided for @drawerAutomations.
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get drawerAutomations;

  /// No description provided for @drawerIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get drawerIntegrations;

  /// No description provided for @drawerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get drawerDashboard;

  /// No description provided for @drawerRecentChats.
  ///
  /// In en, this message translates to:
  /// **'Recent chats'**
  String get drawerRecentChats;

  /// No description provided for @drawerSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get drawerSeeAll;

  /// No description provided for @drawerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get drawerLoading;

  /// No description provided for @drawerNoRecentChats.
  ///
  /// In en, this message translates to:
  /// **'No recent chats'**
  String get drawerNoRecentChats;

  /// No description provided for @drawerNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get drawerNoResults;

  /// No description provided for @renameChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename chat'**
  String get renameChatTitle;

  /// No description provided for @renameChatHint.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get renameChatHint;

  /// No description provided for @deleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chat?'**
  String get deleteChatTitle;

  /// No description provided for @deleteChatContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteChatContent;

  /// No description provided for @upgradeRequired.
  ///
  /// In en, this message translates to:
  /// **'Upgrade required'**
  String get upgradeRequired;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlans;

  /// No description provided for @fileAttached.
  ///
  /// In en, this message translates to:
  /// **'File \'{fileName}\' attached to Chat'**
  String fileAttached(String fileName);

  /// No description provided for @logOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logOutTitle;

  /// No description provided for @logOutContent.
  ///
  /// In en, this message translates to:
  /// **'You will need to log in again.'**
  String get logOutContent;

  /// No description provided for @logOutAction.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOutAction;

  /// No description provided for @connectIntegrationFirst.
  ///
  /// In en, this message translates to:
  /// **'Connect {integrationName} in settings first.'**
  String connectIntegrationFirst(String integrationName);

  /// No description provided for @text.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get text;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @selectText.
  ///
  /// In en, this message translates to:
  /// **'Select text'**
  String get selectText;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @grantAccess.
  ///
  /// In en, this message translates to:
  /// **'Grant Access'**
  String get grantAccess;

  /// No description provided for @automationRemoved.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" removed from automations'**
  String automationRemoved(String title);

  /// No description provided for @deleteAutomation.
  ///
  /// In en, this message translates to:
  /// **'Delete automation'**
  String get deleteAutomation;

  /// No description provided for @deleteAutomationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete automation?'**
  String get deleteAutomationTitle;

  /// No description provided for @loginGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to authenticate with Google. Try again.'**
  String get loginGoogleFailed;

  /// No description provided for @loginAppleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to authenticate with Apple. Try again.'**
  String get loginAppleFailed;

  /// No description provided for @loginEmailSoon.
  ///
  /// In en, this message translates to:
  /// **'Email login coming soon. Use Google for now.'**
  String get loginEmailSoon;

  /// No description provided for @openingCheckout.
  ///
  /// In en, this message translates to:
  /// **'Opening checkout in secure browser...'**
  String get openingCheckout;

  /// No description provided for @paymentError.
  ///
  /// In en, this message translates to:
  /// **'Error processing payment: {error}'**
  String paymentError(String error);

  /// No description provided for @cancelSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription?'**
  String get cancelSubscriptionTitle;

  /// No description provided for @cancelPlan.
  ///
  /// In en, this message translates to:
  /// **'Cancel plan'**
  String get cancelPlan;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @addNewCard.
  ///
  /// In en, this message translates to:
  /// **'Add new card'**
  String get addNewCard;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @feedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback!'**
  String get feedbackThanks;

  /// No description provided for @openingLink.
  ///
  /// In en, this message translates to:
  /// **'Opening {title}...'**
  String openingLink(String title);

  /// No description provided for @configPermissions.
  ///
  /// In en, this message translates to:
  /// **'Configure Permissions'**
  String get configPermissions;

  /// No description provided for @sendFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get sendFeedback;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @sendSupportEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Support Email'**
  String get sendSupportEmail;

  /// No description provided for @accessDocs.
  ///
  /// In en, this message translates to:
  /// **'Access Documentation'**
  String get accessDocs;

  /// No description provided for @joinDiscordBrowser.
  ///
  /// In en, this message translates to:
  /// **'Join Discord via Browser'**
  String get joinDiscordBrowser;

  /// No description provided for @couldNotLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not load image'**
  String get couldNotLoadImage;

  /// No description provided for @imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get imageUnavailable;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications'**
  String get settingsNotificationsSub;

  /// No description provided for @settingsNotifAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get settingsNotifAll;

  /// No description provided for @settingsNotifImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get settingsNotifImportant;

  /// No description provided for @settingsNotifNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsNotifNone;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsAppearanceSub.
  ///
  /// In en, this message translates to:
  /// **'Interface theme'**
  String get settingsAppearanceSub;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSub.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get settingsLanguageSub;

  /// No description provided for @settingsAccountSubsciption.
  ///
  /// In en, this message translates to:
  /// **'Account & Subscription'**
  String get settingsAccountSubsciption;

  /// No description provided for @settingsAccountConfig.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get settingsAccountConfig;

  /// No description provided for @settingsManageSub.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get settingsManageSub;

  /// No description provided for @settingsConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get settingsConnections;

  /// No description provided for @settingsScheduledTasks.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Tasks'**
  String get settingsScheduledTasks;

  /// No description provided for @settingsAutomations.
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get settingsAutomations;

  /// No description provided for @settingsIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get settingsIntegrations;

  /// No description provided for @settingsInfoSupport.
  ///
  /// In en, this message translates to:
  /// **'Information & Support'**
  String get settingsInfoSupport;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsGetHelp.
  ///
  /// In en, this message translates to:
  /// **'Get Help'**
  String get settingsGetHelp;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get settingsLogout;

  /// No description provided for @settingsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsCancel;

  /// No description provided for @integrationsConnectors.
  ///
  /// In en, this message translates to:
  /// **'Connectors'**
  String get integrationsConnectors;

  /// No description provided for @integrationsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage connectors'**
  String get integrationsManage;

  /// No description provided for @integrationsConfigure.
  ///
  /// In en, this message translates to:
  /// **'Configure'**
  String get integrationsConfigure;

  /// No description provided for @thinkingProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get thinkingProcessing;

  /// No description provided for @thinkingReasoning.
  ///
  /// In en, this message translates to:
  /// **'Reasoning...'**
  String get thinkingReasoning;

  /// No description provided for @thinkingPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning...'**
  String get thinkingPlanning;

  /// No description provided for @thinkingExecuting.
  ///
  /// In en, this message translates to:
  /// **'Executing automation...'**
  String get thinkingExecuting;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @textDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get textDialogTitle;

  /// No description provided for @errorSelectDocument.
  ///
  /// In en, this message translates to:
  /// **'Error selecting document:'**
  String get errorSelectDocument;

  /// No description provided for @errorSelectImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image:'**
  String get errorSelectImage;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning {name}!'**
  String goodMorning(String name);

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon {name}!'**
  String goodAfternoon(String name);

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening {name}!'**
  String goodEvening(String name);

  /// No description provided for @noMessages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get noMessages;

  /// No description provided for @aiExclusive.
  ///
  /// In en, this message translates to:
  /// **'AI use is exclusive to subscribers.'**
  String get aiExclusive;

  /// No description provided for @unlockAccess.
  ///
  /// In en, this message translates to:
  /// **'Unlock Access'**
  String get unlockAccess;

  /// No description provided for @askAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask anything...'**
  String get askAnything;

  /// No description provided for @addAttachment.
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// No description provided for @addIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Add Integrations'**
  String get addIntegrations;

  /// No description provided for @generationInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Generation interrupted'**
  String get generationInterrupted;

  /// No description provided for @stopGeneration.
  ///
  /// In en, this message translates to:
  /// **'Stop generation'**
  String get stopGeneration;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get files;

  /// No description provided for @tools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get tools;

  /// No description provided for @webSearch.
  ///
  /// In en, this message translates to:
  /// **'Web Search'**
  String get webSearch;

  /// No description provided for @integrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrations;

  /// No description provided for @navigationContext.
  ///
  /// In en, this message translates to:
  /// **'Navigation Context'**
  String get navigationContext;

  /// No description provided for @audioComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Audio coming soon'**
  String get audioComingSoon;

  /// No description provided for @recordAudio.
  ///
  /// In en, this message translates to:
  /// **'Record audio'**
  String get recordAudio;

  /// No description provided for @executingAutomation.
  ///
  /// In en, this message translates to:
  /// **'Executing Automation:'**
  String get executingAutomation;

  /// No description provided for @actionExecuted.
  ///
  /// In en, this message translates to:
  /// **'Action Executed'**
  String get actionExecuted;

  /// No description provided for @dataComplete.
  ///
  /// In en, this message translates to:
  /// **'Data Complete'**
  String get dataComplete;

  /// No description provided for @waitingForInfo.
  ///
  /// In en, this message translates to:
  /// **'Waiting for information...'**
  String get waitingForInfo;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help you today?'**
  String get howCanIHelp;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @dislike.
  ///
  /// In en, this message translates to:
  /// **'Dislike'**
  String get dislike;

  /// No description provided for @feedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Why was this answer good?'**
  String get feedbackTitle;

  /// No description provided for @feedbackTitleBad.
  ///
  /// In en, this message translates to:
  /// **'Why was this answer not good?'**
  String get feedbackTitleBad;

  /// No description provided for @feedbackAutomationWorked.
  ///
  /// In en, this message translates to:
  /// **'Automation executed correctly'**
  String get feedbackAutomationWorked;

  /// No description provided for @feedbackClearAnswer.
  ///
  /// In en, this message translates to:
  /// **'Clear and objective answer'**
  String get feedbackClearAnswer;

  /// No description provided for @feedbackUsefulInfo.
  ///
  /// In en, this message translates to:
  /// **'Useful and complete information'**
  String get feedbackUsefulInfo;

  /// No description provided for @feedbackResolvedDoubt.
  ///
  /// In en, this message translates to:
  /// **'Resolved my question'**
  String get feedbackResolvedDoubt;

  /// No description provided for @feedbackFastResponse.
  ///
  /// In en, this message translates to:
  /// **'Fast response'**
  String get feedbackFastResponse;

  /// No description provided for @feedbackAutomationFailed.
  ///
  /// In en, this message translates to:
  /// **'Automation failed / didn\'t execute'**
  String get feedbackAutomationFailed;

  /// No description provided for @feedbackConfusing.
  ///
  /// In en, this message translates to:
  /// **'Confusing or hard to understand'**
  String get feedbackConfusing;

  /// No description provided for @feedbackIncorrectInfo.
  ///
  /// In en, this message translates to:
  /// **'Incorrect information'**
  String get feedbackIncorrectInfo;

  /// No description provided for @feedbackIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete answer (missing something)'**
  String get feedbackIncomplete;

  /// No description provided for @feedbackNotAnswered.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t answer my question'**
  String get feedbackNotAnswered;

  /// No description provided for @feedbackSkip.
  ///
  /// In en, this message translates to:
  /// **'I prefer not to answer'**
  String get feedbackSkip;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get feedbackSent;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your AI doesn\'t just talk.'**
  String get loginSubtitle;

  /// No description provided for @loginSubtitleExecution.
  ///
  /// In en, this message translates to:
  /// **'It executes.'**
  String get loginSubtitleExecution;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Log in with Email'**
  String get loginWithEmail;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @loginEmailFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please check your email and password.'**
  String get loginEmailFailed;

  /// No description provided for @signingUp.
  ///
  /// In en, this message translates to:
  /// **'Creating account...'**
  String get signingUp;

  /// No description provided for @signUpSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get signUpSuccess;

  /// No description provided for @signUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign up failed. Please try again.'**
  String get signUpFailed;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get backToLogin;

  /// No description provided for @googleConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting with Google...'**
  String get googleConnecting;

  /// No description provided for @appleConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting with Apple...'**
  String get appleConnecting;

  /// No description provided for @termsAgreementPrefix.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our\n'**
  String get termsAgreementPrefix;

  /// No description provided for @andLabel.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get andLabel;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversation history yet.'**
  String get historyEmpty;

  /// No description provided for @automationActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get automationActive;

  /// No description provided for @automationPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get automationPaused;

  /// No description provided for @automationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get automationFailed;

  /// No description provided for @automationActivated.
  ///
  /// In en, this message translates to:
  /// **'{title} activated'**
  String automationActivated(String title);

  /// No description provided for @automationPausadaFeedback.
  ///
  /// In en, this message translates to:
  /// **'{title} paused'**
  String automationPausadaFeedback(String title);

  /// No description provided for @automationOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get automationOptions;

  /// No description provided for @automationCreatedOn.
  ///
  /// In en, this message translates to:
  /// **'Created on {date} at {time}'**
  String automationCreatedOn(String date, String time);

  /// No description provided for @automationIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations:'**
  String get automationIntegrations;

  /// No description provided for @automationViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get automationViewDetails;

  /// No description provided for @automationPause.
  ///
  /// In en, this message translates to:
  /// **'Pause Automation'**
  String get automationPause;

  /// No description provided for @automationActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate Automation'**
  String get automationActivate;

  /// No description provided for @integrationsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search integrations (ex: Gmail, Slack...)'**
  String get integrationsSearchHint;

  /// No description provided for @integrationsConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get integrationsConnected;

  /// No description provided for @integrationsDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get integrationsDisconnected;

  /// No description provided for @integrationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get integrationsBlocked;

  /// No description provided for @integrationsCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get integrationsCategoryAll;

  /// No description provided for @integrationsCategoryGoogle.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get integrationsCategoryGoogle;

  /// No description provided for @integrationsCategoryProductivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get integrationsCategoryProductivity;

  /// No description provided for @integrationsCategoryCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get integrationsCategoryCommunication;

  /// No description provided for @integrationsCategoryCRM.
  ///
  /// In en, this message translates to:
  /// **'CRM/Sales'**
  String get integrationsCategoryCRM;

  /// No description provided for @integrationsDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get integrationsDisconnect;

  /// No description provided for @integrationsConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get integrationsConnect;

  /// No description provided for @appBrandName.
  ///
  /// In en, this message translates to:
  /// **'CATAS'**
  String get appBrandName;

  /// No description provided for @planSuffix.
  ///
  /// In en, this message translates to:
  /// **'PLAN'**
  String get planSuffix;

  /// No description provided for @defaultUserName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get defaultUserName;

  /// No description provided for @dropFileHint.
  ///
  /// In en, this message translates to:
  /// **'Drop file to attach'**
  String get dropFileHint;

  /// No description provided for @viewAction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAction;

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversations;

  /// No description provided for @modifiedAt.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get modifiedAt;

  /// No description provided for @featureInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Feature in development'**
  String get featureInDevelopment;

  /// No description provided for @pageTitleChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get pageTitleChat;

  /// No description provided for @pageTitleAutomations.
  ///
  /// In en, this message translates to:
  /// **'Automations'**
  String get pageTitleAutomations;

  /// No description provided for @pageTitleIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get pageTitleIntegrations;

  /// No description provided for @pageTitleSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pageTitleSettings;

  /// No description provided for @pageTitleHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get pageTitleHistory;

  /// No description provided for @pageTitlePricing.
  ///
  /// In en, this message translates to:
  /// **'Plans'**
  String get pageTitlePricing;

  /// No description provided for @pageTitleDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get pageTitleDashboard;

  /// No description provided for @manageBillingStripe.
  ///
  /// In en, this message translates to:
  /// **'Manage Billing & Invoices at Stripe'**
  String get manageBillingStripe;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @onboardingHeadline.
  ///
  /// In en, this message translates to:
  /// **'What do you want to automate?'**
  String get onboardingHeadline;

  /// No description provided for @onboardingPage1Body.
  ///
  /// In en, this message translates to:
  /// **'Pick repetitive work: email, calendar, spreadsheets, and more.'**
  String get onboardingPage1Body;

  /// No description provided for @onboardingPage2Body.
  ///
  /// In en, this message translates to:
  /// **'Describe it in plain language. CATAS builds the plan and runs it safely.'**
  String get onboardingPage2Body;

  /// No description provided for @onboardingPage3Body.
  ///
  /// In en, this message translates to:
  /// **'Watch every step update live in the chat.'**
  String get onboardingPage3Body;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Start in chat'**
  String get onboardingStart;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingSelectToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Select your tools'**
  String get onboardingSelectToolsTitle;

  /// No description provided for @onboardingSelectToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the integrations you want to connect to automate your routine'**
  String get onboardingSelectToolsSubtitle;

  /// No description provided for @dashboardEstimatedROI.
  ///
  /// In en, this message translates to:
  /// **'Estimated ROI'**
  String get dashboardEstimatedROI;

  /// No description provided for @dashboardSavedInTasks.
  ///
  /// In en, this message translates to:
  /// **'saved in tasks'**
  String get dashboardSavedInTasks;

  /// No description provided for @dashboardTasksExecuted.
  ///
  /// In en, this message translates to:
  /// **'Tasks Executed'**
  String get dashboardTasksExecuted;

  /// No description provided for @dashboardCredits.
  ///
  /// In en, this message translates to:
  /// **'Credits'**
  String get dashboardCredits;

  /// No description provided for @dashboardOfCredits.
  ///
  /// In en, this message translates to:
  /// **'of {limit} credits'**
  String dashboardOfCredits(int limit);

  /// No description provided for @dashboardYouSaved.
  ///
  /// In en, this message translates to:
  /// **'You saved '**
  String get dashboardYouSaved;

  /// No description provided for @dashboardHoursThisMonth.
  ///
  /// In en, this message translates to:
  /// **' hours this month with CATAS.'**
  String get dashboardHoursThisMonth;

  /// No description provided for @dashboardTopIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Top Integrations'**
  String get dashboardTopIntegrations;

  /// No description provided for @dashboardMostUsedTools.
  ///
  /// In en, this message translates to:
  /// **'Your most used tools'**
  String get dashboardMostUsedTools;

  /// No description provided for @dashboardUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock {plan}'**
  String dashboardUnlock(String plan);

  /// No description provided for @dashboardUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get dashboardUpgrade;

  /// No description provided for @dashboardMaxPlanActive.
  ///
  /// In en, this message translates to:
  /// **'MAX Plan Active'**
  String get dashboardMaxPlanActive;

  /// No description provided for @dashboardMaxPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'You have full access to all AI models, custom workflows and maximum execution priority.'**
  String get dashboardMaxPlanDescription;

  /// No description provided for @dashboardUsed.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get dashboardUsed;

  /// No description provided for @dashboardSeeMore.
  ///
  /// In en, this message translates to:
  /// **'See more...'**
  String get dashboardSeeMore;

  /// No description provided for @dashboardExplorePrompts.
  ///
  /// In en, this message translates to:
  /// **'Explore more prompts'**
  String get dashboardExplorePrompts;

  /// No description provided for @dashboardWeeklyDayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dashboardWeeklyDayMon;

  /// No description provided for @dashboardWeeklyDayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dashboardWeeklyDayTue;

  /// No description provided for @dashboardWeeklyDayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dashboardWeeklyDayWed;

  /// No description provided for @dashboardWeeklyDayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dashboardWeeklyDayThu;

  /// No description provided for @dashboardWeeklyDayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dashboardWeeklyDayFri;

  /// No description provided for @dashboardWeeklyDaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get dashboardWeeklyDaySat;

  /// No description provided for @dashboardWeeklyDaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get dashboardWeeklyDaySun;

  /// No description provided for @dashboardAutomationsExecuted.
  ///
  /// In en, this message translates to:
  /// **'Automations Executed'**
  String get dashboardAutomationsExecuted;

  /// No description provided for @dashboardLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get dashboardLast7Days;

  /// No description provided for @dashboardTasks.
  ///
  /// In en, this message translates to:
  /// **'tasks'**
  String get dashboardTasks;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
