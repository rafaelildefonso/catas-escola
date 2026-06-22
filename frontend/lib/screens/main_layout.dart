import 'package:catas/core/app_config.dart';
import 'package:catas/core/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/navigation_provider.dart';
import '../components/app_drawer.dart';
import '../providers/integrations_provider.dart';
import '../components/upgrade_modal.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../models/picked_attachment.dart';
import '../l10n/app_localizations.dart';

// --- Custom Drawer Main Layout ---

class MainLayout extends StatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDragging = false;

  Future<void> _handleGlobalDrop(DropDoneDetails details) async {
    if (details.files.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;

    final file = details.files.first;
    final isImage = ['jpg', 'jpeg', 'png', 'webp', 'gif'].any(
      (ext) => file.name.toLowerCase().endsWith(ext),
    );

    final chatProvider = context.read<ChatProvider>();
    chatProvider.addAttachments([
      PickedAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        path: file.path, // DropDoneDetails might give a path but sometimes it needs special handling, we assume path is ok
        name: file.name,
        isImage: isImage,
      )
    ]);

    // Feedback visual se não estiver no chat
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
    final nav = context.watch<NavigationProvider>();
    final auth = context.watch<AuthProvider>();
    final integrations = context.watch<IntegrationsProvider>();
    final l10n = AppLocalizations.of(context)!;

    // Sincroniza o NavigationProvider com a rota atual (Importante para F5/Link Direto)
    final String location = GoRouterState.of(context).matchedLocation;
    final page = _getPageFromLocation(location);
    
    // Título e página atuais baseados na rota real (evita flicker do Provider)
    final currentPage = page;
    final pageTitle = _getLocalizedPageTitle(context, currentPage);

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
        if (context.mounted) {
          context.read<IntegrationsProvider>().fetchIntegrations();
        }
      });
    }

    return DropTarget(
      onDragDone: _handleGlobalDrop,
      onDragEntered: (details) => setState(() => _isDragging = true),
      onDragExited: (details) => setState(() => _isDragging = false),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: currentPage == AppPage.chat ? false : true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          title: currentPage == AppPage.chat && auth.subscriptionTier != 'free'
              ? _buildModelSelector(context, theme)
              : Text(
                  pageTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          actions: [
            nav.currentPage == AppPage.chat && auth.subscriptionTier != 'free' && !AppConfig.isDemoMode
                ? Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text(
                          auth.quotaRemaining != null &&
                                  auth.monthlyQuotaLimit != null
                              ? "${auth.monthlyQuotaLimit! - auth.quotaUsed!}/${auth.monthlyQuotaLimit}"
                              : "-",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
        drawer: const AppDrawer(),
        body: Stack(
          children: [
            GestureDetector(
              onHorizontalDragEnd: (details) {
                // Detect Swipe Right (Velocity > 0)
                if (details.primaryVelocity! > 200) {
                  _scaffoldKey.currentState?.openDrawer();
                }
              },
              child: SafeArea(
                child: Container(
                  color: Colors.transparent, // Ensures gesture hits empty space
                  child: widget.child,
                ),
              ),
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
        ),
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final tier = auth.subscriptionTier ?? 'free';

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) => PopupMenuButton<String>(
        offset: const Offset(0, 5),
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        color: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        onSelected: (model) {
          if (_isModelAllowed(model, tier)) {
            chatProvider.setSelectedModel(model);
          } else {
            UpgradeModal.show(
              context,
              '${l10n.textDialogTitle} $model',
              _getRequiredTier(model),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chatProvider.selectedModel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => chatProvider.availableModels.map((model) {
          final isSelected = chatProvider.selectedModel == model;
          final isAllowed = _isModelAllowed(model, tier);
          final requiredTier = _getRequiredTier(model);

          return PopupMenuItem<String>(
            value: model,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            model,
                            style: GoogleFonts.inter(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isAllowed
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildTierBadge(requiredTier, theme),
                        ],
                      ),
                      Text(
                        chatProvider.modelsInfo[model] ?? "",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: isAllowed ? 1.0 : 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  )
                else if (!isAllowed)
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isModelAllowed(String model, String userTier) {
    if (userTier == 'max') return true;
    if (userTier == 'pro') return model != "CATAS MAX";
    return model == "CATAS Free";
  }

  String _getRequiredTier(String model) {
    if (model == "CATAS MAX") return "max";
    if (model == "CATAS Pro") return "pro";
    return "free";
  }

  Widget _buildTierBadge(String tier, ThemeData theme) {
    Color color;
    switch (tier) {
      case 'max':
        color = const Color(0xFF0D47A1); // Blue 900
        break;
      case 'pro':
        color = theme.colorScheme.primary;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(
        tier.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  /// Converte a localização da rota para AppPage
  AppPage _getPageFromLocation(String location) {
    if (location.startsWith('/chat') || location == '/') {
      return AppPage.chat;
    }
    if (location.startsWith(AppRoutes.automations)) {
      return AppPage.automations;
    }
    if (location.startsWith(AppRoutes.integrations)) {
      return AppPage.integrations;
    }
    if (location.startsWith(AppRoutes.history)) {
      return AppPage.history;
    }
    if (location.startsWith(AppRoutes.pricing)) {
      return AppPage.pricing;
    }
    if (location.startsWith(AppRoutes.dashboard)) {
      return AppPage.dashboard;
    }
    if (location.startsWith(AppRoutes.settings)) {
      return AppPage.settings;
    }
    
    return AppPage.chat;
  }

  String _getLocalizedPageTitle(BuildContext context, AppPage page) {
    final l10n = AppLocalizations.of(context)!;
    switch (page) {
      case AppPage.chat:
        return l10n.pageTitleChat;
      case AppPage.automations:
        return l10n.pageTitleAutomations;
      case AppPage.integrations:
        return l10n.pageTitleIntegrations;
      case AppPage.settings:
        return l10n.pageTitleSettings;
      case AppPage.history:
        return l10n.pageTitleHistory;
      case AppPage.pricing:
        return l10n.pageTitlePricing;
      case AppPage.dashboard:
        return l10n.pageTitleDashboard;
    }
  }
}
