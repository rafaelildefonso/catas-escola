import 'package:catas/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  final String planName;

  const SubscriptionSuccessScreen({super.key, required this.planName});

  @override
  State<SubscriptionSuccessScreen> createState() =>
      _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getPlanEmoji() {
    switch (widget.planName.toLowerCase()) {
      case 'free':
        return '🚀';
      case 'pro':
        return '⚡';
      case 'max':
        return '👑';
      default:
        return '🎉';
    }
  }

  String _getPlanMessage() {
    switch (widget.planName.toLowerCase()) {
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
    switch (widget.planName.toLowerCase()) {
      case 'free':
        return 'Que tal desbloquear mais recursos? Considere o PRO para automações avançadas!';
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
    final planEmoji = _getPlanEmoji();

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
                      repeat: true, // Let it sparkle!
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
                              color: (Theme.of(context).brightness == Brightness.dark ? Colors.green[900]! : Colors.green[100]!).withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_circle,
                              size: 80,
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.green[400] : Colors.green,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                      // Emoji do plano
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: const Interval(0.3, 0.8, curve: Curves.elasticOut),
                          ),
                        ),
                        child: Text(planEmoji, style: const TextStyle(fontSize: 64)),
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
                              'Plano ${widget.planName.toUpperCase()} Ativado',
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
                                _getPlanMessage(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withValues(
                                    alpha: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
                            onPressed: () {
                              // First update the navigation state so MainLayout knows to show Chat
                              context.read<NavigationProvider>().setPage(
                                AppPage.chat,
                              );
      
                              // Pop everything until the first route (which is the AuthWrapper/MainLayout)
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
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
