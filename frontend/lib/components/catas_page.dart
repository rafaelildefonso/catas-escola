import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/design_tokens.dart';

/// Shared layout primitives for CATAS product screens.
class CatasPage extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;
  final List<Widget> actions;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const CatasPage({
    super.key,
    required this.title,
    this.description,
    required this.child,
    this.actions = const [],
    this.maxWidth = 1180,
    this.padding = const EdgeInsets.fromLTRB(24, 28, 24, 40),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 700;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: compact
              ? const EdgeInsets.fromLTRB(16, 20, 16, 32)
              : padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: compact ? 520 : 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: compact ? 24 : 29,
                            height: 1.15,
                            letterSpacing: -0.6,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            description!,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              height: 1.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ),
              const SizedBox(height: 28),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class CatasSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  const CatasSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: context.catasTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(context.catasTokens.radiusMedium),
        border: Border.all(color: context.catasTokens.borderSubtle),
      ),
      child: child,
    );

    if (onTap == null) return surface;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(context.catasTokens.radiusMedium),
        child: surface,
      ),
    );
  }
}

enum CatasStatusTone { neutral, info, success, warning, danger }

class CatasStatusBadge extends StatelessWidget {
  final String label;
  final CatasStatusTone tone;
  final IconData? icon;

  const CatasStatusBadge({
    super.key,
    required this.label,
    this.tone = CatasStatusTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.catasTokens;
    final color = switch (tone) {
      CatasStatusTone.info => tokens.info,
      CatasStatusTone.success => tokens.success,
      CatasStatusTone.warning => tokens.warning,
      CatasStatusTone.danger => tokens.danger,
      CatasStatusTone.neutral => theme.colorScheme.onSurfaceVariant,
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(tokens.radiusSmall),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatasSectionHeader extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? action;

  const CatasSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (action != null) action!,
      ],
    );
  }
}

class CatasEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const CatasEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 25),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}
