import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:catas/components/brand_logo.dart';
import 'package:catas/providers/integrations_provider.dart';
import 'package:catas/providers/chat_provider.dart';
import 'package:catas/providers/auth_provider.dart';
import 'package:catas/components/toggle.dart';
import 'package:catas/screens/integrations_screen.dart' show IntegrationItem, IntegrationCategory;
import 'package:catas/components/upgrade_modal.dart';
import 'package:go_router/go_router.dart';
import 'package:catas/core/router.dart';
import 'package:catas/providers/navigation_provider.dart';

class IntegrationsBottomSheet extends StatelessWidget {
  const IntegrationsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const IntegrationsBottomSheet(),
    );
  }

  // Mesma lista de integrações da IntegrationsScreen para manter consistência
  static const List<IntegrationItem> _integrations = [
    IntegrationItem(
      title: 'Google Calendar',
      logoId: LogoId.googleCalendar,
      providerName: 'google_calendar',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Sheets',
      logoId: LogoId.googleSheets,
      providerName: 'google_sheets',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Drive',
      logoId: LogoId.googleDrive,
      providerName: 'google_drive',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Docs',
      logoId: LogoId.googleDocs,
      providerName: 'google_docs',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Notion',
      logoId: LogoId.notion,
      providerName: 'notion',
      category: [IntegrationCategory.productivity],
    ),
    IntegrationItem(
      title: 'Gmail',
      logoId: LogoId.googleGmail,
      providerName: 'google_gmail',
      category: [IntegrationCategory.communication, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Meet',
      logoId: LogoId.googleMeet,
      providerName: 'google_meet',
      category: [IntegrationCategory.communication, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Whatsapp',
      logoId: LogoId.whatsapp,
      providerName: 'whatsapp',
      category: [IntegrationCategory.communication],
    ),
    IntegrationItem(
      title: 'Slack',
      logoId: LogoId.slack,
      providerName: 'slack',
      category: [IntegrationCategory.communication],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final integrationsProvider = context.watch<IntegrationsProvider>();
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final userTier = authProvider.subscriptionTier ?? 'free';

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handlebar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Conectores',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (integrationsProvider.isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // List of Integrations
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _integrations.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _integrations[index];
                  final bool isConnected = integrationsProvider.isConnected(item.providerName);
                  final bool isAllowed = _isAllowed(item.providerName, userTier);
                  final bool isBusy = integrationsProvider.isBusy(item.providerName);

                  return _buildIntegrationTile(
                    context,
                    item,
                    isConnected,
                    isAllowed,
                    isBusy,
                    integrationsProvider,
                    chatProvider,
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          
          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildFooterAction(
                  context,
                  icon: Icons.settings_input_component_rounded,
                  label: 'Gerenciar conectores',
                  onTap: () {
                    Navigator.pop(context);
                    context.go(AppRoutes.integrations);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationTile(
    BuildContext context,
    IntegrationItem item,
    bool isConnected,
    bool isAllowed,
    bool isBusy,
    IntegrationsProvider provider,
    ChatProvider chatProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActiveInChat = chatProvider.isIntegrationActive(item.providerName);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark ? colorScheme.surfaceContainerHigh : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Logo(
            logoId: item.logoId,
            size: 28,
            onErrorIcon: const Icon(Icons.link_rounded),
          ),
        ),
        title: Text(
          item.title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isAllowed ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        trailing: isBusy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : (!isAllowed
                ? Icon(Icons.lock_outline_rounded, size: 20, color: colorScheme.primary)
                : Opacity(
                    opacity: isConnected ? 1.0 : 0.4,
                    child: CatasToggle(
                      value: isConnected && isActiveInChat,
                      onChanged: (value) {
                        if (isConnected) {
                          chatProvider.toggleChatIntegration(item.providerName);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Conecte o ${item.title} nas configurações primeiro.'),
                              action: SnackBarAction(
                                label: 'Configurar',
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<NavigationProvider>().setPage(AppPage.integrations);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  )),
        onTap: () {
          if (!isAllowed) {
            UpgradeModal.show(context, item.title, _getRequiredTier(item.providerName));
          } else if (!isConnected && !isBusy) {
            provider.toggleConnection(item.providerName);
          }
        },
      ),
    );
  }

  Widget _buildFooterAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  bool _isAllowed(String providerName, String userTier) {
    if (userTier == 'max') return true;
    if (userTier == 'pro') return true;
    final freeAllowed = [
      "google_calendar",
      "google_gmail",
      "google_meet",
      "google_drive",
      "google_docs",
      "notion",
    ];
    return freeAllowed.contains(providerName);
  }

  String _getRequiredTier(String providerName) {
    final proRequired = ["whatsapp", "slack", "telegram"];
    if (proRequired.contains(providerName)) return "pro";
    return "free";
  }
}