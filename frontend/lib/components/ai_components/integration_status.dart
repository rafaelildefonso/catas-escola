import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntegrationStatusComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;

  const IntegrationStatusComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Status das Integrações';
    final services = (data['services'] as List<dynamic>? ?? []);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: services.map((service) {
                  final name = service['name'] ?? '';
                  final status = service['status'] ?? 'disconnected';
                  final isConnected = status == 'connected';

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getIconColor(name).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getServiceIcon(name), size: 18, color: _getIconColor(name)),
                    ),
                    title: Text(
                      name,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConnected 
                          ? Colors.green.withValues(alpha: 0.1) 
                          : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isConnected ? 'Conectado' : 'Desconectado',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isConnected ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getServiceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('google')) return Icons.g_mobiledata_rounded;
    if (n.contains('whatsapp')) return Icons.chat_bubble_outline_rounded;
    if (n.contains('mail')) return Icons.email_outlined;
    if (n.contains('calendar')) return Icons.calendar_today_rounded;
    if (n.contains('sheets')) return Icons.table_chart_outlined;
    return Icons.extension_rounded;
  }

  Color _getIconColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('google')) return Colors.blue;
    if (n.contains('whatsapp')) return Colors.green;
    return Colors.grey;
  }
}
