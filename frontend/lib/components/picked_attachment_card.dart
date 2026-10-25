import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/picked_attachment.dart';
import 'full_screen_viewer.dart';

class PickedAttachmentCard extends StatelessWidget {
  final PickedAttachment attachment;
  final VoidCallback onRemove;

  const PickedAttachmentCard({
    super.key,
    required this.attachment,
    required this.onRemove,
  });

  bool _isVideo(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext);
  }

  Widget _buildPreview(BuildContext context) {
    if (attachment.isImage) {
      if (attachment.bytes != null) {
        return Image.memory(
          attachment.bytes!,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        );
      } else if (!kIsWeb && attachment.path.isNotEmpty) {
        return Image.file(
          File(attachment.path),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        );
      }
    }

    // Fallback para icones
    return Container(
      width: 50,
      height: 50,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        _isVideo(attachment.name)
            ? Icons.videocam_outlined
            : Icons.insert_drive_file_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullScreenViewer(attachment: attachment),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildPreview(context),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
