import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../components/dashboard/metric_card.dart';
import '../../components/dashboard/productivity_chart.dart';
import '../../components/brand_logo.dart';
import '../../l10n/app_localizations.dart';

class ImpactDashboardScreen extends StatelessWidget {
  const ImpactDashboardScreen({super.key});

  // Emerald palette for "growth/success" accent
  static const _emerald = Color(0xFF10B981);
  static const _blue = Color(0xFF3B82F6);
  static const _amber = Color(0xFFF59E0B);
  static const _violet = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.sizeOf(context).width > 600;

    // ── Computed metrics (from AuthProvider profile data) ──
    final quotaUsed = auth.quotaUsed ?? 0;
    final quotaRemaining = auth.quotaRemaining ?? 0;
    final quotaLimit = auth.monthlyQuotaLimit ?? 500;
    final tier = auth.subscriptionTier ?? 'free';

    // Estimated time saved: ~5 min per automation
    final minutesSaved = quotaUsed * 5;
    final hoursSaved = (minutesSaved / 60);

    // Financial estimate: avg hourly rate R$ 50 → each 5 min = ~R$4.17
    final moneySaved = (quotaUsed * 4.17);

    // Mock weekly data (ideally from backend later)
    final weeklyData = _generateWeeklyData(quotaUsed);
    final l10n = AppLocalizations.of(context)!;
    final dayLabels = [
      l10n.dashboardWeeklyDayMon,
      l10n.dashboardWeeklyDayTue,
      l10n.dashboardWeeklyDayWed,
      l10n.dashboardWeeklyDayThu,
      l10n.dashboardWeeklyDayFri,
      l10n.dashboardWeeklyDaySat,
      l10n.dashboardWeeklyDaySun,
    ];

    // Top integrations mock (based on common usage)
    final topIntegrations = [
      _IntegrationUsage(
        'Google Calendar',
        LogoId.googleCalendar,
        Icons.calendar_month_rounded,
        0.42,
        const Color(0xFF4285F4),
      ),
      _IntegrationUsage(
        'Notion',
        LogoId.notion,
        Icons.book_outlined,
        0.28,
        const Color(0xFF000000),
      ),
      _IntegrationUsage(
        'Gmail',
        LogoId.googleGmail,
        Icons.email_outlined,
        0.18,
        const Color(0xFFEA4335),
      ),
      _IntegrationUsage(
        'Slack',
        LogoId.slack,
        Icons.tag_rounded,
        0.12,
        const Color(0xFF4A154B),
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 20 : 16,
          vertical: isWide ? 24 : 16,
        ),
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
              hoursSaved,
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
                      title: l10n.dashboardEstimatedROI,
                      value: 'R\$${moneySaved.toStringAsFixed(0)}',
                      subtitle: l10n.dashboardSavedInTasks,
                      icon: Icons.savings_outlined,
                      accentColor: _amber,
                      animationDelayMs: 200,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MetricCard(
                      title: l10n.dashboardTasksExecuted,
                      value: '$quotaRemaining',
                      subtitle: l10n.dashboardOfCredits(quotaLimit),
                      icon: Icons.bolt_rounded,
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
                          title: l10n.dashboardEstimatedROI,
                          value: 'R\$${moneySaved.toStringAsFixed(0)}',
                          icon: Icons.savings_outlined,
                          accentColor: _amber,
                          animationDelayMs: 200,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          title: l10n.dashboardCredits,
                          value: '$quotaRemaining',
                          icon: Icons.bolt_rounded,
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
            ProductivityChart(weeklyData: weeklyData, dayLabels: dayLabels),
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
                  _buildUpsellCard(context, theme, isDark, tier, isWide, l10n),
                ],
              ),
            SizedBox(height: isWide ? 32 : 16),
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
    double hoursSaved,
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
                      child:                     _buildHeroTextContent(
                        theme,
                        hoursSaved,
                        firstName,
                        isWide,
                        l10n,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildCreditsRing(theme, auth, l10n),
                  ],
                )
              
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
    double hoursSaved,
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
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            children: [
              TextSpan(text: l10n.dashboardYouSaved),
              TextSpan(
                text: '${hoursSaved.toStringAsFixed(1)} horas',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _emerald,
                ),
              ),
              TextSpan(text: l10n.dashboardHoursThisMonth),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditsRing(ThemeData theme, AuthProvider auth, AppLocalizations l10n) {
    final used = auth.quotaUsed ?? 0;
    final limit = auth.monthlyQuotaLimit ?? 500;
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
                l10n.dashboardTopIntegrations,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.dashboardMostUsedTools,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
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
                      l10n.dashboardUnlock( targetPlan),
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

  Widget _buildMaxPlanCard(ThemeData theme, bool isDark, bool isWide, AppLocalizations l10n) {
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
    ).animate(delay: (kIsWeb ? 300 : 600).ms).fadeIn(duration: (kIsWeb ? 200 : 400).ms);
  }

  // ═══════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════
  List<double> _generateWeeklyData(int totalUsed) {
    // Distribute total usage somewhat realistically across 7 days
    if (totalUsed == 0) return [0, 0, 0, 0, 0, 0, 0];
    final base = (totalUsed / 30.0); // daily avg
    return [
      (base * 1.2).roundToDouble(),
      (base * 0.8).roundToDouble(),
      (base * 1.5).roundToDouble(),
      (base * 1.1).roundToDouble(),
      (base * 1.4).roundToDouble(),
      (base * 0.6).roundToDouble(),
      (base * 0.4).roundToDouble(),
    ];
  }
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
