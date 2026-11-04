import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/navigation_provider.dart';
import '../core/router.dart';
import '../core/navigation_helpers.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../l10n/app_localizations.dart';
import 'catas_input.dart';
import 'chat/options_button.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with TickerProviderStateMixin {

  void _navigateTo(BuildContext context, AppPage page) {
    context.go(getRouteForPage(page));
    Navigator.pop(context); // Close Drawer
  }

  void _createNewChat(BuildContext context) {
    context.read<ChatProvider>().clearChat();
    context.go(AppRoutes.chat);
    Navigator.pop(context); // Close Drawer
  }

  Future<void> _openSession(String sessionId) async {
    await context.read<ChatProvider>().switchSession(sessionId);
    if (!context.mounted) return;
    context.go(AppRoutes.chatSession(sessionId));
    context.read<NavigationProvider>().setPage(AppPage.chat);
    Navigator.pop(context);
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
            content: CatasInput(
              controller: controller,
              hintText: l10n.renameChatHint,
              autofocus: true,
              maxLength: 50,
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
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final chat = context.watch<ChatProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final unreadCount = 0;

    if (chat.sessions.isEmpty &&
        !chat.isLoadingSessions &&
        !chat.hasAttemptedLoadSessions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ChatProvider>().loadSessions();
      });
    }

    return Drawer(
      backgroundColor: theme.drawerTheme.backgroundColor,
      width: screenWidth * 0.9,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(0)),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            _buildNormalMode(context, chat, theme, unreadCount),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final l10n = AppLocalizations.of(context)!;
                return Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: InkWell(
                  onTap: () => _navigateTo(context, AppPage.settings),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.drawerTheme.backgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.2,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: auth.userPhotoUrl != null
                              ? Image.network(
                                  auth.userPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.person,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.white,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                auth.userName ?? l10n.defaultUserName,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              if (auth.subscriptionTier != null && auth.subscriptionTier != 'free')
                                Text(
                                  "${auth.subscriptionTier!.toUpperCase()} ${l10n.planSuffix}",
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: auth.subscriptionTier == 'max'
                                        ? (theme.brightness == Brightness.dark
                                            ? Colors.blue[400]
                                            : const Color(0xFF0D47A1))
                                        : (auth.subscriptionTier == 'pro'
                                            ? theme.colorScheme.primary
                                            : Colors.grey),
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
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildNormalMode(
    BuildContext context,
    ChatProvider chat,
    ThemeData theme,
    int unreadCount,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header & New Chat
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      theme.brightness == Brightness.dark
                          ? 'assets/icons/app_icon_transparent_white.png'
                          : 'assets/icons/app_icon_transparent.png',
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.appBrandName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),

                    // Notificações
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: () {
                            Navigator.pop(context);
                            context.go(AppRoutes.notifications);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: theme.colorScheme.secondaryContainer,
                            ),
                            child: Icon(
                              Icons.notifications_none_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (unreadCount > 0)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.drawerTheme.backgroundColor ??
                                      theme.colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _createNewChat(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      l10n.drawerNewChat,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 10,
                      ),
                      alignment: Alignment.centerLeft,
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Shortcuts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildShortcutButton(
                        context,
                        l10n.drawerAutomations,
                        Icons.route_outlined,
                        () => _navigateTo(context, AppPage.automations),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildShortcutButton(
                        context,
                        l10n.drawerIntegrations,
                        Icons.device_hub_outlined,
                        () => _navigateTo(context, AppPage.integrations),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateTo(context, AppPage.dashboard),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.dashboard_outlined,
                                size: 24,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.drawerDashboard,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateTo(context, AppPage.relatorios),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.insights_outlined,
                                size: 24,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Relatórios',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.drawerRecentChats,
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () => _navigateTo(context, AppPage.history),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.drawerSeeAll,
                    style: GoogleFonts.inter(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSessionsList(context, chat, theme, shrinkWrap: true),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSessionsList(
    BuildContext context,
    ChatProvider chat,
    ThemeData theme, {
    required bool shrinkWrap,
  }) {
    final l10n = AppLocalizations.of(context)!;

    if (chat.isLoading) {
      return Skeletonizer(
        enabled: true,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: 5,
          itemBuilder: (context, index) =>
              _buildHistoryItem(context, "loading", l10n.drawerLoading, false),
        ),
      );
    }

    if (chat.sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            l10n.drawerNoRecentChats,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final sessions = chat.filteredSessions.take(10).toList();
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            l10n.drawerNoResults,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: sessions
          .map(
            (s) => _buildHistoryItem(
              context,
              s.id,
              s.title,
              chat.currentSessionId == s.id,
              onTap: () => _openSession(s.id),
              pinned: chat.isPinnedSession(s.id),
            ),
          )
          .toList(),
    );
  }

  Widget _buildShortcutButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    String sessionId,
    String title,
    bool active, {
    VoidCallback? onTap,
    bool pinned = false,
  }) {
    final theme = Theme.of(context);

    return ListTile(
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: active
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pinned)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.push_pin,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            OptionsButton(
              iconSize: 18,
              padding: const EdgeInsets.all(4),
              items: [
                CatasOptionItem(
                  value: 'rename',
                  icon: Icons.edit_outlined,
                  label: AppLocalizations.of(context)!.actionRename,
                ),
                CatasOptionItem(
                  value: 'pin',
                  icon: pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  label: pinned
                      ? AppLocalizations.of(context)!.actionUnpin
                      : AppLocalizations.of(context)!.actionPin,
                ),
                CatasOptionItem(
                  value: 'delete',
                  icon: Icons.delete_outline,
                  label: AppLocalizations.of(context)!.actionDelete,
                  isDestructive: true,
                ),
              ],
              onSelected: (value) => _handleSessionAction(context, value, sessionId, title),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        dense: true,
        onTap: () {
          if (onTap != null) {
            onTap();
            return;
          }
          _openSession(sessionId);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        tileColor: active
            ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
            : null,
    );
  }
}

