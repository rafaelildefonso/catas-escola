import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CatasOptionItem {
  final String value;
  final IconData? icon;
  final String label;
  final String? subtitle;
  final bool isDestructive;
  final bool enabled;
  final Widget? trailing;

  const CatasOptionItem({
    required this.value,
    this.icon,
    required this.label,
    this.subtitle,
    this.isDestructive = false,
    this.enabled = true,
    this.trailing,
  });
}

class CatasOptionSection {
  final String? title;
  final List<CatasOptionItem> items;

  const CatasOptionSection({this.title, required this.items});
}

class CatasOptionsMenu {
  static Future<String?> show({
    required BuildContext context,
    required List<CatasOptionItem> items,
    required ValueChanged<String> onSelected,
    Offset? position,
  }) {
    return showSections(
      context: context,
      sections: [CatasOptionSection(items: items)],
      onSelected: onSelected,
      position: position,
    );
  }

  static Future<String?> showSections({
    required BuildContext context,
    required List<CatasOptionSection> sections,
    required ValueChanged<String> onSelected,
    Offset? position,
    double? right,
  }) async {
    final effectivePosition = position ?? _defaultPosition(context);
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    double estimatedHeight = 12;
    for (final section in sections) {
      if (section.title != null) estimatedHeight += 22;
      estimatedHeight += section.items.length * 48.0;
      if (sections.indexOf(section) > 0) estimatedHeight += 9;
    }

    double left = effectivePosition.dx;
    double top = effectivePosition.dy;

    if (top + estimatedHeight > screenSize.height - padding.bottom) {
      top = (screenSize.height - estimatedHeight - padding.bottom - 8)
          .clamp(0, screenSize.height);
    }

    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).dialogLabel,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, anim, secAnim) {
        return _MenuOverlay(
          sections: sections,
          onSelected: (value) => Navigator.of(ctx).pop(value),
          position: Offset(left, top),
          right: right,
        );
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 150),
    );

    if (result != null) onSelected(result);
    return result;
  }

  static Offset _defaultPosition(BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    final offset = box.localToGlobal(Offset.zero);
    return Offset(offset.dx, offset.dy + box.size.height);
  }
}

class _MenuOverlay extends StatelessWidget {
  final List<CatasOptionSection> sections;
  final ValueChanged<String> onSelected;
  final Offset position;
  final double? right;

  const _MenuOverlay({
    required this.sections,
    required this.onSelected,
    required this.position,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            right: right,
            left: right != null ? null : position.dx,
            top: position.dy,
            child: _CatasMenuContent(
              sections: sections,
              onSelected: onSelected,
            ),
          ),
        ],
      ),
    );
  }
}

class _CatasMenuContent extends StatelessWidget {
  final List<CatasOptionSection> sections;
  final ValueChanged<String> onSelected;

  const _CatasMenuContent({
    required this.sections,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 280),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildSections(context, theme, colorScheme),
        ),
      ),
    );
  }

  List<Widget> _buildSections(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final children = <Widget>[];

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];

      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
        );
      }

      if (section.title != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              section.title!,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }

      for (final item in section.items) {
        children.add(_buildItemRow(item, theme, colorScheme));
      }
    }

    return children;
  }

  Widget _buildItemRow(
    CatasOptionItem item,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final destructiveColor = colorScheme.error;
    final iconColor = item.isDestructive
        ? destructiveColor
        : colorScheme.onSurfaceVariant;
    final labelColor = item.isDestructive
        ? destructiveColor
        : colorScheme.onSurface;
    final subtitleColor = item.isDestructive
        ? destructiveColor.withValues(alpha: 0.7)
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    final hasIcon = item.icon != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: item.enabled ? () => onSelected(item.value) : null,
          child: Padding(
            padding: EdgeInsets.only(
              left: hasIcon ? 8 : 12,
              right: 12,
              top: item.subtitle != null ? 6 : 8,
              bottom: item.subtitle != null ? 6 : 8,
            ),
            child: Row(
              children: [
                if (hasIcon) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: item.isDestructive
                          ? destructiveColor.withValues(alpha: 0.08)
                          : colorScheme.secondaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.icon,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: labelColor,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: subtitleColor,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (item.trailing != null) ...[
                  const SizedBox(width: 8),
                  item.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OptionsButton extends StatelessWidget {
  final List<CatasOptionItem> items;
  final IconData icon;
  final double iconSize;
  final EdgeInsetsGeometry? padding;
  final ValueChanged<String>? onSelected;

  const OptionsButton({
    super.key,
    required this.items,
    this.icon = Icons.more_vert,
    this.iconSize = 20,
    this.padding,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(
        icon,
        size: iconSize,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      padding: padding ?? EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      onPressed: onSelected != null ? () => _openMenu(context) : null,
    );
  }

  void _openMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final overlayRender = Navigator.of(context).overlay?.context.findRenderObject();
    if (overlayRender == null || overlayRender is! RenderBox) return;

    final buttonRect = Rect.fromPoints(
      box.localToGlobal(Offset.zero, ancestor: overlayRender),
      box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlayRender),
    );

    final normalItems = items.where((item) => !item.isDestructive).toList();
    final destructiveItems = items.where((item) => item.isDestructive).toList();

    final sections = <CatasOptionSection>[];
    if (normalItems.isNotEmpty) sections.add(CatasOptionSection(items: normalItems));
    if (destructiveItems.isNotEmpty) sections.add(CatasOptionSection(items: destructiveItems));

    final rightInset = overlayRender.size.width - buttonRect.right;

    CatasOptionsMenu.showSections(
      context: context,
      sections: sections.isEmpty ? [CatasOptionSection(items: items)] : sections,
      position: Offset(buttonRect.right, buttonRect.bottom),
      right: rightInset,
      onSelected: onSelected!,
    );
  }
}

class OptionsTriggerButton extends StatelessWidget {
  final List<CatasOptionItem> items;
  final Widget? selectedLabel;
  final IconData? prefixIcon;
  final ValueChanged<String>? onSelected;

  const OptionsTriggerButton({
    super.key,
    required this.items,
    this.selectedLabel,
    this.prefixIcon,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onSelected != null ? () => _openMenu(context) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
            ],
            if (selectedLabel != null) selectedLabel!,
            const SizedBox(width: 6),
            Icon(
              Icons.unfold_more_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final globalBottomLeft = box.localToGlobal(Offset(0, box.size.height), ancestor: overlay);

    CatasOptionsMenu.showSections(
      context: context,
      sections: [CatasOptionSection(items: items)],
      position: globalBottomLeft,
      onSelected: onSelected!,
    );
  }
}

typedef OptionsMenuItem = CatasOptionItem;
