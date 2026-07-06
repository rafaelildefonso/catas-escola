import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/picked_attachment.dart';
import '../services/token_holder.dart';
import '../core/app_config.dart';

class StorageRepository {
  Future<String> uploadAttachment(PickedAttachment attachment) async {
    final token = TokenHolder().token;
    if (token == null) throw Exception("Usuário não autenticado");

    throw UnimplementedError(
      "Upload de arquivos não implementado. "
      "Implemente um endpoint de upload no backend e substitua esta chamada.",
    );
  }
}
