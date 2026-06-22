import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TextInputComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;
  final bool readonly;

  const TextInputComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = data['label'] as String? ?? 'Sua resposta';
    final value = data['value'] as String? ?? '';

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
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
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.isEmpty ? '---' : value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: value.isEmpty
                    ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)
                    : Theme.of(context).colorScheme.onSurface,
                  fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
