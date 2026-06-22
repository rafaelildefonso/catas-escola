import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../data/suggested_prompts.dart';
import '../components/brand_logo.dart';

class SuggestedPromptsScreen extends StatefulWidget {
  const SuggestedPromptsScreen({super.key});

  @override
  State<SuggestedPromptsScreen> createState() => _SuggestedPromptsScreenState();
}

class _SuggestedPromptsScreenState extends State<SuggestedPromptsScreen> {
  String _selectedCategory = 'Todos';

  List<SuggestedPrompt> get _filteredPrompts {
    if (_selectedCategory == 'Todos') {
      return SuggestedPromptsData.prompts;
    }
    return SuggestedPromptsData.prompts
        .where((p) => p.category == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Biblioteca de Prompts",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: kIsWeb
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: SuggestedPromptsData.categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    selectedColor: colorScheme.primary,
                    checkmarkColor: colorScheme.onPrimary,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const Divider(height: 1),
          
          // Grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount = 1;
                if (width > 1200) crossAxisCount = 4;
                else if (width > 800) crossAxisCount = 3;
                else if (width > 600) crossAxisCount = 2;

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _filteredPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = _filteredPrompts[index];
                    return _buildPromptCard(context, prompt);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(BuildContext context, SuggestedPrompt prompt) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        // Return the prompt text to the previous screen (ChatScreen)
        context.pop(prompt.prompt);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                prompt.category,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Text(
                prompt.prompt,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: colorScheme.onSurface,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: prompt.logos.map((logoId) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Logo(
                  logoId: logoId,
                  size: 20,
                  onErrorIcon: const Icon(Icons.auto_awesome, size: 16),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
