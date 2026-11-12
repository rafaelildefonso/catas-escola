import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_tokens.dart';

class AlertBannerComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;

  const AlertBannerComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final level = data['level'] as String? ?? 'info';
    final title = data['title'] as String? ?? '';
    final message = data['message'] as String? ?? '';
    final action = data['action'] as Map<String, dynamic>?;

    final tokens = context.catasTokens;
    Color baseColor;
    IconData icon;

    switch (level) {
      case 'warning':
        baseColor = tokens.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case 'error':
        baseColor = tokens.danger;
        icon = Icons.error_outline_rounded;
        break;
      case 'success':
        baseColor = tokens.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      default:
        baseColor = Theme.of(context).colorScheme.primary;
        icon = Icons.info_outline_rounded;
    }

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(tokens.radiusMedium),
          border: Border.all(color: baseColor.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: baseColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: TextButton(
                  onPressed: () {
                    final route = action['route'] as String?;
                    if (route != null) {
                      context.go(route);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: baseColor,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        action['label'] ?? 'Saiba mais',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
