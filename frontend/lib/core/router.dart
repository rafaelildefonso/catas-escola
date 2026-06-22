import 'package:catas/providers/auth_provider.dart';
import 'package:catas/providers/server_status_provider.dart';
import 'package:catas/screens/automations_screen.dart';
import 'package:catas/screens/chat_screen.dart';
import 'package:catas/screens/dashboard/impact_dashboard_screen.dart';
import 'package:catas/screens/history_screen.dart';
import 'package:catas/screens/integrations_screen.dart';
import 'package:catas/screens/notifications_screen.dart';
import 'package:catas/screens/pricing_screen.dart';
import 'package:catas/screens/settings_screen.dart';
import 'package:catas/screens/splash_screen.dart';
import 'package:catas/screens/web/web_main_layout.dart';
import 'package:catas/screens/automation_detail_screen.dart';
import 'package:catas/screens/main_layout.dart';
// Demo screens
import 'package:catas/screens/demo_report_screen.dart';
import 'package:catas/screens/suggested_prompts_screen.dart';
import 'package:catas/core/app_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_page_renderer.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:catas/core/responsive.dart';
import 'package:catas/screens/auth/login_screen.dart';
import 'package:catas/screens/onboarding/onboarding_screen.dart';
import 'package:catas/screens/account_settings_screen.dart';
import 'package:catas/screens/manage_subscription_screen.dart';
import 'package:catas/components/settings_sub_screen.dart';
import 'package:catas/main.dart' show navigatorKey;
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:catas/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Rotas do aplicativo
class AppRoutes {
  static const String login = '/app/login';
  static const String onboarding = '/app/onboarding';
  static const String chat = '/app';
  static const String chatWithSession = '/app/chat/:sessionId';
  static const String automations = '/app/automations';
  static const String integrations = '/app/integrations';
  static const String settings = '/app/settings';
  static const String history = '/app/history';
  static const String pricing = '/app/pricing';
  static const String dashboard = '/app/dashboard';
  static const String settingsAccount = '/app/settings/account';
  static const String settingsSubscription = '/app/settings/subscription';
  static const String settingsAbout = '/app/settings/about';
  static const String settingsHelp = '/app/settings/help';
  static const String notifications = '/app/notifications';
  static const String automationDetail = '/app/automations/:runId';
  static const String suggestedPrompts = '/app/prompts';
  static const String splash = '/app/splash';
  // Demo routes
  static const String demoReport = '/app/report/demo';

  /// Helper para obter rota de chat com sessionId
  static String chatSession(String sessionId) => '/app/chat/$sessionId';
}

