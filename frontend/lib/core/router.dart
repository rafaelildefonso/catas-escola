import 'package:catas/providers/auth_provider.dart';
import 'package:catas/screens/active_automations_screen.dart';
import 'package:catas/screens/chat_screen.dart';
import 'package:catas/screens/dashboard/impact_dashboard_screen.dart';
import 'package:catas/screens/history_screen.dart';
import 'package:catas/screens/integrations_screen.dart';
import 'package:catas/screens/notification_list_screen.dart';
import 'package:catas/screens/pricing_screen.dart';
import 'package:catas/screens/settings_screen.dart';
import 'package:catas/screens/web/web_main_layout.dart';
import 'package:catas/screens/automation_detail_screen.dart';
import 'package:catas/screens/crud/crud_management_screen.dart';
import 'package:catas/screens/relatorios/relatorio_screen.dart';
import 'package:catas/screens/main_layout.dart';
// Demo screens
import 'package:catas/screens/demo_report_screen.dart';
import 'package:catas/screens/suggested_prompts_screen.dart';
import 'package:catas/core/app_config.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
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
import 'package:catas/screens/settings_content.dart';
import 'package:catas/screens/subscription_success_screen.dart';

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
  static const String crud = '/app/crud';
  static const String relatorios = '/app/relatorios';
  static const String suggestedPrompts = '/app/prompts';
  // Demo routes
  static const String demoReport = '/app/report/demo';
  static const String paymentSuccess = '/app/payment-success';

  /// Helper para obter rota de chat com sessionId
  static String chatSession(String sessionId) => '/app/chat/$sessionId';

  /// Helper para obter rota de detalhes de automação
  static String automationDetailPath(String runId) => '/app/automations/$runId';
}

/// Transição padrão para todas as rotas
Page<T> _buildPageWithTransition<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
  );
}

