import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/automations_provider.dart';
import '../core/responsive.dart';
import '../components/brand_logo.dart';
import '../components/options_button.dart';
import '../core/app_config.dart';
import '../main.dart' show navigatorKey;
import '../providers/demo_automations_provider.dart';
import '../providers/demo_autoplay_controller.dart';
import '../providers/chat_provider.dart';

class AutomationDetailScreen extends StatefulWidget {
  final String runId;

  const AutomationDetailScreen({super.key, required this.runId});

  @override
  State<AutomationDetailScreen> createState() => _AutomationDetailScreenState();
}

class _AutomationDetailScreenState extends State<AutomationDetailScreen> {
  AutomationStepLog? _selectedStep;
  Timer? _restartTimer;
  bool _restartTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<AutomationsProvider>();
    if (provider is DemoAutomationsProvider) {
      provider.fetchStepLogs(widget.runId);
    } else {
      await provider.fetchStepLogs(widget.runId);
    }
  }

  @override
  void dispose() {
    _restartTimer?.cancel();
    super.dispose();
  }

  void _startRestartCountdown() {
    if (!AppConfig.isDemoMode) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) _doRestart();
    });
  }

  void _doRestart() {
    if (!mounted) return;
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        ctx.read<ChatProvider>().clearChat();
        Future.delayed(const Duration(milliseconds: 300), () {
          ctx.read<DemoAutoplayController>().startOnboardingDemo();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutomationsProvider>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final run = provider.runs.cast<AutomationRun?>().firstWhere(
      (r) => r?.id == widget.runId,
      orElse: () => null,
    );

    final isOnboardingDemo = AppConfig.isDemoMode &&
        run != null &&
        run.runType == 'onboarding';

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          run?.inputSummary ?? "Detalhes da Automação",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: isOnboardingDemo
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _restartTimer?.cancel();
                  Navigator.of(context).pop();
                },
              )
            : null,
        actions: isOnboardingDemo
            ? []
            : [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadData,
                  tooltip: "Recarregar",
                ),
              ],
      ),
      body: isOnboardingDemo
          ? _buildOnboardingCanvas(provider, colorScheme, run)
          : _buildStandard(provider, colorScheme),
    );
  }

  Widget _buildStandard(AutomationsProvider provider, ColorScheme colorScheme) {
    final isMobileView = isMobile(context);

    return Row(
      children: [
        Expanded(
          child: provider.isLoadingSteps
              ? const Center(child: CircularProgressIndicator())
              : _buildFlowCanvas(provider.stepLogs),
        ),
        if (!isMobileView && _selectedStep != null)
          _buildSidebar(_selectedStep!, colorScheme),
      ],
    );
  }

  Widget _buildFlowCanvas(List<AutomationStepLog> steps) {
    if (steps.isEmpty) {
      return const Center(child: Text("Nenhum passo registrado nesta execução."));
    }

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.1,
      maxScale: 2.0,
      constrained: false,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 300),
        child: Column(
          children: [
            _buildNode(
              title: "Início",
              subtitle: "Gatilho detectado",
              icon: Icons.play_arrow_rounded,
              color: Colors.blue,
              isStart: true,
            ),
            for (int i = 0; i < steps.length; i++) ...[
              _buildConnector(),
              _buildStepNode(steps[i]),
            ],
            if (steps.isNotEmpty && steps.last.status == 'success') ...[
              _buildConnector(),
              _buildNode(
                title: "Fim",
                subtitle: "Automação finalizada",
                icon: Icons.check_circle_rounded,
                color: Colors.green,
                isEnd: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnector() {
    return Container(
      width: 2,
      height: 40,
      color: Colors.grey.withValues(alpha: 0.3),
    );
  }

  Widget _buildNode({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isStart = false,
    bool isEnd = false,
  }) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(AutomationStepLog step) {
    final isSelected = _selectedStep?.id == step.id;
    final color = _getStepColor(step.status);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedStep = step);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Theme.of(context).colorScheme.primary : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2), blurRadius: 8)]
                : [],
          ),
          child: Row(
            children: [
              _buildStepIcon(step),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.stepName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      _getStatusLabel(step.status),
                      style: GoogleFonts.inter(fontSize: 11, color: color),
                    ),
                  ],
                ),
              ),
              if (isMobile(context))
                OptionsButton(
                  iconSize: 18,
                  padding: const EdgeInsets.all(4),
                  items: [
                    OptionsMenuItem(
                      value: 'details',
                      icon: Icons.info_outline,
                      label: 'Ver detalhes',
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'details') {
                      setState(() => _selectedStep = step);
                      _showStepDialog(step);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIcon(AutomationStepLog step) {
    final type = step.stepType.toLowerCase();
    LogoId? logoId;

    if (type.contains('gmail')) {
      logoId = LogoId.googleGmail;
    } else if (type.contains('sheets')) {
      logoId = LogoId.googleSheets;
    } else if (type.contains('calendar')) {
      logoId = LogoId.googleCalendar;
    } else if (type.contains('drive')) {
      logoId = LogoId.googleDrive;
    } else if (type.contains('slack')) {
      logoId = LogoId.slack;
    } else if (type.contains('whatsapp')) {
      logoId = LogoId.whatsapp;
    } else if (type.contains('notion')) {
      logoId = LogoId.notion;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getStepColor(step.status).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: logoId != null
          ? Logo(logoId: logoId, size: 20, onErrorIcon: const Icon(Icons.auto_awesome, size: 20))
          : Icon(_getStepIcon(step.status), color: _getStepColor(step.status), size: 20),
    );
  }

  Color _getStepColor(String status) {
    switch (status) {
      case 'success': return Colors.green;
      case 'error': return Colors.red;
      case 'running': return Colors.blue;
      default: return Colors.grey;
    }
  }

  IconData _getStepIcon(String status) {
    switch (status) {
      case 'success': return Icons.check_circle_outline;
      case 'error': return Icons.error_outline;
      case 'running': return Icons.sync;
      default: return Icons.schedule;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'success': return "Concluído";
      case 'error': return "Erro";
      case 'running': return "Processando";
      default: return "Aguardando";
    }
  }

  Widget _buildSidebar(AutomationStepLog step, ColorScheme colorScheme) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(left: BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.1))),
      ),
      child: _buildStepDetails(step),
    );
  }

  void _showStepDialog(AutomationStepLog step) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(step.stepName),
        content: SingleChildScrollView(
          child: _buildStepDetails(step),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDetails(AutomationStepLog step) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStepIcon(step),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.stepName,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selectedStep = null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStepColor(step.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getStatusLabel(step.status).toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _getStepColor(step.status),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailSection("Tipo do Passo", step.stepType),
          const SizedBox(height: 16),
          if (step.errorMessage != null)
            _buildDetailSection("Erro", step.errorMessage!, isError: true),
          const SizedBox(height: 16),
          _buildDetailSection("Duração", step.durationMs != null ? "${step.durationMs}ms" : "—"),
          const SizedBox(height: 24),
          Text(
            "Metadados",
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              step.metadata.toString(),
              style: GoogleFonts.firaCode(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String label, String value, {bool isError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isError ? Colors.redAccent : null,
            fontWeight: isError ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }

  // ===== ONBOARDING DEMO MODE =====

  Widget _buildOnboardingCanvas(
    AutomationsProvider provider,
    ColorScheme colorScheme,
    AutomationRun run,
  ) {
    final steps = provider.stepLogs;
    final allCompleted = steps.isNotEmpty && steps.every((s) => s.status == 'success');

    if (allCompleted && !_restartTriggered) {
      _restartTriggered = true;
      _startRestartCountdown();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  run.inputSummary,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  allCompleted
                      ? 'Automação concluída com sucesso!'
                      : 'Executando automação em tempo real...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (allCompleted) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        '3 etapas concluídas em ${steps.fold<int>(0, (sum, s) => sum + (s.durationMs ?? 0))}ms',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Title for steps
          Text(
            'Etapas da Automação',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Veja em tempo real cada integração sendo executada:',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 16),

          // Steps list
          if (steps.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Iniciando automação...',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...steps.map((step) => _buildOnboardingStepCard(step, colorScheme)),

          // Legend
          if (steps.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo da Automação',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLegendRow(
                    Icons.check_circle,
                    Colors.green,
                    'Concluído',
                    colorScheme,
                  ),
                  const SizedBox(height: 4),
                  _buildLegendRow(
                    Icons.sync,
                    Colors.blue,
                    'Em execução',
                    colorScheme,
                  ),
                  const SizedBox(height: 4),
                  _buildLegendRow(
                    Icons.schedule,
                    Colors.grey,
                    'Aguardando',
                    colorScheme,
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildLegendRow(IconData icon, Color color, String label, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingStepCard(AutomationStepLog step, ColorScheme colorScheme) {
    final isRunning = step.status == 'running';
    final isSuccess = step.status == 'success';
    final isPending = step.status == 'pending';

    LogoId? logoId;
    final type = step.stepType.toLowerCase();
    if (type.contains('calendar')) {
      logoId = LogoId.googleCalendar;
    } else if (type.contains('drive')) {
      logoId = LogoId.googleDrive;
    } else if (type.contains('sheets')) {
      logoId = LogoId.googleSheets;
    }

    final desc = step.metadata['description'] as String? ?? '';
    final subtitle = step.metadata['subtitle'] as String? ?? '';

    Color borderColor;
    Color bgColor;
    if (isRunning) {
      borderColor = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.05);
    } else if (isSuccess) {
      borderColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.05);
    } else {
      borderColor = Colors.grey.withValues(alpha: 0.3);
      bgColor = colorScheme.surface;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + step.stepIndex * 150),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-24 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isRunning ? 2 : 1,
          ),
          boxShadow: isRunning
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                  color: isRunning
                      ? Colors.blue.withValues(alpha: 0.1)
                      : isSuccess
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: logoId != null
                    ? Logo(logoId: logoId, size: 24, onErrorIcon: const Icon(Icons.auto_awesome, size: 24))
                    : Icon(Icons.auto_awesome, size: 24, color: borderColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.stepName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isPending
                            ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isRunning)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              if (isSuccess)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.green,
                  ),
                ),
              if (isPending)
                const Icon(
                  Icons.schedule,
                  size: 18,
                  color: Colors.grey,
                ),
            ],
          ),
          if (desc.isNotEmpty && (isRunning || isSuccess)) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (isSuccess && step.durationMs != null) ...[
            const SizedBox(height: 8),
            Text(
              'Concluído em ${(step.durationMs ?? 0) ~/ 10}ms',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    ),
    );
  }
}
