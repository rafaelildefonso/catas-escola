import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/design_tokens.dart';

class CatasLoadingIndicator extends StatelessWidget {
  const CatasLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Text(
      'CATAS está pensando...',
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final content = context.reduceMotion
        ? text
        : text
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1800.ms,
                color: theme.colorScheme.primary.withValues(alpha: 0.85),
              );

    return Semantics(
      liveRegion: true,
      label: 'CATAS está preparando a resposta',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            content,
          ],
        ),
      ),
    );
  }
}
