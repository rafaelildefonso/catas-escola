import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catas/components/brand_logo.dart';
import 'package:provider/provider.dart';
import 'package:catas/providers/integrations_provider.dart';

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

    final content = SingleChildScrollView(
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
                    color: connected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.onSurface.withValues(alpha: 0.05),
                    ),
                  ),
                  child: provider.isBusy(providerName)
                      ? const SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
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
                                : colorScheme.onSurface.withValues(alpha: 0.5),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: connected
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    connected ? "Conectado" : "Desconectado",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: connected ? Colors.green[600] : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // Permissões Section
          Text(
            "Permissões da Integração",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildPermissionItem(
            context,
            Icons.read_more,
            "Ler dados básicos do seu perfil",
          ),
          _buildPermissionItem(
            context,
            Icons.edit_calendar,
            "Agendar e modificar eventos em seu nome",
          ),
          _buildPermissionItem(
            context,
            Icons.search,
            "Buscar informações no seu histórico",
          ),
          const SizedBox(height: 32),

          // Links Section
          Text(
            "Informações",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _buildLinkItem(context, "Site Original da Integração"),
          _buildLinkItem(context, "Política de Privacidade"),
          const SizedBox(height: 48),

          // Ações / Configurações
          Text(
            "Ações",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Configurar Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
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
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
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
                  const SnackBar(content: Text('Obrigado pelo seu feedback!')),
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
                connected ? "Desconectar Integração" : "Conectar Integração",
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: connected ? Colors.white : colorScheme.primary,
                backgroundColor: connected
                    ? Colors.red[600]
                    : Colors.transparent,
                side: BorderSide(
                  color: connected ? Colors.red[600]! : colorScheme.primary,
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
    );

    if (isModal) {
      return content;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
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
