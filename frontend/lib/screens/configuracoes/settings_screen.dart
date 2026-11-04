import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/web_page_renderer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/router.dart';
import '../../l10n/app_localizations.dart';
import '../../components/catas_dropdown.dart';
import '../../components/catas_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _notificationsPreference = "Todas";

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    String currentThemeString;
    switch (themeProvider.themeMode) {
      case ThemeMode.light:
        currentThemeString = l10n.themeLight;
        break;
      case ThemeMode.dark:
        currentThemeString = l10n.themeDark;
        break;
      case ThemeMode.system:
        currentThemeString = l10n.themeSystem;
        break;
    }

    String currentLanguageLabel = l10n.systemLanguage;
    if (localeProvider.locale?.languageCode == 'pt') {
      currentLanguageLabel = l10n.languagePortuguese;
    } else if (localeProvider.locale?.languageCode == 'en') {
      currentLanguageLabel = l10n.languageEnglish;
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // --- Profile Section ---
        _buildSectionHeader(""),
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                  image: auth.userPhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(auth.userPhotoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: auth.userPhotoUrl == null
                    ? Center(
                        child: Text(
                          (auth.userName ?? "Usuário")[0].toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 6),
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
                  fontWeight: FontWeight.w600,
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
                          ? Colors.blue[400]
                          : const Color(0xFF0D47A1))
                      : (auth.subscriptionTier == 'pro'
                            ? theme.colorScheme.primary
                            : Colors.grey),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                child: FilledButton.icon(
                  onPressed: () {
                    context.go(AppRoutes.pricing);
                  },
                  icon: const Icon(Icons.star_outline_rounded, size: 18),
                  label: Text(l10n.viewPlans),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // --- Preferences Section ---
        _buildSectionHeader(l10n.settingsPreferences),
        const SizedBox(height: 12),
        _buildSettingsCard(
          children: [
            _buildDropdownTile(
              icon: Icons.notifications_outlined,
              title: l10n.settingsNotifications,
              subtitle: l10n.settingsNotificationsSub,
              options: [
                l10n.settingsNotifAll,
                l10n.settingsNotifImportant,
                l10n.settingsNotifNone,
              ],
              value: _notificationsPreference == "Todas"
                  ? l10n.settingsNotifAll
                  : _notificationsPreference == "Importantes"
                  ? l10n.settingsNotifImportant
                  : _notificationsPreference == "Nenhuma"
                  ? l10n.settingsNotifNone
                  : _notificationsPreference,
              onChanged: (val) =>
                  setState(() => _notificationsPreference = val),
            ),
            _buildDivider(),
            _buildDropdownTile(
              icon: Icons.light_mode_outlined,
              title: l10n.settingsAppearance,
              subtitle: l10n.settingsAppearanceSub,
              value: currentThemeString,
              options: [l10n.themeLight, l10n.themeDark, l10n.themeSystem],
              onChanged: (val) {
                if (val == l10n.themeLight) {
                  themeProvider.setThemeMode(ThemeMode.light);
                } else if (val == l10n.themeDark) {
                  themeProvider.setThemeMode(ThemeMode.dark);
                } else {
                  themeProvider.setThemeMode(ThemeMode.system);
                }
              },
            ),
            _buildDivider(),
            _buildDropdownTile(
              icon: Icons.language,
              title: l10n.settingsLanguage,
              subtitle: l10n.settingsLanguageSub,
              value: currentLanguageLabel,
              options: [
                l10n.systemLanguage,
                l10n.languagePortuguese,
                l10n.languageEnglish,
              ],
              onChanged: (val) {
                Locale? newLocale;
                if (val == l10n.systemLanguage) {
                  newLocale = null;
                } else if (val == l10n.languagePortuguese) {
                  newLocale = const Locale('pt');
                } else if (val == l10n.languageEnglish) {
                  newLocale = const Locale('en');
                }
                context.read<LocaleProvider>().setLocale(newLocale);
              },
            ),
          ],
        ),

        const SizedBox(height: 28),

        // --- Account & Subscription Section ---
        _buildSectionHeader(l10n.settingsAccountSubsciption),
        const SizedBox(height: 12),
        _buildSettingsCard(
          children: [
            _buildTapTile(
              icon: Icons.person_outline,
              title: l10n.settingsAccountConfig,
              onTap: () {
                context.push(AppRoutes.settingsAccount);
              },
            ),
            _buildDivider(),
            _buildTapTile(
              icon: Icons.workspace_premium_outlined,
              title: l10n.settingsManageSub,
              onTap: () {
                context.push(AppRoutes.settingsSubscription);
              },
            ),
          ],
        ),

        const SizedBox(height: 28),

        // --- Connections Section ---
        _buildSectionHeader(l10n.settingsConnections),
        const SizedBox(height: 12),
        _buildSettingsCard(
          children: [
            _buildTapTile(
              icon: Icons.route,
              title: l10n.settingsAutomations,
              onTap: () {
                context.go(AppRoutes.automations);
              },
            ),
            _buildDivider(),
            _buildTapTile(
              icon: Icons.device_hub_outlined,
              title: l10n.settingsIntegrations,
              onTap: () {
                context.go(AppRoutes.integrations);
              },
            ),
          ],
        ),

        const SizedBox(height: 28),

        // --- About Section ---
        _buildSectionHeader(l10n.settingsInfoSupport),
        const SizedBox(height: 12),
        _buildSettingsCard(
          children: [
            _buildTapTile(
              icon: Icons.info_outline,
              title: l10n.settingsAbout,
              onTap: () { if (kIsWeb) navigateTo('/about'); },
            ),
            _buildDivider(),
            _buildTapTile(
              icon: Icons.help_outline_rounded,
              title: l10n.settingsGetHelp,
              onTap: () { if (kIsWeb) navigateTo('/contact'); },
            ),
          ],
        ),

        const SizedBox(height: 28),

        // --- Logout Button ---
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showCatasDialog<bool>(
                context: context,
                title: l10n.logOutTitle,
                message: l10n.logOutContent,
                icon: Icon(
                  Icons.logout,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                actionsBuilder: (innerCtx) => [
                  CatasDialogAction(
                    label: l10n.settingsCancel,
                    onPressed: () => Navigator.pop(innerCtx, false),
                    isSecondary: true,
                  ),
                  CatasDialogAction(
                    label: l10n.logOutAction,
                    onPressed: () => Navigator.pop(innerCtx, true),
                  ),
                ],
              );
              if (confirmed == true && context.mounted) {
                if (context.mounted) {
                  context.read<AuthProvider>().logout();
                }
              }
            },
            icon: const Icon(Icons.logout, size: 18),
            label: Text(
              l10n.settingsLogout,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 12,
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
        borderRadius: BorderRadius.circular(16),
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
      indent: 56,
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CatasDropdown<String>(
            value: value,
            items: options.map((opt) {
              IconData? itemIcon;
              if (opt == l10n.themeLight) itemIcon = Icons.light_mode_outlined;
              if (opt == l10n.themeDark) itemIcon = Icons.dark_mode_outlined;
              if (opt == l10n.themeSystem) {
                itemIcon = Icons.settings_brightness_outlined;
              }

              if (opt == l10n.systemLanguage) itemIcon = Icons.translate;

              return CatasDropdownItem<String>(
                value: opt,
                label: opt,
                icon: itemIcon,
              );
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
      // borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Icon(icon, color: theme.colorScheme.onSurface, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
