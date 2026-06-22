import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:catas/components/toggle.dart';
import '../providers/chat_provider.dart';
import 'package:google_fonts/google_fonts.dart';

/// BottomSheet de anexos e ações para o CATAS
/// Segue o tema do app: agente de automação inteligente
class AttachmentBottomSheet extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onFileTap;

  const AttachmentBottomSheet({
    super.key,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onFileTap,
  });

  /// Mostra o BottomSheet
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onCameraTap,
    required VoidCallback onGalleryTap,
    required VoidCallback onFileTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AttachmentBottomSheet(
        onCameraTap: onCameraTap,
        onGalleryTap: onGalleryTap,
        onFileTap: onFileTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chatProvider = context.watch<ChatProvider>();

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grid de Ações Rápidas
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adicionar',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  spacing: 10,
                  children: [
                    _QuickActionCard(
                      icon: Icons.camera_alt_outlined,
                      label: 'Câmera',
                      onTap: () {
                        Navigator.of(context).pop();
                        onCameraTap();
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeria',
                      onTap: () {
                        Navigator.of(context).pop();
                        onGalleryTap();
                      },
                    ),
                    _QuickActionCard(
                      icon: Icons.insert_drive_file_outlined,
                      label: 'Arquivos',
                      onTap: () {
                        Navigator.of(context).pop();
                        onFileTap();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divisor
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(
              color: colorScheme.outline.withValues(alpha: 0.15),
              height: 24,
            ),
          ),

          // Ferramentas e Opções
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: Text(
                    'Ferramentas',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Busca na Web
                _ToolListTile(
                  icon: Icons.travel_explore_outlined,
                  title: 'Busca na Web',
                  subtitle: 'Pesquisar informações online',
                  trailing: CatasToggle(
                    value: chatProvider.isWebSearchEnabled,
                    onChanged: (value) {
                      chatProvider.toggleWebSearch(value);
                    },
                  ),
                ),
                // Acesso a Integrações
                _ToolListTile(
                  icon: Icons.hub_outlined,
                  title: 'Integrações',
                  subtitle: 'Conectar com apps externos',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Navegar para tela de integrações ou abrir sub-menu
                  },
                ),
                // Histórico de Contexto
                _ToolListTile(
                  icon: Icons.history_outlined,
                  title: 'Contexto de Navegação',
                  subtitle: 'Usar página atual como contexto',
                  onTap: () {
                    Navigator.of(context).pop();
                    // Implementar lógica de contexto
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Card de ação rápida com ícone e label
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ListTile para ferramentas/opções
class _ToolListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ToolListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}