import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CodeBlockComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;

  const CodeBlockComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final code = data['code'] as String? ?? '';
    final language = data['language'] as String? ?? 'text';
    final title = data['title'] as String? ?? '';

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark VSCode-like color
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Text(
                    language.toUpperCase(),
                    style: GoogleFonts.firaCode(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  if (title.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else const Spacer(),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Código copiado!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white70),
                    tooltip: 'Copiar código',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            // Code
            Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  code,
                  style: GoogleFonts.firaCode(
                    fontSize: 13,
                    color: const Color(0xFFD4D4D4),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
