import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/relatorio_provider.dart';
import '../../components/dashboard/metric_card.dart';
import '../../components/dashboard/productivity_chart.dart';
import '../../components/brand_logo.dart';
import '../../l10n/app_localizations.dart';
import '../../components/catas_page.dart';

class ImpactDashboardScreen extends StatefulWidget {
  const ImpactDashboardScreen({super.key});

  @override
  State<ImpactDashboardScreen> createState() => _ImpactDashboardScreenState();
}

class _ImpactDashboardScreenState extends State<ImpactDashboardScreen> {
  // Emerald palette for "growth/success" accent
  static const _emerald = Color(0xFF10B981);
  static const _blue = Color(0xFF3B82F6);
  static const _amber = Color(0xFFF59E0B);
  static const _violet = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDashboard());
  }

  Future<void> _carregarDashboard() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    await context.read<RelatorioProvider>().carregarDashboard(userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final relatorio = context.watch<RelatorioProvider>();
    final dashboard = relatorio.dashboard;
    final isWide = MediaQuery.sizeOf(context).width > 600;

    final tier = auth.subscriptionTier ?? 'free';

    final totalExecutions = _intValue(dashboard?['total_execucoes']);
    final successRate = _intValue(dashboard?['taxa_sucesso']);

    final l10n = AppLocalizations.of(context)!;
    final weekly = _buildWeeklySeries(dashboard, l10n);
    final topIntegrations = _parseIntegrations(dashboard);

    return CatasPage(
      title: 'Visão geral',
      description:
          'Acompanhe o impacto do CATAS no seu tempo, tarefas e automações.',
      child: relatorio.carregandoDashboard && dashboard == null
          ? _buildDashboardLoading(theme)
          : relatorio.erro != null && dashboard == null
          ? _buildDashboardError(theme, relatorio.erro!)
          : RefreshIndicator(
              onRefresh: _carregarDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══════════════════════════════════════
                    // 1. HERO GREETING CARD
                    // ═══════════════════════════════════════
                    _buildHeroCard(
                      context,
                      theme,
                      isDark,
                      auth,
                      totalExecutions,
                      tier,
                      isWide,
                      l10n,
                    ),
                    SizedBox(height: isWide ? 24 : 16),

                    // ═══════════════════════════════════════
                    // 2. KEY METRICS ROW
                    // ═══════════════════════════════════════
                    if (isWide)
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: l10n.dashboardExecutionsInPeriod,
                                  value: '$totalExecutions',
                                  subtitle: l10n.dashboardLast7Days,
                                  icon: Icons.bolt_rounded,
                                  accentColor: _amber,
                                  animationDelayMs: 200,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: MetricCard(
                                  title: l10n.dashboardSuccessRate,
                                  value: totalExecutions == 0
                                      ? 'N/A'
                                      : '$successRate%',
                                  subtitle: totalExecutions == 0
                                      ? l10n.dashboardNoExecutionsShort
                                      : l10n.dashboardBasedOnExecutions,
                                  icon: Icons.check_circle_outline_rounded,
                                  accentColor: _blue,
                                  animationDelayMs: 300,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: MetricCard(
                                  title: l10n.dashboardExecutionsInPeriod,
                                  value: '$totalExecutions',
                                  subtitle: l10n.dashboardLast7Days,
                                  icon: Icons.bolt_rounded,
                                  accentColor: _amber,
                                  animationDelayMs: 200,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: MetricCard(
                                  title: l10n.dashboardSuccessRate,
                                  value: totalExecutions == 0
                                      ? 'N/A'
                                      : '$successRate%',
                                  subtitle: totalExecutions == 0
                                      ? l10n.dashboardNoExecutionsShort
                                      : l10n.dashboardBasedOnExecutions,
                                  icon: Icons.check_circle_outline_rounded,
                                  accentColor: _blue,
                                  animationDelayMs: 300,
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    SizedBox(height: isWide ? 24 : 16),

                    // ═══════════════════════════════════════
                    // 3. PRODUCTIVITY CHART
                    // ═══════════════════════════════════════
                    ProductivityChart(
                      weeklyData: weekly.values,
                      dayLabels: weekly.labels,
                    ),
                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════
                    // 4. BOTTOM ROW: Top Integrations + Upsell
                    // ═══════════════════════════════════════
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildTopIntegrationsCard(
                              context,
                              theme,
                              isDark,
                              topIntegrations,
                              isWide,
                              l10n,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: _buildUpsellCard(
                              context,
                              theme,
                              isDark,
                              tier,
                              isWide,
                              l10n,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildTopIntegrationsCard(
                            context,
                            theme,
                            isDark,
                            topIntegrations,
                            isWide,
                            l10n,
                          ),
                          const SizedBox(height: 16),
                          _buildUpsellCard(
                            context,
                            theme,
                            isDark,
                            tier,
                            isWide,
                            l10n,
                          ),
                        ],
                      ),
                    SizedBox(height: isWide ? 32 : 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardLoading(ThemeData theme) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDashboardError(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: theme.colorScheme.error,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              error.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _carregarDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // HERO CARD
  // ═══════════════════════════════════════════════════
  Widget _buildHeroCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    AuthProvider auth,
    int totalExecutions,
    String tier,
    bool isWide,
    AppLocalizations l10n,
  ) {
    final firstName = auth.userFirstName ?? l10n.defaultUserName;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.all(isWide ? 24 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _emerald.withValues(alpha: isDark ? 0.15 : 0.08),
                _blue.withValues(alpha: isDark ? 0.10 : 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _emerald.withValues(alpha: isDark ? 0.2 : 0.15),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildHeroTextContent(
                  theme,
                  totalExecutions,
                  firstName,
                  isWide,
                  l10n,
                ),
              ),
              const SizedBox(width: 16),
              _buildCreditsRing(theme, auth, l10n),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: (kIsWeb ? 300 : 600).ms)
        .slideY(
          begin: -0.05,
          end: 0,
          duration: (kIsWeb ? 300 : 600).ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildHeroTextContent(
    ThemeData theme,
    int totalExecutions,
    String firstName,
    bool isWide,
    AppLocalizations l10n,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.goodMorning(firstName)
        : hour < 18
        ? l10n.goodAfternoon(firstName)
        : l10n.goodEvening(firstName);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: GoogleFonts.inter(
            fontSize: isWide ? 22 : 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          totalExecutions == 0
              ? l10n.dashboardNoExecutions
              : l10n.dashboardExecutionsSummary(totalExecutions),
          style: GoogleFonts.inter(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCreditsRing(
    ThemeData theme,
    AuthProvider auth,
    AppLocalizations l10n,
  ) {
    final used = auth.quotaUsed ?? 0;
    final limit = auth.monthlyQuotaLimit ?? 0;
    final progress = limit > 0 ? (used / limit).clamp(0.0, 1.0) : 0.0;

    Color ringColor;
    if (progress < 0.5) {
      ringColor = _emerald;
    } else if (progress < 0.8) {
      ringColor = _amber;
    } else {
      ringColor = const Color(0xFFEF4444); // Red
    }

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ringColor,
                ),
              ),
              Text(
                l10n.dashboardUsed,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // TOP INTEGRATIONS CARD
  // ═══════════════════════════════════════════════════
  Widget _buildTopIntegrationsCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    List<_IntegrationUsage> integrations,
    bool isWide,
    AppLocalizations l10n,
  ) {
    return Container(
          padding: EdgeInsets.all(isWide ? 20 : 16),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? theme.colorScheme.outlineVariant
                  : theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dashboardConnectedIntegrations,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.dashboardConnectedIntegrationsSubtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              if (integrations.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_off_outlined,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.dashboardNoIntegrations,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...integrations.map(
                  (integration) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: integration.color.withValues(
                              alpha: isDark ? 0.15 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: integration.logoId != null
                              ? Center(
                                  child: Logo(
                                    logoId: integration.logoId!,
                                    size: 18,
                                    onErrorIcon: Icon(
                                      integration.fallbackIcon,
                                      color: isDark
                                          ? integration.color.withValues(
                                              alpha: 0.9,
                                            )
                                          : integration.color,
                                      size: 18,
                                    ),
                                  ),
                                )
                              : Icon(
                                  integration.fallbackIcon,
                                  color: isDark
                                      ? integration.color.withValues(alpha: 0.9)
                                      : integration.color,
                                  size: 18,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                integration.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: integration.percentage,
                                  minHeight: 5,
                                  backgroundColor: theme.colorScheme.outline
                                      .withValues(alpha: 0.08),
                                  valueColor: AlwaysStoppedAnimation(
                                    integration.color.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(integration.percentage * 100).toInt()}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        )
        .animate(delay: (kIsWeb ? 200 : 400).ms)
        .fadeIn(duration: (kIsWeb ? 200 : 400).ms)
        .slideX(
          begin: -0.05,
          end: 0,
          duration: (kIsWeb ? 200 : 400).ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ═══════════════════════════════════════════════════
  // UPSELL / PLAN CARD
  // ═══════════════════════════════════════════════════
  Widget _buildUpsellCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String tier,
    bool isWide,
    AppLocalizations l10n,
  ) {
    if (tier == 'max') {
      // If max plan, show a "you're on the best plan" card
      return _buildMaxPlanCard(theme, isDark, isWide, l10n);
    }

    final targetPlan = tier == 'free' || tier == 'basic' ? 'PRO' : 'MAX';
    final benefits = (tier == 'free' || tier == 'basic')
        ? ['7.500 créditos/mês', 'Multi-step workflows', 'Anexos no chat']
        : [
            '25.000 créditos/mês',
            'Modelos avançados de IA',
            'Agentes customizados de IA',
          ];

    return Container(
          padding: EdgeInsets.all(isWide ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _violet.withValues(alpha: isDark ? 0.12 : 0.06),
                _blue.withValues(alpha: isDark ? 0.08 : 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _violet.withValues(alpha: isDark ? 0.2 : 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: _violet, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.dashboardUnlock(targetPlan),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...benefits.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: _emerald,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.read<NavigationProvider>().setPage(AppPage.pricing);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _violet,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    l10n.dashboardUpgrade,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(delay: (kIsWeb ? 300 : 600).ms)
        .fadeIn(duration: (kIsWeb ? 200 : 400).ms)
        .slideX(
          begin: 0.05,
          end: 0,
          duration: (kIsWeb ? 200 : 400).ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildMaxPlanCard(
    ThemeData theme,
    bool isDark,
    bool isWide,
    AppLocalizations l10n,
  ) {
    return Container(
          padding: EdgeInsets.all(isWide ? 20 : 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _emerald.withValues(alpha: isDark ? 0.12 : 0.06),
                _blue.withValues(alpha: isDark ? 0.08 : 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _emerald.withValues(alpha: isDark ? 0.2 : 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified_rounded, color: _emerald, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    l10n.dashboardMaxPlanActive,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.dashboardMaxPlanDescription,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
            ],
          ),
        )
        .animate(delay: (kIsWeb ? 300 : 600).ms)
        .fadeIn(duration: (kIsWeb ? 200 : 400).ms);
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════
  int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  _WeeklySeries _buildWeeklySeries(
    Map<String, dynamic>? dashboard,
    AppLocalizations l10n,
  ) {
    final byDate = <String, double>{};
    final raw = dashboard?['execucoes_por_dia'];
    if (raw is List) {
      for (final item in raw) {
        if (item is! Map) continue;
        final date = '${item['dia'] ?? ''}'.split('T').first;
        if (date.isEmpty) continue;
        byDate[date] = _intValue(item['total']).toDouble();
      }
    }

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final values = <double>[];
    final labels = <String>[];
    for (var offset = 6; offset >= 0; offset--) {
      final date = start.subtract(Duration(days: offset));
      final key = _dateKey(date);
      values.add(byDate[key] ?? 0);
      labels.add(_weekdayLabel(date.weekday, l10n));
    }
    return _WeeklySeries(values: values, labels: labels);
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _weekdayLabel(int weekday, AppLocalizations l10n) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.dashboardWeeklyDayMon;
      case DateTime.tuesday:
        return l10n.dashboardWeeklyDayTue;
      case DateTime.wednesday:
        return l10n.dashboardWeeklyDayWed;
      case DateTime.thursday:
        return l10n.dashboardWeeklyDayThu;
      case DateTime.friday:
        return l10n.dashboardWeeklyDayFri;
      case DateTime.saturday:
        return l10n.dashboardWeeklyDaySat;
      default:
        return l10n.dashboardWeeklyDaySun;
    }
  }

  List<_IntegrationUsage> _parseIntegrations(Map<String, dynamic>? dashboard) {
    final raw = dashboard?['top_integracoes'];
    if (raw is! List) return [];
    final entries = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final total = _intValue(item['total']);
      if (total > 0) {
        entries.add({'provider': '${item['provider'] ?? ''}', 'total': total});
      }
    }
    final totalIntegrations = entries.fold<int>(
      0,
      (sum, item) => sum + (item['total'] as int),
    );
    if (totalIntegrations == 0) return [];

    return entries.map((item) {
      final provider = item['provider'] as String;
      final descriptor = _integrationDescriptor(provider);
      return _IntegrationUsage(
        descriptor.name,
        descriptor.logoId,
        descriptor.fallbackIcon,
        (item['total'] as int) / totalIntegrations,
        descriptor.color,
      );
    }).toList();
  }

  _IntegrationDescriptor _integrationDescriptor(String provider) {
    switch (provider) {
      case 'google_calendar':
        return const _IntegrationDescriptor(
          'Google Calendar',
          LogoId.googleCalendar,
          Icons.calendar_month_rounded,
          Color(0xFF4285F4),
        );
      case 'google_gmail':
      case 'gmail':
        return const _IntegrationDescriptor(
          'Gmail',
          LogoId.googleGmail,
          Icons.email_outlined,
          Color(0xFFEA4335),
        );
      case 'google_sheets':
        return const _IntegrationDescriptor(
          'Google Sheets',
          LogoId.googleSheets,
          Icons.table_chart_outlined,
          Color(0xFF34A853),
        );
      case 'google_drive':
        return const _IntegrationDescriptor(
          'Google Drive',
          LogoId.googleDrive,
          Icons.folder_outlined,
          Color(0xFF4285F4),
        );
      case 'notion':
        return const _IntegrationDescriptor(
          'Notion',
          LogoId.notion,
          Icons.book_outlined,
          Color(0xFF000000),
        );
      case 'slack':
        return const _IntegrationDescriptor(
          'Slack',
          LogoId.slack,
          Icons.tag_rounded,
          Color(0xFF4A154B),
        );
      default:
        final name = provider
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
        return _IntegrationDescriptor(
          name.isEmpty ? 'Integração' : name,
          null,
          Icons.extension_outlined,
          _blue,
        );
    }
  }
}

class _WeeklySeries {
  final List<double> values;
  final List<String> labels;

  const _WeeklySeries({required this.values, required this.labels});
}

class _IntegrationDescriptor {
  final String name;
  final LogoId? logoId;
  final IconData fallbackIcon;
  final Color color;

  const _IntegrationDescriptor(
    this.name,
    this.logoId,
    this.fallbackIcon,
    this.color,
  );
}

class _IntegrationUsage {
  final String name;
  final LogoId? logoId;
  final IconData fallbackIcon;
  final double percentage;
  final Color color;

  _IntegrationUsage(
    this.name,
    this.logoId,
    this.fallbackIcon,
    this.percentage,
    this.color,
  );
}
