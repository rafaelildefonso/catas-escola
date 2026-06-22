import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PreviewDocsComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;

  const PreviewDocsComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Documento sem título';
    final snippet = data['snippet'] as String? ?? '';
    final url = data['url'] as String?;

    const Color docsBlue = Color(0xFF4285F4);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: docsBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: docsBlue.withValues(alpha: 0.1)),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, color: docsBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Google Docs',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: docsBlue,
                  ),
                ),
                if (url != null) ...[
                  const Spacer(),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (snippet.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    snippet,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