/// Configuração do GoRouter
GoRouter createRouter(
  AuthProvider authProvider, {
  required ValueNotifier<bool> initNotifier,
  required VoidCallback onTriggerInit,
  required VoidCallback onRetryConn,
  required ServerStatusProvider serverStatusProvider,
}) {
  return GoRouter(
    navigatorKey: navigatorKey,
    debugLogDiagnostics: true,
    refreshListenable: Listenable.merge([authProvider, initNotifier]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 0. Se app não iniciou e rota é /app, redireciona pro splash
      if (!initNotifier.value && loc.startsWith('/app') && loc != AppRoutes.splash) {
        debugPrint('🔄 Router: Redirecionando para splash (init pendente)');
        return AppRoutes.splash;
      }

      // 0a. Se app já iniciou e está no splash, sai dele
      if (initNotifier.value && loc == AppRoutes.splash) {
        if (AppConfig.isDemoMode) return AppRoutes.chat;
        if (authProvider.isLoading) return null;
        if (!authProvider.isAuthenticated) return AppRoutes.login;
        return AppRoutes.chat;
      }

      // 1. Demo mode — sem restrições de auth
      if (AppConfig.isDemoMode) {
        return null;
      }

      // 2. Se o AuthProvider ainda está inicializando, não redirecionamos.
      if (authProvider.isLoading) {
        debugPrint('🛡️ Router: Protegendo contra flicker. AuthProvider ainda carregando...');
        return null;
      }

      final isAuthenticated = authProvider.isAuthenticated;

      // 2. Limpeza de URL (Web Only) - Remove parâmetros OAuth da URL após login
      if (kIsWeb && isAuthenticated) {
        final hasAuthParams = state.uri.queryParameters.containsKey('code') ||
            state.uri.queryParameters.containsKey('type') ||
            state.uri.queryParameters.containsKey('error') ||
            state.uri.queryParameters.containsKey('access_token') ||
            state.uri.queryParameters.containsKey('refresh_token') ||
            state.uri.queryParameters.containsKey('expires_in');

        if (hasAuthParams) {
          debugPrint('🧹 Router: Limpando parâmetros OAuth da URL...');
          // Limpa a URL removendo todos os query params, mantendo apenas o path
          return state.uri.path;
        }
      }

      // Só protege rotas que começam com /app
      final isAppRoute = loc.startsWith('/app');
      if (!isAppRoute) return null;

      final isLoginRoute = loc == AppRoutes.login;
      final isOnboardingRoute = loc == AppRoutes.onboarding;

      if (!isAuthenticated && !isLoginRoute && !isOnboardingRoute) {
        final fullPath = state.uri.path + (state.uri.query.isNotEmpty ? '?${state.uri.query}' : '');
        return '${AppRoutes.login}?from=${Uri.encodeComponent(fullPath)}';
      }

      if (isAuthenticated && isLoginRoute) {
        final needsOnboarding = !authProvider.onboardingCompleted ||
            (authProvider.profile != null && authProvider.profile!.industry == null);
        if (authProvider.onboardingPrefsLoaded && needsOnboarding) {
          return AppRoutes.onboarding;
        }
        
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return Uri.decodeComponent(from);
        }
        
        return AppRoutes.chat;
      }

      final needsOnboarding = !authProvider.onboardingCompleted ||
          (authProvider.profile != null && authProvider.profile!.industry == null);

      if (isAuthenticated &&
          authProvider.onboardingPrefsLoaded &&
          needsOnboarding &&
          !isOnboardingRoute &&
          !isLoginRoute) {
        return AppRoutes.onboarding;
      }

      return null;
    },
    routes: [
      // Rota raiz: busca landing.html e substitui a página (mantém URL /)
      GoRoute(
        path: '/',
        builder: (context, state) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) => renderPage('/landing.html'));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),

      // Rota de login (fora do shell)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Splash (fora do shell — sem sidebar)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        parentNavigatorKey: navigatorKey,
        builder: (context, state) => ChangeNotifierProvider.value(
          value: serverStatusProvider,
          child: SplashScreen(
            onInitializationTrigger: onTriggerInit,
            onRetryConnection: onRetryConn,
          ),
        ),
      ),

      // Shell route para o layout principal (web com sidebar)
      ShellRoute(
        builder: (context, state, child) {
          // No Web, decide pelo tamanho da viewport
          if (kIsWeb) {
            final width = MediaQuery.of(context).size.width;
            if (width < Breakpoints.mobile) {
              return MainLayout(child: child);
            }
            return WebMainLayout(child: child);
          }

          // Em dispositivos móveis nativos, usa o layout mobile
          return MainLayout(child: child);
        },
        routes: [
          // Chat principal (nova conversa)
          GoRoute(
            path: AppRoutes.chat,
            name: 'chat',
            builder: (context, state) => const ChatScreen(),
          ),

          // Chat com sessão específica
          GoRoute(
            path: AppRoutes.chatWithSession,
            name: 'chat-session',
            builder: (context, state) => const ChatScreen(),
          ),

          // Automações
          GoRoute(
            path: AppRoutes.automations,
            name: 'automations',
            builder: (context, state) => const AutomationsScreen(),
          ),

          // Prompts Sugeridos
          GoRoute(
            path: AppRoutes.suggestedPrompts,
            name: 'suggested-prompts',
            builder: (context, state) => const SuggestedPromptsScreen(),
          ),

          // Detalhes da Automação (Flow)
          GoRoute(
            path: AppRoutes.automationDetail,
            name: 'automation-detail',
            builder: (context, state) {
              final runId = state.pathParameters['runId']!;
              return AutomationDetailScreen(runId: runId);
            },
          ),

          // Demo Report (only available in demo mode)
          if (AppConfig.isDemoMode)
            GoRoute(
              path: AppRoutes.demoReport,
              name: 'demo-report',
              builder: (context, state) => const DemoReportScreen(),
            ),

          // Integrações
          GoRoute(
            path: AppRoutes.integrations,
            name: 'integrations',
            builder: (context, state) => const IntegrationsScreen(),
          ),

          // Configurações
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),

          // Histórico
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
          ),

          // Planos
          GoRoute(
            path: AppRoutes.pricing,
            name: 'pricing',
            builder: (context, state) => const PricingScreen(),
          ),

          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const ImpactDashboardScreen(),
          ),
        ],
      ),

      // Rota de Configurações da Conta (fora do shell para não ter Drawer/AppBar do MainLayout)
      GoRoute(
        path: AppRoutes.settingsAccount,
        name: 'settings-account',
        parentNavigatorKey: navigatorKey,
        builder: (context, state) => const AccountSettingsScreen(),
      ),

      // Rota de Gerenciamento de Assinatura (fora do shell)
      GoRoute(
        path: AppRoutes.settingsSubscription,
        name: 'settings-subscription',
        parentNavigatorKey: navigatorKey,
        builder: (context, state) => const ManageSubscriptionScreen(),
      ),

      // Rota Sobre (fora do shell)
      GoRoute(
        path: AppRoutes.settingsAbout,
        name: 'settings-about',
        parentNavigatorKey: navigatorKey,
        builder: (context, state) => SettingsSubScreen(
          title: "Sobre o CATAS",
          children: _buildAboutContent(context),
        ),
      ),

      // Rota Ajuda (fora do shell)
      GoRoute(
        path: AppRoutes.settingsHelp,
        name: 'settings-help',
        parentNavigatorKey: navigatorKey,
        builder: (context, state) => SettingsSubScreen(
          title: "Obter Ajuda",
          children: _buildHelpContent(context),
        ),
      ),

      // Notificações (fora do shell)
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: navigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Páginas HTML: busca e substitui página (mantém URL limpa)
      GoRoute(
        path: '/terms',
        name: 'terms',
        builder: (context, state) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) => renderPage('/terms.html'));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) => renderPage('/privacy.html'));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
      GoRoute(
        path: '/security',
        name: 'security',
        builder: (context, state) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) => renderPage('/security.html'));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) => renderPage('/about.html'));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
      GoRoute(
        path: '/contact',
        name: 'contact',
        builder: (context, state) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) => renderPage('/contact.html'));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
      GoRoute(
        path: '/cookies',
        name: 'cookies',
        builder: (context, state) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) => renderPage('/cookies.html'));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
      GoRoute(
        path: '/refund',
        name: 'refund',
        builder: (context, state) {
          if (kIsWeb) {
            WidgetsBinding.instance.addPostFrameCallback((_) => renderPage('/refund.html'));
          }
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        },
      ),
    ],
  );
}

