import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PreviewWhatsappComponent extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isEnabled;

  const PreviewWhatsappComponent({
    super.key,
    required this.data,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final recipient = data['recipient_name'] as String? ?? 
                      data['recipient'] as String? ?? 
                      data['phone'] as String? ?? 
                      'Contato';
    final message = data['message_text'] as String? ?? 
                    data['message'] as String? ?? 
                    '';
    final time = data['timestamp'] as String? ?? 'Agora';

    const Color whatsappGreen = Color(0xFF25D366);
    const Color whatsappDarkBox = Color(0xFF075E54);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? whatsappDarkBox.withValues(alpha: 0.1)
            : Colors.green.shade50,
        border: Border.all(color: whatsappGreen.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: whatsappGreen.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: whatsappGreen,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pré-visualização do WhatsApp',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: whatsappGreen,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Para: $recipient',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E2b22)
                        : const Color(0xFFE1FFC7), // ZAP light color
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(0), // WhatsApp feel
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: GoogleFonts.inter(
                          height: 1.4,
                          fontSize: 14,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white54
                                : Colors.black45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
