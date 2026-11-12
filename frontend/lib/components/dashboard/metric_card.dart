import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A premium metric card with animated count-up and gradient icon background.
class MetricCard extends StatefulWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final int animationDelayMs;
  final EdgeInsetsGeometry? padding;
  final bool expanded;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.animationDelayMs = 0,
    this.padding,
    this.expanded = false,
  });

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _countController;
  late Animation<double> _countAnimation;
  double? _numericValue;

  @override
  void initState() {
    super.initState();
    // Try parsing the value as a number for count-up animation
    _numericValue = double.tryParse(
      widget.value.replaceAll(RegExp(r'[^\d.]'), ''),
    );

    _countController = AnimationController(
      duration: Duration(milliseconds: kIsWeb ? 600 : 1200),
      vsync: this,
    );

    _countAnimation = Tween<double>(begin: 0, end: _numericValue ?? 0).animate(
      CurvedAnimation(parent: _countController, curve: Curves.easeOutCubic),
    );

    // Delayed start for staggered feel
    Future.delayed(Duration(milliseconds: widget.animationDelayMs + 300), () {
      if (mounted) _countController.forward();
    });
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  String _formatDisplayValue(double val) {
    // If original has decimal, show one decimal. Otherwise integer.
    if (widget.value.contains('.')) {
      return val.toStringAsFixed(1);
    }
    return val.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Widget card =
        Container(
              padding: widget.padding ?? const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111113) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Animated value
                  _numericValue != null
                      ? AnimatedBuilder(
                          animation: _countAnimation,
                          builder: (context, _) {
                            // Extract prefix/suffix from the original value
                            final prefix =
                                widget.value.startsWith(RegExp(r'[^\d]'))
                                ? widget.value.substring(
                                    0,
                                    widget.value.indexOf(RegExp(r'[\d]')),
                                  )
                                : '';
                            final suffixMatch = RegExp(
                              r'[^\d.]+$',
                            ).firstMatch(widget.value);
                            final suffix = suffixMatch?.group(0) ?? '';

                            return Text(
                              '$prefix${_formatDisplayValue(_countAnimation.value)}$suffix',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            );
                          },
                        )
                      : Text(
                          widget.value,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),

                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: widget.accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            )
            .animate(delay: Duration(milliseconds: widget.animationDelayMs))
            .fadeIn(duration: 500.ms)
            .slideY(
              begin: 0.1,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            );

    return widget.expanded ? Expanded(child: card) : card;
  }
}
