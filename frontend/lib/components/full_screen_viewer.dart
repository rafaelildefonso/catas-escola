import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/picked_attachment.dart';
import '../l10n/app_localizations.dart';

class FullScreenViewer extends StatelessWidget {
  final PickedAttachment? attachment;
  final String? url;
  final String? tag;

  const FullScreenViewer({super.key, this.attachment, this.url, this.tag})
    : assert(attachment != null || url != null);

  bool _isVideo(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget content;
    final String name =
        attachment?.name ?? url?.split('/').last.split('?').first ?? 'Arquivo';

    if (url != null) {
      final isLocal = !url!.startsWith('http');
      content = InteractiveViewer(
        child: Hero(
          tag: tag ?? url!,
          child: isLocal
              ? Image.file(File(url!), fit: BoxFit.contain)
              : CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.54),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.couldNotLoadImage,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    } else if (attachment!.isImage) {
      if (attachment!.bytes != null) {
        content = InteractiveViewer(child: Image.memory(attachment!.bytes!));
      } else if (!kIsWeb && attachment!.path.isNotEmpty) {
        content = InteractiveViewer(child: Image.file(File(attachment!.path)));
      } else {
        content = Center(child: Text(l10n.imageUnavailable));
      }
    } else {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isVideo(name) ? Icons.videocam : Icons.insert_drive_file,
              size: 100,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 24),
            Text(
              name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Visualização não suportada nativamente.",
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.54),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          name,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
      ),
      body: content,
    );
  }
}
