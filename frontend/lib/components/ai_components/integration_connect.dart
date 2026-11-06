import 'package:catas/components/brand_logo.dart';
import 'package:catas/components/toggle.dart';
import 'package:catas/providers/chat_provider.dart';
import 'package:catas/providers/integrations_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class IntegrationConnectComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;
  final bool readonly;
  final void Function(Map<String, dynamic> responseData)? onResponse;

  const IntegrationConnectComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.readonly = false,
    this.onResponse,
  });

  static const _providers = <String, ({String name, LogoId logo})>{
    'google_gmail': (name: 'Gmail', logo: LogoId.googleGmail),
    'google_calendar': (name: 'Google Calendar', logo: LogoId.googleCalendar),
    'google_sheets': (name: 'Google Sheets', logo: LogoId.googleSheets),
    'google_drive': (name: 'Google Drive', logo: LogoId.googleDrive),
    'google_docs': (name: 'Google Docs', logo: LogoId.googleDocs),
    'google_meet': (name: 'Google Meet', logo: LogoId.googleMeet),
    'whatsapp': (name: 'WhatsApp', logo: LogoId.whatsapp),
    'notion': (name: 'Notion', logo: LogoId.notion),
    'slack': (name: 'Slack', logo: LogoId.slack),
  };

  @override
  Widget build(BuildContext context) {
    final providerName = data['provider'] as String? ?? '';
    final details = _providers[providerName];
    final displayName =
        data['provider_name'] as String? ??
        details?.name ??
        providerName.replaceAll('google_', 'Google ').replaceAll('_', ' ');
    final message =
        data['message'] as String? ??
        'Você precisa configurar esta integração antes de continuar.';
    final integrations = context.watch<IntegrationsProvider>();
    final chat = context.watch<ChatProvider>();
    final connected = integrations.isConnected(providerName);
    final activeInChat = chat.isIntegrationActive(providerName);
    final canInteract =
        isEnabled && !readonly && !integrations.isBusy(providerName);
    final needsConnection = !connected;
    final effectiveMessage = needsConnection
        ? message
        : (activeInChat
              ? '$displayName está ativo neste chat.'
              : 'Ative $displayName neste chat para continuar.');
    final colorScheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: isEnabled ? 1 : 0.6,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: details == null
                  ? Icon(Icons.extension_rounded, color: colorScheme.primary)
                  : Logo(
                      logoId: details.logo,
                      size: 24,
                      onErrorIcon: Icon(
                        Icons.extension_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    effectiveMessage,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (integrations.isBusy(providerName))
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (needsConnection)
              OutlinedButton.icon(
                onPressed: canInteract
                    ? () => integrations.connectProvider(providerName)
                    : null,
                icon: const Icon(Icons.link, size: 16),
                label: const Text('Conectar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              CatasToggle(
                value: activeInChat,
                onChanged: canInteract
                    ? (value) {
                        if (value) {
                          chat.activateIntegration(providerName);
                          onResponse?.call({
                            'provider': providerName,
                            'activated': true,
                          });
                        } else {
                          chat.toggleChatIntegration(providerName);
                        }
                      }
                    : (_) {},
              ),
          ],
        ),
      ),
    );
  }
}
