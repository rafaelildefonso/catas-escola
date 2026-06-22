import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CatasToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;

  const CatasToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Cores padrão baseadas no design premium do CATAS
    final Color effectiveActiveColor = activeColor ?? colorScheme.primary;
    final Color effectiveInactiveColor = inactiveColor ?? 
        (theme.brightness == Brightness.dark 
            ? colorScheme.surfaceContainerHighest 
            : colorScheme.outlineVariant);
    
    final Color effectiveThumbColor = thumbColor ?? colorScheme.surface;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: value ? effectiveActiveColor : effectiveInactiveColor,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              left: value ? 22 : 2,
              top: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: effectiveThumbColor,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
