import 'package:catas/providers/cloudinary_provider.dart';
import 'package:catas/providers/payments_provider.dart';
import 'package:catas/providers/server_status_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/integrations_provider.dart';
import 'providers/native_context_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/automations_provider.dart';
// Demo providers
import 'providers/demo_automations_provider.dart';
import 'providers/demo_notifications_provider.dart';
import 'providers/demo_autoplay_controller.dart';
import 'screens/splash_screen.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/app_config.dart';
import 'package:flutter/foundation.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializa o Firebase se necessário para processar mensagens em background
  await Firebase.initializeApp();
  debugPrint("FCM Mensagem em background: ${message.messageId}");
}

Future<void> main() async {
  // Configurar URLs limpas no Web (remover o #)
  usePathUrlStrategy();

  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables (.env) from bundled assets.
  // .env is declared as an asset in pubspec.yaml so it's available on all platforms.
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: Could not load .env file: $e");
  }

  // 2. Initialize Firebase safely
  try {
    // On Web, Firebase.initializeApp() requires 'options'.
    // If firebase_options.dart is missing, we skip it to prevent a crash.
    if (!kIsWeb) {
      await Firebase.initializeApp();
      // Only set background handler on supported platforms
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } else {
      debugPrint("Firebase: Skipping default initialization on Web (no options).");
      // If you need Firebase on Web, run 'flutterfire configure' or provide options here.
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  // Enable edge-to-edge mode for transparent system bars
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final isDemoMode = AppConfig.isDemoMode;

  if (!isDemoMode) {
    _initDeepLinks();
  }

  // Load saved locale BEFORE runApp to avoid flash of wrong language
  final localeProvider = LocaleProvider();
  await localeProvider.loadStoredLocale();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(localeProvider: localeProvider)),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => CloudinaryProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => IntegrationsProvider()),
        ChangeNotifierProvider(create: (_) => PaymentsProvider()),
        ChangeNotifierProvider(create: (_) => NativeContextProvider()),
        // Always register base provider types, but use demo implementations when in demo mode
        ChangeNotifierProvider<NotificationsProvider>(
          create: (_) => isDemoMode ? DemoNotificationsProvider() : NotificationsProvider(),
        ),
        ChangeNotifierProvider<AutomationsProvider>(
          create: (_) => isDemoMode ? DemoAutomationsProvider() : AutomationsProvider(),
        ),
        // Demo-only: also register concrete types for direct access in chat_screen
        if (isDemoMode) ...[
          ChangeNotifierProvider<DemoNotificationsProvider>(
            create: (context) => context.read<NotificationsProvider>() as DemoNotificationsProvider,
          ),
          ChangeNotifierProvider<DemoAutomationsProvider>(
            create: (context) => context.read<AutomationsProvider>() as DemoAutomationsProvider,
          ),
          ChangeNotifierProvider(create: (_) => DemoAutoplayController()),
        ],
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: MyApp(navigatorKey: navigatorKey),
    ),
  );
}

void _initDeepLinks() {
  final appLinks = AppLinks();

  // Handle initial link (app opened from deep link)
  appLinks.getInitialLink().then((uri) {
    if (uri != null) {
      _handleDeepLink(uri);
    }
  });

  // Handle incoming links while app is running
  appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri);
  });
}

void _handleDeepLink(Uri uri) {
  if (uri.scheme == 'catas') {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    if (uri.host == 'payment-success') {
      final uriPlan = uri.queryParameters['plan']?.toUpperCase() ?? 'PRO';
      
      // Refresh the user profile so Flutter picks up the new plan tier
      // that the Stripe webhook just wrote to the database.
      context.read<AuthProvider>().refreshProfile().then((_) {
        if (!context.mounted) return;
        context.go('${AppRoutes.paymentSuccess}?plan=$uriPlan');
      });
    } else if (uri.host == 'payment-cancel') {
      context.go(AppRoutes.chat);
    }
  }
}

// AppInitializer removed and merged into MyApp to prevent double MaterialApp routing issues.

class MyApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;
  late final ValueNotifier<bool> _initNotifier;
  bool _fcmInitialized = false;
  late ServerStatusProvider _serverStatusProvider;
  static const Duration _minimumSplashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _initNotifier = ValueNotifier<bool>(false);
    _serverStatusProvider = ServerStatusProvider();
    _router = createRouter(
      context.read<AuthProvider>(),
    );
  }

  Future<void> _initializeApp() async {
    if (AppConfig.isDemoMode) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        int timeoutCounter = 0;
        while (authProvider.isLoading && timeoutCounter < 50) {
          await Future.delayed(const Duration(milliseconds: 100));
          timeoutCounter++;
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _initNotifier.value = true;
      }
      return;
    }

    final startTime = DateTime.now();
    String apiURL = AppConfig.apiBaseUrl;

    await _serverStatusProvider.checkServerHealth(apiURL);

    if (_serverStatusProvider.isOnline) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        int timeoutCounter = 0;
        while (authProvider.isLoading && timeoutCounter < 50) {
          await Future.delayed(const Duration(milliseconds: 100));
          timeoutCounter++;
        }
      }

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < _minimumSplashDuration) {
        await Future.delayed(_minimumSplashDuration - elapsed);
      }

      if (mounted) {
        _initNotifier.value = true;
      }
    }
  }

  Future<void> _retryConnection() async {
    String apiURL = AppConfig.apiBaseUrl;
    await _serverStatusProvider.checkServerHealth(apiURL);
    if (_serverStatusProvider.isOnline) {
      _initNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();

    if (AppConfig.isDemoMode) {
      // FCM não é necessário no demo mode
    } else if (authProvider.isAuthenticated && !_fcmInitialized) {
      _fcmInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          if (!kIsWeb || Firebase.apps.isNotEmpty) {
            context.read<NotificationsProvider>().initFCM();
          } else {
            debugPrint("Skipping FCM init on Web because Firebase is not configured.");
          }
        }
      });
    } else if (!authProvider.isAuthenticated && _fcmInitialized) {
      _fcmInitialized = false;
    }

    return Title(
      title: 'CATAS',
      color: Theme.of(context).colorScheme.primary,
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeProvider.themeMode,
        locale: localeProvider.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) {
          return _SplashGate(
            initNotifier: _initNotifier,
            serverStatusProvider: _serverStatusProvider,
            onInitializationTrigger: _initializeApp,
            onRetryConnection: _retryConnection,
            child: child!,
          );
        },
      ),
    );
  }
}

/// Wrapper stateful que ouve mudanças no _initNotifier e mostra/oculta o splash.
/// Precisa estar DENTRO do MaterialApp.router para o SplashScreen ter acesso ao tema.
class _SplashGate extends StatefulWidget {
  final ValueNotifier<bool> initNotifier;
  final ServerStatusProvider serverStatusProvider;
  final VoidCallback onInitializationTrigger;
  final VoidCallback onRetryConnection;
  final Widget child;

  const _SplashGate({
    required this.initNotifier,
    required this.serverStatusProvider,
    required this.onInitializationTrigger,
    required this.onRetryConnection,
    required this.child,
  });

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    widget.initNotifier.addListener(_onInitChanged);
  }

  @override
  void dispose() {
    widget.initNotifier.removeListener(_onInitChanged);
    super.dispose();
  }

  void _onInitChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!widget.initNotifier.value)
          ChangeNotifierProvider.value(
            value: widget.serverStatusProvider,
            child: SplashScreen(
              onInitializationTrigger: widget.onInitializationTrigger,
              onRetryConnection: widget.onRetryConnection,
            ),
          ),
      ],
    );
  }
}
