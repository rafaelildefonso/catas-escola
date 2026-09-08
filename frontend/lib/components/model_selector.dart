import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';

class ModelSelectorWidget extends StatelessWidget {
  final double horizontalPadding;
  final double iconSpacing;
  final void Function(BuildContext context, String model) onUpgradeRequired;

  const ModelSelectorWidget({
    super.key,
    this.horizontalPadding = 12,
    this.iconSpacing = 4,
    required this.onUpgradeRequired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final tier = auth.subscriptionTier ?? 'free';

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, _) => PopupMenuButton<String>(
        offset: const Offset(0, 5),
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.12),
          ),
        ),
        color: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        onSelected: (model) {
          if (isModelAllowed(model, tier)) {
            chatProvider.setSelectedModel(model);
          } else {
            onUpgradeRequired(context, model);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 6),
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
              Text(
                chatProvider.selectedModel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(width: iconSpacing),
              Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
        itemBuilder: (context) => chatProvider.availableModels.map((model) {
          final isSelected = chatProvider.selectedModel == model;
          final isAllowed = isModelAllowed(model, tier);
          final requiredTier = getRequiredTier(model);

          return PopupMenuItem<String>(
            value: model,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            model,
                            style: GoogleFonts.inter(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isAllowed
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          buildTierBadge(requiredTier, theme),
                        ],
                      ),
                      Text(
                        chatProvider.modelsInfo[model] ?? "",
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: isAllowed ? 1.0 : 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  )
                else if (!isAllowed)
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

bool isModelAllowed(String model, String userTier) {
  if (userTier == 'max') return true;
  if (userTier == 'pro') return model != "CATAS MAX";
  return model == "CATAS Basic";
}

String getRequiredTier(String model) {
  if (model == "CATAS MAX") return "max";
  if (model == "CATAS Pro") return "pro";
  return "free";
}

Widget buildTierBadge(String tier, ThemeData theme) {
  Color color;
  switch (tier) {
    case 'max':
      color = theme.brightness == Brightness.dark
          ? Colors.blue[400]!
          : const Color(0xFF0D47A1);
      break;
    case 'pro':
      color = theme.colorScheme.primary;
      break;
    default:
      color = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
    ),
    child: Text(
      tier.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 8,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );
}
