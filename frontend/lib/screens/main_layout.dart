import 'package:catas/core/app_config.dart';
import 'package:catas/core/router.dart';
import 'package:catas/core/navigation_helpers.dart';
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
import '../components/chat/model_selector.dart';
import 'package:desktop_drop/desktop_drop.dart';
import '../models/picked_attachment.dart';
import '../l10n/app_localizations.dart';
import '../core/design_tokens.dart';

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
        path: file
            .path, // DropDoneDetails might give a path but sometimes it needs special handling, we assume path is ok
        name: file.name,
        isImage: isImage,
      ),
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
    final nav = context.read<NavigationProvider>();
    final auth = context.watch<AuthProvider>();
    final integrations = context.watch<IntegrationsProvider>();
    final l10n = AppLocalizations.of(context)!;

    // Sincroniza o NavigationProvider com a rota atual (Importante para F5/Link Direto)
    final String location = GoRouterState.of(context).matchedLocation;
    final page = getPageFromLocation(location);

    // Título e página atuais baseados na rota real (evita flicker do Provider)
    final currentPage = page;
    final pageTitle = getLocalizedPageTitle(context, currentPage);
    final useNavigationRail = MediaQuery.sizeOf(context).width >= 720;

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
        backgroundColor: context.catasTokens.canvas,
        appBar: AppBar(
          backgroundColor: context.catasTokens.canvas,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: currentPage == AppPage.chat ? false : true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          ),
          title: currentPage == AppPage.chat && auth.subscriptionTier != 'free'
              ? ModelSelectorWidget(
                  horizontalPadding: 12,
                  iconSpacing: 4,
                  onUpgradeRequired: (context, model) {
                    final l10n = AppLocalizations.of(context);
                    UpgradeModal.show(
                      context,
                      '${l10n!.textDialogTitle} $model',
                      getRequiredTier(model),
                    );
                  },
                )
              : Text(
                  pageTitle,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          actions: [
            nav.currentPage == AppPage.chat &&
                    auth.subscriptionTier != 'free' &&
                    !AppConfig.isDemoMode
                ? Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
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
        bottomNavigationBar: useNavigationRail
            ? null
            : _buildMobileNavigation(context, currentPage),
        body: Stack(
          children: [
            Row(
              children: [
                if (useNavigationRail)
                  _buildNavigationRail(context, currentPage),
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragEnd: (details) {
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 200) {
                        _scaffoldKey.currentState?.openDrawer();
                      }
                    },
                    child: SafeArea(
                      top: false,
                      child: Container(
                        color: Colors.transparent,
                        child: widget.child,
                      ),
                    ),
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
        ),
      ),
    );
  }

  Widget _buildMobileNavigation(BuildContext context, AppPage currentPage) {
    final selectedIndex = switch (currentPage) {
      AppPage.chat => 0,
      AppPage.automations => 1,
      AppPage.integrations => 2,
      _ => 3,
    };

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) =>
          _navigateFromAdaptiveNav(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.forum_outlined),
          selectedIcon: Icon(Icons.forum_rounded),
          label: 'Chat',
        ),
        NavigationDestination(
          icon: Icon(Icons.bolt_outlined),
          selectedIcon: Icon(Icons.bolt_rounded),
          label: 'Automações',
        ),
        NavigationDestination(
          icon: Icon(Icons.extension_outlined),
          selectedIcon: Icon(Icons.extension_rounded),
          label: 'Integrações',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined),
          selectedIcon: Icon(Icons.grid_view_rounded),
          label: 'Mais',
        ),
      ],
    );
  }

  Widget _buildNavigationRail(BuildContext context, AppPage currentPage) {
    final selectedIndex = switch (currentPage) {
      AppPage.chat => 0,
      AppPage.automations => 1,
      AppPage.integrations => 2,
      _ => 3,
    };
    final tokens = context.catasTokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceRaised,
        border: Border(right: BorderSide(color: tokens.borderSubtle)),
      ),
      child: SafeArea(
        child: NavigationRail(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) =>
              _navigateFromAdaptiveNav(context, index),
          labelType: NavigationRailLabelType.all,
          leading: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Tooltip(
              message: 'Novo chat',
              child: IconButton.filled(
                onPressed: () {
                  context.read<ChatProvider>().clearChat();
                  context.go(AppRoutes.chat);
                },
                icon: const Icon(Icons.add),
              ),
            ),
          ),
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: Text('Chat'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.bolt_outlined),
              selectedIcon: Icon(Icons.bolt_rounded),
              label: Text('Automações'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.extension_outlined),
              selectedIcon: Icon(Icons.extension_rounded),
              label: Text('Integrações'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: Text('Mais'),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateFromAdaptiveNav(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.chat);
        return;
      case 1:
        context.go(AppRoutes.automations);
        return;
      case 2:
        context.go(AppRoutes.integrations);
        return;
      default:
        _scaffoldKey.currentState?.openDrawer();
    }
  }
}
