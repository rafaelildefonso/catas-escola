import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DateTimePickerComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;
  final bool readonly;

  const DateTimePickerComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = data['label'] as String? ?? 'Selecione Data e Hora';
    final selectedDate = data['selected_date'] as String?;
    final selectedTime = data['selected_time'] as String?;
    final hasValue = selectedDate != null || selectedTime != null;

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
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  hasValue
                    ? '${selectedDate ?? '---'} às ${selectedTime ?? '---'}'
                    : '---',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: hasValue
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
