import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/automation_labels.dart';
import '../core/router.dart';
import '../data/automations_repository.dart';
import '../providers/chat_provider.dart';

String _triggerLabel(Map<String, dynamic> trigger) {
  switch (trigger['type']) {
    case 'schedule':
      final minutes = trigger['interval_minutes'];
      return 'A cada $minutes minuto${minutes == 1 ? '' : 's'}';
    case 'cron':
      final fields = trigger['cron_expression']?.toString().split(' ') ?? [];
      if (fields.length == 5 && fields[0] != '*' && fields[1] != '*') {
        final minute = int.tryParse(fields[0]);
        final hour = int.tryParse(fields[1]);
        if (minute == null || hour == null) return 'Horário programado';
        final now = DateTime.now().toUtc();
        final localTime = DateTime.utc(
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        ).toLocal();
        final time =
            '${localTime.hour.toString().padLeft(2, '0')}:'
            '${localTime.minute.toString().padLeft(2, '0')}';
        if (fields[2] == '*' && fields[3] == '*' && fields[4] == '*') {
          return 'Todos os dias às $time';
        }
        if (fields[2] == '*' && fields[3] == '*' && fields[4] == '1-5') {
          return 'Dias úteis às $time';
        }
      }
      return 'Horário programado';
    default:
      return 'Execução sob demanda';
  }
}

String _nextExecution(dynamic value) {
  if (value == null) return 'Sob demanda';
  final raw = value.toString();
  final parsed = DateTime.tryParse(raw.endsWith('Z') ? raw : '${raw}Z');
  if (parsed == null) return 'Aguardando horário';
  final local = parsed.toLocal();
  String pad(int number) => number.toString().padLeft(2, '0');
  return '${pad(local.day)}/${pad(local.month)} ${pad(local.hour)}:${pad(local.minute)}';
}

IconData _stepIcon(String moduleId) {
  if (moduleId.startsWith('gmail.')) return Icons.email_outlined;
  if (moduleId.startsWith('google_calendar.')) {
    return Icons.calendar_month_outlined;
  }
  if (moduleId.startsWith('google_drive.')) return Icons.folder_outlined;
  if (moduleId.startsWith('google_sheets.')) return Icons.table_chart_outlined;
  if (moduleId == 'flow.wait') return Icons.schedule_outlined;
  if (moduleId == 'flow.condition') return Icons.alt_route_outlined;
  if (moduleId == 'flow.loop') return Icons.repeat_outlined;
  return Icons.auto_awesome_outlined;
}

String _stepsSummary(List<dynamic> steps) {
  if (steps.isEmpty) return 'Nenhum passo configurado';
  final first = Map<String, dynamic>.from(steps.first as Map);
  final count = steps.length;
  return '$count passo${count == 1 ? '' : 's'} · '
      '${friendlyAutomationStepName(first['module_id']?.toString() ?? '')}';
}

class ActiveAutomationsScreen extends StatefulWidget {
  const ActiveAutomationsScreen({super.key});

  @override
  State<ActiveAutomationsScreen> createState() =>
      _ActiveAutomationsScreenState();
}

