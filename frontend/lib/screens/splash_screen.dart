import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/server_status_provider.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationTrigger;
  final VoidCallback onRetryConnection;

  const SplashScreen({
    super.key,
    required this.onInitializationTrigger,
    required this.onRetryConnection,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showError = false;
  String _errorMessage = '';
  String _errorDescription = '';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.3).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
    _fadeController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onInitializationTrigger();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String description) {
    setState(() {
      _showError = true;
      _errorMessage = title;
      _errorDescription = description;
    });
  }

  void _dismissError() {
    setState(() {
      _showError = false;
    });
    widget.onRetryConnection();
  }

  Future<String> _getVersion() async {
    final info = await PackageInfo.fromPlatform();
    return "${info.version} (${info.buildNumber})";
  }

  Widget _buildLogo(ThemeData theme, bool isConnecting) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: isConnecting ? _fadeAnimation.value : 1.0,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset(
                'assets/icons/app_icon.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  Consumer<ServerStatusProvider>(
                    builder: (context, serverStatus, child) {
                      final isConnecting = serverStatus.status ==
                              ServerStatus.checking ||
                          serverStatus.status == ServerStatus.starting;

                      if ((serverStatus.status == ServerStatus.offline ||
                              serverStatus.status ==
                                  ServerStatus.unavailable) &&
                          !_showError) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showErrorDialog(
                            serverStatus.getStatusMessage(),
                            serverStatus.getStatusDescription(),
                          );
                        });
                      }

                      return _buildLogo(theme, isConnecting);
                    },
                  ),

                  const Spacer(),

                  FutureBuilder<String>(
                    future: _getVersion(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        "v${snapshot.data}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            if (_showError)
              Positioned.fill(
                child: Container(
                  color: theme.colorScheme.scrim.withValues(alpha: 0.5),
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _errorMessage,
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorDescription,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _dismissError,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
