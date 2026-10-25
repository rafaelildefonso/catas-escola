import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/automation_labels.dart';
import '../core/router.dart';
import '../data/notifications_repository.dart';

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
                    ? ListView(children: [ListTile(title: Text(_error!))])
                    : _items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(child: Text('Nenhuma notificação')),
                        ],
                      )
                    : ListView.builder(
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
                            child: ListTile(
                              minVerticalPadding: 12,
                              leading: Icon(
                                isRead
                                    ? Icons.notifications_none
                                    : Icons.notifications_active,
                              ),
                              title: Text(item['title']?.toString() ?? ''),
                              subtitle: Text(item['body']?.toString() ?? ''),
                              trailing: Text(dateLabel),
                              onTap: () => _open(item),
                            ),
                          );
                        },
                      ),
              ),
      ),
    );
  }
}
