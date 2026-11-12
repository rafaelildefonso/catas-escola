import 'dart:async';

import 'package:catas/data/billing_repository.dart';
import 'package:catas/providers/navigation_provider.dart';
import 'package:catas/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/design_tokens.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  final String? sessionId;

  const SubscriptionSuccessScreen({super.key, this.sessionId});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final BillingRepository _billingRepository = BillingRepository();
  String _planName = 'basic';
  bool _isConfirming = true;
  String? _confirmationError;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.forward();
    unawaited(_confirmPayment());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _confirmPayment() async {
    final auth = context.read<AuthProvider>();
    final sessionId = widget.sessionId;

    if (!await _waitForAuthenticatedSession(auth)) {
      if (!mounted) return;
      setState(() {
        _confirmationError = 'Entre novamente para confirmar o pagamento.';
        _isConfirming = false;
      });
      return;
    }

    if (sessionId == null || sessionId.isEmpty) {
      await auth.refreshProfile();
      if (!mounted) return;
      setState(() {
        _planName = auth.subscriptionTier ?? 'basic';
        _isConfirming = false;
      });
      return;
    }

    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        final billing = await _billingRepository.confirmCheckout(sessionId);
        await auth.refreshProfile();
        if (!mounted) return;
        setState(() {
          _planName = (billing['subscription_tier'] as String?) ?? 'basic';
          _isConfirming = false;
        });
        return;
      } on BillingConfirmationException catch (error) {
        if (error.statusCode != 409 || attempt == 7) {
          if (!mounted) return;
          setState(() {
            _confirmationError = error.message;
            _isConfirming = false;
          });
          return;
        }
        await Future<void>.delayed(const Duration(milliseconds: 800));
      } catch (error) {
        debugPrint('Falha ao confirmar checkout Stripe: $error');
        if (!mounted) return;
        setState(() {
          _confirmationError = 'Não foi possível confirmar seu plano agora.';
          _isConfirming = false;
        });
        return;
      }
    }
  }

  Future<bool> _waitForAuthenticatedSession(AuthProvider auth) async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (auth.isAuthenticated && !auth.isLoading) return true;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  IconData _getPlanIcon() {
    switch (_planName.toLowerCase()) {
      case 'free':
        return Icons.rocket_launch_rounded;
      case 'pro':
        return Icons.bolt_rounded;
      case 'max':
        return Icons.workspace_premium_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  String _getPlanMessage() {
    switch (_planName.toLowerCase()) {
      case 'free':
      case 'basic':
        return 'Você agora tem 500 créditos por mês para automatizar suas ideias!';
      case 'pro':
        return 'Com 7.500 créditos por mês, você está pronto para turbinar sua produtividade!';
      case 'max':
        return '25.000 créditos por mês e acesso total! Você desbloqueou o poder máximo do CATAS!';
      default:
        return 'Seu plano foi ativado com sucesso!';
    }
  }

  String _getUpgradeHint() {
    switch (_planName.toLowerCase()) {
      case 'free':
        return 'Que tal desbloquear mais recursos? Considere o PRO para automações avançadas!';
      case 'basic':
        return 'Sua assinatura está ativa. Você pode gerenciar ou alterar o plano quando quiser.';
      case 'pro':
        return 'Precisa de ainda mais? O MAX oferece fluxos customizados e API dedicada!';
      case 'max':
        return 'Você está no topo! Aproveite todos os recursos exclusivos do CATAS!';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.catasTokens;
    final planIcon = _getPlanIcon();
    final title = _isConfirming
        ? 'Confirmando pagamento'
        : _confirmationError == null
        ? 'Plano ${_planName.toUpperCase()} Ativado'
        : 'Pagamento em confirmação';
    final message = _isConfirming
        ? 'Estamos confirmando sua assinatura com o Stripe. Isso pode levar alguns segundos.'
        : _confirmationError ?? _getPlanMessage();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.3),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // Animação de confetti
                  SizedBox(
                    height: 200,
                    child: Lottie.asset(
                      'assets/animations/success_confetti.json',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      repeat: false,
                      onWarning: (warning) {
                        // Ignora aviso se o asset não existir
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback: mostra um ícone animado se não tiver Lottie
                        return ScaleTransition(
                          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: tokens.success.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              size: 80,
                              color: tokens.success,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Ícone do plano
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(
                          0.3,
                          0.8,
                          curve: Curves.elasticOut,
                        ),
                      ),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                            width: 56,
                            height: 56,
                            child: CircularProgressIndicator(strokeWidth: 4),
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: tokens.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: tokens.success.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Icon(
                              planIcon,
                              color: tokens.success,
                              size: 34,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Título
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.4, 0.9),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Parabéns!',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Mensagem motivacional
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.5, 1.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (!_isConfirming && _confirmationError == null)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _getUpgradeHint(),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Botão de ação
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: const Interval(0.7, 1.0),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isConfirming
                            ? null
                            : () {
                                context.read<NavigationProvider>().setPage(
                                  AppPage.chat,
                                );
                                context.go('/app');
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Começar a Usar',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
