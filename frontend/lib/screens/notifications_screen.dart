import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/router.dart';

/// Tela de notificações simplificada — sem backend de CRUD no momento.
/// Mostra estado vazio com mensagem explicativa.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Notificações",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.chat);
            }
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(
              "Nenhuma notificação",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Quando houver novidades, elas aparecerão aqui.",
              style: GoogleFonts.inter(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
