import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../components/chat/model_selector.dart';
import '../../core/navigation_helpers.dart';
import '../../core/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/termo_aceite_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/integrations_provider.dart';
import '../../core/router.dart';
import 'web_sidebar.dart';
import 'web_settings_modal.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/picked_attachment.dart';
import '../../l10n/app_localizations.dart';

class WebMainLayout extends StatefulWidget {
  final Widget child;

  const WebMainLayout({super.key, required this.child});

  @override
  State<WebMainLayout> createState() => _WebMainLayoutState();
}

class _WebMainLayoutState extends State<WebMainLayout> {
  bool _isDragging = false;
  bool _aceitoNoGate = false;

  void _navigateTo(AppPage page) {
    context.go(getRouteForPage(page));
  }

  void _createNewChat() {
    context.read<ChatProvider>().clearChat();
    context.go(AppRoutes.chat);
  }

  void _openSettings() {
    WebSettingsModal.show(context);
  }

  Future<void> _handleGlobalDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;

    final file = details.files.first;
    final isImage = [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    ].any((ext) => file.name.toLowerCase().endsWith(ext));

    final chatProvider = context.read<ChatProvider>();
    chatProvider.addAttachments([
      PickedAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: file.path,
        name: file.name,
        isImage: isImage,
      ),
    ]);

    final l10n = AppLocalizations.of(context)!;
    final nav = context.read<NavigationProvider>();
    if (nav.currentPage != AppPage.chat) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.fileAttached(file.name)),
          action: SnackBarAction(
            label: l10n.viewAction,
            onPressed: () => context.go(AppRoutes.chat),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final nav = context.read<NavigationProvider>();
    final auth = context.watch<AuthProvider>();
    final integrations = context.watch<IntegrationsProvider>();

    // Sincroniza o NavigationProvider com a rota atual (Importante para F5/Link Direto)
    final String location = GoRouterState.of(context).matchedLocation;
    final page = getPageFromLocation(location);

    // Título e página atuais baseados na rota real (evita flicker do Provider)
    final currentPage = page;

    if (nav.currentPage != page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          nav.setPage(page);
        }
      });
    }

    // Fetch integrations if needed
    if (auth.isAuthenticated &&
        !integrations.isLoading &&
        !integrations.hasAttemptedFetch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<IntegrationsProvider>().fetchIntegrations();
      });
    }

    // Verifica o aceite dosTermos de Uso/Consentimento (LGPD) do usuário
    final termos = context.watch<TermoAceiteProvider>();
    final usuarioSeparado = !AppConfig.isDemoMode && auth.isAuthenticated;
    if (usuarioSeparado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<TermoAceiteProvider>().carregar(
            auth.userEmail ?? 'usuario',
          );
        }
      });
    }
    final precisaAceitar =
        usuarioSeparado && termos.aceito == false && termos.carregado;

    return DropTarget(
      onDragDone: _handleGlobalDrop,
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      child: Scaffold(
        body: Stack(
          children: [
            Row(
              children: [
                // Sidebar
                WebSidebar(
                  onNavigate: _navigateTo,
                  onNewChat: _createNewChat,
                  onOpenSettings: _openSettings,
                ),

                // Main content area
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      _buildHeader(context, theme, currentPage, auth),

                      // Content
                      Expanded(
                        child: Container(
                          color: theme.colorScheme.surface,
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isDragging)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.dropFileHint,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
          if (precisaAceitar) _buildGateTermos(theme, termos),
        ),
      ),
    );
  }

  // ─── GATE DE TERMOS (LGPD) ────────────────────────────────

  Widget _buildGateTermos(ThemeData theme, TermoAceiteProvider termos) {
    return Positioned.fill(
      child: Material(
        color: theme.colorScheme.scrim.withValues(alpha: 0.6),
        child: Center(
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.gavel_rounded,
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Termos de Uso e Consentimento',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Para usar o CATAS, é necessário que você leia e concorde com '
                  'o Termo de Uso e o Termo de Consentimento para Tratamento de '
                  'Dados Pessoais (LGPD), versão ${termos.versaoAtual ?? '1.0'}.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _abrirTermo('terms'),
                  icon: const Icon(Icons.article_outlined, size: 16),
                  label: const Text('Ler o Termo de Uso'),
                ),
                TextButton.icon(
                  onPressed: () => _abrirTermo('consent'),
                  icon: const Icon(Icons.fact_check_outlined, size: 16),
                  label: const Text('Ler o Termo de Consentimento'),
                ),
                const SizedBox(height: 4),
                CheckboxListTile(
                  value: _aceitoNoGate,
                  onChanged: (value) =>
                      setState(() => _aceitoNoGate = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    'Li e aceito os dois termos, de forma livre e informada.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: termos.registrando
                            ? null
                            : () => context.read<AuthProvider>().logout(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Sair'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _aceitoNoGate && !termos.registrando
                            ? () async {
                                await context
                                    .read<TermoAceiteProvider>()
                                    .aceitar();
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: termos.registrando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Aceitar e continuar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirTermo(String page) {
    if (!kIsWeb) return;
    final uri = Uri.base.replace(path: '/$page');
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppPage currentPage,
    AuthProvider auth,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Page title
          Text(
            getLocalizedPageTitle(context, currentPage),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),

          const Spacer(),

          Semantics(
            button: true,
            label: 'Abrir notificações',
            child: IconButton(
              onPressed: () {
                final currentLocation = GoRouterState.of(
                  context,
                ).uri.toString();
                final notificationsLocation = Uri.parse(AppRoutes.notifications)
                    .replace(queryParameters: {'from': currentLocation})
                    .toString();
                context.push(notificationsLocation);
              },
              tooltip: 'Notificações',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 8),

          // Model selector (only on chat page)
          if (currentPage == AppPage.chat &&
              auth.subscriptionTier != 'free' &&
              !AppConfig.isDemoMode) ...[
            Flexible(
              child: ModelSelectorWidget(
                horizontalPadding: 16,
                iconSpacing: 6,
                onUpgradeRequired: (context, model) =>
                    _showUpgradeModal(context, model),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(child: _buildCreditsBadge(context, theme, auth)),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditsBadge(
    BuildContext context,
    ThemeData theme,
    AuthProvider auth,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.grade_rounded, size: 16, color: Colors.amber[400]),
          const SizedBox(width: 6),
          Text(
            auth.quotaRemaining != null && auth.monthlyQuotaLimit != null
                ? "${auth.monthlyQuotaLimit! - auth.quotaUsed!}/${auth.monthlyQuotaLimit} créditos"
                : "- créditos",
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showUpgradeModal(BuildContext context, String model) {
    final requiredTier = getRequiredTier(model);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Premium Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                "Desbloqueie o $model",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Description (Fixed redundancy)
              Text(
                "Este modelo faz parte do plano ${requiredTier.toUpperCase()}. Faça o upgrade agora para acessar recursos avançados e maior velocidade.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        "Depois",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.go(AppRoutes.pricing);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      child: Text(
                        "Ver Planos",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
