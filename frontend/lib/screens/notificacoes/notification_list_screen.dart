import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/automation_labels.dart';
import '../../core/router.dart';
import '../../data/notifications_repository.dart';
import '../../components/catas_page.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key, this.returnLocation});

  final String? returnLocation;

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _repository = NotificationsRepository();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  String get _safeReturnLocation {
    final location = widget.returnLocation;
    if (location != null &&
        location.startsWith('/app') &&
        !location.startsWith(AppRoutes.notifications)) {
      return location;
    }
    return AppRoutes.chat;
  }

  void _goBack() {
    context.go(_safeReturnLocation);
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repository.list();
      if (mounted) setState(() => _items = items);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAutomationError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(Map<String, dynamic> item) async {
    try {
      await _repository.markRead(item['id'] as String);
      if (!mounted) return;
      final path = item['action_data']?.toString();
      if (path != null && path.startsWith('/app/automations/')) {
        final currentLocation = GoRouterState.of(context).uri.toString();
        final detailLocation = Uri.parse(
          path,
        ).replace(queryParameters: {'from': currentLocation}).toString();
        context.push(detailLocation);
      } else {
        _reload();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyAutomationError(error))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notificações'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Voltar para a tela anterior',
            onPressed: _goBack,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _reload,
                child: _error != null
                    ? ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          CatasEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Não foi possível carregar',
                            message: _error!,
                            action: FilledButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tentar novamente'),
                            ),
                          ),
                        ],
                      )
                    : _items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 96),
                          CatasEmptyState(
                            icon: Icons.notifications_none_rounded,
                            title: 'Tudo em dia',
                            message:
                                'Novidades sobre suas automações vão aparecer aqui.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final isRead = item['is_read'] == true;
                          final createdAt = DateTime.tryParse(
                            item['created_at']?.toString() ?? '',
                          )?.toLocal();
                          final dateLabel = createdAt == null
                              ? ''
                              : '${createdAt.day.toString().padLeft(2, '0')}/'
                                    '${createdAt.month.toString().padLeft(2, '0')}';
                          return Semantics(
                            button: true,
                            label: isRead
                                ? 'Notificação lida'
                                : 'Notificação não lida',
                            child: CatasSurface(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              onTap: () => _open(item),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color:
                                          (isRead
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest
                                                  : Theme.of(
                                                      context,
                                                    ).colorScheme.primary)
                                              .withValues(
                                                alpha: isRead ? 0.65 : 0.1,
                                              ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isRead
                                          ? Icons.notifications_none_rounded
                                          : Icons.notifications_active_rounded,
                                      color: isRead
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant
                                          : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title']?.toString() ?? '',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(item['body']?.toString() ?? ''),
                                      ],
                                    ),
                                  ),
                                  if (dateLabel.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      dateLabel,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
