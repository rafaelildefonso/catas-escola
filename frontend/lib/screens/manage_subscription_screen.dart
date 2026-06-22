import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/payments_provider.dart';
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
  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _openStripePortal() async {
    final payments = context.read<PaymentsProvider>();

    try {
      final url = await payments.createBillingPortalSession();
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showSnack('Não foi possível abrir o portal de cobrança.', isError: true);
      }
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final payments = context.watch<PaymentsProvider>();
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

        // Gerenciamento Stripe
        Text(
          l10n.paymentMethod.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
          ),
          child: InkWell(
            onTap: payments.isLoading ? null : _openStripePortal,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payments_outlined,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.manageBillingStripe,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Assinaturas, cartões e faturas',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (payments.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.open_in_new,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        Text(
          'O CATAS utiliza o Stripe para processar pagamentos de forma segura. Nenhuma informação de cartão é armazenada em nossos servidores.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
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
