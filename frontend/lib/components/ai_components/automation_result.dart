import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AutomationResultComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;

  const AutomationResultComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
  });

  String _formatModuleName(String action) {
    return action.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final success = data['success'] as bool? ?? (data['status'] == 'completed' || data['status'] == 'success');
    
    String? title = data['title'] as String?;
    if (title == null && data.containsKey('action')) {
      final action = data['action'] as String;
      title = _formatModuleName(action);
    }
    title ??= (success ? 'Sucesso!' : 'Houve um problema');

    String? summary = data['summary'] as String?;
    if (summary == null && data.containsKey('status')) {
      summary = 'Status: ${data['status']}';
    }
    summary ??= '';
    
    final details = (data['details'] as List<dynamic>? ?? []);

    final color = success ? Colors.green : Theme.of(context).colorScheme.error;

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success ? Icons.check_rounded : Icons.close_rounded,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (summary.isNotEmpty)
                          Text(
                            summary,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (details.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 12,
                  children: details.map((detail) {
                    final label = detail['label'] ?? '';
                    final value = detail['value'] ?? '';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          value,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
