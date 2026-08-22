import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/router.dart';
import '../l10n/app_localizations.dart';

class ManageSubscriptionScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const ManageSubscriptionScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  State<ManageSubscriptionScreen> createState() =>
      _ManageSubscriptionScreenState();
}

class _ManageSubscriptionScreenState extends State<ManageSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    final tier = auth.subscriptionTier ?? 'free';
    Color tierColor;
    String tierName;
    String tierBenefits;

    switch (tier) {
      case 'max':
        tierColor = const Color(0xFF0D47A1);
        tierName = 'MAX';
        tierBenefits = '25.000 créditos/mês • Todos os modelos • API access';
        break;
      case 'pro':
        tierColor = theme.colorScheme.primary;
        tierName = 'PRO';
        tierBenefits = '7.500 créditos/mês • Anexos • Multi-step';
        break;
      case 'basic':
        tierColor = Colors.grey;
        tierName = 'BASIC';
        tierBenefits = '500 créditos/mês • Gemini Flash';
        break;
      default:
        tierColor = Colors.grey;
        tierName = l10n.systemLanguage; // "Gratuito" ou similar se disponível
        tierBenefits = '500 créditos/mês • Gemini Flash';
    }

    final content = ListView(
      shrinkWrap: widget.isEmbedded,
      physics: widget.isEmbedded ? const NeverScrollableScrollPhysics() : null,
      padding: EdgeInsets.symmetric(
        horizontal: widget.isEmbedded ? 0 : 20,
        vertical: widget.isEmbedded ? 0 : 24,
      ),
      children: [
        if (widget.isEmbedded && widget.onBack != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  iconSize: 20,
                ),
                Text(
                  l10n.settingsManageSub,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        // Banner do Plano Atual
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                tierColor.withValues(alpha: 0.15),
                tierColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: tierColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tierColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.workspace_premium_rounded,
                      color: tierColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.pageTitlePricing.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: tierColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Plano $tierName',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                tierBenefits.replaceAll(' • ', '\n• '),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    if (widget.isEmbedded) {
                      context.go(AppRoutes.pricing);
                    } else {
                      Navigator.of(context).pop();
                      context.go(AppRoutes.pricing);
                    }
                  },
                  icon: const Icon(Icons.upgrade_rounded, size: 20),
                  label: Text(l10n.upgrade),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: tierColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settingsManageSub,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(child: content),
    );
  }
}
