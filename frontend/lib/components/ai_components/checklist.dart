import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChecklistComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;
  final bool readonly;

  const ChecklistComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Checklist';
    final items = (data['items'] as List<dynamic>? ?? []);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            ...List.generate(items.length, (index) {
              final item = items[index];
              final checked = item['checked'] as bool? ?? false;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 20,
                      color: checked
                        ? Colors.green
                        : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['label'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          decoration: checked ? TextDecoration.lineThrough : null,
                          color: checked
                            ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                            : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