/// Configuração do GoRouter
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: navigatorKey,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 1. Demo mode — sem restrições de auth
      if (AppConfig.isDemoMode) {
        return null;
      }

      // 2. Se o AuthProvider ainda está inicializando, não redirecionamos.
      if (authProvider.isLoading) {
        debugPrint(
          '🛡️ Router: Protegendo contra flicker. AuthProvider ainda carregando...',
        );
        return null;
      }

      final isAuthenticated = authProvider.isAuthenticated;

      // 2. Limpeza de URL (Web Only) - Remove parâmetros OAuth da URL após login
      if (kIsWeb && isAuthenticated) {
        final hasAuthParams =
            state.uri.queryParameters.containsKey('code') ||
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
        final fullPath =
            state.uri.path +
            (state.uri.query.isNotEmpty ? '?${state.uri.query}' : '');
        return '${AppRoutes.login}?from=${Uri.encodeComponent(fullPath)}';
      }

      if (isAuthenticated && isLoginRoute) {
        final needsOnboarding =
            !authProvider.onboardingCompleted ||
            (authProvider.profile != null &&
                authProvider.profile!.industry == null);
        if (authProvider.onboardingPrefsLoaded && needsOnboarding) {
          return AppRoutes.onboarding;
        }

        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) {
          return Uri.decodeComponent(from);
        }

        return AppRoutes.chat;
      }

      final needsOnboarding =
          !authProvider.onboardingCompleted ||
          (authProvider.profile != null &&
              authProvider.profile!.industry == null);

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
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: Builder(
            builder: (context) {
              if (kIsWeb) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => renderPage('/landing.html'),
                );
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          state: state,
        ),
      ),

      // Rota de login (fora do shell)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) =>
            _buildPageWithTransition(child: const LoginScreen(), state: state),
      ),

      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const OnboardingScreen(),
          state: state,
        ),
      ),

      // Shell route para o layout principal (web com sidebar)
      ShellRoute(
        builder: (context, state, child) {
          // No Web, decide pelo tamanho da viewport
          if (kIsWeb) {
            return LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < Breakpoints.mobile) {
                  return MainLayout(child: child);
                }
                return WebMainLayout(child: child);
              },
            );
          }

          // Em dispositivos móveis nativos, usa o layout mobile
          return MainLayout(child: child);
        },
        routes: [
          // Chat principal (nova conversa)
          GoRoute(
            path: AppRoutes.chat,
            name: 'chat',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const ChatScreen(),
              state: state,
            ),
          ),

          // Chat com sessão específica
          GoRoute(
            path: AppRoutes.chatWithSession,
            name: 'chat-session',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const ChatScreen(),
              state: state,
            ),
          ),

          // Automações
          GoRoute(
            path: AppRoutes.automations,
            name: 'automations',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const ActiveAutomationsScreen(),
              state: state,
            ),
          ),

          // Prompts Sugeridos
          GoRoute(
            path: AppRoutes.suggestedPrompts,
            name: 'suggested-prompts',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const SuggestedPromptsScreen(),
              state: state,
            ),
          ),

          // CRUD Management
          GoRoute(
            path: AppRoutes.crud,
            name: 'crud',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const CrudManagementScreen(),
              state: state,
            ),
          ),

          // Relatórios
          GoRoute(
            path: AppRoutes.relatorios,
            name: 'relatorios',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const RelatorioScreen(),
              state: state,
            ),
          ),

          // Detalhes da Automação (Flow)
          GoRoute(
            path: AppRoutes.automationDetail,
            name: 'automation-detail',
            pageBuilder: (context, state) {
              final runId = state.pathParameters['runId']!;
              return _buildPageWithTransition(
                child: AutomationDetailScreen(
                  runId: runId,
                  returnLocation: state.uri.queryParameters['from'],
                ),
                state: state,
              );
            },
          ),

          // Demo Report (only available in demo mode)
          if (AppConfig.isDemoMode)
            GoRoute(
              path: AppRoutes.demoReport,
              name: 'demo-report',
              pageBuilder: (context, state) => _buildPageWithTransition(
                child: const DemoReportScreen(),
                state: state,
              ),
            ),

          // Integrações
          GoRoute(
            path: AppRoutes.integrations,
            name: 'integrations',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const IntegrationsScreen(),
              state: state,
            ),
          ),

          // Configurações
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const SettingsScreen(),
              state: state,
            ),
          ),

          // Histórico
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const HistoryScreen(),
              state: state,
            ),
          ),

          // Planos
          GoRoute(
            path: AppRoutes.pricing,
            name: 'pricing',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const PricingScreen(),
              state: state,
            ),
          ),

          // Dashboard
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const ImpactDashboardScreen(),
              state: state,
            ),
          ),
        ],
      ),

      // Rota de Configurações da Conta (fora do shell para não ter Drawer/AppBar do MainLayout)
      GoRoute(
        path: AppRoutes.settingsAccount,
        name: 'settings-account',
        parentNavigatorKey: navigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const AccountSettingsScreen(),
          state: state,
        ),
      ),

      // Rota de Gerenciamento de Assinatura (fora do shell)
      GoRoute(
        path: AppRoutes.settingsSubscription,
        name: 'settings-subscription',
        parentNavigatorKey: navigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const ManageSubscriptionScreen(),
          state: state,
        ),
      ),

      // Rota Sobre (fora do shell)
      GoRoute(
        path: AppRoutes.settingsAbout,
        name: 'settings-about',
        parentNavigatorKey: navigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: SettingsSubScreen(
            title: "Sobre o CATAS",
            children: buildAboutContent(context),
          ),
          state: state,
        ),
      ),

      // Rota Ajuda (fora do shell)
      GoRoute(
        path: AppRoutes.settingsHelp,
        name: 'settings-help',
        parentNavigatorKey: navigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: SettingsSubScreen(
            title: "Obter Ajuda",
            children: buildHelpContent(context),
          ),
          state: state,
        ),
      ),

      // Notificações (fora do shell)
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        parentNavigatorKey: navigatorKey,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: NotificationListScreen(
            returnLocation: state.uri.queryParameters['from'],
          ),
          state: state,
        ),
      ),

      // Payment success (fora do shell, usado por deep link)
      GoRoute(
        path: AppRoutes.paymentSuccess,
        name: 'payment-success',
        parentNavigatorKey: navigatorKey,
        pageBuilder: (context, state) {
          final plan =
              state.uri.queryParameters['plan']?.toUpperCase() ?? 'PRO';
          return _buildPageWithTransition(
            child: SubscriptionSuccessScreen(planName: plan),
            state: state,
          );
        },
      ),

      // Páginas HTML: busca e substitui página (mantém URL limpa)
      GoRoute(
        path: '/:page(terms|privacy|security|about|contact|cookies|refund)',
        name: 'static-page',
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: Builder(
            builder: (context) {
              final page = state.pathParameters['page']!;
              if (kIsWeb) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => renderPage('/$page.html'),
                );
              }
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
          state: state,
        ),
      ),
    ],
  );
}
