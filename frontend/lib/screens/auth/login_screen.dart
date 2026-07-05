import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catas/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _showEmailForm = false;
  String? _loadingMessage;
  bool _isSignUpMode = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _pageController = PageController();
  Timer? _carouselTimer;
  int _currentSlide = 0;

  static const _desktopBreakpoint = 900.0;

  @override
  void initState() {
    super.initState();
    _startCarousel();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentSlide + 1) % 4;
      _currentSlide = next;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _navigateToPage(String path) {
    if (kIsWeb) html.window.location.href = path;
  }

  void _loginWithEmail() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.signingIn;
    });
    if (!mounted) return;
    final success = await context.read<AuthProvider>().loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      context.read<NavigationProvider>().reset();
    } else if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginEmailFailed), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _sendMagicLink() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.emailHint), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.signingIn;
    });
    if (!mounted) return;
    final ok = await context.read<AuthProvider>().signInWithMagicLink(email);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _loadingMessage = null;
    });
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.magicLinkSent), behavior: SnackBarBehavior.floating),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.magicLinkFailed), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _signUpWithEmail() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _loadingMessage = l10n.signingUp;
    });
    if (!mounted) return;
    final success = await context.read<AuthProvider>().signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (success && mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signUpSuccess), behavior: SnackBarBehavior.floating),
      );
    } else if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.signUpFailed), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = colorScheme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
            final gradient = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.primary.withValues(alpha: 0.4),
                colorScheme.secondary.withValues(alpha: 0.05),
              ],
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: Container(decoration: BoxDecoration(gradient: gradient)),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: isDesktop
                        ? _buildDesktopCard(colorScheme, l10n, isDarkMode)
                        : _buildMobileCard(colorScheme, l10n, isDarkMode),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── DESKTOP CARD (login + carousel lado a lado) ────────

  Widget _buildDesktopCard(ColorScheme colorScheme, AppLocalizations l10n, bool isDarkMode) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: _buildLoginContent(colorScheme, l10n, isDarkMode),
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            flex: 8,
            child: _buildImageCarousel(colorScheme),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE CARD ────────────────────────────────────────

  Widget _buildMobileCard(ColorScheme colorScheme, AppLocalizations l10n, bool isDarkMode) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.05)),
      ),
      child: _buildLoginContent(colorScheme, l10n, isDarkMode),
    );
  }

  // ─── SHARED LOGIN CONTENT ─────────────────────────────────

  Widget _buildLoginContent(ColorScheme colorScheme, AppLocalizations l10n, bool isDarkMode) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_showEmailForm) ...[
          Center(
            child: SizedBox(
              child: Image.asset(
                isDarkMode
                    ? 'assets/icons/app_icon_transparent_white.png'
                    : 'assets/icons/app_icon_transparent.png',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l10n.loginSubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              l10n.loginSubtitleExecution,
              style: GoogleFonts.outfit(
                fontSize: 20,
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _showEmailForm
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEmailLink(colorScheme, l10n),
            ],
          ),
          secondChild: _buildEmailForm(colorScheme, l10n),
        ),

        const SizedBox(height: 24),
        Center(
          child: _buildTermsText(colorScheme, l10n),
        ),
      ],
    );
  }

  // ─── EMAIL LINK ─────────────────────────────────────────

  Widget _buildEmailLink(ColorScheme colorScheme, AppLocalizations l10n) {
    return Center(
      child: TextButton(
        onPressed: _isLoading ? null : () => setState(() => _showEmailForm = true),
        child: Text(
          l10n.loginWithEmail,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ─── EMAIL FORM ───────────────────────────────────────────

  Widget _buildEmailForm(ColorScheme colorScheme, AppLocalizations l10n) {
    return Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 20),
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _showEmailForm = false;
                            _isSignUpMode = false;
                            _emailController.clear();
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.backToLogin,
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              enabled: !_isLoading,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: l10n.emailHint,
                labelText: l10n.email,
                prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.inter(fontSize: 15),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Digite seu email';
                if (!value.contains('@')) return 'Email inválido';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: true,
              decoration: InputDecoration(
                hintText: l10n.passwordHint,
                labelText: l10n.password,
                prefixIcon: Icon(Icons.lock_outlined, color: colorScheme.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              style: GoogleFonts.inter(fontSize: 15),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Digite sua senha';
                if (value.length < 8) return 'Mínimo 8 caracteres';
                if (!RegExp(r'[a-z]').hasMatch(value)) return 'Precisa de uma letra minúscula';
                if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Precisa de uma letra maiúscula';
                if (!RegExp(r'[0-9]').hasMatch(value)) return 'Precisa de um dígito';
                if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) return 'Precisa de um caractere especial';
                return null;
              },
            ),
            if (_isSignUpMode) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Repita a senha',
                  labelText: 'Confirmar senha',
                  prefixIcon: Icon(Icons.lock_outlined, color: colorScheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                style: GoogleFonts.inter(fontSize: 15),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Confirme sua senha';
                  if (value != _passwordController.text) return 'Senhas não conferem';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? _buildLoadingIndicator(colorScheme, l10n)
                  : _buildGradientButton(
                      onPressed: _isSignUpMode ? _signUpWithEmail : _loginWithEmail,
                      label: _isSignUpMode ? l10n.signUp : l10n.signIn,
                      colorScheme: colorScheme,
                    ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _isSignUpMode = !_isSignUpMode),
                child: Text(
                  _isSignUpMode ? l10n.alreadyHaveAccount : l10n.dontHaveAccount,
                  style: GoogleFonts.inter(fontSize: 13, color: colorScheme.primary),
                ),
              ),
            ),
            if (!_isSignUpMode)
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _sendMagicLink,
                  child: Text(
                    l10n.magicLinkButton,
                    style: GoogleFonts.inter(fontSize: 13, color: colorScheme.primary),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  // ─── GRADIENT BUTTON ──────────────────────────────────────

  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.85)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── LOADING ──────────────────────────────────────────────

  Widget _buildLoadingIndicator(ColorScheme colorScheme, AppLocalizations l10n) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary),
        if (_loadingMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _loadingMessage!,
            style: GoogleFonts.inter(fontSize: 13, color: colorScheme.onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ],
    );
  }

  // ─── TERMS TEXT ───────────────────────────────────────────

  Widget _buildTermsText(ColorScheme colorScheme, AppLocalizations l10n) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 12,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
          height: 1.5,
        ),
        children: [
          TextSpan(text: l10n.termsAgreementPrefix),
          TextSpan(
            text: l10n.termsOfService,
            style: TextStyle(color: colorScheme.primary, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _navigateToPage('/terms'),
          ),
          TextSpan(text: l10n.andLabel),
          TextSpan(
            text: l10n.privacyPolicy,
            style: TextStyle(color: colorScheme.primary, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _navigateToPage('/privacy'),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  // ─── IMAGE CAROUSEL ───────────────────────────────────────

  Widget _buildImageCarousel(ColorScheme colorScheme) {
    final slides = [
      _ImageSlide(
        gradientColors: [
          colorScheme.primary.withValues(alpha: 0.25),
          colorScheme.primaryContainer.withValues(alpha: 0.4),
          colorScheme.surface,
        ],
        title: 'Descreva em linguagem natural',
        description: 'Explique o que você quer automatizar como se estivesse falando com um assistente.',
      ),
      _ImageSlide(
        gradientColors: [
          colorScheme.secondary.withValues(alpha: 0.25),
          colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          colorScheme.surface,
        ],
        title: 'IA processa e cria fluxos',
        description: 'O motor de IA interpreta sua intenção e monta a lógica automaticamente.',
      ),
      _ImageSlide(
        gradientColors: [
          Colors.amber.withValues(alpha: 0.2),
          Colors.orange.withValues(alpha: 0.15),
          colorScheme.surface,
        ],
        title: 'Automações prontas em segundos',
        description: 'Seu fluxo de trabalho é criado e ativado instantaneamente.',
      ),
      _ImageSlide(
        gradientColors: [
          Colors.green.withValues(alpha: 0.2),
          Colors.teal.withValues(alpha: 0.15),
          colorScheme.surface,
        ],
        title: 'Monitore resultados em tempo real',
        description: 'Acompanhe métricas e ajuste fluxos com comandos simples.',
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentSlide = index),
              itemCount: slides.length,
              itemBuilder: (context, index) {
                final slide = slides[index];
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: slide.gradientColors,
                    ),
                    border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 80,
                          color: colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slide.title,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              slide.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: _currentSlide == i ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentSlide == i
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ImageSlide {
  final List<Color> gradientColors;
  final String title;
  final String description;

  const _ImageSlide({
    required this.gradientColors,
    required this.title,
    required this.description,
  });
}
