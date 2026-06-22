import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionApprovalComponent extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;
  final bool readonly;
  final void Function(Map<String, dynamic> responseData)? onResponse;

  const ActionApprovalComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.readonly = false,
    this.onResponse,
  });

  @override
  State<ActionApprovalComponent> createState() =>
      _ActionApprovalComponentState();
}

class _ActionApprovalComponentState extends State<ActionApprovalComponent> {
  bool _responded = false;
  bool? _approved;

  @override
  Widget build(BuildContext context) {
    final title = widget.data['title'] as String? ?? 'Aprovar Ação';
    final description =
        widget.data['description'] as String? ?? 'Deseja continuar?';
    final dangerLevel = widget.data['danger_level'] as String? ?? 'low';

    final Color accentColor = dangerLevel == 'high'
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    final bool isDone = _responded || !widget.isEnabled;
    final double opacity = isDone ? 0.6 : 1.0;

    final Widget componentContent = Opacity(
        opacity: opacity,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: isDone ? 0.3 : 0.5),
            border: Border.all(color: accentColor.withValues(alpha: isDone ? 0.1 : 0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    dangerLevel == 'high'
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (_responded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (_approved == true ? Colors.green : Theme.of(context).colorScheme.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _approved == true ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: _approved == true ? Colors.green : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _approved == true ? 'Ação Aprovada' : 'Ação Recusada',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _approved == true ? Colors.green : Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                )
              else if (!widget.isEnabled)
                Text(
                  'Ação expirada ou indisponível',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _responded = true;
                          _approved = false;
                        });
                        widget.onResponse?.call({'approved': false});
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _responded = true;
                          _approved = true;
                        });
                        widget.onResponse?.call({'approved': true});
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: dangerLevel == 'high' 
                            ? Theme.of(context).colorScheme.onError 
                            : Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Aprovar e Executar'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

    return componentContent;
  }
}
