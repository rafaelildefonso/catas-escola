import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catas/components/brand_logo.dart';
import 'package:provider/provider.dart';
import 'package:catas/providers/integrations_provider.dart';

import '../../components/catas_page.dart';
import '../../core/design_tokens.dart';

class IntegrationDetailsScreen extends StatelessWidget {
  final String title;
  final LogoId logoId;
  final String providerName;
  final bool isModal;

  const IntegrationDetailsScreen({
    super.key,
    required this.title,
    required this.logoId,
    required this.providerName,
    this.isModal = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IntegrationsProvider>();
    final bool connected = provider.isConnected(providerName);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = context.catasTokens;

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isModal)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                    ),
                  ],
                ),
              // Header: Logo & Title
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: tokens.surfaceRaised,
                        borderRadius: BorderRadius.circular(tokens.radiusLarge),
                        border: Border.all(color: tokens.borderSubtle),
                      ),
                      child: provider.isBusy(providerName)
                          ? SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                strokeWidth: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            )
                          : Logo(
                              logoId: logoId,
                              size: 64,
                              onErrorIcon: Icon(
                                Icons.extension,
                                color: connected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                size: 64,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CatasStatusBadge(
                      label: connected ? 'Conectado' : 'Desconectado',
                      icon: connected
                          ? Icons.check_circle_rounded
                          : Icons.pause_circle_outline_rounded,
                      tone: connected
                          ? CatasStatusTone.success
                          : CatasStatusTone.neutral,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Permissões Section
              const CatasSectionHeader(
                title: 'Permissões da integração',
                description: 'O que o CATAS pode fazer com esta conexão.',
              ),
              const SizedBox(height: 16),
              CatasSurface(
                child: Column(
                  children: [
                    _buildPermissionItem(
                      context,
                      Icons.read_more,
                      'Ler dados básicos do seu perfil',
                    ),
                    _buildPermissionItem(
                      context,
                      Icons.edit_calendar,
                      'Agendar e modificar eventos em seu nome',
                    ),
                    _buildPermissionItem(
                      context,
                      Icons.search,
                      'Buscar informações no seu histórico',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Links Section
              const CatasSectionHeader(title: 'Informações'),
              const SizedBox(height: 16),
              _buildLinkItem(context, "Site Original da Integração"),
              _buildLinkItem(context, "Política de Privacidade"),
              const SizedBox(height: 48),

              // Ações / Configurações
              const CatasSectionHeader(title: 'Ações'),
              const SizedBox(height: 16),

              // Configurar Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: connected
                      ? () {
                          // TODO: Open bottom sheet to toggle specific permissions
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Configurações detalhadas estarão disponíveis em breve.',
                              ),
                            ),
                          );
                        }
                      : null,
                  icon: const Icon(Icons.settings),
                  label: const Text("Configurar Permissões"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Enviar Feedback Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Obrigado pelo seu feedback!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text("Enviar Feedback"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Desconectar / Conectar Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: provider.isBusy(providerName)
                      ? null
                      : () {
                          provider.toggleConnection(providerName);
                        },
                  icon: Icon(connected ? Icons.link_off : Icons.link),
                  label: Text(
                    connected
                        ? "Desconectar Integração"
                        : "Conectar Integração",
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: connected
                        ? colorScheme.onError
                        : colorScheme.primary,
                    backgroundColor: connected
                        ? tokens.danger
                        : Colors.transparent,
                    side: BorderSide(
                      color: connected ? tokens.danger : colorScheme.primary,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (isModal) {
      return content;
    }

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: tokens.canvas,
        elevation: 0,
      ),
      body: content,
    );
  }

  Widget _buildPermissionItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        // Mock link open
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Abrindo $title...')));
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
