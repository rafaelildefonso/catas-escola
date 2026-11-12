import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/web_page_renderer.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catas/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _loadingMessage;
  bool _isSignUpMode = false;
  bool _aceitouTermos = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _desktopBreakpoint = 900.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _navigateToPage(String path) {
    if (kIsWeb) navigateTo(path);
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
      context.go('/app');
    } else if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.loginEmailFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _signUpWithEmail() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (!_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Para criar sua conta, leia e aceite o Termo de Uso e o Termo de Consentimento.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
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
      context.go('/app');
    } else if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _loadingMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.signUpFailed),
          behavior: SnackBarBehavior.floating,
        ),
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
            return ColoredBox(
              color: isDarkMode
                  ? const Color(0xFF09090B)
                  : const Color(0xFFF7F7F8),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: isDesktop
                      ? _buildDesktopCard(colorScheme, l10n, isDarkMode)
                      : _buildMobileCard(colorScheme, l10n, isDarkMode),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── DESKTOP CARD (login + carousel lado a lado) ────────

  Widget _buildDesktopCard(
    ColorScheme colorScheme,
    AppLocalizations l10n,
    bool isDarkMode,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111113) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.18 : 0.06),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
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
            flex: 7,
            child: _buildProductPreview(colorScheme, isDarkMode),
          ),
        ],
      ),
    );
  }

  // ─── MOBILE CARD ────────────────────────────────────────

  Widget _buildMobileCard(
    ColorScheme colorScheme,
    AppLocalizations l10n,
    bool isDarkMode,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF111113) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: _buildLoginContent(colorScheme, l10n, isDarkMode),
    );
  }

  // ─── SHARED LOGIN CONTENT ─────────────────────────────────

  Widget _buildLoginContent(
    ColorScheme colorScheme,
    AppLocalizations l10n,
    bool isDarkMode,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              isDarkMode
                  ? 'assets/icons/app_icon_transparent_white.png'
                  : 'assets/icons/app_icon_transparent.png',
              width: 42,
              height: 42,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'CATAS',
              style: GoogleFonts.inter(
                fontSize: 20,
                letterSpacing: -0.4,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          _isSignUpMode ? 'Crie sua conta' : 'Bem-vindo de volta',
          style: GoogleFonts.inter(
            fontSize: 27,
            height: 1.15,
            letterSpacing: -0.7,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isSignUpMode
              ? 'Comece a transformar pedidos em automações reais.'
              : 'Entre para continuar suas conversas e automações.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.5,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),

        _buildEmailForm(colorScheme, l10n),

        const SizedBox(height: 24),
        _buildTermsConsent(colorScheme, l10n),
      ],
    );
  }

  // ─── EMAIL FORM ───────────────────────────────────────────

  Widget _buildEmailForm(ColorScheme colorScheme, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
            decoration: InputDecoration(
              hintText: l10n.emailHint,
              labelText: l10n.email,
              prefixIcon: Icon(
                Icons.email_outlined,
                color: colorScheme.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.7,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
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
            obscureText: _obscurePassword,
            autofillHints: _isSignUpMode
                ? const [AutofillHints.newPassword]
                : const [AutofillHints.password],
            textInputAction: _isSignUpMode
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (_isSignUpMode) {
                FocusScope.of(context).nextFocus();
              } else {
                _loginWithEmail();
              }
            },
            decoration: InputDecoration(
              hintText: l10n.passwordHint,
              labelText: l10n.password,
              prefixIcon: Icon(Icons.lock_outlined, color: colorScheme.primary),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.7,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: GoogleFonts.inter(fontSize: 15),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Digite sua senha';
              }
              if (value.length < 8) {
                return 'Mínimo 8 caracteres';
              }
              if (!RegExp(r'[a-z]').hasMatch(value)) {
                return 'Precisa de uma letra minúscula';
              }
              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                return 'Precisa de uma letra maiúscula';
              }
              if (!RegExp(r'[0-9]').hasMatch(value)) {
                return 'Precisa de um dígito';
              }
              if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
                return 'Precisa de um caractere especial';
              }
              return null;
            },
          ),
          if (_isSignUpMode) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              obscureText: _obscureConfirmPassword,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signUpWithEmail(),
              decoration: InputDecoration(
                hintText: 'Repita a senha',
                labelText: 'Confirmar senha',
                prefixIcon: Icon(
                  Icons.lock_outlined,
                  color: colorScheme.primary,
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  tooltip: _obscureConfirmPassword
                      ? 'Mostrar senha'
                      : 'Ocultar senha',
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.7,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: GoogleFonts.inter(fontSize: 15),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme sua senha';
                }
                if (value != _passwordController.text) {
                  return 'Senhas não conferem';
                }
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
                    onPressed: _isSignUpMode
                        ? _signUpWithEmail
                        : _loginWithEmail,
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
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.primary,
                ),
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
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  // ─── LOADING ──────────────────────────────────────────────

  Widget _buildLoadingIndicator(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(strokeWidth: 3, color: colorScheme.primary),
        if (_loadingMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _loadingMessage!,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  // ─── TERMS CONSENT ────────────────────────────────────────

  Widget _buildTermsConsent(ColorScheme colorScheme, AppLocalizations l10n) {
    if (!_isSignUpMode) {
      // Modo login: apenas informativo
      return Center(child: _buildTermsText(colorScheme, l10n));
    }

    // Modo cadastro: consentimento explícito obrigatório (LGPD)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: _aceitouTermos,
            onChanged: (value) =>
                setState(() => _aceitouTermos = value ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: 'Declaro que li e aceito o '),
                    TextSpan(
                      text: l10n.termsOfService,
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _navigateToPage('/terms'),
                    ),
                    const TextSpan(text: ' e o '),
                    TextSpan(
                      text: 'Termo de Consentimento (LGPD)',
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _navigateToPage('/consent'),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
            style: TextStyle(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _navigateToPage('/terms'),
          ),
          TextSpan(text: l10n.andLabel),
          TextSpan(
            text: l10n.privacyPolicy,
            style: TextStyle(
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _navigateToPage('/privacy'),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildProductPreview(ColorScheme colorScheme, bool isDarkMode) {
    final surface = isDarkMode ? const Color(0xFF17171A) : Colors.white;
    return Semantics(
      label: 'Exemplo de automação executada pelo CATAS',
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0D0D0F) : const Color(0xFFF7F7F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ASSISTENTE DE AUTOMAÇÕES',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  letterSpacing: 0.7,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Do pedido à execução,\nsem trocar de aplicativo.',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      height: 1.15,
                      letterSpacing: -0.8,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Converse com o CATAS, revise o plano e acompanhe cada etapa em tempo real.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 390),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF242428)
                      : const Color(0xFFEDEEF0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Organize os contatos da planilha e envie um resumo por e-mail.',
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Automação concluída',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '3 etapas',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _previewStep(
                    colorScheme,
                    Icons.table_chart_outlined,
                    'Planilha lida',
                    '42 contatos',
                  ),
                  _previewStep(
                    colorScheme,
                    Icons.auto_awesome_outlined,
                    'Dados organizados',
                    'Concluído',
                  ),
                  _previewStep(
                    colorScheme,
                    Icons.mail_outline_rounded,
                    'Resumo enviado',
                    'Gmail',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: const [
                _TrustItem(
                  icon: Icons.lock_outline_rounded,
                  label: 'Dados protegidos',
                ),
                _TrustItem(
                  icon: Icons.visibility_outlined,
                  label: 'Ações revisáveis',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewStep(
    ColorScheme colorScheme,
    IconData icon,
    String label,
    String detail,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: Color(0xFF22C55E),
          ),
          const SizedBox(width: 6),
          Text(
            detail,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
