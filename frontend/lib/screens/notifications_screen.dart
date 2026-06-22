import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/notifications_provider.dart';
import '../models/notification_model.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<NotificationsProvider>();
      if (!provider.hasLoaded) {
        provider.loadNotifications().then((_) {
          if (mounted) _markVisibleAsRead();
        });
      } else {
        _markVisibleAsRead();
      }
    });
  }

  void _markVisibleAsRead() {
    context.read<NotificationsProvider>().markVisibleAsRead();
  }

  void _handleNotificationTap(AppNotification notification) {
    if (notification.actionType == 'external_url' &&
        notification.actionData != null) {
      launchUrl(
        Uri.parse(notification.actionData!),
        mode: LaunchMode.externalApplication,
      );
    } else if (notification.actionType == 'app_route' &&
        notification.actionData != null) {
      context.go(notification.actionData!);
    } else {
      // Fallback por tipo
      switch (notification.type) {
        case NotificationType.automation:
          context.go('/app/automations');
          break;
        case NotificationType.integration:
          context.go('/app/integrations');
          break;
        case NotificationType.billing:
          context.go('/app/settings/subscription');
          break;
        case NotificationType.update:
        case NotificationType.system:
          break; // Sem ação default
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Notificações",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/app');
            }
          },
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: Text(
                "Ler todas",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(theme, provider),
    );
  }

  Widget _buildBody(ThemeData theme, NotificationsProvider provider) {
    if (provider.isLoading && provider.notifications.isEmpty) {
      return Skeletonizer(
        enabled: true,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: 6,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _NotificationCard(
              notification: AppNotification(
                id: 'skeleton-$index',
                userId: 'skeleton',
                title: 'Título da Notificação fake para esqueleto',
                body: 'Corpo da notificação fake para preencher o espaço do esqueleto e dar feedback visual correto.',
                type: index % 2 == 0 ? NotificationType.update : NotificationType.automation,
                createdAt: DateTime.now(),
                isRead: false,
              ),
              onTap: () {},
            );
          },
        ),
      );
    }

    if (provider.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              "Nenhuma notificação",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Quando houver novidades, elas aparecerão aqui.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!provider.isLoading &&
            !provider.isLoadingMore &&
            provider.hasMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          provider.loadMoreNotifications();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => provider.loadNotifications(),
        color: theme.colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: provider.notifications.length +
              (provider.isLoadingMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == provider.notifications.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            final notification = provider.notifications[index];
            return _NotificationCard(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
            );
          },
        ),
      ),
    );
  }
}

// ─── Notification Card ───────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? theme.colorScheme.outline.withValues(alpha: 0.08)
                : theme.colorScheme.primary.withValues(alpha: 0.25),
            width: notification.isRead ? 1 : 1.5,
          ),
        ),
        child: _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (notification.type) {
      case NotificationType.update:
        return _buildUpdateCard(theme);
      case NotificationType.automation:
        return _buildAutomationCard(theme);
      case NotificationType.integration:
        return _buildGenericCard(
          theme,
          icon: Icons.device_hub,
          iconColor: const Color(0xFF8B5CF6), // Keep brand purple
          chipLabel: "Integração",
          chipColor: const Color(0xFF8B5CF6),
        );
      case NotificationType.billing:
        return _buildGenericCard(
          theme,
          icon: Icons.receipt_long_outlined,
          iconColor: Colors.amber[700]!, // More visible amber
          chipLabel: "Cobrança",
          chipColor: Colors.amber[700]!,
        );
      case NotificationType.system:
        return _buildGenericCard(
          theme,
          icon: Icons.auto_awesome,
          iconColor: theme.colorScheme.primary,
          chipLabel: "Sistema",
          chipColor: theme.colorScheme.primary,
        );
    }
  }

  // ─── UPDATE card ─────────────────────────────────────────────────────────

  Widget _buildUpdateCard(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner 16:9
        if (notification.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildNotificationImage(notification.imageUrl!, theme),
            ),
          ),
        if (notification.imageUrl != null) const SizedBox(height: 12),

        // Chip + time row
        Row(
          children: [
            _buildChip("Novidade", const Color(0xFF10B981), theme),
            const Spacer(),
            if (!notification.isRead) _buildUnreadDot(theme),
            _buildTimeAgo(theme),
          ],
        ),
        const SizedBox(height: 8),

        Text(
          notification.title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          notification.body,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── AUTOMATION card ─────────────────────────────────────────────────────

  Widget _buildAutomationCard(ThemeData theme) {
    final status = notification.automationStatus;
    final statusConfig = _automationStatusConfig(status, theme);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone de status
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusConfig.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            statusConfig.icon,
            size: 22,
            color: statusConfig.color,
          ),
        ),
        const SizedBox(width: 12),

        // Conteúdo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildChip(
                    statusConfig.label,
                    statusConfig.color,
                    theme,
                  ),
                  if (notification.automationName != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        notification.automationName!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (!notification.isRead) _buildUnreadDot(theme),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notification.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                notification.body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              _buildTimeAgo(theme),
            ],
          ),
        ),
      ],
    );
  }

  // ─── GENERIC card (integration / billing / system) ───────────────────────

  Widget _buildGenericCard(
    ThemeData theme, {
    required IconData icon,
    required Color iconColor,
    required String chipLabel,
    required Color chipColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildChip(chipLabel, chipColor, theme),
                  const Spacer(),
                  if (!notification.isRead) _buildUnreadDot(theme),
                  _buildTimeAgo(theme),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notification.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                notification.body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildChip(String label, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUnreadDot(ThemeData theme) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTimeAgo(ThemeData theme) {
    return Text(
      _formatTimeAgo(notification.createdAt),
      style: GoogleFonts.inter(
        fontSize: 11,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}sem';
    return '${(diff.inDays / 30).floor()}m';
  }

  _AutomationStatusConfig _automationStatusConfig(AutomationStatus status, ThemeData theme) {
    switch (status) {
      case AutomationStatus.success:
        return _AutomationStatusConfig(
          icon: Icons.check_circle_outline,
          color: const Color(0xFF10B981), // Green
          label: 'Sucesso',
        );
      case AutomationStatus.error:
        return _AutomationStatusConfig(
          icon: Icons.error_outline,
          color: theme.colorScheme.error,
          label: 'Erro',
        );
      case AutomationStatus.warning:
        return _AutomationStatusConfig(
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B), // Amber
          label: 'Aviso',
        );
    }
  }

  // ─── Shared Image Loader ─────────────────────────────────────────────────

  Widget _buildNotificationImage(String url, ThemeData theme) {
    final isSvg = url.toLowerCase().contains('.svg');

    if (isSvg) {
      return SvgPicture.network(
        url,
        fit: BoxFit.cover,
        placeholderBuilder: (context) => _buildPlaceholder(theme),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildPlaceholder(theme),
      errorWidget: (context, url, error) => _buildImageError(theme),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildImageError(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.system_update,
          size: 40,
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _AutomationStatusConfig {
  final IconData icon;
  final Color color;
  final String label;

  const _AutomationStatusConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}
