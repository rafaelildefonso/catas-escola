import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catas/components/brand_logo.dart';
import 'package:catas/screens/integrations_screen.dart' show IntegrationItem, IntegrationCategory;

class MentionMenu extends StatelessWidget {
  final List<IntegrationItem> items;
  final Function(IntegrationItem) onSelect;

  const MentionMenu({
    super.key,
    required this.items,
    required this.onSelect,
  });

  String _formatCategory(IntegrationCategory cat) {
    switch (cat) {
      case IntegrationCategory.productivity:
        return 'Produtividade';
      case IntegrationCategory.communication:
        return 'Comunicação';
      case IntegrationCategory.google:
        return 'Google';
      default:
        return 'Outros';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group items by their first category
    final groupedItems = <String, List<IntegrationItem>>{};
    for (var item in items) {
      final categoryTitle = item.category.isNotEmpty 
          ? _formatCategory(item.category.first) 
          : 'Outros';
      groupedItems.putIfAbsent(categoryTitle, () => []).add(item);
    }

    final screenWidth = MediaQuery.of(context).size.width;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 250, // Reduced height to avoid AppBar clashing on smaller screens
          maxWidth: screenWidth - 32, // Professional margin from edges
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: groupedItems.keys.length,
            itemBuilder: (context, sectionIndex) {
              final header = groupedItems.keys.elementAt(sectionIndex);
              final sectionItems = groupedItems[header]!;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 6),
                    child: Text(
                      header.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  ...sectionItems.map((item) => InkWell(
                    onTap: () => onSelect(item),
                    hoverColor: colorScheme.primaryContainer.withValues(alpha: 0.1),
                    splashColor: colorScheme.primaryContainer.withValues(alpha: 0.2),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Logo(
                            logoId: item.logoId,
                            size: 18,
                            onErrorIcon: Icon(
                              Icons.extension_rounded, 
                              size: 18, 
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
