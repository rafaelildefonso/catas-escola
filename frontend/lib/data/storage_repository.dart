import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/picked_attachment.dart';

class StorageRepository {
  late final SupabaseClient _supabase = Supabase.instance.client;
  final String _bucketName = 'attachments';

  Future<String> uploadAttachment(PickedAttachment attachment) async {
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // Format: userId/timestamp_filename
    // Sanitizando o nome do arquivo para remover espaços ou caracteres especiais
    final safeName = attachment.name.replaceAll(RegExp(r'[^a-zA-Z0-9.\-]'), '_');
    final fileName = '$userId/${timestamp}_$safeName';

    if (kIsWeb) {
      if (attachment.bytes == null) {
        throw Exception("Bytes are required for web upload");
      }
      await _supabase.storage.from(_bucketName).uploadBinary(
            fileName,
            attachment.bytes!,
            fileOptions: const FileOptions(upsert: true),
          );
    } else {
      final file = File(attachment.path);
      await _supabase.storage.from(_bucketName).upload(
            fileName,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
    }

    final publicUrl = _supabase.storage.from(_bucketName).getPublicUrl(fileName);
    return publicUrl;
  }
}
