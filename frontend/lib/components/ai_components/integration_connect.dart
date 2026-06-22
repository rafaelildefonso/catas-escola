import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntegrationConnectComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;
  final bool readonly;

  const IntegrationConnectComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.readonly = false,
  });

  IconData _getIconForProvider(String provider) {
    switch (provider) {
      case 'google_gmail':
        return Icons.mail_outline_rounded;
      case 'google_calendar':
        return Icons.calendar_today_outlined;
      case 'google_drive':
        return Icons.folder_outlined;
      case 'google_docs':
        return Icons.description_outlined;
      case 'google_sheets':
        return Icons.table_chart_outlined;
      case 'google_meet':
        return Icons.videocam_outlined;
      case 'whatsapp':
        return Icons.chat_bubble_outline_rounded;
      case 'notion':
        return Icons.note_outlined;
      case 'slack':
        return Icons.tag_rounded;
      default:
        return Icons.link_rounded;
    }
  }

  String _getProviderDisplayName(String provider) {
    switch (provider) {
      case 'google_gmail':
        return 'Gmail';
      case 'google_calendar':
        return 'Google Calendar';
      case 'google_drive':
        return 'Google Drive';
      case 'google_docs':
        return 'Google Docs';
      case 'google_sheets':
        return 'Google Sheets';
      case 'google_meet':
        return 'Google Meet';
      case 'whatsapp':
        return 'WhatsApp';
      case 'notion':
        return 'Notion';
      case 'slack':
        return 'Slack';
      default:
        return provider.replaceAll('google_', 'Google ').replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = data['provider'] as String? ?? '';
    final providerName = data['provider_name'] as String? ?? _getProviderDisplayName(provider);
    final message = data['message'] as String? ?? 'Você precisa configurar esta integração.';

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getIconForProvider(provider),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    providerName,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