class _ActiveAutomationsScreenState extends State<ActiveAutomationsScreen> {
  final _repository = AutomationsRepository();
  List<Map<String, dynamic>> _automations = [];
  bool _loading = true;
  String? _error;

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
      final data = await _repository.fetchAutomations(status: 'active');
      if (mounted) setState(() => _automations = data);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAutomationError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _edit([Map<String, dynamic>? automation]) async {
    if (automation == null) {
      context.read<ChatProvider>().setMessageDraft('Crie uma automação que ');
      context.go(AppRoutes.chat);
      return;
    }
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _AutomationEditor(repository: _repository, automation: automation),
    );
    if (changed == true) _reload();
  }

  Future<void> _setStatus(
    Map<String, dynamic> automation,
    String status,
  ) async {
    try {
      await _repository.saveAutomation({
        'status': status,
      }, id: automation['id'] as String);
      await _reload();
    } catch (error) {
      if (mounted) _message(friendlyAutomationError(error));
    }
  }

  Future<void> _delete(Map<String, dynamic> automation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir automação?'),
        content: Text(automation['name']?.toString() ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.deleteAutomation(automation['id'] as String);
      await _reload();
    } catch (error) {
      if (mounted) _message(friendlyAutomationError(error));
    }
  }

  Future<void> _showPaused() async {
    try {
      final paused = await _repository.fetchAutomations(status: 'paused');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Automações pausadas'),
          content: SizedBox(
            width: 460,
            child: paused.isEmpty
                ? const Text('Nenhuma automação pausada.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: paused.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(paused[index]['name']?.toString() ?? ''),
                      trailing: TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _setStatus(paused[index], 'active');
                        },
                        child: const Text('Ativar'),
                      ),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) _message(friendlyAutomationError(error));
    }
  }

  Future<void> _showDetails(Map<String, dynamic> automation) async {
    final trigger = Map<String, dynamic>.from(
      automation['trigger'] as Map? ?? {},
    );
    final steps = automation['steps'] as List? ?? const [];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        final description = automation['description']?.toString().trim() ?? '';
        return AlertDialog(
          title: const Text('Fluxo de trabalho'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.72,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    automation['name']?.toString() ?? 'Automação',
                    style: Theme.of(dialogContext).textTheme.titleLarge,
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(description),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quando acontece',
                          style: Theme.of(dialogContext).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(_triggerLabel(trigger)),
                        const SizedBox(height: 4),
                        Text(
                          'Próxima execução: ${_nextExecution(automation['next_run_at'])}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'O que a automação fará',
                    style: Theme.of(dialogContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Os passos serão executados nesta ordem.',
                    style: Theme.of(dialogContext).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (steps.isEmpty)
                    const Text('Nenhum passo foi configurado.')
                  else
                    ...steps.indexed.map((entry) {
                      final index = entry.$1;
                      final data = Map<String, dynamic>.from(entry.$2 as Map);
                      return _WorkflowStepCard(
                        number: index + 1,
                        isLast: index == steps.length - 1,
                        data: data,
                      );
                    }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Automações ativas'),
        actions: [
          TextButton(onPressed: _showPaused, child: const Text('Pausadas')),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Criar pelo chat'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _reload,
              child: _automations.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text(
                            'Nenhuma automação ativa. Descreva no chat o que você quer automatizar.',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      itemCount: _automations.length,
                      itemBuilder: (context, index) {
                        final item = _automations[index];
                        final trigger = Map<String, dynamic>.from(
                          item['trigger'] as Map? ?? {},
                        );
                        final steps = item['steps'] as List? ?? const [];
                        return Card(
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  item['name']?.toString() ?? 'Sem nome',
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_triggerLabel(trigger)} · Próxima execução: ${_nextExecution(item['next_run_at'])}',
                                      ),
                                      const SizedBox(height: 4),
                                      Text(_stepsSummary(steps)),
                                    ],
                                  ),
                                ),
                                trailing: PopupMenuButton<String>(
                                  tooltip:
                                      'Ações de ${item['name']?.toString() ?? 'automação'}',
                                  onSelected: (action) async {
                                    if (action == 'edit') {
                                      await _edit(item);
                                    }
                                    if (action == 'details') {
                                      await _showDetails(item);
                                    }
                                    if (action == 'pause') {
                                      await _setStatus(item, 'paused');
                                    }
                                    if (action == 'delete') {
                                      await _delete(item);
                                    }
                                    if (action == 'run') {
                                      try {
                                        await _repository.runAutomation(
                                          item['id'] as String,
                                        );
                                        if (mounted) {
                                          _message('Execução iniciada');
                                        }
                                      } catch (error) {
                                        if (mounted) {
                                          _message(
                                            friendlyAutomationError(error),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'run',
                                      child: Text('Executar agora'),
                                    ),
                                    PopupMenuItem(
                                      value: 'details',
                                      child: Text('Detalhes'),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Pedir alteração à IA'),
                                    ),
                                    PopupMenuItem(
                                      value: 'pause',
                                      child: Text('Pausar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Excluir'),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  8,
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: SizedBox(
                                    height: 48,
                                    child: TextButton.icon(
                                      onPressed: () => _showDetails(item),
                                      icon: const Icon(
                                        Icons.account_tree_outlined,
                                      ),
                                      label: const Text('Ver fluxo'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  const _WorkflowStepCard({
    required this.number,
    required this.isLast,
    required this.data,
  });

  final int number;
  final bool isLast;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final moduleId = data['module_id']?.toString() ?? '';
    final params = Map<String, dynamic>.from(data['params'] as Map? ?? {});
    final title = friendlyAutomationStepName(moduleId);
    final description = friendlyAutomationStepDescription(moduleId, params);
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      label: 'Passo $number: $title. $description',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Text(
                      '$number',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_stepIcon(moduleId), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(description),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!isLast)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                Icons.arrow_downward,
                size: 20,
                color: colors.onSurfaceVariant,
                semanticLabel: 'Depois',
              ),
            ),
        ],
      ),
    );
  }
}

class _AutomationEditor extends StatefulWidget {
  const _AutomationEditor({required this.repository, required this.automation});
  final AutomationsRepository repository;
  final Map<String, dynamic>? automation;

  @override
  State<_AutomationEditor> createState() => _AutomationEditorState();
}

class _AutomationEditorState extends State<_AutomationEditor> {
  final TextEditingController _instruction = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _instruction.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final request = _instruction.text.trim();
    if (request.isEmpty) {
      setState(() => _error = 'Descreva o que deseja alterar.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.reviseAutomation(
        widget.automation!['id'] as String,
        request,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = friendlyAutomationError(error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Alterar ${widget.automation?['name'] ?? 'automação'}'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Explique a mudança. A IA cuidará dos passos e dos horários.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _instruction,
              autofocus: true,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'O que você quer mudar?',
                hintText: 'Ex.: envie o resumo toda segunda-feira às 9h',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Alterando...' : 'Pedir alteração'),
        ),
      ],
    );
  }
}
