import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DriveFileSelectComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;
  final bool readonly;

  const DriveFileSelectComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
    this.readonly = false,
  });

  @override
  Widget build(BuildContext context) {
    final purpose = data['purpose'] as String? ?? 'Selecione arquivos do Drive';
    final selectedFiles = (data['selected_files'] as List<dynamic>?)?.cast<String>() ?? [];

    const Color driveBlue = Color(0xFF4285F4);

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
                const Icon(Icons.add_to_drive_rounded, color: driveBlue, size: 20),
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
            if (selectedFiles.isEmpty)
              Text(
                'Nenhum arquivo selecionado',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: selectedFiles.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.insert_drive_file_outlined, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        f,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