// Helpers para não poluir o router com UI
List<Widget> _buildAboutContent(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  Future<String> getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return "${info.version} (${info.buildNumber})";
  }

  return [
    const SizedBox(height: 20),
    Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.auto_awesome,
          size: 50,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
    const SizedBox(height: 24),
    Text(
      "CATAS",
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    const SizedBox(height: 8),
    FutureBuilder<String>(
      future: getVersion(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Text(
            "Carregando...",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
        return Text(
          "Versão ${snapshot.data}",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    ),
    const SizedBox(height: 32),
    Text(
      "O Context Aware Task Automation System (CATAS) é um agente inteligente desenhado para converter linguagem natural em fluxos de automação poderosos.",
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 16,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    const SizedBox(height: 32),
    OutlinedButton.icon(
      onPressed: () { if (kIsWeb) navigateTo('/terms'); },
      icon: const Icon(Icons.description_outlined),
      label: Text(l10n.termsOfService),
    ),
    const SizedBox(height: 12),
    OutlinedButton.icon(
      onPressed: () { if (kIsWeb) navigateTo('/privacy'); },
      icon: const Icon(Icons.privacy_tip_outlined),
      label: Text(l10n.privacyPolicy),
    ),
  ];
}

Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    debugPrint('Could not launch $url');
  }
}

List<Widget> _buildHelpContent(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;

  return [
    Text(
      "Como podemos ajudar?",
      style: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    const SizedBox(height: 16),
    Text(
      "Se você precisa de ajuda para configurar integrações, entender funcionalidades ou relatar um problema, entre em contato conosco.",
      style: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
    const SizedBox(height: 32),
    FilledButton.icon(
      onPressed: () => _launchUrl('mailto:suporte@catas.ai'),
      icon: const Icon(Icons.email_outlined),
      label: Text(l10n.sendSupportEmail),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () { if (kIsWeb) navigateTo('/security'); },
      icon: const Icon(Icons.menu_book),
      label: Text(l10n.accessDocs),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    const SizedBox(height: 32),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                "Comunidade",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Junte-se à nossa comunidade no Discord para trocar ideias e receber dicas de automações úteis do dia a dia.",
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _launchUrl('https://discord.gg/placeholder'),
            child: Text(l10n.joinDiscordBrowser),
          ),
        ],
      ),
    ),
  ];
}
