import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:catas/l10n/app_localizations.dart';
import 'package:catas/core/web_page_renderer.dart' show navigateTo;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

String? _cachedVersion;

Future<String> _getVersion() async {
  if (_cachedVersion != null) return _cachedVersion!;
  final info = await PackageInfo.fromPlatform();
  _cachedVersion = "${info.version} (${info.buildNumber})";
  return _cachedVersion!;
}

List<Widget> buildAboutContent(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return [
    const SizedBox(height: 20),
    Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.auto_awesome,
          size: 50,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
    const SizedBox(height: 24),
    Text(
      "CATAS",
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    const SizedBox(height: 8),
    FutureBuilder<String>(
      future: _getVersion(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            "Carregando...",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Text(
          "Versão ${snapshot.data}",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    ),
    const SizedBox(height: 32),
    Text(
      "O Context Aware Task Automation System (CATAS) é um agente inteligente desenhado para converter linguagem natural em fluxos de automação poderosos.",
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    const SizedBox(height: 32),
    OutlinedButton.icon(
      onPressed: () { if (kIsWeb) navigateTo('/terms'); },
      icon: const Icon(Icons.description_outlined),
      label: Text(l10n.termsOfService),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: () { if (kIsWeb) navigateTo('/privacy'); },
      icon: const Icon(Icons.privacy_tip_outlined),
      label: Text(l10n.privacyPolicy),
    ),
  ];
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $url');
  }
}

List<Widget> buildHelpContent(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return [
    Text(
      "Como podemos ajudar?",
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    const SizedBox(height: 16),
    Text(
      "Se você precisa de ajuda para configurar integrações, entender funcionalidades ou relatar um problema, entre em contato conosco.",
      style: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 32),
    FilledButton.icon(
      onPressed: () => _launchUrl('mailto:suporte@catas.ai'),
      icon: const Icon(Icons.email_outlined),
      label: Text(l10n.sendSupportEmail),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () { if (kIsWeb) navigateTo('/security'); },
      icon: const Icon(Icons.menu_book),
      label: Text(l10n.accessDocs),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    const SizedBox(height: 32),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                "Comunidade",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Junte-se à nossa comunidade no Discord para trocar ideias e receber dicas de automações úteis do dia a dia.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _launchUrl('https://discord.gg/placeholder'),
            child: Text(l10n.joinDiscordBrowser),
          ),
        ],
      ),
    ),
  ];
}
