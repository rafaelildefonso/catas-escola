import 'package:flutter/material.dart';

import '../core/design_tokens.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.catasTokens;
    return Semantics(
      toggled: value,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: activeColor ?? scheme.primary,
        inactiveTrackColor: inactiveColor ?? tokens.surfaceMuted,
        activeThumbColor: thumbColor ?? scheme.onPrimary,
        inactiveThumbColor: thumbColor ?? scheme.onSurfaceVariant,
        trackOutlineColor: WidgetStatePropertyAll(tokens.borderSubtle),
      ),
    );
  }
}
