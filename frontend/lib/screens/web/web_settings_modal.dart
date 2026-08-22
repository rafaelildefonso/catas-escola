import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/web_page_renderer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../components/catas_dropdown.dart';
import '../../components/catas_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../account_settings_screen.dart';
import '../manage_subscription_screen.dart';

class WebSettingsModal extends StatefulWidget {
  const WebSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const WebSettingsModal(),
    );
  }

  @override
  State<WebSettingsModal> createState() => _WebSettingsModalState();
}

enum _SettingsView { main, account, subscription }

class _WebSettingsModalState extends State<WebSettingsModal> {
  _SettingsView _currentView = _SettingsView.main;
  String _notificationsPreference = "Todas";

  void _setView(_SettingsView view) {
    setState(() => _currentView = view);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    String currentThemeString;
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        currentThemeString = AppLocalizations.of(context)!.themeLight;
        break;
      case ThemeMode.dark:
        currentThemeString = AppLocalizations.of(context)!.themeDark;
        break;
      case ThemeMode.system:
        currentThemeString = AppLocalizations.of(context)!.themeSystem;
        break;
    }

    String currentLanguageLabel = AppLocalizations.of(context)!.systemLanguage;
    if (localeProvider.locale?.languageCode == 'pt') {
      currentLanguageLabel = AppLocalizations.of(context)!.languagePortuguese;
    } else if (localeProvider.locale?.languageCode == 'en') {
      currentLanguageLabel = AppLocalizations.of(context)!.languageEnglish;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _currentView == _SettingsView.account
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: AccountSettingsScreen(
                        isEmbedded: true,
                        onBack: () => _setView(_SettingsView.main),
                      ),
                    )
                  : _currentView == _SettingsView.subscription
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      child: ManageSubscriptionScreen(
                        isEmbedded: true,
                        onBack: () => _setView(_SettingsView.main),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Section
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                    image: auth.userPhotoUrl != null
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              auth.userPhotoUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: auth.userPhotoUrl == null
                                      ? Center(
                                          child: Text(
                                            (auth.userName ?? "Usuário")[0]
                                                .toUpperCase(),
                                            style: GoogleFonts.inter(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.onPrimary,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  auth.userName ?? "Usuário",
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  auth.userEmail ?? "",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  (auth.subscriptionTier == null ||
                                          auth.subscriptionTier == 'free')
                                      ? ""
                                      : "${auth.subscriptionTier!.toUpperCase()} PLAN",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: auth.subscriptionTier == 'max'
                                        ? (theme.brightness == Brightness.dark
                                            ? Colors.blue[400]!
                                            : const Color(0xFF0D47A1))
                                        : (auth.subscriptionTier == 'pro'
                                            ? theme.colorScheme.primary
                                            : Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    context.read<NavigationProvider>().setPage(
                                      AppPage.pricing,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.star_outline_rounded,
                                    size: 18,
                                  ),
                                  label: Text(AppLocalizations.of(context)!.viewPlans),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Preferences Section
                          _buildSectionHeader(AppLocalizations.of(context)!.settingsPreferences),
                          const SizedBox(height: 12),
                          _buildSettingsCard(
                            children: [
                              _buildDropdownTile(
                                icon: Icons.notifications_outlined,
                                title: AppLocalizations.of(context)!.settingsNotifications,
                                subtitle: AppLocalizations.of(context)!.settingsNotificationsSub,
                                options: [
                                  AppLocalizations.of(context)!.settingsNotifAll,
                                  AppLocalizations.of(context)!.settingsNotifImportant,
                                  AppLocalizations.of(context)!.settingsNotifNone,
                                ],
                                value: _notificationsPreference == "Todas"
                                    ? AppLocalizations.of(context)!.settingsNotifAll
                                    : _notificationsPreference == "Importantes"
                                    ? AppLocalizations.of(context)!.settingsNotifImportant
                                    : AppLocalizations.of(context)!.settingsNotifNone,
                                onChanged: (val) =>
                                    setState(() => _notificationsPreference = val),
                              ),
                              _buildDivider(),
                              _buildDropdownTile(
                                icon: Icons.light_mode_outlined,
                                title: AppLocalizations.of(context)!.settingsAppearance,
                                subtitle: AppLocalizations.of(context)!.settingsAppearanceSub,
                                value: currentThemeString,
                                options: [
                                  AppLocalizations.of(context)!.themeLight,
                                  AppLocalizations.of(context)!.themeDark,
                                  AppLocalizations.of(context)!.themeSystem,
                                ],
                                onChanged: (val) {
                                  if (val == AppLocalizations.of(context)!.themeLight) {
                                    themeProvider.setThemeMode(ThemeMode.light);
                                  } else if (val == AppLocalizations.of(context)!.themeDark) {
                                    themeProvider.setThemeMode(ThemeMode.dark);
                                  } else {
                                    themeProvider.setThemeMode(ThemeMode.system);
                                  }
                                },
                              ),
                              _buildDivider(),
                              _buildDropdownTile(
                                icon: Icons.language,
                                title: AppLocalizations.of(context)!.settingsLanguage,
                                subtitle: AppLocalizations.of(context)!.settingsLanguageSub,
                                value: currentLanguageLabel,
                                options: [
                                  AppLocalizations.of(context)!.systemLanguage,
                                  AppLocalizations.of(context)!.languagePortuguese,
                                  AppLocalizations.of(context)!.languageEnglish,
                                ],
                                onChanged: (val) {
                                  Locale? newLocale;
                                  if (val == AppLocalizations.of(context)!.systemLanguage) {
                                    newLocale = null;
                                  } else if (val == AppLocalizations.of(context)!.languagePortuguese) {
                                    newLocale = const Locale('pt');
                                  } else if (val == AppLocalizations.of(context)!.languageEnglish) {
                                    newLocale = const Locale('en');
                                  }
                                  context.read<LocaleProvider>().setLocale(newLocale);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Account & Subscription Section
                          _buildSectionHeader(AppLocalizations.of(context)!.settingsAccountSubsciption),
                          const SizedBox(height: 12),
                          _buildSettingsCard(
                            children: [
                              _buildTapTile(
                                icon: Icons.person_outline,
                                title: AppLocalizations.of(context)!.settingsAccountConfig,
                                onTap: () {
                                  _setView(_SettingsView.account);
                                },
                              ),
                              _buildDivider(),
                              _buildTapTile(
                                icon: Icons.workspace_premium_outlined,
                                title: AppLocalizations.of(context)!.settingsManageSub,
                                onTap: () {
                                  _setView(_SettingsView.subscription);
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Connections Section
                          _buildSectionHeader(AppLocalizations.of(context)!.settingsConnections),
                          const SizedBox(height: 12),
                          _buildSettingsCard(
                            children: [
                              _buildTapTile(
                                icon: Icons.route,
                                title: AppLocalizations.of(context)!.settingsAutomations,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.read<NavigationProvider>().setPage(
                                    AppPage.automations,
                                  );
                                },
                              ),
                              _buildDivider(),
                              _buildTapTile(
                                icon: Icons.device_hub_outlined,
                                title: AppLocalizations.of(context)!.settingsIntegrations,
                                onTap: () {
                                  Navigator.pop(context);
                                  context.read<NavigationProvider>().setPage(
                                    AppPage.integrations,
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Info & Support Section
                          _buildSectionHeader(AppLocalizations.of(context)!.settingsInfoSupport),
                          const SizedBox(height: 12),
                          _buildSettingsCard(
                            children: [
                              _buildTapTile(
                                icon: Icons.info_outline,
                                title: AppLocalizations.of(context)!.settingsAbout,
                                onTap: () { if (kIsWeb) navigateTo('/about'); },
                              ),
                              _buildDivider(),
                              _buildTapTile(
                                icon: Icons.help_outline_rounded,
                                title: AppLocalizations.of(context)!.settingsGetHelp,
                                onTap: () { if (kIsWeb) navigateTo('/contact'); },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Logout
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final confirmed = await showCatasDialog<bool>(
                                  context: context,
                                  title: AppLocalizations.of(context)!.logOutTitle,
                                  message: AppLocalizations.of(context)!.logOutContent,
                                  icon: Icon(
                                    Icons.logout,
                                    size: 48,
                                    color: theme.colorScheme.primary,
                                  ),
                                  actionsBuilder: (innerCtx) => [
                                    CatasDialogAction(
                                      label: AppLocalizations.of(context)!.settingsCancel,
                                      onPressed: () => Navigator.pop(innerCtx, false),
                                      isSecondary: true,
                                    ),
                                    CatasDialogAction(
                                      label: AppLocalizations.of(context)!.logOutAction,
                                      onPressed: () => Navigator.pop(innerCtx, true),
                                    ),
                                  ],
                                );
                                if (confirmed == true && context.mounted) {
                                  await context.read<NotificationsProvider>().deactivateCurrentToken();
                                  if (context.mounted) {
                                    context.read<AuthProvider>().logout();
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              icon: const Icon(Icons.logout, size: 18),
                              label: Text(
                                AppLocalizations.of(context)!.settingsLogout,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error.withValues(alpha: 0.3),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
      indent: 48,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurface, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CatasDropdown<String>(
            value: value,
            items: options.map((opt) {
              return CatasDropdownItem<String>(value: opt, label: opt);
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTapTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurface, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
