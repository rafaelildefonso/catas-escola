import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/automation_labels.dart';
import '../../providers/chat_provider.dart';
import '../brand_logo.dart';

class AutomationProgressComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;

  const AutomationProgressComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
  });

  static const Map<String, LogoId> _moduleLogoId = {
    'google_calendar.create_event': LogoId.googleCalendar,
    'google_drive.create_folder': LogoId.googleDrive,
    'google_sheets.append_row': LogoId.googleSheets,
    'google_sheets.create_spreadsheet': LogoId.googleSheets,
    'google_drive.upload_file': LogoId.googleDrive,
    'gmail.send_email': LogoId.googleGmail,
    'gmail.create_draft': LogoId.googleGmail,
    'http.request': LogoId.google,
    'ai.transform_data': LogoId.google,
    'flow.wait': LogoId.google,
    'flow.condition': LogoId.google,
  };

  @override
  Widget build(BuildContext context) {
    final automationId = data['automation_id'] as String?;

    return Consumer<ChatProvider>(
      builder: (context, chatProv, child) {
        final steps = chatProv.automationSteps;
        final phase = chatProv.automationPhase;
        final isCompleted = phase == 'completed';
        final isFailed = phase == 'failed' || phase == 'canceled';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF151518)
                : const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCompleted
                  ? const Color(0xFF22C55E).withValues(alpha: 0.28)
                  : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
                phase,
                isCompleted,
                isFailed,
                chatProv.automationError,
              ),
              const Divider(height: 1),
              if (steps.isEmpty)
                _buildLoading(context)
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: steps
                        .map((step) => _buildStepItem(context, step, phase))
                        .toList(),
                  ),
                ),
              if (isCompleted && automationId != null) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () =>
                          context.push('/app/automations/$automationId'),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: Text(
                        'Ver Detalhes',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String phase,
    bool isCompleted,
    bool isFailed,
    String? error,
  ) {
    final cs = Theme.of(context).colorScheme;

    String title;
    String subtitle;
    Widget icon;

    switch (phase) {
      case 'appearing':
        title = 'Preparando automação';
        subtitle = 'Identificando integrações...';
        icon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        );
        break;
      case 'descriptions':
        title = 'Mapeando ações';
        subtitle = 'Definindo o que cada integração fará';
        icon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        );
        break;
      case 'verifying':
        title = 'Verificando integrações';
        subtitle = 'Testando conexão com cada serviço';
        icon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        );
        break;
      case 'running':
        title = 'Executando automação';
        subtitle = 'Aguardando a resposta da integração.';
        icon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
          ),
        );
        break;
      case 'testingTrigger':
        title = 'Testando automação';
        subtitle = 'Ativando gatilho da automação...';
        icon = const _PulseIcon(
          child: Icon(
            Icons.electric_bolt_rounded,
            size: 18,
            color: Colors.amber,
          ),
        );
        break;
      case 'completed':
        title = 'Automação pronta!';
        subtitle = '3 integrações verificadas com sucesso';
        icon = Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: Colors.green),
        );
        break;
      case 'failed':
      case 'canceled':
        title = 'Não foi possível concluir';
        subtitle = error ?? 'A execução falhou. Tente novamente.';
        icon = Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: cs.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.close_rounded, size: 14, color: cs.error),
        );
        break;
      default:
        title = 'Iniciando...';
        subtitle = '';
        icon = SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        );
    }

    if (phase == 'completed') {
      subtitle = 'A execução terminou com sucesso.';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isCompleted
                        ? Colors.green
                        : isFailed
                        ? cs.error
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(
          'Iniciando processos...',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    Map<String, dynamic> step,
    String phase,
  ) {
    final moduleId = step['module_id'] ?? '';
    final status = step['status'] as String? ?? 'pending';
    final label =
        step['label'] as String? ?? friendlyAutomationStepName(moduleId);
    final description = step['description'] as String? ?? '';
    final logoId = _moduleLogoId[moduleId];
    final cs = Theme.of(context).colorScheme;
    final idx = step['step_index'] as int? ?? 0;

    Color iconColor;
    bool showSpinner = false;
    bool showCheck = false;

    switch (status) {
      case 'verifying':
      case 'running':
        iconColor = Colors.blue;
        showSpinner = true;
        break;
      case 'verified':
      case 'success':
        iconColor = Colors.green;
        showCheck = true;
        break;
      case 'error':
        iconColor = cs.error;
        break;
      default:
        iconColor = cs.onSurfaceVariant.withValues(alpha: 0.4);
    }

    final showDescription =
        phase == 'descriptions' ||
        phase == 'verifying' ||
        phase == 'testingTrigger' ||
        phase == 'completed';
    final animationsDisabled = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: animationsDisabled
          ? Duration.zero
          : Duration(milliseconds: 400 + idx * 80),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: RepaintBoundary(
        child: Padding(
          key: ValueKey('step-${step['step_index']}'),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Column(
                      children: [
                        if (idx > 0)
                          Container(
                            width: 1,
                            height: 8,
                            color: cs.outline.withValues(alpha: 0.24),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: showSpinner
                                ? Colors.blue.withValues(alpha: 0.1)
                                : showCheck
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.grey.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: logoId != null
                              ? Logo(
                                  logoId: logoId,
                                  size: 14,
                                  onErrorIcon: Icon(
                                    Icons.circle_rounded,
                                    size: 14,
                                    color: iconColor,
                                  ),
                                )
                              : Icon(
                                  Icons.circle_rounded,
                                  size: 14,
                                  color: iconColor,
                                ),
                        ),
                        if (idx >= 0)
                          Container(
                            width: 1,
                            height: 8,
                            color: cs.outline.withValues(alpha: 0.24),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: showSpinner || showCheck
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                        fontWeight: showSpinner || showCheck
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (showSpinner)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (showCheck)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.green,
                    ),
                  if (status == 'error')
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: cs.error,
                    ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 6, left: 28),
                  child: Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                ),
                crossFadeState: showDescription && description.isNotEmpty
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulseIcon extends StatefulWidget {
  final Widget child;
  const _PulseIcon({required this.child});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return widget.child;
    }
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}
