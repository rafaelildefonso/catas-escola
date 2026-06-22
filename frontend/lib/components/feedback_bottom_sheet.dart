import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catas/l10n/app_localizations.dart';

enum FeedbackReason {
  // Positive
  automationWorked,
  clearAnswer,
  usefulInfo,
  resolvedDoubt,
  fastResponse,
  // Negative
  automationFailed,
  confusing,
  incorrectInfo,
  incomplete,
  notAnswered,
}

class FeedbackBottomSheet extends StatefulWidget {
  final bool isPositive;
  final Function(FeedbackReason) onReasonSelected;
  final VoidCallback onSkip;

  const FeedbackBottomSheet({
    super.key,
    required this.isPositive,
    required this.onReasonSelected,
    required this.onSkip,
  });

  static Future<void> show({
    required BuildContext context,
    required bool isPositive,
    required Function(FeedbackReason) onReasonSelected,
    required VoidCallback onSkip,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FeedbackBottomSheet(
        isPositive: isPositive,
        onReasonSelected: onReasonSelected,
        onSkip: onSkip,
      ),
    );
  }

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final reasons = widget.isPositive ? _positiveReasons : _negativeReasons;
    final title = widget.isPositive ? l10n.feedbackTitle : l10n.feedbackTitleBad;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ...reasons.map((reason) => _buildReasonTile(
                    context,
                    reason,
                    _getReasonLabel(l10n, reason),
                  )),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      widget.onSkip();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      l10n.feedbackSkip,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  List<FeedbackReason> get _positiveReasons => [
    FeedbackReason.automationWorked,
    FeedbackReason.clearAnswer,
    FeedbackReason.usefulInfo,
    FeedbackReason.resolvedDoubt,
    FeedbackReason.fastResponse,
  ];

  List<FeedbackReason> get _negativeReasons => [
    FeedbackReason.automationFailed,
    FeedbackReason.confusing,
    FeedbackReason.incorrectInfo,
    FeedbackReason.incomplete,
    FeedbackReason.notAnswered,
  ];

  String _getReasonLabel(AppLocalizations l10n, FeedbackReason reason) {
    switch (reason) {
      case FeedbackReason.automationWorked:
        return l10n.feedbackAutomationWorked;
      case FeedbackReason.clearAnswer:
        return l10n.feedbackClearAnswer;
      case FeedbackReason.usefulInfo:
        return l10n.feedbackUsefulInfo;
      case FeedbackReason.resolvedDoubt:
        return l10n.feedbackResolvedDoubt;
      case FeedbackReason.fastResponse:
        return l10n.feedbackFastResponse;
      case FeedbackReason.automationFailed:
        return l10n.feedbackAutomationFailed;
      case FeedbackReason.confusing:
        return l10n.feedbackConfusing;
      case FeedbackReason.incorrectInfo:
        return l10n.feedbackIncorrectInfo;
      case FeedbackReason.incomplete:
        return l10n.feedbackIncomplete;
      case FeedbackReason.notAnswered:
        return l10n.feedbackNotAnswered;
    }
  }

  Widget _buildReasonTile(BuildContext context, FeedbackReason reason, String label) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            widget.onReasonSelected(reason);
            Navigator.of(context).pop();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  widget.isPositive ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 20,
                  color: widget.isPositive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String feedbackReasonToString(FeedbackReason reason) {
  return reason.name;
}

FeedbackReason? stringToFeedbackReason(String? value) {
  if (value == null) return null;
  try {
    return FeedbackReason.values.firstWhere((r) => r.name == value);
  } catch (_) {
    return null;
  }
}