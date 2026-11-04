import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:catas/components/brand_logo.dart';
import 'package:catas/providers/chat_provider.dart';
import 'package:catas/providers/auth_provider.dart';
import 'package:catas/providers/integrations_provider.dart';
import 'package:catas/components/toggle.dart';
import 'package:catas/components/upgrade_modal.dart';
import 'package:catas/screens/integracoes/integrations_screen.dart' show IntegrationItem, IntegrationCategory;
import 'package:go_router/go_router.dart';
import 'package:catas/core/router.dart';

class IntegrationsOptionsMenu {
  IntegrationsOptionsMenu._();

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const IntegrationsOptionsDialog(),
    );
  }
}

class IntegrationsOptionsDialog extends StatelessWidget {
  const IntegrationsOptionsDialog({super.key});

  static const List<IntegrationItem> _integrations = [
    IntegrationItem(title: 'Google Calendar', logoId: LogoId.googleCalendar, providerName: 'google_calendar', category: [IntegrationCategory.productivity, IntegrationCategory.google]),
    IntegrationItem(title: 'Google Sheets', logoId: LogoId.googleSheets, providerName: 'google_sheets', category: [IntegrationCategory.productivity, IntegrationCategory.google]),
    IntegrationItem(title: 'Google Drive', logoId: LogoId.googleDrive, providerName: 'google_drive', category: [IntegrationCategory.productivity, IntegrationCategory.google]),
    IntegrationItem(title: 'Docs', logoId: LogoId.googleDocs, providerName: 'google_docs', category: [IntegrationCategory.productivity, IntegrationCategory.google]),
    IntegrationItem(title: 'Notion', logoId: LogoId.notion, providerName: 'notion', category: [IntegrationCategory.productivity]),
    IntegrationItem(title: 'Gmail', logoId: LogoId.googleGmail, providerName: 'google_gmail', category: [IntegrationCategory.communication, IntegrationCategory.google]),
    IntegrationItem(title: 'Google Meet', logoId: LogoId.googleMeet, providerName: 'google_meet', category: [IntegrationCategory.communication, IntegrationCategory.google]),
    IntegrationItem(title: 'Whatsapp', logoId: LogoId.whatsapp, providerName: 'whatsapp', category: [IntegrationCategory.communication]),
    IntegrationItem(title: 'Slack', logoId: LogoId.slack, providerName: 'slack', category: [IntegrationCategory.communication]),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final integrationsProvider = context.watch<IntegrationsProvider>();
    final userTier = authProvider.subscriptionTier ?? 'free';

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: 320,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Text('Conectores', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                itemCount: _integrations.length,
                itemBuilder: (context, index) {
                  final item = _integrations[index];
                  final bool isConnected = integrationsProvider.isConnected(item.providerName);
                  final bool isActiveInChat = chatProvider.isIntegrationActive(item.providerName);
                  final bool isAllowed = _isAllowed(item.providerName, userTier);
                  final bool isBusy = integrationsProvider.isBusy(item.providerName);
                  return _buildTile(context, item, isConnected, isActiveInChat, isAllowed, isBusy, integrationsProvider, chatProvider);
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(Icons.settings_input_component_rounded, color: colorScheme.onSurfaceVariant),
                title: Text('Gerenciar conectores', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () {
                  Navigator.pop(context);
                  context.go(AppRoutes.integrations);
                },
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    IntegrationItem item,
    bool isConnected,
    bool isActiveInChat,
    bool isAllowed,
    bool isBusy,
    IntegrationsProvider integrationsProvider,
    ChatProvider chatProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!isAllowed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Logo(logoId: item.logoId, size: 24, onErrorIcon: const Icon(Icons.link_rounded, size: 24)),
          title: Text(item.title, style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.5))),
          trailing: Icon(Icons.lock_outline, size: 18, color: colorScheme.primary),
          onTap: () => UpgradeModal.show(context, item.title, _getRequiredTier(item.providerName)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Logo(logoId: item.logoId, size: 24, onErrorIcon: const Icon(Icons.link_rounded, size: 20)),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActiveInChat ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        subtitle: Text(
          isConnected ? 'Conectado' : 'Desconectado',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isConnected ? Colors.green : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        trailing: isBusy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : Opacity(
                opacity: isConnected ? 1.0 : 0.4,
                child: CatasToggle(
                  value: isConnected && isActiveInChat,
                  onChanged: (value) {
                    if (isConnected) {
                      chatProvider.toggleChatIntegration(item.providerName);
                      _savePref(item.providerName, value);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Conecte o ${item.title} nas configurações primeiro.'),
                        ),
                      );
                    }
                  },
                ),
              ),
        onTap: () {
          if (!isConnected && !isBusy) {
            integrationsProvider.toggleConnection(item.providerName);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isAllowed(String providerName, String userTier) {
    if (userTier == 'max' || userTier == 'pro') return true;
    return ["google_calendar", "google_gmail", "google_meet", "google_drive", "google_docs", "notion"].contains(providerName);
  }

  String _getRequiredTier(String providerName) {
    final proRequired = ["whatsapp", "slack", "telegram"];
    if (proRequired.contains(providerName)) return "pro";
    return "free";
  }

  Future<void> _savePref(String providerName, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('integration_active_$providerName', isActive);
  }
}
