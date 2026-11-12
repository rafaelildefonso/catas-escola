import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/design_tokens.dart';

class CatasDialog extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? content;
  final Widget? icon;
  final List<CatasDialogAction> actions;

  const CatasDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.catasTokens;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: tokens.surfaceRaised.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(tokens.radiusLarge),
            border: Border.all(color: tokens.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(height: 16)],
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (message != null || content != null) ...[
                const SizedBox(height: 12),
                if (message != null)
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ?content,
              ],
              const SizedBox(height: 24),
              OverflowBar(
                alignment: MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                spacing: 12,
                overflowSpacing: 12,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CatasDialogAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;
  final bool isDestructive;

  const CatasDialogAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isSecondary) {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: isDestructive
            ? context.catasTokens.danger
            : theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

Future<T?> showCatasDialog<T>({
  required BuildContext context,
  required String title,
  String? message,
  Widget? content,
  Widget? icon,
  required List<CatasDialogAction> Function(BuildContext context)
  actionsBuilder,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => CatasDialog(
      title: title,
      message: message,
      content: content,
      icon: icon,
      actions: actionsBuilder(context),
    ),
  );
}
