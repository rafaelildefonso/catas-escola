import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/billing_repository.dart';
import '../providers/auth_provider.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen>
    with WidgetsBindingObserver {
  final BillingRepository _billingRepository = BillingRepository();
  String? _processingTier;
  bool _openingPortal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<AuthProvider>().refreshAccount());
    }
  }

  Future<void> _handlePlanSelection(String planTier) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      _showMessage('Entre na sua conta para assinar um plano.');
      return;
    }
    setState(() => _processingTier = planTier);
    try {
      final url = auth.profile?.hasBillingSubscription == true
          ? await _billingRepository.createPortal()
          : await _billingRepository.createCheckout(planTier);
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched)
        throw Exception('Não foi possível abrir a página de pagamento.');
    } catch (erro) {
      if (mounted)
        _showMessage(erro.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _processingTier = null);
    }
  }

  Future<void> _openBillingPortal() async {
    setState(() => _openingPortal = true);
    try {
      final url = await _billingRepository.createPortal();
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!launched)
        throw Exception('Não foi possível abrir o portal de cobrança.');
    } catch (erro) {
      if (mounted)
        _showMessage(erro.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _openingPortal = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final currentTier = auth.subscriptionTier ?? 'free';
    final hasBillingAccount = auth.profile?.hasBillingAccount ?? false;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Escolha o seu plano",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Desbloqueie o poder total da automação inteligente",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 48),

                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1100) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildBasicCard(context, currentTier),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildProCard(
                                context,
                                colorScheme,
                                currentTier,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildMaxCard(
                                context,
                                theme,
                                colorScheme,
                                currentTier,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (constraints.maxWidth >= 720) {
                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          SizedBox(
                            width: (constraints.maxWidth - 20) / 2,
                            child: _buildBasicCard(context, currentTier),
                          ),
                          SizedBox(
                            width: (constraints.maxWidth - 20) / 2,
                            child: _buildProCard(
                              context,
                              colorScheme,
                              currentTier,
                            ),
                          ),
                          SizedBox(
                            width: (constraints.maxWidth - 20) / 2,
                            child: _buildMaxCard(
                              context,
                              theme,
                              colorScheme,
                              currentTier,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildBasicCard(
                          context,
                          currentTier,
                          fullFeatures: true,
                        ),
                        const SizedBox(height: 20),
                        _buildProCard(
                          context,
                          colorScheme,
                          currentTier,
                          fullFeatures: true,
                        ),
                        const SizedBox(height: 20),
                        _buildMaxCard(
                          context,
                          theme,
                          colorScheme,
                          currentTier,
                          fullFeatures: true,
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 48),

                if (hasBillingAccount) ...[
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton.icon(
                      onPressed: _openingPortal || _processingTier != null
                          ? null
                          : _openBillingPortal,
                      icon: _openingPortal
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.manage_accounts_outlined),
                      label: const Text('Gerenciar assinatura'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  "Todos os planos incluem suporte via email e renovação automática mensal.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicCard(
    BuildContext context,
    String currentTier, {
    bool fullFeatures = false,
  }) {
    return _buildPlanCard(
      context,
      name: "BASIC",
      planTier: "basic",
      price: "R\$ 39,90",
      tasks: "500 créditos/mês",
      model: "Gemini 3 Flash",
      color: Colors.grey,
      features: fullFeatures
          ? [
              "Chatbot NLU Inteligente",
              "Integração Google e Notion",
              "Suporte a anexos",
              "Resumos de textos e links",
              "Histórico de 30 dias",
            ]
          : [
              "Chatbot NLU",
              "Google/Notion",
              "5 anexos/mês",
              "Resumos",
              "30 dias",
            ],
      isCurrent: currentTier == 'basic',
      currentTier: currentTier,
    );
  }

  Widget _buildProCard(
    BuildContext context,
    ColorScheme colorScheme,
    String currentTier, {
    bool fullFeatures = false,
  }) {
    return _buildPlanCard(
      context,
      name: "PRO",
      planTier: "pro",
      price: "R\$ 99,90",
      tasks: "7.500 créditos/mês",
      model: "Gemini 3 Pro",
      color: colorScheme.primary,
      features: fullFeatures
          ? [
              "Tudo que é gratuito",
              "Automações multi-step",
              "Anexos Ilimitados",
              "Integração WhatsApp e Slack",
              "Histórico Ilimitado",
              "IA personalizada pelo histórico",
            ]
          : [
              "Tudo do Basic",
              "Multi-step",
              "Anexos Ilimit.",
              "WhatsApp/Slack",
              "Ilimitado",
              "Personalizado",
            ],
      isHighlighted: true,
      isCurrent: currentTier == 'pro',
      currentTier: currentTier,
    );
  }

  Widget _buildMaxCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String currentTier, {
    bool fullFeatures = false,
  }) {
    return _buildPlanCard(
      context,
      name: "MAX",
      planTier: "max",
      price: "R\$ 249,90",
      tasks: "25.000 créditos/mês",
      model: "Gemini 3 Pro High / Claude",
      color: theme.brightness == Brightness.dark
          ? Colors.blue[400]!
          : const Color(0xFF0D47A1),
      features: fullFeatures
          ? [
              "Tudo do plano Pro",
              "Fluxos customizados n8n",
              "Acesso à API do CATAS",
              "Agentes Compartilhados",
              "Tokens extendidos",
              "Suporte prioritário",
            ]
          : [
              "Tudo do Pro",
              "Custom n8n",
              "API Access",
              "Compartilhados",
              "Tokens ext.",
              "Prioritário",
            ],
      isCurrent: currentTier == 'max',
      currentTier: currentTier,
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String name,
    required String planTier,
    required String price,
    required String tasks,
    required String model,
    required Color color,
    required List<String> features,
    bool isHighlighted = false,
    bool isCurrent = false,
    required String currentTier,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isHighlighted
              ? color
              : colorScheme.outline.withValues(alpha: 0.1),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isHighlighted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(21),
                ),
              ),
              child: Text(
                "MAIS POPULAR",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "ATUAL",
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        price,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        "/mês",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(context, tasks, Icons.task_alt, color),
                _buildFeatureItem(
                  context,
                  model,
                  Icons.psychology_outlined,
                  color,
                ),
                const Divider(height: 32),
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        isCurrent || _processingTier != null || _openingPortal
                        ? null
                        : () => _handlePlanSelection(planTier),
                    style: FilledButton.styleFrom(
                      backgroundColor: isHighlighted
                          ? color
                          : (theme.brightness == Brightness.dark
                                ? colorScheme.surfaceContainerHigh
                                : colorScheme.onSurface),
                      foregroundColor: isHighlighted
                          ? Colors.white
                          : (theme.brightness == Brightness.light
                                ? Colors.white
                                : colorScheme.onSurface),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _processingTier == planTier
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isCurrent
                                ? "Plano Atual"
                                : (_getTierRank(currentTier) >
                                          _getTierRank(planTier)
                                      ? "Abaixar Plano"
                                      : "Começar Agora"),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  int _getTierRank(String tier) {
    switch (tier.toLowerCase()) {
      case 'max':
        return 2;
      case 'pro':
        return 1;
      case 'free':
      default:
        return 0;
    }
  }
}
