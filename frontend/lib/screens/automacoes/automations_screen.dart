import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../components/brand_logo.dart';
import '../../components/upgrade_modal.dart';
import '../../components/chat/options_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/automations_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../components/catas_page.dart';

class AutomationsScreen extends StatefulWidget {
  const AutomationsScreen({super.key});

  @override
  State<AutomationsScreen> createState() => _AutomationsScreenState();
}

class _AutomationsScreenState extends State<AutomationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (!mounted) return;
    if (auth.userId != null) {
      await context.read<AutomationsProvider>().fetchRuns(
        auth.userId!,
        refresh: true,
      );
    }
  }

  void _toggleAutomation(AutomationRun run, bool value, String userTier) {
    if (userTier == 'free') {
      UpgradeModal.show(context, "Ativar Automações", "Basic");
      return;
    }

    if (run.automationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Esta execução não está vinculada a uma automação salva e não pode ser pausada.",
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    context.read<AutomationsProvider>().toggleAutomationStatus(
      run.automationId!,
      value,
    );

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? l10n.automationActivated(run.inputSummary)
              : l10n.automationPausadaFeedback(run.inputSummary),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteAutomation(AutomationRun run) {
    if (run.automationId != null) {
      context.read<AutomationsProvider>().deleteAutomation(run.automationId!);
    } else {
      // Se não tem automationId, deletamos apenas a RUN do histórico
      context.read<AutomationsProvider>().deleteRun(run.id);
    }

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.automationRemoved(run.inputSummary)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(AutomationRun run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final l10n = AppLocalizations.of(dialogCtx)!;
        return AlertDialog(
          title: Text(l10n.deleteAutomationTitle),
          content: Text('${l10n.deleteChatContent} "${run.inputSummary}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text(l10n.actionDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      _deleteAutomation(run);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<AutomationsProvider>();
    final userTier = auth.subscriptionTier ?? 'free';

    return CatasPage(
      title: 'Automações',
      description:
          'Acompanhe execuções, revise resultados e gerencie seus fluxos.',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.suggestedPrompts),
          icon: const Icon(Icons.auto_awesome_outlined, size: 18),
          label: const Text('Ver ideias'),
        ),
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.chat),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nova automação'),
        ),
      ],
      child: Column(
        children: [
          _buildPromptsCtaBanner(),
          Expanded(
            child: Skeletonizer(
              enabled: provider.isLoading,
              child: RefreshIndicator(
                onRefresh: () => _loadInitialData(),
                child: provider.isLoading
                    ? _buildSkeletonList()
                    : (provider.runs.isEmpty
                          ? _buildEmptyState()
                          : _buildContent(provider, auth, userTier)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptsCtaBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 500) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sem ideias de automação?',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Explore nossa biblioteca de prompts sugeridos e comece a automatizar em segundos.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: () {
                      context.push(AppRoutes.suggestedPrompts);
                    },
                    child: const Text('Ver Prompts Sugeridos'),
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sem ideias de automação?',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore nossa biblioteca de prompts sugeridos e comece a automatizar em segundos.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.tonal(
                onPressed: () {
                  context.push(AppRoutes.suggestedPrompts);
                },
                child: const Text('Ver Prompts'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        if (isDesktop) {
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => _buildAutomationCard(
              context,
              _dummyRun(),
              'pro',
              isDesktop: true,
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) => _buildAutomationCard(
            context,
            _dummyRun(),
            'pro',
            isDesktop: false,
          ),
        );
      },
    );
  }

  AutomationRun _dummyRun() {
    return AutomationRun(
      id: 'dummy',
      status: 'completed',
      automationStatus: 'active',
      automationName: 'Carregando nome da automação...',
      runType: 'temporal',
      inputSummary: 'Carregando detalhes da automação salva no sistema...',
      inputPayload: {
        'modules': ['google', 'whatsapp', 'slack'],
      },
      createdAt: DateTime.now(),
    );
  }

  Widget _buildContent(
    AutomationsProvider provider,
    AuthProvider auth,
    String userTier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 800;
        final itemCount = provider.runs.length + (provider.hasMore ? 1 : 0);

        if (isDesktop) {
          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == provider.runs.length) {
                return _buildLoadMoreButton(provider, auth.userId!);
              }
              return _buildAutomationCard(
                context,
                provider.runs[index],
                userTier,
                isDesktop: true,
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (index == provider.runs.length) {
              return _buildLoadMoreButton(provider, auth.userId!);
            }
            return _buildAutomationCard(
              context,
              provider.runs[index],
              userTier,
              isDesktop: false,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "Nenhuma automação encontrada",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Crie uma nova automação via chat para começar.",
            style: GoogleFonts.inter(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(AutomationsProvider provider, String userId) {
    if (!provider.hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: provider.isLoadingMore
            ? const CircularProgressIndicator()
            : OutlinedButton(
                onPressed: () => provider.fetchRuns(userId),
                child: const Text("Carregar mais"),
              ),
      ),
    );
  }

  ({Color color, Color textColor, String label}) _getStatusInfo(
    BuildContext context,
    AutomationRun run,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Se a automação estiver pausada, mostramos pausado independente do status da RUN
    if (run.automationStatus == 'paused') {
      return (
        color: Colors.grey.withValues(alpha: 0.15),
        textColor: Colors.grey[400]!,
        label: l10n.automationPaused,
      );
    }

    switch (run.status) {
      case 'completed':
        return (
          color: Colors.green.withValues(alpha: 0.15),
          textColor: Colors.green[400]!,
          label: l10n.automationActive,
        );
      case 'failed':
        return (
          color: Colors.red.withValues(alpha: 0.15),
          textColor: Colors.red[400]!,
          label: l10n.automationFailed,
        );
      case 'running':
        return (
          color: Colors.blue.withValues(alpha: 0.15),
          textColor: Colors.blue[400]!,
          label: "Executando",
        );
      default:
        return (
          color: Colors.orange.withValues(alpha: 0.15),
          textColor: Colors.orange[400]!,
          label: "Pendente",
        );
    }
  }

  List<LogoId> _extractLogos(AutomationRun run) {
    final List<LogoId> logos = [];
    final payload = run.inputPayload;

    final modules = payload['modules'];
    if (modules is List) {
      for (var m in modules) {
        final mod = m.toString().toLowerCase();
        if (mod.contains('sheets')) logos.add(LogoId.google);
        if (mod.contains('calendar')) logos.add(LogoId.googleCalendar);
        if (mod.contains('gmail')) logos.add(LogoId.googleGmail);
        if (mod.contains('slack')) logos.add(LogoId.slack);
        if (mod.contains('whatsapp')) logos.add(LogoId.whatsapp);
        if (mod.contains('notion')) logos.add(LogoId.notion);
      }
    }

    if (logos.isEmpty) {
      final type = payload['action_type']?.toString().toLowerCase() ?? '';
      if (type.contains('gmail')) logos.add(LogoId.googleGmail);
      if (type.contains('calendar')) logos.add(LogoId.googleCalendar);
      if (type.contains('whatsapp')) logos.add(LogoId.whatsapp);
    }

    return logos.toSet().take(3).toList();
  }

  Widget _buildAutomationCard(
    BuildContext context,
    AutomationRun run,
    String userTier, {
    bool isDesktop = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final statusInfo = _getStatusInfo(context, run);
    final logos = _extractLogos(run);

    final dateStr =
        "${run.createdAt.day.toString().padLeft(2, '0')}/${run.createdAt.month.toString().padLeft(2, '0')}/${run.createdAt.year}";
    final timeStr =
        "${run.createdAt.hour.toString().padLeft(2, '0')}:${run.createdAt.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF111113)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  run.inputSummary.isEmpty
                      ? "Automação sem título"
                      : run.inputSummary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OptionsButton(
                iconSize: 20,
                padding: const EdgeInsets.all(4),
                items: [
                  OptionsMenuItem(
                    value: run.automationStatus != 'paused'
                        ? 'pause'
                        : 'activate',
                    icon: run.automationStatus != 'paused'
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_fill_outlined,
                    label: run.automationStatus != 'paused'
                        ? l10n.automationPause
                        : l10n.automationActivate,
                  ),
                  OptionsMenuItem(
                    value: 'delete',
                    icon: Icons.delete_outline,
                    label: l10n.deleteAutomation,
                    isDestructive: true,
                  ),
                ],
                onSelected: (value) {
                  if (value == 'pause' || value == 'activate') {
                    _toggleAutomation(run, value == 'activate', userTier);
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(run);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.automationCreatedOn(dateStr, timeStr),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          if (isDesktop) const Spacer() else const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 450) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.automationIntegrations,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: logos.isEmpty
                                ? [
                                    Icon(
                                      Icons.hub_outlined,
                                      size: 20,
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ]
                                : logos
                                      .map(
                                        (logo) => Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Logo(
                                            logoId: logo,
                                            size: 20,
                                            onErrorIcon: const Icon(
                                              Icons.auto_awesome,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      height: 32,
                      decoration: BoxDecoration(
                        color: statusInfo.color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusInfo.textColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusInfo.label,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: statusInfo.textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    SizedBox(
                      height: 32,
                      child: FilledButton(
                        onPressed: () => context.push(
                          AppRoutes.automationDetailPath(run.id),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.onSurface.withValues(
                            alpha: 0.1,
                          ),
                          foregroundColor: colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          l10n.automationViewDetails,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.automationIntegrations,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        height: 32,
                        decoration: BoxDecoration(
                          color: statusInfo.color,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusInfo.textColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusInfo.label,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: statusInfo.textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: logos.isEmpty
                        ? [
                            Icon(
                              Icons.hub_outlined,
                              size: 20,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                            ),
                          ]
                        : logos
                              .map(
                                (logo) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Logo(
                                    logoId: logo,
                                    size: 20,
                                    onErrorIcon: const Icon(
                                      Icons.auto_awesome,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          context.push(AppRoutes.automationDetailPath(run.id)),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        l10n.automationViewDetails,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
