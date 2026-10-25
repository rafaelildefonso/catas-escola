import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../core/router.dart';
import '../../components/options_button.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../l10n/app_localizations.dart';

class WebSidebar extends StatefulWidget {
  final Function(AppPage) onNavigate;
  final VoidCallback onNewChat;
  final VoidCallback onOpenSettings;

  const WebSidebar({
    super.key,
    required this.onNavigate,
    required this.onNewChat,
    required this.onOpenSettings,
  });

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  bool _isCollapsed = false;
  bool _collapseInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Set initial collapse state based on screen size (only on first build)
    if (!_collapseInitialized) {
      _collapseInitialized = true;
      final screenWidth = MediaQuery.of(context).size.width;
      _isCollapsed = screenWidth < 1200;
    }
  }

  Future<void> _openSession(String sessionId) async {
    await context.read<ChatProvider>().switchSession(sessionId);
    if (!mounted) return;
    context.go(AppRoutes.chatSession(sessionId));
    context.read<NavigationProvider>().setPage(AppPage.chat);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nav = context.watch<NavigationProvider>();
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();

    if (chat.sessions.isEmpty &&
        !chat.isLoadingSessions &&
        !chat.hasAttemptedLoadSessions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatProvider>().loadSessions();
      });
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: _isCollapsed ? 70 : 280,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(
              _isCollapsed ? 11 : 16,
              20,
              _isCollapsed ? 11 : 16,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: _isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isCollapsed)
                      Row(
                        children: [
                          Image.asset(
                            theme.brightness == Brightness.dark
                                ? 'assets/icons/app_icon_transparent_white.png'
                                : 'assets/icons/app_icon_transparent.png',
                            width: 40,
                            height: 40,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "CATAS",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    Tooltip(
                      message: _isCollapsed ? 'Expandir menu' : 'Recolher menu',
                      child: Semantics(
                        button: true,
                        label: _isCollapsed
                            ? 'Expandir menu lateral'
                            : 'Recolher menu lateral',
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: FilledButton(
                            onPressed: () =>
                                setState(() => _isCollapsed = !_isCollapsed),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.center,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: theme.colorScheme.surface,
                              foregroundColor: theme.colorScheme.onSurface,
                            ),
                            child: Icon(
                              _isCollapsed ? Icons.menu : Icons.menu_open,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Tooltip(
                  message: 'Novo chat',
                  child: Semantics(
                    button: true,
                    label: 'Iniciar novo chat',
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: widget.onNewChat,
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: _isCollapsed ? 0 : 16,
                          ),
                          alignment: _isCollapsed
                              ? Alignment.center
                              : Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add, size: 18),
                              if (!_isCollapsed) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  "Novo Chat",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
          _buildNavItem(
            context,
            icon: Icons.dashboard_outlined,
            label: "Dashboard",
            page: AppPage.dashboard,
            isSelected: nav.currentPage == AppPage.dashboard,
          ),
          _buildNavItem(
            context,
            icon: Icons.route_outlined,
            label: "Automações",
            page: AppPage.automations,
            isSelected: nav.currentPage == AppPage.automations,
          ),
          _buildNavItem(
            context,
            icon: Icons.device_hub,
            label: "Integrações",
            page: AppPage.integrations,
            isSelected: nav.currentPage == AppPage.integrations,
          ),
          _buildNavItem(
            context,
            icon: Icons.history_outlined,
            label: "Histórico",
            page: AppPage.history,
            isSelected: nav.currentPage == AppPage.history,
          ),
          _buildNavItem(
            context,
            icon: Icons.workspace_premium_outlined,
            label: "Planos",
            page: AppPage.pricing,
            isSelected: nav.currentPage == AppPage.pricing,
          ),
          _buildNavItem(
            context,
            icon: Icons.insights_outlined,
            label: "Relatórios",
            page: AppPage.relatorios,
            isSelected: nav.currentPage == AppPage.relatorios,
          ),

          // Divider only when expanded
          if (!_isCollapsed) const Divider(height: 24),

          // Recent chats - only show when expanded
          if (!_isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Chats Recentes",
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chat.isLoadingSessions
                  ? Skeletonizer(
                      enabled: true,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: 5,
                        itemBuilder: (context, index) => _buildChatItem(
                          context,
                          title: "Carregando...",
                          isActive: false,
                          pinned: false,
                        ),
                      ),
                    )
                  : chat.sessions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon(
                            //   Icons.chat_bubble_outline,
                            //   size: _isCollapsed ? 24 : 40,
                            //   color: theme.colorScheme.onSurface.withValues(
                            //     alpha: 0.2,
                            //   ),
                            // ),
                            if (!_isCollapsed) ...[
                              const SizedBox(height: 12),
                              Text(
                                "Nenhum chat ainda",
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: chat.filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = chat.filteredSessions[index];
                        return _buildChatItem(
                          context,
                          title: session.title,
                          isActive: chat.currentSessionId == session.id,
                          pinned: chat.isPinnedSession(session.id),
                          onTap: () => _openSession(session.id),
                          sessionId: session.id,
                        );
                      },
                    ),
            ),
          ],

          // // Expand button when collapsed
          // if (_isCollapsed) ...[
          //   const SizedBox(height: 16),
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16),
          //     child: IconButton(
          //       icon: const Icon(Icons.history, size: 20),
          //       onPressed: () => setState(() => _isCollapsed = false),
          //       tooltip: "Ver Chats",
          //     ),
          //   ),
          // ],

          // Spacer to push user footer to bottom
          if (_isCollapsed) const Spacer(),

          // User footer
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: InkWell(
              onTap: widget.onOpenSettings,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: _isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      backgroundImage: auth.userPhotoUrl != null
                          ? NetworkImage(auth.userPhotoUrl!)
                          : null,
                      child: auth.userPhotoUrl == null
                          ? Text(
                              (auth.userName ?? "U")[0].toUpperCase(),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : null,
                    ),
                    if (!_isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.userName ?? "Usuário",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              (auth.subscriptionTier == 'free' ||
                                      auth.subscriptionTier == null)
                                  ? ''
                                  : auth.subscriptionTier!.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: auth.subscriptionTier == 'max'
                                    ? (theme.brightness == Brightness.dark
                                          ? Colors.blue[400]!
                                          : const Color(0xFF0D47A1))
                                    : (auth.subscriptionTier == 'pro'
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant
                                                .withValues(alpha: 0.5)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required AppPage page,
    required bool isSelected,
  }) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        message: _isCollapsed ? label : '',
        child: InkWell(
          onTap: () {
            widget.onNavigate(page);
            context.read<NavigationProvider>().setPage(page);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context, {
    required String title,
    required bool isActive,
    required bool pinned,
    VoidCallback? onTap,
    String? sessionId,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: _isCollapsed ? title : '',
      preferBelow: false,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: _isCollapsed ? 0 : 8,
            vertical: 0,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.1)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _isCollapsed
                    ? const SizedBox(width: 14) // Centering adjustment
                    : const SizedBox(width: 12),
                SizedBox(
                  width: 164, // max width to avoid overflow
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (pinned)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.push_pin,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                if (!_isCollapsed && sessionId != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: OptionsButton(
                      iconSize: 16,
                      padding: const EdgeInsets.all(4),
                      items: [
                        CatasOptionItem(
                          value: 'rename',
                          icon: Icons.edit_outlined,
                          label: l10n.actionRename,
                        ),
                        CatasOptionItem(
                          value: 'pin',
                          icon: pinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          label: pinned ? l10n.actionUnpin : l10n.actionPin,
                        ),
                        CatasOptionItem(
                          value: 'delete',
                          icon: Icons.delete_outline,
                          label: l10n.actionDelete,
                          isDestructive: true,
                        ),
                      ],
                      onSelected: (value) => _handleSessionAction(
                        context,
                        value,
                        sessionId,
                        title,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSessionAction(
    BuildContext context,
    String action,
    String sessionId,
    String currentTitle,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.read<ChatProvider>();

    switch (action) {
      case 'rename':
        final controller = TextEditingController(text: currentTitle);
        final newTitle = await showDialog<String>(
          context: context,
          builder: (dctx) => AlertDialog(
            title: Text(l10n.renameChatTitle),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLength: 50,
              decoration: InputDecoration(hintText: l10n.renameChatHint),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(),
                child: Text(l10n.actionCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(controller.text.trim()),
                child: Text(l10n.actionSave),
              ),
            ],
          ),
        );

        if (newTitle != null && newTitle.isNotEmpty) {
          await chat.renameSession(sessionId, newTitle);
        }
        break;
      case 'pin':
        await chat.togglePin(sessionId);
        break;
      case 'delete':
        final deleteTheme = Theme.of(context);
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dctx) => AlertDialog(
            title: Text(l10n.deleteChatTitle),
            content: Text(l10n.deleteChatContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(false),
                child: Text(l10n.actionCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: deleteTheme.colorScheme.error,
                ),
                child: Text(l10n.actionDelete),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await chat.deleteSession(sessionId);
        }
        break;
    }
  }
}
