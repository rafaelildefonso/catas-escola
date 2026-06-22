import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactSelectComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;
  final bool readonly;

  const ContactSelectComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final purpose = data['purpose'] as String? ?? 'Selecione um contato';
    final selectedContacts = (data['selected_contacts'] as List<dynamic>?)?.cast<String>() ?? [];

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.contacts_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    purpose,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (selectedContacts.isEmpty)
              Text(
                'Nenhum contato selecionado',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedContacts
                    .map(
                      (c) => Chip(
                        avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        label: Text(c, style: GoogleFonts.inter(fontSize: 12)),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
